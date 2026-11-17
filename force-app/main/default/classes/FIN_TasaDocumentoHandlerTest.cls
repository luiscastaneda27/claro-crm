@isTest
private class FIN_TasaDocumentoHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Datos de prueba comunes
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorDocumentoCliente__c registroValido = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert registroValido;
    }
    
    @isTest
    static void testHandleInsert_NoRecursion() {
        // Configuración con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '87654321',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '8,50'
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que los registros se insertaron correctamente
        List<FIN_TasaPorDocumentoCliente__c> insertedRecords = [
            SELECT Id, FIN_Documento__c, FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(1, insertedRecords.size(), 'Debería haberse insertado el registro');
        Assert.isTrue(insertedRecords[0].FIN_Desde__c > ahora, 'La fecha Desde debe ser futura');
        Assert.isTrue(insertedRecords[0].FIN_Hasta__c > ahora, 'La fecha Hasta debe ser futura');
    }
    
    @isTest
    static void testAjustarFechasHasta_Solapamiento() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicioExistente = ahora.addDays(10);
        Datetime finExistente = ahora.addDays(20);
        Datetime inicioNuevo = ahora.addDays(15);
        Datetime finNuevo = ahora.addDays(25);
        
        // Crear registro existente
        FIN_TasaPorDocumentoCliente__c existente = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '11111111',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicioExistente,
            FIN_Hasta__c = finExistente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert existente;
        
        // Crear registro nuevo que solapa
        FIN_TasaPorDocumentoCliente__c nuevo = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '11111111',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicioNuevo,
            FIN_Hasta__c = finNuevo,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '6,00'
        );
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar que el registro existente fue actualizado
        FIN_TasaPorDocumentoCliente__c updatedExistente = [
            SELECT FIN_Hasta__c 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(inicioNuevo, updatedExistente.FIN_Hasta__c, 
            'La fecha Hasta del registro existente debería haberse actualizado');
    }
    
    @isTest
    static void testEliminarDuplicados() {
        // Configuración de datos de prueba con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicioVigente = ahora.addDays(1);
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);
        Datetime finFuturo = ahora.addDays(30);
        
        // Crear registro vigente (debe ser eliminado)
        FIN_TasaPorDocumentoCliente__c vigente = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '22222222',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '14,00'
        );
        insert vigente;
        
        // Crear registro futuro que activará el reemplazo
        FIN_TasaPorDocumentoCliente__c futuro = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '22222222',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '30,00'
        );
        
        Test.startTest();
        insert futuro;
        Test.stopTest();
        
        // Verificar que el registro vigente fue eliminado
        List<FIN_TasaPorDocumentoCliente__c> vigentesDespues = [
            SELECT Id 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(vigentesDespues.isEmpty(), 'El registro vigente debería haber sido eliminado');
    }
    
    @isTest
    static void testHandleBeforeInsert_AjusteHorasMasivo() {
        // Configuración con fechas futuras para carga masiva
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '33333333',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00',
            FIN_Masivo__c = true
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Recuperar el registro insertado
        FIN_TasaPorDocumentoCliente__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id = :rec.Id
        ];
        
        // Verificar ajuste de horas (+5 horas)
        Assert.areEqual(inicio.addHours(5), registroInsertado.FIN_Desde__c, 
            'La fecha Desde debe haberse ajustado en +5 horas');
        Assert.areEqual(fin.addHours(5), registroInsertado.FIN_Hasta__c, 
            'La fecha Hasta debe haberse ajustado en +5 horas');
    }
    
    @isTest
    static void testHandleBeforeInsert_RecorteEntreRegistros() {
        // Configuración con fechas futuras que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicio1 = ahora.addDays(5);
        Datetime fin1 = ahora.addDays(15);
        Datetime inicio2 = ahora.addDays(10);
        Datetime fin2 = ahora.addDays(20);
        
        List<FIN_TasaPorDocumentoCliente__c> nuevos = new List<FIN_TasaPorDocumentoCliente__c>();
        
        nuevos.add(new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '44444444',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio1,
            FIN_Hasta__c = fin1,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        ));
        
        nuevos.add(new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '44444444',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio2,
            FIN_Hasta__c = fin2,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '6,00'
        ));
        
        Test.startTest();
        insert nuevos;
        Test.stopTest();
        
        // Recuperar los registros insertados
        List<FIN_TasaPorDocumentoCliente__c> registrosInsertados = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id IN :nuevos
            ORDER BY FIN_Desde__c
        ];
        
        // Verificar que el primer registro fue recortado
        Assert.areEqual(inicio2, registrosInsertados[0].FIN_Hasta__c, 
            'La fecha Hasta del primer registro debería haberse ajustado');
    }
    
    @isTest
    static void testRecursionControl() {
        // Configuración con fechas futuras
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '55555555',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        
        // Forzar recursividad
        FIN_TasaDocumentoHandler.enEjecucion = true;
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que el registro se insertó
        List<FIN_TasaPorDocumentoCliente__c> registrosInsertados = [
            SELECT Id 
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE FIN_Documento__c = '55555555'
        ];
        
        Assert.isFalse(registrosInsertados.isEmpty(), 'El registro debería haberse insertado');
        
        // Restablecer el flag
        FIN_TasaDocumentoHandler.enEjecucion = false;
    }

    @isTest
    static void testInsertRegistroValido() {
        // Configuración de datos de prueba
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(10);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '87654321',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
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
        FIN_TasaPorDocumentoCliente__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Documento__c, 
                   FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorDocumentoCliente__c 
            WHERE Id = :rec.Id
        ];

        // Verificar valores
        Assert.areEqual(inicio, registroInsertado.FIN_Desde__c, 'La fecha Desde no coincide');
        Assert.areEqual(fin, registroInsertado.FIN_Hasta__c, 'La fecha Hasta no coincide');
        Assert.areEqual('87654321', registroInsertado.FIN_Documento__c, 'El Documento no coincide');
    }
    
    @isTest
    static void testValidarFechasRequeridas() {
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
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
        Assert.isTrue(mensaje.contains('Desde y Hasta son obligatorios'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarFechasPasadas() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(-1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
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
    static void testValidarTipoDocumentoInvalido() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'TIPO_INVALIDO',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
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

        Assert.isTrue(errorLanzado, 'Se esperaba error por tipo de documento inválido');
        Assert.isTrue(mensaje.contains('Tipo de documento inválido'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarTasaInteresFormato() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
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
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '24',
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

        Assert.isTrue(errorLanzado, 'Se esperaba error por plazo mínimo mayor al máximo');
        Assert.isTrue(mensaje.contains('Plazo máximo < plazo mínimo'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarDuplicadosExistentes() {
        // Obtener registro existente del testSetup
        FIN_TasaPorDocumentoCliente__c existente = [SELECT FIN_Documento__c, FIN_Tipo_documento__c, FIN_Desde__c, 
                                                   FIN_Hasta__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, 
                                                   FIN_Tasa_Interes__c 
                                                   FROM FIN_TasaPorDocumentoCliente__c LIMIT 1];
        
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = existente.FIN_Documento__c,
            FIN_Tipo_documento__c = existente.FIN_Tipo_documento__c,
            FIN_Desde__c = existente.FIN_Desde__c,
            FIN_Hasta__c = existente.FIN_Hasta__c,
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
        Assert.isTrue(mensaje.contains('Este registro ya existe'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarRangoPicklistPlazos() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        // Obtener valores permitidos para FIN_Plazo_Minimo__c
        Schema.DescribeFieldResult fieldDescribe = FIN_TasaPorDocumentoCliente__c.FIN_Plazo_Minimo__c.getDescribe();
        Integer minValor = 9999;
        Integer maxValor = -1;
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                Integer val = Integer.valueOf(entry.getValue());
                if (val < minValor) minValor = val;
                if (val > maxValor) maxValor = val;
            }
        }
        
        // Crear registro con valor fuera de rango
        FIN_TasaPorDocumentoCliente__c rec = new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '12345678',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = String.valueOf(minValor - 1),
            FIN_Plazo_Maximo__c = '24',
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

        Assert.isTrue(errorLanzado, 'Se esperaba error por valor fuera de rango');
        Assert.isTrue(mensaje.contains('fuera de rango'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarDuplicadosEnCarga() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        List<FIN_TasaPorDocumentoCliente__c> registros = new List<FIN_TasaPorDocumentoCliente__c>();
        
        // Crear dos registros idénticos en la misma carga
        registros.add(new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '11111111',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        ));
        
        registros.add(new FIN_TasaPorDocumentoCliente__c(
            FIN_Documento__c = '11111111',
            FIN_Tipo_documento__c = 'CC',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        ));

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registros;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(errorLanzado, 'Se esperaba error por registros duplicados en la carga');
        Assert.isTrue(mensaje.contains('Registro duplicado en la carga'), 'Mensaje de error incorrecto');
    }
    
}