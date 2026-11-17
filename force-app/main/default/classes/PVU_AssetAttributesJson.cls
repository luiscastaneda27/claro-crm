/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : Nilyan Berti
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   02-09-2024   SALESFORCE   Initial Version
**/

global with sharing class PVU_AssetAttributesJson implements vlocity_cmt.VlocityOpenInterface2{
    static global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        Boolean result = false;
        try {
            if ('getBloqueos'.equalsIgnoreCase(methodName)) {
                getBloqueos(inputMap,outMap);
                result = true;
            } 
        } catch (Exception e) {
                system.debug('Error');
        }
        return result;
    }


static public void getBloqueos(Map<String,Object> inputMap,Map<String,Object> outMap){
        Map<String, Object> finalMap = new Map<String, Object>();
        List<String> codigos = new List<String>();
        Map<String, Object> allAttribute = new Map<String, Object>();
        Map<String, Object> responseData;
        List< Map<String, Object>> responseOut = new List< Map<String, Object>>();
        List< Map<String, Object>> responseInactivo = new List< Map<String, Object>>();
        for (String key : inputMap.keySet()) {
            Map<String, Object> inMap = (Map<String, Object>)inputMap.get(key);
            for (String inKey : inMap.keySet())
            {                     
                String values = (String)inMap.get(inKey);
                Map<String, Object> resultMap2 = (Map<String, Object>) JSON.deserializeUntyped(values);
              
                for (String inKey2 : resultMap2.keySet())
                    {
                        if(inKey2.contains('B2C-ATTR-FYB-')){
                            codigos.add(inKey2);
                            allAttribute.putAll(resultMap2);
                        } 
                    }
                }
            }
            
        try {
                List<vlocity_cmt__Attribute__c>  lista = [SELECT Id, Name, vlocity_cmt__Code__c FROM vlocity_cmt__Attribute__c WHERE vlocity_cmt__Code__c in:codigos WITH USER_MODE];            
                System.debug('Lista: ' + lista );
                if (lista != null && !lista.isEmpty()) {
                    for (vlocity_cmt__Attribute__c cdg : lista) {
                        
                        for (String cdgAll : allAttribute.keySet()) {
                            Object value = allAttribute.get(cdgAll);
                             if(cdg.vlocity_cmt__Code__c == cdgAll) {
                                responseData = new Map<String, Object>();
                                responseData.put('Name', cdg.Name);
                                responseData.put('Code', cdg.vlocity_cmt__Code__c);
                                responseData.put('Active', value);                               
                               if (value == true) {
                                responseOut.add(responseData);
                               }else {
                                responseInactivo.add(responseData);
                               } 
                              
                             }
                                                       
                        }
                        
                        
                    }
                    outMap.put('activos', responseOut);
                    outMap.put('inactivos', responseInactivo);
                }  
            }catch (Exception e) {
                System.debug('Error al recuperar la lista de atributos: ' + e.getMessage());
            }
        
          
    }


}