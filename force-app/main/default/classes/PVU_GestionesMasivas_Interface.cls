/*******************************************************************************
* Autor: hllanos
* Fecha: 2024-10-25
* Equipo: Pos-Ventas
* Descripcion: Interfaz - API Call to AssetToOrder
* History
<Date>            <Author>             <Description>             <Version>
2024-10-25         hllanos                 creacion                   01
2025-08-01         hllanos                 AddingByPass               01
***********************************************************************************/
global with sharing class PVU_GestionesMasivas_Interface implements vlocity_cmt.VlocityOpenInterface{
    //bypass future orders
    Public String BY_PASS_ORDER_STATUS = 'Temporary';
    
	 global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        switch on methodName {
            when 'AssetToOrder'{
                try{
                    this.AssetToOrder(inputMap,outMap);
                    result = true;        
                    
                }catch(Exception e){
                    system.debug(e.getMessage());
                    outMap.put('status', 'Error');
                    outMap.put('description', e.getMessage());
                    result = false;
                }
            }
            when 'checkout'{
                try{
                    this.checkout(inputMap,outMap);
                    result = true;        
                    
                }catch(Exception e){
                    system.debug(e.getMessage());
                    outMap.put('status', 'Error');
                    outMap.put('description', e.getMessage());
                    result = false;
                }
            }
            
            when 'cancelOrdenesFuturas'{
                try{
                    this.cancelOrdenesFuturas(inputMap,outMap);
                    result = true;        
                    
                }catch(Exception e){
                    system.debug(e.getMessage());
                    outMap.put('status', 'Error');
                    outMap.put('description', e.getMessage());
                    result = false;
                }
            }
             when 'callPlatFormEvent'{
                try{
                    this.callPlatFormEvent(inputMap,outMap);
                    result = true;        
                    
                }catch(Exception e){
                    system.debug(e.getMessage());
                    outMap.put('status', 'Error');
                    outMap.put('description', e.getMessage());
                    result = false;
                }
            }
            when else {		  
                result = false;
            }
        }
    	return result;
	}
    
    public void AssetToOrder(Map<String,Object> inputMap,  Map<String,Object> outMap){
        system.debug('MASS AssetToOrder - inputMap:' + inputMap); 
        String assetId= (String)inputMap.get('assetId');
        String assetReferenceId= (String)inputMap.get('assetReferenceId');
        String accountId=(String)inputMap.get('accountId');
        
        DateTime requestDateTime = DateTime.now();            
        String requestDateTimeString = string.valueOfGmt(requestDateTime);
        
        //List productos adicionales
        List<String> assetList = new List<String>();
        assetList.add(assetId);
        
            for( Asset asset: [SELECT Id
                               FROM Asset 
                               WHERE vlocity_cmt__ParentItemId__c = null 
                               AND vlocity_cmt__ReliesOnItemId__c =: assetReferenceId
                               WITH SECURITY_ENFORCED]
               ){
                   assetList.add(asset.Id);
               }
        
        
        String StringAditionalProdList = String.join(assetList, ',');
        
        //calling de API assetToOrder
        vlocity_cmt.CpqAppHandler cpqAppHandler = new vlocity_cmt.CpqAppHandler();
        Map<String, Object> newinputMap = new Map<String, Object>{
            	'accountId' => AccountId,
                'id' => StringAditionalProdList,
                'requestDateTime' => requestDateTimeString
        };       
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        //==========  Set order ByPass ==========
        Map<Id, String> mapUpdateOrders = new Map<Id, String>();
        mapUpdateOrders = setOrderByPass(assetId);
        
        //==========  Asset to order ============
        system.debug('======== request asset to order: ' + newinputMap);
        try{
            cpqAppHandler.invokeMethod('assetToOrder', newinputMap, outputMap, optionsMap);
        }catch(Exception ex){
            system.debug('Exception asset to order - ' + ex.getMessage());
            outMap.put('status', 'error');
            outMap.put('description', ex.getMessage());
        }
        
        //result   
        try{
            vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)outputMap.get('result');
            vlocity_cmt.JSONRecord record = result.records[0];
            Id orderIdNew = (Id)record.fields.get('cartId');
            outMap.put('cartId', orderIdNew);
            outMap.put('status', 'success');
        }catch(Exception ex){
            outMap.put('status', 'error');
            outMap.put('description', 'Change To Order Failed.');
        }
        
        //========== Restore ByPass =============
        restoreOrderByPass(mapUpdateOrders);
    }
    
     public void checkout(Map<String,Object> inputMap,  Map<String,Object> outMap){
        system.debug('MASS checkout - inputMap:' + inputMap); 
        String cartId= (String)inputMap.get('cartId');
        
        //calling de API assetToOrder
        vlocity_cmt.CpqAppHandler cpqAppHandler = new vlocity_cmt.CpqAppHandler();
        Map<String, Object> newinputMap = new Map<String, Object>{
            'ContextId' => cartId,
            'cartId' => cartId,
            'checkOrderStatus' => false,
            'orderId' => cartId
        };       
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        cpqAppHandler.invokeMethod('checkout', newinputMap, outputMap, optionsMap);
        system.debug('MASS checkout - result:' + outputMap); 
        //result    
        vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)outputMap.get('result');
        vlocity_cmt.JSONRecord record = result.records[0];
        Id orderIdNew = (Id)record.fields.get('cartId');
        outMap.put('cartId', orderIdNew);
        outMap.put('status', 'success');
    }
    
    /**
    * SetOrderByPass: obtiene las ordenes encoladas futuras y las modifica con un status temporal
    * @param AssetRootPlan Activo.
    * @return mapa de assets modificados con su status anterior.
    */
    public Map<Id, String> setOrderByPass(String RootAssetId){
        //get orders 
        Map<Id, String> orderIds = new Map<Id, String>();
        for(OrderItem item : [SELECT Id, OrderId, Order.vlocity_cmt__OrderStatus__c
                              FROM OrderItem 
                              WHERE vlocity_cmt__AssetId__c  =: RootAssetId
                              AND order.vlocity_cmt__RequestDate__c >= TODAY
                              AND vlocity_cmt__ParentItemId__c = null
                              AND Order.vlocity_cmt__OrderStatus__c IN ('Ready To Submit', 'Draft', 'Queued', 'In Progress')
                              WITH SECURITY_ENFORCED])
        {
            if(orderIds.get(item.OrderId) == null){
                orderIds.put(item.OrderId, item.Order.vlocity_cmt__OrderStatus__c);
            }            
        }
        
        //update orders with temporal status
        if(!orderIds.isEmpty()){
            List<Order> listOrderUpdate = new List<Order>();
            for(Id orderId : orderIds.keySet()){
                Order tempOrder = new Order(Id = orderId, vlocity_cmt__OrderStatus__c = BY_PASS_ORDER_STATUS);
                listOrderUpdate.add(tempOrder);
            }
            
            if(listOrderUpdate.size() > 0){
                Database.update(listOrderUpdate, false, AccessLevel.System_mode);
            }
        }
        
        //return map of updated orders
        return orderIds;
    }
    
    /**
    * Description: Restaura las ordenes futuras modificadas con el status temporal
    * @param AssetRootPlan Activo.
    */
    public void restoreOrderByPass(Map<Id, String> mapUpdateOrders){
        //update orders with temporal status
        if(!mapUpdateOrders.isEmpty()){
            List<Order> listOrderUpdate = new List<Order>();
            
            for(Id orderId : mapUpdateOrders.keySet()){
                Order tempOrder = new Order(Id = orderId, vlocity_cmt__OrderStatus__c = mapUpdateOrders.get(orderId));
                listOrderUpdate.add(tempOrder);
            }
            
            if(listOrderUpdate.size() > 0){
                Database.update(listOrderUpdate, false, AccessLevel.System_mode);
            }
        }
    }
    
    /**
    * Description: Wrap method para cancelar ordenes futuras
    * @param AssetPlan Activo.
    */
    public void cancelOrdenesFuturas(Map<String,Object> inputMap,  Map<String,Object> outMap){
        system.debug('MASS cancelOrdenesFuturas - inputMap:' + inputMap); 
        PVU_Gestiones_Masivas_Handler handler =  new PVU_Gestiones_Masivas_Handler(); 
        List<Case> caseClosed = new List<Case>();
        List<String> caseClosedVoces = new List<String>();
        String status = 'success';
        String msj = 'Ordenes canceladas con Exito';
        String assetId= (String)inputMap.get('assetId');
        try{
            Asset asset = [SELECT Id, Name, Status, 
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
                           FROM Asset WHERE Id=:assetId WITH SECURITY_ENFORCED LIMIT 1];
            
            PVU_Gestiones_Masivas__c gm = new PVU_Gestiones_Masivas__c(PVU_CustNum__c = '0000');
            PVU_Gestiones_Masivas_Handler.WGestionMasiva masiveRecord = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gm);
            masiveRecord.AssetPlan = asset;
            caseClosed = handler.cancelQueuedOrders(masiveRecord);
            
            if(caseClosed.size() != null && caseClosed.size() > 0){
                for(Case caso: caseClosed){
                    caseClosedVoces.add(caso.PVU_Level3__c);
                }
            }
        }catch(Exception ex){
            status = 'Error';
            msj = 'Error al cancelar ordenes:' + ex.getMessage();
        }  
        
        outMap.put('status', status);
        outMap.put('msj', msj);
        outMap.put('cantidadCasosCancelados', caseClosedVoces.size());
        outMap.put('casosVocesCanceladas', String.join(caseClosedVoces, ', '));
    }
    
    /**
    * Description: Wrap method para llamar a un evento de plataform	y enviar un mail
    * @param AssetPlan Activo.
    */
    public void callPlatFormEvent(Map<String,Object> inputMap,  Map<String,Object> outMap){
        system.debug('MASS callPlatFormEvent - inputMap:' + inputMap); 
      
        String status = 'success';
        String msj = 'Evento registrado correctamente';
        try{
            List<PVU_EngagementInteraction__e> eventos = new List<PVU_EngagementInteraction__e>();
            PVU_EngagementInteraction__e eventoPlataforma = new PVU_EngagementInteraction__e();
            eventoPlataforma.PVU_Actions__c = (String)inputMap.get('caseId');
            eventoPlataforma.PVU_IPName__c = 'NotiCancelarFutureOrderMasivos';
            eventoPlataforma.PVU_Body__c =  (String)inputMap.get('emailMessage');
            eventoPlataforma.PVU_Subject__c = (String)inputMap.get('asuntoCorreo');
            eventos.add(eventoPlataforma);
            List<Database.SaveResult> results = EventBus.publish(eventos);
        }catch(Exception ex){
            status = 'Error';
            msj = 'Error al enviar evento de plataforma:' + ex.getMessage();
        }  
        
        outMap.put('status', status);
        outMap.put('msj', msj);
    }
}