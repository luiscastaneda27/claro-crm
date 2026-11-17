/**
 * @description       : Esta clase extrae los atributos que se tienen en el custom metadata OM_getAttributeByJSONAttribute__mdt del campo obtenido de la query vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__JSONAttribute__c
 * del objeto vlocity_cmt__InventoryItemDecompositionRelationship__c y la respuesta será remplazada del json attribute para retornarlo al IP que lo esta invocando
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : Salesforce
 * @last modified on  : 01-15-2025
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           08/ENE/2025     Karen Sanchez   HDU 425302 - Se requieren visualizar los items y caracteristicas en la pestaña activo de inventario
 *
**/
global with sharing class OM_GetAttributesByItems_cls implements vlocity_cmt.VlocityOpenInterface, Callable {
    
	/**
	* @description: Método requerido para que se pueda invocar esta clase desde un IP 
	* @author karsanchez | 01-13-2025 
	* @param action 
	* @param args 
	* @return Object 
	**/
	global Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    /**
	* @description: Método requerido para que se pueda invocar esta clase desde un IP 
    * @author karsanchez | 01-13-2025 
    * @param procedureName 
    * @param inputMap 
    * @param outputMap 
    * @param options 
    * @return Boolean 
    **/
    global Boolean invokeMethod(String procedureName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            getAttributes(inputMap, outputMap, options);
        } catch (Exception e) {
            System.debug('invokeMethod -> exception: ' + e + 'LineError '+ e.getLineNumber());
            result = false;
        }
        return result;
    }
    
     /**
    * @description Método principal que procesa los atributos y genera un mapa de resultados.
    * @author karsanchez | 01-13-2025 
    * @param inputMap Mapa de entrada que contiene los datos de entrada para procesar.
    * @param outMap Mapa de salida que almacenará los resultados procesados.
    * @param options Opciones adicionales enviadas desde el IP
    **/
    global static void getAttributes(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            Id idDI = (Id) inputMap.get('Id');

            // Obtener el JSON desde la base de datos
            vlocity_cmt__InventoryItemDecompositionRelationship__c jsonAttribute = getJsonAttribute(idDI);
            String jsonString = jsonAttribute.vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__JSONAttribute__c;

            // Parsear el JSON y obtener los metadatos
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            List<OM_getAttributeByJSONAttribute__mdt> metadatos = getMetadata();

            // Procesar los datos
            List<Map<String, String>> lstItemResult = processJsonData(jsonMap, metadatos);

            // Colocar el resultado final en el mapa de salida
            outMap.put('outMap', lstItemResult);
        } catch (Exception e) {
            outMap.put('outMap', 'Ha ocurrido un error: ' + e.getMessage() + ' - LineError: '+ e.getLineNumber());
        }
    }

    /**
    * @description Recupera el atributo JSON de la base de datos para un ID específico.
    * @author karsanchez | 01-13-2025 
    * @param idDI ID del registro de descomposición de inventario.
    * @return vlocity_cmt__InventoryItemDecompositionRelationship__c Registro con el atributo JSON.
    **/
    private static vlocity_cmt__InventoryItemDecompositionRelationship__c getJsonAttribute(Id idDI) {
        vlocity_cmt__InventoryItemDecompositionRelationship__c result = [
            SELECT vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__JSONAttribute__c
            FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
            WHERE id = :idDI LIMIT 1
        ];
        return result;
    }

    /**
    * @description Recupera los metadatos necesarios para procesar el JSON.
    * @author karsanchez | 01-13-2025 
    * @return List<OM_getAttributeByJSONAttribute__mdt> Lista de registros de metadatos con las claves de campos.
    **/
    private static List<OM_getAttributeByJSONAttribute__mdt> getMetadata() {
        return [SELECT OM_FieldKey__c FROM OM_getAttributeByJSONAttribute__mdt];
    }

    /**
    * @description Procesa los datos del JSON, extrae los items y los mapea según los metadatos.
    * @author karsanchez | 01-13-2025 
    * @param jsonMap Mapa deserializado del JSON.
    * @param metadatos Lista de metadatos con las claves de campos a buscar en el JSON.
    * @return List<Map<String, String>> Lista con los resultados procesados, donde cada mapa contiene un campo y su valor.
    **/
    private static List<Map<String, String>> processJsonData(Map<String, Object> jsonMap, List<OM_getAttributeByJSONAttribute__mdt> metadatos) {
        List<Map<String, String>> lstItemResult = new List<Map<String, String>>();

        for (String key : jsonMap.keySet()) {
            List<Map<String, Object>> items = extractItems(jsonMap.get(key));
            for (Map<String, Object> item : items) {
                Map<String, String> itemResult = extractItemData(item, metadatos);
                if (!itemResult.isEmpty()) {
                    lstItemResult.add(itemResult);
                }
            }
        }
        return lstItemResult;
    }

     /**
    * @description Extrae los items de un valor que puede ser una lista o un mapa.
    * @author karsanchez | 01-13-2025 
    * @param value Valor asociado a una clave del JSON, que puede ser una lista o un mapa.
    * @return List<Map<String, Object>> Lista de mapas con los items extraídos.
    **/
    private static List<Map<String, Object>> extractItems(Object value) {
        List<Map<String, Object>> items = new List<Map<String, Object>>();

        if (value instanceof List<Object>) {
            for (Object listItem : (List<Object>) value) {
                if (listItem instanceof Map<String, Object>) {
                    items.add((Map<String, Object>) listItem);
                }
            }
        } else if (value instanceof Map<String, Object>) {
            items.add((Map<String, Object>) value);
        }
        return items;
    }

    /**
    * @description Extrae los datos de un item usando los metadatos proporcionados.
    * @author karsanchez | 01-13-2025 
    * @param item Mapa de datos del item que contiene claves y valores.
    * @param metadatos Lista de metadatos con las claves de campos que deben ser extraídas del item.
    * @return Map<String, String> Mapa con las claves extraídas y sus valores asociados.
    **/
    private static Map<String, String> extractItemData(Map<String, Object> item, List<OM_getAttributeByJSONAttribute__mdt> metadatos) {
        Map<String, String> itemResult = new Map<String, String>();

        for (OM_getAttributeByJSONAttribute__mdt atributo : metadatos) {
            String fieldKey = atributo.OM_FieldKey__c;
            if (item.containsKey(fieldKey)) {
                itemResult.put(fieldKey, String.valueOf(item.get(fieldKey)));
            }
        }
        return itemResult;
    }
}