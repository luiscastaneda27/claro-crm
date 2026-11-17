/***************************************************************************************************
 * @Class Name          : FIN_ConsultaFinanciamientoControllerTest
 * @description         : Contiene los métodos test para la cobertura de la clase FIN_ConsultaFinanciamientoController.
 * @Author              : Gerardo A. Mendoza
 * @Created date        : 18-october-2024
 * @Modification Log    :
 * Version  Date          Developer             Modification
 * 1.0      18/10/2024    Gerardo A. Mendoza    Initial version
 * 1.1      02/11/2024    Javier A. Esquivel    Se agregan tests de integración y escenarios.
 *
 */
@IsTest
public class FIN_ConsultaFinanciamientoControllerTest {

    private static final String METHOD_GENERATE  = 'generateJSONFinanciamientos';
    private static final String METHOD_INTEGRATE = 'integrateAllData';

    /**
     * @description Helper: replica el formatCurrency del controller (que es private),
     *              para poder comparar en asserts sin depender de locale.
     * @param value Valor numérico en string.
     * @return String formateado como moneda.
     */
    private static String fmt(String value) {
        if (value == null) {
            return '$0.00';
        }
        return '$' + Decimal.valueOf(value).setScale(2).format();
    }

    /***************************************************************************************************
     * @Method name  : testGenerateJSONFinanciamientos
     * @description  : Prueba el método generateJSONFinanciamientos de la clase FIN_ConsultaFinanciamientoController.
     */
    @isTest
    public static void testGenerateJSONFinanciamientos() {

        Map<String, Object> financingRecord = new Map<String, Object>{
            FIN_ConsultaFinanciamientoController.NODO_CREATION_DATE => '2024-10-26 11:32:07',
            'financingCode' => 'CRED_TEST_001'
        };

        List<Object> financiamientos = new List<Object>{ financingRecord };

        Map<String, Object> summaryRecord = new Map<String, Object>{
            'resolvedState' => 'N - NORMAL'
        };
        List<Object> summaries = new List<Object>{ summaryRecord };

        Map<String, Object> inputMap = new Map<String, Object>{
            'financing' => financiamientos,
            'summary'   => summaries
        };

        Map<String, Object> outMap   = new Map<String, Object>();
        Map<String, Object> options  = new Map<String, Object>();

        FIN_ConsultaFinanciamientoController controller = new FIN_ConsultaFinanciamientoController();

        Test.startTest();
            controller.invokeMethod(METHOD_GENERATE, inputMap, outMap, options);
        Test.stopTest();

        System.assert(
            outMap.containsKey(FIN_ConsultaFinanciamientoController.RESULT_STRING),
            'El mapa de salida debe contener la clave result.'
        );

        List<Object> result = (List<Object>) outMap.get(FIN_ConsultaFinanciamientoController.RESULT_STRING);
        System.assertEquals(1, result.size(), 'Debe existir exactamente 1 resultado.');

        Map<String, Object> resultItem = (Map<String, Object>) result[0];
        System.assertEquals(
            'N - NORMAL',
            resultItem.get('resolvedState'),
            'resolvedState debe insertarse dentro del nodo financing.'
        );
    }

