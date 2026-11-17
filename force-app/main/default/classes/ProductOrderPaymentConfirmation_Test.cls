/*------------------------------------------------------------------------
Author:        	Daniela Romero
Company:       	Salesforce.com
Description:   	Test class to manage the coverage code for the class REST_ProductOrderPaymentConfirmation
History
<Date>      	<Author>     	<Description>
01-Agos-2023	Daniela Romero	Initial Version
22-Agos-2023	Luis Mendoza	Version with workaround
20-Sept-2023	Luis Mendoza	Version with new field into JSON
----------------------------------------------------------------------------*/
@isTest
public class ProductOrderPaymentConfirmation_Test {

    @TestSetup
    static void makeData(){
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Case casedata = new Case(AccountId = acct.Id, Status = 'Draft');
        insert casedata;

        Pricebook2 pb = new Pricebook2(Name = 'Standard Price Book', isActive = true);
        insert pb;
        
        Product2 testProduct = new Product2(Name = 'Test Product',Description = 'This is a test product',ProductCode = 'test1', isActive = true);
        insert testProduct;
        
        PriceBookEntry[] entryList = new List<PriceBookEntry> {
            new PricebookEntry( Product2Id=testProduct.id, UnitPrice=0, PriceBook2Id=Test.getStandardPricebookId(), UseStandardPrice=false, isActive=true),
            new PricebookEntry( Product2Id=testProduct.id, UnitPrice=0, PriceBook2Id=pb.id, UseStandardPrice=true, isActive=true)
            };
        insert entryList;
        
        Order ord = new Order(AccountId = acct.Id, Pricebook2Id = pb.Id, Status = 'Draft', EffectiveDate = date.today());
        insert ord;
        
        OrderItem testOrderItem = new OrderItem(OrderId = ord.Id, PricebookEntryId = entryList[1].Id, Quantity = 1, UnitPrice = entryList[1].UnitPrice, vlocity_cmt__OneTimeCharge__c = 100, vlocity_cmt__BaseOneTimeTotal__c = 100, FVU_EffectiveOneTimeTotalIncTaxes__c = 100);
        insert testOrderItem;
        
    }

    @isTest
    public static void productOrCasePaymentConfirmation (){

        Order updatedOrder = [Select Id, OrderNumber FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id, OrderItemNumber FROM OrderItem WHERE OrderId = :updatedOrder.Id LIMIT 1];
        system.debug('ORDER ID' + updatedOrder);
        
        vlocity_cmt__OrderPayment__c op1 = new vlocity_cmt__OrderPayment__c(vlocity_cmt__OrderId__c = updatedOrder.Id, FVU_PaymentMethod__c = '', vlocity_cmt__PaymentAmount__c = 0.0);
        insert op1;
        
        vlocity_cmt__OrderPayment__c op2 = new vlocity_cmt__OrderPayment__c(vlocity_cmt__OrderId__c = updatedOrder.Id, FVU_PaymentMethod__c = '', vlocity_cmt__PaymentAmount__c = 0.0);
        insert op2;

                
        String JSONOrderTest = '{'+
            '    "PaymentConfirmation": ['+
            '      {'+
            '        "OrderNumber": "' + updatedOrder.OrderNumber +'",'+
            '        "paymentId": "999",'+
            '        "companyId": "SICACOM",'+
            '        "status": "NA",'+
            '        "collectionCenter": 12345,'+
            '        "ProductOrderItem": ['+
            '          {'+
            '            "ProductCode": "B2C-MOB-PRD-TERM-70049671",'+
            '            "Name": "$20 for $10",'+
            '            "OrderItemNumber": "'+ oi.OrderItemNumber +'"'+
            '          }'+
            '        ],'+
            '        "OrderPaymentInformation": ['+
            '          {'+
            '            "paymentMethod": "1",'+
            '            "amount": 100,'+
            '            "dateTime": "2021-04-16T00:00:00.000Z",'+
            '            "paymentTransactionId": "101000000000",'+
            '            "transactionId": "1220ASAS545454",'+
            '            "sourceTransactionId": "6"'+
            '          }'+
            '        ]'+
            '      }'+
            '    ]'+
            '  }';
        
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(JSONOrderTest);     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        test.startTest();
            REST_ProductOrderPaymentConfirmation postOrderMethod = new REST_ProductOrderPaymentConfirmation();
            Boolean result = postOrderMethod.invokeMethod('productOrCasePaymentConfirmation', inputMap, outputMap, options);
        test.stopTest();
        
        vlocity_cmt__OrderPayment__c op2Result = [SELECT Id, Name, vlocity_cmt__OrderId__c, FVU_PaymentMethod__c, FVU_CollectionCenter__c, FVU_PaymentTxDate__c, vlocity_cmt__PaymentAmount__c FROM vlocity_cmt__OrderPayment__c WHERE Id =:op2.Id];
        Assert.areEqual('1', op2Result.FVU_PaymentMethod__c);
        Assert.areEqual('12345', op2Result.FVU_CollectionCenter__c);
    }

