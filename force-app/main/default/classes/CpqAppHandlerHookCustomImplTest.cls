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
}