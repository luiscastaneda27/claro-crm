@isTest
private class PVU_IMEIBodyBuilderTest {

    private static Asset createTestAsset(String imeiValue) {
        Account acc = new Account(
            Name = 'Cuenta Test',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678',
            Phone = '3001234567',
            FVU_Email__c = 'test@test.com'
        );
        insert acc;

        Account bill = new Account(
            Name = 'BA Test',
            ParentId = acc.Id,
            FVU_BillingShortAddress__c = 'Calle 123',
            FVU_BillingMunicipality__c = 'Bogotá',
            FVU_BillingMiniCity__c = 'Chapinero'
        );
        insert bill;
        
        Product2 prod = new Product2(
        	Name = 'Modelo X',
            ProductCode = 'MarcaX'
        );
        insert prod;

        Asset a = new Asset(
            Name = 'Modelo X',
            Product2Id = prod.Id,
            PVU_IMEI__c = imeiValue,
            AccountId = acc.Id,
            vlocity_cmt__BillingAccountId__c = bill.Id
        );
        insert a;

        return a;
    }

    private static Map<String,Object> baseInput(String category) {
        return new Map<String,Object>{
            'category' => category,
            'imei' => '123456789012345',
            'tipoReporteAbd' => '1',
            'usuario' => 'testUser',
            'msisdn' => '3001112233',
            'fiscalia' => '1',
            'empleoViolencia' => '0',
            'tipoArma' => '0',
            'victimaMenorEdad' => '0'
        };
    }

    @isTest
    static void testReporteIMEI() {
        createTestAsset('123456789012345');

        Map<String,Object> inputMap = baseInput('reporteIMEI');
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Boolean result = new PVU_IMEIBodyBuilder().invokeMethod(
            'buildBody',
            inputMap,
            outMap,
            options
        );

        System.assertEquals(true, result, 'invokeMethod debe retornar true');
        System.assert(outMap.containsKey('body'), 'Debe generar body');
        System.assertNotEquals(null, outMap.get('body'));
    }

    @isTest
    static void testLiberacionIMEI() {
        createTestAsset('123456789012345');

        Map<String,Object> inputMap = baseInput('liberacionIMEI');
        inputMap.put('tipoReporteAbd', 'Extravío');
        Map<String,Object> outMap = new Map<String,Object>();

        Boolean result = new PVU_IMEIBodyBuilder().invokeMethod(
            'buildBody',
            inputMap,
            outMap,
            new Map<String,Object>()
        );

        System.assert(result, 'invokeMethod debe retornar true');
        System.assert(outMap.get('body') != null);

        Map<String,Object> body = (Map<String,Object>) outMap.get('body');
        List<Object> productOrderItem = (List<Object>) body.get('productOrderItem');
        Map<String,Object> firstItem = (Map<String,Object>) productOrderItem[0];
        Map<String,Object> product = (Map<String,Object>) firstItem.get('product');
        List<Object> characteristics = (List<Object>) product.get('productCharacteristic');
        Boolean hasPassword = false;
        String tipoReporteValue;

        for (Object item : characteristics) {
            Map<String,Object> characteristic = (Map<String,Object>) item;
            if ((String) characteristic.get('name') == 'Password') {
                hasPassword = true;
            }
            if ((String) characteristic.get('name') == 'tipoReporteAbd') {
                tipoReporteValue = (String) characteristic.get('value');
            }
        }

        System.assertEquals(true, hasPassword, 'liberacionIMEI debe enviar Password');
        System.assertEquals('2', tipoReporteValue, 'Extravío debe mapear a 2 en liberacionIMEI');
    }

    @isTest
    static void testRegistroIMEI() {
        Map<String,Object> inputMap = baseInput('registroIMEI');
        Map<String,Object> outMap = new Map<String,Object>();

        Boolean result = new PVU_IMEIBodyBuilder().invokeMethod(
            'buildBody',
            inputMap,
            outMap,
            new Map<String,Object>()
        );

        System.assert(result);
        System.assert(outMap.containsKey('body'));
        
        Map<String,Object> body = (Map<String,Object>) outMap.get('body');
        System.assertEquals('registroIMEI', body.get('category'));
    }

