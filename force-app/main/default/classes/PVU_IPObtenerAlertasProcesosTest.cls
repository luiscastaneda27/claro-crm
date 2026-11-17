@IsTest
private class PVU_IPObtenerAlertasProcesosTest {

    // Helper: Crea un case con lo mínimo típico (ajusta si tu org exige más)
    private static Case newCase(String alertas) {
        Case c = new Case(
            Subject = 'Test PVU alerts',
            Status  = 'New',
            Origin  = 'Phone',
            PVU_AlertasProcesos__c = alertas
        );
        return c;
    }

    @IsTest
    static void testCaseIdNullReturnsEmptyAlerts() {
        PVU_IPObtenerAlertasProcesos svc = new PVU_IPObtenerAlertasProcesos();

        Map<String, Object> inputMap  = new Map<String, Object>(); // sin CaseId
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        Test.startTest();
        Boolean ok = svc.invokeMethod('getAlerts', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'Debe retornar true aunque falte CaseId (según implementación).');
        System.assertEquals(true, outputMap.containsKey('alertsJson'), 'Debe retornar alertsJson.');
        System.assertEquals(true, outputMap.containsKey('message'), 'Debe retornar message.');

        List<Object> alerts = (List<Object>) outputMap.get('alertsJson');
        System.assertEquals(0, alerts.size(), 'alertsJson debe ser vacío cuando CaseId es null.');

        System.assertEquals('CaseId is required', (String) outputMap.get('message'), 'El message debe indicar que falta CaseId.');
    }

    @IsTest
    static void testBuildsTwoAlertsAndAccumulatesPoints() {
        // 2 éxitos + 2 errores, con espacios y uno vacío para validar trims
        Case c = newCase('Exito: exito 1;  hola error 1 ;Éxito: exito 2; ; hola error 2');
        insert c;

        PVU_IPObtenerAlertasProcesos svc = new PVU_IPObtenerAlertasProcesos();
        Map<String, Object> inputMap  = new Map<String, Object>{ 'CaseId' => c.Id };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        Test.startTest();
        Boolean ok = svc.invokeMethod('getAlerts', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'Debe retornar true.');
        List<Object> alerts = (List<Object>) outputMap.get('alertsJson');
        System.assertEquals(2, alerts.size(), 'Debe generar máximo 2 alerts (success y error).');

        // Convertimos a maps para validar fácil
        Map<String, Object> a0 = (Map<String, Object>) alerts[0];
        Map<String, Object> a1 = (Map<String, Object>) alerts[1];

        // Determinamos cuál es success y cuál error (no asumimos orden)
        Map<String, Object> successAlert;
        Map<String, Object> errorAlert;

        if ((String) a0.get('variant') == 'success') {
            successAlert = a0;
            errorAlert   = a1;
        } else {
            successAlert = a1;
            errorAlert   = a0;
        }

        System.assertEquals('success', (String) successAlert.get('variant'), 'El alert success debe tener variant=success.');
        System.assertEquals('success-1', (String) successAlert.get('id'), 'El alert success debe tener id=success-1.');
        System.assertEquals(true, (Boolean) successAlert.get('dismissible'), 'El alert success debe ser dismissible.');
        System.assertEquals(20, (Integer) successAlert.get('order'), 'El alert success debe tener order=20.');

        List<Object> successPointsObj = (List<Object>) successAlert.get('points');
        List<String> successPoints = new List<String>();
        for (Object o : successPointsObj) {
            successPoints.add((String) o);
        }

        System.assertEquals(2, successPoints.size(), 'Debe acumular 2 puntos de éxito en el mismo alert.');
        System.assertEquals('exito 1', successPoints[0], 'Primer punto de éxito incorrecto.');
        System.assertEquals('exito 2', successPoints[1], 'Segundo punto de éxito incorrecto.');

        System.assertEquals('error', (String) errorAlert.get('variant'), 'El alert error debe tener variant=error.');
        System.assertEquals('error-1', (String) errorAlert.get('id'), 'El alert error debe tener id=error-1.');
        System.assertEquals(true, (Boolean) errorAlert.get('dismissible'), 'El alert error debe ser dismissible.');
        System.assertEquals(20, (Integer) errorAlert.get('order'), 'El alert error debe tener order=20.');

        List<Object> errorPointsObj = (List<Object>) errorAlert.get('points');
        List<String> errorPoints = new List<String>();
        for (Object o : errorPointsObj) {
            errorPoints.add((String) o);
        }

        System.assertEquals(2, errorPoints.size(), 'Debe acumular 2 errores en el mismo alert.');
        System.assertEquals('hola error 1', errorPoints[0], 'Primer punto de error incorrecto.');
        System.assertEquals('hola error 2', errorPoints[1], 'Segundo punto de error incorrecto.');
    }

    @IsTest
    static void testMethodNotSupportedReturnsFalseAndErrorKey() {
        PVU_IPObtenerAlertasProcesos svc = new PVU_IPObtenerAlertasProcesos();

        Map<String, Object> inputMap  = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        Test.startTest();
        Boolean ok = svc.invokeMethod('noExiste', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(false, ok, 'Si el método no se soporta debe retornar false.');
        System.assertEquals(true, outputMap.containsKey('error'), 'Debe retornar la key "error" en outputMap.');
        System.assert(((String) outputMap.get('error')).contains('Method not supported'), 'El mensaje de error debe indicar "Method not supported".');
    }

    @IsTest
    static void testMethodNameBlankDefaultsToGetAlerts() {
        Case c = newCase('Exito: ok;error X');
        insert c;

        PVU_IPObtenerAlertasProcesos svc = new PVU_IPObtenerAlertasProcesos();
        Map<String, Object> inputMap  = new Map<String, Object>{ 'CaseId' => c.Id };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        Test.startTest();
        // methodName vacío => debe rutear a getAlerts
        Boolean ok = svc.invokeMethod('', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'Debe retornar true cuando methodName viene vacío y rutea a getAlerts.');
        List<Object> alerts = (List<Object>) outputMap.get('alertsJson');
        System.assertEquals(2, alerts.size(), 'Debe crear success y error.');
    }

    @IsTest
    static void testInvokeAliasWorks() {
        Case c = newCase('Exito: ok');
        insert c;

        PVU_IPObtenerAlertasProcesos svc = new PVU_IPObtenerAlertasProcesos();
        Map<String, Object> inputMap  = new Map<String, Object>{ 'CaseId' => c.Id };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        Test.startTest();
        Boolean ok = svc.invokeMethod('invoke', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'Debe retornar true para alias invoke.');
        List<Object> alerts = (List<Object>) outputMap.get('alertsJson');
        System.assertEquals(1, alerts.size(), 'Solo success, sin error.');
        Map<String, Object> a0 = (Map<String, Object>) alerts[0];
        System.assertEquals('success', (String) a0.get('variant'), 'El único alert debe ser success.');
    }
}