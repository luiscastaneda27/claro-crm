public class FVU_ValidateStatusOrder_BCH implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext BC){
        string labelString = system.label.configuracionBatchCancelacionEntrega;
      
        String Query ='SELECT id,OrderItem.OrderId, Order.Status,Order.OrderNumber FROM OrderItem WHERE Order.FVU_OrderDeliveryStatus__c = \'PendingOMS\' order by order.ordernumber desc ';
        System.debug('Query === ' + query);     
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<OrderItem> scope){ 
        GetORders(scope);
    }
     
    public void finish(Database.BatchableContext BC){        
        
    }
    
    public static void GetORders(list<OrderItem> lstOrderItm){
        map<string,string> mapTst = new map<string,string>();
        map<id,Map<String, Object>> mapOrder = new map<id,Map<String, Object>>();
        list<id> listId = new list<id>();
        for(OrderItem objORderItm:lstOrderItm){
            mapTst = new map<string,string>();
            mapTst.put('numorder',objORderItm.Order.OrderNumber);
            mapOrder.put(objORderItm.OrderId,FVU_cancelOrder_BCH.callIp(mapTst,'Service_GetOMSOrder'));
        }
        system.debug(JSON.serializePretty(mapOrder));
        validateOrder(mapOrder);
        
    }
    
    public static void validateOrder(map<id,Map<String, Object>>mapOrder){
        map<string,string> mapTst = new map<string,string>();
        set<id>orderIdUp = new set<id>();
        list<order> lstOrderUPd = new list<order>();
        string labelString = system.label.configuracionBatchCancelacionEntrega;
        map<string,map<string,string>> mapConfig2 = (map<string,map<string,string>>)JSON.deserializeStrict(labelString,map<string,map<string,string>>.class);
        
        String dayss = String.valueof(mapConfig2.get('ValidateStatusOrder').get('orderState'));
        for(id keyMAp:mapOrder.keyset()){
            system.debug(mapOrder.get(keyMAp));
            if(mapOrder.get(keyMAp).containsKey('orderInfo')){
                system.debug(mapOrder.get(keyMAp).get('orderInfo'));
                Map<String, Object> m = (Map<String, Object>) mapOrder.get(keyMAp).get('orderInfo');  
                if(m.containsKey('orderState') && m.get('orderState') == '12_CANCELADO'){      
                    order objOder = new order(id = keyMAp, Status = 'Cerrada Perdida', FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega');
                    lstOrderUPd.add(objOder);
                }              
            }
        }
        
        if(!lstOrderUPd.isEmpty() && lstOrderUPd.size() > 0){
            system.debug('actualizo order');
            system.debug(lstOrderUPd);
            update lstOrderUPd;            
        }
        
    }
}