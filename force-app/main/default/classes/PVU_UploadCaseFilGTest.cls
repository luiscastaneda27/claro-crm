@IsTest
private class PVU_UploadCaseFilGTest {

    @IsTest
    static void testInvokeMethod_Success() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();
        Map<String, Object> fakeResponse = new Map<String, Object>{ 'responseCode' => '200' };

        Map<String, Object> input = new Map<String, Object>{
            'maxRetries' => 2,
            'nameIP' => 'FakeIP',
            'fakeResponse' => fakeResponse
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = cls.invokeMethod('pHandlerDocument', input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals('200', String.valueOf(outMap.get('responseCode')));
    }

    @IsTest
    static void testInvokeMethod_FailAfterRetries() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();
        Map<String, Object> fakeResponse = new Map<String, Object>{ 'responseCode' => '500' };

        Map<String, Object> input = new Map<String, Object>{
            'maxRetries' => 2,
            'nameIP' => 'FakeIP',
            'fakeResponse' => fakeResponse
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = cls.invokeMethod('pHandlerDocument', input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result, 'invokeMethod sigue retornando true');
        System.assert(String.valueOf(outMap.get('errormessage')).contains('No se obtuvo código 200'), 
                      'Debe contener mensaje de error');
    }

    @IsTest
    static void testInvokeMethod_UnsupportedMethod() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = cls.invokeMethod('otroMetodo', new Map<String, Object>(), outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, result);
        System.assert(String.valueOf(outMap.get('errormessage')).contains('Método no soportado'));
    }
    
    @IsTest
    static void testNullInputsAndOptions() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();
        Map<String, Object> outMap = new Map<String, Object>();

        // Pasamos input y options en null
        Test.startTest();
        Boolean result = cls.invokeMethod('pHandlerDocument', null, outMap, null);
        Test.stopTest();

        // Aunque estén en null, debe procesar y devolver algo
        System.assertEquals(false, result);
        System.assert(outMap.containsKey('errormessage') || outMap.containsKey('responseCode'));
    }

    @IsTest
    static void testExceptionInsideLoop() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();

        // fakeResponse que no es un Map, fuerza ClassCastException
        Map<String, Object> input = new Map<String, Object>{
            'maxRetries' => 1,
            'nameIP' => 'FakeIP',
            'fakeResponse' => 'esto no es un map'
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = cls.invokeMethod('pHandlerDocument', input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result);
        System.assert(outMap.containsKey('error'), 'Debe entrar al catch y registrar el error');
    }

    @IsTest
    static void testInvokeMethodCatch() {
        PVU_UploadCaseFilG cls = new PVU_UploadCaseFilG();
        Map<String, Object> input = new Map<String, Object>{
            'maxRetries' => 1,
            'nameIP' => 'FakeIP'
        };
        Map<String, Object> outMap = new Map<String, Object>();

        // Forzamos una excepción directa llamando a un método soportado sin fakeResponse
        Test.startTest();
        Boolean result = cls.invokeMethod('pHandlerDocument', input, outMap, new Map<String, Object>());
        Test.stopTest();

        // Como no hay fakeResponse ni IntegrationProcedure real, debe caer en catch
        System.assertEquals(true, result, 'invokeMethod sigue retornando true');
        System.assert(outMap.containsKey('errormessage'), 'Debe haber capturado la excepción');
    }
}