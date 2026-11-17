@isTest
public with sharing class PVU_FileControllerTest {
    
    @TestSetup
    static void dataFactory() {
        // Create user 
        Profile p = [SELECT Id FROM Profile WHERE Name IN ('Read Only', 'Solo Lectura') LIMIT 1];
        User newUser = new User();
        newUser.Alias = 'readonl';
        newUser.Email='readonlyuser2024.1@testmail.com'; 
        newUser.EmailEncodingKey='UTF-8'; 
        newUser.LastName='Testing Readonly'; 
        newUser.LanguageLocaleKey='en_US'; 
        newUser.LocaleSidKey='en_US'; 
        newUser.ProfileId = p.Id; 
        newUser.TimeZoneSidKey='America/Los_Angeles'; 
        newUser.UserName='readonlyuser2024.1@testmail.com.develop';
        insert newUser;

        // Create an Account Record
        Account newAccount = new Account(Name = 'Test Account - ContentVersion');
        Insert newAccount;

        Blob contentBlob = Blob.valueOf('This is a test document content.');
        // Create a ContentVersion record 
        ContentVersion newContentVersion = new ContentVersion(
            Title = 'Test Document', 
            PathOnClient = 'test_document.txt', 
            VersionData = contentBlob,
            IsMajorVersion = true,
            FirstPublishLocationId = newAccount.Id
        );
        insert newContentVersion;

        Case caseTest = new Case(Subject = 'Caso Test', Status = 'New', Origin = 'V360', PVU_Level1__c ='Facturación y pagos', PVU_Level2__c = 'Financiación', PVU_Level3__c = 'Ajuste de Credito');
        insert caseTest;

        ContentVersion docA = new ContentVersion(
            Title                 = 'DOC_caseTest',
            PathOnClient          = 'DOC_caseTest.pdf',
            VersionData           = Blob.valueOf('contenido caseTest'),
            FirstPublishLocationId= caseTest.Id
        );
        insert docA;

    }

    @IsTest
    static void getContentVersionsTest() {
        Account acc1 = [SELECT Id, Name FROM Account LIMIT 1];
        String sObjectType = 'Account';
        Map<String, Object> answer = new Map<String, Object>();
        
        Test.startTest();
            answer = PVU_FileController.getFiles(acc1.Id, sObjectType);
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(answer.get('isEditPermission'), true);
        Assert.areEqual(answer.get('message'), 'Registros de arhivos consultados exitosamente.');
    }

    @IsTest
    static void getContentVersionsReadonlyTest() {
        User readonlyUser = [SELECT Id, username FROM User WHERE UserName = 'readonlyuser2024.1@testmail.com.develop'];
        Account acc1 = [SELECT Id, Name FROM Account LIMIT 1];
        String sObjectType = 'Account';
        Map<String, Object> answer = new Map<String, Object>();

        Test.startTest();
            System.runAs(readonlyUser) {
                answer = PVU_FileController.getFiles(acc1.Id, sObjectType);
            }
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(answer.get('isEditPermission'), false);
        Assert.areEqual(answer.get('message'), 'No posee los niveles de permisos necesarios para leer los archivos, contacte a su administrador.');
    }

    @isTest
	static void getContentVersionsCatchTest() {
        Id caseTest = [SELECT Id FROM Case WHERE Subject = 'Caso Test' LIMIT 1].Id;
        String sObjectType = 'Case';
        Map<String, Object> answer = new Map<String, Object>();

        Test.startTest();
        answer = PVU_FileController.getFiles(caseTest, sObjectType);
        Test.stopTest();

    }

}