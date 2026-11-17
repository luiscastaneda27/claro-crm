/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test Class for CATTechProductBrowserController LWC Cat Prod Browser
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
21-Feb-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
@isTest
private class CATTechProductBrowserControllerTest {
    @testSetup
    static void setupTestData() {
        Account accountTest = CATTestDataFactory.createAccount(false);
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Tech', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        List <SObject> testProductList2 = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Tech', 5, 15);
        Product2 testProduct2 = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry2 = (PricebookEntry) testProductList[1];
        vlocity_cmt__PriceList__c priceList = CATTestDataFactory.createPriceList('Cliente Masivo');
        vlocity_cmt__PricingVariable__c pricingVariable = CATTestDataFactory.createPricingVariable('OT Std');
        vlocity_cmt__PricingElement__c pricingElement = CATTestDataFactory.createPricingElementEntry(priceList.Id,pricingVariable.Id,'OT Std',5000);
        //Put Prices to Products
        CATTestDataFactory.createPriceListEntry(priceList.Id,testProduct.Id,testPricebookEntry.Id,pricingElement.Id);
        List <Id> testAttrMarcaList = CATTestDataFactory.createAttr('MarcaTech');
        List <Id> testAttrCatList = CATTestDataFactory.createAttr('CatTech');
        List <Id> testAttrSubCatList = CATTestDataFactory.createAttr('SubCatTech');
        List <Id> testAttrURLList = CATTestDataFactory.createAttr('URL');
        Id attrCatMarcaId = testAttrMarcaList[0];
        Id attrMarcaId = testAttrMarcaList[1];
        Id attrCatURLId = testAttrURLList[0];
        Id attrURLId = testAttrURLList[1];
        Id attrCatCat = testAttrCatList[0];
        Id attrCatId = testAttrCatList[1];
        Id attrSubCatCatId = testAttrSubCatList[0];
        Id attrSubCatId = testAttrSubCatList[1];
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatURLId, attrURLId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatCat, attrCatId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrSubCatCatId, attrSubCatId);
        CATTestDataFactory.createPriceListEntry(priceList.Id,testProduct2.Id,testPricebookEntry.Id,pricingElement.Id);
        CATTestDataFactory.createAttrAssgn(testProduct2.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct2.Id, attrCatMarcaId, attrMarcaId);
        FVU_UVT_info__c uVTInfo = CATTestDataFactory.CreateUVTInfo();
        CATTestDataFactory.createAttach(testProduct2.Id);
        Asset testAsset = CATTestDataFactory.createAsset(accountTest.Id, testProduct2.Id);
    }
    @isTest
    static void testGetCategories() {
        Test.startTest();
        List<String> categories = CATTechProductBrowserController.getCategories( 'Tech');
        Test.stopTest();
        Assert.areNotEqual(null, categories, 'Result should not be null');
        Assert.areEqual(1,categories.size(), 'Expected at least one category');
    }

    @isTest
    static void testGetSubCategories() {
        Test.startTest();
        List<String> subcategories = CATTechProductBrowserController.getSubCategories('Apple','Tech');
        Test.stopTest();
        Assert.areNotEqual(0, subcategories.size(), 'Products should be retrieved within the price range.');
    }
    
    @isTest
    static void testGetTechProductsCatAndSubCatWithBrand() {
        Test.startTest();
        //(String productType, String productBrand, Integer latestReleasesDays, Integer bestSellersDays, String selectedPriceRange, Integer numProducts, String selectedCategory, String selectedSubCategory) {
        List<CATTechProductBrowserController.ProductWrapper> result = CATTechProductBrowserController.getTechProducts('Tech', '', 0, 0, '', 0, 'Apple','');
        List<CATTechProductBrowserController.ProductWrapper> resultWithHighPriceFilter = CATTechProductBrowserController.getTechProducts ('Tech', '', 0, 0, '2000000-3000000', 0, 'Apple','Apple');
        List<CATTechProductBrowserController.ProductWrapper> resultWithBrand = CATTechProductBrowserController.getTechProducts ('Tech', 'Apple', 0, 0, '', 0, 'Apple','');
        List<CATTechProductBrowserController.ProductWrapper> resultWithHighPriceFilterWithBrand = CATTechProductBrowserController.getTechProducts ('Tech', 'Apple', 0, 0, '4000-6000', 0, 'Apple','Apple');
        Test.stopTest();
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areNotEqual(null, resultWithHighPriceFilter, 'Result should not be null');
        Assert.areNotEqual(null, resultWithBrand, 'Result should not be null');
        Assert.areNotEqual(null, resultWithHighPriceFilterWithBrand, 'Result should not be null');
    }

    @isTest
    static void testGetTechProductsLatestReleasesFilter() {
        Test.startTest();
        List<CATTechProductBrowserController.ProductWrapper> products = CATTechProductBrowserController.getTechProducts('Tech', '', 7, 0, '', 0, 'Apple','');
        List<CATTechProductBrowserController.ProductWrapper> productswithSubCat = CATTechProductBrowserController.getTechProducts('Tech', '', 7, 0, '4000-6000', 0, 'Apple','Apple');
        List<CATTechProductBrowserController.ProductWrapper> productsWithBrandNoPriceNoSUbCat = CATTechProductBrowserController.getTechProducts('Tech', 'Apple', 7, 0, '', 0, 'Apple','');
        List<CATTechProductBrowserController.ProductWrapper> productsWithBrandWithCatAndSubCat = CATTechProductBrowserController.getTechProducts('Tech', 'Apple', 7, 0, '4000-6000', 0, 'Apple', 'Apple');


        Test.stopTest();
        Assert.areNotEqual(0, products.size(), 'Latest releases should return products.');
        Assert.areNotEqual(0, productswithSubCat.size(), 'Latest releases should return products.');
        Assert.areNotEqual(0, productsWithBrandWithCatAndSubCat.size(), 'Latest releases should return products.');
        Assert.areNotEqual(0, productsWithBrandNoPriceNoSUbCat.size(), 'Latest releases should return products.');
    }

    @isTest
    static void testGetProductsBestSellersFilter() {
        Test.startTest();
        List<CATTechProductBrowserController.ProductWrapper> products = CATTechProductBrowserController.getTechProducts('Tech', '', 0, 15, '', 5, 'Apple','');
        List<CATTechProductBrowserController.ProductWrapper> productsNoBrand = CATTechProductBrowserController.getTechProducts('Tech', '', 0, 15, '4000-6000', 5, 'Apple', 'Apple');
        List<CATTechProductBrowserController.ProductWrapper> productsWithBrand = CATTechProductBrowserController.getTechProducts('Tech', 'Apple', 0, 15, '4000-6000', 5, 'Apple', 'Apple' );
        List<CATTechProductBrowserController.ProductWrapper> productsWithBrandNoPrice = CATTechProductBrowserController.getTechProducts('Tech', 'Apple', 0, 15, '', 5, 'Apple', '');
        Test.stopTest();
        Assert.areNotEqual(0, products.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsWithBrand.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsWithBrandNoPrice.size(), 'Best sellers should return products.');
        Assert.areNotEqual(0, productsNoBrand.size(), 'Best sellers should return products.');
    }

    @isTest
    static void testGetBrandsURl() {
        Test.startTest();
        List<Map<String, String>> brandsWithCat = CATTechProductBrowserController.getBrandsURl('Apple','','Tech');
        List<Map<String, String>> brandsWithCatAndSubCat = CATTechProductBrowserController.getBrandsURl('Apple','Apple','Tech');
        Test.stopTest();
        Assert.areNotEqual(0, brandsWithCat.size(), 'testGetBrandsURl should return products.');
        Assert.areNotEqual(0, brandsWithCatAndSubCat.size(), 'testGetBrandsURl should return products.');
    }
}