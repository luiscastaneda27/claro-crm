/*-------------------------------------------------------------------------------------------------------------

Author:         Emmanuel Ruarte  - andres.ruarte@nespon.com
Company:        Nespon
Description:    
Code Coverage:  92%
History
<Date>      <Author>            <Description>             							            		<Version>
22-May-24                                                        							    	Version inicial
06-jun-24   Emmanuel Ruarte     HDU 736681				 							            			1.1
06-jun-24   Emmanuel Ruarte     Para reason code 2022 no validar fecha fin del caso             			1.2
20-jul-24   Hever Salas         Actualizar reasonCode								            			1.3
22-jul-24   Gabriel Alvis       BUG 743267 - Separación de root y relies on asset ids           			1.4
02-Sep-24   Emmanuel Ruarte     HDU 398553 - Garantizar reason code ordenes futuras             			1.5
10-Sep-24   Hever Salas         BUG 416308 - Actualizar la consulta a la metadata	            			1.6
08-Oct-24   Gabriel Alvis       BUG 437305 - Desbloqueo de SMS ENT en Reactivacion              			1.7
20-11-24    Hever Salas     	HDU-341223 - Crear orden de Cancelación de Servicio automática futura		1.8
26-02-25    Emmanuel Ruarte     HDU-539667 - Mantener servicios bloqueados en cambio de simcard             1.9
13-05-25    Karen Sancheze      HDU-596277 - Se modifica query del objeto OM_SubscriptionSuspInfo__c para   1.10
                                            cuando se tiene una RECONEXION
07-Jul-25   Gabriel Alvis       BUG 633297 - Ajuste en cancelación de órdenes futuras              			1.11
29-Ene-26   Hever Salas         HDU-711247 - [EVOLUTIVOS OM]Validacion de ordenes futuras             		2.0
--------------------------------------------------------------------------------------------------------------*/
global with sharing class OM_ManageFutureOrders implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    class notificationException extends Exception{}
    
    public static final String REASON_CODE_TERMINACION_UNILATERAL_CONTRATO = '205';
    public static final String SUBCAUSAL_TERMINACION_UNILATERAL_CONTRATO = 'Terminación Unilateral de Contrato';
    public static final String OT_ACTIVATION = 'Activation';                        // v 1.5
    public static final String OT_SUSPENSION = 'Suspension';                        // v 1.5
    public static final String OT_CAMBIOSIM = 'Cambio SIM';                         // v 1.5
    public static final String OT_CAMBIOESIM = 'Cambio eSIM';                       // v 1.5
    public static final String OT_RECONEXION = 'Reconexion';                        // v 1.5
    public static final String OST_ACTIVATION = 'Activation';                       // v 1.5
    public static final String OST_TEMPORAL = 'Temporal';                           // v 1.5
    public static final String OST_CAMBIOSIM_RP = 'CambioSIM_RoboPerdida';          // v 1.5
    public static final String OST_CAMBIOSIM_V = 'CambioSIM_Voluntario';            // v 1.5
    public static final String OST_ROB_PER = 'Robo_Perdida';                        // v 1.5
    public static final String OST_FRAUDE = 'Fraude_GPT';							// v 1.8
    public static final String PC_FUN_BLOQ = 'B2C-MOB-POST-FUNC-y-BLOQ-PS';         // v 1.9
    public static final String ACTION_CHANGE = 'Change';                            // v 1.9
    public static final String OST_CARTERA = 'Cartera';                            // v 1.9


    global  void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {

        Datetime dateNow = Datetime.NOW();
        Integer intDays;
		
        vlocity_cmt__OrchestrationItem__c orchesItem = [
            SELECT 
                Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Type,
                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_CaseInfo__c, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_SuspensionLevel__c, vlocity_cmt__FulfilmentRequestLineId__c,
                vlocity_cmt__Request__c, vlocity_cmt__Response__c
            FROM vlocity_cmt__OrchestrationItem__c
            WHERE id = :item[0].Id
            WITH SECURITY_ENFORCED
        ];
        
        List<OrderItem> oItemLstInicial = [
            SELECT 
                Id, Product2.ProductCode, Product2.vlocity_cmt__GlobalKey__c, vlocity_cmt__Action__c, 
            vlocity_cmt__SubAction__c, FVU_ReasonCode__c, product2.name , OM_SubCausal__c,vlocity_cmt__AssetId__c,
                vlocity_cmt__SubscriptionId__c, vlocity_cmt__ReliesOnItemId__c, Order.Type, Order.FVU_OrderSubType__c,
            Order.CreatedById, Order.OM_Canal__c
            FROM OrderItem
            WHERE OrderId =: orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c
            AND   (    vlocity_cmt__ParentItemId__c = null 
                    OR Product2.ProductCode =: PC_FUN_BLOQ )                            // v 1.9
            WITH SECURITY_ENFORCED
        ];
        
        OrderItem oItemParent;                                                          // OrderItem de Plan principal
        String rootAssetId = '';                                                        // v 1.4
        String reliesOnAssetIds = '';                                                   // v 1.4
        String funcBloqAction = ''  ;                                                   // v 1.9
        
        // Extracción de identificador de Asset Root e identificadores de asset relacionados por Relies on por separado - BUG 743267 - v 1.4
        for (OrderItem oItemLstFor : oItemLstInicial) {
            if (oItemLstFor.vlocity_cmt__ReliesOnItemId__c == null && oItemLstFor.Product2.ProductCode != PC_FUN_BLOQ ) {
                oItemParent = oItemLstFor;
                rootAssetId = oItemLstFor.vlocity_cmt__AssetId__c;                                                                                                  // v 1.4
            } else if(oItemLstFor.vlocity_cmt__AssetId__c != null && oItemLstFor.Product2.ProductCode != PC_FUN_BLOQ) {
                reliesOnAssetIds += (reliesOnAssetIds == '' ? (String)oItemLstFor.vlocity_cmt__AssetId__c : ',' + (String)oItemLstFor.vlocity_cmt__AssetId__c);     // v 1.4
            } else if(oItemLstFor.Product2.ProductCode == PC_FUN_BLOQ ) {               // v 1.9
                funcBloqAction = oItemLstFor.vlocity_cmt__Action__c;                    // v 1.9
            }
        } 

        String accountId = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId;
        String caseInfo = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_CaseInfo__c;
        String subscriptionId = oItemParent.vlocity_cmt__SubscriptionId__c ;
        String orderId = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c ;
        String generateOrderSuccess = '';
        String orderType = oItemParent.Order.Type;                                                                  // v 1.5
        String orderSubType = oItemParent.Order.FVU_OrderSubType__c;                                                            // v 1.5
        String reasonCodeOI = oItemParent.FVU_ReasonCode__c;
        String suspensionLevel = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_SuspensionLevel__c;
        String canal = oItemParent.Order.OM_Canal__c;
        String usuarioGenerador = oItemParent.Order.CreatedById;
        
        InterfaceSettings__mdt interSetmdt = OM_MetadataUtility.getInterfaceSettings(orderType, orderSubType, reasonCodeOI);

        if (caseInfo == null) {
            return;
        }
        
        Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();    
        
        Map<String, object> caseInfoMap =  new Map<String, object>();
        string  fechaFinList = '' ;
        string  fechaInicioList = '';
        
        
        if(interSetmdt == null){
            return;
        }

        if ((orderType == OT_SUSPENSION && (orderSubType == OST_TEMPORAL || orderSubType == OST_ROB_PER || orderSubType == OST_FRAUDE)) || 
            orderType == OT_CAMBIOSIM  || 
            orderType == OT_CAMBIOESIM || 
            (orderType == OT_RECONEXION && orderSubType == OST_CAMBIOSIM_RP)){  //FVU_ReasonCode__c == '7','2022','2032','2038' y '2064' con cambio SIM // v 1.5
                
                if(orderType == OT_SUSPENSION && (orderSubType == OST_TEMPORAL || orderSubType == OST_ROB_PER || orderSubType == OST_FRAUDE)){ //FVU_ReasonCode__c == '7' y '2022'  // v 1.5
                    caseInfoMap = (Map<String, object>)JSON.deserializeUntyped(caseInfo);
                    fechaFinList = (String)caseInfoMap.get('fechaFinSusp');
                    fechaInicioList = (String)caseInfoMap.get('fechaInicioSusp');    
                }
                
                if(orderType == OT_SUSPENSION && orderSubType == OST_FRAUDE){   
                    generateOrderSuccess ='1';
                    ipInput.put('AccountId', accountId);
                    ipInput.put('RootAssetId', rootAssetId);                                    
                    ipInput.put('ReliesOnAssetIds', reliesOnAssetIds);                          
                    ipInput.put('RequestDateTime', fechaFinList);
                    ipInput.put('inputAction','Suspend' );
                    ipInput.put('inputSubAction','Disconnect-Delete' );
                    ipInput.put('reason', (String)interSetmdt.reasonCodeFDO__c);    // 226 => 184 ; 261 => 184                           
                    ipInput.put('subCausal', (String)interSetmdt.subCausalFDO__c);
                    ipInput.put('orderType', interSetmdt.orderTypeFDO__c ); 
                    ipInput.put('orderSubType', interSetmdt.orderSubTypeFDO__c );
                    ipInput.put('canal', canal);
                    ipInput.put('usuarioGenerador', usuarioGenerador);
                }
            
                if(orderType == OT_SUSPENSION && orderSubType == OST_TEMPORAL){     //FVU_ReasonCode__c == '7' 
                    generateOrderSuccess ='1';
                    ipInput.put('AccountId', accountId);
                    ipInput.put('RootAssetId', rootAssetId);                                    // v 1.4
                    ipInput.put('ReliesOnAssetIds', reliesOnAssetIds);                          // v 1.4
                    ipInput.put('RequestDateTime', fechaFinList);
                    ipInput.put('inputAction','Resume' );
                    ipInput.put('inputSubAction','Resume-Reactivate' );
                    ipInput.put('reason', (String)interSetmdt.reasonCodeFDO__c);    //'2064'                            // v 1.5
                    ipInput.put('subCausal', (String)interSetmdt.subCausalFDO__c);  //'Temporal Voluntaria'             // v 1.5
                    ipInput.put('orderType', interSetmdt.orderTypeFDO__c );         //'Activation'                      // v 1.5
                    ipInput.put('orderSubType', interSetmdt.orderSubTypeFDO__c );   //'Activation'                      // v 1.5
                    ipInput.put('canal', canal);
                    ipInput.put('usuarioGenerador', usuarioGenerador);
                }
                
                if(orderType == OT_SUSPENSION && orderSubType == OST_ROB_PER){      //FVU_ReasonCode__c == '2022'  
                    intDays = Integer.valueOf(OrderIntegrationSystemInterfaceConstants.getValue('DaysSuspRobPerd'));
                    generateOrderSuccess ='1';
                    ipInput.put('AccountId', accountId);
                    ipInput.put('RootAssetId', rootAssetId);                                    // v 1.4
                    ipInput.put('ReliesOnAssetIds', reliesOnAssetIds);                          // v 1.4
                    ipInput.put('RequestDateTime', String.valueOf(DateTime.now().addDays(intDays)));
                    ipInput.put('inputAction','Suspend' );
                    ipInput.put('inputSubAction','Disconnect-Delete' );
                    ipInput.put('reason', (String)interSetmdt.reasonCodeFDO__c);    // '205'                                    // v 1.5
                    ipInput.put('subCausal', (String)interSetmdt.subCausalFDO__c);  //'Terminación Unilateral de Contrato'      // v 1.5
                    ipInput.put('orderType', interSetmdt.orderTypeFDO__c );         //'Cancelacion'                             // v 1.5
                    ipInput.put('orderSubType', interSetmdt.orderSubTypeFDO__c );   //'Robo_Perdida'                            // v 1.5
                    ipInput.put('canal', canal);
                    ipInput.put('usuarioGenerador', usuarioGenerador);
                }
                
                if(funcBloqAction == ACTION_CHANGE && (orderType == OT_CAMBIOSIM || orderType == OT_CAMBIOESIM || (orderType == OT_RECONEXION && orderSubType == OST_CAMBIOSIM_RP ))){   //FVU_ReasonCode__c == '2032', '2038' y '2064' con cambio SIM
                    intDays = Integer.valueOf(OrderIntegrationSystemInterfaceConstants.getValue('DayTypeChangeAndReconexion'));
                    generateOrderSuccess ='1';
                    ipInput.put('AccountId', accountId);
                    ipInput.put('RootAssetId', rootAssetId);                                    // v 1.4
                    ipInput.put('ReliesOnAssetIds', reliesOnAssetIds);                          // v 1.4
                    ipInput.put('RequestDateTime', String.valueOf(Datetime.now().addDays(intDays)));
                    ipInput.put('inputAction','Existing' );
                    ipInput.put('inputSubAction','ChangeService-Modify' );
                    ipInput.put('reason', '');
                    ipInput.put('subCausal', '');
                    ipInput.put('orderType', interSetmdt.orderTypeFDO__c );         //'Cambios'                                  // v 1.5
                    ipInput.put('orderSubType', interSetmdt.orderSubTypeFDO__c);    //'Cambio_de_Funcionalidades'                // v 1.5
                    ipInput.put('canal', canal);
                    ipInput.put('usuarioGenerador', usuarioGenerador);
                }
               
                if(!Test.isRunningTest()) {             
                    ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_GenerateFutureDatedOrders', ipInput, ipOptions);
                    System.debug ('---TEST Ip input'+ipInput);
                    System.debug ('---TEST Ip output'+ipOutput);
                    
                    orchesItem.vlocity_cmt__Request__c = JSON.serialize(ipInput);
                    orchesItem.vlocity_cmt__Response__c = JSON.serialize(ipOutput);
                }else{
                    if(orchesItem.vlocity_cmt__Response__c == null){
                        Map <String, Object> descripcion = new Map <String, Object> ();
                        descripcion.put('description', 'Error');
                        ipOutput.put('success', false);
                        ipOutput.put('ErrorCode', -1);
                        ipOutput.put('ErrorMessage', 'Error');
                        ipOutput.put('result', descripcion);
                        orchesItem.vlocity_cmt__Response__c = JSON.serialize(ipOutput);
                    } else{
                        ipOutput.put('OrderId',orderId );
                    }   
                }
            
                update orchesItem;
                
                if(string.isNotBlank(subscriptionId) && orderType == OT_SUSPENSION && (orderSubType == OST_TEMPORAL || orderSubType == OST_ROB_PER || orderSubType == OST_FRAUDE)){ //reason '7' y '2022'
                    OM_SubscriptionSuspInfo__c objSubscripSuspInfo = [
                        SELECT OM_FutureOrderId__c, OM_OrderId__c, OM_SubStatus__c
                        FROM OM_SubscriptionSuspInfo__c
                        WHERE OM_Subscription__c =: subscriptionId
                        AND   OM_OrderId__c      =:orderId WITH SECURITY_ENFORCED];
                    
                    String orderfut = orchesItem.vlocity_cmt__Response__c ;
                    Map<String, object> OrderFuturemap = (Map<String, object>)JSON.deserializeUntyped(orderfut);
                    String  numOrderFuture = (String)OrderFuturemap.get('OrderId');
                    objSubscripSuspInfo.OM_FutureOrderId__c = numOrderFuture;     
                    update objSubscripSuspInfo; 
                }
        }

        List<OM_SubscriptionSuspInfo__c> subscripSuspInfo = new List<OM_SubscriptionSuspInfo__c>();
        // La orden futura de Cancelación de servicios en caso de Robo Pérdida ya no es necesaria si se solicita Reconexión por lo tanto se cancela
        if (orderType == OT_RECONEXION && (orderSubType == OST_CAMBIOSIM_RP || orderSubType == OST_FRAUDE || orderSubType == OST_ROB_PER || orderSubType == OST_CARTERA)) {
            List<Order> orderFuture = new List<Order>() ; 
            
            subscripSuspInfo = [  
                SELECT id, OM_StatusEndDate__c, OM_FutureOrderId__r.FVU_OrderSubType__c, OM_Status__c  
                FROM OM_SubscriptionSuspInfo__c 
                WHERE OM_CustomerAccount__c =: accountId 
                AND OM_Subscription__c =: subscriptionId
                AND OM_Subscription__r.vlocity_cmt__Status__c IN('Suspended','Active')
                AND OM_FutureOrderId__r.FVU_OrderSubType__c =: orderSubType
                AND OM_StatusEndDate__c > :dateNow 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if(subscripSuspInfo.size() > 0){
                orderFuture = [
                    SELECT id,  vlocity_cmt__OrderStatus__c  
                    FROM Order 
                    WHERE id =: subscripSuspInfo[0].OM_FutureOrderId__c 
                    AND   Status NOT IN ('Cerrada Perdida', 'Activated')
                    WITH SECURITY_ENFORCED
                ];
            }
            
            if(orderFuture.size() > 0 ){
                orderFuture[0].Status = 'Cerrada Perdida';
                orderFuture[0].vlocity_cmt__OrderStatus__c = 'Cancelled';
                update orderFuture[0];
            }
        }

        // Actualización de la fecha de terminación de la suspensión temporal
        if (orderType == OT_ACTIVATION && orderSubType == OST_ACTIVATION) {
            subscripSuspInfo = [
                SELECT id, OM_StatusEndDate__c, OM_FutureOrderId__c
                FROM OM_SubscriptionSuspInfo__c
                WHERE OM_CustomerAccount__c =: accountId
                AND OM_SubStatus__c = 'Temporal Voluntaria'
                AND OM_StatusEndDate__c > :dateNow
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }

        // Actualización de la fecha de terminación de la suspensión
        if(subscripSuspInfo.size() > 0){
            subscripSuspInfo[0].OM_StatusEndDate__c = dateNow;
            update subscripSuspInfo[0];
        }

        
        if(funcBloqAction == ACTION_CHANGE && (orderType == OT_CAMBIOSIM || orderType == OT_CAMBIOESIM || (orderType == OT_RECONEXION && orderSubType == OST_CAMBIOSIM_RP))) {                   // v 1.7   // v 1.9

            List<OrderItem> oItemFuncFuture = [
                SELECT Id, vlocity_cmt__LineNumber__c, vlocity_cmt__AttributeSelectedValues__c,vlocity_cmt__AttributeMetadataChanges__c, Product2.vlocity_cmt__AttributeMetadata__c 
                FROM OrderItem
                WHERE OrderId =: (Id)ipOutput.get('OrderId')
                AND   Product2.ProductCode = :PC_FUN_BLOQ
                WITH SECURITY_ENFORCED
            ];
            
            String segment1 = '';
            String segment2 = '';
            String segment3 = '';
            String categoryCodebloq ='B2C-ATTRCAT-FUNC-DETAILS';
            
            if (!oItemFuncFuture.isEmpty()) {
                
                for (OrderItem itemBloq : oItemFuncFuture) {
                    String LineNumber = itemBloq.vlocity_cmt__LineNumber__c;
                    
                    // Dividir el productCode por el punto
                    String[] segments = LineNumber.split('\\.');
                    
                    if (segments.size() > 0) {
                        segment1 = segments[0]; //  '0029'
                    }
                    if (segments.size() > 1) {
                        segment2 = segments[0] + '.' + segments[1]; // '0029.0001'
                    }
                    if (segments.size() > 2) {
                        segment3 = segments[0] + '.' + segments[1] + '.' + segments[2]; // '0029.0001.0001'
                    }
                    
                    System.debug('Segment 1: ' + segment1);
                    System.debug('Segment 2: ' + segment2);
                    System.debug('Segment 3: ' + segment3);
                }
            }
            
            
            Map<String, Object> ipInputCart = new Map<String, Object>();
            Map<String, Object> ipOutputCart = new Map<String, Object>();
            Map<String, Object> ipOptionsCart = new Map<String, Object>();
            
            ipInputCart.put('cartId', ipOutput.get('OrderId'));
            System.debug('----OrderId:'+ipOutput.get('OrderId'));
            
            
            if (!Test.isRunningTest()) {
                ipOutputCart = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_GetCartItems', ipInputCart, ipOptionsCart);
            } else {
                
                if(orchesItem.vlocity_cmt__Response__c != null ){  ipOutputCart =(Map<String, Object>)JSON.deserializeUntyped(orchesItem.vlocity_cmt__Response__c);}
            }
            System.debug('---TEST ipInputCart CPQ_GetCartItems:' + JSON.serializePretty(ipInputCart));
            System.debug('---TEST ipOutputCart CPQ_GetCartItems:' + JSON.serializePretty(ipOutputCart));
            // colocar 'B2C-ATTR-FYB-BLQ-SMS-ENT' en false
            Map<String, Object> result = (Map<String, Object>) ipOutputCart.get('result');
            List<Object> cartRecords = (List<Object>) result.get('records');            
            Map<String, Object> idmap = new Map<String, Object>();
            Map<String, Object> actionMap = new Map<String, Object>();
            Map<String, Object> lineNumberMap = new Map<String, Object>();
            Map<String, Object> RootItemIMap = new Map<String, Object>();
            Map<String, Object> attributeCategoriesMap1 = new Map<String, Object>();    
            
            for (Object rec : cartRecords) {
                Map<String, Object> recordmap = (Map<String, Object>)rec ;
                Map<String, Object> LineNumber1 = (Map<String, Object>)recordmap.get('vlocity_cmt__LineNumber__c');
                if ((String)LineNumber1.get('value') == segment1 ) {
                    
                    List<Object> lineItemsLvl1 = (List<Object>) ((Map<String, Object>) recordmap.get('lineItems')).get('records');
                    for (Object lil1 : lineItemsLvl1) {
                        Map<String, Object> lineItemLvl1 = (Map<String, Object>)lil1 ;
                        Map<String, Object> LineNumber2 = (Map<String, Object>)lineItemLvl1.get('vlocity_cmt__LineNumber__c');
                        if ((String)LineNumber2.get('value') == segment2 ) {
                            
                            List<Object> lineItemsLvl2 = (List<Object>) ((Map<String, Object>) lineItemLvl1.get('lineItems')).get('records');
                            for (Object lil2 : lineItemsLvl2) {
                                Map<String, Object> lineItemLvl2 = (Map<String, Object>)lil2; 
                                Map<String, Object> LineNumber3 = (Map<String, Object>)lineItemLvl2.get('vlocity_cmt__LineNumber__c');
                                if ((String)LineNumber3.get('value') == segment3 ) {
                                    
                                    List<Object> attributeCategories = (List<Object>) ((Map<String, Object>) lineItemLvl2.get('attributeCategories')).get('records');
                                    idmap = (Map<String, Object>) lineItemLvl2.get('Id');
                                    actionMap = (Map<String, Object>) lineItemLvl2.get('vlocity_cmt__Action__c');
                                    lineNumberMap = (Map<String, Object>) lineItemLvl2.get('vlocity_cmt__LineNumber__c');
                                    RootItemIMap = (Map<String, Object>) lineItemLvl2.get('vlocity_cmt__RootItemId__c');
                                    attributeCategoriesMap1 = (Map<String, Object>) lineItemLvl2.get('attributeCategories');
                                    System.debug('---TEST attributeCategoriesMap1:'+JSON.serializePretty(attributeCategoriesMap1));
                                    for (Object attrCat : attributeCategories) {
                                        Map<String, Object> attributeCategory = (Map<String, Object>)attrCat ;
                                        
                                        if ((String)attributeCategory.get('Code__c') == categoryCodebloq ) {
                                            
                                            List<Object> productAttributes = (List<Object>) ((Map<String, Object>) attributeCategory.get('productAttributes')).get('records');
                                            for (Object prodAttr : productAttributes) {
                                                Map<String, Object> productAttribute = (Map<String, Object>)prodAttr;
                                                if ('B2C-ATTR-FYB-BLQ-SMS-ENT'.equals(productAttribute.get('code'))) {
                                                    System.debug('---TEST userValues-B2C-ATTR-FYB-BLQ-SMS-ENT:'+ productAttribute.get('userValues'));
                                                    productAttribute.put('userValues', false);
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Map<String, Object> ipInputUpdate = new Map<String, Object>();
            Map<String, Object> ipOutputUpdate = new Map<String, Object>();
            Map<String, Object> ipOptionsUpdate = new Map<String, Object>();
            
            Map<String, Object> inputs = new Map<String, Object>();
            inputs.put('Id', idmap) ;
            inputs.put('vlocity_cmt__Action__c' , actionMap);
            inputs.put('vlocity_cmt__LineNumber__c', lineNumberMap);
            inputs.put('vlocity_cmt__RootItemId__c', RootItemIMap);
            inputs.put('attributeCategories', attributeCategoriesMap1);
            
            
            List<Map<String, Object>> putCartList = new  List<Map<String, Object>>{inputs};
                
            Map<String,Object> items = new  Map<String,Object>{'records' => putCartList };
                    
            // entrada para el IP 'PUTCartItems'  
            ipInputUpdate.put('methodName', 'putCartsItems');
            ipInputUpdate.put('items', items ); // Se pasa toda la lista de registros con 'attributeCategories' actualizado
            ipInputUpdate.put('filters', null);
            ipInputUpdate.put('itemId', idmap.get('value')); // ID del segundo nivel
            ipInputUpdate.put('id', idmap.get('value')); // ID del segundo nivel
            ipInputUpdate.put('cartId', ipOutput.get('OrderId'));
            ipInputUpdate.put('price', true);
            ipInputUpdate.put('validate', true);
            
            //Llamada Al IP PUT
            if (!Test.isRunningTest()) {
                System.debug('---TEST ipInputupdate justoAntes:'+JSON.serializePretty(ipInputupdate));
                ipOutputUpdate = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_UpdateCartItem', ipInputupdate, ipOptionsUpdate);
            } else {
                if(orchesItem.vlocity_cmt__Response__c == null){
                    Map<String, Object> descripcion = new Map<String, Object>();
                    descripcion.put('description', 'Error');
                    ipOutputUpdate.put('success', false);
                    ipOutputUpdate.put('ErrorCode', -1);
                    ipOutputUpdate.put('ErrorMessage', 'Error');
                    ipOutputUpdate.put('result', descripcion);
                }else{
                    orchesItem.vlocity_cmt__Response__c = JSON.serialize(ipInputupdate); 
                    update orchesItem;
                }
                
            }
            System.debug('---TEST ipInputupdate CPQ_UpdateCartItem:' + JSON.serializePretty(ipInputupdate));
            System.debug('---TEST ipOutputUpdate CPQ_UpdateCartItem:' + JSON.serializePretty(ipOutputUpdate));

        }
        
        if(generateOrderSuccess =='0'){
            Map <String, Object> mapError = new Map <String, Object> ();
            mapError = (Map <String, Object>)ipOutput.get('result');
            
            throw new notificationException('Error generando orden futura. descripcion:' + mapError.get('description'));
        }
    }
}