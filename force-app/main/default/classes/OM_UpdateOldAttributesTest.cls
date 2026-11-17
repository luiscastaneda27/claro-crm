/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    <Version>
03-06-24      Hever Salas    Test class to update technical attributes JSON        inicial version
----------------------------------------------------------------------------*/

@isTest
public with sharing class OM_UpdateOldAttributesTest {
    
    @isTest
    static void updateJSONTest(){
        
        OM_UpdateOldAttributes testUpdateJSON = new OM_UpdateOldAttributes();
    	
        String JsonInput = '{"mapAttributes":{"TechPCnewICCID":"TechRCiccid","TechPCnewIMSI":"TechRCimsi"},"JSONAttribute":{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"displaysequence__c":null,"SegmentValue":"8957651100000151041","attributeuniquecode__c":"TechPCnewICCID","uidisplaytype__c":null,"Filterable":false,"attributecategoryid__c":"","isrequired__c":false,"attributedisplayname__c":"TechPCnewICCID","attributeid__c":"a0a79000000G494AAC","attributeRunTimeInfo":{"value":"8957651100000151041","dataType":"Text","default":""},"Code":"TechPCnewICCID","isactive__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"attributeconfigurable__c":true,"formatmask__c":null,"isquerydriven__c":false,"attributedisplaysequence__c":null,"id":"","querycode__c":null,"valueinnumber__c":null,"valuedescription__c":null,"hasrule__c":false,"rulemessage__c":null,"querylabel__c":null,"isnotassetizable__c":false,"Name":"TechPCnewICCID","objectid__c":"","isconfigurable__c":true,"objecttype__c":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","valuedatatype__c":"Text","attributefilterable__c":true,"value__c":null},{"displaysequence__c":null,"SegmentValue":"736501000151041","attributeuniquecode__c":"TechPCnewIMSI","uidisplaytype__c":null,"Filterable":false,"attributecategoryid__c":"","isrequired__c":false,"attributedisplayname__c":"TechPCnewIMSI","attributeid__c":"a0a79000000G495AAC","attributeRunTimeInfo":{"value":"736501000151041","dataType":"Text","default":""},"Code":"TechPCnewIMSI","isactive__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"attributeconfigurable__c":true,"formatmask__c":null,"isquerydriven__c":false,"attributedisplaysequence__c":null,"id":"","querycode__c":null,"valueinnumber__c":null,"valuedescription__c":null,"hasrule__c":false,"rulemessage__c":null,"querylabel__c":null,"isnotassetizable__c":false,"Name":"TechPCnewIMSI","objectid__c":"","isconfigurable__c":true,"objecttype__c":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","valuedatatype__c":"Text","attributefilterable__c":true,"value__c":null},{"displaysequence__c":null,"SegmentValue":"8957651100000151036","attributeuniquecode__c":"TechRCiccid","uidisplaytype__c":null,"Filterable":false,"attributecategoryid__c":"","isrequired__c":false,"attributedisplayname__c":"TechRCiccid","attributeid__c":"a0a79000000G4FOAA0","attributeRunTimeInfo":{"value":"8957651100000151036","dataType":"Text","default":""},"Code":"TechRCiccid","isactive__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"attributeconfigurable__c":true,"formatmask__c":null,"isquerydriven__c":false,"attributedisplaysequence__c":null,"id":"","querycode__c":null,"valueinnumber__c":null,"valuedescription__c":null,"hasrule__c":false,"rulemessage__c":null,"querylabel__c":null,"isnotassetizable__c":false,"Name":"TechRCiccid","objectid__c":"","isconfigurable__c":true,"objecttype__c":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","valuedatatype__c":"Text","attributefilterable__c":true,"value__c":null},{"displaysequence__c":null,"SegmentValue":"736501000151036","attributeuniquecode__c":"TechRCimsi","uidisplaytype__c":null,"Filterable":false,"attributecategoryid__c":"","isrequired__c":false,"attributedisplayname__c":"TechRCimsi","attributeid__c":"a0a79000000G4FQAA0","attributeRunTimeInfo":{"value":"736501000151036","dataType":"Text","default":""},"Code":"TechRCimsi","isactive__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"attributeconfigurable__c":true,"formatmask__c":null,"isquerydriven__c":false,"attributedisplaysequence__c":null,"id":"","querycode__c":null,"valueinnumber__c":null,"valuedescription__c":null,"hasrule__c":false,"rulemessage__c":null,"querylabel__c":null,"isnotassetizable__c":false,"Name":"TechRCimsi","objectid__c":"","isconfigurable__c":true,"objecttype__c":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","valuedatatype__c":"Text","attributefilterable__c":true,"value__c":null}]}}}';
        
        Map<String,Object> input = (Map<String,Object>)JSON.deserializeUntyped(JsonInput);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        testUpdateJSON.invokeMethod('updateOldAttributes', input, output, options);
        Test.stopTest();
        Map<String,Object> outAuxMap = (Map<String,Object>)output.get('result');
        List<Object> response = (List<Object>)outAuxMap.get('223541c2-e1cb-fe89-a86d-b07a65470f1b');
        System.AssertEquals(response.size(), 4, 0);
    }
}