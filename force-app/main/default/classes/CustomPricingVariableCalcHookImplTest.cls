@isTest
public class CustomPricingVariableCalcHookImplTest {

    public static Map<String, Object> testCreateOrderWithProducts() {
        Id pricebookId = Test.getStandardPricebookId();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' OR Name='Administrador del sistema']; 
        User u = new User(Alias = 'UCityCav', Email='TestCityCAVAd@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', ProfileId = p.Id, FVU_DANE_Punto_de_Venta__c ='88', UserName='TestCityCAVAdmin@testorg.com');
        insert u;

        Account acc = new Account(name='ClaroTaxesTest',FVU_ServiceState__c = 'AMAZONAS');
        acc.BillingStreet = 'Calle 123 # 45 - 67';
        acc.BillingCity = 'Bogotá D.C';
        acc.BillingState = 'Bogotá D.C';
        acc.BillingCountry = 'Colombia';
        acc.ShippingStreet = 'Calle 123 # 45 - 67';
        acc.ShippingCity = 'Bogotá D.C';
        acc.ShippingState = 'Bogotá D.C';
        acc.ShippingCountry = 'Colombia';
        acc.FVU_ServiceDaneCode__c = '88001'; //SAN ANDRÉS
        insert acc;

        Account acc2 = new Account(name='ClaroTaxesTest 2',FVU_ServiceState__c = 'ANTIOQUIA');
        acc2.BillingStreet = 'Calle 123 # 45 - 88';
        acc2.BillingCity = 'Medellín';
        acc2.BillingState = 'Antioquia';
        acc2.BillingCountry = 'Colombia';
        acc2.ShippingStreet = 'Calle 123 # 45 - 88';
        acc2.ShippingCity = 'Medellín';
        acc2.ShippingState = 'Antioquia';
        acc2.ShippingCountry = 'Colombia';
        acc2.FVU_ServiceDaneCode__c = '88001'; //SAN ANDRÉS
        insert acc2;

        Order ord = new Order(AccountId = acc.id,vlocity_cmt__Phone__c='0523400003',Status = 'Draft',EffectiveDate = Date.today(),Pricebook2Id = pricebookId,vlocity_cmt__DefaultServiceAccountId__c = acc.id);
        insert ord;

        Order ord2 = new Order(AccountId = acc2.id,vlocity_cmt__Phone__c='0523400003',Status = 'Draft',EffectiveDate = Date.today(),Pricebook2Id = pricebookId,vlocity_cmt__DefaultServiceAccountId__c = acc2.id);
        insert ord2;

        vlocity_cmt__ObjectClass__c objType = new vlocity_cmt__ObjectClass__c(Name = 'OT ClaroTaxesTest',vlocity_cmt__IsActive__c = true,vlocity_cmt__ObjectApiName__c = 'Product2');
        insert objType;

        Product2 prodTech = new Product2(Name = 'Product Tech',ProductCode = 'B2C-CLARO-TECH-TEST',isActive = true,vlocity_cmt__ObjectTypeId__c = objType.Id,Family = 'Device', vlocity_cmt__Type__c = 'Tech', vlocity_cmt__SubType__c = 'None');
        insert prodTech;

        Product2 prodHandset = new Product2(Name = 'Claro Taxes Test',ProductCode = 'B2C-CLARO-HANDSET-TEST',isActive = true,vlocity_cmt__ObjectTypeId__c = objType.Id,Family = 'Device', vlocity_cmt__Type__c = 'Handset', vlocity_cmt__SubType__c = 'None');
        insert prodHandset;

        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prodTech.Id,Product2 = prodTech, UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        OrderItem oliOneTimeTech = new OrderItem(OrderId = ord.Id,Quantity = 2,Product2Id = prodTech.Id,vlocity_cmt__Product2Id__c = prodTech.Id,PricebookEntryId = pbEntry.Id,UnitPrice = 100.00,vlocity_cmt__OneTimeCalculatedPrice__c = 100.00,vlocity_cmt__OneTimeCharge__c = 100.00, vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-SUP-CAT-PROD":"Patineta Eléctrica","B2C-ATTR-TEC-LIMITE-UVT":1}');
        insert oliOneTimeTech;

        OrderItem oliOneTimeHandset = new OrderItem(OrderId = ord2.Id,Quantity = 1,Product2Id = prodHandset.Id,vlocity_cmt__Product2Id__c = prodHandset.Id,PricebookEntryId = pbEntry.Id,UnitPrice = 100.00,vlocity_cmt__OneTimeCalculatedPrice__c = 100.00,vlocity_cmt__OneTimeCharge__c = 100.00, vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-EXC-IMP-TERM": 1}');
        insert oliOneTimeHandset;

        OrderItem oliOneTimeHandsetHighUVT = new OrderItem(OrderId = ord2.Id,Quantity = 1,Product2Id = prodHandset.Id,vlocity_cmt__Product2Id__c = prodHandset.Id,PricebookEntryId = pbEntry.Id,UnitPrice = 100.00,vlocity_cmt__OneTimeCalculatedPrice__c = 100.00,vlocity_cmt__OneTimeCharge__c = 100.00, vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-EXC-IMP-TERM": 60}');
        insert oliOneTimeHandsetHighUVT;

        OrderItem oliOneTimeHandsetHighPrice = new OrderItem(OrderId = ord2.Id,Quantity = 1,Product2Id = prodHandset.Id,vlocity_cmt__Product2Id__c = prodHandset.Id,PricebookEntryId = pbEntry.Id,UnitPrice = 100.00,vlocity_cmt__OneTimeCalculatedPrice__c = 100000000.00,vlocity_cmt__OneTimeCharge__c = 100000000.00, vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-EXC-IMP-TERM": 1}');
        insert oliOneTimeHandsetHighPrice;

        Map<String, Object> dynMap = new Map<String, Object>();
        dynMap.put('OrderTech',ord);
        dynMap.put('OrderHandset',ord2);
        dynMap.put('OrderItemTech',oliOneTimeTech);
        dynMap.put('OrderItemHandset',oliOneTimeHandset);
        dynMap.put('OrderItemHandsetHighUVT',oliOneTimeHandsetHighUVT);
        dynMap.put('OrderItemHandsetHighPrice',oliOneTimeHandsetHighPrice);
        dynMap.put('PriceBookEntry',pbEntry);
        dynMap.put('Account',acc);
        dynMap.put('Account2',acc2);
        dynMap.put('ProdTech',prodTech);
        dynMap.put('ProdHandset',prodHandset);
        dynMap.put('PriceBookEntry',pbEntry);
        dynMap.put('User',u);
        return dynMap;
    }

    @isTest
    private static void testcallcalculatePostInvoke() {

        Map<String, Object> optionsMap = new Map<String, Object>();
        Map<String, Object> outPutMap = new Map<String, Object>();
        Map<string, object> innerMap = new Map<string, object>();
        innerMap.put('OT_STD_PRC_TOTAL',2000000);
        innerMap.put('REC_MNTH_STD_PRC_TOTAL',10000);
        innerMap.put('OT_STD_PRC',2000000);
        innerMap.put('BASE_OT_STD_PRC',2000000);
        innerMap.put('REC_MNTH_STD_PRC',10000);
        innerMap.put('OT_STD_PRC_VENTA',2000000);
        innerMap.put('OT_STD_PRC_INC_TAXES_TOTAL',2000000);
        innerMap.put('REC_MNTH_STD_PRC_INC_TAXES_TOTAL',10000);
        innerMap.put('REC_MNTH_STD_PRC_INC_TAXES',10000);
        innerMap.put('EFF_OT_STD_PRC_TOTAL',10000);
        innerMap.put('EFF_REC_MNTH_STD_PRC_TOTAL',10000);
        innerMap.put('LINE_QUANTITY',1);
        innerMap.put('OT_STD_PRC_INC_TAXES',2000000);
        innerMap.put('ROLLUP_OT_STD_PRC_INC_TAXES_TOTAL',0);
        innerMap.put('BASE_REC_MNTH_STD_PRC',10000);

        outPutMap.put('pricingVariableMap',innerMap);

        //For Prod2 Type:Tech
        Map<String, Object> ordMap = testCreateOrderWithProducts();
        User user = (User)ordMap.get('User');
        Order ord = (Order) ordMap.get('OrderTech');
        Account acc = (Account) ordMap.get('Account');
        Product2 prodTech = (Product2) ordMap.get('ProdTech');
        system.debug('OrderTech::'+ ord);
        PricebookEntry prientry = (PricebookEntry) ordMap.get('PriceBookEntry');
        OrderItem ordItem = (OrderItem) ordMap.get('OrderItemTech'); 
        system.debug('OrderItemTech::'+ordItem);
        Id ordItemId = ordItem.Id;
        list<OrderItem> itemlists = new list<OrderItem>();
        itemlists.add(ordItem);

        Map<String, Object> customFieldValuesTechMap = new Map<String, Object> {ordItemId => new map<String, object>{'daneDptoCAVCode'=>User.get('FVU_DANE_Punto_de_Venta__c'),'FVU_OrderDefaultSvcAccDepartamento__c'=>acc.get('FVU_ServiceState__c'),'Product2Id'=>prodTech.get('Id'),'vlocity_cmt__AttributeSelectedValues__c'=>ordItem.get('vlocity_cmt__AttributeSelectedValues__c'),'ProductCode'=>prodTech.get('ProductCode'),'Family'=>prodTech.get('Family'),'vlocity_cmt__Type__c'=>prodTech.get('vlocity_cmt__Type__c'),'vlocity_cmt__SubType__c'=>prodTech.get('vlocity_cmt__SubType__c'),'IMPUESTO_DECIMAL'=>1.05,'UVT_VIGENTE'=>10000,'aplicaIVA'=>true,'serviceAccDptoCode'=>'AMAZONAS'}};

        //For Prod2 Type:Handset
        Order ordHandset = (Order) ordMap.get('OrderHandset');
        system.debug('OrderHandset::'+ ordHandset);
        OrderItem ordItemHandset = (OrderItem) ordMap.get('OrderItemHandset');
        system.debug('OrderItemHandset::'+ordItemHandset);
        Account acc2 = (Account) ordMap.get('Account2');
        Product2 prodHandset = (Product2) ordMap.get('ProdHandset');
        OrderItem ordItemHandsetHighUVT = (OrderItem) ordMap.get('OrderItemHandsetHighUVT'); 
        Id ordItemHandsetId = ordItemHandset.Id;
        Id ordItemHandsetHighUVTId = ordItemHandsetHighUVT.Id;
        list<OrderItem> itemlistsHandset = new list<OrderItem>();
        itemlistsHandset.add(ordItemHandset);
        list<OrderItem> itemlistsHandsetHighUVT = new list<OrderItem>();
        itemlistsHandsetHighUVT.add(ordItemHandsetHighUVT);

        //For ordItemHandsetHighPrice
        OrderItem ordItemHandsetHighPrice = (OrderItem) ordMap.get('OrderItemHandsetHighPrice'); 
        Id ordItemHandsetHighPriceId = ordItemHandsetHighPrice.Id;
        list<OrderItem> itemlistsHandsetHighPrice = new list<OrderItem>();
        itemlistsHandsetHighPrice.add(ordItemHandsetHighPrice);


        Map<String, Object> customFieldValuesHandsetMap = new Map<String, Object> {ordItemHandsetId => new map<String, object>{'FVU_CAVDaneCode__c'=> 'TMK','FVU_OrderDefaultSvcAccDepartamento__c'=>acc.get('FVU_ServiceState__c'),'Product2Id'=>prodHandset.get('Id'),'vlocity_cmt__AttributeSelectedValues__c'=>ordItemHandset.get('vlocity_cmt__AttributeSelectedValues__c'),'ProductCode'=>prodHandset.get('ProductCode'),'Family'=>prodHandset.get('Family'),'vlocity_cmt__Type__c'=>prodHandset.get('vlocity_cmt__Type__c'),'vlocity_cmt__SubType__c'=>prodHandset.get('vlocity_cmt__SubType__c'),'IMPUESTO_DECIMAL'=>1.19,'UVT_VIGENTE'=>1000,'aplicaIVA'=>false}};

        Map<String, Object> customFieldValuesHandsetHighUVTMap = new Map<String, Object> {ordItemHandsetHighUVTId => new map<String, object>{'FVU_CAVDaneCode__c'=>'TMK','FVU_OrderDefaultSvcAccDepartamento__c'=>acc2.get('FVU_ServiceState__c'),'Product2Id'=>prodHandset.get('Id'),'vlocity_cmt__AttributeSelectedValues__c'=>ordItemHandsetHighUVT.get('vlocity_cmt__AttributeSelectedValues__c'),'ProductCode'=>prodHandset.get('ProductCode'),'Family'=>prodHandset.get('Family'),'vlocity_cmt__Type__c'=>prodHandset.get('vlocity_cmt__Type__c'),'vlocity_cmt__SubType__c'=>prodHandset.get('vlocity_cmt__SubType__c'),'IMPUESTO_DECIMAL'=>1.19,'UVT_VIGENTE'=>50000,'aplicaIVA'=>true}};

        Map<String, Object> customFieldValuesHandsetHighPriceMap = new Map<String, Object> {ordItemHandsetHighPriceId => new map<String, object>{'FVU_CAVDaneCode__c'=> 'TMK','FVU_OrderDefaultSvcAccDepartamento__c'=>acc2.get('FVU_ServiceState__c'),'Product2Id'=>prodHandset.get('Id'),'vlocity_cmt__AttributeSelectedValues__c'=>ordItemHandsetHighPrice.get('vlocity_cmt__AttributeSelectedValues__c'),'ProductCode'=>prodHandset.get('ProductCode'),'Family'=>prodHandset.get('Family'),'vlocity_cmt__Type__c'=>prodHandset.get('vlocity_cmt__Type__c'),'vlocity_cmt__SubType__c'=>prodHandset.get('vlocity_cmt__SubType__c'),'IMPUESTO_DECIMAL'=>1.19,'UVT_VIGENTE'=>20000,'aplicaIVA'=>false}};


        Test.startTest();

        // The following code runs as user 'u' 
        System.debug('Current User: ' + UserInfo.getUserName());
        System.debug('Current Profile: ' + UserInfo.getProfileId()); 
        CustomPricingVariableCalcHookImpl objclass2 = new CustomPricingVariableCalcHookImpl();

        vlocity_cmt.PricingPlanService.putInPricingContext('Parent', ord);
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemlists);
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP', customFieldValuesTechMap);
        vlocity_cmt.PricingPlanService.putInPricingContext('IVAExempt', true);

        Boolean result = objclass2.invokeMethod('calculate.PostInvoke',new map<String, object>{'Parent'=>ord,
                                           'itemList'=>itemlists,'isRoot'=>true,'itemId'=>ordItemId,'PricebookEntry'=>prientry},outPutMap,optionsMap);

        CustomPricingVariableCalcHookImpl objclass3 = new CustomPricingVariableCalcHookImpl();

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemlistsHandset);
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP', customFieldValuesHandsetMap);
        Boolean resultHandset = objclass3.invokeMethod('calculate.PostInvoke',new map<String, object>{'Parent'=>ordHandset,
                                               'itemList'=>itemlistsHandset,'isRoot'=>true,'itemId'=>ordItemHandsetId,'PricebookEntry'=>prientry},outPutMap,optionsMap);

        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemlistsHandsetHighUVT);
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP',customFieldValuesHandsetHighUVTMap);
        Boolean resultHandsetHighUVT = objclass3.invokeMethod('calculate.PostInvoke',new map<String, object>{'Parent'=>ordHandset,
                                                'itemList'=>itemlistsHandsetHighUVT,'isRoot'=>true,'itemId'=>ordItemHandsetHighUVTId,'PricebookEntry'=>prientry},outPutMap,optionsMap);
        
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemlistsHandsetHighPrice);
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP',customFieldValuesHandsetHighPriceMap);
        Boolean resultHandsetHighPrice = objclass3.invokeMethod('calculate.PostInvoke',new map<String, object>{'Parent'=>ordHandset,
                                                'itemList'=>itemlistsHandsetHighPrice,'isRoot'=>true,'itemId'=>ordItemHandsetHighPriceId,'PricebookEntry'=>prientry},outPutMap,optionsMap);
        vlocity_cmt.PricingPlanService.putInPricingContext('LineItemList', itemlistsHandsetHighPrice);
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP',new map<String, object>());
        Boolean resultCustomValuesMapEmpty = objclass3.invokeMethod('calculate.PostInvoke',new map<String, object>{'Parent'=>ordHandset,
                                                                'itemList'=>itemlistsHandsetHighPrice,'isRoot'=>true,'itemId'=>ordItemHandsetHighPriceId,'PricebookEntry'=>prientry},outPutMap,optionsMap);
        
        Test.stopTest();
        
    }
}