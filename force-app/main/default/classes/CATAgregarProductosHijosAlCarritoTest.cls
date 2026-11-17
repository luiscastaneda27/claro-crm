/*--------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Test CATBorrarProductosDelCarrito
Code Coverage:  N/A
History
<Date>            <Author>             <Description>             <Version>
07-Abr-25         Fernanda Maldonado                             version inicial
----------------------------------------------------------------------------*/
@isTest
public class CATAgregarProductosHijosAlCarritoTest {

    @testSetup
    static void testData() {
        // Crear datos de prueba usando TestDataFactory
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);        

        // Crear productos y entradas de pricebook
        List<SObject> testProductListParent = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        Product2 testParentProduct = (Product2)testProductListParent[0];
        PricebookEntry testParentPricebookEntry = (PricebookEntry)testProductListParent[1];

        List<SObject> testProductListChild = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Plan', 5, 15);
        Product2 testChildProduct = (Product2)testProductListChild[0];
        PricebookEntry testChildPricebookEntry = (PricebookEntry)testProductListChild[1];

        // Crear orden y order item padre
        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup', false);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testParentProduct, testParentPricebookEntry, testAccount.Id);

        // Simular el campo de jerarquía del producto
        testOrderItem.vlocity_cmt__ProductHierarchyPath__c = testOrderItem.Id + '<' + testParentProduct.Id;
        update testOrderItem;
    }

    @isTest
    static void testAgregarProducto() {
        List<Order> orders = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> orderItems = [SELECT Id, vlocity_cmt__ProductHierarchyPath__c, PricebookEntry.Product2Id 
                                       FROM OrderItem LIMIT 1];
        List<PricebookEntry> pbes = [SELECT Id, Product2Id FROM PricebookEntry LIMIT 2];

        // Verificamos que haya datos
        System.assert(!orders.isEmpty(), 'No se encontró ningún Order');
        System.assert(!orderItems.isEmpty(), 'No se encontró ningún OrderItem');
        System.assert(pbes.size() >= 2, 'No se encontraron suficientes PricebookEntry');

        // Construimos estructura de entrada
        String orderId = orders[0].Id;
        String orderItemId = orderItems[0].Id;
        String hierarchyPath = orderItems[0].vlocity_cmt__ProductHierarchyPath__c;
        String parentPBEId = pbes[0].Id;
        String childPBEId = pbes[1].Id;

        List<List<String>> informacionProducto = new List<List<String>>();
        List<String> infoProducto = new List<String>();

        infoProducto.add(orderId);
        infoProducto.add('dummy'); // valor posicional
        infoProducto.add(orderItemId);
        infoProducto.add(hierarchyPath);
        infoProducto.add(parentPBEId);
        infoProducto.add(childPBEId);

        informacionProducto.add(infoProducto);

        Test.startTest();
        CATAgregarProductosHijosAlCarrito.agregarProductosHijos(informacionProducto);
        Test.stopTest();

        System.debug('Test ejecutado exitosamente.');
    }
}