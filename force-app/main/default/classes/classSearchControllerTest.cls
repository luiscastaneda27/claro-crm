/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 06-04-2024
 * @last modified by  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   02-23-2024   SALESFORCE   Initial Version
**/
@isTest
public class classSearchControllerTest {
    @TestSetup
    static void setup(){
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
        /*****Fin*****/



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
         /*****Fin*****/

            //Creación de los AccesosProcesos por PermissionSet
        accesosProcesos__c ap1 = new accesosProcesos__c();
        ap1.Canal__c = 'OrdersTest';
        ap1.Componente__c=  'PVUDevTest1'; 
        ap1.Tipo__c = 'OmniScript';
        ap1.Descripcion__c = 'Para proceso test 1';
        ap1.Grupo_Permisos__c  = 'Claro_EPC_Administrador';
        ap1.DetalleComponente__c = 'Devolución TEst';
        ap1.IsActive__c = true;
        ap1.Access__c = true;
        ap1.ObjectName__c = 'Account';
        insert ap1;

        accesosProcesos__c ap2 = new accesosProcesos__c();
        ap2.Canal__c = 'OrdersTest';
        ap2.Componente__c=  'PVUDevTest1'; 
        ap2.Tipo__c = 'OmniScript';
        ap2.Descripcion__c = 'Para proceso test 1';
        ap2.Grupo_Permisos__c  = 'FVU_Asesor';
        ap2.DetalleComponente__c = 'Devolución TEst';
        ap2.IsActive__c = true;
        ap2.Access__c = true;
        ap2.ObjectName__c = 'Account';
        insert ap2;
        }       



    }
        
    
    @isTest
    static void testViewPermissionsGroupsAdmin() {
        // Crear datos de prueba si es necesario
        // Insertar un usuario de prueba
        User testUser = [Select Id from user where FirstName = 'ClaroAdmin'];
        System.runAs(testUser){
        List<String> result = classSearchController.viewPerpissionsGroups();

        // Validar el resultado según la lógica de tu método viewPermissionsGroups
        System.assertEquals(1, result.size());
        }
        // Añadir más aserciones según sea necesario
    }

    @isTest
    static void testViewgetObjectsListAdminUser() {
        // Crear datos de prueba si es necesario
        // Insertar un usuario de prueba
        Id testAccountId = [Select Id from account where Name = 'AccuntTestForAccesos'].Id;
        User testUser = [Select Id from user where FirstName = 'ClaroAdmin'];
        System.runAs(testUser){
        Map<String,classSearchController.accesoWrapper > result = classSearchController.getObjectList(testAccountId);

        // Validar el resultado según la lógica de tu método viewPermissionsGroups
        //System.assertEquals(0, result.size());
        System.assert(result.size() > 0);
        }
        // Añadir más aserciones según sea necesario}
    }

    @isTest
    static void testViewgetObjectsListCurrentUser() {
        // Crear datos de prueba si es necesario
        // Insertar un usuario de prueba
        Id testAccountId = [Select Id from account where Name = 'AccuntTestForAccesos'].Id;
        User testUserCurrUs = [Select Id from user where FirstName = 'Claro'];
        System.runAs(testUserCurrUs){
        Map<String,classSearchController.accesoWrapper > result = classSearchController.getObjectList(testAccountId);

        // Validar el resultado según la lógica de tu método viewPermissionsGroups
        //System.assertEquals(0, result.size());
        System.assert(result.size() > 0);
        }
        // Añadir más aserciones según sea necesario
    }


}