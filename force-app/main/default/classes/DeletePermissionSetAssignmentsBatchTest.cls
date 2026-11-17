@isTest
public class DeletePermissionSetAssignmentsBatchTest { 
    @testSetup
    static void setupTestData() {
        // Create a Permission Set Group
        PermissionSetGroup psg = new PermissionSetGroup(
            DeveloperName = 'Test_PSG',
            MasterLabel = 'Test Permission Set Group'
        );
        insert psg;
        
        /*****Creacion del Usuario*****/
        User userAdminTest = tlc_testDataFactory.anUser()
        .withProfile('System Administrator','Administrador del Sistema')
        .withfistname('ClaroAdmin')
        .withLastName('TestUser')
        .isActive(true)
        .withTimeZoneSidKey('America/New_York')
        .withEmailEncodingKey('UTF-8')
        .withLocaleSidKey('en_US')
        .withLanguageLocaleKey('en_US')
        .build();
        insert userAdminTest;

        // Create a Permission Set Assignment
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = userAdminTest.Id,
            PermissionSetGroupId = psg.Id
        );
        insert psa;
    }

    @isTest
    static void testBatchExecution() {
        List<String> psgs = new List<String>{'Test_PSG'};
        Id userId = [SELECT Id FROM User WHERE FirstName = 'ClaroAdmin' LIMIT 1].Id;
        // Verify that test data exists before running the batch
        Integer beforeCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetGroup.DeveloperName = 'Test_PSG'];
        Assert.areEqual(beforeCount > 0, true, 'Test setup failed: No records were inserted.');
        
        
        Test.startTest();
        DeletePermissionSetAssignmentsBatch batch = new DeletePermissionSetAssignmentsBatch(psgs);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify that all records are deleted
        Integer afterCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetGroup.DeveloperName = 'Test_PSG'];
        Assert.areEqual(0, afterCount, 'Records were not deleted successfully.');
    }
}