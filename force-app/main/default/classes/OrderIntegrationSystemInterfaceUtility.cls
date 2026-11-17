/**----------------------------------------------------------------------------------------------------------------------------------------------
Author:         Mamata - 05-09-23
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date MM-dd-YY>   @version     <Author>             <Description>
2023-09-05         1.0.0   		Mamata          	Initial
2025-10-01         2.1          Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
2025-11-11         2.2          Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
--------------------------------------------------------------------------------------------------------------------------------------------------*/

global with sharing class OrderIntegrationSystemInterfaceUtility {
    
    //public static Map<String, Map<String, Object>> defaultValueByClassName;
    
    public static Map<String,Map<String, Map<String, Object>>> defaultValueByClassName;
    
    public static  Map<String,Map<String, Map<String, String>>> sourceAndTargetAttrByClassName;
    
    public static  Map<String,Map<String,Set<String>>> sourceKeyClassMap;
    
    public static Map<String, Map<String, List<String>>> cfsSpecByProduct;
    
    public static Map<String, Map<String, List<String>>> characteristicByCfsSpec;
    
    public static Map<String, String> topLevelProductByFamily;
    
    public static Map<String, Map<String, String>> defaultValueByClassNameWoAction;
    
    public static Map<String, List<OMEricsonChargeTypeSpec__mdt>> priceMappingByTechnicalProduct;
    
    public static Map<String, String> ericsonActionByActionSubActionSubType;
    
    public static Map<String, OMEricsonResourceSpecificationNodeMappin__mdt> ericsonResourceSpecByNodes;
    
    public static Map<String, String> tipoByCodingo;

    public static Map<String, Map<String, Object>> excepciones;
    
    public static Map<String, Map<String, Object>> technicalDetails;
    
    
    public static void getOMEricsonMappings(){
        sourceAndTargetAttrByClassName = new Map<String,Map<String, Map<String, String>>>();
        defaultValueByClassName = new Map<String,Map<String, Map<String, Object>>>();
        
        sourceKeyClassMap = new Map<String,Map<String,Set<String>>>();
        defaultValueByClassNameWoAction = new Map<String, Map<String, String>>();
        for(OMEricsonMapping__mdt key : OMEricsonMapping__mdt.getAll().values()){
            System.debug('====key======='+key);
            if(String.isNotBlank(key.Action__c)){
                for(String actionStr : (key.Action__c).split(';')){
                    if(!sourceAndTargetAttrByClassName.containsKey(actionStr)){
                        sourceAndTargetAttrByClassName.put(actionStr, new Map<String, Map<String, String>>() );
                        sourceKeyClassMap.put(actionStr, new Map<String, Set<String>>() );
                    }
                    if(!sourceAndTargetAttrByClassName.get(actionStr).containsKey(key.ClassName__c)){
                        sourceAndTargetAttrByClassName.get(actionStr).put(key.ClassName__c, new Map<String, String>() );
                    }
                    
                    if(key.IsDefault__c ){
                        if(!defaultValueByClassName.containsKey(actionStr)){
                            defaultValueByClassName.put(actionStr, new Map<String, Map<String, Object>>() );
                        }
                        if(!defaultValueByClassName.get(actionStr).containskey(key.ClassName__c)){
                            defaultValueByClassName.get(actionStr).put(key.ClassName__c, new Map<String, Object>()); 
                        }
                        if(key.DataType__c.equalsIgnoreCase('boolean')){
                            defaultValueByClassName.get(actionStr).get(key.ClassName__c).put(key.TargetAttribute__c, Boolean.valueOf(key.DefaultValue__c)); 
                        }else if(key.DataType__c.equalsIgnoreCase('string')){
                            defaultValueByClassName.get(actionStr).get(key.ClassName__c).put(key.TargetAttribute__c, key.DefaultValue__c); 
                        }
                        
                        System.debug('====OM Mappings======'+defaultValueByClassName);
                        System.debug('====OM Mappings======'+key.DeveloperName);
                    }else if(String.isNotBlank(key.SourceAttribute__c) && String.isNotBlank(key.TargetAttribute__c)){
                        sourceAndTargetAttrByClassName.get(actionStr).get(key.ClassName__c).put(key.SourceAttribute__c, key.TargetAttribute__c);
                        if(!sourceKeyClassMap.get(actionStr).containskey(key.SourceAttribute__c)) sourceKeyClassMap.get(actionStr).put(key.SourceAttribute__c, new Set<String>()); // key2 : source Column from MDT
                		sourceKeyClassMap.get(actionStr).get(key.SourceAttribute__c).add(key.ClassName__c);//retrieve source column and associate it with respective className, sourceKeyClassMap<SourceKey, {c1', 'c2', 'c3'}>
            
                    }
                }
            }
            
            if(key.IsDefault__c){
                if(!defaultValueByClassNameWoAction.containskey(key.ClassName__c)){
                    defaultValueByClassNameWoAction.put(key.ClassName__c, new Map<String, String>()); 
                }   
                defaultValueByClassNameWoAction.get(key.ClassName__c).put(key.TargetAttribute__c, key.DefaultValue__c);
            }
        }
    }
    
    public static void getOMEricsonProductToCFSSpec (){
        
        cfsSpecByProduct = new Map<String, Map<String, List<String>>>();
        
        for(OMEricsonProductToCFSSpec__mdt key : OMEricsonProductToCFSSpec__mdt.getAll().values()){
            
            if(!cfsSpecByProduct.containsKey(key.Type__c)){
                cfsSpecByProduct.put(key.Type__c , new Map<String, List<String>>());
            }
            if(!cfsSpecByProduct.get(key.Type__c).containskey(key.TechnicalProduct__c)){
                cfsSpecByProduct.get(key.Type__c).put(key.TechnicalProduct__c, new List<String>());
            }
            
            cfsSpecByProduct.get(key.Type__c).get(key.TechnicalProduct__c).add(key.CFSSpecification__c);
        }
        System.debug('=====cfsSpecByProduct===='+cfsSpecByProduct);
        
    }
    
    public static void getOMEricsonCFSspecToCharacteristics  (){
        
        characteristicByCfsSpec = new Map<String, Map<String, List<String>>>();
        
        for(OMEricsonCFSspecToCharacteristics__mdt key : OMEricsonCFSspecToCharacteristics__mdt.getAll().values()){
            
            if(!characteristicByCfsSpec.containsKey(key.Type__c)){
                characteristicByCfsSpec.put(key.Type__c , new Map<String, List<String>>());
            }
            if(!characteristicByCfsSpec.get(key.Type__c).containskey(key.CFSSpecification__c)){
                characteristicByCfsSpec.get(key.Type__c).put(key.CFSSpecification__c, new List<String>());
            }
            
            characteristicByCfsSpec.get(key.Type__c).get(key.CFSSpecification__c).add(key.Characteristics__c);
        }
        System.debug('=====characteristicByCfsSpec===='+characteristicByCfsSpec);
        
    }
    
    public static void getOMEricsonTopLevelProductSpec (){
        topLevelProductByFamily = new Map<String, String>();
        
        for(OMEricsonTopLevelProductSpec__mdt key : OMEricsonTopLevelProductSpec__mdt.getAll().values()){
            
            if(!topLevelProductByFamily.containsKey(key.ProductFamily__c) && String.isNotBlank(key.TechnicalProductName__c)){
                topLevelProductByFamily.put(key.ProductFamily__c, key.TechnicalProductName__c);
            }
        }
    }
    
    public static void getOMOMEricsonChargeTypeSpec(){
        priceMappingByTechnicalProduct = new Map<String, List<OMEricsonChargeTypeSpec__mdt>>();
        for(OMEricsonChargeTypeSpec__mdt key : OMEricsonChargeTypeSpec__mdt.getAll().values()){
            if(!priceMappingByTechnicalProduct.containsKey(key.TechnicalProduct__c) && String.isNotBlank(key.TechnicalProduct__c))
            	priceMappingByTechnicalProduct.put(key.TechnicalProduct__c, new List<OMEricsonChargeTypeSpec__mdt>());
            
            priceMappingByTechnicalProduct.get(key.TechnicalProduct__c).add(key);
        }
    }
    
    public static void getOMEricsonActionDerivation(){
        ericsonActionByActionSubActionSubType = new Map<String, String>();
        for(OMEricsonActionDerivation__mdt key : OMEricsonActionDerivation__mdt.getAll().values()){
            ericsonActionByActionSubActionSubType.put(key.Action__c +key.SubAction__c +key.ProductSubType__c , key.EricsonAction__c);
        }
    }
    
    public static void getOMEricsonResourceSpecNodesMap(){
        ericsonResourceSpecByNodes = new Map<String, OMEricsonResourceSpecificationNodeMappin__mdt>();
        for(OMEricsonResourceSpecificationNodeMappin__mdt key : OMEricsonResourceSpecificationNodeMappin__mdt.getAll().values()){
            ericsonResourceSpecByNodes.put(key.DeveloperName , key);
        }
    }
    
    public static void getOMEricsonTipoCodingoMap(){
        tipoByCodingo = new Map<String, String>();
        for(DocumentType__mdt key : DocumentType__mdt.getAll().values()){
            tipoByCodingo.put(key.Type__c, key.Code__c);
        }
    }
    
    /**
     * Extracts the attributes that differ between two JSON Attributes Strings using Code field to match and SegmentValue field to compare. Expected JSON structure:
     * { 
     *   "GlobalIdentifier": [ 
     *     { "Field1":"ValueA", "Field2":"ValueB", ...}, 
     *     { "Field1":"ValueX", "Field2":"ValueY", ...}, 
     *     ...
     *   ]
     * }  
     * @param attributesJSON1 First JSON String with an array of attributes
     * @param attributesJSON2 Second JSON String with an array of attributes
     * @return JSON with an array of attributes that differ with the Ericson attribute name. 
     *         Empty array if there are no differences. 
     *         Every attribute has the old and new value.
     *  */ 
    public static String extractDiferringAttributes(String attributesJSON1, String attributesJSON2){//changed upercase of method name beginning from E => e : Mamata

        try {
            String keyField = OrderIntegrationSystemInterfaceConstants.CODE;
            String valueField = OrderIntegrationSystemInterfaceConstants.SEG_VALUE;
            Map<String, Object> mapDifferingAttrs = new Map<String, Object>();
            Map<String, Object> mapAttributes1 = (Map<String, Object>)JSON.deserializeUntyped(attributesJSON1);
            Map<String, Object> mapAttributes2 = (Map<String, Object>)JSON.deserializeUntyped(attributesJSON2); 
            if(mapAttributes1 != null && mapAttributes2 != null && !mapAttributes1.values().IsEmpty() && !mapAttributes2.values().IsEmpty()){
                Map<String, Object> mapAttr1, mapAttr2;
                Map<String, String> mapAttr1Value = new Map<String, String>();
                Map<String, String> mapAttr2Value = new Map<String, String>();
                List<Object> lstAttributes1 =  (List<Object>)mapAttributes1.values()[0];
                List<Object> lstAttributes2 =  (List<Object>)mapAttributes2.values()[0];
                
                // Build attribute mapping between SF and Ericson
                Map<String, String> mapEricsonAttrs = new Map<String, String>();
                Map<String, OMEricsonMapping__mdt> mapEricsonMapping = OMEricsonMapping__mdt.getAll();
                for(OMEricsonMapping__mdt mdtEricson: mapEricsonMapping.values()){
                    mapEricsonAttrs.put(mdtEricson.SourceAttribute__c, mdtEricson.TargetAttribute__c);
                }

                // Indexation of attributes in JSON 2
                for(Object objAttr2: lstAttributes2){
                    mapAttr2 = (Map<String, Object>)objAttr2;
                    mapAttr2Value.put((String)mapAttr2.get(keyField), (String)mapAttr2.get(valueField));
                }
        		System.debug('==========mapAttr2Value==========='+mapAttr2Value);
                // Differences identification between common attributes - also identifies missing attribute in JSON 2
                for(Object objAttr1: lstAttributes1){
                    System.debug('==========objAttr1==========='+objAttr1);
                    mapAttr1 = (Map<String,Object>)objAttr1;
                    System.debug('==========mapAttr1==========='+mapAttr1);
                    System.debug('==========(String)mapAttr1.get(keyField)==========='+(String)mapAttr1.get(keyField));
                    System.debug('==========(String)mapAttr1.get(valueField)==========='+(String)mapAttr1.get(valueField));
                    mapAttr1Value.put((String)mapAttr1.get(keyField), (String)mapAttr1.get(valueField));
                    if(mapAttr1.get(valueField) != mapAttr2Value.get((String)mapAttr1.get(keyField))){
                        mapDifferingAttrs.put(mapEricsonAttrs.get((String)mapAttr1.get(keyField)), new List<Object>{(String)mapAttr1.get(valueField), mapAttr2Value.get((String)mapAttr1.get(keyField))});
                    }
                }
        		System.debug('==========mapDifferingAttrs==========='+mapDifferingAttrs);
                // Identifies missing attributes in JSON 1
                for(String keyAttr2: mapAttr2Value.keySet()){
                    if(!mapAttr1Value.containsKey(keyAttr2)){
                        mapDifferingAttrs.put(keyAttr2, new List<Object>{null, mapAttr2Value.get(keyAttr2)});
                    }
                }
            }
            System.debug('==========mapDifferingAttrs==========='+JSON.serialize(mapDifferingAttrs));
            return JSON.serialize(mapDifferingAttrs);

        } catch (Exception ex) {
            return null;
        }
    }

    /**
     * Updates the value of the valueField identified using the keyField for a List of JSON Attributes. Expected JSON structure:
     * { 
     *   "ArrayName": [ 
     *     { "Field0":        "ValueN", 
     *       "JSONAttribute": { 
     *         "GlobalIdentifier": [ 
     *           { "Field1":"ValueA", "Field2":"ValueB", "Field3":{ "Field31": "ValueK", ... }, ...}, 
     *           { "Field1":"ValueX", "Field2":"ValueY", "Field3":{ "Field31": "ValueL", ... }, ...}, 
     *           ...
     *         ]
     *       }
     *     },
     *     { "Field0":        "ValueM", 
     *       "JSONAttribute": { 
     *         "GlobalIdentifier": [ 
     *           { "Field1":"ValueC", "Field2":"ValueD", "Field3":{ "Field31": "ValueM", ... }, ...}, 
     *           { "Field1":"ValueW", "Field2":"ValueZ", "Field3":{ "Field31": "ValueN", ... }, ...}, 
     *           ...
     *         ]
     *       }
     *     },
     *     ...
     *   ]
     * }
     *  
     * @param containerItemsList    JSON String with a list of container items
     * @param attrsArrayField       Name of JSON field in the container item with the array of attributes
     * @param keyField              Name of JSON field in the array of attributes to be used as Key to find the required attribute
     * @param valueField            Name of JSON field in the array of attributes to update its value for the same attribute
     * @param keyAttribute          Value that identifies the attribute to update
     * @param newValueAttribute     Value to update in the indicated field of the selected attribute
     * @param valueObject           Name of JSON node containing the value object
     * @param valueObjectField      Name of JSON field inside the value object to be updated
     * @return JSON String with the value of indicated key attribute updated
     *  */ 
    public static String UpdateJSONAttribute(String containerItemsList, String attrsArrayField, String keyField, String valueField, String keyAttribute, String newValueAttribute, String valueObject, String valueObjectField){

        try {
            Map<String, Object> mapContainerItemsList = (Map<String, Object>)JSON.deserializeUntyped(containerItemsList);
            
            if(mapContainerItemsList != null && !mapContainerItemsList.values().IsEmpty()){
                Map<String, Object> mapContainerItem;
                List<Object> lstContainerItems =  (List<Object>)mapContainerItemsList.values()[0];

                // Attribute search and value fields update for the matching attribute
                List<Object> lstAttributes;
                Map<String, Object> mapAttribute;
                for(Object containerItem: lstContainerItems){
                    mapContainerItem = (Map<String, Object>)containerItem;
                    lstAttributes = (List<Object>)((Map<String,Object>) mapContainerItem.get(attrsArrayField)).values()[0];
                    for(Object objAttr: lstAttributes){
                        mapAttribute = (Map<String, Object>)objAttr;
                        if((String)mapAttribute.get(keyField) == keyAttribute){
                            mapAttribute.put(valueField, newValueAttribute);
                            ((Map<String, Object>)mapAttribute.get(valueObject)).put(valueObjectField, newValueAttribute);
                        }
                    }
                }
            }
            
            return JSON.serialize(mapContainerItemsList);

        } catch (Exception ex) {
            return null;
        }
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	SE AGREGAN LAS EXCEPCIONES CONFIGURADAS EN EL OBJETO OM_ProductoTecnico__c
    IN:			  
    OUT:			Mapa de excepciones con los valores almacenados en el objeto OM_ProductoTecnico__c
    -------------------------------------------------------------------------------------------------------------------------------------------------*/
	public static void getOMProductoTecnico(){
        
        excepciones = new Map<String, Map<String, Object>>();
        technicalDetails = new Map<String, Map<String, Object>>();
        for(OM_ProductoTecnico__c item : [SELECT Id, OM_TipoOrden__c, OM_SubtipoOrden__c, OM_Canal__c, 
                                          OM_ProductoTecnico__c, OM_ProcessDetails__c, OM_TechnicalDetails__c
                                          FROM OM_ProductoTecnico__c WITH SECURITY_ENFORCED]){
        	if(!excepciones.containsKey(item.OM_TipoOrden__c+'|'+item.OM_SubtipoOrden__c+'|'+item.OM_Canal__c+'|'+item.OM_ProductoTecnico__c) && String.IsNotBlank((String)item.OM_ProcessDetails__c)){
                excepciones.put(item.OM_TipoOrden__c+'|'+item.OM_SubtipoOrden__c+'|'+item.OM_Canal__c+'|'+item.OM_ProductoTecnico__c, (Map<String, Object>)JSON.DeserializeUntyped(item.OM_ProcessDetails__c));
            }
            if(!technicalDetails.containsKey(item.OM_TipoOrden__c+'|'+item.OM_SubtipoOrden__c+'|'+item.OM_Canal__c+'|'+item.OM_ProductoTecnico__c) && String.IsNotBlank((String)item.OM_TechnicalDetails__c)){
                technicalDetails.put(item.OM_TipoOrden__c+'|'+item.OM_SubtipoOrden__c+'|'+item.OM_Canal__c+'|'+item.OM_ProductoTecnico__c, (Map<String, Object>)JSON.DeserializeUntyped(item.OM_TechnicalDetails__c));
            } 
        }
    }	
}