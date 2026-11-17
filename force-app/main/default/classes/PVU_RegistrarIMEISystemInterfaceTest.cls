@isTest
public with sharing class PVU_RegistrarIMEISystemInterfaceTest {
    @isTest
    private static void callRegistrarImei(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();

        String action = 'callIP';
        String imei = '352527091504668';
        String tipoPersona = '1';
        String tipoId = '1';
        String docNumber = '3333333';
        String name = 'Fernanda';
        String dir = '0';
        String tel = '0';
        String dep = '0';
        String cid = '0';
        String methodName = 'PVU_IPsvcRegistroImei';

        input.put('procedureName', methodName);
        input.put('Serial', imei);
        input.put('tipoPersona', tipoPersona);
        input.put('tipoldentificacion', tipoId);
        input.put('docNumber', docNumber);
        input.put('Name', name);
        input.put('Direccion', dir);
        input.put('TelefonoContacto', tel);
        input.put('Departamento', dep);
        input.put('Ciudad', cid);

        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        Boolean testWasCalled = false;
        Test.startTest();   
        PVU_RegistrarIMEISystemInterface registrarImeiInterface = new PVU_RegistrarIMEISystemInterface();
        	testWasCalled = (Boolean) registrarImeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('352527091504668', (String) response.get('Serial'), 'El imei no coincide');
    }
}