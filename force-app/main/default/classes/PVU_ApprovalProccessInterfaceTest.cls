/**
 * This is a test class for the PVU_ApprovalProccessInterface class.
 */
@IsTest
public with sharing class PVU_ApprovalProccessInterfaceTest {
	private static final Id CASE_RECORDTYPE_ID = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('GestionCasosPosventa').getRecordTypeId();
    @IsTest
    private static void test1() {
        User testUser = new User(
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
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '53145705';
        insert acc;
        
        Case cs = new Case();
        cs.Status = 'En curso';
        cs.PVU_Sub_Estado__c='Ejecutado';
        cs.RecordTypeId= CASE_RECORDTYPE_ID;
        cs.AccountId = acc.Id;
        cs.PVU_IdSolicitud__c = '123456';
        insert cs;

        test.startTest();
            // Create an approval request
            Map<String,Object> inputMap = new Map<String,Object>();
            inputMap.put('CaseId', cs.Id);
            inputMap.put('ApprovalProccessName', 'PVU_DuplicadoIMEI');
            inputMap.put('NextApproverId', testUser.Id);
            Map<String,Object> outMap = new Map<String,Object>();
            Map<String,Object> options = new Map<String,Object>();
            PVU_ApprovalProccessInterface ctr = new PVU_ApprovalProccessInterface();
            
            ctr.invokeMethod('approvalCaseDuplicadoIMEI', inputMap,outMap,options);
            System.assert(outMap.get('isSuccess') == true);
        
        	ctr.invokeMethod('approvalCaseDuplicadoIMEI', inputMap,outMap,options);
        
        test.stopTest();

    }
    
    
    @IsTest
    private static void test2() {
        User testUser = new User(
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
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '53145705';
        insert acc;
        
        Case cs = new Case();
        cs.Status = 'En curso';
        cs.PVU_Sub_Estado__c='Ejecutado';
        cs.RecordTypeId= CASE_RECORDTYPE_ID;
        cs.AccountId = acc.Id;
        cs.PVU_IdSolicitud__c = '123456';
        insert cs;
        
        test.startTest();
        // Create an approval request
        Map<String,Object> inputMap = new Map<String,Object>();
        inputMap.put('CaseId', cs.Id);
        inputMap.put('queueName', 'PVU_DuplicadoIMEI');
        inputMap.put('title', testUser.Id);
        inputMap.put('body', testUser.Id);
        inputMap.put('targetId', cs.Id);
        
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        PVU_ApprovalProccessInterface ctr = new PVU_ApprovalProccessInterface();
        
        ctr.invokeMethod('sendPushNotiToQueue', inputMap,outMap,options);
        System.assert(outMap.get('isSuccess') == 'ok');
        ctr.invokeMethod('approvalCaseDuplicadoIMEI', inputMap,outMap,options);
        
        test.stopTest();
        
    }
    
    @IsTest
    private static void test3() {
        User testUser = new User(
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
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '53145705';
        insert acc;
        
        Case cs = new Case();
        cs.Status = 'En curso';
        cs.PVU_Sub_Estado__c='Ejecutado';
        cs.RecordTypeId= CASE_RECORDTYPE_ID;
        cs.AccountId = acc.Id;
        cs.PVU_IdSolicitud__c = '123456';
        insert cs;
        
        test.startTest();
        // Create an approval request
        Map<String,Object> inputMap = new Map<String,Object>();
        inputMap.put('caseId', cs.Id);
        inputMap.put('queueName', 'PVU_DuplicadoIMEI');
        inputMap.put('title', testUser.Id);
        inputMap.put('body', testUser.Id);
        inputMap.put('targetId', cs.Id);
        
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        PVU_ApprovalProccessInterface ctr = new PVU_ApprovalProccessInterface();
        
        ctr.invokeMethod('sendPushNotiToUser', inputMap,outMap,options);
        System.assert(outMap.get('isSuccess') == 'ok');        
        test.stopTest();
        
    }
}