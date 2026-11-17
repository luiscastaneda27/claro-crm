@IsTest
private class PVU_AdditionalServicesDataTest {

    // Utilidad: crea un Map (registro) con campos comunes y permite overrides
    private static Map<String, Object> makeItem(String name, String subtipo, Map<String, Object> overrides) {
        Map<String, Object> m = new Map<String, Object>{
            'name' => name,
            'Subtipo' => subtipo,
            'vencido' => false,
            'tieneDatos' => true,   // por defecto true (solo para 'Datos' interesa)
            'productCode' => 'TEST_' + name.replace(' ', '_')
        };
        if (overrides != null) {
            for (String k : overrides.keySet()) m.put(k, overrides.get(k));
        }
        return m;
    }

    @IsTest
    static void testInvoke_withItemsList_filtersCorrectly() {
        // Datos: uno válido y uno inválido
        Map<String,Object> datosOk    = makeItem('Datos OK', 'Datos', new Map<String,Object>{ 'vencido' => false, 'tieneDatos' => true,  'productCode' => 'PC_DAT_OK' });
        Map<String,Object> datosBad   = makeItem('Datos BAD', 'Datos', new Map<String,Object>{ 'vencido' => true,  'tieneDatos' => false, 'productCode' => 'PC_DAT_BAD' });

        // LDI: válido (no vencido) e inválido (vencido)
        Map<String,Object> ldiOk      = makeItem('LDI OK', 'LDI', new Map<String,Object>{ 'vencido' => false, 'productCode' => 'PC_LDI_OK' });
        Map<String,Object> ldiBad     = makeItem('LDI BAD', 'LDI', new Map<String,Object>{ 'vencido' => true,  'productCode' => 'PC_LDI_BAD' });

        // Roaming: válido
        Map<String,Object> roamOk     = makeItem('ROAM OK', 'Roaming Internacional', new Map<String,Object>{ 'vencido' => false, 'productCode' => 'PC_ROAM_OK' });

        // Otro subtipo (OTT) debe pasar tal cual
        Map<String,Object> ott        = makeItem('OTT', 'OTT', new Map<String,Object>{ 'productCode' => 'PC_OTT' });

        Map<String, Object> input = new Map<String, Object>{
            'items' => new List<Object>{ datosOk, datosBad, ldiOk, ldiBad, roamOk, ott }
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean ok = new PVU_AdditionalServicesData()
            .invokeMethod('filterAdditionalServicesJson', input, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok, 'invokeMethod debe devolver true para el método soportado');
        System.assert(outMap.containsKey('listAsset'), 'outMap debe contener listAsset');

        List<Object> result = (List<Object>) outMap.get('listAsset');
        System.assertEquals(4, result.size(), 'Deben quedar 4 elementos: Datos OK, LDI OK, Roaming OK y OTT');

        // Validar por productCode los que quedaron
        Set<String> pcs = new Set<String>();
        for (Object o : result) {
            Map<String,Object> row = (Map<String,Object>) o;
            pcs.add((String)row.get('productCode'));
        }
        System.assert(pcs.contains('PC_DAT_OK'), 'Debe incluir Datos OK');
        System.assert(!pcs.contains('PC_DAT_BAD'), 'No debe incluir Datos BAD (vencido y sin datos)');
        System.assert(pcs.contains('PC_LDI_OK'), 'Debe incluir LDI OK');
        System.assert(!pcs.contains('PC_LDI_BAD'), 'No debe incluir LDI BAD (vencido)');
        System.assert(pcs.contains('PC_ROAM_OK'), 'Debe incluir Roaming OK');
        System.assert(pcs.contains('PC_OTT'), 'Debe incluir OTT tal cual');
    }

    @IsTest
    static void testInvoke_withRawJsonPayload_filtersCorrectly() {
        // Array JSON crudo: 1 Datos válido, 1 Datos inválido, 1 OTT
        String payload = JSON.serialize(new List<Object>{
            makeItem('Datos OK', 'Datos', new Map<String,Object>{ 'vencido' => false, 'tieneDatos' => true,  'productCode' => 'PC_DAT_OK_2' }),
            makeItem('Datos BAD', 'Datos', new Map<String,Object>{ 'vencido' => true,  'tieneDatos' => false, 'productCode' => 'PC_DAT_BAD_2' }),
            makeItem('OTT', 'OTT', new Map<String,Object>{ 'productCode' => 'PC_OTT_2' })
        });
        // Enviamos como "json" (cualquiera de json/raw/payload sirve según la clase)
        Map<String, Object> input = new Map<String, Object>{ 'json' => payload };

        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Boolean ok = new PVU_AdditionalServicesData()
            .invokeMethod('filterAdditionalServicesJson', input, outMap, null);
        Test.stopTest();

        System.assertEquals(true, ok);
        System.assert(outMap.containsKey('listAsset'));

        List<Object> res = (List<Object>) outMap.get('listAsset');
        System.assertEquals(2, res.size(), 'Deben quedar 2: Datos OK y OTT');

        Set<String> pcs = new Set<String>();
        for (Object o : res) pcs.add((String)((Map<String,Object>)o).get('productCode'));
        System.assert(pcs.contains('PC_DAT_OK_2'), 'Incluye Datos OK');
        System.assert(!pcs.contains('PC_DAT_BAD_2'), 'Excluye Datos BAD');
        System.assert(pcs.contains('PC_OTT_2'), 'Incluye OTT');
    }

    @IsTest
    static void testStatic_filterAdditionalServicesJson_direct() {
        // Llamada directa al método @AuraEnabled con JSON
        String raw = JSON.serialize(new List<Object>{
            makeItem('LDI OK', 'LDI', new Map<String,Object>{ 'vencido' => false, 'productCode' => 'PC_LDI_OK_3' }),
            makeItem('LDI BAD', 'LDI', new Map<String,Object>{ 'vencido' => true,  'productCode' => 'PC_LDI_BAD_3' })
        });

        Test.startTest();
        List<Map<String,Object>> filtered = PVU_AdditionalServicesData.filterAdditionalServicesJson(raw);
        Test.stopTest();

        System.assertEquals(1, filtered.size(), 'Solo LDI OK debe quedar');
        System.assertEquals('PC_LDI_OK_3', (String)filtered[0].get('productCode'));
    }

    @IsTest
    static void testInvoke_methodUnsupported() {
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Boolean ok = new PVU_AdditionalServicesData()
            .invokeMethod('unknownMethod', new Map<String,Object>(), outMap, null);
        Test.stopTest();

        System.assertEquals(false, ok, 'Método no soportado debe devolver false');
        System.assert(outMap.containsKey('error'), 'Debe informar error en outMap');
    }

    @IsTest
    static void testInvoke_methodNameBlank() {
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Boolean ok = new PVU_AdditionalServicesData()
            .invokeMethod('', new Map<String,Object>(), outMap, null);
        Test.stopTest();

        System.assertEquals(false, ok, 'methodName vacío debe devolver false');
        System.assert(outMap.containsKey('error'), 'Debe informar error en outMap');
    }

    @IsTest
    static void testInvoke_nullOutMapHandled() {
        // Verifica que si outMap llega null, la clase lo maneje sin NPE y retorne true
        Map<String,Object> input = new Map<String,Object>{
            'items' => new List<Object>{
                makeItem('OTT', 'OTT', new Map<String,Object>{ 'productCode' => 'PC_OTT_3' })
            }
        };

        Test.startTest();
        Boolean ok = new PVU_AdditionalServicesData()
            .invokeMethod('filterAdditionalServicesJson', input, null, null);
        Test.stopTest();

        System.assertEquals(true, ok, 'Debe ejecutar incluso con outMap=null (la clase lo protege internamente)');
        // No podemos leer outMap aquí porque era null en la llamada;
        // esta prueba solo asegura que no reviente con NPE y retorne true.
    }
    @IsTest
static void testInvoke_fallbackWithArbitraryKeyList() {
    // Armamos una lista bajo una clave NO estándar (ni items, ni list, ni records, etc.)
    // para forzar la rama fallback del extractListFromInput.
    Map<String,Object> datosBad = new Map<String,Object>{
        'name' => 'Datos BAD',
        'Subtipo' => 'Datos',
        'vencido' => true,
        'tieneDatos' => false,
        'productCode' => 'PC_FALLBACK_DAT_BAD'
    };
    Map<String,Object> ottOk = new Map<String,Object>{
        'name' => 'OTT OK',
        'Subtipo' => 'OTT',
        'vencido' => false,
        'productCode' => 'PC_FALLBACK_OTT_OK'
    };

    // Clave arbitraria: "weirdKey"
    Map<String, Object> input = new Map<String, Object>{
        'weirdKey' => new List<Object>{ datosBad, ottOk }
    };

    Map<String, Object> outMap = new Map<String, Object>();

    Test.startTest();
    Boolean ok = new PVU_AdditionalServicesData()
        .invokeMethod('filterAdditionalServicesJson', input, outMap, null);
    Test.stopTest();

    System.assertEquals(true, ok, 'invokeMethod debe retornar true');
    System.assert(outMap.containsKey('listAsset'), 'Debe poblar outMap.listAsset');

    List<Object> result = (List<Object>) outMap.get('listAsset');
    // Debe incluir solo el OTT (los "Datos" están vencidos y sin datos)
    System.assertEquals(1, result.size(), 'Solo debe quedar 1 elemento (OTT OK)');

    Map<String,Object> only = (Map<String,Object>) result[0];
    System.assertEquals('PC_FALLBACK_OTT_OK', (String)only.get('productCode'), 'Debe quedar el OTT OK del fallback');
}


    // ---------------------------
    // Helpers para crear Map test
    // ---------------------------
    private static Map<String, Object> makeAsset(
        String numeroTelefono, String productCode,
        Boolean vencido, Boolean tieneDatos,
        String subtipo
    ) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('numeroTelefono', numeroTelefono);
        m.put('productCode', productCode);
        if (vencido != null)     m.put('vencido', vencido);
        if (tieneDatos != null)  m.put('tieneDatos', tieneDatos);
        if (subtipo != null)     m.put('Subtipo', subtipo);
        m.put('name', 'Asset ' + productCode);
        return m;
    }

