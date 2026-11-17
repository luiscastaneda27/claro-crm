/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : Nilyan Berti
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   02-12-2024   SALESFORCE   Initial Version
**/
@isTest
public with sharing class PVU_AssetAttributesJsonTest {
   
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
        Map<String, Object> attSelect = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'getBloqueos';
        //input.put('methodName', methodName);
        String Json = '{"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-WEB-MESS":true}';        
        attSelect.put('AttributesSelected',Json);

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        input.put('DatosAtributos', attSelect);

        
            //PVU_AssetAttributesJson attrJson = new PVU_AssetAttributesJson();
            Test.startTest();
            Test.stopTest();
            Boolean t = PVU_AssetAttributesJson.invokeMethod(methodName,input,output,options);
            System.assertEquals(true, t, 'Debe retornar un valor verdadero');        
        

    }

    @isTest
static void testGetBloqueos(){
        Map<String, Object> attSelect = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'getBloqueos';
        //input.put('methodName', methodName);
        String Json = '{"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-WEB-MESS":true}';        
        attSelect.put('AttributesSelected',Json);

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        input.put('DatosAtributos', attSelect);

        
            //PVU_AssetAttributesJson attrJson = new PVU_AssetAttributesJson();
            Test.startTest();
            Test.stopTest();
            PVU_AssetAttributesJson.invokeMethod(methodName,input,output,options);
            System.assertNotEquals(null, output.get('activos'), 'La lista de códigos no debería ser nula');        
        

    }
}