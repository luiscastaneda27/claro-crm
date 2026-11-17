@isTest
private class FIN_TasaAntiguedadHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Datos de prueba comunes
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c registroValido = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'C',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert registroValido;
    }
    
    @isTest
    static void testHandleInsert_NoRecursion() {
         // Datos de prueba comunes
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que los registros se insertaron correctamente
        List<FIN_TasaPorAntiguedadCliente__c> insertedRecords = [
            SELECT Id, FIN_Calificacion_Cliente__c,FIN_Antiguedad_minima_meses__c,FIN_Antiguedad_maxima_meses__c, FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(1, insertedRecords.size(), 'Debería haberse insertado el registro');
        
        // Verificar que todas las fechas son futuras
        Assert.isTrue(insertedRecords[0].FIN_Desde__c > ahora, 'La fecha Desde debe ser futura');
        Assert.isTrue(insertedRecords[0].FIN_Hasta__c > ahora, 'La fecha Hasta debe ser futura');
    }
    
    @isTest
    static void testAjustarFechasHasta_Solapamiento() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicioExistente = ahora.addDays(10); // futuro
        Datetime finExistente = ahora.addDays(20);    // futuro
        Datetime inicioNuevo = ahora.addDays(15);     // futuro (solapa)
        Datetime finNuevo = ahora.addDays(25);        // futuro
        
        // Crear registro existente con fechas futuras
        FIN_TasaPorAntiguedadCliente__c existente = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicioExistente,
            FIN_Hasta__c = finExistente,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert existente;
        
        // Crear registro nuevo que solapa (fechas futuras)
       FIN_TasaPorAntiguedadCliente__c nuevo = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicioNuevo,
            FIN_Hasta__c = finNuevo,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar que el registro existente fue actualizado
        FIN_TasaPorAntiguedadCliente__c updatedExistente = [
            SELECT FIN_Hasta__c 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(
            inicioNuevo, 
            updatedExistente.FIN_Hasta__c, 
            'La fecha Hasta del registro existente debería haberse actualizado al Desde del nuevo registro'
        );
    }
    
    @isTest
    static void testEliminarDuplicados() {
        // Configuración de datos de prueba con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicioVigente = ahora.addDays(1);  // Registro "vigente" (inicio en pasado, fin en futuro)
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);    // Registro futuro que reemplazará al vigente
        Datetime finFuturo = ahora.addDays(30);
        
         
        // Crear registro existente con fechas futuras
        FIN_TasaPorAntiguedadCliente__c vigente = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert vigente;
        
        // Crear registro nuevo que solapa (fechas futuras)
       FIN_TasaPorAntiguedadCliente__c futuro = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '10,00'
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
        List<FIN_TasaPorAntiguedadCliente__c> vigentesDespues = [
            SELECT Id 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(
            vigentesDespues.isEmpty(), 
            'El registro vigente debería haber sido eliminado por el handler'
        );
        
        // Verificar que el registro futuro se insertó correctamente
        FIN_TasaPorAntiguedadCliente__c futuroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Calificacion_Cliente__c, FIN_Antiguedad_minima_meses__c, FIN_Antiguedad_maxima_meses__c
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :futuro.Id
        ];
        
        Assert.areEqual(
            inicioFuturo, 
            futuroInsertado.FIN_Desde__c, 
            'La fecha Desde del registro futuro no debería haber cambiado'
        );
        
        Assert.areEqual(
            finFuturo, 
            futuroInsertado.FIN_Hasta__c, 
            'La fecha Hasta del registro futuro no debería haber cambiado'
        );
    }
    
    @isTest
    static void testHandleBeforeInsert_AjusteHorasMasivo() {
        // Configuración con fechas futuras para carga masiva
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);   // futuro
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '10,00',
            FIN_Masivo__c = true
            
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Recuperar el registro insertado
        FIN_TasaPorAntiguedadCliente__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :rec.Id
        ];
        
        // Verificar ajuste de horas (+5 horas)
        Assert.areEqual(
            inicio.addHours(5), 
            registroInsertado.FIN_Desde__c, 
            'La fecha Desde debe haberse ajustado en +5 horas para carga masiva'
        );
        
        Assert.areEqual(
            fin.addHours(5), 
            registroInsertado.FIN_Hasta__c, 
            'La fecha Hasta debe haberse ajustado en +5 horas para carga masiva'
        );
    }
    
    @isTest
    static void testHandleBeforeInsert_RecorteEntreRegistros() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicio1 = ahora.addDays(5);  // futuro
        Datetime fin1 = ahora.addDays(15);    // futuro
        Datetime inicio2 = ahora.addDays(10); // futuro (solapa)
        Datetime fin2 = ahora.addDays(20);    // futuro
        
        List<FIN_TasaPorAntiguedadCliente__c> nuevos = new List<FIN_TasaPorAntiguedadCliente__c>();
        
        nuevos.add(new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio1,
            FIN_Hasta__c = fin1,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '10,00'
        ));
        
        nuevos.add(new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio2,
            FIN_Hasta__c = fin2,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '10,00'
        ));
        
        Test.startTest();
        insert nuevos;
        Test.stopTest();
        
        // Recuperar los registros insertados
        List<FIN_TasaPorAntiguedadCliente__c> registrosInsertados = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id IN :nuevos
            ORDER BY FIN_Desde__c
        ];
        
        // Verificar que el primer registro fue recortado
        Assert.areEqual(
            inicio2, 
            registrosInsertados[0].FIN_Hasta__c, 
            'La fecha Hasta del primer registro debería haberse ajustado al Desde del segundo registro'
        );
    }
    
     @isTest
    static void testRecursionControl() {
        // Configuración con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);  // futuro
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '10,00'
        );
        
        // Forzar recursividad
        FIN_TasaAntiguedadHandler.enEjecucion = true;
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que el registro se insertó
        List<FIN_TasaPorAntiguedadCliente__c> registrosInsertados = [
            SELECT Id 
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE FIN_Calificacion_Cliente__c = 'A' 
            AND FIN_Desde__c = :inicio
        ];
        
        Assert.isFalse(
            registrosInsertados.isEmpty(), 
            'El registro debería haberse insertado a pesar de la recursividad'
        );
        
        // Restablecer el flag
        FIN_TasaPorProductoHandler.enEjecucion = false;
    }
    
     @isTest
    static void testInsertRegistroValido() {
        // Configuración de datos de prueba
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(10);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'B',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '6',
            FIN_Antiguedad_maxima_meses__c = '12',
            FIN_Plazo_Minimo__c = '3',
            FIN_Plazo_Maximo__c = '6',
            FIN_Tasa_Interes__c = '8,50'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        // Verificaciones
        Assert.isFalse(errorLanzado, 'No se esperaba error en la inserción del registro');
        Assert.isNotNull(rec.Id, 'El registro debería tener un ID asignado');

        // Recuperar el registro insertado
        FIN_TasaPorAntiguedadCliente__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Calificacion_Cliente__c, 
                   FIN_Antiguedad_minima_meses__c, FIN_Antiguedad_maxima_meses__c,
                   FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorAntiguedadCliente__c 
            WHERE Id = :rec.Id
        ];

        // Verificar valores
        Assert.areEqual(
            inicio, 
            registroInsertado.FIN_Desde__c, 
            'La fecha Desde no coincide'
        );
        
        Assert.areEqual(
            fin, 
            registroInsertado.FIN_Hasta__c, 
            'La fecha Hasta no coincide'
        );
        
        Assert.areEqual(
            'B', 
            registroInsertado.FIN_Calificacion_Cliente__c, 
            'La calificación no coincide'
        );
    }
    
    @isTest
    static void testValidarFechasRequeridas() {
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por fechas requeridas');
        Assert.isTrue(mensaje.contains('Ambas fechas (Desde y Hasta) son requeridas'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarFechasPasadas() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(-1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por fecha Desde en pasado');
        Assert.isTrue(mensaje.contains('Desde < hoy'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarAntiguedadNumerica() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = 'abc',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por antigüedad no numérica');
        Assert.isTrue(mensaje.contains('La antigüedad mínima debe ser un número entre 0 y 9999'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarAntiguedadMinMayorMax() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '24',
            FIN_Antiguedad_maxima_meses__c = '12',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por antigüedad mínima mayor que máxima');
        Assert.isTrue(mensaje.contains('La antigüedad mínima no puede ser mayor que la máxima'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarTasaInteresFormato() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5.00' // Punto en lugar de coma
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por formato de tasa incorrecto');
        Assert.isTrue(mensaje.contains('Formato inválido'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarPlazoMinMayorMax() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'A',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '6',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por plazo mínimo mayor al máximo');
        Assert.isTrue(mensaje.contains('Plazo máximo < plazo mínimo'), 'Mensaje de error incorrecto');
    }
    
    
    
    @isTest
    static void testValidarDuplicadosExistentes() {
        // Obtener registro existente del testSetup
        FIN_TasaPorAntiguedadCliente__c existente = [SELECT FIN_Calificacion_Cliente__c, FIN_Desde__c, FIN_Hasta__c, 
                                                    FIN_Antiguedad_minima_meses__c, FIN_Antiguedad_maxima_meses__c,
                                                    FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c 
                                                    FROM FIN_TasaPorAntiguedadCliente__c LIMIT 1];
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = existente.FIN_Calificacion_Cliente__c,
            FIN_Desde__c = existente.FIN_Desde__c,
            FIN_Hasta__c = existente.FIN_Hasta__c,
            FIN_Antiguedad_minima_meses__c = existente.FIN_Antiguedad_minima_meses__c,
            FIN_Antiguedad_maxima_meses__c = existente.FIN_Antiguedad_maxima_meses__c,
            FIN_Plazo_Minimo__c = existente.FIN_Plazo_Minimo__c,
            FIN_Plazo_Maximo__c = existente.FIN_Plazo_Maximo__c,
            FIN_Tasa_Interes__c = existente.FIN_Tasa_Interes__c
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por registro duplicado existente');
        Assert.isTrue(mensaje.contains('Ya existe un registro en salesforce'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarCalificacionPicklist() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorAntiguedadCliente__c rec = new FIN_TasaPorAntiguedadCliente__c(
            FIN_Calificacion_Cliente__c = 'X', // Calificación inválida
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Antiguedad_minima_meses__c = '12',
            FIN_Antiguedad_maxima_meses__c = '24',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '5,00'
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert rec;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por calificación inválida');
        Assert.isTrue(mensaje.contains('Calificación inválida'), 'Mensaje de error incorrecto');
    }
}