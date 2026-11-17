@isTest
private class PVU_PlatformEventIntefaceTest {

    /**
     * @description Test positive scenario where event is published successfully with a Payload
     */
    @isTest
    static void testPublishCompletionEvent_Success() {
        // 1. Setup Data
        PVU_PlatformEventInteface service = new PVU_PlatformEventInteface();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('correlationId', 'TEST-GUID-12345');
        
        // Create a dummy payload object (Map)
        Map<String, Object> payloadData = new Map<String, Object>();
        payloadData.put('status', 'OK');
        payloadData.put('details', 'Integration successful');
        inputMap.put('payload', payloadData);

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // 2. Execution
        Test.startTest();
        Boolean result = service.invokeMethod('publishCompletionEvent', inputMap, outMap, options);
        Test.stopTest(); // Forces the Platform Event to be published in the test context

        // 3. Assertions
        System.assertEquals(true, result, 'The invokeMethod should return true on success.');
        System.assertEquals(true, outMap.get('success'), 'The outMap should contain success=true.');
        System.assertEquals(null, outMap.get('error'), 'There should be no errors in outMap.');
    }

    /**
     * @description Test scenario where payload is null but CorrelationID exists.
     * The code should handle null payload gracefully without crashing.
     */
    @isTest
    static void testPublishCompletionEvent_NullPayload() {
        PVU_PlatformEventInteface service = new PVU_PlatformEventInteface();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('correlationId', 'TEST-GUID-67890');
        inputMap.put('payload', null); // Explicitly null

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = service.invokeMethod('publishCompletionEvent', inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(true, result, 'Method should succeed even with null payload.');
        System.assertEquals(true, outMap.get('success'), 'Platform Event should still publish.');
    }

    /**
     * @description Test exception handling block by forcing a NullPointerException.
     * We pass "null" as the inputMap to trigger the error in the helper method.
     */
    @isTest
    static void testInvokeMethod_ExceptionHandling() {
        PVU_PlatformEventInteface service = new PVU_PlatformEventInteface();
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        // Passing NULL as inputMap will cause a NullPointerException when code tries to do inputMap.get()
        // This validates the Try/Catch block in invokeMethod
        Boolean result = service.invokeMethod('publishCompletionEvent', null, outMap, options);
        Test.stopTest();

        // Assertions
        System.assertEquals(false, result, 'The invokeMethod should return false on exception.');
        System.assertEquals(false, outMap.get('isSuccess'), 'isSuccess should be false in outMap.');
        System.assertNotEquals(null, outMap.get('error'), 'An error message should be present in outMap.');
    }

    /**
     * @description Test invokemethod with an unknown method name
     */
    @isTest
    static void testInvokeMethod_UnknownMethod() {
        PVU_PlatformEventInteface service = new PVU_PlatformEventInteface();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = service.invokeMethod('NonExistentMethod', inputMap, outMap, options);
        Test.stopTest();

        // Based on the code, if method doesn't match, it exits the if but returns the default result (true)
        System.assertEquals(true, result, 'Should return true by default for unknown methods (based on current implementation).');
    }
}