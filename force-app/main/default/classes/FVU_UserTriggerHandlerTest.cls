@isTest
private class FVU_UserTriggerHandlerTest {

    @isTest
    private static void afterInsertUserTest() {

        FVU_AuditField__c fields = new FVU_AuditField__c();
        fields.Name = 'Empleador';
        fields.FVU_FieldName__c = 'FVU_Empleador__c';
        fields.FVU_ObjectName__c = 'User';
        insert fields;

        Profile pAdmin = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'Administrador del sistema') LIMIT 1];
        User userAdmin = new User(
            Alias = 'TestAd', 
            Email='userAdminTEST@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Test Admin', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = pAdmin.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='userAdminTEST@testorg.com');
        insert userAdmin;

        System.runAs(userAdmin) {
            Test.startTest();
                Profile pStandard = [SELECT Id FROM Profile WHERE Name='Standard User'];
                User userStandar = new User(
                    Alias = 'TestSt', 
                    Email='userStandar01@testorg.com',
                    EmailEncodingKey='UTF-8', 
                    LastName='TestSt', 
                    LanguageLocaleKey='en_US',
                    LocaleSidKey='en_US', 
                    ProfileId = pStandard.Id,
                    TimeZoneSidKey='America/Los_Angeles', 
                    UserName='userStandar01@testorg.com',
                    FVU_Empleador__c ='Empleador Test');
                insert userStandar;

                userStandar.FVU_Empleador__c = 'Juanes';
                update userStandar;
            Test.stopTest();
        }
   }
}