/*******************************************************************************
 * Autor: Federico Mandri
 * Fecha: 2023-09-01
 * Equipo: Pos-Ventas
 * HU: 661134
 * Descripcion: Clase utilitaria de PQR
 * Modificaciones: 2023-09-05 por HU 658839
 * Modificaciones: 2023-09-05 por HU 689269
 * Modificaciones: 2024-03-27 por HU 672699
 ***********************************************************************************/

global with sharing class PVU_PQRUtils implements vlocity_cmt.VlocityOpenInterface{
    public  Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Boolean result = true;
        try{
            if (methodName.equals('transformPQRList')){
                transformPQRList(input, outMap, options);
            }
            else if(methodName.equals('populatePicklist')){
                populatePicklist(input, outMap, options);
            }
            else if(methodName.equals('populateChildPickList')){
                populateChildPickList(input, outMap, options);
            }
            else if(methodName.equals('populateGrandChildPickList')){
                populateGrandChildPickList(input, outMap, options);
            }
            //20240403 - FM - HU 675471 - INICIO
            else if(methodName.equals('populateSubCategoryPickList')){
                populateSubCategoryPickList(input, outMap, options);
            }
            else if(methodName.equals('populateVocesClientePickList')){
                populateVocesClientePickList(input, outMap, options);
            }
            else if(methodName.equals('getAllTipification')){
                getAllTipification(input, outMap, options);
            }
            //20240403 - FM - HU 675471 - FIN
            else if(methodName.equals('calculateTiempoDesactivacion')){ //20240816 - SG - NEGACION PORTABILIDAD
                calculateTiempoDesactivacion(input, outMap, options);
            }
        }
        catch(Exception ex){
            outMap.put('error', ex.getStackTraceString());
            outMap.put('MensajeExcepcion', ex.getMessage());
            outMap.put('Linea', ex.getLineNumber());
            outMap.put('Causa', ex.getCause());
            
            result = false;
        }
        
        return result;
    }
    
    /************************************************************************
     * Autor: Federico Mandri
     * Fecha: 2023-09-01
     * Equipo: Pos-Ventas
     * HU: 661134
     * Descripcion: este metodo se usa para armar los registros pqr que se van a mostrar en la v360.
     * 				Por cada registro devuelto por el servicio PVU_IPsConsultCasesAPis, obtiene la voz de cliente
     * 				del custom metadata PQR_Codigos__mdt a partir del codigo que llega en el servicio y arma el dato
     * 				para mostrar en ela v360.
     * 				El objetivo mejorar la performance en el IP PVU_IPsvcConsultaCasesPQRRecurso
     *
     * Modificaciones: 2024-03-27 por HU 672699 - El asesor radicador y su ubicación se obtienen de SF
     */
    
    private String safeString(Object value) {
            return value == null ? '' : String.valueOf(value);
        }
    public void transformPQRList(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        try{
            /*******************************************************************************/
            /*El parametro de entrada que llega del IP es la lista de PQRs devuelta por ADA*/
            
            Map<String, Object> pqrApiList = (Map<String, Object>)input.get('cases');
            
            List<Object> instances = (List<Object>)pqrApiList.get('cases');
            
            
            /*********************************************************************************/
            
            Set<String> codigosVozCliente = new Set<String>();
            List<Map<String, Object>> pqrMapList = new List<Map<String, Object>>();
            //20240327 - FM - HU 672699 - INICIO
            Set<String> nrSet = new Set<String>();
            //20240327 - FM - HU 672699 - FIN
            
            /********************************************************************************/
            /*Obtengo los codigos de voz de cliente que vienen en cada registro devuelto por ADA para luego consultarlos en el custom metadata*/
            for(Object instance : instances){
                pqrMapList.add((Map<String, Object>)instance);
            }
            for(Map<String, Object> pqrMap : pqrMapList){
                String codigoVozCliente = String.valueOf(pqrMap.get('codVozDelCliente'));
                codigosVozCliente.add(codigoVozCliente);
                
                //20240327 - FM - HU 672699 - INICIO
                String nr = (String)pqrMap.get('nr');
                nrSet.add(nr);
                //20240327 - FM - HU 672699 - FIN
            }
            
            /******************************************************************************************/
            
            List<PQR_Codigos__mdt> vocesCliente = [SELECT ID, Categoria__c, SubCategoria__c, VozCliente__c, CodigoCategoria__c, CodigoSubCategoria__c, CodigoVozCliente__c 
                                                   FROM PQR_Codigos__mdt 
                                                   WHERE CodigoVozCliente__c IN :codigosVozCliente
                                                   WITH USER_MODE
                                                  LIMIT 5000];
            Map<String, PQR_Codigos__mdt> vozClienteMap = new Map<String, PQR_Codigos__mdt>();
            for(PQR_Codigos__mdt vozCliente : vocesCliente){
                vozClienteMap.put(vozCliente.CodigoVozCliente__c, vozCliente);
            }
            
            
            //20240327 - FM - HU 672699 - INICIO
            List<Case> casesSF = [SELECT Id, PVU_NR__c, CreatedBy.PVU_Usuario_Red__c, CreatedBy.FVU_PuntoVenta__c 
                                  FROM Case 
                                  WHERE PVU_NR__c in :nrSet
                                  WITH USER_MODE 
                                  LIMIT 5000];
            Map<String, Case> casesSFMap = new Map<String, Case>();
            for(Case caso : casesSF){
                casesSFMap.put(caso.PVU_NR__c, caso);
            }
            
            //20240327 - FM - HU 672699 - FIN
            
            List<Map<String, Object>> casosTransformados = new List<Map<String, Object>>();
            
            /*******************************************************************************************/
            /*Recorro la lista de pqr devuelta por ADA y armo el registro transformado que luego será visible en v360*/
            for(Map<String, Object> pqrMap : pqrMapList){
                
                Map<String, String> casoPqr = new Map<String, String>();
                //casoPqr.put('casoAsesorRadPQR', (String)pqrMap.get('assessorWhoCreatedPQR'));
                //casoPqr.put('casoCodigoCierre', (String)pqrMap.get('codRazonDeCierre'));
                casoPqr.put('casoCodigoCierre', String.valueOf(pqrMap.get('codRazonDeCierre')));
                casoPqr.put('casoDescripcion', (String)pqrMap.get('descripcion'));
                casoPqr.put('casoEstado', (String)pqrMap.get('estado'));
                casoPqr.put('casoFavorabilidad', (String)pqrMap.get('favorability'));
                casoPqr.put('casoFechaCreacion', (String)pqrMap.get('fechaRadicacion'));
                casoPqr.put('casoFechaRecibido', (String)pqrMap.get('fechaRecibido'));
                casoPqr.put('casoEntregaEquipo', safeString(pqrMap.get('devolucionEquipo')));
                casoPqr.put('casoValorDevolver', safeString(pqrMap.get('valorDevolver')));
                casoPqr.put('casoComentarioFinalCaso', safeString(pqrMap.get('comentarioFinalCaso')));
                casoPqr.put('casoFechaSAP', (String)pqrMap.get('fechaSap'));
                casoPqr.put('casoNumCun', (String)pqrMap.get('cun'));
                //casoPqr.put('casoNumRadicado', (String)pqrMap.get('nr'));
                casoPqr.put('casoTipo', (String)pqrMap.get('tipoCaso'));
                //casoPqr.put('casoUbicacionAsesor', (String)pqrMap.get('assessorLocationWhoCreatedPQR'));
                casoPqr.put('casoUserSolPQR', (String)pqrMap.get('assessorWhoRespondedPQR'));
                casoPqr.put('caseDescripcion', (String)pqrMap.get('descripcion'));
                casoPqr.put('casoAsunto', (String)pqrMap.get('asunto'));
                casoPqr.put('casoCategoria', (String)pqrMap.get('forCategory'));
                casoPqr.put('casoSubCategoria', (String)pqrMap.get('forSubcategory'));
                casoPqr.put('respuestaDelCaso', (String)pqrMap.get('respuestaDelCaso'));
                String vozClienteInput = String.valueOf(pqrMap.get('codVozDelCliente'));
                //String vozCliente = (vozClienteMap.get(vozClienteInput)).VozCliente__c;
                String vozCliente = vozClienteMap.get(vozClienteInput) != null ?  (vozClienteMap.get(vozClienteInput)).VozCliente__c : '';
                 if ((String)pqrMap.get('tipoCaso')!='REQUERIMIENTOS LEGALES'){
                casoPqr.put('casoVozCliente', vozCliente);
                  }else {
                   casoPqr.put('casoVozCliente',(String)pqrMap.get('forVoiceOfCustomer'));
                   }
                //20240327 - FM - HU 672699 - INICIO
                String nrInput = (String)pqrMap.get('nr');
                String usuarioRadicador = casesSFMap.get(nrInput) != null ? (casesSFMap.get(nrInput)).CreatedBy.PVU_Usuario_Red__c : 'Sin Información';
                String ubicacionRadicador = casesSFMap.get(nrInput) != null ? (casesSFMap.get(nrInput)).CreatedBy.FVU_PuntoVenta__c : 'Sin Información';
                casoPqr.put('casoAsesorRadPQR', usuarioRadicador);
                casoPqr.put('casoUbicacionAsesor', ubicacionRadicador);
                casoPqr.put('casoNumRadicado', nrInput);
                //20240327 - FM - HU 672699 - FIN
                
                casosTransformados.add(casoPqr);
            }
            /*********************************************************************************************************/
            
            outMap.put('CasosSF', casosTransformados);
            
        }
        catch(Exception ex){
            
            throw ex;
        }
        
    }
    
    public void populatePicklist(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options) {
        List<String> categoriaListNegra = new List<String>{'Ventas'};
        List < Map < String, String >> UIoptions = new List < Map < String, String >> ();
        Schema.DescribeFieldResult fieldResult = Case.PVU_Level1__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            if(!categoriaListNegra.contains(pickListVal.getLabel())  &&  (pickListVal.isActive()) ){
                Map < String, String > tempMap = new Map < String, String > ();
                tempMap.put('name', pickListVal.getLabel());
                tempMap.put('value', pickListVal.getLabel());
                UIoptions.add(tempMap);
            }
        }
        outMap.put('options', UIoptions);
        
    }
    
    public void populateChildPickList(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Map<String, List < Map < String, String >>> dependency = new Map<String, List < Map < String, String >>> ();
        List<PQR_Categoria__mdt> categoriaList = [SELECT Id, Categoria__c FROM PQR_Categoria__mdt WITH USER_MODE];
        
        List<PQR_Subcategoria__mdt> subcategoriaList = [SELECT Id, Categoria__c, SubCategoria__c FROM PQR_Subcategoria__mdt WITH USER_MODE];
        
        for(PQR_Categoria__mdt categoria : categoriaList){
            List < Map < String, String >> UIoptions = new List < Map < String, String >> ();
            for(PQR_Subcategoria__mdt subcategoria : subcategoriaList){
                
                if(subcategoria.Categoria__c == categoria.Categoria__c){
                    Map < String, String > tempMap = new Map < String, String > ();
                    tempMap.put('name', subcategoria.SubCategoria__c);
                    tempMap.put('value', subcategoria.SubCategoria__c);
                    UIoptions.add(tempMap);
                    
                }
            }
            dependency.put(categoria.Categoria__c,UIoptions);
            
        }
        outMap.put('dependency', dependency);
        
    }
    
    public void populateGrandChildPickList(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Map<String, List < Map < String, String >>> dependency = new Map<String, List < Map < String, String >>> ();
        List<PQR_Subcategoria__mdt> subcategoriaList = [SELECT Id, Categoria__c, SubCategoria__c FROM PQR_Subcategoria__mdt WITH USER_MODE];
        
        List<PQR_Codigos__mdt> vocesCliente = [SELECT Id, Categoria__c, SubCategoria__c, VozCliente__c FROM PQR_Codigos__mdt WITH USER_MODE];
        
        for(PQR_Subcategoria__mdt subcategoria : subcategoriaList){
            List < Map < String, String >> UIoptions = new List < Map < String, String >> ();
            for(PQR_Codigos__mdt vozCliente : vocesCliente){
                
                if(vozCliente.SubCategoria__c == subcategoria.SubCategoria__c){
                    Map < String, String > tempMap = new Map < String, String > ();
                    tempMap.put('name', vozCliente.VozCliente__c);
                    tempMap.put('value', vozCliente.VozCliente__c);
                    UIoptions.add(tempMap);
                    
                }
            }
            dependency.put(subcategoria.SubCategoria__c,UIoptions);
            
        }
        outMap.put('dependency', dependency);
        
    }
    
    //20240403 - FM - HU 675471 - INICIO
    public void populateSubCategoryPickList(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        
        String catgoriaInput = (String)input.get('categoria');
        List < Map < String, String >> subcategorias = new List < Map < String, String >> ();
        
        List<PQR_Subcategoria__mdt> subcategoriaList = [SELECT Id, Categoria__c, SubCategoria__c 
                                                        FROM PQR_Subcategoria__mdt 
                                                       	WHERE Categoria__c = :catgoriaInput
                                                        WITH USER_MODE 
                                                        LIMIT 5000];
        
        for(PQR_Subcategoria__mdt subcategoria : subcategoriaList){
            Map < String, String > tempMap = new Map < String, String > ();
            tempMap.put('name', subcategoria.SubCategoria__c);
            tempMap.put('value', subcategoria.SubCategoria__c);
            subcategorias.add(tempMap);
        }
        
        
        outMap.put('subcategorias', subcategorias);
    }
    
    
    public void populateVocesClientePickList(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        
        String tipoPQRInput = (String)input.get('tipoPQR');
        List < Map < String, String >> vocesClienteListMap = new List < Map < String, String >> ();
        List<PQR_Codigos__mdt> vocesCliente = new List<PQR_Codigos__mdt>();
        
        if(tipoPQRInput == 'Queja'){
            vocesCliente = [SELECT Id, Categoria__c, SubCategoria__c, VozCliente__c, Queja__c, Peticion__c, PVU_RequerimientoLegal__c 
                            FROM PQR_Codigos__mdt WHERE Queja__c = True WITH USER_MODE LIMIT 5000];
            
        }
        else if(tipoPQRInput == 'RequerimientoLegal'){
            vocesCliente = [SELECT Id, Categoria__c, SubCategoria__c, VozCliente__c, Queja__c, Peticion__c, PVU_RequerimientoLegal__c 
                            FROM PQR_Codigos__mdt WHERE PVU_RequerimientoLegal__c = True WITH USER_MODE LIMIT 5000];
        }
        else{
            vocesCliente = [SELECT Id, Categoria__c, SubCategoria__c, VozCliente__c, Queja__c, Peticion__c, PVU_RequerimientoLegal__c 
                            FROM PQR_Codigos__mdt WHERE Peticion__c = True WITH USER_MODE LIMIT 5000];
            
        }
        
        for(PQR_Codigos__mdt vozCliente : vocesCliente){
            Map < String, String > tempMap = new Map < String, String > ();
            tempMap.put('name', vozCliente.VozCliente__c);
            tempMap.put('value', vozCliente.VozCliente__c);
            vocesClienteListMap.add(tempMap);
        }
        
        
        outMap.put('vocesCliente', vocesClienteListMap);
    }
    
    
    public void getAllTipification(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        List<Map<String,String>> fields = new List<Map<String, String>>();
        List<PQR_Codigos__mdt> tipificaciones = [SELECT Id, Categoria__c, SubCategoria__c, VozCliente__c, 
                                                 	CodigoCategoria__c, CodigoSubCategoria__c, CodigoVozCliente__c, 
                                                 	Queja__c, Peticion__c, PVU_RequerimientoLegal__c 
                            					FROM PQR_Codigos__mdt 
                                                WITH USER_MODE
                                                ORDER BY VozCliente__c ASC
                                                LIMIT 5000];
        for(PQR_Codigos__mdt tipificacion : tipificaciones){
            Map<String, String> field = new Map<String, String>();
            field.put('categoria', tipificacion.Categoria__c);
            field.put('subcategoria', tipificacion.SubCategoria__c);
            field.put('vozDeCliente', tipificacion.VozCliente__c);
            field.put('codigoCategoria', tipificacion.CodigoCategoria__c);
            field.put('codigoSubCategoria', tipificacion.CodigoSubCategoria__c);
            field.put('codigoVozDeCliente', tipificacion.CodigoVozCliente__c);
            field.put('queja', String.valueOf(tipificacion.Queja__c));
            field.put('peticion', String.valueOf(tipificacion.Peticion__c));
            field.put('requerimientoLegal', String.valueOf(tipificacion.PVU_RequerimientoLegal__c));
            fields.add(field);
        }
        
        outMap.put('tipificaciones', fields);
    }
    //20240403 - FM - HU 675471 - FIN
    
    public void calculateTiempoDesactivacion(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        String assetId = (String)input.get('assetId');
        Long tiempoDesactivacion = 0;
        List<Map<String,String>> fields = new List<Map<String, String>>();
        Asset assetInput = [SELECT LastModifiedDate, OM_SubStatus__c, Status 
                            FROM Asset 
                            WHERE Id =: assetId 
                            WITH USER_MODE][0];
        
        if (assetInput != null && assetInput.Status == 'Deactivated' &&
        assetInput.OM_SubStatus__c == 'Portout') {
            tiempoDesactivacion = daysDiffBetweenTwoDatetimes(assetInput.LastModifiedDate, DateTime.now());
        }
        
        outMap.put('TiempoDesactivacion', tiempoDesactivacion);
    }
    
    public Long daysDiffBetweenTwoDatetimes(DateTime dt1, DateTime dt2){
        Long dt1Long = dt1.getTime();
        Long dt2Long = dt2.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hours = minutes / 60;
        return hours / 24;
    }
    
}