/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test Class for Updating Inventory Items JSON Attribute Field
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
11-Mar-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
@isTest
private class CATUpdateInventoryItemJSONTest {

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
    static void testUpdateJSONAttribute() {
        // Get test record
        vlocity_cmt__InventoryItem__c inventoryItem = [SELECT Id FROM vlocity_cmt__InventoryItem__c LIMIT 1];

        // Create test request
        CATUpdateInventoryItemJSON.Request req = new CATUpdateInventoryItemJSON.Request();
        req.inventoryAssetId = inventoryItem.Id;
        req.techAttrCode = 'attributeCode';
        req.techAttrValue = 'newValue';

        List<CATUpdateInventoryItemJSON.Request> requests = new List<CATUpdateInventoryItemJSON.Request>{req};

        // Call the invocable method
        Test.startTest();
        List<CATUpdateInventoryItemJSON.Response> responses = CATUpdateInventoryItemJSON.updateJSONAttribute(requests);
        Test.stopTest();

        // Assertions
        Assert.areEqual(1, responses.size(), 'Expected one response for one request.');
        Assert.isTrue(responses[0].updatedJSONList != null && responses[0].updatedJSONList.size() > 0, 'Expected updated JSON list.');
        System.debug(responses[0].updatedJSONList);
        Assert.isTrue(responses[0].updatedJSONList[0].contains('"attributeuniquecode__c":"attributeCode"'), 'Missing attribute code');
        Assert.isTrue(responses[0].updatedJSONList[0].contains('"attributeRunTimeInfo":{"value":"newValue"}'), 'Missing attribute value');
        Assert.isTrue(responses[0].updatedJSONList[0].contains('"SegmentValue":"newValue"'), 'Missing segment value');
        //Assert.isTrue(responses[0].updatedJSONList.contains('{"testNode": [{"attributeuniquecode__c": "attributeCode", "attributeRunTimeInfo":{"value": "newValue"}, "SegmentValue":"newValue"}]}'), 'JSON should be updated.');
    }

    @isTest
    static void testUpdateJSONAttributeNoMatchingRecords() {
        // Create test request with an invalid assetId
        CATUpdateInventoryItemJSON.Request req = new CATUpdateInventoryItemJSON.Request();
        req.inventoryAssetId = 'invalidAssetId';
        req.techAttrCode = 'attributeCode';
        req.techAttrValue = 'newValue';

        List<CATUpdateInventoryItemJSON.Request> requests = new List<CATUpdateInventoryItemJSON.Request>{req};

        // Call the invocable method
        Test.startTest();
        List<CATUpdateInventoryItemJSON.Response> responses = CATUpdateInventoryItemJSON.updateJSONAttribute(requests);
        Test.stopTest();

        // Assertions
        Assert.areEqual(1, responses.size(), 'Expected one response even for no matching records.');
        Assert.isTrue(responses[0].updatedJSONList.contains('No matching records found'), 'Expected no matching records message.');
    }
}