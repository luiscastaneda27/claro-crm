@isTest
private class FIN_PriceTermValidationTest {

    @isTest
    static void testInvokeMethod_GetPlazosByPrice() {
        Map<String, Object> input = new Map<String, Object>{
            'DecisionMatrixAction' => new List<Object>{
                new Map<String, Object>{
                    '25-36' => true,
                    '13-18' => true,
                    '1-6' => true,
                    '19-24' => true,
                    '7-12' => true,
                    'PVPMax' => '4.500.000'
                }
            },
            'Producto' => 'Tecnologia'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = new FIN_PriceTermValidation().invokeMethod('getPlazosByPrice', input, outMap, options);
		Test.stopTest();
        
        Assert.isTrue(result, 'El método debe devolver true');
        Assert.isTrue(outMap.containsKey('Plazos'), 'El mapa de salida debe contener "Plazos"');
    }

    @isTest
    static void testInvokeMethod_GetPlazosByTasaInteres() {
        Map<String, Object> input = new Map<String, Object>{
            'Plazos' => new List<Object>{ '1-3', '5-6' }
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

		Test.startTest();
        Boolean result = new FIN_PriceTermValidation().invokeMethod('getPlazosByTasaInteres', input, outMap, options);
		Test.stopTest();
        
        Assert.isTrue(result, 'El método debe devolver true');
        Assert.isTrue(outMap.containsKey('PlazosTotal'), 'Debe devolver una lista de plazos generados');

        List<Map<String, Object>> plazosTotal = (List<Map<String, Object>>) outMap.get('PlazosTotal');
        Assert.areEqual(5, plazosTotal.size(), 'Debe haber 5 plazos generados');
    }

    @isTest
    static void testInvokeMethod_InvalidMethod() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
		
        Test.startTest();
        Boolean result = new FIN_PriceTermValidation().invokeMethod('invalidMethod', input, outMap, options);
		Test.stopTest();
        
        Assert.isTrue(result, 'El método debe devolver true aunque el nombre no sea válido');
        Assert.areEqual(0, outMap.size(), 'No debe haber modificaciones en outMap');
    }

    @isTest
    static void testStart() {
        Map<String, Object> input = new Map<String, Object>{
            'DecisionMatrixAction' => new List<Object>{
                new Map<String, Object>{
                    '25-36' => true,
                    '13-18' => true,
                    '1-6' => true,
                    '19-24' => true,
                    '7-12' => true,
                    'PVPMax' => '4.500.000'
                }
            },
            'Producto' => 'Tecnologia'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = new FIN_PriceTermValidation().invokeMethod('getPlazosByPrice', input, outMap, options);
        Test.stopTest();

        Assert.isTrue(result, 'testStart: El método debe devolver true');
    }

    @isTest
    static void testStop() {
        Map<String, Object> input = new Map<String, Object>{
            'Plazos' => new List<Object>{ '1-3', '5-6' }
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = new FIN_PriceTermValidation().invokeMethod('getPlazosByTasaInteres', input, outMap, options);
        Test.stopTest();

        Assert.isTrue(outMap.containsKey('PlazosTotal'), 'testStop: El mapa de salida debe contener "PlazosTotal"');
    }
}