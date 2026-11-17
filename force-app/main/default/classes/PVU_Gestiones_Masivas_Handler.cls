/*******************************************************************************
* Autor: Ame
* Fecha: 2024-10-25
* Equipo: Pos-Ventas
* Descripcion: Handler para el proceso de gestiones masivas.
* History
<Date>            <Author>             <Description>                                 <Version>
2024-10-25         Ame                 creacion                                       01
2024-11-13         Hector              modificacion                                   02
2024-11-29         Gabo                Validacion Reactivacion                        03
2025-01-03         Gabo                Ajuste Validacion Desactivacion                04
2025-01-09         Gabo                Reinstalacion                                  05
2025-01-22         Ame                 Evolutivo 534479                               06
2025-02-05         Ame                 sp51                                           07
2025-02-28         Ame                 sp52                                           08
2025-02-28         hllanos            Add BUG 558057                                  09
2025-03-27         hllanos            Add BUG 579233                                  10
2025-05-05         hllanos            fix disconnect Adition Product
                                      with more than two existing products on asset   11
2025-05-08         Ame                 sp55 Activación/Desactivación de 
                                        beneficio Todo Claro                          12
2025-10-06         hllanos            Add HDU #586055                                 13
***********************************************************************************/
public with sharing class PVU_Gestiones_Masivas_Handler {
    
    //Wrapper Class
    Public class WGestionMasiva{
        //Variables globales del proceso
        public Map<String, PVU_AssetToOrderCodigos__mdt> mapAssetToOrderMTD{get;set;}
        //RecordTypesId
        public Id StandardOrderRTId{get;set;}
    	public Id posventaRT{get;set;} 

        public String BillingAccountNumber{get;set;} //Billing Account External Number
        public Id BillingAccountId {get;set;} //Billing Account Id
        public PVU_Gestiones_Masivas__c GestionMasiva{get;set;} //Gestion Masiva
        public Asset Asset{get;set;}//Asset (root) relacionado a la billing Account
        public Asset AssetPlan{get;set;}//Asset(Producto:Plan)
        public Asset AssetFuncionalidades{get;set;}//Asset(Producto:Funcionalidades)
        public Asset AssetMin{get;set;}//Asset(Producto: Type = 'MISDN') 
        public Map<String, Asset> MapAssetAdicionales{get;set;} //Asset(Productos Adicionales) relacionado a la billing Account
        public Case Caso{get;set;} //Caso Generado
        public Order Orden{get;set;} //Orden Generada
        public List<Case> CasosExistentes{get;set;} //Lista de Casos existentes relacionados al Asset
        
        //Validaciones iniciales
        public Boolean ValidacionesIniciales{get;set;} //Flag indica si las validaciones iniciales se cumplieron
        public String ValidacionesInicialesError{get;set;} // Mensaje de Error de validaciones iniciales.
        
        //Orden
        public Boolean StatusOrden{get;set;} //Flag indica si la orden se genero correctamente
        public String  StatusOrdenError{get;set;} // Mensaje de error en caso que la orden fallo
        
        //Caso
        public Boolean StatusCaso{get;set;} //Flag indica si el caso se creo correctamente
        public String  StatusCasoError{get;set;} // Mensaje de error
        public String  StatusValueCaso{get;set;} // lleva el valor del estado para la creacion del caso
        public String  SubStatusValueCaso{get;set;} //lleva el valor del subestado del caso
        
        public WGestionMasiva (PVU_Gestiones_Masivas__c gestionMasiva){
            
            this.BillingAccountNumber = gestionMasiva.PVU_CustNum__c;
            this.GestionMasiva = gestionMasiva;
            this.StatusValueCaso = 'En curso';
            this.SubStatusValueCaso = 'Pendiente ejecución';

            
            //por defecto pasa validaciones iniciales
            this.ValidacionesIniciales = true;
            this.GestionMasiva.PVU_Message__c = 'Pasa validaciones Iniciales';
            
            this.mapAssetToOrderMTD = new Map<String, PVU_AssetToOrderCodigos__mdt>();
            this.StandardOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
    		this.posventaRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('GestionCasosPosventa').getRecordTypeId();
        }
        
        public void setError(String validation_type, Boolean status, String msj){
            switch on validation_type {
                when 'ValidacionesIniciales' {
                    this.ValidacionesIniciales = status;
                    this.ValidacionesInicialesError = msj;
                    this.GestionMasiva.PVU_Status__c = status == false ? 'Error' : '';
                    this.GestionMasiva.PVU_Message__c = msj;
                }
                when 'StatusOrden' {
                    this.StatusOrden = status;
                    this.StatusOrdenError = msj;
                    this.GestionMasiva.PVU_Status__c  = status ==  false ? 'Error' : 'Orden creada';
                    this.GestionMasiva.PVU_Message__c = msj;
                }
                when 'StatusCaso' {
                    this.StatusCaso = status;
                    this.StatusCasoError = msj;
                    this.GestionMasiva.PVU_Status__c = status == false ? 'Error' : 'Caso creado ';
                    this.GestionMasiva.PVU_Message__c = msj;
                }
                when 'StatusInProgress' {
                    //this.StatusCaso = '';
                    //this.StatusCasoError = msj;
                    this.GestionMasiva.PVU_Status__c = 'En Proceso';
                    this.GestionMasiva.PVU_Message__c = msj;
                }
                when 'ValidCreateCaseAndOrder'{
                    this.StatusCaso = status;
                    this.StatusCasoError = msj;
                    this.GestionMasiva.PVU_Status__c = status == false ? 'Error' : 'Exitoso ';
                    this.GestionMasiva.PVU_Message__c = msj;
                }
            }
        }
    }
    
    /**
* =============================================================================================================================
* ===========================================       INIT PROCESS         ======================================================
* =============================================================================================================================
*/
    
    /**
    * Método principal para procesar las gestiones masivas.
    * - Agrupa las gestiones por BillingAccount.
    * - Consulta los activos asociados a las gestiones.
    * - Crea y valida casos para cada gestión masiva.
    * - Crea órdenes de suspensión y las actualiza si es necesario.
    * @param Gestion Masiva a procesar.
    */
    public void assetService(PVU_Gestiones_Masivas__c gmasiva) {
        //init wrapper variable
        WGestionMasiva WGestionMasiva = new WGestionMasiva(gmasiva);
        
        //consulta metadatas
        setAssetToOrderMtd(WGestionMasiva);
        
        //Consulta y establece los assets
        queryAssets(WGestionMasiva);
        
        //Consulta Casos existentes
        WGestionMasiva.CasosExistentes = WGestionMasiva.Asset != null ? getExistingCases(WGestionMasiva.Asset.Id, WGestionMasiva.GestionMasiva) : null;
        
        //creacion de Orden y caso
        if (WGestionMasiva.Asset != null) {
            //Validaciones Iniciales
            ValidacionesIniciales(WGestionMasiva);
            
            Map<String, Boolean> responseMap = validCreateOrderwhitCase(WGestionMasiva);
            if(WGestionMasiva.ValidacionesIniciales && responseMap.get('createOrder') == false && responseMap.get('createCase') == true){
                //crear caso
              createCase(WGestionMasiva);
            }
            //Si pasan las validaciones iniciales
            if(WGestionMasiva.ValidacionesIniciales && responseMap.get('createOrder') == true ){
                if(WGestionMasiva.GestionMasiva.PVU_Action__c != 'DEACTIVATE_SA' && WGestionMasiva.GestionMasiva.PVU_Action__c != 'DEACTIVATE_TC' && WGestionMasiva.GestionMasiva.PVU_Action__c != 'DEACTIVATE_NETFLIXSA40'){//Syncrono
                    //Crear Orden
                    createOrder(WGestionMasiva);
                    
                    if(WGestionMasiva.StatusOrden){
                        //crear caso
                        createCase(WGestionMasiva);
                        
                        //Update and checkout(Queuable) Orden
                        updateOrder(WGestionMasiva);
                    }  
                }else{//Asyncrono
                    System.enqueueJob(new PVU_GestionesMasivas_Queueable('procesarOrdenYCaso', WGestionMasiva));
                    WGestionMasiva.setError('StatusInProgress', false, 'Gestion en Proceso.');
                }
            }
            
            if(WGestionMasiva.ValidacionesIniciales && responseMap.get('createMarca') == true){
                aplicarMarca(WGestionMasiva);
            }
        } else { //AssetPlan No encontrado
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Billing Account no encontrado.'); 
        }
        
        //Actualizacion status del proceso
        updateRecordGestionMasiva(WGestionMasiva);
    }
    
    /**
    * =================================================================================================================================
    * ===========================================       FUNCIONES HELPERS        ======================================================
    * =================================================================================================================================
    */
    
    /**
    * Realiza una consulta a la base de datos para obtener los activos relacionados con los Billing Account IDs proporcionados.
    * @param billingAccountIds Conjunto de Billing Account IDs.
    * @return Mapa de Billing Account ID y el activo asociado.
    */
    private void queryAssets(WGestionMasiva WGestionMasiva) {
        Map<String, Asset> mapAssetsRoot = new Map<String, Asset>();
        Map<String, Asset> mapAssetsPlan = new Map<String, Asset>();
        Map<String, Asset> mapAssetsFunc = new Map<String, Asset>();
        Map<String, Asset> mapAssetsAdicionales = new Map<String, Asset>();
        for(Asset asset : [SELECT Id, Name, Status, 
                           vlocity_cmt__ParentItemId__c, 
                           vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, 
                           vlocity_cmt__SubscriptionId__c,
                           vlocity_cmt__SubscriptionId__r.OM_SusByCollectionsFlag__c,
                           vlocity_cmt__SubscriptionId__r.OM_MSISDN__c,
                           vlocity_cmt__AssetReferenceId__c,
                           Account.FVU_AccountExternalID__c,
                           vlocity_cmt__ServiceAccountId__c,
                           vlocity_cmt__BillingAccountId__c,
                           vlocity_cmt__SubscriptionId__r.OM_SubStatus__c,
                           Product2.vlocity_cmt__Type__c,
                           Product2.ProductCode,
                           AccountId,
                           vlocity_cmt__ReliesOnItemId__c,
                           vlocity_cmt__AttributeSelectedValues__c,
                           vlocity_cmt__SubscriptionId__r.OM_PortationStatus__c
                           FROM Asset 
                           WHERE vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c =: WGestionMasiva.BillingAccountNumber
                           WITH SYSTEM_MODE])
        {
            if(mapAssetsRoot.get(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c) == null && asset.Product2.vlocity_cmt__Type__c == 'Plan' && asset.vlocity_cmt__ParentItemId__c == null ){
                mapAssetsRoot.put(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, asset);
            }
            
            if(mapAssetsPlan.get(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c) == null && asset.Product2.vlocity_cmt__Type__c == 'Plan' && asset.vlocity_cmt__ParentItemId__c != null ){
                mapAssetsPlan.put(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, asset);
            }
            
            if(mapAssetsFunc.get(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c) == null && asset.Product2.ProductCode == 'B2C-MOB-POST-FUNC-y-BLOQ-PS' ){
                mapAssetsFunc.put(asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, asset);
            }
            
            if(mapAssetsAdicionales.get(asset.Product2.ProductCode) == null && asset.vlocity_cmt__ParentItemId__c == null && asset.vlocity_cmt__ReliesOnItemId__c != null && asset.Status == 'Active' ){
               mapAssetsAdicionales.put(asset.Product2.ProductCode, asset); 
            }
        }
        
        WGestionMasiva.Asset = mapAssetsRoot.get(WGestionMasiva.BillingAccountNumber);
        WGestionMasiva.AssetPlan = mapAssetsPlan.get(WGestionMasiva.BillingAccountNumber);
        WGestionMasiva.AssetFuncionalidades = mapAssetsFunc.get(WGestionMasiva.BillingAccountNumber);
        WGestionMasiva.MapAssetAdicionales = mapAssetsAdicionales;
    }
    
    /**
    * Obtiene un mapa de los casos existentes filtrados por ciertos criterios.
    * @return Mapa de Asset ID a lista de casos existentes asociados.
    */
    private List<Case> getExistingCases(Id assetId, PVU_Gestiones_Masivas__c WGestionMasiva) {
        //por si la voz cambia con respecto al origen de la gestion
        // String vozCliente =  WGestionMasiva.PVU_Source__c == 'COLLECTIONS' ? 'Proceso Cobranza' : '';
        
        String vozCliente;
        if(WGestionMasiva.PVU_ReasonId__c == '38' || WGestionMasiva.PVU_ReasonId__c == '165' ||
           WGestionMasiva.PVU_ReasonId__c == '266' || WGestionMasiva.PVU_ReasonId__c == '96' ||
           WGestionMasiva.PVU_Motivo__c == 'FRAU01'){
               vozCliente = 'Proceso Prevención Fraude';
           }
        else if(WGestionMasiva.PVU_ReasonId__c == '226' || WGestionMasiva.PVU_ReasonId__c == '261' || 
                WGestionMasiva.PVU_ReasonId__c == '206' || WGestionMasiva.PVU_ReasonId__c == '184' ||
                WGestionMasiva.PVU_Motivo__c == 'GPT01'){
                    vozCliente = 'Proceso Gpt';
                }
        else if(WGestionMasiva.PVU_Source__c == 'TODO_CLARO'){
            vozCliente = 'Beneficio Todo Claro';
        }
        else{
            vozCliente = 'Proceso Cobranza';
        }
        
        Map<Id, List<Case>> existingCaseMap = new Map<Id, List<Case>>();
        for (Case existingCase : [SELECT Id, AssetId, Asset.Status, Status, PVU_Order__r.Type, PVU_Order__c, PVU_Order__r.PVU_SuspensionLevel__c 
                                  FROM Case 
                                  WHERE PVU_Level3__c =:vozCliente AND AssetId =:assetId WITH SYSTEM_MODE]) 
        {
            
            if (!existingCaseMap.containsKey(existingCase.AssetId)) {
                existingCaseMap.put(existingCase.AssetId, new List<Case>());
            }
            
            existingCaseMap.get(existingCase.AssetId).add(existingCase);
        }
        
        return existingCaseMap.size() > 0 ? existingCaseMap.get(assetId) : null;
    }
    
    /**
    * Valida y procesa cada caso de gestión masiva.
    * - Comprueba si el activo ya tiene un caso existente.
    * - Si el caso es duplicado o inválido, lo marca con un mensaje de error.
    * @param WGestionMasiva gestion masiva procesada
    */
    private void ValidacionesIniciales(WGestionMasiva WGestionMasiva) {
        Boolean hasRecord = false;
        if (WGestionMasiva.CasosExistentes != null && !WGestionMasiva.CasosExistentes.isEmpty()) {
            for (Case existingCase : WGestionMasiva.CasosExistentes) {
                if (existingCase.Status == 'Abierto' || existingCase.Status == 'En curso') {
                    hasRecord = true;
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Caso abierto o en curso para este activo.'); 
                } 
            }
            //Si existen casos pero no tienen un estado Abierto o En curso, procede a las validaciones.
            if(hasRecord == false){
                processCaseValidation(WGestionMasiva);
            }
        }else{ //si no existen casos creados, procedemos directo a las validaciones.
            processCaseValidation(WGestionMasiva);
        }
    }
    
    // Procesar validación de un caso cerrado
    public void processCaseValidation(WGestionMasiva WGestionMasiva) {
        
        Boolean isActionSuspension = WGestionMasiva.GestionMasiva.PVU_Action__c == 'SUSPENSION';
        Boolean isActionDeactivation = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATION';
        Boolean isActionReactivation = WGestionMasiva.GestionMasiva.PVU_Action__c == 'REACTIVATION';
        Boolean isActionCancelacion = WGestionMasiva.GestionMasiva.PVU_Action__c == 'CANCELACION';
        Boolean isActionReinstalation = WGestionMasiva.GestionMasiva.PVU_Action__c == 'REINSTALATION';
        Boolean isActionActivateFunc = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_FUNC';
        Boolean isActionDeactivateFunc = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_FUNC';
        Boolean isActionActivateSA = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_SA';
        Boolean isActionDeactivateSA = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_SA';
        Boolean isActionActivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_ROAMING';
        Boolean isActionDeactivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_ROAMING';
        Boolean isActionActivateCastigo = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CASTIGO';
        Boolean isActionDeactivateCastigo = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CASTIGO';
        Boolean isActionActivateCCV = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CCV';
        Boolean isActionDeactivateCCV = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CCV';
        Boolean isActionActivateTC = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_TC';
        Boolean isActionDeactivateTC = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_TC';
        Boolean isAssetSuspended = WGestionMasiva.Asset.Status == 'Suspended';
        Boolean isAssetActive = WGestionMasiva.Asset.Status == 'Active';
        Boolean isAssetDeactivated = WGestionMasiva.Asset.Status == 'Deactivated';
        Boolean isDesactivationCollectionsSubStatus = WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == 'Desactivación por Collections';
        Boolean isAssetSuspendedByCollections = isAssetSuspended && (WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == 'Parcial Mora' || WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == 'Total Mora');
        Boolean isActionDeactivateNETFLIXSA40 = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_NETFLIXSA40';
        
        // ------------------------------------------ Chequeo de escenarios sin reasonId ---------------------------------------------------------------       
        if((!(isActionActivateFunc || isActionDeactivateFunc || isActionActivateSA || isActionDeactivateSA || isActionActivateRoaming || isActionDeactivateRoaming || isActionActivateCastigo || isActionDeactivateCastigo || isActionActivateCCV || isActionDeactivateCCV || isActionActivateTC || isActionDeactivateTC || isActionDeactivateNETFLIXSA40))){
            
            if(WGestionMasiva.GestionMasiva.PVU_ReasonId__c == null){ 
                WGestionMasiva.setError('ValidacionesIniciales', false, 'El reasonId debe contener un valor válido');
                return;
            }
            
            // ------------------------------------------ Chequeo de datos respecto a la metadata de assetToOrder ------------------------------------------
            if(getMetadata(WGestionMasiva) == null){
                WGestionMasiva.setError('ValidacionesIniciales', false, 'Metadata no encontrada - Reason code incorrecto para este origen y action'); 
                return;
            }
        }
        
        // ------------------------------------------ Chequeo de msisdn y motivo ---------------------------------------------------------------       
        if((isActionActivateFunc || isActionDeactivateFunc || isActionActivateSA || isActionDeactivateSA || isActionActivateRoaming || isActionDeactivateRoaming) && 
           (WGestionMasiva.GestionMasiva.PVU_MSISDN__c == null || WGestionMasiva.GestionMasiva.PVU_Motivo__c == null)){
               WGestionMasiva.setError('ValidacionesIniciales', false, 'El MSIDSN y el motivo deben contener un valor válido');
               return;
           }
        if(isActionDeactivateNETFLIXSA40 && WGestionMasiva.GestionMasiva.PVU_MSISDN__c == null){
               WGestionMasiva.setError('ValidacionesIniciales', false, 'El MSIDSN debe contener un valor válido');
               return;
           }
        // ------------------------------------------ Chequeo de datos de Acciones Masivas ---------------------------------------------------------------       
        if(isActionActivateCastigo || isActionDeactivateCastigo || isActionActivateCCV || isActionDeactivateCCV){
            if(WGestionMasiva.GestionMasiva.PVU_Marca__c == null){
                WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - la marca es obligatoria para este proceso');  
            }
            if((isActionActivateCCV || isActionDeactivateCCV) && (WGestionMasiva.GestionMasiva.PVU_NombreCompradorCartera__c == null || WGestionMasiva.GestionMasiva.PVU_TelefonoComprador__c == null || WGestionMasiva.GestionMasiva.PVU_DireccionComprador__c == null)){
                WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - faltan uno o mas campos obligatorios');  
            }
        }
        
        switch on WGestionMasiva.GestionMasiva.PVU_Source__c {
            when 'COLLECTIONS' {
                // ------------------------------------------ Evaluacion de escenarios ------------------------------------------
                Boolean isSameSuspensionLevel = WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SusByCollectionsFlag__c == WGestionMasiva.GestionMasiva.PVU_SuspensionLevel__c;
                Boolean isAssetNotSuspendedValidation = (!isAssetSuspended && isActionSuspension) || ( isAssetSuspended && !isActionSuspension);
                Boolean isValidSuspensionLevel = !isSameSuspensionLevel;
                Boolean isSuspendedAndSameSuspensionLevel = isAssetSuspended && isActionSuspension && isSameSuspensionLevel;
                Boolean isBlankSuspensionLevel = WGestionMasiva.GestionMasiva.PVU_SuspensionLevel__c == null || WGestionMasiva.GestionMasiva.PVU_SuspensionLevel__c == '';
                
                if(isBlankSuspensionLevel && isActionSuspension){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'En una suspension el suspensionLevel no puede estar vacio'); 
                }
                else if(isActionReactivation && isAssetActive){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'El asset no debe estar activo en una reconexión');
                }
                else if(isSuspendedAndSameSuspensionLevel){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'El asset esta suspendido y suspensionlevel de la gestión es el mismo que el del asset'); 
                }
                else if (isActionDeactivation && !(isAssetSuspended && WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SusByCollectionsFlag__c == '2')){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Para deactivación el asset debe estar suspendido en nivel 2'); 
                }
                else if(isActionReinstalation){
                    if(!isAssetDeactivated){
                        WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset debe estar desactivado');
                    }
                    else if(!isDesactivationCollectionsSubStatus){ 
                        WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset no tiene el subestado correcto');
                    } else {
                        Boolean validService = getValidService(WGestionMasiva);
                    }
                }
                else if(isActionActivateCastigo || isActionDeactivateCastigo || isActionActivateCCV || isActionDeactivateCCV){
                    if(!isAssetDeactivated){
                        WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset debe estar desactivado');  
                    }
                    else if(WGestionMasiva.GestionMasiva.PVU_Marca__c == 'Cartera castigada vendida'){
                        if(!getCasesAccionesMasivas(WGestionMasiva)){
                            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - no existen casos previos de Castigo o Cartera castigada vendida');  
                        }
                    }
                }
                else if (!(isAssetNotSuspendedValidation || (isAssetSuspended && isValidSuspensionLevel)) && !isActionReactivation){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada'); 
                }
                else if (isActionSuspension && isAssetDeactivated){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'El Asset no puede estar Desactivado para esta operación.'); 
                }
                else if (isActionSuspension && isAssetSuspended && !isAssetSuspendedByCollections){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'El Asset esta suspendido por otro subcausal diferente a (Parcial Mora y/o Total Mora).'); 
                }
                
            }
            when 'TODO_CLARO' {
                Boolean isTCActive = isTodoClaroActiveForAsset(WGestionMasiva);
                if(isActionActivateTC && isTCActive){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el beneficio Todo Claro ya esta activo para el asset');  
                }
                else if(isActionDeactivateTC && !isTCActive){ 
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el beneficio Todo Claro esta inactivo para el asset');  
                }
            }
            when else {
                // Para fraude com y gpt
                // ------------------------------------------ Evaluacion de escenarios ------------------------------------------
                
                if(isActionSuspension && isAssetActive){
                    cancelQueuedOrders(WGestionMasiva);
                }
                else if(isActionSuspension && !isAssetActive){
                    if(isAssetSuspended){
                        Boolean isInvalidSubCausal = getInvalidsubCausalSuspensionfraudeGpt(WGestionMasiva);
                        if(isInvalidSubCausal){
                            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset esta suspendido por un subCausal incompatible con esta operación');
                        }
                    }else{
                        WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset no esta activo');  
                    }
                    
                }
                else if(isActionDeactivation && isAssetDeactivated){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset no debe estar desactivado');
                }
                else if(isActionReactivation && !isAssetSuspended){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset debe estar suspendido');
                }
                else if(isActionReactivation && isAssetSuspended){
                    Boolean isValidMotivoSubCausal = getValidMotivovsSubCausal(WGestionMasiva);
                    if(!isValidMotivoSubCausal){
                        WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el subStatus del Asset no coincide con el motivo');
                    }
                }
                else if(isActionReinstalation && isAssetDeactivated){
                    System.debug('saras'+ isAssetDeactivated);
                    if( getValidService(WGestionMasiva)){
                        Boolean isValidSubCausal = getValidSubCausalOfAsset(WGestionMasiva);
                        if(!isValidSubCausal){
                            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el subStatus del Asset no coincide con el SubCausal');
                        }
                    }
                }
                else if(isActionReinstalation && !isAssetDeactivated){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset debe estar desactivado');  
                }
                else if( (isActionActivateFunc || isActionDeactivateFunc || isActionActivateSA || isActionDeactivateSA || isActionActivateRoaming || isActionDeactivateRoaming || isActionDeactivateNETFLIXSA40) && !isAssetActive){
                    WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada - el Asset no esta activo'); 
                }
            }
        }
    }
    
    /**
    * Método para obtener la metadata con las posibles configuraciones Motivo - SubCausal en las validaciones.
    * 
    */
    public Boolean getValidMotivovsSubCausal(WGestionMasiva WGestionMasiva) {
        Boolean isValidMotivoSubCausal = false;
        for (PVU_GestionesMasivasMotivovsSubCausal__mdt mdt : [select Id, PVU_Motivo__c, PVU_SubCausal__c from PVU_GestionesMasivasMotivovsSubCausal__mdt WITH SYSTEM_MODE]) {   
            if( (WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == mdt.PVU_SubCausal__c) && 
               (WGestionMasiva.GestionMasiva.PVU_Motivo__c == mdt.PVU_Motivo__c) ){
                   isValidMotivoSubCausal = true;
               }
        }
        return isValidMotivoSubCausal;
    }
    /**
    * Método para obtener la metadata con las posibles configuraciones  SubCausal de un Asset.
    * 
    */
    public Boolean getValidSubCausalOfAsset(WGestionMasiva WGestionMasiva) {
        Boolean isValidSubCausal = false;
        for (PVU_GestionesMasivasMotivovsSubCausal__mdt mdt : [select Id, PVU_SubCausal__c from PVU_GestionesMasivasMotivovsSubCausal__mdt where PVU_Motivo__c = null WITH SYSTEM_MODE]) {   
            if( (WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == mdt.PVU_SubCausal__c) ){
                isValidSubCausal = true;
            }
        }
        return isValidSubCausal;
    }
    
    /**
    * Método para obtener la metadata con las configuraciones invalidas - SubCausal en las validaciones del action SUSPENSION por fraude o gpt.
    * 
    */
    public Boolean getInvalidsubCausalSuspensionfraudeGpt(WGestionMasiva WGestionMasiva) {
        Boolean isInvalidSubCausal = false;
        for (PVU_GestionesMasivasMotivovsSubCausal__mdt mdt : [select Id, PVU_Motivo__c, PVU_SubCausal__c from PVU_GestionesMasivasMotivovsSubCausal__mdt where PVU_Motivo__c != null WITH SYSTEM_MODE]) {   
            if( (WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c == mdt.PVU_SubCausal__c)){
                   isInvalidSubCausal = true;
               }
        }
        return isInvalidSubCausal;
    }
    /**
    * Método para Validar si estuvo en cuarentena , si pertenece a claro
    * 
    */
    public Boolean getValidService(WGestionMasiva WGestionMasiva) {
        
        /* Initialize variables */
        String procedureName = 'PVU_ValidServicesReinstalation';
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();     
        
        String assetId = WGestionMasiva.Asset.Id;
        String requestType = 'subscritionNum';
        ipInput.put('AssetId', assetId);
        ipInput.put('requestType', requestType);         
        
        
        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
        
        System.debug('IP Output: ' + ipOutput);
        if(ipOutput.get('ValidIsFailServices') == true){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Fallo en la ejecución: uno o más servicios no respondieron correctamente');
            return false;
        }

        Boolean isValidCuarentine = !Test.isRunningTest() && ipOutput.get('ValidCuarentine') != null ? (Boolean)ipOutput.get('ValidCuarentine') : false;
        Boolean isValidDaysDesactived = !Test.isRunningTest() && ipOutput.get('ValidDaysDesactived') != null ? (Boolean)ipOutput.get('ValidDaysDesactived') : false;
        Boolean isValidPortability = !Test.isRunningTest() && ipOutput.get('ValidPortability') != null ? (Boolean)ipOutput.get('ValidPortability'):false;
        Boolean isValidMora = !Test.isRunningTest() && ipOutput.get('ValidMora') != null ? (Boolean) ipOutput.get('ValidMora'):false;
        Boolean validarOrdenRoboPerdida = !Test.isRunningTest() && ipOutput.get('validarOrdenRoboPerdida') != null ? (Boolean) ipOutput.get('validarOrdenRoboPerdida'):false;
        
        
        if(validarOrdenRoboPerdida == true ){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Existe una orden de suspension Robo_Perdida antes de Orden de Cancelación.');
            return false;
        }
        
        if(isValidCuarentine == true ){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada por no cumplir cuarentena');
            return false;
        }
        if(isValidDaysDesactived == true ){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada por estar desactivada superior a 90 dias');
            return false;
        }
        if(isValidPortability == true ){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada por estar desactivada y no pertecer a Claro mayor a 28 dias');
            return false;
        }
        if(isValidMora == true ){
            WGestionMasiva.setError('ValidacionesIniciales', false, 'Validación no aprobada por mora');
            return false;
        }
        
        
        
        return true;
    }
    
	/**
    * Método para chequear casos anteriores de acciones masivas
    * 
    */
    public Boolean getCasesAccionesMasivas(WGestionMasiva WGestionMasiva) {
        Boolean caseFounded = false;
        for(Case cases: [select id from Case where AssetId =: WGestionMasiva.Asset.Id and 
                         (PVU_TipoSolicitudMasivos__c = 'ACTIVATE_CASTIGO' OR PVU_TipoSolicitudMasivos__c = 'DEACTIVATE_CASTIGO' OR
                          PVU_TipoSolicitudMasivos__c = 'ACTIVATE_CCV' OR PVU_TipoSolicitudMasivos__c = 'DEACTIVATE_CCV') WITH USER_MODE]){
                              caseFounded = true;
                              break;
                          }
        return  caseFounded;
    }

    /**
    * Método para cancelar ordenes encoladas.
    * 
    */
    public List<Case> cancelQueuedOrders(WGestionMasiva WGestionMasiva) {
        
        List<Case> cases = [Select id,PVU_Order__c, CaseNumber, PVU_Level3__c from Case 
                            where AssetId =: WGestionMasiva.AssetPlan.Id AND (Status = 'Abierto' OR Status = 'En curso') 
                            AND PVU_Order__r.vlocity_cmt__OrderStatus__c = 'Queued' WITH SYSTEM_MODE];
        List<Case> casesToClose = new List<Case>();
        
        if (cases.size() > 0) {
            List<Order> ordersToCancel = new List<Order>();
            // obtener tipos de ordenes validas para cancelar
            Set<String> validOrderTypes = new Set<String>();
            Set<String> validOrderSubTypes = new Set<String>();
            for (PVU_GestionesMasivasPendingOrders__mdt mdt : [select Id, Type__c, SubType__c from PVU_GestionesMasivasPendingOrders__mdt WITH SYSTEM_MODE]) {
                validOrderTypes.add(mdt.Type__c);
                validOrderSubTypes.add(mdt.SubType__c);
            }
            
            Set<Id> orderIds = new Set<Id>();
            for (Case c : cases) {
                if (c.PVU_Order__c != null) {
                    orderIds.add(c.PVU_Order__c);
                }
            }
            
            Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Type, FVU_OrderSubType__c
                                                          FROM Order 
                                                          WHERE Id IN :orderIds WITH SYSTEM_MODE]);
            
            for(Case c:cases){
                Order relatedOrder = orderMap.get(c.PVU_Order__c);
                if (relatedOrder != null 
                    && validOrderTypes.contains(relatedOrder.Type) 
                    && validOrderSubTypes.contains(relatedOrder.FVU_OrderSubType__c)) {
                        
                        c.OM_Orden_Procesada__c = 'No Exitosa';
                        c.PVU_Observaciones__c = 'Orden cancelada por gestion masiva';
                        casesToClose.add(c);
                        ordersToCancel.add(new Order(Id = c.PVU_Order__c, vlocity_cmt__OrderStatus__c = 'Cancelled', Status = 'Closed'));
                    }
            }
            
            if (casesToClose.size() > 0) {
                update as system casesToClose;
            }
            
            if (ordersToCancel.size() > 0) {
                update as system ordersToCancel;
            }
        }
        
        return casesToClose;
    }

    /**
    * Método para chequear si el beneficio esta activo o no para el asset.
    * 
    */
    public Boolean isTodoClaroActiveForAsset(WGestionMasiva WGestionMasiva) {
        Boolean isTCActive = false;
        List<vlocity_cmt__AccountAppliedPromotionItem__c> tcList = [SELECT Id, vlocity_cmt__AssetId__c, vlocity_cmt__AssetId__r.Product2.Name, vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.Name,vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_Type__c 
                                                                    FROM vlocity_cmt__AccountAppliedPromotionItem__c 
                                                                    WHERE vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_Type__c = 'TodoClaro' 
                                                                    AND vlocity_cmt__AssetId__r.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c =: WGestionMasiva.GestionMasiva.PVU_CustNum__c
                                                                    AND vlocity_cmt__AssetId__r.Product2.vlocity_cmt__Type__c = 'Add On'
                                                                    WITH SYSTEM_MODE];
        
        if (tcList.size() > 0) {
            Asset assetStatus = [Select Id, Product2.Name, vlocity_cmt__SubscriptionId__r.OM_MSISDN__c, Status, vlocity_cmt__SubscriptionId__r.vlocity_cmt__Status__c 
                                        from Asset where Id =: tcList[0].vlocity_cmt__AssetId__c WITH SYSTEM_MODE];
            if(assetStatus.Status == 'Active'){
                isTCActive = true;
            }
        }
        return isTCActive;
    }

    public static Map<String,Boolean> validCreateOrderwhitCase (WGestionMasiva WGestionMasiva){
        
        String accountExtenalId = WGestionMasiva.GestionMasiva.PVU_CustNum__c;
        system.debug('accountExtenalId: '+accountExtenalId);
        String key = WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c !=null ? WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c : '';
        system.debug('key: '+key);
        Boolean isActionActivateFunc = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_FUNC';
        Boolean isActionDeactivateFunc = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_FUNC';
        Boolean isActionActivateSA = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_SA';
        Boolean isActionDeactivateSA = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_SA';
        Boolean isActionActivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_ROAMING';
        Boolean isActionDeactivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_ROAMING';
        Boolean isActionDeactivateNETFLIXSA40 = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_NETFLIXSA40';
        String  keyRoaming = 'B2C-ATTR-ROAMING';
        Map<String, Boolean> response = new Map<String, Boolean>();
        response.put('createOrder',true);
        response.put('createCase',true);
        response.put('createMarca', false);
        
        if (isActionActivateFunc || isActionDeactivateFunc) {
            try {
                Asset  queryAsset = WGestionMasiva.AssetFuncionalidades;
                
                String jsonAttribute = queryAsset.vlocity_cmt__AttributeSelectedValues__c;
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonAttribute);
                if (jsonMap.containsKey(key)) {
                    if(WGestionMasiva.GestionMasiva.PVU_Motivo__c == 'FRA01'){
                        if(jsonMap.get(key) == false  && isActionDeactivateFunc){
                            response.put('createOrder', false);
                            WGestionMasiva.StatusValueCaso = 'Cerrado';
                            WGestionMasiva.SubStatusValueCaso = '-';
                        }
                        if(jsonMap.get(key) == true  && isActionActivateFunc){
                            response.put('createOrder', false);
                            response.put('createCase', false);
                            WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó caso ni orden');
                        }
                    }
                    if(WGestionMasiva.GestionMasiva.PVU_Motivo__c == 'GPT01'){
                        if(jsonMap.get(key) == true  && isActionActivateFunc ){
                            response.put('createOrder', false);
                            WGestionMasiva.StatusValueCaso = 'Cerrado';
                            WGestionMasiva.SubStatusValueCaso = '-';
                            
                        }
                        if(jsonMap.get(key) == false  && isActionDeactivateFunc){
                            response.put('createCase', false);
                            response.put('createOrder', false);
                            WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó caso ni orden');
                        }
                    }}
                else {
                    WGestionMasiva.setError('ValidCreateCaseAndOrder', false, 'No se encontro la clave de la funcionalidad');
                    response.put('createOrder', false);
                    response.put('createCase', false);
                }
                
            } catch (QueryException e) {
                System.debug('No se encontró ningún registro: ' + e.getMessage());
            }
        } else {
            if (isActionActivateSA || isActionDeactivateSA) {
                
                //Integer haveServiceAdd = [SELECT COUNT() FROM Asset WHERE  vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c=:accountExtenalId AND Product2.ProductCode  =: key AND Status='Active' WITH SYSTEM_MODE LIMIT 1]; 
                Integer haveServiceAdd = WGestionMasiva.MapAssetAdicionales.get(key) != null && WGestionMasiva.MapAssetAdicionales.get(key).Status == 'Active'  ? 1 : 0; 
                if(haveServiceAdd == 0 && isActionDeactivateSA){
                    response.put('createOrder', false);
                    WGestionMasiva.StatusValueCaso = 'Cerrado';
                    WGestionMasiva.SubStatusValueCaso = '-';
                    WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó orden - Producto adicional a desactivar no encontrado.');
                    
                }
                if(haveServiceAdd >= 1 && isActionActivateSA){
                    response.put('createCase', false);
                    response.put('createOrder', false);
                    WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó caso ni orden');
                }
                
            } else {
                if (isActionActivateRoaming || isActionDeactivateRoaming) {
                    try {
                        
                        Asset  queryAsset = WGestionMasiva.AssetPlan; 
                        String jsonAttribute = queryAsset.vlocity_cmt__AttributeSelectedValues__c;
                        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonAttribute);
                        system.debug('valueKey'+jsonMap.get(keyRoaming));
                        if (jsonMap.containsKey(keyRoaming)) {
                            if(jsonMap.get(keyRoaming) == false && isActionDeactivateRoaming){
                                response.put('createOrder', false);
                                WGestionMasiva.StatusValueCaso = 'Cerrado';
                                WGestionMasiva.SubStatusValueCaso = '-';
                                
                            }
                            if(jsonMap.get(keyRoaming) == true && isActionActivateRoaming){
                                response.put('createOrder', false);
                                response.put('createCase', false);
                                WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó caso ni orden');
                            }}
                        else {
                            WGestionMasiva.setError('ValidCreateCaseAndOrder', false, 'No se encontro la clave del roaming');
                            response.put('createOrder', false);
                            response.put('createCase', false);
                        }
                    } 
                    catch (QueryException e) {
                        System.debug('No se encontró ningún registro: ' + e.getMessage());
                    }
                } else {
                    if (isActionDeactivateNETFLIXSA40) {
                        
                        Integer haveServiceAdd = WGestionMasiva.MapAssetAdicionales.get(key) != null && WGestionMasiva.MapAssetAdicionales.get(key).Status == 'Active'  ? 1 : 0; 
                        if(haveServiceAdd == 0 && isActionDeactivateNETFLIXSA40){
                            response.put('createOrder', false);
                            WGestionMasiva.StatusValueCaso = 'Cerrado';
                            WGestionMasiva.SubStatusValueCaso = '-';
                            WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'No se generó orden - Producto adicional a desactivar no encontrado.');
                        }                      
                    }
                }
            } 
        }
        
        //Adding 541693
        if(WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CCV' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CCV'){
            response.put('createOrder', false);
            response.put('createMarca', true);
        }
        return response;
    }
    
    /**
    * Método para procesar un nuevo caso de proceso cobranza.
    * @param assetMatch Activo correspondiente.
    */
    public void createCase(WGestionMasiva WGestionMasiva) {
        Case newCase = new Case();
        Boolean isActionActivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_ROAMING';
        Boolean isActionDeactivateRoaming = WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_ROAMING';
        newCase.RecordTypeId = WGestionMasiva.posventaRT;
        newCase.AssetId = WGestionMasiva.Asset.Id;
        newCase.AccountId = WGestionMasiva.Asset.AccountId;
        newCase.Status = WGestionMasiva.StatusValueCaso;
        newCase.PVU_Sub_Estado__c = WGestionMasiva.SubStatusValueCaso;
        newCase.vlocity_cmt__BillingAccountId__c = WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c;
        newCase.PVU_Order__c = (WGestionMasiva.Orden != null)? WGestionMasiva.Orden.Id : null; 
        newCase.Descripcion__c = WGestionMasiva.GestionMasiva.Id;
        newCase.Description = WGestionMasiva.GestionMasiva.PVU_Description__c;
        newCase.PVU_TipoSolicitudMasivos__c = WGestionMasiva.GestionMasiva.PVU_Action__c;
        newCase.PVU_NumeroLinea__c = WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_MSISDN__c;
        newCase.PVU_NombreCompradorCartera__c = WGestionMasiva.GestionMasiva.PVU_NombreCompradorCartera__c;
        newCase.PVU_ContractId__c = WGestionMasiva.GestionMasiva.PVU_ContractId__c;
        newCase.PVU_TelefonoComprador__c = WGestionMasiva.GestionMasiva.PVU_TelefonoComprador__c;
        newCase.PVU_DireccionComprador__c = WGestionMasiva.GestionMasiva.PVU_DireccionComprador__c;
        newCase.PVU_PaginaWeb__c = WGestionMasiva.GestionMasiva.PVU_PaginaWeb__c;
        newCase.PVU_CorreoElectronico__c = WGestionMasiva.GestionMasiva.PVU_CorreoElectronico__c;
        newCase.PVU_Saldo__c = WGestionMasiva.GestionMasiva.PVU_Saldo__c;
        newCase.PVU_ObligacionNo__c = WGestionMasiva.GestionMasiva.PVU_ObligacionNo__c;
        newCase.PVU_Producto__c = WGestionMasiva.GestionMasiva.PVU_Producto__c;
        newCase.PVU_CiudadComprador__c = WGestionMasiva.GestionMasiva.PVU_CiudadComprador__c;
        newCase.PVU_FechaVentaCartera__c = WGestionMasiva.GestionMasiva.PVU_FechaVentaCartera__c;
        newCase.PVU_Nit_Establecimiento_Venta__c  = WGestionMasiva.GestionMasiva.PVU_Nit__c;
        if(WGestionMasiva.StatusValueCaso == 'Cerrado'){
            newCase.PVU_Codigo_de_Cierre__c = '-';
        }
        if(WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '226' || WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '261' || 
           WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '206' || WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '184' ){
               newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
               newCase.PVU_Level2__c = 'Control GPT';
               newCase.PVU_Level3__c = 'Proceso Gpt';
           }
        else if(WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '38' || WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '165' ||
                WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '266' || WGestionMasiva.GestionMasiva.PVU_ReasonId__c == '96' ){
                    newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
                    newCase.PVU_Level2__c = 'Control Prevención Fraude';
                    newCase.PVU_Level3__c = 'Proceso Prevención Fraude';
                }
        else if( WGestionMasiva.GestionMasiva.PVU_Motivo__c == 'GPT01'){
            newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
            newCase.PVU_Level2__c = 'Control GPT';
            newCase.PVU_Level3__c = 'Proceso Gpt';
            if (!String.isBlank(WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c)) {
                newCase.PVU_FeaturesOrServices__c =  WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c;
            }
            if(isActionActivateRoaming || isActionDeactivateRoaming) {
                newCase.PVU_FeaturesOrServices__c =  'B2C-ATTR-ROAMING';
            }
         
            newCase.PVU_NumeroLinea__c =  WGestionMasiva.GestionMasiva.PVU_MSISDN__c;
        }
        else if(WGestionMasiva.GestionMasiva.PVU_Motivo__c == 'FRA01'){
            newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
            newCase.PVU_Level2__c = 'Control Prevención Fraude';
            newCase.PVU_Level3__c = 'Proceso Prevención Fraude';
            if (!String.isBlank(WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c)) {
                newCase.PVU_FeaturesOrServices__c =  WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c;
            }
            newCase.PVU_NumeroLinea__c =  WGestionMasiva.GestionMasiva.PVU_MSISDN__c;
        }
        else if(WGestionMasiva.GestionMasiva.PVU_Source__c == 'TODO_CLARO'){
            newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
            newCase.PVU_Level2__c = 'Activación/ desactivación Todo claro';
            newCase.PVU_Level3__c = 'Beneficio Todo Claro';
        }
        else if(WGestionMasiva.GestionMasiva.PVU_Source__c == 'NETFLIX40'){
            newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
            newCase.PVU_Level2__c = 'Activación/Desactivación Servicios Adicionales y Funcionalidades';
            newCase.PVU_Level3__c = 'Desactivación de servicios adicionales';
        	newCase.PVU_Causal__c = 'No cobro por 40 días consecutivos';
            Account caseAccount = [SELECT Id, FVU_DocumentNumber__c, FVU_DocumentType__c FROM Account WHERE Id = :newCase.AccountId LIMIT 1];
            newCase.PVU_NumeroDocCliente__c = caseAccount.FVU_DocumentNumber__c;
            newCase.PVU_TipoDocumento__c = caseAccount.FVU_DocumentType__c;
            newCase.PVU_FeaturesOrServices__c = WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c;
        }              
        else {
            newCase.PVU_Level1__c = 'Facturación y pagos';
            newCase.PVU_Level2__c = 'Pagos';
            newCase.PVU_Level3__c = 'Proceso Cobranza';
        }
        
        //----Adding HDU:541735----
        if(WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CCV' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CCV'){
            newCase.PVU_Marca__c = WGestionMasiva.GestionMasiva.PVU_Marca__c;
            newCase.Status = 'Cerrado';
            newCase.PVU_Codigo_de_Cierre__c = '-';
            newCase.PVU_Sub_Estado__c = '-';
        }
        if( WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CCV'){  
            //format convenio de pago field into json
            if(WGestionMasiva.GestionMasiva.PVU_ConvenioPago__c != null){
                try{
                    Map<String, String> mapConvenio = new Map<String, String>();
                    List<String> listConvenio = WGestionMasiva.GestionMasiva.PVU_ConvenioPago__c.split(';'); 
                    for(String item : listConvenio){
                        mapConvenio.put('pago', item);
                    }
                    string jsonstring = JSON.serialize(mapConvenio);
                    newCase.PVU_ConvenioPago__c = jsonstring;
                }catch(Exception ex){
                    system.debug('Error casting into json - PVU_ConvenioPago__c');
                }
            }
        }//-----End HDU:541735----
        
        try {
            System.debug('Caso: ' + newCase);
            insert as system newCase;
            
            //Caso exitoso
            WGestionMasiva.Caso = newCase;
            WGestionMasiva.GestionMasiva.PVU_CaseId__c = newCase.Id;
            
            //update status
            if(WGestionMasiva.StatusValueCaso == 'Cerrado'){
                WGestionMasiva.setError('ValidCreateCaseAndOrder', true, 'Caso Creado');
            }else{
                WGestionMasiva.setError('StatusCaso', true, ''); 
            }
            
        } catch (DmlException e) {
            //update status
            System.debug('Error al insertar Caso: ' + e.getMessage());
            WGestionMasiva.setError('StatusCaso', false, 'Error al generar caso - ' + e.getMessage()); 
        }
    }
    
    
    /**
    * Actualiza las gestiones masivas con la nueva información.
    * @param gmToUpdate Lista de gestiones masivas a actualizar.
    */
    public void updateRecordGestionMasiva(WGestionMasiva WGestionMasiva) {
        try {
            update WGestionMasiva.GestionMasiva;
        } catch (DmlException e) {
            System.debug('Error al actualizar registros: ' + e.getMessage());
        }
    }
    
    /**
    * Activa o desactiva marca de castigo
    * @param WGestionMasiva a procesar.
    */
    public void aplicarMarca(WGestionMasiva WGestionMasiva) {
        Account billingAccount = new Account(Id = WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c);
        try {
            if(WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'ACTIVATE_CCV'){
                billingAccount.PVU_Marca_Cobranza__c = WGestionMasiva.GestionMasiva.PVU_Marca__c;
            }else{
                if(WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CASTIGO' || WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATE_CCV'){
                    billingAccount.PVU_Marca_Cobranza__c = null;
                }
            }
            
            update as system billingAccount;
        } catch (DmlException e) {
            System.debug('Error al actualizar billing account con Marca: ' + e.getMessage());
        }
    }
    
    /**
    * =================================================================================================================================
    * ===========================================       FUNCIONES ORDENES        ======================================================
    * =================================================================================================================================
    */
        
    //Obtiene un mapa con toda la info de assetToOrder
    public void setAssetToOrderMtd(WGestionMasiva WGestionMasiva){
        //AssetToOrder metadata
        for(PVU_AssetToOrderCodigos__mdt mtd : [SELECT Id, DeveloperName, ordertype__c, cartconfiguration__c , cartoperations__c, subcausal__c, reasoncode__c, subtype__c, orderinitialstatus__c,  action__c, subaction__c, type__c 
                                                FROM PVU_AssetToOrderCodigos__mdt 
                                                WHERE DeveloperName LIKE '%MASS%' WITH USER_MODE])
        {
            if(WGestionMasiva.mapAssetToOrderMTD.get(mtd.DeveloperName) == null){
                WGestionMasiva.mapAssetToOrderMTD.put(mtd.DeveloperName, mtd);
            }
        }
    }
    
    //Obtiene la metadata en base a la gestion masiva a procesar
    public PVU_AssetToOrderCodigos__mdt getMetadata(WGestionMasiva WGestionMasiva){
        string mtdname = '';
        if( (WGestionMasiva.GestionMasiva.PVU_Action__c == 'SUSPENSION' && WGestionMasiva.GestionMasiva.PVU_Source__c == 'COLLECTIONS')){
            mtdname = 'MASS_' + WGestionMasiva.GestionMasiva.PVU_Source__c + '_' + WGestionMasiva.GestionMasiva.PVU_Action__c + '_' + WGestionMasiva.GestionMasiva.PVU_ReasonId__c + '_' + WGestionMasiva.GestionMasiva.PVU_SuspensionLevel__c;
        }else{
            if(WGestionMasiva.GestionMasiva.PVU_ReasonId__c != null){
                mtdname = 'MASS_' + WGestionMasiva.GestionMasiva.PVU_Source__c + '_' + WGestionMasiva.GestionMasiva.PVU_Action__c + '_' + WGestionMasiva.GestionMasiva.PVU_ReasonId__c;
            }else{
                mtdname = 'MASS_' + WGestionMasiva.GestionMasiva.PVU_Action__c;
            }
            
        }
        return WGestionMasiva.mapAssetToOrderMTD.get(mtdname);
    }
    
    /**
    * Se actualiza orden con la info del caso recien creado.
    * @param WGestionMasiva GestionMasiva.
    */
    public void updateOrder(WGestionMasiva WGestionMasiva) {
        
        //build case info
        PVU_AssetToOrderCodigos__mdt assetToOrdermtd = getMetadata(WGestionMasiva); 
        
        //build case info
        DateTime requestDateTime = DateTime.now();            
        String requestStartDateTimeString = string.valueOfGmt(requestDateTime);
        String requestEndDateTimeString = null;
        
        //Calculo de fecha fin
        if ( (WGestionMasiva.GestionMasiva.PVU_Source__c == 'FRAUDE_COM' || WGestionMasiva.GestionMasiva.PVU_Source__c == 'FRAUDE_GPT') && WGestionMasiva.GestionMasiva.PVU_Action__c == 'SUSPENSION') {
            try{
                Map<String, Object> mapDiasByReason =  (Map<String, Object>)JSON.deserializeUntyped(assetToOrdermtd.cartconfiguration__c);
                Integer dias = (Integer) mapDiasByReason.get('DiasOrdenFuturaByReasonCode'); 
                DateTime requestEndDateTime = DateTime.now().addDays(dias);
                requestEndDateTimeString = string.valueOfGmt(requestEndDateTime);
            }catch(Exception ex){
                //update status
                WGestionMasiva.setError('StatusOrden', false, 'Error al obtener datos para orden futura - Reason code incorrecto para este origen y action'); 
                return;
            }
            
        }
        
        //build case info
        Map<String,Object> caseInfo = new Map<String,Object>();
        if(requestEndDateTimeString != null){
            caseInfo = new Map<String, String> { 'Id' => WGestionMasiva.Caso.Id, 'fechaInicioSusp' => requestStartDateTimeString,'fechaFinSusp' => requestEndDateTimeString};
                }else{
                    caseInfo = new Map<String, String> { 'Id' => WGestionMasiva.Caso.Id, 'fechaInicioSusp' => requestStartDateTimeString};
                        }  
        
        //Adding #586055 fecha de cancelacion parcial en el caseInfo de la orden
        if(WGestionMasiva.GestionMasiva.PVU_Action__c == 'DEACTIVATION'){
            try{
                Map<String, String> diasCancParcialMTD = new Map<String, String> ();
                for(InterfaceSettings__mdt mtd : [SELECT Id, DeveloperName,  Identificador__c, IdCode__c FROM InterfaceSettings__mdt  where DeveloperName  IN ('PVU_DiasCancelacionParcialNumeroClaro', 'PVU_DiasCancelacionParcialNumeroNoClaro') WITH USER_MODE])
                {
                    diasCancParcialMTD.put(mtd.DeveloperName, mtd.IdCode__c);
                } 
                DateTime fechaFinCanc = requestDateTime;
                if(WGestionMasiva.Asset.vlocity_cmt__SubscriptionId__r.OM_PortationStatus__c == '0'){ //numero de claro
                    fechaFinCanc = fechaFinCanc.adddays(Integer.valueOf(diasCancParcialMTD.get('PVU_DiasCancelacionParcialNumeroClaro')));
                }else{
                    fechaFinCanc = fechaFinCanc.adddays(Integer.valueOf(diasCancParcialMTD.get('PVU_DiasCancelacionParcialNumeroNoClaro')));        
                }
                caseInfo.put('fechaFinCanc', string.valueOfGmt(fechaFinCanc));
            }catch(Exception ex){ 
                WGestionMasiva.setError('StatusOrden', false, 'Error al calcular fecha de cancelacion parcial - '+ ex.getMessage()); 
            }
        }
        
        Order order = new Order(
            Id = WGestionMasiva.Orden.Id,
            RecordTypeId = WGestionMasiva.StandardOrderRTId,
            vlocity_cmt__DefaultBillingAccountId__c =  WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c,
            PVU_CaseInfo__c = JSON.serialize(caseInfo),
            vlocity_cmt__DefaultServiceAccountId__c =  WGestionMasiva.Asset.vlocity_cmt__ServiceAccountId__c,
            Type = assetToOrdermtd.Type__c,
            FVU_OrderSubType__c = assetToOrdermtd.SubType__c,
            PVU_SuspensionLevel__c = WGestionMasiva.GestionMasiva.PVU_Source__c == 'COLLECTIONS' && WGestionMasiva.GestionMasiva.PVU_Action__c == 'SUSPENSION' ? WGestionMasiva.GestionMasiva.PVU_SuspensionLevel__c : null,
            FVU_OriginalChannel__c = WGestionMasiva.GestionMasiva.PVU_Source__c,
            OM_Motivo__c = (WGestionMasiva.GestionMasiva.PVU_Source__c == 'Fraude_GPT' ||  WGestionMasiva.GestionMasiva.PVU_Source__c == 'Fraude_COM') && WGestionMasiva.GestionMasiva.PVU_Motivo__c != null ? WGestionMasiva.GestionMasiva.PVU_Motivo__c : null
        );  
        
        try{
            update Order;
            
            WGestionMasiva.Orden = Order;
            
            //update status
            WGestionMasiva.setError('StatusOrden', true, ''); 
            
            //order checkout
            System.enqueueJob(new PVU_GestionesMasivas_Queueable(WGestionMasiva.Orden.Id, WGestionMasiva.GestionMasiva.Id));
            
        }catch(Exception ex){
            system.debug('Error al actualizar orden - '+ ex.getMessage());
            //update status
            WGestionMasiva.setError('StatusOrden', false, 'Error al actualizar orden - '+ ex.getMessage()); 
        }
    }
    
    /**
    * Crea la orden con el activo relacionado y actualiza la gestion masiva correspondiente.
    * @param AssetRootPlan Activo.
    * @param gmasivas Lista de gestiones masivas.
    */
    public void createOrder(WGestionMasiva WGestionMasiva) {
        String status = '';
        String msj = '';
        String ACTION = WGestionMasiva.GestionMasiva.PVU_Action__c;
        
        //create request
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        inputMap.put('assetId', WGestionMasiva.Asset.Id);
        inputMap.put('assetReferenceId', WGestionMasiva.Asset.vlocity_cmt__AssetReferenceId__c);
        inputMap.put('accountId', WGestionMasiva.Asset.AccountId);
        PVU_GestionesMasivas_Interface assetToOrderClass = new PVU_GestionesMasivas_Interface();
        if(!test.isRunningTest()){
            assetToOrderClass.invokeMethod('AssetToOrder', inputMap, outputMap,optionsMap);
            system.debug('MASS assetToOrderClass - output:' + outputMap);
        }
        //se genero correctamente la orden
        if(outputMap.get('status') == 'success' || test.isRunningTest()){
            //AssetToOrder metadata
            PVU_AssetToOrderCodigos__mdt assetToOrdermtd = getMetadata(WGestionMasiva);
            
            Id orderIdNew = Test.isRunningTest() && WGestionMasiva.Orden != null ? WGestionMasiva.Orden.Id : (Id)outputMap.get('cartId') ;
            
            //update orderitems
            try{
                List<OrderItem> orderItems = [SELECT Id,
                                              orderid,
                                              order.AccountId,
                                              vlocity_cmt__parentitemid__c,
                                              vlocity_cmt__action__c,
                                              vlocity_cmt__assetid__c,
                                              pricebookentryid,
                                              Product2Id,
                                              Product2.vlocity_cmt__Type__c,
                                              Product2.ProductCode,
                                              vlocity_cmt__AttributeSelectedValues__c,
                                              vlocity_cmt__AssetReferenceId__c
                                              FROM OrderItem 
                                              WHERE OrderId =: orderIdNew WITH SYSTEM_MODE];
                
                OrderItem rootOrderItem = null;
                OrderItem planOrderItem = null;
                OrderItem OrderItemDisconnect = null;
                OrderItem orderItemToActivate = null;
                for(OrderItem item : orderItems){
                    item.vlocity_cmt__Action__c = ACTION == 'ACTIVATE_FUNC' || ACTION == 'DEACTIVATE_FUNC' || ACTION == 'ACTIVATE_SA' || ACTION == 'DEACTIVATE_SA' || ACTION == 'ACTIVATE_ROAMING'|| ACTION == 'DEACTIVATE_ROAMING' || ACTION == 'ACTIVATE_TC' || ACTION == 'DEACTIVATE_TC' || ACTION == 'DEACTIVATE_NETFLIXSA40' ? item.vlocity_cmt__Action__c :  assetToOrdermtd.Action__c;
                    item.vlocity_cmt__SubAction__c = assetToOrdermtd.SubAction__c;
                    item.FVU_ReasonCode__c = WGestionMasiva.GestionMasiva.PVU_ReasonId__c != null ? WGestionMasiva.GestionMasiva.PVU_ReasonId__c : null;
                    item.OM_SubCausal__c = assetToOrdermtd.SubCausal__c != null ? assetToOrdermtd.SubCausal__c : null;
                    item.vlocity_cmt__BillingAccountId__c = WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c;
                    item.vlocity_cmt__ServiceAccountId__c = WGestionMasiva.Asset.vlocity_cmt__ServiceAccountId__c;
                    
                    //Activacion/Desactivar funcionalidades
                    if( (ACTION == 'ACTIVATE_FUNC' || ACTION == 'DEACTIVATE_FUNC') && item.Product2.ProductCode == 'B2C-MOB-POST-FUNC-y-BLOQ-PS'){
                        Boolean flag = ACTION == 'ACTIVATE_FUNC'? true : false;
                        item.vlocity_cmt__AttributeSelectedValues__c = updateJsonAttribute(item.vlocity_cmt__AttributeSelectedValues__c, WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c, flag);
                        item.vlocity_cmt__Action__c = 'Change';
                    }  
                    
                    //Activacion/Desactivar Roaming
                    if( (ACTION == 'ACTIVATE_ROAMING' || ACTION == 'DEACTIVATE_ROAMING') && item.Product2.vlocity_cmt__Type__c == 'Plan' && item.vlocity_cmt__ParentItemId__c != null){
                        Boolean flag = ACTION == 'ACTIVATE_ROAMING' ? true : false;
                        item.vlocity_cmt__AttributeSelectedValues__c = updateJsonAttribute(item.vlocity_cmt__AttributeSelectedValues__c,'B2C-ATTR-ROAMING', flag);
                        item.vlocity_cmt__AttributeSelectedValues__c = updateJsonAttribute(item.vlocity_cmt__AttributeSelectedValues__c,'B2C-ATTR-ROAMING-BARR', !flag);
                        item.vlocity_cmt__Action__c = 'Change';
                    }
                    
                    if(item.Product2.vlocity_cmt__Type__c == 'Plan' && item.vlocity_cmt__ParentItemId__c == null ){
                        rootOrderItem = item;
                    }
                    
                    if(item.Product2.vlocity_cmt__Type__c == 'Plan' && item.vlocity_cmt__ParentItemId__c != null ){
                        planOrderItem = item;
                    }
                    
                    if(ACTION == 'DEACTIVATE_SA' && item.Product2.ProductCode == WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c){
                        OrderItemDisconnect = item;
                    }
                    
                    if(ACTION == 'DEACTIVATE_NETFLIXSA40' && item.Product2.ProductCode == WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c){
                        OrderItemDisconnect = item;
                    }
                    
                    if (ACTION == 'ACTIVATE_TC' && item.Product2.vlocity_cmt__Type__c == 'Plan' && item.vlocity_cmt__ParentItemId__c == null) {
                        orderItemToActivate = item;
                    }
                    
                    if (ACTION == 'DEACTIVATE_TC') {
                        OrderItemDisconnect = item;
                    }
                }
                
                //Update records
                update as system orderItems;
                
                //Eliminar productos adicionales o promo Todo Claro
                if(ACTION == 'DEACTIVATE_SA' || ACTION == 'DEACTIVATE_TC' || ACTION == 'DEACTIVATE_NETFLIXSA40'){
                    Map<String, Object> respDisconnect = disconnectLineItem(orderIdNew, OrderItemDisconnect);
                    Boolean statusDea = (Boolean) respDisconnect.get('status');
                    String msjDea = (String) respDisconnect.get('msj');
                    if(statusDea == false){
                        WGestionMasiva.setError('StatusOrden', false, 'Error al desconectar promoción: ' + msjDea);
                        return;
                    }
                }
                
                //Agregar Productos Adicionales
                if(ACTION == 'ACTIVATE_SA'){
                    try{
                        Map<String, Object> ipOutPostCartItem = postCartItem(orderIdNew, WGestionMasiva.GestionMasiva.PVU_FeaturesOrServices__c, planOrderItem.Id,  rootOrderItem.vlocity_cmt__AssetReferenceId__c,  WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c);
                        if(ipOutPostCartItem.get('EndProcess') != 'success'){
                            Map<String, Object> Details = (Map<String, Object>) ipOutPostCartItem.get('Details');
                            WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartItem: ' + Details.get('Message'));
                            return;
                        }else{
                            try{
                                Map<String, Object> Details = (Map<String, Object>) ipOutPostCartItem.get('Details');
                                String orderItemAddId =  (String)Details.get('OrderProductId');
                                OrderItem OrderItemAdd = new OrderItem(Id = orderItemAddId);
                                OrderItemAdd.FVU_ReasonCode__c = WGestionMasiva.GestionMasiva.PVU_ReasonId__c != null ? WGestionMasiva.GestionMasiva.PVU_ReasonId__c : null;
                                OrderItemAdd.OM_SubCausal__c = assetToOrdermtd.SubCausal__c != null ? assetToOrdermtd.SubCausal__c : null;
                                OrderItemAdd.vlocity_cmt__BillingAccountId__c = WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c;
                                OrderItemAdd.vlocity_cmt__ServiceAccountId__c = WGestionMasiva.Asset.vlocity_cmt__ServiceAccountId__c;
                                update as system OrderItemAdd;
                            }catch(Exception ex){
                                system.debug('PostCartItem: Error actualizando orderItem');
                                WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartItem: error en update de orderItem ' + ex.getMessage());
                                return;
                            }
                        }
                    }catch(Exception ex){
                        WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartItem:' + ex.getMessage());
                        return;
                    }
                }
                
                // Agregar promocion TODO CLARO
                if(ACTION == 'ACTIVATE_TC'){
                    Map<String, Object> ipOutgetPromosCompatibles = getPromosCompatibles(orderItemToActivate, orderIdNew);
                
                    if (ipOutgetPromosCompatibles.get('success') == false) {
                        Map<String, Object> result = (Map<String, Object>) ipOutgetPromosCompatibles.get('result');
                        String errorDescription = (String) result.get('error');
                        WGestionMasiva.setError('StatusOrden', false, 'Error en getPromosCompatibles: ' + errorDescription);
                        return;
                    }else{
                        List<Object> compatibleOffers = (List<Object>) ipOutgetPromosCompatibles.get('CompatibleOffersList');
                        
                        if(compatibleOffers == null || compatibleOffers.isEmpty()){
                            WGestionMasiva.setError('StatusOrden', false, 'Error en getPromosCompatibles: Lista vacía - no se encontraron promociones compatibles.');
                        	return;
                        }else{
                            String promotionId = null;
                
                            for (Object offerObj : compatibleOffers) {
                                Map<String, Object> offer = (Map<String, Object>) offerObj;
                                String catType = (String) offer.get('CAT_Type__c');
                
                                if (catType == 'TodoClaro') {
                                    promotionId = (String) offer.get('id');
                                    break; // El requerimiento es solo tomar la primera promo todoclaro encontrada
                                }
                            }
                            
                            // Se agrega promocion al carrito
                            if(promotionId != null){
                                String developerNameMdt = String.valueOf(((SObject)assetToOrdermtd).get('DeveloperName'));
                                Map<String, Object> ipOutpostCartPromoItem = postCartPromoItem(orderIdNew, promotionId, developerNameMdt);
                                String endProcess = (String) ipOutpostCartPromoItem.get('EndProcess');
                
                                if(endProcess != 'success'){
                                    Map<String, Object> result = (Map<String, Object>) ipOutpostCartPromoItem.get('result');
                                    String errorDescription = (String) result.get('error');
                                    WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartPromoItem: ' + errorDescription);
                                    return;
                                }else{
                                    try {
                                        Map<String, Object> details = (Map<String, Object>) ipOutpostCartPromoItem.get('Details');
                                        String orderItemAddId = (String) details.get('OrderProductId');
                
                                        if (String.isBlank(orderItemAddId)) {
                                            WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartPromoItem: respuesta sin OrderItemId');
                                            return;
                                        }
                						System.debug('OrderProductId: '+orderItemAddId);
                                        OrderItem orderItemAdd = new OrderItem(Id = orderItemAddId);
                                        orderItemAdd.OM_SubCausal__c = assetToOrdermtd.SubCausal__c != null ? assetToOrdermtd.SubCausal__c : null;
                                        orderItemAdd.vlocity_cmt__BillingAccountId__c = WGestionMasiva.Asset.vlocity_cmt__BillingAccountId__c;
                                        orderItemAdd.vlocity_cmt__ServiceAccountId__c = WGestionMasiva.Asset.vlocity_cmt__ServiceAccountId__c;
                                        orderItemAdd.vlocity_cmt__AssetId__c = WGestionMasiva.Asset.Id;
                                        orderItemAdd.vlocity_cmt__Action__c = assetToOrdermtd.Action__c;
                                        orderItemAdd.vlocity_cmt__SubAction__c = assetToOrdermtd.SubAction__c;
                                        update as system orderItemAdd;
                
                                    } catch (Exception ex) {
                                        System.debug('PostCartPromoItem: Error actualizando OrderItem');
                                        WGestionMasiva.setError('StatusOrden', false, 'Error en PostCartPromoItem: error en update de OrderItem ' + ex.getMessage());
                                    	return;
                                    }
                                }
                            }else{
                                WGestionMasiva.setError('StatusOrden', false, 'Error: no hay promociones Todo Claro para insertar');
                                return;
                            }
                        }
                    }
                }
                
            }catch(Exception ex){
                system.debug('Error al actualizar ordenItems - '+ ex.getMessage());
                //update gestion masiva status
                WGestionMasiva.setError('StatusOrden', false, 'Error al actualizar ordenItems' + ex.getMessage());
                return;
            }
            
            //Orden Generada Correctamente
            WGestionMasiva.StatusOrden = true;
            WGestionMasiva.Orden = new Order(
                Id = orderIdNew
            );
            
            //update gestion masiva status
            WGestionMasiva.setError('StatusOrden', true, '');
            
        }else{
            //update gestion masiva status
            WGestionMasiva.setError('StatusOrden', false, 'Error al generar orden - ' + outputMap.get('description'));
        }
    }
    
    /**
    * Reemplaza el valor de un attributo especifico de un json
    * @param SelectedAttributes : Json(String) a trabajar
    * @param attribute : Nombre del attributo a modificar
    * @param value : Nuevo valor del attributo
    * @return (String) retorna el json con los cambios en el attributo
    */
    public String updateJsonAttribute(String SelectedAttributes, String attribute, Boolean value){
        if(SelectedAttributes.contains(attribute)){
            Map<String, Object> mapAtts =  (Map<String, Object>) JSON.deserializeUntyped(SelectedAttributes);
            Boolean originAttValue = (Boolean)mapAtts.get(attribute);
            return SelectedAttributes.replace('"'+attribute+'":'+originAttValue, '"'+attribute+'":'+value);
        }else{
            return SelectedAttributes;
        }
    }
    
    /**
    * PosCartItem agrega un producto al carrito.
    * @param OrderId : Cart o orden a modificar
    * @param productCode : Codigo del producto a insertar
    * @param planOrderItemId : OrderItem del plan
    * @param rootOrderItemId : OrderItem root del plan.
    * @return Map<String, Object> Respuesta de la operacion
    */
    public Map<String, Object> postCartItem(String OrderId, String productCode, String planOrderItemId, String rootOrderItemId, String billingAccountId){
        String procedureName = 'PVU_PostCartItem';
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();  
        Map<String, Object> operation = new Map<String, Object> ();
        Map<String, Object> product = new Map<String, Object> ();
        
        //request
        product.put('Product2Code', productCode);
        operation.put('OrderId', OrderId);
        operation.put('Product', product);
        ipInput.put('CartOperation', operation);
        ipInput.put('Proceso', 'Masivos');
        ipInput.put('PlanOrderItemId', planOrderItemId);
        ipInput.put('parentAssetId', rootOrderItemId);
        Map<String, Object> fieldsToUpdate = new Map<String, Object> ();
        fieldsToUpdate.put('vlocity_cmt__SubAction__c', 'ChangeService-Product'); 
        ipInput.put('fieldsToUpdate', fieldsToUpdate);
        
        //call ip to postcartItem
        System.debug('postCartItem-IP Input: ' + ipInput);
        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
        System.debug('postCartItem-IP Output: ' + ipOutput);
        
        return ipOutput; 
    }

    /**
    * postCartPromoItem agrega una promocion al carrito.
    * @param OrderId : Cart o orden a modificar
    * @param PricebookEntryId : id de la relacion precio producto
    * @param promotionId : Id de la promocion a agregar
    * @return Map<String, Object> Respuesta de la operacion
    */
    public Map<String, Object> postCartPromoItem (String OrderId, String promotionId, String developerNameMdt){
        String procedureName = 'PVU_PostCartPromoItem';
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();  
        
        //request
        ipInput.put('PricebookEntryId', promotionId);
        ipInput.put('cartId', OrderId);
        ipInput.put('promotionId', promotionId);
        ipInput.put('OrderId', OrderId);
        ipInput.put('Proceso', developerNameMdt);
        
        //call ip to postcartPromoItem
        System.debug('postCartPromoItem-IP Input: ' + ipInput);
        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
        System.debug('postCartPromoItem-IP Output: ' + ipOutput);
        
        return ipOutput; 
    }
    
    public Map<String, Object> disconnectLineItem(String OrderId, OrderItem orderItem){
        Map<String, Object> resp = new Map<String, Object>();
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> (); 
        String procedureName = '';
        
        //Search and disconnect Promo
        vlocity_cmt__OrderAppliedPromotionItem__c orderAppliedPromo = NULL;
        try{
            orderAppliedPromo = [SELECT Id, vlocity_cmt__OrderItemId__c, vlocity_cmt__OrderAppliedPromotionId__c FROM vlocity_cmt__OrderAppliedPromotionItem__c WHERE vlocity_cmt__OrderItemId__r.OrderId =:OrderId AND vlocity_cmt__OrderItemId__r.Product2.ProductCode =:orderItem.Product2.ProductCode WITH SYSTEM_MODE  LIMIT  1];
        }catch(Exception ex){
            system.debug('disconnectLineItem: Promocion no encontrada!');
            /*resp.put('status', false);
            resp.put('msj', 'Error al desconectar promocion - ' + ex.getMessage());
            return resp;*/
        }  
        
        try{
            if(orderAppliedPromo != null){
                //==== DeleteCartPromotion ======
                procedureName = 'CPQ_DeleteCartPromotion';
                
                ipInput.put('cartId', OrderId);
                ipInput.put('id', orderAppliedPromo.vlocity_cmt__OrderAppliedPromotionId__c);
                //call ip
                System.debug('CPQ_DeleteCartPromotion-IP Input: ' + ipInput);
                ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
                System.debug('CPQ_DeleteCartPromotion-IP Output: ' + ipOutput);
                
                
                //====Disconnect LineItem======
                procedureName = 'CPQ_DisconnectLineItems';
                ipInput = new Map<String, Object> ();
                ipOutput = new Map<String, Object> ();
                ipOptions = new Map<String, Object> (); 
                ipInput.put('cartId', OrderId);
                ipInput.put('id', OrderItem.Id);
                //call ip
                System.debug('disconnectLineItem-IP Input: ' + ipInput);
                ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
                System.debug('disconnectLineItem-IP Output: ' + ipOutput);
                
                resp.put('status', true);
                resp.put('msj', 'Exito');
                
            }else{
                //====Disconnect LineItem======
                procedureName = 'CPQ_DisconnectLineItems';
                ipInput = new Map<String, Object> ();
                ipOutput = new Map<String, Object> ();
                ipOptions = new Map<String, Object> (); 
                ipInput.put('cartId', OrderId);
                ipInput.put('id', OrderItem.Id);
                //call ip
                System.debug('disconnectLineItem-IP Input: ' + ipInput);
                ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
                System.debug('disconnectLineItem-IP Output: ' + ipOutput);
                
                resp.put('status', true);
                resp.put('msj', 'Exito');
            }
            
        }catch(Exception ex){
            resp.put('status', false);
            resp.put('msj', 'Error al desconectar promocion - ' + ex.getMessage());
            return resp;
        }
        return resp; 
    }

    /**
    * getPromosCompatibles llama al IP de promociones compatibles.
    * @param OrderId : Cart o orden a modificar
    * @param orderitem : orderitem relacionado
    * @return Map<String, Object> Respuesta de la operacion
    */
    public static Map<String, Object> getPromosCompatibles(OrderItem orderitem, String orderId) {
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> (); 
        String procedureName = 'CAT_CompraPromociones';
        
        //request
        ipInput.put('OrderAccountId', orderitem.order.AccountId);
        ipInput.put('OrderItemId', orderitem.Id);
        ipInput.put('cartId', orderId);
        ipInput.put('productId', orderitem.Product2Id);
        ipInput.put('promoType', 'CAT_Type__c');
        
        //call ip
        System.debug('comprapromociones-IP Input: ' + ipInput);
        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);       
        System.debug('comprapromociones-IP Output: ' + ipOutput);
        
        return ipOutput;
    }
}