/*--------------------------------------------------------------------------
Author:          Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    	<Version>
17-07-24      	Hever Salas    Test class to OM_UpdateOrderItemsChangePlan       			inicial version 1.0
----------------------------------------------------------------------------*/
@isTest
public with sharing class OM_UpdateOrderItemsChangePlanTest {
    
    public static  void setupData(){
        
        Id pricebookId = Test.getStandardPricebookId();
        Datetime dateNow = Datetime.NOW();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        contact testcontact = new contact(vlocity_cmt__MiddleName__c = 'rodolfo',LastName= 'paez',AccountId =  testAccount.Id);
        insert testcontact;
        
        vlocity_cmt__Subscription__c testsubscription = new vlocity_cmt__Subscription__c(OM_Contract__c='contac85',vlocity_cmt__SubscriptionNumber__c='testsuscr22',vlocity_cmt__ServiceAccountId__c=testAccount.id) ;
        insert testsubscription;
        
        Order testOrder = new Order(Name= 'testOrderChangeSim' ,AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today(),Pricebook2Id = pricebookId, PVU_CaseInfo__c=' {"fechaInicioSusp":"2024-03-21","fechaFinSusp":"2024-03-25","Id":"500790000057EAvAAM"}' );
        insert testOrder;
        
        Asset testAsset = new Asset(Name ='navegala m 23',AccountId = testAccount.Id, contactId= testcontact.id );
        insert testAsset;
        
        Product2 productBase = new Product2(Family = 'CS/CD',ProductCode = 'B2C-ATTR-SIM-MATERIAL',Name = 'SimCard'); //Product2.ProductCode IN ('B2C-ATTR-SIM-MATERIAL'
        insert productBase;
        
        PricebookEntry pricebookentry = new PricebookEntry(UnitPrice = 0.0,IsActive = true, Pricebook2Id= pricebookId, Product2Id= productBase.id ) ;
        insert  pricebookentry;   
        
        OrderItem testOrderItem = new OrderItem( vlocity_cmt__AssetId__c = testAsset.Id ,vlocity_cmt__SubscriptionId__c = testsubscription.Id, orderId =testOrder.Id, PricebookEntryId= pricebookentry.id,UnitPrice= 0.0,Quantity = 1,
                                                vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-IMSI": "oldIMSI"}',vlocity_cmt__Action__c = 'Add') ; 
        insert testOrderItem;
        
        OrderItem testOrderItem2 = new OrderItem( vlocity_cmt__AssetId__c = testAsset.Id , orderId =testOrder.Id, PricebookEntryId= pricebookentry.id,UnitPrice= 0.0,Quantity = 1,
                                                vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-IMSI": "oldIMSI"}',vlocity_cmt__Action__c = 'Disconnect') ; 
        insert testOrderItem2;
        
	    system.debug('orderId '+ testOrder.Id + ' ,orderitemAdd '+ testOrderItem.orderId + ' ,orderitemDisc '+testOrderItem2.orderId);    
    }
    
    @isTest
    static void updateOrderItemsTest(){
        setupData();
        OM_UpdateOrderItemsChangePlan testUpdateOrderItems = new OM_UpdateOrderItemsChangePlan();
    	
        
        Map<String,Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

 		String orderId = [SELECT Id FROM Order LIMIT 1].Id;
        input.put('orderId', orderId);
        
        Test.startTest();
        testUpdateOrderItems.invokeMethod('updateOrderItems', input, output, options);
        Test.stopTest();
        
        OrderItem oi = [SELECT Id, vlocity_cmt__disconnectdate__c
                        FROM OrderItem
                        WHERE OrderId = :orderId
                       	AND vlocity_cmt__Action__c = 'Disconnect'];
        
        System.Assert(oi.vlocity_cmt__disconnectdate__c != null);
        
    }
}