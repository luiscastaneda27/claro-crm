@isTest
public with sharing class PVU_LiberacionIMEISystemInterfaceTest {
    @isTest
    private static void callValidatePin(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String clientID = '43759066';
        String pin = '6RWP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcValidatePin';
        input.put('procedureName', methodName);
        input.put('imei', imei);
        input.put('clientID',clientID);
        input.put('pin',pin);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_LiberacionIMEISystemInterface liberacionImeiInterface = new PVU_LiberacionIMEISystemInterface();
        	testWasCalled = (Boolean) liberacionImeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }

    @isTest
    private static void callPinGeneration(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        Boolean isEmail = true;
        String vchDataHalfShipmen = 'callPinGeneration@test.com';
        String clientID = '43759066';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcPinGeneration';
        input.put('procedureName', methodName);
        input.put('imei', imei);
        input.put('vchDataHalfShipmen',vchDataHalfShipmen);
        input.put('isEmail',isEmail);
        input.put('clientID',clientID);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_LiberacionIMEISystemInterface liberacionImeiInterface = new PVU_LiberacionIMEISystemInterface();
        	testWasCalled = (Boolean) liberacionImeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
}