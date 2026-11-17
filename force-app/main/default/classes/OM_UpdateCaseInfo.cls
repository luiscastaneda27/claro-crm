/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* --------------------------------------------------------------------------
 *                         Date           Author          Description
 * ---------------------------------------------------------------------------
 * @version 1.0          
 * @version 1.1           01/Aug/2024     Karen Sanchez    HDU 354355 - Se agrega OrderType para actualizar el caso como 'No exitosa' por la cancelación
**/
global with sharing class OM_UpdateCaseInfo implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    class notificationException extends Exception{}
  
    
    global  void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {
        Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();

        vlocity_cmt__OrchestrationItem__c orchesItem = [SELECT Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Type,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.FVU_OrderSubType__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId
                                                        FROM vlocity_cmt__OrchestrationItem__c
                                                        where id = :item[0].Id
                                                        WITH SECURITY_ENFORCED
                                                        LIMIT 1];
        String strHasSuperseded = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__c != null ? 'Si' : 'No';
        
        ipInput.put('OrderId', orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c);
        ipInput.put('HasSuperseded', strHasSuperseded);

        if(!Test.isRunningTest()) {             
        	 ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_UpdateCaseInfo', ipInput, ipOptions);
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
            throw new notificationException('Error al actualizar caso. descripcion:' + mapError.get('description'));
        }        
    }
}