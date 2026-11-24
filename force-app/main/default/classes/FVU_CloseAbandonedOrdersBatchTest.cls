@isTest
private class FVU_CloseAbandonedOrdersBatchTest {
    
    private static final Id ORDER_ENTERPRISE_RECORDTYPE_ID = Schema.SObjectType.Order
        .getRecordTypeInfosByDeveloperName()
        .get('EnterpriseOrder').getRecordTypeId();

    @IsTest
    static void runBatchWithRecords() {
        List<Order> listOrder = new List<Order>();
        List<Order> listOrderUpdate = new List<Order>(); 
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();

        for (Integer i = 0 ; i < 2 ; i++ ){
            Order ord = new Order();
            ord.RecordTypeId = ORDER_ENTERPRISE_RECORDTYPE_ID;
            ord.Pricebook2Id = pricebookId;
            ord.AccountId = acc.Id;
            ord.Status = 'Draft';
            ord.FVU_OrderDeliveryStatus__c = 'Draft';
            ord.FVU_PaymentStatus__c = 'PP';
            ord.FVU_PaymentMethod__c = 'Pin Link de Pagos';
            ord.EffectiveDate = System.today();
            ord.FVU_OrderOMSId__c = '123456789';
            ord.FVU_FechaVigencia__c = System.now() - 1/48;
            ord.FVU_PortInData__c = '123456789';
            listOrder.add(ord);
        }

        insert listOrder;

        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;

        // PricebookEntry 
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;

        // Create Order Items
        List<OrderItem> listOrderItem = new List<OrderItem>();
        for(Order order: listOrder){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = prod1.Id;
            orderItem.PricebookEntryId = pbe1.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '0001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = acc.Id;
            orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
            listOrderItem.add(orderItem);
        }
        insert listOrderItem;

        for (Order order : listOrder) {
            order.Status = 'InPayment';
            order.FVU_PaymentStatus__c = 'PP';
            listOrderUpdate.add(order);
        }

        update listOrderUpdate;

        Test.startTest();
        FVU_CloseAbandonedOrdersSchedule schedule = new FVU_CloseAbandonedOrdersSchedule();
        String jobId = System.schedule('CloseAbandonedOrders', FVU_CloseAbandonedOrdersSchedule.CRON_JOB, schedule);
        Test.stopTest();
    }

    @IsTest
    static void runBatchWithoutRecords() {
        List<Order> listOrder = new List<Order>();
        List<Order> listOrderUpdate = new List<Order>(); 
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        for (Integer i = 0 ; i < 2 ; i++ ){
            Order ord = new Order();
            ord.RecordTypeId = ORDER_ENTERPRISE_RECORDTYPE_ID;
            ord.Pricebook2Id = pricebookId;
            ord.AccountId = acc.Id;
            ord.Status = 'Draft';
            ord.FVU_OrderDeliveryStatus__c = 'Draft';
            ord.FVU_PaymentStatus__c = 'PP';
            ord.FVU_PaymentMethod__c = 'Pin Link de Pagos';
            ord.EffectiveDate = System.today();
            ord.FVU_OrderOMSId__c = '123456789';
            ord.FVU_FechaVigencia__c = System.now() + 1;
            ord.FVU_PortInData__c = '123654789';
            listOrder.add(ord);
        }

        insert listOrder;
        
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;

        // PricebookEntry 
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;

        // Create Order Items
        List<OrderItem> listOrderItem = new List<OrderItem>();
        for(Order order: listOrder){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = prod1.Id;
            orderItem.PricebookEntryId = pbe1.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '0001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = acc.Id;
            orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
            listOrderItem.add(orderItem);
        }
        insert listOrderItem;

        for (Order order : listOrder) {
            order.Status = 'InPayment';
            order.FVU_PaymentStatus__c = 'PP';
            listOrderUpdate.add(order);
        }

        update listOrderUpdate;

        Test.startTest();
        FVU_CloseAbandonedOrdersSchedule schedule = new FVU_CloseAbandonedOrdersSchedule();
        String jobId = System.schedule('CloseAbandonedOrders', FVU_CloseAbandonedOrdersSchedule.CRON_JOB, schedule);
        Test.stopTest();
    }

