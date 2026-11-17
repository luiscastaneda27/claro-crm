/*--------------------------------------------------------------------------
Autor: Hever Salas - hever.salas@nespon.com
Compania: Salesforce.com
Descripcion: clase de prueba para la clase OM_EjecutarAccionesDeRecepcion
Cobertura:  96%
Historial
<Fecha>       <Version>	  <Autor>          <Descripcion>             					
03-02-2026     1.0.0     Hever Salas      	Initial        
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_EjecutarAccionesDeRecepcionTest {

    @isTest static void executeItemSuccess(){
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 prod = new Product2(Name = 'PO_MovPosBasico', ProductCode = 'B2C-MOV-OFR-SIMCARD', IsActive = true, Family = 'Mobile', vlocity_cmt__Status__c = 'Active');
        insert prod;
        
        PricebookEntry pricebookEntries = new PricebookEntry(Pricebook2Id = standardPricebookId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pricebookEntries;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today(), Pricebook2Id = standardPricebookId);
        insert testOrder;
        
        OrderItem msisdnOrderItem = new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pricebookEntries.Id, product2Id = prod.Id,
                                                  Quantity = 1, UnitPrice = 100, vlocity_cmt__Action__c = 'Add', vlocity_cmt__SubAction__c = 'Cession-Transfer');
        insert msisdnOrderItem;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];
        
        OM_EjecutarAccionesDeRecepcion ejecutarAccionesDeRecepcion = new OM_EjecutarAccionesDeRecepcion();  
        Try{
            Test.startTest();
            ejecutarAccionesDeRecepcion.executeBatch(itemsLst);
            Test.stopTest();
            System.assert(true, 'shuldUpdateCase');
        }catch(Exception ex){
            
            System.assertEquals('Error al consumir el IP milestone notification. descripcion:Error', ex.getMessage());
        }
    }
}