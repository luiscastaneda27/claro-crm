/*-------------------------------------------------------------------------------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    Esta clase se utilizara para probar todos los metodos de la clase OM_OrderIntegrationHelper
Code Coverage:  92%
History
<Date>       <Version>     	<Author> 				<Description>          											         
2025-05-30     1.0         Hever Salas    	    Creacion de la clase test
2025-10-01     2.0         Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
2025-11-11     2.1         Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
---------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
global without sharing class OM_OrderIntegrationHelperTest{
            
    @TestSetup
    static void setup() {

        PricebookEntry pbe = OrderMgtTestDataFactory.createProduct('Navégala ULTRA M 23 Emmanuel', 'PO_MovPosPlanNavegalaA145_Ashish');

        Account consumerAccount = new Account(
            Name = 'Consumer Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId(), 
            Estado_del_Cliente__c = 'Al dia',
			FVU_BillingDetailFlag__c = false, 
            FVU_DocumentType__c = 'PP', 
            FVU_DocumentNumber__c = '1234567',
            Phone = '3196013097', 
            OM_BSCSID__c = '12345', 
            FVU_Email__c = 'xyz@salesforce.com',
            FVU_ServiceShortAddress__c = 'KR 1 70 35 AG A CS A'
        );
		insert consumerAccount;
        
        Contact primaryContact = new Contact(
            firstName = 'test FirstName', 
            LastName = 'test LastName',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('FVU_Consumer').getRecordTypeId(), 
            AccountId = consumerAccount.Id
        );
        insert primaryContact;
        
        consumerAccount.vlocity_cmt__PrimaryContactId__c = primaryContact.Id;
        UPDATE consumerAccount;
        
        Account serviceAccount = new Account(
            Name = 'Service Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId(),
            FVU_ServiceState__c = 'BOGOTÁ', 
            FVU_ServiceShortAddress__c = 'KR 1 70 35 AG A CS A', 
            FVU_ServiceMunicipality__c = 'BOGOTÁ, D.C.', 
            FVU_ServiceDaneCode__c = '11001000', 
            FVU_SerciveMerId__c = '15225541', 
            FVU_ServiceExtract__c = 6,
            FVU_AccountExternalID__c = '93000000058122',
            ParentId = consumerAccount.Id
        );
        insert serviceAccount;
        
        Account billingAccount = new Account(
            Name = 'Billing Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Billing').getRecordTypeId(),
            FVU_ServiceShortAddress__c = 'KR 1 70 35 AG A CS A',
			OM_BSCSID__c = '91000000057556', 
            OM_BSCSIntID__c = '51986', 
            vlocity_cmt__BillCycle__c = '',
            ParentId = consumerAccount.Id,
            FVU_AccountExternalID__c = '93000000058122'
        );
        insert billingAccount;
        
        Order objOrder = OrderMgtTestDataFactory.createOrder(consumerAccount.Id, billingAccount.Id, serviceAccount.Id);
        Map<String,Object> mapCaseInfo = new Map<String,Object>();
        mapCaseInfo.put('cedenteCustomerAccount', consumerAccount.Id);
        mapCaseInfo.put('cedenteServiceAccount', serviceAccount.Id);
        mapCaseInfo.put('cedenteBillingAccount', billingAccount.Id);
        mapCaseInfo.put('cedenteAssetId', '');
        mapCaseInfo.put('fechaFinCanc','03/06/2025');
        objOrder.PVU_CaseInfo__c = JSON.serialize(mapCaseInfo);
		UPDATE objOrder;
        
        vlocity_cmt__OrchestrationPlan__c objOrchesPlan = OrderMgtTestDataFactory.createOrchestrationPlan(consumerAccount.Id, objOrder.Id);
        insert objOrchesPlan;
        
        objOrder.vlocity_cmt__OrchestrationPlanId__c = objOrchesPlan.Id;
		UPDATE objOrder;
        
        vlocity_cmt__FulfilmentRequest__c objFulfilmentRequest = OrderMgtTestDataFactory.returnFulfilmentRequest(objOrder.Id);
        insert objFulfilmentRequest;

        vlocity_cmt__FulfilmentRequestLine__c objFulfilmentRequestLine = OrderMgtTestDataFactory.returnFulfilmentRequestLine(consumerAccount.Id, objFulfilmentRequest.Id);
        insert objFulfilmentRequestLine;

        vlocity_cmt__OrchestrationItem__c objItem = OrderMgtTestDataFactory.createOrchestrationItem(objOrchesPlan.Id, objFulfilmentRequestLine.Id);
        insert objItem;
        
        OrderItem orderItemInstance = OrderMgtTestDataFactory.createOrderItem(objOrder.Id, pbe.Id);
        
        vlocity_cmt__Subscription__c subscription = new vlocity_cmt__Subscription__c();
        subscription.OM_MSISDN__c = '1234';
        subscription.OM_MSISDN_Temporary__c = '1234';
        subscription.vlocity_cmt__SubscriptionNumber__c = '0017900000NwuK3AAJCONTR0000019946';
        insert subscription;
        
        
        PVU_Community__c community = new PVU_Community__c();
        community.PVU_Estatus__c = 'Activa';
        community.PVU_Linea_Padre__c = subscription.Id;
        insert community;
            
        PVU_Community_Member__c communityMember = new PVU_Community_Member__c();
        communityMember.PVU_Comunidad__c = community.Id;
        communityMember.PVU_Linea_Hija__c = '1234';
        insert communityMember;
        
        vlocity_cmt__AttributeCategory__c attributeCategory = new vlocity_cmt__AttributeCategory__c();
        attributeCategory.vlocity_cmt__Code__c = 'B2C-ATTRCAT-SIM';
        attributeCategory.Name = 'TechAttributesDecompose';
        attributeCategory.vlocity_cmt__DisplaySequence__c = 900;
        insert attributeCategory;
        
    }
    
	@isTest
    static void duplicateItemTest(){
        List<EricsonRequestJSON.cls_resources> resourcesListInstance = new  List<EricsonRequestJSON.cls_resources>();
        EricsonRequestJSON.cls_resources OIResourceInstance = new EricsonRequestJSON.cls_resources();
        resourcesListInstance.add(OIResourceInstance);
        List<EricsonRequestJSON.cls_services> servicesListInstance = new  List<EricsonRequestJSON.cls_services>();
        EricsonRequestJSON.cls_services OIServicesInstance = new EricsonRequestJSON.cls_services();
        servicesListInstance.add(OIServicesInstance);
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
		Map<String, List<EricsonRequestJSON.child_cls_orderItems>> childOrderMap = new Map<String, List<EricsonRequestJSON.child_cls_orderItems>>();
        EricsonRequestJSON.child_cls_orderItems childOrderItem = new EricsonRequestJSON.child_cls_orderItems();
        childOrderItem.item = new EricsonRequestJSON.child_cls_item();
        Map<String,String> mapServiceId = new Map<String,String>();
        Map<String,String> mapResourceId = new Map<String,String>();
        mapServiceId.put('CFSS_MovPosOptClaroDrive','825050101148001');
        mapResourceId.put('CFSS_MovPosOptClaroDrive','825050101148001');
        
        Order orderInstance = [SELECT Id, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
        
        Map<String,object> mapParams = new Map<String,object>();
    	
        mapParams.put('childOrderItem', childOrderItem);
        mapParams.put('childOrderMap', childOrderMap);
        mapParams.put('AttributeDefaultValues', AttributeDefaultValues);
        mapParams.put('orderSubType', (String)orderInstance.FVU_OrderSubType__c);
        mapParams.put('currentProductFamily', 'Mobile');
        mapParams.put('boolIsDuplicate', true);
        mapParams.put('strProductId', '825050101148001');
        mapParams.put('mapServiceId', mapServiceId);
        mapParams.put('mapResourceId', mapResourceId);
        mapParams.put('resourcesListInstance', resourcesListInstance);
        mapParams.put('servicesListInstance', servicesListInstance);
        mapParams.put('parentProductId', 0);
        
        Test.startTest();
        Integer result = OM_OrderIntegrationHelper.duplicateItem(mapParams);
        Test.stopTest();
        System.Assert(result > 0);
    }
    
    @isTest
    static void setOIResource_ResourceNumberTest(){
        EricsonRequestJSON.cls_resources OIResourceInstance = new EricsonRequestJSON.cls_resources();
        Order orderInstance = [SELECT Id, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResource_ResourceNumber(OIResourceInstance, 'Resume-Reactivate-PortOut', attrCodeValueMap, 'LRS_MovNumero', subscription);
        Test.stopTest();
        System.Assert(OIResourceInstance.resourceNumber != '');
    }
    
    @isTest
    static void setOIResource_ResourceNumber2Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonResourceSpecNodesMap();
        EricsonRequestJSON.cls_resources OIResourceInstance = new EricsonRequestJSON.cls_resources();
        Order orderInstance = [SELECT Id, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResource_ResourceNumber(OIResourceInstance, '', attrCodeValueMap, 'LRS_MovNumero', subscription);
        Test.stopTest();
        System.Assert(OIResourceInstance.resourceNumber != '');
    }
    
    @isTest
    static void setOIResourcesCharacteristicsTest(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Activation-Add', 'TechRChlrcode', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics2Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('network','network');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Activation-Add', 'network', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics3Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
        orderInstance.Type = 'Portabilidad';
        orderInstance.FVU_OrderSubType__c = 'Portout';
        orderInstance.OM_PortabilityStatus__c = 'test';
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('network','network');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Activation-Add', 'network', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics4Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c
                               FROM Order
                               LIMIT 1];
        orderInstance.Type = 'Portabilidad';
        orderInstance.FVU_OrderSubType__c = 'Portout';
        orderInstance.OM_PortabilityStatus__c = 'test';
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('portation_status','portation_status');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Activation-Add', 'portation_status', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics5Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c
                               FROM Order
                               LIMIT 1];
        orderInstance.Type = 'Portabilidad';
        orderInstance.FVU_OrderSubType__c = 'Portout';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('NRN','NRN');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Activation-Add', 'NRN', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics6Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c
                               FROM Order
                               LIMIT 1];
        orderInstance.Type = 'Portabilidad';
        orderInstance.FVU_OrderSubType__c = 'Portout';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('resourceNumber','resourceNumber');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Resume-Reactivate-PortOut', 'resourceNumber', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() > 0);
    }
    
    @isTest
    static void setOIResourcesCharacteristics7Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();
        List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
        EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c
                               FROM Order
                               LIMIT 1];
        orderInstance.Type = 'Portabilidad';
        orderInstance.FVU_OrderSubType__c = 'Portout';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Test.startTest();
        OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, 'default', 'Resume-Reactivate-PortOut', 'resourceNumber', 'LRS_MovNumero', oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, 'test', 'RollbackPortOut');
        Test.stopTest();
        System.Assert(oIResourceCharacList.size() == 0);
    }
    
    @isTest
    static void setProdCharacWithoutMetaDataTest(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosAddOnCancelacion');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Activation-Add');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData2Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosOptFaFVozProv');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Activation-Add');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData3Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosOptFaFVozProv');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData4Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        
        subscription.OM_MSISDN_Temporary__c = '4444';
        UPDATE subscription;
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosBasico');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Resume-Reactivate-PortOut');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData5Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        mapAgrupado.put(derivedFRLId, 'test');
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosBasico');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Resume-Reactivate-PortOut');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData6Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        getOrderLineItemPriceByFRL.put('PO_SIM7012268_Resume-Reactivate-PortOut', inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        mapAgrupado.put(derivedFRLId, 'test');
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosBasico');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Resume-Reactivate-PortOut');
        inputProdCharac.put('productCode','PO_SIM7012268');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData7Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        getOrderLineItemPriceByFRL.put('B2C-MOV-OFR-SIMCARD_Resume-Reactivate-PortOut', inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        mapAgrupado.put(derivedFRLId, 'test');
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosBasico');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Resume-Reactivate-PortOut');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setProdCharacWithoutMetaData8Test(){
        
        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource = new EricsonRequestJSON.cls_productCharacteristics();

        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> inputPrice = new Map<String, Object>();
        inputPrice.put('OrderId',orderInstance.Id);
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(inputPrice);
        getOrderLineItemPriceByFRL.put('B2C-MOV-OFR-SIMCARD_Resume-Reactivate-PortOut', inputPrice);
        orderInstance.Type = 'Cancelacion';
        orderInstance.FVU_OrderSubType__c = 'Voluntaria';
        orderInstance.OM_PortabilityStatus__c = 'test';
        orderInstance.OM_NRN__c = '1';
        orderInstance.recordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        UPDATE orderInstance;
    	Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        mapCfsCharac.put('test','test');
        attrCodeValueMap.put('cls_resourceCharacteristics', mapCfsCharac);
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Id derivedFRLId = [SELECT Id 
                           FROM vlocity_cmt__FulfilmentRequestLine__c].Id;
        List<Object> lstParents = new List<Object>();
        EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
        Map<String,String> mapAgrupado = new Map<String,String>();
        mapAgrupado.put(derivedFRLId, 'test');
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> mapProductCode = new Map<String, Object>();
        mapProductCode.put('service_id','');
        mapProductCode.put('Technical_Details',mapCfsCharac);
        MapGen.put('B2C-MOV-OFR-SIMCARD', mapProductCode);
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        AttributeDefaultValues.put('B2C-ATTR-TECH-DET', '{"test":"test"}');
        AttributeDefaultValues.put('B2C-ATTR-SERV-ID', '{"test":"test"}');
        Map<String, Object> inputProdCharac = new Map<String, Object>();
        inputProdCharac.put('lstParents',lstParents);
        inputProdCharac.put('PO_Product','PO_MovPosBasico');
        inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
        inputProdCharac.put('derivedStrSubAction','Resume-Reactivate-PortOut');
        inputProdCharac.put('productCode','B2C-MOV-OFR-SIMCARD');
        inputProdCharac.put('subscription',subscription);
        inputProdCharac.put('productinstance',productinstance);
        inputProdCharac.put('mapAgrupado',mapAgrupado);
        inputProdCharac.put('derivedFRLId',derivedFRLId);
        inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
        inputProdCharac.put('MapGen',MapGen);
        inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
        inputProdCharac.put('orderInstance',orderInstance);
        Test.startTest();
        OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
        Test.stopTest();
        System.Assert(productinstance.productCharacteristics != null);
    }
    
    @isTest
    static void setExceptionsTest(){
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Map<String, Object> inputExceptionsList = new Map<String, Object>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> mapProductCode = new Map<String, Object>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        List<Object> lstObject = new List<Object>();
        lstObject.add(subscription);
        mapCfsCharac.put('exceptions',lstObject);
        mapProductCode.put('Process_Details',mapCfsCharac);
        MapGen.put('B2C-MOV-OFR-SIMCARD', mapProductCode);
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        AttributeDefaultValues.put('B2C-ATTR-TECH-DET', '{"test":"test"}');
        AttributeDefaultValues.put('B2C-ATTR-SERV-ID', '{"test":"test"}');
        inputExceptionsList.put('productCode', 'B2C-MOV-OFR-SIMCARD');
        inputExceptionsList.put('MapGen',MapGen);
        inputExceptionsList.put('AttributeDefaultValues',AttributeDefaultValues);

        Test.startTest();
        List<object> result = OM_OrderIntegrationHelper.setExceptions(inputExceptionsList);
        Test.stopTest();
        System.Assert(result.size() > 0);
    }
    
    @isTest
    static void setExceptions2Test(){
        vlocity_cmt__Subscription__c subscription = [SELECT Id, OM_MSISDN__c, OM_MSISDN_Temporary__c 
                                                     FROM vlocity_cmt__Subscription__c 
                                                     LIMIT 1];
        Map<String, Object> inputExceptionsList = new Map<String, Object>();
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        Map<String, Object> mapProductCode = new Map<String, Object>();
        Map<String, Object> mapCfsCharac = new Map<String, Object>();
        List<Object> lstObject = new List<Object>();
        lstObject.add(subscription);
        mapCfsCharac.put('exceptions',lstObject);
        mapProductCode.put('Process_Details',mapCfsCharac);
        MapGen.put('B2C-MOV-OFR-SIMCARD2', mapProductCode);
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        AttributeDefaultValues.put('B2C-ATTR-PRC-DET', '{"exceptions":[{"test":"test"}]}');
        inputExceptionsList.put('productCode', 'B2C-MOV-OFR-SIMCARD');
        inputExceptionsList.put('MapGen',MapGen);
        inputExceptionsList.put('AttributeDefaultValues',AttributeDefaultValues);

        Test.startTest();
        List<object> result = OM_OrderIntegrationHelper.setExceptions(inputExceptionsList);
        Test.stopTest();
        System.Assert(result.size() > 0);
    }
    
    @isTest
    static void ignoreFRLTest(){
        List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = [SELECT Id
                                                             FROM vlocity_cmt__FulfilmentRequestLine__c];

        Test.startTest();
        Boolean result = OM_OrderIntegrationHelper.ignoreFRL('Disconnect', 'ChangePlan-Reassign', 'Activation', 'Activation', 'Activation', lstFRL, lstFRL[0].Id);
        Test.stopTest();
        System.Assert(result);
    }
    
    @isTest
    static void ignoreFRL2Test(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonActionDerivation();
        List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = [SELECT Id
                                                             FROM vlocity_cmt__FulfilmentRequestLine__c];

        Test.startTest();
        Boolean result = OM_OrderIntegrationHelper.ignoreFRL('Add', 'Activation-Add', 'Cancelacion', 'Portout', 'BaseTechProduct2', lstFRL, lstFRL[0].Id);
        Test.stopTest();
        System.Assert(result);
    }
    
    @isTest
    static void getcfsSpecIdTest(){
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Map<String, Object>> mapInventoryItemCesion = new Map<String, Map<String, Object>>();
		Map<String, Object> mapInterno = new Map<String, Object>();
        mapInterno.put('productIds', JSON.DeserializeUntyped('[{"PS_MovPosOptFaFVozProv":"825050101141001"}]'));
        mapInventoryItemCesion.put('PO_MovPosBasico', mapInterno); 
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('lstInventoryItemCesion' , mapInventoryItemCesion.get('PO_MovPosBasico').get('productIds'));
        mapParams.put('cfsSpec', 'cls_productCharacteristics');
        Test.startTest();
        String result = OM_OrderIntegrationHelper.getcfsSpecId(mapParams);
        Test.stopTest();
        System.Assert(String.IsBlank(result));
    }
    
    @isTest
    static void getcfsSpecId2Test(){
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Map<String, Object>> mapInventoryItemCesion = new Map<String, Map<String, Object>>();
		Map<String, Object> mapInterno = new Map<String, Object>();
        mapInterno.put('productIds', JSON.DeserializeUntyped('[{"PS_MovPosOptFaFVozProv":"825050101141001"}]'));
        mapInventoryItemCesion.put('PO_MovPosBasico', mapInterno); 
        Map<String,Object> mapParams = new Map<String,Object>();
        mapParams.put('lstInventoryItemCesion' , mapInventoryItemCesion.get('PO_MovPosBasico').get('productIds'));
        mapParams.put('cfsSpec', 'PS_MovPosOptFaFVozProv');
        Test.startTest();
        String result = OM_OrderIntegrationHelper.getcfsSpecId(mapParams);
        Test.stopTest();
        System.Assert(String.IsNotBlank(result));
    }
    
    @isTest
    static void isDuplicateTest(){
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        AttributeDefaultValues.put('TechAttrProductDetail', '{"behavior":[{"action":"duplicate","orderSubType":"'+orderInstance.FVU_OrderSubType__c+'"}]}');
        Map<String,Object> mapInputIsDuplicate = new Map<String,Object>();
        mapInputIsDuplicate.put('AttributeDefaultValues', AttributeDefaultValues);
        mapInputIsDuplicate.put('orderSubType', (String)orderInstance.FVU_OrderSubType__c);
        Test.startTest();
        Boolean result = OM_OrderIntegrationHelper.isDuplicate(mapInputIsDuplicate);
        Test.stopTest();
        System.Assert(result);
    }
    
    @isTest
    static void isDuplicate2Test(){
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, OM_PortabilityStatus__c, OM_NRN__c, PVU_CaseInfo__c, recordtypeId
                               FROM Order
                               LIMIT 1];
        Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
        Map<String,Object> mapInputIsDuplicate = new Map<String,Object>();
        mapInputIsDuplicate.put('AttributeDefaultValues', AttributeDefaultValues);
        mapInputIsDuplicate.put('orderSubType', (String)orderInstance.FVU_OrderSubType__c);
        Test.startTest();
        Boolean result = OM_OrderIntegrationHelper.isDuplicate(mapInputIsDuplicate);
        Test.stopTest();
        System.Assert(!result);
    }
    
    @isTest
    static void invokeDecisionMatrixCosTest(){
        Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>();
        Map<String, Object> mapInterno = new Map<String, Object>();
        mapInterno.put('SRVVVM', true);
        mapInterno.put('BRRNLOST', true);
        mapInterno.put('BRRMARYA', true);
        attrCodeValueMap.put('cls_productCharacteristics', mapInterno);
        Map<String,Object> mapInputCos = new Map<String,Object>();        
        mapInputCos.put('attrCodeValueMap',attrCodeValueMap);
        Test.startTest();
        String result = OM_OrderIntegrationHelper.invokeDecisionMatrixCos(mapInputCos);
        Test.stopTest();
        System.Assert(String.IsBlank(result));
    }
    
    @isTest
    static void updateCosToFRLTest(){
        Product2 productClass = new Product2(
        	Name = 'Paquetes Adicionales OTT Class',
            IsActive = true,
            ProductCode = 'PO-MOV-POS-FUN-BLOQ',
            vlocity_cmt__Status__c = 'Active'
        );
        INSERT productClass;
        vlocity_cmt__FulfilmentRequestLine__c lstFRL = [SELECT Id, vlocity_cmt__Product2Id__c, vlocity_cmt__JSONAttribute__c
                                                        FROM vlocity_cmt__FulfilmentRequestLine__c
                                                        LIMIT 1];
        lstFRL.vlocity_cmt__JSONAttribute__c = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"$$AttributeDefinitionStart$$":null,"categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b","attributeid__c":"a0a79000000G48EAAS","attributeuniquecode__c":"TechPCcos","attributedisplayname__c":"TechPCcos","id":"","objectid__c":"","objecttype__c":null,"categoryname__c":"Category","valuedatatype__c":"Text","displaysequence__c":null,"attributecategoryid__c":"","attributedisplaysequence__c":null,"hasrule__c":false,"isactive__c":true,"ishidden__c":false,"isnotassetizable__c":false,"isreadonly__c":false,"isquerydriven__c":false,"isconfigurable__c":true,"attributefilterable__c":true,"attributeconfigurable__c":true,"isrequired__c":false,"formatmask__c":null,"valueinnumber__c":null,"querycode__c":null,"querylabel__c":null,"rulemessage__c":null,"uidisplaytype__c":null,"value__c":null,"valuedescription__c":null,"attributeRunTimeInfo":{"dataType":"Text","default":"","value":"Mobile"},"Name":"TechPCcos","Code":"TechPCcos","Filterable":false,"SegmentValue":"Mobile","$$AttributeDefinitionEnd$$":null}]}';
        lstFRL.vlocity_cmt__Product2Id__c = productClass.Id;
        UPDATE lstFRL;
        Map<String,Object> mapFRL = new Map<String,Object>();
        mapFRL.put(lstFRL.Id, lstFRL);
        Map<String, Object> mapInputupdateCosToFRL = new Map<String, Object>();
        mapInputupdateCosToFRL.put('mapFRL', mapFRL);
        mapInputupdateCosToFRL.put('cos', '0_01');
        Test.startTest();
        OM_OrderIntegrationHelper.updateCosToFRL(mapInputupdateCosToFRL);
        Test.stopTest();
        System.Assert(mapFRL.size() > 0);
    }
    
    @isTest
    static void agregarExcepcionesAdicionalesTest(){
        OM_ProductoTecnico__c objPTE = new OM_ProductoTecnico__c();
        objPTE.OM_TipoOrden__c = 'Cancelacion';
        objPTE.OM_SubtipoOrden__c = 'Cancelacion_Orden';
        objPTE.OM_Canal__c = 'Ix';
        objPTE.OM_ProductoTecnico__c = 'PO_MovPosOptOTTNeflixEstHDSA';
        objPTE.OM_ProcessDetails__c = '{"exceptions":[{"cancelation":false}]}';
        INSERT objPTE;
        
        Map<String, Object> inputExcepcionesAdicionales = new Map<String, Object>();
        List<Object> lstException = new List<Object>();
        Map<String, Object> mapTest = new Map<String, Object>();
        mapTest.put('change_sim',false);
        mapTest.put('activation_simple',false);
        lstException.add((Object)mapTest);
        inputExcepcionesAdicionales.put('exceptionsListInstance',lstException);
        inputExcepcionesAdicionales.put('orderType','Cancelacion');
        inputExcepcionesAdicionales.put('orderSubType','Cancelacion_Orden');
        inputExcepcionesAdicionales.put('origin','Ix');
        inputExcepcionesAdicionales.put('productCode','PO_MovPosOptOTTNeflixEstHDSA');
        Test.startTest();
        OrderIntegrationSystemInterfaceUtility.getOMProductoTecnico();
        OM_OrderIntegrationHelper.agregarExcepcionesAdicionales(inputExcepcionesAdicionales);
        Test.stopTest();
        System.Assert(lstException.size() > 0);
    }
}