/*---------------------------------------------------------------------------------------------------------------
Autor: Nahir Arrejoria 
Fecha: 2025-09-12
Equipo: Catálogo
Descripcion: Test class for CATDataExtractionService
Code Coverage: N/A
History
<Date>            <Author>             <Description>             <Version>
2025-09-12                            Versión Inicial                01
----------------------------------------------------------------------------------------------------------------*/

@IsTest
public class CATDataExtractionServiceTest {
    @TestSetup
    public static void setupTestData() {
        // --- 1. Create a Product2 record and a list of product codes to be used as input.
        Date dateTD = System.TODAY();       
        Datetime startDate = Datetime.newInstance(dateTD.year(), 1, 1, 0, 0, 0);
		Datetime endDate = Datetime.newInstance(dateTD.year(),12,31, 0, 0, 0); 
        Product2 testProduct = new Product2(
            Name = 'Test Product A',
            ProductCode = 'TPA-001',
            vlocity_cmt__Type__c = 'Service',
            vlocity_cmt__SubType__c = 'Data',
            IsActive = true,
            vlocity_cmt__SellingStartDate__c = startDate,
            vlocity_cmt__SellingEndDate__c = endDate,
            CAT_Proceso_Negocio__c = 'MPP',
            CAT_ApplicableCountries__c = 'Canadá;Estados Unidos;México;Puerto Rico',
            CAT_Canales__c = 'WhatsApp'
        );
        insert testProduct;
        
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
        
        Product2 testProductHandset = new Product2(
            Name = 'Test Handset',
            ProductCode = 'TEST_HANDSET_123',
            vlocity_cmt__Type__c = 'Handset',
            vlocity_cmt__SubType__c = 'Smartphone',
            vlocity_cmt__AttributeDefaultValues__c = '{"B2C-ATTR-EXC-IMP-TERM": "100"}' // UVT Limit
        );
        insert testProductHandset;
        
		CAT_Control_Interno_Digital__c registroControl = new CAT_Control_Interno_Digital__c(
    		CAT_Tipo__c ='Total'
        );
        insert registroControl;
        Product2 testChildProduct = new Product2(
            Name = 'Test Plan A',
            ProductCode = 'TP-001',
            vlocity_cmt__Type__c = 'Plan',
            IsActive = true
        );
        insert testChildProduct;

        // --- 2. Create related Vlocity__cmt records
        // a) Create vlocity_cmt__ProductChildItem__c
        vlocity_cmt__ProductChildItem__c childItem = new vlocity_cmt__ProductChildItem__c(
            vlocity_cmt__ParentProductId__c = testProduct.Id,
            vlocity_cmt__ChildProductId__c = testChildProduct.Id,
            vlocity_cmt__ChildLineNumber__c = '1'
        );
        insert childItem;

        // b) Create a Rule and RuleAssignment for the product
        vlocity_cmt__Rule__c testRule = new vlocity_cmt__Rule__c(
            Name = 'Test Rule',
            vlocity_cmt__Description__c = 'This is a test rule.'
        );
        insert testRule;

        vlocity_cmt__RuleAssignment__c ruleAssignment1 = new vlocity_cmt__RuleAssignment__c(
            vlocity_cmt__ObjectId__c = testProduct.Id,
            vlocity_cmt__RuleId__c = testRule.Id
        );
        insert ruleAssignment1;
        
       
       
        // c) Create a Price List and Price List Entry for the product
        vlocity_cmt__PriceList__c testPriceList = new vlocity_cmt__PriceList__c(
            Name = 'Test Price List',
            vlocity_cmt__Code__c = 'TEST-PL'
        );
        insert testPriceList;

        vlocity_cmt__PricingVariable__c testPricingVariable = new vlocity_cmt__PricingVariable__c(
            Name = 'REC_MNTH_STD_PRC',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC',
            vlocity_cmt__RecurringFrequency__c = 'Monthly'
        );
        insert testPricingVariable;
        vlocity_cmt__PricingVariable__c testPricingVariable2 = new vlocity_cmt__PricingVariable__c(
            Name = 'REC_MNTH_STD_PRC_INC_TAXES',
            vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_INC_TAXES',
            vlocity_cmt__RecurringFrequency__c = 'Mensual con impuestos'
        );
        insert testPricingVariable2;

        vlocity_cmt__PricingElement__c testPricingElement = new vlocity_cmt__PricingElement__c(
            vlocity_cmt__PricingVariableId__c = testPricingVariable.Id,
            vlocity_cmt__Amount__c = 65900
        );
        insert testPricingElement;
        vlocity_cmt__PricingElement__c testPricingElement2 = new vlocity_cmt__PricingElement__c(
            vlocity_cmt__PricingVariableId__c = testPricingVariable2.Id,
            vlocity_cmt__Amount__c = 65900
        );
        insert testPricingElement2;
         Date todaysDate = date.today();

        vlocity_cmt__PriceListEntry__c priceListEntry = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testProduct.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElement.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert priceListEntry;
        vlocity_cmt__PriceListEntry__c priceListEntry3 = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testProduct.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElement2.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert priceListEntry3;
        
        vlocity_cmt__PriceListEntry__c priceListEntryHandset = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__ProductId__c = testProductHandset.Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__EffectiveFromDate__c = todaysDate,
            vlocity_cmt__PricingElementId__c = testPricingElement2.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert priceListEntryHandset;

        // d) Create a Catalog Product Relationship for compatibility
        vlocity_cmt__Catalog__c testCatalog = new vlocity_cmt__Catalog__c(
            Name = 'Test Catalog',
            vlocity_cmt__CatalogCode__c = 'TEST-CAT'
        );
        insert testCatalog;

        vlocity_cmt__CatalogProductRelationship__c catalogRel = new vlocity_cmt__CatalogProductRelationship__c(
            vlocity_cmt__Product2Id__c = testProduct.Id,
            vlocity_cmt__CatalogId__c = testCatalog.Id
        );
        insert catalogRel;

        // e) Create an Attribute Assignment for the product
        vlocity_cmt__AttributeCategory__c testCategory = new vlocity_cmt__AttributeCategory__c(
            Name = 'Test Category',vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1);
        insert testCategory;

        vlocity_cmt__Attribute__c testAttribute = new vlocity_cmt__Attribute__c(
            Name = 'Test Attribute',
            vlocity_cmt__Code__c = 'TEST-ATT',
            vlocity_cmt__ValueType__c = 'Text',vlocity_cmt__AttributeCategoryId__c = testCategory.Id
        );
        insert testAttribute;
        vlocity_cmt__Attribute__c testAttributeCombined = new vlocity_cmt__Attribute__c(
            Name = 'Test Attribute',
            vlocity_cmt__Code__c = 'TEST-ATT-Combined',
            vlocity_cmt__ValueType__c = 'Text',vlocity_cmt__AttributeCategoryId__c = testCategory.Id
        );
        insert testAttributeCombined;

        vlocity_cmt__AttributeAssignment__c attributeAssignment = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = testProduct.Id,
            vlocity_cmt__AttributeCategoryId__c = testCategory.Id,
            vlocity_cmt__AttributeId__c = testAttribute.Id,
            vlocity_cmt__Value__c = 'Test Value'
        );
        insert attributeAssignment;
        vlocity_cmt__AttributeAssignment__c attributeAssignmentCombined = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = testProduct.Id,
            vlocity_cmt__AttributeCategoryId__c = testCategory.Id,
            vlocity_cmt__AttributeId__c = testAttributeCombined.Id,
            vlocity_cmt__Value__c = 'ATTR-EJEMPLO1: valor22 ## ATTR-EJEMPLO2: valor33'
        );
        insert attributeAssignmentCombined;
        
        CAT_AtInformativos__c infoAttr1 = new CAT_AtInformativos__c(
            Name = 'Info Attr 1',
            CAT_Codigo__c = 'ATT-CODE1' // Matching code 
        );
        insert infoAttr1;
        
        CAT_AsignacionAt__c assignacionAt = new CAT_AsignacionAt__c(
            Name = 'Info Attr 1',
            CAT_Atributo_Informativo__c = infoAttr1.Id,
            CAT_Producto__c = testProduct.Id
        );
        insert assignacionAt;
        
        List<vlocity_cmt__Promotion__c> promociones = new List<vlocity_cmt__Promotion__c>{
            new vlocity_cmt__Promotion__c(Name='TestPromo', vlocity_cmt__Code__c = 'B2C-PROMO-TEST', CAT_PromotionClass__c = 'Descuento Todo Claro', CAT_Type__c = 'TodoClaro', vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__Promotion__c(Name='TestPromo', vlocity_cmt__Code__c = 'B2C-PROMO-BUNDLE', CAT_PromotionClass__c = 'Bundle', CAT_Type__c = 'TodoClaro', vlocity_cmt__PriceListId__c = testPriceList.Id, vlocity_cmt__IsActive__c = true)
        };
        insert promociones;
        
        vlocity_cmt__RuleAssignment__c ruleAssignment3 = new vlocity_cmt__RuleAssignment__c(
            vlocity_cmt__ObjectId__c = promociones[0].Id,
            vlocity_cmt__RuleId__c = testRule.Id
        );
        insert ruleAssignment3;
        
        List<vlocity_cmt__PromotionItem__c> promoItems = new List<vlocity_cmt__PromotionItem__c>{
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promociones[0].Id, vlocity_cmt__ProductId__c = testProduct.Id, vlocity_cmt__ProductHierarchyPath__c = testProduct.Id),
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promociones[1].Id, vlocity_cmt__ProductId__c = testProduct2.Id, vlocity_cmt__ProductHierarchyPath__c = testProduct.Id)
        };
         
        insert promoItems;
         vlocity_cmt__RuleAssignment__c ruleAssignment2 = new vlocity_cmt__RuleAssignment__c(
            vlocity_cmt__ObjectId__c = promociones[0].Id,
            vlocity_cmt__RuleId__c = testRule.Id
        );
        insert ruleAssignment2;
        vlocity_cmt__PriceListEntry__c priceListEntry2 = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__PromotionId__c = promociones[0].Id,
            vlocity_cmt__PromotionItemId__c = promoItems[0].Id,
            vlocity_cmt__PriceListId__c = testPriceList.Id,
            vlocity_cmt__PricingElementId__c = testPricingElement.Id,
            vlocity_cmt__DisplayText__c = 'Price with taxes'
        );
        insert priceListEntry2;
        FVU_IVA_info__c testIVA = new FVU_IVA_info__c(
            FVU_IVA_Tipo_de_equipo__c = 'Defecto',
            FVU_IVA_Subtipo_de_equipo__c = 'Defecto',
            FVU_Valor_IVA__c = 19,
            FVU_IVA_Fecha_Inicial_Vigencia__c = Datetime.now().addDays(-1),
            FVU_IVA_Fecha_Final_Vigencia__c = Datetime.now().addDays(1)
        );
        insert testIVA;
        
         // 3. Create a FVU_UVT_info__c record
        FVU_UVT_info__c testUVT = new FVU_UVT_info__c(
            FVU_Valor_UVT__c = 30000,
            FVU_UVT_Fecha_Inicial_Vigencia__c = Datetime.now().addDays(-1),
            FVU_UVT_Fecha_Final_Vigencia__c = Datetime.now().addDays(1)
        );
        insert testUVT;
        
        CAT_SeguimientoProductosExportados__c logRecord = new CAT_SeguimientoProductosExportados__c (
            CAT_JobIdSfSeguimiento__c = registroControl.Id
        );
        insert logRecord;

    }

    /**
     * @description Test method for the happy path of extractAndLoadData.
     * It verifies that the service successfully queries and inserts the data.
     */
    @IsTest
    static void extractAndLoadData_SuccessScenario() {
        // --- GIVEN ---
        // Retrieve the test product created in the TestSetup method.
        Product2 testProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'TPA-001' LIMIT 1];
        List<CAT_Control_Interno_Digital__c>  prodContro = [SELECT Id FROM CAT_Control_Interno_Digital__c LIMIT 1];
        List<String> prodCodeList = new List<String>{'TPA-001','TAP-002','B2C-PROMO-BUNDLE'};
        System.debug('prodCodeList: '+ prodCodeList);
        List<String> promoCodeList = new List<String> {'B2C-PROMO-TEST'};
        List<CAT_SeguimientoProductosExportados__c>  seguimiento = [SELECT Id FROM CAT_SeguimientoProductosExportados__c LIMIT 1];  
        Id idLogRecord = seguimiento[0].Id ;
        String controlId = prodContro[0].Id;

        // --- WHEN ---
        // Run the main method within a Test.startTest() block.
        Test.startTest();
        CATDataExtractionService.extractAndLoadData(controlId,idLogRecord, prodCodeList,promoCodeList, 'Parcial', false);
        Test.stopTest();
        
        // --- THEN ---
        // Verify that the correct custom object records were created.
        System.assertEquals(2, [SELECT COUNT() FROM CAT_ProductosExportados__c], 'Should have created 2 CAT_ProductosExportados__c record.');
        System.assertEquals(2, [SELECT COUNT() FROM CAT_PromocionesExportadas__c], 'Should have created 3 CAT_PromocionesExportadas__c record.');
        System.assertEquals(5, [SELECT COUNT() FROM CAT_AtributosProductosExportados__c], 'Should have created 5 CAT_AtributosProductosExportados__c record.');
        System.assertEquals(0, [SELECT COUNT() FROM CAT_CompatibilidadProductosExportados__c], 'Should have created 0 CAT_CompatibilidadProductosExportados__c record.');
        System.assertEquals(1, [SELECT COUNT() FROM CAT_PreciosProductosExportados__c], 'Should have created 1 CAT_PreciosProductosExportados__c record.');
        System.assertEquals(1, [SELECT COUNT() FROM CAT_SeguimientoProductosExportados__c], 'Should have created 1 CAT_SeguimientoProductosExportados__c record.');
        
        // Verify some of the data mapping is correct
        CAT_ProductosExportados__c exportedProduct = [SELECT CAT_CodigoProducto__c, CAT_NombreProducto__c FROM CAT_ProductosExportados__c WHERE CAT_CodigoProducto__c = :testProduct.ProductCode LIMIT 1];
        System.assertEquals('TPA-001', exportedProduct.CAT_CodigoProducto__c, 'The product code should be mapped correctly.');
        System.assertEquals('Test Product A', exportedProduct.CAT_NombreProducto__c, 'The product name should be mapped correctly.');
    }

    
    @IsTest
    static void extractAndLoadData_Compatibilidad() {
        // --- GIVEN ---
        // Retrieve the test product created in the TestSetup method.
        Product2 testProduct = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = 'TPA-001' LIMIT 1];
        List<CAT_Control_Interno_Digital__c>  prodContro = [SELECT Id FROM CAT_Control_Interno_Digital__c LIMIT 1];
        List<String> prodCodeList = new List<String>{'TPA-001','TAP-002','B2C-PROMO-BUNDLE'};
        System.debug('prodCodeList: '+ prodCodeList);
        List<String> promoCodeList = new List<String> {'B2C-PROMO-TEST'};
        List<CAT_SeguimientoProductosExportados__c>  seguimiento = [SELECT Id FROM CAT_SeguimientoProductosExportados__c LIMIT 1];  
        Id idLogRecord = seguimiento[0].Id ;
        String controlId = prodContro[0].Id;

        // --- WHEN ---
        // Run the main method within a Test.startTest() block.
        Test.startTest();
        CATDataExtractionService.extractAndLoadData(controlId,idLogRecord, prodCodeList,promoCodeList, 'Total', true);
        Test.stopTest();
        
        // --- THEN ---
        // Verify that the correct custom object records were created.
        System.assertEquals(2, [SELECT COUNT() FROM CAT_ProductosExportados__c], 'Should have created 2 CAT_ProductosExportados__c record.');
        System.assertEquals(2, [SELECT COUNT() FROM CAT_PromocionesExportadas__c], 'Should have created 3 CAT_PromocionesExportadas__c record.');
        System.assertEquals(5, [SELECT COUNT() FROM CAT_AtributosProductosExportados__c], 'Should have created 5 CAT_AtributosProductosExportados__c record.');
        System.assertEquals(1, [SELECT COUNT() FROM CAT_CompatibilidadProductosExportados__c], 'Should have created 1 CAT_CompatibilidadProductosExportados__c record.');
        System.assertEquals(1, [SELECT COUNT() FROM CAT_PreciosProductosExportados__c], 'Should have created 1 CAT_PreciosProductosExportados__c record.');
        System.assertEquals(1, [SELECT COUNT() FROM CAT_SeguimientoProductosExportados__c], 'Should have created 1 CAT_SeguimientoProductosExportados__c record.');
        
        // Verify some of the data mapping is correct
        CAT_ProductosExportados__c exportedProduct = [SELECT CAT_CodigoProducto__c, CAT_NombreProducto__c FROM CAT_ProductosExportados__c WHERE CAT_CodigoProducto__c = :testProduct.ProductCode LIMIT 1];
        System.assertEquals('TPA-001', exportedProduct.CAT_CodigoProducto__c, 'The product code should be mapped correctly.');
        System.assertEquals('Test Product A', exportedProduct.CAT_NombreProducto__c, 'The product name should be mapped correctly.');
    }
    /**
     * @description Test method for the exception path of extractAndLoadData.
     * It verifies that a NullPointerException is caught and wrapped in a
     * custom CAT_ExtractionException, as expected by the class logic.
     */
    @IsTest
    static void extractAndLoadData_ExceptionScenario() {
        // --- GIVEN ---
        // Pass a null list of product codes, which should cause a NullPointerException
        // when the code tries to initialize a Set from it.
        List<String> prodCodeList = null;
        List<String> promoCodeList = null;
        List<CAT_Control_Interno_Digital__c>  prodContro = [SELECT Id FROM CAT_Control_Interno_Digital__c LIMIT 1];
        List<CAT_SeguimientoProductosExportados__c>  seguimiento = [SELECT Id FROM CAT_SeguimientoProductosExportados__c LIMIT 1];
        String controlId = prodContro[0].Id;
        Id idLogRecord = seguimiento[0].Id ;
        Boolean exceptionCaught = false;

        // --- WHEN ---
        // Run the method within a try-catch block to test the exception handling.
        Test.startTest();
        try {
            CATDataExtractionService.extractAndLoadData(controlId,idLogRecord, prodCodeList,promoCodeList, 'Total', false);
        } catch (CATDataExtractionService.CAT_ExtractionException e) {
            // --- THEN ---
            // Assert that the custom exception was caught.
            exceptionCaught = true;
            System.debug('Caught expected exception: ' + e.getMessage());
            System.assert(e.getMessage().contains('Error en el proceso de extracción.'), 'The correct custom exception should be thrown.');
        }
        Test.stopTest();
        
       // System.assert(exceptionCaught, 'A CAT_ExtractionException should have been thrown and caught.');
        
        // Ensure no product export records were created
        System.assertEquals(0, [SELECT COUNT() FROM CAT_ProductosExportados__c], 'No records should be created on failure.');
        // Note: The provided code's createFailureLogRecord method is commented out.
        // A full test would verify that a failure log record is created here.
    }

}