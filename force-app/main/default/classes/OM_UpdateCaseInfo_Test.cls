/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-31-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class OM_UpdateCaseInfo_Test {
            
    
    
    @isTest static void executeItemSuccess(){
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];
        
        OM_UpdateCaseInfo UpdateCase = new OM_UpdateCaseInfo();  
        Try{
            //String path;
            String url;
            Test.startTest();
            UpdateCase.executeBatch(itemsLst);
            Test.stopTest();
            System.assert(true, 'shuldUpdateCase');
        }catch(Exception ex){
            
            System.assertEquals('Error al actualizar caso. descripcion:Error', ex.getMessage());
        }
    }
    
     @isTest static void executeItemFail(){
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];
        
        OM_UpdateCaseInfo UpdateCase = new OM_UpdateCaseInfo();  
        Try{
            //String path;
            String url;
            Test.startTest();
            UpdateCase.executeBatch(itemsLst);
            Test.stopTest();
            System.assert(true, 'shuldTrhowException');
        }catch(Exception ex){
            
            System.assertEquals('Error al actualizar caso. descripcion:Error', ex.getMessage());
            
        }
    }

}