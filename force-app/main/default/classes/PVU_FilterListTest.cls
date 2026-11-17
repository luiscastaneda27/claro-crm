@isTest
public with sharing class PVU_FilterListTest {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case testCase = new Case(
            AccountId = acc.Id,
            vlocity_cmt__BillingAccountId__c = acc.Id,
            PVU_TipoSolicitudMasivos__c = 'ACTIVATE_CCV',
            PVU_Level1__c = 'Facturación y pagos',
            PVU_Level2__c = 'Pagos',
            PVU_Level3__c = 'Proceso Cobranza'
        );
        insert testCase;
    }
    
    @isTest
    static void getFilterListTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"principal":[{"min":"3150004013","imsi":"732101166062005"},{"min":"3150004014","imsi":"732101166062005"},{"min":"3150004015","imsi":"732101166062005"},{"min":"3150004016","imsi":"732101166062005"}],"secundaria":[{"minDelete":"3150004015","imsiDelete":"732101166062005"},{"minDelete":"3150004016","imsiDelete":"732101166062005"}],"keyPrincipal":"min","keySecundaria":"minDelete"}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('getFilterList',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Borrado');
    }

    @isTest
    static void getFilterListTestPrincipalNull(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"principal":"","secundaria":[{"minDelete":"3150004015","imsiDelete":"732101166062005"},{"minDelete":"3150004016","imsiDelete":"732101166062005"}],"keyPrincipal":"min","keySecundaria":"minDelete"}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('getFilterList',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Borrado');
    }

    @isTest
    static void getFilterListTestSecundariaNull(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"principal":[{"min":"3150004013","imsi":"732101166062005"},{"min":"3150004014","imsi":"732101166062005"},{"min":"3150004015","imsi":"732101166062005"},{"min":"3150004016","imsi":"732101166062005"}],"secundaria":"","keyPrincipal":"min","keySecundaria":"minDelete"}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('getFilterList',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Borrado');
    }
    
    @isTest
    static void addMinAdicionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"keyPrincipal":"minAdicion","principal":["3150004014","3150004016"]}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('addMinAdicion',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Duplas');
    }
    @isTest
    static void splitByComaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"keyPrincipal":"minAdicion","lista":["3150004014","3150004016"]}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('splitByComa',input,output,options);
        Test.stopTest();
        system.debug('output.get(result)>'+output.get('result'));
        System.assert(output.get('result') != null,'result');
    }
    @isTest
    static void unSplitByComaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();

        String jsonStr = '{"keyPrincipal":"minAdicion","lista":"3150004014,3150004016"}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('unSplitByComa',input,output,options);
        Test.stopTest();
        system.debug('output.get(result)>'+output.get('result'));
        System.assert(output.get('result') != null,'result');
    }
    @isTest
    static void promoNoValidaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();



        String jsonStr = '{"promos":[{"Id":"3150004014","imsi":"732101166062005"}],"validas":[{"Id":"3150004013","imsi":"732101166062005"}],"campo":"Id"}';
		input = (Map<String,Object>) JSON.deserializeUntyped(jsonStr);
        
        Test.startTest();
        testMsg.invokeMethod('promoNoValida',input,output,options);
        Test.stopTest();
        system.debug('output.get(result)>'+output.get('result'));
        System.assert(output.get('result') != null,'result');
    }
    
    @isTest
    static void testGetCasesCCV_ValidData() {
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_FilterList testMsg = new PVU_FilterList();
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case testCase = [SELECT Id FROM Case WHERE AccountId = :acc.Id LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>{
            'cuentasMarcaCobranza' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => acc.Id,
                    'ExternalId' => '93000000051163'
                }
            }
        };
        
        Test.startTest();
        testMsg.invokeMethod('getCasesCCV',input,output,options);
        Test.stopTest();
        system.debug('output.get(result)>'+output.get('result'));
        
 	}
    @isTest
    static void mergePaymentFinancingTest(){
    
        Map<String, Object> input = (Map<String, Object>)
            JSON.deserializeUntyped(
                '{"PaymentRef":['+
                    '{"chargeBillingAccount":"1","Id":"1"},'+
                    '{"chargeBillingAccount":"2","Id":"2"}'+
                '],'+
                '"Financing":['+
                    '{"chargeBillingAccount":"1","NumeroDeCredito":"CRED1"},'+
                    '{"chargeBillingAccount":"2","NumeroDeCredito":"CRED2"},'+
                    '{"chargeBillingAccount":"1","NumeroDeCredito":"CRED3"}'+
                ']}'
            );
    
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
    
        PVU_FilterList service = new PVU_FilterList();    
        Test.startTest();
    
        Boolean result = service.invokeMethod('mergePaymentFinancing',input,output,options);    
        Test.stopTest();
    
        System.assertEquals(true, result);
    
        List<Object> merged = (List<Object>) output.get('MergedResult');
    
        System.assertNotEquals(null, merged);
        System.assertEquals(3, merged.size());
    
        Map<String,Object> first = (Map<String,Object>) merged[0];
    
        System.assert(first.containsKey('chargeBillingAccount'));
    
        System.assert(first.containsKey('NumeroDeCredito')
        );
	}
}