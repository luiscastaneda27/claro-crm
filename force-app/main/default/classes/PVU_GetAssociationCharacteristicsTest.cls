/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 09-09-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   04-29-2025   SALESFORCE   Initial Version
**/


@isTest
private class PVU_GetAssociationCharacteristicsTest {

    private static final Id CASE_RECORDTYPE_ID = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('GestionCasosPosventa').getRecordTypeId();

    @testSetup
    static void setupData() {
        Date testDate = Date.newInstance(2025, 9, 9);
        PVU_TMFFieldsInsertCase__mdt mdt = PVU_TMFFieldsInsertCase__mdt.getInstance('AssociationCharacteristics');
        
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

        // Crea un caso relacionado (u otro objeto) con datos de prueba si es necesario
        Case cs = new Case();
        cs.Status = 'En curso';
        cs.PVU_Sub_Estado__c='En diagnóstico';
        cs.RecordTypeId= CASE_RECORDTYPE_ID;
        cs.AccountId = acc.Id;
        cs.PVU_IdSolicitud__c = '123456';
        cs.Subject = 'Test Case';
    
        insert cs;

        //Creamos los campos relacionados
        PVU_Relacion_de_servicios_y_equipos__c se = new PVU_Relacion_de_servicios_y_equipos__c();
        //se.Name = 'ABC'; 
        se.PVU_Concepto_devolucion__c = 'Test1'; 
        se.PVU_No_Nota_Credito__c = '123';
        se.PVU_No_Tratamiento_de_Nota_Credito__c = '123'; 
        se.PVU_Serial_o_Imei__c = '123';
        se.PVU_Valor_devolucion__c = 1213123;
        se.PVU_caso_relacionado__c = cs.Id;
        se.PVU_CuotaInicial__c = 123000;
        se.PVU_ExternalAccountId__c = '920009191000';
        insert se;

        PVU_Relacion_de_servicios_y_equipos__c se2 = new PVU_Relacion_de_servicios_y_equipos__c();
        //se2.Name = 'ABC'; 
        se2.PVU_Concepto_devolucion__c = 'Test1'; 
        se2.PVU_No_Nota_Credito__c = '123A';
        se2.PVU_No_Tratamiento_de_Nota_Credito__c = '123'; 
        se2.PVU_Serial_o_Imei__c = '123';
        se2.PVU_Valor_devolucion__c = 1213123;
        se2.PVU_caso_relacionado__c = cs.Id;
        se.PVU_CuotaInicial__c = 123000;
        se.PVU_ExternalAccountId__c = '920009191000';
        insert se2;

    }

    @isTest
    static void testInvokeMethod_Success() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'sObjectName' => 'PVU_Relacion_de_servicios_y_equipos__c',
            'fieldStandard' => 'Id',
            'customerVoice' => 'AssociationCharacteristics',
            'documentType' => 'CC',
            'documentNumber' => '53145705',
            'status' => 'En curso',
            'wheredata' => new List<Object>{
                new Map<String,Object>{
                    'field' => 'PVU_caso_relacionado__r.Status',
                    'value' => 'En curso',
                    'operater' => 'AND'
                }
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        PVU_GetAssociationCharacteristics instance = new PVU_GetAssociationCharacteristics();
        Boolean result = instance.invokeMethod('getAssocCharsDynamic', inputMap, outMap, options);
        Test.stopTest();
        
        System.debug(outMap.get('status'));
        Assert.istrue(result, 'Expected method to return true');
        Assert.areEqual('Success', outMap.get('status'), 'Expected successful status');
        Assert.areEqual('200', outMap.get('code'), 'Expected HTTP 200 code');
        Assert.istrue(outMap.containsKey('responsesData'), 'Expected response data to be present');
    }

    @isTest
    static void testInvokeMethod_MissingCustomerVoice() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'sObjectName' => 'PVU_Relacion_de_servicios_y_equipos__c',
            'fieldStandard' => 'Id',
            'documentType' => 'CC',
            'documentNumber' => '53145705',
            'status' => 'En curso',
            'wheredata' => new List<Object>{
                new Map<String,Object>{
                    'field' => 'PVU_caso_relacionado__r.Status',
                    'value' => 'En curso',
                    'operater' => 'AND'
                }
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        PVU_GetAssociationCharacteristics instance = new PVU_GetAssociationCharacteristics();
        Boolean result = instance.invokeMethod('getAssocCharsDynamic', inputMap, outMap, options);
        Test.stopTest();

        Assert.istrue(result, 'Expected method to return true even if it fails internally');
        Assert.areEqual('Failed', outMap.get('status'), 'Expected failure status due to missing customerVoice');
        Assert.areEqual('400', outMap.get('code'), 'Expected HTTP 400 code');
    }
}