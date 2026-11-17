/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class test to PVU_CommunityValidations 
Test Class:     
History
<Date>          <Author>        <Change Description>
29/11/2024      Luis Mendoza    Initial Version
20/01/2025      Luis Mendoza    version with new method
------------------------------------------------------------*/
@isTest
private class PVU_CommunityValidations_TEST {

    @TestSetup
    static void createCommunityData() {

        Account testAccount = new Account(
            Name = 'Test Account Community');
        insert testAccount;
        
        Account testAccount2 = new Account(
            Name = 'Test Account Community2');
        insert testAccount2;
        
        
        vlocity_cmt__Subscription__c testsubscription = new vlocity_cmt__Subscription__c(
            OM_Contract__c='contac85',
            OM_MSISDN__c='5731000049536',
            vlocity_cmt__SubscriptionNumber__c='testsuscr22',
            vlocity_cmt__ServiceAccountId__c= testAccount.id
            ) ;
        insert testsubscription;

        vlocity_cmt__Subscription__c testsubscription2 = new vlocity_cmt__Subscription__c(
            OM_Contract__c='contac859',
            OM_MSISDN__c='5731000049538',
            vlocity_cmt__SubscriptionNumber__c='testsuscr22r',
            vlocity_cmt__ServiceAccountId__c= testAccount2.id
            ) ;
        insert testsubscription2;

        Product2 prod2 = new Product2 (
            Name='Product 2', 
            ProductCode = 'B2C-MOV-PLAN-POST-CONECT-V41MX', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan',
            vlocity_cmt__SubType__c = 'Postpaid'
        );

        insert prod2;

        Asset ast = new Asset();
        ast.Name = 'Test Asset1';
        ast.AccountId = testAccount.Id;
        ast.vlocity_cmt__SubscriptionId__c  = testsubscription.Id;
        ast.Product2Id = prod2.Id;
        insert ast;       

        PVU_Community__c communi = new PVU_Community__c();
        communi.Name  = 'Test Comunidad Padre';
        communi.PVU_Linea_Padre__c = testsubscription.Id;
        communi.PVU_Estatus__c = 'Activa';
        communi.PVU_Fecha_de_activacion__c = Date.today();
        communi.PVU_Segmento_linea__c = 'Postpago';
        insert communi;

        PVU_Community__c communi2 = new PVU_Community__c();
        communi2.Name  = 'Test Comunidad Padre 2';
        communi2.PVU_Linea_Padre__c = testsubscription2.Id;
        communi2.PVU_Estatus__c = 'Inactiva';
        communi2.PVU_Fecha_de_activacion__c = Date.today();
        communi2.PVU_Segmento_linea__c = 'Postpago';
        insert communi2;

        PVU_Community_Member__c member = new PVU_Community_Member__c();
        member.PVU_Linea_Hija__c = '5731785409536';
        member.Name = 'test member';
        member.PVU_Segmento_Linea__c = 'Fija';
        member.PVU_Tipo_Linea__c = 'Movil';
        member.PVU_Comunidad__c = communi.id;
        insert member;

        Case caso1 = new Case();
        caso1.PVU_Level1__c = 'Facturación y pagos';
        caso1.PVU_Level2__c = 'Pagos';
        caso1.PVU_Level3__c = 'Pago no abonado'; 
        caso1.status = 'Abierto';
        caso1.PVU_NR__c = '00000001';
        caso1.AccountId = testAccount.Id;
        caso1.AssetId = ast.Id;
        caso1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('GestionCasosPosventa').getRecordTypeId();
        caso1.PVU_Comunidad__c = communi.Id;       
        insert caso1;
        
        
    }
    
    @isTest
    static void getCommunityParameterNotFound(){
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        PVU_CommunityParameters__mdt testMdt = PVU_CommunityParameters__mdt.getInstance('ERROR_CHILDLINE_REQUIRED');
        
        Test.startTest();
            PVU_CommunityValidations.getResquestCommunity();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('error', resMap.get('status') , 'response error not found');
    }
    
    @isTest
    static void getCommunityParentTestSuccess(){
        
        PVU_Community__c cmuni = [SELECT Id, PVU_Linea_Padre__r.OM_MSISDN__c FROM PVU_Community__c WHERE Name = 'Test Comunidad Padre' LIMIT 1];
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        req.addParameter('parentLine', cmuni.PVU_Linea_Padre__r.OM_MSISDN__c);
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        
        Test.startTest();
        PVU_CommunityValidations.getResquestCommunity();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('success', resMap.get('status') , 'response success');
    }
    
    @isTest
    static void getCommunityParentAndChildTest(){
        
        PVU_Community__c cmuni = [SELECT Id, PVU_Linea_Padre__r.OM_MSISDN__c FROM PVU_Community__c WHERE Name = 'Test Comunidad Padre' LIMIT 1];
        PVU_Community_Member__c cmuniChild = [SELECT Id, PVU_Linea_Hija__c FROM PVU_Community_Member__c WHERE Name = 'test member' LIMIT 1];
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        req.addParameter('parentLine', cmuni.PVU_Linea_Padre__r.OM_MSISDN__c);
        req.addParameter('childLine', cmuniChild.PVU_Linea_Hija__c);
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        
        Test.startTest();
        PVU_CommunityValidations.getResquestCommunity();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('success', resMap.get('status') , 'response success');
    }
    
    @isTest
    static void getCommunityChildWithoutParentTest(){
        
        PVU_Community_Member__c cmuniChild = [SELECT Id, PVU_Linea_Hija__c FROM PVU_Community_Member__c WHERE Name = 'test member' LIMIT 1];
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        req.addParameter('parentLine', '');
        req.addParameter('childLine', cmuniChild.PVU_Linea_Hija__c);
        RestContext.request = req;
        
        PVU_CommunityParameters__mdt testMdt = PVU_CommunityParameters__mdt.getInstance('ERROR_CHILDLINE_REQUIRED');
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        
        Test.startTest();
        PVU_CommunityValidations.getResquestCommunity();    
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('error', resMap.get('status') , 'response error without parentline');
    }
    
    @isTest
    static void getCommunityChildNotFound(){
        
        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        req.addParameter('parentLine', '2222');
        req.addParameter('childLine', '1111');
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        PVU_CommunityParameters__mdt testMdt = PVU_CommunityParameters__mdt.getInstance('ERROR_COMMUNITY_NOT_FOUND');
        PVU_CommunityParameters__mdt testMdt2 = PVU_CommunityParameters__mdt.getInstance('ERROR_COMMUNITY_MEMBER_NOT_FOUND');
        
        Test.startTest();
        PVU_CommunityValidations.getResquestCommunity();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('error', resMap.get('status') , 'response error not found');
    }

    @isTest
    static void testCommunityInactiva(){
        
        PVU_Community__c cmuni = [SELECT Id, PVU_Linea_Padre__r.OM_MSISDN__c FROM PVU_Community__c WHERE Name = 'Test Comunidad Padre 2' LIMIT 1];

        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_CommunityValidations';
        req.httpMethod = 'GET';
        req.addParameter('parentLine', cmuni.PVU_Linea_Padre__r.OM_MSISDN__c);
        req.addParameter('childLine','');
        RestContext.request = req;
        
        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        PVU_CommunityParameters__mdt testMdt = PVU_CommunityParameters__mdt.getInstance('ERROR_COMM_INACTIVE');
        
        Test.startTest();
        PVU_CommunityValidations.getResquestCommunity();
        Test.stopTest();
        
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('error', resMap.get('status') , 'response error community inactiva');
    }
}