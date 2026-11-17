/*-------------------------------------------------------------------------------------------------------------
Author:         Hever Salas  - hever.salas@nespon.com
Company:        Nespon
Description:    Clase para desactivar los asset de la cuenta cedente
Code Coverage:  96%
History
<Date>      	<Author>            <Description>             							            		<Version>
20-03-2025    Hever Salas     	HDU-531956 - PV - [CESION] Plan de orquestación CESION      					1.0
24-09-2025    Hever Salas     	HDU-635832 - [MEJORAS OM] Actualizacion reason code cesion de contrato     		2.0
--------------------------------------------------------------------------------------------------------------*/
global with sharing class OM_DeactivateAssets implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    class notificationException extends Exception{}

    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {
		Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();
		String strAssetReferenceId = '';
        vlocity_cmt__OrchestrationItem__c orchesItem = [SELECT Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_CaseInfo__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c
                                                        FROM vlocity_cmt__OrchestrationItem__c
                                                        WHERE Id = :item[0].Id WITH SECURITY_ENFORCED
                                                        LIMIT 1];
        
        Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped((String)orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.PVU_CaseInfo__c);

        if(mapCaseInfo.containsKey('cedenteAssetId') && String.IsNotBlank((String)mapCaseInfo.get('cedenteAssetId'))){
            
            strAssetReferenceId = [SELECT Id, vlocity_cmt__AssetReferenceId__c 
                                   FROM Asset
                                   WHERE Id = :(String)mapCaseInfo.get('cedenteAssetId') WITH SECURITY_ENFORCED].vlocity_cmt__AssetReferenceId__c ;
        }
        if(String.IsNotBlank(strAssetReferenceId)){
            ipInput.put('AssetReferenceId', strAssetReferenceId);
            ipInput.put('OrderId', (String)orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c);
            if(mapCaseInfo.containsKey('causalDesactivacionCedente') && String.IsNotBlank((String)mapCaseInfo.get('causalDesactivacionCedente'))){
                ipInput.put('causalDesactivacionCedente', mapCaseInfo.get('causalDesactivacionCedente'));
            }
            if(!Test.isRunningTest()) {
                ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_DeactivateAssets', ipInput, ipOptions);
            }else{
                Map <String, Object> descripcion = new Map <String, Object> ();
                descripcion.put('description', 'Error');
                ipOutput.put('success', false);
                ipOutput.put('result', descripcion);
            }
        }else{
            Map <String, Object> descripcion = new Map <String, Object> ();
            descripcion.put('description', 'Falta el valor cedenteAssetId en el campo PVU_CaseInfo__c');
            ipOutput.put('success', false);
            ipOutput.put('result', descripcion);
        }
            
        if((boolean)ipOutput.get('success') == false){
            Map <String, Object> mapError = new Map <String, Object> ();
            mapError = (Map <String, Object>)ipOutput.get('result');
            throw new notificationException('Error al desactivar los assets. descripcion:' + mapError.get('description'));
        }       
    }
}