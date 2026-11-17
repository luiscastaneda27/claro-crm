@isTest
public with sharing class PVUCustomerVoiceTest {
@isTest
    static void getCustomerVoiceTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVUCustomerVoice testclass = new PVUCustomerVoice();
        
        input.put('Warranty','false');
        input.put('notConforming','no');     
        input.put('RetractoCompra','no'); 
        input.put('flagAfterDateThreeDays',true); 
        
        List<Map<String,Object>> optionsList = new List<Map<String,Object>>();
       
        Test.startTest();
        testclass.invokeMethod('getCustomerVoice',input,output,options);
        Test.stopTest();
        System.assert(output.get('ListOptions') != null,'Fallo Lista');
    }
}