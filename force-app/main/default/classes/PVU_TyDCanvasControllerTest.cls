@isTest
private class PVU_TyDCanvasControllerTest {

    private static Case buildCase(String lineNumber) {
        return new Case(
            Status = 'En curso',
            PVU_NumeroLinea__c = lineNumber,
            PVU_Level1__c = 'Soporte, fallas de servicio y equipos',
            PVU_Level2__c = 'Falla de Servicios',
            PVU_Level3__c = 'Fallas de Servicio Móvil'
        );
    }

    @isTest
    static void testRedirectSuccess() {
        // Test.isRunningTest() fuerza sandboxName='sandboxNoExist', el metadata no existe,
        // por lo que el constructor captura el error. Probamos redirectToTyD() con finalUrl válido.
        Case testCase = buildCase('3001234567');
        insert testCase;

        Test.setCurrentPage(Page.PVU_TyDCanvas);
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        PVU_TyDCanvasController controller = new PVU_TyDCanvasController(sc);

        // Simulamos el estado exitoso del constructor para probar redirectToTyD()
        controller.finalUrl = 'https://appscvgwsfcipred.claro.com.co/tyd/?lineNumber=3001234567';
        controller.errorMessage = null;

        PageReference result = controller.redirectToTyD();
        Test.stopTest();

        System.assertNotEquals(null, result, 'El PageReference no debería ser nulo con finalUrl válido');
        System.assert(result.getUrl().contains('lineNumber=3001234567'), 'La URL debe contener el número de línea');
        System.assert(result.getRedirect(), 'Debe estar marcado como redirect');
    }

    @isTest
    static void testRedirectErrorNoMetadata() {
        // sandboxNoExist no existe en metadata — el constructor captura TyDException
        Case testCase = buildCase('3001234567');
        insert testCase;

        Test.setCurrentPage(Page.PVU_TyDCanvas);
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        PVU_TyDCanvasController controller = new PVU_TyDCanvasController(sc);
        PageReference result = controller.redirectToTyD();
        Test.stopTest();

        System.assertEquals(null, result, 'Debe retornar null cuando no hay metadato');
        System.assertNotEquals(null, controller.errorMessage, 'Debe existir mensaje de error');
        System.assert(controller.errorMessage.contains('Configuración'), 'El mensaje debe indicar error de configuración');
    }

    @isTest
    static void testRedirectErrorBlankLineNumber() {
        // Caso sin número de línea — debe capturar TyDException
        Case testCase = buildCase(null);
        insert testCase;

        Test.setCurrentPage(Page.PVU_TyDCanvas);
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        PVU_TyDCanvasController controller = new PVU_TyDCanvasController(sc);
        PageReference result = controller.redirectToTyD();
        Test.stopTest();

        System.assertEquals(null, result, 'Debe retornar null cuando el número de línea está vacío');
        System.assertNotEquals(null, controller.errorMessage, 'Debe existir mensaje de error');
        System.assert(controller.errorMessage.contains('número de línea'), 'El mensaje debe indicar falta de número de línea');
        System.assertEquals(null, controller.finalUrl, 'finalUrl debe ser nulo');
    }

    @isTest
    static void testRedirectErrorNullId() {
        // StandardController sin Id (registro no insertado)
        Case testCase = buildCase('3001234567');

        Test.setCurrentPage(Page.PVU_TyDCanvas);
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        PVU_TyDCanvasController controller = new PVU_TyDCanvasController(sc);
        PageReference result = controller.redirectToTyD();
        Test.stopTest();

        System.assertEquals(null, result, 'Debe retornar null cuando el Id es nulo');
        System.assertNotEquals(null, controller.errorMessage, 'Debe existir mensaje de error');
        System.assert(controller.errorMessage.contains('caso'), 'El mensaje debe indicar que no se encontró el caso');
    }

    @isTest
    static void testRedirectToTyDWithBlankFinalUrl() {
        // Verifica que redirectToTyD retorna null cuando finalUrl está vacío
        Case testCase = buildCase('3001234567');
        insert testCase;

        Test.setCurrentPage(Page.PVU_TyDCanvas);
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        PVU_TyDCanvasController controller = new PVU_TyDCanvasController(sc);
        controller.finalUrl = '';
        PageReference result = controller.redirectToTyD();
        Test.stopTest();

        System.assertEquals(null, result, 'redirectToTyD debe retornar null con finalUrl vacío');
    }
}