    @IsTest
    static void runBatchWithPortInRecords() {
        List<Order> listOrder = new List<Order>();
        List<Order> listOrderUpdate = new List<Order>(); 
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();

        for (Integer i = 0 ; i < 1 ; i++ ){
            Order ord = new Order();
            ord.RecordTypeId = ORDER_ENTERPRISE_RECORDTYPE_ID;
            ord.Pricebook2Id = pricebookId;
            ord.AccountId = acc.Id;
            ord.Status = 'Draft';
            ord.FVU_OrderDeliveryStatus__c = 'Draft';
            ord.FVU_PaymentStatus__c = 'PP';
            ord.FVU_PurchaseType__c = 'POR';
            ord.FVU_PaymentMethod__c = 'Contado';
            ord.EffectiveDate = System.today();
            ord.FVU_OrderOMSId__c = '123456789';
            ord.FVU_FechaVigencia__c = System.now() - 1/48;
            listOrder.add(ord);
        }

        insert listOrder;

        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;

        // PricebookEntry 
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;

        // Create Order Items
        List<OrderItem> listOrderItem = new List<OrderItem>();
        for(Order order: listOrder){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = prod1.Id;
            orderItem.PricebookEntryId = pbe1.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '0001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = acc.Id;
            orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
            listOrderItem.add(orderItem);
        }
        insert listOrderItem;

        for (Order order : listOrder) {
            order.Status = 'InPayment';
            order.FVU_PaymentStatus__c = 'PP';
            listOrderUpdate.add(order);
        }

        update listOrderUpdate;

        Test.startTest();
        
         String url = 'http://example.com/example';
         String path = 'FVU_SolicitudPortabilidadEntranteBatch';
         String mockResponse = '{"response":[{"success":true,"orderNumber":"Q00011615","error":"ERROR","errorsByMin":[{"error":"Regulatory Request 1111111111 not found ","min":"3002000572"}],"claroRequestId":null,"minPortinInfo":[]},{"success":true,"orderNumber":"Q00011617","error":"ok","errorsByMin":[{"error":"Hay una portabilidad vigente en estado SENT_ABD que no permite crear una nueva solicitud.","min":"3003559131"}],"claroRequestId":null,"minPortinInfo":[]}]}';

         HttpResponse response = new HttpResponse();
         response.setHeader('Content-Type', 'application/json');
         response.setBody(mockResponse);
         response.setStatusCode(200);
         vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponseByUrlOrActionName('HTTP_SolicitudPortabilidad', response);

         FVU_CloseAbandonedOrdersSchedule schedule = new FVU_CloseAbandonedOrdersSchedule();
         String jobId = System.schedule('CloseAbandonedOrders', FVU_CloseAbandonedOrdersSchedule.CRON_JOB, schedule);
         Test.stopTest();
    }

    @IsTest
    static void runBatchWithPortInRecords2() {
        List<Order> listOrder = new List<Order>();
        List<Order> listOrderUpdate = new List<Order>(); 
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();

        for (Integer i = 0 ; i < 1 ; i++ ){
            Order ord = new Order();
            ord.RecordTypeId = ORDER_ENTERPRISE_RECORDTYPE_ID;
            ord.Pricebook2Id = pricebookId;
            ord.AccountId = acc.Id;
            ord.Status = 'Draft';
            ord.FVU_OrderDeliveryStatus__c = 'Draft';
            ord.FVU_PaymentStatus__c = 'PP';
            ord.FVU_PurchaseType__c = 'POR';
            ord.FVU_PaymentMethod__c = 'Contado';
            ord.EffectiveDate = System.today();
            ord.FVU_OrderOMSId__c = '123456789';
            ord.FVU_FechaVigencia__c = System.now() - 1/48;
            listOrder.add(ord);
        }

        insert listOrder;

        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;

        // PricebookEntry 
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;

        // Create Order Items
        List<OrderItem> listOrderItem = new List<OrderItem>();
        for(Order order: listOrder){
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.Id;
            orderItem.Product2Id = prod1.Id;
            orderItem.PricebookEntryId = pbe1.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '0001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = acc.Id;
            orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
            listOrderItem.add(orderItem);
        }
        insert listOrderItem;

        Test.startTest();
        
         String url = 'http://example.com/example';
         String path = 'FVU_SolicitudPortabilidadEntranteBatch';
         String mockResponse = '{"response":[{"success":true,"orderNumber":"Q00011615","error":"ERROR","errorsByMin":[{"error":"Regulatory Request 1111111111 not found ","min":"3002000572"}],"claroRequestId":null,"minPortinInfo":[]},{"success":true,"orderNumber":"Q00011617","error":"ok","errorsByMin":[{"error":"Hay una portabilidad vigente en estado SENT_ABD que no permite crear una nueva solicitud.","min":"3003559131"}],"claroRequestId":null,"minPortinInfo":[]}]}';

         HttpResponse response = new HttpResponse();
         response.setHeader('Content-Type', 'application/json');
         response.setBody(mockResponse);
         response.setStatusCode(200);
         vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponseByUrlOrActionName('HTTP_SolicitudPortabilidad', response);

         FVU_CloseAbandonedOrdersSchedule schedule = new FVU_CloseAbandonedOrdersSchedule();
         String jobId = System.schedule('CloseAbandonedOrders', FVU_CloseAbandonedOrdersSchedule.CRON_JOB, schedule);
         Test.stopTest();
    }

}