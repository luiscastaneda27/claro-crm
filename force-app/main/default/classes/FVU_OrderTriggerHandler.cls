public with sharing class FVU_OrderTriggerHandler {
    private static String ORDER_STATUS_CERRADA_GANADA =  'Activated';
    private static String IP_NOTIFICATION_CUS_CHANNEL =  'PVU_IPNotificationCusChannel';
    private static String IP_CALL_INSERT_DATA_TABLE_BRIDGE =  'FVU_CallInsertDataInTableBridge';
    private static String IP_UPDATE_ASSET_LIST =  'FVU_IPUpdateAssetList'; //[2026-03-05 - COE-Soporte SF]: Related to HU 692708 - INC000002702745    
    private static String PURCHASE_TYPE_NAP = 'NAP';
    private static String PURCHASE_TYPE_FIN = 'FIN';
    
    public static void afterUpdate(List<Order> newOrder, Map<Id,Order> mapOldOrder){
        Set<Id> listOrdertId = new Set<Id>();
        Set<Id> listAccountId = new Set<Id>();
        list<Order> listOrderCerradaGanada = new list<Order>();
        Map<Id,Account> accountList = new Map<Id,Account>();

        for (Order order : newOrder) {
            Order orderOld = mapOldOrder.get(order.Id);

           if (order.Status == ORDER_STATUS_CERRADA_GANADA &&
                orderOld.Status != order.Status &&
				(order.FVU_PurchaseType__c == PURCHASE_TYPE_NAP ||
				(order.FVU_PurchaseType__c == PURCHASE_TYPE_FIN &&
				order.vlocity_cmt__DeliveryMethod__c != 'Delivery'))) {
                listOrdertId.add(order.Id);
                listAccountId.add(order.AccountId);
                listOrderCerradaGanada.add(order);
            }
        } 

        if (!listAccountId.isEmpty()) {
            accountList = new Map<Id, Account> ([SELECT Id, Name, Phone, FVU_DocumentNumber__c FROM Account WHERE Id IN :listAccountId WITH SECURITY_ENFORCED]);
            notificationCusChannelRequest(listOrderCerradaGanada, accountList);            
        }

        if (!listOrderCerradaGanada.isEmpty()) {            
            insertDataInTableBridgeRequest(listOrdertId);
        }
    }

    @future(callout=true)
	public static void callProcedure(String procedureName, String inputMapStr, String optionsStr) {
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapStr);
        Map<String, Object> options = (Map<String, Object>)JSON.deserializeUntyped(optionsStr);
        Map<String, Object> args = new Map<String, Object>();
       	
        args.put('input', inputMap);
        args.put('options', options);

        FVU_CallSystemInterface callInterface = new FVU_CallSystemInterface();
        callInterface.call(procedureName, args);
    }
    
    public static void notificationCusChannelRequest(list<Order> listOrderCerradaGanada, Map<Id,Account> accountList){ 
       
        Map<String, Object> options =  new Map<String, Object>();

        for (Order order : listOrderCerradaGanada) {
            if (accountList.containsKey(order.AccountId)) {
                Account account = accountList.get(order.AccountId);

                Map<String, Object> inputMap =  new Map<String, Object>(); 
                List<Map<String, Object>> listObject = new List<Map<String, Object>>();
                Map<String, Object> receiverMap =  new Map<String, Object>(); 
    
                inputMap.put('messageType', 'SMS');
                inputMap.put('description', 'venta de terminales o tecnologia exitosa');
                inputMap.put('sendTimes', 1);
                inputMap.put('subject', String.format(System.Label.FVU_NotificationSubject, new List<String>{account.FVU_DocumentNumber__c}));
                inputMap.put('tryTimes', 3);
                inputMap.put('pushType', 'SINGLE');
                inputMap.put('communicationOrigin', 'TCRM');
                inputMap.put('communicationType', 'COMERCIAL');
                inputMap.put('state', 'Active');
                inputMap.put('deliveryReceipts', 'N');
                inputMap.put('contentType', 'MESSAGE');
                //Logica mensaje Ecommerce
                if(order.vlocity_cmt__OriginatingChannel__c == 'ECOMMERCE'){
                	inputMap.put('content', String.format(System.Label.FVU_NotificationContentEcommerce, new List<String>{order.FVU_ChannelOrderId__c}));
                } else {
                    inputMap.put('content', String.format(System.Label.FVU_NotificationContent, new List<String>{account.Name, order.OrderNumber}));
                }
                inputMap.put('profileId', 'SALESFORCE');
                receiverMap.put('phone', '57'+ account.Phone);
                listObject.add(receiverMap);
                inputMap.put('receiver', listObject);
                callProcedure(IP_NOTIFICATION_CUS_CHANNEL, JSON.serialize(inputMap), JSON.serialize(options));  
            }
        } 

    }	    
    
    /**
    * Processes the Orders received from the trigger and invokes the Integration Procedure 
    * "FVU_IPUpdateAssetList" to update Asset information and insert data into the Bridge Table asynchronously using a @future callout.
    ************************************************************************************************************
    * [2026-03-05 - COE-Soporte SF]: Related to HU 692708 - INC000002702745
    * This method was refactored to retrieve Asset data and call the Integration Procedure "FVU_IPUpdateAssetList" asynchronously using the
    * FVU_CallInsertTableBridgeFuture class.
    *
    * @param listOrdertId Set of Order record Ids to process.
    */
    @future(callout=true)
    public static void insertDataInTableBridgeRequest(Set<Id> listOrdertId){                		
        List<Asset> assetList = [SELECT fvu_warrantyperiod__c, purchasedate, fin_idreferenciadelcredito92__c, name, id, vlocity_cmt__orderid__c 
                                 FROM Asset WHERE vlocity_cmt__OrderId__c IN :listOrdertId WITH SECURITY_ENFORCED];                        
                
        for (Id orderId : listOrdertId) {            
            for (Asset asset : assetList) {
                if (asset.vlocity_cmt__OrderId__c == orderId) {
                    Map<String, Object> inputMap  	   = new Map<String, Object>();
                    Map<String, Object> inputAssetMap  = new Map<String, Object>();
                    Map<String,Object>  payloadMap     = new Map<String, Object>();
                    Map<String,Object>  options        = new Map<String, Object>();
                    Map<String,Object>  outputMap      = new Map<String, Object>();    
                    
                    options.put('chainable',true);
                    payloadMap.put('assetId', asset.Id);
                    payloadMap.put('AssetName', asset.Name);
                    payloadMap.put('AssetId', asset.Id);
                    payloadMap.put('WarrantyPeriod', asset.FVU_WarrantyPeriod__c);
                    payloadMap.put('FinRef92', asset.FIN_IdReferenciaDelCredito92__c);
                    payloadMap.put('PurchaseDate', asset.PurchaseDate);                    
                    
                    inputMap.put('Asset', payloadMap);                                        
                    inputMap.put('procedureName', IP_UPDATE_ASSET_LIST);  
                                        
                    FVU_CallInsertTableBridgeFuture handlerCallIP = new FVU_CallInsertTableBridgeFuture();    
                    handlerCallIP.invokeMethod('callUpdateAssetAndTB',inputMap,outputMap,options);                    
                }
            }         
        }            
    }
}