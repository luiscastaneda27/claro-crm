@IsTest
private class PVU_CierreCasoDigitalesTest {

    // Utilidad para ejecutar el invocable con el payload esperado
    private static Map<String, Object> runInvoke(String accountId, String voz) {
        PVU_CierreCasoDigitales svc = new PVU_CierreCasoDigitales();
        Map<String, Object> input   = new Map<String, Object>{
            'AccountId' => (Id)accountId,
            'vozDeCliente' => voz
        };
        Map<String, Object> outMap  = new Map<String, Object>();
        Test.startTest();
        Boolean ok = svc.invokeMethod('cerrarCasoDigitales', input, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assertEquals(true, ok, 'invokeMethod debe devolver true');
        return outMap;
    }

    // Crea un caso genérico con los campos mínimos para las pruebas
    private static Case makeCase(Id accId, String status, String vocL3,String vocL1,String vocL2, String minReported, String numLine) {
        Case c = new Case();
        c.AccountId = accId;
        c.Status = status;
        c.PVU_Level1__c = vocL1;
        c.PVU_Level2__c = vocL2;
        c.PVU_Level3__c = vocL3;
        c.PVU_MINReporteImei__c = minReported;
        c.PVU_NumeroLinea__c = numLine;
        return c;
    }

    @IsTest
    static void test_CancelacionVoluntaria_cierraDigital() {
        Account a1 = new Account(Name='Acme CV'); insert a1;
        Account a2 = new Account(Name='Otra Cuenta'); insert a2;

        // Targets (mismo Account, abiertos/en curso y con VOC Digital)
        Case t1 = makeCase(a1.Id, 'En curso', 'Cancelación Voluntaria Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111111', '5711111111111');
        Case t2 = makeCase(a1.Id, 'Abierto',  'Cancelación Voluntaria Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111113', '5711111111113');
        // Distractor en otra cuenta (no debe cerrarse)
        Case d1 = makeCase(a2.Id, 'En curso', 'Cancelación Voluntaria Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111110', '5711111111110');
        // Distractor con otra VOC (no debe cerrarse)
        Case d2 = makeCase(a1.Id, 'En curso', 'Cambio de pospago a prepago Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111112', '5711111111112');
        insert new List<Case>{ t1, t2, d1, d2 };

        Map<String, Object> outMap = runInvoke(a1.Id, 'Cancelación Voluntaria');

        // Reconsultar
        List<Case> all = [SELECT Id, Status, PVU_Codigo_de_Cierre__c, PVU_Observaciones__c, PVU_Level3__c, AccountId
                          FROM Case WHERE Id IN :new List<Id>{ t1.Id, t2.Id, d1.Id, d2.Id }];

        // Validaciones
        Integer closed = 0;
        for (Case c : all) {
            if (c.Id == t1.Id || c.Id == t2.Id) {
                System.assertEquals('Cerrado', c.Status, 'Debe cerrar casos CV Digital en la misma Account');
                System.assertEquals('Cancelación Digital', c.PVU_Codigo_de_Cierre__c, 'Código de cierre incorrecto');
                System.assertEquals('Solicitud atendida en WhatsApp', c.PVU_Observaciones__c, 'Observación incorrecta');
                closed++;
            } else {
                // Distractores no cierran
                System.assertNotEquals('Cerrado', c.Status, 'No debe cerrar casos fuera de alcance');
            }
        }
        System.assertEquals(2, closed, 'Cantidad cerrada incorrecta');
        System.assertEquals(2, (Integer)outMap.get('closedCount'), 'closedCount en outMap incorrecto');
        System.assertEquals(true, (Boolean)outMap.get('success'), 'success debería ser true');
    }

    @IsTest
    static void test_CambioPospagoPrepago_cierraDigital() {
        Account a1 = new Account(Name='Acme CPP'); insert a1;

        Case t1 = makeCase(a1.Id, 'En curso', 'Cambio de pospago a prepago Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111111', '5711111111111' );
        Case t2 = makeCase(a1.Id, 'Abierto',  'Cambio de pospago a prepago Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111112', '5711111111112' );
        Case d1 = makeCase(a1.Id, 'En curso', 'Cancelación Voluntaria Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111113', '5711111111113' ); // distractor
        insert new List<Case>{ t1, t2, d1 };

        Map<String, Object> outMap = runInvoke(a1.Id, 'Cambio de pospago a prepago');

        List<Case> all = [SELECT Id, Status, PVU_Codigo_de_Cierre__c, PVU_Observaciones__c
                          FROM Case WHERE Id IN :new List<Id>{ t1.Id, t2.Id, d1.Id }];

        Integer closed = 0;
        for (Case c : all) {
            if (c.Id == t1.Id || c.Id == t2.Id) {
                System.assertEquals('Cerrado', c.Status);
                System.assertEquals('Paso a prepago Digital', c.PVU_Codigo_de_Cierre__c);
                System.assertEquals('Solicitud atendida en WhatsApp', c.PVU_Observaciones__c);
                closed++;
            } else {
                System.assertNotEquals('Cerrado', c.Status);
            }
        }
        System.assertEquals(2, closed);
        System.assertEquals(2, (Integer)outMap.get('closedCount'));
        System.assertEquals(true, (Boolean)outMap.get('success'));
    }

    @IsTest
    static void test_CambioPlanMovil_cierraDigitalDW() {
        Account a1 = new Account(Name='Acme CPM'); insert a1;

        Case t1 = makeCase(a1.Id, 'En curso', 'Cambio de plan móvil Digital DW','Solicitud de información y modificaciones', 'Cambio de plan','5711111111111', '5711111111111' );
        
        insert new List<Case>{ t1 };

        Map<String, Object> outMap = runInvoke(a1.Id, 'Cambio de plan móvil');

        List<Case> all = [SELECT Id, Status, PVU_Codigo_de_Cierre__c, PVU_Observaciones__c
                          FROM Case WHERE Id IN :new List<Id>{ t1.Id }];

        for (Case c : all) {
            if (c.Id == t1.Id) {
                System.assertEquals('Cerrado', c.Status);
                System.assertEquals('Cambio plan DW Digital', c.PVU_Codigo_de_Cierre__c);
                System.assertEquals('Solicitud atendida en WhatsApp', c.PVU_Observaciones__c);
            } else {
                System.assertNotEquals('Cerrado', c.Status);
            }
        }
        System.assertEquals(1, (Integer)outMap.get('closedCount'));
        System.assertEquals(true, (Boolean)outMap.get('success'));
    }

    @IsTest
    static void test_NoMatch_noCierra() {
        Account a1 = new Account(Name='Acme NoMatch'); insert a1;

        Case t1 = makeCase(a1.Id, 'En curso', 'Cancelación Voluntaria Digital','Solicitud de información y modificaciones', 'Cancelación Servicio Móvil','5711111111111', '5711111111111' );
        insert t1;

        Map<String, Object> outMap = runInvoke(a1.Id, 'Otra VOC');

        t1 = [SELECT Status FROM Case WHERE Id = :t1.Id];
        System.assertNotEquals('Cerrado', t1.Status, 'No debería cerrar para VOC no contemplada');
        System.assertEquals(0, (Integer)outMap.get('closedCount'));
        System.assertEquals(true, (Boolean)outMap.get('success'));
    }

    @IsTest
    static void test_ValidacionesEntrada() {
        // Falta AccountId
        PVU_CierreCasoDigitales svc = new PVU_CierreCasoDigitales();
        Map<String, Object> outMap = new Map<String, Object>();
        Boolean ok = svc.invokeMethod('cerrarCasoDigitales',
            new Map<String, Object>{ 'vozDeCliente' => 'Cancelación Voluntaria' },
            outMap,
            new Map<String, Object>()
        );
        System.assertEquals(true, ok, 'invokeMethod debe devolver true aunque falle validación');
        System.assertEquals(false, (Boolean)outMap.get('success'), 'success debe ser false cuando falta AccountId');

        // Voz de Cliente vacía
        Account a1 = new Account(Name='Acme Entrada'); insert a1;
        outMap = runInvoke(a1.Id, '');
        System.assertEquals(0, (Integer)outMap.get('closedCount'));
        System.assertEquals(true, (Boolean)outMap.get('success'));
    }
}