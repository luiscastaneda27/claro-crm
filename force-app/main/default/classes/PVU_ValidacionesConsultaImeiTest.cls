@IsTest
private class PVU_ValidacionesConsultaImeiTest {

    // ========= Helpers de armado de payload =========

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Map<String, Object> buildProduct(
        String productId,
        String status,
        String imei,
        Boolean isValid,
        String bdaCodigo,
        String bdaCodigoError,
        String bdaDescripcionError,
        String bdoCodigo,
        Boolean bdoIsReported,
        Boolean includeBlacklist
    ) {
        Map<String, Object> prod = new Map<String, Object>();
        prod.put('id', productId);
        prod.put('status', status);

        List<Object> chars = new List<Object>();

        // imei
        chars.add(new Map<String, Object>{
            'name' => 'imei',
            'value' => imei
        });

        // isValid
        chars.add(new Map<String, Object>{
            'name' => 'isValid',
            'value' => isValid
        });

        // brand/model (extras)
        chars.add(new Map<String, Object>{ 'name' => 'brand', 'value' => 'ACME' });
        chars.add(new Map<String, Object>{ 'name' => 'model', 'value' => 'ULTRA-9000' });

        if (includeBlacklist == true) {
            Map<String, Object> bdaPositivo = new Map<String, Object>();
            if (bdaCodigo != null) {
                bdaPositivo.put('codigo', bdaCodigo);
            }
            if (bdaCodigoError != null) {
                bdaPositivo.put('codigoError', bdaCodigoError);
            }
            if (bdaDescripcionError != null) {
                bdaPositivo.put('descripcionError', bdaDescripcionError);
            }

            Map<String, Object> bdoNegativo = new Map<String, Object>();
            if (bdoCodigo != null) {
                bdoNegativo.put('codigo', bdoCodigo);
            }
            if (bdoIsReported != null) {
                bdoNegativo.put('isReported', bdoIsReported);
            }

            Map<String, Object> blacklist = new Map<String, Object>{
                'bdaPositivo' => bdaPositivo,
                'bdoNegativo' => bdoNegativo
            };

            // Ojo: en la clase productCharacteristic.blacklist espera "value" como Map
            chars.add(new Map<String, Object>{
                'name'  => 'blacklist',
                'value' => blacklist
            });
        }

        prod.put('productCharacteristic', chars);
        return prod;
    }

