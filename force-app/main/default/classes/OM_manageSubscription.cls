global with sharing class OM_manageSubscription implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    class notificationException extends Exception{}

    
    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {
        vlocity_cmt__OrchestrationItem__c orchesItem = [SELECT Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                        vlocity_cmt__OrchestrationPlanId__c
                                                        FROM vlocity_cmt__OrchestrationItem__c
                                                        where id = :item[0].Id WITH SECURITY_ENFORCED
                                                        LIMIT 1];
        
        
        
        Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();
        
        ipInput.put('OrchestrationPlanId', orchesItem.vlocity_cmt__OrchestrationPlanId__c);
        ipInput.put('OrderId', orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c);
        
        if(!Test.isRunningTest()) {             
        	 ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_manageSubscription', ipInput, ipOptions);
        }else{
            Map <String, Object> descripcion = new Map <String, Object> ();
            descripcion.put('description', 'Error');
            ipOutput.put('success', false);
            ipOutput.put('ErrorCode', -1);
            ipOutput.put('ErrorMessage', 'Error');
            ipOutput.put('result', descripcion);
        }
        
        
        if((boolean)ipOutput.get('success') == false){
            Map <String, Object> mapError = new Map <String, Object> ();
            mapError = (Map <String, Object>)ipOutput.get('result');
            
            throw new notificationException('Error al actualizar Subscription. descripcion:' + mapError.get('description'));
        }
        
    }
    
}