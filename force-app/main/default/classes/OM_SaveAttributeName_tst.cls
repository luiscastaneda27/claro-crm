/**
 * This class contains unit tests for validating the behavior of the
 * CustomStringFunction Apex class.
 *
 * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *                      Date           Author                      Description                    Coverage 100%
 * -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 * @version 1.1      01/04/2025     Karen Sanchez (karsanchez)   HDU 538800 - Prueba unitaria de la clase OM_SaveAttributeName_cls
 **/
@isTest
public with sharing class OM_SaveAttributeName_tst {
    private static Map<String, String> mapAttNamesAndCodes;
    
    /**
     * @description Método auxiliar para inicializar datos comunes para todos los tests
     */
    private static void setupTestData() {
        // Inicializar mapAttNamesAndCodes que es común en todos los tests
        mapAttNamesAndCodes = new Map<String, String>{
            'B2C-ATTR-FAM-Y-AMIGOS' => 'Familia y Amigos',
            'B2C-ATTR-SA-CLR-DRIVE' => 'Claro Drive',
            'B2C-ATTR-SA-CLR-MUSICA-GR' => 'Claro música gratis',
            'B2C-ATTR-SA-CLR-MUSICA-PREM' => 'Claro música premium',
            'B2C-ATTR-SA-CLR-VIDEO' => 'Claro video'
        };
    }
    
    /**
     * @description Test cuando description_offer coincide con una clave en el mapa
     */
    @isTest
    static void testCreateAttName_WithMatchingDescription() {
        setupTestData();
        String cfsCharac = 'description_offer';
        Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> productCharacteristics = new Map<String, Object>{
            'description_offer' => 'B2C-ATTR-SA-CLR-MUSICA-GR'
        };
        attrCodeValueMap.put('cls_productCharacteristics', productCharacteristics);
        EricsonRequestJSON.cls_productCharacteristics orderItemPProductCharacInstance = new EricsonRequestJSON.cls_productCharacteristics();
        Test.startTest();
            OM_SaveAttributeName_cls.createAttName(cfsCharac, attrCodeValueMap, mapAttNamesAndCodes, orderItemPProductCharacInstance);
        Test.stopTest();
        System.assertEquals(cfsCharac, orderItemPProductCharacInstance.name, 'El nombre debe establecerse con el valor de cfsCharac');
        System.assertEquals('Claro música gratis', orderItemPProductCharacInstance.value, 'El valor debe establecerse con el valor coincidente de mapAttNamesAndCodes');
    }

     /**
     * @description Test del método auxiliar getMapValue
     */
    @isTest
    static void testGetMapValue() {
        Map<String, Map<String, Object>> parentMap = new Map<String, Map<String, Object>>();
        Map<String, Object> childMap = new Map<String, Object>{'key' => 'value'};
        parentMap.put('childMap', childMap);
        // Probar con clave existente
        Map<String, Object> result = (Map<String, Object>)OM_SaveAttributeName_cls.getMapValue(parentMap, 'childMap');
        System.assertEquals(childMap, result, 'Debe devolver el submapa para una clave existente');
        // Probar con clave no existente
        result = (Map<String, Object>)OM_SaveAttributeName_cls.getMapValue(parentMap, 'nonExistingKey');
        System.assertEquals(null, result, 'Debe devolver null para una clave no existente');
        // Probar con mapa padre null
        result = (Map<String, Object>)OM_SaveAttributeName_cls.getMapValue(null, 'anyKey');
        System.assertEquals(null, result, 'Debe devolver null cuando el mapa padre es null');
    }

    /**
     * @description Test del método auxiliar getValue
     */
    @isTest
    static void testGetValue() {
        // Configuración de datos de prueba
        Map<String, Object> sourceMap = new Map<String, Object>{'key' => 'value'};
        // Probar con clave existente
        Object result = OM_SaveAttributeName_cls.getValue(sourceMap, 'key');
        System.assertEquals('value', result, 'Debe devolver el valor para una clave existente');
        // Probar con clave no existente
        result = OM_SaveAttributeName_cls.getValue(sourceMap, 'nonExistingKey');
        System.assertEquals(null, result, 'Debe devolver null para una clave no existente');
        // Probar con mapa fuente null
        result = OM_SaveAttributeName_cls.getValue(null, 'anyKey');
        System.assertEquals(null, result, 'Debe devolver null cuando el mapa fuente es null');
    }
}