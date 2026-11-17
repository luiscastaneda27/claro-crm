/**
 * @description       : Esta clase extrae y asigna atributos a productos en función de los datos configurados en vlocity_cmt__MappingsData__c dentro de 
 * DecompositionRelationship. Utiliza configuraciones definidas en Custom Metadata (ProductMappingCharacteristics__mdt) que especifican el nombre del atributo a 
 * extraer, el subtipo de productos a procesar, la variable en la que se almacenará el valor y el tipo de nodo JSON (ya sea estático o lista). Esto permite aplicar 
 * reglas de mapeo específicas para cada producto, basándose en sus características y simplificando la lógica de extracción y asignación de datos en productos relacionados. 
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : Salesforce
 * @last modified on  : 11-09-2024
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           07/NOV/2024     Karen Sanchez   HDU 417597
 *
**/
global with sharing class OM_CatalogoTecnico_cls implements vlocity_cmt.VlocityOpenInterface, Callable {
    
	global Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String procedureName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            getProducts(inputMap, outputMap, options);
        } catch (Exception e) {
            System.debug('invokeMethod -> exception: ' + e + 'LineError '+ e.getLineNumber());
            result = false;
        }
        return result;
    }

    /**
    * @description:Procesa una lista de productos a partir de los datos de entrada y genera un mapeo basado en relaciones de descomposición y metadata personalizada.
    * @author karsanchez | 11-09-2024 
    * @param inputMap Mapa de entrada que contiene los datos necesarios, incluyendo la lista de productos bajo la clave 'Productos'.
    * @param outMap Mapa de salida en el cual se almacenan los productos procesados con los nodos mapeados.
    *               En caso de error, este mapa contendrá una clave 'error' con un mensaje descriptivo.
    * @param options Mapa de opciones adicionales que puede contener configuraciones para el procesamiento (actualmente no se usa en este método).
    */
    public static void getProducts(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            // Paso 1: Recuperar Custom Metadata para hacer el mapeo
            Map<String, ProductMappingCharacteristics__mdt> metadataMap = loadCustomMetadata();
            
            // Paso 2: Recuperar los productos desde inputMap y verificar el tipo
            Object productosValue = inputMap.get('Productos');
            List<Map<String, Object>> mapProducts = convertToProductMapList(productosValue);
            
            // Obtener en un set todos los parentClassId para buscarlos dentro de los DecompositionRelationship
            Set<Id> setParentClassId = extractParentClassIds(mapProducts);

            // Paso 3: Ejecutar la consulta para obtener las relaciones de descomposición
            List<vlocity_cmt__DecompositionRelationship__c> decompositionRecords = fetchDecompositionRecords(setParentClassId);

            // Paso 4: Procesar las relaciones de descomposición y mapear nuevos nodos a los productos correspondientes
            processProducts(mapProducts, decompositionRecords, metadataMap, outMap);
        } catch (Exception e) {
            outMap.put('ERROR: ', 'Ha ocurrido un error al procesar los productos: ' + e.getMessage() + 'LineError '+ e.getLineNumber());
        }
    }
    
    /**
    * @description:Carga y devuelve un mapa de registros de Custom Metadata de tipo ProductMappingCharacteristics__mdt.Realiza una consulta sobre la metadata de tipo ProductMappingCharacteristics__mdt
    * y mapea cada registro en un mapa usando el campo 'MasterLabel' como clave.
    * @author karsanchez | 11-09-2024 
    * @return Un mapa donde las claves son los valores de 'MasterLabel' y los valores son 
    *         los registros correspondientes de ProductMappingCharacteristics__mdt.
    */
    public static Map<String, ProductMappingCharacteristics__mdt> loadCustomMetadata() {
        List<ProductMappingCharacteristics__mdt> customMetadataList = [
            SELECT MasterLabel, DeveloperName, MappingType__c, AtributoBuscar__c, GuardarValor__c, TipoProducto__c 
            FROM ProductMappingCharacteristics__mdt
        ];
        Map<String, ProductMappingCharacteristics__mdt> metadataMap = new Map<String, ProductMappingCharacteristics__mdt>();
        for (ProductMappingCharacteristics__mdt cm : customMetadataList) {
            metadataMap.put(cm.MasterLabel, cm);
        }
        return metadataMap;
    }
    
    /**
    * @description: Convierte el objeto 'productosValue' en una Lista de Mapas, si es posible.
    * @author karsanchez | 11-09-2024 
    * @param productosValue. productosValue El objeto de entrada que se espera que sea una Lista de Mapas o una Lista de Objetos que contienen Mapas. 
    * @return List<Map<String, Object>>. Una Lista de Mapas que contiene los detalles de los productos, o una lista vacía si la conversión falla. 
    **/
    public static List<Map<String, Object>> convertToProductMapList(Object productosValue) {
        List<Map<String, Object>> mapProducts = new List<Map<String, Object>>();
        
        // Verificar si productosValue es una lista de mapas
        if (productosValue instanceof List<Map<String, Object>>) {
            mapProducts = (List<Map<String, Object>>) productosValue;
        } 
        // Verificar si productosValue es una lista de objetos
        else if (productosValue instanceof List<Object>) {
            List<Object> objectProducts = (List<Object>) productosValue;
            // Recorrer cada elemento en la lista y agregarlo a mapProducts si es un mapa
            for (Object item : objectProducts) {
                if (item instanceof Map<String, Object>) {
                    mapProducts.add((Map<String, Object>) item);
                }
            }
        } 
        return mapProducts;
    }

    /**
    * @description Extrae los valores de 'vlocity_cmt__ParentClassId__c' de una lista de productos y los agrega a un conjunto (Set) de IDs, eliminando duplicados.
    * @author karsanchez | 11-09-2024 
    * @param mapProducts Lista de mapas que representan los productos. Cada mapa debe contener el campo 'vlocity_cmt__ParentClassId__c' como clave.
    * @return Un conjunto (Set) de IDs, que contiene los valores únicos de 'vlocity_cmt__ParentClassId__c' encontrados en los productos de la lista. Solo se incluyen IDs no vacíos.
    */
    public static Set<Id> extractParentClassIds(List<Map<String, Object>> mapProducts) {
        Set<Id> setParentClassId = new Set<Id>();
        for (Map<String, Object> product : mapProducts) {
            String parentClassId = (String) product.get('vlocity_cmt__ParentClassId__c');
            if (String.isNotBlank(parentClassId)) {
                setParentClassId.add(parentClassId);
            }
        }
        return setParentClassId;
    }

    /**
    * @description Realiza una consulta para obtener registros de vlocity_cmt__DecompositionRelationship__c basándose en un conjunto de IDs de productos fuente.
    * @author karsanchez | 11-09-2024 
    * @param setParentClassId Conjunto (Set) de IDs de productos fuente (vlocity_cmt__SourceProductId__c) 
    *                         para los cuales se desean obtener las relaciones de descomposición.
    * @return  List<vlocity_cmt__DecompositionRelationship__c>  Una lista de registros de vlocity_cmt__DecompositionRelationship__c que contienen
    *         los detalles de descomposición de productos, filtrados por los IDs proporcionados en setParentClassId.
    */
    public static List<vlocity_cmt__DecompositionRelationship__c> fetchDecompositionRecords(Set<Id> setParentClassId) {
        return [
            SELECT vlocity_cmt__sourceproductid__c, Id, 
                vlocity_cmt__SourceProductId__r.Name, vlocity_cmt__DestinationProductId__r.Name,
                vlocity_cmt__DestinationProductId__c, vlocity_cmt__MappingsData__c
            FROM vlocity_cmt__DecompositionRelationship__c
            WHERE vlocity_cmt__SourceProductId__c IN :setParentClassId
        ];
    }

    /**
    * Procesa una lista de productos y mapea valores utilizando relaciones de descomposición y metadatos de características de productos.
    * @author karsanchez | 11-09-2024 
    * @param mapProducts Lista de productos, donde cada producto es un mapa con sus propiedades.
    * @param decompositionRecords Lista de registros de descomposición que contienen datos de mapeo.
    * @param metadataMap Mapa de metadatos de características de productos.
    * @param outMap Mapa de salida donde se almacenarán los productos procesados.
    */
    public static void processProducts(List<Map<String, Object>> mapProducts, List<vlocity_cmt__DecompositionRelationship__c> decompositionRecords, Map<String, ProductMappingCharacteristics__mdt> metadataMap, Map<String, Object> outMap) {
        for (vlocity_cmt__DecompositionRelationship__c record : decompositionRecords) {
            List<Object> mappingsDataListRaw = (List<Object>) JSON.deserializeUntyped(record.vlocity_cmt__MappingsData__c);
            for (Map<String, Object> product : mapProducts) {
                processProductMappings(product, mappingsDataListRaw, metadataMap);
            }
        }
        outMap.put('Productos', mapProducts);
    }

    /**
    * Procesa y aplica los mapeos correspondientes para un producto específico, usando los datos de mapeo y el mapa de metadatos.
    * @author karsanchez | 11-09-2024 
    * @param product Mapa que representa un producto y contiene sus atributos.
    * @param mappingsDataListRaw Lista de datos de mapeo deserializados sin tipificar.
    * @param metadataMap Mapa de metadatos de características de productos.
    */
    private static void processProductMappings(Map<String, Object> product, List<Object> mappingsDataListRaw, Map<String, ProductMappingCharacteristics__mdt> metadataMap) {
        String productSubType = (String) product.get('vlocity_cmt__SubType__c');
        String productCode = (String) product.get('ProductCode');
        
        for (Object item : mappingsDataListRaw) {
            Map<String, Object> mapping = (Map<String, Object>) item;
            String mappingType = (String) mapping.get('mapping_type');
            if ('list'.equals(mappingType)) {
                processListMappings(product, mapping, metadataMap, productSubType, productCode);
            } else if ('static'.equals(mappingType)) {
                processStaticMappings(product, mapping, metadataMap, productSubType);
            }
        }
    }

    /**
    * Procesa mapeos de tipo "list" y aplica los valores correspondientes al producto según el código y el subtipo.
    * @author karsanchez | 11-09-2024 
    * @param product Mapa que representa un producto y contiene sus atributos.
    * @param mapping Mapa que contiene los datos de mapeo.
    * @param metadataMap Mapa de metadatos de características de productos.
    * @param productSubType Tipo de producto en el producto.
    * @param productCode Código del producto en el producto.
    */
    private static void processListMappings(Map<String, Object> product, Map<String, Object> mapping, Map<String, ProductMappingCharacteristics__mdt> metadataMap, String productSubType, String productCode) {
        List<Object> transformMappingsList = (List<Object>) mapping.get('transform_mappings');
        
        if (transformMappingsList != null) {
            for (Object transformMappingObj : transformMappingsList) {
                Map<String, Object> transformMapping = (Map<String, Object>) transformMappingObj;
                String sourceValue = (String) transformMapping.get('source_value');
                String destinationValue = (String) transformMapping.get('destination_value');
                // Verifica si el mapeo coincide con el tipo de producto, código y atributos
                for (ProductMappingCharacteristics__mdt metadata : metadataMap.values()) {
                    String destinationAttrCode = (String) mapping.get('destination_attr_code');
                    if (metadata.TipoProducto__c.equals(productSubType) &&
                        metadata.AtributoBuscar__c.equals(destinationAttrCode) &&
                        metadata.MappingType__c.equals('list') &&
                        sourceValue.equals(productCode)) {
                        product.put(metadata.GuardarValor__c, destinationValue);
                    }
                }
            }
        }
    }
    
    /**
    * Procesa mapeos de tipo "static" y aplica los valores correspondientes al producto según el subtipo y los atributos.
    * @author karsanchez | 11-09-2024 
    * @param product Mapa que representa un producto y contiene sus atributos.
    * @param mapping Mapa que contiene los datos de mapeo.
    * @param metadataMap Mapa de metadatos de características de productos.
    * @param productSubType Tipo de producto en el producto.
    */
    private static void processStaticMappings(Map<String, Object> product, Map<String, Object> mapping, Map<String, ProductMappingCharacteristics__mdt> metadataMap, String productSubType) {
        String destinationAttrCode = (String) mapping.get('destination_attr_code');
        
        for (ProductMappingCharacteristics__mdt metadata : metadataMap.values()) {
            // Verifica si el mapeo es de tipo "static" y si coincide con el tipo de producto y el atributo
            if (metadata.TipoProducto__c.equals(productSubType) &&
                metadata.AtributoBuscar__c.equals(destinationAttrCode) &&
                metadata.MappingType__c.equals('static')) {
                product.put(metadata.GuardarValor__c, mapping.get('value'));
            }
        }
    }
}