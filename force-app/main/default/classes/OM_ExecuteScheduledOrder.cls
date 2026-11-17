global with sharing class OM_ExecuteScheduledOrder implements Schedulable{
    
    public String orderId;
    public String orderItemId;
    public String typeAction;
    
    public OM_ExecuteScheduledOrder(String orderId, String orderItemId, String typeAction){
        
        this.orderId = orderId;
        this.orderItemId = orderItemId;
        this.typeAction = typeAction;
    }
    
    global void execute(SchedulableContext SC) {
        
        system.debug(orderId);
        system.debug(orderItemId);
        
        switch on typeAction {
            when 'DisconnectOrder' {
                this.disconnectOrder(orderId, orderItemId);
        		this.checkOutOrder(orderId);
            }	
            when 'ReactivationOrder' {
                
                this.reactivationOrder(orderId);
                this.checkOutOrder(orderId);
            }           
        }       
    }
    
    public void disconnectOrder(String orderId, String orderItemId){
        
        vlocity_cmt.CpqAppHandler cpqAppHandler = new vlocity_cmt.CpqAppHandler();
        
        Map<String, Object> inputMap = new Map<String, Object>{
            'cartId' => orderId,
                'id' => orderItemId
                };                
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        cpqAppHandler.invokeMethod('deleteCartsItems', inputMap, outputMap, optionsMap);
        
    }
    
    public void checkOutOrder(String orderId){
        
        vlocity_cmt.CpqAppHandler cpqAppHandler = new vlocity_cmt.CpqAppHandler();
        
        Map<String, Object> inputMap = new Map<String, Object>{
            	'cartId' => orderId,
                'ContextId' => orderId
                };                
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        cpqAppHandler.invokeMethod('checkout', inputMap, outputMap, optionsMap);
        
    }
    public void reactivationOrder(String orderId){
        
        List<OrderItem> listOrderItems = [SELECT Id, vlocity_cmt__Action__c FROM orderItem WHERE OrderId =: orderId WITH SECURITY_ENFORCED];
        
        for(OrderItem orderItem : listOrderItems){
            orderItem.vlocity_cmt__Action__c = 'Existing';
        }
        
        update listOrderItems;
    }
    
}