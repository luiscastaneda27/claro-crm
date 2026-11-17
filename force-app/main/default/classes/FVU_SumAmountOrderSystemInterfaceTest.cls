@isTest
private class FVU_SumAmountOrderSystemInterfaceTest {
    
    @isTest
    private static void invokeValidFraudeSuccessByAccount() {
        
        String response ='{"accountId":"1234"}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(response); 
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', inputMap);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            FVU_SumAmountOrderItemSystemInterface sumAmountOrderItem = new FVU_SumAmountOrderItemSystemInterface();
            sumAmountOrderItem.call('getOrderTotalByAccount', args);
        Test.stopTest();
        
    }
    
    @isTest
    private static void invokeValidFraudeSuccessByOwner() {
        
        String response ='{"ownerId":"1234"}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(response); 
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', inputMap);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            FVU_SumAmountOrderItemSystemInterface sumAmountOrderItem = new FVU_SumAmountOrderItemSystemInterface();
            sumAmountOrderItem.call('getOrderTotalByOwner', args);
        Test.stopTest();
        
    }    
    
    @isTest
    private static void invokeValidFraudeException() {
        
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', null);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            FVU_SumAmountOrderItemSystemInterface sumAmountOrderItem = new FVU_SumAmountOrderItemSystemInterface();
            sumAmountOrderItem.call('getOrderTotalByAccount', args);
        Test.stopTest();
    }    

}