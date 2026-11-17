@isTest
public class PVU_ManageCommunityMemberTest {
    
    @TestSetup
    static void setupTestData() {

        // Crear línea subcription y Community
        vlocity_cmt__Subscription__c subscription = new vlocity_cmt__Subscription__c(Name = 'Parent Line', OM_MSISDN__c = '1234567890', vlocity_cmt__SubscriptionNumber__c='TEST12345678');
        insert subscription;

        PVU_Community__c community = new PVU_Community__c(Name = 'Test Community', PVU_Linea_Padre__c = subscription.Id, PVU_Estatus__c='Activa', PVU_Segmento_linea__c = 'Postpago');
        insert community;

        PVU_Community_Member__c member = new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2358132134', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert member;

        PVU_Community_Member__c memberForDelete= new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2599318', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert memberForDelete;

    }
    
    @isTest
    static void testHandlePost_AddAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"action":"add","parentLine":"1234567890","childLine":"259180393","lineType":"movil","lineSegment":"Fija","origin":"SuperApp","hasCost":true}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunityMember.Response response = PVU_ManageCommunityMember.handlePost();
        Map<String,Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_ADD');
        Test.stopTest();
        
        System.assertEquals('success', response.status);
        System.assertEquals(message.get('message'),response.message);

    }
    
    @isTest
    static void testHandlePost_EditAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"action":"edit","parentLine":"1234567890","childLine":"2358132134","newChildLine":"987654323","lineType":"movil","origin":"SuperApp","hasCost":true,"lineSegment":"Prepago"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunityMember.Response response = PVU_ManageCommunityMember.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_EDIT');
        Test.stopTest();
        
        System.assertEquals('success', response.status);
        System.assertEquals('987654323', response.childLine);
        System.assertEquals(message.get('message'),response.message);

    }
    
    @isTest
    static void testHandlePost_RemoveAction() {
        // Configurar solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        req.requestBody = Blob.valueOf('{"action":"remove","parentLine":"1234567890","childLine":"2599318","origin":"SuperApp","hasCost":true}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunityMember.Response response = PVU_ManageCommunityMember.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_REMOVE');
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

        req.requestBody = Blob.valueOf('{"action":"invalid","parentLine":"1234567890","childLine":"0987654321","origin":"SuperApp"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunityMember.Response response = PVU_ManageCommunityMember.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_INVALID_ACTION');
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

        req.requestBody = Blob.valueOf('{"parentLine":"1234567890","childLine":"0987654321","origin":"SuperApp"}');
        req.httpMethod = 'POST';
        
        Test.startTest();
        PVU_ManageCommunityMember.Response response = PVU_ManageCommunityMember.handlePost();
        Map<String,Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_ACTION_REQUIRED');
        Test.stopTest();
        
        System.assertEquals('error', response.status);
        System.assertEquals(message.get('message'), response.message);
    }
}