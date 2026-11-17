/*--------------------------------------------------------------------------
Author:         Julian Giraldo - julian.giraldo@vasscompany.com
Company:        Vass
Description:    Test class for CollaborationGroupMemberHelper
----------------------------------------------------------------------------*/
@isTest
private class CollabGroMemTriggerHelper_Test {
    @testSetup
    static void setupData() {
        // Crear perfil y usuario
        Profile profile = getAdminProfile();
        User user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser' + Math.abs(Crypto.getRandomInteger()) + '@example.com',            
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        // Separar la operación del PermissionSet en un contexto diferente
        System.runAs(user1) {
            
            // Insertar objeto regular (non-setup)
            CollaborationGroup publicGroup = new CollaborationGroup(
                Name = 'Test grupo',
                CollaborationType = 'Public'
            );
            insert publicGroup;
            
            String permissionSetName = 'CanJoinChatterGroup';
            List<PermissionSet> existingPS = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
            if (!existingPS.isEmpty()) {
                PermissionSetAssignment psa = new PermissionSetAssignment(
                    AssigneeId = user1.Id,
                    PermissionSetId = existingPS[0].Id
                );
                insert psa;
            }
        }
    }
    
    private static Profile getAdminProfile(){
        return [SELECT Id, Name FROM Profile WHERE PermissionsModifyAllData = true LIMIT 1];
    }
    
    private static User getSystemAdminUser() {
        Profile sysAdminProfile = getAdminProfile();
        
        // Crear usuario de prueba con perfil de System Administrator
        User testAdmin = new User(
            Alias = 'testadm',
            Email = 'testadmin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testadmin_' + Datetime.now().getTime() + '@test.com'
        );
        insert testAdmin;
        return testAdmin;
    }
    
    @isTest
    static void testGetPublicGroupIds() {
        User adminUser = getSystemAdminUser();
        Test.startTest();
        System.runAs(adminUser) {
            Set<Id> publicGroupIds = CollaborationGroupMemberTriggerHelper.getPublicGroupIds();
            System.assertEquals(1, publicGroupIds.size(), 'There should be one public group.');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetUsersByIds() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User1' LIMIT 1];
        Set<Id> userIds = new Set<Id>{testUser.Id};
        
        Test.startTest();
        Map<Id, User> usersMap = CollaborationGroupMemberTriggerHelper.getUsersByIds(userIds);
        Test.stopTest();
        
        System.assert(usersMap.containsKey(testUser.Id), 'User should exist in the returned map.');
    }
}