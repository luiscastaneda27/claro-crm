/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class test to  PVU_Inbound_GetAssets
History
<Date>          <Author>        <Change Description>
20/06/2024      Luis Mendoza    Initial Version
------------------------------------------------------------*/
@isTest
public class PVU_Inbound_GetAssets_TEST {
    
    @TestSetup
    static void makeData(){
        

        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.FVU_DocumentType__c = 'CC';
        acc2.FVU_DocumentNumber__c = '1258967';
        insert acc2;

        Asset ast = new Asset();
        ast.Name = 'Test Asset1';
        ast.AccountId = acc2.Id;
        insert ast;
        
    }

    @isTest
    static void getAssetTestSuccess(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssets';
           req.httpMethod = 'GET';
           req.addParameter('documentNumber', '1258967');
           req.addParameter('documentType', 'CC');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
            PVU_Inbound_GetAssets.getAssetsByDocumentAndType();    
            Test.stopTest();

            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            Assert.areEqual('1258967', resMap.get('documentNumber'), 'Response success');
    }

    @isTest
    static void getAssetTestWithFilterFields(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssets';
           req.httpMethod = 'GET';
           req.addParameter('documentNumber', '1258967');
           req.addParameter('documentType', 'CC');
           req.addParameter('fields', 'productCode,assetReferenceId,disconnectDate');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
            PVU_Inbound_GetAssets.getAssetsByDocumentAndType();    
            Test.stopTest();

            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            Assert.areEqual('1258967', resMap.get('documentNumber'), 'Response success');
    }

    @isTest
    static void getAssetTestFailed(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssets';
           req.httpMethod = 'GET';
           req.addParameter('documentNumber', '12589678');
           req.addParameter('documentType', 'CC');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
            PVU_Inbound_GetAssets.getAssetsByDocumentAndType();    
            Test.stopTest();

            // Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            // Assert.areEqual('Asset not found', resMap.get('message'), 'Error response');
            Assert.areEqual(404, res.statusCode, 'Error response');
    }
}