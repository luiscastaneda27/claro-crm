/*------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:   	Class to get attribute name
Test Class:    	PVU_getDomainURL_Test
History
<Date>      	<Author>     	<Change Description>
02-Oct-2023	    Luis Mendoza	Initial Version
------------------------------------------------------------*/
global with sharing class Inbound_GetAttributeData implements vlocity_cmt.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('getAttibuteName')) {
                getAttibuteName(inputMap, outMap, options);
            } else {
                result = false;
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;  
    }

/*------------------------------------------------------------
    Author:		Luis Mendoza
    Company:		Salesforce.com
    Description:   	method to get attribute name		
    OUT: map<String, Object> to response success or error 			
    History
    <Date>      <Author>     <Description>
    02-Oct-2023	Luis Mendoza	Version to get attribute name
------------------------------------------------------------*/
    public static void getAttibuteName(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {

            List<String> requestJSON = new List<String>();
            List<Object> attrData = (List<Object>) inputMap.get('attrData');
           
            for (Object instance : attrData ){
                requestJSON.add((String) instance);
            }
            
           List<vlocity_cmt__Attribute__c> attrNames = [SELECT Name, vlocity_cmt__Code__c FROM vlocity_cmt__Attribute__c WHERE vlocity_cmt__Code__c IN :requestJSON];

           for (vlocity_cmt__Attribute__c name : attrNames) {
              String code = name.vlocity_cmt__Code__c;
              List<String> codesName = code.split('-');
              System.debug('codesName' + codesName);
              outMap.put( codesName[2] + codesName[3], name.Name);
           }
         
           outMap.remove('errorCode');
           outMap.remove('error');
    
    }
}