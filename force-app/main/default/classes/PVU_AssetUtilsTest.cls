/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 02-18-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   08-29-2024   SALESFORCE   Initial Version
 * 2.0   02-18-2025   SALESFORCE   Ajustes para mostrar información de producto pasaporte america. 
**/
@isTest
public with sharing class PVU_AssetUtilsTest {
   
    @TestSetup
    static void setup(){

        //test data de asset's
        List<Asset> assets = new List<Asset>();
        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert acc;
        /*******************************/
        
        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset';
        ast.AccountId = acc.Id;
        ast.vlocity_cmt__AttributeSelectedValues__c='{"B2C-ATTR-MSISDN":"573100003941"}';
        ast.vlocity_cmt__RootItemId__c='123456789';
        assets.add(ast);
        
        Asset ast2 = new Asset();
        ast2.Name = 'SIM Card';
        ast2.AccountId = acc.Id;
        ast2.vlocity_cmt__AttributeSelectedValues__c='{"B2C-ATTR-ICCID":null,"B2C-ATTR-IMSI":"123456789000","B2C-ATTR-TECN-SIM":null}';
        ast2.vlocity_cmt__RootItemId__c='123456789';
        assets.add(ast2);
        
        // Pruebas de Roaming
        Product2 prod = new Product2();
        prod.Name = 'Roaming product';
        prod.vlocity_cmt__Type__c = 'Add On';
        prod.vlocity_cmt__SubType__c = 'Roaming Internacional';
        prod.ProductCode = 'PO_MovPosOptPaqRoamConvC';
        insert prod;
        
        Asset ast3 = new Asset();
        ast3.Name = 'Roaming Plan 1';
        ast3.status = 'Active';
        ast3.AccountId = acc.Id;
        ast3.Product2id = prod.Id;
        ast3.vlocity_cmt__ReliesOnItemId__c = '7aa13c41-c327-36a4-0ce7-0c3a0a228412';
        ast3.vlocity_cmt__AttributeSelectedValues__c='{"B2C-ATTR-ICCID":null,"B2C-ATTR-IMSI":"123456789000","B2C-ATTR-TECN-SIM":null}';
        ast3.vlocity_cmt__RootItemId__c='123456789';
        ast3.fvu_recurringtotalinctaxes__c = 2000;
        assets.add(ast3);
        
        Asset ast4 = new Asset();
        ast4.Name = 'Roaming Plan 2';
        ast4.AccountId = acc.Id;
        ast4.Product2id = prod.Id;
        ast4.status = 'Active';
        ast4.vlocity_cmt__ReliesOnItemId__c = '7aa13c41-c327-36a4-0ce7-0c3a0a228412';
        ast4.vlocity_cmt__AttributeSelectedValues__c='{"B2C-ATTR-ICCID":null,"B2C-ATTR-IMSI":"123456789000","B2C-ATTR-TECN-SIM":null}';
        ast4.vlocity_cmt__RootItemId__c='123456789';
        ast4.FVU_EffectiveOneTimeTotalIncTaxes__c = 1000;
        assets.add(ast4);
        
        insert assets;
        
      
}

@isTest
static void testGetImsi(){
        Map<String, Object> attSelect = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'getIMSI';
        

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        input.put('minValue', '573100003941');

        
            //PVU_AssetAttributesJson attrJson = new PVU_AssetAttributesJson();
            Test.startTest();
            
            PVU_AssetUtils.invokeMethod(methodName,input,output,options);
            Test.stopTest();
            system.debug('imsi>>>>>'+output.get('imsi'));
            System.assertNotEquals(null, output.get('imsi'), 'el imsi no debe ser null');        
      

    }

    
    @isTest
    static void testgetRoamingServices(){
        Map<String, Object> attSelect = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String methodName = 'getRoamingServices';
        

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        input.put('assetReferenceId', '7aa13c41-c327-36a4-0ce7-0c3a0a228412');

        Test.startTest();
        PVU_AssetUtils.invokeMethod(methodName,input,output,options);
        Test.stopTest();
        //System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');

    }
}