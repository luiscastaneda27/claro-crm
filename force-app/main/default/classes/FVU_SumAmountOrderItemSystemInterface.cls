global class FVU_SumAmountOrderItemSystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {

	public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        Boolean result = true;
        
        try {
        	if(methodName == 'getOrderTotalByAccount') {
                result = getOrderTotalByAccount(inputMap, outputMap, options);
        	}
        	else if(methodName == 'getOrderTotalByOwner') {
                result = getOrderTotalByOwner(inputMap, outputMap, options);
        	}            
        } 
        catch(Exception e) {
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In FVU_Utils.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        
        return result;
        
    }
    
    private Boolean getOrderTotalByAccount(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        String accountId = (String)inputMap.get('accountId');
        setOrderTotalWrapper(accountId, null, outputMap);
        
        return true;
    }
    
    private Boolean getOrderTotalByOwner(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
    
        String ownerId = (String)inputMap.get('ownerId');
        setOrderTotalWrapper(null, ownerId, outputMap);
        
        
        return true;
        
    }
    
    private static void setOrderTotalWrapper(String accountId, String ownerId, Map<String, Object> outputMap) {
        
        OrderTotal orderTotalWrapperService = new OrderTotal();
        
        orderTotalWrapperService.orderTotalToday = getOrderTotalByNDays('servicio', accountId, ownerId, 1);
        orderTotalWrapperService.orderTotalWeek = getOrderTotalByNDays('servicio', accountId, ownerId, 7);
        orderTotalWrapperService.orderTotalMonth = getOrderTotalByNDays('servicio', accountId, ownerId, 30);
        
        Map<String, Object> mapOrderTotal = new Map<String, Object>();
        mapOrderTotal.put('orderTotalMonth', orderTotalWrapperService.orderTotalMonth);
        mapOrderTotal.put('orderTotalWeek', orderTotalWrapperService.orderTotalWeek);
        mapOrderTotal.put('orderTotalToday', orderTotalWrapperService.orderTotalToday);
        
        outputMap.put('OrderTotalService', mapOrderTotal);        
        
        OrderTotal orderTotalWrapperProduct = new OrderTotal();
        
        orderTotalWrapperProduct.orderTotalToday = getOrderTotalByNDays('producto', accountId, ownerId, 1);
        orderTotalWrapperProduct.orderTotalWeek = getOrderTotalByNDays('producto', accountId, ownerId, 7);
        orderTotalWrapperProduct.orderTotalMonth = getOrderTotalByNDays('producto', accountId, ownerId, 30);
        
        mapOrderTotal = new Map<String, Object>();
        mapOrderTotal.put('orderTotalMonth', orderTotalWrapperProduct.orderTotalMonth);
        mapOrderTotal.put('orderTotalWeek', orderTotalWrapperProduct.orderTotalWeek);
        mapOrderTotal.put('orderTotalToday', orderTotalWrapperProduct.orderTotalToday);
        outputMap.put('OrderTotalProduct', mapOrderTotal);        
        
    }
    
    private static Decimal getOrderTotalByNDays(String purchaseType, String accountId, String ownerId, Integer nDays) {
        
        Set<String> lstProductFamily;
        Set<String> lstProductType;
        String productSpecificationType = 'Offer';
        String orderStatus = 'Activated';
        String salesType = 'Venta';
        
        if(purchaseType == 'producto') {
        	lstProductFamily = new Set<String>{'Device', 'Accessories'};
            lstProductType = new Set<String>{'Handset', 'Tech'};
        }
        else {
            lstProductFamily = new Set<String>{'Mobile', 'Landline', 'Internet', 'TV', 'Multiplay'};
            lstProductType = new Set<String>{'Plan'};              
        }
        
        String orderItemQuery = 'SELECT SUM(vlocity_cmt__EffectiveOneTimeTotal__c) effectiveOneTimeTotal, ' + 
            'SUM(vlocity_cmt__EffectiveRecurringTotal__c) effectiveRecurringTotal ' + 
            'FROM OrderItem ' + 
            'WHERE Product2.Family IN :lstProductFamily  ' + 
            'AND Product2.vlocity_cmt__SpecificationType__c = :productSpecificationType ' + 
            'AND Product2.vlocity_cmt__Type__c IN :lstProductType ' + 
            'AND Order.Status = :orderStatus ';
        if(String.isNotBlank(accountId)) {
            orderItemQuery += 'AND Order.AccountId = :accountId ';
        }
        else if(String.isNotBlank(ownerId)) {
            orderItemQuery += 'AND Order.OwnerId = :ownerId ';
        }
        orderItemQuery += 'AND Order.FVU_SalesType__c = :salesType ' + 
            'AND Order.CreatedDate >= LAST_N_DAYS:' + nDays;
        
        List<AggregateResult> lstAggrOrderItem = (List<AggregateResult>)Database.query(orderItemQuery);
        
        Decimal effectiveOneTimeTotal = (Decimal)lstAggrOrderItem[0].get('effectiveOneTimeTotal');
        if(effectiveOneTimeTotal == null) effectiveOneTimeTotal = 0;
        Decimal effectiveRecurringTotal = (Decimal)lstAggrOrderItem[0].get('effectiveRecurringTotal');
        if(effectiveRecurringTotal == null) effectiveRecurringTotal = 0;
        Decimal orderTotal = effectiveOneTimeTotal + effectiveRecurringTotal;
        
        return orderTotal;
        
    }
    
    public class OrderTotal {
        
        Decimal orderTotalToday {get; set;}
        Decimal orderTotalWeek {get; set;}
        Decimal orderTotalMonth {get; set;}
        
    }

}