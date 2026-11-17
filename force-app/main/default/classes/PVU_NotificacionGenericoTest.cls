@isTest
private class PVU_NotificacionGenericoTest {

    @testSetup
    static void setupData() {
        // Crear un usuario de prueba
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testu@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'testu' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        // Crear un caso de prueba
        insert new Case(
            Subject = 'Caso de prueba para notificación',
            Origin = 'Phone',
            Status = 'New'
        );
    }

    @isTest
    static void testSendNotification_Success() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        User u = [SELECT Id FROM User WHERE Alias = 'testu' LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'notificationDevName' => 'CaseUpdate',
            'recordId' => c.Id,
            'userId' => u.Id,
            'titulo' => 'Notificación de Prueba',
            'cuerpo' => 'Este es un mensaje de prueba'
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_NotificacionGenerico().invokeMethod('sendNotification', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, output.get('success'));
    }

    @isTest
    static void testSendNotification_InvalidParams() {
        Map<String, Object> input = new Map<String, Object>{
            'notificationDevName' => 'CaseUpdate'
            // faltan recordId y userId
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_NotificacionGenerico().invokeMethod('sendNotification', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, output.get('success'));
        System.assert(((String) output.get('message')).contains('Parámetros inválidos'));
    }

    @isTest
    static void testUnsupportedMethod() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_NotificacionGenerico().invokeMethod('otroMetodo', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, output.get('success'));
        System.assert(((String) output.get('message')).contains('Método no soportado'));
    }

    @isTest
    static void testCatchInsideSendNotification() {
        // notificationDevName inválido para romper la query → entra en catch interno
        Case c = [SELECT Id FROM Case LIMIT 1];
        User u = [SELECT Id FROM User WHERE Alias = 'testu' LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'notificationDevName' => 'NoExisteTipoNotif',
            'recordId' => c.Id,
            'userId' => u.Id
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_NotificacionGenerico().invokeMethod('sendNotification', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, output.get('success'));
        System.assert(((String) output.get('message')).contains('Error al enviar notificación'));
    }

    @isTest
    static void testCatchInvokeMethod() {
        // Mandamos un objeto inválido como recordId para romper el Id.valueOf → entra al catch externo
        Map<String, Object> input = new Map<String, Object>{
            'notificationDevName' => 'CaseUpdate',
            'recordId' => new List<String>{ 'valorInvalido' }, // rompe el casteo
            'userId' => '005XXXXXXXXXXXX'
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_NotificacionGenerico().invokeMethod('sendNotification', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, output.get('success'));
        System.assert(((String) output.get('message')).contains('Error en ejecución'));
    }
}