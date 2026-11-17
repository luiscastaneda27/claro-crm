/*******************************************************************************
* Autor: Federico Mandri
* Fecha: 2023-09-12
* Equipo: Pos-Ventas
* HU: 644584
* Descripcion: Clase de test para PVU_PagosNoAbonadosUtils
***********************************************************************************/
@isTest
public class PVU_PagosNoAbonadosUtilsTest {
	@TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;                            
        
        // --- create orders --- 
        Order orden1 = new Order();
        orden1.AccountId = acc.Id;
        orden1.Status = 'Draft';
        orden1.Pricebook2Id = pricebookId;
        orden1.EffectiveDate = System.Today();
        insert orden1;
        
        Order orden2 = new Order();
        orden2.AccountId = acc.Id;
        orden2.Status = 'Draft';
        orden2.Pricebook2Id = pricebookId;
        orden2.EffectiveDate = System.Today();
        insert orden2;
        
        Order orden3 = new Order();
        orden3.AccountId = acc.Id;
        orden3.Status = 'Draft';
        orden3.Pricebook2Id = pricebookId;
        orden3.EffectiveDate = System.Today();
        insert orden3;
        
        //insert order item
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orden1.Id;
        orderItem1.Product2Id = prod1.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.Quantity = 1;
        orderItem1.UnitPrice = 10;
        orderItem1.vlocity_cmt__LineNumber__c = '0001';
        orderItem1.vlocity_cmt__Action__c = 'Add';
        orderItem1.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem1.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem1.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem1.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem1;
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.OrderId = orden2.Id;
        orderItem2.Product2Id = prod1.Id;
        orderItem2.PricebookEntryId = pbe1.Id;
        orderItem2.Quantity = 1;
        orderItem2.UnitPrice = 10;
        orderItem2.vlocity_cmt__LineNumber__c = '0001';
        orderItem2.vlocity_cmt__Action__c = 'Add';
        orderItem2.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem2.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem2.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem2.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem2;
        
        OrderItem orderItem3 = new OrderItem();
        orderItem3.OrderId = orden3.Id;
        orderItem3.Product2Id = prod1.Id;
        orderItem3.PricebookEntryId = pbe1.Id;
        orderItem3.Quantity = 1;
        orderItem3.UnitPrice = 10;
        orderItem3.vlocity_cmt__LineNumber__c = '0001';
        orderItem3.vlocity_cmt__Action__c = 'Add';
        orderItem3.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem3.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem3.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem3.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem3;

        // --- update orders ---
        orden2.Status = 'Cerrada Perdida';
        orden2.FVU_ClosingReason__c = 'Cancelado por no finalización de orden';
        update orden2;
       
        orden3.Status = 'InPayment';
        orden3.FVU_PaymentStatus__c = 'PP';
        orden3.FVU_PaymentMethod__c = 'Contado';
        update orden3;
        
    }
    
    @isTest
    static void getOrdersByAccountTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        input.put('AccountId', acc.Id);
        String methodName = 'getOrdersByAccountId';
        Boolean result;
        Test.startTest();
        	PVU_PagosNoAbonadosUtils pna = new PVU_PagosNoAbonadosUtils();
        	result = pna.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(True, result,'Hubo algún problema en la ejecución del método');
        System.AssertEquals(3, ((List<Object>)output.get('Ordenes')).size(), 'La cantidad de ordenes no coincide con las creadas');
    }
    
    @isTest
    static void getOrdersAvailableTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        input.put('AccountId', acc.Id);
        String methodName = 'getOrdersAvailable';
        Boolean result;
        Test.startTest();
        	PVU_PagosNoAbonadosUtils pna = new PVU_PagosNoAbonadosUtils();
        	result = pna.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(True, result,'Hubo algún problema en la ejecución del método');
        System.AssertEquals(2, ((List<Object>)output.get('Ordenes')).size(), 'La cantidad de ordenes no coincide con las creadas');
    }
    
    @isTest
    static void exceptionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        input.put('AccountId', Decimal.valueOf(1111));
        String methodName = 'getOrdersAvailable';
        Boolean result;
        Test.startTest();
        	PVU_PagosNoAbonadosUtils pna = new PVU_PagosNoAbonadosUtils();
        	result = pna.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(False, result,'No se capturaron excepciones');
        System.AssertEquals(False,String.isBlank((String)output.get('error')), 'El nodo error de salida está vacío');
        
    }
}