/*******************************************************************************
* Autor: hllanos
* Fecha: 2024-05-28
* Equipo: Pos-Ventas
* Descripcion: Utility class - Cambio de SIM
* History
<Date>            <Author>             <Description>             <Version>
2024-05-28        Hllanos               creacion                   01
2024-07-19        Federico Mandri       BUG 362739                 02
2024-09-17        Hllanos               RoamingDesactivacion       03
2025-04-04        MOlay                 HU414821 Cambio Plan       04
2025-05-14        MOlay                 HU552200 Modificacion de Datos  05
2025-05-20        Hllanos               Adding mergeListWithPosition method 06
2025-06-13        Hllanos               Adding validateHistoryRoboPerdida
2026-02-16        JAguilar              Change on merge by         08
                                        position method
2026-05-18        hllanos              calculateMidnightDates      09
                                        
***********************************************************************************/
global with sharing class PVU_CambioSimInterface implements vlocity_cmt.VlocityOpenInterface{
	class MyException extends Exception{}
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('buildRequestChildItemToCart')){
                Map<String, Object> response = buildRequestChildItemToCart(inputMap, outMap);
            }else if (methodName.Equals('getOrderItemsByOrderId')){
                Map<String, Object> response = getOrderItemsByOrder(inputMap, outMap);
            }else if (methodName.Equals('getOrderItemsByOrderIdCambioPlanAccInmediatas')){
                Map<String, Object> response = getOrderItemsCambioPlanAccInmediatas(inputMap, outMap);
            }else if (methodName.Equals('getPromosByOrderId')){
                Map<String, Object> response = getPromosByOrderId(inputMap, outMap);
            } else if (methodName.Equals('updateOrderItemsByOrderIdCesionContrato')){
                Map<String, Object> response = updateOrderItemsByOrderIdCesionContrato(inputMap, outMap);
            } else if (methodName.Equals('getOrdersByAssetAccount')){
                Map<String, Object> response = getOrdersByAssetAccount(inputMap, outMap);
            } else if (methodName.Equals('mergeListWithPosition')){
                Map<String, Object> response = mergeListWithPosition(inputMap, outMap);
            } else if (methodName.Equals('validateHistoryRoboPerdida')){
                Map<String, Object> response = validateHistoryRoboPerdida(inputMap, outMap);
            } else if (methodName.Equals('checkPromoCFMLast6Months')){
                Map<String, Object> response = checkPromoCFMLast6Months(inputMap, outMap);
            } else if (methodName.Equals('calculateMidnightDates')){
                Map<String, Object> response = calculateMidnightDates(inputMap, outMap);
            }
            
        } catch(Exception ex) {
            outMap.put('error', ex.getMessage()); 
            outmap.put('isSuccess', false);
            result = false; 
        }
        return result;
    }
    
    //20240719 - FM - BUG 362739 - Se modifica query para traer billing y service account desde la orden y no desde el asset
    global Map<String,Object> getOrderItemsByOrder(Map<String,Object> inputMap, Map<String,Object> outMap){
        system.debug('getOrderItemsByOrder>' + inputMap);
        String OrderId = (String)inputMap.get('OrderId');
        Map<String, Object> respMap = new Map<String, Object>();
        List<Object> listOrderItem = new List<Object>();
        
        for(OrderItem item : [SELECT Id, order.Type, order.FVU_OrderSubType__c, vlocity_cmt__AssetReferenceId__c,  vlocity_cmt__ParentItemId__c, vlocity_cmt__Product2Id__c, 
                              vlocity_cmt__Product2Id__r.Name, vlocity_cmt__Product2Id__r.ProductCode,vlocity_cmt__Product2Id__r.vlocity_cmt__Type__c, vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c, PriceBookEntryId,
                              vlocity_cmt__AssetId__c,vlocity_cmt__Action__c, vlocity_cmt__AttributeSelectedValues__c,
                              vlocity_cmt__AssetId__r.vlocity_cmt__AttributeSelectedValues__c,
                              vlocity_cmt__AssetId__r.vlocity_cmt__BillingAccountId__c, vlocity_cmt__AssetId__r.vlocity_cmt__ServiceAccountId__c,
                              Order.vlocity_cmt__DefaultBillingAccountId__c, Order.vlocity_cmt__DefaultServiceAccountId__c,vlocity_cmt__ReliesOnItemId__c, vlocity_cmt__Product2Id__r.Family, vlocity_cmt__RootItemId__c
                              FROM OrderItem 
                              WHERE OrderId =: OrderId WITH SECURITY_ENFORCED])
        {
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('AssetId', item.vlocity_cmt__AssetId__c);
            obj.put('Id', item.Id);
            obj.put('AssetReferenceId',item.vlocity_cmt__AssetReferenceId__c);
            obj.put('PricebookEntryId', item.PriceBookEntryId);
            obj.put('Product2Id',item.vlocity_cmt__Product2Id__c);
            obj.put('Action', item.vlocity_cmt__Action__c);
            obj.put('Product2Code', item.vlocity_cmt__Product2Id__r.ProductCode);
            obj.put('Product2Type', item.vlocity_cmt__Product2Id__r.vlocity_cmt__Type__c);
            obj.put('Product2SubType', item.vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c);
            if(item.vlocity_cmt__ParentItemId__c != null){obj.put('ParentItemId', item.vlocity_cmt__ParentItemId__c);}
            obj.put('AttributeSelectedValues', item.vlocity_cmt__AttributeSelectedValues__c);
            obj.put('AttributeSelectedValuesAsset', item.vlocity_cmt__AssetId__r.vlocity_cmt__AttributeSelectedValues__c);
            //20240719 - BUG 362739 - INICIO
            //if(item.vlocity_cmt__AssetId__r.vlocity_cmt__BillingAccountId__c != null){obj.put('BillingAccountId', item.vlocity_cmt__AssetId__r.vlocity_cmt__BillingAccountId__c);}
            //if(item.vlocity_cmt__AssetId__r.vlocity_cmt__ServiceAccountId__c != null){obj.put('ServiceAccountId', item.vlocity_cmt__AssetId__r.vlocity_cmt__ServiceAccountId__c);}
            if(item.Order.vlocity_cmt__DefaultBillingAccountId__c != null){obj.put('BillingAccountId', item.Order.vlocity_cmt__DefaultBillingAccountId__c);}
            if(item.Order.vlocity_cmt__DefaultServiceAccountId__c != null){obj.put('ServiceAccountId', item.Order.vlocity_cmt__DefaultServiceAccountId__c);}
            //20240719 - BUG 362739 - FIN
            obj.put('ReliesOnItem', item.vlocity_cmt__ReliesOnItemId__c);
            obj.put('ProductFamily', item.vlocity_cmt__Product2Id__r.Family);
            obj.put('RootItemId', item.vlocity_cmt__RootItemId__c);
            obj.put('OrderType', item.order.Type);
            obj.put('OrderSubType', item.order.FVU_OrderSubType__c);
            listOrderItem.add(obj);
        }
        outMap.put('EndProcess', 'success');
        respMap.put('OrderItem', listOrderItem);
        outMap.put('Detail', respMap);
        system.debug('outMap>' + outMap);
        return outMap;
    }
    
    //Construye el request para consumir el servicio PostItemRequest para insentar.
    global Map<String,Object> buildRequestChildItemToCart(Map<String,Object> inputMap, Map<String,Object> outMap){
        system.debug('buildRequestChildItemToCart:' + inputMap);
        Map<String, PricebookEntry> MapPriceBookentries = new Map<String, PricebookEntry>();
        Map<String, Object> parentProductInfo = new Map<String, Object>();
        String OrderId;
        Map<String, Object> ProductInfo = (Map<String, Object>)inputMap.get('Product');
        
        system.debug('ProductInfo:' + ProductInfo);
        try{
            OrderId = (String)inputMap.get('OrderId');
            
            if(inputMap.get('ParentProduct') != null){
                parentProductInfo = (Map<String, Object>)inputMap.get('ParentProduct');
                system.debug('parentProductInfo:' + parentProductInfo);
            }
            //get pricebookentries for child product
            List<PricebookEntry> priceBookentries = [SELECT Id, Pricebook2.Name, Product2Id, Product2.Name, Product2.ProductCode, Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SubType__c
                                                     FROM PricebookEntry 
                                                     WHERE Product2.ProductCode =: (String)ProductInfo.get('Product2Code') WITH SECURITY_ENFORCED limit 1];
            
            for(PricebookEntry item: priceBookentries){
                MapPriceBookentries.put(item.Product2.ProductCode , item);
            }
            PriceBookEntry pricebookentry = MapPriceBookentries.get((String)ProductInfo.get('Product2Code'));
            system.debug('pricebookentry:' + pricebookentry);
            
            //get order items
            Map<String, OrderItem> mapOrderItemsByProductCode = new Map<String, OrderItem>();
            Map<String, OrderItem> mapOrderItemsBySubtype = new Map<String, OrderItem>();
            List<OrderItem> OrderItems = [SELECT Id, vlocity_cmt__AssetReferenceId__c,  vlocity_cmt__ParentItemId__c, vlocity_cmt__Product2Id__c, vlocity_cmt__Product2Id__r.Name, vlocity_cmt__Product2Id__r.ProductCode,vlocity_cmt__Product2Id__r.vlocity_cmt__Type__c, vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c, vlocity_cmt__ProductHierarchyPath__c  
                                          FROM OrderItem 
                                          WHERE OrderId =: OrderId WITH SECURITY_ENFORCED];
            
            for(OrderItem orderItem: OrderItems){
                mapOrderItemsByProductCode.put(orderItem.vlocity_cmt__Product2Id__r.ProductCode, orderItem);
                //mapOrderItemsBySubtype.put(orderItem.vlocity_cmt__Product2Id__r.vlocity_cmt__Type__c + '_' + orderItem.vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c , orderItem);
            }
            
            //Child record
            system.debug('mapOrderItemsByProductCode:' + mapOrderItemsByProductCode);
            OrderItem parentItem = new  OrderItem();
            if(inputMap.get('ParentProduct') != null){
                parentItem = mapOrderItemsByProductCode.get((String)parentProductInfo.get('Product2Code'));
                system.debug('parentItem:' + parentItem);
            }
            
            OrderItem Item = mapOrderItemsByProductCode.get((String)ProductInfo.get('Product2Code')); 
            system.debug('Item:' + Item);
            
            //Parent record
            Map<String, String> ParentProduct = new Map<String, String>();
            List<Map<String, String>> ParentProductList = new List<Map<String, String>>();
            Map<String, Map<String, List<Map<String, String>>>> parentRecord = new Map<String, Map<String, List<Map<String, String>>>>();
            Map<String, List<Map<String, String>>> records = new Map<String, List<Map<String, String>>>();
            if(inputMap.get('ParentProduct') != null){
                ParentProduct.put('Id', (String)parentItem.Id);
                ParentProduct.put('ProductId', (String)parentItem.vlocity_cmt__Product2Id__c);
                ParentProduct.put('productHierarchyPath', (String)parentItem.vlocity_cmt__ProductHierarchyPath__c);
                ParentProduct.put('ParentLineItemId',  (String)parentItem.Id );
                ParentProduct.put('itemType', 'childProduct' );
                ParentProductList.add(ParentProduct);
                records.put('records', ParentProductList);
            }
            
            //Build request
            Map<String, Object> request = new Map<String, Object>();
            Map<String, Object> operation = new Map<String, Object>();
            List<Map<String, Object>> Items = new List<Map<String, Object>>();
            Map<String, Object> requestCpqAppHandler = new Map<String, Object>();
            Map<String, Object> respCpqAppHandler = new Map<String, Object>();
            Map<String, Object> optionsMap = new Map<String, Object>();
            if(inputMap.get('fieldsToUpdate') != null){operation.put('fieldsToUpdate', inputMap.get('fieldsToUpdate'));}
            operation.put('itemId', (String)pricebookentry.Id);
            //operation.put('quantity', 1);
            if(inputMap.get('ParentProduct') != null){
                operation.put('parentId', (String)parentItem.Id);
            	operation.put('productHierarchyPath', (String)parentItem.Id);
                operation.put('parentRecord', records);
            }
           
            Items.add(operation);
            request.put('items', Items);
            request.put('cartId', OrderId); 
            //request.put('price', false);
            
            //output
            outMap.put('request', request); 
            
        }catch(Exception ex){
            system.debug('Error - ADD Cart Operation  ('+ ProductInfo.get('Product2Code') + ')' + ex.getMessage());
             outMap.put('EndProcess', 'fail');
        }
        
        
        system.debug('outMap>' + outMap);
        outMap.put('EndProcess', 'success');
        outMap.put('Details', 'OK');

        return outmap;
    }

    /* Dev: Mariana Olay / Sara Garrido
    * Descripcion: Metodo retorna los OrderItems de la Orden Antigua con estado Falla Ejecución/Cliente desiste solicitud de un cambio de Plan
    * Fecha: 01/04/2025
    * Input: OrderId
    * Output: Lista de OrderItems Orden Cambio de Plan.
    */
     global Map<String,Object> getOrderItemsCambioPlanAccInmediatas(Map<String,Object> inputMap, Map<String,Object> outMap){
        system.debug('getOrderItemsCambioPlanAccInmediatas>' + inputMap);
        String OrderId = (String)inputMap.get('OrderId');
        Map<String, Object> respMap = new Map<String, Object>();
        List<Object> listOrderItemAll = new List<Object>();
        List<Object> listOrderItem = new List<Object>();
        String productCodePlan = '';
        
        for(OrderItem item : [SELECT Id, Product2.Name, Product2.ProductCode, Product2.vlocity_cmt__Type__c, vlocity_cmt__Action__c,
                                    vlocity_cmt__ReliesOnItemId__c, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__ParentItemId__c,
                                    vlocity_cmt__SubAction__c
                                FROM OrderItem  
                                WHERE OrderId =: OrderId  
                                AND (vlocity_cmt__ParentItemId__c = null OR vlocity_cmt__ReliesOnItemId__c != null)
                                WITH SECURITY_ENFORCED])
        {
            if (item.Product2.vlocity_cmt__Type__c == 'Plan' && item.vlocity_cmt__Action__c == 'Add') {
                productCodePlan = item.Product2.ProductCode;
            } else {
                if(item.vlocity_cmt__Action__c == 'Add') {
                    Map<String, Object> obj = new Map<String, Object>();
                    obj.put('Id', item.Id);
                    obj.put('AssetReferenceId',item.vlocity_cmt__AssetReferenceId__c);
                    obj.put('Product2Code', item.Product2.ProductCode);
                    obj.put('SubAction', item.vlocity_cmt__SubAction__c);
                    listOrderItem.add(obj);
                }
                Map<String, Object> objAll = new Map<String, Object>();
                objAll.put('Id', item.Id);
                objAll.put('AssetReferenceId',item.vlocity_cmt__AssetReferenceId__c);
                objAll.put('Product2Code', item.Product2.ProductCode);
                objAll.put('SubAction', item.vlocity_cmt__SubAction__c);
                objAll.put('Action', item.vlocity_cmt__Action__c);
                listOrderItemAll.add(objAll);
            }
        }
         
         respMap.put('OrderItemsAdd', listOrderItem);
         respMap.put('OrderItemsAll', listOrderItemAll);
         respMap.put('productCodePlan', productCodePlan);
         outMap.put('EndProcess', 'success');
         outMap.put('Detail', respMap);

        system.debug('outMap>' + outMap);
        return outMap;
    }

    /* Dev: Mariana Olay / Sara Garrido
    * Descripcion: Metodo retorna las promos aplicadas a la orden
    * Fecha: 01/04/2025
    * Input: OrderId
    * Output: Lista de PromoItemsId para Orden Cambio de Plan Acciones Inmediatas.
    */
     global Map<String,Object> getPromosByOrderId(Map<String,Object> inputMap, Map<String,Object> outMap){
        System.debug('getPromosByOrderId>' + inputMap);
        String OrderId = (String)inputMap.get('OrderId');
        Map<String, Object> respMap = new Map<String, Object>();
        List<Object> listPromoItems = new List<Object>();
        List<Object> listPromoItemsObj = new List<Object>();
        Set<Id> idPromosSet = new Set<Id>();
        Map<String, vlocity_cmt__OrderAppliedPromotionItem__c> idPromosMap = new Map<String, vlocity_cmt__OrderAppliedPromotionItem__c>();
        
        for(vlocity_cmt__OrderAppliedPromotionItem__c item : [SELECT Id, vlocity_cmt__OrderItemId__r.OrderId, vlocity_cmt__OrderItemId__r.vlocity_cmt__Action__c,
                                                                vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__c,vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c, vlocity_cmt__OrderItemId__r.Product2.ProductCode,vlocity_cmt__OrderItemId__r.Product2.vlocity_cmt__Type__c, vlocity_cmt__OrderItemId__r.vlocity_cmt__ParentItemId__c 
                                                              	FROM vlocity_cmt__OrderAppliedPromotionItem__c 
                                                                WHERE vlocity_cmt__OrderItemId__r.OrderId = :OrderId 
                                                                AND vlocity_cmt__OrderItemId__r.vlocity_cmt__Action__c = 'Add' 
                                                                WITH SECURITY_ENFORCED ])
        {
            idPromosSet.add(item.vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__c);
            if(idPromosMap.get(item.Id) == null){
                idPromosMap.put(item.Id, item);
            }
        }
         
        for (Id idPromo : idPromosSet) {
            Map<String, Object> obj = new Map<String, Object>();
            obj.put('promoId', idPromo);
            listPromoItems.add(obj);
        }
         for (vlocity_cmt__OrderAppliedPromotionItem__c promoItem : idPromosMap.values()) {
             Map<String, Object> obj = new Map<String, Object>();
             obj.put('promotionId', promoItem.vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__c);
             obj.put('productCode', promoItem.vlocity_cmt__OrderItemId__r.Product2.ProductCode);
             obj.put('promotionCode', promoItem.vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c);
             obj.put('productType', promoItem.vlocity_cmt__OrderItemId__r.Product2.vlocity_cmt__Type__c); 
             obj.put('parentItemId', promoItem.vlocity_cmt__OrderItemId__r.vlocity_cmt__ParentItemId__c); 
             listPromoItemsObj.add(obj);
         }
         
         respMap.put('listPromoIds', listPromoItems);
         respMap.put('listPromo', listPromoItemsObj);
         outMap.put('EndProcess', 'success');
         outMap.put('Detail', respMap);

        System.debug('outMap>' + outMap);
        return outMap;
    }

    /* Dev: Mariana Olay / Sara Garrido
    * Descripcion: Metodo actualiza las GlobalKeys de la Orden generada para Cesión de Contrato
    * Fecha: 05/05/2025
    * Input: OrderId, ListNewGlobalKeys
    * Output: Booleano si se fueron actualizados o no los orden items
    */
    global Map<String,Object> updateOrderItemsByOrderIdCesionContrato(Map<String,Object> inputMap, Map<String,Object> outMap){
        String OrderId = (String)inputMap.get('OrderId');
        List<Object> listGlobalKeys = (List<Object>)inputMap.get('ListNewGlobalKeys');
        Map<String, String> globalKeysMap = new Map<String, String>();
        List<OrderItem> listOrderItem = [SELECT Id, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__RootItemId__c, vlocity_cmt__ParentItemId__c,  vlocity_cmt__ReliesOnItemId__c
                                        FROM OrderItem 
                                        WHERE OrderId =: OrderId 
                                        WITH SECURITY_ENFORCED];

        for (Integer i = 0; i < listOrderItem.size(); i++) {
            globalKeysMap.put(listOrderItem[i].vlocity_cmt__AssetReferenceId__c, (String)listGlobalKeys[i]);
        }

        for (OrderItem item : listOrderItem) {
            if (item.vlocity_cmt__AssetReferenceId__c != null && globalKeysMap.containsKey(item.vlocity_cmt__AssetReferenceId__c)) {
                item.vlocity_cmt__AssetReferenceId__c = globalKeysMap.get(item.vlocity_cmt__AssetReferenceId__c);
            }
            if (item.vlocity_cmt__RootItemId__c != null && globalKeysMap.containsKey(item.vlocity_cmt__RootItemId__c)) {
                item.vlocity_cmt__RootItemId__c = globalKeysMap.get(item.vlocity_cmt__RootItemId__c);
            }
            if (item.vlocity_cmt__ReliesOnItemId__c != null && globalKeysMap.containsKey(item.vlocity_cmt__ReliesOnItemId__c)) {
                item.vlocity_cmt__ReliesOnItemId__c = globalKeysMap.get(item.vlocity_cmt__ReliesOnItemId__c);
            }
            if (item.vlocity_cmt__ParentItemId__c != null && globalKeysMap.containsKey(item.vlocity_cmt__ParentItemId__c)) {
                item.vlocity_cmt__ParentItemId__c = globalKeysMap.get(item.vlocity_cmt__ParentItemId__c);
            }
        }

        try {
            update as system listOrderItem;
            outMap.put('Response', 'success');
        } catch (Exception e) {
            outMap.put('Response', 'fail');
        }
        return outMap;
    }
    
    /* Dev: Mariana Olay / Silvia Tovar
    * Descripcion: Metodo retorna los Id's de las Orden relacionada a cada Asset Activo de un Cliente.
    * Fecha: 14/05/2025
    * Input: AccountId
    * Output: Lista de Ordenes para Modificacion de Datos - Envio de Contrato.
    */
     global Map<String,Object> getOrdersByAssetAccount(Map<String,Object> inputMap, Map<String,Object> outMap){
        String accountId = (String)inputMap.get('AccountId');
        Map<String, Object> respMap = new Map<String, Object>();
        List<Object> listOrderByAssetObj = new List<Object>();
        Map<String, Asset> idOrdersMap = new Map<String, Asset>();
        
        for(Asset asset : [SELECT Id, RootAssetId, Name, Status, AccountId, Account.Name, Product2.vlocity_cmt__Type__c, vlocity_cmt__OrderId__c, vlocity_cmt__OrderId__r.Id,
                                 vlocity_cmt__OrderId__r.Status, vlocity_cmt__OrderId__r.Type, vlocity_cmt__OrderId__r.FVU_OrderSubType__c 
                          FROM Asset 
                          WHERE Product2.vlocity_cmt__Type__c = 'Plan' AND vlocity_cmt__OrderId__r.Status = 'Activated' AND Status = 'Active' AND 
                                vlocity_cmt__SubscriptionId__r.vlocity_cmt__Status__c = 'Active' AND Product2.vlocity_cmt__SpecificationSubType__c = 'Simple' 
                                AND AccountId =: accountId
                                WITH SECURITY_ENFORCED])
        {
            if(!idOrdersMap.containsKey(asset.vlocity_cmt__OrderId__r.Id)) {
            	idOrdersMap.put(asset.vlocity_cmt__OrderId__r.Id, asset);
            }
        }
         for (Asset assetItem : idOrdersMap.values()) {
             Map<String, Object> obj = new Map<String, Object>();
             obj.put('orderId', assetItem.vlocity_cmt__OrderId__r.Id);
             obj.put('assetId', assetItem.Id);
             obj.put('assetName', assetItem.Name); 
             listOrderByAssetObj.add(obj);
         }
         
         respMap.put('listOrdersByAsset', listOrderByAssetObj);
         outMap.put('EndProcess', 'success');
         outMap.put('Detail', respMap);

        System.debug('outMap>' + outMap);
        return outMap;
    }
    
    /* Dev: hllanos
    * Descripcion: Metodo para hacer mergue de listas con keys duplicados
    * Fecha: 19/05/2025
    * Input: listDevices, listDevices
    * Output: merge list
    */
     global Map<String,Object> mergeListWithPosition(Map<String,Object> inputMap, Map<String,Object> outMap){
         system.debug('calling mergeListWithPosition: listDevices=>' +  inputMap.get('listDevices') + '    , listProducts=>' + inputMap.get('listProducts'));
         Map<String, Object> respMap = new Map<String, Object>();
         List<Map<String, Object>> listMerge= new List<Map<String, Object>>();
         try{
             List<Object> listDevicesObj = (List<Object>)inputMap.get('listDevices');
             List<Object> listProductsObj = (List<Object>)inputMap.get('listProducts');
             Map<String, String> usedPositions = new Map<String, String>();
             List<Map<String, Object>> listProducts= new List<Map<String, Object>>();
             List<Map<String, String>> listSerials= new List<Map<String, String>>();
             
             
             for(Object obj: listProductsObj){
                 Map<String, Object> prd = (Map<String, Object>) obj;
                 Map<String, Object> newEntry = new Map<String, Object>();
                 newEntry.put('productCode', (String) prd.get('productCode'));
                 newEntry.put('position', (String)prd.get('position'));
                 newEntry.put('sequence', (Integer)prd.get('sequence'));
                 listProducts.add(newEntry);
             }
             
             for(Object obj: listDevicesObj){
                 Map<String, Object> device = (Map<String, Object>) obj;
                 String devicePrdCode = (String) device.get('Product2CodeOrderItemRoot');
                 String deviceId = (String) device.get('Id');
                 for(Map<String, Object> item : listProducts){
                     String code = (String) item.get('productCode'); 
                     String position = (String) item.get('position'); 
                     Integer sequence = (Integer) item.get('sequence');
                
                // New logic - TMF API: verify if the position is used
                // Only reuse position if the productCode is the same
                String usedProductCode = usedPositions.get(position);
                Boolean canUsePosition = (usedProductCode == null || usedProductCode == code);
                
                if(devicePrdCode == code && canUsePosition){
                         Map<String, Object> newEntry = new Map<String, Object>();
                         newEntry.put('Product2Code', devicePrdCode);
                         newEntry.put('position', position);
                         newEntry.put('sequence', sequence);
                         newEntry.put('Id', deviceId);
                         listMerge.add(newEntry);
                         usedPositions.put(position, code); // Save the productCode associated with this position
                         break;
                     }
                 }
             }
         }catch(Exception ex){
             system.debug('Error:' + ex.getMessage());
             outMap.put('EndProcess', 'fail');
             outMap.put('Detail', ex.getMessage());
             return outMap;
         }
         
         respMap.put('listMerge', listMerge);
         outMap.put('EndProcess', 'success');
         outMap.put('Detail', respMap);

        System.debug('outMap>' + outMap);
        return outMap;
    }
    
    /* Dev: hllanos
    * Descripcion: Reinstalacion - Metodo para validar si existe una orden de suspension robo/perdida antes de una orden de desactivacion
    * Fecha: 13/06/2025
    * Output: merge list
    */
    global Map<String,Object> validateHistoryRoboPerdida(Map<String,Object> inputMap, Map<String,Object> outMap){
        system.debug('validateHistoryRoboPerdida:' + inputMap);
        String assetIdPlan = (String)inputMap.get('AssetId');
        Map<String, Object> respMap = new Map<String, Object>();
        List<OrderItem> listOrders = new List<OrderItem>();
        Map<Integer, OrderItem> mapOrders = new Map<Integer, OrderItem>();
        try{
            listOrders =  [SELECT Id, vlocity_cmt__AssetId__c, Product2.name, OrderId, vlocity_cmt__RequestDate__c,Order.Type,Order.FVU_OrderSubType__c,order.Status 
                           FROM OrderItem 
                           WHERE vlocity_cmt__AssetId__c =:assetIdPlan  AND order.vlocity_cmt__OrderStatus__c ='Activated' 
                           WITH SECURITY_ENFORCED
                           order by CreatedDate  desc LIMIT 10
                           ];
            
            Integer index = 0;
            Integer indexLastCancelation = 0;
            for(OrderItem item: listOrders){
                mapOrders.put(index, item);
                if(item.Order.Type == 'Cancelacion'){ indexLastCancelation = index; }
                index++;
            }
            if(mapOrders.get(indexLastCancelation + 1) != null && mapOrders.get(indexLastCancelation + 1).Order.Type == 'Suspension'  && mapOrders.get(indexLastCancelation + 1).Order.FVU_OrderSubType__c == 'Robo_Perdida' ){
                respMap.put('validarOrdeRoboPerdida', true);
            }else{
                respMap.put('validarOrdeRoboPerdida', false);
            }
        }catch(Exception ex){
            system.debug('Error:' + ex.getMessage());
            outMap.put('EndProcess', 'fail');
            outMap.put('Detail', ex.getMessage());
            respMap.put('validarOrdeRoboPerdida', false);
            return outMap;
        }
        outMap.put('EndProcess', 'success');
        outMap.put('Detail', respMap);
        System.debug('outMap>' + outMap);
        return outMap;
    }
    
    /* Dev: hllanos
    * Descripcion: Valida si existe una promocion de clase CFM reciente
    * Fecha: 15/12/2025
    * Output: Map
    */
    global Map<String,Object> checkPromoCFMLast6Months(Map<String,Object> inputMap, Map<String,Object> outMap){
        system.debug('checkPromoCFMLast6Months:' + inputMap);
        String assetRootId = (String)inputMap.get('AssetRootId');
        Boolean checkPromoCFMLast6Months = true;
        Map<String, Object> respMap = new Map<String, Object>();
        List<vlocity_cmt__AccountAppliedPromotionItem__c> listAccountPromoItems = new List<vlocity_cmt__AccountAppliedPromotionItem__c>();
        
        //Metadata con cantidad de meses
        InterfaceSettings__mdt Retencion_MesesAntiguedadCFM = [SELECT DeveloperName, IdCode__c FROM InterfaceSettings__mdt WHERE DeveloperName= 'Retencion_MesesAntiguedadCFM' LIMIT 1];
        
        try{

            listAccountPromoItems =  [SELECT Id, 
                                      CreatedDate, 
                                      vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__c,
                                      vlocity_cmt__appliedpromotionid__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__r.vlocity_cmt__TotalDuration__c, 
                                      vlocity_cmt__appliedpromotionid__r.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c, 
                                      vlocity_cmt__appliedpromotionid__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__r.vlocity_cmt__TotalDurationUoM__c
                                       FROM vlocity_cmt__AccountAppliedPromotionItem__c 
                                       WHERE vlocity_cmt__AssetId__c =: assetRootId
                                       AND vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = 'Obsequios de CFM'];
            
            for(vlocity_cmt__AccountAppliedPromotionItem__c promoItem : listAccountPromoItems){
                Date FechaCreacionPromo = promoItem.CreatedDate.date();
                if(
                    promoItem.vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__c != null &&
                    promoItem.vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__r.vlocity_cmt__TotalDurationUoM__c == 'Month'
                ){
                    Integer mesesParaVencimiento = (Integer) promoItem.vlocity_cmt__AppliedPromotionId__r.vlocity_cmt__PromotionId__r.vlocity_cmt__DurationTimePlanId__r.vlocity_cmt__TotalDuration__c;
                    Date promo_FechaVencimiento = FechaCreacionPromo.addMonths(mesesParaVencimiento);
                    Date promo_FechaVenciminetoMasMesesRetencion = promo_FechaVencimiento.addMonths(Integer.valueOf(Retencion_MesesAntiguedadCFM.IdCode__c));
                    if(Date.today() > promo_FechaVenciminetoMasMesesRetencion){
                        checkPromoCFMLast6Months = false;
                    }  
                }else{
                    checkPromoCFMLast6Months = true;
                }
            }
            
        }catch(Exception ex){
            system.debug('Error:' + ex.getMessage());
            outMap.put('EndProcess', 'fail');
            outMap.put('Detail', ex.getMessage());
            respMap.put('HasPromoCFMLast6Months', true);
            return outMap;
        }
        respMap.put('HasPromoCFMLast6Months', checkPromoCFMLast6Months);
        outMap.put('EndProcess', 'success');
        outMap.put('Detail', respMap);
        System.debug('outMap>' + outMap);
        return outMap;
    }
    
    private Map<String, Object> calculateMidnightDates(Map<String, Object> input, Map<String, Object> output) {
        try {
            // 1. Obtener parámetros de entrada desde el IP
            String orderId = (String) input.get('orderId');
            // Se espera que envíes "HH:mm" (ej. "22:00") desde el IP en lugar de minutos enteros
            String timeCheckout = (String) input.get('minutesCheckout'); 
            String timeSOM = (String) input.get('minutesSOM');      
            
            String requestedDateStr = (String) input.get('requestedDate'); 
            Date baseDate;
            
            // Validar que vengan las horas
            if (String.isBlank(timeCheckout) || String.isBlank(timeSOM)) {
                output.put('EndProcess', 'error');
                output.put('error', 'Los parámetros timeCheckout y timeSOM ("HH:mm") son obligatorios.');
                return output;
            }
            
            if (String.isNotBlank(requestedDateStr)) {
                // MODO DIRECTO:
                baseDate = Date.valueOf(requestedDateStr.substring(0, 10));
            } else {
                // MODO ORDEN
                if (String.isBlank(orderId)) {
                    output.put('EndProcess', 'error');
                    output.put('error', 'El orderId es obligatorio si no se envía requestedDate.');
                    return output;
                }
                
                Order ord = [SELECT Id, vlocity_cmt__RequestedStartDate__c FROM Order WHERE Id = :orderId LIMIT 1];
                
                if (ord.vlocity_cmt__RequestedStartDate__c == null) {
                    output.put('EndProcess', 'error');
                    output.put('error', 'El campo RequestedStartDate está vacío en la Orden.');
                    return output;
                }
                
                Object requestedDateObj = ord.vlocity_cmt__RequestedStartDate__c;
                if (requestedDateObj instanceof Datetime) {
                    baseDate = ((Datetime)requestedDateObj).dateGmt(); // dateGmt() para evitar el desfase
                } else {
                    baseDate = (Date)requestedDateObj;
                }
            }
            
            // 2. Restar UN DÍA a la fecha base
            Date previousDay = baseDate.addDays(-1);
            
            // 3. Extraer la hora y los minutos de los parámetros "HH:mm"
            List<String> partsCheckout = timeCheckout.split(':');
            List<String> partsSOM = timeSOM.split(':');
            
            Integer hourCheckoutCOL = Integer.valueOf(partsCheckout[0]);
            Integer minCheckout     = Integer.valueOf(partsCheckout[1]);
            Integer hourSOMCOL      = Integer.valueOf(partsSOM[0]);
            Integer minSOM          = Integer.valueOf(partsSOM[1]);

            // Convertir hora Colombia a UTC (COL = UTC - 5)
            Integer hourCheckoutUTC = Math.mod(hourCheckoutCOL + 5, 24);
            Integer hourSOMUTC      = Math.mod(hourSOMCOL      + 5, 24);

            // Si la hora UTC < 5 significa que en Colombia todavía es el día anterior
            // (ej: 22 COL → 03 UTC), por lo que se aplica sobre baseDate y no previousDay
            Date targetDayCheckout = (hourCheckoutUTC < 5) ? baseDate : previousDay;
            Date targetDaySOM      = (hourSOMUTC      < 5) ? baseDate : previousDay;
            DateTime adjustedDate1 = DateTime.newInstanceGmt(targetDayCheckout.year(), targetDayCheckout.month(), targetDayCheckout.day(), hourCheckoutUTC, minCheckout, 0);
            DateTime adjustedDate2 = DateTime.newInstanceGmt(targetDaySOM.year(),      targetDaySOM.month(),      targetDaySOM.day(),      hourSOMUTC,      minSOM,      0);
            
            String dateFormat = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
            
            // 5. Asignar al Output
            output.put('fechaAjustadaCheckout', adjustedDate1.formatGMT(dateFormat));
            output.put('fechaAjustadaSOM', adjustedDate2.formatGMT(dateFormat));
            output.put('EndProcess', 'success');
            
            return output;
            
        } catch(Exception e) {
            output.put('EndProcess', 'error');
            output.put('error', e.getMessage());
            return output;
        }
    }

}