@isTest
public class PVU_DuplicadosSystemInterfaceTest {

    @isTest
    private static void callConsultaActividadMinImei(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String imei = '123456789012345';
        String min = '3013463337';
        String methodName = 'PVU_IPsvcConsultaActividadMinImei';
        input.put('procedureName', methodName);
        input.put('imei',imei);
        input.put('min',min);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_DuplicadosSystemInterface consultaInterface = new PVU_DuplicadosSystemInterface();
        testWasCalled = (Boolean) consultaInterface.call(action, args);
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
        String numeroIdentificacion = '123456';
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
        PVU_DuplicadosSystemInterface consultaInterface = new PVU_DuplicadosSystemInterface();
        testWasCalled = (Boolean) consultaInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
        @isTest
    private static void callValidarDuplasAdicion(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String imei = '123456789012345';
        String min = '3013463337';
        String methodName = 'PVU_IPsvcValidarDuplasAdicion';
        input.put('procedureName', methodName);
        input.put('imei',imei);
        input.put('min',min);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_DuplicadosSystemInterface consultaInterface = new PVU_DuplicadosSystemInterface();
        testWasCalled = (Boolean) consultaInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
}