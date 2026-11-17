/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    Test class for OrderIntegrationSystemInterfaceUtility
Code Coverage:  96%
<Date>       <Version>     	<Author> 				<Description>          	
2025-10-01     1.0         Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
2025-11-11     2.1         Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_OISystemInterfaceUtilityTest {
    
    @isTest
    static void getOMEricsonMappingsTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.size() > 0);
    }
    
    @isTest
    static void extractDiferringAttributesTest(){
        String attributesJSON1 = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"$$AttributeDefinitionStart$$":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G47sAAC","attributeuniquecode__c":"TechATRSegmentoTarifario","attributedisplayname__c":"TechATRSegmentoTarifario","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":"Text","default":"","value":""},"Name":"TechATRSegmentoTarifario","Code":"TechATRSegmentoTarifario","Filterable":false,"SegmentValue":"","$$AttributeDefinitionEnd$$":null}]}'; 
        String attributesJSON2 = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"$$AttributeDefinitionStart$$":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G47sAAC","attributeuniquecode__c":"TechATRSegmentoTarifario","attributedisplayname__c":"TechATRSegmentoTarifario","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":"Text","default":"","value":""},"Name":"TechATRSegmentoTarifario","Code":"TechATRSegmentoTarifario","Filterable":false,"SegmentValue":"","$$AttributeDefinitionEnd$$":null}]}';
        Test.startTest();
        String result = OrderIntegrationSystemInterfaceUtility.extractDiferringAttributes(attributesJSON1, attributesJSON2);
        Test.stopTest();
        System.Assert(String.IsNotBlank(result));
    }

	@isTest
    static void UpdateJSONAttributeTest(){
        String containerItemsList = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"$$AttributeDefinitionStart$$":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G47sAAC","attributeuniquecode__c":"TechATRSegmentoTarifario","attributedisplayname__c":"TechATRSegmentoTarifario","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":[{"Text":"test"}],"default":"test","value":"test"},"Name":"TechATRSegmentoTarifario","Code":"TechATRSegmentoTarifario","Filterable":false,"SegmentValue":"","$$AttributeDefinitionEnd$$":null}]}';
        String attrsArrayField = 'attributeRunTimeInfo';
        String keyField = 'Text';
        String valueField = 'test';
        String keyAttribute = 'test';
        Map<String, Object> mapAttribute = new Map<String, Object>();
        mapAttribute.put('test','test');
        String newValueAttribute = JSON.Serialize(mapAttribute);
        String valueObject = 'test';
        String valueObjectField = 'test';
        Test.startTest();
        String result = OrderIntegrationSystemInterfaceUtility.UpdateJSONAttribute(containerItemsList, attrsArrayField, keyField, valueField, keyAttribute, newValueAttribute, valueObject, valueObjectField);
        Test.stopTest();
        System.Assert(String.IsBlank(result));
    }
    
    @isTest
    static void getOMProductoTecnicoExcepcionTest(){
        OM_ProductoTecnico__c objPTE = new OM_ProductoTecnico__c();
        objPTE.OM_TipoOrden__c = 'Cancelacion';
        objPTE.OM_SubtipoOrden__c = 'Cancelacion_Orden';
        objPTE.OM_Canal__c = 'Ix';
        objPTE.OM_ProductoTecnico__c = 'PO_MovPosOptOTTNeflixEstHDSA';
        objPTE.OM_ProcessDetails__c = '{"cancelation":false}';
        INSERT objPTE;
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMProductoTecnico();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.excepciones.size() > 0);
    }
    
    @isTest
    static void getOMEricsonProductToCFSSpecTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonProductToCFSSpec();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.size() > 0);
    }
    
    @isTest
    static void getOMEricsonCFSspecToCharacteristicsTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonCFSspecToCharacteristics();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.size() > 0);
    }
    
    @isTest
    static void getOMEricsonTopLevelProductSpecTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonTopLevelProductSpec();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.topLevelProductByFamily.size() > 0);
    }
    
    @isTest
    static void getOMOMEricsonChargeTypeSpecTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMOMEricsonChargeTypeSpec();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.priceMappingByTechnicalProduct.size() > 0);
    }
    
    @isTest
    static void getOMEricsonActionDerivationTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonActionDerivation();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.size() > 0);
    }
    
    @isTest
    static void getOMEricsonResourceSpecNodesMapTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonResourceSpecNodesMap();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.size() > 0);
    }
    
    @isTest
    static void getOMEricsonTipoCodingoMapTest(){
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonTipoCodingoMap();
        Test.stopTest();
        System.Assert(OrderIntegrationSystemInterfaceUtility.tipoByCodingo.size() > 0);
    }
}