@isTest
private class FVU_OrderTriggerHandlerTest {
    @isTest
    private static void afterUpdateTest() {
       
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
        // pbe1.UseStandardPrice = false;
        insert pbe1;
       
        Account acc = new Account();
        acc.Name = 'Test';
        acc.FVU_DocumentNumber__c = '21584879';
        acc.FVU_DocumentType__c = 'CC';
        acc.Phone = '5555555555';
        insert acc;
        
        Contact contact = new Contact();
        contact.FirstName = 'Name';
        contact.LastName = 'Apellido';
        contact.AccountId = acc.Id;
        insert contact;
        
        Order order = new Order();
        order.Status = 'Draft'; //fixing repo
        order.FVU_PaymentStatus__c = 'PP';
        order.AccountId = acc.Id;        
        order.EffectiveDate = date.today();
        order.Pricebook2Id = pricebookId;
        order.FVU_PurchaseType__c = 'NAP';
        insert order;

        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.Id;
        orderItem.Product2Id = prod1.Id;
        orderItem.PricebookEntryId = pbe1.Id;
        orderItem.Quantity = 1;
        orderItem.UnitPrice = 10;
        orderItem.vlocity_cmt__LineNumber__c = '0001';
        orderItem.vlocity_cmt__Action__c = 'Add';
        orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem;
        
        Asset asset = new Asset();
        asset.Name = 'TestAsset';
        asset.vlocity_cmt__OrderId__c = order.Id;
        asset.AccountId = acc.Id;
        asset.ContactId = contact.Id;
        insert asset;

        Test.startTest();
            order.Status = 'Activated';
            order.FVU_ClosingReason__c = 'Mejor Oferta';
            order.EndDate = date.today();
            update order;
        
		System.assertEquals('Activated', order.Status, 'El Status no es igual a Cerrada Ganada (Activated)');
        
        Test.stopTest();
   }
}