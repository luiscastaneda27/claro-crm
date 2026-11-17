/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    	<Version>
03-06-24      Hever Salas    Utility class to update technical attributes JSON       	inicial version
16-09-24	Hever Salas		Se agregan varios valores para una misma clave Bug-420406	      v1.1	
15-10-24	Emmanuel Ruarte Se agrega condicional en caso de valor null HDU-433728			  V1.2
----------------------------------------------------------------------------*/

global with sharing class OM_UpdateOldAttributes implements vlocity_cmt.VlocityOpenInterface {
    
    class MyException extends Exception{}
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('updateOldAttributes')){
                updateOldAttributes(inputMap, outMap, options);
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
    
    public void updateOldAttributes(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        
        Map<String,Object> outAuxMap = new Map<String,Object>();
        List<Object> lstResult = new List<Object>();
        Map<String,Object> mapAttributes = new Map<String,object>();
        Map<String,Object> objectAttribute = (Map<String,Object>)inputMap.get('JSONAttribute'); 
        mapAttributes = (Map<String,Object>)inputMap.get('mapAttributes');      
        Set<String> setAttributes = mapAttributes.keyset(); 
        Map<String,Object> newValues = new Map<String,Object>();
        lstResult = (List<Object>)objectAttribute.values()[0];
        
        //limpiar valores en atributos nuevos
        for(Object ItemAttribute: lstResult){           
            Map<String, Object> attributeRunTimeInfo = new Map<String,Object>();
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            if(setAttributes.contains((String)attribute.get('Code'))){
				//Se obtiene la lista de valores para una misma clave v1.1
                Object oldAttrs = mapAttributes.get((String)attribute.get('Code'));
                if(oldAttrs != null){  //V1.2
                    List<String> lstCode = ((String)oldAttrs).split(',');
                    for(String itemCode :lstCode){
                        //Se recorren los atributos para generar N cantidad valores v1.1
                        newValues.put(itemCode, (String)attribute.get('SegmentValue'));
                    }    
                }
                attributeRunTimeInfo = (Map<String,Object>)attribute.get('attributeRunTimeInfo');
                attributeRunTimeInfo.put('value', '');
                attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                attribute.put('SegmentValue', '');
            }
            ItemAttribute = attribute;
        }
        
        Set<String> setAttributesOld = newValues.keyset();
        //agregar valores en atributos viejos
        for(Object ItemAttribute: lstResult){           
            Map<String, Object> attributeRunTimeInfo = new Map<String,Object>();
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            if(setAttributesOld.contains((String)attribute.get('Code'))){            
                attributeRunTimeInfo = (Map<String,Object>)attribute.get('attributeRunTimeInfo');
                attributeRunTimeInfo.put('value', (String)newValues.get((String)attribute.get('Code')));
                attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                attribute.put('SegmentValue', (String)newValues.get((String)attribute.get('Code')));
            }
            ItemAttribute = attribute;
        }
        outAuxMap.put('223541c2-e1cb-fe89-a86d-b07a65470f1b', lstResult);
        outMap.put('result',outAuxMap);
    }
}