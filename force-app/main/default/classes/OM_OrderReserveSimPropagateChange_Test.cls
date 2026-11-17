/*--------------------------------------------------------------------------
Author:         Emmanuel Ruarte  - andres.ruarte@nespon.com
Company:        Nespon
Description:    Clase TEST para APEX  OM_OrderReserveSimBackPropAgateChangeSim
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
29-May-24         Emmanuel Ruarte       HDU-736687              inicial version

----------------------------------------------------------------------------*/
@isTest(seeAllData = true)
public class OM_OrderReserveSimPropagateChange_Test {
    	
    
    public static  void setupData(){
        
        vlocity_cmt__CpqConfigurationSetup__c cpqSetup = vlocity_cmt__CpqConfigurationSetup__c.getInstance('CacheEnabled');
	    cpqSetup.vlocity_cmt__SetupValue__c = 'False';
    	update cpqSetup;
                
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
                                                vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-IMSI": "oldIMSI"}',vlocity_cmt__Action__c = 'Change') ; 
        insert testOrderItem;
        
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        testOrder.vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.id ;
        update testOrder;
        
        //  Fulfilment Request Line
        vlocity_cmt__FulfilmentRequestLine__c fulfilmentRequestLine = new vlocity_cmt__FulfilmentRequestLine__c(vlocity_cmt__JSONAttribute__c = '{"SerialisedJSONAttr":{"223541c2-e1cb-fe89-a86d-b07a65470f1b":[{"SegmentValue":"772222222","Filterable":false,"Code":"TechPCnewIMSI","Name":"TechPCnewIMSI","attributeRunTimeInfo":{"value":"Mobile","default":"","dataType":"Text"},"valuedescription__c":null,"value__c":null,"uidisplaytype__c":null,"rulemessage__c":null,"querylabel__c":null,"querycode__c":null,"valueinnumber__c":null,"formatmask__c":null,"isrequired__c":false,"attributeconfigurable__c":true,"attributefilterable__c":true,"isconfigurable__c":true,"isquerydriven__c":false,"isreadonly__c":false,"isnotassetizable__c":false,"ishidden__c":false,"isactive__c":true,"hasrule__c":false,"attributedisplaysequence__c":null,"attributecategoryid__c":"","displaysequence__c":null,"valuedatatype__c":"Text","categoryname__c":"Category","objecttype__c":null,"objectid__c":"","id":"","attributedisplayname__c":"TechATRfamily","attributeuniquecode__c":"TechATRfamily","attributeid__c":"a0a79000000G48EAAS","categorycode__c":"223541c2-e1cb-fe89-a86d-b07a65470f1b"}]}}',
                                                                                                                vlocity_cmt__BillingAccountId__c= testAccount.id,
                                                                                                               vlocity_cmt__SubAction__c = 'ChangeSim-Modify');
        insert fulfilmentRequestLine;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id, Name='TestChangeSim22' ,vlocity_cmt__OrderItemId__c=testOrderItem.id,vlocity_cmt__FulfilmentRequestLineId__c= fulfilmentRequestLine.id  );
        insert testOrchestrationItem;
        //orchesItemId = testOrchestrationItem.name;
        
        OM_SubscriptionSuspInfo__c testSubscriptionSuspInf = new OM_SubscriptionSuspInfo__c(OM_OrderId__c= testorder.id, OM_Subscription__c= testsubscription.Id, OM_StatusEndDate__c=Date.valueOf(dateNow).addDays(60) );
        insert testSubscriptionSuspInf;
        
        
        
        // Fulfilment Request Line Decomp Relationship
        vlocity_cmt__FulfilmentRequestLineDecompRelationship__c frlDecomp = new vlocity_cmt__FulfilmentRequestLineDecompRelationship__c(vlocity_cmt__SourceOrderItemId__c = testOrderItem.id, vlocity_cmt__DestinationFulfilmentRequestLineId__c = fulfilmentRequestLine.id);
        insert frlDecomp;
        
 
    }
    
    
    @isTest
    static void testExecuteBatch() {
        setupData();
        // Obtener  OrchestrationItem
        
        List<vlocity_cmt__OrchestrationItem__c> orchestrationItems = [
            SELECT Id ,vlocity_cmt__FulfilmentRequestLineId__c,vlocity_cmt__OrchestrationPlanId__c
            FROM vlocity_cmt__OrchestrationItem__c 
            where name = 'TestChangeSim22'
        ];
        
        Test.startTest();
        
        OM_OrderReserveSimBackPropAgateChangeSim autoTask = new OM_OrderReserveSimBackPropAgateChangeSim();
        autoTask.executeBatch(orchestrationItems);
        
        Test.stopTest();

        // Verificar que las actualizaciones se hayan realizado correctamente
        List<OrderItem> updatedOrderItems = [
            SELECT Id, vlocity_cmt__AttributeSelectedValues__c 
            FROM OrderItem
            where Order.name = 'testOrderChangeSim'
        ];
        system.debug('array orderitem'+updatedOrderItems);
        if(updatedOrderItems.size()> 0){
            for(OrderItem item : updatedOrderItems) {
                System.assert(item.vlocity_cmt__AttributeSelectedValues__c.contains('772222222'), 'El atributo IMSI debe actualizarse.');
            }
        }
    } 
}