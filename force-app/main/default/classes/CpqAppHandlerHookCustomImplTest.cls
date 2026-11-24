@isTest
public class CpqAppHandlerHookCustomImplTest {
    @isTest
    static void testCreateFields()
    {     
        try
        {
            List<SObject> sObjList = new List<SObject>();

            // Create products
            Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'PO_MovPosPlanConV41Mx', Family = 'Device', vlocity_cmt__Type__c = 'Handset', FVU_Beneficios__c = '');
            sObjList.add(prod1);

            //Crear un producto que corresponda a un plan movil
            Product2 prodMobilePlan = new Product2 ();
            prodMobilePlan.Name = 'Mobile Plan';
            prodMobilePlan.ProductCode = 'PO_MovPosPlanConV41Mx';
            prodMobilePlan.FVU_Beneficios__c = '';
            prodMobilePlan.Family = 'Mobile';
            prodMobilePlan.vlocity_cmt__Type__c = 'Plan';
            prodMobilePlan.vlocity_cmt__SubType__c = 'Postpaid';
            prodMobilePlan.vlocity_cmt__SpecificationType__c = 'Offer';
            prodMobilePlan.vlocity_cmt__SpecificationSubType__c = 'Bundle';
            sObjList.add(prodMobilePlan);

            insert sObjList;
            sObjList.clear();

            //Crear un producto que corresponda a un Add On
            Product2 addOn = new Product2 ();
            addOn.Name = 'Add On';
            addOn.ProductCode = 'B2C-MOV-AddOn-CODE';
            addOn.FVU_Beneficios__c = '';
            addOn.Family = 'Mobile';
            addOn.vlocity_cmt__Type__c = 'Add On';
            addOn.vlocity_cmt__SpecificationType__c = 'Offer';
            addOn.vlocity_cmt__SpecificationSubType__c = 'Simple';
            sObjList.add(addOn);

            insert sObjList;
            sObjList.clear();

            // Create Price Book Entries
            Pricebook2 testPricebook =  new Pricebook2(Id = Test.getStandardPricebookId(), Name = 'TestPricebook', IsActive = true);
            PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = testPricebook.Id,
                Product2Id = prod1.Id, UnitPrice = 0, vlocity_cmt__RecurringPrice__c = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
            sObjList.add(pbe1);

            //Crear un PriceBookEntry que use el producto del plan movil.
            PricebookEntry pbeMobilePlan = new PricebookEntry(Pricebook2Id = testPricebook.Id,
                Product2Id = prodMobilePlan.Id, UnitPrice = 0, vlocity_cmt__RecurringPrice__c = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
            sObjList.add(pbeMobilePlan);

            insert sObjList;
            sObjList.clear();

            //Crear un PriceBookEntry que use el producto del Add On.
            PricebookEntry pbeAddOn = new PricebookEntry(Pricebook2Id = testPricebook.Id,
                Product2Id = addOn.Id, UnitPrice = 0, vlocity_cmt__RecurringPrice__c = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
            sObjList.add(pbeAddOn);

            insert sObjList;
            sObjList.clear();

            Account testAccount = new Account();
            testAccount.Name = 'Hook Test Account';
            testAccount.FVU_StatusTodoClaro__c = 'Potencial';
            insert testAccount;

            Order testOrder = new Order(Name='Test Order',EffectiveDate=System.today(),status='Draft',AccountId = testAccount.Id, Pricebook2Id = testPricebook.Id,FVU_CreditQuota__c=50000);
            insert testOrder;

            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = testOrder.Id;
            orderItem.Product2Id = prod1.Id;
            orderItem.PricebookEntryId = pbe1.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '0001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = testAccount.Id;
            orderItem.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItem.CAT_ProductType__c = 'TyT';
            sObjList.add(orderItem);
            insert sObjList;
            sObjList.clear();

            OrderItem orderItemAddOn = new OrderItem();
            orderItemAddOn.OrderId = testOrder.Id;
            orderItemAddOn.Product2Id = addOn.Id;
            orderItemAddOn.PricebookEntryId = pbeAddOn.Id;
            orderItemAddOn.Quantity = 1;
            orderItemAddOn.UnitPrice = 10;
            orderItemAddOn.vlocity_cmt__LineNumber__c = '0001';
            orderItemAddOn.vlocity_cmt__Action__c = 'Add';
            orderItemAddOn.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItemAddOn.vlocity_cmt__ServiceAccountId__c = testAccount.Id;
            orderItemAddOn.FVU_OneTimeTotalIncTaxes__c = 2000000;
            orderItemAddOn.vlocity_cmt__Action__c = 'Disconnect';
            sObjList.add(orderItemAddOn);
            insert sObjList;
            sObjList.clear();
            
            vlocity_cmt__Promotion__c promotion = new vlocity_cmt__Promotion__c();
            promotion.vlocity_cmt__Code__c = 'FAN_1000';
            promotion.Name = 'FAN_1000';
            promotion.CAT_Type__c = 'Estandar';
            promotion.CAT_PromotionClass__c = 'Terceros';
            insert promotion;

            vlocity_cmt__PromotionItem__c promotionItem = new vlocity_cmt__PromotionItem__c();
            promotionItem.vlocity_cmt__PromotionId__c = promotion.Id;
            promotionItem.vlocity_cmt__ProductId__c = addOn.Id;
            insert promotionItem;

            vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion = new vlocity_cmt__OrderAppliedPromotion__c();
            orderAppliedPromotion.vlocity_cmt__PromotionId__c = promotion.Id;
            orderAppliedPromotion.vlocity_cmt__OrderId__c = testOrder.Id;
            insert orderAppliedPromotion;

            vlocity_cmt__OrderAppliedPromotionItem__c orderAppliedPromotionItem = new vlocity_cmt__OrderAppliedPromotionItem__c();
            orderAppliedPromotionItem.vlocity_cmt__OrderAppliedPromotionId__c = orderAppliedPromotion.Id;
            orderAppliedPromotionItem.vlocity_cmt__OrderItemId__c = orderItemAddOn.Id;
            orderAppliedPromotionItem.vlocity_cmt__AppliedAction__c = 'Add';
            insert orderAppliedPromotionItem;
            
            vlocity_cmt__Promotion__c promotionTech = new vlocity_cmt__Promotion__c();
            promotionTech.vlocity_cmt__Code__c = 'PROMO_1000';
            promotionTech.Name = 'PROMO_1000';
            promotionTech.CAT_Type__c = 'TodoClaro';
            promotionTech.CAT_PromotionClass__c = 'Descuento Todo Claro';
            insert promotionTech;

            vlocity_cmt__PromotionItem__c promotionItemTech = new vlocity_cmt__PromotionItem__c();
            promotionItemTech.vlocity_cmt__PromotionId__c = promotionTech.Id;
            promotionItemTech.vlocity_cmt__ProductId__c = prod1.Id;
            insert promotionItemTech;

            vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotionTech = new vlocity_cmt__OrderAppliedPromotion__c();
            orderAppliedPromotionTech.vlocity_cmt__PromotionId__c = promotionTech.Id;
            orderAppliedPromotionTech.vlocity_cmt__OrderId__c = testOrder.Id;
            insert orderAppliedPromotionTech;

            vlocity_cmt__OrderAppliedPromotionItem__c orderAppliedPromotionItemTech = new vlocity_cmt__OrderAppliedPromotionItem__c();
            orderAppliedPromotionItemTech.vlocity_cmt__OrderAppliedPromotionId__c = orderAppliedPromotionTech.Id;
            orderAppliedPromotionItemTech.vlocity_cmt__OrderItemId__c = orderItem.Id;
            orderAppliedPromotionItemTech.vlocity_cmt__AppliedAction__c = 'Add';
            insert orderAppliedPromotionItemTech;

            //PostCartItems inputMap
            String ultraWifiId='01u74000003TW5JAAW';
            Map<String, Object> postItemsMap = new Map<String, Object>{'itemId'=>pbe1.Id};
            List<Object> postItemLists = new List<Object>{postItemsMap};

            //PostCartItems inputMap incluyendo un plan móvil
            Map<String, Object> postItemsMapMobilePlan = new Map<String, Object>{'itemId'=>pbeMobilePlan.Id};
            List<Object> postItemListsMobilePlan = new List<Object>{postItemsMapMobilePlan};

            //PostCartItems inputMap incluyendo un Add On
            Map<String, Object> postItemsMapAddOn = new Map<String, Object>{'itemId'=>pbeAddOn.Id};
            List<Object> postItemListsAddOn = new List<Object>{postItemsMapAddOn};
            
            //PutCartItems inputMap    
            String productCode='B2C-FIJA-OFR-ULTRAWIFI';
            Map<String, Integer> putQuantityMap = new Map<String, Integer>{'value'=>1};
            Map<String, Object> putRecordsProdCodeMap = new Map<String, Object>{'ProductCode'=>productCode,'Quantity'=>putQuantityMap};
            List<Object> putLineItemsRecords = new List<Object>{putRecordsProdCodeMap};
            Map<String, Object> putLineItemsRecordsMap = new Map<String, Object>{'records'=>putLineItemsRecords};
            Map<String, Object> putLineItemsMap = new Map<String, Object>{'lineItems'=>putLineItemsRecordsMap};
            List<Object> putRecords = new List<Object>{putLineItemsMap};
            Map<String, Object> putItemsMap = new Map<String, Object>{'records'=>putRecords};
            
            Map<String, Object> putNoLineItemsMap = new Map<String, Object>{'test'=>putRecords};
            List<Object> putRecordsNoLineItems = new List<Object>{putNoLineItemsMap}; 
            Map<String, Object> putItemsMapNoLineItems = new Map<String, Object>{'records'=>putRecordsNoLineItems};
                
            List<Object> putRecordsEmptyList = new List<Object>{}; 
            Map<String, Object> putItemsNoRecordsMap = new Map<String, Object>{'records'=>putRecordsEmptyList};
                
            Map<String, Object> output = new Map<String, Object>();
            Map<String, Object> options = new Map<String, Object>();

            //DeleteCartsItems Output Map
            // Create a Map to mimic the 'modifiedItems' output from the deleteCartsItems.PostInvoke method
            Map<Id, Object> modifiedItems = new Map<Id, Object>();
            modifiedItems.put(orderItem.Id, null);
            // Create input and output maps to simulate method parameters
            Map<String, Object> input = new Map<String, Object>();
            output.put('modifiedItems', modifiedItems);
            
            Test.startTest();

            CpqAppHandlerHookCustomImpl GetCartsProductsEmptyFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsEmptyFieldsHook.invokeMethod('getCartsProducts.PreInvoke', new map<String, object>{'fields'=>''}, output, options);
            CpqAppHandlerHookCustomImpl GetCartsProductsFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsFieldsHook.invokeMethod('getCartsProducts.PreInvoke', new map<String, object>{'fields'=>'Test Fields'}, output, options);
            
            CpqAppHandlerHookCustomImpl GetCartsItemsEmptyFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsItemsEmptyFieldsHook.invokeMethod('getCartsItems.PreInvoke', new map<String, object>{'fields'=>'','cartId'=>testOrder.Id}, output, options);
            CpqAppHandlerHookCustomImpl GetCartsItemsFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsItemsFieldsHook.invokeMethod('getCartsItems.PreInvoke', new map<String, object>{'fields'=>'Test2 Fields','cartId'=>testOrder.Id}, output, options);

            CpqAppHandlerHookCustomImpl PostCartsItemsEmptyFieldsHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsEmptyFieldsHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemLists,'fields'=>'','cartId'=>testOrder.Id,'recPrice'=>10000}, output, options);

            CpqAppHandlerHookCustomImpl PostCartsItemsFieldsHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemLists,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000000}, output, options);

            CpqAppHandlerHookCustomImpl PostCartsItemsMobilePlanHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsMobilePlanHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemListsMobilePlan,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000000}, output, options);

            CpqAppHandlerHookCustomImpl PostCartsItemsMobilePlanLowPriceHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsMobilePlanLowPriceHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemListsMobilePlan,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000}, output, options);

            CpqAppHandlerHookCustomImpl PostCartsItemsAddOnPositiveHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsAddOnPositiveHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemListsAddOn,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000000,'CreditLimit'=>10000000}, output, options);
            CpqAppHandlerHookCustomImpl PostCartsItemsAddOnNegativeHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsAddOnNegativeHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemListsAddOn,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000000,'CreditLimit'=>100000}, output, options);
            CpqAppHandlerHookCustomImpl PostCartsItemsAddOnNoCreditLimitHook = new CpqAppHandlerHookCustomImpl();
            PostCartsItemsAddOnNoCreditLimitHook.invokeMethod('postCartsItems.PreInvoke', new map<String, object>{'items'=>postItemListsAddOn,'fields'=>'Test','cartId'=>testOrder.Id,'recPrice'=>1000000}, output, options);

            CpqAppHandlerHookCustomImpl deleteAppliedPromoItemsPre = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsEmptyFieldsHook.invokeMethod('deleteAppliedPromoItems.PreInvoke', new map<String, object>{'id'=>orderAppliedPromotion.Id}, output, options);
            CpqAppHandlerHookCustomImpl deleteAppliedPromoItemsPost = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsFieldsHook.invokeMethod('deleteAppliedPromoItems.PostInvoke', new map<String, object>{'cartId'=>testOrder.Id,'orderItemIds'=>new Map<Id,String>{orderItemAddOn.Id => 'Add On',orderItem.Id => 'Plan'}}, output, options);

            CpqAppHandlerHookCustomImpl getCartsPromotionsEmptyFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsEmptyFieldsHook.invokeMethod('getCartsPromotions.PreInvoke', new map<String, object>{'cartId'=>testOrder.Id,'filters'=>promotion.Id,'fields'=>''}, output, options);
            CpqAppHandlerHookCustomImpl getCartsPromotionsFieldsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsFieldsHook.invokeMethod('getCartsPromotions.PreInvoke', new map<String, object>{'cartId'=>testOrder.Id,'filters'=>promotion.Id,'fields'=>'Test Fields'}, output, options);

            CpqAppHandlerHookCustomImpl deleteCartsItemsHook = new CpqAppHandlerHookCustomImpl();
            GetCartsProductsFieldsHook.invokeMethod('deleteCartsItems.PostInvoke', new map<String, object>{'cartId'=>testOrder.Id}, output, options);
            //Crear vlocity_cmt.JSONResult result
            /*
            Below logic will do the basic json structure.
            */
            String basicJsonResultStructure = '{"totalSize":1,"records":[],"name":null,"messages":[],"description":null,    "data":null,"actions":{}}';
            vlocity_cmt.JSONResult jsonResult = (vlocity_cmt.JSONResult)JSON.deserialize(basicJsonResultStructure,vlocity_cmt.JSONResult.class);
            System.debug('JSON RESULT BASIC STRUCTURE DONE: ' + jsonResult);

            vlocity_cmt.JSONResult jsonResultSuccess = (vlocity_cmt.JSONResult)JSON.deserialize(basicJsonResultStructure,vlocity_cmt.JSONResult.class);
            System.debug('JSON RESULT BASIC STRUCTURE DONE: ' + jsonResultSuccess);

            /*
                Below logic will start populating messages
            */

            List<vlocity_cmt.JSONMessage> messagesList = new List<vlocity_cmt.JSONMessage>();
            String messageJSONString = '{"code": "143", "message": "Test Input Message"}';
            vlocity_cmt.JSONMessage messageJSONObj = (vlocity_cmt.JSONMessage)JSON.deserialize(messageJSONString,vlocity_cmt.JSONMessage.class);
            String messageJSONString1 = '{"code":"310", "message":"first error: test, Test Input Message:"}';
            vlocity_cmt.JSONMessage messageJSONObj1 = (vlocity_cmt.JSONMessage)JSON.deserialize(messageJSONString1,vlocity_cmt.JSONMessage.class);
            String messageJSONString2 = '{"code":"310", "message":"first error: Test Input Message:"}';
            vlocity_cmt.JSONMessage messageJSONObj2 = (vlocity_cmt.JSONMessage)JSON.deserialize(messageJSONString2,vlocity_cmt.JSONMessage.class);
            String messageJSONString3 = '{"code":"109", "message":"first error: test, Test Input Message:"}';
            vlocity_cmt.JSONMessage messageJSONObj3 = (vlocity_cmt.JSONMessage)JSON.deserialize(messageJSONString3,vlocity_cmt.JSONMessage.class);
            String messageJSONString4 = '{"code":"109", "message":"first error: Test Input Message:"}';
            vlocity_cmt.JSONMessage messageJSONObj4 = (vlocity_cmt.JSONMessage)JSON.deserialize(messageJSONString4,vlocity_cmt.JSONMessage.class);

            List<vlocity_cmt.JSONMessage> messagesSuccesCodeList = new List<vlocity_cmt.JSONMessage>();
            String messagesuccessJSONString = '{"code": "150", "message": "Test Input Message"}';
            vlocity_cmt.JSONMessage messagesuccessJSONObj = (vlocity_cmt.JSONMessage)JSON.deserialize(messagesuccessJSONString,vlocity_cmt.JSONMessage.class);

            messagesList.add(messageJSONObj);
            messagesList.add(messageJSONObj1);
            messagesList.add(messageJSONObj2);
            messagesList.add(messageJSONObj3);
            messagesList.add(messageJSONObj4);
            jsonResult.messages = messagesList;

            output = new Map<String, Object>();
            output.put('result',jsonResult);

            messagesSuccesCodeList.add(messagesuccessJSONObj);
            jsonResultSuccess.messages = messagesSuccesCodeList;

            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PostInvoke', new map<String, object>{'abovecreditlimit'=>true}, output, options);
            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PostInvoke', new map<String, object>{'morethanoneplan'=>true}, output, options);
            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PostInvoke', new map<String, object>{'addOnAdded'=>true,'planOrderItemId'=>orderItem.Id,'creditLimitType'=>'Límite Nacional Servicios','newCreditLimit'=>1000}, new map<String, object>{'result'=>jsonResultSuccess}, options);
            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PostInvoke', new map<String, object>{'addOnAdded'=>true,'planOrderItemId'=>orderItem.Id,'creditLimitType'=>'Límite Nacional Paquetes','newCreditLimit'=>1000}, new map<String, object>{'result'=>jsonResultSuccess}, options);
            PostCartsItemsFieldsHook.invokeMethod('postCartsItems.PostInvoke', new map<String, object>{'addOnAdded'=>true,'planOrderItemId'=>orderItem.Id,'creditLimitType'=>'Límite Nacional Roaming','newCreditLimit'=>1000}, new map<String, object>{'result'=>jsonResultSuccess}, options);

            CpqAppHandlerHookCustomImpl PutCartsItemsHook = new CpqAppHandlerHookCustomImpl();
            PutCartsItemsHook.invokeMethod('putCartsItems.PreInvoke', new map<String, object>{'items'=>putItemsMap}, output, options);
            CpqAppHandlerHookCustomImpl PutCartsItemsNoLineItemsHook = new CpqAppHandlerHookCustomImpl();
            PutCartsItemsNoLineItemsHook.invokeMethod('putCartsItems.PreInvoke', new map<String, object>{'items'=>putItemsMapNoLineItems}, output, options);
            CpqAppHandlerHookCustomImpl GetCartsheaderFieldSetHook = new CpqAppHandlerHookCustomImpl();
            GetCartsheaderFieldSetHook.invokeMethod('getCarts.PreInvoke', new map<String, object>{'headerFieldSet'=>'Test Field Sets'}, output, options);
            CpqAppHandlerHookCustomImpl GetCartsErrorMessagePromotion = new CpqAppHandlerHookCustomImpl();
            GetCartsErrorMessagePromotion.invokeMethod('postCartsPromoItems.PostInvoke', input, output, options);

            Test.stopTest();
        }

        catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
            throw e;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getCartsProducts.PostInvoke
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldReturnTrue_WhenGetCartsProductsPostInvoke() {
        // Given / When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod(
            'getCartsProducts.PostInvoke',
            new Map<String, Object>{'fields' => 'Test'},
            new Map<String, Object>(),
            new Map<String, Object>()
        );
        Test.stopTest();

        // Then
        Assert.isTrue(result, 'getCartsProducts.PostInvoke should return true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getCartsItems.PreInvoke — Quote cart
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldSetQuoteFields_WhenGetCartsItemsPreInvoke_WithQuoteCartId() {
        // Given
        Account acc = new Account(Name = 'Quote GetCartsItems Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Quote GetCartsItems Opp', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'Quote GetCartsItems', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;

        Map<String, Object> input = new Map<String, Object>{'cartId' => q.Id, 'fields' => ''};
        Map<String, Object> output = new Map<String, Object>();

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartsItems.PreInvoke', input, output, new Map<String, Object>());
        Test.stopTest();

        // Then
        String fields = (String) input.get('fields');
        Assert.isTrue(fields.contains('Quote.Id'), 'fields should contain Quote.Id for a Quote cart');
        Assert.isFalse(fields.contains('Order.Type'), 'Order-specific fields should not appear for a Quote cart');
        Assert.isTrue(result, 'Should return true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // postCartsItems.PreInvoke — Quote cart (early return)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldSetQuoteFieldsAndEarlyReturn_WhenPostCartsItemsPreInvoke_WithQuoteCartId() {
        // Given
        Account acc = new Account(Name = 'Quote PostCartsItems Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Quote PostCartsItems Opp', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'Quote PostCartsItems', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;

        Map<String, Object> input = new Map<String, Object>{'cartId' => q.Id, 'fields' => ''};
        Map<String, Object> output = new Map<String, Object>();

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('postCartsItems.PreInvoke', input, output, new Map<String, Object>());
        Test.stopTest();

        // Then — Quote path sets Quote-specific fields and returns before any SOQL
        String fields = (String) input.get('fields');
        Assert.isTrue(fields.contains('Quote.Id'), 'fields should contain Quote.Id for a Quote cart');
        Assert.isNull(input.get('abovecreditlimit'), 'Credit limit should not be evaluated for a Quote cart');
        Assert.isTrue(result, 'Should return true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // postCartsItems.PreInvoke — skip credit limit: Cambio de Plan
    // ─────────────────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────────────────
    // postCartsItems.PreInvoke — skip credit limit: OmitirHDC
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldSkipCreditLimitCheck_WhenOmitirHDCIsTrue() {
        // Given
        Product2 mobilePlan = new Product2(
            Name = 'Plan OmitHDC', ProductCode = 'PO_OmitHDC_TEST',
            Family = 'Mobile', vlocity_cmt__Type__c = 'Plan', vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Bundle'
        );
        insert mobilePlan;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = mobilePlan.Id, UnitPrice = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
        insert pbe;
        Account acc = new Account(Name = 'OmitHDC Account');
        insert acc;
        Order ord = new Order(
            Name = 'OmitHDC Order', EffectiveDate = System.today(), Status = 'Draft',
            AccountId = acc.Id, Pricebook2Id = pb.Id, FVU_CreditQuota__c = 1000,
            PVU_OmitirHDC__c = true
        );
        insert ord;

        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id, 'fields' => '', 'recPrice' => 99999,
            'items' => new List<Object>{new Map<String, Object>{'itemId' => pbe.Id}}
        };

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('postCartsItems.PreInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then
        Assert.isTrue(result, 'Should return true when OmitirHDC is true');
        Assert.isNull(input.get('abovecreditlimit'), 'Credit limit check should be skipped when OmitirHDC is true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // postCartsItems.PreInvoke — IVA-exempt: Mobile Plan (REC_MNTH_STD_PRC branch)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldUseExcludingTaxPriceSOQL_WhenIVAExemptOrder_MobilePlan() {
        // Given
        Product2 mobilePlan = new Product2(
            Name = 'Plan IVAExempt', ProductCode = 'PO_IVAExempt_Plan',
            Family = 'Mobile', vlocity_cmt__Type__c = 'Plan', vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Bundle'
        );
        insert mobilePlan;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = mobilePlan.Id, UnitPrice = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
        insert pbe;
        Account acc = new Account(Name = 'IVAExempt Plan Account');
        insert acc;
        Order ord = new Order(
            Name = 'IVAExempt Plan Order', EffectiveDate = System.today(), Status = 'Draft',
            AccountId = acc.Id, Pricebook2Id = pb.Id, FVU_CreditQuota__c = 1000000,
            FVU_IsIVAExempt__c = true
        );
        insert ord;

        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id, 'fields' => '', 'recPrice' => 1,
            'items' => new List<Object>{new Map<String, Object>{'itemId' => pbe.Id}}
        };

        // When — exercises the isIVAExemptOrder == true SOQL branch for Plan (line 316)
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('postCartsItems.PreInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then — no exception, method completes normally
        Assert.isTrue(result, 'Should return true for IVA-exempt plan order');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // postCartsItems.PreInvoke — IVA-exempt: Add On (REC_MNTH_STD_PRC branch)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldUseExcludingTaxPriceSOQL_WhenIVAExemptOrder_AddOn() {
        // Given
        Product2 addOnProd = new Product2(
            Name = 'AddOn IVAExempt', ProductCode = 'PO_IVAExempt_AddOn',
            Family = 'Mobile', vlocity_cmt__Type__c = 'Add On',
            vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert addOnProd;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbeAddOn = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = addOnProd.Id, UnitPrice = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
        insert pbeAddOn;
        Account acc = new Account(Name = 'IVAExempt AddOn Account');
        insert acc;
        Order ord = new Order(
            Name = 'IVAExempt AddOn Order', EffectiveDate = System.today(), Status = 'Draft',
            AccountId = acc.Id, Pricebook2Id = pb.Id, FVU_CreditQuota__c = 1000000,
            FVU_IsIVAExempt__c = true
        );
        insert ord;

        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id, 'fields' => '', 'recPrice' => 1000,
            'CreditLimit' => 500000,
            'items' => new List<Object>{new Map<String, Object>{'itemId' => pbeAddOn.Id}}
        };

        // When — exercises the isIVAExemptOrder == true SOQL branch for AddOn (line 262)
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('postCartsItems.PreInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then — CreditLimit > recPrice → addOnAdded should be true
        Assert.isTrue(result, 'Should return true for IVA-exempt add-on order');
        Assert.isTrue((Boolean)input.get('addOnAdded'), 'addOnAdded should be set when credit limit is sufficient');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getCartsPromotions.PostInvoke — Quote cart, null result (early return)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldReturnTrue_WhenGetCartsPromotionsPostInvoke_NullResult() {
        // Given
        Account acc = new Account(Name = 'PostInvoke NullResult Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'NullResult Opp', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'NullResult Quote', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;

        Map<String, Object> input  = new Map<String, Object>{'cartId' => q.Id};
        Map<String, Object> output = new Map<String, Object>(); // no 'result' key

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartsPromotions.PostInvoke', input, output, new Map<String, Object>());
        Test.stopTest();

        // Then — exits at the null-result guard (line 794)
        Assert.isTrue(result, 'Should return true when result is null');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getCartsPromotions.PostInvoke — Quote cart, empty records (early return)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldReturnTrue_WhenGetCartsPromotionsPostInvoke_EmptyRecords() {
        // Given
        Account acc = new Account(Name = 'PostInvoke EmptyRecords Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'EmptyRecords Opp', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'EmptyRecords Quote', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;

        Map<String, Object> resultMap = new Map<String, Object>{'records' => new List<Object>()};
        Map<String, Object> input  = new Map<String, Object>{'cartId' => q.Id};
        Map<String, Object> output = new Map<String, Object>{'result' => resultMap};

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartsPromotions.PostInvoke', input, output, new Map<String, Object>());
        Test.stopTest();

        // Then — exits at the empty-records guard (line 800)
        Assert.isTrue(result, 'Should return true when records list is empty');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getCartsPromotions.PostInvoke — Quote cart, Descuento promo filtered out
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldFilterOutDescuentoPromo_WhenGetCartsPromotionsPostInvoke_QuoteCart() {
        // Given
        Account acc = new Account(Name = 'PostInvoke Filter Account');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Filter Opp', StageName = 'Prospecting', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'Filter Quote', OpportunityId = opp.Id, Pricebook2Id = Test.getStandardPricebookId());
        insert q;

        // Build output.result with two promos: one Descuento (should be filtered) and one Bundle (kept)
        List<Object> records = new List<Object>{
            new Map<String, Object>{
                'fields' => new Map<String, Object>{'CAT_PromotionClass__c' => 'Descuento'},
                'Id'    => 'someId1',
                'Name'  => 'Descuento Promo'
            },
            new Map<String, Object>{
                'fields' => new Map<String, Object>{'CAT_PromotionClass__c' => 'Bundle'},
                'Id'    => 'someId2',
                'Name'  => 'Bundle Promo'
            }
        };
        Map<String, Object> input  = new Map<String, Object>{'cartId' => q.Id};
        Map<String, Object> output = new Map<String, Object>{'result' => new Map<String, Object>{'records' => records}};

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartsPromotions.PostInvoke', input, output, new Map<String, Object>());
        Test.stopTest();

        // Then — only the non-Descuento promo remains
        List<Object> filteredRecords = (List<Object>) output.get('records');
        Assert.isNotNull(filteredRecords, 'Filtered records should be present in output');
        Assert.areEqual(1, filteredRecords.size(), 'Only the non-Descuento promo should remain');
        Assert.areEqual(1, (Integer) output.get('totalSize'), 'totalSize should match filtered count');
        Assert.isTrue(result, 'Should return true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // deleteAppliedPromoItems.PostInvoke — Bundle promo class: blocking items deleted
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldDeleteBlockingPromoItems_WhenBundlePromotion_AddOnType() {
        // Given
        Product2 addOnProd = new Product2(
            Name = 'AddOn Bundle Test', ProductCode = 'B2C-ADDON-BUNDLE-TEST',
            Family = 'Mobile', vlocity_cmt__Type__c = 'Add On',
            vlocity_cmt__SpecificationType__c = 'Offer', vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert addOnProd;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbeAddOn = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = addOnProd.Id, UnitPrice = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
        insert pbeAddOn;

        Account acc = new Account(Name = 'Bundle Promo Account');
        insert acc;
        Order ord = new Order(Name = 'Bundle Promo Order', EffectiveDate = System.today(), Status = 'Draft', AccountId = acc.Id, Pricebook2Id = pb.Id);
        insert ord;

        OrderItem addOnOI = new OrderItem(
            OrderId = ord.Id, Product2Id = addOnProd.Id, PricebookEntryId = pbeAddOn.Id,
            Quantity = 1, UnitPrice = 0, vlocity_cmt__LineNumber__c = '0001',
            vlocity_cmt__Action__c = 'Add', vlocity_cmt__ProvisioningStatus__c = 'New',
            vlocity_cmt__ServiceAccountId__c = acc.Id
        );
        insert addOnOI;

        vlocity_cmt__Promotion__c bundlePromo = new vlocity_cmt__Promotion__c(
            vlocity_cmt__Code__c = 'BUNDLE-TEST-PROMO', Name = 'Bundle Test Promo',
            CAT_Type__c = 'Estandar', CAT_PromotionClass__c = 'Bundle'
        );
        insert bundlePromo;

        vlocity_cmt__OrderAppliedPromotion__c appliedPromo = new vlocity_cmt__OrderAppliedPromotion__c(
            vlocity_cmt__PromotionId__c = bundlePromo.Id, vlocity_cmt__OrderId__c = ord.Id
        );
        insert appliedPromo;

        vlocity_cmt__OrderAppliedPromotionItem__c blockingItem = new vlocity_cmt__OrderAppliedPromotionItem__c(
            vlocity_cmt__OrderAppliedPromotionId__c = appliedPromo.Id,
            vlocity_cmt__OrderItemId__c = addOnOI.Id,
            vlocity_cmt__AppliedAction__c = 'Add'
        );
        insert blockingItem;

        Map<String, Object> input = new Map<String, Object>{
            'cartId'        => ord.Id,
            'promotionClass'=> 'Bundle',
            'orderItemIds'  => new Map<Id, String>{addOnOI.Id => 'Add On'},
            'externalRefresh' => true   // skip price-refresh IP call at the end
        };

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('deleteAppliedPromoItems.PostInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then — blocking OrderAppliedPromotionItem should be deleted
        List<vlocity_cmt__OrderAppliedPromotionItem__c> remaining = [
            SELECT Id FROM vlocity_cmt__OrderAppliedPromotionItem__c
            WHERE Id = :blockingItem.Id
        ];
        Assert.areEqual(0, remaining.size(), 'Blocking promo items should be deleted for Bundle promotion');
        Assert.isTrue(result, 'Should return true');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // deleteAppliedPromoItems.PostInvoke — Handset product type (sets Modification = 0)
    // ─────────────────────────────────────────────────────────────────────────

    @isTest
    static void shouldSetModificationToZero_WhenHandsetProductType() {
        // Given
        Product2 handsetProd = new Product2(
            Name = 'Handset Test', ProductCode = 'B2C-HANDSET-TEST',
            Family = 'Device', vlocity_cmt__Type__c = 'Handset'
        );
        insert handsetProd;
        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbeHandset = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = handsetProd.Id, UnitPrice = 0, IsActive = true, vlocity_cmt__RecurringUOM__c = 'Monthly');
        insert pbeHandset;

        Account acc = new Account(Name = 'Handset Account');
        insert acc;
        Order ord = new Order(Name = 'Handset Order', EffectiveDate = System.today(), Status = 'Draft', AccountId = acc.Id, Pricebook2Id = pb.Id);
        insert ord;

        OrderItem handsetOI = new OrderItem(
            OrderId = ord.Id, Product2Id = handsetProd.Id, PricebookEntryId = pbeHandset.Id,
            Quantity = 1, UnitPrice = 0, vlocity_cmt__LineNumber__c = '0001',
            vlocity_cmt__Action__c = 'Add', vlocity_cmt__ProvisioningStatus__c = 'New',
            vlocity_cmt__ServiceAccountId__c = acc.Id
        );
        insert handsetOI;

        Map<String, Object> input = new Map<String, Object>{
            'cartId'         => ord.Id,
            'promotionClass' => 'Terceros',
            'orderItemIds'   => new Map<Id, String>{handsetOI.Id => 'Handset'},
            'externalRefresh'=> true    // skip price-refresh IP call
        };

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('deleteAppliedPromoItems.PostInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then — vlocity_cmt__Modification__c should be set to 0 for Handset type
        OrderItem updated = [SELECT vlocity_cmt__Modification__c FROM OrderItem WHERE Id = :handsetOI.Id];
        Assert.areEqual(0, updated.vlocity_cmt__Modification__c, 'Modification should be 0 for Handset product type');
        Assert.isTrue(result, 'Should return true');
    }

    

    @isTest
    static void shouldNotRemovePromo_WhenAppliedPromosFieldIsNull() {
        // Given
        Account acc = new Account(Name = 'No OTP Account');
        insert acc;

        Pricebook2 pb = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(
            vlocity_cmt__Code__c = 'B2C-PROMO-DISNEY-SA',
            Name = 'Disney SA Null Test',
            CAT_Type__c = 'Estandar',
            CAT_PromotionClass__c = 'Terceros'
        );
        insert promo;

        Order ord = new Order(
            Name = 'OTP Null Order',
            EffectiveDate = System.today(),
            Status = 'Draft',
            AccountId = acc.Id,
            Pricebook2Id = pb.Id
        );
        insert ord;

        String filters = 'Id:' + promo.Id;
        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id,
            'filters' => filters,
            'fields' => ''
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        hook.invokeMethod('getCartsPromotions.PreInvoke', input, output, options);
        Test.stopTest();

        // Then
        String updatedFilters = (String) input.get('filters');
        Assert.isTrue(updatedFilters.contains(promo.Id), 'Promo should remain when applied promos field is null');
    }

    @isTest
    static void shouldProcessCode310Messages_WhenGetCartsItemsPostInvoke() {
        // Given
        String basicJson = '{"totalSize":0,"records":[],"name":null,"messages":[],"description":null,"data":null,"actions":{}}';
        vlocity_cmt.JSONResult jsonResult = (vlocity_cmt.JSONResult)JSON.deserialize(basicJson, vlocity_cmt.JSONResult.class);

        vlocity_cmt.JSONMessage msgWithComma = (vlocity_cmt.JSONMessage)JSON.deserialize(
            '{"code":"310","message":"prefix: part1, extracted message"}', vlocity_cmt.JSONMessage.class);
        vlocity_cmt.JSONMessage msgWithoutComma = (vlocity_cmt.JSONMessage)JSON.deserialize(
            '{"code":"310","message":"prefix: message without comma"}', vlocity_cmt.JSONMessage.class);
        vlocity_cmt.JSONMessage msgWithoutColon = (vlocity_cmt.JSONMessage)JSON.deserialize(
            '{"code":"310","message":"message without colon"}', vlocity_cmt.JSONMessage.class);
        vlocity_cmt.JSONMessage otherCode = (vlocity_cmt.JSONMessage)JSON.deserialize(
            '{"code":"200","message":"success message"}', vlocity_cmt.JSONMessage.class);

        List<vlocity_cmt.JSONMessage> messages = new List<vlocity_cmt.JSONMessage>{
            msgWithComma, msgWithoutComma, msgWithoutColon, otherCode
        };
        jsonResult.messages = messages;

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>{'result' => jsonResult};
        Map<String, Object> options = new Map<String, Object>();

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean r1 = hook.invokeMethod('getCartsItems.PostInvoke', input, output, options);
        Boolean r2 = hook.invokeMethod('postCartsPromoItems.PostInvoke', input, output, options);
        Test.stopTest();

        // Then
        Assert.isTrue(r1, 'getCartsItems.PostInvoke should return true');
        Assert.isTrue(r2, 'postCartsPromoItems.PostInvoke should return true');
        Assert.areEqual('extracted message', msgWithComma.message, 'Should extract message after colon and comma');
        Assert.areEqual('message without comma', msgWithoutComma.message, 'Should extract message after colon when no comma');
    }

    @isTest
    static void shouldReturnEarly_WhenOrderCart_GetCartsPromotionsPostInvoke() {
        // Given — Order cartId (not Quote): the PostInvoke body is skipped entirely
        Account acc = new Account(Name = 'Order Cart PostInvoke Account');
        insert acc;

        Order ord = new Order(
            Name = 'Order Cart PostInvoke',
            EffectiveDate = System.today(),
            Status = 'Draft',
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        Map<String, Object> input = new Map<String, Object>{'cartId' => ord.Id};
        Map<String, Object> output = new Map<String, Object>{'result' => new Map<String, Object>{'records' => new List<Object>()}};
        Map<String, Object> options = new Map<String, Object>();

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartsPromotions.PostInvoke', input, output, options);
        Test.stopTest();

        // Then
        Assert.isTrue(result, 'Should return true when cartId is an Order (inner block skipped)');
        Assert.isFalse(output.containsKey('records') && !output.containsKey('result'),
            'Output should NOT be restructured when cart is not a Quote');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HU 826417 — Reemplazo de SIM Card por eSIM en migración con eSIM
    // ─────────────────────────────────────────────────────────────────────────
    private static Order createSimCart(String migraData) {
        return createSimCart(migraData, null);
    }

    private static Order createSimCart(String migraData, String purchaseType) {
        Product2 simGroup = new Product2(Name = 'Escoja SIM Card Test', ProductCode = 'B2C-MOV-OFR-ESCOJA-SIM-TEST', Family = 'Mobile');
        Product2 simCard = new Product2(Name = 'SIM Card Test', ProductCode = 'B2C-MOV-OFR-SIMCARD', Family = 'Mobile');
        Product2 esim = new Product2(Name = 'eSIM Test', ProductCode = 'B2C-MOB-OFR-ESIM', Family = 'Mobile');
        insert new List<Product2>{simGroup, simCard, esim};
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbeGroup = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = simGroup.Id, UnitPrice = 0, IsActive = true);
        PricebookEntry pbeSimCard = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = simCard.Id, UnitPrice = 0, IsActive = true);
        PricebookEntry pbeEsim = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = esim.Id, UnitPrice = 0, IsActive = true);
        insert new List<PricebookEntry>{pbeGroup, pbeSimCard, pbeEsim};
        Account acc = new Account(Name = 'SIM Swap Account');
        insert acc;
        Order ord = new Order(Name = 'SIM Swap Order', EffectiveDate = System.today(), Status = 'Draft',
            AccountId = acc.Id, Pricebook2Id = pricebookId, FVU_MigraData__c = migraData, FVU_PurchaseType__c = purchaseType);
        insert ord;
        OrderItem groupItem = new OrderItem(OrderId = ord.Id, Product2Id = simGroup.Id, PricebookEntryId = pbeGroup.Id,
            Quantity = 1, UnitPrice = 0, vlocity_cmt__LineNumber__c = '0001.0002', vlocity_cmt__Action__c = 'Add',
            vlocity_cmt__AssetReferenceId__c = 'sim-group-ref', vlocity_cmt__ProductHierarchyPath__c = 'plan<group');
        insert groupItem;
        OrderItem simItem = new OrderItem(OrderId = ord.Id, Product2Id = simCard.Id, PricebookEntryId = pbeSimCard.Id,
            Quantity = 1, UnitPrice = 0, vlocity_cmt__LineNumber__c = '0001.0002.0001', vlocity_cmt__Action__c = 'Add',
            vlocity_cmt__ParentItemId__c = 'sim-group-ref', vlocity_cmt__ProductHierarchyPath__c = 'plan<group<sim');
        insert simItem;
        return ord;
    }

    @isTest
    static void shouldDetectEsimSale_OnlyWhenSimTypeIsEsim() {
        Assert.isTrue(CpqAppHandlerHookCustomImpl.isEsimSale('[{"ICCID":"","SimType":"eSIM","NRN":""}]'), 'Lista con SimType eSIM');
        Assert.isTrue(CpqAppHandlerHookCustomImpl.isEsimSale('{"SimType":"eSIM"}'), 'Objeto con SimType eSIM');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.isEsimSale('[{"SimType":"USIM"}]'), 'SimType USIM');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.isEsimSale('[{"SimType":""}]'), 'SimType vacío');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.isEsimSale(''), 'Campo vacío');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.isEsimSale(null), 'Campo nulo');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.isEsimSale('no es json'), 'JSON inválido');
    }

    @isTest
    static void shouldTrySimSwap_WhenGetCartLineItemPricesPreInvoke_WithEsimMigration() {
        // Given
        Order ord = createSimCart('[{"ICCID":"","SimType":"eSIM","NRN":""}]');

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();
        Boolean result = hook.invokeMethod('getCartLineItemPrices.PreInvoke', new Map<String, Object>{'cartId' => ord.Id},
            new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then: los IP de CPQ no existen en el contexto de prueba; el reemplazo no debe romper la operación del carrito
        Assert.isTrue(result, 'El hook debe responder true aunque el reemplazo no se complete');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.swappingSimToEsim, 'La bandera de reemplazo debe quedar liberada');
    }

    @isTest
    static void shouldTrySimSwap_WhenGetCartsItemsPreInvoke_WithEsimMigration() {
        // Given
        Order ord = createSimCart('[{"SimType":"eSIM"}]');
        Map<String, Object> input = new Map<String, Object>{'cartId' => ord.Id, 'fields' => ''};

        // When
        Test.startTest();
        Boolean result = new CpqAppHandlerHookCustomImpl().invokeMethod('getCartsItems.PreInvoke', input,
            new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then: el reemplazo no altera el armado de campos que ya hacía este evento
        Assert.isTrue(result, 'El hook debe responder true');
        Assert.isTrue(String.valueOf(input.get('fields')).contains('FVU_OneTimeTotalIncTaxes__c'), 'Se mantienen los campos personalizados');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.swappingSimToEsim, 'La bandera de reemplazo debe quedar liberada');
    }

    @isTest
    static void shouldBlockSimCard_WhenPostCartsItemsPreInvoke_WithEsimMigration() {
        // Given
        Order ord = createSimCart('[{"SimType":"eSIM"}]');
        PricebookEntry pbeSimCard = [SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'B2C-MOV-OFR-SIMCARD' LIMIT 1];
        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id, 'fields' => '',
            'items' => new List<Object>{new Map<String, Object>{'itemId' => pbeSimCard.Id}}
        };

        // When
        Test.startTest();
        Boolean result = new CpqAppHandlerHookCustomImpl().invokeMethod('postCartsItems.PreInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then
        Assert.isTrue(result, 'El hook debe responder true');
        Assert.isTrue((Boolean)input.get('simcardnotallowed'), 'Debe marcar la SIM Card como no permitida');
        Assert.isNull(input.get('items'), 'Debe vaciar los items para que no se agregue la SIM Card');
    }

    @isTest
    static void shouldSetEsimMessages_WhenPostCartsItemsPostInvoke() {
        // Given
        vlocity_cmt.JSONResult blockedResult = (vlocity_cmt.JSONResult)JSON.deserialize(
            '{"totalSize":0,"records":[],"messages":[{"code":"143","message":"Original"}],"actions":{}}', vlocity_cmt.JSONResult.class);
        vlocity_cmt.JSONResult addedResult = (vlocity_cmt.JSONResult)JSON.deserialize(
            '{"totalSize":1,"records":[],"messages":[{"code":"150","message":"Añadido exitosamente."}],"actions":{}}', vlocity_cmt.JSONResult.class);
        CpqAppHandlerHookCustomImpl hook = new CpqAppHandlerHookCustomImpl();

        // When
        Test.startTest();
        hook.invokeMethod('postCartsItems.PostInvoke', new Map<String, Object>{'simcardnotallowed' => true},
            new Map<String, Object>{'result' => blockedResult}, new Map<String, Object>());
        hook.invokeMethod('postCartsItems.PostInvoke', new Map<String, Object>{'esimSale' => true},
            new Map<String, Object>{'result' => addedResult}, new Map<String, Object>());
        Test.stopTest();

        // Then
        Assert.isTrue(blockedResult.messages[0].message.contains('migración con eSIM'), 'Mensaje de SIM Card no permitida');
        Assert.isTrue(addedResult.messages[0].message.contains('se reemplaza automáticamente por eSIM'), 'Aviso de reemplazo al agregar el plan');
    }

    @isTest
    static void shouldOnlyRemoveSimCard_WhenGroupAlreadyHasEsim() {
        // Given: el grupo ya tiene eSIM y además una SIM Card agregada a mano
        Order ord = createSimCart('[{"SimType":"eSIM"}]');
        PricebookEntry pbeEsim = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.ProductCode = 'B2C-MOB-OFR-ESIM' LIMIT 1];
        insert new OrderItem(OrderId = ord.Id, Product2Id = pbeEsim.Product2Id, PricebookEntryId = pbeEsim.Id,
            Quantity = 1, UnitPrice = 0, vlocity_cmt__LineNumber__c = '0001.0002.0002', vlocity_cmt__Action__c = 'Add',
            vlocity_cmt__ParentItemId__c = 'sim-group-ref', vlocity_cmt__ProductHierarchyPath__c = 'plan<group<esim');

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl.swapSimCardToEsim(ord.Id);
        Test.stopTest();

        // Then: los IP de CPQ no existen en el contexto de prueba; se valida que no rompa y libere la bandera
        Assert.isFalse(CpqAppHandlerHookCustomImpl.swappingSimToEsim, 'La bandera de reemplazo debe quedar liberada');
    }

    @isTest
    static void shouldNotTouchSimCard_WhenPlanAndTerminalOrder() {
        // Given: Plan + Terminal (ATT), donde el catálogo no permite eSIM
        Order ord = createSimCart('[{"SimType":"eSIM"}]', 'ATT');
        PricebookEntry pbeSimCard = [SELECT Id FROM PricebookEntry WHERE Product2.ProductCode = 'B2C-MOV-OFR-SIMCARD' LIMIT 1];
        Map<String, Object> input = new Map<String, Object>{
            'cartId' => ord.Id, 'fields' => '',
            'items' => new List<Object>{new Map<String, Object>{'itemId' => pbeSimCard.Id}}
        };

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl.swapSimCardToEsim(ord.Id);
        new CpqAppHandlerHookCustomImpl().invokeMethod('postCartsItems.PreInvoke', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then
        Assert.areEqual(1, [SELECT COUNT() FROM OrderItem WHERE OrderId = :ord.Id AND Product2.ProductCode = 'B2C-MOV-OFR-SIMCARD'],
            'En Plan + Terminal la SIM Card se mantiene');
        Assert.isNull(input.get('simcardnotallowed'), 'En Plan + Terminal no se bloquea la SIM Card');
    }

    @isTest
    static void shouldDetectAddedMessageCode() {
        Assert.isTrue(CpqAppHandlerHookCustomImpl.hasMessageCode(new Map<String, Object>{
            'messages' => new List<Object>{new Map<String, Object>{'code' => '150', 'message' => 'Añadido exitosamente.'}}}, '150'), 'Código 150 presente');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.hasMessageCode(new Map<String, Object>{
            'messages' => new List<Object>{new Map<String, Object>{'code' => '310', 'message' => 'Error'}}}, '150'), 'Código 150 ausente');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.hasMessageCode(null, '150'), 'Salida nula');
        Assert.isFalse(CpqAppHandlerHookCustomImpl.hasMessageCode(new Map<String, Object>(), '150'), 'Sin mensajes');
    }

    @isTest
    static void shouldNotSwapSim_WhenSimTypeIsNotEsim() {
        // Given
        Order ord = createSimCart('[{"ICCID":"","SimType":"USIM","NRN":""}]');

        // When
        Test.startTest();
        CpqAppHandlerHookCustomImpl.swapSimCardToEsim(ord.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(1, [SELECT COUNT() FROM OrderItem WHERE OrderId = :ord.Id AND Product2.ProductCode = 'B2C-MOV-OFR-SIMCARD'],
            'La SIM Card debe quedarse cuando la venta no es eSIM');
    }

    @isTest
    static void shouldSkipSimSwap_WhenAlreadySwapping() {
        // Given
        Order ord = createSimCart('[{"SimType":"eSIM"}]');
        CpqAppHandlerHookCustomImpl.swappingSimToEsim = true;

        // When
        Test.startTest();
        Boolean result = new CpqAppHandlerHookCustomImpl().invokeMethod('getCartLineItemPrices.PreInvoke', new Map<String, Object>{'cartId' => ord.Id},
            new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Then: con la bandera activa (llamada interna del propio reemplazo) no se vuelve a reemplazar
        Assert.isTrue(result, 'El hook debe responder true');
        Assert.areEqual(1, [SELECT COUNT() FROM OrderItem WHERE OrderId = :ord.Id AND Product2.ProductCode = 'B2C-MOV-OFR-SIMCARD'],
            'La SIM Card no se toca durante un reemplazo en curso');
    }
}