@isTest
public class PVU_ConsultaActividadSystemInterfaceTest {

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
        PVU_ConsultaActividadSystemInterface consultaInterface = new PVU_ConsultaActividadSystemInterface();
        testWasCalled = (Boolean) consultaInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }
    
     @isTest
    private static void callConsultaActividadMinImeiFail(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String imei = '123456789012345';
        String min = '3013463337';
        String methodName = 'PVU_IPsvcConsultaActividadMinImei';
        Boolean testWasCalled = false;
        Boolean caughtException = false;
        Test.startTest();
        try{
            PVU_ConsultaActividadSystemInterface consultaInterface = new PVU_ConsultaActividadSystemInterface();
            testWasCalled = (Boolean) consultaInterface.call(action, args);            
        }catch(Exception e){
            caughtException=true;
        }
        
        Test.stopTest();
        
        
        System.assert(caughtException, true);
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        //System.assertEquals('111111111111111', (String) response.get('imei'), 'El imei no coincide');
    }

    /*@isTest
    private static void testInvokeMethodException(){
        Map<String, Object> input = new Map<String, Object>();
        input.put('procedureName', 'InvalidProcedureName');
        Boolean testWasCalled = false;
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Test.startTest();
        PVU_ConsultaActividadSystemInterface consultaInterface = new PVU_ConsultaActividadSystemInterface();
        testWasCalled = (Boolean) consultaInterface.call('other', args);
        Test.stopTest();
        System.assert(output.containsKey('EXCEPTION'), 'El mapa de salida debería contener la clave "EXCEPTION"');
        Map<String, Object> exceptionMap = (Map<String, Object>) output.get('EXCEPTION');
        System.assertNotEquals(null, exceptionMap.get('Message'), 'El mensaje de la excepción no debería ser nulo');
    }*/
}