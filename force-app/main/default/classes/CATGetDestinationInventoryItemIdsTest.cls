/*--------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Test Class for Getting Inventory Item Ids
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
18-Mar-25         Fernanda Maldonado                             inicial version
----------------------------------------------------------------------------------*/
@isTest
private class CATGetDestinationInventoryItemIdsTest {

    @testSetup
    static void setupTestData() {
        Account acc = CATTestDataFactory.createAccount(false);
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Tech', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        Asset testAsset = CATTestDataFactory.createAsset(acc.Id, testProduct.Id);
        vlocity_cmt__InventoryItem__c inventoryItem = new vlocity_cmt__InventoryItem__c(
            vlocity_cmt__JSONAttribute__c = '{"testNode": [{"attributeuniquecode__c": "attributeCode", "attributeRunTimeInfo":{"value": "oldValue"}, "SegmentValue":"oldValue"}]}',
            vlocity_cmt__ProductId__c = testProduct.Id
        );
        insert inventoryItem;

        // Create a related decomposition relationship
        vlocity_cmt__InventoryItemDecompositionRelationship__c relationship = new vlocity_cmt__InventoryItemDecompositionRelationship__c(
            vlocity_cmt__SourceAssetId__c = testAsset.Id,
            vlocity_cmt__DestinationInventoryItemId__c = inventoryItem.Id
        );
        insert relationship;
    }

    @isTest
    static void testInventoryItemId_Found() {
        // Create test request
        CATGetDestinationInventoryItemIds.Request req = new CATGetDestinationInventoryItemIds.Request();

        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        req.assetIds = new List<String>{testAsset.Id};
        req.techProdId = testProduct.Id;

        List<CATGetDestinationInventoryItemIds.Request> requests = new List<CATGetDestinationInventoryItemIds.Request>{req};
        
        // Call the invocable method
        Test.startTest();
        List<List<String>> results = CATGetDestinationInventoryItemIds.inventoryItemIds(requests);
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(1, results.size(), 'Expected one response for one request.');
        Assert.areEqual(1, results[0].size(), 'Expected one inventory ID in the list.');
        Assert.areNotEqual('No matching records found', results[0][0], 'There must be a valid result.');
    }

    @isTest
    static void testInventoryItemId_NotFound() {
        // Create test request with a non existent assetId
        CATGetDestinationInventoryItemIds.Request req = new CATGetDestinationInventoryItemIds.Request();
        req.assetIds = new List<String>{'invalidAssetId'};
        req.techProdId = 'testTechProdId';

        List<CATGetDestinationInventoryItemIds.Request> requests = new List<CATGetDestinationInventoryItemIds.Request>{req};
        
        // Call the invocable method
        Test.startTest();
        List<List<String>> results = CATGetDestinationInventoryItemIds.inventoryItemIds(requests);
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(1, results.size(), 'Expected one response even for no matching records.');
    }
}