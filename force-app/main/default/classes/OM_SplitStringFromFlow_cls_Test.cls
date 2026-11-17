/**
 * @description       : Clase unitaria de OM_SplitStringFromFlow_cls
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : SFDC
 * @last modified on  : 07-23-2024
 * RS = ResponseStatus
 * -----------------------------------------------------------------------------------------
 *                         Date           Author          Description              Coverage
 * -----------------------------------------------------------------------------------------
 * @version 1.0           09/07/2024     Karen Sanchez    HDU 335666 - Created      96%     
**/
@IsTest
public with sharing class OM_SplitStringFromFlow_cls_Test {

    @TestSetup
    static void setup() {
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;

        Order objOrder = OrderMgtTestDataFactory.createOrder(acc.Id,acc.Id,acc.Id);
        
        vlocity_cmt__OrchestrationPlan__c orchPlan = new vlocity_cmt__OrchestrationPlan__c(
            vlocity_cmt__State__c = 'In Progress',
            vlocity_cmt__OrderId__c = objOrder.Id,
            vlocity_cmt__IsBeingWatched__c = false
        );
        insert orchPlan;

        objOrder.OM_OrchestrationItemState__c = 'Error';
        objOrder.vlocity_cmt__OrchestrationPlanId__c = [SELECT Id FROM vlocity_cmt__OrchestrationPlan__c LIMIT 1].Id;
        update objOrder;

        vlocity_cmt__OrchestrationItem__c orchItem = new vlocity_cmt__OrchestrationItem__c();
        orchItem.vlocity_cmt__OrchestrationPlanId__c = [SELECT Id FROM vlocity_cmt__OrchestrationPlan__c LIMIT 1].Id;
        insert orchItem;
        
    }
  

    /**
    * @description: Prueba un escenario donde el JSON contiene un mensaje que incluye un XML válido dentro del campo responseStatus.message 
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSXML() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"message":"<?xml version=\'1.0\'?><message>Error: Invalid input</message>"}}';
        
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Error: Invalid input', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON contiene un mensaje que incluye un XML con un tag de error dentro del campo responseStatus.message. 
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSXMLError() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"message":"<?xml version=\'1.0\'?><error>Error: Invalid input</error>"}}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals(null, result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON contiene un mensaje regular dentro del campo responseStatus.message.
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSMessage() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"code":"FS_ESB_0","message":"Transacción Completada","status":"Ok"},"iccid":"8957651100000151643"}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Transacción Completada', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON en responseStatus no contiene un campo message. 
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSWithoutMessage() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"error":"No input objects sent."}}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('No input objects sent.', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON en responseStatus no contiene ni message ni error. 
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSWithoutMessageAndError() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"example":"No"}}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('No message or error found in responseStatus', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON no contiene responseStatus.message, pero tiene otros campos como message, error, y code.
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithoutRSMessage() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"status":"ERROR","message":"Data not found","code":"FS_ESB_7"}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Data not found', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON no contiene responseStatus.error, pero tiene otros campos como message, error, y code
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithoutRSError() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"status":"ERROR","error":"Data not found","code":"FS_ESB_7"}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Data not found', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON en responseStatus contiene un campo que no es ni message ni error.
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithoutRSElse() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"status":"ERROR","example":"Data not found","code":"FS_ESB_7"}';
        orchItem.vlocity_cmt__State__c = 'Complete';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('No message or error found', result[0]);
    }

    /**
    * @description: Prueba un escenario donde vlocity_cmt__Response__c es null, lo que debería provocar una NullPointerException.
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void catchNullPointerMessage() {
        // Test with null pointer exception
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = null;
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Null pointer exception: null input to JSON parser', result[0]);
    }

    /**
    * @description: Prueba un escenario donde el JSON es inválido y provoca una JSONException. 
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void catchJSONException() {
        // Test with invalid JSON string
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{responseStatus":{message":"Error: Invalid JSON}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Se espera exactamente un mensaje de error');
    }

    /**
    * @description: Prueba un escenario donde el JSON contiene un valor numérico en lugar de un mensaje dentro de responseStatus.message.
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void messageWithRSXMLErrorNum() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Fatally Failed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"message":123}}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.assertEquals('Unexpected error: Invalid conversion from runtime type Integer to String',result[0]);
    }

    /**
    * @description: Prueba un escenario donde el orchestration Item cambia a Completed
    * @author karsanchez | 07-09-2024 
    **/
    @IsTest
    static void deleteErrorCompleted() {
        vlocity_cmt__OrchestrationItem__c orchItem = [SELECT Id,vlocity_cmt__OrchestrationPlanId__c FROM vlocity_cmt__OrchestrationItem__c LIMIT 1];
        orchItem.vlocity_cmt__State__c = 'Completed';
        orchItem.vlocity_cmt__Response__c = '{"responseStatus":{"message":123}}';
        Test.startTest();
            List<String> result = OM_SplitStringFromFlow_cls.extractErrorMessage(new List<vlocity_cmt__OrchestrationItem__c>{ orchItem });
        Test.stopTest();
        System.debug('result:'+result);
    }  
}