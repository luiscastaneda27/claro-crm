/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test Class for CATProductDetailsController LWC Cat Prod Browser
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
25-Feb-25         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
@isTest
private class CATProductDetailsControllerTest {
    @testSetup
    static void setupTestData() {
        Account accountTest = CATTestDataFactory.createAccount(false);
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        vlocity_cmt__PriceList__c priceListClienteMasivo = CATTestDataFactory.createPriceList('Cliente Masivo');
        vlocity_cmt__PriceList__c priceList24Meses = CATTestDataFactory.createPriceList('24 meses');
        vlocity_cmt__PricingVariable__c pricingVariable = CATTestDataFactory.createPricingVariable('OT Std');
        vlocity_cmt__PricingElement__c pricingElementClienteMasivo = CATTestDataFactory.createPricingElementEntry(priceListClienteMasivo.Id,pricingVariable.Id,'OT Std',5000);
        vlocity_cmt__PricingElement__c pricingElement24Meses = CATTestDataFactory.createPricingElementEntry(priceList24Meses.Id,pricingVariable.Id,'OT Std',1000);
        //Put Prices to Test Product
        CATTestDataFactory.createPriceListEntry(priceListClienteMasivo.Id,testProduct.Id,testPricebookEntry.Id,pricingElementClienteMasivo.Id);
        CATTestDataFactory.createPriceListEntry(priceList24Meses.Id,testProduct.Id,testPricebookEntry.Id,pricingElement24Meses.Id);
        List <Id> testAttrMarcaList = CATTestDataFactory.createAttr('Marca');
        List <Id> testAttrURLList = CATTestDataFactory.createAttr('URL');
        Id attrCatMarcaId = testAttrMarcaList[0];
        Id attrMarcaId = testAttrMarcaList[1];
        Id attrCatURLId = testAttrURLList[0];
        Id attrURLId = testAttrURLList[1];
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatMarcaId, attrMarcaId);
        CATTestDataFactory.createAttrAssgn(testProduct.Id, attrCatURLId, attrURLId);
        CATTestDataFactory.createAttach(testProduct.Id);
    }
    @isTest
    static void testGetProductImages() {
        // Retrieve the test product
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        Test.startTest();
        // Call the method under test
        CATProductDetailsController.ProductWrapper result = CATProductDetailsController.getProductDetails(testProduct.Id);
        Test.stopTest();
        // Validate the returned product details
        Assert.areNotEqual(null, result, 'The result should not be null');
        Assert.areEqual(testProduct.Id, result.id, 'The product ID should match the test product');
        Assert.areEqual('Test Product', result.name, 'The product name should be "Test Product"');
        Assert.areEqual('Test product description', result.description, 'The description should match');
    }
}