@IsTest
global class PVU_FacturasConceptosTest {

    // Fake that overrides runIP to return a simulated response
    global class PVU_FacturasConceptosFake extends PVU_FacturasConceptos {
        global override Map<String,Object> runIP(String ipName, Map<String,Object> input) {
            Map<String,Object> concepto = new Map<String,Object>{
                'ipc' => 123,
                'orginalAmount' => 100,
                'chargeType' => 'Cargo Fijo',
                'totalAmount' => 120,
                'otherTax' => 10,
                'discount' => 5,
                'iva' => 19,
                'spDescription' => 'Servicio de prueba',
                'startDate' => '2025-01-01',
                'endDate' => '2025-01-31',
                'productOffering' => 'Plan Básico'
            };
                
            List<Object> conceptosList = new List<Object>{ concepto };
                
            conceptosList.add(new Map<String,Object>{
                    'ipc' => '10',
                    'orginalAmount' => 50,
                    'chargeType' => 'O',
                    'totalAmount' => 60,
                    'otherTax' => 5,
                    'discount' => 0,
                    'iva' => 5,
                    'spDescription' => 'Interés por Mora',
                    'startDate' => '2025-01-01',
                    'endDate' => '2025-01-31',
                    'productOffering' => ''
                });

            Map<String,Object> invoiceItem   = new Map<String,Object>{ 'item' => conceptosList };
            Map<String,Object> subItem       = new Map<String,Object>{ 'invoiceItem' => invoiceItem, 'printBoxDes' => 'Detalle Específico' };
            Map<String,Object> subSection    = new Map<String,Object>{ 'item' => new List<Object>{ subItem } };
            Map<String,Object> item          = new Map<String,Object>{ 'subSection' => subSection, 'printBoxDes' => 'Móvil' };
            Map<String,Object> section       = new Map<String,Object>{ 'item' => new List<Object>{ item } };
            Map<String,Object> detail        = new Map<String,Object>{ 'section' => section };
            Map<String,Object> services      = new Map<String,Object>{ 'detail' => detail };

            Map<String,Object> nodoFactura = new Map<String,Object>{
                'invoiceReferenceNumber' => 'F001',
                'servicesDetails'        => services
            };

            return new Map<String,Object>{
                'getInvoiceDetailsResponse' => new List<Object>{ nodoFactura }
            };
        }
    }

    
    @IsTest
    static void testFacturaConConceptos() {
        Map<String,Object> factura = new Map<String,Object>{
            'Tipo' => 'FACTURA',
            'billNumber' => 'F001'
        };
        Map<String,Object> input  = new Map<String,Object>{ 'Datos' => new List<Object>{ factura } };
        Map<String,Object> outMap = new Map<String,Object>();

        Test.startTest();
        Boolean ok = new PVU_FacturasConceptosFake().invokeMethod('getFacturasConConceptos', input, outMap, new Map<String,Object>());
        Test.stopTest();

        System.assertEquals(true, ok);
        System.assert(outMap.containsKey('FacturasConConceptos'));

        List<Object> facturasResp = (List<Object>) outMap.get('FacturasConConceptos');
        System.assertEquals(1, facturasResp.size());

        Map<String,Object> facturaResp = (Map<String,Object>) facturasResp[0];
        List<Object> conceptos = (List<Object>) facturaResp.get('Conceptos');
        System.assertEquals(2, conceptos.size(), 'Debe traer 2 conceptos');

        Map<String,Object> c = (Map<String,Object>) conceptos[0];
        System.assertEquals('Cargo Fijo', c.get('concepto'));
        System.assertEquals('Móvil',      c.get('servicio'));
        System.assertEquals(120,          c.get('valorTotal'));
        System.assertEquals(19,           c.get('IVA'));
    }

    @IsTest
    static void testSinDatos() {
        Map<String,Object> outMap = new Map<String,Object>();
        Boolean ok = new PVU_FacturasConceptos().invokeMethod('getFacturasConConceptos', new Map<String,Object>(), outMap, new Map<String,Object>());
        System.assertEquals(true, ok);
        System.assertEquals(0, ((List<Object>) outMap.get('FacturasConConceptos')).size());
    }

    @IsTest
    static void testFacturaSinBillNumber() {
        Map<String,Object> factura = new Map<String,Object>{ 'Tipo' => 'FACTURA' };
        Map<String,Object> input   = new Map<String,Object>{ 'Datos' => new List<Object>{ factura } };
        Map<String,Object> outMap  = new Map<String,Object>();

        Boolean ok = new PVU_FacturasConceptos().invokeMethod('getFacturasConConceptos', input, outMap, new Map<String,Object>());
        System.assertEquals(true, ok);
        System.assertEquals(0, ((List<Object>) outMap.get('FacturasConConceptos')).size());
    }

    @IsTest
    static void testConExcepcion() {
        // fuerza ClassCastException en el try/catch principal
        Map<String,Object> input  = new Map<String,Object>{ 'Datos' => new List<Object>{ 'stringInvalido' } };
        Map<String,Object> outMap = new Map<String,Object>();

        Boolean ok = new PVU_FacturasConceptos().invokeMethod('getFacturasConConceptos', input, outMap, new Map<String,Object>());
        System.assertEquals(true, ok);
        System.assert(outMap.containsKey('error'));
    }
}