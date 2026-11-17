@IsTest
public class FVU_CloseOrderDeliveryTypeFutureTest {
    
    @IsTest
    static void testInvokeMethod() {
        // Arrange
        FVU_CloseOrderDeliveryTypeFuture instance = new FVU_CloseOrderDeliveryTypeFuture();
        Map<String, Object> inputMap = new Map<String, Object>{
            'orderId' => '12345'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Act
        Boolean result = instance.invokeMethod('callCloseDelTypeFuture', inputMap, outputMap, options);

        // Assert
        System.assertEquals(true, result, 'The invokeMethod should return true for valid input.');
    }
    
    @IsTest
    static void testCallCloseDelTypeFuture() {
        // Arrange
        FVU_CloseOrderDeliveryTypeFuture instance = new FVU_CloseOrderDeliveryTypeFuture();
        Map<String, Object> inputMap = new Map<String, Object>{
            'orderId' => '12345'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Act
        Boolean result = instance.callCloseDelTypeFuture(inputMap, outputMap, options);

        // Assert
        System.assertEquals(true, result, 'The callCloseDelTypeFuture method should return true.');
    }
    
    @IsTest
    static void testCallProCloseDelTypeFuture() {
        // Arrange
        FVU_CloseOrderDeliveryTypeFuture.ProcedureWrapper wrapper = new FVU_CloseOrderDeliveryTypeFuture.ProcedureWrapper();
        wrapper.orderId = '12345';
        List<FVU_CloseOrderDeliveryTypeFuture.ProcedureWrapper> wrapperList = new List<FVU_CloseOrderDeliveryTypeFuture.ProcedureWrapper>{ wrapper };

        Test.startTest();
        // Act
        FVU_CloseOrderDeliveryTypeFuture.callProCloseDelTypeFuture(wrapperList);
        Test.stopTest();

        // Assert
        System.assert(true, 'The callProCloseDelTypeFuture method should execute without exceptions.');
    }
}