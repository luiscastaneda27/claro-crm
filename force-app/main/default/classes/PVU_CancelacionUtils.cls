/*****************************************************************************
* Autor: Sara Garrido
* Fecha: 2024-19-04
* Equipo: Pos-Ventas
* HU: 669156
* Descripcion: Clase utilitaria para canceilación
* Modificaciones: 2024-19-04 por HU 669156
***********************************************************************************/

global with sharing class PVU_CancelacionUtils implements vlocity_cmt.VlocityOpenInterface{
    public  Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Boolean result = true;
        try{
            if (methodName.equals('getOrdenesFuturas')){
                getOrdenesFuturas(input, outMap, options);
            }else if (methodName.equals('updateCase')){
                updateCase(input, outMap, options);
            }else if (methodName.equals('setDatetimeGmt')){
                setDatetimeGmt(input, outMap, options);
            }else if ( methodName.equals('datesByCycle')){
                datesByCycle(input, outMap, options);
            }else if ( methodName.equals('updateAssetFallecimiento')){
                updateAssetFallecimiento(input, outMap, options);
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
* Autor: Sara Garrido
* Fecha: 2024-05-22
* Equipo: Pos-Ventas
* HU: 687137
* Input: MIN
* Descripcion: este metodo se usa para traer las ordenes futuras asociadas a un mismo MIN
*/
    public void getOrdenesFuturas(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        try{
            String inputMin = (String)input.get('min');
            List<Object> lstOrdenesFuturas = new List<Object>();
            
            List<vlocity_cmt__Subscription__c> lstSubscription = [SELECT Id 
                                                                  FROM vlocity_cmt__Subscription__c 
                                                                  WHERE OM_MSISDN__c =: inputMin WITH USER_MODE];
            
            Map<String, Map<String, String> > mapOrderItem = new Map<String, Map<String, String>> ();
            if (!lstSubscription.isEmpty()) {
                Set<String> idsSubscription = new Set<String>();
                
                for(vlocity_cmt__Subscription__c subs : lstSubscription){
                    idsSubscription.add(subs.Id);
                }
                
                List<OrderItem> lstOrderItem = [SELECT id, Order.OrderNumber, toLabel(Order.vlocity_cmt__OrderStatus__c), 
                                                Order.Type, Order.FVU_OrderSubType__c
                                                FROM OrderItem 
                                                WHERE Order.vlocity_cmt__OrderStatus__c = 'Queued'
                                                AND vlocity_cmt__AssetId__r.vlocity_cmt__SubscriptionId__c IN: idsSubscription WITH USER_MODE];
                for(OrderItem orderRecord : lstOrderItem){
                    Map<String, String> objOrdenFutura = new Map<String, String>();
                    objOrdenFutura.put('orderId', orderRecord.Order.Id);
                    objOrdenFutura.put('orderNumber', orderRecord.Order.OrderNumber);
                    objOrdenFutura.put('orderStatus', orderRecord.Order.vlocity_cmt__OrderStatus__c);
                    objOrdenFutura.put('orderVozCliente', orderRecord.Order.Type+' '+orderRecord.Order.FVU_OrderSubType__c);
                    lstOrdenesFuturas.add(objOrdenFutura);
                    
                    if(mapOrderItem.get(orderRecord.Order.OrderNumber) == null){
                        mapOrderItem.put(orderRecord.Order.OrderNumber, objOrdenFutura);
                    }
                }
            }
            //outMap.put('lstOrdenesFuturas', lstOrdenesFuturas);
            //outMap.put('lstOrdenesFuturasSize', lstOrdenesFuturas.size());
            outMap.put('lstOrdenesFuturas', mapOrderItem.values());
            outMap.put('lstOrdenesFuturasSize', mapOrderItem.values().size());
        }catch(Exception ex){
            throw ex;
        }
    }
    
    public void updateCase(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        String inputOrderId = (String)input.get('orderId');
        String inputMensaje = (String)input.get('mensajeCase');
        String inputOrdenProcesada = (String)input.get('ordenProcesadaValue');
        List<Object> caseFinal = new List<Object>();
        
        // Lista de casos relacionados a la orden (deberia haber uno solo relacionado a la misma orden)
        List<Case> casesByOrderIdList = [select Id, CaseNumber, PVU_Order__c, PVU_Order__r.OrderNumber, OM_Orden_Procesada__c, 
                                         PVU_Observaciones__c, PVU_Order__r.vlocity_cmt__OrderStatus__c
                                         from Case where PVU_Order__c  =: inputOrderId WITH USER_MODE];
        if( casesByOrderIdList.size() > 0 ){
            // Set de mensaje parametrizable para las Observaciones del caso
            PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
            String methodNameMessage = 'setParametrosEnMensaje';
            Map<String, Object> inputMessage = new Map<String, Object>();
            Map<String, Object> outputMessage = new Map<String, Object>();
            Map<String, Object> optionsMessage = new Map<String, Object>();
            List<String> parametros = new List<String>();
            parametros.add(casesByOrderIdList[0].CaseNumber);
            parametros.add(casesByOrderIdList[0].PVU_Order__r.OrderNumber);
            inputMessage.put('mensaje', inputMensaje);
            inputMessage.put('parametros', parametros);
            messageHandler.invokeMethod(methodNameMessage, inputMessage, outputMessage, optionsMessage);
            String mensajeResultado = (String)outputMessage.get('mensajeParametrizado');
            
            // Update campo Observaciones y camino de procesamiento de Orden
            casesByOrderIdList[0].PVU_Observaciones__c = mensajeResultado;
            casesByOrderIdList[0].OM_Orden_Procesada__c = inputOrdenProcesada;
            update as user casesByOrderIdList;
            
            
            Map<String, String> caseUpdated = new Map<String, String>();
            caseUpdated.put('caseOrderId', casesByOrderIdList[0].PVU_Order__c);
            caseUpdated.put('caseOrderNumber', casesByOrderIdList[0].PVU_Order__r.OrderNumber);
            caseUpdated.put('caseOrderStatus', casesByOrderIdList[0].PVU_Order__r.vlocity_cmt__OrderStatus__c);
            caseUpdated.put('caseId', casesByOrderIdList[0].Id);
            caseUpdated.put('caseNumber', casesByOrderIdList[0].CaseNumber);
            caseUpdated.put('caseOrdenProcesada', casesByOrderIdList[0].OM_Orden_Procesada__c);
            caseUpdated.put('caseObservaciones', casesByOrderIdList[0].PVU_Observaciones__c);
            caseFinal.add(caseUpdated);
            outMap.put('caseUpdated', caseFinal);
        }else{
            Map<String, String> caseUpdated = new Map<String, String>();
            caseUpdated.put('ERROR', 'No hay casos asociados a la orden ' + inputOrderId);
            caseFinal.add(caseUpdated);
            outMap.put('caseUpdated', caseFinal);
        }
    }
    
    public void setDatetimeGmt(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        try{
            String inputDate = (String)input.get('date');
            DateTime dt = DateTime.now();
            Time myTime = dt.time();
            Date mydate = Date.valueOf(inputDate);
            DateTime result = DateTime.newInstance(myDate, myTime);
            
            outMap.put('fechaGMT', result);
        }catch(Exception ex){
            throw ex;
        }
    }
    
    /************************************************************************
* Autor: Hector Machuca
* Fecha: 2025-01-09
* Equipo: Pos-Ventas
* HU: 393574
* Input: Ciclo
* Descripcion: Este metodo se utiliza para retornar la información de fecha en relación a un ciclo de facturación. 
*/
    public void datesByCycle(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        try{
            DateTime dt = DateTime.now();
            Integer anioActual = Date.today().year();
            Integer mesActual = Date.today().month();
            Integer diaActual = Date.today().day();
            
            
            String cicloInput = (String)input.get('ciclo');
            
            Integer ciclo = integer.valueof(cicloInput);
            
            Date fechaCiclo = Date.newInstance(anioActual,mesActual,ciclo);
            Date fechaSiguiente = Date.newInstance(anioActual, mesActual + 1, ciclo);
            Date fechaActual = Date.newInstance(anioActual, mesActual, diaActual);
            
            
            Set<Date> feriados = new Set<Date>();
            //Obtenemos los feriados desde Holiday  object. 
            for( Holiday feriado : [SELECT ActivityDate from Holiday WITH SYSTEM_MODE]){
                feriados.add(feriado.ActivityDate);
            }
            
            
            Integer diasLaborales = 0;
            
            if (fechaActual < fechaCiclo){
                for (Date fecha = fechaActual; fecha < fechaCiclo; fecha = fecha.addDays(1)) {
                    //Verificar si el día es laboral (no sábado, no domingo y no feriado)
                    date InicioSemana = fecha.toStartofWeek();
                    integer dayofweek = InicioSemana.daysBetween(fecha);
                    
                    if (dayofweek == 6 || dayofweek == 0 || feriados.contains(fecha)) {
                        continue;
                    }else{
                        diasLaborales++;
                    }
                }
            }         
            
            
            outMap.put('fechaCiclo', fechaCiclo);
            outMap.put('fechaCorteActual', fechaCiclo);
            outMap.put('fechaCorteSiguiente', fechaSiguiente);
            outMap.put('diasLaborales',diasLaborales);
        }catch(Exception ex){
            throw ex;
        }
    }
    
        
    public void updateAssetFallecimiento (Map<String, Object> input,Map<String, Object> outMap,Map<String, Object> options){
        try {
            // Obtener el nodo raíz
            Map<String, Object> root = (Map<String, Object>) input.get('IPGetFinancingInfo');
            String accountId = (String) input.get('accountId');
            
            if (root == null || accountId == null) {
                outMap.put('error', 'Datos de entrada incompletos: root o accountId son nulos');
                return;
            }
            
            // Obtener financings
            Map<String, Object> financings = (Map<String, Object>) root.get('financings');
            
            if (financings == null) {
                outMap.put('warning', 'No se encontró el nodo financings en la respuesta');
                return;
            }
            
            // SOLUCIÓN ROBUSTA: Manejar tanto lista como objeto único
            List<Object> financingList = new List<Object>();
            Object financingObj = financings.get('financing');
            
            if (financingObj == null) {
                outMap.put('warning', 'No se encontró el campo financing en financings');
                return;
            }
            
            // Determinar el tipo de objeto y convertirlo a lista
            if (financingObj instanceof List<Object>) {
                // Caso 1: Es una lista de financiamientos
                financingList = (List<Object>) financingObj;
                System.debug('DEBUG: financing es una lista con ' + financingList.size() + ' elementos');
            } else if (financingObj instanceof Map<String, Object>) {
                // Caso 2: Es un objeto único (Map) - convertirlo a lista
                financingList.add(financingObj);
                System.debug('DEBUG: financing es un objeto único, convertido a lista');
            } else {
                System.debug('error, Tipo de dato inesperado para financing');
                // Caso 3: Tipo inesperado - registrar y salir
                //outMap.put('error', 'Tipo de dato inesperado para financing: ' + financingObj.getTypeName());
                return;
            }
            
            if (financingList.isEmpty()) {
                outMap.put('warning', 'La lista de financiamientos está vacía');
                return;
            }
            
            // Set para evitar duplicados
            Set<String> chargeBillingAccountSet = new Set<String>();
            
            for (Object f : financingList) {
                if (f instanceof Map<String, Object>) {
                    Map<String, Object> node = (Map<String, Object>) f;
                    String cba = (String) node.get('chargeBillingAccount');
                    if (String.isNotBlank(cba)) {
                        chargeBillingAccountSet.add(cba);
                        System.debug('DEBUG: Agregado chargeBillingAccount: ' + cba);
                    }
                } else {
                    System.debug('DEBUG: Elemento inesperado en financingList: ' + f);
                }
            }
            
            if (chargeBillingAccountSet.isEmpty()) {
                outMap.put('warning', 'No se encontraron chargeBillingAccount válidos');
                return;
            }
            
            System.debug('DEBUG: chargeBillingAccountSet a buscar: ' + chargeBillingAccountSet);
            
            // ============================
            //   CONSULTA DE ASSETS
            // ============================
            List<Asset> assetsToUpdate = [
                SELECT Id,
                AccountId,
                PVU_GestionPorFallecimiento__c,
                Product2.Name,
                Product2.vlocity_cmt__Type__c,
                FIN_NumeroDeCredito__c,
                FIN_IdReferenciaDelCredito92__c
                FROM Asset
                WHERE FIN_IdReferenciaDelCredito92__c IN :chargeBillingAccountSet
                AND AccountId = :accountId
                WITH SYSTEM_MODE
            ];
            
            System.debug('DEBUG: Assets encontrados: ' + assetsToUpdate.size());
            
            if (assetsToUpdate.isEmpty()) {
                outMap.put('info', 'No se encontraron Assets para actualizar');
                return;
            }
            
            // ============================
            //   UPDATE DE ASSETS
            // ============================
            for (Asset a : assetsToUpdate) {
                a.PVU_GestionPorFallecimiento__c = 'Crédito cliente fallecido';
                System.debug('DEBUG: Asset a actualizar - Id: ' + a.Id + ', Referencia: ' + a.FIN_IdReferenciaDelCredito92__c);
            }
            
            // Update con captura de errores parciales
            Database.SaveResult[] results = Database.update(assetsToUpdate, false, AccessLevel.SYSTEM_MODE);
            
            // Manejo detallado de resultados
            Integer successCount = 0;
            Integer errorCount = 0;
            List<String> errorMessages = new List<String>();
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult r = results[i];
                Asset asset = assetsToUpdate[i];
                
                if (r.isSuccess()) {
                    successCount++;
                    System.debug('DEBUG: Asset actualizado exitosamente - Id: ' + asset.Id);
                } else {
                    errorCount++;
                    for (Database.Error err : r.getErrors()) {
                        String errorMsg = 'Asset Id: ' + asset.Id + 
                            ', Referencia: ' + asset.FIN_IdReferenciaDelCredito92__c + 
                            ', Error: ' + err.getMessage();
                        errorMessages.add(errorMsg);
                        System.debug('ERROR: ' + errorMsg);
                    }
                }
            }
            
            // Preparar respuesta detallada
            outMap.put('success', successCount > 0);
            outMap.put('successCount', successCount);
            outMap.put('errorCount', errorCount);
            outMap.put('totalProcessed', assetsToUpdate.size());
            
            if (!errorMessages.isEmpty()) {
                outMap.put('errorDetails', errorMessages);
            }
            
            if (successCount > 0) {
                outMap.put('message', 'Se actualizaron ' + successCount + ' de ' + assetsToUpdate.size() + ' Assets');
            }
            
        } catch (Exception e) {
            // Logging detallado del error
            System.debug('ERROR CRÍTICO en updateAssetFallecimiento: ' + 
                         e.getMessage() + 
                         ' - Línea: ' + e.getLineNumber() + 
                         ' - StackTrace: ' + e.getStackTraceString());
            
            // Respuesta de error estructurada
            outMap.put('error', 'Error en updateAssetFallecimiento: ' + e.getMessage());
            outMap.put('errorType', e.getTypeName());
            outMap.put('lineNumber', e.getLineNumber());
            outMap.put('stackTrace', e.getStackTraceString());
        }
    }
}