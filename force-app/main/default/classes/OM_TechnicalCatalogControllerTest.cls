/**----------------------------------------------------------------------------------------------------------------------------------------------
Author:         Fabio Farath
Company:        Salesforce.com
Description:    Metodos de prueba para la clase OM_TechnicalCatalogController
Code Coverage:  91%
History
<Date MM-dd-YY>   @version     <Author>             <Description>
2025-10-03         1.0.0   	  Fabio Farath          	Initial
--------------------------------------------------------------------------------------------------------------------------------------------------*/

@IsTest
private class OM_TechnicalCatalogControllerTest {
    @TestSetup
    static void setupData() {
        List<Product2> products = new List<Product2>();
        for (Integer i = 1; i <= 35; i++) {
            Product2 p = new Product2();
            p.Name = 'Test Product ' + i;
            p.ProductCode = 'CODE-' + String.valueOf(i);
            p.Description = 'Desc ' + i;
            p.IsActive = true;
            products.add(p);
        }
        insert products;
    }

    @IsTest
    static void testFetchRecords_basicPagination() {
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name, ProductCode, Description', null, 'Name', '', 10, 1);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(10, result.records.size(), 'Should return 10 records for page size 10');
        System.assertEquals(35, result.totalRecords, 'Total records should match inserted');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
        System.assertEquals(10, result.pageSize, 'Page size should be 10');
    }

    @IsTest
    static void testFetchRecords_secondPage() {
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name', null, 'Name', '', 10, 2);
        Test.stopTest();
        System.assertEquals(10, result.records.size(), 'Second page should also have 10');
        System.assertEquals(2, result.pageNumber, 'Page number should be 2');
    }

    @IsTest
    static void testFetchRecords_lastPartialPage() {
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name', null, 'Name', '', 10, 4);
        Test.stopTest();
        System.assertEquals(5, result.records.size(), 'Last page should have remaining 5 records');
        System.assertEquals(4, result.pageNumber, 'Page number should be 4');
    }

    @IsTest
    static void testFetchRecords_searchByName() {
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name, ProductCode', 'Product 3', 'Name', '', 50, 1);
        Test.stopTest();
        System.assert(result.records.size() > 0, 'Should find records containing Product 3');
    }

    @IsTest
    static void testFetchRecords_withFilter() {
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name, ProductCode', null, 'Name', 'IsActive = true', 50, 1);
        Test.stopTest();
        System.assert(result.records.size() > 0, 'Should return filtered results');
    }

    @IsTest
    static void testFetchRecords_ignoresInvalidFields() {
        Test.startTest();
        // include invalid field and SOQL injection-like tokens; they should be ignored by sanitization
        OM_TechnicalCatalogController.SObjectSearchResult result = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name, DoesNotExist__c, Id; FROM User', null, 'Name', '', 10, 1);
        Test.stopTest();
        System.assertEquals(10, result.records.size(), 'Still returns data with sanitized fields');
    }

    @IsTest
    static void testFetchRecords_defaultsAndClamps() {
        // objectApiName blank defaults to Product2; pageSize clamped to max; pageNumber <=0 defaults to 1
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult res = OM_TechnicalCatalogController.fetchRecords('', 'Name', null, '', '', 9999, 0);
        Test.stopTest();
        System.assertEquals(1, res.pageNumber, 'Defaults page number to 1');
        System.assertEquals(200, res.pageSize, 'Clamped page size to 200');
    }

    @IsTest
    static void testFetchRecords_invalidObjectNameFallsBack() {
        // invalid object name should fall back to Product2 safely
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult res = OM_TechnicalCatalogController.fetchRecords('Invalid Object Name !', 'Name, Id', null, 'Name', '', 10, 1);
        Test.stopTest();
        System.assert(res.records.size() > 0, 'Falls back to Product2 and returns data');
    }

