/*------------------------------------------------------------
    
|   Author:        	Luis Mendoza
    Company:       	Salesforce.com
    Description:   	class test to PVU_SecurityProcess
    History
    <Date>      	<Author>     	<Change Description>
    15/05/2024   	Luis Mendoza	Initial Version
------------------------------------------------------------*/

@isTest
private class PVU_SecurityProcessTEST {

    @TestSetup
    static void makeData(){

        accesosProcesos__c acc = new accesosProcesos__c();
        acc.grupo_permisos__c = 'FVU_Asesor_TMK'; 
        acc.Componente__c = 'TEST Component';
        acc.IsActive__c = true;
        acc.Access__c = true;

        insert acc;    
        
        Profile p = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar') LIMIT 1]; 

        User u = new User();
            u.Alias = 'standt';
            u.Email='standarduser2024.1@yopmail.com'; 
            u.EmailEncodingKey='UTF-8'; 
            u.LastName='Testing'; 
            u.LanguageLocaleKey='en_US'; 
            u.LocaleSidKey='en_US'; 
            u.ProfileId = p.Id; 
            u.TimeZoneSidKey='America/Los_Angeles'; 
            u.UserName='standarduser2024.1@yopmail.com.develop';

        insert u;
        
        Case caseA = new Case(Subject = 'Caso A', Status = 'New', Origin = 'Phone');
        insert caseA;
        
        Case caseB = new Case(Subject = 'Caso B', Status = 'New', Origin = 'Phone');
        insert caseB;
        
        ContentVersion docA = new ContentVersion(
            Title                 = 'DOC_A',
            PathOnClient          = 'DOC_A.pdf',
            VersionData           = Blob.valueOf('contenido A'),
            FirstPublishLocationId= caseA.Id
        );
        insert docA;
        
        ContentVersion docB = new ContentVersion(
            Title                 = 'DOC_B',
            PathOnClient          = 'DOC_B.txt',
            VersionData           = Blob.valueOf('contenido B'),
            FirstPublishLocationId = caseB.Id
        );
        insert docB;
        
        docB = [
            SELECT Id, ContentDocumentId
            FROM   ContentVersion
            WHERE  Id = :docB.Id
            LIMIT  1
        ];

    }

    @isTest
    static void methodSetComponent() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('compentName', 'TEST Component');
        input.put('isAccess', true);

        Test.startTest();               
            PVU_SecurityProcess postCaseMethod = new PVU_SecurityProcess();
            Boolean result = postCaseMethod.invokeMethod('getIsAccessTheProcess', input, output, options);        
        Test.stopTest();
        Assert.areEqual(true, result);
    }
    @isTest
    static void methodSetComponentWithOtherUser() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('compentName', 'TEST Component');
        input.put('isAccess', true);
        User us = [Select Id FROM User where Email = 'standarduser2024.1@yopmail.com'];
        System.runAs(us){
            Test.startTest();               
            PVU_SecurityProcess postCaseMethod = new PVU_SecurityProcess();
            Boolean result = postCaseMethod.invokeMethod('getIsAccessTheProcess', input, output, options);        
            Test.stopTest();
            Assert.areEqual(true, result);
        }
    }

    @isTest
    static void methodToUserComponent() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        User us = [Select Id FROM User where Email = 'standarduser2024.1@yopmail.com'];
        System.runAs(us){
            Test.startTest();               
                PVU_SecurityProcess postCaseMethod = new PVU_SecurityProcess();
                Boolean result = postCaseMethod.invokeMethod('getIsAccessTheProcessByPSG', input, output, options);        
            Test.stopTest();
            
            Assert.areEqual(true, result);
        }
    }
    
    @isTest
    static void testGetIsAccessTheProcessByCP() {
        // Iniciar el bloque de pruebas
        Test.startTest();

        // Crear un mapa de entrada simulado
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('isAccess', true);  // Cambia este valor según el caso que quieras probar

        // Crear los mapas de salida y opciones
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Mock para el usuario con perfil de 'Admin'
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name IN('System Administrator', 'Administrador del sistema') LIMIT 1];
        User adminUser = new User(
            Alias = 'admintS',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AdminTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standar0912@test.com'
        );
        insert adminUser; //NOPMD

        // Crear mock para Custom Permissions y PermissionSet
      	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CRS_Procesos'];
       	insert new PermissionSetAssignment(AssigneeId = adminUser.id, PermissionSetId = ps.Id);//NOPMD
    
        // Simular la respuesta del sistema para las Custom Permissions usando un RunAs
        System.runAs(adminUser) {
            // Llamar al método a probar
            PVU_SecurityProcess postCaseMethod1 = new PVU_SecurityProcess();
            Boolean result = postCaseMethod1.invokeMethod('getIsAccessTheProcessByCP', inputMap, outMap, options);
            PVU_SecurityProcess.getIsAccessTheProcessByCP(inputMap, outMap, options);
			
            // Verificar que el mapa de salida tenga el acceso procesado correctamente
            Map<String, Object> accessProcessMap = (Map<String, Object>) outMap.get('accessProcess');

            // Verificaciones para asegurar que los resultados son los esperados
            System.assertEquals(true, accessProcessMap.get('isAdmin'), 'El usuario debería ser Admin');
            System.assert(accessProcessMap.containsKey('PVU_activacionServicios'), 'Debería contener PVU_activacionServicios');
            System.assertEquals(true, accessProcessMap.get('PVU_activacionServicios'), 'El permiso PVU_activacionServicios debería estar presente');
            Assert.areEqual(true, result);
        }
		
        Test.stopTest();
    }
    
    @isTest
    static void getContentVersionsTest() {

        Id aId = [SELECT Id FROM Case WHERE Subject='Caso A' LIMIT 1].Id;
        Id bId = [SELECT Id FROM Case WHERE Subject='Caso B' LIMIT 1].Id;

        Test.startTest();

        Map<String,Object> o1 = PVU_SecurityProcess.getContentVersions(aId, 'Case');
        Map<String,Object> o2 = PVU_SecurityProcess.getContentVersionsFromCDL(bId, 'Case');

        System.assertNotEquals(null, o1);
        System.assertNotEquals(null, o2);
        System.assertEquals(1, ((List<ContentVersion>) o1.get('data')).size());
        System.assertEquals(1, ((List<ContentVersion>) o2.get('data')).size());
        Test.stopTest();
    }
        
    @isTest
	static void getContentVersionsCatchTest() {
        Id aId = [SELECT Id FROM Case WHERE Subject = 'Caso A' LIMIT 1].Id;
        
        Test.startTest();

        try {
            PVU_SecurityProcess.getContentVersions(aId, 'objPrueba');
            System.assert(false, 'Debió lanzar excepción (catch).');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Se espera excepción catch.');
        }
    
        try {
            PVU_SecurityProcess.getContentVersionsFromCDL(aId, 'objPrueba');
            System.assert(false, 'Debió lanzar excepción (catch rethrow).');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Se espera excepción catch.');
        }
        
        Test.stopTest();

    }
}