    @isTest
    static void testDuplicadoIMEI() {
        Map<String,Object> inputMap = baseInput('duplicado');
        Map<String,Object> outMap = new Map<String,Object>();
        inputMap.put('accion', 'add');
        inputMap.put('usuarioRed', 'CAVDIRECTO_C501');
        inputMap.put('tipoDocumento', '2');
        inputMap.put('numeroDocumento', '88453232');
        inputMap.put('nombres', 'SANTIAGO');
        inputMap.put('apellidos', 'HERNANDEZ');
        inputMap.put('modelo', 'NTH-NX9');
        inputMap.put('marca', 'Honor 200');
        inputMap.put('direccion', 'CL 13 68 10');
        inputMap.put('detalle', 'test');
        inputMap.put('correo', 'vallejoe@hitss.com');
        inputMap.put('ciudad', 'BOGOTA, D.C.');
        inputMap.put('aceptaInfoLegal', 'SI');
        inputMap.put('compList', new List<Object>{
            new Map<String,Object>{
                'imsiAdicion' => '732101641118555',
                'minAdicion' => '3130001968'
            }
        });

        Boolean result = new PVU_IMEIBodyBuilder().invokeMethod(
            'buildBody',
            inputMap,
            outMap,
            new Map<String,Object>()
        );

        System.assert(result);
        System.assert(outMap.containsKey('body'));
        
        Map<String,Object> body = (Map<String,Object>) outMap.get('body');
        System.assertEquals('gestionDuplicadosIMEI', body.get('category'));
        List<Object> productOrderItem = (List<Object>) body.get('productOrderItem');
        Map<String,Object> firstItem = (Map<String,Object>) productOrderItem[0];
        System.assertEquals('add', firstItem.get('action'));
        System.assertEquals('Solicitud de Gestion Duplicados de IMEI', body.get('description'));

        List<Object> channelList = (List<Object>) body.get('channel');
        Map<String,Object> channelWrapper = (Map<String,Object>) channelList[0];
        System.assertEquals('POSVENTA', channelWrapper.get('role'));

        Map<String,Object> product = (Map<String,Object>) firstItem.get('product');
        List<Object> characteristics = (List<Object>) product.get('productCharacteristic');
        Map<String,Object> compListCharacteristic;
        String tipoOperacionValue;
        Integer imeiCount = 0;
        Boolean hasPassword = false;

        for (Object item : characteristics) {
            Map<String,Object> characteristic = (Map<String,Object>) item;
            if ((String) characteristic.get('name') == 'imei') {
                imeiCount++;
            }
            if ((String) characteristic.get('name') == 'Password') {
                hasPassword = true;
            }
            if ((String) characteristic.get('name') == 'compList') {
                compListCharacteristic = characteristic;
            }
            if ((String) characteristic.get('name') == 'tipoOperacion') {
                tipoOperacionValue = (String) characteristic.get('value');
            }
        }

        System.assertNotEquals(null, compListCharacteristic, 'Debe enviar compList');
        System.assertEquals('array', compListCharacteristic.get('valueType'), 'compList debe enviarse como array');
        System.assertEquals(1, imeiCount, 'Debe enviar imei una sola vez');
        List<Object> compList = (List<Object>) compListCharacteristic.get('value');
        System.assertEquals(1, compList.size(), 'Debe conservar la dupla enviada');
        Map<String,Object> firstComp = (Map<String,Object>) compList[0];
        System.assertEquals('732101641118555', firstComp.get('imsi'));
        System.assertEquals('3130001968', firstComp.get('min'));
        System.assertEquals('1', tipoOperacionValue, 'accion add debe mapear tipoOperacion a 1');
        System.assertEquals(true, hasPassword, 'gestionDuplicadosIMEI debe enviar Password');
    }

    @isTest
    static void testInvalidMethodName() {
        Boolean result = new PVU_IMEIBodyBuilder().invokeMethod(
            'metodoInexistente',
            new Map<String,Object>(),
            new Map<String,Object>(),
            new Map<String,Object>()
        );

        System.assertEquals(true, result);
    }
}