    private static Map<String, Object> makeConsumo(
        String msisdn, String productCode,
        Boolean tieneDatos, String datosDisponibles
    ) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('msisdn', msisdn);
        m.put('productCode', productCode);
        if (tieneDatos != null)     m.put('tieneDatos', tieneDatos);
        if (datosDisponibles != null) m.put('datosDisponibles', datosDisponibles);
        return m;
    }

   

    // -----------------------------------------------------------------
    // Test: mergeAssetsConsumosFromInput con claves alternativas (imagen)
    // -----------------------------------------------------------------
    @IsTest
static void test_mergeAssetsConsumosFromInput_namedKeys() {
    Map<String, Object> input = new Map<String, Object>();

    // assets bajo DRTAdditionalServicesDatasets
    List<Object> drt = new List<Object>();
    drt.add(makeAsset('573100006421', 'PO_MovPosAddOnDatos006', false, null, 'Datos'));
    input.put('DRTAdditionalServicesDatasets', drt);

    // consumos bajo "LoopServices:consumos"
    List<Object> consumoList = new List<Object>();
    consumoList.add(''); // ruido
    consumoList.add(makeConsumo('573100006421', 'PO_MovPosAddOnDatos006', true, '111')); // o '111'
    input.put('LoopServices:consumos', consumoList);

    List<Map<String, Object>> merged =
        PVU_AdditionalServicesData.mergeAssetsConsumosFromInput(input);

    System.assertEquals(1, merged.size());
    System.assertEquals(true, (Boolean) merged[0].get('tieneDatos'));
    System.assertEquals('111', (String) merged[0].get('datosDisponibles'));
}


    // -------------------------------------------------------
    // Test: invokeMethod('mergeAssetsConsumos') happy path
    // -------------------------------------------------------
    @IsTest
    static void test_invokeMethod_mergeAssetsConsumos() {
        Map<String, Object> input = new Map<String, Object>();
        input.put('assets', new List<Object>{
            makeAsset('573100006421', 'X1', false, null, 'OTT')
        });
        input.put('consumos', new List<Object>{
            makeConsumo('573100006421', 'X1', true, '2048')
        });

        Map<String, Object> outMap = new Map<String, Object>();

        Boolean ok = new PVU_AdditionalServicesData().invokeMethod(
            'mergeAssetsConsumos', input, outMap, new Map<String, Object>()
        );

        System.assertEquals(true, ok, 'Debe retornar true');
        System.assert(outMap.containsKey('listAsset'), 'Debe devolver listAsset');
        List<Object> outList = (List<Object>) outMap.get('listAsset');
        System.assertEquals(1, outList.size());

        Map<String, Object> a = (Map<String, Object>) outList[0];
        System.assertEquals(true, (Boolean)a.get('tieneDatos'));
        System.assertEquals('2048', (String)a.get('datosDisponibles'));
    }

    // -------------------------------------------------------
    // Test: invokeMethod - methodName inválido
    // -------------------------------------------------------
    @IsTest
    static void test_invokeMethod_invalidName() {
        Map<String, Object> outMap = new Map<String, Object>();
        Boolean ok = new PVU_AdditionalServicesData().invokeMethod(
            'noExiste', new Map<String, Object>(), outMap, new Map<String, Object>()
        );
        System.assertEquals(false, ok);
        System.assert( ((String)outMap.get('error')).contains('Método no soportado') );
    }

    // -------------------------------------------------------
    // Test: filterAdditionalServices (validaciones por subtipo)
    // -------------------------------------------------------
    @IsTest
    static void test_filterAdditionalServices_rules() {
        List<Map<String, Object>> items = new List<Map<String, Object>>();

        // Datos: pasa solo si !vencido y tieneDatos
        items.add(makeAsset('1','PDAT-OK', false, true,  'Datos')); // pasa
        items.add(makeAsset('1','PDAT-NO1', true,  true,  'Datos')); // no pasa
        items.add(makeAsset('1','PDAT-NO2', false, false, 'Datos')); // no pasa

        // LDI: pasa si !vencido
        items.add(makeAsset('1','PLDI-OK',  false, true, 'LDI'));   // pasa
        items.add(makeAsset('1','PLDI-NO1',  true,  true, 'LDI'));   // no pasa
        items.add(makeAsset('1','PLDI-NO2',  false,  false, 'LDI'));   // no pasa


        // Roaming: pasa si !vencido
        items.add(makeAsset('1','PROAM-OK', false, null, 'Roaming')); // pasa
        items.add(makeAsset('1','PROAM-NO', true,  null, 'Roaming Internacional')); // no pasa

        // OTT u otro: pasan siempre
        items.add(makeAsset('1','POTT-OK',  null,  null, 'OTT'));
        items.add(makeAsset('1','POTR-OK',  null,  null, 'Cualquiera'));

        List<Map<String, Object>> filtered =
            PVU_AdditionalServicesData.filterAdditionalServices(items);

        // Esperados: PDAT-OK, PLDI-OK, PROAM-OK, POTT-OK, POTR-OK  => 5
        Set<String> codes = new Set<String>();
        for (Map<String, Object> r : filtered) codes.add( (String) r.get('productCode') );

        System.assertEquals(5, filtered.size());
        System.assertEquals(true,  codes.contains('PDAT-OK'));
        System.assertEquals(false, codes.contains('PDAT-NO1'));
        System.assertEquals(false, codes.contains('PDAT-NO2'));
        System.assertEquals(true,  codes.contains('PLDI-OK'));
        System.assertEquals(false, codes.contains('PLDI-NO1'));
        System.assertEquals(false, codes.contains('PLDI-NO2'));
        System.assertEquals(true,  codes.contains('PROAM-OK'));
        System.assertEquals(false, codes.contains('PROAM-NO'));
        System.assertEquals(true,  codes.contains('POTT-OK'));
        System.assertEquals(true,  codes.contains('POTR-OK'));
    }

    // -------------------------------------------------------
    // Test: filterAdditionalServicesJson (entrada JSON cruda)
    // -------------------------------------------------------
    @IsTest
    static void test_filterAdditionalServicesJson_rawJson() {
        // Tres registros, solo 2 pasan (Datos ok y OTT)
        String raw = JSON.serialize(new List<Object>{
            makeAsset('1','DAT-OK', false, true,  'Datos'),
            makeAsset('1','DAT-NO', false, false, 'Datos'),
            makeAsset('1','OTT-OK', null,  null,  'OTT')
        });

        List<Map<String, Object>> out =
            PVU_AdditionalServicesData.filterAdditionalServicesJson(raw);

        System.assertEquals(2, out.size(), 'Deben pasar DAT-OK y OTT-OK');
        Set<String> pc = new Set<String>();
        for (Map<String, Object> r : out) pc.add( (String) r.get('productCode') );
        System.assert(pc.contains('DAT-OK'));
        System.assert(pc.contains('OTT-OK'));
        System.assert(!pc.contains('DAT-NO'));
    }

    // -------------------------------------------------------
    // Test: entradas vacías o nulas
    // -------------------------------------------------------
    @IsTest
    static void test_emptyInputs() {
        // merge con nulos
        List<Map<String, Object>> merged =
            PVU_AdditionalServicesData.mergeAssetsConsumos(null, null);
        System.assertEquals(0, merged.size());

        // invoke con methodName vacío
        Map<String, Object> outMap = new Map<String, Object>();
        Boolean ok = new PVU_AdditionalServicesData().invokeMethod(
            '', new Map<String, Object>(), outMap, new Map<String, Object>()
        );
        System.assertEquals(false, ok);
        System.assert( ((String)outMap.get('error')).contains('vacío') );

        // filtro con lista nula
        List<Map<String, Object>> out = PVU_AdditionalServicesData.filterAdditionalServices(null);
        System.assertEquals(0, out.size());

        // filtro JSON vacío
        out = PVU_AdditionalServicesData.filterAdditionalServicesJson('');
        System.assertEquals(0, out.size());
    }


    
    
    

}