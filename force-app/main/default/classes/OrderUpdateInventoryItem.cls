global class  OrderUpdateInventoryItem implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {

    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> items){
        System.debug('====UpdateInventory====='+items[0].Id+'==='+items[0].vlocity_cmt__OrchestrationPlanId__c );
        Map<String, Object> ipInput   = (Map<String, Object>)JSON.deserializeUntyped('{"OrchestrationPlanId":"'+items[0].vlocity_cmt__OrchestrationPlanId__c+'"}');
        Map<String, Object> ipOptions = new Map<String, Object>();
        String path = 'OM_UpdateInventoryItems';
        
        Map<String, Object> ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInput, ipOptions);
        
    }
}