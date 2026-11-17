/*--------------------------------------------------------------------------
Author:         Hever Salas
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    		<Version>
2024-06-11      Hever Salas  	Test class to update attributes AdminCharge in JSON        	 	 1.0.0
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_UpdateValuesAdminChargeTest {
    
    @isTest
    static void createJSONTest(){
        
        OM_UpdateValuesAdminCharge testUpdateJSON = new OM_UpdateValuesAdminCharge();
    	
        String JsonInput = '{"version":0,"run":true,"requestedCompletionDate":"2024-06-12T13:04:32.340Z","relatedParties":[],"relatedEntities":[],"orderType":"ProductOfferingOrder","orderSpec":{"name":"ProductOrder","characteristics":[]},"orderItems":[{"item":{"relatedParties":[{"role":"Customer","reference":"93000000017203"}],"relatedEntities":[{"type":"Place","reference":"7647841"},{"type":"CustomerAccount","reference":"17203","name":"17203"},{"type":"Contract","reference":"CONTR000021105","name":"ContractId"}],"orderType":"CustomerChangeOrder","id":"13","attrs":[{"value":["true"],"name":"ApplyAdmin"},{"value":["ADM000186"],"name":"EventCode"},{"value":["2000"],"name":"Price"},{"value":["PO_MovPosAdChgCamSimCardG001"],"name":"productOfferingId"},{"value":["380"],"name":"Taxes"}],"action":"AddAdminCharge"}}],"description":"ORDSFQ00003835","createdDate":"2024-06-11T13:04:28.814Z","attrs":[{"value":"9","name":"requestTargetId"}]}';
        

        Map<String, Object> output = new Map<String, Object>();
        
        Test.startTest();
        output = testUpdateJSON.updateValuesAdminCharge(JsonInput);
        Test.stopTest();
        List<Object> response = (List<Object>)output.get('orderItems');
        System.AssertEquals(response.size(), 1, 'Los items no coinciden');
    }
}