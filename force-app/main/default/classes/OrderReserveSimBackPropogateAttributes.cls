/*--------------------------------------------------------------------------
Author:         Emmanuel Ruarte  - andres.ruarte@nespon.com
Company:        Nespon
Description:    Clase para pasar atributos desde el FFRL a order item en un cambio de SIM 
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
29-May-24         Emmanuel Ruarte       HDU-736687              inicial version
07-06-2024		 Hever Salas			HDU-736685				  1.0.1
----------------------------------------------------------------------------*/
global with sharing class OrderReserveSimBackPropogateAttributes implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> items){
        
        Map<String, String> techAttrBySelectedAttr = new Map<String, String>{
            'B2C-ATTR-IMSI'=>'TechRCimsi',
            'B2C-ATTR-ICCID'=>'TechRCiccid',
            'B2C-ATTR-SIM-PIN' => 'TechRCpin',
			'B2C-ATTR-SIM-PUK' => 'TechRCpuk',
            'B2C-ATTR-TECN-SIM' => 'TechAttrSIMTechnology'    
        };
        
        Set<String> techAtrrs = new Set<String>{'TechRCimsi','TechRCiccid','TechRCpin','TechRCpuk','TechAttrSIMTechnology'};
        
        String attrCatCode = OrderIntegrationSystemInterfaceHelper.getTechAttributeCategoryCode();//get category code of attribute category -> ex : 223541c2-e1cb-fe89-a86d-b07a65470f1b
        String auxICCID = '';
        vlocity_cmt__OrchestrationItem__c orchestItem = [SELECT Id, vlocity_cmt__AutoTaskParameters__c,
                                                         vlocity_cmt__OrchestrationPlanId__c,
                                                         vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                         vlocity_cmt__OrderItemId__c,
                                                         vlocity_cmt__FulfilmentRequestLineId__c
                                                         FROM vlocity_cmt__OrchestrationItem__c WHERE Id =: items[0].Id WITH SECURITY_ENFORCED];
        System.debug('========orchestItem======='+orchestItem);
        
        vlocity_cmt__FulfilmentRequestLine__c frl = [SELECT Id, vlocity_cmt__JSONAttribute__c
                                                     FROM vlocity_cmt__FulfilmentRequestLine__c
                                                     WHERE Id =: orchestItem.vlocity_cmt__FulfilmentRequestLineId__c WITH SECURITY_ENFORCED LIMIT 1];
        System.debug('========frl======='+frl);
        
        Map<String, Object> ipInput   = (Map<String, Object>)JSON.deserializeUntyped('{"FulfilmentRequestLineId":"'+frl.Id+'"}');       
        System.debug('========ipInput======='+ipInput);
		List<Map <String, Object>> getDRResult = OrderIntegrationSystemInterfaceHelper.callDrExtract(ipInput, 'OM_DR_GetFulfilmentRequestLineJsonAttributes');
        System.debug('========getDRResult======='+getDRResult);
        
        List<List<Object>> tempList = new List<List<Object>>();
        Map<String, String> attributeValueMap = new Map<String, String>();
        Map<String, Object> tempMap = new Map<String, Object>(); //FRS each item characteristics as key and value
        for(Map <String, Object> outputDRMap : getDRResult){ 
            for(String key1 : outputDRMap.keySet()){                
                Map<String, Object> deserialisedMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(outputDRMap.get(key1))) ; //attributecategory id=>all techAttribute items
                tempList.add((List<Object>)JSON.deserializeUntyped(JSON.serialize(deserialisedMap.get(attrCatCode))));// add list of attributes per attribute category node of each FR   
                for(List<Object> lst : tempList){
                    for(Object key2: lst){
                        tempMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(key2));
                        System.debug('========tempMap======='+tempMap);
                        System.debug((String)tempMap.get('Code')+'<<code========String.isNotEmpty((String)tempMap.get(Code))======='+String.isNotEmpty((String)tempMap.get('Code')));
                        System.debug((String)tempMap.get('SegmentValue')+'<<segmentvalue========techAttrBySelectedAttr.containsKey((String)tempMap.get(Code))======='+techAtrrs.contains((String)tempMap.get('Code')));
                        if(String.isNotEmpty((String)tempMap.get('Code')) && techAtrrs.contains((String)tempMap.get('Code'))){
                            attributeValueMap.put((String)tempMap.get('Code'), (String.isNotEmpty((String)tempMap.get('SegmentValue'))) ? (String)tempMap.get('SegmentValue') : '');
                        }
                    }  
                }
            } 
        }
        System.debug('========attributeValueMap======='+attributeValueMap);
        List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> frlDecomposeList = [SELECT Id, vlocity_cmt__SourceOrderItemId__c 
                                                                                          from vlocity_cmt__FulfilmentRequestLineDecompRelationship__c
                                                                                          where vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c =: orchestItem.vlocity_cmt__OrchestrationPlanId__c
                                                                                          and vlocity_cmt__DestinationFulfilmentRequestLineId__c =: orchestItem.vlocity_cmt__FulfilmentRequestLineId__c
                                                                                          AND vlocity_cmt__SourceOrderItemId__r.Product2.Name = 'SIM Card' WITH SECURITY_ENFORCED
                                                                                         ];
        System.debug('========frlDecomposeList======='+frlDecomposeList);
        List<OrderItem> oiUpdateList = new List<OrderItem>();
        Map<String, object> oliAttributeSelectedValue  = new Map<String, object>();
        for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c vcfrldr : frlDecomposeList){
            System.debug('========vcfrldr======='+vcfrldr);
            for(OrderItem oi : [SELECT Id, vlocity_cmt__AttributeSelectedValues__c, vlocity_cmt__SerialNumber__c 
                                FROM OrderItem 
                                WHERE Id =: vcfrldr.vlocity_cmt__SourceOrderItemId__c WITH SECURITY_ENFORCED])
            {
                System.debug('========oi======='+oi);
                oliAttributeSelectedValue = (Map<String,Object>)JSON.deserializeUntyped(oi.vlocity_cmt__AttributeSelectedValues__c);
                for(String key : oliAttributeSelectedValue.keySet()){
                 
                    if(techAttrBySelectedAttr.containsKey(key)){
                        oliAttributeSelectedValue.put(key, (String.isNotEmpty((String)techAttrBySelectedAttr.get(key)))? (Object)attributeValueMap.get((String)techAttrBySelectedAttr.get(key)) : '');
                    	if((String)techAttrBySelectedAttr.get(key) == 'TechRCiccid'){ //[COE-2025-12-18 - HU695834]: Changed "key" for "(String)techAttrBySelectedAttr.get(key)""
                            auxICCID = (String)attributeValueMap.get((String)techAttrBySelectedAttr.get(key));
                            system.debug('auxICCID '+auxICCID);
                        }
                    }
                }
                oi.vlocity_cmt__AttributeSelectedValues__c = JSON.serializePretty(oliAttributeSelectedValue);
                System.debug('========oi.vlocity_cmt__AttributeSelectedValues__c======='+oi.vlocity_cmt__AttributeSelectedValues__c);
                System.debug('========oiUpdateList======='+oiUpdateList);
                if(String.isEmpty(oi.vlocity_cmt__SerialNumber__c) && String.isNotEmpty(auxICCID))
                {                 	
                    oi.vlocity_cmt__SerialNumber__c = auxICCID;   //[COE-2025-12-18 - HU695834]: Enabled this line to backPropagate to OI the ICCID in Pre-a-Pos Orders
                }                
                oiUpdateList.add(oi);
            }
        }
        
        if(!oiUpdateList.isEmpty() && oiUpdateList <> null){
            System.debug('==IF ==oiUpdateList==='+oiUpdateList);
            update oiUpdateList;
        }
    }
    
    
                        
    /*System.debug('========tempMap======='+tempMap);
    if('TechPCnewIMSI'.equalsIgnoreCase((String)tempMap.get('Code')) ){
    System.debug('========TechPCnewIMSI=======');
    attributeValueMap.put('TechPCnewIMSI', (String)tempMap.get('SegmentValue'));
    }if('TechRCiccid'.equalsIgnoreCase((String)tempMap.get('Code')) ){
    System.debug('========TechRCiccid=======');
    attributeValueMap.put('TechRCiccid', (String)tempMap.get('SegmentValue'));
    }*/
    
    
    /*if(key.equalsIgnoreCase('B2C-ATTR-IMSI')){
    System.debug('========B2C-ATTR-IMSI=======');
    oliAttributeSelectedValue.put('B2C-ATTR-IMSI', (Object)attributeValueMap.get('TechPCnewIMSI'));
    
    
    }else if(key.equalsIgnoreCase('B2C-ATTR-ICCID')){
    System.debug('========B2C-ATTR-ICCID=======');
    oliAttributeSelectedValue.put('B2C-ATTR-ICCID', (Object)attributeValueMap.get('TechRCiccid'));
    }*/ 
}