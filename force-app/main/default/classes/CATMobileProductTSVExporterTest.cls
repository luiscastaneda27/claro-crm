@IsTest
public class CATMobileProductTSVExporterTest {

    @IsTest
    public static void testMobileProductTSVExporter() {

        // Crear productos (plan móvil y add on)
        Product2 prod1 = new Product2 (
            Name='Product 1', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            Description = 'Descripción Larga',
            Short_Description__c = 'Descripción Corta'
        );
        insert prod1;

        Product2 prod2 = new Product2 (
            Name='Product 2', 
            ProductCode = 'AddOn',
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Add On', 
            vlocity_cmt__SubType__c = 'Datos'
        );
        insert prod2;

        // Crear Regla
        vlocity_cmt__Rule__c rule = new vlocity_cmt__Rule__c(
            Name = 'Regla',
            vlocity_cmt__Description__c = 'Descripción Regla', 
            vlocity_cmt__IsActive__c = true
        );
        insert rule;

        // Crear Asignación de Regla
        vlocity_cmt__RuleAssignment__c ruleAssignment = new vlocity_cmt__RuleAssignment__c(
            vlocity_cmt__ObjectId__c = prod1.Id, 
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
            vlocity_cmt__DisplayText__c = 'Display Text ple4', 
            vlocity_cmt__EffectiveFromDate__c = Date.today()
        );
        insert priceListEntry4;

        // Crear lista de Product Ids
        List<Id> prodIds = new List<String>{
            prod1.Id,
            prod2.Id
        };

        // Llamar al método que se está probando
        List<List<Id>> productIdsList = new List<List<Id>>{prodIds};
        List<Id> contentVersionId = CATMobileProductTSVExporter.generateMobileProductTSV(productIdsList);
        List<ContentVersion> contentVersionList = [SELECT Id FROM ContentVersion WHERE Id = :contentVersionId[0] WITH USER_MODE];
        System.assertEquals(1, contentVersionList.size(),'No se generó archivo tsv en ContentVersion.');
    }
}