    /***************************************************************************************************
     * @Method name  : integrateAllDataTest
     * @description  : Prueba el método integrateAllData para un escenario con transacción PAY, facturas y financiamientos.
     */
    @IsTest
    public static void integrateAllDataTest() {

        String transactionsJSON = '[' +
            '{' +
                '"openAmount": "-88700",' +
                '"type": "PAY",' +
                '"refDate": "2024-10-18 11:48:38",' +
                '"id": "4804",' +
                '"details": {' +
                    '"detail": [' +
                        '{' +
                            '"openAmount": "0",' +
                            '"chargeDesc": "Regular Interest Tax",' +
                            '"chargeType": "IVA",' +
                            '"amount": "-3265.47"' +
                        '},' +
                        '{' +
                            '"openAmount": "0",' +
                            '"chargeDesc": "Terminal Regular Interest",' +
                            '"chargeType": "RI_TER",' +
                            '"amount": "-17186.69"' +
                        '},' +
                        '{' +
                            '"openAmount": "0",' +
                            '"chargeDesc": "Amortization",' +
                            '"chargeType": "AMZ",' +
                            '"amount": "-68247.84"' +
                        '}' +
                    ']' +
                '},' +
                '"term": "1",' +
                '"dueDate": "2024-10-18 11:48:38"' +
            '}' +
        ']';
        List<Object> transactionsObjList = (List<Object>) JSON.deserializeUntyped(transactionsJSON);

        String invoicesJSON = '[' +
            '{' +
                '"cutoffDate": "2025-10-31",' +
                '"financialDocDate": "2025-11-01",' +
                '"financialDocID": "045804",' +
                '"dueDate": "2025-11-05",' +
                '"financingReference": {' +
                    '"pendingAmount": "0.00",' +
                    '"paymentReference": "92000000070286",' +
                    '"totalAmount": "410508.00"' +
                '}' +
            '}' +
        ']';
        List<Object> invoicesObjList = (List<Object>) JSON.deserializeUntyped(invoicesJSON);

        String financingsJSON = '[' +
            '{' +
                '"creationDate": "2023-07-24 08:53:28",' +
                '"baseAmount": "895000",' +
                '"monthlyFee": "500"' +
            '}' +
        ']';
        List<Object> financingsObjList = (List<Object>) JSON.deserializeUntyped(financingsJSON);

        String paymentsJSON = '[' +
            '{' +
                '"id": "4378",' +
                '"term": "1",' +
                '"paymentId": "4804",' +
                '"method": "1",' +
                '"balanceDate": "2024-10-18 11:48:38",' +
                '"collectingEntity": "5",' +
                '"amount": "88700"' +
            '}' +
        ']';
        List<Object> paymentsObjList = (List<Object>) JSON.deserializeUntyped(paymentsJSON);

        Map<String, Object> inputMap = new Map<String, Object>{
            'transaction'  => transactionsObjList,
            'payments'     => paymentsObjList,
            'invoices'     => invoicesObjList,
            'financings'   => financingsObjList,
            'customerCharges' => new List<Object>(),
            'creditHistory'   => new List<Object>(),
            'reasonIds'       => new List<Object>(),
            'accountId'       => 'ACC12345',
            'cuentaOrigen'    => 'CO67890'
        };

        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_ConsultaFinanciamientoController controller = new FIN_ConsultaFinanciamientoController();

        Test.startTest();
            controller.invokeMethod(METHOD_INTEGRATE, inputMap, outMap, options);
        Test.stopTest();

        System.assert(outMap.containsKey('result'), 'El outMap debe contener la clave "result".');

        List<Map<String, Object>> result = (List<Map<String, Object>>) outMap.get('result');
        System.assert(result.size() > 0, 'El resultado no debe estar vacío.');
    }

    /***************************************************************************************************
     * @Method name  : processCreditHistoryTest
     * @description  : Prueba el procesamiento de creditHistory filtrando por reasonIds válidos.
     */
    @IsTest
    public static void processCreditHistoryTest() {

        String creditHistoryJSON = '[' +
            '{' +
                '"IdRazon": "205",' +
                '"Saldo": "50000.00",' +
                '"Valor": "25000.00",' +
                '"FechaTransaccion": "2024-10-25 15:30:45",' +
                '"Estado": "Activo"' +
            '},' +
            '{' +
                '"IdRazon": "208",' +
                '"Saldo": "30000.00",' +
                '"Valor": "15000.00",' +
                '"FechaTransaccion": "2024-10-26 10:20:30",' +
                '"Estado": "Pendiente"' +
            '},' +
            '{' +
                '"IdRazon": "100",' +
                '"Saldo": "10000.00",' +
                '"Valor": "5000.00",' +
                '"FechaTransaccion": "2024-10-27 09:10:15",' +
                '"Estado": "Cancelado"' +
            '}' +
        ']';
        List<Object> creditHistoryObjList = (List<Object>) JSON.deserializeUntyped(creditHistoryJSON);

        String reasonIdsJSON = '["205", "208"]';
        List<Object> reasonIdsObjList = (List<Object>) JSON.deserializeUntyped(reasonIdsJSON);

        List<Object> emptyArray = new List<Object>();

        Map<String, Object> inputMap = new Map<String, Object>{
            'creditHistory'   => creditHistoryObjList,
            'reasonIds'       => reasonIdsObjList,
            'transaction'     => emptyArray,
            'payments'        => emptyArray,
            'invoices'        => emptyArray,
            'financings'      => emptyArray,
            'customerCharges' => emptyArray,
            'accountId'       => 'ACC12345',
            'cuentaOrigen'    => 'CO67890'
        };

        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_ConsultaFinanciamientoController controller = new FIN_ConsultaFinanciamientoController();

        Test.startTest();
            controller.invokeMethod(METHOD_INTEGRATE, inputMap, outMap, options);
        Test.stopTest();

        System.assert(outMap.containsKey('result'), 'El outMap debe contener la clave "result".');

        List<Map<String, Object>> result = (List<Map<String, Object>>) outMap.get('result');
        System.assertEquals(
            2,
            result.size(),
            'Solo deben incluirse 2 registros (IdRazon 205 y 208).'
        );

        Boolean found205 = false;
        Boolean found208 = false;

        for (Map<String, Object> item : result) {
            String idRazon = (String) item.get('idRazon');

            if (idRazon == '205') {
                found205 = true;
                System.assertEquals('Ajuste Crédito', (String) item.get('tipoTransaccion'), 'tipoTransaccion debe ser Ajuste Crédito (205).');
                System.assertEquals(fmt('25000.00'), (String) item.get('valor'), 'valor formateado incorrecto (205).');
                System.assertEquals(fmt('50000.00'), (String) item.get('saldo'), 'saldo formateado incorrecto (205).');
            } else if (idRazon == '208') {
                found208 = true;
                System.assertEquals('Ajuste Crédito', (String) item.get('tipoTransaccion'), 'tipoTransaccion debe ser Ajuste Crédito (208).');
                System.assertEquals(fmt('15000.00'), (String) item.get('valor'), 'valor formateado incorrecto (208).');
                System.assertEquals(fmt('30000.00'), (String) item.get('saldo'), 'saldo formateado incorrecto (208).');
            }
        }

        System.assert(found205, 'No se encontró el registro con IdRazon 205.');
        System.assert(found208, 'No se encontró el registro con IdRazon 208.');
    }

