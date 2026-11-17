/*******************************************************************************
* Autor: hllanos
* Fecha: 2024-05-28
* Equipo: Pos-Ventas
* Descripcion: Utility class - Cambio de SIM
* History
<Date>            <Author>             <Description>             <Version>
2024-05-28        Hllanos               creacion                   01
2024-07-19        Federico Mandri       BUG 362739                 02
2024-09-17        Hllanos               RoamingDesactivacion       03
2025-04-04        MOlay                 HU414821 Cambio Plan       04
2025-05-19        MOlay                 HU522200 Mod. Datos        05
***********************************************************************************/
@isTest
public class PVU_CambioSimInterfaceTest {
	 @TestSetup
    private static void dataSetup(){
        List<Asset> assets = new List<Asset>();
        List<Order> ordenes = new List<Order>();
        List<Case> casos = new List<Case>();
        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        // Create products
        Product2 prod1 = new Product2 (Name='SIM Card', ProductCode = 'B2C-ATTR-SIM-MATERIAL', FVU_Beneficios__c = '');
        insert prod1;
        Product2 prod2 = new Product2 (Name='eSIM', ProductCode = 'B2C-MOB-OFR-ESIM', FVU_Beneficios__c = '');
        insert prod2;
        Product2 prod3 = new Product2 (Name='Escoja SIM Card', ProductCode = 'B2C-MOB-OFR-SIMCARD', FVU_Beneficios__c = '');
        insert prod3;
        Product2 prod4 = new Product2 (Name='Plan Conectados V 4.1 Mx', ProductCode = 'B2C-MOV-PLAN-POST-CONECT-V41MX', vlocity_cmt__Type__c = 'Plan', vlocity_cmt__SpecificationSubType__c = 'Simple', FVU_Beneficios__c = '');
        insert prod4;
            
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbe1;  
        
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = pricebookId;
        pbe2.Product2Id = prod2.Id;
        pbe2.UnitPrice = 1;
        pbe2.IsActive = true;
        // pbe2.UseStandardPrice = false;
        insert pbe2;                            

        PricebookEntry pbe3 = new PricebookEntry();
        pbe3.Pricebook2Id = pricebookId;
        pbe3.Product2Id = prod3.Id;
        pbe3.UnitPrice = 1;
        pbe3.IsActive = true;
        // pbe3.UseStandardPrice = false;
        insert pbe3; 
        
        PricebookEntry pbe4 = new PricebookEntry();
        pbe4.Pricebook2Id = pricebookId;
        pbe4.Product2Id = prod4.Id;
        pbe4.UnitPrice = 1;
        pbe4.IsActive = true;
        // pbe3.UseStandardPrice = false;
        insert pbe4; 
        
        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert acc;
        /*******************************/
        
        /*****Creacion de subscripcion*****/
        vlocity_cmt__Subscription__c subs1 = new vlocity_cmt__Subscription__c();
        subs1.OM_MSISDN__c = '123456789';
        subs1.vlocity_cmt__SubscriptionNumber__c = '00001';
        subs1.vlocity_cmt__Status__c = 'Active';
        insert subs1;
        /*******************************/
        
        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset 1';
        ast.AccountId = acc.Id;
        ast.Product2Id = prod4.Id;
        ast.Status = 'Active';
        ast.vlocity_cmt__SubscriptionId__c = subs1.Id;
        assets.add(ast);
        
        Asset ast2 = new Asset();
        ast2.Name = 'Test Asset 2';
        ast2.AccountId = acc.Id;
        ast2.Product2Id = prod4.Id;
        ast2.Status = 'Active';
        ast2.vlocity_cmt__SubscriptionId__c = subs1.Id;
        assets.add(ast2);
        insert assets;
        /***************************/
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Análisis de Necesidad';
        orden1.FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        ordenes.add(orden1);
        
        Order orden2 = new Order();
        orden2.Status = 'Análisis de Necesidad';
        orden2.FVU_ClosingReason__c = 'Muerto en caja sin cambio';
        orden2.EffectiveDate = System.Today();
        orden2.AccountId = acc.Id;
        orden2.Pricebook2Id = pricebookId;
        ordenes.add(orden2);
        
        //Orden 3 y 4 entradas para fucnionalidad pagos no abonados
        Order orden3 = new Order();
        orden3.AccountId = acc.Id;
        orden3.Status = 'Análisis de Necesidad';
        orden3.FVU_ClosingReason__c = 'Cancelado por no finalización de orden';
        orden3.EffectiveDate = System.Today();
        orden3.Pricebook2Id = pricebookId;
        ordenes.add(orden3);
        
        Order orden4 = new Order();
        orden4.AccountId = acc.Id;
        orden4.Status = 'Análisis de Necesidad';
        orden4.FVU_PaymentStatus__c = 'PP';
        orden4.EffectiveDate = System.Today();
        orden4.Pricebook2Id = pricebookId;
        ordenes.add(orden4);
        //  system.debug('recordtype>>>>'+orden1.RecordTypeId);
        insert ordenes;
        /*****************************/
        
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
        orderItem2.vlocity_cmt__AssetReferenceId__c = '123456ab-7c89-0123-4567-89defg098765';
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
        orderItem3.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem3;
        
        OrderItem orderItem4 = new OrderItem();
        orderItem4.OrderId = orden4.Id;
        orderItem4.Product2Id = prod1.Id;
        orderItem4.PricebookEntryId = pbe1.Id;
        orderItem4.Quantity = 1;
        orderItem4.UnitPrice = 10;
        orderItem4.vlocity_cmt__LineNumber__c = '0001';
        orderItem4.vlocity_cmt__Action__c = 'Add';
        orderItem4.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem4.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem4.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem4.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        insert orderItem4;
        
        OrderItem orderItem5 = new OrderItem();
        orderItem5.OrderId = orden2.Id;
        orderItem5.Product2Id = prod1.Id;
        orderItem5.PricebookEntryId = pbe1.Id;
        orderItem5.Quantity = 1;
        orderItem5.UnitPrice = 10;
        orderItem5.vlocity_cmt__LineNumber__c = '0001';
        orderItem5.vlocity_cmt__Action__c = 'Add';
        orderItem5.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem5.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem5.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem5.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItem5.vlocity_cmt__AssetReferenceId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem5.vlocity_cmt__RootItemId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem5.vlocity_cmt__ReliesOnItemId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem5.vlocity_cmt__ParentItemId__c = '123456ab-7c89-0123-4567-89defg098765';
        insert orderItem5;
        
        OrderItem orderItem6 = new OrderItem();
        orderItem6.OrderId = orden4.Id;
        orderItem6.Product2Id = prod1.Id;
        orderItem6.PricebookEntryId = pbe1.Id;
        orderItem6.Quantity = 1;
        orderItem6.UnitPrice = 10;
        orderItem6.vlocity_cmt__LineNumber__c = '0001';
        orderItem6.vlocity_cmt__Action__c = 'Add';
        orderItem6.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem6.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem6.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem6.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        //orderItem6.vlocity_cmt__AssetReferenceId__c = '123456ab-7c89-0123-4567-89defg098765';
        insert orderItem6;
        
        OrderItem orderItem7 = new OrderItem();
        orderItem7.OrderId = orden4.Id;
        orderItem7.Product2Id = prod1.Id;
        orderItem7.PricebookEntryId = pbe1.Id;
        orderItem7.Quantity = 1;
        orderItem7.UnitPrice = 10;
        orderItem7.vlocity_cmt__LineNumber__c = '0001';
        orderItem7.vlocity_cmt__Action__c = 'Add';
        orderItem7.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem7.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem7.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem7.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        /*orderItem7.vlocity_cmt__AssetReferenceId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem7.vlocity_cmt__RootItemId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem7.vlocity_cmt__ReliesOnItemId__c = '123456ab-7c89-0123-4567-89defg098765';
        orderItem7.vlocity_cmt__ParentItemId__c = '123456ab-7c89-0123-4567-89defg098765';*/
        insert orderItem7;
        
        orden1.Status='Activated';
        orden2.Status='Cerrada Perdida';
        orden3.Status='Cerrada Perdida';
        orden4.Status='InPayment';
        
        update ordenes;
        
        // Create a Promotion Record
        vlocity_cmt__Promotion__c promotion =  new vlocity_cmt__Promotion__c(
            Name = 'Test Promotion',
            vlocity_cmt__Code__c = 'PENDIENTE', 
            CAT_Type__c = 'Estandar', 
            CAT_PromotionClass__c = 'Descuento'
        );
        insert promotion;

        // Create a test vlocity_cmt__OrderAppliedPromotion__c
        vlocity_cmt__OrderAppliedPromotion__c appliedPromotion = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__OrderId__c = orden1.Id,
            vlocity_cmt__PromotionId__c = promotion.Id,
            Name = 'Test Applied Promotion'
        );
        insert appliedPromotion;

