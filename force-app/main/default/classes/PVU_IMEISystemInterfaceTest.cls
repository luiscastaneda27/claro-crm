@isTest
public class PVU_IMEISystemInterfaceTest {
    
    @isTest
    private static void callValidacionLuhn(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcImeiValidacionLuhn';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callConsultaTipoIdentificacion(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcConsultaTipoIdentificacion';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callBdoNegativo(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcbdoNegativo';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callBdaPositivo(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcBdaPositivo';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callBdoPositivo(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcBdoPositivo';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callCesionUsuario(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcCesionUsuario';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callConsultaDuplicados(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String imei = '358043123373191';
        String min = '3013463337';
        String methodName = 'PVU_IPsvcConsultaDuplicados';
        input.put('procedureName', methodName);
        input.put('imei',imei);
        input.put('min',min);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callConsultaDuplasporId(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String numeroIdentificacion = '127968';
        String tipoIdentificacion = '1';
        String methodName = 'PVU_IPsvcConsultaDuplasPorId';
        input.put('procedureName', methodName);
        input.put('numeroIdentificacion',numeroIdentificacion);
        input.put('tipoIdentificacion',tipoIdentificacion);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callReportarImei(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcReportarImeiBdo';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callLiberarImei(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcLiberarImei';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callGestionDuplicados(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        String methodName = 'PVU_IPsvcGestionDuplicados';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        	testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
    @isTest
    private static void callImeiDataList(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = 'CC';
        String action = 'callIP';
        String imei = '123456789012345';
        // List<Object> dataTable = [{"min":"3013463337","imsi":"732101560226370"},{"min":"3013463337","imsi":"732101560226371"}];
        String methodName = 'PVU_IPsvcImeiDataList';
        input.put('procedureName', methodName);
        input.put('AccountTipoDoc', tipoDoc);
        input.put('imei',imei);
        //input.put('dataTable',dataTable);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_IMEISystemInterface imeiInterface = new PVU_IMEISystemInterface();
        	testWasCalled = (Boolean) imeiInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
}