@isTest
public class VPLLeadConversionTest {
    @testSetup static void setup() {

        Lead Leads = new Lead();
        Leads.FVU_ExternalOperator__c = 'Movistar';
        Leads.FirstName = 'Javier';
        Leads.Email = 'javi@test.com';
        Leads.LastName = 'Hernandez';
        Leads.Lead_Type__c = 'Consumer';
        Leads.FVU_City__c = 'Colombia';
        Leads.FVU_DocumentType__c = 'CC';
        Leads.Phone = '35487986581';
        Leads.FVU_DocumentNumber__c = '123456';
        insert Leads;

        Lead Lead2 = new Lead();
        Lead2.FVU_ExternalOperator__c = 'Movistar';
        Lead2.FirstName = 'Javier Business';
        Lead2.Email = 'javi@test.com';
        Lead2.LastName = 'Hernandez Business';
        Lead2.Lead_Type__c = 'Business';
        Lead2.FVU_City__c = 'Colombia';
        Lead2.FVU_DocumentType__c = 'CC';
        Lead2.Phone = '35487986581';
        Lead2.FVU_DocumentNumber__c = '123456';
        insert Lead2;
    }
    static testMethod void LeadConversionTest() {        
        Lead prospect = [SELECT Id FROM Lead WHERE Lead_Type__c = 'Consumer'  LIMIT 1];
        
        test.starttest();
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', prospect.Id);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        VPLLeadConversion lc = new VPLLeadConversion();
        Boolean retValue = lc.invokeMethod('LeadConversion', inputMap, outputMap, null);
        test.stopTest();    
        
        
    }
    static testMethod void LeadConversionTest2() {        
        Lead prospect = [SELECT Id FROM Lead WHERE Lead_Type__c = 'Business'  LIMIT 1];
        
        test.starttest();
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('ContextId', prospect.Id);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        VPLLeadConversion lc = new VPLLeadConversion();
        Boolean retValue = lc.invokeMethod('LeadConversion', inputMap, outputMap, null);
        test.stopTest();    
        
        
    }
    
}