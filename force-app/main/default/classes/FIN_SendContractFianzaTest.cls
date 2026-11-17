@IsTest
private class FIN_SendContractFianzaTest {
    
    @IsTest
    static void testSendContractFianzaWithFianzaDataFullHappyPathTipoVentaFromRoot() {
        // Arrange usando helper para bajar NCSS
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        Map<String, Object> input = buildHappyPathInputWithRootTipoVenta();
        
        Map<String, Object> outMap   = new Map<String, Object>();
        Map<String, Object> options  = new Map<String, Object>();
        
        // Act
        Test.startTest();
        Boolean ok = svc.invokeMethod('sendContractFianza', input, outMap, options);
        Test.stopTest();
        
        // Assert básicos
        System.assertEquals(true, ok, 'invokeMethod debe devolver true en el happy path');
        System.assert(
            outMap.containsKey('bodyFianza'),
            'Debe generarse el nodo bodyFianza en outMap'
        );
        
        Map<String, Object> bodyFianza    = (Map<String, Object>) outMap.get('bodyFianza');
        Map<String, Object> outMapWrapper = (Map<String, Object>) bodyFianza.get('map');
        List<Object> outMapEntries        = (List<Object>) outMapWrapper.get('mapEntry');
        
        // Buscamos TipoVenta y validamos que se pisó a 48
        Map<String, Object> outTipoVentaEntry = findEntryByKey(outMapEntries, 'TipoVenta');
        System.assertNotEquals(
            null,
            outTipoVentaEntry,
            'Debe existir TipoVenta en los mapEntry'
        );
        System.assertEquals(
            '48',
            (String) outTipoVentaEntry.get('value'),
            'TipoVenta debe venir del parámetro tipoVenta (48), no del 21 original'
        );
    }
    
    @IsTest
    static void testSendContractFianzaTipoVentaFromFianzaWhenNoRoot() {
        // Escenario: no hay tipoVenta en root ni TipoVenta en mapEntry,
        // pero sí viene fianza.tipoVenta -> debe crear el mapEntry.
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        
        Map<String, Object> input      = new Map<String, Object>();
        Map<String, Object> body       = new Map<String, Object>();
        Map<String, Object> fianzaBody = new Map<String, Object>();
        Map<String, Object> fianza     = new Map<String, Object>();
        
        fianza.put('tipoVenta', '48');
        fianzaBody.put('Fianza', fianza);
        
        // Armamos body con map/mapEntry pero SIN TipoVenta
        List<Object> mapEntryList = new List<Object>();
        Map<String, Object> entryNumeroContrato = new Map<String, Object>();
        entryNumeroContrato.put('key', 'NumeroContrato');
        entryNumeroContrato.put('value', 'ABC123');
        mapEntryList.add(entryNumeroContrato);
        
        Map<String, Object> mapWrapper = new Map<String, Object>();
        mapWrapper.put('mapEntry', mapEntryList);
        
        body.put('map', mapWrapper);
        body.put('target', 9);
        
        Map<String, Object> huellaMap = new Map<String, Object>();
        huellaMap.put('huella', '999');
        body.put('huellaYFirmaCliente', huellaMap);
        
        input.put('body', body);
        input.put('fianzaBody', fianzaBody);
        // IMPORTANTE: NO ponemos input.put('tipoVenta', ...) para forzar el fallback a Fianza
        
        Map<String, Object> outMap   = new Map<String, Object>();
        Map<String, Object> options  = new Map<String, Object>();
        
        // Act
        Test.startTest();
        Boolean ok = svc.invokeMethod('sendContractFianza', input, outMap, options);
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, ok, 'invokeMethod debe retornar true');
        System.assert(
            outMap.containsKey('bodyFianza'),
            'Debe generarse bodyFianza cuando hay body válido'
        );
        
        Map<String, Object> bodyFianza    = (Map<String, Object>) outMap.get('bodyFianza');
        Map<String, Object> outMapWrapper = (Map<String, Object>) bodyFianza.get('map');
        List<Object> outMapEntries        = (List<Object>) outMapWrapper.get('mapEntry');
        
