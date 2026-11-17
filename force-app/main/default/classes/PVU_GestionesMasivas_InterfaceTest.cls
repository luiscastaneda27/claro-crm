@isTest
public class PVU_GestionesMasivas_InterfaceTest {
    @TestSetup
    private static void dataSetup() {
        // Crear cuenta
        Account acc = new Account(Name = 'Test Account', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '111', FVU_AccountExternalID__c = '93000000055938');
        insert acc;
        
        
        // Crear suscripción
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000000');
        insert testSubscription;
        
        // Crear información de suscripciones
        List<OM_SubscriptionSuspInfo__c> subscriptions = new List<OM_SubscriptionSuspInfo__c>();
        for (Integer i = 0; i < 5; i++) {
            subscriptions.add(new OM_SubscriptionSuspInfo__c(OM_Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', OM_Subscription__c = testSubscription.Id));
        }
        insert subscriptions;
        
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        // Crear activos
        Asset ast = new Asset(Name = 'Test Asset1', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        // Crear registro de gestiones masivas
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(PVU_SuspensionLevel__c ='1', PVU_CustNum__c = '93000000055938', 
                                                                        PVU_BillingAccountId__c =acc.Id, PVU_Action__c = 'SUSPENSION',PVU_ReasonId__c = '221' ,
                                                                        PVU_Source__c ='COLLECTIONS',PVU_JobIdentifier__c = '111');
        insert gestion;   
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today(), Pricebook2Id = pricebookId );
        Order testOrder2 = new Order(AccountId = testAccount.Id, vlocity_cmt__OrderStatus__c = 'Queued', status = 'Draft', EffectiveDate= Date.today().addDays(2), vlocity_cmt__RequestDate__c = Date.today().addDays(2), Pricebook2Id = pricebookId);
        insert testOrder;
        insert testOrder2; 
        
        
        PricebookEntry pricebookentry = new PricebookEntry(UnitPrice = 0.0,IsActive = true, Pricebook2Id= pricebookId, Product2Id= prod1.id ) ;
        insert  pricebookentry;   
        
        OrderItem testOrderItem = new OrderItem( vlocity_cmt__AssetId__c = ast.Id ,vlocity_cmt__SubscriptionId__c = testSubscription.Id, orderId =testOrder.Id, PricebookEntryId= pricebookentry.id, UnitPrice= 0.0,Quantity = 1,
                                                vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-IMSI": "oldIMSI"}',vlocity_cmt__Action__c = 'Change') ; 
        OrderItem testOrderItem2 = new OrderItem( vlocity_cmt__AssetId__c = ast.Id ,vlocity_cmt__SubscriptionId__c = testSubscription.Id, orderId =testOrder2.Id, PricebookEntryId= pricebookentry.id, UnitPrice= 0.0,Quantity = 1,
                                                vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-IMSI": "oldIMSI"}',vlocity_cmt__Action__c = 'Change') ; 
        insert testOrderItem;
        insert testOrderItem2;
    }
    
    @isTest
    static void test1() {
        // mejorar consulta
        PVU_Gestiones_Masivas__c gestion = [select Id, Name, PVU_Status__c, PVU_Action__c, PVU_CustNum__c, PVU_BillingAccountId__c, PVU_Source__c, PVU_Message__c, PVU_ReasonId__c, PVU_SuspensionLevel__c, PVU_CaseId__c, PVU_Status_OM__c,PVU_JobIdentifier__c 
                                            FROM PVU_Gestiones_Masivas__c WHERE PVU_CustNum__c ='93000000055938'];
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        PVU_GestionesMasivas_Interface assetToOrderClass = new PVU_GestionesMasivas_Interface();
        Order order = [Select Id From order limit 1];
        Asset asset = [Select Id From Asset limit 1];
        Account acc = [Select Id From Account limit 1];
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        inputMap.put('cartId', order.Id);
        inputMap.put('asset', asset.Id);
        inputMap.put('accountId', acc.Id);
        assetToOrderClass.invokeMethod('AssetToOrder', inputMap, outputMap,optionsMap);
        assetToOrderClass.invokeMethod('checkout', inputMap, outputMap,optionsMap);
        PVU_GestionesMasivas_Interface inter = new PVU_GestionesMasivas_Interface();
        
        
        inter.setOrderByPass(asset.Id);
        
        Map<Id, String> orderIds = new Map<Id, String>();
        orderIds.put(order.Id, 'Draft');
        inter.restoreOrderByPass(orderIds);
        
        Test.stopTest();
        
        
        System.debug('gestion: '+gestion);
        //System.assertEquals('Caso creado', gestion.PVU_Status__c,'El registro de GM debe actualizarse con Status Caso creado');
        //System.assertNotEquals(null, gestion.PVU_CaseId__c, 'Cuando los datos de GM coinciden correctamente con el asset, debe crearse un caso');
    }
    
}