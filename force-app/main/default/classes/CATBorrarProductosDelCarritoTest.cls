/*--------------------------------------------------------------------------
Author:         Juan Mojica - juan.mojica@salesforce.com
Company:        Salesforce.com
Description:    Test CATBorrarProductosDelCarrito
Code Coverage:  N/A
History
<Date>            <Author>             <Description>             <Version>
06-Abr-25         Juan Mojica                                    version inicial
----------------------------------------------------------------------------*/
@isTest
public class CATBorrarProductosDelCarritoTest {
    @testSetup
    static void setupTestData() {
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);
    }
    @IsTest static void testBorrarProducto() {
        Boolean resultadoBorrarProducto = false;
        List<OrderItem> itemList = [SELECT Id From OrderItem LIMIT 1];

        List<Order> testOrder = [SELECT Id, Name FROM Order LIMIT 1];

        List<List<String>> informacionProducto = new  List<List<String>>();
        List<String> infoProducto = new List<String>();
        infoProducto.add(testOrder[0].Id);
        infoProducto.add(itemList[0].Id);
        informacionProducto.add(infoProducto);


        Test.startTest();
        List<String> messages = (List<String>)CATBorrarProductosDelCarrito.borrarProductosDelCarrito(informacionProducto);
        Test.stopTest();

        for (String responseMessage : messages) {
            if(responseMessage == 'Successfully deleted.'){
                resultadoBorrarProducto = true;
            }
            System.debug('responseMessage: ' + responseMessage);
        }

        System.assertEquals(true, resultadoBorrarProducto, 'El producto se borró exitosamente del carrito');
        System.debug('Test passed successfully.');
    }
}