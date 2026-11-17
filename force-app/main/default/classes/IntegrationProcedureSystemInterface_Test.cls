/**
 * @description       : Clase unitaria de la clase IntegrationProcedureSystemInterface
 * @author            : 
 * @group             : 
 * @last modified on  : 10-16-2024
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            Coverage: 87%
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           16/Oct/2024     Karen Sanchez    HDU 365050 - Refactorizacion                                     
 *
**/
@isTest(seeAllData=true)
global with sharing class IntegrationProcedureSystemInterface_Test {
    
    /**
    * @description: Se inserta la data a utilizarse 
    * @author karsanchez | 10-16-2024  
    **/
    @IsTest
    static void testSetup() {
        vlocity_cmt__CpqConfigurationSetup__c cpqSetup = vlocity_cmt__CpqConfigurationSetup__c.getInstance('CacheEnabled');
	    cpqSetup.vlocity_cmt__SetupValue__c = 'False';
    	update cpqSetup;

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
        objItem.Name = 'testOcheItem';
        insert objItem;
    }

    /**
    * @description: Executamos simulación del IP OM_ActivateOrderEricsson
    * @author karsanchez | 10-16-2024 
    **/
    @IsTest
    static void testExecuteIPReserveSIM() {
        IntegrationProcedureSystemInterface integrationSystemInterface = new IntegrationProcedureSystemInterface();

        testSetup();
        String strError;

        System.debug('Test...');
        vlocity_cmt__OrchestrationItem__c item = [SELECT id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId,vlocity_cmt__OrderItemId__c,Name,
        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Owner.Name, vlocity_cmt__FulfilmentRequestLineId__c,
        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__r.OM_EricssonOrderId__c, 
        vlocity_cmt__OrchestrationPlanId__c 
        FROM vlocity_cmt__OrchestrationItem__c 
        WHERE Name = 'testOcheItem' LIMIT 1];
        System.debug('Test...');
                                                         
                                                         
        Test.startTest();
            try {
                integrationSystemInterface.executeItem('test', 'OM_ActivateOrderEricsson', item);
            } catch (Exception err) {
                strError = err.getMessage();
            }
        Test.stopTest();
        String strRequest = [SELECT id, vlocity_cmt__Response__c FROM vlocity_cmt__OrchestrationItem__c WHERE Name = 'testOcheItem' LIMIT 1].vlocity_cmt__Response__c;
        System.assertEquals(String.isNotBlank(strRequest), true, 'Se hizó la actualización correctamente');

        
    }
    /**
    * @description: Ejecutar metodos de Start y End Batch
    * @author karsanchez | 10-16-2024 
    **/
    @IsTest
    static void testExecuteStartEndBatch() {
        IntegrationProcedureSystemInterface integrationSystemInterface = new IntegrationProcedureSystemInterface();
        Test.startTest();
            integrationSystemInterface.startBatch('http://example.com', '/path/to/resource');
            integrationSystemInterface.endBatch('http://example.com', '/path/to/resource'); 
        Test.stopTest();
    }


}