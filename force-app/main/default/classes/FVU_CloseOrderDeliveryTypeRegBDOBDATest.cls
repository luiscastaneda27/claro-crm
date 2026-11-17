@IsTest
public class FVU_CloseOrderDeliveryTypeRegBDOBDATest {
    @IsTest
    static void testCallProBDOBDADel() {
        // Create test data
        FVU_CloseOrderDeliveryTypeRegBDOBDA.ProcedureWrapper procedureWrapper = new FVU_CloseOrderDeliveryTypeRegBDOBDA.ProcedureWrapper();
        procedureWrapper.orderId = 'TestOrderId';

        // Call the method
        Test.startTest();
        FVU_CloseOrderDeliveryTypeRegBDOBDA.callProBDOBDADel(new List<FVU_CloseOrderDeliveryTypeRegBDOBDA.ProcedureWrapper>{procedureWrapper});
        Test.stopTest();

        // Add assertions here to validate the expected behavior
    }
}