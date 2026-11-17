/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase responsable de extraer datos de Salesforce y cargarlos 
 * en objetos custom para su posterior exportación.
 * Code Coverage: 91%
 * History
 * <Date>       <Author>        <Description>       											<Version>
 * 08-Sep-25    Hugo Revuelta   Version inicial 												0.1
 * 20-Sep-25	Nahir Arrejoria	Implementación de logica de extracción y llenado de objetos		1.0
 * 
 *----------------------------------------------------------------------------*/
public with sharing class CATDataExtractionService {

    /**
     * @description orquesta el proceso completo de extracción y carga de datos.
     * Invoca métodos privados para cada custom object.
     * @return void
     */
    public static void extractAndLoadData(String objetoControlId,Id idLogRecord, List<String> prodCodeList, List<String> promoCodeList, String tipoCarga, Boolean incluirCompatibilidad) {
        System.debug('[INFO] Iniciando el proceso de extracción y carga de datos.');
        Datetime fechaInicio = datetime.NOW();

        try {
            System.debug('+++queries at the begining: '+ Limits.getQueries());
            // Invoca los métodos de extracción y carga para cada objeto.
            // Remove duplicates and store in a single list
            // logic for batch for atributes 
            // Collect all products into a unified map for the batch
            Map<Id, Product2> allProductsByIdBatch = new Map<Id, Product2>();
            
            
            System.debug('tipoCarga:' + tipoCarga);
            System.debug('incluirCompatibilidad:' + incluirCompatibilidad);
            
            if(tipoCarga == 'Compatibilidad' || tipoCarga == 'Total' ||(tipoCarga != 'Compatibilidad' && incluirCompatibilidad == true)){
                CATCompatibilityExportBatch batchCompatibidad = new CATCompatibilityExportBatch();
                Database.executeBatch(batchCompatibidad);
                if (tipoCarga == 'Compatibilidad'){
                    CATDataUpdateService.updateSuccessLogRecord('Extracción y carga de datos completada con éxito.', objetoControlId,idLogRecord);
          
                    //Notificacion
                    CATNotificationService.enqueue(objetoControlId);
                }
                
                
            }
            if(tipoCarga != 'Compatibilidad'){
                Set<String> uniqueProductCodes = new Set<String>(prodCodeList);
                List<String> productCodeList = new List<String>(uniqueProductCodes);
                Set<String> uniquePromotionCodes ;
                List<String> promotionCodeList ; 
                if(promoCodeList != null) {
                    uniquePromotionCodes = new Set<String>(promoCodeList);
                	promotionCodeList = new List<String>(uniquePromotionCodes);
                }
                
        
                // Pre-query all necessary data to reduce SOQL calls
                Map<String, Product2> productsByCode = getProductsByProductCode(productCodeList);
                Set<Id> productIds = new Set<Id>();
                for (Product2 prod : productsByCode.values()) {
                    productIds.add(prod.Id);
                    allProductsByIdBatch.put(prod.Id,prod);
                }
                
                Map<String, vlocity_cmt__Promotion__c> promotionsByCode = getPromotionByCode(productCodeList);
                Set<Id> promotionsIds = new Set<Id>();
                for (vlocity_cmt__Promotion__c promo : promotionsByCode.values()) {
                    promotionsIds.add(promo.Id);
                }
                
                Map<Id, List<vlocity_cmt__ProductChildItem__c>> childItemsByParentId = getProductChildItems(productIds);
                
                Map<Id, List<vlocity_cmt__RuleAssignment__c>> productRulesByObjectId = getRuleAssignments(productIds);
                
                // Promotions and related data
                List<vlocity_cmt__PromotionItem__c> promoItemList = new List<vlocity_cmt__PromotionItem__c>();
                Map<Id, Product2> childItemsByParentIdPromo  = new Map<Id, Product2>();
                if(promoCodeList != null) {
                    promoItemList = getPromotionItemsPromo(promotionCodeList,productCodeList);
                }
                
      
                System.debug('+++promotionsIds: '+ promotionsIds);
                childItemsByParentIdPromo = getProductChildItemsPromo(promotionsIds);
                Set<Id> promoChildProductIds = new Set<Id>();
                for(Product2 prodPromo :childItemsByParentIdPromo.values()){
                    promoChildProductIds.add(prodPromo.Id);
                }
                Map<Id, List<vlocity_cmt__ProductChildItem__c>> childItemsByParentIdPromos = getProductChildItems(promoChildProductIds);
                System.debug('+++childItemsByParentIdPromo: '+ childItemsByParentIdPromo);
                System.debug('+++promotionCodeList: '+ childItemsByParentIdPromo.size());
                allProductsByIdBatch.putAll(childItemsByParentIdPromo);
                for (List<vlocity_cmt__ProductChildItem__c> childItemList : childItemsByParentIdPromos.values()) {
                    // For each list, iterate over the individual ProductChildItem__c records
                    for (vlocity_cmt__ProductChildItem__c childItem : childItemList) {
                        
                        // Ensure the child product and its parent are not null before adding
                        if (childItem.vlocity_cmt__ChildProductId__c != null && childItem.vlocity_cmt__ChildProductId__c != null) {
                            
                            // The key for the new map is the child's Id.
                            // The value is the related child Product2 record.
                            allProductsByIdBatch.put(childItem.vlocity_cmt__ChildProductId__c, childItem.vlocity_cmt__ChildProductId__r);
                        }
                    }
                }
                for (List<vlocity_cmt__ProductChildItem__c> childItemList : childItemsByParentId.values()) {
                    // For each list, iterate over the individual ProductChildItem__c records
                    for (vlocity_cmt__ProductChildItem__c childItem : childItemList) {
                        
                        // Ensure the child product and its parent are not null before adding
                        if (childItem.vlocity_cmt__ChildProductId__c != null && childItem.vlocity_cmt__ChildProductId__c != null) {
                            
                            // The key for the new map is the child's Id.
                            // The value is the related child Product2 record.
                            allProductsByIdBatch.put(childItem.vlocity_cmt__ChildProductId__c, childItem.vlocity_cmt__ChildProductId__r);
                        }
                    }
                }
                System.debug('allProductsByIdBatch: '+ allProductsByIdBatch.size());
                Map<String, vlocity_cmt__ProductChildItem__c> parentProductByChildProductCodeBatch = getParentProductByChildProductCode(productsByCode,childItemsByParentId, childItemsByParentIdPromo);
                
                Set<Id> promotionIds = new Set<Id>();
                Set<Id> promoItemIds = new Set<Id>();
                for(vlocity_cmt__PromotionItem__c promoItem : promoItemList){
                    promotionIds.add(promoItem.vlocity_cmt__PromotionId__c);
                }
                List<vlocity_cmt__PromotionItem__c> promoItemListProduct = getPromotionItemsProduct(productCodeList);
                for(vlocity_cmt__PromotionItem__c promoItem : promoItemListProduct){
                    promotionIds.add(promoItem.vlocity_cmt__PromotionId__c);
         
                    promoItemList.add(promoItem); //se agrega promoitem de las promociones asociadas al plan
                }
       
                
                Map<Id, List<vlocity_cmt__PriceListEntry__c>> priceListEntriesByPromoId = getPriceListEntriesByPromotion(promotionIds,productCodeList,promotionCodeList,promoItemList);
                // Iterate over the values of the priceListEntriesByPromoId map
                Set<Id> pleIds = new Set<Id>();
                for (List<vlocity_cmt__PriceListEntry__c> priceListEntries : priceListEntriesByPromoId.values()) {
                    for (vlocity_cmt__PriceListEntry__c ple : priceListEntries) {
                        pleIds.add(ple.Id);
                    }
                }
                
                Map<Id, List<vlocity_cmt__RuleAssignment__c>> pleRulesByObjectId = getRuleAssignments(pleIds);
                Map<Id, List<vlocity_cmt__RuleAssignment__c>> promotionRulesByObjectId = getRuleAssignments(promotionIds);
                
                 // Attributes and related data
                Map<Id, List<vlocity_cmt__AttributeAssignment__c>> attributesByObjectId = getAttributeAssignments(productIds, productsByCode, childItemsByParentIdPromo);
                
                // Compatibility and related data
                Map<Id, List<vlocity_cmt__CatalogProductRelationship__c>> compatibilityByObjectId = getProductCompatibility(productIds, childItemsByParentIdPromo);
                
                // Prices
                Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode = getProductPrices(productCodeList, childItemsByParentIdPromo );
                
                Integer batchSize = 50;
                CATAttributeExportBatch batchJob = new CATAttributeExportBatch(allProductsByIdBatch, parentProductByChildProductCodeBatch);
                Database.executeBatch(batchJob,batchSize);
                
                extractAndLoadProducts(productsByCode, childItemsByParentId, productRulesByObjectId, promotionsByCode,childItemsByParentIdPromo); 
               // extractAndLoadProductCompatibility(compatibilityByObjectId, productsByCode);   
                extractAndLoadProductPrices(pricesByProductCode);
                extractAndLoadPromotions(promoItemList, priceListEntriesByPromoId, promotionRulesByObjectId,pleRulesByObjectId);
                //extractAndLoadProductAttributes(attributesByObjectId, productsByCode,childItemsByParentId, childItemsByParentIdPromo);
                // Lógica para registrar la finalización exitosa.
                
                System.debug('+++queries at the end: '+ Limits.getQueries());
                    //return listResponse;
                    //Se llama a la clase que maneja la actualización de precios
                   System.debug('+++promoItemList: '+ promoItemList);
                CATDataUpdateService.calculateAndUpdateData(objetoControlId,idLogRecord,productCodeList,pricesByProductCode,promoItemList);
                //CATDataUpdateService.calculateAndUpdateData(objetoControlId,productCodeList,pricesByProductCode);  
               // String successLog = createSuccessLogRecord('Extracción y carga de datos completada con éxito.', objetoControlId,fechaInicio);
                  String resultadoProceso = 'Éxito';
                  System.debug('[SUCCESS] El proceso de extracción y carga de datos ha finalizado correctamente.');
                
            }
            
            
            
                

        } catch (Exception processException) {
            // Lógica para registrar el fallo en la ejecución y notificar al usuario.
            createFailureLogRecord('Error durante la extracción y carga de datos: ' + processException.getMessage(),objetoControlId,idLogRecord);
            
            System.debug('[ERROR] El proceso de extracción y carga de datos ha fallado.');
            
            //throw new CAT_ExtractionException('Error en el proceso de extracción.', processException);
            //return listResponse;
        }
        
    }
    // --- Helper Methods for Data Retrieval ---
    // 

     private static Map<String, vlocity_cmt__ProductChildItem__c> getParentProductByChildProductCode(Map<String, Product2> productsByCode, Map<Id, List<vlocity_cmt__ProductChildItem__c>> childItemsByParentId,Map<Id, Product2>childItemsByParentIdPromo) {
         // Step 1: Create a unified map of ALL products (parents and children).
        // This is the most efficient way to access product data later.
        Map<Id, Product2> allProductsById = new Map<Id, Product2>();
        
        // Add all parent products from the initial query
        for (Product2 prod : productsByCode.values()) {
            allProductsById.put(prod.Id, prod);
        }
        
        // Add all child products. First, get their Ids.
        Set<Id> childProductIds = new Set<Id>();
        for (List<vlocity_cmt__ProductChildItem__c> childItems : childItemsByParentId.values()) {
            for (vlocity_cmt__ProductChildItem__c item : childItems) {
                childProductIds.add(item.vlocity_cmt__ChildProductId__r.Id);
            }
        }
        System.debug('+++childItemsByParentIdPromo: '+ childItemsByParentIdPromo.keySet());
         // Loop through all the Product2 records (values) in the map
        Set<Id> productIdsFromPromoMap = new Set<Id>();
        for (Product2 prod : childItemsByParentIdPromo.values()) {
            System.debug('++prod.produccode: '+ prod.ProductCode);
            // Add the Id of each Product2 record to the set
           // allProductsById.put(prod.Id, prod);
            productIdsFromPromoMap.add(prod.Id);
            
        }
     	 List<vlocity_cmt__ProductChildItem__c> childProducts = [SELECT Id, vlocity_cmt__ChildProductId__r.Name,vlocity_cmt__ChildProductId__r.ProductCode,vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c,vlocity_cmt__ParentProductId__r.ProductCode, vlocity_cmt__ParentProductId__c 
            														FROM vlocity_cmt__ProductChildItem__c
            														WHERE vlocity_cmt__ParentProductId__c IN :productIdsFromPromoMap
            														AND vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c = 'Plan'
            														WITH SECURITY_ENFORCED];
        
        System.debug('+++childProductIds: '+ childProductIds);
        // Query for the child Product2 records and add them to the map
        for (vlocity_cmt__ProductChildItem__c childprodPromo : childProducts ) {
            childProductIds.add(childprodPromo.vlocity_cmt__ChildProductId__r.Id);
            

        }
        
        List<Product2> childProds = [SELECT Id, ProductCode,vlocity_cmt__Type__c,vlocity_cmt__SpecificationSubType__c FROM Product2 WHERE Id IN :childProductIds WITH SECURITY_ENFORCED];
        System.debug('+++childProds.size: '+ childProds.size());
        
        
        for (Product2 childProd : childProds) {
            System.debug('adding  '+ childProd.ProductCode);
            allProductsById.put(childProd.Id, childProd);
        }
      
        System.debug('++++allProductsById'  + 'size: '+ allProductsById.keySet());
        List<vlocity_cmt__ProductChildItem__c> parentProducts = [select id,vlocity_cmt__ChildProductId__r.ProductCode,vlocity_cmt__ParentProductId__r.ProductCode  from vlocity_cmt__ProductChildItem__c where vlocity_cmt__ChildProductId__c IN :childProductIds  WITH SECURITY_ENFORCED];
        Map<String, vlocity_cmt__ProductChildItem__c> parentProductByChildProductCode = new Map<String, vlocity_cmt__ProductChildItem__c>();

        for (vlocity_cmt__ProductChildItem__c item : parentProducts) {
            String childProductCode = item.vlocity_cmt__ChildProductId__r.ProductCode;
            parentProductByChildProductCode.put(childProductCode, item);
        }
         return parentProductByChildProductCode;
    
	}
    
    
     private static Map<String, Product2> getProductsByProductCode(List<String> prodCodeList) {
        List<Product2> productList = [
            SELECT Id, Name, ProductCode, vlocity_cmt__Type__c,CAT_PrecioOneTime__c,CAT_Oferta_Retencion__c,vlocity_cmt__SpecificationSubType__c, vlocity_cmt__SubType__c, Description, Short_Description__c, Family,
                   vlocity_cmt__SellingEndDate__c, CAT_Canales__c, CAT_Proceso_Negocio__c, vlocity_cmt__SellingStartDate__c,
                   vlocity_cmt__IsOrderable__c, IsActive
            FROM Product2
            WHERE ProductCode IN :prodCodeList
            WITH SECURITY_ENFORCED
        ];
        Map<String, Product2> productMap = new Map<String, Product2>();
        for (Product2 prod : productList) {
            productMap.put(prod.ProductCode, prod);
        }
        
        return productMap;
    }
    
    private static Map<String, vlocity_cmt__Promotion__c> getPromotionByCode(List<String> prodCodeList) {
        List<vlocity_cmt__Promotion__c> promotionList = [
            SELECT Id, Name, vlocity_cmt__Code__c, vlocity_cmt__Description__c, vlocity_cmt__EffectiveStartDate__c, 
            vlocity_cmt__EffectiveEndDate__c,CAT_Oferta_Retencion__c,CAT_PromotionClass__c,CAT_Type__c ,  CAT_Canales__c, CAT_Proceso_Negocio__c, 
            vlocity_cmt__IsOrderable__c, vlocity_cmt__IsActive__c 
            FROM vlocity_cmt__Promotion__c 
            WHERE vlocity_cmt__Code__c IN :prodCodeList AND CAT_PromotionClass__c = 'Bundle'
            WITH SECURITY_ENFORCED
        ]; 
        Map<String, vlocity_cmt__Promotion__c> promotionMap = new Map<String, vlocity_cmt__Promotion__c>();
        for (vlocity_cmt__Promotion__c promo : promotionList) {
            promotionMap.put(promo.vlocity_cmt__Code__c, promo);
        }
        
        return promotionMap;
    }
    
    private static Map<Id, List<vlocity_cmt__ProductChildItem__c>> getProductChildItems(Set<Id> productIds) {
        List<vlocity_cmt__ProductChildItem__c> childItems = [
            SELECT Id, vlocity_cmt__ChildProductId__r.Name,vlocity_cmt__ChildProductId__r.ProductCode,vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c,vlocity_cmt__ChildProductId__r.vlocity_cmt__SpecificationSubType__c, vlocity_cmt__ParentProductId__c 
            FROM vlocity_cmt__ProductChildItem__c
            WHERE vlocity_cmt__ParentProductId__c IN :productIds
            AND vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c = 'Plan'
            WITH SECURITY_ENFORCED
        ];
        Map<Id, List<vlocity_cmt__ProductChildItem__c>> childItemsMap = new Map<Id, List<vlocity_cmt__ProductChildItem__c>>();
        for (vlocity_cmt__ProductChildItem__c item : childItems) {
            if (!childItemsMap.containsKey(item.vlocity_cmt__ParentProductId__c)) {
                childItemsMap.put(item.vlocity_cmt__ParentProductId__c, new List<vlocity_cmt__ProductChildItem__c>());
            }
            childItemsMap.get(item.vlocity_cmt__ParentProductId__c).add(item);
        }
        return childItemsMap;
    }
    
    private static Map<Id, Product2> getProductChildItemsPromo (Set<Id> promoCodeList) {
        //Obtener promoItems, obtener product, obtener child 'plan'
        System.debug('getProductChildItemsPromo++promoCodeList: '+ promoCodeList);
        List<vlocity_cmt__PromotionItem__c> promoItems = [SELECT vlocity_cmt__PromotionId__c,vlocity_cmt__ProductId__c,vlocity_cmt__PromotionId__r.CAT_Canales__c
                                                             FROM vlocity_cmt__PromotionItem__c  WHERE vlocity_cmt__PromotionId__c IN :promoCodeList AND vlocity_cmt__ProductId__r.vlocity_cmt__Type__c = 'Plan' WITH SECURITY_ENFORCED 
                                                             ORDER BY vlocity_cmt__PromotionId__r.Name]; 
        
        System.debug('+++promoItems:' + promoItems);
        Set<Id> productIds = new Set<Id>();
        Map<Id, Id> promoIdToProductId = new Map<Id, Id>();
    
        for (vlocity_cmt__PromotionItem__c item : promoItems) {
            if (item.vlocity_cmt__ProductId__c != null) {
                productIds.add(item.vlocity_cmt__ProductId__c);
                // This map links each PromotionId to a ProductId.
                promoIdToProductId.put(item.vlocity_cmt__PromotionId__c, item.vlocity_cmt__ProductId__c);
            }
        }
    
        // Step 2: Query for the full Product2 records.
       Map<Id, Product2> productsById = new Map<Id, Product2>([
            SELECT Id, Name, ProductCode, vlocity_cmt__Type__c,vlocity_cmt__SpecificationSubType__c, vlocity_cmt__SubType__c, Description, Short_Description__c, Family,
                   vlocity_cmt__SellingEndDate__c, CAT_Canales__c, CAT_Proceso_Negocio__c, vlocity_cmt__SellingStartDate__c,
                   vlocity_cmt__IsOrderable__c, IsActive
            FROM Product2
            WHERE Id IN :productIds
            WITH SECURITY_ENFORCED
        ]);
    
        // Step 3: Build the final map with PromotionId as the key and Product2 as the value.
        Map<Id, Product2> promotionIdToProductMap = new Map<Id, Product2>();
        for (Id promoId : promoIdToProductId.keySet()) {
            Id productId = promoIdToProductId.get(promoId);
            Product2 productRecord = productsById.get(productId);
    
            if (productRecord != null) {
                promotionIdToProductMap.put(promoId, productRecord);
            }
        }
            return promotionIdToProductMap;
    }
    
    private static Map<Id, List<vlocity_cmt__RuleAssignment__c>> getRuleAssignments(Set<Id> objectIds) {
        List<vlocity_cmt__RuleAssignment__c> ruleAssignments = [
            SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__RuleId__r.Name, vlocity_cmt__RuleId__r.vlocity_cmt__Description__c
            FROM vlocity_cmt__RuleAssignment__c
            WHERE vlocity_cmt__ObjectId__c IN :objectIds
            WITH SECURITY_ENFORCED
        ];
        Map<Id, List<vlocity_cmt__RuleAssignment__c>> rulesByObjectId = new Map<Id, List<vlocity_cmt__RuleAssignment__c>>();
        for (vlocity_cmt__RuleAssignment__c ra : ruleAssignments) {
            if (!rulesByObjectId.containsKey(ra.vlocity_cmt__ObjectId__c)) {
                rulesByObjectId.put(ra.vlocity_cmt__ObjectId__c, new List<vlocity_cmt__RuleAssignment__c>());
            }
            rulesByObjectId.get(ra.vlocity_cmt__ObjectId__c).add(ra);
        }
        return rulesByObjectId;
    }

    private static List<vlocity_cmt__PromotionItem__c> getPromotionItemsPromo(List<String> promotionCodeList,List<String> productCodeList) {
        return [
            SELECT vlocity_cmt__PromotionId__c,vlocity_cmt__Description__c,vlocity_cmt__PromotionId__r.CAT_Oferta_Retencion__c,vlocity_cmt__PromotionId__r.CAT_Canales__c,vlocity_cmt__PromotionId__r.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c, vlocity_cmt__EffectiveFromDate__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__Quantity__c,
                   vlocity_cmt__MaxQuantity__c, vlocity_cmt__MinQuantity__c, vlocity_cmt__PromotionId__r.Name, vlocity_cmt__PromotionId__r.vlocity_cmt__Description__c,
                   vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsOrderable__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsActive__c,
                   vlocity_cmt__PromotionId__r.CAT_Type__c, vlocity_cmt__PromotionId__r.CAT_PromotionClass__c, vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscount__c,
                   vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscountPercent__c, vlocity_cmt__PromotionId__r.CAT_Proceso_Negocio__c,
                   vlocity_cmt__ProductId__r.Name, vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c
            FROM vlocity_cmt__PromotionItem__c
            WHERE (vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :promotionCodeList OR vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :productCodeList)
            AND vlocity_cmt__IsActive__c = true
            WITH SECURITY_ENFORCED
        ];
    }
    
    private static List<vlocity_cmt__PromotionItem__c> getPromotionItemsProduct(List<String> prodCodeList) {
        return [
            SELECT vlocity_cmt__PromotionId__c,vlocity_cmt__Description__c,vlocity_cmt__PromotionId__r.CAT_Oferta_Retencion__c, vlocity_cmt__PromotionId__r.CAT_Canales__c,vlocity_cmt__PromotionId__r.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c, vlocity_cmt__EffectiveFromDate__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__Quantity__c,
                   vlocity_cmt__MaxQuantity__c, vlocity_cmt__MinQuantity__c, vlocity_cmt__PromotionId__r.Name, vlocity_cmt__PromotionId__r.vlocity_cmt__Description__c,
                   vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsOrderable__c, vlocity_cmt__PromotionId__r.vlocity_cmt__IsActive__c,
                   vlocity_cmt__PromotionId__r.CAT_Type__c, vlocity_cmt__PromotionId__r.CAT_PromotionClass__c, vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscount__c,
                   vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscountPercent__c, vlocity_cmt__PromotionId__r.CAT_Proceso_Negocio__c,
                   vlocity_cmt__ProductId__r.Name, vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c
            FROM vlocity_cmt__PromotionItem__c
            WHERE vlocity_cmt__ProductId__r.ProductCode IN :prodCodeList
            WITH SECURITY_ENFORCED
        ];
    }
    private static Map<Id, List<vlocity_cmt__PriceListEntry__c>> getPriceListEntriesByPromotion(Set<Id> promotionIds, List<String> productCodeList, List<String> promotionCodeList,List<vlocity_cmt__PromotionItem__c> promoItemList) {
       Set<Id> promoItemIds = new Set<Id> ();
        for (vlocity_cmt__PromotionItem__c promoItem : promoItemList) {
            promoItemIds.add(promoItem.Id);
        }
        System.debug('++promoItemIds: '+ promoItemIds);
        // TODO: modificar query, definir WHERE, se deben obtener los pricelistentries de las promociones de tipo bundle y otro tipos. 
        // validar si vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null está correcto
        List<vlocity_cmt__PriceListEntry__c> priceListEntries = [
            SELECT Id, vlocity_cmt__PromotionId__c,vlocity_cmt__PromotionItemId__c,vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__IsOverride__c, vlocity_cmt__ProductId__r.Name,
                   vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, vlocity_cmt__DisplayText__c,
                   vlocity_cmt__PricingElementAmount__c,vlocity_cmt__PromotionId__r.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c,vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c,
                   vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__AdjustmentMethod__c,
                   vlocity_cmt__EffectiveFromDate__c
            FROM vlocity_cmt__PriceListEntry__c
            WHERE vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__PricingElementId__c != null
          //  AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            AND  vlocity_cmt__PromotionItemId__c IN :promoItemIds
            /*(( vlocity_cmt__ProductId__r.ProductCode IN :productCodeList  AND  vlocity_cmt__PromotionId__c IN :promotionIds ) 
                 OR  vlocity_cmt__PromotionItemId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :promotionCodeList 
                 OR  vlocity_cmt__PromotionItemId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :productCodeList  ) */ 
            AND ((vlocity_cmt__EffectiveFromDate__c <= TODAY AND (vlocity_cmt__EffectiveUntilDate__c >= TODAY OR vlocity_cmt__EffectiveUntilDate__c = null))
            OR (vlocity_cmt__EffectiveFromDate__c > TODAY) OR (vlocity_cmt__EffectiveFromDate__c = null and vlocity_cmt__EffectiveUntilDate__c = null ))
            WITH SECURITY_ENFORCED
        ];
        Map<Id, List<vlocity_cmt__PriceListEntry__c>> mapByPromoId = new Map<Id, List<vlocity_cmt__PriceListEntry__c>>();
        for (vlocity_cmt__PriceListEntry__c ple : priceListEntries) {
            if (!mapByPromoId.containsKey(ple.vlocity_cmt__PromotionItemId__c)) {
                mapByPromoId.put(ple.vlocity_cmt__PromotionItemId__c, new List<vlocity_cmt__PriceListEntry__c>());
            }
           // mapByPromoId.get(ple.vlocity_cmt__PromotionId__c).add(ple);
            mapByPromoId.get(ple.vlocity_cmt__PromotionItemId__c).add(ple);
        }
        System.debug('+++mapByPromoId: '+ mapByPromoId);
        return mapByPromoId;
    }
    
    private static Map<Id, List<vlocity_cmt__AttributeAssignment__c>> getAttributeAssignments(Set<Id> productIds, Map<String, Product2> productsByCode,Map<Id, Product2> childItemsByParentIdPromo) {
        
        // Step 1: Identify all products that are 'Bundle' and collect their Ids.
        Set<Id> bundleProductIds = new Set<Id>();
        for (Product2 prod : productsByCode.values()) {
            if (prod.vlocity_cmt__SpecificationSubType__c == 'Bundle') {
                bundleProductIds.add(prod.Id);
            }
        }
        
        System.debug('+++childItemsByParentIdPromo: '+ childItemsByParentIdPromo);
         // Loop through all the Product2 records (values) in the map
        for (Product2 prod : childItemsByParentIdPromo.values()) {
            // Add the Id of each Product2 record to the set
            bundleProductIds.add(prod.Id);
        }	
        
        // Step 2: If any bundles are found, query for their child product Ids.
        Set<Id> childProductIds = new Set<Id>();
        if (!bundleProductIds.isEmpty()) {
            List<vlocity_cmt__ProductChildItem__c> childItems = [
                SELECT vlocity_cmt__ChildProductId__c
                FROM vlocity_cmt__ProductChildItem__c
                WHERE vlocity_cmt__ParentProductId__c IN :bundleProductIds
                AND vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c = 'Plan'
                WITH SECURITY_ENFORCED
            ];
            for (vlocity_cmt__ProductChildItem__c childItem : childItems) {
                childProductIds.add(childItem.vlocity_cmt__ChildProductId__c);
            }
        }
        
        // Step 3: Consolidate all product Ids (parent and children) into a single set for the query.
        Set<Id> allRelevantProductIds = new Set<Id>();
        allRelevantProductIds.addAll(productIds);
        allRelevantProductIds.addAll(childProductIds);
        System.debug('[INFO] Total de IDs de productos para obtener atributos: ' + allRelevantProductIds.size());
        
        // Step 4: Perform a single, unified SOQL query to get all attribute assignments.
        List<vlocity_cmt__AttributeAssignment__c> attAssignments = [
            SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__AttributeCategoryId__r.Name, vlocity_cmt__AttributeId__r.Name,
                   vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c, vlocity_cmt__Value__c, vlocity_cmt__AttributeId__r.vlocity_cmt__ValueType__c,
                   vlocity_cmt__IsRequired__c, vlocity_cmt__IsReadOnly__c, vlocity_cmt__IsHidden__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__ObjectId__c IN :allRelevantProductIds
            WITH SECURITY_ENFORCED
            ORDER BY vlocity_cmt__AttributeId__r.Name
        ];
        Map<Id, List<vlocity_cmt__AttributeAssignment__c>> mapByObjectId = new Map<Id, List<vlocity_cmt__AttributeAssignment__c>>();
        for(vlocity_cmt__AttributeAssignment__c att : attAssignments) {
            if(!mapByObjectId.containsKey(att.vlocity_cmt__ObjectId__c)) {
                mapByObjectId.put(att.vlocity_cmt__ObjectId__c, new List<vlocity_cmt__AttributeAssignment__c>());
            }
            mapByObjectId.get(att.vlocity_cmt__ObjectId__c).add(att);
        }
        return mapByObjectId;
    }
    
    private static Map<Id, List<vlocity_cmt__CatalogProductRelationship__c>> getProductCompatibility(Set<Id> productIds, Map<Id, Product2> childItemsByParentIdPromo) {
        Set<Id> newProdCodeList = new Set<Id>();
        for (Product2 prod : childItemsByParentIdPromo.values()) {
            // Add the Id of each Product2 record to the set
            newProdCodeList.add(prod.Id);
        }
        
        List<vlocity_cmt__CatalogProductRelationship__c> catalogProdRels = [
            SELECT vlocity_cmt__Product2Id__c, vlocity_cmt__CatalogId__r.Name, vlocity_cmt__CatalogId__r.vlocity_cmt__CatalogCode__c,
                   vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.Name, vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.vlocity_cmt__Code__c,
                   vlocity_cmt__Product2Id__r.Name, vlocity_cmt__Product2Id__r.ProductCode, vlocity_cmt__CatalogId__r.vlocity_cmt__StartDateTime__c,
                   vlocity_cmt__CatalogId__r.vlocity_cmt__EndDateTime__c, vlocity_cmt__CatalogId__r.vlocity_cmt__IsActive__c
            FROM vlocity_cmt__CatalogProductRelationship__c
            WHERE (vlocity_cmt__Product2Id__c IN :productIds OR vlocity_cmt__Product2Id__c IN :newProdCodeList)
            WITH SECURITY_ENFORCED
        ];
        Map<Id, List<vlocity_cmt__CatalogProductRelationship__c>> mapByObjectId = new Map<Id, List<vlocity_cmt__CatalogProductRelationship__c>>();
        for (vlocity_cmt__CatalogProductRelationship__c cpr : catalogProdRels) {
            if (!mapByObjectId.containsKey(cpr.vlocity_cmt__Product2Id__c)) {
                mapByObjectId.put(cpr.vlocity_cmt__Product2Id__c, new List<vlocity_cmt__CatalogProductRelationship__c>());
            }
            mapByObjectId.get(cpr.vlocity_cmt__Product2Id__c).add(cpr);
        }
        return mapByObjectId;
    }
    
    private static Map<String, List<vlocity_cmt__PriceListEntry__c>> getProductPrices(List<String> prodCodeList, Map<Id, Product2> childItemsByParentIdPromo) {
        List<String> newProdCodeList = new List<String>();
        for (Product2 prod : childItemsByParentIdPromo.values()) {
            // Add the Id of each Product2 record to the set
            newProdCodeList.add(prod.ProductCode);
        }
        System.debug('++newProdCodeList: '+ newProdCodeList);
        List<vlocity_cmt__PriceListEntry__c> priceListEntries = [
            SELECT vlocity_cmt__ProductId__r.ProductCode,vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, vlocity_cmt__PriceListName__c, vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c, vlocity_cmt__DisplayText__c,
                   vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c,
                   vlocity_cmt__PricingElementAmount__c, vlocity_cmt__EffectiveFromDate__c
            FROM vlocity_cmt__PriceListEntry__c
            WHERE (vlocity_cmt__ProductId__r.ProductCode IN :prodCodeList OR vlocity_cmt__ProductId__r.ProductCode IN :newProdCodeList)
            AND vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__PricingElementId__c != null
            AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            AND vlocity_cmt__IsOverride__c	= false
            AND ((vlocity_cmt__EffectiveFromDate__c <= TODAY AND (vlocity_cmt__EffectiveUntilDate__c >= TODAY OR vlocity_cmt__EffectiveUntilDate__c = null))
            OR (vlocity_cmt__EffectiveFromDate__c > TODAY))
            WITH SECURITY_ENFORCED
        ];
        System.debug('++priceListEntries: '+ priceListEntries.size());

        Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByCode = new Map<String, List<vlocity_cmt__PriceListEntry__c>>();
        for (vlocity_cmt__PriceListEntry__c ple : priceListEntries) {
            String productCode = ple.vlocity_cmt__ProductId__r.ProductCode;
            if(!pricesByCode.containsKey(productCode)) {
                pricesByCode.put(productCode, new List<vlocity_cmt__PriceListEntry__c>());
            }
            pricesByCode.get(productCode).add(ple);
        }
        System.debug('++pricesByCode: '+ pricesByCode.size());
        
        return pricesByCode;
    }


     
    /**
     * @description Extracción y carga de datos de productos en CAT_ProductosExportados__c.
     * @return void
     */
      private static void extractAndLoadProducts(Map<String, Product2> productsByCode, Map<Id, List<vlocity_cmt__ProductChildItem__c>> childItemsByParentId, Map<Id, List<vlocity_cmt__RuleAssignment__c>> productRulesByObjectId, Map<String, vlocity_cmt__Promotion__c> promotionsByCode,Map<Id, Product2> childItemsByParentIdPromo) {
          List<CAT_ProductosExportados__c> productosExportados = new List<CAT_ProductosExportados__c>();
          Set<Id> productIdsFromPromoMap = new Set<Id>();

          // Loop through all the Product2 records (values) in the map
          for (Product2 prod : childItemsByParentIdPromo.values()) {
            // Add the Id of each Product2 record to the set
            productIdsFromPromoMap.add(prod.Id);
        	}	
          
          List<vlocity_cmt__ProductChildItem__c> childProducts = [SELECT Id, vlocity_cmt__ChildProductId__r.Name,vlocity_cmt__ChildProductId__r.ProductCode,vlocity_cmt__ParentProductId__r.ProductCode, vlocity_cmt__ParentProductId__c 
            														FROM vlocity_cmt__ProductChildItem__c
            														WHERE vlocity_cmt__ParentProductId__c IN :productIdsFromPromoMap
            														AND vlocity_cmt__ChildProductId__r.vlocity_cmt__Type__c = 'Plan'
            														WITH SECURITY_ENFORCED];
        Map<String, vlocity_cmt__ProductChildItem__c> childProductByParentProductCode = new Map<String, vlocity_cmt__ProductChildItem__c>();

        for (vlocity_cmt__ProductChildItem__c item : childProducts) {
            String childProductCode = item.vlocity_cmt__ParentProductId__r.ProductCode;
            childProductByParentProductCode.put(childProductCode, item);
        }
          
          
        System.debug('+++childProductByParentProductCode: ' + childProductByParentProductCode);
          // Se itera primero por el mapa de productos obtenidos
          for (Product2 product : productsByCode.values()) {
            CAT_ProductosExportados__c infoProdExportado = new CAT_ProductosExportados__c();
            infoProdExportado.CAT_NombreProducto__c = product.Name;
            infoProdExportado.CAT_CodigoProducto__c = product.ProductCode;
            infoProdExportado.CAT_DescripcionProducto__c = product.Description;
            infoProdExportado.CAT_DescripcionCortaProducto__c = product.Short_Description__c;
            infoProdExportado.CAT_FamiliaProducto__c = product.Family;
            infoProdExportado.CAT_TipoProducto__c = product.vlocity_cmt__Type__c;
            infoProdExportado.CAT_SubtipoProducto__c = product.vlocity_cmt__SubType__c;
            infoProdExportado.CAT_ProductoOrderable__c = product.vlocity_cmt__IsOrderable__c;
            infoProdExportado.CAT_ProductoActivo__c = product.IsActive;
            infoProdExportado.CAT_ProcesosNegocioProducto__c = product.CAT_Proceso_Negocio__c;
            infoProdExportado.CAT_CanalAsignado__c = product.CAT_Canales__c;
            infoProdExportado.CAT_PrecioOneTime__c = product.CAT_PrecioOneTime__c;
            infoProdExportado.CAT_Oferta_Retencion__c = product.CAT_Oferta_Retencion__c;
            
            if (product.vlocity_cmt__SellingStartDate__c != null) {
                infoProdExportado.CAT_InicioVigenciaProducto__c = product.vlocity_cmt__SellingStartDate__c;
            }
            if (product.vlocity_cmt__SellingEndDate__c != null) {
                infoProdExportado.CAT_FinVigenciaProducto__c = product.vlocity_cmt__SellingEndDate__c;
            }

            if (childItemsByParentId.containsKey(product.Id)) {
                infoProdExportado.CAT_PlanMovilBundle__c = childItemsByParentId.get(product.Id)[0].vlocity_cmt__ChildProductId__r.ProductCode;
            }

            if (productRulesByObjectId.containsKey(product.Id)) {
                vlocity_cmt__RuleAssignment__c rule = productRulesByObjectId.get(product.Id)[0];
                infoProdExportado.CAT_ReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.Name;
                infoProdExportado.CAT_DescripcionReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c;
            }

            productosExportados.add(infoProdExportado);
        }
          // se itera sobre el mapa de promocines de tipo bundle
          for (vlocity_cmt__Promotion__c promo : promotionsByCode.values()) {
              System.debug('++promoBundle');
            CAT_ProductosExportados__c infoProdExportado = new CAT_ProductosExportados__c();
            infoProdExportado.CAT_NombreProducto__c = promo.Name;
            infoProdExportado.CAT_CodigoProducto__c = promo.vlocity_cmt__Code__c;
            infoProdExportado.CAT_DescripcionProducto__c = promo.vlocity_cmt__Description__c;
            infoProdExportado.CAT_TipoProducto__c = promo.CAT_PromotionClass__c;
            infoProdExportado.CAT_SubtipoProducto__c = promo.CAT_Type__c;
            infoProdExportado.CAT_ProductoOrderable__c = promo.vlocity_cmt__IsOrderable__c;
            infoProdExportado.CAT_ProductoActivo__c = promo.vlocity_cmt__IsActive__c;
            infoProdExportado.CAT_ProcesosNegocioProducto__c = promo.CAT_Proceso_Negocio__c;
            infoProdExportado.CAT_CanalAsignado__c = promo.CAT_Canales__c;
            infoProdExportado.CAT_InicioVigenciaProducto__c = promo.vlocity_cmt__EffectiveStartDate__c;
            infoProdExportado.CAT_FinVigenciaProducto__c = promo.vlocity_cmt__EffectiveEndDate__c;
            infoProdExportado.CAT_Oferta_Retencion__c = promo.CAT_Oferta_Retencion__c;
  
            // plan o bundle??
            System.debug('++childItemsByParentIdPromo '+childItemsByParentIdPromo);
            if (childItemsByParentIdPromo.containsKey(promo.Id)) {
                Product2 prod2 = childItemsByParentIdPromo.get(promo.Id);
                infoProdExportado.CAT_PlanMovilBundle__c = childProductByParentProductCode.get(prod2.ProductCode).vlocity_cmt__ChildProductId__r.ProductCode;
                //infoProdExportado.CAT_PlanMovilBundle__c = childItemsByParentIdPromo.get(promo.Id).ProductCode;
            }

            if (productRulesByObjectId.containsKey(promo.Id)) { //rules para promocion
                vlocity_cmt__RuleAssignment__c rule = productRulesByObjectId.get(promo.Id)[0];
                infoProdExportado.CAT_ReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.Name;
                infoProdExportado.CAT_DescripcionReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c;
            }

            productosExportados.add(infoProdExportado);
        }
        if (!productosExportados.isEmpty()) {
            insert as user productosExportados;
            System.debug('Se crearon '+ productosExportados.size() + ' registros en CAT_ProductosExportados__c');
        }
      }    

    /**
     * @description Extracción y carga de datos de promociones en CAT_PromocionesExportadas__c.
     * @return void
     */
    private static void extractAndLoadPromotions(List<vlocity_cmt__PromotionItem__c> promoItemList, Map<Id, List<vlocity_cmt__PriceListEntry__c>> priceListEntriesByPromoId, Map<Id, List<vlocity_cmt__RuleAssignment__c>> promotionRulesByObjectId,Map<Id, List<vlocity_cmt__RuleAssignment__c>> pleByObjectId ) {
        List<CAT_PromocionesExportadas__c> promocionesExportadas = new List<CAT_PromocionesExportadas__c>();
        System.debug('++++pleByObjectId:'+ pleByObjectId);
        System.debug('++promoItemList.size() '+ promoItemList.size());
        for (vlocity_cmt__PromotionItem__c promoItem : promoItemList) {
            Id currentPromoId = promoItem.Id;
            List<vlocity_cmt__PriceListEntry__c> relatedPriceListEntries = priceListEntriesByPromoId.get(currentPromoId);
            
            if (relatedPriceListEntries != null && !relatedPriceListEntries.isEmpty()) {
                
                //promo items con pricelist entries asociados
                for (vlocity_cmt__PriceListEntry__c eachPricelistentry : relatedPriceListEntries) { 
                    CAT_PromocionesExportadas__c infoPromoExportada = new CAT_PromocionesExportadas__c();
                    System.debug('+++relatedPriceListEntries.size():' + relatedPriceListEntries.size());
                    System.debug('eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c: '+ eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c);
                    //CAT_PromocionesExportadas__c infoPromoExportada = new CAT_PromocionesExportadas__c();
                    
                    infoPromoExportada.CAT_NombrePromocion__c = promoItem.vlocity_cmt__PromotionId__r.Name;
                    infoPromoExportada.CAT_CodigoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c;
                    infoPromoExportada.CAT_DescripcionPromocion__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__Description__c;
                    infoPromoExportada.CAT_PromocionOrderable__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__IsOrderable__c;
                    infoPromoExportada.CAT_PromocionActivo__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__IsActive__c;
                    infoPromoExportada.CAT_TipoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Type__c;
                    infoPromoExportada.CAT_CardinalidadDefault__c = promoItem.vlocity_cmt__Quantity__c;
                    infoPromoExportada.CAT_CardinalidadMaxima__c = promoItem.vlocity_cmt__MaxQuantity__c;
                    infoPromoExportada.CAT_CardinalidadMinima__c = promoItem.vlocity_cmt__MinQuantity__c;
                    infoPromoExportada.CAT_InicioVigenciaPromocion__c = promoItem.vlocity_cmt__EffectiveFromDate__c;
                    infoPromoExportada.CAT_FinVigenciaPromocion__c = promoItem.vlocity_cmt__EffectiveUntilDate__c;
                    infoPromoExportada.CAT_TipoBeneficioPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c;
                    infoPromoExportada.CAT_DescPrimerMesPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscount__c;
                    infoPromoExportada.CAT_PcntPrimerMesPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscountPercent__c;
                    infoPromoExportada.CAT_ProcesosNegocioPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Proceso_Negocio__c;
                    infoPromoExportada.CAT_NombreProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.Name;
                    infoPromoExportada.CAT_CodigoProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.ProductCode;
                    infoPromoExportada.CAT_TipoProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c;
                    infoPromoExportada.CAT_CodigoListaPrecioPrecios__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
                    infoPromoExportada.CAT_CanalAsignadoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Canales__c;
                    infoPromoExportada.CAT_Descripcion__c = promoItem.vlocity_cmt__Description__c;
                    System.debug('oferta retencion: '+ promoItem.vlocity_cmt__PromotionId__r.CAT_Oferta_Retencion__c);
                    infoPromoExportada.CAT_Oferta_Retencion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Oferta_Retencion__c;                    
                
                    // Context Rules
                    if (promotionRulesByObjectId.containsKey(currentPromoId)) {
                        vlocity_cmt__RuleAssignment__c rule = promotionRulesByObjectId.get(currentPromoId)[0];
                        infoPromoExportada.CAT_ReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.Name;
                        infoPromoExportada.CAT_DescripcionReglaCtxProducto__c = rule.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c;
                    } 
                    //reglas elegibilidad pleByObjectId
                  //  if (relatedPriceListEntries != null && !relatedPriceListEntries.isEmpty()) {
                      //  for (vlocity_cmt__PriceListEntry__c eachPricelistentry : relatedPriceListEntries) {
                     System.debug('+++eachPricelistentry: '+ eachPricelistentry.Id);
                      if(pleByObjectId.containsKey(eachPricelistentry.Id)) {
                          Boolean hayRegla = true;
                          vlocity_cmt__RuleAssignment__c ruleInstance = pleByObjectId.get(eachPricelistentry.Id)[0];
                          System.debug('+++ruleInstance: '+ ruleInstance);
                          infoPromoExportada.CAT_NombreReglaElegibilidadProd__c = ruleInstance.vlocity_cmt__RuleId__r.Name;
                          infoPromoExportada.CAT_DescReglaElegProd__c = ruleInstance.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c;
                          System.debug('+++hayRegla: '+ hayRegla);
                      }
                    // PriceListEntry info
                    
                    infoPromoExportada.CAT_DisplayNameAjustePromocion__c = eachPricelistentry.vlocity_cmt__DisplayText__c;
                    infoPromoExportada.CAT_TipoAjuste__c = eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__AdjustmentMethod__c;
                    infoPromoExportada.CAT_ValorOverridePrecioPromocion__c = eachPricelistentry.vlocity_cmt__IsOverride__c;
                    infoPromoExportada.CAT_InicioVigenciaAjustePromocion__c = eachPricelistentry.vlocity_cmt__EffectiveFromDate__c;
                    infoPromoExportada.CAT_FinVigAj__c = eachPricelistentry.vlocity_cmt__EffectiveUntilDate__c;
                    infoPromoExportada.CAT_Frecuencia__c = eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c;
                    if(eachPricelistentry.vlocity_cmt__IsOverride__c){
                        infoPromoExportada.CAT_ValorAjustePrecioPromocion__c = eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c;
                    } else {
                        infoPromoExportada.CAT_ValorAjustePrecioPromocion__c = eachPricelistentry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c;
                    }
      
                    promocionesExportadas.add(infoPromoExportada);
                     //   }                    
                   // }                    
                }
            } else {
                CAT_PromocionesExportadas__c infoPromoExportada = new CAT_PromocionesExportadas__c();
                //promo item sin pricelistentry relacionado
                infoPromoExportada.CAT_CodigoListaPrecioPrecios__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
                infoPromoExportada.CAT_NombrePromocion__c = promoItem.vlocity_cmt__PromotionId__r.Name;
                infoPromoExportada.CAT_CodigoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c;
                infoPromoExportada.CAT_DescripcionPromocion__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__Description__c;
                infoPromoExportada.CAT_PromocionOrderable__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__IsOrderable__c;
                infoPromoExportada.CAT_PromocionActivo__c = promoItem.vlocity_cmt__PromotionId__r.vlocity_cmt__IsActive__c;
                infoPromoExportada.CAT_TipoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Type__c;
                infoPromoExportada.CAT_CardinalidadDefault__c = promoItem.vlocity_cmt__Quantity__c;
                infoPromoExportada.CAT_CardinalidadMaxima__c = promoItem.vlocity_cmt__MaxQuantity__c;
                infoPromoExportada.CAT_CardinalidadMinima__c = promoItem.vlocity_cmt__MinQuantity__c;
                infoPromoExportada.CAT_InicioVigenciaPromocion__c = promoItem.vlocity_cmt__EffectiveFromDate__c;
                infoPromoExportada.CAT_FinVigenciaPromocion__c = promoItem.vlocity_cmt__EffectiveUntilDate__c;
                infoPromoExportada.CAT_TipoBeneficioPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c;
                infoPromoExportada.CAT_DescPrimerMesPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscount__c;
                infoPromoExportada.CAT_PcntPrimerMesPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_FirstMonthDiscountPercent__c;
                infoPromoExportada.CAT_ProcesosNegocioPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Proceso_Negocio__c;
                infoPromoExportada.CAT_NombreProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.Name;
                infoPromoExportada.CAT_CodigoProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.ProductCode;
                infoPromoExportada.CAT_TipoProductoPromocion__c = promoItem.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c;
                infoPromoExportada.CAT_CanalAsignadoPromocion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Canales__c;
                infoPromoExportada.CAT_Oferta_Retencion__c = promoItem.vlocity_cmt__PromotionId__r.CAT_Oferta_Retencion__c; 
                promocionesExportadas.add(infoPromoExportada);
            }
            
        }
        if (!promocionesExportadas.isEmpty()) {
            insert as user promocionesExportadas;
            System.debug('Se crearon '+ promocionesExportadas.size() + ' registros en CAT_PromocionesExportadas__c');
        }
    }
    
     
    /**
     * @description Extracción y carga de datos de precios en CAT_PreciosProductosExportados__c.
     * @return void
     */
     private static void extractAndLoadProductPrices(Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode) {
        List<CAT_PreciosProductosExportados__c> preciosProdExportados = new List<CAT_PreciosProductosExportados__c>();
        Map<String, CAT_PreciosProductosExportados__c> consolidatedRecordsMap = new Map<String, CAT_PreciosProductosExportados__c>();
        System.debug('+++pricesByProductCode: ' + pricesByProductCode.size());
        for (String productCode : pricesByProductCode.keySet()) {
            List<vlocity_cmt__PriceListEntry__c> priceListEntries = pricesByProductCode.get(productCode);
            for (vlocity_cmt__PriceListEntry__c ple : priceListEntries) {
                String codePlusPriceList;
                if(ple.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c == 'Plan' ){
                    codePlusPriceList = ple.vlocity_cmt__ProductId__r.ProductCode + ple.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c +ple.vlocity_cmt__DisplayText__c;
                }else {
                    codePlusPriceList = ple.vlocity_cmt__ProductId__r.ProductCode + ple.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c +ple.vlocity_cmt__DisplayText__c+ple.vlocity_cmt__EffectiveFromDate__c;
                }
                String tipoProducto = ple.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c ;
                CAT_PreciosProductosExportados__c currentConsolidatedRecord;
                if (!consolidatedRecordsMap.containsKey(codePlusPriceList)) {
                    currentConsolidatedRecord = new CAT_PreciosProductosExportados__c();
                    currentConsolidatedRecord.CAT_CodigoProductoPrecios__c = ple.vlocity_cmt__ProductId__r.ProductCode;
                    currentConsolidatedRecord.CAT_ListaPrecioPrecios__c = ple.vlocity_cmt__PriceListName__c;
                    currentConsolidatedRecord.CAT_CodigoListaPrecioPrecios__c = ple.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
                    consolidatedRecordsMap.put(codePlusPriceList, currentConsolidatedRecord);
                } else {
                    currentConsolidatedRecord = consolidatedRecordsMap.get(codePlusPriceList);
                }

                if (ple.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c == 'Monthly' || (tipoProducto == 'Handset' || tipoProducto == 'Tech') ){
                    currentConsolidatedRecord.CAT_NombrePrecioSinImpuestosPrecios__c = ple.vlocity_cmt__DisplayText__c;
                    currentConsolidatedRecord.CAT_PrecioSinImpuestosPrecios__c = ple.vlocity_cmt__PricingElementAmount__c;
                    currentConsolidatedRecord.CAT_InicioVigenciaPrecioSinImpPrecios__c = ple.vlocity_cmt__EffectiveFromDate__c;
                } else {
                    currentConsolidatedRecord.CAT_NombrePrecioConImpuestosPrecios__c = ple.vlocity_cmt__DisplayText__c;
                    currentConsolidatedRecord.CAT_PrecioConImpuestosPrecios__c = ple.vlocity_cmt__PricingElementAmount__c;
                    currentConsolidatedRecord.CAT_InicioVigenciaPrecioConImpPrecios__c = ple.vlocity_cmt__EffectiveFromDate__c;
                }
            }
        }
        
        preciosProdExportados.addAll(consolidatedRecordsMap.values());
        
        if (!preciosProdExportados.isEmpty()) {
            insert as user preciosProdExportados;
            System.debug('Se crearon '+ preciosProdExportados.size() + ' registros en CAT_PreciosProductosExportados__c');
        }
    }    

    /**
     * @description Actualiza un registro de seguimiento de fallo en CAT_SeguimientoProductosExportados__c.
     * @param message El mensaje de error del log.
     * @return void
     */
    private static void createFailureLogRecord(String message, String objetoControlId, Id idLogRecord) {
        //  COMENTARIO: Lógica para actualizar el registro de seguimiento con el fallo 
        System.debug('[LOGGING] Registrando fallo: ' + message);
        CAT_Control_Interno_Digital__c logInterno = [SELECT Id FROM CAT_Control_Interno_Digital__c WHERE Id = :objetoControlId WITH SECURITY_ENFORCED LIMIT 1];
        CAT_SeguimientoProductosExportados__c logRecord = [SELECT Id FROM CAT_SeguimientoProductosExportados__c WHERE Id = :idLogRecord WITH SECURITY_ENFORCED LIMIT 1];
        logRecord.CAT_ObjetoSeguimiento__c = 'Salesforce con errores';
        logRecord.CAT_FechaFinSfSeguimiento__c = datetime.NOW();
        logRecord.CAT_ResultadoGlobalSeguimiento__c = 'Error';
        logInterno.CAT_Estado_Final__c = 'Error';
        update as user logInterno; 
        update as user logRecord; 
    

    }

// Clase de excepción personalizada para manejo de errores más específicos.
public class CAT_ExtractionException extends Exception {}
}