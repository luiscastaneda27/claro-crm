/*------------------------------------------------------------------------
Author:        	Luis Mendoza 
Company:       	Salesforce.com
Description:   	Test class to manage the coverage code for the class PVU_getDomainURL
History
<Date>      	<Author>     	<Description>
02-Oct-2023	    Luis Mendoza 	Initial Version
----------------------------------------------------------------------------*/
@isTest
public class PVU_getDomainURL_Test {

    @IsTest
    static void getDomainUrl(){

        Map<String, Object> inputMap = new Map<String, Object>();     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        inputMap.put('domainString', 'https://clarosfi--dev08.sandbox.my.salesforce.com/');
        inputMap.put('domainProd', 'https://clarosfi--prod.sandbox.my.salesforce.com/');

        Test.startTest();
       
        PVU_getDomainURL getDomainTest = new PVU_getDomainURL();
        Boolean result = getDomainTest.invokeMethod('getDomainURL', inputMap, outputMap, options);

        Test.stopTest();
        System.debug( 'domain:::' +  outputMap.get('domain'));
        Assert.areEqual(true, result);
        
    }
   
    @IsTest
    static void getDomainUrlNotFound(){

        Map<String, Object> inputMap = new Map<String, Object>();     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        inputMap.put('domainString', 'https://clarosfi--dev08.sandbox.my.salesforce.com/');
        inputMap.put('domainProd', 'https://clarosfi--prod.sandbox.my.salesforce.com/');

        Test.startTest();
       
        PVU_getDomainURL getDomainTest = new PVU_getDomainURL();
        Boolean result = getDomainTest.invokeMethod('getDomainURLTest', inputMap, outputMap, options);

        Test.stopTest();
        System.debug( 'domain:::' +  outputMap.get('domain'));
        Assert.areEqual(false, result);
        Assert.areEqual(null, outputMap.get('domain'));
        
    }

    @IsTest
    static void getDomainUrlTest(){

        Map<String, Object> inputMap = new Map<String, Object>();     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        String urlDomain =  String.valueOf(System.Url.getOrgDomainUrl());
        inputMap.put('domainProd', urlDomain);

        Test.startTest();
       
        PVU_getDomainURL getDomainTest = new PVU_getDomainURL();
        Boolean result = getDomainTest.invokeMethod('getDomainURL', inputMap, outputMap, options);

        Test.stopTest();
        System.debug( 'domain:::' +  outputMap.get('domain'));
        Assert.areEqual(true, result);
        
    }
   
}