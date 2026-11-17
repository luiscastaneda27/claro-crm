/*------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:   	Class test to "PVU_CalloutHandlerDocument"
MOCK Class:    	PVU_MockCalloutHandlerDocument
History
<Date>      	<Author>     	<Change Description>
29-Abril-2024	Luis Mendoza	Initial Version
------------------------------------------------------------*/
@isTest
public class PVu_CalloutHandlerDocumentTEST {

    @TestSetup
    static void makeData(){
        Account account = new Account();
        account.Name = 'Account Consumer';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        insert account;

        //Contract
        Contract contractActive = new Contract();
        contractActive.name = 'Activated';
        contractActive.AccountId = account.Id;
        contractActive.Status = 'Draft';
        Insert contractActive;

        vlocity_cmt__DocumentTemplate__c docTemplate = new  vlocity_cmt__DocumentTemplate__c();
        docTemplate.Name = 'TEST_TEMPLATE';
        docTemplate.vlocity_cmt__UsageType__c = 'Contract';
        docTemplate.vlocity_cmt__VersionNumber__c = 1;
        insert docTemplate;

        vlocity_cmt__ContractVersion__c newContractVersion = new vlocity_cmt__ContractVersion__c();
        newContractVersion.Name = 'Version 1';
        newContractVersion.vlocity_cmt__ContractId__c = contractActive.Id;
        newContractVersion.vlocity_cmt__DocumentTemplateId__c = docTemplate.Id;
        insert newContractVersion;
                
        Attachment attach=new Attachment();     
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.Description = 'Test';
        attach.ContentType = 'Test';
        attach.parentId = newContractVersion.id;
        insert attach;

        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = attach.Name+'.pdf';
        newContentVersion.PathOnClient = '/' + attach.Name+'.pdf';
        newContentVersion.ContentLocation = 'S';
        newContentVersion.VersionData = (attach.Body == null ? Blob.valueOf('.') : attach.Body);
        newContentVersion.Description = attach.Description;
        newContentVersion.SharingPrivacy = 'N'; // Can be always public.
        newContentVersion.FirstPublishLocationId = attach.ParentId; // Parent Id
        insert newContentVersion;
    } 


    @isTest static  void testGetCalloutSuccess() {

        List<ContentVersion> contVers =  [SELECT id, VersionData FROM ContentVersion LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new PVU_MockCalloutHandlerDocument());     

        String jsonInput = '{"urlPath":"/MS/RES/Resource/RsResourceEnSpDocUpload/V1/InsertEnSpDocDelay","docName":"pruebaFallecimiento.pdf","contentVersionId":"'+ contVers[0].id +'","document":{"xdTipoCliente":"","xdNumeroContrato":"","xdFechaCambio":"","xdFechaRecepcion":"","xdIdPunto":"","xdOrdenTrabajo":"","xdTipoPlan":"","xdNumeroCuenta":"","xdMIN":"","xdNumeroRadicado":"","xdIdProceso":"","xdNumeroIdentificacion":"198734234","xdTipoIdentificacion":"20987924","xdNombrePunto":"","xdIdCliente":"","xdIdSalesForce":"500750000038ep5AAA","xdEmpresa":"COMCEL","xdTipoDocumental":"REGISTRO_CIVIL_DE_DEFUNCION","xdFechaDocumento":"2024-04-29   12:00:36-0500","xdFechaArchivo":"2024-04-29   12:00:36-0500"},"apiKey":"pxt5eVIxqakYdeR18vQ20cgTk4uhiBUC"}';


        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        test.startTest();
            PVU_CalloutHandlerDocument calloutResp = new PVU_CalloutHandlerDocument();
            Boolean result = calloutResp.invokeMethod('getCallOutHandlerDocument', inputMap, outputMap, options);
        test.stopTest();

        Assert.areEqual(true, result);

    }
    @isTest static  void testGetCalloutWithoutDocument() {

        Test.setMock(HttpCalloutMock.class, new PVU_MockCalloutHandlerDocument());     

        String jsonInput = '{"urlPath":"/MS/RES/Resource/RsResourceEnSpDocUpload/V1/InsertEnSpDocDelay","docName":"pruebaFallecimiento.pdf","contentVersionId":"484848","document":{"xdTipoCliente":"","xdNumeroContrato":"","xdFechaCambio":"","xdFechaRecepcion":"","xdIdPunto":"","xdOrdenTrabajo":"","xdTipoPlan":"","xdNumeroCuenta":"","xdMIN":"","xdNumeroRadicado":"","xdIdProceso":"","xdNumeroIdentificacion":"198734234","xdTipoIdentificacion":"20987924","xdNombrePunto":"","xdIdCliente":"","xdIdSalesForce":"500750000038ep5AAA","xdEmpresa":"COMCEL","xdTipoDocumental":"REGISTRO_CIVIL_DE_DEFUNCION","xdFechaDocumento":"2024-04-29   12:00:36-0500","xdFechaArchivo":"2024-04-29   12:00:36-0500"},"apiKey":"pxt5eVIxqakYdeR18vQ20cgTk4uhiBUC"}';


        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        test.startTest();
            PVU_CalloutHandlerDocument calloutResp = new PVU_CalloutHandlerDocument();
            Boolean result = calloutResp.invokeMethod('getCallOutHandlerDocument', inputMap, outputMap, options);
        test.stopTest();

        Assert.areEqual(true, result);

    }
}