@isTest
public class PVU_CommunityInfoExtract_Test {
    
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
    static void testInvokeMethod_ValidMethod() {
         Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
       input.put('parentLine', '1234567890');
          Test.startTest();               
     PVU_CommunityInfoExtract comExtract = new PVU_CommunityInfoExtract();
            Boolean result = comExtract.invokeMethod('getCommunitInformation', input, output, options);        
        Test.stopTest();
        Assert.areEqual(true, result);
        


    }
    @isTest
        static void testInvokeMethod_invalidMethod() {
         Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
       input.put('parentLine', '1234567890');
          Test.startTest();               
     PVU_CommunityInfoExtract comExtract = new PVU_CommunityInfoExtract();
            Boolean result = comExtract.invokeMethod('getCommunitInformon', input, output, options);        
        Test.stopTest();
        Assert.areEqual(false, result);
        


    }
    
     @isTest
    static void testGetCommunitInformation_ExceptionScenario() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
       input.put('parentLine', '');
      Test.startTest(); 

       PVU_CommunityInfoExtract.getCommunitInformation( input, output, options);  
        
        Test.stopTest();
         System.assertEquals('error', output.get('status'), 'The status is error');
         System.assertEquals('parentline required', output.get('message'), 'The status is error');
            System.assertEquals(400, output.get('statusCode'), 'The status is error');

    }

    @isTest
    static void testGetCommunitInformation_Exception() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('parentLine', 1234567890);
        Test.startTest();
        PVU_CommunityInfoExtract.getCommunitInformation(input, output, options);
        Test.stopTest();
        System.assertEquals('406', output.get('code'));
        System.assertEquals('Failed', output.get('status'));
    }

    

}