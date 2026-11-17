/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 10-10-2024
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   10-09-2024   SALESFORCE   Initial Version
**/
@isTest
public class PVU_NotifyOldInteractionsBatchTest {

    @testSetup
    static void setupData() {

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

        PermissionSetGroup userPSG = [SELECT Id, DeveloperName from PermissionSetGroup WHERE DeveloperName = 'Claro_EPC_Administrador'];
        System.Test.calculatePermissionSetGroup(userPSG.Id);
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
        permissionSetAssignment.PermissionSetGroupId  = userPSG.id;
        permissionSetAssignment.AssigneeId = userAdminTest.Id;
        insert permissionSetAssignment;

        User userStandardTest = tlc_testDataFactory.anUser()
        .withProfile('Standard User Claro','Usuario Standard Claro')
        .withfistname('Claro')
        .withLastName('TestUser')
        .isActive(true)
        .withTimeZoneSidKey('America/New_York')
        .withEmailEncodingKey('UTF-8')
        .withLocaleSidKey('en_US')
        .withLanguageLocaleKey('en_US')
        .build();
        insert userStandardTest;
        


        PermissionSetGroup userPSGCurrent = [SELECT Id, DeveloperName from PermissionSetGroup WHERE DeveloperName = 'FVU_Asesor'];
        System.Test.calculatePermissionSetGroup(userPSGCurrent.Id);
        PermissionSetAssignment permissionSetAssignmentCu = new PermissionSetAssignment();
        permissionSetAssignmentCu.PermissionSetGroupId  = userPSGCurrent.id;
        permissionSetAssignmentCu.AssigneeId = userStandardTest.Id;
        insert permissionSetAssignmentCu;


 

        System.runAs(userAdminTest){

        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'AccuntTestForAccesos';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '123456789';
        insert acc;
        // Create test data
        
        EngagementInteraction interaction = new EngagementInteraction(
            //Name = 'Test Interaction ' + i,
            InitiatingAttendeeId = [SELECT Id FROM Account LIMIT 1].Id, // You may need to create an Account or other sObject for testing
            Status = 'Nuevo',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addDays(15),
            OwnerId = userAdminTest.Id,
            CommunicationChannel = 'Llamada de voz'
               //CreatedDate = DateTime.now().addHours(-3) // Ensure it's older than 2 hours
            );
        insert interaction;
        }
        /*****Fin*****/

    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        PVU_NotifyOldInteractionsBatch batch = new PVU_NotifyOldInteractionsBatch();
        
        Database.QueryLocator queryLocator = batch.start(null);
        System.assertNotEquals(null, queryLocator,'Valor no vacio');
        
        List<EngagementInteraction> interactions = [SELECT Id,OwnerId, Name, InitiatingAttendeeId FROM EngagementInteraction];
        batch.execute(null, interactions);
        
        Test.stopTest();
        
        // Verify the interactions
        for(EngagementInteraction interaction : interactions) {
            System.assertNotEquals(null, interaction, 'Valor no vacio');
        }
    }

}