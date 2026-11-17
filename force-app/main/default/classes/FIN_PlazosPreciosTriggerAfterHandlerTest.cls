@isTest
@SuppressWarnings('PMD.ExcessiveParameterList')
private class FIN_PlazosPreciosTriggerAfterHandlerTest {

    // Crea un registro base válido
    private static FIN_PlazosPrecios__c crearRegistro(
        DateTime desde, 
        DateTime hasta, 
        String producto, 
        String pvpMin, 
        String pvpMax
    ) {
        return new FIN_PlazosPrecios__c(
            FIN_Producto__c = producto,
            FIN_PVP_Min__c = pvpMin,
            FIN_PVP_Max__c = pvpMax,
            FIN_Plazo_1_6__c = 'SI',
            FIN_Plazo_7_12__c = 'SI',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'SI',
            FIN_Plazo_25_36__c = 'SI',
            FIN_Desde__c = desde,
            FIN_Hasta__c = hasta
        );
    }

    @isTest
    static void testAjustarFechaHastaCuandoSolapa() {
        // Registro vigente: hoy hasta dentro de 10 días
        DateTime hoy = DateTime.now();
        DateTime hastaVigente = hoy.addDays(10);
        FIN_PlazosPrecios__c vigente = crearRegistro(hoy.addDays(1), hastaVigente, 'Tecnología', '100', '200');
        insert vigente;

        // Nuevo registro: inicia en 5 días (solapando)
        FIN_PlazosPrecios__c nuevo = crearRegistro(hoy.addDays(5), hoy.addDays(15), 'Tecnología', '100', '200');

        Test.startTest();
        FIN_PlazosPreciosTriggerAfterHandler.ajustarFechasHasta(new List<FIN_PlazosPrecios__c>{nuevo});
        Test.stopTest();

        // Verifica que el registro vigente fue actualizado
        FIN_PlazosPrecios__c actualizado = [SELECT FIN_Hasta__c FROM FIN_PlazosPrecios__c WHERE Id = :vigente.Id];
        Assert.areEqual(nuevo.FIN_Desde__c, actualizado.FIN_Hasta__c, 'La fecha FIN_Hasta__c del registro anterior debe ajustarse al inicio del nuevo.');
    }

    @isTest
    static void testTriggerAjustarFechasHasta() {
        // Crea un registro existente
        DateTime hoy = DateTime.now();
        FIN_PlazosPrecios__c vigente = crearRegistro(hoy.addDays(1), hoy.addDays(10), 'Tecnología', '100', '200');
        insert vigente;
        
        // Crea un nuevo registro que debe provocar un ajuste de la fecha Hasta
        FIN_PlazosPrecios__c nuevo = crearRegistro(hoy.addDays(5), hoy.addDays(15), 'Tecnología', '100', '200');

        Test.startTest();
        insert nuevo;
        Test.stopTest();

        // Recarga el existente y comprueba que su FIN_Hasta__c se haya ajustado                                                                                                                                                                  
        FIN_PlazosPrecios__c actualizado = [SELECT FIN_Hasta__c FROM FIN_PlazosPrecios__c WHERE Id = :vigente.Id];
        Assert.areEqual(nuevo.FIN_Desde__c, actualizado.FIN_Hasta__c, 'La fecha Hasta debe ajustarse al inicio del nuevo registro.');
    }

    @isTest
    static void testEliminarDuplicadosValoresEspecificos() {
        // Configuración con valores específicos
        Datetime ahora = Datetime.now();
        Datetime inicioVigente = ahora.addDays(1);
        Datetime finVigente = ahora.addDays(30);
        Datetime inicioFuturo = ahora.addDays(1);
        Datetime finFuturo = ahora.addDays(30);

        // Crea un registro existente
        FIN_PlazosPrecios__c vigente = new FIN_PlazosPrecios__c(
            FIN_Producto__c = 'Tecnología',
            FIN_PVP_Min__c = '100',
            FIN_PVP_Max__c = '200',
            FIN_Plazo_1_6__c = 'SI',
            FIN_Plazo_7_12__c = 'SI',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'SI',
            FIN_Plazo_25_36__c = 'SI',
            FIN_Desde__c = inicioVigente,
            FIN_Hasta__c = finVigente
        );
        insert vigente;
        
        // Crear registro futuro con valores específicos
        FIN_PlazosPrecios__c futuro = new FIN_PlazosPrecios__c(
            FIN_Producto__c = 'Tecnología',
            FIN_PVP_Min__c = '100',
            FIN_PVP_Max__c = '200',
            FIN_Plazo_1_6__c = 'NO',
            FIN_Plazo_7_12__c = 'NO',
            FIN_Plazo_13_18__c = 'SI',
            FIN_Plazo_19_24__c = 'SI',
            FIN_Plazo_25_36__c = 'SI',
            FIN_Desde__c = inicioFuturo,
            FIN_Hasta__c = finFuturo
        );
        
        Test.startTest();
        insert futuro;
        Test.stopTest();
        
        // Verificar eliminación del duplicado
        List<FIN_PlazosPrecios__c> vigentesDespues = [
            SELECT Id FROM FIN_PlazosPrecios__c WHERE Id = :vigente.Id
        ];
        
        Assert.isTrue(vigentesDespues.isEmpty(), 'El registro vigente debería haber sido eliminado');
        
        // Verificar que el nuevo registro se insertó
        FIN_PlazosPrecios__c futuroInsertado = [
            SELECT FIN_Plazo_1_6__c, FIN_Plazo_7_12__c
            FROM FIN_PlazosPrecios__c 
            WHERE Id = :futuro.Id
        ];
        
        Assert.areEqual('NO', futuroInsertado.FIN_Plazo_1_6__c, 'FIN_Plazo_1_6__c no coincide');
        Assert.areEqual('NO', futuroInsertado.FIN_Plazo_7_12__c, 'FIN_Plazo_7_12__c no coincide');
    }
}