        // Create a test vlocity_cmt__OrderAppliedPromotionItem__c
        vlocity_cmt__OrderAppliedPromotionItem__c promotionItem = new vlocity_cmt__OrderAppliedPromotionItem__c(
            vlocity_cmt__OrderItemId__c = orderItem1.Id, 
            vlocity_cmt__OrderAppliedPromotionId__c = appliedPromotion.Id, 
            Name = 'Test Promotion Item'
        );
        insert promotionItem;
        
        ast.vlocity_cmt__OrderId__c = orden1.Id;
        update assets;
    }
    
    @isTest
    private static void getOrderItemsByOrderTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'getOrderItemsByOrderId';
        Boolean res = false;
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order LIMIT 1];
        input.put('OrderId', orden.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'getOrderItemsByOrderTest');
    }
    
    
    @isTest
    private static void testbuildRequestChildItemToCart1(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = false;
        String methodName = 'buildRequestChildItemToCart';
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order LIMIT 1];
        //input
        input.put('OrderId', orden.Id);
        Map<String, Object> CartOperation = new Map<String, Object>();
        Map<String, Object> Product = new Map<String, Object>();
        Product.put('Product2Name', 'SIM');
        Product.put('Product2Code', 'B2C-ATTR-SIM-MATERIAL');
        input.put('Product', Product);
        input.put('OrderId', orden.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'testbuildRequestChildItemToCart1');
    }
    
    @isTest
    private static void testbuildRequestChildItemToCart2(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'buildRequestChildItemToCart';
        Boolean res = false;
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order LIMIT 1];
        //input
        input.put('OrderId', orden.Id);
        Map<String, Object> CartOperation = new Map<String, Object>();
        Map<String, Object> Product = new Map<String, Object>();
        Map<String, Object> ParentProduct = new Map<String, Object>();
        Product.put('Product2Name', 'SIM');
        Product.put('Product2Code', 'B2C-ATTR-SIM-MATERIAL');
        input.put('Product', Product);
        input.put('OrderId', orden.Id);
        
        ParentProduct.put('Product2Name', 'B2C-MOB-OFR-SIMCARD');
        ParentProduct.put('Product2Code', 'B2C-MOB-OFR-SIMCARD');
        input.put('ParentProduct', ParentProduct);
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
       	res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'testbuildRequestChildItemToCart2');
    }
    
    @isTest
    private static void getOrderItemsCambioPlanAccInmediatasTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = false;
        String methodName = 'getOrderItemsByOrderIdCambioPlanAccInmediatas';
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order LIMIT 1];
        input.put('OrderId', orden.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'getOrderItemsCambioPlanAccInmediatasTest');
    }
    
    @isTest
    private static void getPromosByOrderIdTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'getPromosByOrderId';
        Boolean res = false;
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order LIMIT 1];
        input.put('OrderId', orden.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'getPromosByOrderIdTest');
    }

    @isTest
    private static void updateOrderItemsByOrderIdCesionContratoTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = false;
        String methodName = 'updateOrderItemsByOrderIdCesionContrato';
        List<String> listGlobalKeys = new List<String>{'123456ab-7c89-0123-4567-89defg012345', '9876547ab-7c89-0123-4567-89defg0654321'};
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order WHERE FVU_ClosingReason__c = 'Muerto en caja sin cambio' LIMIT 1];
        input.put('OrderId', orden.Id);
        input.put('ListNewGlobalKeys', listGlobalKeys);
        
        Test.startTest();
            PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
            res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'updateOrderItemsByOrderIdCesionContratoTest');
    }
    
    @isTest
    private static void getOrdersByAssetAccountTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'getOrdersByAssetAccount';
        Boolean res = false;
        Account cuenta = [SELECT Id, Name FROM Account][0];
        input.put('AccountId', cuenta.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'getOrdersByAssetAccountTest');
    }
    
    @isTest
    private static void mergeListWithPositionTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = false;
        
        String methodName = 'mergeListWithPosition';		
        List<Object>  prodList = (List<Object>) JSON.deserializeUntyped('[{"productCode": "B2C-TERM-GALAXYA14-PLATA-128GB","sequence": 1,"position": "00010"},{"productCode": "B2C-TERM-IPHONE14-NEGRO-128GB","sequence": 1,"position": "00020"},{"productCode": "B2C-TERM-MOTOG22-NEGRO-128GB","sequence": 1,"position": "00030"}]');
        List<Object>  deviceList = (List<Object>) JSON.deserializeUntyped('[{"Product2CodeOrderItemRoot": "B2C-TERM-GALAXYA14-PLATA-128GB","Product2Code": "B2C-TERM-GALAXYA14-PLATA-128GB","Id": "802dm000006WYEPAA4"},{"LoopBlockIterationIndex": 2,"LoopBlockIterationStatus": true,"SVFindRootItemDeviceStatus": true,"RootItemId": "f531fc31-81ca-ef3e-8957-579ce1aef82b","Product2CodeOrderItemRoot": "B2C-TERM-IPHONE14-NEGRO-128GB","Product2Code": "B2C-TERM-IPHONE14-NEGRO-128GB","Id": "802dm000006WYEQAA4"},{"LoopBlockIterationIndex": 3,"LoopBlockIterationStatus": true,"SVFindRootItemDeviceStatus": true,"RootItemId": "9cabcad1-9b15-edfb-9291-3d463b726c12","Product2CodeOrderItemRoot": "B2C-TERM-MOTOG22-NEGRO-128GB","Product2Code": "B2C-TERM-MOTOG22-NEGRO-128GB","Id": "802dm000006WYERAA4"}]');
    
        input.put('listDevices', deviceList);
        input.put('listProducts', prodList);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Assert.isTrue(res, 'mergeListWithPosition');
    }
    
    @isTest
    private static void checkPromoCFMLast6Months() {
        
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(
            CAT_Type__c = 'TodoClaro',
            vlocity_cmt__Code__c = 'PO_MovPosOptAppClaroVidPromoA001',
            CAT_PromotionClass__c = 'Obsequios de CFM'
        );
        insert promo;
        
        vlocity_cmt__AccountAppliedPromotion__c appliedPromo = new vlocity_cmt__AccountAppliedPromotion__c(
            vlocity_cmt__PromotionId__c = promo.Id,
            vlocity_cmt__BillingAccountId__c = acc.Id
        );
        insert appliedPromo;
        
        vlocity_cmt__AccountAppliedPromotionItem__c accAppliedPromo = new vlocity_cmt__AccountAppliedPromotionItem__c(
            vlocity_cmt__AssetId__c = ast.Id,
            vlocity_cmt__AppliedPromotionId__c = appliedPromo.Id
        );
        insert accAppliedPromo;
        
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = false;
        
        String methodName = 'checkPromoCFMLast6Months';
        input.put('AssetRootId', ast.Id);
        
        Test.startTest();
        PVU_CambioSimInterface CambioSimInterface = new PVU_CambioSimInterface();
        res = CambioSimInterface.invokeMethod(methodName, input, output, options);
        Test.stopTest();
    }
    
    
    
}