        // Debe haberse creado un mapEntry para TipoVenta = 48
        Map<String, Object> outTipoVentaEntry = findEntryByKey(outMapEntries, 'TipoVenta');
        System.assertNotEquals(
            null,
            outTipoVentaEntry,
            'Debe haberse creado el mapEntry de TipoVenta'
        );
        System.assertEquals(
            '48',
            (String) outTipoVentaEntry.get('value'),
            'TipoVenta debe venir de fianza.tipoVenta cuando no hay parámetro root'
        );
    }
    
    // ---- Tests anteriores para mantener cobertura del resto de la lógica ----
    
    @IsTest
    static void testSendContractFianzaWithoutBody() {
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        
        Map<String, Object> input   = new Map<String, Object>();
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean ok = svc.invokeMethod('sendContractFianza', input, outMap, options);
        Test.stopTest();
        
        System.assertEquals(
            true,
            ok,
            'invokeMethod debe retornar true incluso sin body'
        );
        System.assertEquals(
            0,
            outMap.size(),
            'outMap debe quedar vacío cuando no hay body'
        );
    }
    
    @IsTest
    static void testSendContractFianzaWithoutFianzaBodyAndWithoutMap() {
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> body  = new Map<String, Object>();
        
        body.put('target', 2);
        Map<String, Object> huellaMap = new Map<String, Object>();
        huellaMap.put('huella', '777');
        body.put('huellaYFirmaCliente', huellaMap);
        
        input.put('body', body);
        // sin fianzaBody
        
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean ok = svc.invokeMethod('sendContractFianza', input, outMap, options);
        Test.stopTest();
        
        System.assertEquals(
            true,
            ok,
            'invokeMethod debe retornar true aun sin fianzaBody'
        );
        System.assert(
            outMap.containsKey('bodyFianza'),
            'Debe generarse bodyFianza aunque no haya fianzaBody'
        );
        
        Map<String, Object> bodyFianza    = (Map<String, Object>) outMap.get('bodyFianza');
        Map<String, Object> outMapWrapper = (Map<String, Object>) bodyFianza.get('map');
        List<Object> outMapEntries        = (List<Object>) outMapWrapper.get('mapEntry');
        
        System.assertNotEquals(
            null,
            outMapEntries,
            'La lista de mapEntry no debe ser nula'
        );
        System.assertEquals(
            0,
            outMapEntries.size(),
            'Sin map y sin fianza no debe haber entries'
        );
    }
    
    @IsTest
    static void testSendContractFianzaPartialFianzaMissingAndNullValues() {
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        
        Map<String, Object> input      = new Map<String, Object>();
        Map<String, Object> body       = new Map<String, Object>();
        Map<String, Object> fianzaBody = new Map<String, Object>();
        Map<String, Object> fianza     = new Map<String, Object>();
        
        fianza.put('ValorFianzaIva', '12345');
        fianza.put('ValorFinanciadoFianza', null);   // value null
        fianzaBody.put('Fianza', fianza);
        
        Map<String, Object> mapWrapper = new Map<String, Object>();
        body.put('map', mapWrapper);
        body.put('target', 3);
        
        Map<String, Object> huellaMap = new Map<String, Object>();
        huellaMap.put('huella', '555');
        body.put('huellaYFirmaCliente', huellaMap);
        
        input.put('body', body);
        input.put('fianzaBody', fianzaBody);
        
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean ok = svc.invokeMethod('sendContractFianza', input, outMap, options);
        Test.stopTest();
        
        System.assertEquals(
            true,
            ok,
            'invokeMethod debe retornar true en escenario parcial'
        );
        
        Map<String, Object> bodyFianza    = (Map<String, Object>) outMap.get('bodyFianza');
        Map<String, Object> outMapWrapper = (Map<String, Object>) bodyFianza.get('map');
        List<Object> outMapEntries        = (List<Object>) outMapWrapper.get('mapEntry');
        
        Map<String, Object> valorFianzaIvaEntry =
            findEntryByKey(outMapEntries, 'ValorFianzaIva');
        System.assertNotEquals(
            null,
            valorFianzaIvaEntry,
            'Debe existir entry para ValorFianzaIva'
        );
        System.assertEquals(
            '12345',
            (String) valorFianzaIvaEntry.get('value'),
            'ValorFianzaIva debe mantenerse igual'
        );
        
        Map<String, Object> valorFinanciadoFianzaEntry =
            findEntryByKey(outMapEntries, 'ValorFinanciadoFianza');
        System.assertNotEquals(
            null,
            valorFinanciadoFianzaEntry,
            'Debe existir entry para ValorFinanciadoFianza'
        );
        System.assertEquals(
            null,
            valorFinanciadoFianzaEntry.get('value'),
            'ValorFinanciadoFianza debe quedar en null si venía null'
        );
    }
    
    @IsTest
    static void testInvokeMethodWithOtherMethodName() {
        FIN_SendContractFianza svc = new FIN_SendContractFianza();
        
        Map<String, Object> input   = new Map<String, Object>();
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean ok = svc.invokeMethod('otroMetodo', input, outMap, options);
        Test.stopTest();
        
        System.assertEquals(
            true,
            ok,
            'invokeMethod debe retornar true aunque el método no exista'
        );
        System.assertEquals(
            0,
            outMap.size(),
            'No debe tocar outMap si el método no es sendContractFianza'
        );
    }
    
    // Helper para buscar un mapEntry según la key
    private static Map<String, Object> findEntryByKey(List<Object> entries, String keyName) {
        for (Object o : entries) {
            Map<String, Object> entry = (Map<String, Object>) o;
            if (entry != null && entry.containsKey('key') && (String)entry.get('key') == keyName) {
                return entry;
            }
        }
        return null;
    }
    
    // Helper para armar el input completo del happy path con tipoVenta en root
    private static Map<String, Object> buildHappyPathInputWithRootTipoVenta() {
        Map<String, Object> input      = new Map<String, Object>();
        Map<String, Object> body       = new Map<String, Object>();
        Map<String, Object> fianzaBody = new Map<String, Object>();
        Map<String, Object> fianza     = new Map<String, Object>();
        
        // Nodo Fianza completo
        fianza.put('NumeroMes', '6');
        fianza.put('CuotaFianza', '106175');
        fianza.put('Sigla', 'FGA');
        fianza.put('contractFianza', true);
        fianza.put('ValorProductoFinanciado', '590900');
        fianza.put('ValorCuotaMensualFinanciado', '0.05');
        fianza.put('tipoVenta', '48'); // también lo mandamos en Fianza
        fianza.put('CuotaProductoFinanciado', '4924.17');
        fianza.put('ValorFianzaIva', '29545');
        fianza.put('ValorTotalFinanciadoFianza', '633428');
        // ID fake para evitar PMD AvoidHardcodingId
        fianza.put('Id', 'FAKE_FIANZA_ID_001');
        fianza.put('ValorFinanciadoFianza', '29545');
        fianzaBody.put('Fianza', fianza);
        
        // body.map.mapEntry con datos base + TipoVenta = 21 (para que se pise)
        List<Object> mapEntryList = new List<Object>();
        
        Map<String, Object> entryNumeroContrato = new Map<String, Object>();
        entryNumeroContrato.put('key', 'NumeroContrato');
        entryNumeroContrato.put('value', 'S025202562500');
        mapEntryList.add(entryNumeroContrato);
        
        Map<String, Object> entryIdSalesforce = new Map<String, Object>();
        entryIdSalesforce.put('key', 'IdSalesForce');
        // ID fake para evitar PMD AvoidHardcodingId
        entryIdSalesforce.put('value', 'FAKE_QUOTE_ID_001');
        mapEntryList.add(entryIdSalesforce);
        
        // TipoVenta original = 21
        Map<String, Object> entryTipoVenta = new Map<String, Object>();
        entryTipoVenta.put('key', 'TipoVenta');
        entryTipoVenta.put('value', '21');
        mapEntryList.add(entryTipoVenta);
        
        Map<String, Object> mapWrapper = new Map<String, Object>();
        mapWrapper.put('mapEntry', mapEntryList);
        
        body.put('map', mapWrapper);
        body.put('target', 1);
        
        // huellaYFirmaCliente
        Map<String, Object> huellaMap = new Map<String, Object>();
        huellaMap.put('huella', '141');
        body.put('huellaYFirmaCliente', huellaMap);
        
        input.put('body', body);
        input.put('fianzaBody', fianzaBody);
        
        // tipoVenta en el root del input
        input.put('tipoVenta', 48);
        
        return input;
    }
}