    @isTest
    public static void productOrPayConfirtWiouthORP (){

        Order updatedOrder = [Select Id, OrderNumber FROM Order LIMIT 1];
        OrderItem oi = [SELECT Id, OrderItemNumber FROM OrderItem WHERE OrderId = :updatedOrder.Id LIMIT 1];
        system.debug('ORDER ID' + updatedOrder);
                       
        String JSONOrderTest = '{'+
            '    "PaymentConfirmation": ['+
            '      {'+
            '        "OrderNumber": "' + updatedOrder.OrderNumber +'",'+
            '        "paymentId": "999",'+
            '        "companyId": "SICACOM",'+
            '        "status": "NA",'+
            '        "collectionCenter": 12345,'+
            '        "ProductOrderItem": ['+
            '          {'+
            '            "ProductCode": "B2C-MOB-PRD-TERM-70049671",'+
            '            "Name": "$20 for $10",'+
            '            "OrderItemNumber": "'+ oi.OrderItemNumber +'"'+
            '          }'+
            '        ],'+
            '        "OrderPaymentInformation": ['+
            '          {'+
            '            "paymentMethod": "1",'+
            '            "amount": 50,'+
            '            "dateTime": "2021-04-16T00:00:00.000Z",'+
            '            "paymentTransactionId": "101000000000",'+
            '            "transactionId": "1220ASAS545454",'+
            '            "sourceTransactionId": "6"'+
            '          },'+
            '          {'+
            '            "paymentMethod": "1",'+
            '            "amount": 50,'+
            '            "dateTime": "2021-04-16T00:00:00.000Z",'+
            '            "paymentTransactionId": "101000500000",'+
            '            "transactionId": "1220ASAS545499",'+
            '            "sourceTransactionId": "6"'+
            '          }'+
            '        ]'+
            '      }'+
            '    ]'+
            '  }';
        
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(JSONOrderTest);     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        test.startTest();
            REST_ProductOrderPaymentConfirmation postOrderMethod = new REST_ProductOrderPaymentConfirmation();
            Boolean result = postOrderMethod.invokeMethod('productOrCasePaymentConfirmation', inputMap, outputMap, options);
        test.stopTest();
        
        vlocity_cmt__OrderPayment__c op2Result = [SELECT Id, Name, vlocity_cmt__OrderId__c, FVU_PaymentMethod__c, FVU_PaymentTxDate__c, vlocity_cmt__PaymentAmount__c FROM vlocity_cmt__OrderPayment__c LIMIT 1];
        Assert.areEqual('1', op2Result.FVU_PaymentMethod__c);
    }
    
