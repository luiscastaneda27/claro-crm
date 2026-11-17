@isTest
private class FVU_CallInsertTableBridgeFutureTest {
    
    @isTest
    static void testInvokeMethod_callTBFuture() {
        // Arrange
        Map<String, Object> inputMap = new Map<String, Object>{'assetId' => 'testAssetId' };
            Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        
        // Act
        FVU_CallInsertTableBridgeFuture instance = new FVU_CallInsertTableBridgeFuture();
        Boolean result = instance.invokeMethod('callTBFuture', inputMap, outputMap, options);
        
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, result, 'Expected invokeMethod to return true');
        System.assert(outputMap.isEmpty(), 'OutputMap should remain empty');
    }
    
    @isTest
    static void testInvokeMethod_callTBFutureErr() {
        // Arrange
        Map<String, Object> inputMap = new Map<String, Object>{'assetId' => 'testAssetId' };
            Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        
        // Act
        FVU_CallInsertTableBridgeFuture instance = new FVU_CallInsertTableBridgeFuture();
        Boolean result = instance.invokeMethod('callTBFutures', inputMap, outputMap, options);
        
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'Expected invokeMethod to return false');
    }
    
    @isTest
	static void testInvokeMethod_callUpdateAssetAndTB() {
        // Arrange
        Map<String, Object> inputMap = new Map<String, Object>{
            'procedureName' => 'Dummy_IP_Name',
            'assetId' => 'testAssetId'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
    
        FVU_CallInsertTableBridgeFuture instance = new FVU_CallInsertTableBridgeFuture();
    
        Test.startTest();
    
        // Act
        Boolean result = instance.invokeMethod('callUpdateAssetAndTB', inputMap, outputMap, options);
    
        Test.stopTest();
    
        // Assert
        System.assertEquals(true, result, 'Expected invokeMethod to return true');
	}    
}