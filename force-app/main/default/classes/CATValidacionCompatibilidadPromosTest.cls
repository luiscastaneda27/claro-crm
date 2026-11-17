/*-----------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Test Class for CATValidacionCompatibilidadPromos
Code Coverage:  NA
History
<Date>            <Author>                <Description>             <Version>
29-Abr-25         Fernanda Maldonado                                inicial version
-------------------------------------------------------------------------------------*/

@isTest
public class CATValidacionCompatibilidadPromosTest {
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

        // Crear producto (plan móvil)
        Product2 prod1 = new Product2 (
            Name='Product 1', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer',
            vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert prod1;

        // Crear Promociones
        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(
            Name = 'Promo1', 
            vlocity_cmt__Code__c = 'B2C-PROMO-TEST', 
            vlocity_cmt__IsOrderable__c = true, 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Terceros', 
            CAT_FirstMonthDiscount__c = false
        );
        insert promo;

        vlocity_cmt__Promotion__c promo1 = new vlocity_cmt__Promotion__c(
            Name = 'Promo1', 
            vlocity_cmt__Code__c = 'B2C-PROMO-MULTAST', 
            vlocity_cmt__IsOrderable__c = true, 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Terceros', 
            CAT_FirstMonthDiscount__c = false
        );
        insert promo1;

        vlocity_cmt__Promotion__c promo2 = new vlocity_cmt__Promotion__c(
            Name = 'Promo2', 
            vlocity_cmt__Code__c = 'B2C-PROMO-CON25V55PETS', 
            vlocity_cmt__IsOrderable__c = true, 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Bundle', 
            CAT_FirstMonthDiscount__c = false
        );
        insert promo2;
        
        // Crear PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod1.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Crear Orden
        Order order = new Order(
            Name='Test Order',
            EffectiveDate=System.today(),
            Status='Draft',
            AccountId = testAccount.Id, 
            Pricebook2Id = Test.getStandardPricebookId(), 
            vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,
            FVU_TiendaRetiroDaneCode__c='88001',
            FVU_BodegaEnvioDaneCode__c='88001', 
            FVU_Channel__c = 'SF_CAV', 
            FVU_DaneCiudadCAVOrden__c = '88001000',
            vlocity_cmt__DeliveryMethod__c='Immediatepickup', 
            FVU_IsIVAExempt__c = true
        );
        insert order;

        // Crear OrderItem
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = prod1.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 10,
            vlocity_cmt__LineNumber__c = '0001',
            vlocity_cmt__Action__c = 'Add',
            vlocity_cmt__ProvisioningStatus__c = 'New',
            vlocity_cmt__ServiceAccountId__c = testAccount.Id,
            FVU_OneTimeTotalIncTaxes__c = 2000000
        );
        insert orderItem;

        /*Crear OrderAppliedPromotion - Promo 1
        vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion1 = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = order.Id,
            vlocity_cmt__PromotionId__c = promo1.Id
        );*/

        //Crear OrderAppliedPromotion - Promo 2
        vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion2 = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = order.Id,
            vlocity_cmt__PromotionId__c = promo2.Id
        );

        insert orderAppliedPromotion2;
    }

    @isTest
    static void testPromocionNoEnMatriz() {
        // Simula las variables
        Map<String, Object> testMatrixData = new Map<String, Object>();
        String promosObligatorias = 'B2C-PROMO-CON25V55PETS,B2C-PROMO-CON25V55SALUD';
        String promosIncompatibles = 'B2C-PROMO-CON25V55MULT,B2C-PROMO-CON25V63MULT';
        
        vlocity_cmt__Promotion__c promo = [SELECT vlocity_cmt__Code__c FROM vlocity_cmt__Promotion__c WHERE vlocity_cmt__Code__c = 'B2C-PROMO-TEST' LIMIT 1];
        Order order = [SELECT Id FROM Order LIMIT 1];
        
        // Ejecutar método y validar
        Test.startTest();
        String resultValid = CATValidacionCompatibilidadPromos.validacionCompatibilidadPromos(promo.vlocity_cmt__Code__c, order.Id, testMatrixData, promosObligatorias, promosIncompatibles);
        Test.stopTest();

        //Assert.areEqual(1, resultValid = 'isValid', 'Promoción válida');
    }
    
    @isTest
    static void testPromoValida() {
        // Simula las variables
        Map<String, Object> testMatrixData = new Map<String, Object>();
        String promosObligatorias = 'B2C-PROMO-CON25V55PETS,B2C-PROMO-CON25V55SALUD';
        String promosIncompatibles = 'B2C-PROMO-CON25V55MULT,B2C-PROMO-CON25V63MULT';
        
        vlocity_cmt__Promotion__c promo = [SELECT vlocity_cmt__Code__c FROM vlocity_cmt__Promotion__c WHERE vlocity_cmt__Code__c = 'B2C-PROMO-TEST' LIMIT 1];
        Order order = [SELECT Id FROM Order LIMIT 1];
        
        // Ejecutar método y validar
        Test.startTest();
        String resultValid = CATValidacionCompatibilidadPromos.validacionCompatibilidadPromos(promo.vlocity_cmt__Code__c, order.Id, testMatrixData, promosObligatorias, promosIncompatibles);
        Test.stopTest();

        Assert.areEqual('', resultValid, 'Promoción válida, no hay mensaje de error');
    }
}