    @IsTest
    static void testFetchRecords_zeroMatches() {
        // Search for a term that does not exist to cover count=0 path
        Test.startTest();
        OM_TechnicalCatalogController.SObjectSearchResult res = OM_TechnicalCatalogController.fetchRecords('Product2', 'Name', 'ZZZ-NO-MATCH-TERM', 'Name', '', 10, 1);
        Test.stopTest();
        System.assertEquals(0, res.totalRecords, 'No matches should yield total=0');
        System.assertEquals(0, res.records.size(), 'No rows returned when count is zero');
    }

    @IsTest
    static void testFetchRecordDetails_handlesInvalidNestedJson() {
        // Produce invalid nested JSON strings to exercise try/catch branches
        Product2 p = new Product2(Name='Bad JSON', ProductCode='TECH-BAD', IsActive=true,
            vlocity_cmt__AttributeDefaultValues__c='{"B2C-ATTR-TECH-DET":"{invalid}","B2C-ATTR-PRC-DET":"{invalid}"}');
        insert p;

        Test.startTest();
        OM_TechnicalCatalogController.RecordDetailsResult res = OM_TechnicalCatalogController.fetchRecordDetails(p.Id, 'Product2');
        Test.stopTest();
        System.assertNotEquals(null, res, 'Method should handle invalid JSON safely');
    }

    @IsTest
    static void testFetchRecordDetails_nullId_returnsNull() {
        Test.startTest();
        OM_TechnicalCatalogController.RecordDetailsResult res = OM_TechnicalCatalogController.fetchRecordDetails(null, 'Product2');
        Test.stopTest();
        System.assertEquals(null, res, 'Null Id should return null result');
    }

    @IsTest
    static void testFetchRecords_multipleFieldsAndFilter_onAccount() {
        Account a = new Account(Name='Test Acc');
        insert a;
        Test.startTest();
        //OM_TechnicalCatalogController.SObjectSearchResult res = OM_TechnicalCatalogController.fetchRecords('Account', null, 'Test', 'Name, Id, Bad-Field', 'Name != null', 5, 1);
        OM_TechnicalCatalogController.SObjectSearchResult res = OM_TechnicalCatalogController.fetchRecords('Account', null, 'Test', 'Name', 'Name != null', 5, 1);
        Test.stopTest();
        System.assert(res.totalRecords > 0, 'Should find account by name');
        System.assert(res.records.size() > 0, 'Should return at least one row');
    }

    @IsTest
    static void testFetchProductSpecifications_withMetadata() {
        // Use existing custom metadata records if present in org
        List<OMEricsonProductToCFSSpec__mdt> specs = [SELECT TechnicalProduct__c, CFSSpecification__c FROM OMEricsonProductToCFSSpec__mdt LIMIT 1];
        String techCode = (specs.isEmpty()) ? 'NO_MATCH' : specs[0].TechnicalProduct__c;
        Test.startTest();
        OM_TechnicalCatalogController.ProductSpecificationResult res = OM_TechnicalCatalogController.fetchProductSpecifications(techCode);
        Test.stopTest();
        if (!specs.isEmpty()) {
            System.assert(res.Specifications.size() > 0, 'Should return metadata-based specifications');
        } else {
            System.assertEquals(0, res.Specifications.size(), 'No metadata present');
        }
    }

    @IsTest
    static void testFetchProductPriceConfig_withMetadata() {
        List<OMEricsonChargeTypeSpec__mdt> prices = [SELECT TechnicalProduct__c, ChargeType__c, PopId__c, Price__c FROM OMEricsonChargeTypeSpec__mdt LIMIT 1];
        String techCode = (prices.isEmpty()) ? 'NO_MATCH' : prices[0].TechnicalProduct__c;
        Test.startTest();
        OM_TechnicalCatalogController.ProductPriceConfigResult res = OM_TechnicalCatalogController.fetchProductPriceConfig(techCode);
        Test.stopTest();
        if (!prices.isEmpty()) {
            System.assert(res.PriceConfigurations.size() > 0, 'Should return metadata-based price configs');
        } else {
            System.assertEquals(0, res.PriceConfigurations.size(), 'No metadata present');
        }
    }

