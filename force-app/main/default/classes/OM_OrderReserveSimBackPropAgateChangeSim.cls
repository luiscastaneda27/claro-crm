/*--------------------------------------------------------------------------
Author:         Emmanuel Ruarte  - andres.ruarte@nespon.com
Company:        Nespon
Description:    Clase para pasar atributos desde el FFRL a order item en un cambio de SIM 
Code Coverage:  100%
History
<Date>            <Author>             <Description>             			<Version>
29-May-24         Emmanuel Ruarte       HDU-736687              		inicial version
03-07-2024		Hever Salas				HDU-348282							1.0.1
22-07-2024		Hever Salas			Se agrega ProductCode adicional			1.0.2
----------------------------------------------------------------------------*/
global with sharing class OM_OrderReserveSimBackPropAgateChangeSim implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> items){
        
        OrderReserveSimBackPropogateAttributes orderReserveSim = new OrderReserveSimBackPropogateAttributes();
        Map<String, String> techAttrBySelectedAttr = new Map<String, String>{
            
            'B2C-ATTR-IMSI'=>'TechPCnewIMSI',
                'B2C-ATTR-ICCID'=>'TechPCnewICCID',
                'B2C-ATTR-SIM-PIN' => 'TechPCnewPIN',
                'B2C-ATTR-SIM-PUK' => 'TechPCnewPUK',
                'B2C-ATTR-TECN-SIM' => 'TechAttrSIMTechnology'    
                };
                    
        Set<String> techAtrrs = new Set<String>{'TechPCnewIMSI','TechPCnewICCID','TechPCnewPIN','TechPCnewPUK','TechAttrSIMTechnology'};             
        String attrCatCode = OrderIntegrationSystemInterfaceHelper.getTechAttributeCategoryCode();//get category code of attribute category -> ex : 223541c2-e1cb-fe89-a86d-b07a65470f1b
        String auxICCID = '';
        
        vlocity_cmt__OrchestrationItem__c orchestItem = [SELECT Id, vlocity_cmt__AutoTaskParameters__c,
                                                         vlocity_cmt__OrchestrationPlanId__c,
                                                         vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                         vlocity_cmt__OrderItemId__c,
                                                         vlocity_cmt__FulfilmentRequestLineId__c
                                                         FROM vlocity_cmt__OrchestrationItem__c WHERE Id =: items[0].Id WITH SECURITY_ENFORCED];
        System.debug('========orchestItem======='+orchestItem);
        
        vlocity_cmt__FulfilmentRequestLine__c frl = [SELECT Id, vlocity_cmt__JSONAttribute__c, vlocity_cmt__SubAction__c
                                                     FROM vlocity_cmt__FulfilmentRequestLine__c
                                                     WHERE Id =: orchestItem.vlocity_cmt__FulfilmentRequestLineId__c WITH SECURITY_ENFORCED LIMIT 1];
        System.debug('========frl======='+frl);
        
        //if(frl.vlocity_cmt__SubAction__c == 'ChangeSim-Modify'){
            
            Map<String, Object> ipInput   = (Map<String, Object>)JSON.deserializeUntyped('{"FulfilmentRequestLineId":"'+frl.Id+'"}');       
            System.debug('========ipInput======='+ipInput);
            List<Map <String, Object>> getDRResult = OrderIntegrationSystemInterfaceHelper.callDrExtract(ipInput, 'OM_DR_GetFulfilmentRequestLineJsonAttributes');
            System.debug('========getDRResult======='+getDRResult);
            
            if(Test.isRunningTest()){
                List<String> listkeyset = new List<String>(getDRResult[0].keyset()) ; 
                getDRResult[0]=(Map <String, Object>) getDRResult[0].get(listkeyset[0]);
            }
            List<Object> tempList = new List<Object>();
            Map<String, String> attributeValueMap = new Map<String, String>();
            Map<String, Object> tempMap = new Map<String, Object>(); //FRS each item characteristics as key and value
            //Barre los atributos del JSON para obtener los valores techAtrrs y colocarlos en oitem  
            for(Map <String, Object> outputDRMap : getDRResult){ 
                for(String key1 : outputDRMap.keySet()){
                    Map<String,Object> deserialisedMap = (Map<String,Object>)outputDRMap.get(key1) ; //attributecategory id=>all techAttribute items
                    system.debug('=====attrCatCode====='+attrCatCode);
                    tempList.addall((List<Object>)deserialisedMap.get(attrCatCode));// add list of attributes per attribute category node of each FR   
                    
                    for(Object objAttr : tempList){
                        Map<String,Object> mapAttr = (Map<String,Object>)objAttr;
                        if(String.isNotEmpty((String)mapAttr.get('Code')) && techAtrrs.contains((String)mapAttr.get('Code'))){
                            attributeValueMap.put((String)mapAttr.get('Code'), (String.isNotEmpty((String)mapAttr.get('SegmentValue'))) ? (String)mapAttr.get('SegmentValue') : '');
                            
                        }  
                    }
                } 
            }
            System.debug('========attributeValueMap======='+attributeValueMap);
            
            
            List<OrderItem> oiUpdateList = new List<OrderItem>();
            Map<String, object> oliAttributeSelectedValue  = new Map<String, object>();
            /**
            * @description: Desde catálogo se realizó una actualización del ProductoCode en el producto SIM Card
            * B2C-ATTR-SIM-MATERIAL  -->  B2C-MOV-OFR-SIMCARD
            **/
            for(OrderItem oi : [SELECT Id, vlocity_cmt__AttributeSelectedValues__c, vlocity_cmt__SerialNumber__c 
                                FROM OrderItem 
                                WHERE Id IN (SELECT  vlocity_cmt__SourceOrderItemId__c 
                                             FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c
                                             WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c =: orchestItem.vlocity_cmt__OrchestrationPlanId__c
                                             AND vlocity_cmt__DestinationFulfilmentRequestLineId__c =: orchestItem.vlocity_cmt__FulfilmentRequestLineId__c
                                             AND vlocity_cmt__SourceOrderItemId__r.Product2.ProductCode IN ('B2C-ATTR-SIM-MATERIAL', :OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD, :OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD)
                                             AND (vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Action__c = 'Change'
                                                 OR vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Action__c = 'Add'))
                               WITH SECURITY_ENFORCED])
            {
                System.debug('========oi======='+oi);
                oliAttributeSelectedValue = (Map<String,Object>)JSON.deserializeUntyped(oi.vlocity_cmt__AttributeSelectedValues__c);
                for(String key : oliAttributeSelectedValue.keySet()){
                    
                    if(techAttrBySelectedAttr.containsKey(key)){
                        oliAttributeSelectedValue.put(key, (String.isNotEmpty((String)techAttrBySelectedAttr.get(key)))? (Object)attributeValueMap.get((String)techAttrBySelectedAttr.get(key)) : '');
                        if(key == 'B2C-ATTR-ICCID'){
                            auxICCID = (String)attributeValueMap.get((String)techAttrBySelectedAttr.get(key));
                        }
                    }
                }
                oi.vlocity_cmt__AttributeSelectedValues__c = JSON.serializePretty(oliAttributeSelectedValue);
                System.debug('========oi.vlocity_cmt__AttributeSelectedValues__c======='+oi.vlocity_cmt__AttributeSelectedValues__c);
                System.debug('========oiUpdateList======='+oiUpdateList);
                oi.vlocity_cmt__SerialNumber__c = auxICCID;
                oiUpdateList.add(oi);
            }
            
            if(!oiUpdateList.isEmpty() && oiUpdateList <> null){
                System.debug('==IF ==oiUpdateList==='+oiUpdateList);
                update oiUpdateList;
            }
        /*}else{
            if(frl.vlocity_cmt__SubAction__c == 'Resume-Reactivate-ChangeSim'){
                orderReserveSim.executeBatch(items);
            }
        }*/
    }
    
}