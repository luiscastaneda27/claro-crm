@IsTest
public class FVU_cancelOrder_TST {
    
    /*static testmethod void testLoadData() { 
        String OrderJSON = '{"attributes":{"type":"Order","url":"/services/data/v25.0/sobjects/Order/80101000000Wba5AAC"},"Id":"80101000000Wba5AAC","Status":"DeliveryAndActivated","FVU_PaymentStatus__c":"PE", "vlocity_cmt__DeliveryMethod__c":"Delivery", "FVU_OrderDeliveryStatus__c":"PaymentNotified" ,"CreatedDate":"2023-10-04T17:54:26.000+0000","LastModifiedDate":"2024-04-04T17:54:26.000+0000"}'; 
        String OrderItemJSON = '{"attributes":{"type":"OrderItem","url":"/services/data/v25.0/sobjects/OrderItem/8020100000481PQAAY"},"Id":"8020100000481PQAAY","OrderId":"80101000000Wba5AAC", "FVU_ProductDeliveryStatus__c":"ReadyForDelivery" ,"CreatedDate":"2023-10-04T17:54:26.000+0000","LastModifiedDate":"2024-05-04T17:54:26.000+0000"}'; 
        Order Orde0 = (Order) JSON.deserialize(OrderJSON, Order.class); 
        OrderItem OrderItem0 = (OrderItem) JSON.deserialize(OrderItemJSON, OrderItem.class); 
        Order ordrtst = new Order();
        ordrtst.id=Orde0.id;
        //update ordrtst;
        PricebookEntry obe = [SELECT id,Product2Id FROM PricebookEntry limit 1];
        OrderItem orderITst = new OrderItem();
        //orderITst.id = OrderItem0.id;
        orderITst.OrderId = ordrtst.id;  
        orderITst.PricebookEntryId = obe.id;
        orderITst.Product2Id = obe.Product2Id;
        //insert orderITst;
       }*/
     
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
       // Order.Status = \'DeliveryAndActivated\' AND FVU_ProductDeliveryStatus__c =\'ReadyForDelivery\'AND order.FVU_PaymentStatus__c =\'PE\' AND Order.vlocity_cmt__DeliveryMethod__c	=\'Delivery\' AND order.FVU_OrderDeliveryStatus__c = \'PaymentNotified\' order by order.ordernumber desc limit 3';
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;                            
        
        // --- create orders --- 
        Order orden1 = new Order();
        orden1.AccountId = acc.Id;
        orden1.Status = 'Draft';
        orden1.Pricebook2Id = pricebookId;
        orden1.EffectiveDate = System.Today();
        insert orden1;
        
        Order orden2 = new Order();
        orden2.AccountId = acc.Id;
        orden2.Status = 'Draft';
        orden2.Pricebook2Id = pricebookId;
        orden2.EffectiveDate = System.Today();
        insert orden2;
        
        Order orden3 = new Order();
        orden3.AccountId = acc.Id;
        orden3.Status = 'Draft';
        orden3.Pricebook2Id = pricebookId;
        orden3.EffectiveDate = System.Today();
        insert orden3;
        
        //insert order item
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orden1.Id;
        orderItem1.Product2Id = prod1.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.Quantity = 1;
        orderItem1.UnitPrice = 10;
        orderItem1.vlocity_cmt__LineNumber__c = '0001';
        orderItem1.vlocity_cmt__Action__c = 'Add';
        orderItem1.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem1.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem1.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem1.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem1;
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.OrderId = orden2.Id;
        orderItem2.Product2Id = prod1.Id;
        orderItem2.PricebookEntryId = pbe1.Id;
        orderItem2.Quantity = 1;
        orderItem2.UnitPrice = 10;
        orderItem2.vlocity_cmt__LineNumber__c = '0001';
        orderItem2.vlocity_cmt__Action__c = 'Add';
        orderItem2.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem2.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem2.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem2.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem2;
        
        OrderItem orderItem3 = new OrderItem();
        orderItem3.OrderId = orden3.Id;
        orderItem3.Product2Id = prod1.Id;
        orderItem3.PricebookEntryId = pbe1.Id;
        orderItem3.Quantity = 1;
        orderItem3.UnitPrice = 10;
        orderItem3.vlocity_cmt__LineNumber__c = '0001';
        orderItem3.vlocity_cmt__Action__c = 'Add';
        orderItem3.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem3.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem3.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem3.FVU_ProductDeliveryStatus__c = 'ReadyForDelivery';
        insert orderItem3;
        
        // --- update orders ---
        orden2.Status = 'Cerrada Perdida';
        orden2.FVU_ClosingReason__c = 'Cancelado por no finalización de orden';
        update orden2;
        
        orden3.Status = 'DeliveryAndActivated';
        orden3.FVU_PaymentStatus__c = 'PE';
        orden3.vlocity_cmt__DeliveryMethod__c = 'Delivery';
        orden3.FVU_PaymentMethod__c = 'Contado';
        orden3.FVU_OrderDeliveryStatus__c = 'PaymentNotified';
        update orden3;  
    }
    
   // Order.Status = \'DeliveryAndActivated\' 
       // FVU_ProductDeliveryStatus__c =\'ReadyForDelivery\'
        //order.FVU_PaymentStatus__c =\'PE\' 
        //Order.vlocity_cmt__DeliveryMethod__c	=\'Delivery\'
        //order.FVU_OrderDeliveryStatus__c = \'PaymentNotified\'
    
    @isTest
    static void getOrdersAvailableTest(){
        //testLoadData();
        /*Test.loadData(Order.sObjectType, 'dataTest');
        Test.loadData(Account.sObjectType, 'dataTestOrI');*/
        FVU_cancelOrder_BCH borrarRegistros = new FVU_cancelOrder_BCH();
        Database.executeBatch(borrarRegistros, 1);
    }
    
}