/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test Class for Checking Attr JSON Field in Decomposition Relationship records
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
11-Mar-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
@isTest
public class CATAttributeJSONCheckerTest {
    @testSetup
    static void setupTestData() {
        Account acc = CATTestDataFactory.createAccount(false);
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Tech', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        // Create test records
        vlocity_cmt__DecompositionRelationship__c testRecord = new vlocity_cmt__DecompositionRelationship__c(
            vlocity_cmt__MappingsData__c = '[{"source_type":"Attribute","source_attr_name":"Tipo de Plan","source_attr_code":"B2C-ATTR-CG-TIPO-PLAN","mapping_type":"ad-verbatim","destination_attr_name":"TechPCTipoPlan","destination_attr_code":"TechPCTipoPlan"}]',
            vlocity_cmt__DestinationProductId__c = testProduct.Id,
            vlocity_cmt__SourceProductId__c = testProduct.Id
        );
        insert testRecord;
    }
    @isTest
    static void testCheckJSONAttributes() {
        SObject testRecord = [
            SELECT Id, vlocity_cmt__MappingsData__c,vlocity_cmt__DestinationProductId__c 
            FROM vlocity_cmt__DecompositionRelationship__c
        ];
        // Prepare Request wrapper
        CATAttributeJSONChecker.Request req = new CATAttributeJSONChecker.Request();
        req.records = new List<SObject>{ testRecord };
        req.searchAttr = 'B2C-ATTR-CG-TIPO-PLAN';
        // Execute method
        Test.startTest();
        List<CATAttributeJSONChecker.Response> responses = CATAttributeJSONChecker.checkJSONAttributes(new List<CATAttributeJSONChecker.Request>{ req });
        Test.stopTest();
        // Assertions
        Assert.areEqual(1, responses.size(), 'Expected one response record');
        Assert.areEqual('TechPCTipoPlan', responses[0].destinationAttrCode, 'Destination attribute should match');
        Assert.areEqual(true, responses[0].isAttributeFound, 'Attribute should be found');
    }
    @isTest
    static void testCheckJSONAttributesNoAttrFound() {
        SObject testRecord = [
            SELECT Id, vlocity_cmt__MappingsData__c,vlocity_cmt__DestinationProductId__c 
            FROM vlocity_cmt__DecompositionRelationship__c
        ];

        // Prepare Request wrapper
        CATAttributeJSONChecker.Request req = new CATAttributeJSONChecker.Request();
        req.records = new List<SObject>{ testRecord };
        req.searchAttr = 'B2C-ATTR-CG-TIPO-PLAN-TEST';
        Test.startTest();
        // Execute method
        List<CATAttributeJSONChecker.Response> responses = CATAttributeJSONChecker.checkJSONAttributes(new List<CATAttributeJSONChecker.Request>{ req });
        Test.stopTest();
        // Assertions
        Assert.areEqual(false, responses[0].isAttributeFound, 'Attribute should be found');
    }
}