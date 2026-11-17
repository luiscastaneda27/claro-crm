/*-----------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Test Class for CATBorrarPromosObligatorias
Code Coverage:  NA
History
<Date>            <Author>                <Description>             <Version>
29-Abr-25         Fernanda Maldonado                                inicial version
-------------------------------------------------------------------------------------*/
@isTest
public class CATBorrarPromosObligatoriasTest {
    @IsTest
    static void testBorrarPromosObligatorias() {

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

        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'PLAN-CODE', Family = 'Mobile', vlocity_cmt__Type__c = 'Plan', vlocity_cmt__SubType__c = 'Pospaid', vlocity_cmt__IsOrderable__c = true);
        insert prod1;

        // Create test data for Promotions
        List<vlocity_cmt__Promotion__c> promotions = new List<vlocity_cmt__Promotion__c>();
        for (Integer i = 0; i < 3; i++) {
            promotions.add(new vlocity_cmt__Promotion__c(
                Name = 'Test Promotion ' + i,
                CAT_PromotionClass__c = 'Bundle',
                vlocity_cmt__Code__c = 'TestPromo' + i,
                CAT_Type__c = 'Estandar',
                vlocity_cmt__IsActive__c = true,
                vlocity_cmt__IsOrderable__c = true,
                vlocity_cmt__EffectiveStartDate__c = System.today().addDays(-1),
                vlocity_cmt__EffectiveEndDate__c = System.today().addDays(1)
                ));
        }
        insert promotions;

        // Create test data for Pricebooks
        Pricebook2 testPricebook =  new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'TestPricebook', IsActive = true);
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = testPricebook.Id,
            Product2Id = prod1.Id, UnitPrice = 10, vlocity_cmt__RecurringPrice__c = 5, IsActive = true);
        insert pbe1;

        // Create test data for Orders
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Order(
                Name = 'Test Order ' + i,EffectiveDate=System.today(),status='Draft',AccountId = testAccount.Id, Pricebook2Id = TestPricebook.Id, vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,FVU_TiendaRetiroDaneCode__c='88001',FVU_BodegaEnvioDaneCode__c='88001',vlocity_cmt__DeliveryMethod__c='Immediatepickup')
            );
        }
        insert orders;
        
        //Obtener Id orden
        Order order = [SELECT Id FROM Order LIMIT 1];
        System.debug('order: ' + order);

        //Obtener promociones
        List<vlocity_cmt__Promotion__c> promotionCodesList = [SELECT vlocity_cmt__Code__c FROM vlocity_cmt__Promotion__c];
        System.debug('promotionCodesList: ' + promotionCodesList);
        
        vlocity_cmt__Promotion__c promo = [SELECT Id FROM vlocity_cmt__Promotion__c LIMIT 1];
        System.debug('promo: ' + promo);

        // Create test data for OrderAppliedPromotion
        vlocity_cmt__OrderAppliedPromotion__c appliedPromo = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = order.Id, 
            vlocity_cmt__PromotionId__c = promo.Id
        );
        insert appliedPromo;

        List<String> promotionCodes = new List<String>();
        for(vlocity_cmt__Promotion__c promotion: promotionCodesList){
            promotionCodes.add(promotion.vlocity_cmt__Code__c);
        }
        String promotionsCode = String.join(promotionCodes, ',');
        System.debug('promotionsCode: ' + promotionsCode);

        //LLamar método
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('PromotionsList', promotionsCode);
        input.put('OrderId', order.Id);

        try {
            Test.startTest();
            // Call the method to be tested
            CATBorrarPromosObligatorias catBorrarPromosObligatorias = new CATBorrarPromosObligatorias();
            catBorrarPromosObligatorias.invokeMethod('borrarPromosObligatorias', input, output, options);
        
            CATBorrarPromosObligatorias catBorrarPromo = new CATBorrarPromosObligatorias();
            catBorrarPromo.invokeMethod('borrarPromo', input, output, options);
            Test.stopTest();

            // Verify if promos were deleted
            List<vlocity_cmt__OrderAppliedPromotion__c> appliedPromos = [SELECT Id, vlocity_cmt__PromotionId__c FROM vlocity_cmt__OrderAppliedPromotion__c WHERE vlocity_cmt__OrderId__c = :order.Id WITH USER_MODE];
            // Assert
            Assert.areEqual(1, appliedPromos.size(), 'Promotions were deleted');

        } catch (Exception e) {
            System.debug('Error in invoke method: ' + e.getMessage());
            throw e;

        }
    }
}