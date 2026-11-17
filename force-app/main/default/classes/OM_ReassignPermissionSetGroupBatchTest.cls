/**
 * @Autor         : Gabriel Alvis
 * @Empresa       : Salesforce.com
 * @Descripción   : Clase de prueba que valida ejecución de batch de reasignación de permisos
 * 
 * Ver   Fecha        Autor           Modificación
 * 1.0   2025-05-28   Gabriel Alvis   Versión inicial
**/
@isTest
private class OM_ReassignPermissionSetGroupBatchTest {

    @TestSetup
    static void buildData(){
        // Usuario test
        User objUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'apextestuser@clarosfi.com.co',
            Email = 'apextestuser@example.com',
            Alias = 'test',
            CommunityNickname = 'testuser',
            ProfileId = UserInfo.getProfileId(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            AboutMe = 'En migración a nuevo Permission Set Group'
        );
        insert objUser;

        List<PermissionSetGroup> lstPSG = [
            SELECT Id, Status
            FROM PermissionSetGroup
            WHERE DeveloperName IN ('OM_Backoffice', 'OM_Estandar', 'OM_Supervisor', 'SFI_OMRuntimeUser')
            ORDER BY DeveloperName
        ];
        
        // Fuerza recalculo de PSG nuevo en caso que no se encuentre actualizado
        for(PermissionSetGroup psg : lstPSG){
            if (psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
        }

        // Asignación de PSG a usuario test
        List<PermissionSetAssignment> lstPSAInsert = new List<PermissionSetAssignment>();
        PermissionSetAssignment objPermAssignOld = new PermissionSetAssignment(
            AssigneeId = objUser.Id,
            PermissionSetGroupId = lstPSG[1].Id
        ); 
        lstPSAInsert.add(objPermAssignOld); //OM_Estandar
        PermissionSetAssignment objPermAssignNew = new PermissionSetAssignment(
            AssigneeId = objUser.Id,
            PermissionSetGroupId = lstPSG[3].Id
        ); 
        lstPSAInsert.add(objPermAssignNew); //SFI_OMRuntimeUser

        PermissionSetAssignment objPermAssignOld0 = new PermissionSetAssignment(
            AssigneeId = objUser.Id,
            PermissionSetGroupId = lstPSG[0].Id
        );
        lstPSAInsert.add(objPermAssignOld0); //OM_Backoffice

        insert lstPSAInsert;
    }

    @isTest
    static void testReassignPSG() {
        Test.StartTest();
        OM_ReassignPermissionSetGroupBatch objReassign = new OM_ReassignPermissionSetGroupBatch(true);
        ID batchprocessid = Database.executeBatch(objReassign);
        Test.StopTest();

        User objUser = [
            SELECT Id
            FROM User
            WHERE Username = 'apextestuser@clarosfi.com.co'
        ];

        Assert.areEqual(0, Database.countquery('SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetGroup.DeveloperName = \'SFI_OMRuntimeUser\' AND AssigneeId=\'' + objUser.Id + '\''), 'Error en la reasignación de Grupo de Conjunto de Permisos');  
    }
}