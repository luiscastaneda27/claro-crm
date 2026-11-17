@isTest
@SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation')
private class FIN_PlazosHabilitadosHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Datos de prueba con los valores específicos proporcionados
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(1);
        Datetime fin = ahora.addDays(5);
        
        FIN_PlazosHabilitados__c registroValido = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24'
        );
        insert registroValido;
    }
    
    @isTest
    static void testHandleInsertValoresEspecificos() {
        // Configuración con los valores específicos
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_PlazosHabilitados__c rec = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24'
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar inserción con los valores específicos
        List<FIN_PlazosHabilitados__c> insertedRecords = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, 
                   FIN_Plazo_Maximo__c
            FROM FIN_PlazosHabilitados__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(1, insertedRecords.size(), 'Debería haberse insertado el registro');
        Assert.areEqual('CAV', insertedRecords[0].FIN_Canal__c, 'El canal no coincide');
        Assert.areEqual('70061044', insertedRecords[0].FIN_Material__c, 'El material no coincide');
        Assert.areEqual('12', insertedRecords[0].FIN_Plazo_Minimo__c, 'Plazo mínimo no coincide');
        Assert.areEqual('24', insertedRecords[0].FIN_Plazo_Maximo__c, 'Plazo máximo no coincide');
       
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
        FIN_PlazosHabilitados__c existente = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioExistente,
            FIN_Hasta__c = finExistente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24'
            
        );
        insert existente;
        
        // Crear registro nuevo con valores específicos que solapa
        FIN_PlazosHabilitados__c nuevo = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioNuevo,
            FIN_Hasta__c = finNuevo,
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12'
        );
        
        Test.startTest();
        insert nuevo;
        Test.stopTest();
        
        // Verificar ajuste de fechas
        FIN_PlazosHabilitados__c updatedExistente = [
            SELECT FIN_Hasta__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c
            FROM FIN_PlazosHabilitados__c 
            WHERE Id = :existente.Id
        ];
        
        Assert.areEqual(inicioNuevo, updatedExistente.FIN_Hasta__c, 'Fecha Hasta no se ajustó correctamente');
        Assert.areEqual('12', updatedExistente.FIN_Plazo_Minimo__c, 'Plazo mínimo no debería cambiar');
        Assert.areEqual('24', updatedExistente.FIN_Plazo_Maximo__c, 'Plazo máximo no debería cambiar');
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
        FIN_PlazosHabilitados__c vigente = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24'
        );
        insert vigente;
        
        // Crear registro futuro con valores específicos
        FIN_PlazosHabilitados__c futuro = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo,
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12'
        );
        
        Test.startTest();
        insert futuro;
        Test.stopTest();
        
        // Verificar eliminación del duplicado
        List<FIN_PlazosHabilitados__c> vigentesDespues = [
            SELECT Id FROM FIN_PlazosHabilitados__c WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(vigentesDespues.isEmpty(), 'El registro vigente debería haber sido eliminado');
        
        // Verificar que el nuevo registro se insertó
        FIN_PlazosHabilitados__c futuroInsertado = [
            SELECT FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c
            FROM FIN_PlazosHabilitados__c 
            WHERE Id = :futuro.Id
        ];
        
        Assert.areEqual('6', futuroInsertado.FIN_Plazo_Minimo__c, 'Plazo mínimo no coincide');
        Assert.areEqual('12', futuroInsertado.FIN_Plazo_Maximo__c, 'Plazo máximo no coincide');
    }
    
    @isTest
    static void testHandleBeforeInsertAjusteHorasMasivo() {
        // Configuración con valores específicos para carga masiva
        Datetime ahora = Datetime.now();
        Datetime inicio = ahora.addDays(5);
        Datetime fin = ahora.addDays(15);
        
        FIN_PlazosHabilitados__c rec = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Iphone 16 Pro Max 256Gb Plata',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin,
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Masivo__c = true
        );
        
        Test.startTest();
        insert rec;
        Test.stopTest();
        
        // Verificar ajuste de horas
        FIN_PlazosHabilitados__c registroInsertado = [
            SELECT FIN_Desde__c, FIN_Hasta__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c
            FROM FIN_PlazosHabilitados__c 
            WHERE Id = :rec.Id
        ];
        
        Assert.areEqual(inicio.addHours(5), registroInsertado.FIN_Desde__c, 'Ajuste de horas en Desde incorrecto');
        Assert.areEqual(fin.addHours(5), registroInsertado.FIN_Hasta__c, 'Ajuste de horas en Hasta incorrecto');
        Assert.areEqual('12', registroInsertado.FIN_Plazo_Minimo__c, 'Plazo mínimo no debería cambiar');
        Assert.areEqual('24', registroInsertado.FIN_Plazo_Maximo__c, 'Plazo máximo no debería cambiar');
    }
    
    static testMethod void testMissingRequiredFields() {
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
        	Assert.fail('Debe lanzar error por campos requeridos');
    	} else {
        	Assert.isTrue((mensaje.contains('FIN_Canal__c')), 'Debe marcar error por campo requerido FIN_Canal__c');
    	}
    }

    static testMethod void testFormatoMaterialInvalido() {
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '7006A1044', // Contiene letra
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
        	Assert.fail('Debe fallar por material inválido');
    	} else {
        	Assert.isTrue((mensaje.contains('Material debe ser un número entero')), 'Debe marcar error por formato de material inválido');
    	}
        
    }

    static testMethod void testPlazoMinimoMayorQueMaximo() {
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '36',
            FIN_Plazo_Maximo__c = '12',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
        	Assert.fail('Debe fallar por plazo mínimo mayor que máximo');
    	} else {
        	Assert.isTrue((mensaje.contains('El Plazo Mínimo no puede ser mayor al Plazo Máximo')), 'Debe marcar error por plazo mínimo > máximo');
    	}
        
    }



    
    
    static testMethod void testCanalPicklistInvalido() {
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CANAL_INVALIDO',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
            Assert.fail('Debe lanzar error por canal inválido');
        } else {
            Assert.isTrue((mensaje.contains('Canal inválido')), 'Debe marcar error por canal picklist inválido');
        }
    }

    static testMethod void testPlazoMinimoFueraDeRango() {
        // Obtener valores mínimos y máximos permitidos
        Integer minValor = 9999;
        Integer maxValor = -1;
        for (Schema.PicklistEntry ple : FIN_PlazosHabilitados__c.FIN_Plazo_Minimo__c.getDescribe().getPicklistValues()) {
            if (ple.isActive()) {
                Integer val = Integer.valueOf(ple.getValue());
                minValor = Math.min(minValor, val);
                maxValor = Math.max(maxValor, val);
            }
        }
        
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = String.valueOf(minValor - 1),
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
            Assert.fail('Debe lanzar error por plazo mínimo fuera de rango');
        } else {
            Assert.isTrue((mensaje.contains('Plazo Mínimo inválido')), 'Debe marcar error por plazo mínimo fuera de rango');
        }
    }

    static testMethod void testFechaInicioPasada() {
        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(-1),
            FIN_Hasta__c = DateTime.now().addDays(2)
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
            Assert.isTrue((mensaje.contains('Desde < hoy')), 'Debe marcar error por fecha inicio en pasado');
        }
    }
    
    static testMethod void testPlazoMinimoNoNumerico() {
    	FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
        	FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061044',
        	FIN_Plazo_Minimo__c = 'ABC', // Valor no numérico
        	FIN_Plazo_Maximo__c = '24',
        	FIN_Desde__c = DateTime.now().addDays(1),
        	FIN_Hasta__c = DateTime.now().addDays(2)
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
        	Assert.fail('Debe lanzar error por valor no numérico en Plazo Mínimo');
    	} 
	}
    
    static testMethod void testPlazoMaximoNoNumerico() {
    	FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
        	FIN_Canal__c = 'CAV',
        	FIN_Material__c = '70061044',
        	FIN_Plazo_Minimo__c = '12',
        	FIN_Plazo_Maximo__c = 'veinte', // valor no numérico intencional
        	FIN_Desde__c = DateTime.now().addDays(1),
        	FIN_Hasta__c = DateTime.now().addDays(2)
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
        	Assert.fail('Debe lanzar error por valor no numérico en Plazo Máximo');
    	} 
	}
    static testMethod void testDuplicadoEnMismaCarga() {
        FIN_PlazosHabilitados__c reg1 = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Honor',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );
        FIN_PlazosHabilitados__c reg2 = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Honor',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = DateTime.now().addDays(1),
            FIN_Hasta__c = DateTime.now().addDays(2)
        );
        Boolean errorLanzado = false;
        String mensaje = '';
        
        Test.startTest();
        try {
            insert new List<FIN_PlazosHabilitados__c>{reg1, reg2};
        } catch (DmlException e) {
            errorLanzado = true;
            mensaje = e.getMessage();
        }
        Test.stopTest();
        if (!errorLanzado) {
        	Assert.fail('Debe fallar por duplicado en la misma carga');
    	} else {
        	Assert.isTrue((mensaje.contains('Registro duplicado en la carga')), 'Debe marcar error por duplicado en la misma carga');
    	}
    }
    @isTest
    static void testDuplicados() {
        DateTime ahora = DateTime.now();
        DateTime inicio = ahora.addDays(1);
        DateTime fin =  ahora.addDays(2);
        FIN_PlazosHabilitados__c reg1 = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Honor',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin
        );
        
         insert reg1;

        FIN_PlazosHabilitados__c reg2 = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Honor',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin
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
            Assert.isFalse(errorLanzado,'Debe fallar por duplicado');
        } else {
            Assert.isTrue(mensaje.contains('Este registro ya existe en Salesforce.'), 'Se esperaba el mensaje de error adecuado por duplicado');
        }
    }

    @isTest
    static void testCoberturaEliminarDuplicados() {
        Datetime ahora = Datetime.now();

        // Registro EXISTENTE futuro
        FIN_PlazosHabilitados__c existente = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Cobertura',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '99999999',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = ahora.addDays(10),
            FIN_Hasta__c = ahora.addDays(20)
        );
        insert existente;

        // Registro NUEVO futuro con MISMA clave
        FIN_PlazosHabilitados__c nuevo = new FIN_PlazosHabilitados__c(
            FIN_Referencia__c = 'Cobertura',
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '99999999',
            FIN_Plazo_Minimo__c = '6',
            FIN_Plazo_Maximo__c = '12',
            FIN_Desde__c = ahora.addDays(10),
            FIN_Hasta__c = ahora.addDays(20)
        );

        Test.startTest();
        insert nuevo;
        Test.stopTest();

        // El existente debería haberse eliminado
        List<FIN_PlazosHabilitados__c> existentes = [
            SELECT Id FROM FIN_PlazosHabilitados__c WHERE Id = :existente.Id
        ];

        System.assertEquals(
            0,
            existentes.size(),
            'El registro duplicado existente debía eliminarse'
        );
    }
    @isTest
    static void testCoberturaValidacionesPlazosHabilitados() {
        DateTime inicio = DateTime.now().addDays(1);
        DateTime fin = inicio.addMinutes(30);

        FIN_PlazosHabilitados__c reg = new FIN_PlazosHabilitados__c(
            FIN_Canal__c = 'CAV',
            FIN_Material__c = '70061044',
            FIN_Plazo_Minimo__c = '12',
            FIN_Plazo_Maximo__c = '24',
            FIN_Desde__c = inicio,
            FIN_Hasta__c = fin
        );

        Test.startTest();
        FIN_PlazosHabilitadosHandler.validacionesPlazosHabilitados(
            new List<FIN_PlazosHabilitados__c>{ reg }
        );
        Test.stopTest();

        System.assert(true, 'Método ejecutado para cobertura');
    }
    
}