/*--------------------------------------------------------------------------
Author:          Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    	<Version>
20-06-24      	Hever Salas    Test class to update attributes in JSON       			inicial version 1.0
15-07-24		Hever Salas    Se agrega prueba para metodo de modificación del json			1.1
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_UpdateJsonAttributeTest {
    
    @isTest
    static void updateJSONTest(){
        
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
    	
        vlocity_cmt__FulfilmentRequestLine__c frl = new vlocity_cmt__FulfilmentRequestLine__c();
        frl.vlocity_cmt__JSONAttribute__c = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"attributefilterable__c":true,"value__c":null,"valuedatatype__c":"Text","categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","objecttype__c":null,"isconfigurable__c":true,"objectid__c":"","Name":"TechRCNRN","isnotassetizable__c":false,"querylabel__c":null,"rulemessage__c":null,"hasrule__c":false,"valueinnumber__c":null,"valuedescription__c":null,"querycode__c":null,"id":"","attributedisplaysequence__c":null,"isquerydriven__c":false,"formatmask__c":null,"attributeconfigurable__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"isactive__c":true,"attributeRunTimeInfo":{"default":"","dataType":"Text","value":""},"Code":"TechRCNRN","attributeid__c":"a0a79000000G4G1AAK","attributedisplayname__c":"TechRCNRN","attributecategoryid__c":"","isrequired__c":false,"Filterable":false,"uidisplaytype__c":null,"attributeuniquecode__c":"TechRCNRN","displaysequence__c":null,"SegmentValue":""}]}';
        INSERT frl;
        
        Map<String,Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('FulfilmentRequestLineId', frl.Id);
        input.put('attributeCodeToValue', 'TechRCNRN');
        input.put('newValueAttribute', 121);
        
        Test.startTest();
        testUpdateJSON.invokeMethod('updateJSON', input, output, options);
        Test.stopTest();
        
        vlocity_cmt__FulfilmentRequestLine__c frlOutput = [SELECT Id, vlocity_cmt__JSONAttribute__c
                                                    FROM vlocity_cmt__FulfilmentRequestLine__c
                                                    WHERE Id = :frl.Id];
        
        System.Assert(frlOutput.vlocity_cmt__JSONAttribute__c.contains('121'));
        
    }
    
    @isTest
    static void modifyJSONTest(){
        
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
    	
        vlocity_cmt__FulfilmentRequestLine__c frl = new vlocity_cmt__FulfilmentRequestLine__c();
        frl.vlocity_cmt__JSONAttribute__c = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"attributefilterable__c":true,"value__c":null,"valuedatatype__c":"Text","categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","objecttype__c":null,"isconfigurable__c":true,"objectid__c":"","Name":"TechRCNRN","isnotassetizable__c":false,"querylabel__c":null,"rulemessage__c":null,"hasrule__c":false,"valueinnumber__c":null,"valuedescription__c":null,"querycode__c":null,"id":"","attributedisplaysequence__c":null,"isquerydriven__c":false,"formatmask__c":null,"attributeconfigurable__c":true,"categoryname__c":"Category","ishidden__c":false,"isreadonly__c":false,"isactive__c":true,"attributeRunTimeInfo":{"default":"","dataType":"Text","value":""},"Code":"TechRCNRN","attributeid__c":"a0a79000000G4G1AAK","attributedisplayname__c":"TechRCNRN","attributecategoryid__c":"","isrequired__c":false,"Filterable":false,"uidisplaytype__c":null,"attributeuniquecode__c":"TechRCNRN","displaysequence__c":null,"SegmentValue":""}]}';
        INSERT frl;
        

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String JSONAttrInput = '{"jsonAttribute":{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"SegmentValue":"","displaysequence__c":null,"attributeuniquecode__c":"TechPCcontractId","uidisplaytype__c":null,"Filterable":false,"isrequired__c":false,"attributecategoryid__c":"","attributedisplayname__c":"TechPCcontractId","attributeid__c":"a0a79000000G48yAAC","Code":"TechPCcontractId","attributeRunTimeInfo":{"value":"","dataType":"Text","default":""},"isactive__c":true,"isreadonly__c":false,"ishidden__c":false},{"SegmentValue":"","displaysequence__c":null,"attributeuniquecode__c":"TechPCfechaActivacion","uidisplaytype__c":null,"Filterable":false,"isrequired__c":false,"attributecategoryid__c":"","attributedisplayname__c":"TechPCfechaActivacion","attributeid__c":"a0a79000000G490AAC","Code":"TechPCfechaActivacion","attributeRunTimeInfo":{"value":"","dataType":"Text","default":""},"isactive__c":true,"isreadonly__c":false,"ishidden__c":false}]},"mapAttributeCodeToValue":{"TechPCfechaActivacion":"2024-06-25T10:05:00.000Z","TechPCcontractId":"CONTR0000210082"}}';
		Map<String, object> input = (Map<String, object>)JSON.deserializeUntyped(JSONAttrInput); 

        
        Test.startTest();
        testUpdateJSON.invokeMethod('modifyJSON', input, output, options);
        Test.stopTest();
        
		String result = String.valueOf(output.get('JSONAttribute'));
        System.Assert(result.contains('CONTR0000210082'));
        
    }
    
    @isTest
    static void extractAttributeJSONTest(){
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
		Map<String, object> mapInterno = new Map<String, object>();
        mapInterno.put('test', 'test');
        List<Map<String, object>> lstInterno = new List<Map<String, object>>();
        lstInterno.add(mapInterno);
        Map<String, object> mapJSONAttribute = new Map<String, object>();
        mapJSONAttribute.put('B2C-ATTRCAT-SVC-ADC-DETAILS', lstInterno);
        mapJSONAttribute.put('B2C-ATTRCAT-CAT-GRL-DETAILS', lstInterno);
        Map<String, object> input = new Map<String, object>();
        input.put('JSONAttribute', mapJSONAttribute);
        Test.startTest();
        testUpdateJSON.invokeMethod('extractAttributeJSON', input, output, options);
        Test.stopTest();
		Map<String,Object> result = (Map<String,Object>)output.get('JSONAttribute');
        System.Assert(result.containsKey('DETAILS'));
    }
    
    @isTest
    static void extractAttributeJSON2Test(){
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String JSONAttrInput = '{"JSONAttribute":{}}';
		Map<String, object> input = (Map<String, object>)JSON.deserializeUntyped(JSONAttrInput);
        Test.startTest();
        testUpdateJSON.invokeMethod('extractAttributeJSON', input, output, options);
        Test.stopTest();
		Map<String,Object> result = (Map<String,Object>)output.get('JSONAttribute');
        System.Assert(result.containsKey('DETAILS'));
    }
    
    @isTest
    static void extractListAttributeJSONTest(){
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, object> input = new Map<String, Object>();
        String jsonAttribute = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"$$AttributeDefinitionStart$$":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G47sAAC","attributeuniquecode__c":"TechATRSegmentoTarifario","attributedisplayname__c":"TechATRSegmentoTarifario","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":"Text","default":"","value":""},"Name":"TechATRSegmentoTarifario","Code":"TechATRSegmentoTarifario","Filterable":false,"SegmentValue":"","$$AttributeDefinitionEnd$$":null}]}';
        List<String> lstAttributeCodeToValue = new List<String>{'TechATRSegmentoTarifario'};
        input.put('lstAttributeCodeToValue', lstAttributeCodeToValue);
        input.put('jsonAttribute', (Map<String, object>)JSON.deserializeUntyped(jsonAttribute));
        Test.startTest();
        Map<String,Object> result = testUpdateJSON.extractListAttributeJSON(input);
        Test.stopTest();
        System.Assert(result.containsKey('mapAttributeCodeToValue'));
    }
    
    @isTest
    static void mergeListConcileLineTest(){
        OM_UpdateJsonAttribute testUpdateJSON = new OM_UpdateJsonAttribute();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String JSONAttrInput = '{"lstOrderItem":[{"Action":"Existing","PricebookEntryId":"01uUN000002xm13YAA","Id":"802VA00000KwKamYAF","RootItemId":"3c994e4f-7c5e-521f-4843-6d39a7c1c189","AssetId":"02iVA000007vCMzYAM"},{"Action":"Existing","PricebookEntryId":"01uUN000003an3hYAA","Id":"802VA00000KwKatYAF","RootItemId":"598aa5c8-02e7-5746-2e82-675e7fede204","AssetId":"02iVA000007vCN6YAM"},{"Action":"Existing","PricebookEntryId":"01uVA00000BPExVYAX","Id":"802VA00000KwKauYAF","RootItemId":"3d35fb1a-42fa-e1c7-045b-3c0b959ab709","AssetId":"02iVA000007vCN7YAM"}],"lstProductSelected":[{"NombreProducto":"Paquete Datos Adicionales 10 GB vigencia 30 dias","CodigoProducto":"PO_MovPosAddOnDatos008","RootItemId":"03a4b0b9-9fbb-7981-2bb5-52bcf1fe71a2"},{"NombreProducto":"Claro Gaming B","CodigoProducto":"PO_MovPosOptOTTClaroGamingB","RootItemId":"3d35fb1a-42fa-e1c7-045b-3c0b959ab709"}]}';
		Map<String, object> input = (Map<String, object>)JSON.deserializeUntyped(JSONAttrInput);
        Test.startTest();
        testUpdateJSON.invokeMethod('mergeListConcileLine', input, output, options);
        Test.stopTest();
		List<Object> result = (List<Object>)output.get('lstOrderItem');
        System.Assert(result.size() > 0);
    }
}