/**
 * @description       : Clase unitaria de la clase "OMOrderIntegrationSystemInterface"
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : SFDC
 * @last modified on  : 07-24-2024
 * ----------------------------------------------------------------------------------------
 *                         Date           Author          Description            Coverage
 * -----------------------------------------------------------------------------------------
 * @version 1.0           23/07/2024     Karen Sanchez    HDU 335666 - Created    87%
**/
@isTest
public with sharing class OMOrderIntegrationSystemInterface_tst {

    /**
    * @description; Insertar data 
    * @author karsanchez | 07-23-2024 
    **/
    @TestSetup
    static void setup() {
        PricebookEntry pbe = OrderMgtTestDataFactory.createProduct('Navégala ULTRA M 23 Emmanuel', 'PO_MovPosPlanNavegalaA145_Ashish');
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Order objOrder = OrderMgtTestDataFactory.createOrder(testAccount.Id,testAccount.Id,testAccount.Id);
        
        vlocity_cmt__OrchestrationPlan__c objOrchesPlan = OrderMgtTestDataFactory.createOrchestrationPlan(testAccount.Id, objOrder.Id);
        insert objOrchesPlan;

        vlocity_cmt__FulfilmentRequest__c objFulfilmentRequest = OrderMgtTestDataFactory.returnFulfilmentRequest(objOrder.Id);
        insert objFulfilmentRequest;

        vlocity_cmt__FulfilmentRequestLine__c objFulfilmentRequestLine = OrderMgtTestDataFactory.returnFulfilmentRequestLine(testAccount.Id, objFulfilmentRequest.Id);
        insert objFulfilmentRequestLine;

        vlocity_cmt__OrchestrationItem__c objItem = OrderMgtTestDataFactory.createOrchestrationItem(objOrchesPlan.Id, objFulfilmentRequestLine.Id);
        insert objItem;
        
    }

    /**
    * @description: Verifica el comportamiento del método executeItem en la clase OMOrderIntegrationSystemInterface utilizando un registro de vlocity_cmt__OrchestrationItem__c 
    * @author karsanchez | 07-24-2024 
    **/
    @isTest
    static void testWithoutOrderItem() {
        OMOrderIntegrationSystemInterface omOrderIntSysInterf = new OMOrderIntegrationSystemInterface();
        vlocity_cmt__OrchestrationItem__c item = [SELECT Id, vlocity_cmt__OrderItemId__c, vlocity_cmt__OrchestrationPlanId__c, vlocity_cmt__OrchestrationItemType__c
        FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        Test.startTest();
            omOrderIntSysInterf.executeItem('test', 'OM_ActivateOrderEricsson', item);
        Test.stopTest();
        String request = [SELECT Id,vlocity_cmt__Request__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1].vlocity_cmt__Request__c;
        System.assertEquals(String.isNotBlank(request), true, 'Request JSON,was saved it');
    }
}