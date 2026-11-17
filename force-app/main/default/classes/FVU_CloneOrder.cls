/**--------------------------------------------------------------------------------------------------------------

Author:         Marina de Morais - mdemorais@salesforce.com
Company:        Salesforce.com
Description:    Clone Order and Related Records
Code Coverage:  90%
History
<Date>            <Author>             <Description>                                            <Version>
17-Sep-24         Marina               RETOMA - PORTABILIDAD - DUPLICAR ORDEN AUTOMATICA          Inicial version

----------------------------------------------------------------------------------------------------------------**/

global class FVU_CloneOrder implements vlocity_cmt.VlocityOpenInterface2 {

    private final static String CLOSED_ORDER_STATUS = 'Cerrada Perdida';
    private final static String ORDER_CLOSING_REASON = 'Duplicada por Retoma de Portabilidad';

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        try {
            if (methodName == 'cloneOrder') {
                return cloneOrder(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug('Error in invoke method: ' + e.getMessage());
            throw e;
        }
        return false;
    }

    public Boolean cloneOrder(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Id recordId = (Id) inputMap.get('recordId');
        String clonedOrderStatus = (String) inputMap.get('status');

        // Validate input
        if(clonedOrderStatus == null) {
            outputMap.put('error', 'Invalid input.');
            return false;
        }
        
        // Get original order
        Order originalRecord =  (Order) getSingleRecord(recordId, new Order(), 'Id', 'OpportunityId');
        if(originalRecord == null) {
            outputMap.put('error', 'Order not found.');
            return false;
        }

        // Clone the order
        Order clonedRecord = cloneRecord(originalRecord);
        if(clonedRecord == null) {
            outputMap.put('error', 'Order could not be cloned.');
            return false;
        }

        // Update status
        updateStatus(originalRecord, clonedRecord, clonedOrderStatus);

        // Add result to the output
        outputMap.put('orderId', clonedRecord.Id);

        return true;
    }  

    private Order cloneRecord(Order originalOrder) {    
        Savepoint beforeCloneSavepoint = Database.setSavepoint(); 
        
        Order clonedRecord = new Order();
        try {
            clonedRecord = originalOrder.clone(false, true, true, true);
            clonedRecord.FVU_ClonedOrderParent__c = originalOrder.Id;
            clonedRecord.Status = 'Draft';
            clonedRecord.FVU_ClosingReason__c = '';

            // Reset fields for OM
            clonedRecord.vlocity_cmt__OrderStatus__c = 'Ready To Submit';
            clonedRecord.OM_OrchestrationItemState__c  = '';  
            clonedRecord.vlocity_cmt__ProcessingLog__c = ''; 
            clonedRecord.vlocity_cmt__IsChangesAllowed__c = true; 
            clonedRecord.vlocity_cmt__FulfilmentStatus__c = 'Draft';
            clonedRecord.vlocity_cmt__OrchestrationPlanId__c = null;

            insert clonedRecord;
        } catch (Exception e) {
            system.debug(e);
            return null;
        }

        try {
            Map<Id, Id> orderItems = copyOrderItems(originalOrder.Id, clonedRecord);
            Map<Id, Id> promotions = clonePromotions(originalOrder.Id, clonedRecord.Id, orderItems);
        } catch (Exception e) {
            system.debug(e);
            Database.rollback(beforeCloneSavepoint);
            return null;
        }

        try {
            vlocity_cmt__OrderPayment__c clonedOrderPayment = cloneOrderPayment(originalOrder.Id, clonedRecord.Id);
        } catch (Exception e) {
            system.debug(e);
            Database.rollback(beforeCloneSavepoint);
            return null;
        }

        return clonedRecord;
    }
    
    private Map<Id, Id> copyOrderItems(Id originalOrderId, Order clonedOrder) {
        List<OrderItem> originalRecords = (List<OrderItem>) getRecords(originalOrderId, new OrderItem(), 'OrderId');
        if (originalRecords.isEmpty()) return null;
                
        List<String> fields = getObjectFields(OrderItem.getSObjectType().getDescribe(), '');
        
        List<OrderItem> newOrderItems = new List<OrderItem>();
        for(OrderItem item : originalRecords){
            OrderItem newItem = new OrderItem();
            for(String field : fields) {
                newItem.put(field, item.get(field));
            }
            newItem.OrderId = clonedOrder.Id;
            newItem.FVU_InitialRegReqId__c = '';
        	newItem.FVU_RegReqId__c = '';
        	newItem.FVU_ClaroRequestId__c = '';
            newItem.vlocity_cmt__IsChangesAllowed__c  = true; 
            newOrderItems.add(newItem);
        }        
        
        insert newOrderItems;
        
        Map<Id, Id> orderItems = new Map<Id, Id>();
        for (Integer i = 0; i < originalRecords.size(); i++) {
            orderItems.put(originalRecords[i].Id, newOrderItems[i].Id);
        }

        return orderItems;
    }

    private vlocity_cmt__OrderPayment__c cloneOrderPayment(Id originalOrderId, Id clonedOrderId) {
        vlocity_cmt__OrderPayment__c originalOrderPayment = (vlocity_cmt__OrderPayment__c) getSingleRecord(originalOrderId, new vlocity_cmt__OrderPayment__c(), 'vlocity_cmt__OrderId__c', '');
        if(originalOrderPayment == null) return null;

        vlocity_cmt__OrderPayment__c clonedOrderPayment = originalOrderPayment.clone(false, true, true, true);
        clonedOrderPayment.vlocity_cmt__OrderId__c = clonedOrderId;
        insert clonedOrderPayment;

        return clonedOrderPayment;
    }
    
    private Map<Id, Id> clonePromotions(Id originalOrderId, Id clonedOrderId, Map<Id, Id> orderItems) {
        List<vlocity_cmt__OrderAppliedPromotion__c> originalPromotions = (List<vlocity_cmt__OrderAppliedPromotion__c>) getRecords(originalOrderId, new vlocity_cmt__OrderAppliedPromotion__c(), 'vlocity_cmt__OrderId__c');    
        if(originalPromotions == null) return null;
        
        //Clone Applied Promotions
        List<vlocity_cmt__OrderAppliedPromotion__c> clonedPromotions = new List<vlocity_cmt__OrderAppliedPromotion__c>();        
        for(vlocity_cmt__OrderAppliedPromotion__c orderPromotion : originalPromotions) {
            vlocity_cmt__OrderAppliedPromotion__c clonedPromotion = orderPromotion.clone(false, true, true, true);
            clonedPromotion.vlocity_cmt__OrderId__c = clonedOrderId;
            clonedPromotion.Name = '';
            clonedPromotions.add(clonedPromotion);
        }
        
        insert clonedPromotions;
        
        Map<Id, Id> promotions = new Map<Id, Id>();
        for (Integer i = 0; i < originalPromotions.size(); i++) {
            promotions.put(originalPromotions[i].Id, clonedPromotions[i].Id);
        }

        //Clone Promotion Items
        List<vlocity_cmt__OrderAppliedPromotionItem__c> clonedPromotionItems = clonePromotionItems(orderItems, promotions);
        
        //Clone Price Adjustments
        Map<Id, Id> clonedOrderPriceAdjustment = cloneOrderPriceAdjustment(originalOrderId, clonedOrderId, orderItems, promotions);

        return promotions;
    }

    private List<vlocity_cmt__OrderAppliedPromotionItem__c> clonePromotionItems(Map<Id,Id> orderItems, Map<Id,Id> promotions) {
        List<vlocity_cmt__OrderAppliedPromotionItem__c> clonedPromotionsItems = new List<vlocity_cmt__OrderAppliedPromotionItem__c>(); 

        for (Id originalOrderItemId : orderItems.keySet()) {
            List<vlocity_cmt__OrderAppliedPromotionItem__c> originalPromotionsItems = (List<vlocity_cmt__OrderAppliedPromotionItem__c>) getRecords(originalOrderItemId, new vlocity_cmt__OrderAppliedPromotionItem__c(), 'vlocity_cmt__OrderItemId__c');
            System.debug(originalOrderItemId);
            System.debug(originalPromotionsItems);
            if(originalPromotionsItems == null) continue;

            for(vlocity_cmt__OrderAppliedPromotionItem__c item : originalPromotionsItems) {
                vlocity_cmt__OrderAppliedPromotionItem__c clonedPromotionItem = item.clone(false, true, true, true);
                clonedPromotionItem.Name = '';
                clonedPromotionItem.vlocity_cmt__OrderItemId__c = orderItems.get(originalOrderItemId);
                clonedPromotionItem.vlocity_cmt__OrderAppliedPromotionId__c = promotions.get(item.vlocity_cmt__OrderAppliedPromotionId__c);
                clonedPromotionsItems.add(clonedPromotionItem);
            }
        }
        
        insert clonedPromotionsItems;
        return clonedPromotionsItems;
    }

    private Map<Id, Id> cloneOrderPriceAdjustment(String originalOrderId, String clonedOrderId, Map<Id,Id> orderItems, Map<Id,Id> promotions) {
        List<vlocity_cmt__OrderPriceAdjustment__c> originalPriceAdjustments = (List<vlocity_cmt__OrderPriceAdjustment__c>) getRecords(originalOrderId, new vlocity_cmt__OrderPriceAdjustment__c(), 'vlocity_cmt__OrderId__c');    
        if(originalPriceAdjustments == null) return null;
        
        List<vlocity_cmt__OrderPriceAdjustment__c> clonedPriceAdjustments = new List<vlocity_cmt__OrderPriceAdjustment__c>(); 
        for(vlocity_cmt__OrderPriceAdjustment__c adjustment : originalPriceAdjustments) {
            vlocity_cmt__OrderPriceAdjustment__c clonedAdjustment = adjustment.clone(false, true, true, true);
            clonedAdjustment.Name = '';
            clonedAdjustment.vlocity_cmt__OrderId__c = clonedOrderId;
            clonedAdjustment.vlocity_cmt__OrderItemId__c = orderItems.get(adjustment.vlocity_cmt__OrderItemId__c);
            clonedAdjustment.vlocity_cmt__OrderAppliedPromotionId__c = promotions.get(adjustment.vlocity_cmt__OrderAppliedPromotionId__c);
            clonedPriceAdjustments.add(clonedAdjustment);
        }
        
        insert clonedPriceAdjustments;
        
        Map<Id, Id> priceAdjusments = new Map<Id, Id>();
        for (Integer i = 0; i < originalPriceAdjustments.size(); i++) {
            priceAdjusments.put(originalPriceAdjustments[i].Id, clonedPriceAdjustments[i].Id);
        }

        return priceAdjusments;
    }

    public void updateStatus(Order originalOrder, Order clonedOrder, String clonedOrderStatus) {
        clonedOrder.Status = clonedOrderStatus;
        originalOrder.Status = CLOSED_ORDER_STATUS;
        originalOrder.FVU_ClosingReason__c = ORDER_CLOSING_REASON;

        try {
            upsert clonedOrder;
            upsert originalOrder;
        } catch (DMLException e) {
            system.debug(e);
        }
    }

    public sObject getSingleRecord(Id recordId, sObject queryObject, String filterFieldName, String excludeField) { 
        String fields = String.join(getObjectFields(queryObject.getSObjectType().getDescribe(), excludeField), ',');
        String objectName = queryObject.getSObjectType().getDescribe().getLocalName();
        String query = 'SELECT ' + fields + ' FROM ' + objectName + ' WHERE ' + filterFieldName + ' = :recordId LIMIT 1';
        
        try {
            List<sObject> result = Database.query(query);
            return (result.isEmpty()) ? null : result[0];
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            return null;
        }
    }

    public List<sObject> getRecords(Id recordId, sObject queryObject, String filterFieldName) {
        String fields = String.join(getObjectFields(queryObject.getSObjectType().getDescribe(), ''), ',');
        String objectName = queryObject.getSObjectType().getDescribe().getLocalName();
        String query = 'SELECT ' + fields + ' FROM ' + objectName + ' WHERE ' + filterFieldName + ' = :recordId';

        try {
          return Database.query(query);
        } catch (System.QueryException e) {
            system.debug(e);
          return null;
        }
    }

    private List<String> getObjectFields(DescribeSObjectResult describe, String excludeField){
        List<String> fieldList = new List<String>();
        for (Schema.SObjectField sField : describe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldResult = sField.getDescribe();

            Boolean isFieldClonable = (fieldResult.isCreateable() && fieldResult.isAccessible() && !fieldResult.isCustom()) || (fieldResult.isCustom() && !fieldResult.isCalculated());

            if (isFieldClonable && fieldResult.isDeprecatedAndHidden() == false && fieldResult.getName() != excludeField) {
                fieldList.add(fieldResult.getLocalName());
            }
        }

        return fieldList;
    }
}