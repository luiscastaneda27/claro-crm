/**------------------------------------------------------------------------------------------------------
Author:         Hever Salas
Company:        Salesforce.com
Description:    
Code Coverage:  84%
History
<Date>			@version     	<Author>             <Description>
2025-10-23       1.0.0   	  	Hever Salas          	Initial
--------------------------------------------------------------------------------------------------------*/
public with sharing class OM_UpdateOrderFieldsByReportsBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query inicial para obtener los planes de orquestación
        return Database.getQueryLocator([
            SELECT Id, vlocity_cmt__OrderId__c, vlocity_cmt__OrderId__r.PVU_CaseInfo__c,
                vlocity_cmt__OrderId__r.Type, vlocity_cmt__OrderId__r.FVU_OrderSubType__c, 
                vlocity_cmt__OrderId__r.vlocity_cmt__SubmittedToOmDate__c, 
                vlocity_cmt__OrderId__r.vlocity_cmt__RequestedCompletionDate__c
            FROM vlocity_cmt__OrchestrationPlan__c
            WHERE vlocity_cmt__OrderId__c != ''
            AND vlocity_cmt__OrderId__r.OM_MSISDN__c = '' 
            AND vlocity_cmt__OrderId__r.status != 'Draft'
            AND vlocity_cmt__OrderId__r.vlocity_cmt__DueDate__c != null 
            WITH SECURITY_ENFORCED
        ]);
    }

    public void execute(Database.BatchableContext BC, List<vlocity_cmt__OrchestrationPlan__c> scope) {
        List<Order> lstOrdersToUpdate = new List<Order>();
        // Get the Fulfilment Request Lines related to the Orchestration Plan
        Map<Id, vlocity_cmt__FulfilmentRequestLine__c> fulfilmentReqLinesXOrchPlan = new Map<Id, vlocity_cmt__FulfilmentRequestLine__c>([
            SELECT Id
            FROM vlocity_cmt__FulfilmentRequestLine__c
            WHERE Id IN (SELECT vlocity_cmt__FulfilmentRequestLineId__c 
                         FROM vlocity_cmt__OrchestrationItem__c 
                         WHERE vlocity_cmt__OrchestrationPlanId__c IN :scope) WITH SECURITY_ENFORCED
        ]);
        
        // Extracts the Decomposition Relationship between Order Items and Fulfilment Request Lines - V. 1.0.1
        List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> fulfilmentReqLinDecompositionRel = [
            SELECT 
            vlocity_cmt__SourceOrderItemId__c, vlocity_cmt__SourceOrderItemId__r.Product2.ProductCode, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ParentItemId__c,
            vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c, vlocity_cmt__SourceOrderItemId__r.Product2.Family, 
            vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SerialNumber__c, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__AttributeSelectedValues__c,
            vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SubscriptionId__r.OM_Contract__c, vlocity_cmt__DestinationFulfilmentRequestLineId__c,
            vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Action__c, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SubAction__c,
            vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name, vlocity_cmt__SourceOrderItemId__r.OM_newICCID__c,
            vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c, vlocity_cmt__SourceOrderItemId__r.FVU_ReasonCode__c
            FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c
            WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c = :scope WITH SECURITY_ENFORCED
            ORDER BY vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Action__c DESC
        ];
        Map<Id, List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c>> mapfrldr = new Map<Id, List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c>>();
        for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c frldr : fulfilmentReqLinDecompositionRel){
            if(mapfrldr.containsKey(frldr.vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c)){
                List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> lstfrldr = mapfrldr.get(frldr.vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c);
                lstfrldr.add(frldr);
                mapfrldr.put(frldr.vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c, lstfrldr);
            }else{
                mapfrldr.put(frldr.vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c, new List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c>{frldr});
            }
        }
        for(vlocity_cmt__OrchestrationPlan__c item: scope) {

            //Set completion date, Due Date on Order which will be used to calculate Jeopardy status
            Order orderDetails = new Order();
            orderDetails.Id = item.vlocity_cmt__OrderId__c;
            orderDetails.Type = item.vlocity_cmt__OrderId__r.Type;
            orderDetails.FVU_OrderSubType__c = item.vlocity_cmt__OrderId__r.FVU_OrderSubType__c;
            orderDetails.vlocity_cmt__SubmittedToOmDate__c = item.vlocity_cmt__OrderId__r.vlocity_cmt__SubmittedToOmDate__c;
            orderDetails.vlocity_cmt__RequestedCompletionDate__c = item.vlocity_cmt__OrderId__r.vlocity_cmt__RequestedCompletionDate__c;
            orderDetails.PVU_CaseInfo__c = item.vlocity_cmt__OrderId__r.PVU_CaseInfo__c;
            orderDetails.vlocity_cmt__OrchestrationPlanId__c = item.Id;

            Map<Id, List<OrderItem>> fulfilmentReqLineId_OrderItems = new Map<Id, List<OrderItem>>();
            for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c fRLDR: mapfrldr.get(item.Id)){
                // The relationships in scope are: the ones with Fulfilment Request Lines referenced in the Orchestration Plan - V. 1.0.1
                if(fulfilmentReqLinesXOrchPlan.containsKey(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c)){
                    // Mapping of Fulfilment Request Line and their related Order Items
                    if(!fulfilmentReqLineId_OrderItems.containsKey(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c)){
                        fulfilmentReqLineId_OrderItems.put(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c, new List<OrderItem>{fRLDR.vlocity_cmt__SourceOrderItemId__r});
                    }
                    else{
                        fulfilmentReqLineId_OrderItems.get(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c).add(fRLDR.vlocity_cmt__SourceOrderItemId__r);
                    }
                }
            }
            Set<String> simCardProductCodes = new Set<String>{OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD, OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD, 'B2C-ATTR-SIM-MATERIAL'};
            for(Id fRLId: fulfilmentReqLineId_OrderItems.keySet()){
                Set<String> mSISDNs = new Set<String>();
                Set<String> iCCIDs = new Set<String>();
                Set<String> iCCIDOlds = new Set<String>();
                Set<String> families = new Set<String>();
                Set<String> contractIds = new Set<String>();
                Set<String> reasonCodes = new Set<String>();
                for(OrderItem orderItemRel: fulfilmentReqLineId_OrderItems.get(fRLId)){
                    if(orderItemRel.vlocity_cmt__ParentItemId__c == null && orderItemRel.vlocity_cmt__ReliesOnItemId__c == null){
                        families.add(orderItemRel.Product2.Family);
                        contractIds.add(orderItemRel.vlocity_cmt__SubscriptionId__r.OM_Contract__c);
                        reasonCodes.add(orderItemRel.FVU_ReasonCode__c);
                    }
                    if(orderItemRel.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER) {
                        Map<String, Object> oIAttributes = (Map<String, Object>) JSON.deserializeUntyped(orderItemRel.vlocity_cmt__AttributeSelectedValues__c);
                        mSISDNs.add(String.valueOf(oIAttributes.get(OrderIntegrationSystemInterfaceConstants.ATTR_MSISDN)));
                    } else if (simCardProductCodes.contains(orderItemRel.Product2.ProductCode)) {// Verificar si el producto es una tarjeta SIM 
                        Boolean isChangeAction = orderItemRel.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_CHANGE;
                        Boolean isDisconnectAction = orderItemRel.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_DISCONNECT;
                        Boolean isChangeSimSubAction = orderItemRel.vlocity_cmt__SubAction__c.contains(OrderIntegrationSystemInterfaceConstants.ORD_SUBTYPE_CHANGESIM);
                        Boolean hasSerialNumber = String.isNotBlank(orderItemRel.vlocity_cmt__SerialNumber__c);
                        Boolean hasNewICCID = String.isNotBlank(orderItemRel.OM_newICCID__c);

                        if (isChangeAction && isChangeSimSubAction && hasNewICCID) { // Procesar el nuevo ICCID para operaciones de cambio
                            iCCIDs.add(orderItemRel.OM_newICCID__c);
                        } else if ((isChangeAction || isDisconnectAction) && isChangeSimSubAction && hasSerialNumber) {// Procesar el ICCID antiguo en casos específicos
                            iCCIDOlds.add(orderItemRel.vlocity_cmt__SerialNumber__c);
                        } else if (hasSerialNumber) {// Para cualquier otro caso con número de serie, añadir a ICCIDs
                            iCCIDs.add(orderItemRel.vlocity_cmt__SerialNumber__c);
                        }
                    }
                }
                orderDetails.OM_MSISDN__c = String.join(mSISDNs, ';');
                orderDetails.OM_ICCIDOld__c = String.join(iCCIDOlds, ';');
                orderDetails.OM_ICCIDNew__c = String.join(iCCIDs, ';');
                orderDetails.OM_ProductFamily__c = String.join(families, ';');
                orderDetails.OM_ContractId__c = String.join(contractIds, ';');
                orderDetails.OM_ReasonCode__c = String.join(reasonCodes, ';');
            }

            lstOrdersToUpdate.add(orderDetails);
        }

        if (!lstOrdersToUpdate.isEmpty()) {
            try {
                update lstOrdersToUpdate;
                System.debug('Órdenes actualizadas en este lote: ' + lstOrdersToUpdate.size());
            } catch (Exception e) {
                System.debug('Error actualizando órdenes: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId() WITH SECURITY_ENFORCED];
        String body = 'El proceso batch ha finalizado. \n\n';
        body += 'Registros procesados: ' + job.JobItemsProcessed + '\n';
        body += 'Registros con error: ' + job.NumberOfErrors + '\n';
        system.debug(body);
    }
}