/**
 * @description       : Clase unitaria de la clase OM_CatalogoTecnico_cls
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : Salesforce
 * @last modified on  : 11-09-2024
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            Coverage: 95%
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           07/NOV/2024     Karen Sanchez   HDU 417597
 *
**/
@isTest
public with sharing class OM_CatalogoTecnico_tst {
    /**
    * @description: Método de configuración de datos de prueba para 'OM_CatalogoTecnico_tst'.
    * Inserta un 'Product2' de clase y un 'Product2' adicional, y crea una relación de descomposición ('DecompositionRelationship') entre ambos.
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 11-09-2024 
    **/
    @testSetup
    static void setupTestData() {
        Product2 objProductClass = OrderMgtTestDataFactory.oTEspecBasedeProductosClass();
        insert objProductClass;

        Product2 objProduct = OrderMgtTestDataFactory.objProduct('Offer','Mobile','Add On','OTT','Simple','PO_MovPosOptOTTDisneyPrm',objProductClass.Id);
        insert objProduct;

        vlocity_cmt__DecompositionRelationship__c objDescRel = OrderMgtTestDataFactory.objDecompositionRelationship(objProductClass.Id);
        insert objDescRel;
    }

    /**
    * @description: Prueba 'convertToProductMapList' con una lista de objetos para verificar que el método maneje correctamente 'List<Object>' y produzca la salida esperada.
    * La prueba verifica que se transformen los productos y que el 'outMap' contenga los productos procesados.
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 11-09-2024 
    **/
    @isTest
    static void testConvertToProductMapListWithListOfObjects() {
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> objectProducts = new List<Object>();

        Id ParenClassId = [SELECT Id FROM Product2 WHERE ProductCode = 'B2C-CLASS-PAQ-ADC-OTT'].Id;
    
        Map<String, Object> product1 = new Map<String, Object>{
            'ProductCode' => 'PO_MovPosOptOTTDisneyPrm',
            'vlocity_cmt__SubType__c' => 'OTT',
            'vlocity_cmt__ParentClassId__c' => ParenClassId
        };
        Map<String, Object> product2 = new Map<String, Object>{
            'ProductCode' => 'PO_MovPosOptPaqUcpm50Min',
            'vlocity_cmt__SubType__c' => 'LDI',
            'vlocity_cmt__ParentClassId__c' => ParenClassId
        };
        objectProducts.add(product1);
        objectProducts.add(product2);

        Map<String, Object> inputMap = new Map<String, Object>{
            'Productos' => objectProducts
        };
        
        OM_CatalogoTecnico_cls catalogoTecnico = new OM_CatalogoTecnico_cls();
        
        Test.startTest();
            catalogoTecnico.invokeMethod('getProducts', inputMap, outMap, options);
        Test.stopTest();
        System.assert(outMap.containsKey('Productos'), 'El mapa de salida debe contener la clave "Productos".');
        System.assertEquals(2, ((List<Object>) outMap.get('Productos')).size(), 'Debe haber 2 productos en la lista de salida.');
    }
    
    /**
    * @description: Prueba el método 'call' de 'OM_CatalogoTecnico_cls' invocando 'getProducts'. Verifica que el método retorne 'true' cuando se ejecuta sin errores.
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 11-09-2024 
    **/
    @isTest
    static void testCallMethodWithInvoke() {
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Id ParenClassId = [SELECT Id FROM Product2 WHERE ProductCode = 'B2C-CLASS-PAQ-ADC-OTT'].Id;
        Map<String, Object> inputMap = new Map<String, Object>{
            'Productos' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'ProductCode' => 'PO_MovPosOptOTTDisneyPrm',
                    'vlocity_cmt__SubType__c' => 'OTT',
                    'vlocity_cmt__ParentClassId__c' => ParenClassId
                }
            }
        };
        OM_CatalogoTecnico_cls catalogo = new OM_CatalogoTecnico_cls();
        Object result = catalogo.call('getProducts', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => options
        });
       System.assertEquals(true, result, 'Se ejecutó correctamente');
    }
}