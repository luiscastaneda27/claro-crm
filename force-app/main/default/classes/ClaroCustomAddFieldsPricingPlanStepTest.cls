@isTest
private class ClaroCustomAddFieldsPricingPlanStepTest {

    @isTest
    static void testOrderTerminal() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 5, 15);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);
        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        //Create Test Data for IVA Object "FVU_Exencion_IVA_EI__c"
        FVU_Exencion_IVA_EI__c exencionIVAEI = CATTestDataFactory.CreateExencionIVAEI();
        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();
        // set up the input for ClaroCustomAddFieldsPricingPlanStepImpl
        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 10000);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        // Calling main class
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrder);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testOrderTerminalDelivery() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccountWithoutIVA = CATTestDataFactory.createAccount(false);
        Account testAccountWithIVA = CATTestDataFactory.createAccount(true);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Handset', 10, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        Order testOrderWithoutIVA = CATTestDataFactory.createOrder(testAccountWithoutIVA, testPricebook, 'Delivery',false);
        Order testOrderWithIVA = CATTestDataFactory.createOrder(testAccountWithIVA, testPricebook, 'Delivery',true);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrderWithoutIVA.Id, testProduct, testPricebookEntry, testAccountWithoutIVA.Id);
        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrderWithoutIVA.Id];
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        //Create Test Data for IVA Object "FVU_Exencion_IVA_Dom__c"
        FVU_Exencion_IVA_Dom__c exencionIVAEDom = CATTestDataFactory.CreateExencionIVADom();
        //Create Test Data for IVA Object "FVU_Exencion_IVA_Bodega_Envio__c"
        FVU_Exencion_IVA_Bodega_Envio__c exencionIVABODG = CATTestDataFactory.CreateExencionIVABODG();

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();
        // set up the input for ClaroCustomAddFieldsPricingPlanStepImpl
        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 10000);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        // Calling main class
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithoutIVA);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        Test.startTest();
        //Entrega en domicilio (Delivery) - Caso donde NO Aplica IVA
        Boolean testResponseNoIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        //Entrega en domicilio (Delivery) - Caso donde SÍ Aplica IVA
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithIVA);
        Boolean testResponseIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponseNoIVA, 'La Clase no debe retornar "False" en Caso donde NO Aplica IVA');
        System.assertEquals(true, testResponseNoIVA, 'La Clase retorna "true" en Caso donde NO Aplica IVA');
        System.assertNotEquals(false, testResponseIVA, 'La Clase no debe retornar "False" en Caso donde SÍ Aplica IVA');
        System.assertEquals(true, testResponseIVA, 'La Clase retorna "true" en Caso donde SÍ Aplica IVA');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testOrderTechPickUp() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Tech', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];
        Order testOrderWithoutIVA = CATTestDataFactory.createOrder(testAccount, testPricebook, 'PickUp',false);
        Order testOrderWithIVA = CATTestDataFactory.createOrder(testAccount, testPricebook, 'PickUp',true);
        System.debug('testOrderWithoutIVA: ' + testOrderWithoutIVA);
        System.debug('testOrderWithIVA: ' + testOrderWithIVA);
        System.debug('testOrderWithoutIVA.Id: ' + testOrderWithoutIVA.Id);
        System.debug('testOrderWithIVA.Id: ' + testOrderWithIVA.Id);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrderWithoutIVA.Id, testProduct, testPricebookEntry, testAccount.Id);
        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrderWithoutIVA.Id];
        System.debug('Order Items Retrieved: ' + itemList);
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        //Create Test Data for IVA Object "FVU_Exencion_IVA_Ret_Tienda__c"
        FVU_Exencion_IVA_Ret_Tienda__c exencionIVARetTienda = CATTestDataFactory.CreateExencionIVARetTienda();
        //Create Test Data for IVA Object "FVU_Exencion_IVA_Bodega_Envio__c"
        FVU_Exencion_IVA_Bodega_Envio__c exencionIVABODG = CATTestDataFactory.CreateExencionIVABODG();

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        // set up the input for ClaroCustomAddFieldsPricingPlanStepImpl
        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 10000);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }
        // Calling main class
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithoutIVA);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);

        Test.startTest();
        //Entrega en domicilio (Delivery) - Caso donde NO Aplica IVA
        Boolean testResponseNoIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        //Entrega en domicilio (Delivery) - Caso donde SÍ Aplica IVA
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithIVA);
        Boolean testResponseIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponseNoIVA, 'La Clase no debe retornar "False" en Caso donde NO Aplica IVA');
        System.assertEquals(true, testResponseNoIVA, 'La Clase retorna "true" en Caso donde NO Aplica IVA');
        System.assertNotEquals(false, testResponseIVA, 'La Clase no debe retornar "False" en Caso donde SÍ Aplica IVA');
        System.assertEquals(true, testResponseIVA, 'La Clase retorna "true" en Caso donde SÍ Aplica IVA');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testMobilePlanProduct() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);

        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Plan', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Order testOrderWithoutIVA = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        Order testOrderWithIVA = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Delivery',true);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrderWithoutIVA.Id, testProduct, testPricebookEntry, testAccount.Id);

        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrderWithoutIVA.Id];

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('REC_MNTH_STD_PRC', 10000);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithoutIVA);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        Test.startTest();
        Boolean testResponseNoIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWithIVA);
        Boolean testResponseIVA = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponseNoIVA, 'La Clase no debe retornar "False" en Caso donde NO Aplica IVA');
        System.assertEquals(true, testResponseNoIVA, 'La Clase retorna "true" en Caso donde NO Aplica IVA');
        System.assertNotEquals(false, testResponseIVA, 'La Clase no debe retornar "False" en Caso donde SÍ Aplica IVA');
        System.assertEquals(true, testResponseIVA, 'La Clase retorna "true" en Caso donde SÍ Aplica IVA');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testFeeProduct() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);

        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Fee', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 0);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrder);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testSIMProduct() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);

        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'SIM Card', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);

        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 0);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrder);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testOrderWorkingCart() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);

        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Fee', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup',false);
        Order testOrderWorkingCart = CATTestDataFactory.createOrderWorkingCart(testOrder, testAccount, testPricebook, 'Immediatepickup');

        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);

        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];
        //Create Test Data for IVA
        FVU_IVA_info__c CreateIVAInfo = CATTestDataFactory.CreateIVAInfo();
        //Create Test Data for UVT
        FVU_UVT_info__c CreateUVTInfo = CATTestDataFactory.CreateUVTInfo();
        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 0);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWorkingCart);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();

        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testWorkingCartWrongMethodInfo() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);

        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Fee', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Order testOrder = CATTestDataFactory.createOrder(testAccount, testPricebook, 'Immediatepickup', false);
        Order testOrderWorkingCart = CATTestDataFactory.createOrderWorkingCart(testOrder, testAccount, testPricebook, 'Immediatepickup');

        OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);

        List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];
        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();

        for (SObject sObj : itemList)
        {
            Map<String, Object> infoMap = new Map<String, Object>();
            infoMap.put('ProductId', sObj.get('Product2Id'));
            infoMap.put('vlocity_cmt__Product2Id__c', sObj.get('vlocity_cmt__Product2Id__c'));
            infoMap.put('PricingVariableLog', new Map<String, Object>()); // we don't care about this in ClaroCustomAddFieldsPricingPlanStepImpl
            Map<String, Object> pricingVariableCodeToValueMap = new Map<String, Object>();
            pricingVariableCodeToValueMap.put('OT_STD_PRC', 0);
            infoMap.put('PricingVariableValues', pricingVariableCodeToValueMap);
            testData.put(sObj.Id, infoMap);
        }

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testOrderWorkingCart);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfoWrong', input, output, options);
        Test.stopTest();
        

        // Assert
        System.assertNotEquals(true, testResponse, 'La Clase no debe retornar "True" ya que se está probando con un metodo incorrecto');
        System.assertEquals(false, testResponse, 'La Clase retorna "False" - debido a una llamada del metodo incorrecta');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testQuote() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);
        Opportunity testOpp = CATTestDataFactory.createOpp(testAccount);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Fee', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Quote testQuote = CATTestDataFactory.createQuote(testAccount, testPricebook,testOpp, 'Immediatepickup');
        //OrderItem testOrderItem = CATTestDataFactory.createOrderItem(testOrder.Id, testProduct, testPricebookEntry, testAccount.Id);

        //List<SObject> itemList = [SELECT Id, OrderId,Product2Id,vlocity_cmt__Product2Id__c,PricebookEntry.Id, PricebookEntry.Product2.Name, Quantity, vlocity_cmt__LineNumber__c,
        //vlocity_cmt__Action__c, vlocity_cmt__ProvisioningStatus__c, vlocity_cmt__AttributeSelectedValues__c from OrderItem where OrderId =: testOrder.Id];

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();
        // Llenar el mapa con un ejemplo vacío
        testData.put(testQuote.Id, new Map<String, Object>{
            'TestKey' => null});
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testQuote);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        //Test Parent Quote
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();
        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
    @isTest
    static void testQuoteWorkingCart() {
        //Create Test Data
        Pricebook2 testPricebook = CATTestDataFactory.createPriceBook();
        Account testAccount = CATTestDataFactory.createAccount(false);
        Opportunity testOpp = CATTestDataFactory.createOpp(testAccount);
        List <SObject> testProductList = CATTestDataFactory.createProductAndPriceBookEntry(testPricebook, 'Fee', 15, 5);
        System.debug('testProduct '+ testProductList);
        Product2 testProduct = (Product2)testProductList[0];
        PricebookEntry testPricebookEntry = (PricebookEntry) testProductList[1];

        Quote testQuote = CATTestDataFactory.createQuote(testAccount, testPricebook, testOpp, 'Immediatepickup');
        Quote testQuoteWorkingCart = CATTestDataFactory.createQuoteWorkingCart(testQuote, testAccount, testPricebook, testOpp, 'Immediatepickup');

        Map<String, Object> input = new Map<String, Object>{'Test' => 'Test'};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<Id, Map<String, Object>> testData = new Map<Id, Map<String, Object>>();
        // Llenar el mapa con un ejemplo vacío
        testData.put(testQuote.Id, new Map<String, Object>{
        'TestKey' => null});

        //vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemList);
        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', testQuoteWorkingCart);
        vlocity_cmt.PricingPlanService.putInPricingContext('TestLineItemPricingVariableValues', testData);
        ClaroCustomAddFieldsPricingPlanStepImpl instance = new ClaroCustomAddFieldsPricingPlanStepImpl();
        //Test Working Cart Quote
        Test.startTest();
        Boolean testResponse = instance.invokeMethod('GetSalesContextInfo', input, output, options);
        Test.stopTest();
        // Assert
        System.assertNotEquals(false, testResponse, 'La Clase no debe retornar "False"');
        System.assertEquals(true, testResponse, 'La Clase retorna "true"');
        System.debug('Test passed successfully.');
    }
}