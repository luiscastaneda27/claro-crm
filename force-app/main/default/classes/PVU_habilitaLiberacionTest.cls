/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 03-08-2024
 * @last modified by  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   03-08-2024   SALESFORCE   Initial Version
**/
@isTest
public with sharing class PVU_habilitaLiberacionTest {
    @TestSetup
    static void setup(){
        User userTest = tlc_testDataFactory.anUser()
        .withProfile('System Administrator', 'Administrador del sistema')
        .withfistname('Claro')
        .withLastName('TestUser')
        .isActive(true)
        .withTimeZoneSidKey('America/New_York')
        .withEmailEncodingKey('UTF-8')
        .withLocaleSidKey('en_US')
        .withLanguageLocaleKey('en_US')
        .build();
        insert userTest;
        
        PermissionSetGroup userPSG = [SELECT Id, DeveloperName from PermissionSetGroup WHERE DeveloperName = 'Claro_EPC_Administrador'];
        System.Test.calculatePermissionSetGroup(userPSG.Id);
        
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
        permissionSetAssignment.PermissionSetGroupId  = userPSG.id;
        permissionSetAssignment.AssigneeId = userTest.Id;
        insert permissionSetAssignment;

        System.runAs(userTest){       
            Account acc = new Account();
            acc.Name = 'Test AccLiberacion';
            acc.FVU_DocumentType__c = 'CC';
            acc.FVU_DocumentNumber__c = '1234';
            insert acc;
    
            Asset ast = new Asset();
            ast.Name = 'Test Asset';
            ast.AccountId = acc.Id;
            ast.FVU_IMEI2__c = '571234';
            ast.PVU_IMEI__c = '571234';
            insert(ast);
    
            Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '', Family = 'Device');
            insert prod1;
            
            // Create Price Book Entries     
            Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry pbe1 = new PricebookEntry();
            pbe1.Pricebook2Id = pricebookId;
            pbe1.Product2Id = prod1.Id;
            pbe1.UnitPrice = 1;
            pbe1.IsActive = true;
            insert pbe1;     
            
            Order orden1 = new Order();
            orden1.Status = 'Draft';
            orden1.EffectiveDate = System.Today();
            orden1.AccountId = acc.Id;
            orden1.Pricebook2Id = pricebookId;
            insert orden1;
                    
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = orden1.Id;
            orderItem1.Product2Id = prod1.Id;
            orderItem1.PricebookEntryId = pbe1.Id;
            orderItem1.Quantity = 1;
            orderItem1.UnitPrice = 10;
            orderItem1.vlocity_cmt__LineNumber__c = '0001';
            orderItem1.vlocity_cmt__Action__c = 'Add';
            orderItem1.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem1.vlocity_cmt__ServiceAccountId__c = acc.Id;
            orderItem1.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem1.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
            orderItem1.FVU_IMEI__c = '571234567890';
            insert orderItem1;
    
            Order ordernew = [Select id from Order where id =: orden1.Id];
            ordernew.Status = 'Activated';
            update(ordernew);        
            //Agregamos los atributos
            vlocity_cmt__AttributeCategory__c attCat = new vlocity_cmt__AttributeCategory__c();
            attCat.vlocity_cmt__ApplicableSubType__c = 'Product Attribute';
            attCat.vlocity_cmt__ApplicableTypes__c = 'Product2';
            attCat.vlocity_cmt__Code__c = 'B2C-ATTR-FYB';
            attCat.vlocity_cmt__DisplaySequence__c = 1;
            insert(attCat);
    
            List<vlocity_cmt__Attribute__c> listAtt = new List<vlocity_cmt__Attribute__c>();
            vlocity_cmt__Attribute__c att = new vlocity_cmt__Attribute__c();
            att.vlocity_cmt__AttributeCategoryId__c = attCat.Id;
            att.vlocity_cmt__Code__c = 'B2C-ATTR-FYB-VID-LLAM';
            att.vlocity_cmt__DisplaySequence__c = 1;
            att.Name = 'Test Att 1';     
    
            listAtt.add(att);
            vlocity_cmt__Attribute__c att2 = new vlocity_cmt__Attribute__c();
            att2.vlocity_cmt__Code__c = 'B2C-ATTR-FYB-BLQ-GPRS';
            att2.Name = 'Test Att 2'; 
            att2.vlocity_cmt__AttributeCategoryId__c = attCat.Id;
            att2.vlocity_cmt__DisplaySequence__c = 1;
            listAtt.add(att2);
            insert listAtt;        
        }
	}

    @isTest
    static void testInvoke(){
        List<Object> attSelect = new  List<Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'liberacionImeiAccount';
        String imei = '571234';
        String minInput = '571234';
        Account cuenta = [SELECT Id FROM Account][0];
        List<Object> listaDeReportes = new List<Object>();
        // Crear instancias de ReportsList y agregarlas a la lista
        PVU_habilitaLiberacion.ReportsList reporte1 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A NO';
        reporte1.tipoReporte = '7';
        listaDeReportes.add(reporte1);
        
        input.put('accountId', cuenta.Id);
        input.put('reportsList', listaDeReportes);
        input.put('imei', imei);
        input.put('minInput', minInput);
        
        
            Test.startTest();
            Boolean t = PVU_habilitaLiberacion.invokeMethod(methodName,input,output,options);
            Test.stopTest();            
            System.assertEquals(true, t, 'Debe retornar un valor verdadero');        
               
    }
    
    @isTest
    static void testBotonReinicidenteError(){
        List<Object> attSelect = new  List<Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'liberacionImeiAccount';
        String imei = '571234567890';
        String minInput = '571234';
        Account cuenta = [SELECT Id FROM Account][0];
        List<Object> listaDeReportes = new List<Object>();
        // Crear instancias de ReportsList y agregarlas a la lista
        PVU_habilitaLiberacion.ReportsList reporte1 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A';
        reporte1.tipoReporte = '7';
        listaDeReportes.add(reporte1);
        
        input.put('accountId', cuenta.Id);
        input.put('reportsList', listaDeReportes);
        input.put('imei', imei);
        input.put('minInput', minInput);
        
        
            Test.startTest();
            Boolean t = PVU_habilitaLiberacion.invokeMethod(methodName,input,output,options);
            Test.stopTest();            
            System.assertEquals(true, t, 'Debe retornar un valor verdadero');        
               
    }
    
    @isTest
    static void testInvokeRoboPerdidaError(){
        List<Object> attSelect = new  List<Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'liberacionImeiAccount';
        String imei = '571234';
        String minInput = '571234';
        Account cuenta = [SELECT Id FROM Account][0];
        List<Object> listaDeReportes = new List<Object>();
        // Crear instancias de ReportsList y agregarlas a la lista
        PVU_habilitaLiberacion.ReportsList reporte1 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A';
        reporte1.tipoReporte = '1';
        listaDeReportes.add(reporte1);
        PVU_habilitaLiberacion.ReportsList reporte2 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A';
        reporte1.tipoReporte = '1';
        listaDeReportes.add(reporte2);
        
        input.put('accountId', cuenta.Id);
        input.put('reportsList', listaDeReportes);
        input.put('imei', imei);
        input.put('minInput', minInput);
        
        
            Test.startTest();
            Boolean t = PVU_habilitaLiberacion.invokeMethod(methodName,input,output,options);
            Test.stopTest();            
            System.assertEquals(true, t, 'Debe retornar un valor verdadero');        
               
    }

    @isTest
    static void TesthabilitaBotonRoboPerdida(){
        Map<String,Boolean> respuestas = new Map<String,Boolean>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        String methodName = 'liberacionImeiAccount';
        String imei = '571234';
        String minInput = '571234';
        String minCuenta = '571234567890';
        List<Object> listaDeReportes = new List<Object>();
        // Crear instancias de ReportsList y agregarlas a la lista
        PVU_habilitaLiberacion.ReportsList reporte1 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A';
        reporte1.tipoReporte = '1';
        listaDeReportes.add(reporte1);

        PVU_habilitaLiberacion.ReportsList reporte2 = new PVU_habilitaLiberacion.ReportsList();
        reporte2.fechaReporte = '2024-03-08';
        reporte2.msisdn = '5712348989567890';
        reporte2.operador = 'Comcel S.A';
        reporte2.tipoReporte = '1';
        listaDeReportes.add(reporte2);
        
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('reportsList', listaDeReportes);
        input.put('imei', imei);
        input.put('minInput', minInput);
        
        
            Test.startTest();
            PVU_habilitaLiberacion.habilitaBotonRoboPerdida(minCuenta,listaDeReportes,respuestas);
            Test.stopTest();
            System.assertNotEquals(null, respuestas, 'Las variables de salida no deberían ser nulas');        
        
        
    }
    
    @isTest
    static void TesthabilitaBotonReinicidente(){
        List<Object> attSelect = new  List<Object>();
        Map<String,Boolean> respuestas = new Map<String,Boolean>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        String methodName = 'liberacionImeiAccount';
        String imei = '571234';
        String minInput = '571234';
        String minCuenta = '3113680563';
        //input.put('methodName', methodName);
        List<Object> listaDeReportes = new List<Object>();
        // Crear instancias de ReportsList y agregarlas a la lista
        PVU_habilitaLiberacion.ReportsList reporte1 = new PVU_habilitaLiberacion.ReportsList();
        reporte1.fechaReporte = '2024-03-08';
        reporte1.msisdn = '571234567890';
        reporte1.operador = 'Comcel S.A';
        reporte1.tipoReporte = '7';
        listaDeReportes.add(reporte1);
        
        
        
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('reportsList', attSelect);
        
        input.put('imei', imei);
        input.put('minInput', minInput);
        
        
            Test.startTest();
            PVU_habilitaLiberacion.habilitaBotonReinicidente(cuenta.Id, imei,listaDeReportes,respuestas);
            Test.stopTest();
            System.assertNotEquals(null, respuestas, 'Las variables de salida no deberían ser nulas');        
        
        
    }
}