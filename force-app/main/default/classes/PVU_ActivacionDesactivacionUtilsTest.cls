@isTest
public class PVU_ActivacionDesactivacionUtilsTest {
    
    @TestSetup
    static void makeData(){
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        insert pb;
        
        Product2 testProduct = new Product2(Name = 'Test Product',Description = 'This is a test product',ProductCode = 'test1', isActive = true);
        insert testProduct;
        
        PriceBookEntry[] entryList = new List<PriceBookEntry> {
            new PricebookEntry( Product2Id=testProduct.id, UnitPrice=0, PriceBook2Id=Test.getStandardPricebookId(), UseStandardPrice=false, isActive=true),
            new PricebookEntry( Product2Id=testProduct.id, UnitPrice=0, PriceBook2Id=pb.id, UseStandardPrice=true, isActive=true)
        };
        insert entryList;

        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'StandardOrder'][0];

        Order ord1 = new Order(AccountId = acct.Id, Pricebook2Id = pb.Id, Status = 'Draft',RecordTypeId = rt.Id, PVU_CaseInfo__c= '{"fechaFinCanc":"2025-12-11T22:30:13Z","numeroLinea":"573100006338","fechaInicioSusp":"2025-09-12","Id":"500VA00000IW9YrYAL","esRetencion":true,"vozCliente":"Beneficios para tu plan"}', 
        EffectiveDate = Date.today(), Type = 'Cambios', FVU_OrderSubType__c = 'Adicion_de_Adicionales');
        insert ord1;

        OrderItem ordItem1 = new OrderItem(OrderId = ord1.Id, Quantity = 1, 
        vlocity_cmt__action__c = 'Add', PricebookEntryId = entryList[1].Id,
        FVU_EffectiveRecurringTotalIncTaxes__c = 1234, UnitPrice = entryList[1].UnitPrice,
        Product2Id = testProduct.Id);
        insert ordItem1;
        // [2026-05-11: COE-Soporte]: Se adiciona la creación y aplicación de una promoción al OrderItem1, para incrementar la cobertura de código de la clase de test.        
        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(        
        Name = 'Promo CFM Test',CAT_Type__c = 'Estandar',CAT_PromotionClass__c = 'Obsequios de CFM',vlocity_cmt__GlobalKey__c = 'PROMO_TEST',vlocity_cmt__Code__c = 'PROMO_TEST');
        insert promo;

        vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromo = new vlocity_cmt__OrderAppliedPromotion__c(
        vlocity_cmt__OrderId__c = ord1.Id, vlocity_cmt__PromotionId__c = promo.Id, vlocity_cmt__Action__c = 'Add');
        insert orderAppliedPromo;
        
        vlocity_cmt__OrderAppliedPromotionItem__c promoItem = new vlocity_cmt__OrderAppliedPromotionItem__c(
        vlocity_cmt__OrderItemId__c = ordItem1.Id, vlocity_cmt__OrderAppliedPromotionId__c = orderAppliedPromo.Id);
        insert promoItem;

        Order ord2 = new Order(AccountId = acct.Id, Pricebook2Id = pb.Id, Status = 'Draft',RecordTypeId = rt.Id, PVU_CaseInfo__c= '{"fechaFinCanc":"2025-12-11T22:30:13Z","numeroLinea":"573100006338","fechaInicioSusp":"2025-09-12","Id":"500VA00000IW9YrYAL"}',
        EffectiveDate = Date.today(), Type = 'Cambios', FVU_OrderSubType__c = 'Eliminacion_de_Adicionales');
        insert ord2;

        OrderItem ordItem2 = new OrderItem(OrderId = ord2.Id, Quantity = 1, 
        vlocity_cmt__action__c = 'Disconnect', PricebookEntryId = entryList[1].Id,
        FVU_EffectiveRecurringTotalIncTaxes__c = 1234, UnitPrice = entryList[1].UnitPrice,
        Product2Id = testProduct.Id);
        insert ordItem2;
    }

    @isTest
    public static void getDataOrderActivacionTest(){
        Order orden = [SELECT Id FROM Order WHERE FVU_OrderSubType__c = 'Adicion_de_Adicionales'][0];
        Boolean result = false;
        
        String methodName = 'getDataOrder';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('OrderId',orden.Id);
        
        PVU_ActivacionDesactivacionUtils activDesactivUtils = new PVU_ActivacionDesactivacionUtils();
        Test.startTest();
            result = activDesactivUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');    
    }

    @isTest
    public static void getDataOrderDesactivacionTest(){
        Order orden = [SELECT Id FROM Order WHERE FVU_OrderSubType__c = 'Eliminacion_de_Adicionales'][0];
        Boolean result = false;
        
        String methodName = 'getDataOrder';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('OrderId',orden.Id);
        
        PVU_ActivacionDesactivacionUtils activDesactivUtils = new PVU_ActivacionDesactivacionUtils();
        Test.startTest();
            result = activDesactivUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');    
    }

    @isTest
    public static void errorCatchPpalTest(){
        Boolean result = false;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        PVU_ActivacionDesactivacionUtils activDesactivUtils = new PVU_ActivacionDesactivacionUtils();
        Test.startTest();
            result = activDesactivUtils.invokeMethod(null, input, output, options);
        Test.stopTest();
        System.assertEquals(result,false, 'El método principal fue invocado');    
    }    
}