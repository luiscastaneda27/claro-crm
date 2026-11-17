@isTest
public with sharing class FVU_CloneOrderTest {

    @testSetup
    static void setupData() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Product2 product = new Product2 (
            Name='Product 1', 
            ProductCode = 'ABCDEF12345'
        );
        insert product;

        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pricebookEntry = new PricebookEntry(      
            Product2Id = product.Id,
            Pricebook2Id = pricebookId,
            UnitPrice = 1,
            IsActive = true
        );
        insert pricebookEntry;   

        Order originalOrder = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            Pricebook2Id = pricebookId,
            EffectiveDate = Date.today(),
            AccountId = account.Id
        );
        insert originalOrder;

        OrderItem item1 = new OrderItem(
            OrderId = originalOrder.Id,
            Quantity = 1,
            PricebookEntryId = pricebookEntry.Id,
            UnitPrice = 100.00
        );
        
        OrderItem item2 = new OrderItem(
            OrderId = originalOrder.Id,
            Quantity = 2,
            PricebookEntryId = pricebookEntry.Id,
            UnitPrice = 50.00
        );

        insert new List<OrderItem> { item1, item2 };

        vlocity_cmt__OrderPayment__c orderPayment = new vlocity_cmt__OrderPayment__c(
            vlocity_cmt__OrderId__c = originalOrder.Id,
            vlocity_cmt__PaymentAmount__c = 200.00
        );
        insert orderPayment;

        // Create a Promotion Record
        vlocity_cmt__Promotion__c promotion =  new vlocity_cmt__Promotion__c(
            Name = 'Test Promotion',
            vlocity_cmt__Code__c = 'PENDIENTE', 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Descuento'
        );
        insert promotion;

        // Create a test vlocity_cmt__OrderAppliedPromotion__c
        vlocity_cmt__OrderAppliedPromotion__c appliedPromotion = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = originalOrder.Id,
            vlocity_cmt__PromotionId__c = promotion.Id,
            Name = 'Test Applied Promotion'
        );
        insert appliedPromotion;

        // Create a test vlocity_cmt__OrderAppliedPromotionItem__c
        vlocity_cmt__OrderAppliedPromotionItem__c promotionItem = new vlocity_cmt__OrderAppliedPromotionItem__c(
            vlocity_cmt__OrderItemId__c = item1.Id, 
            vlocity_cmt__OrderAppliedPromotionId__c = appliedPromotion.Id, 
            Name = 'Test Promotion Item'
        );
        insert promotionItem;

        // Create a test vlocity_cmt__OrderPriceAdjustment__c
        vlocity_cmt__OrderPriceAdjustment__c priceAdjustment = new vlocity_cmt__OrderPriceAdjustment__c(
            vlocity_cmt__OrderId__c = originalOrder.Id, 
            vlocity_cmt__OrderItemId__c = item1.Id, 
            vlocity_cmt__OrderAppliedPromotionId__c = appliedPromotion.Id,
            vlocity_cmt__PromotionId__c = promotion.Id, 
            Name = 'Test Price Adjustment'
        );
        insert priceAdjustment;

    }

    @isTest
    static void cloneOrderSuccessTest() {
        Order originalOrder = [SELECT Id, Status FROM Order LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => originalOrder.Id,
            'status' => 'DeliveryAndActivated'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FVU_CloneOrder cloneOrderClass = new FVU_CloneOrder();
        Boolean result = cloneOrderClass.invokeMethod('cloneOrder', inputMap, outputMap, options);

        // Assert the clone was successful
        System.assert(result == true, 'The cloneOrder method should return true.');
        System.assert(outputMap.containsKey('orderId'), 'The cloned order Id should be present in outputMap.');

        // Verify the cloned Order
        Id clonedOrderId = (Id) outputMap.get('orderId');
        Order clonedOrder = [SELECT Id, Status, FVU_ClonedOrderParent__c FROM Order WHERE Id = :clonedOrderId LIMIT 1];
        System.assertEquals(originalOrder.Id, clonedOrder.FVU_ClonedOrderParent__c, 'The original order Id should be set as the cloned parent.');

        // Verify cloned OrderItems
        List<OrderItem> clonedOrderItems = [SELECT Id, OrderId FROM OrderItem WHERE OrderId = :clonedOrderId];
        System.assertEquals(2, clonedOrderItems.size(), 'Cloned order items should match the number of original items.');

        // Verify cloned Order Payment
        vlocity_cmt__OrderPayment__c clonedOrderPayment = [SELECT Id, vlocity_cmt__OrderId__c FROM vlocity_cmt__OrderPayment__c WHERE vlocity_cmt__OrderId__c = :clonedOrderId LIMIT 1];
        System.assertNotEquals(null, clonedOrderPayment, 'Cloned order payment should be created.');
    }

    @isTest
    static void cloneOrderOrderNotFoundTest() {
        // Prepare inputMap with a non-existing Order Id
        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => '8012K00001ABCDe',
            'status' => 'DeliveryAndActivated'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Create instance of FVU_CloneOrder class
        FVU_CloneOrder cloneOrderClass = new FVU_CloneOrder();

        // Call the invokeMethod to clone the order
        Boolean result = cloneOrderClass.invokeMethod('cloneOrder', inputMap, outputMap, options);

        // Assert the clone failed
        System.assert(result == false, 'The cloneOrder method should return false.');
        System.assert(outputMap.containsKey('error'), 'The outputMap should contain the error message.');
    }
    
    @IsTest
	static void testExceptions() {        
        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => '8012K00001ABCDe',
            'status' => null
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        FVU_CloneOrder cloneOrderClass = new FVU_CloneOrder();
        Boolean result = cloneOrderClass.invokeMethod('cloneOrder', inputMap, outputMap, options);
		System.assertEquals(false, result, 'The method should return false when the input is not valid.');

		List<sObject> records = cloneOrderClass.getRecords('8012K00001ABCDe', new OrderItem(), 'NonExistentField');
		System.assertEquals(null, records, 'The method should return null when the query throws a System.QueryException');

		sObject singleRecord = cloneOrderClass.getSingleRecord('8012K00001ABCDe', new OrderItem(), 'NonExistentField', '');
		System.assertEquals(null, records, 'The method should return null when the query throws a System.QueryException');

	}

}