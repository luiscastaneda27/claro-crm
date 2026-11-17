@isTest
private class PVU_Gestiones_Masivas_Handler_Test {
    
    @TestSetup
    private static void dataSetup() {
        // Crear cuenta
        Account acc = new Account(Name = 'Test Account', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '111', FVU_AccountExternalID__c = '93000000055938');
        insert acc;
        
        // Crear suscripción
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000000', OM_SusByCollectionsFlag__c = '1');
        insert testSubscription;
        
        // Crear producto
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        // Crear activos
        Asset ast = new Asset(Name = 'Test Asset1', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        insert pbe1;                   
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Cancelled';
        insert orden1;
        
        Order orden2 = new Order();
        orden2.Status = 'Draft';
        orden2.EffectiveDate = System.Today();
        orden2.AccountId = acc.Id;
        orden2.Pricebook2Id = pricebookId;
        orden2.vlocity_cmt__OrderStatus__c = 'Queued';
        insert orden2;
        
        /****Creacion de orden item****/
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orden2.Id;
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
        orderItem1.vlocity_cmt__AssetId__c = ast.Id;
        insert orderItem1;
        
        // Crear registro de gestiones masivas
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055938', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_ReasonId__c = '221' ,
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        // Crear registro de gestiones masivas
        PVU_Gestiones_Masivas__c gestionFraude = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055940', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION',
            PVU_Source__c = 'FRAUDE_COM', 
            PVU_ReasonId__c = '226',
            PVU_JobIdentifier__c = '1111'
        );
        insert gestionFraude;
    }

    @isTest
    static void testAssetServiceNewGMRecordAssetFoundedSuccess() {
        // Obtener el registro de gestion masiva para la prueba
        PVU_Gestiones_Masivas__c gestion = [SELECT Id, Name, PVU_Status__c, PVU_Action__c, PVU_CustNum__c, PVU_BillingAccountId__c, PVU_Source__c, PVU_Message__c, PVU_ReasonId__c, PVU_SuspensionLevel__c, PVU_CaseId__c, PVU_Status_OM__c, PVU_Description__c,PVU_Motivo__c, PVU_FeaturesOrServices__c, PVU_FechaVentaCartera__c,
                                            PVU_CiudadComprador__c,
                                            PVU_ConvenioPago__c,
                                            PVU_Producto__c,
                                            PVU_ObligacionNo__c,
                                            PVU_Saldo__c,
                                            PVU_CorreoElectronico__c,
                                            PVU_PaginaWeb__c,
                                            PVU_Nit__c,
                                            PVU_DireccionComprador__c,
                                            PVU_TelefonoComprador__c,
                                            PVU_ContractId__c,
                                            PVU_NombreCompradorCartera__c,
                                            PVU_Marca__c 
                                            FROM PVU_Gestiones_Masivas__c WHERE PVU_CustNum__c = '93000000055938' LIMIT 1];
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
        
        // Verificar que el status se actualizó correctamente
        gestion = [SELECT PVU_Status__c, PVU_CaseId__c FROM PVU_Gestiones_Masivas__c WHERE Id = :gestion.Id LIMIT 1];
        // System.assertEquals('Caso creado', gestion.PVU_Status__c, 'El registro de GM debe actualizarse con el status "Caso creado"');
        System.assertNotEquals(null, gestion.PVU_CaseId__c, 'Cuando los datos de GM coinciden correctamente con el asset, debe crearse un caso');
    }
    
    @isTest
    static void testHandleRecordNotFound() {
        // Crear cuenta sin registros de gestión coincidentes
        Account acc = new Account(Name = 'Test Account No Case', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055930');
        insert acc;
        
        // Crear un registro de gestión masiva que no coincida
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c();
        gestion.PVU_SuspensionLevel__c = '1';
        gestion.PVU_CustNum__c = '9300000005593';
        gestion.PVU_BillingAccountId__c = acc.Id;
        gestion.PVU_Action__c = 'SUSPENSION';
        gestion.PVU_Source__c = 'COLLECTIONS';
        gestion.PVU_ReasonId__c = '221';
        gestion.PVU_JobIdentifier__c = '1111';
        insert gestion;
        
        // Ejecutar el método de handler
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion); // Cambiado para pasar solo una gestión
        Test.stopTest();
        
        // Verificar que no se ha creado ningún caso
        gestion = [SELECT PVU_Status__c, PVU_CaseId__c FROM PVU_Gestiones_Masivas__c WHERE Id = :gestion.Id LIMIT 1];
        // System.assertEquals('Error', gestion.PVU_Status__c, 'El registro de GM debe actualizarse con el status "Error" debido a la falta de un caso previo');
        System.assertEquals(null, gestion.PVU_CaseId__c, 'No debe crearse un caso cuando no existe un caso previo asociado');
    }
    
    @isTest
    static void testCaseCreatedForSuspensionLevelIncrease() {
        // Setup para el primer escenario
        Account acc = [SELECT Id FROM Account WHERE FVU_AccountExternalID__c = '93000000055938' LIMIT 1];
        
        Order order = new Order(AccountId = acc.Id, Type = 'Suspension', PVU_SuspensionLevel__c = '1', status = 'Draft', EffectiveDate = Date.today());
        insert order;
        
        // Crear un caso previo con nivel de suspensión 1
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', PVU_Order__c = order.Id, 
                                     PVU_Level1__c = 'Facturación y pagos', PVU_Level2__c = 'Pagos', PVU_Level3__c = 'Proceso Cobranza');
        insert existingCase;
        
