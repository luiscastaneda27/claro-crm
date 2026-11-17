/**
 * @description       : Clase invocada desde el OI Definition "OM Cancelación de Orden" para hacer la cancelación de la orden en Ericsson
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : 
 * @last modified on  : 08-13-2024
 * --------------------------------------------------------------------------
 *                         Date           Author          Description
 * ---------------------------------------------------------------------------
 * @version 1.0           09/07/2024     Karen Sanchez    HDU 354355 - Created
 * @version 1.1           05/08/2024     Karen Sanchez    HDU 354355 - Se debe almacenar el request y response entregados por el IP en un metodo a futuro
 * @version 1.2           21/05/2025     Hever Salas      HDU 579017 - [EVOLUTIVO OM] Adicionar codigo de error
**/
global with sharing class OM_InvokeIPCancelEricsson_cls implements vlocity_cmt.XOMOrchestrationInterfaces.ISystemInterface {
    public class CancelException extends Exception {}

    global virtual void startBatch(String url, String path){
        // Do nothing
    }
    
    global virtual void endBatch(String url, String path){
        // Do nothing
    }
    
    /**
    * @description: Invoca el IP para hacer la cancelación, tomando en cuenta los inputs creados. 
    * @author karsanchez | 08-02-2024 
    * @param url 
    * @param path 
    * @param item 
    * @return virtual 
    **/
    global virtual void executeItem(String url, String path, vlocity_cmt__OrchestrationItem__c item) {
        Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();



        vlocity_cmt__OrchestrationItem__c orchesItem = [SELECT Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Owner.Name, 
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__r.OM_EricssonOrderId__c, 
                                                        vlocity_cmt__OrchestrationPlanId__c
                                                        FROM vlocity_cmt__OrchestrationItem__c
                                                        WHERE id = :item.Id];
		ipInput.put('sfOrderId', orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c);
        ipInput.put('action', 'Cancel');
        ipInput.put('EricssonOrderId', orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__r.OM_EricssonOrderId__c);
        ipInput.put('reason', 'Error funcional');
        ipInput.put('requester', orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Owner.Name);
        ipInput.put('requestId', '1');
        ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_OrderCancelEricsson', ipInput, ipOptions);
        Map<String, Object> mapResponse = (Map<String, Object>)ipOutput.get('response');       
        Map<String, Object> mapResponseStatus = (Map<String, Object>)mapResponse.get('responseStatus');
       
        updateItemAsync(item.Id, JSON.serialize(ipOutput.get('request')), JSON.serialize(ipOutput.get('response')));
        if((String)mapResponseStatus.get('status') == 'ERROR') {
            throw new vlocity_cmt.XOMOrchestrationInterfaces.SystemInterfaceRecoverableException ('Response: ' + mapResponseStatus.get('message'));    
        }
    }

    /**
     * Asynchronous method to update an Orchestration Item.
     * This method is annotated with @future to run asynchronously and is static because it cannot reference instance variables or methods.
     * @future
     * @param item The Orchestration Item to update
     */
    @future
    public static void updateItemAsync(Id itemId, String strRequest, String strResponse) {
        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
            item.vlocity_cmt__Request__c = strRequest;
            item.vlocity_cmt__Response__c = strResponse;
            item.Id = itemId;
            update item;                   
    }
}