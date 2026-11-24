@IsTest
private class FINPlazoByPaymentInitialTest {
    @IsTest
    static void testObtenerPlazosValidos_Tecnologia() {
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

        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        System.assert(outMap.containsKey('Plazos_Validos_HDC'), 'Debe contener el key Plazos_Validos_HDC');
        System.assertEquals(new List<String>{'1-6', '13-18'}, outMap.get('Plazos_Validos_HDC'), 'Los rangos no coinciden');
        System.assert(outMap.containsKey('Numero_Mayor'), 'Debe contener el key Numero_Mayor');
        System.assertEquals(18, outMap.get('Numero_Mayor'), 'El numero mayor debe ser 18');
    }

    @IsTest
    static void testObtenerPlazosValidos_TerminalesHasta24() {
        Map<String, Object> input = new Map<String, Object>{
            'PaymentInitial' => new Map<String, Object>{
                'Product' => new Map<String, Object>{
                    'TipoDeProducto' => 'Terminales'
                },
                'Quote' => new Map<String, Object>{
                    'PagosInicialesTerminales' => new Map<String, Object>{
                        'pagoInicialTerminales_1' => '0',
                        'pagoInicialTerminales_6' => '0',
                        'pagoInicialTerminales_12' => '0',
                        'pagoInicialTerminales_18' => '0',
                        'pagoInicialTerminales_24' => '100'
                    }
                }
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();

        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        System.assertEquals(
            new Set<String>{'1-6', '7-12', '13-18', '19-24'},
            new Set<String>((List<String>) outMap.get('Plazos_Validos_HDC')),
            'Terminales debe llegar hasta 24 cuando pagoInicialTerminales_24 viene en 100.'
        );
        System.assertEquals(24, outMap.get('Numero_Mayor'), 'El numero mayor debe ser 24');
    }

    @IsTest
    static void testObtenerPlazosValidos_TerminalesHasta36() {
        Map<String, Object> input = new Map<String, Object>{
            'PaymentInitial' => new Map<String, Object>{
                'Product' => new Map<String, Object>{
                    'TipoDeProducto' => 'Terminales'
                },
                'Quote' => new Map<String, Object>{
                    'PagosInicialesTerminales' => new Map<String, Object>{
                        'pagoInicialTerminales_1' => '1',
                        'pagoInicialTerminales_6' => '1',
                        'pagoInicialTerminales_12' => '1',
                        'pagoInicialTerminales_18' => '1',
                        'pagoInicialTerminales_24' => '1'
                    }
                }
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();

        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        System.assertEquals(
            new Set<String>{'1-6', '7-12', '13-18', '19-24', '25-36'},
            new Set<String>((List<String>) outMap.get('Plazos_Validos_HDC')),
            'Terminales debe llegar hasta 36 cuando pagoInicialTerminales_24 es diferente de 100.'
        );
        System.assertEquals(36, outMap.get('Numero_Mayor'), 'El numero mayor debe ser 36');
    }

    @IsTest
    static void testObtenerNumeroMayor() {
        List<String> rangos = new List<String>{'1-6', '7-12', '13-18', '25-36'};

        Integer max = FINPlazoByPaymentInitial.obtenerNumeroMayor(rangos);
        System.assertEquals(36, max, 'El numero mayor debe ser 36');
    }

    @IsTest
    static void testSinPagosIniciales() {
        Map<String, Object> input = new Map<String, Object>{
            'PaymentInitial' => new Map<String, Object>{
                'Product' => new Map<String, Object>{
                    'TipoDeProducto' => 'Terminales'
                },
                'Quote' => new Map<String, Object>{}
            }
        };

        Map<String, Object> outMap = new Map<String, Object>();

        FINPlazoByPaymentInitial instance = new FINPlazoByPaymentInitial();
        instance.invokeMethod('obtenerPlazosValidos', input, outMap, new Map<String, Object>());

        System.assert(outMap.containsKey('Plazos_Validos_HDC'), 'Debe contener el key Plazos_Validos_HDC');
        System.assertEquals(new List<String>(), outMap.get('Plazos_Validos_HDC'), 'Debe estar vacio');
        System.assert(outMap.containsKey('Numero_Mayor'), 'Debe contener el key Numero_Mayor');
        System.assertEquals(0, outMap.get('Numero_Mayor'), 'El numero mayor debe ser 0');
    }
}