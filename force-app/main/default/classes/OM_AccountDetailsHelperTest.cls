/*-------------------------------------------------------------------------------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    Esta clase se utilizara para probar todos los metodos de la clase OM_AccountDetailsHelper
Code Coverage:  91%
History
<Date>       <Version>     	<Author> 				<Description>          											         
2025-09-25     1.0         Hever Salas    	    HDU-627710: [CANALES] Identificacion del sistema y usuario origen de creación de la orden
2025-12-15     1.1         Hever Salas    	    HDU-691571: [EVOLUTIVOS OM]Modificación atributos de info Activación y conciliación de paq adicionales
---------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
global without sharing class OM_AccountDetailsHelperTest{
    
    public static Map<String, Map<String, String>> refeByRoleRelatedEntities = new Map<String, Map<String, String>>{
    	'Contact'=> new Map<String, String>{
            'FIRSTNAME'=>'FirstName',
            'LASTNAME'=>'LastName'
         },
         'Account'=>new Map<String, String>{       
             'DOCID'=>'FVU_DocumentNumber__c',
             'TYPE_DOC'=>'FVU_DocumentType__c',
             'PASSWORD_CUSTOMER'=>'',
             'EMAIL_CUSTOMER'=>'FVU_Email__c',
             'CONTACT_PHONE_NUMBER'=>'Phone'
         }    
    };
    
    public static Map<String, String> relatedEntitiesEntities = new Map<String, String>{
        'DIRECCION'=>'FVU_ServiceShortAddress__c',
        'CIUDAD'=>'FVU_ServiceMunicipality__c',
    	'CITY_CODE'=>'FVU_ServiceDaneCode__c',
        'DISCTRICTO'=>'FVU_ServiceState__c',
        'ID'=>'FVU_SerciveMerId__c',
        'DANE'=>'FVU_ServiceDaneCode__c'
    };
            
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
        
    }
    
	@isTest
    static void topRelatedEntityTest(){
        EricsonRequestJSON instEricsonReq = new EricsonRequestJSON();
		instEricsonReq.relatedEntities = new List<EricsonRequestJSON.cls_relatedEntities>();
        
        Account serviceAccount = [SELECT Id, Name, RecordTypeId, FVU_ServiceState__c, FVU_ServiceShortAddress__c, FVU_ServiceMunicipality__c, 
                                  		FVU_ServiceDaneCode__c, FVU_SerciveMerId__c, FVU_ServiceExtract__c, FVU_AccountExternalID__c, ParentId 
                                  FROM Account 
                                  WHERE RecordType.DeveloperName = 'Service'];
        
        Account billingAccount = [SELECT Id, Name, RecordTypeId, FVU_ServiceShortAddress__c, OM_BSCSID__c, OM_BSCSIntID__c, vlocity_cmt__BillCycle__c, ParentId
                                  FROM Account 
                                  WHERE RecordType.DeveloperName = 'Billing'];
        
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        
        orderItemInstance.vlocity_cmt__SubAction__c = 'Cession-Transfer';
        UPDATE orderItemInstance;

        Map<String,Object> mapParamsEntities = new Map<String,Object>();
        mapParamsEntities.put('relatedEntitiesEntities', relatedEntitiesEntities);
        mapParamsEntities.put('orderServiceAccount', serviceAccount);
        mapParamsEntities.put('orderBillingAccount', billingAccount);
        mapParamsEntities.put('relatedEntities', instEricsonReq.relatedEntities);
        mapParamsEntities.put('orderItemInstance', orderItemInstance);
        Test.startTest();
        OM_AccountDetailsHelper.topRelatedEntity(mapParamsEntities);
        Test.stopTest();
        System.Assert(instEricsonReq.relatedEntities.size() > 0);
    }
    
    @isTest
    static void topRelatedPartiesTest(){
        OrderIntegrationSystemInterfaceUtility.getOMEricsonTipoCodingoMap();
        EricsonRequestJSON instEricsonReq = new EricsonRequestJSON();
		instEricsonReq.relatedParties = new List<EricsonRequestJSON.cls_relatedParties>();
        
        Contact primaryContact = [SELECT Id, firstName, LastName, RecordTypeId, AccountId
                                  FROM Contact 
                                  WHERE RecordType.DeveloperName = 'FVU_Consumer'];
        
        Account consumerAccount = [SELECT Id, Name, RecordTypeId, FVU_ServiceState__c, FVU_ServiceShortAddress__c, FVU_ServiceMunicipality__c, 
                                  		FVU_ServiceDaneCode__c, FVU_SerciveMerId__c, FVU_ServiceExtract__c, FVU_AccountExternalID__c, 
                                   		ParentId, FVU_DocumentType__c, FVU_DocumentNumber__c, FVU_Email__c, Phone
                                  FROM Account 
                                  WHERE RecordType.DeveloperName = 'Consumer'];
        
        Account billingAccount = [SELECT Id, Name, RecordTypeId, FVU_ServiceShortAddress__c, OM_BSCSID__c, OM_BSCSIntID__c, 
                                  		vlocity_cmt__BillCycle__c, ParentId, FVU_AccountExternalID__c
                                  FROM Account 
                                  WHERE RecordType.DeveloperName = 'Billing'];
        
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        
        orderItemInstance.vlocity_cmt__SubAction__c = 'Cession-Transfer';
        UPDATE orderItemInstance;

        Map<String,Object> mapParamsParties = new Map<String,Object>();
        mapParamsParties.put('orderBillingAccount', billingAccount);
        mapParamsParties.put('orderAccount', consumerAccount);
        mapParamsParties.put('orderPrimaryContact', primaryContact);
        mapParamsParties.put('orderItemInstance', orderItemInstance);
        mapParamsParties.put('refeByRoleRelatedEntities', refeByRoleRelatedEntities);
        mapParamsParties.put('relatedParties', instEricsonReq.relatedParties);
        system.debug('mapParamsParties '+mapParamsParties);
        Test.startTest();
        OM_AccountDetailsHelper.topRelatedParties(mapParamsParties);
        Test.stopTest();
        System.Assert(instEricsonReq.relatedParties.size() > 0);
    }
    
    @isTest
    static void orderTypePortInOrderTest(){
        String SubAction = 'Activation-PortIn';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'PortInOrder');
    }
    
    @isTest
    static void orderTypeSuspendedTest(){
        String SubAction = 'Resume-Reactivate-ChangeSim';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'ChangeSuspendedResources');
    }
    
    @isTest
    static void orderTypePortOutOrderTest(){
        String SubAction = 'Disconnect-PortOut';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'PortOutOrder');
    }
    
    @isTest
    static void orderTypeRollbackPortOutTest(){
        String SubAction = 'Disconnect-Delete-PortIn';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'RollbackPortOut');
    }
    
    @isTest
    static void orderTypeRollbackPortInTest(){
        String SubAction = 'Resume-Reactivate-PortOut';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'RollbackPortIn');
    }
    
    @isTest
    static void orderTypeContractTakeOverTest(){
        String SubAction = 'Cession-Transfer';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'ContractTakeOver');
    }
    
    @isTest
    static void orderTypeConciliationTest(){
        String SubAction = 'Concile-Line';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'Conciliation');
    }
    
    @isTest
    static void orderTypeActivationTest(){
        String SubAction = '';
        Test.startTest();
        String response = OM_AccountDetailsHelper.orderTypeAssigment(SubAction);
        Test.stopTest();
        System.Assert(response == 'ProductOfferingOrder');
    }
    
    @isTest
    static void searchCommunityByParentTest(){
        String msisdn = [SELECT Id, OM_MSISDN__c FROM vlocity_cmt__Subscription__c LIMIT 1].OM_MSISDN__c;
        Test.startTest();
        Map<String,Object> response = OM_AccountDetailsHelper.searchCommunityByParent(msisdn);
        Test.stopTest();
        System.Assert(response.containsKey('parent'));
    }
    
    @isTest
    static void searchCommunityByChildrenTest(){
        List<Object> lstParents = new List<Object>();
        String msisdn = [SELECT Id, OM_MSISDN__c FROM vlocity_cmt__Subscription__c LIMIT 1].OM_MSISDN__c;
        Test.startTest();
        OM_AccountDetailsHelper.searchCommunityByChildren(msisdn, lstParents);
        Test.stopTest();
        System.Assert(lstParents.size() > 0);
    }
    
    @isTest
    static void getAttributeCodeNameMapTest(){
        Test.startTest();
        Map<String,Object> response = OM_AccountDetailsHelper.getAttributeCodeNameMap();
        Test.stopTest();
        System.Assert(response.size() == 0);
    }
    
    @isTest
    static void topAttributesTest(){
        
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();
        
        Order orderInstance = [SELECT Id, Type, FVU_OrderSubType__c, FVU_OriginalChannel__c, PVU_SuspensionLevel__c, vlocity_cmt__OrchestrationPlanId__c, 
                               CreatedBy.FVU_CodigoD__c, PVU_NewBillCycle__c
                              FROM Order 
                               LIMIT 1];
        
        Account billingAccount = [SELECT Id, Name, RecordTypeId, FVU_ServiceShortAddress__c, OM_BSCSID__c, OM_BSCSIntID__c, vlocity_cmt__BillCycle__c, ParentId
                                  FROM Account 
                                  WHERE RecordType.DeveloperName = 'Billing'];
        
        OrderItem orderItemInstance = [SELECT Id, OrderId, PricebookEntryId, Quantity, UnitPrice, vlocity_cmt__LineNumber__c, 
                                       		vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__RecurringCharge__c, FVU_ReasonCode__c 
                                       FROM OrderItem 
                                       LIMIT 1];
        
        InterfaceSettings__mdt interSetmdt = OM_MetadataUtility.getInterfaceSettingsReasonTop(orderInstance.Type, orderInstance.FVU_OrderSubType__c);
        
        Map<String, Object> inputParamsDR = (Map<String, Object>)JSON.deserializeUntyped('{"OrchestrationPlanId":"'+orderInstance.vlocity_cmt__OrchestrationPlanId__c+'", "OrderId":"'+orderInstance.Id+'", "IsNotEOC":"'+false+'"}');   
        
        Map<String,Object> mapParams = new Map<String,Object>();  
        
        mapParams.put('Type', orderInstance.Type);
        mapParams.put('mapAttr', OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction);
        mapParams.put('SubType', orderInstance.FVU_OrderSubType__c);
        mapParams.put('Origin', orderInstance.FVU_OriginalChannel__c);
        mapParams.put('SuspensionLevel', orderInstance.PVU_SuspensionLevel__c);
        mapParams.put('orderBillingAccount', billingAccount);
        mapParams.put('orderInstance', orderInstance);
        mapParams.put('orderItemInstance', orderItemInstance);
        mapParams.put('interSetmdt', interSetmdt);
        mapParams.put('Channel', 'test');
        mapParams.put('Person', '');
        mapParams.put('inputParamsDR', inputParamsDR);
        
        Test.startTest();
        List<EricsonRequestJSON.cls_attributes> response = OM_AccountDetailsHelper.topAttributes(mapParams);
        Test.stopTest();
        System.Assert(response.size() > 0);
    }
    
    @isTest
    static void obtAtributosConVigenciaTest(){
        Test.startTest();
        Map<String,String> response = OM_AccountDetailsHelper.obtAtributosConVigencia();
        Test.stopTest();
        System.Assert(response.size() == 0);
    }
}