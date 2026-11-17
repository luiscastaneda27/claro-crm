@isTest
public class FVU_OrderSelectorTest {

    @isTest
    static void testGetOrderIdClaroData() {

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Order testOrder = new Order(
            Name = 'Test',
            EffectiveDate = System.today(),
            Status = 'Draft',
            AccountId = testAccount.Id
        );
        insert testOrder;

        FVU_OrderSelector orderSelector = new FVU_OrderSelector();

        Order resultOrder = orderSelector.getOrderIdClaroData(testOrder.Id);
        System.assertEquals(testOrder.Id, resultOrder.Id);
    }
}