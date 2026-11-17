/*******************************************************************************
* Autor: Daniel Alvarez
* Fecha: 2024-12-12
* Equipo: Posventas
* Descripcion: test de API que permite gestionar las comunidades.

<Date>            <Author>             <Description>                                      <Version>
2024-12-03         C.Daniel Alvarez       Creacion                                               01
***********************************************************************************/
@isTest
private class PVU_ManageCommunityTest {

  
    @TestSetup
    static void setupTestData() {

        // Crear línea subcription y Community
        vlocity_cmt__Subscription__c subscription = new vlocity_cmt__Subscription__c(Name = 'Parent Line', OM_MSISDN__c = '1234567890', vlocity_cmt__SubscriptionNumber__c='TEST12345678');
        insert subscription;

        vlocity_cmt__Subscription__c subscriptionCommunityTest = new vlocity_cmt__Subscription__c(Name = 'Parent Line 2', OM_MSISDN__c = '679810125', vlocity_cmt__SubscriptionNumber__c='TEST1234567892');
        insert subscriptionCommunityTest ;

        PVU_Community__c community = new PVU_Community__c(Name = 'Test Community', PVU_Linea_Padre__c = subscription.Id, PVU_Estatus__c='Activa', PVU_Segmento_linea__c = 'Postpago');
        insert community;

        PVU_Community_Member__c member = new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2358132134', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert member;

        PVU_Community_Member__c memberForDelete= new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2599318', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert memberForDelete;

    }
    
    @isTest
    static void testHandlePost_ActivateAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{ "parentLine":"679810125","action":"activate", "origin":"superApp","lineSegment":"Postpago"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunity.Response response = PVU_ManageCommunity.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_ACTIVATED');
        Test.stopTest();
        
        System.assertEquals('success', response.status);
        System.assertEquals(message.get('message'),response.message);

    }
    
    @isTest
    static void testHandlePost_DeactivateAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{ "parentLine":"1234567890","action":"deactivate", "origin":"superApp","lineSegment":"Postpago"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunity.Response response = PVU_ManageCommunity.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_DEACTIVATED');
        Test.stopTest();
        
        System.assertEquals('success', response.status);
        System.assertEquals(message.get('message'),response.message);

    }
    
    @isTest
    static void testHandlePost_SuspendAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{ "parentLine":"1234567890","action":"suspend", "origin":"superApp","lineSegment":"Postpago"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunity.Response response = PVU_ManageCommunity.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_SUSPENDED');
        Test.stopTest();
        
        System.assertEquals('success', response.status);
        System.assertEquals(message.get('message'),response.message);
    }

    @isTest
    static void testHandlePost_InvalidAction() {
        // Configurar solicitud con una acción inválida
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"action":"invalid","parentLine":"1234567890","origin":"SuperApp","lineSegment":"Postpago"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunity.Response response = PVU_ManageCommunity.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_INVALID_ACTION');
        Test.stopTest();
        
        System.assertEquals('error', response.status);
        System.assertEquals(message.get('message'), response.message);
    }

    @isTest
    static void testHandlePost_MissingAction() {
        // Configurar solicitud sin acción
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"parentLine":"1234567890","origin":"SuperApp"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunity.Response response = PVU_ManageCommunity.handlePost();
         Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_ACTION_REQUIRED');
        Test.stopTest();
        
        System.assertEquals('error', response.status);
        System.assertEquals(message.get('message'), response.message);
    }
}