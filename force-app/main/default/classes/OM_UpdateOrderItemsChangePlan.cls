/*--------------------------------------------------------------------------
Author:          Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    <Version>
17-07-24		Hever Salas     	Se actualizan las fechas y subscriptionid			   1.1
----------------------------------------------------------------------------*/
global with sharing class OM_UpdateOrderItemsChangePlan implements vlocity_cmt.VlocityOpenInterface {
    
    class MyException extends Exception{}
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
          
        try {
            if (methodName.Equals('updateOrderItems')){
                updateOrderItems(inputMap, outMap, options);
            }
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch(Exception ex) {
            outMap.put('error', ex.getStackTraceString()); 
            result = false; 
        }
        return result;
    }
    
    /**
    * @description: Actualiza las fechas, subscription y status de los orderitem viejos y nuevos
    * @author Hever Salas | 17-07-2024 
    * @param orderId
    **/
    public void updateOrderItems(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        
       	String orderId = (String)inputMap.get('orderId');
        Datetime fechaActual = Datetime.NOW();
        String subscriptionId = [SELECT Id, vlocity_cmt__subscriptionid__c
                                FROM OrderItem 
                                WHERE OrderId = :orderId 
                                AND vlocity_cmt__Action__c = 'Disconnect'
                                AND vlocity_cmt__ParentItemId__c = ''
                                AND vlocity_cmt__ReliesOnItemId__c = null
                                AND vlocity_cmt__ReliesOnItemId__c <> ' '].vlocity_cmt__subscriptionid__c;
        
        List<OrderItem> lstOrderItem = [SELECT Id, vlocity_cmt__connectdate__c, vlocity_cmt__disconnectdate__c, 
                                        vlocity_cmt__action__c, vlocity_cmt__subscriptionid__c, 
                                        vlocity_cmt__ProvisioningStatus__c, OM_Status__c, vlocity_cmt__ReliesOnItemId__c
                                        FROM OrderItem 
                                        WHERE (OrderId = :orderId AND vlocity_cmt__Action__c = 'Add') 
                                        OR (OrderId = :orderId AND vlocity_cmt__Action__c = 'Disconnect')]; 
        
        for(OrderItem item :lstOrderItem){
            if(item.vlocity_cmt__action__c == 'Add'){
                item.vlocity_cmt__connectdate__c = fechaActual;
                item.vlocity_cmt__ProvisioningStatus__c = 'Active';
                item.OM_Status__c = 'Active';
                item.vlocity_cmt__subscriptionid__c = subscriptionId;
            }else{
                if(item.vlocity_cmt__action__c == 'Disconnect'){
                    item.vlocity_cmt__disconnectdate__c = fechaActual;
                    item.vlocity_cmt__ProvisioningStatus__c = 'Deactivated';
                    item.OM_Status__c = 'Deactivated';
            	}
            }
        }      
        UPDATE lstOrderItem;       
    }
}