    /***************************************************************************************************
     * @Method name  : processCustomerChargesTest
     * @description  : Prueba el procesamiento de customerCharges generando movimientos tipo "Cargo Fijo".
     */
    @IsTest
    public static void processCustomerChargesTest() {

        String customerChargesJSON = '[' +
            '{' +
                '"currentBalance": "75000.00",' +
                '"amount": "12500.00",' +
                '"transactionDate": "2024-10-24 14:25:35",' +
                '"description": "Cargo por instalación",' +
                '"chargeService": "SRV001",' +
                '"idCharge": "CHG123"' +
            '},' +
            '{' +
                '"currentBalance": "62500.00",' +
                '"amount": "8750.00",' +
                '"transactionDate": "2024-10-25 09:15:20",' +
                '"description": "Cargo por mantenimiento",' +
                '"chargeService": "SRV002",' +
                '"idCharge": "CHG456"' +
            '}' +
        ']';
        List<Object> customerChargesObjList = (List<Object>) JSON.deserializeUntyped(customerChargesJSON);

        List<Object> emptyArray = new List<Object>();

        Map<String, Object> inputMap = new Map<String, Object>{
            'customerCharges' => customerChargesObjList,
            'transaction'     => emptyArray,
            'payments'        => emptyArray,
            'invoices'        => emptyArray,
            'financings'      => emptyArray,
            'creditHistory'   => emptyArray,
            'reasonIds'       => emptyArray,
            'accountId'       => 'ACC12345',
            'cuentaOrigen'    => 'CO67890'
        };

        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_ConsultaFinanciamientoController controller = new FIN_ConsultaFinanciamientoController();

        Test.startTest();
            controller.invokeMethod(METHOD_INTEGRATE, inputMap, outMap, options);
        Test.stopTest();

        System.assert(outMap.containsKey('result'), 'El outMap debe contener la clave "result".');

        List<Map<String, Object>> result = (List<Map<String, Object>>) outMap.get('result');
        System.assertEquals(2, result.size(), 'Deben procesarse exactamente 2 cargos.');

        Boolean foundChg123 = false;
        Boolean foundChg456 = false;

        for (Map<String, Object> item : result) {
            String idCargo = (String) item.get('idCargo');

            if (idCargo == 'CHG123') {
                foundChg123 = true;
                System.assertEquals('Cargo Fijo', (String) item.get('tipoTransaccion'), 'tipoTransaccion debe ser Cargo Fijo (CHG123).');
                System.assertEquals(fmt('12500.00'), (String) item.get('valor'), 'valor formateado incorrecto (CHG123).');
                System.assertEquals(fmt('75000.00'), (String) item.get('saldo'), 'saldo formateado incorrecto (CHG123).');
                System.assertEquals('Cargo por instalación', (String) item.get('descripcion'), 'descripcion incorrecta (CHG123).');
                System.assertEquals('SRV001', (String) item.get('servicioCargoId'), 'servicioCargoId incorrecto (CHG123).');
            } else if (idCargo == 'CHG456') {
                foundChg456 = true;
                System.assertEquals('Cargo Fijo', (String) item.get('tipoTransaccion'), 'tipoTransaccion debe ser Cargo Fijo (CHG456).');
                System.assertEquals(fmt('8750.00'), (String) item.get('valor'), 'valor formateado incorrecto (CHG456).');
                System.assertEquals(fmt('62500.00'), (String) item.get('saldo'), 'saldo formateado incorrecto (CHG456).');
                System.assertEquals('Cargo por mantenimiento', (String) item.get('descripcion'), 'descripcion incorrecta (CHG456).');
                System.assertEquals('SRV002', (String) item.get('servicioCargoId'), 'servicioCargoId incorrecto (CHG456).');
            }
        }

        System.assert(foundChg123, 'No se encontró el registro con idCargo CHG123.');
        System.assert(foundChg456, 'No se encontró el registro con idCargo CHG456.');
    }
}