@isTest
private class FIN_PlazosPreciosTriggerHandlerTest {

    // Helper para generar datos válidos base
    private static FIN_PlazosPrecios__c crearRegistroValido() {
        return new FIN_PlazosPrecios__c(
            FIN_Producto__c = 'Tecnología', // Asegúrate de que exista este valor en el picklist
            FIN_PVP_Min__c = '100',
            FIN_PVP_Max__c = '200',
            FIN_Plazo_1_6__c = 'SI',
            FIN_Plazo_7_12__c = 'SI',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'NO',
            FIN_Plazo_25_36__c = 'NO',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );
    }

    @isTest
    static void testProductoInvalido() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_Producto__c = 'ProductoInvalido';

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();
        
        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar producto inválido');
    }

    @isTest
    static void testDuplicadoEnLista() {
        FIN_PlazosPrecios__c r1 = crearRegistroValido();
        FIN_PlazosPrecios__c r2 = crearRegistroValido(); // Igual que r1

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{r1, r2});
        Test.stopTest();

        Assert.isTrue(r2.getErrors().size() > 0, 'Debe detectar duplicado en la misma lista');
    }

    @isTest
    static void testPVPMinDecimal() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_PVP_Min__c = '100.5';

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por PVP Min decimal');
    }

    @isTest
    static void testPVPMaxNoNumerico() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_PVP_Max__c = 'abc';

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por PVP Max no numérico');
    }

    @isTest
    static void testPVPMinMayorQueMax() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_PVP_Min__c = '300';
        registro.FIN_PVP_Max__c = '200';

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por PVP Min mayor que Max');
    }

    @isTest
    static void testFechaDesdePasada() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_Desde__c = DateTime.now().addDays(-1);

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por fecha desde pasada');
    }// 5. Fechas sin hora (00:00:00)
        

    @isTest
    static void testFechaDesdeInvalida() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_Desde__c = DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0));

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por fecha invalida');
    }

    @isTest
    static void testFechaHastaInvalida() {
        FIN_PlazosPrecios__c registro = crearRegistroValido();
        registro.FIN_Hasta__c = DateTime.newInstance(Date.today(), Time.newInstance(0,0,1,0));
        registro.FIN_Masivo__c = true;

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarDuplicados(new List<FIN_PlazosPrecios__c>{registro});
        Test.stopTest();

        Assert.isTrue(registro.getErrors().size() > 0, 'Debe marcar error por fecha invalida');
    }

    @isTest
    static void testAjustarFechasHastaValoresEspecificos() {
        // Configuración con valores específicos que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicioExistente = ahora.addDays(10);
        Datetime finExistente = ahora.addDays(20);
        Datetime inicioNuevo = ahora.addDays(15);
        Datetime finNuevo = ahora.addDays(25);

        FIN_PlazosPrecios__c existente = crearRegistroValido();
        existente.FIN_Desde__c = inicioExistente;
        existente.FIN_Hasta__c = finExistente;
        
        insert existente;

        FIN_PlazosPrecios__c nuevo = crearRegistroValido();
        nuevo.FIN_Desde__c = inicioNuevo;
        nuevo.FIN_Hasta__c = finNuevo;
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar ajuste de fechas
        FIN_PlazosPrecios__c updatedExistente = [
            SELECT FIN_Hasta__c
            FROM FIN_PlazosPrecios__c 
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(inicioNuevo, updatedExistente.FIN_Hasta__c, 'Fecha Hasta no se ajustó correctamente');
        
    }
    @isTest
    static void testValidarYPrepararSolapamientoMasivo() {
        // Fechas base
        Datetime base = Datetime.newInstance(2026, 1, 10, 10, 0, 0);

        // Registro principal
        FIN_PlazosPrecios__c r1 = new FIN_PlazosPrecios__c(
            FIN_Producto__c = 'Tecnología',
            FIN_PVP_Min__c = '100',
            FIN_PVP_Max__c = '200',
            FIN_Plazo_1_6__c = 'SI',
            FIN_Plazo_7_12__c = 'SI',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'NO',
            FIN_Plazo_25_36__c = 'NO',
            FIN_Desde__c = base,
            FIN_Hasta__c = base.addDays(10),
            FIN_Masivo__c = true
        );

        // Registro que solapa y debe cortar la fecha del primero
        FIN_PlazosPrecios__c r2 = new FIN_PlazosPrecios__c(
            FIN_Producto__c = 'Tecnología',
            FIN_PVP_Min__c = '100',
            FIN_PVP_Max__c = '200',
            FIN_Plazo_1_6__c = 'SI',
            FIN_Plazo_7_12__c = 'SI',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'NO',
            FIN_Plazo_25_36__c = 'NO',
            FIN_Desde__c = base.addDays(5),
            FIN_Hasta__c = base.addDays(15),
            FIN_Masivo__c = true
        );

        List<FIN_PlazosPrecios__c> lista = new List<FIN_PlazosPrecios__c>{ r1, r2 };

        Test.startTest();
        FIN_PlazosPreciosTriggerHandler.validarYPreparar(lista);
        Test.stopTest();

        // Se espera:
        // r1.Hasta = r2.Desde (ambos +5 horas por masivo)
        Datetime desdeR2Esperado = base.addDays(5).addHours(5);

        Assert.areEqual(
            desdeR2Esperado,
            r1.FIN_Hasta__c,
            'La fecha Hasta del registro principal no fue ajustada correctamente'
        );
    }

}