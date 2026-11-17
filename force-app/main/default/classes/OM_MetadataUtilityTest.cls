/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  87%
History
<Date>            <Author>             <Description>                                    <Version>
22-11-2024      Hever Salas    		Utility class to Custom metadata      				Initial version
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_MetadataUtilityTest {
    
    @isTest
    static void getInterfaceSettingsTest(){

        Test.startTest();
        InterfaceSettings__mdt interSetmdt = OM_MetadataUtility.getInterfaceSettings('Suspension', 'Fraude_GPT', '38');
        Test.stopTest();
        system.debug('interSetmdt '+interSetmdt);
        System.AssertEquals('Fraud',interSetmdt.OM_Reason__c); 
    }
    
    @isTest
    static void getInterfaceSettingsTest2(){

        Test.startTest();
        InterfaceSettings__mdt interfaceSettings = OM_MetadataUtility.getInterfaceSettingsReasonTop('Suspension', 'Fraude_GPT');
        Test.stopTest();
        system.debug('interSetmdt '+interfaceSettings);
        System.AssertEquals('Fraud',interfaceSettings.OM_Reason__c); 
    }
}