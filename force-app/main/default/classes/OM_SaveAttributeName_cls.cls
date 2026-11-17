/**
 * Clase encargada de buscar coincidencias en otro mapa de referencia, asignando el valor correspondiente a un objeto de características de producto.
 * --------------------------------------------------------------------------
 *                         Date           Author                      Description
 * ---------------------------------------------------------------------------
 * @version 1.1           02/04/2025     Karen Sanchez (karsanchez)   HDU 538800 - Se requiere asignar el nombre del atributo en el nodo description_offer
 **/
public with sharing class OM_SaveAttributeName_cls {
    private static final String PRODUCT_CHARACTERISTICS_KEY = 'cls_productCharacteristics';
    private static final String DESCRIPTION_OFFER_KEY = 'description_offer';
        
    /**
    * @description Método para asignar el nombre del atributo basado en la coincidencia entre mapas
    * @author karsanchez | 04-02-2025 
    * @param cfsCharac 
    * @param attrCodeValueMap 
    * @param mapAttNamesAndCodes 
    * @param orderItemPProductCharacInstance 
    **/
    public static void createAttName(String cfsCharac, Map<String, Map<String, Object>> attrCodeValueMap, 
                                Map<String, String> mapAttNamesAndCodes, 
                                EricsonRequestJSON.cls_productCharacteristics orderItemPProductCharacInstance) {
        orderItemPProductCharacInstance.name = cfsCharac;
        Map<String, Object> productCharacteristics = getMapValue(attrCodeValueMap, PRODUCT_CHARACTERISTICS_KEY);
        String descriptionOffer = (String)getValue(productCharacteristics, DESCRIPTION_OFFER_KEY);
        String matchedValue = mapAttNamesAndCodes.get(descriptionOffer);
        if (String.isNotBlank(matchedValue)) {
            orderItemPProductCharacInstance.value = matchedValue;
        } 
    }

    /**
     * Método auxiliar para obtener un submapa de manera segura
     * @author karsanchez | 04-02-2025 
     * @param parentMap El mapa padre que contiene submapas
     * @param key La clave para buscar en el mapa padre
     * @return El submapa correspondiente a la clave o null si no existe
     */
     @TestVisible
    private static Map<String, Object> getMapValue(Map<String, Map<String, Object>> parentMap, String key) {
        if (parentMap == null || !parentMap.containsKey(key)) {
            return null;
        }
        return parentMap.get(key);
    }

    /**
     * Método auxiliar para obtener un valor de un mapa de manera segura
     * @author karsanchez | 04-02-2025 
     * @param sourceMap El mapa fuente
     * @param key La clave para buscar en el mapa
     * @return El valor correspondiente a la clave o null si no existe
     */
     @TestVisible
    private static Object getValue(Map<String, Object> sourceMap, String key) {
        if (sourceMap == null || !sourceMap.containsKey(key)) {
            return null;
        }
        return sourceMap.get(key);
    }
}