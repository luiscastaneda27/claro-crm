/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  98%
History
<Date>            <Author>             <Description>                                    <Version>
21-MMy-24      Hever Salas    Test class to create technical attributes JSON        inicial version
17-06-2024 	 Hever Salas   	  Add new Attributes values in response       				1.1
----------------------------------------------------------------------------*/

@isTest
public with sharing class OM_CreateJsonTechnicalAttributesTest {
    
    @isTest
    static void createJSONTest(){
        
        OM_CreateJsonTechnicalAttributes testcreateJSON = new OM_CreateJsonTechnicalAttributes();
    	
        String JsonInput = '{"listOtherProducts":[{"serviceId":[{"CFSS_MovPosPlanMmsUSG":"124050004756101"},{"CFSS_MovPosPlanVideoLlamadaUSG":"124050004756102"}],"productOffering":"PO_MovPosUsoOtros","productId":[{"PS_MovPosUsoOtros":"124050004756001"}]}],"mapAttributes":{"TechRCSDP_ID":"sdp","TechRCki":"ki","TechRCiccid":"iccid","TechRCimsi":"imsi","TechRCsm_id":"smClass","TechRChlrcode":"physicalHlrCode","TechRCNRN":"nrn","TechRCportation_status":"Portation_status","TechRCelectricalProfile":"electricalProfile","TechRCresourceNumber":"msisdn","TechAttrSIMTechnology":"technology","TechRCCodigoMaterial":"codigoSap"},"InventoryItem":{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"SegmentValue":"12345","Filterable":false,"Code":"TechRCresourceNumber","Name":"TechRCresourceNumber","attributeRunTimeInfo":{"value":"","default":"","dataType":"Text"},"valuedescription__c":null,"value__c":null,"uidisplaytype__c":null,"rulemessage__c":null,"querylabel__c":null,"querycode__c":null,"valueinnumber__c":null,"formatmask__c":null,"isrequired__c":false,"attributeconfigurable__c":true,"attributefilterable__c":true,"isconfigurable__c":true,"isquerydriven__c":false,"isreadonly__c":false,"isnotassetizable__c":false,"ishidden__c":false,"isactive__c":true,"hasrule__c":false,"attributedisplaysequence__c":null,"attributecategoryid__c":"","displaysequence__c":null,"valuedatatype__c":"Text","categoryname__c":"Category","objecttype__c":null,"objectid__c":"","id":"","attributedisplayname__c":"TechAttrAttrDetail","attributeuniquecode__c":"TechAttrAttrDetail","attributeid__c":"a0a79000000G48cAAC","categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b"}]}}}';
        
        Map<String,Object> input = (Map<String,Object>)JSON.deserializeUntyped(JsonInput);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        testcreateJSON.invokeMethod('createJSON', input, output, options);
        Test.stopTest();
        Map<String, Object> response = (Map<String, Object>)output.get('msisdnList');
        System.AssertEquals((String)response.get('msisdn'), '12345', 'Los mensajes no coinciden');
    }
    
    @isTest
    static void getAttributeJSONTest(){
        
        OM_CreateJsonTechnicalAttributes testgetAttributeJSON = new OM_CreateJsonTechnicalAttributes();
    	
        String JsonInput = '{"attributeCodeToValue":"TechAttrProductOfferingId","JSONAttr":{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G481AAC","attributeuniquecode__c":"TechAttrProductOfferingId","attributedisplayname__c":"TechAttrProductOfferingId","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":"Text","default":"","value":"PO_MovPosPlanNavegalaA120"},"Name":"TechAttrProductOfferingId","Code":"TechAttrProductOfferingId","Filterable":false,"SegmentValue":"PO_MovPosPlanNavegalaA120"}]}}';
        
        Map<String,Object> input = (Map<String,Object>)JSON.deserializeUntyped(JsonInput);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        testgetAttributeJSON.invokeMethod('getAttributeJSON', input, output, options);
        Test.stopTest();
        String response = (String)output.get('ProductOfferingId');
        System.AssertEquals(response, 'PO_MovPosPlanNavegalaA120', 'Los mensajes no coinciden');
    }
}