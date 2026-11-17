/**
* This class exposes extends the Default System Interface class used by Order Management to
* make a synchronous callout to an Integration Procedure (rather than a direct REST API call).
*
* The general flow is as follows:
* 
*  -----------    ------------------    ------------    -----------------------
* | Orch Item |  | System Interface |  | this Class |  | Integration Procedure |
*  -----------    ------------------    ------------    -----------------------
*       |                 |                   |                    |
*       |     execute     |                   |                    |
*       |---------------->|    startBatch()   |                    |
*       |                 |------------------>|                    |
*       |                 |                   |                    |
*       |                 |   executeItem()   |                    |
*       |                 |------------------>|      call IP       |
*       |                 |                   |------------------->|
*       |                 |                   |                    |<----------> Do integration stuff
*       |                 |                   |      response      |
*       |                 | processResponse() |<-------------------|
*       |                 |<------------------|                    |xom
*       |                 |                   |                    |
*       |                 |    endBatch()     |                    |
*       |     complete    |------------------>|                    |
*       |<----------------|                   |                    |
*       |                 |                   |                    |
*       
** OrderIntegrationSystemInterface for OM Stream - Generate JSON for all submitted Orders for Order MACD operations
--------------------------------------------------------------------------
Author:         Mamata - v1.0.0   2023-09-05  Mamata          Initial
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>         <Version>      <Author>             <Description>                                    
2024-06-20      1.0.1         Hever Salas    		Change: Add Parameter isEOC    
2024-08-30      1.0.2		  Karen Sanchez         BUG 409669: Se agrega método future para evitar errores de "LOCK RECORD" 	
2025-03-06      1.0.3      	  Hever Salas      	    HDU-544910: Identificacion de Items sin accion
----------------------------------------------------------------------------*/
global with sharing class OrderIntegrationSystemInterface extends vlocity_cmt.DefaultSystemInterface{
    /**
    * Default Constructor
    */
    global OrderIntegrationSystemInterface() {
        super();
    }
    
    /**
    * This method is a part of the ISystemInterface. It is invoked at the start of the batch
    * 
    * @param url   base URL the batch is started for
    * @param path  path this batch is started for
    */
    global override void startBatch(String url, String path) {}
    
    /**
    * Executes a Callout OrchestrationItem
    * 
    * @param url   base URL to send the request to (in this class it is ignored as we'll be calling an Integration Procedure)
    * @param path  path to send the request to (in this class it is interpreted as the Integration Procedure API Key)
    * @param item  OrchestrationItem that needs to be executed
    */
    global override void executeItem(String url, String path, vlocity_cmt__OrchestrationItem__c item) {
        
        System.debug(' - Orchestration Item -> ' + JSON.serialize(item.getPopulatedFieldsAsMap()));
        
        // Get the Order SObject - the technique will differ depending on if this orchestration item is related to an Order Item or a Fulfillment Request Line
        Id orderId = null;
        Id accountId = null;
        Id orchestrationPlanId = null;
        String frlId = null;
        Boolean IsNotEOC = false;
        EricsonRequestJSON.ProdWithoutAction objProdWithoutAction = new EricsonRequestJSON.ProdWithoutAction();
        
        if (item.vlocity_cmt__OrderItemId__c != null) 
            
            orderId = item.vlocity_cmt__OrderItemId__r.OrderId;
        
        else {
            
            vlocity_cmt__OrchestrationItem__c orchItem = [SELECT vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Id, 
                                                          vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId,
                                                          vlocity_cmt__OrchestrationPlanId__c,
                                                          vlocity_cmt__FulfilmentRequestLineId__c,
                                                          vlocity_cmt__FulfilmentRequestLineId__r.OM_IsNotEOC__c
                                                          FROM vlocity_cmt__OrchestrationItem__c WHERE Id = :item.Id WITH SECURITY_ENFORCED];
            orderId = orchItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Id;
            accountId = orchItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId;
            orchestrationPlanId = orchItem.vlocity_cmt__OrchestrationPlanId__c;
            frlId = orchItem.vlocity_cmt__FulfilmentRequestLineId__c;
            IsNotEOC = orchItem.vlocity_cmt__FulfilmentRequestLineId__r.OM_IsNotEOC__c;
        }
        Map<String, Object> ipInput   = (Map<String, Object>)JSON.deserializeUntyped('{"OrderId" : "'+orderId+'","AccountId":"'+accountId+'","OrchestrationPlanId":"'+orchestrationPlanId+'"}');       
        Map<String, Object> inputParamsDR = (Map<String, Object>)JSON.deserializeUntyped('{"OrchestrationPlanId":"'+orchestrationPlanId+'", "OrderId":"'+orderId+'", "IsNotEOC":"'+IsNotEOC+'"}');   
        
        String ericssonJson = OrderIntegrationAccountDetails.setAccountDetails(ipInput, inputParamsDR, url, path, objProdWithoutAction);
        Map<String, Object> ipInputJSON = new Map<String, Object>{'orderId'=>(String)orderId, 'ericssonJson'=>(String)ericssonJson};
        
        Map<String, Object> Input = new Map<String, Object>();
        Map<String, Object> Output = new Map<String, Object>();
        Map<String, Object> Options = new Map<String, Object>();
        
        Input.put('orderType', objProdWithoutAction.orderType);
        Input.put('orderSubType', objProdWithoutAction.orderSubType);
		
        if((objProdWithoutAction.orderType == OrderIntegrationSystemInterfaceConstants.PORTABILITY_TYPE && 
          		(objProdWithoutAction.orderSubType == OrderIntegrationSystemInterfaceConstants.ROLLBACK_PORTOUT)) ||
           (objProdWithoutAction.orderType == OrderIntegrationSystemInterfaceConstants.ORD_TYPE_PORTIN && 
          		objProdWithoutAction.orderSubType == OrderIntegrationSystemInterfaceConstants.ORD_SUBTYPE_NEG_PORTIN)){
                    Output.put('request', '');
            		Output.put('response', objProdWithoutAction.response);
                    Output.put('dataCancelacion', '');
                    Output.put('cancelacion', false);
                    Output.put('manualQueueId', '');
        }else{
            Input.put('ApiName', objProdWithoutAction.ApiName);
            Input.put('ErrorCode', objProdWithoutAction.ErrorCode);
            Input.put('orderId', objProdWithoutAction.orderId);
            Input.put('response', (Map<String,Object>)objProdWithoutAction.response.get('responseStatus'));
            Output = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_getDataQueueCMAndOrderDetails', Input, Options);   
        }
        
        if(String.IsBlank(ericssonJson)){
            processResponse(item, Input, Output);
        }else{
            vlocity_cmt__FulfilmentRequestLine__c updateFRLEricssonJSON = new vlocity_cmt__FulfilmentRequestLine__c();
            System.debug(' - IP Input ericssonJSON -> ' + JSON.serialize(ipInputJSON));
            updateFRLEricssonJSON.Id = frlId;
            updateFRLEricssonJSON.OM_EricssonJSONRequest__c =  JSON.serialize(ipInputJSON);
            
            try{
                update updateFRLEricssonJSON;
            }catch(Exception e){
                System.debug(e);
            }
        }  
    }
    
    /**
    * This method is called from executeItem to handle the response from the Integration Procedure.
    * By default it does nothing (but some logging), but it could be customized to do something more.
    *
    * @param item      The Orchestration Item
    * @param ipInput   The request sent to the Integration Procedure
    * @param ipOutput  The response from the Integration Procedure
    */
    global virtual void processResponse(vlocity_cmt__OrchestrationItem__c item, Map<String, Object> ipInput, Map<String, Object> ipOutput) {
        
        System.debug(' - M:IP Output -> ' + JSON.serialize(ipOutput));
        System.debug(' - IP Request -> ' + JSON.serialize(ipOutput.get('request')));
        System.debug(' - IP Response -> ' + JSON.serialize(ipOutput.get('response')));
        
        
        Map<String, Object> mapResponse = (Map<String, Object>)ipOutput.get('response');       
        String strRequest = JSON.serialize(ipOutput.get('request'));
        String strResponse = JSON.serialize(ipOutput.get('response'));
        Boolean cancelacion = Boolean.valueOf(JSON.serialize(ipOutput.get('cancelacion')));
        String dataCancelacion = JSON.serialize(ipOutput.get('dataCancelacion'));

        updateItemAsync(item.Id, strRequest, strResponse, dataCancelacion, cancelacion);
        Boolean bErrorCondition = mapResponse.get('responseStatus') == '' || ((Map<String, Object>)mapResponse.get('responseStatus')).get('status') == 'ERROR';
        if(bErrorCondition) {
            HandledException ex = new HandledException();
            ex.setMessage('Response: ' + ipOutput.get('response'));
            throw ex;  
        }
    }


    /**
     * Asynchronous method to update an Orchestration Item.
     * This method is annotated with @future to run asynchronously and is static because it cannot reference instance variables or methods.
     * @future
     * @param item The Orchestration Item to update
     */
    @future
    global static void updateItemAsync(Id itemId, String strRequest, String strResponse, String dataCancelacion, Boolean cancelacion) {
        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
        
        item.OM_Cancelacion__c = dataCancelacion == 'null' ? '' : dataCancelacion;
        item.OM_CancelarPlan__c = cancelacion;
        item.vlocity_cmt__Request__c = strRequest;
        item.vlocity_cmt__Response__c = strResponse;
        item.Id = itemId;
        update item;                   
    }
    
    /**
    * This method is called at the end of the batch
    * 
    * @param url   base URL for the batch
    * @param path  path for the batch
    */
    global override void endBatch(String url, String path) {} 
}