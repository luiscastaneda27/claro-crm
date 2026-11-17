@isTest
public class OM_ScheduledOrder_Test {
	
    @isTest static void invokeMethodScheduledDisconnectOrderTest() {
        
        Test.startTest();
        
        OM_ScheduledOrder scheduledOrder = new OM_ScheduledOrder();
        
        String methodName = 'executeScheduledDisconnectOrder';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('orderId', '21312p1231231321');
        inputMap.put('orderItemId', '21312p1231231321');
        inputMap.put('daysToDisconnect', 23);
        
        Boolean result = scheduledOrder.invokeMethod(methodName, inputMap, outMap, options);
        
      	System.assertEquals(true, result);
        
        Test.stopTest();
    }
    
    @isTest static void invokeMethodScheduledReactivationOrderTest() {
                
        Test.startTest();
                
        OM_ScheduledOrder scheduledOrder = new OM_ScheduledOrder();
        
        String methodName = 'executeScheduledReactivationOrder';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('orderId', '6565656565566556');
        inputMap.put('orderItemId', '21312p1231231321');
        inputMap.put('daysToReactivation', 23);
        
        Boolean result = scheduledOrder.invokeMethod(methodName, inputMap, outMap, options);
        
        System.assertEquals(true, result);
        
        Test.stopTest();
        
    }
    
    
    @isTest static void invokeMethodScheduledDisconnectOrderErrorTest() {
        
        Test.startTest();
        
        OM_ScheduledOrder scheduledOrder = new OM_ScheduledOrder();
        
        String methodName = 'executeScheduledDisconnectOrder';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('orderId', '88888888888888888');
        inputMap.put('orderItemId', '21312p1231231321');
        inputMap.put('daysToDisconnect', '23');
        
        Boolean result = scheduledOrder.invokeMethod(methodName, inputMap, outMap, options);
		
		System.assertEquals(false, result);
        
        Test.stopTest();
                
    }
    
    @isTest static void invokeMethodScheduledReactivationOrderErrorTest() {
        
        Test.startTest();
        
        OM_ScheduledOrder scheduledOrder = new OM_ScheduledOrder();
        
        String methodName = 'executeScheduledReactivationOrder';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('orderId', '88888888888888888');
        inputMap.put('orderItemId', '21312p1231231321');
        inputMap.put('daysToDisconnect', '23');
        
        Boolean result = scheduledOrder.invokeMethod(methodName, inputMap, outMap, options);
		
		System.assertEquals(false, result);
        
        Test.stopTest();
                
    }
    
    @isTest static void invokeMethodScheduledPortOutOrderTest() {
                
        Test.startTest();
                
        OM_ScheduledOrder scheduledOrder = new OM_ScheduledOrder();
        
        String methodName = 'executePortOutOrder';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('assetId', '02i78000002iumZAAQ');
        inputMap.put('accountId', '0017800000H8n7MAAR');
        inputMap.put('daysToReactivation', 23);
        
        Boolean result = scheduledOrder.invokeMethod(methodName, inputMap, outMap, options);
        
        System.assertEquals(false, result);
        
        Test.stopTest();
        
    }
}