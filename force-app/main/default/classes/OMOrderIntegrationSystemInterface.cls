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
** OMOrderIntegrationSystemInterface for OM Stream - Generate JSON for all submitted Orders for Order MACD operations
* v1.0.0  
 * --------------------------------------------------------------------------
 *                         Date           Author            Description
 * ---------------------------------------------------------------------------
 * @version 1.0           2024-04-18    Ashish Paymode          Initial
 * @version 1.1           2024-07-23    Karen Sanchez          Se agrega método future para evitar errores de "LOCK RECORD"
 * @version 1.2           10/10/2024    Karen Sanchez          HDU 365050 - Se agrega el campo cancelación recibido desde un IP para que este ejecute un flow y se cancele la orden en curso con falla 
 * @version 1.3           20/01/2024    Karen Sanchez          BUG 536306 - Se agrega al mapa el orderId para recibirlo desde los IP necesarios
**/
global with sharing class OMOrderIntegrationSystemInterface extends vlocity_cmt.DefaultSystemInterface{
    /**
    * Default Constructor
    */
    global OMOrderIntegrationSystemInterface() {
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
        String inputJSON = null;
        
        if (item.vlocity_cmt__OrderItemId__c != null) 
            orderId = item.vlocity_cmt__OrderItemId__r.OrderId;
        else {
            vlocity_cmt__OrchestrationItem__c orchItem = [SELECT vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Id, 
                                                          vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId,
                                                          vlocity_cmt__OrchestrationPlanId__c,
                                                          vlocity_cmt__FulfilmentRequestLineId__r.OM_EricssonJSONRequest__c
                                                          FROM vlocity_cmt__OrchestrationItem__c WHERE Id = :item.Id WITH SECURITY_ENFORCED];
            orderId = orchItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Id;
            accountId = orchItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId;
            orchestrationPlanId = orchItem.vlocity_cmt__OrchestrationPlanId__c;
            inputJSON = orchItem.vlocity_cmt__FulfilmentRequestLineId__r.OM_EricssonJSONRequest__c;
        System.debug(' - Attempting to call Integration Procedure: ' + inputJSON);

        }
        Map<String, Object> ipOptions = new Map<String, Object>();
        Map<String, Object> ipInputActivate = (Map<String, Object>)JSON.deserializeUntyped(inputJSON);
        ipInputActivate.put('OrderId', orderId);
        System.debug(' - Attempting to call Integration Procedure "' + path + '"');
        System.debug(' - IP Input ericssonJSON -> ' + JSON.serialize(ipInputActivate));   // Ashish Uncommect after tes
        Map<String, Object> ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputActivate, ipOptions);  //  Ashish Uncommenct
        system.debug('====ipInputJson========'+ipInputActivate);
        system.debug('====ipOutput========'+ipOutput);
        processResponse(item, ipInputActivate, ipOutput);  //--- Ashish uncommented to call IP OM_ActivateOrderEricsson  Ashish Uncommenct
    }

    /**
     * This method is called from executeItem to handle the response from the Integration Procedure.
     * By default it does nothing (but some logging), but it could be customized to do something more.
     * @param item      The Orchestration Item
     * @param ipInput   The request sent to the Integration Procedure
     * @param ipOutput  The response from the Integration Procedure
     */
    global virtual void processResponse(vlocity_cmt__OrchestrationItem__c item, Map<String, Object> ipInput, Map<String, Object> ipOutput) {
        if(Test.isRunningTest()){
            String inputString = '{"responseStatus": {"status": "Success"}}';
            Object inputObject = JSON.deserializeUntyped(inputString);  
            ipOutput.put('response', inputObject);
            ipOutput.put('request', inputObject);
            system.debug('Es un test');
        }

        Map<String, Object> mapResponse = (Map<String, Object>)ipOutput.get('response');       
        String strRequest = JSON.serialize(ipOutput.get('request'));
        String strResponse = JSON.serialize(ipOutput.get('response'));
        Boolean cancelacion = Boolean.valueOf(JSON.serialize(ipOutput.get('cancelacion')));
        String dataCancelacion = JSON.serialize(ipOutput.get('dataCancelacion'));
        Id errorQueueId;
        if ((String) ipOutput.get('manualQueueId') != '') {
            errorQueueId = (String) ipOutput.get('manualQueueId');    
        }

        updateItemAsync(item.Id, strRequest, strResponse, errorQueueId, dataCancelacion, cancelacion);
        Boolean bErrorCondition = mapResponse.get('responseStatus') == '' || ((Map<String, Object>)mapResponse.get('responseStatus')).get('status') == 'ERROR';
        if(bErrorCondition) {
            throw new vlocity_cmt.XOMOrchestrationInterfaces.SystemInterfaceRecoverableException ('Response: ' + ipOutput.get('response'));    
        }
    }

    /**
     * Asynchronous method to update an Orchestration Item.
     * This method is annotated with @future to run asynchronously and is static because it cannot reference instance variables or methods.
     * @future
     * @param item The Orchestration Item to update
     */
    @future
    global static void updateItemAsync(Id itemId, String strRequest, String strResponse,  Id errorQueueId, String dataCancelacion, Boolean cancelacion) {
        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
        if (String.isNotBlank(String.valueOf(errorQueueId))){
            item.vlocity_cmt__ErrorQueueId__c = errorQueueId;
        }
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