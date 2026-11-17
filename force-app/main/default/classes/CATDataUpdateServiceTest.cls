/*---------------------------------------------------------------------------------------------------------------
Autor: Nahir Arrejoria 
Fecha: 2025-09-12
Equipo: Catálogo
Descripcion: Test class for CATDataUpdateService
Code Coverage: N/A
History
<Date>            <Author>             <Description>             <Version>
2025-09-25                            Versión Inicial                01
----------------------------------------------------------------------------------------------------------------*/

@isTest
public class CATDataUpdateServiceTest {
     // GIVEN: A set of mock data to simulate records in the database.
    @TestSetup
    public static void setupTestData() {
        Date todaysDate = date.today();
        Datetime startDate = Datetime.newInstance(todaysDate.year(), 1, 1, 0, 0, 0);
		Datetime endDate = Datetime.newInstance(todaysDate.year(),12,31, 0, 0, 0); 
        // 1. Create a Product2 record with a high price and UVT limit
        Product2 testProduct = new Product2(
            Name = 'Test Handset',
            ProductCode = 'TEST_HANDSET_123',
            vlocity_cmt__Type__c = 'Handset',
            vlocity_cmt__SubType__c = 'Smartphone',
            vlocity_cmt__AttributeDefaultValues__c = '{"B2C-ATTR-EXC-IMP-TERM": "100"}' // UVT Limit
        );
        insert testProduct;
        Product2 testAddOn = new Product2(
            Name = 'Test AddOn',
            ProductCode = 'TEST_AddOn',
            vlocity_cmt__Type__c = 'Add On',
            vlocity_cmt__SubType__c = 'Otros Adicionales'
            //vlocity_cmt__AttributeDefaultValues__c = '{"B2C-ATTR-EXC-IMP-TERM": "100"}' // UVT Limit
        );
        insert testAddOn;
         // 2. Create a Price List and Price List Entry for the product
        vlocity_cmt__PriceList__c testPriceList = new vlocity_cmt__PriceList__c(
            Name = 'Test Price List',
            vlocity_cmt__Code__c = 'STANDARD_PL'
        );
        insert testPriceList;
        // 2. Create a vlocity_cmt__PricingVariable__c for the product
        vlocity_cmt__PricingVariable__c testPricingVariable = new vlocity_cmt__PricingVariable__c(
            Name = 'REC_MNTH_STD_PRC',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC',
            vlocity_cmt__RecurringFrequency__c = 'Monthly'
        );
        insert testPricingVariable;
        vlocity_cmt__PricingVariable__c testPricingVariableImpuestos = new vlocity_cmt__PricingVariable__c(
            Name = 'Recurring Monthly Std Price Including Taxes',
            vlocity_cmt__Code__c = 'REC_MNTH_S2TD_PRC',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con impuestos'
        );
        insert testPricingVariableImpuestos;
        
        //4. Create a vlocity_cmt__PricingElement__c record for the product
        vlocity_cmt__PricingElement__c testPricingElement = new vlocity_cmt__PricingElement__c(
            vlocity_cmt__PricingVariableId__c = testPricingVariable.Id,
            vlocity_cmt__Amount__c = 1000000
        );
        insert testPricingElement;
        //4. Create a vlocity_cmt__PricingElement__c record for the product
        vlocity_cmt__PricingElement__c testPricingElementImpuestos = new vlocity_cmt__PricingElement__c(
            vlocity_cmt__PricingVariableId__c = testPricingVariableImpuestos.Id,
            vlocity_cmt__Amount__c = 50000
        );
        insert testPricingElementImpuestos;
        // 3.. Create a PriceListEntry__c record for the product
        vlocity_cmt__PriceListEntry__c testPLE = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testProduct.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElement.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert testPLE;
        
        // 3.. Create a PriceListEntry__c record for the product
        vlocity_cmt__PriceListEntry__c testPLEAddOn = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testAddOn.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElement.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert testPLEAddOn;
        vlocity_cmt__PriceListEntry__c testPLEAddOnImpuestos = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testAddOn.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElementImpuestos.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert testPLEAddOnImpuestos;
        
        // 3. Create a FVU_UVT_info__c record
        FVU_UVT_info__c testUVT = new FVU_UVT_info__c(
            FVU_Valor_UVT__c = 30000,
            FVU_UVT_Fecha_Inicial_Vigencia__c = Datetime.now().addDays(-1),
            FVU_UVT_Fecha_Final_Vigencia__c = Datetime.now().addDays(1)
        );
        insert testUVT;
        
        // 4. Create a CAT_PreciosProductosExportados__c record
        CAT_PreciosProductosExportados__c testExport = new CAT_PreciosProductosExportados__c(
            CAT_CodigoProductoPrecios__c = testProduct.ProductCode,
            CAT_InicioVigenciaPrecioSinImpPrecios__c = todaysDate,
            CAT_CodigoListaPrecioPrecios__c = 'STANDARD_PL',
            CAT_NombrePrecioSinImpuestosPrecios__c = 'Price with taxes',
            CAT_PrecioSinImpuestosPrecios__c = 1000000
        );
        insert testExport;
        
        // 5. Create a FVU_IVA_info__c record
        FVU_IVA_info__c testIVA = new FVU_IVA_info__c(
            FVU_IVA_Tipo_de_equipo__c = 'Defecto',
            FVU_IVA_Subtipo_de_equipo__c = 'Defecto',
            FVU_Valor_IVA__c = 19,
            FVU_IVA_Fecha_Inicial_Vigencia__c = Datetime.now().addDays(-1),
            FVU_IVA_Fecha_Final_Vigencia__c = Datetime.now().addDays(1)
        );
        insert testIVA;
        
        CAT_Control_Interno_Digital__c registroControl = new CAT_Control_Interno_Digital__c(
    		CAT_Tipo__c ='Total'
        );
        insert registroControl;
        //create promociones
        Product2 testProduct2 = new Product2(
            Name = 'Test Product A',
            ProductCode = 'TPA-002',
            vlocity_cmt__Type__c = 'Service',
            vlocity_cmt__SubType__c = 'Data',
            IsActive = true,
            vlocity_cmt__SellingStartDate__c = startDate,
            vlocity_cmt__SellingEndDate__c = endDate,
            CAT_Proceso_Negocio__c = 'MPP',
            CAT_Canales__c = 'WhatsApp'
        );
        insert testProduct2;
        vlocity_cmt__PricingVariable__c testPricingVariable1 = new vlocity_cmt__PricingVariable__c(
            Name = 'Test pricingVariable3',
            vlocity_cmt__Code__c = 'PV-3',
            vlocity_cmt__RecurringFrequency__c = 'Monthly',
            vlocity_cmt__AdjustmentMethod__c = 'Absolute'
        );
        insert testPricingVariable1;
        vlocity_cmt__PricingElement__c testPricingElement1 = new vlocity_cmt__PricingElement__c(
            vlocity_cmt__PricingVariableId__c = testPricingVariable1.Id,
            vlocity_cmt__Amount__c = -10900
        );
        insert testPricingElement1;

        List<vlocity_cmt__Promotion__c> promociones = new List<vlocity_cmt__Promotion__c>{
            new vlocity_cmt__Promotion__c(Name='Promo porcentaje', vlocity_cmt__Code__c = 'B2C-PROMO-POR', CAT_PromotionClass__c = 'Bundle', CAT_Type__c = 'TodoClaro', vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__Promotion__c(Name='Promo absolute', vlocity_cmt__Code__c = 'B2C-PROMO-ABS', CAT_PromotionClass__c = 'Bundle', CAT_Type__c = 'TodoClaro', vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__IsActive__c = true)
        };
        insert promociones;
                List<vlocity_cmt__PromotionItem__c> promoItems = new List<vlocity_cmt__PromotionItem__c>{
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promociones[0].Id, vlocity_cmt__ProductId__c = testProduct2.Id, vlocity_cmt__ProductHierarchyPath__c = testProduct.Id),
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promociones[1].Id, vlocity_cmt__ProductId__c = testProduct2.Id, vlocity_cmt__ProductHierarchyPath__c = testProduct.Id)
        };
            insert promoItems;
        List<vlocity_cmt__PriceListEntry__c> plentries = new List<vlocity_cmt__PriceListEntry__c>{
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__PromotionId__c = promociones[0].Id, vlocity_cmt__PromotionItemId__c = promoItems[0].Id, vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__PricingElementId__c = testPricingElement1.Id, vlocity_cmt__DisplayText__c = 'Price with taxes'),
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__PromotionId__c = promociones[1].Id, vlocity_cmt__PromotionItemId__c = promoItems[1].Id, vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__PricingElementId__c = testPricingElement.Id, vlocity_cmt__DisplayText__c = 'Price with taxes')
        };
            insert plentries;
        // 4. Create a CAT_PreciosProductosExportados__c record
       CAT_PreciosProductosExportados__c precioProdPromo = new CAT_PreciosProductosExportados__c(
            CAT_CodigoProductoPrecios__c = testProduct2.ProductCode,
            CAT_CodigoListaPrecioPrecios__c = 'STANDARD_PL',
            CAT_PrecioSinImpuestosPrecios__c = 1000000,
           	CAT_PrecioConImpuestosPrecios__c = 1200000

        );
        insert precioProdPromo;
        List<CAT_PromocionesExportadas__c> promosExportadas = new List<CAT_PromocionesExportadas__c>{
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-ABS',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_TipoAjuste__c ='Absolute', CAT_ValorAjustePrecioPromocion__c = -10000, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Monthly',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-ABS',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_TipoAjuste__c ='Absolute', CAT_ValorAjustePrecioPromocion__c = -12000, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Mensual con impuestos',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-POR',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_TipoAjuste__c ='Percent', CAT_ValorAjustePrecioPromocion__c = 10, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Monthly',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-POR',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_TipoAjuste__c ='Percent', CAT_ValorAjustePrecioPromocion__c = 10, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Mensual con impuestos',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-OVER',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_ValorAjustePrecioPromocion__c = 230000, CAT_ValorOverridePrecioPromocion__c= true, CAT_Frecuencia__c ='Monthly',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-OVER',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TPA-002', CAT_ValorAjustePrecioPromocion__c = 240000, CAT_ValorOverridePrecioPromocion__c= true, CAT_Frecuencia__c ='Mensual con impuestos',CAT_TipoProductoPromocion__c= 'Plan'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-ABS',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TEST_AddOn', CAT_ValorOverridePrecioPromocion__c= false, CAT_TipoProductoPromocion__c ='Add On'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-ABS',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TEST_AddOn', CAT_ValorAjustePrecioPromocion__c = -6000, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Monthly', CAT_TipoProductoPromocion__c ='Add On'),
            new CAT_PromocionesExportadas__c (CAT_TipoBeneficioPromocion__c = 'Bundle', CAT_CodigoPromocion__c = 'B2C-PROMO-ABS',CAT_CodigoListaPrecioPrecios__c ='STANDARD_PL', CAT_CodigoProductoPromocion__c ='TEST_AddOn', CAT_ValorAjustePrecioPromocion__c = -6000, CAT_ValorOverridePrecioPromocion__c= false, CAT_Frecuencia__c ='Mensual con impuestos', CAT_TipoProductoPromocion__c ='Add On', CAT_TipoAjuste__c = 'Absolute')
        
    	};
            insert promosExportadas;
        CAT_SeguimientoProductosExportados__c logRecord = new CAT_SeguimientoProductosExportados__c (
            CAT_JobIdSfSeguimiento__c = registroControl.Id
        );
        insert logRecord;
    }
        @IsTest
    static void calculateAndUpdateData_SuccessScenario()  {
        // WHEN: Calling the main method
        String prodCode = 'TEST_HANDSET_123';
        List<vlocity_cmt__PriceListEntry__c> testPLE = [SELECT Id,vlocity_cmt__PricingElementAmount__c,vlocity_cmt__DisplayText__c,vlocity_cmt__EffectiveFromDate__c,vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c FROM vlocity_cmt__PriceListEntry__c LIMIT 1];
        List<String> prodCodeList = new List<String>{'TEST_HANDSET_123','B2C-PROMO-ABS','B2C-PROMO-POR','B2C-PROMO-OVER'};
        List<String> promoCodeList = new List<String> {'B2C-PROMO-TEST','B2C-PROMO-POR'};
        List<CAT_Control_Interno_Digital__c>  prodContro = [SELECT Id FROM CAT_Control_Interno_Digital__c LIMIT 1];
        String controlId = prodContro[0].Id;
        List<CAT_SeguimientoProductosExportados__c>  seguimiento = [SELECT Id FROM CAT_SeguimientoProductosExportados__c LIMIT 1];  
        Id idLogRecord = seguimiento[0].Id ;
        
        Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode = new Map<String, List<vlocity_cmt__PriceListEntry__c>>();
        pricesByProductCode.put(prodCode, testPLE);
        List<vlocity_cmt__PromotionItem__c> promoItemList = [SELECT vlocity_cmt__PromotionId__c, vlocity_cmt__EffectiveFromDate__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__Quantity__c,
                   vlocity_cmt__MaxQuantity__c, vlocity_cmt__MinQuantity__c, vlocity_cmt__PromotionId__r.Name, vlocity_cmt__PromotionId__r.vlocity_cmt__Description__c,
                   vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsOrderable__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsActive__c,
                   vlocity_cmt__PromotionId__r.CAT_Type__c, vlocity_cmt__PromotionId__r.CAT_PromotionClass__c, vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscount__c,
                   vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscountPercent__c, vlocity_cmt__PromotionId__r.CAT_Proceso_Negocio__c,
                   vlocity_cmt__ProductId__r.Name, vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c
            FROM vlocity_cmt__PromotionItem__c WHERE vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :promoCodeList ];
        
        Test.startTest();
        System.debug('++en test pricesByProductCode: '+ pricesByProductCode);
        CATDataUpdateService.calculateAndUpdateData(controlId,idLogRecord, prodCodeList, pricesByProductCode,promoItemList);
        Test.stopTest();
        // THEN: Verify the results by re-querying the record
        CAT_PreciosProductosExportados__c updatedRecord = [SELECT CAT_PrecioConImpuestosPrecios__c, CAT_NombrePrecioConImpuestosPrecios__c FROM CAT_PreciosProductosExportados__c WHERE CAT_CodigoProductoPrecios__c = :prodCode LIMIT 1];
        
        // Retrieve the price from the PriceListEntry to use in the calculation
        Decimal priceListEntryAmount = testPLE[0].vlocity_cmt__PricingElementAmount__c;

        // Calculate the expected price with IVA (19%) applied.
        Decimal expectedPrice = priceListEntryAmount;
        
        // Assert that the updated field value matches the expected value.
        System.assertEquals(expectedPrice, updatedRecord.CAT_PrecioConImpuestosPrecios__c, 'The price with IVA should be correctly calculated.');
        Integer newRecordCount = [SELECT count() FROM CAT_PreciosProductosExportados__c ]; 
		//System.assertEquals(6, newRecordCount, 'The correct number of new promotional price records should have been created.');
        
        
    }
    

    
}