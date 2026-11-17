@IsTest
public class CATBundlePriceProcessorTest {

    @IsTest
    public static void testProcessBundlePLE() {

        // Crear productos (plan móvil y add on)
        Product2 prod1 = new Product2 (
            Name='Product 1', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid'
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

        // Crear datos de prueba para PricingVariable
        vlocity_cmt__PricingVariable__c pricingVariable1 = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos y sin adjustment method
            Name = 'Test pricingVariable1',
            vlocity_cmt__Code__c = 'PV-1',
            vlocity_cmt__RecurringFrequency__c = 'Monthly'
        );
        insert pricingVariable1;

        vlocity_cmt__PricingVariable__c pricingVariable2 = new vlocity_cmt__PricingVariable__c( // Pricing Variable con impuestos y sin adjustment method
            Name = 'Test pricingVariable2',
            vlocity_cmt__Code__c = 'PV-2',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con Impuestos'
        );
        insert pricingVariable2;

        vlocity_cmt__PricingVariable__c pricingVariable3 = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos y con adjustment method = absolute
            Name = 'Test pricingVariable3',
            vlocity_cmt__Code__c = 'PV-3',
            vlocity_cmt__RecurringFrequency__c = 'Monthly',
            vlocity_cmt__AdjustmentMethod__c = 'Absolute'
        );
        insert pricingVariable3;

        vlocity_cmt__PricingVariable__c pricingVariable4 = new vlocity_cmt__PricingVariable__c( // Pricing Variable con impuestos y con adjustment method = absolute
            Name = 'Test pricingVariable4',
            vlocity_cmt__Code__c = 'PV-4',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con Impuestos',
            vlocity_cmt__AdjustmentMethod__c = 'Absolute'
        );
        insert pricingVariable4;

