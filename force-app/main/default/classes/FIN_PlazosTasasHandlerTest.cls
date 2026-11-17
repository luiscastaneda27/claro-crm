@isTest
@SuppressWarnings('PMD.CyclomaticComplexity')
private class FIN_PlazosTasasHandlerTest {
    
    // Método para configurar datos de prueba comunes con fechas futuras
    private static List<FIN_Plazos_y_Tasas_info__c> setupTestDataFuturo(Integer diasInicio, Integer diasDuracion) {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(diasInicio);
        Datetime fin = inicio.addDays(diasDuracion);
        
        List<FIN_Plazos_y_Tasas_info__c> testRecords = new List<FIN_Plazos_y_Tasas_info__c>();
        
        testRecords.add(new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,00',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        ));
        
        testRecords.add(new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '24',
            FIN_Tasa_de_Interes__c = '6,50',
            FIN_Fecha_Inicio__c = inicio.addDays(10),
            FIN_Fecha_Fin__c = fin.addDays(10)
        ));
        
        return testRecords;
    }
    
    @isTest
    static void testHandleInsertNoRecursion() {
        // Configuración con fechas futuras (inicio en 5 días, duración 10 días)
        List<FIN_Plazos_y_Tasas_info__c> testRecords = setupTestDataFuturo(5, 10);
        
        Test.startTest();
        insert testRecords;
        Test.stopTest();
        
        // Verificar que los registros se insertaron correctamente
        List<FIN_Plazos_y_Tasas_info__c> insertedRecords = [
            SELECT Id, FIN_Plazo__c, FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id IN :testRecords
        ];
        
        Assert.areEqual(2, insertedRecords.size(), 'Deberían haberse insertado 2 registros');
        
        // Verificar que todas las fechas son futuras
        for (FIN_Plazos_y_Tasas_info__c rec : insertedRecords) {
            Assert.isTrue(rec.FIN_Fecha_Inicio__c > Datetime.now(), 'La fecha de inicio debe ser futura');
            Assert.isTrue(rec.FIN_Fecha_Fin__c > Datetime.now(), 'La fecha de fin debe ser futura');
        }
    }
    
    @isTest
    static void testFinActualizarFechaFinSolapamientoFuturo() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicioExistente = ahora.addDays(10); // futuro
        Datetime finExistente = ahora.addDays(20);    // futuro
        Datetime inicioNuevo = ahora.addDays(15);     // futuro (solapa)
        Datetime finNuevo = ahora.addDays(25);        // futuro
        
        // Crear registro existente con fechas futuras
        FIN_Plazos_y_Tasas_info__c existente = new FIN_Plazos_y_Tasas_info__c();
        existente.FIN_Plazo__c = '12';
        existente.FIN_Tasa_de_Interes__c = '4,50';
        existente.FIN_Fecha_Inicio__c = inicioExistente;
        existente.FIN_Fecha_Fin__c = finExistente;
        
        List<FIN_Plazos_y_Tasas_info__c> lstExistentes = new List<FIN_Plazos_y_Tasas_info__c>();
        lstExistentes.add(existente);
        if (!lstExistentes.isEmpty()) {
            insert lstExistentes;
        }
        
        // Crear registro nuevo que solapa (fechas futuras)
        FIN_Plazos_y_Tasas_info__c nuevo = new FIN_Plazos_y_Tasas_info__c();
        nuevo.FIN_Plazo__c = '12';
        nuevo.FIN_Tasa_de_Interes__c = '5,00';
        nuevo.FIN_Fecha_Inicio__c = inicioNuevo;
        nuevo.FIN_Fecha_Fin__c = finNuevo;
        
        Test.startTest();
        List<FIN_Plazos_y_Tasas_info__c> lstNuevo = new List<FIN_Plazos_y_Tasas_info__c>();
        lstNuevo.add(nuevo);
        if (!lstNuevo.isEmpty()) {
            insert lstNuevo;
        }
        
