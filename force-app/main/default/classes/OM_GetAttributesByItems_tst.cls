/**
 * @description       : Clase unitaria de la clase OM_GetAttributesByItems_cls
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : Salesforce
 * @last modified on  : 01-13-2025
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            Coverage: 92%    
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           08/ENE/2025     Karen Sanchez   HDU 425302 - Se requieren visualizar los items y caracteristicas en la pestaña activo de inventario
 *
**/
@isTest
public class OM_GetAttributesByItems_tst {

    @TestSetup
    static void makeData() {
        vlocity_cmt__InventoryItem__c objInventoryItem = new vlocity_cmt__InventoryItem__c(
            vlocity_cmt__JSONAttribute__c = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"Name":"TechATRfamily","SegmentValue":"Mobile"}]}'
        );
        insert objInventoryItem;

        vlocity_cmt__InventoryItemDecompositionRelationship__c record = new vlocity_cmt__InventoryItemDecompositionRelationship__c(
            vlocity_cmt__DestinationInventoryItemId__c = objInventoryItem.Id
            
        );
        insert record;
    }

    /**
    * @description Prueba el método principal de getAttributes para asegurar que los resultados sean procesados correctamente.
    * @author karsanchez| 01-13-2025 
    **/
    @isTest
    public static void testGetAttributes() {
        Id idIIDR = [SELECT Id FROM vlocity_cmt__InventoryItemDecompositionRelationship__c LIMIT 1].Id;

        Map<String, Object> inputMap = new Map<String, Object>{
            'Id' => idIIDR
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); // Si tienes opciones adicionales

        Test.startTest();
        OM_GetAttributesByItems_cls.getAttributes(inputMap, outMap, options);
        Test.stopTest();

        List<Map<String, String>> resultList = (List<Map<String, String>>) outMap.get('outMap');
        System.debug('resultList:'+resultList);
        System.assertEquals(resultList.size()>0, true, 'Se obtuvieron correctamente las caracteristicas de los atributos');

    }

    /**
    * @description Verifica el manejo de errores en el método getAttributes cuando el campo Id no está presente en el inputMap.
    * @author karsanchez| 01-13-2025 
    **/
    @isTest
    public static void testGetAttributesWithMissingId() {
        Map<String, Object> inputMap = new Map<String, Object>();  // No se incluye el "Id"
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        OM_GetAttributesByItems_cls.getAttributes(inputMap, outMap, options);
        Test.stopTest();
        String result = String.valueOf(outMap.get('outMap'));
        System.assertEquals(result.contains('Ha ocurrido un error'), true, 'La salida debe estar vacía cuando falta el "Id"');
    }

    /**
    * @description: Prueba el método 'call' de 'OM_GetAttributesByItems_cls' invocando 'getAttributes'. Verifica que el método retorne 'true' cuando se ejecuta sin errores.
    * @author karsanchez| 11-09-2024 
    **/
    @isTest
    static void testCallMethodWithInvoke() {
        Id idIIDR = [SELECT Id FROM vlocity_cmt__InventoryItemDecompositionRelationship__c LIMIT 1].Id;

        Map<String, Object> inputMap = new Map<String, Object>{
            'Id' => idIIDR
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); // Si tienes opciones adicionales

        OM_GetAttributesByItems_cls atts = new OM_GetAttributesByItems_cls();
        Object result = atts.call('getAttributes', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => options
        });
       System.assertEquals(true, result, 'Se ejecutó correctamente');
    }
}