@IsTest
public class CATPromotionTSVExporterTest {

    @IsTest
    public static void testPromoTSVExporter() {

        // Crear productos (plan móvil)
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

        Product2 prod2 = new Product2 (
            Name='Product 2', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer',
            vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert prod2;

        // Crear Promociones
        vlocity_cmt__Promotion__c promo1 = new vlocity_cmt__Promotion__c(
            Name = 'Promo1', 
            vlocity_cmt__Code__c = 'CodePromo1', 
            vlocity_cmt__IsOrderable__c = true, 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Bundle', 
            CAT_FirstMonthDiscount__c = false, 
            CAT_FirstMonthDiscountPercent__c = null
        );
        insert promo1;

        vlocity_cmt__Promotion__c promo2 = new vlocity_cmt__Promotion__c(
            Name = 'Promo2', 
            vlocity_cmt__Code__c = 'CodePromo2', 
            vlocity_cmt__IsOrderable__c = true, 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Bundle', 
            CAT_FirstMonthDiscount__c = false, 
            CAT_FirstMonthDiscountPercent__c = null
        );
        insert promo2;

        // Crear Item de Promoción
        vlocity_cmt__PromotionItem__c promoItem1 = new vlocity_cmt__PromotionItem__c(
            vlocity_cmt__PromotionId__c = promo1.Id, 
            vlocity_cmt__ProductId__c = prod1.Id
        );
        insert promoItem1;

        vlocity_cmt__PromotionItem__c promoItem2 = new vlocity_cmt__PromotionItem__c(
            vlocity_cmt__PromotionId__c = promo2.Id, 
            vlocity_cmt__ProductId__c = prod2.Id
        );
        insert promoItem2;


        // Crear Regla
        vlocity_cmt__Rule__c rule = new vlocity_cmt__Rule__c(
            Name = 'Regla',
            vlocity_cmt__Description__c = 'Descripción Regla', 
            vlocity_cmt__IsActive__c = true
        );
        insert rule;

        // Crear Asignación de Regla
        vlocity_cmt__RuleAssignment__c ruleAssignment = new vlocity_cmt__RuleAssignment__c(
            vlocity_cmt__ObjectId__c = promo1.Id, 
            vlocity_cmt__RuleId__c = rule.Id
        );
        insert ruleAssignment;

        // Crear datos de prueba para PricingVariable
        vlocity_cmt__PricingVariable__c pricingVariable1 = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos
            Name = 'Recurring Monthly Std Price',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC',
            vlocity_cmt__RecurringFrequency__c = 'Monthly'
        );
        insert pricingVariable1;

        vlocity_cmt__PricingVariable__c pricingVariable2 = new vlocity_cmt__PricingVariable__c( // Pricing Variable con impuestos
            Name = 'Recurring Monthly Std Price Including Taxes',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_INC_TAXES',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con impuestos'
        );
        insert pricingVariable2;

        vlocity_cmt__PricingVariable__c pricingVariable3 = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos
            Name = 'Recurring Monthly Std Price Adjustment Abs',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_ADJ_ABS',
            vlocity_cmt__RecurringFrequency__c = 'Monthly'
        );
        insert pricingVariable3;

        vlocity_cmt__PricingVariable__c pricingVariable4 = new vlocity_cmt__PricingVariable__c( // Pricing Variable con impuestos
            Name = 'Recurring Monthly Std Price Adj Abs Inc Taxes',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_ADJ_ABS_INC_TAXES',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con impuestos'
        );
        insert pricingVariable4;

        //Crear datos de prueba para PricingElement
        vlocity_cmt__PricingElement__c pricingElement1 = new vlocity_cmt__PricingElement__c( // Pricing Element sin impuestos
            Name = 'Test pricingElement1',
            vlocity_cmt__Amount__c = 955.55,
            vlocity_cmt__PricingVariableId__c = pricingVariable1.Id,
            vlocity_cmt__AdjustmentValue__c = null
        );
        insert pricingElement1;

