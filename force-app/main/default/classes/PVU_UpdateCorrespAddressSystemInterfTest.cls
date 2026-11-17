@isTest
public with sharing class PVU_UpdateCorrespAddressSystemInterfTest {
    @isTest
    private static void callUpdateAddress(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();

        String action = 'callIP';
        String accountNumber = 'CUST0000000064';
        String state = 'Cordoba';
        String city = 'Cordoba';
        String street = 'cr 75c #105 15 Garces';
        String cityArea = '2435';
        String dane = '05001061';
        String methodName = 'PVU_IPsvcUpdateCorrespondenceAddress';

        input.put('procedureName', methodName);
        input.put('accountNumber', accountNumber);
        input.put('state', state);
        input.put('city', city);
        input.put('street', street);
        input.put('cityArea', cityArea);
        input.put('dane', dane);

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        Boolean testWasCalled = false;
        Test.startTest();   
        PVU_UpdateCorrespAddressSystemInterf UpdateCorrespInterface = new PVU_UpdateCorrespAddressSystemInterf();
        	testWasCalled = (Boolean) UpdateCorrespInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('CUST0000000064', (String) response.get('accountNumber'), 'El account Number no coincide');
    }
}