    @isTest
    public static void casePaymentConfirmationTest (){
        
        Case UpdatedCase = [Select Id, CaseNumber FROM Case Limit 1];
        
        String JSONCaseTest = '{'+
            '    "PaymentConfirmation": ['+
            '      {'+
            '        "CaseNumber": "' + UpdatedCase.CaseNumber +'",'+
            '        "paymentId": "999",'+
            '        "companyId": "SICACOM",'+
            '        "status": "Approved",'+
            '        "collectionCenter": 12345,'+
            '        "SubState": "Devolución de Dinero",'+
            '        "ProductOrderItem": ['+
            '          {'+
            '            "ProductCode": "B2C-MOB-PRD-TERM-70049671",'+
            '            "Name": "$20 for $10",'+
            '            "OrderItemNumber": "1234567890"'+
            '          }'+
            '        ],'+
            '        "OrderPaymentInformation": ['+
            '          {'+
            '            "paymentMethod": "Tarjeta",'+
            '            "amount": 100,'+
            '            "dateTime": "2021-04-16T00:00:00.000Z",'+
            '            "paymentTransactionId": "101000000000",'+
            '            "transactionId": "1220ASAS545454",'+
            '            "sourceTransactionId": "6"'+
            '          }'+
            '        ]'+
            '      }'+
            '    ]'+
            '  }';
        
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(JSONCaseTest);     
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        test.startTest();
        REST_ProductOrderPaymentConfirmation postOrderMethod = new REST_ProductOrderPaymentConfirmation();
        Boolean result = postOrderMethod.invokeMethod('productOrCasePaymentConfirmation', inputMap, outputMap, options);
        test.stopTest();
        
        Case resultCase = [Select Id, CaseNumber, Status, PVU_Sub_Estado__c FROM Case Limit 1];
        Assert.areEqual('Draft', resultCase.Status);
    }
    
    @isTest
	public static void validateProductOrderItemsTest(){
        Order ord = [SELECT Id, OrderNumber, FVU_BaseOneTimeTotalSummary__c, FVU_EffectiveOneTimeIncTaxesTotal__c FROM Order LIMIT 1];
    
        OrderItem oi = [SELECT Id, OrderItemNumber FROM OrderItem WHERE OrderId = :ord.Id LIMIT 1];
        
        // Error scenario
        String jsonFail = '{'+
            '"PaymentConfirmation": ['+
            '{'+
                '"OrderNumber": "'+ ord.OrderNumber +'",'+
                '"status": "PE",'+
                '"paymentId": "123",'+
                '"collectionCenter": 123,'+                
                '"OrderPaymentInformation": ['+
                    '{'+
                        '"paymentMethod": "1",'+
                        '"amount": 50,'+ 
                        '"dateTime": "2026-03-16T00:00:00.000Z"'+
                    '}'+
                ']'+
            '}'+
            ']'+
        '}';
    
        Map<String, Object> inputMapFail = (Map<String, Object>) JSON.deserializeUntyped(jsonFail);
        Map<String, Object> outMapFail = new Map<String, Object>();
    
               
        // Success scenario
        String jsonSuccessByAmount = '{'+
            '"PaymentConfirmation": ['+
            '{'+
                '"OrderNumber": "'+ ord.OrderNumber +'",'+
                '"status": "PE",'+
                '"paymentId": "123",'+
                '"collectionCenter": 123,'+               
                '"OrderPaymentInformation": ['+
                    '{'+
                        '"paymentMethod": "1",'+
                        '"amount": '+ ord.FVU_BaseOneTimeTotalSummary__c +','+
                        '"dateTime": "2026-03-16T00:00:00.000Z"'+
                    '}'+
                ']'+
            '}'+
            ']'+
        '}';
    
        Map<String, Object> inputMapSuccess = (Map<String, Object>) JSON.deserializeUntyped(jsonSuccessByAmount);
        Map<String, Object> outMapSuccess = new Map<String, Object>();
    
       	Test.startTest();
        	REST_ProductOrderPaymentConfirmation cls = new REST_ProductOrderPaymentConfirmation();    
        	// Scenery 1
        	cls.invokeMethod('productOrCasePaymentConfirmation', inputMapFail, outMapFail, new Map<String,Object>());    
        	// Scenery 2
        	cls.invokeMethod('productOrCasePaymentConfirmation', inputMapSuccess, outMapSuccess, new Map<String,Object>());    
    	Test.stopTest();
	} 
}