        vlocity_cmt__PricingElement__c pricingElement2 = new vlocity_cmt__PricingElement__c( // Pricing Element con impuestos
            Name = 'Test pricingElement2',
            vlocity_cmt__Amount__c = 1000,
            vlocity_cmt__PricingVariableId__c = pricingVariable2.Id,
            vlocity_cmt__AdjustmentValue__c = null
        );
        insert pricingElement2;

        vlocity_cmt__PricingElement__c pricingElement3 = new vlocity_cmt__PricingElement__c( // Pricing Element con impuestos
            Name = 'Test pricingElement3',
            vlocity_cmt__AdjustmentValue__c = -95.5,
            vlocity_cmt__PricingVariableId__c = pricingVariable3.Id
        );
        insert pricingElement3;

        vlocity_cmt__PricingElement__c pricingElement4 = new vlocity_cmt__PricingElement__c( // Pricing Element con impuestos
            Name = 'Test pricingElement4',
            vlocity_cmt__AdjustmentValue__c = -100,
            vlocity_cmt__PricingVariableId__c = pricingVariable4.Id
        );
        insert pricingElement4;

        // Crear datos de prueba para PriceList
            vlocity_cmt__PriceList__c priceList = new vlocity_cmt__PriceList__c (
                Name = 'Cliente Masivo', 
                vlocity_cmt__Code__c = 'PL-B2C');
        insert priceList;

        // Crear datos de prueba para PriceListEntry
        vlocity_cmt__PriceListEntry__c priceListEntry1 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin impuestos (plan movil 1)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = true,
            vlocity_cmt__EffectiveUntilDate__c = null,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement1.Id,
            vlocity_cmt__ProductId__c = prod1.Id,
            vlocity_cmt__PromotionId__c = promo1.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple1',
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry1;

        vlocity_cmt__PriceListEntry__c priceListEntry2 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 1)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = true,
            vlocity_cmt__EffectiveUntilDate__c = null,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement2.Id,
            vlocity_cmt__ProductId__c = prod1.Id,
            vlocity_cmt__PromotionId__c = promo1.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple2', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry2;

        vlocity_cmt__PriceListEntry__c priceListEntry3 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = true,
            vlocity_cmt__EffectiveUntilDate__c = null,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement1.Id,
            vlocity_cmt__ProductId__c = prod2.Id,
            vlocity_cmt__PromotionId__c = promo2.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple3', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry3;

        vlocity_cmt__PriceListEntry__c priceListEntry4 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = true,
            vlocity_cmt__EffectiveUntilDate__c = null,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement2.Id,
            vlocity_cmt__ProductId__c = prod2.Id,
            vlocity_cmt__PromotionId__c = promo2.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple4', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry4;

        vlocity_cmt__PriceListEntry__c priceListEntry5 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement3.Id,
            vlocity_cmt__PromotionId__c = promo1.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple5', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry5;

        vlocity_cmt__PriceListEntry__c priceListEntry6 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement4.Id,
            vlocity_cmt__PromotionId__c = promo1.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple6', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry6;

        vlocity_cmt__PriceListEntry__c priceListEntry7 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement3.Id,
            vlocity_cmt__PromotionId__c = promo2.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple7', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry7;

        vlocity_cmt__PriceListEntry__c priceListEntry8 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con impuestos (plan movil 2)
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement4.Id,
            vlocity_cmt__PromotionId__c = promo2.Id,
            vlocity_cmt__DisplayText__c = 'Display Text ple8', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry8;

        // Crear lista de Product Ids
        List<Id> promoIds = new List<String>{
            promo1.Id,
            promo2.Id
        };

        // Llamar al método que se está probando
        List<List<Id>> promotionIdsList = new List<List<Id>>{promoIds};
        List<Id> contentVersionId = CATPromotionTSVExporter.generatePromotionTSV(promotionIdsList);
        List<ContentVersion> contentVersionList = [SELECT Id FROM ContentVersion WHERE Id = :contentVersionId[0] WITH USER_MODE];
        System.assertEquals(1, contentVersionList.size(),'No se generó archivo tsv en ContentVersion.');
    }
}