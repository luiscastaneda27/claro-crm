@isTest
public with sharing class FinCustomMessageHandlerTest {
    
    @isTest
    static void getConfirmationMsgTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        FinCustomMessageHandler testMsg = new FinCustomMessageHandler();
        
        FIN_CustomMessages__mdt prueba = FIN_CustomMessages__mdt.getInstance('ProcessStop');

        Map<String, Object> datos = new Map<String, Object>();
        datos.put('TitleMessage', prueba.Title_Message__c);
        datos.put('MainMessage', prueba.Message__c);
        datos.put('Type', prueba.Type__c);
        datos.put('Action', prueba.Action__c);
        
        List<Object> paramstest = new List<Object> {3838382,'343432423432'};
        options.put('confirmationParams', paramstest);
        options.put('Message', datos);
        Test.startTest();
        testMsg.invokeMethod('getConfirmationMsg',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') != null,'Get Message');
    }
    
    @isTest
    static void getConfirmationMsgFailTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        FinCustomMessageHandler testMsg = new FinCustomMessageHandler();
        Test.startTest();
        testMsg.invokeMethod('',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Get Message');
    }
}