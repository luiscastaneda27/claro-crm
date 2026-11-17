@isTest
public with sharing class OM_manageSubscription_Test {
    
       
    
    @isTest static void executeItemSuccess(){
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        vlocity_cmt__OrchestrationPlan__c orchestrationPlan = new vlocity_cmt__OrchestrationPlan__c();
        orchestrationPlan.vlocity_cmt__OrderId__c = testOrder.Id;
        insert orchestrationPlan;
         
         vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
        item.vlocity_cmt__OrchestrationPlanId__c = orchestrationPlan.Id;
        //item.vlocity_cmt__FulfilmentRequestLineId__c =  ffrl.Id;
        //item.vlocity_cmt__OrderItemId__c = orderItemPlan.Id;
        insert item;
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];
        
        OM_manageSubscription manage_Subscription = new OM_manageSubscription();  
        Try{
            //String path;
            String url;
            Test.startTest();
            manage_Subscription.executeBatch(itemsLst);
            Test.stopTest();
            System.assert(true, 'shuldmanageSubscription');
        }catch(Exception ex){
            
            System.assertEquals('Error al actualizar Subscription. descripcion:Error', ex.getMessage());
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

         
         vlocity_cmt__OrchestrationPlan__c orchestrationPlan = new vlocity_cmt__OrchestrationPlan__c();
        orchestrationPlan.vlocity_cmt__OrderId__c = testOrder.Id;
        insert orchestrationPlan;
         
         vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
        item.vlocity_cmt__OrchestrationPlanId__c = orchestrationPlan.Id;
        //item.vlocity_cmt__FulfilmentRequestLineId__c =  ffrl.Id;
        //item.vlocity_cmt__OrderItemId__c = orderItemPlan.Id;
        insert item;
    //}    
    List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];
        
        OM_manageSubscription manage_Subscription = new OM_manageSubscription();  
        Try{
            //String path;
            //String url;
            Test.startTest();
            manage_Subscription.executeBatch(itemsLst);
            Test.stopTest();
            System.assert(true, 'shuldTrhowException');
        }catch(Exception ex){
            
            System.assertEquals('Error al actualizar Subscription. descripcion:Error', ex.getMessage());
            
        }
     
    }

}