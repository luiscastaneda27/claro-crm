@isTest
public class PVU_GestorComunidadesTest {

          
    @TestSetup
    static void setupTestData() {

        // Crear línea subcription y Community
        vlocity_cmt__Subscription__c subscription = new vlocity_cmt__Subscription__c(Name = 'Parent Line', OM_MSISDN__c = '1234567890', vlocity_cmt__SubscriptionNumber__c='TEST12345678');
        insert subscription;

        vlocity_cmt__Subscription__c subscriptionCommunityTest = new vlocity_cmt__Subscription__c(Name = 'Parent Line 2', OM_MSISDN__c = '679810125', vlocity_cmt__SubscriptionNumber__c='TEST1234567892');
        insert subscriptionCommunityTest ;

        PVU_Community__c community = new PVU_Community__c(Name = 'Test Community', PVU_Linea_Padre__c = subscription.Id, PVU_Estatus__c='Activa', PVU_Segmento_linea__c = 'Postpago',PVU_Fecha_de_activacion__c = System.now());
        insert community;

        PVU_Community_Member__c member = new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2358132134', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert member;

        PVU_Community_Member__c memberForDelete= new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2599318', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert memberForDelete;

    }
    
    @isTest
    static void getCommunityParameterNotFound(){

           // Simulate a GET request
           RestRequest req = new RestRequest();
           req.requestURI = '/services/apexrest/PVU_GetCommunityInfo/';
           req.httpMethod = 'GET';
        //    req.requestBody = Blob.valueOf('{"line":""}');
           req.addParameter('line', '');
           RestContext.request = req;

            // Simulate the response
            RestResponse res = new RestResponse();
            RestContext.response = res;

            Test.startTest();
            PVU_GestorComunidades.getResquestCommunity();
            
            Test.stopTest();

            Assert.areEqual(400, res.statusCode, 'Parameter required');
    }

    @isTest
    static void getCommunityParentTestSuccess(){


        // Simulate a GET request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PVU_GetCommunityInfo';
        req.httpMethod = 'GET';
        req.addParameter('line', '1234567890');
        // req.requestBody = Blob.valueOf('{"line":"1234567890"}');
        RestContext.request = req;

        // Simulate the response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        Test.startTest();
        PVU_GestorComunidades.getResquestCommunity();
        Test.stopTest();
            
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );
        Assert.areEqual('success', resMap.get('status') , 'Success on test');
    }
    

}