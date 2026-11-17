/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test Class for CATProductListController LWC Cat Prod Browser
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
21-Feb-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
@isTest
private class CATProductListControllerTest {
    @testSetup
    static void setupTestData() {
        Account accountTest = CATTestDataFactory.createAccount(false);
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        List <SObject> testProductList2 = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        Product2 testProduct2 = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry2 = (PricebookEntry) testProductList[1];
        vlocity_cmt__PriceList__c priceList = CATTestDataFactory.createPriceList('Cliente Masivo');
        vlocity_cmt__PricingVariable__c pricingVariable = CATTestDataFactory.createPricingVariable('OT Std');
        vlocity_cmt__PricingElement__c pricingElement = CATTestDataFactory.createPricingElementEntry(priceList.Id,pricingVariable.Id,'OT Std',5000);
        //Put Prices to Products
        CATTestDataFactory.createPriceListEntry(priceList.Id,testProduct.Id,testPricebookEntry.Id,pricingElement.Id);
        List <Id> testAttrMarcaList = CATTestDataFactory.createAttr('Marca');
        List <Id> testAttrURLList = CATTestDataFactory.createAttr('URL');
        List <Id> testAttrUVTList = CATTestDataFactory.createAttr('Límite UVT');
        Id attrCatMarcaId = testAttrMarcaList[0];
        Id attrMarcaId = testAttrMarcaList[1];
        Id attrCatURLId = testAttrURLList[0];
        Id attrURLId = testAttrURLList[1];
        Id attrCatUVTId = testAttrUVTList[0];
        Id attrUVTId = testAttrUVTList[1];
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatURLId, attrURLId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatUVTId, attrUVTId);
        CATTestDataFactory.createPriceListEntry(priceList.Id,testProduct2.Id,testPricebookEntry.Id,pricingElement.Id);
        CATTestDataFactory.createAttrAssgn(testProduct2.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct2.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct2.Id, attrCatUVTId, attrUVTId);
        FVU_UVT_info__c uVTInfo = CATTestDataFactory.CreateUVTInfo();
        CATTestDataFactory.createAttach(testProduct2.Id);
        Asset testAsset = CATTestDataFactory.createAsset(accountTest.Id, testProduct2.Id);
        CATTestDataFactory.createPriceObjectLWCInfo('Terminales');
    }
    
    @isTest
    static void testGetProducts() {
        Test.startTest();
        List<CATProductListController.ProductWrapper> result = CATProductListController.getProducts( '', 'Test', '', 0, 0, '', 0);
        Test.stopTest();
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(2,result.size(), 'Expected at least one product');
    }

    @isTest
    static void testGetProductsTypeHandset() {
        Test.startTest();
        List<CATProductListController.ProductWrapper> handsetProducts = CATProductListController.getProducts('Handset','', '', 0, 0, '', 0);
        List<CATProductListController.ProductWrapper> handsetProductsWithPriceFilter = CATProductListController.getProducts('Handset','','', 0, 0, '4000-6000', 0);
        Test.stopTest();
        Assert.areNotEqual(0, handsetProducts.size(), 'Products should be more than 0.');
        Assert.areNotEqual(0, handsetProductsWithPriceFilter.size(), 'Products should be retrieved within the price range.');
    }
    
    @isTest
    static void testGetProductsByBrand() {
        Test.startTest();
        List<CATProductListController.ProductWrapper> result = CATProductListController.getProducts('Handset', '', 'Apple', 0, 0, '', 0);
        List<CATProductListController.ProductWrapper> resultWithHighPriceFilter = CATProductListController.getProducts('Handset', '', 'Apple', 0, 0, '2000000-3000000', 0);
        Test.stopTest();
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areNotEqual(null, resultWithHighPriceFilter, 'Result should not be null');
    }

    @isTest
    static void testGetProductsLatestReleasesFilter() {
        Test.startTest();
        List<CATProductListController.ProductWrapper> products = CATProductListController.getProducts('Handset', '', '', 7, 0, '4000-6000', 0);
        List<CATProductListController.ProductWrapper> productsWithBrand = CATProductListController.getProducts('Handset', '', 'Apple', 7, 0, '4000-6000', 0);
        List<CATProductListController.ProductWrapper> productsWithBrandNoPrice = CATProductListController.getProducts('Handset', '', 'Apple', 7, 0, '', 0);
        Test.stopTest();
        Assert.areNotEqual(0, products.size(), 'Latest releases should return products.');
        Assert.areNotEqual(0, productsWithBrand.size(), 'Latest releases should return products.');
        Assert.areNotEqual(0, productsWithBrandNoPrice.size(), 'Latest releases should return products.');
    }

    @isTest
    static void testGetProductsBestSellersFilter() {
        Test.startTest();
        List<CATProductListController.ProductWrapper> products = CATProductListController.getProducts('Handset', '', '', 0, 15, '', 5);
        List<CATProductListController.ProductWrapper> productsNoBrand = CATProductListController.getProducts('Handset', '', '', 0, 15, '4000-6000', 5);
        List<CATProductListController.ProductWrapper> productsWithBrand = CATProductListController.getProducts('Handset', '', 'Apple', 0, 15, '4000-6000', 5);
        List<CATProductListController.ProductWrapper> productsWithBrandNoPrice = CATProductListController.getProducts('Handset', '', 'Apple', 0, 15, '', 5);
        Test.stopTest();
        Assert.areNotEqual(0, products.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsWithBrand.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsWithBrandNoPrice.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsNoBrand.size(), 'Best sellers should return products.');
    }

    @isTest
    static void testGetHandsetBrandToURlProduct() {
        Test.startTest();
        List<Map<String, String>> result = CATProductListController.getBrandsURl();
        Test.stopTest();
        Assert.areNotEqual(0, result.size(), 'GetHandsetBrandToURlProduct should return products.');
    }

    @isTest
    static void testGetPriceOptions() {
        Test.startTest();
        List<Map<String, String>> result = CATProductListController.getPriceOptions('Terminales');
        Test.stopTest();
        Assert.areNotEqual(0, result.size(), 'GetPriceOptions should return products.');
    }
}