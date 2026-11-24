/*------------------------------------------------------------------------
Author:        	Silvia Tovar
Company:       	Salesforce.com
Description:   	Test class to manage the coverage code for the class PVU_TMFCustomCase
History
<Date>      	<Author>     	<Description>
22-Dic-23		Silvia Tovar	
06-Mar-24		Luis Mendoza	add method test to getCase
14-Jun-24		Luis Mendoza	update all methods
09-Sep-25		Ezequiel Olivera add method test from line 870 to 1139
----------------------------------------------------------------------------*/

@isTest
public with sharing class PVU_TMFCustomCaseTest {
    
    private static final Id CASE_RECORDTYPE_ID = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('GestionCasosPosventa').getRecordTypeId();
    
    @TestSetup
    static void makeData(){
        
        PVU_TMFFieldsInsertCase__mdt mdt = PVU_TMFFieldsInsertCase__mdt.getInstance('CambiodeSIMCard');
        
        Map<String, Object> datos = new Map<String, Object>();
        datos.put('DeveloperName', mdt.DeveloperName);
        datos.put('field_custom__c', mdt.field_custom__c);
        datos.put('type__c', mdt.type__c);  
        datos.put('PVU_Required__c', mdt.PVU_Required__c);  
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '53145705';
        insert acc;
        
        Product2 prod = new Product2();
        prod.Name = 'Test Product2';
        prod.Family = 'Mobile';
        prod.vlocity_cmt__Type__c = 'MSISDN';
        insert prod;
        
        vlocity_cmt__Subscription__c subs = new vlocity_cmt__Subscription__c();
        subs.vlocity_cmt__SubscriptionNumber__c = '01234';
        subs.OM_MSISDN__c = '573012345678';
        insert subs;
        
        Asset asset = new Asset();
        asset.Name = 'Test Asset FIN';
        asset.AccountId = acc.Id;
        asset.Product2Id = prod.Id;
        asset.vlocity_cmt__SubscriptionId__c = subs.Id;
        asset.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-MSISDN": "573012345678"}';
        asset.vlocity_cmt__ParentItemId__c = '0123456789';
        asset.vlocity_cmt__AssetReferenceId__c = '0123456789';
        asset.FIN_IdReferenciaDelCredito92__c = '92000000000';
        asset.PVU_IMEI__c = 'DK5730123456';
        asset.FIN_NumeroDeCredito__c = 'CRED0';
        insert asset;
        
        Contact contact = new Contact();
        contact.LastName='Mendez';
        contact.FVU_DocumentNumber__c='53145705';
        contact.FVU_DocumentType__c='CC';
        insert contact;
        
        Case cs = new Case();
        cs.Status = 'En curso';
        cs.PVU_Sub_Estado__c='En diagnóstico';
        cs.RecordTypeId= CASE_RECORDTYPE_ID;
        cs.AccountId = acc.Id;
        cs.PVU_IdSolicitud__c = '123456';
        insert cs;
    	
        
        
        
        // Setup test data in custom metadata
        PVU_Controller_Field_Dependencis__mdt dependency1 = PVU_Controller_Field_Dependencis__mdt.getInstance('Case');
        
    }
    
    @isTest
    static void insertCaseTMFTestSucces(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '53145705';
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
		String subscriberNumber = '573012345678';       
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        Boolean testWasCalled = false;
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest();
        
        System.assertEquals(result,true);
    }
    
    @isTest
    static void insertCaseTMFTestSucces2(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '12345678';
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
		String subscriberNumber = '573012345678';       
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        Boolean testWasCalled = false;
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest();
        System.assertEquals(result,true);
        
    }

    @isTest
    static void insertCaseTMFTestSucces3(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '53145705';
        String status = 'En curso';
        String description = 'Creacion de caso ajuste de credito';
        String category = 'Facturación y pagos';
        String subcategory = 'Financiación';
        String customerVoice = 'Ajuste de Credito';
		String subscriberNumber = '573012345678';
        String financingCode = 'CRED0'; 
        String billingAccountCode = '92000000000'; 
        String serialNumber = 'DK5730123456';        
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        input.put('financingCode', financingCode);
        input.put('billingAccountCode', billingAccountCode);
        input.put('serialNumber', serialNumber);
        Boolean testWasCalled = false;
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest();
        System.assertEquals(result,true);
        
    }

    @isTest
    static void insertCaseTMFTestSucces4(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '12345678';
        String status = 'En curso';
        String description = 'Creacion de caso ajuste de credito';
        String category = 'Facturación y pagos';
        String subcategory = 'Financiación';
        String customerVoice = 'Ajuste de Credito';
		String subscriberNumber = '573012345678';
        String financingCode = 'CRED0'; 
        String billingAccountCode = '92000000000'; 
        String serialNumber = 'DK5730123456';        
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        input.put('financingCode', financingCode);
        input.put('billingAccountCode', billingAccountCode);
        input.put('serialNumber', serialNumber);
        Boolean testWasCalled = false;
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest();
        System.assertEquals(result,true);
    }
    
    @isTest
    static void insertCaseTMFTestSucces5(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'SuperApp');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '53145705';
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
		String subscriberNumber = '573012345678';       
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        Boolean testWasCalled = false;
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest();
        
        System.assertEquals(result,true);
    }

    @isTest
    static void insertCaseTMFTestSucces6(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        listData.put('name', 'FIN_MotivoAjuste__c');
        listData.put('value', '1');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '53145705';
        String status = 'En curso';
        String description = 'Creacion de caso ajuste de credito';
        String category = 'Facturación y pagos';
        String subcategory = 'Financiación';
        String customerVoice = 'Ajuste de Credito';
        String subscriberNumber = '573012345678';
        String financingCode = 'CRED0'; 
        String billingAccountCode = '92000000000'; 
        String serialNumber = 'DK5730123456';        
        
        // Base inputs - compartidos entre todas las pruebas
        Map<String, Object> baseInput = new Map<String, Object>();
        baseInput.put('type', CASE_RECORDTYPE_ID);
        baseInput.put('channel', channel);
        baseInput.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        baseInput.put('customerVoice', customerVoice);
        baseInput.put('documentType', documentType);
        baseInput.put('documentNumber', documentNumber);
        baseInput.put('subcategory', subcategory);
        baseInput.put('category', category);
        baseInput.put('description', description);
        baseInput.put('status', status);
        baseInput.put('subscriberNumber', subscriberNumber);

        // Crear copias independientes para cada prueba
        Map<String, Object> input1 = baseInput.clone();
        Map<String, Object> input2 = baseInput.clone();
        Map<String, Object> input3 = baseInput.clone();
        
        // Caso 1: Código de financiamiento incorrecto
        input1.put('financingCode', 'CRED1');  // Código incorrecto
        input1.put('billingAccountCode', billingAccountCode);
        input1.put('serialNumber', serialNumber);
        
        // Caso 2: Cuenta de facturación incorrecta
        input2.put('financingCode', financingCode);
        input2.put('billingAccountCode', '0');  // Cuenta incorrecta
        input2.put('serialNumber', serialNumber);
        
        // Caso 3: Número de serie incorrecto
        input3.put('financingCode', financingCode);
        input3.put('billingAccountCode', billingAccountCode);
        input3.put('serialNumber', 'D');  // Serial incorrecto
        
        Test.startTest();               
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        
        // Crear un mapa separado para cada llamada
        Map<String, Object> output1 = new Map<String, Object>();
        Map<String, Object> output2 = new Map<String, Object>();
        Map<String, Object> output3 = new Map<String, Object>();
        
        Boolean result1 = postCaseMethod.invokeMethod('insertCaseTMF', input1, output1, options);
        /*Boolean result2 = postCaseMethod.invokeMethod('insertCaseTMF', input2, output2, options);*/
        Boolean result3 = postCaseMethod.invokeMethod('insertCaseTMF', input3, output3, options);         
        Test.stopTest();
        
        System.assertEquals(true, result1);
        /*System.assertEquals(true, result2);*/
        System.assertEquals(true, result3);
        
        // Verificar mensajes de error específicos
        System.assertEquals('409', output1.get('code'));
        System.assertEquals(System.Label.FIN_TroubleTicket_financingCodeNotMatch, output1.get('message'));
        
        /*System.assertEquals('409', output2.get('code'));
        System.assertEquals(System.Label.FIN_TroubleTicket_financingCodeNotMatch, output2.get('message'));*/
        
        System.assertEquals('409', output3.get('code'));
        System.assertEquals(System.Label.FIN_TroubleTicket_serialNumberNotMatch, output3.get('message'));
    }
    
    @isTest
    static void insertCaseTMFTestDocumentNotFound(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        troubleTicketCharacteristic.add(listData);
        
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
        String subscriberNumber = '573012345678';
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        Test.startTest();
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);       
        Test.stopTest();
        System.assertEquals(result,true);
        
    }
    
    @isTest
    static void insertCaseTMFTestDocumentNotFound2(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        troubleTicketCharacteristic.add(listData);
        
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
        String subscriberNumber = '573052345678';
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        input.put('subscriberNumber', subscriberNumber);
        Test.startTest();
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);       
        Test.stopTest();
        System.assertEquals(result,true);
        
    }
    
    @isTest
    static void insertCaseTMFTestDocumentSubscriberNotFound(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        troubleTicketCharacteristic.add(listData);
        
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
        
        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);
        Test.startTest();
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);       
        Test.stopTest();
        System.assertEquals(result,true);
        
    }
    
    @isTest
    static void insertCaseTMFTestError(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();        
        
        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        troubleTicketCharacteristic.add(listData);
        
        String documentType =  'CC';
        String documentNumber = '53145705';
        String status = 'En curso';
        String description = 'Creacion de caso portabilidad out';
        String category = 'Solicitud de información y modificaciones';
        String subcategory = 'Portabilidad';
        String customerVoice = 'Portabilidad Out';
        String subscriberNumber = '573012345678';
        
        input.put('type', '');
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', customerVoice);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        input.put('subcategory', subcategory);
        input.put('category', category);
        input.put('description', description);
        input.put('status', status);   
        input.put('subscriberNumber', subscriberNumber);  
        Test.startTest();
        PVU_TMFCustomCase postCaseMethod = new PVU_TMFCustomCase();
        Boolean result = postCaseMethod.invokeMethod('insertCaseTMF', input, output, options);        
        Test.stopTest(); 
        System.assertEquals(result,true);
    }
    
    @isTest
    static void updateRecordDynamicTestSucces(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();  
        List<Object> wheredata = new List<Object>();
        
        Case  caso =  [Select Id from Case limit 1];
        String recordId=caso.Id;
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        listData.put('name', 'Respuesta__c');
        listData.put('value', 'Aprobado');
        
        troubleTicketCharacteristic.add(listData);
        
        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Id');
        listWData.put('value', recordId);
        listWData.put('operater', '');
        
        
        wheredata.add(listWData);
        
        Map<String, Object> dJson = new Map<String, Object>();
        dJson.put('sObjectName', 'Case');
        dJson.put('recordId', recordId);
        dJson.put('status','En curso');
        dJson.put('closingCode','No Aplica');
        dJson.put('substate','En diagnóstico');
        dJson.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        dJson.put('wheredata', wheredata);
        dJson.put('fieldsrequired',  'Status,PVU_Sub_Estado__c,PVU_Codigo_de_Cierre__c,PVU_Level3__c');
        
        input.put('datosjson', dJson);
        Test.startTest();     
        PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
        Boolean result = postUpdateMethod.invokeMethod('updateRecordDynamic', input, output, options);        
        Test.stopTest(); 
        System.assertEquals(result,true);
    }
    
    @isTest
    static void updateRecordDynamicTestSucces1(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();  
        List<Object> wheredata = new List<Object>();
        
        Case  caso =  [Select Id from Case limit 1];
        String recordId=caso.Id;
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        listData.put('name', 'Respuesta__c');
        listData.put('value', 'Rechazado');
        
        troubleTicketCharacteristic.add(listData);
        
        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Id');
        listWData.put('value', recordId);
        listWData.put('operater', 'AND');
        
        
        wheredata.add(listWData);
        
        Map<String, Object> dJson = new Map<String, Object>();
        dJson.put('sObjectName', 'Case');
        dJson.put('recordId', recordId);
        dJson.put('status','Cerrado');
        dJson.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        dJson.put('wheredata', wheredata);
        dJson.put('fieldsrequired',  'Status,PVU_Sub_Estado__c,PVU_Codigo_de_Cierre__c');
        
        input.put('datosjson', dJson);
        Test.startTest();     
        PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
        Boolean result = postUpdateMethod.invokeMethod('updateRecordDynamic', input, output, options);        
        Test.stopTest(); 
        System.assertEquals(result,true);
    }
    
    @isTest
    static void updateRecordDynamicTestSucces2(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();  
        List<Object> wheredata = new List<Object>();
        
        Case  caso =  [Select Id from Case limit 1];
        String recordId=caso.Id;
        
        Map<String, Object> listData = new Map<String, Object>();
        /*listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');*/
        listData.put('name', 'PVU_IdSolicitud__c');
        listData.put('value', '00001234');
        
        troubleTicketCharacteristic.add(listData);
        
        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Id');
        listWData.put('value', recordId);
        listWData.put('operater', 'OR');
        
        
        wheredata.add(listWData);
        
        Map<String, Object> dJson = new Map<String, Object>();
        dJson.put('sObjectName', 'Case');
        dJson.put('recordId', recordId);
        dJson.put('status','Cerrado');
        dJson.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        dJson.put('wheredata', wheredata);
        dJson.put('fieldsrequired',  'Status,PVU_Sub_Estado__c,PVU_Codigo_de_Cierre__c');
        
        input.put('datosjson', dJson);
        Test.startTest();     
        PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
        Boolean result = postUpdateMethod.invokeMethod('updateRecordDynamic', input, output, options);        
        Test.stopTest();     
        System.assertEquals(result,true);
    }
        
    @isTest
    static void updateRecordDynamicTestError(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();  
        List<Object> wheredata = new List<Object>();  
        
        Case  caso =  [Select Id from Case limit 1];
        String recordId=caso.Id;
        
        Map<String, Object> listData = new Map<String, Object>();
        listData.put('name', 'PVU_Fechasolicitud__c');
        listData.put('value', '2023-12-13 14:30:00');
        
        troubleTicketCharacteristic.add(listData);
        
        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Id');
        listWData.put('value', null);
        listWData.put('operater', '');        
        
        wheredata.add(listWData);
        
        Map<String, Object> dJson = new Map<String, Object>();
        dJson.put('sObjectName', '');
        dJson.put('recordId', null);
        dJson.put('status','Cerrado');
        dJson.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        dJson.put('wheredata', wheredata);
        
        input.put('datosjson', dJson);
        Test.startTest();     
        PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
        Boolean result = postUpdateMethod.invokeMethod('updateRecordDynamic', input, output, options);        
        Test.stopTest();  
		System.assertEquals(result,true);        
    }
        
    @isTest
    static void methodTestGetCase(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 
        List<Object> wheredata = new List<Object>(); 

        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Account.FVU_DocumentNumber__c');
        listWData.put('value', '123456');
        listWData.put('operater', 'AND');
		Map<String, Object> listWData2 = new Map<String, Object>();        
        listWData2.put('field', 'Account.FVU_DocumentType__c');
        listWData2.put('value', 'CC');
        listWData2.put('operater', 'AND');        
        wheredata.add(listWData);
        wheredata.add(listWData2);
        
        input.put('sObjectName','Case');
        input.put('fieldStandard', 'Id,CaseNumber,ContactId,AccountId,Status,PVU_Sub_Estado__c,ClosedDate,CreatedDate, IsEscalated,LastModifiedById,LastModifiedDate,Origin,OwnerId');
        input.put('customerVoice', 'Portabilidad Out');
        input.put('documentType', 'CC');
        input.put('documentNumber', '122140456');
        input.put('wheredata', wheredata);
        Test.startTest();     
            PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
            Boolean result = postUpdateMethod.invokeMethod('getCaseDynamic', input, output, options);        
        Test.stopTest();   
        System.assertEquals(result,true);
    }
    
    @isTest
    static void methodTestGetCase2(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 
        List<Object> wheredata = new List<Object>(); 

        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Account.FVU_DocumentNumber__c');
        listWData.put('value', '53145705');
        listWData.put('operater', 'AND');        
        Map<String, Object> listWData2 = new Map<String, Object>();        
        listWData2.put('field', 'Account.FVU_DocumentType__c');
        listWData2.put('value', 'CC');
        listWData2.put('operater', 'OR');        
        wheredata.add(listWData);
        wheredata.add(listWData2);
        
        input.put('sObjectName','Case');
        input.put('fieldStandard', 'Id,CaseNumber,ContactId,AccountId,Status,PVU_Sub_Estado__c,ClosedDate,CreatedDate, IsEscalated,LastModifiedById,LastModifiedDate,Origin,OwnerId');
        input.put('customerVoice', 'Portabilidad Out');
        input.put('documentType', 'CC');
        input.put('documentNumber', '122140456');
        input.put('wheredata', wheredata);
        Test.startTest();     
            PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
            Boolean result = postUpdateMethod.invokeMethod('getCaseDynamic', input, output, options);        
        Test.stopTest();   
        System.assertEquals(result,true);
    }
    
    @isTest
    static void methodTestGetCase3(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 
        List<Object> wheredata = new List<Object>(); 

        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'Account.FVU_DocumentNumber__c');
        listWData.put('value', '53145705');
        listWData.put('operater', 'AND');              
        wheredata.add(listWData);
        
        input.put('sObjectName','Case');
        input.put('fieldStandard', 'Id,CaseNumber,ContactId,AccountId,Status,PVU_Sub_Estado__c,ClosedDate,CreatedDate, IsEscalated,LastModifiedById,LastModifiedDate,Origin,OwnerId');
        input.put('documentType', 'CC');
        input.put('documentNumber', '122140456');
        input.put('wheredata', wheredata);
        Test.startTest();     
            PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
            Boolean result = postUpdateMethod.invokeMethod('getCaseDynamic', input, output, options);        
        Test.stopTest();
        System.assertEquals(result,true);
    }

    @isTest
    static void methodTestGetCaseCaseNumber(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 
        List<Object> wheredata = new List<Object>(); 

        Case cs = [SELECT Id, CaseNumber FROM Case LIMIT 1];

        Map<String, Object> listWData = new Map<String, Object>();
        listWData.put('field', 'CaseNumber');
        listWData.put('value', cs.CaseNumber);
        listWData.put('operater', '');              
        wheredata.add(listWData);
        
        input.put('sObjectName','Case');
        input.put('fieldStandard', 'Id,CaseNumber,ContactId,AccountId,Status,PVU_Sub_Estado__c,ClosedDate,CreatedDate, IsEscalated,LastModifiedById,LastModifiedDate,Origin,OwnerId');
        input.put('documentType', 'CC');
        input.put('documentNumber', '122140456');
        input.put('wheredata', wheredata);
        Test.startTest();     
            PVU_TMFCustomCase postUpdateMethod = new PVU_TMFCustomCase();
            Boolean result = postUpdateMethod.invokeMethod('getCaseDynamic', input, output, options);        
        Test.stopTest();
        System.assertEquals(result,true);
    }

    @isTest
    static void insertCaseTMFTest_MotivoAjuste_Invalid() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> troubleTicketCharacteristic = new List<Object>();

        Map<String, Object> channel = new Map<String, Object>();
        channel.put('name', 'Web');

        Map<String, Object> fechaMap = new Map<String, Object>();
        fechaMap.put('name', 'PVU_Fechasolicitud__c');
        fechaMap.put('value', '2023-12-13 14:30:00');
        Map<String, Object> idMap = new Map<String, Object>();
        idMap.put('name', 'PVU_IdSolicitud__c');
        idMap.put('value', '00001234');

        // Valor que NO existe en el picklist
        Map<String, Object> motivoMap = new Map<String, Object>();
        motivoMap.put('name', 'FIN_MotivoAjuste__c');
        motivoMap.put('value', 'ValorInexistente_Motivo');

        troubleTicketCharacteristic.add(fechaMap);
        troubleTicketCharacteristic.add(idMap);
        troubleTicketCharacteristic.add(motivoMap);

        input.put('type', CASE_RECORDTYPE_ID);
        input.put('channel', channel);
        input.put('troubleTicketCharacteristic', troubleTicketCharacteristic);
        input.put('customerVoice', 'Ajuste de Credito');
        input.put('documentType', 'CC');
        input.put('documentNumber', '53145705');
        input.put('subcategory', 'Financiación');
        input.put('category', 'Facturación y pagos');
        input.put('description', 'Creacion de caso ajuste de credito');
        input.put('status', 'En curso');
        input.put('subscriberNumber', '573012345678');
        input.put('financingCode', 'CRED0');
        input.put('billingAccountCode', '92000000000');
        input.put('serialNumber', 'DK5730123456');

        Test.startTest();
            PVU_TMFCustomCase instance = new PVU_TMFCustomCase();
            Boolean result = instance.invokeMethod('insertCaseTMF', input, output, options);
        Test.stopTest();

        System.assertEquals(true, result, 'La invocación debe devolver true aun cuando haya validación de negocio');
        System.assertEquals('409', output.get('code'), 'Debe retornar código 409 cuando el valor de Motivo no es válido');
        System.assertEquals(
            'El valor del campo “Motivo de Ajuste” no coincide con los valores permitidos por el sistema.Favor de verificar e intenta nuevamente.',
            output.get('message'),
            'Mensaje de error esperado para Motivo no válido'
        );
    }

    @isTest
    static void manageCaseByFinancingCode_NoQueue() {
        Map<String,Object> input = new Map<String,Object>{
            'type' => CASE_RECORDTYPE_ID,
            'channel' => new Map<String,Object>{'name'=>'Web'},
            'customerVoice' => 'Ajuste de Credito',
            'documentType' => 'CC',
            'documentNumber' => '53145705',
            'subcategory' => 'Financiación',
            'category' => 'Facturación y pagos',
            'description' => 'Test sin queue',
            'status' => 'New',
            'subscriberNumber' => '573012345678',
            'financingCode' => 'CRED_INVALIDO',
            'billingAccountCode' => '123',
            'serialNumber' => 'ABC'
        };
        Map<String,Object> output = new Map<String,Object>();
        Test.startTest();
        new PVU_TMFCustomCase().invokeMethod('insertCaseTMF', input, output, new Map<String,Object>());
        Test.stopTest();
        System.assertEquals('Failed', output.get('status'));
        System.assertEquals('409', output.get('code'));
    }
    
    @IsTest
    static void testGetQueueIdByName() {
        // Create a Queue (Group of type 'Queue')
        Group testQueue = new Group(
            Name = 'Test Queue',
            DeveloperName = 'TestQueueDevName',
            Type = 'Queue'
        );
        insert testQueue;

        Test.startTest();
        // Call the method under test
        Id queueId = PVU_TMFCustomCase.getQueueIdByName('TestQueueDevName');
        Test.stopTest();

        // Assert the result
        System.assertNotEquals(null, queueId, 'Queue Id should not be null');
        System.assertEquals(testQueue.Id, queueId, 'Returned Id should match the inserted Queue Id');
    }

    @IsTest
    static void testManageCaseByFinancingCode_Failed() {
        // Crear Queue para que no falle
        Group queue = [
        SELECT Id 
        FROM Group 
        WHERE DeveloperName = 'FIN_BackAjustesFinanciacion' 
        AND Type = 'Queue' 
        LIMIT 1
        ];

        // Obtener RecordType válido para Case
        Id caseRtId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Case'
            LIMIT 1
        ].Id;

        // Traer Account y setear RecordType Consumer
        Account acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account LIMIT 1];
        acc.RecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND Name = 'Consumer' 
            LIMIT 1
        ].Id;
        update acc;

        // Traer un Asset válido
        Asset a = [SELECT Id, FIN_NumeroDeCredito__c, PVU_IMEI__c 
               FROM Asset 
               WHERE FIN_NumeroDeCredito__c != '' AND PVU_IMEI__c != '' 
               LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'customerVoice' => 'Ajuste de Credito',
            'status' => 'En Curso',
            'description' => 'Test case',
            'category' => 'Facturación y pagos',
            'subcategory' => 'Financiación',
            'documentType' => acc.FVU_DocumentType__c,
            'documentNumber' => acc.FVU_DocumentNumber__c,
            'type' => caseRtId, // ✅ RecordTypeId real
            'subscriberNumber' => '3001234567',
            'financingCode' => a.FIN_NumeroDeCredito__c,
            'billingAccountCode' => 'ACC001',
            'serialNumber' => a.PVU_IMEI__c,
            'channel' => new Map<String,Object>{ 'name' => 'V360' }
        };

        Map<String, Object> output = new Map<String, Object>();
        Case cas = new Case();

        Test.startTest();
        PVU_TMFCustomCase.manageCaseByFinancingCode(cas, input, output);
        Test.stopTest();

        System.assertEquals('Failed', output.get('status'),
        'Case should be created Failed');
    }

    @IsTest
    static void testManageCaseByFinancingCode_AccountNotFound() {
        Map<String, Object> input = new Map<String, Object>{
            'customerVoice' => 'Other',
            'status' => 'New',
            'description' => 'Account not found test',
            'category' => 'Billing',
            'subcategory' => 'Financing',
            'priority' => 'Low',
            'documentType' => 'PP',
            'documentNumber' => '999999999',
            'type' => '012000000000001AAA',
            'subscriberNumber' => '3001234567',
            'financingCode' => 'CODE123',
            'billingAccountCode' => 'ACC003',
            'serialNumber' => 'SERIAL001',
            'channel' => new Map<String,Object>{ 'name' => 'Branch' }
        };

        Map<String, Object> output = new Map<String, Object>();
        Case cas = new Case();

        Test.startTest();
        PVU_TMFCustomCase.manageCaseByFinancingCode(cas, input, output);
        Test.stopTest();

        System.assertEquals('Failed', output.get('status'));
        System.assertEquals('Document number and document type not found', output.get('message'));
    }

    @IsTest
    static void testGetRequiredData_AllFieldsPresent() {
        String requiredFields = 'FIN_MotivoAjuste__c,PVU_Level3__c';

        // Simulamos JSON con todos los campos
        List<Map<String, Object>> fieldsJSON = new List<Map<String, Object>>();
        fieldsJSON.add(new Map<String, Object>{ 'name' => 'FIN_MotivoAjuste__c', 'value' => 'Test' });
        fieldsJSON.add(new Map<String, Object>{ 'name' => 'PVU_Level3__c', 'value' => 'Test' });

        Test.startTest();
        String missing = PVU_TMFCustomCase.getRequiredData(requiredFields, fieldsJSON);
        Test.stopTest();

        System.assertEquals('', missing,
            'It should not return missing fields when all are present.');
    }

    @IsTest
    static void testManageCaseBySubscriberNumber_Success() {
        Account acc = new Account(Name = 'Test Account', FVU_DocumentNumber__c = '12345', FVU_DocumentType__c = 'CC');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        acc.vlocity_cmt__PrimaryContactId__c = con.Id;
        update acc;

        Product2 planProduct = new Product2(
            Name = 'Test Plan Product',
            Family = 'Mobile',
            vlocity_cmt__Type__c = 'Plan',
            vlocity_cmt__SpecificationSubType__c = 'Simple',
            IsActive = true
        );
        insert planProduct;

        vlocity_cmt__Subscription__c sub = new vlocity_cmt__Subscription__c(
            Name = 'Sub Test',
            OM_MSISDN__c = '3001234567',
            vlocity_cmt__SubscriptionNumber__c = 'SUB-001' 
        );
        insert sub;

        Asset planAsset = new Asset(
            Name = 'Plan Asset Test',
            AccountId = acc.Id,
            Product2Id = planProduct.Id,
            vlocity_cmt__SubscriptionId__c = sub.Id,
            Status = 'Active'
        );
        insert planAsset;

        Id caseRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1].Id;

        Map<String, Object> inputMap = new Map<String, Object>{
            'customerVoice' => 'Ajuste de Credito',
            'status' => 'En Curso',
            'description' => 'Test Case',
            'category' => 'Facturación',
            'subcategory' => 'Financiación',
            'priority' => 'Medium',
            'type' => caseRtId,
            'subscriberNumber' => '3001234567',
            'channel' => new Map<String, Object>{ 'name' => 'V360' }
        };

        Map<String, Object> outMap = new Map<String, Object>();
        Case cas = new Case();

        Test.startTest();
        PVU_TMFCustomCase.manageCaseBySubscriberNumber(cas, inputMap, outMap);
        Test.stopTest();

        System.assertEquals('Failed', outMap.get('status'),
            'Debe haberse creado el Case failed');
    }

    // HU 811299 - Tests de resolveOwnerId (asignación centralizada de owner).

    @isTest
    static void resolveOwnerIdCanalDigitalTest() {
        // Canal digital => usuario de integración (contexto de ejecución = usuario actual).
        Map<String,Object> channel = new Map<String,Object>{ 'name' => 'SuperApp' };
        Test.startTest();
        Id owner = PVU_TMFCustomCase.resolveOwnerId(channel, 'Cualquier voz', UserInfo.getUserId(), false);
        Test.stopTest();
        System.assertEquals(UserInfo.getUserId(), owner,
            'Canal digital debe asignar el usuario de integración (contexto de ejecución)');
    }

    @isTest
    static void resolveOwnerIdOwnerActivoTest() {
        // No digital + owner activo => Account.OwnerId (el usuario actual está activo).
        Map<String,Object> channel = new Map<String,Object>{ 'name' => 'Web' };
        Test.startTest();
        Id owner = PVU_TMFCustomCase.resolveOwnerId(channel, 'Otra voz', UserInfo.getUserId(), false);
        Test.stopTest();
        System.assertEquals(UserInfo.getUserId(), owner,
            'Owner de cuenta activo debe conservarse como owner del caso');
    }

    @isTest
    static void resolveOwnerIdPortabilidadOutOwnerInactivoTest() {
        // No digital + owner inactivo + voz 'Portabilidad Out' => cola PVU_MesaPortout (si existe).
        Map<String,Object> channel = new Map<String,Object>{ 'name' => 'App' };
        Id inactiveOwner = getInactiveUserIdOrNull();
        Test.startTest();
        Id owner = PVU_TMFCustomCase.resolveOwnerId(channel, 'Portabilidad Out', inactiveOwner, false);
        Test.stopTest();
        // Con owner inactivo (o nulo) y voz Portabilidad Out, no debe quedar como el owner inactivo.
        System.assertNotEquals(inactiveOwner, owner,
            'Portabilidad Out con owner inactivo no debe dejar el owner inactivo');
    }

    @isTest
    static void resolveOwnerIdOtraVozOwnerInactivoTest() {
        // No digital + owner inactivo + otra voz => usuario que crea el caso.
        Map<String,Object> channel = new Map<String,Object>{ 'name' => 'App' };
        Id inactiveOwner = getInactiveUserIdOrNull();
        Test.startTest();
        Id owner = PVU_TMFCustomCase.resolveOwnerId(channel, 'Otra voz', inactiveOwner, false);
        Test.stopTest();
        System.assertEquals(UserInfo.getUserId(), owner,
            'Owner inactivo con otra voz debe asignar el usuario que crea el caso');
    }

    @isTest
    static void resolveOwnerIdFinanciacionTest() {
        // No digital + financiación => cola FIN_BackAjustesFinanciacion (o null si no existe la cola).
        Map<String,Object> channel = new Map<String,Object>{ 'name' => 'Web' };
        Test.startTest();
        Id owner = PVU_TMFCustomCase.resolveOwnerId(channel, 'Ajuste de Credito', UserInfo.getUserId(), true);
        Test.stopTest();
        // Si la cola existe, owner es un Group (Queue); si no, es null. En ambos casos no es el Account owner.
        System.assertNotEquals(UserInfo.getUserId(), owner,
            'Escenario financiación no debe asignar el owner de la cuenta');
    }

    // Helper: devuelve el Id de un usuario inactivo si existe, o null.
    private static Id getInactiveUserIdOrNull() {
        List<User> inactivos = [SELECT Id FROM User WHERE IsActive = false LIMIT 1];
        return inactivos.isEmpty() ? null : inactivos[0].Id;
    }

}