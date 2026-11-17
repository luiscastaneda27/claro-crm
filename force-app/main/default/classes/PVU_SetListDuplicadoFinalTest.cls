@isTest
public with sharing class PVU_SetListDuplicadoFinalTest {
    
    @isTest
    static void setListDuplicadoTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_SetListDuplicadoFinal testMsg = new PVU_SetListDuplicadoFinal();

        String jsonStr = '{"DuplasResult":[{"min":"3150004013","imsi":"732101166062005"},{"min":"3150004014","imsi":"732101166062005"},{"min":"3150004015","imsi":"732101166062005"},{"min":"3150004016","imsi":"732101166062005"}]}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('setListDuplicado',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'min');
    }
    
    @isTest
    static void setListDuplicadoAdicionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_SetListDuplicadoFinal testMsg = new PVU_SetListDuplicadoFinal();

        String jsonStr = '{"DuplasResult":[{"min":"3150004013","imsi":"732101166062005"},{"min":"3150004014","imsi":"732101166062005"},{"min":"3150004015","imsi":"732101166062005"},{"min":"3150004016","imsi":"732101166062005"}]}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('setListDuplicadoAdicion',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'min');
    }
}