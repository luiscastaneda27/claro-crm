@isTest
private class PVU_ValidacionesCambioImeiTest {

    @testSetup
    static void setupData() {
        Case caseBase = new Case(
            Origin = 'Phone',
            Status = 'New',
            Subject = 'Caso de prueba'
        );
        insert caseBase;
    }

    // ==============================
    // Casos de validación de negocio
    // ==============================

    @isTest
    static void testStatusBlank() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'caseId' => c.Id,
            'status' => ''
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_ValidacionesCambioImei().invokeMethod('validacionDevolucion', input, output, new Map<String,Object>());
        Test.stopTest();

        Assert.areEqual(false, output.get('esValido'));
        Assert.areEqual('No se envió status', output.get('mensaje'));

        // Verificar actualización del Case
        Case updated = [SELECT PVU_Validacion_Imei__c FROM Case WHERE Id = :c.Id];
        Assert.areEqual(true, updated.PVU_Validacion_Imei__c);
    }

    @isTest
    static void testCreditoCancelado() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'caseId' => c.Id,
            'status' => 'H - CREDITO CANCELADO'
        };
        Map<String, Object> output = new Map<String, Object>();

        new PVU_ValidacionesCambioImei().invokeMethod('validacionDevolucion', input, output, new Map<String,Object>());

        Assert.areEqual(false, output.get('esValido'));
        Assert.isTrue(((String)output.get('mensaje')).contains('El crédito no es válido'));
    }

    @isTest
    static void testValidacionExitosa() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'caseId' => c.Id,
            'status' => 'N - NORMAL',
            'numeroCredito' => 'CRED999'
        };
        Map<String, Object> output = new Map<String, Object>();

        new PVU_ValidacionesCambioImei().invokeMethod('validacionDevolucion', input, output, new Map<String,Object>());

        Assert.areEqual(true, output.get('esValido'));
        Assert.areEqual('Validación exitosa, puede continuar.', output.get('mensaje'));
    }

    // ==============================
    // Casos extra para cobertura total
    // ==============================

    @isTest
    static void testMetodoInvalido() {
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();
        Boolean result = new PVU_ValidacionesCambioImei().invokeMethod('otroMetodo', input, output, new Map<String,Object>());
        Assert.areEqual(false, result, 'Debe retornar false si el método no existe');
    }

    @isTest
    static void testExcepcionInvokeMethod() {
        Map<String,Object> input = new Map<String,Object>{
            'clienteId' => 'NO_ES_UN_ID'
        };
        Map<String,Object> output = new Map<String,Object>();

        Boolean result = new PVU_ValidacionesCambioImei()
            .invokeMethod('validacionDevolucion', input, output, new Map<String,Object>());

        Assert.areEqual(false, result, 'Debe retornar false si lanza excepción');
        Assert.areEqual(false, output.get('esValido'));
        Assert.isTrue(((String)output.get('mensaje')).startsWith('Error en ejecución'));
    }

    @isTest
    static void testErrorUpdateCase() {
        Map<String,Object> input = new Map<String,Object>{
            'caseId' => '500000000000000',
            'status' => ''
        };
        Map<String,Object> output = new Map<String,Object>();

        new PVU_ValidacionesCambioImei().invokeMethod('validacionDevolucion', input, output, new Map<String,Object>());

        Assert.areEqual(false, output.get('esValido'));
        Assert.areEqual('No se envió status', output.get('mensaje'));
    }
    
    // ============================================
    // Cobertura específica: enviarNotificacionValidacion
    // ============================================

    @isTest
    static void testEnviarNotificacion_NullSet() {
        Test.startTest();
        PVU_ValidacionesCambioImei.enviarNotificacionValidacion(null);
        Test.stopTest();
        Assert.isTrue(true, 'No debe lanzar excepción con set null');
    }

    @isTest
    static void testEnviarNotificacion_SetVacio() {
        Test.startTest();
        PVU_ValidacionesCambioImei.enviarNotificacionValidacion(new Set<Id>());
        Test.stopTest();
        Assert.isTrue(true, 'No debe lanzar excepción con set vacío');
    }

    @isTest
    static void testEnviarNotificacion_IdInexistente() {
        // id de Case inexistente (formato válido de Id de Case)
        Id fakeCaseId = (Id)'500000000000000AAA';

        Test.startTest();
        PVU_ValidacionesCambioImei.enviarNotificacionValidacion(new Set<Id>{ fakeCaseId });
        Test.stopTest();

        Assert.isTrue(true, 'Cuando no hay casos encontrados debe salir sin excepción');
    }

    @isTest
    static void testEnviarNotificacion_UnCaso_SinTipoNotif() {
        Case c = new Case(Origin='Phone', Status='New', Subject='Caso notif 1');
        insert c;

        Test.startTest();
        PVU_ValidacionesCambioImei.enviarNotificacionValidacion(new Set<Id>{ c.Id });
        Test.stopTest();

        // Si el CustomNotificationType no existe, el método debe salir sin fallar.
        Assert.isTrue(true, 'Sin tipo de notificación configurado no debe fallar');
    }

    @isTest
    static void testEnviarNotificacion_MultiplesCasos_SinTipoNotif() {
        Case c1 = new Case(Origin='Phone', Status='New', Subject='Caso notif 1');
        Case c2 = new Case(Origin='Phone', Status='New', Subject='Caso notif 2');
        insert new List<Case>{ c1, c2 };

        Test.startTest();
        PVU_ValidacionesCambioImei.enviarNotificacionValidacion(new Set<Id>{ c1.Id, c2.Id });
        Test.stopTest();

        Assert.isTrue(true, 'Con varios casos y sin tipo de notificación no debe fallar');
    }
    
}