        // Crear gestión masiva con nivel de suspensión 2
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '2', 
            PVU_CustNum__c = '93000000055938', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION',
            PVU_ReasonId__c = '221',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        // Ejecutar el método de handler
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion); // Cambiado para pasar solo una gestión
        Test.stopTest();
        
        // Verificar que se ha creado un caso nuevo para la gestión
        gestion = [SELECT PVU_Status__c, PVU_CaseId__c FROM PVU_Gestiones_Masivas__c WHERE Id = :gestion.Id LIMIT 1];
        // System.assertEquals('Caso creado', gestion.PVU_Status__c, 'El registro de GM debe actualizarse con el status "Caso creado"');
        System.assertNotEquals(null, gestion.PVU_CaseId__c, 'Debe crearse un nuevo caso para el aumento del nivel de suspensión');
    }
    
    @isTest
    static void testErrorForDuplicateCase() {
        Asset asset = [SELECT Id FROM Asset WHERE vlocity_cmt__SubscriptionId__r.OM_SusByCollectionsFlag__c = '1'];
        Account acc = [SELECT Id FROM Account WHERE FVU_AccountExternalID__c = '93000000055938' LIMIT 1];
        
        Order order = new Order(AccountId = acc.Id, Type = 'Suspension', PVU_SuspensionLevel__c = '1', status = 'Draft', EffectiveDate = Date.today());
        insert order;
        
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', PVU_Order__c = order.Id, AssetId = asset.Id,
                                     PVU_Level1__c = 'Facturación y pagos', PVU_Level2__c = 'Pagos', PVU_Level3__c = 'Proceso Cobranza');
        insert existingCase;
        
        existingCase.Status = 'Cerrado';
        update existingCase;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055938', 
            PVU_ReasonId__c = '221',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION', 
            PVU_CaseId__c = existingCase.Id,
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion); // Cambiado para pasar solo una gestión
        Test.stopTest();
        
        gestion = [SELECT PVU_Status__c, PVU_CaseId__c FROM PVU_Gestiones_Masivas__c WHERE Id = :gestion.Id LIMIT 1];
        System.assertEquals('Error', gestion.PVU_Status__c, 'El registro de GM debe actualizarse con el status "Error" por ser un duplicado');
        // System.assertEquals(null, gestion.PVU_CaseId__c, 'No debe crearse un caso ya que ya existe un caso con el mismo nivel de suspensión');
    }
    
    @isTest
    static void testDeactivateGestion() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', AssetId = ast.Id,
                                     PVU_Level1__c = 'Facturación y pagos', PVU_Level2__c = 'Pagos', PVU_Level3__c = 'Proceso Cobranza');
        insert existingCase;
        
        existingCase.Status = 'Cerrado';
        update existingCase;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055939', 
            PVU_ReasonId__c = '2008',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATION', 
            PVU_CaseId__c = existingCase.Id,
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
        
    }
    
    @isTest
    static void testFraudeCOMGestion() {
        Account acc = new Account(Name = 'Test Account2', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '333', FVU_AccountExternalID__c = '93000000055940');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__SubscriptionNumber__c = '123', vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFK', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id, vlocity_cmt__ParentItemId__c = null, vlocity_cmt__AssetReferenceId__c = '2cacaf5f-c61a-e699-4f88-9159b3135323');
        insert ast;
        
        Asset ast2 = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id, vlocity_cmt__ParentItemId__c = ast.vlocity_cmt__AssetReferenceId__c);
        insert ast2;
        
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', AssetId = ast2.Id,
                                     PVU_Level1__c = 'Solicitud de información y modificaciones', PVU_Level2__c = 'Control Prevención Fraude', PVU_Level3__c = 'Proceso Prevención Fraude');
        insert existingCase;
        
        // Cerrar el caso existente
        existingCase.Status = 'Cerrado';
        update existingCase;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055940', 
            PVU_ReasonId__c = '38',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION', 
            PVU_CaseId__c = existingCase.Id,
            PVU_Source__c = 'FRAUDE_COM', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
   
    }
    
	@isTest
    static void testCaseAndOrderCreatedForReinstalacion() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055939', 
            PVU_ReasonId__c = '110',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'REINSTALATION', 
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }

	@isTest
    static void testGetValidService() { 
        Account acc = new Account(Name = 'Test Account11', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '22234', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 11', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset11', status = 'Deactivated',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c(
            PVU_SuspensionLevel__c = '1', 
            PVU_CustNum__c = '93000000055939', 
            PVU_ReasonId__c = '110',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'REINSTALATION', 
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01'
        );
        insert gestion;

        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        PVU_Gestiones_Masivas_Handler.WGestionMasiva testGestionMasiva = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestion);
        testGestionMasiva.Asset = ast;
        handler.getValidService(testGestionMasiva);
        Test.stopTest();
    }
    
    @isTest
    static void testCaseCreatedForActiveFuncBlock() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_FUNC',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_MSISDN__c = '1234',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	//activar para gpt01
        	handler.assetService(gestion);
        
        	//activar para fraude
        	PVU_Gestiones_Masivas__c gestion1 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'ACTIVATE_FUNC',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'FRA01',
                PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
            );
        	insert gestion1;
        	handler.assetService(gestion1);
        
        	//funcionalidad ya activa
        	ast.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BLQ-LDI":true}';
        	update ast;
        	handler.assetService(gestion);
        
        	//Funcionalidad ya activa con Fraude
              PVU_Gestiones_Masivas__c gestion2 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'ACTIVATE_FUNC',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'FRA01',
                PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
            );
            insert gestion2;
        	handler.assetService(gestion2);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCaseAndOrderCreatedForDesactiveFuncBlockFra() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BLQ-SMS-ENT":true}');
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_FUNC',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_MSISDN__c = '1234',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-SMS-ENT'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        
                handler.assetService(gestion);
                
                //funcionalidad ya desactivada
                ast.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BLQ-SMS-ENT":false}';
                update ast;
                handler.assetService(gestion);
                
                //Funcionalidad ya Desaactiva con Fraude
                PVU_Gestiones_Masivas__c gestion2 = new PVU_Gestiones_Masivas__c( 
                    PVU_CustNum__c = '93000000055939',
                    PVU_BillingAccountId__c = acc.Id, 
                    PVU_Action__c = 'DEACTIVATE_FUNC',
                    PVU_Source__c = 'FRAUDE_GPT', 
                    PVU_JobIdentifier__c = '1111',
                    PVU_Motivo__c = 'FRA01',
                     PVU_MSISDN__c = '1234',
                    PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-SMS-ENT'
                );
                insert gestion2;
                handler.assetService(gestion2);
                
                //Error no encuentra llave
                ast.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BLQ-SMS-SAL":false}';
                update ast;
                handler.assetService(gestion);
        
        Test.stopTest();
    }
    
    @isTest
    static void testCaseAndOrderCreatedForActiveSA() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_SA',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_MSISDN__c = '1234',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	//activar GPT01
        	handler.assetService(gestion);
        
            //activar FRAU
            PVU_Gestiones_Masivas__c gestion1 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'ACTIVATE_SA',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'FRA01',
                PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
            );
            insert gestion1;
        	handler.assetService(gestion1);
        
        	//Deactivate SA sin producto
            PVU_Gestiones_Masivas__c gestion2 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'DEACTIVATE_SA',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'GPT01',
                PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
            );
            insert gestion2;
        	handler.assetService(gestion2);
        
        	//Activar SA con producto ya agregado
            Product2 prodPrime = new Product2 (Name='HBO', ProductCode = 'PO_MovPosOptOTTMaxStdSA', FVU_Beneficios__c = '', vlocity_cmt__Type__c = 'Add On', vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple');
            insert prodPrime;
        
            Asset astPrime = new Asset(Name = 'HBO',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodPrime.Id, vlocity_cmt__ReliesOnItemId__c = '12344321');
            insert astPrime;
        
        	PVU_Gestiones_Masivas__c gestion3 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'ACTIVATE_SA',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'GPT01',
                PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
            );
            insert gestion3;
        	handler.assetService(gestion3);
        
        Test.stopTest();
        
    }

    @isTest
    static void testCaseAndOrderCreatedForDeactiveSA() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_SA',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_MSISDN__c = '1234',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	//Desactivar sin producto
        	handler.assetService(gestion);
        
        	//desactivar SA con producto ya agregado
            Product2 prodPrime = new Product2 (Name='HBO', ProductCode = 'PO_MovPosOptOTTMaxStdSA', FVU_Beneficios__c = '', vlocity_cmt__Type__c = 'Add On', vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple');
            insert prodPrime;
        
            Asset astPrime = new Asset(Name = 'HBO',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodPrime.Id, vlocity_cmt__ReliesOnItemId__c = '12344321');
            insert astPrime;
        
        	PVU_Gestiones_Masivas__c gestion3 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055939',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'ACTIVATE_SA',
                PVU_Source__c = 'FRAUDE_GPT', 
                PVU_JobIdentifier__c = '1111',
                PVU_Motivo__c = 'GPT01',
                 PVU_MSISDN__c = '1234',
                PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
            );
            insert gestion3;
        	handler.assetService(gestion3);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testActiveRoamingEqualsTrue() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        // Create products
         Product2 prodRoot= new Product2 ();
            prodRoot.Name = 'Mobile Plan';
            prodRoot.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodRoot.FVU_Beneficios__c = '';
            prodRoot.Family = 'Mobile';
            prodRoot.vlocity_cmt__Type__c = 'Plan';
            prodRoot.vlocity_cmt__SubType__c = 'Postpaid';
            prodRoot.vlocity_cmt__SpecificationType__c = 'Offer';
            prodRoot.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodRoot;
                
        Product2 prodMobilePlan = new Product2 ();
            prodMobilePlan.Name = 'Mobile Plan';
            prodMobilePlan.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodMobilePlan.FVU_Beneficios__c = '';
            prodMobilePlan.Family = 'Mobile';
            prodMobilePlan.vlocity_cmt__Type__c = 'Plan';
            prodMobilePlan.vlocity_cmt__SubType__c = 'Postpaid';
            prodMobilePlan.vlocity_cmt__SpecificationType__c = 'Offer';
            prodMobilePlan.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodMobilePlan;
        
        Asset astRoot = new Asset(Name = 'Test Root',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodRoot.Id);
        insert astRoot;
        
        Asset astPlan = new Asset(Name = 'Test asset Plan', vlocity_cmt__ParentItemId__c = astRoot.Id, Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodMobilePlan.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-LIMIT-NAC-SRV":28676,"B2C-ATTR-LIMIT-Roaming":35845,"B2C-ATTR-ROAMING":true,"B2C-ATTR-ROAMING-ACTIVACION":null,"B2C-ATTR-ROAMING-BARR":true,"B2C-ATTR-ROAMING-BLQ-GPT":false,"B2C-ATTR-ROAMING-DESACTIVACION":null,"B2C-ATTR-ROAMING-IND":false}');
        insert astPlan;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbePlan = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id   = prodMobilePlan.Id,
            UnitPrice    = 1,
            IsActive     = true
        );
        insert pbePlan;
        Order orden = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = pricebookId,
            vlocity_cmt__OrderStatus__c = 'Queued'
        );
        insert orden;
        OrderItem orderItem1 = new OrderItem(
            OrderId = orden.Id,
            Product2Id = prodMobilePlan.Id,
            PricebookEntryId = pbePlan.Id,
            Quantity = 1,
            UnitPrice = 10,
            vlocity_cmt__LineNumber__c = '0001',
            vlocity_cmt__Action__c = 'Add',
            vlocity_cmt__ProvisioningStatus__c = 'New',
            vlocity_cmt__ServiceAccountId__c = acc.Id,
            FVU_OneTimeTotalIncTaxes__c = 2000000,
            FVU_ProductDeliveryStatus__c = 'ReadyForPickup',
            vlocity_cmt__AssetId__c = astPlan.Id
        );
        insert orderItem1;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_ROAMING',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_MSISDN__c = '1234',
            PVU_Motivo__c = 'GPT01'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	//Roaming ya activo y activamos
        	handler.assetService(gestion);
        
        	//Roaming ya activo y desactivamos
        	PVU_Gestiones_Masivas__c gestion2 = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_ROAMING',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_MSISDN__c = '1234',
            PVU_Motivo__c = 'FRA01'
            );
            insert gestion2;
        	// handler.assetService(gestion2);
        
        	//ROAMING en asset inactivo
        	astPlan.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-ROAMING":false}';
            update astPlan;
        	
        	//Roaming inactivo en asset y activamos
            handler.assetService(gestion);
        
        	//Roaming inactivo en asset y Desactivamos
            // handler.assetService(gestion2);
        
        	//Test error roaming no encontro la llave
        	astPlan.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEST":false}';
            update astPlan;
        	handler.assetService(gestion);
        
        Test.stopTest();
    }
    
    @isTest
   	static void testFraudeGPTGestion() {
        Account acc = new Account(Name = 'Test Account2', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '444', FVU_AccountExternalID__c = '93000000055941');
        insert acc;
       
       	// Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(OM_MSISDN__c ='', vlocity_cmt__SubscriptionNumber__c = '124', vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida');
        insert testSubscription;
        
        // Create products
         Product2 prodRoot= new Product2 ();
            prodRoot.Name = 'Mobile Plan';
            prodRoot.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodRoot.FVU_Beneficios__c = '';
            prodRoot.Family = 'Mobile';
            prodRoot.vlocity_cmt__Type__c = 'Plan';
            prodRoot.vlocity_cmt__SubType__c = 'Postpaid';
            prodRoot.vlocity_cmt__SpecificationType__c = 'Offer';
            prodRoot.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodRoot;
                
        Product2 prodMobilePlan = new Product2 ();
            prodMobilePlan.Name = 'Mobile Plan';
            prodMobilePlan.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodMobilePlan.FVU_Beneficios__c = '';
            prodMobilePlan.Family = 'Mobile';
            prodMobilePlan.vlocity_cmt__Type__c = 'Plan';
            prodMobilePlan.vlocity_cmt__SubType__c = 'Postpaid';
            prodMobilePlan.vlocity_cmt__SpecificationType__c = 'Offer';
            prodMobilePlan.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodMobilePlan;
       
       	Product2 productFunc = new Product2();
        productFunc.Family = 'CS/CD';
        productFunc.ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS';
        productFunc.Name = 'Cambio';
        insert productFunc; 
        
        Asset astRoot = new Asset(Name = 'Test Root',Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodRoot.Id);
        insert astRoot;
        
        Asset astPlan = new Asset(Name = 'Test asset Plan', vlocity_cmt__ParentItemId__c = astRoot.Id, Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodMobilePlan.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-LIMIT-NAC-SRV":28676,"B2C-ATTR-LIMIT-Roaming":35845,"B2C-ATTR-ROAMING":true,"B2C-ATTR-ROAMING-ACTIVACION":null,"B2C-ATTR-ROAMING-BARR":true,"B2C-ATTR-ROAMING-BLQ-GPT":false,"B2C-ATTR-ROAMING-DESACTIVACION":null,"B2C-ATTR-ROAMING-IND":false}');
        insert astPlan;   
       
        
        PricebookEntry pbePlan = new PricebookEntry();
        pbePlan.Pricebook2Id = pricebookId;
        pbePlan.Product2Id = prodMobilePlan.Id;
        pbePlan.UnitPrice = 1;
        pbePlan.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbePlan;  
        
        PricebookEntry pbeFunc = new PricebookEntry();
        pbeFunc.Pricebook2Id = pricebookId;
        pbeFunc.Product2Id = productFunc.Id;
        pbeFunc.UnitPrice = 1;
        pbeFunc.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeFunc;  
        
        PricebookEntry pbeRoot = new PricebookEntry();
        pbeRoot.Pricebook2Id = pricebookId;
        pbeRoot.Product2Id = prodRoot.Id;
        pbeRoot.UnitPrice = 1;
        pbeRoot.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeRoot;  
       
       /****Creacion de ordenes****/
       Id recordTypeIdOrder = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('StandardOrder').getRecordTypeId();
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Ready To Submit';
        orden1.Type = 'Cambios';
        orden1.FVU_OrderSubType__c = 'Cambio de Plan';
        orden1.RecordTypeId = recordTypeIdOrder;
        insert orden1;
       
       /*****************************/        
        OrderItem orderItemRoot = new OrderItem();
        orderItemRoot.OrderId = orden1.Id;
        orderItemRoot.Product2Id = prodRoot.Id;
        orderItemRoot.PricebookEntryId = pbeRoot.Id;
        orderItemRoot.Quantity = 1;
        orderItemRoot.UnitPrice = 10;
        orderItemRoot.vlocity_cmt__LineNumber__c = '0001';
        orderItemRoot.vlocity_cmt__Action__c = 'Add';
        orderItemRoot.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemRoot.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemRoot.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemRoot.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemRoot.vlocity_cmt__AssetReferenceId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemRoot.vlocity_cmt__ParentItemId__c = null;
        insert orderItemRoot;
        
        
        OrderItem orderItemPlan = new OrderItem();
        orderItemPlan.OrderId = orden1.Id;
        orderItemPlan.Product2Id = prodMobilePlan.Id;
        orderItemPlan.PricebookEntryId = pbePlan.Id;
        orderItemPlan.Quantity = 1;
        orderItemPlan.UnitPrice = 10;
        orderItemPlan.vlocity_cmt__LineNumber__c = '0001';
        orderItemPlan.vlocity_cmt__Action__c = 'Add';
        orderItemPlan.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemPlan.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemPlan.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemPlan.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemPlan.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemPlan.vlocity_cmt__AttributeSelectedValues__c= '{"B2C-ATTR-CG-TIPO-PLAN":"Mixto","B2C-ATTR-COD-SPLIT":1,"B2C-ATTR-PAQ-COMPATIBLES":"Bundle sin LDI","B2C-ATTR-LIMIT-NAC-PAQ":17922,"B2C-ATTR-LIMIT-NAC-SRV":28676,"B2C-ATTR-LIMIT-Roaming":35845,"B2C-ATTR-ROAMING":false,"B2C-ATTR-ROAMING-ACTIVACION":null,"B2C-ATTR-ROAMING-BARR":true,"B2C-ATTR-ROAMING-BLQ-GPT":false,"B2C-ATTR-ROAMING-DESACTIVACION":null,"B2C-ATTR-ROAMING-IND":false,"B2C-ATTR-SI-DATOS":"60","B2C-ATTR-SI-KB-ADICIONAL":null,"B2C-ATTR-SI-LDI-HISP":null,"B2C-ATTR-SI-LDI-MIN":null,"B2C-ATTR-SI-LDI-REST":null,"B2C-ATTR-SI-ROAM-CAN":false,"B2C-ATTR-SI-SMS-CLARO":null,"B2C-ATTR-SI-SMS-NAL":"Ilimitado","B2C-ATTR-SI-TETHERING":"60","B2C-ATTR-SI-VOZ-NAL":"Ilimitado","B2C-ATTR-APP-CABIFY":false,"B2C-ATTR-APP-FB":true,"B2C-ATTR-APP-INSTAGRAM":false,"B2C-ATTR-APP-MOVETIME":false,"B2C-ATTR-APP-RELEVO":false,"B2C-ATTR-APP-TAXIS-LIBRES":false,"B2C-ATTR-APP-TWITTER":true,"B2C-ATTR-APP-WA":true,"B2C-ATTR-APP-WAZE":false,"B2C-ATTR-SA-CLR-DRIVE":true,"B2C-ATTR-SA-CLR-MUSICA-GR":true,"B2C-ATTR-SA-CLR-MUSICA-PREM":false,"B2C-ATTR-SA-CLR-VIDEO":true,"B2C-ATTR-FAM-Y-AMIGOS":true,"B2C-ATTR-SERV-ID":null,"B2C-ATTR-TECH-DET":null,"B2C-ATTR-PRC-DET":null}';
        insert orderItemPlan;
             
		orden1.vlocity_cmt__OrderStatus__c = 'Queued';
        update orden1;
       
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', AssetId = astPlan.Id, PVU_Level1__c = 'Solicitud de información y modificaciones', PVU_Level2__c = 'Control GPT', PVU_Level3__c = 'Proceso Gpt',PVU_Order__c = orden1.Id);
        insert existingCase;
        
        // Cerrar el caso existente
        //existingCase.Status = 'Cerrado';
        //update existingCase; 
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055941', 
            PVU_ReasonId__c = '261',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION', 
            PVU_Description__c = 'test',
            PVU_CaseId__c = existingCase.Id,
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	handler.assetService(gestion);
       		
       	    //Sin casos abiertos
       	    //existingCase.Status = 'Cerrado';
        	//update existingCase; 
       		//handler.assetService(gestion);
       		
        Test.stopTest();
   
    }
    
    @isTest
    static void testValidacionesIniciales_CasosExistentes() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055942');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        Case existingCase = new Case(AccountId = acc.Id, Status = 'En curso', AssetId = ast.Id,
                                     PVU_Level1__c = 'Solicitud de información y modificaciones', PVU_Level2__c = 'Control Prevención Fraude', PVU_Level3__c = 'Proceso Prevención Fraude');
        insert existingCase;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055942', 
            PVU_ReasonId__c = '38',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION', 
            PVU_Description__c = 'test',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_SinReasonId() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055943');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055943', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION', 
            PVU_Description__c = 'test',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaReactivationAndAstActive() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055944');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055944', 
            PVU_BillingAccountId__c = acc.Id,
            PVU_ReasonId__c = '2013',
            PVU_Action__c = 'REACTIVATION', 
            PVU_Description__c = 'test',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaReactivation() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055945');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055945', 
            PVU_BillingAccountId__c = acc.Id,
            PVU_ReasonId__c = '38',
            PVU_Action__c = 'REACTIVATION', 
            PVU_Description__c = 'test',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_MetadataNotFound() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055945');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055945', 
            PVU_BillingAccountId__c = acc.Id,
            PVU_ReasonId__c = '38',
            PVU_Action__c = 'REINSTALATION', 
            PVU_Description__c = 'test',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaReinstalationAstNotDeactivated() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055945');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055945', 
            PVU_BillingAccountId__c = acc.Id,
            PVU_Action__c = 'REINSTALATION', 
            PVU_ReasonId__c = '2013',
            PVU_Description__c = 'test',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaReinstalationSubestadoIncorrecto() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055946');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFJ', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055946', 
            PVU_BillingAccountId__c = acc.Id,
            PVU_Action__c = 'REINSTALATION', 
            PVU_ReasonId__c = '2013',
            PVU_Description__c = 'test',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeActivateFuncAstNotActive() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_FUNC',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeSuspensionSubCausalIncorrecto() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055948');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055948',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION',
            PVU_ReasonId__c = '165',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeDesactivationAstDesactivated() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055949');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055949',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATION',
            PVU_ReasonId__c = '184',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'GPT01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeReactivationInvalidSubCausal() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'REACTIVATION',
            PVU_ReasonId__c = '2064',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'FRA01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeReactivationandAstNotSuspended() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'REACTIVATION',
            PVU_ReasonId__c = '2064',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'FRA01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_FraudeReinstalationandAstNotDeactivated() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'REINSTALATION',
            PVU_ReasonId__c = '110',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_Motivo__c = 'FRA01',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaSameSuspensionLevel() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_SuspensionLevel__c = '1',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'SUSPENSION',
            PVU_ReasonId__c = '221',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaDeactivationAstNotSuspendedLevel2() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATION',
            PVU_ReasonId__c = '2008',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaAccionSinMarca() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055951');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055951',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_CASTIGO',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaAccionActivateCastigo() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055951');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Suspended', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055951',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_CASTIGO',
            PVU_Marca__c = 'Castigo',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	handler.assetService(gestion);
        
        	//Activar Castigo con asset Desactivado para pasar validaciones
        	ast.Status = 'Deactivated';
            update ast;
       		handler.assetService(gestion);
        	
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaAccionActivateCCVCamposObligatorios() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055952');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055952',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_CCV',
            PVU_Marca__c = 'Cartera castigada vendida',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesIniciales_CobranzaAccionActivateCCV() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055952');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Sus Revisión Protección Tecnológica', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='1');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Deactivated', vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
        
        /*
        Case existingCase = new Case(AccountId = acc.Id, Status = 'Cerrado', AssetId = ast.Id, PVU_TipoSolicitudMasivos__c = 'ACTIVATE_CCV',
                                     PVU_Level1__c = 'Facturación y pagos', PVU_Level2__c = 'Pagos', PVU_Level3__c = 'Proceso Cobranza');
        insert existingCase;
        */
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055952',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_CASTIGO',
            PVU_Marca__c = 'Cartera castigada vendida',
            PVU_NombreCompradorCartera__c = 'Test name',
            PVU_TelefonoComprador__c = '1234',
            PVU_DireccionComprador__c = 'Test direccion',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas__c gestion2 = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055952',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_CCV',
            PVU_Marca__c = 'Cartera castigada vendida',
            PVU_NombreCompradorCartera__c = 'Test name',
            PVU_TelefonoComprador__c = '1234',
            PVU_DireccionComprador__c = 'Test direccion',
            PVU_Source__c = 'COLLECTIONS', 
            PVU_ConvenioPago__c = 'Red',
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion2;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	handler.assetService(gestion);
        	handler.assetService(gestion2);
        	//casos activo
        	 Case existingCase = new Case(AccountId = acc.Id, Status = 'Cerrado', AssetId = ast.Id, PVU_TipoSolicitudMasivos__c = 'ACTIVATE_CCV',
                                     PVU_Level1__c = 'Facturación y pagos', PVU_Level2__c = 'Pagos', PVU_Level3__c = 'Proceso Cobranza');
        	insert existingCase;
        	handler.assetService(gestion);
        	handler.assetService(gestion2);
        
        	
        Test.stopTest();
    }
   
    @isTest
    static void testCreateOrder_r5() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        contact testcontact = new contact(vlocity_cmt__MiddleName__c = 'rodolfo',LastName= 'paez',AccountId =  acc.Id);
        insert testcontact;
        
        Asset testAsset = new Asset(Name ='navegala m 23',AccountId = acc.Id, contactId= testcontact.id );
        insert testAsset;
        
         // Create products
         Product2 prodRoot= new Product2 ();
            prodRoot.Name = 'Mobile Plan';
            prodRoot.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodRoot.FVU_Beneficios__c = '';
            prodRoot.Family = 'Mobile';
            prodRoot.vlocity_cmt__Type__c = 'Plan';
            prodRoot.vlocity_cmt__SubType__c = 'Postpaid';
            prodRoot.vlocity_cmt__SpecificationType__c = 'Offer';
            prodRoot.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodRoot;
                
        Product2 prodMobilePlan = new Product2 ();
            prodMobilePlan.Name = 'Mobile Plan';
            prodMobilePlan.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodMobilePlan.FVU_Beneficios__c = '';
            prodMobilePlan.Family = 'Mobile';
            prodMobilePlan.vlocity_cmt__Type__c = 'Plan';
            prodMobilePlan.vlocity_cmt__SubType__c = 'Postpaid';
            prodMobilePlan.vlocity_cmt__SpecificationType__c = 'Offer';
            prodMobilePlan.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodMobilePlan;
        
        Product2 productFunc = new Product2();
        productFunc.Family = 'CS/CD';
        productFunc.ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS';
        productFunc.Name = 'Cambio';
        insert productFunc;
        
        Product2 prodPrime = new Product2 (Name='HBO', ProductCode = 'PO_MovPosOptOTTMaxStdSA', FVU_Beneficios__c = '', vlocity_cmt__Type__c = 'Add On', vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple');
        insert prodPrime;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbePrime = new PricebookEntry();
        pbePrime.Pricebook2Id = pricebookId;
        pbePrime.Product2Id = prodPrime.Id;
        pbePrime.UnitPrice = 1;
        pbePrime.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbePrime;  
        
        PricebookEntry pbePlan = new PricebookEntry();
        pbePlan.Pricebook2Id = pricebookId;
        pbePlan.Product2Id = prodMobilePlan.Id;
        pbePlan.UnitPrice = 1;
        pbePlan.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbePlan;  
        
        PricebookEntry pbeFunc = new PricebookEntry();
        pbeFunc.Pricebook2Id = pricebookId;
        pbeFunc.Product2Id = productFunc.Id;
        pbeFunc.UnitPrice = 1;
        pbeFunc.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeFunc;  
        
        PricebookEntry pbeRoot = new PricebookEntry();
        pbeRoot.Pricebook2Id = pricebookId;
        pbeRoot.Product2Id = prodRoot.Id;
        pbeRoot.UnitPrice = 1;
        pbeRoot.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeRoot;  
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Ready To Submit';
        insert orden1;
        
       
        /*****************************/        
        OrderItem orderItemRoot = new OrderItem();
        orderItemRoot.OrderId = orden1.Id;
        orderItemRoot.Product2Id = prodRoot.Id;
        orderItemRoot.PricebookEntryId = pbeRoot.Id;
        orderItemRoot.Quantity = 1;
        orderItemRoot.UnitPrice = 10;
        orderItemRoot.vlocity_cmt__LineNumber__c = '0001';
        orderItemRoot.vlocity_cmt__Action__c = 'Add';
        orderItemRoot.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemRoot.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemRoot.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemRoot.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemRoot.vlocity_cmt__AssetReferenceId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemRoot.vlocity_cmt__ParentItemId__c = null;
        insert orderItemRoot;
        
        
        OrderItem orderItemPlan = new OrderItem();
        orderItemPlan.OrderId = orden1.Id;
        orderItemPlan.Product2Id = prodMobilePlan.Id;
        orderItemPlan.PricebookEntryId = pbePlan.Id;
        orderItemPlan.Quantity = 1;
        orderItemPlan.UnitPrice = 10;
        orderItemPlan.vlocity_cmt__LineNumber__c = '0001';
        orderItemPlan.vlocity_cmt__Action__c = 'Add';
        orderItemPlan.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemPlan.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemPlan.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemPlan.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemPlan.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemPlan.vlocity_cmt__AttributeSelectedValues__c= '{"B2C-ATTR-CG-TIPO-PLAN":"Mixto","B2C-ATTR-COD-SPLIT":1,"B2C-ATTR-PAQ-COMPATIBLES":"Bundle sin LDI","B2C-ATTR-LIMIT-NAC-PAQ":17922,"B2C-ATTR-LIMIT-NAC-SRV":28676,"B2C-ATTR-LIMIT-Roaming":35845,"B2C-ATTR-ROAMING":false,"B2C-ATTR-ROAMING-ACTIVACION":null,"B2C-ATTR-ROAMING-BARR":true,"B2C-ATTR-ROAMING-BLQ-GPT":false,"B2C-ATTR-ROAMING-DESACTIVACION":null,"B2C-ATTR-ROAMING-IND":false,"B2C-ATTR-SI-DATOS":"60","B2C-ATTR-SI-KB-ADICIONAL":null,"B2C-ATTR-SI-LDI-HISP":null,"B2C-ATTR-SI-LDI-MIN":null,"B2C-ATTR-SI-LDI-REST":null,"B2C-ATTR-SI-ROAM-CAN":false,"B2C-ATTR-SI-SMS-CLARO":null,"B2C-ATTR-SI-SMS-NAL":"Ilimitado","B2C-ATTR-SI-TETHERING":"60","B2C-ATTR-SI-VOZ-NAL":"Ilimitado","B2C-ATTR-APP-CABIFY":false,"B2C-ATTR-APP-FB":true,"B2C-ATTR-APP-INSTAGRAM":false,"B2C-ATTR-APP-MOVETIME":false,"B2C-ATTR-APP-RELEVO":false,"B2C-ATTR-APP-TAXIS-LIBRES":false,"B2C-ATTR-APP-TWITTER":true,"B2C-ATTR-APP-WA":true,"B2C-ATTR-APP-WAZE":false,"B2C-ATTR-SA-CLR-DRIVE":true,"B2C-ATTR-SA-CLR-MUSICA-GR":true,"B2C-ATTR-SA-CLR-MUSICA-PREM":false,"B2C-ATTR-SA-CLR-VIDEO":true,"B2C-ATTR-FAM-Y-AMIGOS":true,"B2C-ATTR-SERV-ID":null,"B2C-ATTR-TECH-DET":null,"B2C-ATTR-PRC-DET":null}';
        insert orderItemPlan;
        
        
        OrderItem orderItemFunc = new OrderItem();
        orderItemFunc.OrderId = orden1.Id;
        orderItemFunc.Product2Id = productFunc.Id;
        orderItemFunc.PricebookEntryId = pbeFunc.Id;
        orderItemFunc.Quantity = 1;
        orderItemFunc.UnitPrice = 10;
        orderItemFunc.vlocity_cmt__LineNumber__c = '0001';
        orderItemFunc.vlocity_cmt__Action__c = 'Add';
        orderItemFunc.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemFunc.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemFunc.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemFunc.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemFunc.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}';
        orderItemFunc.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        insert orderItemFunc;   
        
        OrderItem orderItemPrime = new OrderItem();
        orderItemPrime.OrderId = orden1.Id;
        orderItemPrime.Product2Id = prodPrime.Id;
        orderItemPrime.PricebookEntryId = pbePrime.Id;
        orderItemPrime.Quantity = 1;
        orderItemPrime.UnitPrice = 10;
        orderItemPrime.vlocity_cmt__LineNumber__c = '0001';
        orderItemPrime.vlocity_cmt__Action__c = 'Add';
        orderItemPrime.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemPrime.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemPrime.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemPrime.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemPrime.vlocity_cmt__AssetReferenceId__c = '';
        orderItemPrime.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        insert orderItemPrime;
        
        vlocity_cmt__Promotion__c promotion = new vlocity_cmt__Promotion__c();
        promotion.vlocity_cmt__Code__c = 'PO_DesMovPos50x1a6m';
        promotion.Name = 'Descuento 50% Max 6 Meses';
        promotion.CAT_Type__c = 'Estandar';
        promotion.CAT_PromotionClass__c = 'Terceros';
        insert promotion;
        
        vlocity_cmt__PromotionItem__c promotionItem = new vlocity_cmt__PromotionItem__c();
        promotionItem.vlocity_cmt__PromotionId__c = promotion.Id;
        promotionItem.vlocity_cmt__ProductId__c = prodPrime.Id;
        insert promotionItem;
        
        vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion = new vlocity_cmt__OrderAppliedPromotion__c();
        orderAppliedPromotion.vlocity_cmt__PromotionId__c = promotion.Id;
        orderAppliedPromotion.vlocity_cmt__OrderId__c = orden1.Id;
        insert orderAppliedPromotion;
        
        vlocity_cmt__OrderAppliedPromotionItem__c orderAppliedPromotionItem = new vlocity_cmt__OrderAppliedPromotionItem__c();
        orderAppliedPromotionItem.vlocity_cmt__OrderAppliedPromotionId__c = orderAppliedPromotion.Id;
        orderAppliedPromotionItem.vlocity_cmt__OrderItemId__c = orderItemPrime.Id;
        orderAppliedPromotionItem.vlocity_cmt__AppliedAction__c = 'Apply';
        insert orderAppliedPromotionItem;
        
        PVU_Gestiones_Masivas__c gestionActivateFunc = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_FUNC',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestionActivateFunc;
        
        PVU_Gestiones_Masivas__c gestionDEACTIVATE_FUNC = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_FUNC',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestionDEACTIVATE_FUNC;
        
        PVU_Gestiones_Masivas__c gestionDEACTIVATE_SA = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_SA',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionDEACTIVATE_SA;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_SA = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_SA',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_SA;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_ROAMING = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_ROAMING',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_ROAMING;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_DEACTIVATE_ROAMING = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_ROAMING',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_DEACTIVATE_ROAMING;
        
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionActivateFunc);
        handler.setAssetToOrderMtd(gm);
        gm.Orden = orden1;
        gm.Asset = testAsset;
        handler.createOrder(gm);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm2 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionDEACTIVATE_FUNC);
        handler.setAssetToOrderMtd(gm2);
        gm2.Orden = orden1;
        gm2.Asset = testAsset;
        handler.createOrder(gm2);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm3 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionDEACTIVATE_SA);
        handler.setAssetToOrderMtd(gm3);
        gm3.Orden = orden1;
        gm3.Asset = testAsset;
        handler.createOrder(gm3);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm4 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_SA);
        handler.setAssetToOrderMtd(gm4);
        gm4.Orden = orden1;
        gm4.Asset = testAsset;
        handler.createOrder(gm4);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm5 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_ROAMING);
        handler.setAssetToOrderMtd(gm5);
        gm5.Orden = orden1;
        gm5.Asset = testAsset;
        handler.createOrder(gm5);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm6 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_DEACTIVATE_ROAMING);
        handler.setAssetToOrderMtd(gm6);
        gm6.Orden = orden1;
        gm6.Asset = testAsset;
        handler.createOrder(gm6);
        
        Test.stopTest();
    }
   
    @isTest
    static void testCreateOrder_r5_error() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055950');
        insert acc;
        
        contact testcontact = new contact(vlocity_cmt__MiddleName__c = 'rodolfo',LastName= 'paez',AccountId =  acc.Id);
        insert testcontact;
        
        Asset testAsset = new Asset(Name ='navegala m 23',AccountId = acc.Id, contactId= testcontact.id );
        insert testAsset;
        
         // Create products
         Product2 prodRoot= new Product2 ();
            prodRoot.Name = 'Mobile Plan';
            prodRoot.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodRoot.FVU_Beneficios__c = '';
            prodRoot.Family = 'Mobile';
            prodRoot.vlocity_cmt__Type__c = 'Plan';
            prodRoot.vlocity_cmt__SubType__c = 'Postpaid';
            prodRoot.vlocity_cmt__SpecificationType__c = 'Offer';
            prodRoot.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodRoot;
                
        Product2 prodMobilePlan = new Product2 ();
            prodMobilePlan.Name = 'Mobile Plan';
            prodMobilePlan.ProductCode = 'B2C-MOV-PLAN-CODE';
            prodMobilePlan.FVU_Beneficios__c = '';
            prodMobilePlan.Family = 'Mobile';
            prodMobilePlan.vlocity_cmt__Type__c = 'Plan';
            prodMobilePlan.vlocity_cmt__SubType__c = 'Postpaid';
            prodMobilePlan.vlocity_cmt__SpecificationType__c = 'Offer';
            prodMobilePlan.vlocity_cmt__SpecificationSubType__c = 'Bundle';
        insert prodMobilePlan;
        
        Product2 productFunc = new Product2();
        productFunc.Family = 'CS/CD';
        productFunc.ProductCode = 'B2C-MOB-POST-FUNC-y-BLOQ-PS';
        productFunc.Name = 'Cambio';
        insert productFunc;
        
        Product2 prodPrime = new Product2 (Name='HBO', ProductCode = 'PO_MovPosOptOTTMaxStdSA', FVU_Beneficios__c = '', vlocity_cmt__Type__c = 'Add On', vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple');
        insert prodPrime;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbePrime = new PricebookEntry();
        pbePrime.Pricebook2Id = pricebookId;
        pbePrime.Product2Id = prodPrime.Id;
        pbePrime.UnitPrice = 1;
        pbePrime.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbePrime;  
        
        PricebookEntry pbePlan = new PricebookEntry();
        pbePlan.Pricebook2Id = pricebookId;
        pbePlan.Product2Id = prodMobilePlan.Id;
        pbePlan.UnitPrice = 1;
        pbePlan.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbePlan;  
        
        PricebookEntry pbeFunc = new PricebookEntry();
        pbeFunc.Pricebook2Id = pricebookId;
        pbeFunc.Product2Id = productFunc.Id;
        pbeFunc.UnitPrice = 1;
        pbeFunc.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeFunc;  
        
        PricebookEntry pbeRoot = new PricebookEntry();
        pbeRoot.Pricebook2Id = pricebookId;
        pbeRoot.Product2Id = prodRoot.Id;
        pbeRoot.UnitPrice = 1;
        pbeRoot.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbeRoot;  
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Ready To Submit';
        insert orden1;
        
       
        /*****************************/        
        OrderItem orderItemRoot = new OrderItem();
        orderItemRoot.OrderId = orden1.Id;
        orderItemRoot.Product2Id = prodRoot.Id;
        orderItemRoot.PricebookEntryId = pbeRoot.Id;
        orderItemRoot.Quantity = 1;
        orderItemRoot.UnitPrice = 10;
        orderItemRoot.vlocity_cmt__LineNumber__c = '0001';
        orderItemRoot.vlocity_cmt__Action__c = 'Add';
        orderItemRoot.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemRoot.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemRoot.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemRoot.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemRoot.vlocity_cmt__AssetReferenceId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemRoot.vlocity_cmt__ParentItemId__c = null;
        insert orderItemRoot;
        
        
        OrderItem orderItemPlan = new OrderItem();
        orderItemPlan.OrderId = orden1.Id;
        orderItemPlan.Product2Id = prodMobilePlan.Id;
        orderItemPlan.PricebookEntryId = pbePlan.Id;
        orderItemPlan.Quantity = 1;
        orderItemPlan.UnitPrice = 10;
        orderItemPlan.vlocity_cmt__LineNumber__c = '0001';
        orderItemPlan.vlocity_cmt__Action__c = 'Add';
        orderItemPlan.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemPlan.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemPlan.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemPlan.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemPlan.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        orderItemPlan.vlocity_cmt__AttributeSelectedValues__c= '{"B2C-ATTR-CG-TIPO-PLAN":"Mixto","B2C-ATTR-COD-SPLIT":1,"B2C-ATTR-PAQ-COMPATIBLES":"Bundle sin LDI","B2C-ATTR-LIMIT-NAC-PAQ":17922,"B2C-ATTR-LIMIT-NAC-SRV":28676,"B2C-ATTR-LIMIT-Roaming":35845,"B2C-ATTR-ROAMING":false,"B2C-ATTR-ROAMING-ACTIVACION":null,"B2C-ATTR-ROAMING-BARR":true,"B2C-ATTR-ROAMING-BLQ-GPT":false,"B2C-ATTR-ROAMING-DESACTIVACION":null,"B2C-ATTR-ROAMING-IND":false,"B2C-ATTR-SI-DATOS":"60","B2C-ATTR-SI-KB-ADICIONAL":null,"B2C-ATTR-SI-LDI-HISP":null,"B2C-ATTR-SI-LDI-MIN":null,"B2C-ATTR-SI-LDI-REST":null,"B2C-ATTR-SI-ROAM-CAN":false,"B2C-ATTR-SI-SMS-CLARO":null,"B2C-ATTR-SI-SMS-NAL":"Ilimitado","B2C-ATTR-SI-TETHERING":"60","B2C-ATTR-SI-VOZ-NAL":"Ilimitado","B2C-ATTR-APP-CABIFY":false,"B2C-ATTR-APP-FB":true,"B2C-ATTR-APP-INSTAGRAM":false,"B2C-ATTR-APP-MOVETIME":false,"B2C-ATTR-APP-RELEVO":false,"B2C-ATTR-APP-TAXIS-LIBRES":false,"B2C-ATTR-APP-TWITTER":true,"B2C-ATTR-APP-WA":true,"B2C-ATTR-APP-WAZE":false,"B2C-ATTR-SA-CLR-DRIVE":true,"B2C-ATTR-SA-CLR-MUSICA-GR":true,"B2C-ATTR-SA-CLR-MUSICA-PREM":false,"B2C-ATTR-SA-CLR-VIDEO":true,"B2C-ATTR-FAM-Y-AMIGOS":true,"B2C-ATTR-SERV-ID":null,"B2C-ATTR-TECH-DET":null,"B2C-ATTR-PRC-DET":null}';
        insert orderItemPlan;
        
        
        OrderItem orderItemFunc = new OrderItem();
        orderItemFunc.OrderId = orden1.Id;
        orderItemFunc.Product2Id = productFunc.Id;
        orderItemFunc.PricebookEntryId = pbeFunc.Id;
        orderItemFunc.Quantity = 1;
        orderItemFunc.UnitPrice = 10;
        orderItemFunc.vlocity_cmt__LineNumber__c = '0001';
        orderItemFunc.vlocity_cmt__Action__c = 'Add';
        orderItemFunc.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemFunc.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemFunc.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemFunc.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemFunc.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}';
        orderItemFunc.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        insert orderItemFunc;   
        
        OrderItem orderItemPrime = new OrderItem();
        orderItemPrime.OrderId = orden1.Id;
        orderItemPrime.Product2Id = prodPrime.Id;
        orderItemPrime.PricebookEntryId = pbePrime.Id;
        orderItemPrime.Quantity = 1;
        orderItemPrime.UnitPrice = 10;
        orderItemPrime.vlocity_cmt__LineNumber__c = '0001';
        orderItemPrime.vlocity_cmt__Action__c = 'Add';
        orderItemPrime.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItemPrime.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItemPrime.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItemPrime.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItemPrime.vlocity_cmt__AssetReferenceId__c = '';
        orderItemPrime.vlocity_cmt__ParentItemId__c = 'd5fc6f0e-d4de-7b1c-21cc-f7f3ecf260dd';
        insert orderItemPrime;
        
        /*vlocity_cmt__Promotion__c promotion = new vlocity_cmt__Promotion__c();
        promotion.vlocity_cmt__Code__c = 'PO_DesMovPos50x1a6m';
        promotion.Name = 'Descuento 50% Max 6 Meses';
        promotion.CAT_Type__c = 'Estandar';
        promotion.CAT_PromotionClass__c = 'Terceros';
        insert promotion;
        
        vlocity_cmt__PromotionItem__c promotionItem = new vlocity_cmt__PromotionItem__c();
        promotionItem.vlocity_cmt__PromotionId__c = promotion.Id;
        promotionItem.vlocity_cmt__ProductId__c = prodPrime.Id;
        insert promotionItem;
        
        vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion = new vlocity_cmt__OrderAppliedPromotion__c();
        orderAppliedPromotion.vlocity_cmt__PromotionId__c = promotion.Id;
        orderAppliedPromotion.vlocity_cmt__OrderId__c = orden1.Id;
        insert orderAppliedPromotion;
        
        vlocity_cmt__OrderAppliedPromotionItem__c orderAppliedPromotionItem = new vlocity_cmt__OrderAppliedPromotionItem__c();
        orderAppliedPromotionItem.vlocity_cmt__OrderAppliedPromotionId__c = orderAppliedPromotion.Id;
        orderAppliedPromotionItem.vlocity_cmt__OrderItemId__c = orderItemPrime.Id;
        orderAppliedPromotionItem.vlocity_cmt__AppliedAction__c = 'Apply';
        insert orderAppliedPromotionItem;*/
        
        PVU_Gestiones_Masivas__c gestionActivateFunc = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_FUNC',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestionActivateFunc;
        
        PVU_Gestiones_Masivas__c gestionDEACTIVATE_FUNC = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_FUNC',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'B2C-ATTR-FYB-BLQ-LDI'
        );
        insert gestionDEACTIVATE_FUNC;
        
        PVU_Gestiones_Masivas__c gestionDEACTIVATE_SA = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_SA',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionDEACTIVATE_SA;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_SA = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_SA',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_SA;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_ROAMING = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_ROAMING',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_ROAMING;
        
        PVU_Gestiones_Masivas__c gestionACTIVATE_DEACTIVATE_ROAMING = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055950',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_ROAMING',
            //PVU_ReasonId__c = '',
            PVU_Source__c = 'FRAUDE_GPT', 
            PVU_JobIdentifier__c = '1111',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTMaxStdSA'
        );
        insert gestionACTIVATE_DEACTIVATE_ROAMING;
        
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionActivateFunc);
        handler.setAssetToOrderMtd(gm);
        gm.Orden = orden1;
        gm.Asset = testAsset;
        handler.createOrder(gm);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm2 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionDEACTIVATE_FUNC);
        handler.setAssetToOrderMtd(gm2);
        gm2.Orden = orden1;
        gm2.Asset = testAsset;
        handler.createOrder(gm2);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm3 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionDEACTIVATE_SA);
        handler.setAssetToOrderMtd(gm3);
        gm3.Orden = orden1;
        gm3.Asset = testAsset;
        handler.createOrder(gm3);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm4 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_SA);
        handler.setAssetToOrderMtd(gm4);
        gm4.Orden = orden1;
        gm4.Asset = testAsset;
        handler.createOrder(gm4);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm5 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_ROAMING);
        handler.setAssetToOrderMtd(gm5);
        gm5.Orden = orden1;
        gm5.Asset = testAsset;
        handler.createOrder(gm5);
        
        PVU_Gestiones_Masivas_Handler.WGestionMasiva gm6 = new PVU_Gestiones_Masivas_Handler.WGestionMasiva(gestionACTIVATE_DEACTIVATE_ROAMING);
        handler.setAssetToOrderMtd(gm6);
        gm6.Orden = orden1;
        gm6.Asset = testAsset;
        handler.createOrder(gm6);
        
        Test.stopTest();
    }
 
    @isTest
    static void testValidacionesInicialesActivateTodoClaro() {
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
            CAT_PromotionClass__c = 'Apps sin consumos de datos'
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
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_TC', 
            PVU_Source__c = 'TODO_CLARO',
            PVU_MSISDN__c = '5588332233',
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testValidacionesInicialesDeactivateTodoClaro() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_TC', 
            PVU_Source__c = 'TODO_CLARO',
            PVU_MSISDN__c = '5588332233',
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateCaseActivateTodoClaro() {
        Account acc = new Account(Name = 'Test Account1', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '222', FVU_AccountExternalID__c = '93000000055939');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Suspended', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000001', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset1', status = 'Active',vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id);
        insert ast;
        
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055939', 
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'ACTIVATE_TC', 
            PVU_Source__c = 'TODO_CLARO',
            PVU_MSISDN__c = '5588332233',
            PVU_JobIdentifier__c = '1111'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        handler.assetService(gestion);
        Test.stopTest();
    }
 
    @isTest
    static void testCaseAndOrderCreatedForDeactiveNetflix40() {
        Account acc = new Account(Name = 'Test Account40', FVU_DocumentType__c = 'CC', FVU_DocumentNumber__c = '40', FVU_AccountExternalID__c = '93000000055932');
        insert acc;
        
        vlocity_cmt__Subscription__c testSubscription = new vlocity_cmt__Subscription__c(vlocity_cmt__Status__c = 'Active', OM_SubStatus__c = 'Robo / Perdida', vlocity_cmt__SubscriptionNumber__c = '0000040', OM_SusByCollectionsFlag__c ='2');
        insert testSubscription;
        
        Product2 prod1 = new Product2(Name = 'NetflixSA', ProductCode = 'PO_MovPosOptOTTNeflixBasicoSA', vlocity_cmt__Type__c = 'Plan');
        insert prod1;
        
        Asset ast = new Asset(Name = 'Test Asset40', Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prod1.Id,vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-FYB-BAR-ID-REST":false,"B2C-ATTR-FYB-BLQ-CONT":false,"B2C-ATTR-FYB-BLQ-GPRS":false,"B2C-ATTR-FYB-BLQ-LDI":false,"B2C-ATTR-FYB-BLQ-LDI-INFRA":false,"B2C-ATTR-FYB-BLQ-LDI-MULTI":false,"B2C-ATTR-FYB-BLQ-LLAM-ENT":false,"B2C-ATTR-FYB-BLQ-LLAM-PERD":false,"B2C-ATTR-FYB-BLQ-LLAM-SAL":false,"B2C-ATTR-FYB-BLQ-LLAM-XCOB":false,"B2C-ATTR-FYB-BLQ-MARCA-YA":false,"B2C-ATTR-FYB-BLQ-MMS":false,"B2C-ATTR-FYB-BLQ-NUM-01800":false,"B2C-ATTR-FYB-BLQ-NUM-CORTOS":false,"B2C-ATTR-FYB-BLQ-PASA-SALDO":false,"B2C-ATTR-FYB-BLQ-SMS-ENT":false,"B2C-ATTR-FYB-BLQ-SMS-SAL":false,"B2C-ATTR-FYB-BLQ-VOLTE":true,"B2C-ATTR-FYB-BLQ-VOWIFI":true,"B2C-ATTR-FYB-BUZ-VOZ":true,"B2C-ATTR-FYB-CONF-GSM":true,"B2C-ATTR-FYB-CORR-VOZ-VISUAL":false,"B2C-ATTR-FYB-ID-LLAM":true,"B2C-ATTR-FYB-LLAM-ESP":true,"B2C-ATTR-FYB-NOTI-DIA":false,"B2C-ATTR-FYB-REST-DUR-LLAM":true,"B2C-ATTR-FYB-SHORT-MAIL":true,"B2C-ATTR-FYB-TRANS-LLAM":true,"B2C-ATTR-FYB-VID-LLAM":true,"B2C-ATTR-FYB-WEB-MESS":true}');
        insert ast;
      
        PVU_Gestiones_Masivas__c gestion = new PVU_Gestiones_Masivas__c( 
            PVU_CustNum__c = '93000000055932',
            PVU_BillingAccountId__c = acc.Id, 
            PVU_Action__c = 'DEACTIVATE_NETFLIXSA40',
            PVU_Source__c = 'NETFLIX40', 
            PVU_JobIdentifier__c = '111',
            PVU_Motivo__c = '',
            PVU_MSISDN__c = '5544332233',
            PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTNeflixBasicoSA'
        );
        insert gestion;
        
        PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
        Test.startTest();
        	//Desactivar sin producto
        	handler.assetService(gestion);
        
        	//desactivar SA con producto ya agregado
            Product2 prodPrime = new Product2 (Name='NetflixSA', ProductCode = 'PO_MovPosOptOTTNeflixBasicoSA', FVU_Beneficios__c = '', vlocity_cmt__Type__c = 'Add On', vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple');
            insert prodPrime;
        
            Asset astPrime = new Asset(Name = 'NetflixSA', Status='Active' ,vlocity_cmt__BillingAccountId__c = acc.Id, vlocity_cmt__SubscriptionId__c = testSubscription.Id, AccountId = acc.Id, Product2Id = prodPrime.Id, vlocity_cmt__ReliesOnItemId__c = '12344340');
            insert astPrime;
        
        	PVU_Gestiones_Masivas__c gestion3 = new PVU_Gestiones_Masivas__c( 
                PVU_CustNum__c = '93000000055932',
                PVU_BillingAccountId__c = acc.Id, 
                PVU_Action__c = 'DEACTIVATE_NETFLIXSA40',
                PVU_Source__c = 'NETFLIX40', 
                PVU_JobIdentifier__c = '111',
                PVU_Motivo__c = '',
                PVU_MSISDN__c = '5544332233',
                PVU_FeaturesOrServices__c = 'PO_MovPosOptOTTNeflixBasicoSA'
            );
            insert gestion3;
        	handler.assetService(gestion3);
        
        Test.stopTest();
        
    }
}