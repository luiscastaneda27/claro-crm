/**
 * @description       : Clase unitaria de OM_InvokeIPCancelEricsson_cls
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : 
 * @last modified on  : 08-13-2024
 * ------------------------------------------------------------------------------------------------
 *                         Date           Author          Description            Coverage: 96%
 * -------------------------------------------------------------------------------------------------
 * @version 1.0           09/07/2024     Karen Sanchez    HDU 354355 - Created                                     
 * @version 1.0           05/08/2024     Karen Sanchez    HDU 354355 - Se cubren metodos startBatch y endBatch
 * @version 1.0           13/08/2024     Karen Sanchez    HDU 354355 - Se agrega seAllData para poder hacer la ejecución del IP desde la clase. Adicional, se crea un registro de tipo CpqConfigurationSetup para evitar el error de caché. Se remueve el método de isSetup ya que no pueden convivir seeAllData y ese método. Finalmente se agrega el método "simulateMockIP" para poder simular la respuesta del IP. 
 * @version 1.1           06/01/2025     Karen Sanchez    BUG 529082 thread - Se eliminan métodos ya que la función vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponse para hacer mocks fallido, no funciona.
 * @version 1.2           21/05/2025     Hever Salas      HDU 579017 - [EVOLUTIVO OM] Adicionar codigo de error
**/
@isTest(seeAllData=true)
public with sharing class OM_InvokeIPCancelEricsson_tst {

    /**
    * @description: Se inserta la data a utilizarse 
    * @author karsanchez | 08-13-2024 
    **/
    @IsTest
    static void testSetup() {
        vlocity_cmt__CpqConfigurationSetup__c cpqSetup = vlocity_cmt__CpqConfigurationSetup__c.getInstance('CacheEnabled');
	    cpqSetup.vlocity_cmt__SetupValue__c = 'False';
    	update cpqSetup;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Order objOrder = OrderMgtTestDataFactory.createOrder(testAccount.Id,testAccount.Id,testAccount.Id);
        objOrder.OM_EricssonOrderId__c = '26666';
        update objOrder;

        Order objSupersededOrder = OrderMgtTestDataFactory.createOrder(testAccount.Id,testAccount.Id,testAccount.Id);
        objSupersededOrder.vlocity_cmt__SupersededOrderId__c = objOrder.Id;
        objSupersededOrder.OM_EricssonOrderId__c = '26666';
        update objSupersededOrder;

        vlocity_cmt__OrchestrationPlan__c objOrchesPlan = OrderMgtTestDataFactory.createOrchestrationPlan(testAccount.Id, objSupersededOrder.Id);
        insert objOrchesPlan;

        vlocity_cmt__OrchestrationItem__c orchestrationItem = new vlocity_cmt__OrchestrationItem__c(
            vlocity_cmt__OrchestrationPlanId__c = objOrchesPlan.Id,
            Name = 'testOcheItem'
        );
        insert orchestrationItem;
    }

    /**
    * @description: Se invoca el OI insertado previamente para guardar el request y response del IP invocado
    * @author karsanchez | 08-13-2024 
    **/
    @IsTest
    static void testExecuteIPSuccess() {
        testSetup();
        OM_InvokeIPCancelEricsson_cls classIPCancel = new OM_InvokeIPCancelEricsson_cls();
		String response = '';
        vlocity_cmt__OrchestrationItem__c item = [SELECT id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Owner.Name, 
        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__SupersededOrderId__r.OM_EricssonOrderId__c, 
        vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c WHERE Name = 'testOcheItem' LIMIT 1];
        Test.startTest();
            try{
                classIPCancel.executeItem('', '', item);
            }catch(exception e){
                response = e.getMessage();
            }
        Test.stopTest();
        String strRequest = [SELECT id, vlocity_cmt__Request__c FROM vlocity_cmt__OrchestrationItem__c WHERE Name = 'testOcheItem' LIMIT 1].vlocity_cmt__Request__c;
        System.AssertEquals('Response: Falla de conexión o timeout', response);
    }

    /**
    * @description: Ejecutar metodos de Start y End Batch
    * @author karsanchez | 08-02-2024 
    **/
    @IsTest
    static void testExecuteStartEndBatch() {
        OM_InvokeIPCancelEricsson_cls classIPCancel = new OM_InvokeIPCancelEricsson_cls(); 
        Test.startTest();
            classIPCancel.startBatch('http://example.com', '/path/to/resource');
            classIPCancel.endBatch('http://example.com', '/path/to/resource'); 
        Test.stopTest();
    }
}