    private static Map<String, Object> buildPayloadWithProducts(List<Object> products) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('customer', new Map<String, Object>{
            'product' => products
        });
        return payload;
    }

    // ========= Tests =========

    @IsTest
    static void testRegisteredSingleProductJsonStringKey() {
        // BDA=01 => registrado
        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{
            buildProduct(
                'P1', 'Active', '123456789012345', true,
                '01', null, null,
                '0', false,
                true
            )
        });

        Map<String, Object> inputMap = new Map<String, Object>{
            'json' => System.JSON.serialize(payload) // fuerza rama "String JSON"
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true');
        System.assertEquals(true, (Boolean) outMap.get('esValido'), 'esValido debe ser true para producto registrado');
        System.assertEquals(true, (Boolean) outMap.get('estaRegistrado'), 'estaRegistrado debe ser true para BDA=01');
        System.assertEquals('01', (String) outMap.get('bdaCodigo'), 'bdaCodigo debe ser 01');
        System.assertEquals('CONTINUAR_PUNTO_2', (String) outMap.get('accionSugerida'), 'accionSugerida debe ser CONTINUAR_PUNTO_2');
        System.assertEquals(false, (Boolean) outMap.get('tieneReporteNegativo'), 'No debe haber reporte negativo en BDO');
        System.assertEquals('123456789012345', (String) outMap.get('imei'), 'IMEI debe propagarse al outMap');

        // productos list
        List<Object> productos = (List<Object>) outMap.get('productos');
        System.assertEquals(1, productos.size(), 'Debe exponer lista productos con 1 item');
        Map<String, Object> r0 = (Map<String, Object>) productos[0];
        System.assertEquals(true, (Boolean) r0.get('estaRegistrado'), 'Producto debe marcarse como registrado');
    }

    @IsTest
    static void testNoRegisteredWithBdoNegativeMapPayloadKey() {
        // BDA=07 => no registrado, y BDO negativo => REGISTRAR_CON_ALERTA_BDO
        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{
            buildProduct(
                'P2', 'Active', '999999999999999', true,
                '07', null, null,
                '1', true,
                true
            )
        });

        Map<String, Object> inputMap = new Map<String, Object>{
            'payload' => payload // fuerza rama "Map directo"
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true para payload válido');
        System.assertEquals(true, (Boolean) outMap.get('esValido'), 'esValido debe ser true');
        System.assertEquals(false, (Boolean) outMap.get('estaRegistrado'), 'estaRegistrado debe ser false para BDA=07');
        System.assertEquals('07', (String) outMap.get('bdaCodigo'), 'bdaCodigo debe ser 07');
        System.assertEquals(true, (Boolean) outMap.get('tieneReporteNegativo'), 'Debe detectar reporte negativo');
        System.assertEquals('REGISTRAR_CON_ALERTA_BDO', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser REGISTRAR_CON_ALERTA_BDO');
    }

    @IsTest
    static void testMultiProductMixedDecidible() {
        // 2 productos: uno indeterminado, uno decidible (07)
        Map<String, Object> pInd = buildProduct(
            'P3', 'Active', '111111111111111', true,
            '99', null, 'cualquier cosa',
            '0', false,
            true
        );
        Map<String, Object> pDec = buildProduct(
            'P4', 'Active', '222222222222222', true,
            '07', null, null,
            '0', false,
            true
        );

        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{ pInd, pDec });

        // Fuerza rama: inputMap ya "parece payload" porque tiene customer
        Map<String, Object> inputMap =
            (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(payload));

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true en multiproducto');
        System.assertEquals(true, (Boolean) outMap.get('esValido'),
            'esValido debe ser true si al menos un producto es decidible');
        System.assertEquals('OK_MULTIPRODUCTO', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser OK_MULTIPRODUCTO');
        System.assert(((String) outMap.get('mensaje')).contains('Validación completada'),
            'Mensaje esperado multi-producto');

        List<Object> productos = (List<Object>) outMap.get('productos');
        System.assertEquals(2, productos.size(), 'Deben devolverse 2 productos en la lista');

        // Debe haber uno con BDA=07 (decidible)
        Boolean found07 = false;
        for (Object o : productos) {
            Map<String,Object> r = (Map<String,Object>) o;
            if ((String) r.get('bdaCodigo') == '07') {
                found07 = true;
            }
        }
        System.assertEquals(true, found07, 'Debe existir un producto con BDA=07');
    }

    @IsTest
    static void testIndeterminateWithErrorIntegrationBDA() {
        // BDA sin 01/07 pero con codigoError => ERROR_INTEGRACION_BDA
        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{
            buildProduct(
                'P5', 'Active', '333333333333333', true,
                null, '500', 'Fallo servicio BDA',
                '0', false,
                true
            )
        });

        Map<String, Object> inputMap = new Map<String, Object>{
            'json' => System.JSON.serialize(payload)
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok,
            'invokeMethod retorna true aunque esValido sea false (no hay exception)');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando hay error en BDA');
        System.assertEquals('ERROR_INTEGRACION_BDA', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser ERROR_INTEGRACION_BDA');
        System.assert(((String) outMap.get('mensaje')).toLowerCase().contains('error'),
            'Debe indicar error de BDA en el mensaje');
    }

    @IsTest
    static void testIndeterminateWithoutErrorErrorIndeterminado() {
        // BDA codigo != 01/07 y sin codigoError => ERROR_INDETERMINADO
        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{
            buildProduct(
                'P6', 'Active', '444444444444444', true,
                '88', null, 'Sin match',
                '0', false,
                true
            )
        });

        Map<String, Object> inputMap = new Map<String, Object>{
            'payload' => payload
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando no se puede determinar el estado');
        System.assertEquals('ERROR_INDETERMINADO', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser ERROR_INDETERMINADO');
        System.assert(((String) outMap.get('mensaje')).contains('No se pudo determinar'),
            'Mensaje indeterminado esperado');
    }

    @IsTest
    static void testPayloadMissingCustomerFails() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'payload' => new Map<String, Object>{ 'foo' => 'bar' }
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true incluso con payload inválido');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando falta customer');
        System.assertEquals('ERROR_PAYLOAD', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser ERROR_PAYLOAD');
        System.assert(((String) outMap.get('mensaje')).contains('customer'),
            'Debe fallar por falta de customer en el payload');
    }

    @IsTest
    static void testPayloadMissingProductFails() {
        Map<String, Object> payload = new Map<String, Object>{
            'customer' => new Map<String, Object>() // sin product
        };
        Map<String, Object> inputMap = new Map<String, Object>{ 'payload' => payload };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true incluso sin product');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando falta product');
        System.assertEquals('ERROR_PAYLOAD', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser ERROR_PAYLOAD');
        System.assert(((String) outMap.get('mensaje')).contains('customer.product'),
            'Debe fallar por falta de customer.product');
    }

    @IsTest
    static void testProductWithoutBlacklistIsNotDecidible() {
        // Producto sin blacklist => mensaje ERROR_PAYLOAD por producto; overall esValido false
        Map<String, Object> payload = buildPayloadWithProducts(new List<Object>{
            buildProduct(
                'P7', 'Active', '555555555555555', true,
                '01', null, null,
                '0', false,
                false // includeBlacklist = false
            )
        });

        Map<String, Object> inputMap = new Map<String, Object>{ 'payload' => payload };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('validarConsultaImei', inputMap, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe retornar true aun sin blacklist');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando no se puede evaluar por falta de blacklist');

        List<Object> productos = (List<Object>) outMap.get('productos');
        System.assertEquals(1, productos.size(), 'Debe haber 1 producto en la salida');
        Map<String,Object> r0 = (Map<String,Object>) productos[0];
        System.assertEquals('ERROR_PAYLOAD', (String) r0.get('accionSugerida'),
            'accionSugerida del producto debe ser ERROR_PAYLOAD');
        System.assert(((String) r0.get('mensaje')).contains('blacklist'),
            'Debe indicar falta de blacklist en el mensaje');
    }

    @IsTest
    static void testUnsupportedMethod() {
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        PVU_ValidacionesConsultaImei svc = new PVU_ValidacionesConsultaImei();
        Boolean ok = svc.invokeMethod('metodoQueNoExiste', new Map<String,Object>(), outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(false, ok,
            'Cuando método no soportado, invokeMethod debe retornar false');
        System.assertEquals(false, (Boolean) outMap.get('esValido'),
            'esValido debe ser false cuando el método no es soportado');
        System.assertEquals('ERROR_METODO', (String) outMap.get('accionSugerida'),
            'accionSugerida debe ser ERROR_METODO');
        System.assert(((String) outMap.get('mensaje')).contains('Método no soportado'),
            'Mensaje debe indicar que el método no está soportado');
    }
}