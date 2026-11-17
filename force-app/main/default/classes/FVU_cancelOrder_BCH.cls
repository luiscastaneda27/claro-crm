public class FVU_cancelOrder_BCH implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        string labelString='';
        if(!Test.isRunningTest()){
        	labelString = system.label.configuracionBatchCancelacionEntrega;
        }else{
            labelString = system.label.configuracionBatchCancelacionEntregaTestClass;
        }
        map<string,map<string,string>> mapConfig2 = (map<string,map<string,string>>)JSON.deserializeStrict(labelString,map<string,map<string,string>>.class);
        system.debug(labelString);
        String dayss = String.valueof(mapConfig2.get('cancelOrder').get('days'));
        
        String Query ='SELECT id,OrderItem.OrderId, Order.Status,Order.OrderNumber FROM OrderItem WHERE Order.Status = \'DeliveryAndActivated\' AND (FVU_ProductDeliveryStatus__c =\'ReadyForDelivery\' OR FVU_ProductDeliveryStatus__c =\'AssignSerial\' ) AND order.FVU_PaymentStatus__c =\'PE\' AND Order.vlocity_cmt__DeliveryMethod__c	=\'Delivery\' AND order.FVU_OrderDeliveryStatus__c = \'PaymentNotified\' '+ dayss +'order by order.ordernumber';
        
        System.debug('Query === ' + query);     
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<OrderItem> scope){ 
        GetORdersCancel(scope);
        //GetORders(scope);
    }
    
    public void finish(Database.BatchableContext BC){                
    }
    
    public static void GetORders(wrapperOrder wppOrder){
        map<string,string> mapTst = new map<string,string>();
        map<id,Map<String, Object>> mapOrder = new map<id,Map<String, Object>>();
        list<id> listId = new list<id>();
        for(OrderItem objORderItm:wppOrder.lstOrderItm){
                if(!wppOrder.orderCancelledID.contains(objORderItm.OrderId)){
                mapTst = new map<string,string>();
                mapTst.put('OrderNumber',objORderItm.Order.OrderNumber);
                mapOrder.put(objORderItm.OrderId,callIp(mapTst,'PVU_IPLogisticsBroker'));    
            }
        }
        system.debug(JSON.serializePretty(mapOrder));
        wppOrder.mapOrder = mapOrder;
        validateOrder(wppOrder);
    }
    
    public static void GetORdersCancel(list<OrderItem> lstOrderItm){
        map<string,string> mapTst = new map<string,string>();
        map<id,Map<String, Object>> mapOrder = new map<id,Map<String, Object>>();
        list<id> listId = new list<id>();
        for(OrderItem objORderItm:lstOrderItm){
            mapTst = new map<string,string>();
            mapTst.put('numorder',objORderItm.Order.OrderNumber);
            mapOrder.put(objORderItm.OrderId,callIp(mapTst,'Service_GetOMSOrder'));
        }
        system.debug(JSON.serializePretty(mapOrder));
        wrapperOrder wppOrder = validateCancelOrder(mapOrder,lstOrderItm);
        GetORders(wppOrder);
    }
    
    public static void validateOrder(wrapperOrder wppOrder){
        
        map<id,Map<String, Object>> mapOrder = new map<id,Map<String, Object>>();
        mapOrder = wppOrder.mapOrder;
        map<string,string> mapTst = new map<string,string>();
        set<id>orderIdUp = new set<id>();
        set<id>orderIdUpCancel = new set<id>();
        list<order> lstOrderUPd = new list<order>();
        order OrderUPd = new order();
        string labelString = system.label.configuracionBatchCancelacionEntrega;
        map<string,map<string,string>> mapConfig2 = (map<string,map<string,string>>)JSON.deserializeStrict(labelString,map<string,map<string,string>>.class);
        string lstJso =  string.valueof(mapConfig2.get('cancelOrder').get('news'));
        for(id keyMAp:mapOrder.keyset()){
            //if(mapOrder.get(keyMAp).containsKey('Novedad') && mapOrder.get(keyMAp).get('Novedad') != null && lstJso.contains(string.valueof(mapOrder.get(keyMAp).get('Novedad')))){
            if((mapOrder.get(keyMAp).containsKey('Novedad') && mapOrder.get(keyMAp).get('Novedad') != null && lstJso.contains(string.valueof(mapOrder.get(keyMAp).get('Novedad'))))
                ||(mapOrder.get(keyMAp).containsKey('Novedad2') && mapOrder.get(keyMAp).get('Novedad2') != null && lstJso.contains(string.valueof(mapOrder.get(keyMAp).get('Novedad2')))))
            {
                orderIdUp.add(keyMAp);
            }
        }
        
        //callIpF(orderIdUp);
        for(id keiId:orderIdUp){
            mapTst = new map<string,string>();
            mapTst.put('motivo','RETRACTO');
            mapTst.put('orderId',keiId);
            mapTst.put('rejectedCause','RETRACTO');
            try {
                callIp(mapTst,'FVU_FVU_CancelOrder'); 
                OrderUPd = new order();
                OrderUPd.id =keiId;
                OrderUPd.FVU_OrderDeliveryStatus__c ='PendingOMS';
                lstOrderUPd.add(OrderUPd);
            } catch(Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
        lstOrderUPd.addAll(wppOrder.lstUpd);
        
        update lstOrderUPd;
    }
    
     public static wrapperOrder validateCancelOrder(map<id,Map<String, Object>>mapOrder, list<OrderItem> lstOrderItm){
        set<id>orderCancelledID = new set<id>();
        list<order> lstOrderUPd = new list<order>();

        for(id keyMAp:mapOrder.keyset()){
            system.debug(mapOrder.get(keyMAp));
            if(mapOrder.get(keyMAp).containsKey('orderInfo')){
                system.debug(mapOrder.get(keyMAp).get('orderInfo'));
                Map<String, Object> m = (Map<String, Object>) mapOrder.get(keyMAp).get('orderInfo');  
                if(m.containsKey('orderState') && m.get('orderState') == '12_CANCELADO'){      
                    orderCancelledID.add(keyMAp);
                    order objOder = new order(id = keyMAp, Status = 'Cerrada Perdida', FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega');
                    lstOrderUPd.add(objOder);
                }              
            }
        }        
         wrapperOrder wppOrder = new wrapperOrder(lstOrderUPd,orderCancelledID,lstOrderItm,null);
         return wppOrder;
    }
    
    public static Map<String, Object> callIp(map<string,string> mapInput,String procedureName){
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();
        for(string strKey:mapInput.keyset()){
            ipInput.put(strKey,mapInput.get(strKey));
        }
        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
        System.debug('IP Output: ' + ipOutput);
        System.debug('IP Output: ' + JSON.serializePretty(ipOutput));
        return ipOutput;
    }
    

    
        public class wrapperOrder {
        @AuraEnabled       
        public list<OrderItem> lstOrderItm  {get;set;}
        @AuraEnabled
        public list<order> lstUpd  {get;set;}
        @AuraEnabled       
        public set<id> orderCancelledID  {get;set;}
        @AuraEnabled       
        public map<id,Map<String, Object>>mapOrder {get;set;}

        public wrapperOrder(list<order> lstUpd, set<id> orderCancelledID,list<OrderItem> lstOrderItm,map<id,Map<String, Object>>mapOrder)
        {
            this.lstUpd    			= lstUpd;
            this.orderCancelledID   = orderCancelledID;
            this.lstOrderItm   		= lstOrderItm;
            this.mapOrder      		= mapOrder;
        }
    }
    
}