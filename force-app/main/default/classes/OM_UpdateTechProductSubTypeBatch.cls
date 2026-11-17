/*--------------------------------------------------------------------------
Author:         hever.salas@nespon.com
Description:    Clase para ejecutar la actualización de JSONAttribute__c
                en InventoryItem relacionados a PO_MovPosOptOTT
Code Coverage:  95%
History
<Date>            <Author>             <Description>                                            	<Version>
11-03-2026       Hever Salas    HDU-718193: Comportamiento en proceso cambio de numero         		  1.0       
----------------------------------------------------------------------------*/

global with sharing class OM_UpdateTechProductSubTypeBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Integer totalUpdated = 0;
    global Integer totalErrors = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, vlocity_cmt__JSONAttribute__c   
            FROM vlocity_cmt__InventoryItem__c  
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT' 
            WITH SECURITY_ENFORCED
            ORDER BY Id
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<vlocity_cmt__InventoryItem__c> inventoryItems) {
        
        Map<String, Object> newSelectedItem = (Map<String, Object>)JSON.deserializeUntyped(
            '{"value": "AddOnOTTTechProduct","displayText": "AddOnOTTTechProduct","id": "066bf847-8e1f-1df2-bed5-b80581a8666b"}'
        );
        
        List<Object> newValues = (List<Object>)JSON.deserializeUntyped(
            '[{"value": "AddOnOTTTechProduct","displayText": "AddOnOTTTechProduct","id": "066bf847-8e1f-1df2-bed5-b80581a8666b"},{"value":"BaseTechProduct","displayText":"BaseTechProduct","id":"74ef2b34-cfb8-cf6b-4343-e927b9c93cae"},{"value":"ChildTechProduct","displayText":"ChildTechProduct","id":"4af3fa2a-8a80-70a4-12d7-fbec346fc2dc"},{"value":"AddOnTechProduct","displayText":"AddOnTechProduct","id":"09f334ad-2738-fc0b-e4a1-07a94c662872"},{"value":"SuspTechProduct","displayText":"SuspTechProduct","id":"64d04ca2-46c0-c22e-4445-88e34c0cf5b4"},{"value":"AdminChargeTechProduct","displayText":"AdminChargeTechProduct","id":"69bf7e3a-a157-408e-e2d4-62045aa91950"},{"value":"CancelTechProduct","displayText":"CancelTechProduct","id":"d2d80c89-8dee-4f04-e2dd-c46faee24435"}]'
        );
        
        List<vlocity_cmt__InventoryItem__c> itemsToUpdate = new List<vlocity_cmt__InventoryItem__c>();
        
        for (vlocity_cmt__InventoryItem__c item : inventoryItems) {
            try {
                if (String.isNotBlank(item.vlocity_cmt__JSONAttribute__c)) {
                    String keyName = '';
                    List<Object> lstAttributes = new List<Object>();
                    Map<String, Object> jsonAttribute = (Map<String, Object>)JSON.deserializeUntyped(item.vlocity_cmt__JSONAttribute__c);
                    
                    for (String key : jsonAttribute.keySet()) {
                        lstAttributes = (List<Object>)jsonAttribute.get(key);
                        keyName = key;
                        break;
                    }
                    
                    Boolean found = false;
                    for (Object itemAttribute : lstAttributes) {
                        Map<String, Object> attribute = (Map<String, Object>)itemAttribute;
                        if (attribute.get('attributeuniquecode__c') == 'TechProductSubType') {
                            Map<String, Object> attributeRunTimeInfo = (Map<String, Object>)attribute.get('attributeRunTimeInfo');
                            attributeRunTimeInfo.put('selectedItem', newSelectedItem);
                            attributeRunTimeInfo.put('values', newValues);
                            attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                            attribute.put('SegmentValue', 'AddOnOTTTechProduct');
                            found = true;
                            break;
                        }
                    }
                    
                    if (found) {
                        Map<String, Object> newJsonAttribute = new Map<String, Object>();
                        newJsonAttribute.put(keyName, lstAttributes);
                        item.vlocity_cmt__JSONAttribute__c = JSON.serialize(newJsonAttribute);
                        itemsToUpdate.add(item);
                    }
                }
            } catch (Exception e) {
                System.debug('Error al procesar item ' + item.Id + ': ' + e.getMessage());
                totalErrors++;
            }
        }
        
        if (!itemsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(itemsToUpdate, false);
            
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    totalUpdated++;
                } else {
                    totalErrors++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('===== RESUMEN FINAL =====');
        System.debug('Total de registros actualizados: ' + totalUpdated);
        System.debug('Total de errores: ' + totalErrors);
        
        // Opcional: Enviar email de notificación
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('Batch Job Status: ' + job.Status);
    }
}