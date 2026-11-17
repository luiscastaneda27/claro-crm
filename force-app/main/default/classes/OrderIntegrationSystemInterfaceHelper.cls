/**
* OrderIntegrationSystemInterfaceHelper for OM Stream
<Date>        <Version>     <Author>             <Description>      
2023-09-05      1.0.0       Mamata          	Initial
08-07-24        1.0.2       Emmanuel Ruarte     HDU 335682 - Cambio de Plan 1.0.1
2024-11-04	    1.0.3	  	Hever Salas		  	HDU-409739 - Agrupacion Ofertas
2024-02-03		1.0.4		Soporte-COE			INC2067237 - Se modifica el método "getOrderItemState", para asegurar que obtenga el OM_Status__c del OrderItem Parent.
2025-04-10		1.0.5       Hever Salas      	HDU-522166: PV - [CESION]  Crear Orden SOM
2025-04-30      1.0.6       Hever Salas      	BUG-574609: QA - Medium - BUG - Falta Mapeo de atributo PCcos
2025-05-13      1.0.7       Hever Salas    	    BUG-621423: R5-SIT-E3- Al registrar un caso de cesión de contrato, no se realiza el cierre automático
2025-09-23      1.0.8       Luis Mendoza    	Cambios para evitar vulneravilidades 
2026-01-24      1.0.9.      Gabriel Alvis       BUG-715936: Crea mapa de Producto Técnico por productOfferingId para permitir relacionamiento de productos
*/
public with sharing class OrderIntegrationSystemInterfaceHelper {
    
    public static final String TECH_ATTR_CATEGORY_NAME = OrderIntegrationSystemInterfaceConstants.TECH_ATTR_CATEGORY_NAME;
    public static String attrCatCode = IntegrationSystemInterfaceHelper.getTechAttributeCategoryCode();//get category code of attribute category
    public static final Set<String> TECHNICAL_PRODUCT_ACTION_MODIFY = OrderIntegrationSystemInterfaceConstants.TECHNICAL_PRODUCT_ACTION_MODIFY;
    public static final String TECHNICAL_PARENT_PRODUCT = OrderIntegrationSystemInterfaceConstants.TECHNICAL_PARENT_PRODUCT;        // V. 1.0.1 
    public static final String FRL_JSON_STR = OrderIntegrationSystemInterfaceConstants.FRL_JSON_STR;
    public static final String INV_JSON_STR = OrderIntegrationSystemInterfaceConstants.INV_JSON_STR;
    public static final String PRODUCT_IDS = OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS;              // V. 1.0.1
    public static final String SERVICE_IDS = OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS;            // V. 1.0.1
    public static final String RESOURCE_IDS = OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS;          // V. 1.0.1
    
    // Invoke DR
    public static List<Map <String, Object>> callDrExtract(Map<String, Object> inputParams, String drName){
        
        //Call DR
        vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process(inputParams, drName);    
        List<Map <String, Object>> transformResult = (List<Map <String, Object>>) result.toJsonList();
        System.debug('=====check output==='+ transformResult);
        return transformResult;
    }
    
    public static String getTechAttributeCategoryCode(){
        return [SELECT vlocity_cmt__Code__c FROM vlocity_cmt__AttributeCategory__c WHERE Name =: TECH_ATTR_CATEGORY_NAME WITH SECURITY_ENFORCED].vlocity_cmt__Code__c ;
    }
    
    public static Map<String, Map<String, Object>> getOrderItemPrice(Map<String, Object> ipInput){
        List<OrderItem> lstOrderItem = [SELECT Id, Product2.ProductCode, vlocity_cmt__SubAction__c, 
                                                vlocity_cmt__RecurringCharge__c, FVU_RecurringChargeIncTaxes__c, 
                                                vlocity_cmt__OneTimeCharge__c, FVU_OneTimeTotalIncTaxes__c     		
                                        FROM OrderItem
                                        WHERE OrderId =: (String)ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID)
                                        AND (vlocity_cmt__RecurringCharge__c > 0
                                             OR vlocity_cmt__OneTimeCharge__c > 0)
                                             WITH SECURITY_ENFORCED ];
            
        Map<String, Map<String, Object>> mapOneTimeAndRecurringAmountByFRL = new Map<String, Map<String, Object>>();
        
        if(lstOrderItem <> null && lstOrderItem.size() > 0){
        
            for(OrderItem item: lstOrderItem){
                Map<String, Object> oneTimeAndRecurringAmountByFRL = new Map<String, Object>();
                oneTimeAndRecurringAmountByFRL.put(OrderIntegrationSystemInterfaceConstants.VLOCITY_RECURRING_CHARGE, item.vlocity_cmt__RecurringCharge__c);
                oneTimeAndRecurringAmountByFRL.put(OrderIntegrationSystemInterfaceConstants.RECURRING_CHARGE_TAXES, item.FVU_RecurringChargeIncTaxes__c);
                oneTimeAndRecurringAmountByFRL.put(OrderIntegrationSystemInterfaceConstants.ONETIME_CHARGE, item.vlocity_cmt__OneTimeCharge__c);
                oneTimeAndRecurringAmountByFRL.put(OrderIntegrationSystemInterfaceConstants.ONETIME_CHARGE_TAXES, item.FVU_OneTimeTotalIncTaxes__c);
                
                if(item.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD || item.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PRODUCT_CODE_ESIM){
                    mapOneTimeAndRecurringAmountByFRL.put(OrderIntegrationSystemInterfaceConstants.TECHNICAL_SIMCARD_PRODUCT+'_'+item.vlocity_cmt__SubAction__c, oneTimeAndRecurringAmountByFRL);
                }else{
                    mapOneTimeAndRecurringAmountByFRL.put(item.Product2.ProductCode+'_'+item.vlocity_cmt__SubAction__c, oneTimeAndRecurringAmountByFRL);
                }
            }                
        }
        
        return mapOneTimeAndRecurringAmountByFRL;
    }
    
    public static void getFulfilmentRequestLineIdPopulate(Map<String, Object> mapInputIdPopulate){
        Map<String, Map<String, Set<Object>>> prodResServiceIdByFRL = (Map<String, Map<String, Set<Object>>>)mapInputIdPopulate.get('prodResServiceIdByFRL');
        Map<String,Object> mapFRL = new Map<String,Object>();
        List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = new List<vlocity_cmt__FulfilmentRequestLine__c>();
        Boolean updateCos = (Boolean)mapInputIdPopulate.get('updateCos');
        String cos = (String)mapInputIdPopulate.get('cos');
        vlocity_cmt__FulfilmentRequestLine__c frlInstance ;

        for(String frlKey : prodResServiceIdByFRL.keyset()){
            frlInstance = new vlocity_cmt__FulfilmentRequestLine__c();
            frlInstance.Id = frlKey;
            System.debug('====helper clss===frlKey==='+frlKey);
            for(String psrKey : prodResServiceIdByFRL.get(frlKey).keyset()){
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID)){
                    frlInstance.ProductIds__c = JSON.serialize(prodResServiceIdByFRL.get(frlKey).get(psrKey), true);
                }
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID_SER)){                                   // V. 1.0.1
                    frlInstance.ProductIds__c = (String)(new List<Object>(prodResServiceIdByFRL.get(frlKey).get(psrKey)))[0];
                }
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.SERVICE_ID)){
                    frlInstance.ServiceIds__c = JSON.serialize(prodResServiceIdByFRL.get(frlKey).get(psrKey), true);
                }
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.SERVICE_ID_SER)){                                   // V. 1.0.1
                    frlInstance.ServiceIds__c = (String)(new List<Object>(prodResServiceIdByFRL.get(frlKey).get(psrKey)))[0];
                }
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID)){
                    frlInstance.ResourceIds__c = JSON.serialize(prodResServiceIdByFRL.get(frlKey).get(psrKey), true);
                }
                if(psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID_SER)){                                  // V. 1.0.1
                    frlInstance.ResourceIds__c = (String)(new List<Object>(prodResServiceIdByFRL.get(frlKey).get(psrKey)))[0];
                }
                if (psrKey.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.JSON_ATTR)) {                                     // V. 1.0.1
                    frlInstance.vlocity_cmt__JSONAttribute__c = (String)(new List<Object>(prodResServiceIdByFRL.get(frlKey).get(psrKey)))[0];
                }
            }
            mapFRL.put(frlKey, frlInstance);
        }
        if(updateCos){//En caso de haber generado un nuevo cos entonces se procede a guardarlo en el FRL
            Map<String, Object> mapInputupdateCosToFRL = new Map<String, Object>();
            mapInputupdateCosToFRL.put('mapFRL', mapFRL);
            mapInputupdateCosToFRL.put('cos', cos);
            OM_OrderIntegrationHelper.updateCosToFRL(mapInputupdateCosToFRL);
        }
        for(Object itemFRL:mapFRL.values()){
            lstFRL.add((vlocity_cmt__FulfilmentRequestLine__c)itemFRL);
        }
        try{
            if(!lstFRL.isEmpty()){
                update lstFRL;
            } 
        }catch(Exception e){
            System.debug(e);
        }
    }
    
     public static String getOrderItemState(Map<String, Object> ipInput){
        List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> orderItemList = [SELECT vlocity_cmt__SourceOrderItemId__r.OM_Status__c
                                                                                         FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c 
                                                                                         WHERE vlocity_cmt__SourceOrderItemId__r.OrderId =: (String)ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID)
                                                                                         AND vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ParentItemId__c  = null
                                                                                         AND vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c = null
                                                                                         AND  vlocity_cmt__SourceOrderItemId__r.OM_Status__c != null // INC2067237: se incluye condición para asegurar que el Item a evaluar tenga un valor en el field: OM_Status__c.
                                                                                         WITH SECURITY_ENFORCED
                                                                                         LIMIT 1];
        if (!orderItemList.isEmpty()) {
            //return orderItemInfo.vlocity_cmt__SourceOrderItemId__r.OM_Status__c; 
        	return ((orderItemList[0].vlocity_cmt__SourceOrderItemId__r.OM_Status__c).equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ACTIVE)) ? 
            OrderIntegrationSystemInterfaceConstants.S_PRO_ACT : ((orderItemList[0].vlocity_cmt__SourceOrderItemId__r.OM_Status__c).equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_SUSPENDED)) ? OrderIntegrationSystemInterfaceConstants.S_INACTIVE : '';
        }else
            return '';
    }
    
    public static Map<String, Map<String, Map<String, String>>> getInventoryServiceResourceProductIdForSuspension(Map<String, Object> ipInput){
        Map<String, Map<String, Map<String, String>>> serviceProductResourceIdsByFulfilmentNo = new Map<String, Map<String, Map<String, String>>>();
        List<vlocity_cmt__FulfilmentRequestLine__c> requestLineList = [SELECT Id, Name, vlocity_cmt__InventoryItemId__r.OM_ProductIds__c, 
                                                                       vlocity_cmt__InventoryItemId__r.OM_ServiceIds__c, 
                                                                       vlocity_cmt__InventoryItemId__r.OM_ResourceIds__c 
                                                                       FROM vlocity_cmt__FulfilmentRequestLine__c 
                                                                       WHERE vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__OrderId__c =: (String)ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID)
                                                                       WITH SECURITY_ENFORCED ];
        
        
        for(vlocity_cmt__FulfilmentRequestLine__c frl: requestLineList){
            
            if(!serviceProductResourceIdsByFulfilmentNo.containsKey(frl.Id)){
                serviceProductResourceIdsByFulfilmentNo.put(frl.Id, new Map<String, Map<String, String>>());
            }
            
            if(serviceProductResourceIdsByFulfilmentNo.containsKey(frl.Id)){
                if(!serviceProductResourceIdsByFulfilmentNo.get(frl.Id).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS)){
                    serviceProductResourceIdsByFulfilmentNo.get(frl.Id).put(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS, new Map<String, String>());
                }
                if(!serviceProductResourceIdsByFulfilmentNo.get(frl.Id).containsKey(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS)){
                    serviceProductResourceIdsByFulfilmentNo.get(frl.Id).put(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS, new Map<String, String>());
                }
                if(!serviceProductResourceIdsByFulfilmentNo.get(frl.Id).containsKey(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS)){
                    serviceProductResourceIdsByFulfilmentNo.get(frl.Id).put(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS, new Map<String, String>());
                }
            } 
            
            if(String.isNotBlank(frl.vlocity_cmt__InventoryItemId__r.OM_ProductIds__c)){
                for(Object key : (List<Object>)JSON.deserializeUntyped(frl.vlocity_cmt__InventoryItemId__r.OM_ProductIds__c)){
                    for(String str : ((Map<String, Object>) key).keySet()){
                        serviceProductResourceIdsByFulfilmentNo.get(frl.Id).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS).put(str, (String)((Map<String, Object>) key).get(str)); 
                    }
                }
            }
            
            if(String.isNotBlank(frl.vlocity_cmt__InventoryItemId__r.OM_ServiceIds__c)){
                for(Object key : (List<Object>)JSON.deserializeUntyped(frl.vlocity_cmt__InventoryItemId__r.OM_ServiceIds__c)){
                    for(String str : ((Map<String, Object>) key).keySet()){
                        serviceProductResourceIdsByFulfilmentNo.get(frl.Id).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS).put(str, (String)((Map<String, Object>) key).get(str)); 
                    }
                }
            }
            if(String.isNotBlank(frl.vlocity_cmt__InventoryItemId__r.OM_ResourceIds__c)){
                for(Object key : (List<Object>)JSON.deserializeUntyped(frl.vlocity_cmt__InventoryItemId__r.OM_ResourceIds__c)){
                    for(String str : ((Map<String, Object>) key).keySet()){
                        serviceProductResourceIdsByFulfilmentNo.get(frl.Id).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS).put(str, (String)((Map<String, Object>) key).get(str)); 
                    }
                }
            }
        }
        
        System.debug('======serviceProductResourceIdsByFulfilmentNo==helper=='+JSON.serializePretty(serviceProductResourceIdsByFulfilmentNo, true));
        return serviceProductResourceIdsByFulfilmentNo;
    }
    
    public static Map<String, Map<String, String>> getFRLAndInventoryJSON(Map<String, Object> ipInput){
        // Consulta de atributos técnicos específicos
        Set<String> technicalProducts = new Set<String>(OrderIntegrationSystemInterfaceConstants.TECHNICAL_PRODUCT_ACTION_MODIFY);
        technicalProducts.add(OrderIntegrationSystemInterfaceConstants.TECHNICAL_PARENT_PRODUCT);
        List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> orderItemInfo = [ 
            SELECT 
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id,
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name ,
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__JSONAttribute__c, 
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.vlocity_cmt__JSONAttribute__c,
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ProductIds__c,              // V. 1.0.1
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ServiceIds__c,              // V. 1.0.1
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ResourceIds__c              // V. 1.0.1
            FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c 
            WHERE vlocity_cmt__SourceOrderItemId__r.OrderId =: (String)ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID)
            AND   vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name IN :technicalProducts 
            WITH SECURITY_ENFORCED
        ];

        System.debug('====CHANGEATTR==='+(orderItemInfo.size()>0?orderItemInfo[0].vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name:'Sin Relaciones 0'));
        System.debug('====CHANGEATTR==='+(orderItemInfo.size()>1?orderItemInfo[1].vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name:'Sin Relaciones 1'));
        System.debug('====CHANGEATTR==='+(orderItemInfo.size()>2?orderItemInfo[2].vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name:'Sin Relaciones 2'));

        Map<String, Map<String, String>> frlInventoryJSONByFRLId = new Map<String, Map<String, String>>();
        for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c frldr : orderItemInfo){
            System.debug('====CHANGEATTRId==='+frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id);

            if(!frlInventoryJSONByFRLId.containsKey(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id)){
                frlInventoryJSONByFRLId.put(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id, new Map<String, String>());
            }
            frlInventoryJSONByFRLId.get(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id).put(FRL_JSON_STR, frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__JSONAttribute__c);
            frlInventoryJSONByFRLId.get(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id).put(INV_JSON_STR, frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.vlocity_cmt__JSONAttribute__c);
            frlInventoryJSONByFRLId.get(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id).put(PRODUCT_IDS, frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ProductIds__c);          // V. 1.0.1
            frlInventoryJSONByFRLId.get(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id).put(SERVICE_IDS, frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ServiceIds__c);          // V. 1.0.1
            frlInventoryJSONByFRLId.get(frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.Id).put(RESOURCE_IDS, frldr.vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__InventoryItemId__r.OM_ResourceIds__c);        // V. 1.0.1
        }
        
        return frlInventoryJSONByFRLId;
    }

    /*-----------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se obtienen los inventory item asociados al asset cedente
    IN:			    OrderId id de la orden asociada al plan de orquestacion actual
    OUT:			Se retorna un mapa de mapas que contienen los valores de los inventoryItem cedentes 
    Example OUT: {'PO_MovPosBasico' = {'productIds' = [{"PS_MovPosUsoOtros":"125040097621001"}], 'resourceIds' = [{"PRS_SimCard":"125040097626201"}], 'serviceIds' = [{"CFSS_MovPosBasico":"125040097626101"}]}}
    -------------------------------------------------------------------------------------------------------------*/ 
    public static Map<String, Map<String, Object>> getInventoryItemsOldJSON(Map<String, String> ipInput){
        
        // Se obtiene el id del asset anterior
        String caseInfo = [SELECT Id, PVU_CaseInfo__c
                            FROM Order
                            WHERE Id = :(String)ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID) WITH SECURITY_ENFORCED].PVU_CaseInfo__c;

        if(String.IsNotBlank(caseInfo) && caseInfo.contains('cedenteAssetId')){
            Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped(caseInfo);
            // Se obtiene el assetreference cedente
            Asset assetReferenceId = [SELECT Id, vlocity_cmt__AssetReferenceId__c
                                    FROM Asset
                                    WHERE Id =: (String)mapCaseInfo.get('cedenteAssetId') WITH SECURITY_ENFORCED];
            // Se obtienen los datos del inventory item cedente
            List<vlocity_cmt__InventoryItem__c> lstInventoryItemInfo = [SELECT vlocity_cmt__ProductId__r.name, 
                                                                        OM_ProductIds__c, OM_ResourceIds__c, OM_ServiceIds__c 
                                                                        FROM vlocity_cmt__InventoryItem__c 
                                                                        WHERE Id IN (SELECT vlocity_cmt__DestinationInventoryItemId__c 
                                                                                     FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
                                                                                     WHERE (vlocity_cmt__SourceAssetId__r.vlocity_cmt__RootItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c
                                                                                            OR vlocity_cmt__SourceAssetId__r.vlocity_cmt__ReliesOnItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c)
                                                                                     AND vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__ProductId__r.name != :OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT)
                                                                                     WITH SECURITY_ENFORCED];   
			List<vlocity_cmt__InventoryItemDecompositionRelationship__c> lstIIDR = [SELECT vlocity_cmt__DestinationInventoryItemId__c, vlocity_cmt__SourceAssetId__r.Product2.ProductCode
                                                                                    FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
                                                                                    WHERE (vlocity_cmt__SourceAssetId__r.vlocity_cmt__RootItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c
                                                                                           OR vlocity_cmt__SourceAssetId__r.vlocity_cmt__ReliesOnItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c)
                                                                                    AND vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__ProductId__r.name = :OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT
                                                                                    WITH SECURITY_ENFORCED];
            
            List<vlocity_cmt__InventoryItem__c> lstInventoryItemOTT = [SELECT Id, vlocity_cmt__ProductId__r.name, OM_ProductIds__c, OM_ResourceIds__c, OM_ServiceIds__c 
                                                                       FROM vlocity_cmt__InventoryItem__c 
                                                                       WHERE Id IN (SELECT vlocity_cmt__DestinationInventoryItemId__c 
                                                                                    FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
                                                                                    WHERE (vlocity_cmt__SourceAssetId__r.vlocity_cmt__RootItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c
                                                                                           OR vlocity_cmt__SourceAssetId__r.vlocity_cmt__ReliesOnItemId__c = :(String)assetReferenceId.vlocity_cmt__AssetReferenceId__c)
                                                                                    AND vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__ProductId__r.name = :OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT)
                                                                                    WITH SECURITY_ENFORCED];
            Map<String, vlocity_cmt__InventoryItem__c> mapIIFinal = new Map<String, vlocity_cmt__InventoryItem__c>();
            Map<String, String> mapIIDR = new Map<String, String>();
            if(lstIIDR.size() > 0){
                for(vlocity_cmt__InventoryItemDecompositionRelationship__c itemIIDR: lstIIDR){
                    mapIIDR.put((String)itemIIDR.vlocity_cmt__DestinationInventoryItemId__c, (String)itemIIDR.vlocity_cmt__SourceAssetId__r.Product2.ProductCode);
                }
                for(vlocity_cmt__InventoryItem__c itemOTT: lstInventoryItemOTT){
                    mapIIFinal.put(mapIIDR.get(itemOTT.Id), itemOTT);
                }
            }
            for(vlocity_cmt__InventoryItem__c itemII: lstInventoryItemInfo){
                mapIIFinal.put(itemII.vlocity_cmt__ProductId__r.name, itemII);
            }
            
            Map<String, Map<String, Object>> mapInventoryItemCesion = new Map<String, Map<String, Object>>();
            for(String item : mapIIFinal.keySet()){

                if(!mapInventoryItemCesion.containsKey(item)){
                    mapInventoryItemCesion.put(item, new Map<String, Object>());
                }
                if(String.IsNotBlank(mapIIFinal.get(item).OM_ProductIds__c)){
                    mapInventoryItemCesion.get(item).put(PRODUCT_IDS, JSON.DeserializeUntyped(mapIIFinal.get(item).OM_ProductIds__c));          // V. 1.0.1
                }
                if(String.IsNotBlank(mapIIFinal.get(item).OM_ServiceIds__c)){
                    mapInventoryItemCesion.get(item).put(SERVICE_IDS, JSON.DeserializeUntyped(mapIIFinal.get(item).OM_ServiceIds__c));          // V. 1.0.1
                }
                if(String.IsNotBlank(mapIIFinal.get(item).OM_ResourceIds__c)){
                    mapInventoryItemCesion.get(item).put(RESOURCE_IDS, JSON.DeserializeUntyped(mapIIFinal.get(item).OM_ResourceIds__c));        // V. 1.0.1
                }
            }
            return mapInventoryItemCesion;
        }else{       
            return null;
        }
    }

    /**
    * @description Agrupa por código de Producto Técnico Ericsson y Acción/Subacción los FFRL
    * @author Gabriel Alvis| 2026-10-24
    * @param lstProductoTecnico Lista de información de Productos Técnicos estructurada en mapa
    * @return Mapa de Productos Técnicos cuya llave es el productOfferingId de cada uno. Ejm: {PO_MovPosBasico => {Add/ChangePlan-Reassign => IdFFRL1, Delete/ChangePlan-Reassing => IdFFRL2}}
    **/
    public static Map<String, Map <String, Id>> agruparProductoTecnicoSOMAccion(List<Map <String, Object>> lstProductoTecnico){
        Map<String, Map <String, Id>> mapProductoTecnico = new Map<String, Map <String, Id>>();
        Map<String, Object> mapAtrsProdTecnico;
        Map<String, Object> mapCatsAtrProdTecnico;
        Map<String, Id> mapAccionProdTecnico;
        List<Object> lstAtrsTecnicosProducto;
        if(lstProductoTecnico != null && !lstProductoTecnico.isEmpty()){
            for (Map<String, Object> prodTec : lstProductoTecnico){
                mapCatsAtrProdTecnico = (Map<String, Object>)prodTec.get(OrderIntegrationSystemInterfaceConstants.SERIALISED_JSON_STR);
                if(mapCatsAtrProdTecnico != null && !mapCatsAtrProdTecnico.isEmpty()){
                    lstAtrsTecnicosProducto = (List<Object>)mapCatsAtrProdTecnico.get(OrderIntegrationSystemInterfaceHelper.getTechAttributeCategoryCode());
                    if(lstAtrsTecnicosProducto!= null && !lstAtrsTecnicosProducto.isEmpty()){
                        for (Object atrTec : lstAtrsTecnicosProducto) {
                            mapAtrsProdTecnico = (Map<String, Object>)atrTec;
                            if(mapAtrsProdTecnico != null && !mapAtrsProdTecnico.isEmpty() && mapAtrsProdTecnico.get(OrderIntegrationSystemInterfaceConstants.CODE) == OrderIntegrationSystemInterfaceConstants.getValue('PRODUCT_OFFERING_ATTRIBUTE')){
                                if(mapProductoTecnico.containsKey((String)mapAtrsProdTecnico.get(OrderIntegrationSystemInterfaceConstants.SEG_VALUE))){
                                    mapAccionProdTecnico = mapProductoTecnico.get((String)mapAtrsProdTecnico.get(OrderIntegrationSystemInterfaceConstants.SEG_VALUE));
                                    mapAccionProdTecnico.put(prodTec.get(OrderIntegrationSystemInterfaceConstants.ACTION) + '/' + prodTec.get(OrderIntegrationSystemInterfaceConstants.SUB_ACTION), (Id)prodTec.get(OrderIntegrationSystemInterfaceConstants.FULFILMENTID));
                                }
                                else{
                                    mapAccionProdTecnico = new Map<String, Id> {prodTec.get(OrderIntegrationSystemInterfaceConstants.ACTION) + '/' + prodTec.get(OrderIntegrationSystemInterfaceConstants.SUB_ACTION) => (Id)prodTec.get(OrderIntegrationSystemInterfaceConstants.FULFILMENTID)};
                                    mapProductoTecnico.put((String)mapAtrsProdTecnico.get(OrderIntegrationSystemInterfaceConstants.SEG_VALUE), mapAccionProdTecnico);
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
        return mapProductoTecnico;
    }
}