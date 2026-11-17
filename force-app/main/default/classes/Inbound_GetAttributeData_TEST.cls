/*------------------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:   	Test class to manage the coverage code for the class Inbound_GetAttributeData
History
<Date>      	<Author>     	<Description>
01-Agos-2023	Luis Mendoza	Initial Version
----------------------------------------------------------------------------*/
@IsTest
public with sharing class Inbound_GetAttributeData_TEST {
   
   @IsTest
   static void methodtestAttr(){

    List<String> lisattr = new List<String>();
    lisattr.add('B2C-ATTR-MARCA-TERM');
    lisattr.add('B2C-ATTR-TEC-MARCA');

    Map<String, Object> inputMap =  new Map<String, Object>();    
    Map<String, Object> outputMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();

    inputMap.put('attrData', lisattr);
    
    test.startTest();
        Inbound_GetAttributeData getAttr = new Inbound_GetAttributeData();
        Boolean result = getAttr.invokeMethod('getAttibuteName', inputMap, outputMap, options);
    test.stopTest();

    Assert.areEqual(true, result);
    
   }
   
   @IsTest
   static void methodtestAttrNotFound(){

    List<String> lisattr = new List<String>();
    lisattr.add('B2C-ATTR-MARCA-TERM');
    lisattr.add('B2C-ATTR-TEC-MARCA');

    Map<String, Object> inputMap =  new Map<String, Object>();    
    Map<String, Object> outputMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();

    inputMap.put('attrData', lisattr);
    
    test.startTest();
        Inbound_GetAttributeData getAttr = new Inbound_GetAttributeData();
        Boolean result = getAttr.invokeMethod('getAttibuteName1', inputMap, outputMap, options);
    test.stopTest();

    Assert.areEqual(false, result);
    
   }
}