        vlocity_cmt__PricingVariable__c pricingVariable5 = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos y con adjustment method = percent
            Name = 'Test pricingVariable5',
            vlocity_cmt__Code__c = 'PV-5',
            vlocity_cmt__RecurringFrequency__c = 'Monthly',
            vlocity_cmt__AdjustmentMethod__c = 'Percent'
        );
        insert pricingVariable5;

        vlocity_cmt__PricingVariable__c pricingVariable6 = new vlocity_cmt__PricingVariable__c( // Pricing Variable con impuestos y con adjustment method = percent
            Name = 'Test pricingVariable6',
            vlocity_cmt__Code__c = 'PV-6',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con Impuestos',
            vlocity_cmt__AdjustmentMethod__c = 'Percent'
        );
        insert pricingVariable6;

        //Crear datos de prueba para PricingElement
        vlocity_cmt__PricingElement__c pricingElement1 = new vlocity_cmt__PricingElement__c( // Pricing Element sin ajuste y sin impuestos
            Name = 'Test pricingElement1',
            vlocity_cmt__Amount__c = 55064.05,
            vlocity_cmt__PricingVariableId__c = pricingVariable1.Id
        );
        insert pricingElement1;

        vlocity_cmt__PricingElement__c pricingElement2 = new vlocity_cmt__PricingElement__c( // Pricing Element sin ajuste y con impuestos
        Name = 'Test pricingElement2',
        vlocity_cmt__Amount__c = 65900,
        vlocity_cmt__PricingVariableId__c = pricingVariable2.Id
        );
        insert pricingElement2;

        vlocity_cmt__PricingElement__c pricingElement3 = new vlocity_cmt__PricingElement__c( // Pricing Element con ajuste absolute y sin impuestos
            Name = 'Test pricingElement3',
            vlocity_cmt__Amount__c = 0,
            vlocity_cmt__AdjustmentValue__c = -930.56,
            vlocity_cmt__PricingVariableId__c = pricingVariable3.Id
        );
        insert pricingElement3;

        vlocity_cmt__PricingElement__c pricingElement4 = new vlocity_cmt__PricingElement__c( // Pricing Element con ajuste absolute y con impuestos
            Name = 'Test pricingElement4',
            vlocity_cmt__Amount__c = 0,
            vlocity_cmt__AdjustmentValue__c = -1000,
            vlocity_cmt__PricingVariableId__c = pricingVariable4.Id
        );
        insert pricingElement4;

        vlocity_cmt__PricingElement__c pricingElement5 = new vlocity_cmt__PricingElement__c( // Pricing Element con ajuste percent y sin impuestos
            Name = 'Test pricingElement5',
            vlocity_cmt__Amount__c = 0,
            vlocity_cmt__AdjustmentValue__c = 15,
            vlocity_cmt__PricingVariableId__c = pricingVariable5.Id
        );
        insert pricingElement5;

        vlocity_cmt__PricingElement__c pricingElement6 = new vlocity_cmt__PricingElement__c( // Pricing Element con ajuste percent y con impuestos
            Name = 'Test pricingElement6',
            vlocity_cmt__Amount__c = 0,
            vlocity_cmt__AdjustmentValue__c = 15,
            vlocity_cmt__PricingVariableId__c = pricingVariable6.Id
        );
        insert pricingElement6;

        // Crear datos de prueba para PriceList
            vlocity_cmt__PriceList__c priceList = new vlocity_cmt__PriceList__c (
                Name = 'Cliente Masivo', 
                vlocity_cmt__Code__c = 'PL-B2C');
        insert priceList;

        // Crear datos de prueba para PriceListEntry
        vlocity_cmt__PriceListEntry__c priceListEntry1 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con override, sin ajuste y sin impuestos
            vlocity_cmt__IsOverride__c = true,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement1.Id
        );
        insert priceListEntry1;

        vlocity_cmt__PriceListEntry__c priceListEntry2 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry con override, sin ajuste y con impuestos
            vlocity_cmt__IsOverride__c = true,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement2.Id
        );
        insert priceListEntry2;

        vlocity_cmt__PriceListEntry__c priceListEntry3 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, sin ajuste y sin impuestos (plan movil)
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement1.Id,
            vlocity_cmt__ProductId__c = prod1.Id
        );
        insert priceListEntry3;

        vlocity_cmt__PriceListEntry__c priceListEntry4 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, sin ajuste y con impuestos (plan movil)
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement2.Id,
            vlocity_cmt__ProductId__c = prod1.Id
        );
        insert priceListEntry4;

        vlocity_cmt__PriceListEntry__c priceListEntry5 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, con ajuste absolute y sin impuestos
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement3.Id
        );
        insert priceListEntry5;

        vlocity_cmt__PriceListEntry__c priceListEntry6 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, con ajuste absolute y con impuestos
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement4.Id
        );
        insert priceListEntry6;

        vlocity_cmt__PriceListEntry__c priceListEntry7 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, con ajuste percent y sin impuestos
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement5.Id
        );
        insert priceListEntry7;

        vlocity_cmt__PriceListEntry__c priceListEntry8 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, con ajuste percent y con impuestos
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement6.Id
        );
        insert priceListEntry8;

        vlocity_cmt__PriceListEntry__c priceListEntry9 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, sin ajuste y sin impuestos (add on)
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement1.Id,
            vlocity_cmt__ProductId__c = prod2.Id
        );
        insert priceListEntry9;

        vlocity_cmt__PriceListEntry__c priceListEntry10 = new vlocity_cmt__PriceListEntry__c( // PriceListEntry sin override, sin ajuste y con impuestos (add on)
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElement2.Id,
            vlocity_cmt__ProductId__c = prod2.Id
        );
        insert priceListEntry10;

        // Crear lista de PriceListEntry Ids
        List<String> priceListEntryIds = new List<String>{
            priceListEntry1.Id,
            priceListEntry2.Id,
            priceListEntry3.Id,
            priceListEntry4.Id,
            priceListEntry5.Id,
            priceListEntry6.Id,
            priceListEntry7.Id,
            priceListEntry8.Id,
            priceListEntry9.Id,
            priceListEntry10.Id
        };

        // Llamar al método que se está probando
        List<List<String>> priceListEntryIdsList = new List<List<String>>{priceListEntryIds};
        List<List<Decimal>> result = CATBundlePriceProcessor.processBundlePLE(priceListEntryIdsList);
    }
}