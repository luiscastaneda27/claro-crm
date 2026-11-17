@isTest
private class FINPlazoByPaymentInitialTest {

    

    @isTest
    static void testObtenerPlazosValidos_Tecnologia() {
        // Simulación de datos de entrada con Tecnología
        Map<String, Object> input = new Map<String, Object>{
            'PaymentInitial' => new Map<String, Object>{
                'Product' => new Map<String, Object>{
                    'TipoDeProducto' => 'Tecnologia'
                },
                'Quote' => new Map<String, Object>{
                    'PagosInicialesTecnologia' => new Map<String, Object>{
                        'pagoInicialTecnologia_6' => '30',
                        'pagoInicialTecnologia_18' => '40'
                    }
                }
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();
        
        // Ejecutar el método
        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        // Validaciones
        System.assert(outMap.containsKey('Plazos_Validos_HDC'), 'Debe contener el key Plazos_Validos_HDC');
        System.assertEquals(new List<String>{'1-6', '13-18'}, outMap.get('Plazos_Validos_HDC'), 'Los rangos no coinciden');

        System.assert(outMap.containsKey('Numero_Mayor'), 'Debe contener el key Numero_Mayor');
        System.assertEquals(18, outMap.get('Numero_Mayor'), 'El número mayor debe ser 18');
    }

    @isTest
    static void testObtenerNumeroMayor() {
        // Lista de rangos
        List<String> rangos = new List<String>{'1-6', '7-12', '13-18', '25-36'};
        
        // Validar que el mayor sea 36
        Integer max = FINPlazoByPaymentInitial.obtenerNumeroMayor(rangos);
        System.assertEquals(36, max, 'El número mayor debe ser 36');
    }

    @isTest
    static void testSinPagosIniciales() {
        // Simulación de datos sin Pagos Iniciales
        Map<String, Object> input = new Map<String, Object>{
            'PaymentInitial' => new Map<String, Object>{
                'Product' => new Map<String, Object>{
                    'TipoDeProducto' => 'Terminales'
                },
                'Quote' => new Map<String, Object>{}
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();
        
        // Ejecutar el método
        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        // Validaciones
        System.assert(outMap.containsKey('Plazos_Validos_HDC'), 'Debe contener el key Plazos_Validos_HDC');
        System.assertEquals(new List<String>(), outMap.get('Plazos_Validos_HDC'), 'Debe estar vacío');

        System.assert(outMap.containsKey('Numero_Mayor'), 'Debe contener el key Numero_Mayor');
        System.assertEquals(0, outMap.get('Numero_Mayor'), 'El número mayor debe ser 0');
    }
}