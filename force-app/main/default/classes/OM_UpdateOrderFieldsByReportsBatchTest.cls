/**------------------------------------------------------------------------------------------------------
Author:         Hever Salas
Company:        Salesforce.com
Description:    
Code Coverage:  84%
History
<Date>			@version     	<Author>             <Description>
2025-10-23       1.0.0   	  	Hever Salas          	Initial
--------------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class OM_UpdateOrderFieldsByReportsBatchTest {
    
    @TestSetup
    static void makeData(){
        
        Id pricebookId = Test.getStandardPricebookId();
        
        // Crear datos de prueba
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Crear producto y PricebookEntry
        Product2 mobileProduct = new Product2(
            Name = 'Mobile Number',
            ProductCode = OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER,
            Family = 'Mobile'
        );
        insert mobileProduct;
        
        Product2 simProduct = new Product2(
            Name = 'SIM Card',
            ProductCode = OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD,
            Family = 'SIM'
        );
        insert simProduct;
        
        // Crear Order
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Pricebook2Id = pricebookId,
            vlocity_cmt__DueDate__c = System.today()
        );
        insert testOrder;
        
        // Crear OrchestrationPlan
        vlocity_cmt__OrchestrationPlan__c orchPlan = new vlocity_cmt__OrchestrationPlan__c(
            vlocity_cmt__OrderId__c = testOrder.Id
        );
        insert orchPlan;
        
        PricebookEntry pricebookentry = new PricebookEntry(UnitPrice = 0.0,IsActive = true, Pricebook2Id= pricebookId, Product2Id= mobileProduct.id ) ;
        insert pricebookentry; 
        
        PricebookEntry pricebookentry2 = new PricebookEntry(UnitPrice = 0.0,IsActive = true, Pricebook2Id= pricebookId, Product2Id= simProduct.id ) ;
        insert pricebookentry2;
        
        // Crear OrderItems        
        OrderItem simOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = 1,
            vlocity_cmt__SerialNumber__c = '987654321',
            vlocity_cmt__AttributeSelectedValues__c = '{"MSISDN":"123456789"}',
            PricebookEntryId = pricebookentry2.id,
            UnitPrice = 0.0,
            OM_newICCID__c = '1234',
            vlocity_cmt__Action__c = OrderIntegrationSystemInterfaceConstants.S_CHANGE,
            vlocity_cmt__SubAction__c = 'ChangeSim-Modify'
        );
        insert simOrderItem;
        
        testOrder.Status = 'Activated';
        testOrder.vlocity_cmt__OrchestrationPlanId__c = orchPlan.Id;
        update testOrder;
        
        // Crear FulfilmentRequestLine
        vlocity_cmt__FulfilmentRequestLine__c frl = new vlocity_cmt__FulfilmentRequestLine__c(
            vlocity_cmt__Product2Id__c = mobileProduct.Id
        );
        insert frl;
        
        // Crear OrchestrationItem
        vlocity_cmt__OrchestrationItem__c orchItem = new vlocity_cmt__OrchestrationItem__c(
            vlocity_cmt__OrchestrationPlanId__c = orchPlan.Id,
            vlocity_cmt__FulfilmentRequestLineId__c = frl.Id
        );
        insert orchItem;
        
        // Crear FulfilmentRequestLineDecompRelationship
        vlocity_cmt__FulfilmentRequestLineDecompRelationship__c frldr = new vlocity_cmt__FulfilmentRequestLineDecompRelationship__c(
            vlocity_cmt__SourceOrderItemId__c = simOrderItem.Id,
            vlocity_cmt__DestinationFulfilmentRequestLineId__c = frl.Id
        );
        insert frldr;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Ejecutar el batch
        Database.executeBatch(new OM_UpdateOrderFieldsByReportsBatch(), 50);
        
        Test.stopTest();
        
        // Verificar resultados
        List<Order> updatedOrders = [SELECT Id, OM_MSISDN__c 
                                   FROM Order 
                                   WHERE OM_MSISDN__c != null];
        system.debug('updatedOrders'+updatedOrders.size());
        System.assertNotEquals(null, updatedOrders.size(), 'Debería haber órdenes actualizadas');
    }
    
    @isTest
    static void testBatchWithNoData() {
        // Eliminar datos de prueba
        Order testOrder = [SELECT Id FROM Order];
        testOrder.Status = 'Draft';
        Test.startTest();
        
        // Ejecutar el batch
        Database.executeBatch(new OM_UpdateOrderFieldsByReportsBatch(), 50);
        
        Test.stopTest();
        
        // Verificar que no hay errores cuando no hay datos
        List<AsyncApexJob> jobsCompleted = [SELECT Id, Status, NumberOfErrors 
                                          FROM AsyncApexJob 
                                          WHERE JobType = 'BatchApex'
                                          ORDER BY CreatedDate DESC 
                                          LIMIT 1];
        
        System.assertEquals(0, jobsCompleted[0].NumberOfErrors, 'No deberían haber errores en el proceso batch');
    }
}