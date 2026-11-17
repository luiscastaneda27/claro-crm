/*------------------------------------------------------------
Author:        	Daniela Romero
Company:       	Salesforce.com
Description:   	Class to manager update to integration procedure Inbound_IPProductOrderPaymentConfirmation 
Test Class:    	ProductOrderPaymentConfirmation_Test
History
<Date>      	<Author>     	<Change Description>
01-Agos-2023	Daniela Romero	Initial Version
22-Agos-2023	Luis Mendoza	Version with workaround
07-Dec-2023     Guilherme Camargo   Merged Version

------------------------------------------------------------*/
global with sharing class REST_ProductOrderPaymentConfirmation implements vlocity_cmt.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('productOrCasePaymentConfirmation')) {
                productOrCasePaymentConfirmation(inputMap, outMap, options);
            } else {
                result = false;
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;
        
    }

/*------------------------------------------------------------
    Author:		Luis Mendoza
    Company:		Salesforce.com
    Description:   	method to update Order or Case, and Create or Update object Order Payment Confirmations
    IN:	List Map PaymentConfirmation		
    OUT: map<String, Object> to response success or error 			
    History
    <Date>      <Author>     <Description>
    22-Agos-2023    Luis Mendoza    Version with workaround
    20-Sept-2023    Luis Mendoza    Version with field add to object "vlocity_cmt__OrderPayment__c"
    07-Dec-2023     Guilherme Camargo   Merged Version
	02-Mar-2025		Carlos Pastrana		Version with update in order object, payment date field (line 112 to 118)
    19-Mar-2026     COE-Soporte		Add validation to ensure all chargeable OrderItems are included in payment request
------------------------------------------------------------*/
    public static void productOrCasePaymentConfirmation(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        List<Map<String, Object>> requestJSON = new List<Map<String, Object>>();
        List<Object> requestJSONObject = (List<Object>) inputMap.get('PaymentConfirmation');
        
        for (Object instance : requestJSONObject ){
            requestJSON.add((Map<String, Object>) instance);
        }
        
        List<Map<String,Object>> orderPaymentInformations = new List<Map<String,Object>>(); 
        List<String> ordIds = new List<String>();
        List<String> caseIds = new List<String>();
        List<vlocity_cmt__OrderPayment__c> orderPaymentMethod = new List<vlocity_cmt__OrderPayment__c>();
        List<vlocity_cmt__OrderPayment__c> orderPaymentMethodListNew = new List<vlocity_cmt__OrderPayment__c>();
        // List<Order> orderForConfirm = new Order();
        List<Order> orderForConfirmList = new List<Order>();
        List<Case> caseForConfirmList = new List<Case>();
        
        System.debug('requestJson '+  requestJSON);
        
        try {
            Set<String> ordNumberList = new Set<String>();
            Set<String> caseNumberList = new Set<String>();
            Set<Id> ordIdList = new Set<Id>();

            for (Map<String,Object>  itmO : requestJSON) {
                if(itmO.get('OrderNumber') != null){
                    Map<String,Object> ordrMap = new Map<String,Object>();
                    String ordNum = (String) itmO.get('OrderNumber');
                    String status = (String) itmO.get('status');
                    String paymentId = (String) itmO.get('paymentId');
                    String companyId = (String) itmO.get('companyId');
                    String subState = (String) itmO.get('SubState');
                    String caseNumber = (String) itmO.get('CaseNumber');
                    String collectionCenter = String.valueOf(itmO.get('collectionCenter'));
                    List<Object> requestJSONObjectOrderPayment = (List<Object>) itmO.get('OrderPaymentInformation');
                    for (Object instance : requestJSONObjectOrderPayment ){
                        ordrMap = (Map<String, Object>) instance;
                        ordrMap.put('OrderNumber', ordNum);
                        ordrMap.put('status', status);
                        ordrMap.put('paymentId', paymentId);
                        ordrMap.put('companyId', companyId);
                        ordrMap.put('subState', subState);
                        ordrMap.put('caseNumber', caseNumber);
                        ordrMap.put('collectionCenter', collectionCenter);
                        orderPaymentInformations.add(ordrMap);
                    }
                    System.debug('orderPaymentInformations + ' + orderPaymentInformations);
                    ordNumberList.add(ordNum);
                }else if(itmO.get('CaseNumber') != null){
                    Map<String,Object> casedata = new Map<String,Object>();
                    String caseNumber = (String) itmO.get('CaseNumber');
                    caseNumberList.add(caseNumber);
                }
            }
            /** 
              * [19-Mar-2026 COE-Soporte]:
              * validation: ensure all chargeable OrderItems are included in payment request
			  * Stops execution if validation fails (fail-fast approach)
			**/
            if(!validateProductOrderItemsPayment(requestJSON, ordNumberList, outMap)){
                return;
            }                       
            if (!ordNumberList.isEmpty()) {
                List<Order> ords = [SELECT Id, OrderNumber, Status, FVU_PaymentStatus__c FROM Order WHERE OrderNumber IN :ordNumberList FOR UPDATE];
                for ( Order ord : ords) {
                    for (Map<String,Object> ordPay : orderPaymentInformations) {
                        String ordNum = (String) ordPay.get('OrderNumber');
                        if( ordNum ==  ord.OrderNumber ){
                            ord.FVU_PaymentStatus__c =  (String) ordPay.get('status');
                            
                            // Update in date payment
                            String paymentDate = (String) ordPay.get('dateTime');
                            if (paymentDate != null) {
                                // Convert DateTime to Date 
                                DateTime dtPaymentDate = DateTime.valueOf(paymentDate.replace('T', ' ').replace('Z', ''));
                                ord.FVU_PaymentDate__c = dtPaymentDate.date();
                            }
                        }
                    }
                    orderForConfirmList.add(ord);
                    ordIdList.add(ord.Id);
                }

                if( ordIdList.size() > 0){
                    orderPaymentMethod = [SELECT Id, Name, vlocity_cmt__OrderId__c,FVU_CompanyId__c,FVU_PaymentMethod__c, FVU_PaymentTxDate__c, vlocity_cmt__PaymentAmount__c, FVU_PaymentTransactionId__c, FVU_SourceTransactionId__c, FVU_TransactionId__c FROM vlocity_cmt__OrderPayment__c WHERE vlocity_cmt__OrderId__c IN :ordIdList FOR UPDATE];    
                    
                    if (!orderPaymentMethod.isEmpty()) {
                        for (vlocity_cmt__OrderPayment__c actualPayment : orderPaymentMethod) {
                            for (Map<String,Object> opi : orderPaymentInformations) {
                                String paymentMethod = (String) opi.get('paymentMethod');     
                                actualPayment.Name = (String) opi.get('paymentId');
                                actualPayment.FVU_PaymentMethod__c = paymentMethod;
                                actualPayment.vlocity_cmt__PaymentAmount__c = (Decimal) opi.get('amount');
                                actualPayment.FVU_PaymentTransactionId__c = (String) opi.get('paymentTransactionId');
                                actualPayment.FVU_SourceTransactionId__c = (String) opi.get('sourceTransactionId');
                                actualPayment.FVU_TransactionId__c = (String) opi.get('transactionId');
                                String datess = (String) opi.get('dateTime');
                                actualPayment.FVU_PaymentTxDate__c = DateTime.valueOf(datess.replace('T', ' ').replace('Z', ''));
                                actualPayment.FVU_CollectionCenter__c = (String) opi.get('collectionCenter');
                                actualPayment.FVU_CompanyId__c = (String) opi.get('companyId');
                                
                            }
                        }   
                    }else{
                        for( Id ordId : ordIdList ){
                            for (Map<String,Object> opi : orderPaymentInformations) {
                                vlocity_cmt__OrderPayment__c orderPaymentMethodNew = new vlocity_cmt__OrderPayment__c();
                                String paymentMethod = (String) opi.get('paymentMethod');
                                orderPaymentMethodNew.Name = (String) opi.get('paymentId');
                                orderPaymentMethodNew.FVU_PaymentMethod__c = paymentMethod;
                                orderPaymentMethodNew.vlocity_cmt__PaymentAmount__c = (Decimal) opi.get('amount');
                                orderPaymentMethodNew.vlocity_cmt__OrderId__c = ordId;
                                orderPaymentMethodNew.FVU_PaymentTransactionId__c = (String) opi.get('paymentTransactionId');
                                orderPaymentMethodNew.FVU_SourceTransactionId__c = (String) opi.get('sourceTransactionId');
                                orderPaymentMethodNew.FVU_TransactionId__c = (String) opi.get('transactionId');
                                String datess = (String) opi.get('dateTime');
                                orderPaymentMethodNew.FVU_PaymentTxDate__c = DateTime.valueOf(datess.replace('T', ' ').replace('Z', ''));
                                orderPaymentMethodNew.FVU_CollectionCenter__c = (String) opi.get('collectionCenter');
                                orderPaymentMethodNew.FVU_CompanyId__c = (String) opi.get('companyId');
                                orderPaymentMethodListNew.add(orderPaymentMethodNew);
                            }
                        }
                    }
                }else {
                    outMap.put('code', '406');
                    outMap.put('reason', 'Request not acceptable');
                    outMap.put('message', 'Order not found');
                    outMap.put('status', 'Failed');
                }

            }else if(!caseNumberList.isEmpty()){
                for (Case cas : [SELECT Id, CaseNumber, status, PVU_Sub_Estado__c  FROM Case WHERE CaseNumber IN :caseNumberList]) {
                    for (Map<String,Object> ordPay : orderPaymentInformations) {
                        String caseNumber = (String) ordPay.get('caseNumber');
                        if( caseNumber ==  cas.CaseNumber ){
                            cas.Status = (String) ordPay.get('status');
                            cas.PVU_Sub_Estado__c = (String) ordPay.get('SubState');
                        }
                    }
                    caseForConfirmList.add(cas);
                }
            }


            System.debug('ORDERCONFIRM ' + orderForConfirmList);
            System.debug('ORDERPAYMENT' + orderPaymentMethod);
            System.debug('orderPaymentMethodListNew ' + orderPaymentMethodListNew);
            if(!orderPaymentMethod.isEmpty() && !orderForConfirmList.isEmpty()){
                update orderPaymentMethod;
                update orderForConfirmList;
                outMap.put('code', '200');
                outMap.put('reason', 'Success');
                outMap.put('message', 'Order record updated');
                outMap.put('status', 'ok');                
            }else if(!orderPaymentMethodListNew.isEmpty() && !orderForConfirmList.isEmpty()){
                System.debug('dentro de orderPaymentMethodListNew');
                insert orderPaymentMethodListNew;
                update orderForConfirmList;
                outMap.put('code', '200');
                outMap.put('reason', 'Success');
                outMap.put('message', 'Order Payment record create and update Order');
                outMap.put('status', 'ok'); 
            }
            if(!caseForConfirmList.isEmpty()){
                update caseForConfirmList;
                outMap.put('code', '200');
                outMap.put('reason', 'Success');
                outMap.put('message', 'Case record update');
                outMap.put('status', 'ok'); 
            }
            outMap.remove('errorCode');
            outMap.remove('error');
            
        } catch (Exception e){            
            System.debug('Error ' +  e.getCause() + ' ' + e.getLineNumber() + ' message ' + e.getMessage());
            outMap.put('Error message ', e.getMessage());            
        }
        
    }  
    
    /**
     * [19-Mar-2026 COE-Soporte]:
     * Validates that all OrderItems with OneTimeCharge > 0 are included
     * in the incoming payload (ProductOrderItem array).
     *
     * If any required OrderItem is missing, the process is stopped
     * and an error response is returned in outMap.
     *
     * This is a temporary validation to prevent partial payments.
     */    
    private static Boolean validateProductOrderItemsPayment(List<Map<String, Object>> requestJSON,Set<String> ordNumberList,Map<String,Object> outMap)
	{
        try {        
            Map<String, Decimal> amountByOrder = new Map<String, Decimal>();
    
            // Read payload amounts
            for (Map<String,Object> itmO : requestJSON) {                
                if(itmO.get('OrderNumber') != null){
                    String ordNum = (String) itmO.get('OrderNumber');                
                        
                    // Sum amounts paid
                    if(itmO.get('OrderPaymentInformation') != null){
                        Decimal totalAmount = 0;
    
                        List<Object> payments = (List<Object>) itmO.get('OrderPaymentInformation');
                        for(Object payObj : payments){
                            Map<String,Object> payMap = (Map<String,Object>) payObj;
                            if(payMap.get('amount') != null){
                                totalAmount += (Decimal) payMap.get('amount');
                            }
                        }
                        amountByOrder.put(ordNum, totalAmount);
                    }
                }
            }
            
            // Get in Salesforce OrderItems + Order totals        
            Map<String, Order> orderMap = new Map<String, Order>();
            
            if(!ordNumberList.isEmpty())
            {                
                for(Order orderObj:	[SELECT OrderNumber, vlocity_cmt__QuoteId__r.FIN_TotalCuotaInicial__c, FVU_EffectiveOneTimeIncTaxesTotal__c, FVU_PurchaseType__c
                                     FROM Order where OrderNumber IN :ordNumberList])                                    
                {					        
                    if(!orderMap.containsKey(orderObj.OrderNumber)){
                        orderMap.put(orderObj.OrderNumber, orderObj);
                    }                    
                }
            }
            
            // Validations
            for(String ordNum : orderMap.keySet()){
                
                // validate by order amount
                Decimal payloadAmount = amountByOrder.get(ordNum);
                Order orderByAmount = orderMap.get(ordNum);
    
                Boolean amountMatches = false;
    
                if(orderByAmount != null && payloadAmount != null){
                    if((orderByAmount.FVU_PurchaseType__c == 'FIN' && 
                        (orderByAmount.vlocity_cmt__QuoteId__r.FIN_TotalCuotaInicial__c != null && orderByAmount.vlocity_cmt__QuoteId__r.FIN_TotalCuotaInicial__c == payloadAmount)) 
                    || 
                    (orderByAmount.FVU_PurchaseType__c != 'FIN' &&
                        (orderByAmount.FVU_EffectiveOneTimeIncTaxesTotal__c != null && orderByAmount.FVU_EffectiveOneTimeIncTaxesTotal__c == payloadAmount))){
                            amountMatches = true;
                    }
                }
                if(!amountMatches){
                    outMap.put('code', '422');
                    outMap.put('reason', 'Request not acceptable');
                    outMap.put('message', 'There are ProductOrderItems without payment confirmation');
                    outMap.put('status', 'Failed');                                      
                    return false;
                }
                
            }
        }catch (Exception e){            
                System.debug('Error ' +  e.getCause() + ' ' + e.getLineNumber() + ' message ' + e.getMessage());
                outMap.put('Error message ', e.getMessage()); 
                return false;
        }
        return true;
	}            
}