/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    <Version>
26-10-24      	Hever Salas    Test class to update the flags in Subscription        inicial version
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_UpdateSubscriptionFlagTest {
    
    @isTest
    static void updateFlags(){
        
        OM_UpdateSubscriptionFlag updateSubscriptionFlag = new OM_UpdateSubscriptionFlag();
    	
        String JsonInput = '{"MSISDNList":["573130000102","573130000096"],"bloqueoRoamingCAN":true,"SusByCollectionsFlag":"0","SusByCustomerFlag":"0","SusByFraudFlag":"0","SusByLostFlag":"0","SusByTheftFlag":"0","SusByWarrantyFlag":"0"}';
        
        Map<String,Object> input = (Map<String,Object>)JSON.deserializeUntyped(JsonInput);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        updateSubscriptionFlag.invokeMethod('updateFlags', input, output, options);
        Test.stopTest();
        System.AssertEquals(output.get('result'), 'OK', 0);
    }
    
    @isTest
    static void getMSISDN(){
    	
        vlocity_cmt__Subscription__c subs = new vlocity_cmt__Subscription__c();
        subs.OM_SusByCustomerFlag__c = '0';
        subs.OM_MSISDN__c = '573130000102';
        subs.vlocity_cmt__SubscriptionNumber__c = '0000900000NwuK3AAJCONTR0000099999';
        subs.vlocity_cmt__Status__c = 'Active';
        INSERT subs;
            
        List<String> listSubsId = new  List<String>{subs.Id};
        
        Test.startTest();
        List<String> lstResult = OM_UpdateSubscriptionFlag.getMSISDN(listSubsId);
        Test.stopTest();
        System.AssertEquals(lstResult[0], '573130000102', 0);
    }
}