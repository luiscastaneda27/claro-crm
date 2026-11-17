/*---------------------------------------------------------------------------------------------------------------
--- Author: Emmanuel Ruarte
--- Description: Clase para actualizacion de atributos en order Item SIM Card
--- CreateDate:  27/02/2024
--- Update for: 
--- UpdateDate: 
--- Update Description: 
---------------------------------------------------------------------------------------------------------------*/
global with sharing class UpdateAttributeOrderItem implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    
    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> items){
        
        vlocity_cmt__OrchestrationItem__c orchestItem = [SELECT Id, vlocity_cmt__AutoTaskParameters__c,
                                                         vlocity_cmt__OrchestrationPlanId__c,
                                                         vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                         vlocity_cmt__OrderItemId__c,
                                                         vlocity_cmt__FulfilmentRequestLineId__c
                                                         FROM vlocity_cmt__OrchestrationItem__c WHERE Id =: items[0].Id];
        String ICCID = '';
        String IMSI = '';
        String AtributeSelectedValueOItem = ''; 
        
        Map<String, object> inputMap = new Map<String, object>();
        Map<String, object> outputMap = new Map<String, object>();
        Map<String, object> optionsMap = new Map<String, object>();
        
        List<OrderItem> oItemLst = [SELECT Id, Product2.ProductCode, vlocity_cmt__AssetId__c, vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, Product2.vlocity_cmt__SubType__c,vlocity_cmt__AttributeSelectedValues__c 
                                    FROM OrderItem 
                                    WHERE OrderId =: orchestItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c];
        
        system.debug('oItemLst:::::' +oItemLst);
        
        /*------------ Commenting for error 12/03/2024, 4:55 a. m. FATAL Exception while running the batch: Invalid conversion from runtime type List<ANY> to Map<String,ANY> Class.UpdateAttributeOrderItem.executeBatch: line 33, column 1
(System Code) ------ By Mamata, Uncomment for fixing----------*/
        
        System.debug('=====orchestItem.vlocity_cmt__AutoTaskParameters__c====='+orchestItem.vlocity_cmt__AutoTaskParameters__c);
        Map<string, Object> input = (Map<string, Object>)JSON.deserializeUntyped(orchestItem.vlocity_cmt__AutoTaskParameters__c);
        string source_attr_code = (string)input.get('source_attr_code');
        string destination_attr_code = (string)input.get('destination_attr_code');
        
        
        
        vlocity_cmt__FulfilmentRequestLine__c frl = [SELECT id, vlocity_cmt__JSONAttribute__c
                                                     FROM vlocity_cmt__FulfilmentRequestLine__c
                                                     WHERE Id =: orchestItem.vlocity_cmt__FulfilmentRequestLineId__c LIMIT 1];
        system.debug('frl:::::' + frl);
        String jsonAttribute = frl.vlocity_cmt__JSONAttribute__c;
        System.debug('===jsonAttribute====='+jsonAttribute);
        /* vlocity_cmt__FulfilmentRequestLineDecompRelationship__c FFRLDescomp = [ SELECT vlocity_cmt__SourceOrderItemId__c,
                                                                                    vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Product2Id__r.Name,  
                                                                                    vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Product2Id__r.vlocity_cmt__Type__c, 
                                                                                    vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c, 
                                                                                    vlocity_cmt__DestinationFulfilmentRequestLineId__c
                                                                                    FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c
                                                                                    WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c = orchestItem.vlocity_cmt__OrchestrationPlanId__c
                                                                                    ]; */ // commented query - mamata
        
        
        Map<String, object> jsonMap = (Map<String,Object>)JSON.deserializeUntyped(jsonAttribute);
        jsonMap.get('categorycode__c');
        system.debug('jsonMap:::::' + jsonMap);
        
        List<object> listGeneral = (List<object>)jsonMap.get('223541c2-e1cb-fe89-a86d-b07a65470f1b');
        system.debug('listGeneral :::::' + listGeneral);
        
        List<object> newListGeneral = new List<object>(); 
        for(object obj: listGeneral ){   
            Map<String, object> objMap = (Map<String, object>) obj;
            system.debug('objMap:::: ' + objMap );
            
            string attribute = (string)objMap.get('attributeuniquecode__c');
            if(attribute == 'TechRCiccid'){
                system.debug('attribute::: ' + attribute );  
                Map<String, object> jsonMapInfo = (Map<String,Object>)objMap.get('attributeRunTimeInfo');
                ICCID = (string)jsonMapInfo.get('value');
                system.debug('jsonMapInfo :::::' + jsonMapInfo);  
            }
            if(attribute == 'TechPCnewIMSI'){
                system.debug('attributeimsi::: ' + attribute );  
                Map<String, object> jsonMapInfo = (Map<String,Object>)objMap.get('attributeRunTimeInfo');
                IMSI = (string)jsonMapInfo.get('value');
                system.debug('jsonMapInfo :::::' + jsonMapInfo);  
            }
            
        }
        System.debug('IMSI::: '+ IMSI);
        
        
        for(OrderItem oItem : oItemLst){
            if( oItem.Product2.vlocity_cmt__SubType__c == 'SIM Card' &&
               oItem.Product2.ProductCode == 'B2C-MOB-OFR-SIM'){
                   Map<String, object> jsonMapp = (Map<String,Object>)JSON.deserializeUntyped(oItem.vlocity_cmt__AttributeSelectedValues__c);
                   jsonMapp.put('B2C-ATTR-IMSI', IMSI);
                   jsonMapp.put('B2C-ATTR-ICCID', ICCID);
                   system.debug('jsonMapp update :::::' + jsonMapp); 
                   
               }
            update oItemLst ;  
        }
        
    }
}