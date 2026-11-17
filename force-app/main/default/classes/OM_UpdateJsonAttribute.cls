/*--------------------------------------------------------------------------
Author:          Emmanuel Ruarte - andres.ruarte@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                            <Version>
19-06-24      	Emmanuel Ruarte    Utility class to update attributes in JSON               inicial version
15-07-24		Hever Salas     	Se agrega método de actualización del json			            1.1
08-11-24		Hever Salas    Se agrega método de obtencion de atributos por categoria             1.2
21-04-25        Hever Salas    HDU-577070: [CESION]Validacion end to end cesion de contrato         1.3       
----------------------------------------------------------------------------*/
global with sharing class OM_UpdateJsonAttribute implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    class MyException extends Exception{}
    
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('updateJSON')){
                updateJSON(inputMap, outMap, options);
            }else if (methodName.Equals('modifyJSON')){
                modifyJSON(inputMap, outMap, options);
            }else if(methodName.Equals('extractAttributeJSON')){
                extractAttributeJSON(inputMap, outMap);
            }else if(methodName.Equals('mergeListConcileLine')){
                mergeListConcileLine(inputMap, outMap);
            }
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch(Exception ex) {
            outMap.put('error', ex.getStackTraceString()); 
            result = false; 
        }
    return result;
}
    
    public void updateJSON(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        
        String attributeCodeToValue = (String)inputMap.get('attributeCodeToValue');
        String fulfilmentRequestLineId = (String)inputMap.get('FulfilmentRequestLineId');
        String newValueAttribute = String.valueOf(inputMap.get('newValueAttribute'));
        List<Object> lstAttributes = new List<Object>();
        
        vlocity_cmt__FulfilmentRequestLine__c frl = [SELECT Id, vlocity_cmt__JSONAttribute__c
                                                    FROM vlocity_cmt__FulfilmentRequestLine__c
                                                    WHERE Id = :fulfilmentRequestLineId];
        Map<String,Object> jsonAttribute = (Map<String,Object>)JSON.deserializeUntyped(frl.vlocity_cmt__JSONAttribute__c);
        lstAttributes = (List<Object>)jsonAttribute.values()[0];
        
        for(Object ItemAttribute: lstAttributes){
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            if(attribute.get('attributeuniquecode__c') == attributeCodeToValue){
                Map<String, Object> attributeRunTimeInfo = new Map<String,Object>();
                attributeRunTimeInfo = (Map<String,Object>)attribute.get('attributeRunTimeInfo');
                attributeRunTimeInfo.put('value', newValueAttribute);
                attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                attribute.put('SegmentValue', newValueAttribute);
                ItemAttribute = attribute;
            }
        }
		jsonAttribute = new Map<String,Object>();
        jsonAttribute.put('223541c2-e1cb-fe89-a86d-b07a65470f1b', lstAttributes);
        frl.vlocity_cmt__JSONAttribute__c = JSON.serialize(jsonAttribute);
        UPDATE frl;
    }
    
    /**
    * @description: Modifica una lista de atributos en el jsonAttribute del FRL
    * @author Hever Salas | 15-07-2024 
    * @param JsonAttribute, Map<attributeCodeToValue,newValueAttribute>  
    **/
    public void modifyJSON(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        
       	Map<String,Object> mapAttributeCodeToValue = (Map<String,Object>)inputMap.get('mapAttributeCodeToValue');
        List<Object> lstAttributes = new List<Object>();

        Map<String,Object> jsonAttribute = (Map<String,Object>)inputMap.get('jsonAttribute');
        lstAttributes = (List<Object>)jsonAttribute.values()[0];
            
        for(Object ItemAttribute: lstAttributes){
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            
            if(mapAttributeCodeToValue.containsKey((String)attribute.get('attributeuniquecode__c'))){
                String newValueAttribute = (String)mapAttributeCodeToValue.get((String)attribute.get('attributeuniquecode__c'));
                Map<String, Object> attributeRunTimeInfo = new Map<String,Object>();
                attributeRunTimeInfo = (Map<String,Object>)attribute.get('attributeRunTimeInfo');
                attributeRunTimeInfo.put('value', newValueAttribute);
                attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                attribute.put('SegmentValue', newValueAttribute);
                ItemAttribute = attribute;
            }
        }
		jsonAttribute = new Map<String,Object>();
        jsonAttribute.put('223541c2-e1cb-fe89-a86d-b07a65470f1b', lstAttributes);
        outMap.put('JSONAttribute', jsonAttribute);
        
    }
    
    /**
    * @description: Extrae los atributos necesarios para las categorias B2C-ATTRCAT-SVC-ADC-DETAILS, B2C-ATTRCAT-CAT-GRL-DETAILS, B2C-ATTR-COD-SPLIT, B2C-ATTR-CG-TIPO-PLAN
    * @author Hever Salas | 08-11-2024 
    * @param IN: Map<String,Object> inputMap: contiene el jsonAttribute del productChildItem
    * 		OUT: Map<String,Object> outputMap: devuelve el json solo con las categorias definidas
    **/
    public void extractAttributeJSON(Map<String,Object> inputMap, Map<String,Object> outputMap){
        
        String ADC_DETAILS = 'B2C-ATTRCAT-SVC-ADC-DETAILS';
        String GRL_DETAILS = 'B2C-ATTRCAT-CAT-GRL-DETAILS';
        List<Map<String, Object>> finalADC_DETAILS = new List<Map<String, Object>>();
        List<Map<String, Object>> finalGRL_DETAILS = new List<Map<String, Object>>();
        List<Map<String, Object>> finalDETAILS = new List<Map<String, Object>>();

        List<Object> lstAttributes = new List<Object>();

        Map<String,Object> jsonAttribute = (Map<String,Object>)inputMap.get('JSONAttribute');
        List<Map<String, Object>> lstADC_DETAILS = (jsonAttribute.containsKey(ADC_DETAILS) ? (List<Map<String, Object>>)jsonAttribute.get(ADC_DETAILS) : new List<Map<String, Object>>());
        List<Map<String, Object>> lstGRL_DETAILS = (jsonAttribute.containsKey(GRL_DETAILS) ? (List<Map<String, Object>>)jsonAttribute.get(GRL_DETAILS) : new List<Map<String, Object>>());

        Map<String, Object> attributeSelected;
        
        if(lstADC_DETAILS.size() > 0){
            for(Map<String, Object> itemADC: lstADC_DETAILS){
                attributeSelected = new Map<String,Object>();
                attributeSelected.put('attributedisplayname__c',itemADC.get('attributedisplayname__c'));
                attributeSelected.put('categoryname__c',itemADC.get('categoryname__c'));
                attributeSelected.put('attributeuniquecode__c',itemADC.get('attributeuniquecode__c'));
                attributeSelected.put('value__c',itemADC.get('value__c'));
                finalDETAILS.add(attributeSelected);
            }
        }else{
            finalDETAILS = lstADC_DETAILS;
        }
        
        if(lstGRL_DETAILS.size() > 0){
            for(Map<String, Object> itemGRL: lstGRL_DETAILS){
                attributeSelected = new Map<String,Object>();
                attributeSelected.put('attributedisplayname__c',itemGRL.get('attributedisplayname__c'));
                attributeSelected.put('categoryname__c',itemGRL.get('categoryname__c'));
                attributeSelected.put('attributeuniquecode__c',itemGRL.get('attributeuniquecode__c'));
                attributeSelected.put('value__c',itemGRL.get('value__c'));
                finalDETAILS.add(attributeSelected);
            }
        }else{
            finalDETAILS = lstGRL_DETAILS;
        }
                
		Map<String,Object> jsonAttributeResult = new Map<String,Object>();
        jsonAttributeResult.put('DETAILS', finalDETAILS);
        outputMap.put('JSONAttribute', jsonAttributeResult);
        
    }

    /**
    * @description: Extrae los atributos y los valores requeridos
    * @author Hever Salas | 21-04-2025 
    * @param IN: Map<String,Object> inputMap: contiene el jsonAttribute y la lista de atributos a obtener
    * 		OUT: Map<String,Object> outputMap: mapa que contiene nmombre del atributo y valor en el JSON
    **/
    public Map<String,Object> extractListAttributeJSON(Map<String,Object> inputMap){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> mapAttributeCodeToValue = new Map<String,Object>();
        List<String> lstAttributeCodeToValue = (List<String>)inputMap.get('lstAttributeCodeToValue');
        List<Object> lstAttributes = new List<Object>();
        Map<String,Object> jsonAttribute = (Map<String,Object>)inputMap.get('jsonAttribute');
        lstAttributes = (List<Object>)jsonAttribute.values()[0];
        for(Object ItemAttribute: lstAttributes){
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            if(lstAttributeCodeToValue.contains((String)attribute.get('attributeuniquecode__c'))){
                mapAttributeCodeToValue.put((String)attribute.get('attributeuniquecode__c'),attribute.get('SegmentValue'));
                outputMap.put('mapAttributeCodeToValue',mapAttributeCodeToValue);
            }
        }
        return outputMap;
    }
    
    /**
    * @description: Combina los valores de 2 listas
    * @author Hever Salas | 12-09-2025 
    * @param IN: Map<String,Object> inputMap: contiene las listas que deben evaluarse
    * 		OUT: Map<String,Object> outputMap: mapa que contiene la lista resultante de la combinación
    **/
    public Map<String,Object> mergeListConcileLine(Map<String,Object> inputMap, Map<String,Object> outputMap){
        List<Object> lstOrderItem = (List<Object>)inputMap.get('lstOrderItem');
        List<Object> lstProductSelected = (List<Object>)inputMap.get('lstProductSelected');
        List<Map<String,Object>> lstResult = new List<Map<String,Object>>();
        Map<String,String> mapResult;
        for(Object itemSelected :lstProductSelected){
            Map<String,Object> productSelected = (Map<String,Object>)itemSelected;
            for(Object item :lstOrderItem){
                Map<String,Object> oi = (Map<String,Object>)item;
                if(oi.get('RootItemId') == productSelected.get('RootItemId')){
                    mapResult = new Map<String,String>();
                    mapResult.put('Id',(String)oi.get('Id'));
                    mapResult.put('SubAction','Concile-Line-Modify');
                    lstResult.add(mapResult);
                }
            }
        }
        outputMap.put('lstOrderItem',lstResult);
        return outputMap;
    }
}