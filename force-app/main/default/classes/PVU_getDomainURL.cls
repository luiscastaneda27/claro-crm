/*------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:   	Class to change domain, to managed PQR services
Test Class:    	PVU_getDomainURL_Test
History
<Date>      	<Author>     	<Change Description>
02-Oct-2023	    Luis Mendoza	Initial Version
------------------------------------------------------------*/
global with sharing class PVU_getDomainURL implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('getDomainURL')) {
                getDomainURL(inputMap, outMap, options);
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
    Description:   	method to get domain		
    OUT: map<String, Object> to response success or error 			
    History
    <Date>      <Author>     <Description>
    02-Oct-2023	Luis Mendoza	Version to get domain
------------------------------------------------------------*/
    public static void getDomainURL(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        String urlDomain =  String.valueOf(System.Url.getOrgDomainUrl());
        String domainString = (String) inputMap.get('domainString');
        String domainStringProd = (String) inputMap.get('domainProd');
        
        System.debug('url ' +  urlDomain);
        
        if(urlDomain.contains(domainStringProd) ){
            outMap.put('domain', domainStringProd);
            outMap.put('flagProd', true);
        }else{
            outMap.put('domain', domainString);
            outMap.put('flagProd', false);
        }
        
        
    }
}