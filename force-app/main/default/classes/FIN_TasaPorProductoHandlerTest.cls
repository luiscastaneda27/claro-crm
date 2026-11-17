@isTest
private class FIN_TasaPorProductoHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Datos de prueba comunes
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorProducto__c registroValido = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert registroValido;
    }
    
    @isTest
    static void testHandleInsert_NoRecursion() {
        // Configuración con fechas futuras (inicio en 5 días, duración 10 días)
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '54321',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Tasa_Interes__c = '8,50'
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que los registros se insertaron correctamente
        List<FIN_TasaPorProducto__c> insertedRecords = [
            SELECT Id, FIN_Material__c, FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorProducto__c 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicioExistente = ahora.addDays(10); // futuro
        Datetime finExistente = ahora.addDays(20);    // futuro
        Datetime inicioNuevo = ahora.addDays(15);     // futuro (solapa)
        Datetime finNuevo = ahora.addDays(25);        // futuro
        
        // Crear registro existente con fechas futuras
        FIN_TasaPorProducto__c existente = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicioExistente,
            FIN_Hasta__c = finExistente,
            FIN_Material__c = '12345',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        insert existente;
        
        // Crear registro nuevo que solapa (fechas futuras)
        FIN_TasaPorProducto__c nuevo = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicioNuevo,
            FIN_Hasta__c = finNuevo,
            FIN_Material__c = '12345',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '6,00'
        );
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar que el registro existente fue actualizado
        FIN_TasaPorProducto__c updatedExistente = [
            SELECT FIN_Hasta__c 
            FROM FIN_TasaPorProducto__c 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicioVigente = ahora.addDays(1);  // Registro "vigente" (inicio en pasado, fin en futuro)
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);    // Registro futuro que reemplazará al vigente
        Datetime finFuturo = ahora.addDays(30);
        
        // Crear registro vigente (debe ser eliminado por el handler)
        FIN_TasaPorProducto__c vigente = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente,
            FIN_Material__c = '67890',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '14,00'
        );
        insert vigente;
        
        // Crear registro futuro que activará el reemplazo
        FIN_TasaPorProducto__c futuro = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo,
            FIN_Material__c = '67890',
            FIN_Plazo_Minimo__c = '1',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '30,00'
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
        List<FIN_TasaPorProducto__c> vigentesDespues = [
            SELECT Id 
            FROM FIN_TasaPorProducto__c 
            WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(
            vigentesDespues.isEmpty(), 
            'El registro vigente debería haber sido eliminado por el handler'
        );
        
        // Verificar que el registro futuro se insertó correctamente
        FIN_TasaPorProducto__c futuroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Material__c
            FROM FIN_TasaPorProducto__c 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);   // futuro
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00',
            FIN_Masivo__c = true
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Recuperar el registro insertado
        FIN_TasaPorProducto__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorProducto__c 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio1 = ahora.addDays(5);  // futuro
        Datetime fin1 = ahora.addDays(15);    // futuro
        Datetime inicio2 = ahora.addDays(10); // futuro (solapa)
        Datetime fin2 = ahora.addDays(20);    // futuro
        
        List<FIN_TasaPorProducto__c> nuevos = new List<FIN_TasaPorProducto__c>();
        
        nuevos.add(new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio1,
            FIN_Hasta__c = fin1,
            FIN_Material__c = '123456',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        ));
        
        nuevos.add(new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio2,
            FIN_Hasta__c = fin2,
            FIN_Material__c = '123456',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '6,00'
        ));
        
        Test.startTest();
        insert nuevos;
        Test.stopTest();
        
        // Recuperar los registros insertados
        List<FIN_TasaPorProducto__c> registrosInsertados = [
            SELECT FIN_Desde__c, FIN_Hasta__c 
            FROM FIN_TasaPorProducto__c 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(5); // futuro
        Datetime fin = ahora.addDays(15);  // futuro
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Tasa_Interes__c = '5,00'
        );
        
        // Forzar recursividad
        FIN_TasaPorProductoHandler.enEjecucion = true;
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar que el registro se insertó
        List<FIN_TasaPorProducto__c> registrosInsertados = [
            SELECT Id 
            FROM FIN_TasaPorProducto__c 
            WHERE FIN_Material__c = '12345' 
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
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(10);
        Datetime fin = ahora.addDays(15);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '54321',
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
        FIN_TasaPorProducto__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Material__c, 
                   FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorProducto__c 
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
            '54321', 
            registroInsertado.FIN_Material__c, 
            'El Material no coincide'
        );
    }
    
    @isTest
    static void testValidarFechasRequeridas() {
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Material__c = '12345',
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
        Assert.isTrue(mensaje.contains('Los campos Desde y Hasta son requeridos'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarFechasPasadas() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(-1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
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
    }
    
    @isTest
    static void testValidarMaterialEntero() {
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '123.45',
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

        Assert.isTrue(errorLanzado, 'Se esperaba error por Material no entero');
        Assert.isTrue(mensaje.contains('Material debe ser un número entero'), 'Mensaje de error incorrecto');
    }
    
    @isTest
    static void testValidarPlazoMinMayorMax() {
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
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
    static void testValidarTasaInteresFormato() {
        Datetime ahora = Datetime.newInstanceGmt(2999, 1, 1, 0, 0, 0);
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Material__c = '12345',
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
    static void testValidarDuplicadosExistentes() {
        // Obtener registro existente del testSetup
        FIN_TasaPorProducto__c existente = [SELECT Nombre_producto__c, FIN_Desde__c, FIN_Hasta__c, FIN_Material__c, 
                                           FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c 
                                           FROM FIN_TasaPorProducto__c LIMIT 1];
        
        FIN_TasaPorProducto__c rec = new FIN_TasaPorProducto__c(
            Nombre_producto__c = 'Honor Magic 7 lite 256GB',
            FIN_Desde__c = existente.FIN_Desde__c,
            FIN_Hasta__c = existente.FIN_Hasta__c,
            FIN_Material__c = existente.FIN_Material__c,
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
    static void testHandleUpdate_DisparaValidaciones() {
        // Recuperar un registro del testSetup
        FIN_TasaPorProducto__c existente = [
            SELECT Id, FIN_Desde__c, FIN_Hasta__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorProducto__c
            LIMIT 1
        ];
        
        // Modificar un campo válido
        existente.FIN_Tasa_Interes__c = '10,00';
        
        Test.startTest();
        update existente; // 👉 Esto dispara el bloque before update
        Test.stopTest();
        
        // Volver a consultar para confirmar que el cambio se guardó
        FIN_TasaPorProducto__c actualizado = [
            SELECT FIN_Tasa_Interes__c
            FROM FIN_TasaPorProducto__c
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(
            '10,00',
            actualizado.FIN_Tasa_Interes__c,
            'La tasa debería haberse actualizado'
        );
    }

}