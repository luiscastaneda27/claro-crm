global with sharing class OM_ScheduledOrder implements vlocity_cmt.VlocityOpenInterface{
    
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
    	
        Boolean result = true;
        
        switch on methodName {
            when 'executeScheduledDisconnectOrder'{
                
                try{
                	
                    this.executeScheduledDisconnectOrder((String)inputMap.get('orderId'),(String)inputMap.get('orderItemId'),(Integer)inputMap.get('daysToDisconnect'));
                    
                    result = true;              
                    
                    outMap.put('status', 'Success');
                    
                }catch(Exception e){
                    
                    outMap.put('status', 'Error');
                    outMap.put('Description', e.getMessage());
                    result = false;
                    
                }
                
            }
            when 'executeScheduledReactivationOrder'{
                
                try{
                	
                    this.executeScheduledReactivationOrder((String)inputMap.get('orderId'),(Integer)inputMap.get('daysToReactivation'));
                    
                    result = true;              
                    
                    outMap.put('status', 'Success');
                    
                }catch(Exception e){
                    
                    system.debug(e.getMessage());
                    
                    outMap.put('status', 'Error');
                    outMap.put('Description', e.getMessage());
                    result = false;
                }
                
            }
            when 'executePortOutOrder'{
                
                try{
                	
                    this.executePortOutOrder((String)inputMap.get('assetId'),(String)inputMap.get('accountId'));
                    
                    result = true;              
                    
                    outMap.put('status', 'Success');
                    
                }catch(Exception e){
                    
                    system.debug(e.getMessage());
                    
                    outMap.put('status', 'Error');
                    outMap.put('Description', e.getMessage());
                    result = false;
                }
                
            }
            when else {		  
                result = true;
            }
        }
        
    	return result;
	}
	
    public void executeScheduledDisconnectOrder(String orderId, String orderItemId, Integer daysToDisconnect){
        
        system.debug('orderId: '+orderId);
        system.debug('orderItemId: '+orderItemId);
        system.debug('daysToDisconnect: '+daysToDisconnect);
        
        OM_ExecuteScheduledOrder m = new OM_ExecuteScheduledOrder(orderId, orderItemId, 'DisconnectOrder');       
        date dateDisconnectF = Date.today();
        dateDisconnectF = dateDisconnectF.addDays(daysToDisconnect);
        
        String sch = '0 0 0 '+dateDisconnectF.day()+' '+dateDisconnectF.month()+' ? '+dateDisconnectF.year();        
        
        String jobID = System.schedule('Disconnect Order '+orderId, sch, m);
    }
    public void executeScheduledReactivationOrder(String orderId, Integer daysToReactivation){
        
        system.debug('orderId: '+orderId);        
        system.debug('daysToReactivation: '+daysToReactivation);
        
        OM_ExecuteScheduledOrder m = new OM_ExecuteScheduledOrder(orderId,'','ReactivationOrder');       
        date dateReactivationF = Date.today();
        dateReactivationF = dateReactivationF.addDays(daysToReactivation);
        
        String sch = '0 0 0 '+dateReactivationF.day()+' '+dateReactivationF.month()+' ? '+dateReactivationF.year();        
        
        String jobID = System.schedule('Reactivation Order '+orderId, sch, m);
    }
    public void executePortOutOrder(String assetId, String accountId){
        
        String orderId = '';
        String orderItemId = '';
        DateTime requestDateTime = DateTime.now();        
        requestDateTime = requestDateTime.addDays(2);        
        String requestDateTimeString = string.valueOfGmt(requestDateTime);
        
        system.debug(requestDateTimeString);
        
        vlocity_cmt.CpqAppHandler cpqAppHandler = new vlocity_cmt.CpqAppHandler();
        Map<String, Object> inputMap = new Map<String, Object>{
            'accountId' => accountId,
                'id' => assetId,
                'requestDateTime' => requestDateTimeString
                };                
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        
        cpqAppHandler.invokeMethod('assetToOrder', inputMap, outputMap, optionsMap);
        
        system.debug('outputMap');        
        system.debug(outputMap);
        
        vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)outputMap.get('result');
        
        system.debug(result);
        
        vlocity_cmt.JSONRecord record = result.records[0];
        
         Id orderIdNew = (Id)record.fields.get('cartId');
        
        system.debug(orderIdNew);
        
        List<OrderItem> orderItems = [SELECT id,orderid,vlocity_cmt__parentitemid__c,vlocity_cmt__action__c,vlocity_cmt__assetid__c,pricebookentryid FROM OrderItem WHERE OrderId =: orderIdNew AND vlocity_cmt__parentitemid__c = '' WITH SECURITY_ENFORCED];
        
        system.debug(orderItems);
        system.debug(orderItems.size());
        
        OM_ExecuteScheduledOrder m = new OM_ExecuteScheduledOrder(orderIdNew, orderItems[0].Id, 'DisconnectOrder');       
        
       	DateTime datePortOut = DateTime.now();	    
        Integer hourExecution = datePortOut.hour();        
        Integer minuteExecution = datePortOut.minute() + 1;
        
        String sch = '0 '+minuteExecution+' '+hourExecution+' '+datePortOut.day()+' '+datePortOut.month()+' ? '+datePortOut.year();    
        
        String jobID = System.schedule('Port-Out Order '+orderItems[0].Id, sch, m);
    }
}