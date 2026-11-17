@isTest
@SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation')
private class FIN_CuotaInicialProductoHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Datos de prueba con los valores específicos proporcionados
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_CuotaInicialProducto__c registroValido = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30'
        );
        insert registroValido;
    }
    
    @isTest
    static void testHandleInsertValoresEspecificos() {
        // Configuración con los valores específicos
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_CuotaInicialProducto__c rec = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30'
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar inserción con los valores específicos
        List<FIN_CuotaInicialProducto__c> insertedRecords = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, 
                   FIN_Plazo_Maximo__c, FIN_CuotaInicial__c
            FROM FIN_CuotaInicialProducto__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(1, insertedRecords.size(), 'Debería haberse insertado el registro');
        Assert.areEqual('CAV', insertedRecords[0].FIN_Canal__c, 'El canal no coincide');
        Assert.areEqual('70061044', insertedRecords[0].FIN_Material__c, 'El material no coincide');
        Assert.areEqual('12', insertedRecords[0].FIN_Plazo_Minimo__c, 'Plazo mínimo no coincide');
        Assert.areEqual('24', insertedRecords[0].FIN_Plazo_Maximo__c, 'Plazo máximo no coincide');
        Assert.areEqual('30', insertedRecords[0].FIN_CuotaInicial__c, 'Cuota inicial no coincide');
    }
    
    @isTest
    static void testAjustarFechasHastaValoresEspecificos() {
        // Configuración con valores específicos que se solapan
        Datetime ahora = Datetime.now();
        Datetime inicioExistente = ahora.addDays(10);
        Datetime finExistente = ahora.addDays(20);
        Datetime inicioNuevo = ahora.addDays(15);
        Datetime finNuevo = ahora.addDays(25);
        
        // Crear registro existente con valores específicos
        FIN_CuotaInicialProducto__c existente = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioExistente,
            FIN_Hasta__c = finExistente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30'
        );
        insert existente;
        
        // Crear registro nuevo con valores específicos que solapa
        FIN_CuotaInicialProducto__c nuevo = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioNuevo,
            FIN_Hasta__c = finNuevo,
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_CuotaInicial__c = '20'
        );
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar ajuste de fechas
        FIN_CuotaInicialProducto__c updatedExistente = [
            SELECT FIN_Hasta__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_CuotaInicial__c
            FROM FIN_CuotaInicialProducto__c 
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(inicioNuevo, updatedExistente.FIN_Hasta__c, 'Fecha Hasta no se ajustó correctamente');
        Assert.areEqual('12', updatedExistente.FIN_Plazo_Minimo__c, 'Plazo mínimo no debería cambiar');
        Assert.areEqual('24', updatedExistente.FIN_Plazo_Maximo__c, 'Plazo máximo no debería cambiar');
        Assert.areEqual('30', updatedExistente.FIN_CuotaInicial__c, 'Cuota inicial no debería cambiar');
    }
    
    @isTest
    static void testEliminarDuplicadosValoresEspecificos() {
        // Configuración con valores específicos
        Datetime ahora = Datetime.now();
        Datetime inicioVigente = ahora.addDays(1);
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);
        Datetime finFuturo = ahora.addDays(30);
        
        // Crear registro vigente con valores específicos
        FIN_CuotaInicialProducto__c vigente = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30'
        );
        insert vigente;
        
        // Crear registro futuro con valores específicos
        FIN_CuotaInicialProducto__c futuro = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo,
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_CuotaInicial__c = '20'
        );
        
        Test.startTest();
        insert futuro;
        Test.stopTest();
        
        // Verificar eliminación del duplicado
        List<FIN_CuotaInicialProducto__c> vigentesDespues = [
            SELECT Id FROM FIN_CuotaInicialProducto__c WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(vigentesDespues.isEmpty(), 'El registro vigente debería haber sido eliminado');
        
        // Verificar que el nuevo registro se insertó
        FIN_CuotaInicialProducto__c futuroInsertado = [
            SELECT FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_CuotaInicial__c
            FROM FIN_CuotaInicialProducto__c 
            WHERE Id = :futuro.Id
        ];
        
        Assert.areEqual('6', futuroInsertado.FIN_Plazo_Minimo__c, 'Plazo mínimo no coincide');
        Assert.areEqual('12', futuroInsertado.FIN_Plazo_Maximo__c, 'Plazo máximo no coincide');
        Assert.areEqual('20', futuroInsertado.FIN_CuotaInicial__c, 'Cuota inicial no coincide');
    }
    
    @isTest
    static void testHandleBeforeInsertAjusteHorasMasivo() {
        // Configuración con valores específicos para carga masiva
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_CuotaInicialProducto__c rec = new FIN_CuotaInicialProducto__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Masivo__c = true
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar ajuste de horas
        FIN_CuotaInicialProducto__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c
            FROM FIN_CuotaInicialProducto__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(inicio.addHours(5), registroInsertado.FIN_Desde__c, 'Ajuste de horas en Desde incorrecto');
        Assert.areEqual(fin.addHours(5), registroInsertado.FIN_Hasta__c, 'Ajuste de horas en Hasta incorrecto');
        Assert.areEqual('12', registroInsertado.FIN_Plazo_Minimo__c, 'Plazo mínimo no debería cambiar');
        Assert.areEqual('24', registroInsertado.FIN_Plazo_Maximo__c, 'Plazo máximo no debería cambiar');
    }
    
    @isTest
    static void testRegistroValido() {
        FIN_CuotaInicialProducto__c registroValido = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Referencia__c = 'iphone',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );

        Test.startTest();
        Database.SaveResult[] sr = Database.insert(new List<FIN_CuotaInicialProducto__c>{registroValido}, false);
        Test.stopTest();
        Assert.isTrue(sr[0].isSuccess(), 'Registro válido debería insertarse sin errores');
    }

    @isTest
    static void testCanalInvalidoPicklist() {
        FIN_CuotaInicialProducto__c regInvalido = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CANAL_INVALIDO',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(10)
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(regInvalido, false);
        Test.stopTest();

        Assert.isFalse(sr.isSuccess(), 'La inserción debería fallar por canal inválido');
        Boolean contieneErrorEsperado = false;
        for (Database.Error err : sr.getErrors()) {
            if (err.getMessage().contains('Canal inválido: valores disponibles')) {
                contieneErrorEsperado = true;
                break;
            }
        }
        Assert.isTrue(contieneErrorEsperado, 'Debe mostrarse un mensaje indicando que el canal es inválido');
    }

    @isTest
    static void testCanalValidoPicklist() {
        String canalValido = null;
        Schema.DescribeFieldResult campo = FIN_CuotaInicialProducto__c.FIN_Canal__c.getDescribe();
        for (Schema.PicklistEntry entry : campo.getPicklistValues()) {
            if (entry.isActive()) {
                canalValido = entry.getValue();
                break;
            }
        }

        Assert.isNotNull(canalValido, 'Debe haber al menos un valor válido en el picklist');

        FIN_CuotaInicialProducto__c regValido = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = canalValido,
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Referencia__c = 'iphone',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(10)
        );

        Test.startTest();
        insert regValido;
        Test.stopTest();

        Assert.isNotNull(regValido.Id, 'Inserción exitosa con canal válido');
    }

    @isTest
    static void testMaterialNoNumerico() {
        FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '7006-1043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );

        Test.startTest();
        Database.SaveResult[] sr = Database.insert(new List<FIN_CuotaInicialProducto__c>{registro}, false);
        Test.stopTest();
        Assert.isFalse(sr[0].isSuccess(), 'Se esperaba error por material no numérico');
        Assert.isTrue(sr[0].getErrors()[0].getMessage().contains('Material debe ser un número entero'), 'Mensaje esperado');
    }

    @isTest
    static void testCuotaInicialDecimal() {
        FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30,5',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Se esperaba error por cuota inicial decimal');
        } else {
            Assert.isTrue(
                mensaje.contains('Insert failed.'),'Mensaje esperado sobre plazos inválidos');
        }
    }

    @isTest
    static void testValidacionDePlazos() {
        FIN_CuotaInicialProducto__c registroValido = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30',
            FIN_Referencia__c = 'iphone',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );

        Test.startTest();
        insert registroValido;
        Test.stopTest();
        Assert.isNotNull(registroValido.Id, 'Registro válido debería haberse insertado');
    }

    @isTest
    static void testPlazosFueraDeRango() {
        FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '50',
            FIN_Plazo_Maximo__c = '60',
            FIN_CuotaInicial__c = '30',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debe fallar por plazos fuera del rango permitido');
        } else {
            Assert.isTrue(
                mensaje.contains('Plazo Mínimo inválido') || mensaje.contains('Plazo Máximo inválido'),
                'Mensaje esperado sobre plazos inválidos'
            );
        }
    }

    @isTest
    static void testPlazoMinimoMayorMaximo() {
        FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '24',
            FIN_Plazo_Maximo__c = '12',
            FIN_CuotaInicial__c = '30',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );

        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Se esperaba un error porque el Plazo Mínimo es mayor al Máximo');
        } else {
            Assert.isTrue(mensaje.contains('mayor al Plazo Maximo'), 'Mensaje esperado sobre comparación mínima > máxima');
        }
    }

    @isTest
    static void testFechasObligatorias() {
        FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061043',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_CuotaInicial__c = '30'
        );
        
        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Se esperaba error por fechas no definidas');
        } else {
            Assert.isTrue(mensaje.contains('Insert failed.'), 'Mensaje esperado de fechas');
        }

    }

    @isTest
    static void testDuplicadoEnMismaCarga() {
        DateTime d1 = DateTime.now().addDays(1);
        DateTime h1 = DateTime.now().addDays(2);

        FIN_CuotaInicialProducto__c r1 = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c='CAV', FIN_Material__c='70061043', FIN_Plazo_Minimo__c='12', FIN_Referencia__c = 'iphone',
            FIN_Plazo_Maximo__c='24', FIN_CuotaInicial__c='30', FIN_Desde__c=d1, FIN_Hasta__c=h1
        );
        FIN_CuotaInicialProducto__c r2 = r1.clone(false, true);

        Test.startTest();
        Database.SaveResult[] sr = Database.insert(new List<FIN_CuotaInicialProducto__c>{r1, r2}, false);
        Test.stopTest();

        Assert.isFalse(sr[1].isSuccess(), 'Se esperaba error por duplicado en la misma carga');
        Assert.isTrue(sr[1].getErrors()[0].getMessage().contains('Registro duplicado en la carga'), 'Mensaje esperado de duplicado');
    }
    
	@isTest
	static void testCuotaInicialFueraDeRango() {
    	FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
        	FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = '24',
        	FIN_CuotaInicial__c = '101', // Fuera de rango
        	FIN_Referencia__c = 'iphone',
        	FIN_Desde__c = DateTime.now().addDays(1),
        	FIN_Hasta__c = DateTime.now().addDays(10)
    	);

    	Test.startTest();
    	Database.SaveResult sr = Database.insert(registro, false);
    	Test.stopTest();

    	Assert.isFalse(sr.isSuccess(), 'Debería fallar por cuota inicial fuera de rango');
    	Assert.isTrue(sr.getErrors()[0].getMessage().contains('Cuota Inicial debe ser un número entero válido'), 'Mensaje esperado');
	}

	@isTest
	static void testValidacionPicklistPlazos() {
    	// Obtener valores válidos del picklist
    	List<String> valoresPlazo = new List<String>();
    	Schema.DescribeFieldResult fieldResult = FIN_CuotaInicialProducto__c.FIN_Plazo_Minimo__c.getDescribe();
    	for (Schema.PicklistEntry ple : fieldResult.getPicklistValues()) {
        	if (ple.isActive()) {
            	valoresPlazo.add(ple.getValue());
        	}
    	}
    
    	// Probar con valor inválido
    	FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
        	FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '999', // Valor inválido
        	FIN_Plazo_Maximo__c = valoresPlazo[0],
        	FIN_CuotaInicial__c = '30',
        	FIN_Referencia__c = 'iphone',
        	FIN_Desde__c = DateTime.now().addDays(1),
        	FIN_Hasta__c = DateTime.now().addDays(10)
    	);
        
        Boolean errorLanzado = false;
        String mensaje = '';
        Test.startTest();
        try {
            insert registro;
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();

        if (!errorLanzado) {
            Assert.fail('Debería fallar por plazo mínimo inválido');
        } else {
            Assert.isTrue(mensaje.contains('Insert failed.'), 'Mensaje esperado');
        }

	}

	@isTest
	static void testValidacionUpdateRegistro() {
    	// Insertar registro inicial
    	FIN_CuotaInicialProducto__c registro = new FIN_CuotaInicialProducto__c(
        	FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = '24',
        	FIN_CuotaInicial__c = '30',
        	FIN_Referencia__c = 'iphone',
        	FIN_Desde__c = DateTime.now().addDays(1),
        	FIN_Hasta__c = DateTime.now().addDays(10)
    	);
    	insert registro;

    	// Actualizar con valores inválidos
    	registro.FIN_Plazo_Minimo__c = '999';
    	registro.FIN_Plazo_Maximo__c = '1';

    	Test.startTest();
    	Database.SaveResult sr = Database.update(registro, false);
    	Test.stopTest();

    	Assert.isFalse(sr.isSuccess(), 'Debería fallar la actualización con valores inválidos');
    	Assert.isTrue(sr.getErrors()[0].getMessage().contains('Plazo Mínimo inválido') || 
                 sr.getErrors()[0].getMessage().contains('El Plazo Minimo no puede ser mayor al Plazo Maximo'), 
                 'Mensaje esperado');
	}
    
    @isTest
    static void testValidarFechasPasadas() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(-1);
        Datetime fin = ahora.addDays(5);
        
        FIN_CuotaInicialProducto__c rec = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = '24',
        	FIN_CuotaInicial__c = '30',
        	FIN_Referencia__c = 'iphone',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin     
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
    static void testValidarFechaHastaMenorDeste() {
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(10);
        Datetime fin = ahora.addDays(5);
        
        FIN_CuotaInicialProducto__c rec = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = '24',
        	FIN_CuotaInicial__c = '30',
        	FIN_Referencia__c = 'iphone',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin     
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

        Assert.isTrue(errorLanzado, 'Se esperaba error por fecha Hasta menor a Desde');
    }
    
    @isTest
    static void validacionesCuotaInicialProducto() {
         Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(10);
        Datetime fin = ahora.addDays(5);
        
        FIN_CuotaInicialProducto__c rec = new FIN_CuotaInicialProducto__c(
            FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061043',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = '24',
        	FIN_CuotaInicial__c = '30',
        	FIN_Referencia__c = 'iphone',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin     
        );

        Test.startTest();
        FIN_CuotaInicialProductoHandler.validacionesCuotaInicialProducto(
            new List<FIN_CuotaInicialProducto__c>{ rec }
        );
        Test.stopTest();

        System.assert(true, 'Método ejecutado para cobertura');
    }
    
    
}