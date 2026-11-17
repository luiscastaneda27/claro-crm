global with sharing class VPLLeadConversion implements vlocity_cmt.VlocityOpenInterface
{
    global VPLLeadConversion() { }
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        try
        {
            if (methodName.equals('LeadConversion'))
            {
                LeadConversion(inputMap,outMap,options);
            }
            else 
            {
                result = false;
            }   
        } 
        catch(Exception e)
        {
            System.debug('VPLLeadConversion:invokeMethod -> exception: '+e);
            result = false;
        }
        
        return result;
    }
    
    
    void LeadConversion(Map<String, Object> inputMap, Map<String, Object> outMap,Map<String,Object> options)
    {
        String leadId =(String)inputMap.get('ContextId');
        lead le = [SELECT Id,Lead_Type__c FROM Lead Where Id=: leadId WITH USER_MODE];
        Database.LeadConvert lc = new Database.LeadConvert(); 
        lc.setLeadId(leadId); 
        If(le.Lead_Type__c=='Consumer')
        {
            lc.setDoNotCreateOpportunity(TRUE);
        }else {
                    lc.setDoNotCreateOpportunity(FALSE);
                }
        LeadStatus convertStatus = [SELECT Id, MasterLabel, ApiName FROM LeadStatus WHERE IsConverted=true WITH USER_MODE LIMIT 1]; 
        lc.setConvertedStatus(convertStatus.ApiName);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        lcr.getAccountId();
        System.debug('=====lcr.getAccountId()====>'+lcr.getAccountId());
        System.debug('=====lcr.getOpportunityId()====>'+lcr.getOpportunityId());
        outMap.put('AccountId',lcr.getAccountId());
        outMap.put('ContactId',lcr.getContactId());
        outMap.put('OpportunityId',lcr.getOpportunityId());
       
        System.debug('=====le.Lead_Type__c====>'+le.Lead_Type__c);
        if (le.Lead_Type__c=='Consumer'){
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Consumer').getRecordTypeId();
            Account accUpdate= new Account(Id=lcr.getAccountId(),RecordtypeId=devRecordTypeId);
            Update as user accUpdate;
            
        }
          else if (le.Lead_Type__c =='Business'){

                Id devRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
                Account accUpdate1= new Account(Id=lcr.getAccountId(),RecordtypeId=devRecordTypeId1);
                Update as user accUpdate1;
            }
            else
            {
                Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
                Account accUpdate2= new Account(Id=lcr.getAccountId(),RecordtypeId=devRecordTypeId2);
                Update as user accUpdate2;
                
            
        }
    }
}