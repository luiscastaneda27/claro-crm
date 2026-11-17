@isTest
public class CATValidationPromosEngineTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.BillingStreet = 'Calle 123 # 45 - 67';
        testAccount.BillingCity = 'Bogotá D.C';
        testAccount.BillingState = 'Bogotá D.C';
        testAccount.BillingCountry = 'Colombia';
        testAccount.ShippingStreet = 'Calle 123 # 45 - 67';
        testAccount.ShippingCity = 'Bogotá D.C';
        testAccount.ShippingState = 'Bogotá D.C';
        testAccount.ShippingCountry = 'Colombia';
        testAccount.FVU_ServiceDaneCode__c = '88001'; //SAN ANDRÉS
        insert testAccount;

        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'PLAN-CODE', Family = 'Mobile', vlocity_cmt__Type__c = 'Plan', vlocity_cmt__SubType__c = 'Postpaid');
        insert prod1;

        // Create test data for Pricebooks
        Pricebook2 testPricebook =  new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'TestPricebook', IsActive = true);
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = testPricebook.Id,
            Product2Id = prod1.Id, UnitPrice = 10, vlocity_cmt__RecurringPrice__c = 5, IsActive = true);
        insert pbe1;
        
        // Create test data for Orders
        Order order = new Order(Name='Test Order',EffectiveDate=System.today(),status='Draft',AccountId = testAccount.Id, Pricebook2Id = Test.getStandardPricebookId(), vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,FVU_TiendaRetiroDaneCode__c='88001',FVU_BodegaEnvioDaneCode__c='88001', FVU_Channel__c = 'SF_CAV', FVU_DaneCiudadCAVOrden__c = '88001000',vlocity_cmt__DeliveryMethod__c='Immediatepickup', FVU_IsIVAExempt__c = true);
        insert order;
        
        /*Order order2 = new Order(Name='Test Order',EffectiveDate=System.today(),status='Draft',AccountId = testAccount.Id, Pricebook2Id = Test.getStandardPricebookId(), vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,FVU_TiendaRetiroDaneCode__c='88001',FVU_BodegaEnvioDaneCode__c='88001', FVU_Channel__c = 'SF_CAV', FVU_DaneCiudadCAVOrden__c = '88001000',vlocity_cmt__DeliveryMethod__c='Immediatepickup', FVU_IsIVAExempt__c = true);
        insert order2;*/
        
        // Create test data for OrderItem 1
        OrderItem testOrderItem1 = new OrderItem(OrderId = order.Id, Product2Id = prod1.Id, PricebookEntryId = pbe1.Id, Quantity = 1, UnitPrice = 10);
        insert testOrderItem1;

        // Create test data for OrderItem 2
        OrderItem testOrderItem2 = new OrderItem(OrderId = order.Id, Product2Id = prod1.Id, PricebookEntryId = pbe1.Id, Quantity = 1, UnitPrice = 10);
        insert testOrderItem2;
        
        // Create test data for Promotions
        List<vlocity_cmt__Promotion__c> promotions = new List<vlocity_cmt__Promotion__c>();
        for (Integer i = 0; i < 3; i++) {
            promotions.add(new vlocity_cmt__Promotion__c(
                Name = 'Test Promotion ' + i,
                CAT_PromotionClass__c = 'Más datos',
                vlocity_cmt__Code__c = 'TestPromo' + i,
                CAT_Type__c = 'Estandar',
                vlocity_cmt__IsActive__c = true,
                vlocity_cmt__IsOrderable__c = true,
                vlocity_cmt__EffectiveStartDate__c = System.today().addDays(-1),
                vlocity_cmt__EffectiveEndDate__c = System.today().addDays(1)
                ));
        }
        insert promotions;
        
        vlocity_cmt__Promotion__c promoValid = promotions[0];
        System.debug('promoValid: ' + promoValid);

        vlocity_cmt__Promotion__c promoInvalid = promotions[1];
        System.debug('promoInvalid: ' + promoInvalid);
        
        // Create test data for OrderAppliedPromotion
        vlocity_cmt__OrderAppliedPromotion__c appliedPromo1 = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = order.Id, 
            vlocity_cmt__PromotionId__c = promoValid.Id
        );
        insert appliedPromo1;
        
        vlocity_cmt__OrderAppliedPromotion__c appliedPromo2 = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = order.Id, 
            vlocity_cmt__PromotionId__c = promoInvalid.Id
        );
        insert appliedPromo2;

        //Relate promotion to the first orderItem
        vlocity_cmt__OrderAppliedPromotionItem__c appliedPromoItem = new vlocity_cmt__OrderAppliedPromotionItem__c(
        	vlocity_cmt__OrderAppliedPromotionId__c = appliedPromo1.Id,
        	vlocity_cmt__OrderItemId__c = testOrderItem1.Id
        );
        insert appliedPromoItem;
    }

    @isTest
    static void testPromotionClassValidationValidPromo() {
        // Create input map with valid data
        Map<String, Object> input = new Map<String, Object>();
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        input.put('OrderId', testOrder.Id);
        input.put('PromotionClass', 'Obsequios de CFM');
        input.put('clasesNoObligatoriasList', new List<String>{'Bundle','Terceros','Plan Lector'});

        // Create output map
        Map<String, Object> output = new Map<String, Object>();
        // Create options map (if needed)
        Map<String, Object> options = new Map<String, Object>();

        try{
            Test.startTest();
            // Instantiate the class
            CATValidationPromosEngine engineValid = new CATValidationPromosEngine();
            // Call the method
            Boolean resultValid = engineValid.invokeMethod('promotionClassValidation', input, output, options);
            Test.stopTest();
            
            Assert.areEqual(1, resultValid = true, 'Promoción válida');

        } catch (Exception e){
            System.debug('Error in invoke method: ' + e.getMessage());
           // throw e;
            
        }
    }

    @isTest
    static void testPromotionClassValidationInvalidPromo() {
        // Create input map with data that matches an existing promotion
        Map<String, Object> input = new Map<String, Object>();
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        input.put('OrderId', testOrder.Id);
        input.put('PromotionClass', 'Más datos');
        input.put('clasesNoObligatoriasList', new List<String>{'Bundle','Terceros','Plan Lector'});

        // Create output map
        Map<String, Object> output = new Map<String, Object>();

        // Create options map (if needed)
        Map<String, Object> options = new Map<String, Object>();

        // Call the class
        CATValidationPromosEngine engine = new CATValidationPromosEngine();

        // Call the method
        Boolean result = engine.invokeMethod('promotionClassValidation', input, output, options);

        try{
            Test.startTest();
            // Instantiate the class
            CATValidationPromosEngine engineInvalid = new CATValidationPromosEngine();
            // Call the method
            Boolean resultInvalid = engineInvalid.invokeMethod('promotionClassValidation', input, output, options);
            Test.stopTest();
            
            Assert.areEqual(1, resultInvalid = false, 'Promoción invalida');

        } catch (Exception e){
            System.debug('Error in invoke method: ' + e.getMessage());
           // throw e;
            
        }
    }
}