        // Verificar que el registro existente fue actualizado
        FIN_Plazos_y_Tasas_info__c updatedExistente = [
            SELECT FIN_Fecha_Fin__c 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id = :lstExistentes[0].Id
        ];
            
        Assert.areEqual(
            inicioNuevo,
            updatedExistente.FIN_Fecha_Fin__c,
            'La fecha fin del registro existente debería haberse actualizado al inicio del nuevo registro'
        );
        
        // Verificar que todas las fechas siguen siendo futuras
        Assert.isTrue(
            updatedExistente.FIN_Fecha_Fin__c > ahora,
            'La fecha fin actualizada debe seguir siendo futura'
        );
        Test.stopTest();
    }
    
    @isTest
    static void testFinRemplazarTasasPlazos() {
        // Configuración de datos de prueba con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicioVigente = ahora.addDays(1);
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);
        Datetime finFuturo = ahora.addDays(30);
        
        // Crear registro vigente (debe ser eliminado por el handler)
        FIN_Plazos_y_Tasas_info__c vigente = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '36',
            FIN_Tasa_de_Interes__c = '14',
            FIN_Fecha_Inicio__c = inicioVigente,
            FIN_Fecha_Fin__c = finVigente
        );
        insert vigente;
        
        // Crear registro futuro que activará el reemplazo
        FIN_Plazos_y_Tasas_info__c futuro = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '36',
            FIN_Tasa_de_Interes__c = '30',
            FIN_Fecha_Inicio__c = inicioFuturo,
            FIN_Fecha_Fin__c = finFuturo
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        
        Test.startTest();
        try {
            insert futuro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();
        
        // Verificaciones básicas
        Assert.isFalse(errorLanzado, 'No se esperaba error en la inserción del registro futuro');
        Assert.isNotNull(futuro.Id, 'El registro futuro debería tener un ID asignado');
        
        // Verificar que el registro vigente fue eliminado
        List<FIN_Plazos_y_Tasas_info__c> vigentesDespues = [
            SELECT Id 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id = :vigente.Id
        ];
        Assert.isTrue(
            vigentesDespues.isEmpty(), 
            'El registro vigente debería haber sido eliminado por el handler'
        );
        
        // Verificar que el registro futuro se insertó correctamente
        FIN_Plazos_y_Tasas_info__c futuroInsertado = [
            SELECT FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c, FIN_Plazo__c
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id = :futuro.Id
        ];
        
        Assert.areEqual(
            inicioFuturo, 
            futuroInsertado.FIN_Fecha_Inicio__c, 
            'La fecha de inicio del registro futuro no debería haber cambiado'
        );
        
        Assert.areEqual(
            finFuturo, 
            futuroInsertado.FIN_Fecha_Fin__c, 
            'La fecha de fin del registro futuro no debería haber cambiado'
        );
        
        Assert.areEqual(
            '36', 
            futuroInsertado.FIN_Plazo__c, 
            'El plazo debería coincidir con el valor original'
        );
        
        // Caso adicional: Verificar que no se eliminan registros con plazos diferentes
        FIN_Plazos_y_Tasas_info__c otroPlazo = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,00',
            FIN_Fecha_Inicio__c = ahora.addDays(10),
            FIN_Fecha_Fin__c = ahora.addDays(20)
        );
        insert otroPlazo;
        
        List<FIN_Plazos_y_Tasas_info__c> otrosPlazos = [
            SELECT Id 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE FIN_Plazo__c = '12'
        ];
        
        Assert.isFalse(
            otrosPlazos.isEmpty(), 
            'Los registros con plazos diferentes no deberían ser afectados'
        );
    }
    
    @isTest
    static void testHandleBeforeInsertAjusteHorasMasivoFuturo() {
        // Configuración con fechas futuras para carga masiva
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);   // futuro
        
        FIN_Plazos_y_Tasas_info__c rec = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '36',
            FIN_Tasa_de_Interes__c = '8,50',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin,
            FIN_Masivo__c = true
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Recuperar el registro insertado
        FIN_Plazos_y_Tasas_info__c registroInsertado = [
            SELECT FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id = :rec.Id
        ];
        
        // Verificar ajuste de horas (+5 horas)
        Assert.areEqual(
            inicio.addHours(5), 
            registroInsertado.FIN_Fecha_Inicio__c, 
            'La fecha de inicio debe haberse ajustado en +5 horas para carga masiva'
        );
        
        Assert.areEqual(
            fin.addHours(5), 
            registroInsertado.FIN_Fecha_Fin__c, 
            'La fecha de fin debe haberse ajustado en +5 horas para carga masiva'
        );
        
        // Verificar que las fechas siguen siendo futuras después del ajuste
        Assert.isTrue(
            registroInsertado.FIN_Fecha_Inicio__c > ahora,
            'La fecha de inicio ajustada debe seguir siendo futura'
        );
        Assert.isTrue(
            registroInsertado.FIN_Fecha_Fin__c > ahora,
            'La fecha de fin ajustada debe seguir siendo futura'
        );
    }
    
    @isTest
    static void testHandleBeforeInsertRecorteEntreNuevosFuturos() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicio1 = ahora.addDays(5);  // futuro
        Datetime fin1 = ahora.addDays(15);    // futuro
        Datetime inicio2 = ahora.addDays(10); // futuro (solapa)
        Datetime fin2 = ahora.addDays(20);    // futuro
        
        List<FIN_Plazos_y_Tasas_info__c> nuevos = new List<FIN_Plazos_y_Tasas_info__c>();
        
        nuevos.add(new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,00',
            FIN_Fecha_Inicio__c = inicio1,
            FIN_Fecha_Fin__c = fin1
        ));
        
        nuevos.add(new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '6,00',
            FIN_Fecha_Inicio__c = inicio2,
            FIN_Fecha_Fin__c = fin2
        ));
        
        Test.startTest();
        insert nuevos;
        Test.stopTest();
        
        // Recuperar los registros insertados
        List<FIN_Plazos_y_Tasas_info__c> registrosInsertados = [
            SELECT FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE Id IN :nuevos
            ORDER BY FIN_Fecha_Inicio__c
        ];
        
        // Verificar que el primer registro fue recortado
        Assert.areEqual(
            inicio2, 
            registrosInsertados[0].FIN_Fecha_Fin__c, 
            'La fecha fin del primer registro debería haberse ajustado al inicio del segundo registro'
        );
        
        // Verificar que el segundo registro no fue modificado
        Assert.areEqual(
            fin2, 
            registrosInsertados[1].FIN_Fecha_Fin__c, 
            'La fecha fin del segundo registro no debería haber cambiado'
        );
        
        // Verificar que todas las fechas siguen siendo futuras
        for (FIN_Plazos_y_Tasas_info__c rec : registrosInsertados) {
            Assert.isTrue(rec.FIN_Fecha_Inicio__c > ahora, 'Todas las fechas de inicio deben ser futuras');
            Assert.isTrue(rec.FIN_Fecha_Fin__c > ahora, 'Todas las fechas de fin deben ser futuras');
        }
    }
    
    @isTest
    static void testRecursionControlFuturo() {
        // Configuración con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);  // futuro
        
        FIN_Plazos_y_Tasas_info__c rec = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,00',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        );
        
        // Forzar recursividad
        FIN_PlazosTasasHandler.enEjecucion = true;
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que el registro se insertó (el control de recursividad está en el handler)
        List<FIN_Plazos_y_Tasas_info__c> registrosInsertados = [
            SELECT Id 
            FROM FIN_Plazos_y_Tasas_info__c 
            WHERE FIN_Plazo__c = '12' 
            AND FIN_Fecha_Inicio__c = :inicio
        ];
        
        Assert.isFalse(
            registrosInsertados.isEmpty(), 
            'El registro debería haberse insertado a pesar de la recursividad (el control está en el handler)'
        );
        
        // Restablecer el flag
        FIN_PlazosTasasHandler.enEjecucion = false;
    }
    
    @isTest
    static void testValidacionesFechaFuturas() {
        // Configuración con fecha de inicio pasada (debería fallar)
        Datetime ahora = Datetime.now();
        Datetime inicioPasado = ahora.addDays(-1); // pasado
        Datetime finFuturo = ahora.addDays(10);    // futuro
        
        FIN_Plazos_y_Tasas_info__c recInvalido = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,00',
            FIN_Fecha_Inicio__c = inicioPasado,
            FIN_Fecha_Fin__c = finFuturo
        );
        
        Boolean errorLanzado = false;
        String mensajeError = '';
        
        Test.startTest();
        try {
            insert recInvalido;
        } catch (DmlException e) {
            errorLanzado = true;
            mensajeError = e.getMessage();
        }
        Test.stopTest();
        
        Assert.isTrue(
            errorLanzado,
            'Debería haber fallado al insertar un registro con fecha de inicio en el pasado'
        );
        
        // Configuración con fecha de fin pasada (debería fallar)
        Datetime inicioFuturo = ahora.addDays(1);  // futuro
        Datetime finPasado = ahora.addDays(-5);    // pasado
        
        FIN_Plazos_y_Tasas_info__c recInvalido2 = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '24',
            FIN_Tasa_de_Interes__c = '6,50',
            FIN_Fecha_Inicio__c = inicioFuturo,
            FIN_Fecha_Fin__c = finPasado
        );
        
        errorLanzado = false;
        mensajeError = '';
        
        try {
            insert recInvalido2;
        } catch (DmlException e) {
            errorLanzado = true;
            mensajeError = e.getMessage();
        }
        
        Assert.isTrue(
            errorLanzado,
            'Debería haber fallado al insertar un registro con fecha de fin en el pasado'
        );
    }
    
    // Validaciones plazos y tasas TST
    
    @isTest
    static void testValidacionesExito() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,25',
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(10)
        );

        Test.startTest();
        insert reg;
        Test.stopTest();

        Assert.isNotNull(reg.Id, 'Se esperaba que el registro se insertara correctamente');
    }

    @isTest
    static void testPlazoFueraDeRangoPicklist() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '100',
            FIN_Tasa_de_Interes__c = '5,50',
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(10)
        );

        Boolean errorLanzado = false;
        String mensaje = '';

        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por plazo fuera de rango');
        } else {
            Assert.isTrue(
                mensaje.contains('Plazo fuera de rango') || mensaje.contains('Plazo debe ser un número válido'),
                'Se esperaba el mensaje de error adecuado por plazo fuera de rango'
            );
        }
    }

    @isTest
    static void testTasaRequerida() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = null,
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(5)
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por tasa requerida');
        } else {
            Assert.isTrue(
                mensaje.contains('Tasa requerida.'),
                'Debe marcar error por tasa vacía'
            );
        }
    }

    @isTest
    static void testTasaFormatoInvalido() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = 'abc',
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(5)
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por formato inválido en tasa');
        } else {
            Assert.isTrue(
                mensaje.contains('Formato inválido. Use números con coma decimal (ej: 5,23 o 12,50)'),
                'Debe marcar error por valor no numérico en tasa'
            );
        }
    }

    @isTest
    static void testTasaUnDecimalAutocompletado() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '2,5',
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(3)
        );

        Test.startTest();
        insert reg;
        Test.stopTest();

        Assert.isNotNull(
            reg.Id,
            'Se esperaba que se insertara con tasa de un decimal (autocompletada)'
        );
    }

    @isTest
    static void testTasaConMasDeDosDecimales() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '12',
            FIN_Tasa_de_Interes__c = '5,255',
            FIN_Fecha_Inicio__c = Datetime.now().addDays(1),
            FIN_Fecha_Fin__c = Datetime.now().addDays(10)
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Debe fallar por tasa con más de 2 decimales');
        Assert.isTrue(
            mensaje.contains('Formato inválido'),
            'Mensaje esperado para formato inválido'
        );
    }

    @isTest
    static void testDuplicadoMismaCarga() {
        Datetime inicio = Datetime.now().addDays(1);
        Datetime fin = Datetime.now().addDays(5);

        FIN_Plazos_y_Tasas_info__c reg1 = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '6',
            FIN_Tasa_de_Interes__c = '2,50',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        );

        FIN_Plazos_y_Tasas_info__c reg2 = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '6',
            FIN_Tasa_de_Interes__c = '2,50',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert new List<FIN_Plazos_y_Tasas_info__c>{reg1, reg2};
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por duplicado en la misma carga');
        } else {
            Assert.isTrue(
                mensaje.contains('Registro duplicado en la carga'),
                'Debe marcar error por clave duplicada en el mismo insert'
            );
        }
    }

    @isTest
    static void testFechaInicioRequerida() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '6',
            FIN_Tasa_de_Interes__c = '2,50',
            FIN_Fecha_Fin__c = DateTime.now().addDays(2)
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();
        
        if (!errorLanzado) {
            Assert.fail('Debe lanzar error por fecha inicio en pasado');
        } else {
            Assert.isTrue(
                mensaje.contains('Ambas fechas (inicio y fin) son requeridas'),
                'Debe marcar error por fecha inicio en pasado'
            );
        }
    }

    @isTest
    static void testFechaInicioMenorActual() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '6',
            FIN_Tasa_de_Interes__c = '2,50',
            FIN_Fecha_Inicio__c = DateTime.now().addDays(-1),
            FIN_Fecha_Fin__c = DateTime.now().addDays(2)
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();
        
        if (!errorLanzado) {
            Assert.fail('Debe lanzar error por fecha inicio en pasado');
        } else {
            Assert.isTrue(
                mensaje.contains('Fecha inicio < fecha actual'),
                'Debe marcar error por fecha inicio en pasado'
            );
        }
    }

    @isTest
    static void testFechaInicioMayorFin() {
        FIN_Plazos_y_Tasas_info__c reg = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '6',
            FIN_Tasa_de_Interes__c = '2,50',
            FIN_Fecha_Inicio__c = DateTime.now().addDays(15),
            FIN_Fecha_Fin__c = DateTime.now().addDays(1)
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        
        Test.startTest();
        try {
            insert reg;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();
        
        if (!errorLanzado) {
            Assert.fail('Debe lanzar error por fecha fin menor inicio');
        } else {
            Assert.isTrue(
                mensaje.contains('Fecha fin < fecha inicio'),
                'Debe marcar error por fecha fin menor inicio'
            );
        }
    }
    
    @isTest
    static void testDuplicados() {
        DateTime ahora = DateTime.now();
        DateTime inicio = ahora.addDays(10);
        DateTime fin =  ahora.addDays(40);
        FIN_Plazos_y_Tasas_info__c reg1 = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '20',
            FIN_Tasa_de_Interes__c = '35,50',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        );
        
        insert reg1;

        FIN_Plazos_y_Tasas_info__c reg2 = new FIN_Plazos_y_Tasas_info__c(
            FIN_Plazo__c = '20',
            FIN_Tasa_de_Interes__c = '35,50',
            FIN_Fecha_Inicio__c = inicio,
            FIN_Fecha_Fin__c = fin
        );

        Boolean errorLanzado = false;
        String mensaje = '';

        Test.startTest();
        try {
            insert reg2;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por duplicado');
        } else {
            Assert.isTrue(
                mensaje.contains('Este registro ya existe en Salesforce.'),
                'Se esperaba el mensaje de error adecuado por duplicado'
            );
        }
    }
}