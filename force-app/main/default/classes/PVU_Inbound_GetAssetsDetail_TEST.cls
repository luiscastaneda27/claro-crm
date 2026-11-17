/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class test to  PVU_Inbound_GetAssetDetail B2C-ATTR-FYB-BLQ-GPRS
History
<Date>          <Author>        <Change Description>
25/06/2024      Luis Mendoza    Initial Version
05/12/2024      Luis Mendoza    version with attr insert
------------------------------------------------------------*/
@isTest
public class PVU_Inbound_GetAssetsDetail_TEST {

    @TestSetup
    static void makeData(){
        

        Account acc2 = new Account();
        acc2.Name = 'Test Account';
        acc2.FVU_DocumentType__c = 'CC';
        acc2.FVU_DocumentNumber__c = '1258967';
        insert acc2;
        
        Account accBilling = new Account();
        accBilling.Name = 'Test Account Billing';
        accBilling.FVU_AccountExternalID__c = '930000000587025';
        accBilling.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
        insert accBilling;

        vlocity_cmt__Subscription__c testsubscription = new vlocity_cmt__Subscription__c();
            testsubscription.OM_Contract__c='contac85';
            testsubscription.vlocity_cmt__SubscriptionNumber__c='testsuscr22';
            testsubscription.OM_MSISDN__c='573100003928';
            testsubscription.OM_RoamingCANBlocking__c = True;
            testsubscription.vlocity_cmt__ServiceAccountId__c=acc2.Id;

        insert testsubscription;

        Asset ast = new Asset();
        ast.Name = 'Test Asset1';
        ast.AccountId = acc2.Id;
        ast.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BLQ-GPRS":"573100003928","B2C-ATTR-FYB-VID-LLAM":"573100003928"}';
        ast.vlocity_cmt__BillingAccountId__c = accBilling.Id;
        ast.PVU_Serial__c = '78511';
        ast.vlocity_cmt__SubscriptionId__c= testsubscription.Id;
        ast.PVU_IMEI__c= 'IMEI584584';
        ast.vlocity_cmt__CurrencyPaymentMode__c = 'Currency';
        ast.FVU_EffectiveOneTimeTotalIncTaxes__c = 1200;
        ast.vlocity_cmt__OneTimeTotal__c = 60;
        ast.FVU_RecurringTotalIncTaxes__c = 1800;
        ast.vlocity_cmt__RecurringTotal__c = 50;
        ast.Status = 'Active';
        insert ast;

        vlocity_cmt__AttributeCategory__c attCat = new vlocity_cmt__AttributeCategory__c();
        attCat.vlocity_cmt__ApplicableSubType__c = 'Product Attribute';
        attCat.vlocity_cmt__ApplicableTypes__c = 'Product2';
        attCat.vlocity_cmt__Code__c = 'B2C-ATTR-FYB';
        attCat.vlocity_cmt__DisplaySequence__c = 1;

        insert attCat;

        List<vlocity_cmt__Attribute__c> listAtt = new List<vlocity_cmt__Attribute__c>();
        vlocity_cmt__Attribute__c att = new vlocity_cmt__Attribute__c();
        att.vlocity_cmt__AttributeCategoryId__c = attCat.Id;
        att.vlocity_cmt__Code__c = 'B2C-ATTR-FYB-VID-LLAM';
        att.vlocity_cmt__DisplaySequence__c = 1;
        att.Name = 'Test Att 1';     

        listAtt.add(att);
        vlocity_cmt__Attribute__c att2 = new vlocity_cmt__Attribute__c();
        att2.vlocity_cmt__Code__c = 'B2C-ATTR-FYB-BLQ-GPRS';
        att2.Name = 'Test Att 2'; 
        att2.vlocity_cmt__AttributeCategoryId__c = attCat.Id;
        att2.vlocity_cmt__DisplaySequence__c = 1;
        listAtt.add(att2);

        insert listAtt;  
        
    }
    
    @isTest
    static void getAssetDetailParametNotFound(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssetDetails';
           req.httpMethod = 'GET';
           req.addParameter('other', 'test');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
                PVU_Inbound_GetAssetDetail.getAssetDetail();
            Test.stopTest();

            Assert.areEqual(404, res.statusCode, 'Parameter not found');
    }

    @isTest
    static void getAssetByExternalCustomerIdTestSuccess(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssetDetails';
           req.httpMethod = 'GET';
           req.addParameter('externalCustomerId', '930000000587025');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

           
            Test.startTest();
                PVU_Inbound_GetAssetDetail.getAssetDetail();
            Test.stopTest();

            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            Assert.areEqual('1258967', resMap.get('documentNumber'), 'response success');
    }

    @isTest
    static void getAssetByExternalCustomerIdTestNotFound(){


        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('externalCustomerId', '9300000005870256');
        RestContext.request = req;

        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('Asset Not found', resMap.get('message'), 'Asset Not found');
    }
    
    @isTest
    static void getAssetBySerialTestSuccess(){
        
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('serial', '78511');
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('1258967', resMap.get('documentNumber'), 'response success');
    }
    
    @isTest
    static void getAssetBySerialTestNotFound(){
        
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('serial', '785116');
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('Asset Not found', resMap.get('message'), 'Asset Not found');
    }
    
    @isTest
    static void getAssetByMobileNumberTestSuccess(){
        
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('mobileNumber', '573100003928');
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('1258967', resMap.get('documentNumber'), 'response success');
    }
    
    @isTest
    static void getAssetByMobileNumberTestNotFound(){
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('mobileNumber', '5731000039288');
        req.addParameter('documentNumber', '12589678');
        req.addParameter('documentType', 'CC');
        RestContext.request = req;

        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('Asset Not found', resMap.get('message'), 'Asset Not found');
    }

    @isTest
    static void getAssetByIMEITestSuccess(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssetDetails';
           req.httpMethod = 'GET';
           req.addParameter('imei', 'IMEI584584');
           req.addParameter('documentNumber', '1258967');
           req.addParameter('documentType', 'CC');
           req.addParameter('attrFlag', 'false');
           req.addParameter('isSeeAll', 'false');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
                PVU_Inbound_GetAssetDetail.getAssetDetail();
            Test.stopTest();

            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            Assert.areEqual('1258967', resMap.get('documentNumber'), 'response success');
    }

    @isTest
    static void getAssetByIMEITestNotFound(){

        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('imei', 'IMEI58458477');
        req.addParameter('documentNumber', '12589678');
        req.addParameter('documentType', 'CC');
        RestContext.request = req;

        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('Asset Not found', resMap.get('message'), 'Asset Not found');
    }

    @isTest
    static void getAssetByIMEITestParameter(){

        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetAssetDetails';
        req.httpMethod = 'GET';
        req.addParameter('imei', 'IMEI58458477');
        RestContext.request = req;

        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
            PVU_Inbound_GetAssetDetail.getAssetDetail();
        Test.stopTest();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('número y tipo de documento requeridos', resMap.get('message'), 'número y tipo de documento requeridos');
    }

    @isTest
    static void getAssetByIMEIWithFilterFields(){


           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/GetAssetDetails';
           req.httpMethod = 'GET';
           req.addParameter('imei', 'IMEI584584');
           req.addParameter('documentNumber', '1258967');
           req.addParameter('documentType', 'CC');
           req.addParameter('fields', 'productCharacteristic,id');
           req.addParameter('isSeeAll', 'true');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
                PVU_Inbound_GetAssetDetail.getAssetDetail();
            Test.stopTest();

            Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
            Assert.areEqual('1258967', resMap.get('documentNumber'), 'response success');
    }


}