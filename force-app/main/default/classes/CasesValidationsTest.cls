/**
* @description       : 
* @author            : SALESFORCE
* @group             : 
* @last modified on  : 09-20-2024
* @last modified by  : SALESFORCE
* Modifications Log
* Ver   Date         Author       Modification
* 1.0   03-07-2024   SALESFORCE   Initial Version
**/
@isTest
public Class CasesValidationsTest{
    @TestSetup
    private static void dataSetup(){
        List<Asset> assets = new List<Asset>();
        List<Order> ordenes = new List<Order>();
        List<Case> casos = new List<Case>();
        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        RecordType rtPQR = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPQR'][0];
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
        insert prod1;

        Product2 prod2 = new Product2 (Name='Product 2', ProductCode = 'Terminal2', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = 'Descripción Larga',Short_Description__c = 'Descripción Corta');
        insert prod2;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbe1;                            
        
        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert acc;
        /*******************************/
        
        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset1';
        ast.AccountId = acc.Id;
        assets.add(ast);
        
        Asset ast2 = new Asset();
        ast2.Name = 'Test Asset';
        ast2.AccountId = acc.Id;
        assets.add(ast2);

        Asset ast3 = new Asset();
        ast3.Name = 'Test Asset';
        ast3.AccountId = acc.Id;
        ast3.Status = 'Active';
        ast3.Product2Id = prod2.Id;
        assets.add(ast3);
        insert assets;
        /***************************/
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Análisis de Necesidad';
        orden1.FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.FVU_BusinessChannel__c='CAV';
        orden1.FVU_PaymentMethod__c='Contado';
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
        
        Order orden5 = new Order();
        orden5.AccountId = acc.Id;
        orden5.Status = 'Análisis de Necesidad';
        orden5.FVU_PaymentStatus__c = 'PP';
        orden5.EffectiveDate = System.Today();
        orden5.Pricebook2Id = pricebookId;
        ordenes.add(orden5);
        //  system.debug('recordtype>>>>'+orden1.RecordTypeId);
        insert ordenes;
        /*****************************/
        
        /*****Creacion de casos bloqueantes****/
        Case caso1 = new Case();
        caso1.PVU_Level1__c = 'Facturación y pagos';
        caso1.PVU_Level2__c = 'Pagos';
        caso1.PVU_Level3__c = 'Pago no abonado'; 
        caso1.status = 'Abierto';
        caso1.PVU_NR__c = '00000001';
        caso1.AccountId = acc.Id;
        caso1.AssetId = ast.Id;
        caso1.RecordTypeId = rt.Id;
        caso1.OwnerId  = UserInfo.getUserId();
        casos.add(caso1);
        
        Case caso2 = new Case();
        caso2.PVU_Level1__c = 'Facturación y pagos';
        caso2.PVU_Level2__c = 'Pagos';
        caso2.PVU_Level3__c = 'Pago no abonado'; 
        caso2.status = 'En curso';
        caso2.PVU_NR__c = '00000002';
        caso2.AccountId = acc.Id;
        caso2.AssetId = ast.Id;
        caso2.RecordTypeId = rt.Id;
        caso2.OwnerId  = UserInfo.getUserId();
        casos.add(caso2);
        
        Case caso3 = new Case();
        caso3.PVU_Level1__c = 'Facturación y pagos';
        caso3.PVU_Level2__c = 'Pagos';
        caso3.PVU_Level3__c = 'Pago no abonado'; 
        caso3.status = 'Cerrado';
        caso3.pvu_sub_estado__c = 'Pendiente';
        caso3.PVU_NR__c = '00000003';
        caso3.AccountId = acc.Id;
        caso3.AssetId = ast.Id;
        caso3.PVU_Order__c = ordenes[0].Id;
        caso3.RecordTypeId = rt.Id;
        caso3.OwnerId  = UserInfo.getUserId();
        casos.add(caso3);
        
        //casos 6 y 7 responden a funcionalidad pagos no abonados
        Case caso6 = new Case();
        caso6.Status = 'En curso';
        caso6.PVU_Level1__c = 'Facturación y pagos';
        caso6.PVU_Level2__c = 'Pagos';
        caso6.PVU_Level3__c = 'Pago no abonado';
        caso6.RecordTypeId = rt.Id;
        caso6.AccountId = acc.Id;
        caso6.PVU_Order__c = ordenes[2].Id;
        caso6.OwnerId  = UserInfo.getUserId();
        casos.add(caso6);
        
        Case caso7 = new Case();
        caso7.Status = 'Abierto';
        caso7.PVU_Level1__c = 'Facturación y pagos';
        caso7.PVU_Level2__c = 'Pagos';
        caso7.PVU_Level3__c = 'Pago no abonado';
        caso7.RecordTypeId = rt.Id;
        caso7.AccountId = acc.Id;
        caso7.OwnerId  = UserInfo.getUserId();
        //caso7.PVU_Order__c = ordenes[3].Id;
        casos.add(caso7);
        
        /**************************************/
        
        
        /****Creacion de casos candidatos*****/
        Case caso4 = new Case();
        caso4.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso4.PVU_Level2__c = 'Falla del equipo';
        caso4.PVU_Level3__c = 'Falla técnica en la entrega (Muerto en Caja-DOA)';
        caso4.status = 'Cerrado';
        caso4.pvu_sub_estado__c = 'Aplica Devolucion de dinero';
        caso4.PVU_NoNotaCredito__c = Decimal.valueOf('111111');
        caso4.PVU_ValorDevolucion__c = Decimal.valueOf('40');
        caso4.AccountId = acc.Id;
        caso4.AssetId = ast.Id;
        caso4.RecordTypeId = rt.Id;
        caso4.OwnerId  = UserInfo.getUserId();
        casos.add(caso4);
        
        Case caso5 = new Case();
        caso5.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso5.PVU_Level2__c = 'Falla del equipo';
        caso5.PVU_Level3__c = 'Falla técnica en la entrega (Muerto en Caja-DOA)';
        caso5.status = 'Cerrado';
        caso5.pvu_sub_estado__c = 'Aplica Devolucion de dinero';
        caso5.PVU_NoNotaCredito__c = Decimal.valueOf('888888');
        caso5.PVU_ValorDevolucion__c = Decimal.valueOf('340');
        caso5.AccountId = acc.Id;
        caso5.AssetId = ast2.Id;
        caso5.RecordTypeId = rt.Id;
        caso5.OwnerId  = UserInfo.getUserId();
        casos.add(caso5);
        
        //casos para ReporteImei
        Case caso8 = new Case();
        caso8.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso8.PVU_Level2__c = 'Falla del equipo';
        caso8.PVU_Level3__c = 'Reporte de IMEI';
        caso8.status = 'En curso';
        caso8.PVU_ImeiReporte1__c='100000000000002';
        caso8.AccountId = acc.Id;
        caso8.AssetId = ast.Id;
        caso8.RecordTypeId = rt.Id;
        caso8.OwnerId  = UserInfo.getUserId();
        casos.add(caso8);
        
        Case caso9 = new Case();
        caso9.PVU_Level1__c = 'Ventas';
        caso9.PVU_Level2__c = 'Falla del equipo';
        caso9.PVU_Level3__c = 'Reporte de IMEI';
        caso9.status = 'Abierto';
        caso9.PVU_ImeiReporte1__c='100000000000002';
        caso9.AccountId = acc.Id;
        caso9.AssetId = ast.Id;
        caso9.RecordTypeId = rt.Id;
        caso9.OwnerId  = UserInfo.getUserId();
        casos.add(caso9);
        
        // Casos para liberacionImei
        Case caso10 = new Case();
        caso10.PVU_Level1__c = 'Ventas';
        caso10.PVU_Level2__c = 'Falla del equipo';
        caso10.PVU_Level3__c = 'Liberación IMEI';
        caso10.status = 'En curso';
        caso10.PVU_ImeiReporte1__c='100000000000003';
        caso10.PVU_MINReporteImei__c='12345';
        caso10.AccountId = acc.Id;
        caso10.AssetId = ast.Id;
        caso10.RecordTypeId = rt.Id;
        caso10.OwnerId  = UserInfo.getUserId();
        casos.add(caso10);
        
        Case caso11 = new Case();
        caso11.PVU_Level1__c = 'Ventas';
        caso11.PVU_Level2__c = 'Falla del equipo';
        caso11.PVU_Level3__c = 'Reporte de IMEI';
        caso11.status = 'Cerrado';
        caso11.PVU_ImeiReporte1__c='100000000000003';
        caso11.PVU_MINReporteImei__c='12346';
        caso11.PVU_Tipo_de_reporte__c = 'Robo';
        caso11.PVU_Sub_Estado__c ='Reporte realizado';
        caso11.PVU_Codigo_de_Cierre__c ='Se realiza reporte';
        caso11.PVU_Motivo_del_reporte__c = 'Robo';
        caso11.AccountId = acc.Id;
        caso11.AssetId = ast.Id;
        caso11.RecordTypeId = rt.Id;
        caso11.OwnerId  = UserInfo.getUserId();
        //caso11.ClosedDate = Datetime.valueOf('2024-02-22T21:31:51.000+0000');
        casos.add(caso11);
        
        //caso para cambio de titularidad
        Case caso12 = new Case();
        caso12.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso12.PVU_Level2__c = 'Gestión de IMEI';
        caso12.PVU_Level3__c = 'Cambio de titularidad de IMEI';
        caso12.status = 'En curso';
        caso12.PVU_ImeiReporte1__c='100000000000002';
        caso12.AccountId = acc.Id;
        caso12.AssetId = ast.Id;
        caso12.RecordTypeId = rt.Id;
        caso12.OwnerId  = UserInfo.getUserId();
        casos.add(caso12);
        
        
        
        //caso para cambio de titularidad
        /*Case caso13 = new Case();
        caso12.PVU_Level1__c = 'Facturación y pagos';
        caso12.PVU_Level2__c = 'Ajustes';
        caso12.PVU_Level3__c = 'Cobro Errado';
        caso12.status = 'En curso';
        caso12.PVU_ImeiReporte1__c='100000000000002';
        caso12.AccountId = acc.Id;
        caso12.AssetId = ast.Id;
        caso12.RecordTypeId = rt.Id;
        casos.add(caso13);*/
        
        //insert casos;

        //Caso para Cesion Imei
        Case caso13 = new Case();
        caso13.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso13.PVU_Level2__c = 'Gestión de IMEI';
        caso13.PVU_Level3__c = 'Cesión de IMEI';
        caso13.status = 'En curso';
        caso13.PVU_ImeiReporte1__c='1000000000001234';
        caso13.AccountId = acc.Id;
        caso13.AssetId = ast.Id;
        caso13.RecordTypeId = rt.Id;
        caso13.OwnerId  = UserInfo.getUserId();
        casos.add(caso13);
        
        //Caso para Reinstalación
        Case caso14 = new Case();
        caso14.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso14.PVU_Level2__c = 'Reinstalación';
        caso14.PVU_Level3__c = 'Reinstalación Servicio Móvil';
        caso14.status = 'En curso';
        caso14.AccountId = acc.Id;
        caso14.AssetId = ast.Id;
        caso14.RecordTypeId = rt.Id;
        caso14.OwnerId  = UserInfo.getUserId();
        casos.add(caso14);
        
        //Caso para cambio Plan AccInmediatas
        Case caso15 = new Case();
        caso15.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso15.PVU_Level2__c = 'Cambio de plan';
        caso15.PVU_Level3__c = 'Cambio de plan móvil';
        caso15.status = 'Cerrado';
        caso15.PVU_Codigo_de_Cierre__c = 'Falla de ejecución';
        caso15.PVU_Order__c = orden5.Id;
        caso15.AccountId = acc.Id;
        caso15.AssetId = ast.Id;
        caso15.RecordTypeId = rt.Id;
        caso15.OwnerId  = UserInfo.getUserId();
        casos.add(caso15);
        
        //Caso para Cesión de contrato	
        Case caso16 = new Case();
        caso16.PVU_Level1__c = 'Solicitud de información y modificaciones';
        caso16.PVU_Level2__c = 'Cesión de contrato';
        caso16.PVU_Level3__c = 'Cesión de contrato';
        caso16.status = 'En curso';
        caso16.AccountId = acc.Id;
        caso16.AssetId = ast.Id;
        caso16.RecordTypeId = rt.Id;
        caso16.OwnerId  = UserInfo.getUserId();
        casos.add(caso16);
        
        //Caso para Cesión de contrato	
        Case caso17 = new Case();
        caso17.PVU_Level1__c = 'Facturación y pagos';
        caso17.PVU_Level2__c = 'Pagos';
        caso17.PVU_Level3__c = 'Reverso de pago';
        caso17.status = 'Cerrado';
        caso17.PVU_Codigo_de_Cierre__c='Se realiza devolución';
        caso17.AccountId = acc.Id;
        caso17.PVU_Order__c = ordenes[0].Id;
        caso17.RecordTypeId = rt.Id;
        caso17.OwnerId  = UserInfo.getUserId();
        casos.add(caso17);
        
        //Caso para devolucion de dinero PQR	
        Case caso18 = new Case();
        caso18.PVU_Level1__c = 'Facturación y pagos';
        caso18.PVU_Level2__c = 'Pagos';
        caso18.PVU_Level3__c = 'Reverso de pago';
        caso18.status = 'Cerrado';
        caso18.PVU_Codigo_de_Cierre__c='Se realiza devolución';
        caso18.AccountId = acc.Id;
        caso18.PVU_CUN__c ='1234569789';
        caso18.PVU_NR__c ='987654321';
        caso18.RecordTypeId = rt.Id;
        caso18.OwnerId  = UserInfo.getUserId();
        casos.add(caso18);
        
        //Caso para devolucion de dinero / soporte y falla
        Case caso19 = new Case();
        caso19.PVU_Level1__c = 'Facturación y pagos';
        caso19.PVU_Level2__c = 'Pagos';
        caso19.PVU_Level3__c = 'Reverso de pago';
        caso19.status = 'Cerrado';
        caso19.PVU_Codigo_de_Cierre__c='Se realiza devolución';
        caso19.AccountId = acc.Id;
        caso19.PVU_Origen_DevDinero__c='Asset';
        caso19.AssetId =ast.Id;
        caso19.RecordTypeId = rt.Id;
        caso19.OwnerId  = UserInfo.getUserId();
        casos.add(caso19);
        
        
         //Caso para devolucion de dinero / soporte y falla Equipos OPEN
        Case caso22 = new Case();
        caso22.PVU_Level1__c = 'Soporte, fallas de servicio y equipos';
        caso22.status = 'Abierto';
        caso22.AccountId = acc.Id;
        caso22.AssetId =ast.Id;
        caso22.RecordTypeId = rt.Id;
        casos.add(caso22);
        
        //Caso para devolucion de dinero PQR	
        Case caso20 = new Case();
        caso20.PVU_Level1__c = 'Facturación y pagos';
        caso20.PVU_Level2__c = 'Devolución de dinero';
        caso20.PVU_Level3__c = 'Devolución dinero en efectivo';
        caso20.status = 'Cerrado';
        caso20.PVU_Codigo_de_Cierre__c='Se realiza devolución';
        caso20.AccountId = acc.Id;
        caso20.PVU_CUN__c ='20250519';
        caso20.PVU_NR__c ='20250519';
        caso20.RecordTypeId = rtPQR.Id;
        caso20.OwnerId  = UserInfo.getUserId();
        casos.add(caso20);

         //Caso para Eliminación de financiamiento
         Case caso21 = new Case();
         caso21.PVU_Level1__c = 'Facturación y pagos';
         caso21.PVU_Level2__c = 'Financiación';
         caso21.PVU_Level3__c = 'Eliminación de financiamiento';
         caso21.status = 'Cerrado';
         caso21.PVU_Codigo_de_Cierre__c='Se realiza eliminación de financiamiento';
         caso21.AccountId = acc.Id;
         caso21.FIN_NumeroCredito__c ='CRED00000001234';
         caso21.RecordTypeId = rt.Id;
         caso21.OwnerId  = UserInfo.getUserId();
         casos.add(caso21);

        
        
        insert casos;
        
        /******************************************/
        
        PVU_CasesAssets__c caseAsset = new PVU_CasesAssets__c();
        caseAsset.PVU_RelatedAsset__c = ast3.Id;
        caseAsset.PVU_RelatedCase__c = caso20.Id;
        insert caseAsset;      
        
        /******************************************/
        
        
        
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
        insert orderItem6;
        
        OrderItem orderItem7 = new OrderItem();
        orderItem7.OrderId = orden5.Id;
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
        insert orderItem7;
        
        orden1.Status='Cerrada Perdida';
        
        orden2.Status='Cerrada Perdida';
        orden3.Status='Cerrada Perdida';
        orden4.Status='InPayment';
        
        update ordenes;
        
    }
    
    @isTest
    private static void devolucionDineroTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'DevolucionDinero';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('AccountId',(String)cuenta.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, ((List<Case>)output.get('openCases')).size() > 0, 'La lista de casos candidatos es vacía');
        
    }
    
    @isTest
    private static void devolucionDineroOrdenTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'DevolucionDineroOrder';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('AccountId',(String)cuenta.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('openOrdersSize') > 0, 'La lista de casos candidatos es vacía');
        
    }
    
    @isTest
    private static void devolucionDineroPQRTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'DevolucionDineroPQR';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('AccountId',(String)cuenta.Id);
        Map<String, Object> caso1Map = new Map<String, Object>{
            'casoNumRadicado' => '00000001'
                };
                    
                    Map<String, Object> caso2Map = new Map<String, Object>{
                        'casoNumRadicado' => '00000009'
                            };
                                List<Object> inputList = new List<Object>();
        inputList.add(caso1Map);
        inputList.add(caso2Map);
        input.put('Casos', inputList);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('openCasesSize') > 0, 'La lista de casos candidatos es vacía');
        
    }
    
    @isTest
    private static void pagosNoAbonadosBloqueanteTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'pagosNoAbonados';
        Boolean fueinvocado = false;
        String vozCliente = 'Pago no abonado';
        
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_ClosingReason__c, AccountId 
                       FROM Order 
                       WHERE Status = 'Cerrada Perdida' 
                       AND FVU_ClosingReason__c = 'Cancelado por no finalización de orden'
                       AND AccountId = :cuenta.Id LIMIT 1];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('OrderId', orden.Id);
        input.put('VozCliente', vozCliente);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Boolean)output.get('tieneCasosBloqueantes'), 'La orden no tiene casos bloqueantes');
        
    }
    
    @isTest
    private static void pagosNoAbonadosNoBloqueanteTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'pagosNoAbonados';
        Boolean fueinvocado = false;
        String vozCliente = 'Pago no abonado';
        
        Account cuenta = [SELECT Id FROM Account][0];
        Order orden = [SELECT Id, Status, FVU_PaymentStatus__c, AccountId 
                       FROM Order 
                       WHERE Status = 'InPayment' 
                       AND FVU_PaymentStatus__c = 'PP'
                       AND AccountId = :cuenta.Id LIMIT 1];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('OrderId', orden.Id);
        input.put('VozCliente', vozCliente);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(false, (Boolean)output.get('tieneCasosBloqueantes'), 'La orden tiene casos bloqueantes');
        
    }
    
    @isTest
    private static void reporteImeiTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'reporteImei';
        Boolean fueinvocado = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','100000000000002');
        
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('openCasesSize') > 0, 'La lista de casos candidatos es vacía');
        
    }
    
    @isTest
    private static void liberacionImeiTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'liberacionImei';
        Boolean fueinvocado = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','100000000000003');
        input.put('MIN','12346');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('openCasesSize') > 0, 'La lista de casos es vacía en Liberacion');
        System.AssertEquals(true, (Decimal)output.get('recentlyCasesRoboPerdidaSize') > 0, 'La lista de casos recientes es vacía en Liberacion');
    }
    
    @isTest
    private static void registroImeiTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'registroImei';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','100000000000003');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void duplicadoImeiTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'duplicadoImei';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','100000000000003');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cancelacionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cancelacion';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('VozCliente','Cancelación Fallecimiento');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cancelacionByCausalTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cancelacionByCausal';
        List<String> causales = new List<String>();
        causales.add('Cancelación Fallecimiento');
        causales.add('Cancelación Voluntaria');
        causales.add('Cambio de pospago a prepago"');
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Causales',causales);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void reconexionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'reconexion';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('VozCliente','Reconexión Suspensión Temporal Voluntaria');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    
    @isTest
    private static void cambioCiclo(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cambioCiclo';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);        
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cambioTitularidadTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cambioTitularidad';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('VozCliente','Cambio de titularidad de IMEI');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cambioPlanTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cambioPlan';
        Boolean result = false;
        
        Asset asset = [SELECT Id FROM Asset where Name ='Test Asset1'][0];
        input.put('AssetId',(String)asset.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cambioSimCardTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cambioSimCard';
        Boolean result = false;
        
        Asset asset = [SELECT Id FROM Asset where Name ='Test Asset1'][0];
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('AssetId',(String)asset.Id);
        input.put('AccountId',(String)cuenta.Id);
        input.put('VozCliente','Cambio de SIM Card');
        input.put('AsuntoMotivo','CambioSIM_RoboPerdida');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void roamingTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'roaming';
        Boolean result = false;
        
        Asset asset = [SELECT Id FROM Asset where Name ='Test Asset1'][0];
        input.put('AssetId',(String)asset.Id);
        input.put('SubCategoria','Roaming Internacional');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cobroErradoTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cobroErrado';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('AccountId',(String)cuenta.Id); 
              
        
        List<Object> selectedRows = new List<Object>();
        Map<String, Object> row1 = new Map<String, Object>();
        row1.put('billNumber', 'BillNumber1');
        row1.put('descripcion', 'Descripcion1');
        row1.put('valorOriginal', 'ValorOriginal1');
        selectedRows.add(row1);
        
        Map<String, Object> row2 = new Map<String, Object>();
        row2.put('billNumber', 'BillNumber2');
        row2.put('descripcion', 'Descripcion2');
        row2.put('valorOriginal', 'ValorOriginal2');
        selectedRows.add(row2);
        
        input.put('selectedRows', selectedRows);        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        List<String> selectedIds = (List<String>) output.get('SelectedIds');
        System.assertEquals(2, selectedIds.size(), 'Deberían haberse seleccionado 2 IDs.');
        System.assert(selectedIds.contains('BillNumber1Descripcion1ValorOriginal1'), 'Debe contener la primera ID seleccionada.');
        System.assert(selectedIds.contains('BillNumber2Descripcion2ValorOriginal2'), 'Debe contener la segunda ID seleccionada.');
    }

    @isTest
    private static void cesionImeiTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cesionImei';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','1000000000001234');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void reinstalacionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'reinstalacion';
        Boolean result = false;
        
         Asset asset = [SELECT Id FROM Asset where Name ='Test Asset1'][0];
        Account cuenta = [SELECT Id FROM Account][0];
        input.put('assetId',(String)asset.Id);
        input.put('accountId',(String)cuenta.Id);
        input.put('vozCliente','Reinstalación Servicio Móvil');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cambioPlanAccInmediatasTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cambioPlanAccInmediatas';
        Boolean result = false;
        
        Asset ast = [SELECT Id FROM Asset WHERE Name = 'Test Asset1'][0];
        
        String startD = Date.today().year() +'-'+Date.today().month()+'-'+Date.today().day();
		String endD = Date.today().addMonths(1).year() +'-'+Date.today().addMonths(1).month()+'-'+Date.today().addMonths(1).day();
        
        input.put('AssetId',(String)ast.Id);
        input.put('startDate',startD);
        input.put('endDate',endD);
        
        Test.startTest();
            CasesValidations validation = new CasesValidations();
            result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
    @isTest
    private static void cesioncontratoTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'cesioncontrato';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        Product2 prod = [SELECT Id FROM Product2][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('vozCliente','Cesión de contrato');
        input.put('accountValue','');
        input.put('productId',(String)prod.Id);
        
        Test.startTest();
            CasesValidations validation = new CasesValidations();
            result = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
    
     @isTest
    private static void devolucionDineroCaseClosedVentaNoExitosaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionDineroCloseCaseVentaNoExitosa';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        Order order = [SELECT Id FROM Order where FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega' and AccountId =:cuenta.Id][0];
        input.put('AccountId',(String)cuenta.Id);
        input.put('OrderId',(String)order.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('CasesClosedSize') > 0, 'La lista de casos cerrados es vacia');
        
    }
    @isTest
    private static void devolucionDineroCloseCasePQRTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionDineroCloseCasePQR';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Cun','1234569789');
        input.put('Nr','987654321');
        input.put('AsseId',asset.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('CasesClosedSize') > 0, 'La lista de casos cerrados es vacia');
        
    }
    @isTest
    private static void devolucionDineroCloseCaseSoporteFallaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionDineroCloseCaseSoporteFalla';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];  
        Asset asset = [SELECT Id FROM Asset where Name ='Test Asset1'][0];
        input.put('AccountId',(String)cuenta.Id);        
        input.put('AssetId',asset.Id);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('CasesClosedSize') > 0, 'La lista de casos cerrados es vacia');
        
    }
    
   
    @isTest
    private static void devolucionObtenerAssetPQRTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionObtenerAssetPQR';
        Boolean fueinvocado = false;
        Account cuenta = [SELECT Id FROM Account][0];
        List<PVU_CasesAssets__c> caseAssetRelations = [SELECT PVU_RelatedAsset__r.Id, PVU_RelatedAsset__r.Name, PVU_RelatedAsset__r.Status, PVU_RelatedAsset__r.Product2.vlocity_cmt__Type__c, 
                                                        PVU_RelatedAsset__r.PVU_IMEI__c, PVU_RelatedAsset__r.PVU_Serial__c, PVU_RelatedAsset__r.FIN_IdReferenciaDelCredito92__c, 
                                                        PVU_RelatedCase__r.AccountId, PVU_RelatedCase__r.PVU_CUN__c, PVU_RelatedCase__r.PVU_NR__c, PVU_RelatedAsset__r.AccountId,
                                                        PVU_RelatedAsset__r.vlocity_cmt__AssetReferenceId__c, PVU_RelatedCase__r.RecordType.DeveloperName
                                                       FROM PVU_CasesAssets__c];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('NR','20250519');
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        System.AssertEquals(true, (Decimal)output.get('CasesAssetsSize') > 0, 'Lista de assets');
        
    }

    @isTest
    private static void devolucionObtenerAssetSFTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionObtenerAssetSF';
        Boolean fueinvocado = false;
        Case caso = [SELECT Id, AccountId, CaseNumber FROM Case][0];
        
        input.put('AccountId',(String)caso.AccountId);
        input.put('CaseNumber',(String)caso.CaseNumber);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        List<Asset> listAssets = (List<Asset>)output.get('CasesAssets');
        System.AssertEquals(false, listAssets.isEmpty(), 'Lista de assets');
        
    }

    @isTest
    private static void devolucionObtenerAssetSaldoFinTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'devolucionObtenerAssetSaldoFin';
        Boolean fueinvocado = false;
        Case caso = [SELECT Id, AccountId, FIN_NumeroCredito__c FROM Case WHERE PVU_Level3__c = 'Eliminación de financiamiento' ][0];
        
        input.put('AccountId',(String)caso.AccountId);
        input.put('NroCredito',(String)caso.FIN_NumeroCredito__c);
        
        Test.startTest();
        CasesValidations validation = new CasesValidations();
        fueinvocado = validation.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        System.AssertEquals(true, fueinvocado, 'El metodo ' + methodName + ' no fue invocado');
        List<Asset> listAssets = (List<Asset>)output.get('CasesAssets');
        System.AssertEquals(false, listAssets.isEmpty(), 'Lista de assets');
        
    }
    

    @isTest
    private static void devolucionDineroOpenCaseSoporteFallaEquipoTest() {
        // === PREPARACIÓN DE DATOS ===
        Account acc = new Account(Name = 'Cuenta Test' , FVU_DocumentType__c = 'CC',FVU_DocumentNumber__c = '4321');
        insert acc;

        // RecordType simulado (ajusta el DeveloperName según tu org)
        RecordType rtSoporte = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        RecordType rtPQR = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPQR'][0];
        Product2 produ2 = new Product2 (Name='Product 2', ProductCode = 'Terminal2', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = 'Descripción Larga',Short_Description__c = 'Descripción Corta');
        insert produ2;
       
        // Asset asociado a la cuenta
        Asset ast = new Asset(
            Name = 'Test Asset1 one',
            AccountId = acc.Id,
            Status = 'Active',
            Product2Id = produ2.Id
        );
        insert ast;

        // Caso 1: Caso abierto de soporte y fallas (debe ser encontrado)
        Case casoSoporte = new Case(
            PVU_Level1__c = 'Soporte, fallas de servicio y equipos',
            Status = 'Abierto',
            AccountId = acc.Id,
            AssetId = ast.Id,
            RecordTypeId = rtSoporte.Id
        );
        insert casoSoporte;
        
        // Caso 2: Caso cerrado de devolución (no debe ser contado)
        Case casoCerrado = new Case(
            PVU_Level1__c = 'Facturación y pagos',
            PVU_Level2__c = 'Devolución de dinero',
            PVU_Level3__c = 'Devolución dinero en efectivo',
            Status = 'Cerrado',
            PVU_Codigo_de_Cierre__c = 'Se realiza devolución',
            AccountId = acc.Id,
             PVU_CUN__c ='20250510',
            PVU_NR__c ='20250510',
            RecordTypeId = rtPQR.Id
        );
        insert casoCerrado;

        // === ESCENARIO 1: Tipo = 'Asset' ===
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('AccountId', acc.Id);
        input.put('AssetId', ast.Id);
        input.put('Tipo', 'Asset');

        Test.startTest();
        CasesValidations validation = new CasesValidations();
        Boolean fueInvocado = validation.invokeMethod('devolucionDineroOpenCaseSoporteFallaServiciosEquipos', input, output, options);
        Test.stopTest();

        // === VALIDACIONES ===
        System.assertEquals(true, fueInvocado, 'El método no fue invocado correctamente');
        System.assert(output.containsKey('CasesOpenSize'), 'Debe contener el tamaño de casos abiertos');
        System.assertEquals(1, (Decimal)output.get('CasesOpenSize'), 'Debe haber 1 caso abierto de soporte');

       
    }
    
        @isTest
    private static void devolucionDineroOpenCaseSoporteFallaEquipoTestPQR() {
        // === PREPARACIÓN DE DATOS ===
        Account acc = new Account(Name = 'Cuenta Test' , FVU_DocumentType__c = 'CC',FVU_DocumentNumber__c = '4321');
        insert acc;

        // RecordType simulado (ajusta el DeveloperName según tu org)
        RecordType rtSoporte = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        RecordType rtPQR = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPQR'][0];
        Product2 produ2 = new Product2 (Name='Product 2', ProductCode = 'Terminal2', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = 'Descripción Larga',Short_Description__c = 'Descripción Corta');
        insert produ2;
       
        // Asset asociado a la cuenta
        Asset ast = new Asset(
            Name = 'Test Asset1 one',
            AccountId = acc.Id,
            Status = 'Active',
            Product2Id = produ2.Id
        );
        insert ast;

        // Caso 1: Caso abierto de soporte y fallas (debe ser encontrado)
        Case casoSoporte = new Case(
            PVU_Level1__c = 'Soporte, fallas de servicio y equipos',
            Status = 'Abierto',
            AccountId = acc.Id,
            AssetId = ast.Id,
            RecordTypeId = rtSoporte.Id
        );
        insert casoSoporte;
        
        // Caso 2: Caso cerrado de devolución (no debe ser contado)
        Case casoCerrado = new Case(
            PVU_Level1__c = 'Facturación y pagos',
            PVU_Level2__c = 'Devolución de dinero',
            PVU_Level3__c = 'Devolución dinero en efectivo',
            Status = 'Cerrado',
            PVU_Codigo_de_Cierre__c = 'Se realiza devolución',
            AccountId = acc.Id,
             PVU_CUN__c ='20250510',
            PVU_NR__c ='20250510',
            RecordTypeId = rtPQR.Id
        );
        insert casoCerrado;
         // === ESCENARIO 2: Tipo = 'PQR' con varios assets ===
          Product2 produt2 = new Product2 (Name='Product 2', ProductCode = 'Terminal2', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = 'Descripción Larga',Short_Description__c = 'Descripción Corta');
           insert produt2;
        Asset ast2 = new Asset(Name = 'Asset 2 two', AccountId = acc.Id, Status = 'Active', Product2Id = produt2.Id);
        insert ast2;

        Case casoSoporte2 = new Case(
            PVU_Level1__c = 'Soporte, fallas de servicio y equipos',
            Status = 'En curso',
            AccountId = acc.Id,
            AssetId = ast2.Id,
            RecordTypeId = rtSoporte.Id
        );
        insert casoSoporte2;

        List<Object> assetList = new List<Object>{
            new Map<String, Object>{ 'Id' => (String)ast.Id },
            new Map<String, Object>{ 'Id' => (String)ast2.Id }
        };
           Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('AccountId', acc.Id);
        input.put('Tipo', 'PQR');
        input.put('listAssets', assetList);
        input.put('siAssets', true);
         Test.startTest();
        CasesValidations validation = new CasesValidations();
        Boolean fueInvocado = validation.invokeMethod('devolucionDineroOpenCaseSoporteFallaServiciosEquipos', input, output, options);
        Test.stopTest();

        // === VALIDACIONES PQR ===
        System.assertEquals(true, fueInvocado, 'El método no fue invocado correctamente (PQR)');
        System.assert(output.containsKey('CasesOpenSize'), 'Debe contener el tamaño de casos abiertos (PQR)');
        System.assertEquals(2, (Decimal)output.get('CasesOpenSize'), 'Debe haber 2 casos abiertos/en curso de soporte');

       
    }
    
}