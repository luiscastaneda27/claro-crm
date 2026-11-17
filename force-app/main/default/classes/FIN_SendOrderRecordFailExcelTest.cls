/**
 * @description      Clase test que envia registros fallidos de fianza 
 * @author           ezequiel.olivera@nespon.com
 * @date             2025-12-11
 */
@isTest
private class FIN_SendOrderRecordFailExcelTest {

    @isTest static void testEnviarExcel() {

        List<Map<String, Object>> orderData = new List<Map<String, Object>>();

        Map<String, Object> rec = new Map<String, Object>();
        rec.put('documentType', 'CC');
        rec.put('documentNumber', '1234567890123'); 
        rec.put('cityDaneCode', '33001');
        rec.put('codigoCredito', 'CR-0001');
        rec.put('idSimulacion', 'SIM-123');
        rec.put('saldoDiferir', 1500000);
        rec.put('fechaInicioCredito', '2025-12-01');
        rec.put('plazoCredito', '24');
        rec.put('calificacionCredito', 'A');

        rec.put('sigla', 'TER');
        rec.put('tarifaFianza', '3.5');
        rec.put('totalFianza', 52500);
        rec.put('cuotaMensualFianza', 2187.5);
        rec.put('ivaFianza', '19');

        rec.put('idOrder', 'ORD-1001');
        rec.put('idContract', 'CTR-2002');

        rec.put('cuentaFacturacionPrincipal', 'CUST-999');
        rec.put('cuentaFacturacionCredito', 'CRED-888');
        rec.put('idCiclo', 'CIC-01');
        rec.put('fechaCorteCiclo', '15');

        orderData.add(rec);

        Map<String, Object> inputMap = new Map<String, Object>{
            'orderData' => orderData
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_SendOrderRecordFailExcel svc = new FIN_SendOrderRecordFailExcel();

        Test.startTest();
        Boolean result = svc.invokeMethod('enviarExcel', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, result, 'invokeMethod debería devolver true');
        System.assertEquals('OK', outputMap.get('status'), 'Status debería ser OK');
        System.assertEquals('Email enviado correctamente.', outputMap.get('message'), 'Mensaje incorrecto');
    }

    @isTest static void testMetodoNoReconocido() {

        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_SendOrderRecordFailExcel svc = new FIN_SendOrderRecordFailExcel();

        Test.startTest();
        Boolean result = svc.invokeMethod('metodoInexistente', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(false, result, 'Debe retornar false si el método no existe');
        System.assertEquals('ERROR', outputMap.get('status'), 'Status debería ser ERROR');

        String msg = (String) outputMap.get('message');
        System.assert(
            msg.contains('metodoInexistente'),
            'El mensaje debe contener el nombre del método desconocido.'
        );
    }
}