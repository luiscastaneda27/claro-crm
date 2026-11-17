@isTest
private class PVU_UtilityFunctionsTest {
    /*
	* Created Date: 20240531
	* Created By: Federico Mandri
	* HU: 692695
	* Description: Test Data for Change of Sim Card, the implementation is called from Flow - given parameter order id related to change of SimCard Case, return Sim data from the new Sim Asset
	*/
    @testSetup
    static void testData(){
        //PriceBook
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Test Pricebook';
        insert pb;
        
        //Products
        List<Product2> prods = new List<Product2>();
        Product2 prod1 = new Product2();
        prod1.ProductCode = 'PROD_CODE_1';
        prod1.Name = 'Prod1';
        prod1.vlocity_cmt__Type__c = 'Plan';
        prod1.vlocity_cmt__SubType__c = 'PostPaid';
        prods.add(prod1);
        
        Product2 prod2 = new Product2();
        prod2.ProductCode = 'PROD_CODE_2';
        prod2.Name = 'Prod2';
        prod2.vlocity_cmt__Type__c = 'SIM Card';
        prod2.vlocity_cmt__SubType__c = 'SIM Card';
        prods.add(prod2);
        
        insert prods;
        
        //Pricebook entries
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        pbe1.UnitPrice = 0;
        pbe1.Product2Id = prods[0].Id;
        pbes.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.UnitPrice = 0;
        pbe2.Product2Id = prods[1].Id;
        pbes.add(pbe2);
        
        insert pbes;
        
        //Account
        Account acc = New Account();
        acc.Name = 'Test Account';
        insert acc;
        
        //Order
        Order ord = new Order();
        ord.Name = 'Test Order';
        ord.Status = 'Draft';
        ord.AccountId = acc.Id;
        ord.EffectiveDate = System.Today();
        ord.Pricebook2Id = Test.getStandardPricebookId();
        insert ord;
        
        //Orderitems
        List<OrderItem> oitems = new List<OrderItem>();
        OrderItem oi1 = new OrderItem();
        oi1.Product2Id = prods[0].Id;
        oi1.OrderId = ord.Id;
        oi1.PricebookEntryId = pbes[0].Id;
        oi1.UnitPrice = 0;
        oi1.Quantity = 1;
        oitems.add(oi1);
        
        OrderItem oi2 = new OrderItem();
        oi2.Product2Id = prods[1].Id;
        oi2.OrderId = ord.Id;
        oi2.PricebookEntryId = pbes[1].Id;
        oi2.UnitPrice = 0;
        oi2.Quantity = 1;
        oitems.add(oi2);
        
        insert oitems;
        
        //Assets
        List<Asset> asts = new List<Asset>();
        Asset ast1 = new Asset();
        ast1.Name = 'Test Asset 1';
        ast1.vlocity_cmt__OrderProductId__c = oitems[0].Id;
        ast1.vlocity_cmt__Action__c = 'Existing';
        ast1.AccountId = acc.Id;
        ast1.vlocity_cmt__AttributeSelectedValues__c = '';
        ast1.vlocity_cmt__OrderId__c = ord.Id;
        ast1.vlocity_cmt__ProvisioningStatus__c = 'Active';
        ast1.vlocity_cmt__AssetReferenceId__c = 'abcd-efgh-igjk-lmno';
        ast1.Product2Id = prods[0].Id;
        asts.add(ast1);
        
        Asset ast2 = New Asset();
		ast2.Name = 'Test Asset 2';
		ast2.vlocity_cmt__OrderProductId__c = oitems[1].Id;
        ast2.vlocity_cmt__Action__c = 'Add';
        ast2.AccountId = acc.Id;
        ast2.vlocity_cmt__OrderId__c = ord.Id;
        ast2.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-ICCID":"12345","B2C-ATTR-IMSI":null,"B2C-ATTR-TECN-SIM":null,"B2C-ATTR-TIPO-SIM":"SIM Card","B2C-ATTR-SIM-MATERIAL":"7015434","B2C-ATTR-SIM-PIN":null,"B2C-ATTR-SIM-PUK":"999999"}';
        ast2.vlocity_cmt__ProvisioningStatus__c = 'Active';
        ast2.vlocity_cmt__AssetReferenceId__c = 'pqrs-tuvw-xyza-bcde';
        ast2.Product2Id = prods[1].Id;
        asts.add(ast2);
        
        insert asts;
        
        oitems[1].vlocity_cmt__AssetId__c = asts[1].Id;
        oitems[1].vlocity_cmt__AssetReferenceId__c = asts[1].vlocity_cmt__AssetReferenceId__c;
        update oitems;

        //Case
        Case caso = new Case();
        caso.AccountId = acc.Id;
        caso.PVU_Order__c = ord.Id;
        caso.PVU_Level1__c = 'Soporte, Fallas de Servicio y Equipos';
        caso.PVU_Level2__c = 'Falla de Servicios';
        caso.PVU_Level3__c = 'Cambio de Sim Card';
        caso.PVU_ICCID_Temporal__c  = '12345';
        caso.Status = 'En curso';
        insert caso;
    }

	@isTest    
    static  void listToObjectsTest() {
        
        List<Object> args = new List<Object>();
        args.add('a');
        args.add('b');
    
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('listObject', args);
        inputMap.put('label', 'Id');
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        PVU_UtilityFunctions csf = new PVU_UtilityFunctions();
        Boolean retValue = csf.invokeMethod('ListToObjects', inputMap, outputMap, null);
        List<Object> result = (List<Object>)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result.size(), 2);
    }
    
    /*
	* Created Date: 20240531
	* Created By: Federico Mandri
	* HU: 692695
	* Description: Test method for Change of Sim Card - given parameter order id related to change of SimCard Case, return Sim data from the new Sim Asset
	*/
    @isTest
    static void getSimInfoTest(){
        
        PVU_UtilityFunctions.SimInput input = new PVU_UtilityFunctions.SimInput();
        List<PVU_UtilityFunctions.SimInput> listInput = new List<PVU_UtilityFunctions.SimInput>();
        List<PVU_UtilityFunctions.SimInfo> listOutput = new List<PVU_UtilityFunctions.SimInfo>();
        
        Case testCase = [SELECT Id, PVU_Order__c FROM Case LIMIT 1];
        
        input.orderId = testCase.PVU_Order__c;
        listInput.add(input);
        
        Test.startTest();
        	listOutput = PVU_UtilityFunctions.getNewSimInformationByOrderId(listInput);
        Test.stopTest();
        
        System.Assert(listOutput.size() > 0);
        System.AssertEquals(listOutput.get(0).puk, '999999', 'No coincide el PUK');
        System.AssertEquals(listOutput.get(0).iccid, '12345', 'No coincide el ICCID');
        
        
    }
    
}