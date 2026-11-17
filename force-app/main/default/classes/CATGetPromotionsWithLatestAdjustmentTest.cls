/*--------------------------------------------------------------------------
Author:         Juan Mojica - jmojica@salesforce.com
Company:        Salesforce.com
Description:    Clase que prueba la clase CATGetPromotionsWithLatestAdjustment. Inserta una promoción que tiene un Ajuste de precio y revisa que en la respuesta obtenida de llamar la clase CATGetPromotionsWithLatestAdjustment se tenga el parámetro DiscountAmount que es agregado en la clase y que la lista Discount tenga un solo elemento.
Code Coverage:  N/A
History
<Date>            <Author>             <Description>             <Version>
03-Feb-25         Juan Mojica                                    Versión inicial
----------------------------------------------------------------------------*/
@IsTest
private class CATGetPromotionsWithLatestAdjustmentTest {
    @TestSetup
    static void setupTestData() {
        // Create test data
        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.BillingStreet = 'Calle 123 # 45 - 67';
        testAccount.BillingCity = 'Bogotá D.C';
        testAccount.BillingState = 'Bogotá D.C';
        testAccount.BillingCountry = 'Colombia';
        testAccount.ShippingStreet = 'Calle 123 # 45 - 67';
        testAccount.ShippingCity = 'Bogotá D.C';
        testAccount.ShippingState = 'Bogotá D.C';
        testAccount.ShippingCountry = 'Colombia';
        testAccount.FVU_ServiceDaneCode__c = '88001'; //SAN ANDRÉS
        insert testAccount;

        Order testOrder = new Order(Name='Test Order CAT Test Class',EffectiveDate=System.today(),status='Draft',AccountId = testAccount.Id, Pricebook2Id = Test.getStandardPricebookId(), vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,FVU_TiendaRetiroDaneCode__c='88001',FVU_BodegaEnvioDaneCode__c='88001', FVU_Channel__c = 'SF_CAV', FVU_DaneCiudadCAVOrden__c = '88001000',vlocity_cmt__DeliveryMethod__c='Immediatepickup', FVU_IsIVAExempt__c = true);
        insert testOrder;

        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = testOrder.Id;
        orderItem.Product2Id = product.Id;
        orderItem.vlocity_cmt__Product2Id__c = product.Id;
        orderItem.PricebookEntryId = pricebookEntry.Id;
        orderItem.Quantity = 1;
        orderItem.UnitPrice = 10;
        orderItem.vlocity_cmt__LineNumber__c = '0001';
        orderItem.vlocity_cmt__Action__c = 'Add';
        orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem.vlocity_cmt__ServiceAccountId__c = testAccount.Id;
        orderItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"]"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-EXC-IMP-TERM":0,"B2C-ATTR-FINANC-TERM":null"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple""B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8""B2C-ATTR-TIPO-TERM":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico""B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["NoDisponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","FrecuenciaCardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm""B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible""B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"]"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas""B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no""B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple""B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM""B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X""B2C-ATTR-OBSQ-TERM":"No"}';
        insert orderItem;

        vlocity_cmt__Promotion__c promotion = new vlocity_cmt__Promotion__c(
            Name = 'Test Promotion',
            vlocity_cmt__Code__c = 'Test Promotion',
            vlocity_cmt__EffectiveStartDate__c = Date.today(),
            vlocity_cmt__EffectiveEndDate__c = Date.today().addDays(30),
            CAT_Type__c = 'Estandar',
            CAT_PromotionClass__c = 'Descuento'
        );
        insert promotion;

        vlocity_cmt__PromotionItem__c promotionItem = new vlocity_cmt__PromotionItem__c(
            Name = 'Promotion Item Name Test',
            vlocity_cmt__PromotionId__c = promotion.Id,
            vlocity_cmt__ActionType__c = 'Add/Update',
            vlocity_cmt__CardinalityCheckScope__c = 'Cart Scope',
            vlocity_cmt__EffectiveFromDate__c = Date.today(),
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsUndoable__c = false,
            vlocity_cmt__MaxQuantity__c = 99999,
            vlocity_cmt__MinQuantity__c = 0,
            vlocity_cmt__Quantity__c = 1,
            vlocity_cmt__ProductId__c = product.Id,
            vlocity_cmt__UpdateScope__c = 'Update Item Only'
        );
        insert promotionItem;

        // Crear datos de prueba para PriceList
        vlocity_cmt__PriceList__c priceList = new vlocity_cmt__PriceList__c (
            Name = 'Cliente Masivo', 
            vlocity_cmt__Code__c = 'PL-B2C'
        );
        insert priceList;

        // Crear datos de prueba para PricingVariable
        vlocity_cmt__PricingVariable__c pricingVariableTest = new vlocity_cmt__PricingVariable__c( // Pricing Variable sin impuestos y sin adjustment method
            Name = 'One Time Std Price Adjustment Abs',
            vlocity_cmt__AdjustmentMethod__c = 'Absolute',
            vlocity_cmt__Aggregation__c = 'Unit',
            vlocity_cmt__ChargeType__c = 'Adjustment',
            vlocity_cmt__Code__c = 'OT_STD_PRC_ADJ_ABS',
            vlocity_cmt__CurrencyType__c = 'Currency',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__Scope__c = 'Line',
            vlocity_cmt__SubType__c = 'Standard',
            vlocity_cmt__Type__c = 'Price',
            vlocity_cmt__ValueType__c = 'Pricing Element'
        );
        insert pricingVariableTest;

        vlocity_cmt__PricingElement__c pricingElementTest = new vlocity_cmt__PricingElement__c( // Pricing Element con ajuste absolute y sin impuestos
            Name = 'One Time Std Price Adjustment Abs -12345',
            vlocity_cmt__AdjustmentValue__c = -12345,
            vlocity_cmt__CalculationType__c = 'Simple',
            vlocity_cmt__Code__c = 'One Time Std Price Adjustment Abs_-12345_COP_a2r79000000kPNHAA2',
            vlocity_cmt__CurrencyCode__c = 'COP',
            vlocity_cmt__DisplayText__c = 'One Time Std Price Adjustment Abs -12345',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__IsReusable__c = true,
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingVariableId__c = pricingVariableTest.Id
        );
        insert pricingElementTest;

        vlocity_cmt__PriceListEntry__c priceListEntryTest = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__PriceListId__c = priceList.Id,
            vlocity_cmt__PricingElementId__c = pricingElementTest.Id,
            vlocity_cmt__DisplayText__c = 'Test Adjustment',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = false,
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__IsVirtualPrice__c = false,
            vlocity_cmt__ProductId__c = product.Id,
            vlocity_cmt__PromotionId__c = promotion.Id,
            vlocity_cmt__PromotionItemId__c = promotionItem.Id,
            vlocity_cmt__PriceBookEntryId__c = pricebookEntry.Id
        );
        insert priceListEntryTest;
    }

    @IsTest
    static void testGetPromotionsWithLatestAdj() {
        // Get test data
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        vlocity_cmt__Promotion__c promotion = [SELECT Id FROM vlocity_cmt__Promotion__c WHERE Name = 'Test Promotion' LIMIT 1];
        Order testOrder = [SELECT Id FROM Order WHERE Name = 'Test Order CAT Test Class' LIMIT 1];
        String promotionIds = promotion.Id;

        // Create input map
        Map<String, Object> input = new Map<String, Object>{
            'PromotionsList' => promotionIds,
            'OrderId' => testOrder.Id
        };

        // Create output map
        Map<String, Object> output = new Map<String, Object>();

        // Create options map
        Map<String, Object> options = new Map<String, Object>();

        // Create instance of CATGetPromotionsWithLatestAdjustment class
        CATGetPromotionsWithLatestAdjustment catGetPromotionsWithLatestAdjustment =
            new CATGetPromotionsWithLatestAdjustment();

        // Call the invokeMethod method
        catGetPromotionsWithLatestAdjustment.invokeMethod('getPromotionsWithLatestAdj', input, output, options);

        //Buscar el nodo fields de la respuesta para evaluar si tiene el Key DiscountAmount que es agreagdo en la clase que se está probando y verificar si la lista Discount tiene un solo elemento ya que en la clase se eliminan y se deja solo el más reciente.

        vlocity_cmt.JSONResult responseResult = (vlocity_cmt.JSONResult)output.get('result');
        System.debug('responseResult: '+ responseResult);

        for(vlocity_cmt.JSONRecord record : responseResult.records)
        {
            System.debug('record: '+ record);

            Map<String,Object> recordFields = (Map<String,Object>)record.fields;
            System.debug('recordFields: '+ JSON.serialize(recordFields));

            System.assertEquals(true, recordFields.containsKey('DiscountAmount'),'Respuesta no incluye el parámetro DiscountAmount');
            List<Object> discountList = (List<Object>)recordFields.get('Discount');
            System.assertEquals(1, discountList.size(),'DiscountAmount no trae un solo elemento');
        }
    }
}