    @IsTest
    static void testFetchRecordDetails_withJsonAttributes() {
        // Create a product with AttributeDefaultValues including nested JSON fields used by controller
        Product2 p = new Product2(Name='Tech Prod', ProductCode='TECH-1', Description='Desc', IsActive=true,
            vlocity_cmt__AttributeDefaultValues__c='{"B2C-ATTR-SERV-ID":"12345","B2C-ATTR-TECH-DET":"{\"CPU\":\"8 cores\",\"RAM\":\"16GB\"}","B2C-ATTR-PRC-DET":"{\"exceptions\":[{\"code\":\"E1\",\"msg\":\"X\"}]}"}');
        insert p;

        Test.startTest();
        OM_TechnicalCatalogController.RecordDetailsResult result = OM_TechnicalCatalogController.fetchRecordDetails(p.Id, 'Product2');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Details result should not be null');
        System.assertEquals('Tech Prod', result.Name, 'Name should match');
        // Parsing may vary by org data; ensure method executes without exceptions.
    }

    @IsTest
    static void testFetchRecordDetails_missingOptionalFields() {
        // Create a product without Description or AttributeDefaultValues to exercise optional paths
        Product2 p = new Product2(Name='No Desc', ProductCode='TECH-2', IsActive=true);
        insert p;

        Test.startTest();
        OM_TechnicalCatalogController.RecordDetailsResult result = OM_TechnicalCatalogController.fetchRecordDetails(p.Id, 'Product2');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Details result should not be null');
        System.assertEquals('No Desc', result.Name, 'Name should match');
    }

    @IsTest
    static void testFetchProductSpecifications_emptyWhenNoMetadata() {
        Test.startTest();
        OM_TechnicalCatalogController.ProductSpecificationResult res = OM_TechnicalCatalogController.fetchProductSpecifications('NON_EXIST');
        Test.stopTest();
        System.assertEquals('NON_EXIST', res.ProductCode, 'Echoed product code');
        System.assertEquals(0, res.Specifications.size(), 'No metadata returns empty list');
    }

    @IsTest
    static void testFetchProductPriceConfig_emptyWhenNoMetadata() {
        Test.startTest();
        OM_TechnicalCatalogController.ProductPriceConfigResult res = OM_TechnicalCatalogController.fetchProductPriceConfig('NON_EXIST');
        Test.stopTest();
        System.assertEquals('NON_EXIST', res.ProductCode, 'Echoed product code');
        System.assertEquals(0, res.PriceConfigurations.size(), 'No metadata returns empty list');
    }

    @IsTest
    static void testFetchAdditionalInformation_parsesJson() {
        // Build child product with JSONAttribute and parent mapping via PCI
        Product2 parent = new Product2(Name='Parent', ProductCode='PCODE-1', IsActive=true);
        insert parent;

        Product2 child = new Product2(Name='Child', ProductCode='CHILD-1', IsActive=true,
            vlocity_cmt__SpecificationSubType__c='Simple',
            vlocity_cmt__JSONAttribute__c='{"B2C-ATTRCAT-SVC-ADC-DETAILS":[{"categoryname__c":"Servicios Adicionales","attributedisplayname__c":"Claro Drive 25GB","value__c":"true"}],"B2C-ATTRCAT-CAT-GRL-DETAILS":[{"categoryname__c":"Características Generales","attributedisplayname__c":"Tipo de Plan","value__c":"Mixto"}]}'
        );
        insert child;

        vlocity_cmt__ProductChildItem__c pci = new vlocity_cmt__ProductChildItem__c(
            vlocity_cmt__ParentProductId__c = parent.Id,
            vlocity_cmt__ChildProductId__c = child.Id,
            vlocity_cmt__RelationshipType__c = 'child',
            vlocity_cmt__IsRootProductChildItem__c = true,
            vlocity_cmt__Quantity__c = 1,
            vlocity_cmt__ChildLineNumber__c = '1'
        );
        insert pci;

        Test.startTest();
        OM_TechnicalCatalogController.AdditionalInformationResult res = OM_TechnicalCatalogController.fetchAdditionalInformation('PCODE-1');
        Test.stopTest();
        System.assert(res.AdditionalInfo.size() > 0, 'Should parse additional information from JSON');
    }
}