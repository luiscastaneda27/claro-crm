@IsTest
private class CaseCambioEquipoAppleTest {

    @IsTest
    static void soloAplicaACasosAbiertosDeApple() {
        Assert.isTrue(CaseCambioEquipoApple.isPending(caso(CaseCambioEquipoApple.STATUS_ABIERTO, CaseCambioEquipoApple.LEVEL3_APPLE)));
        Assert.isFalse(CaseCambioEquipoApple.isPending(caso(CaseCambioEquipoApple.STATUS_EN_CURSO, CaseCambioEquipoApple.LEVEL3_APPLE)));
        Assert.isFalse(CaseCambioEquipoApple.isPending(caso(CaseCambioEquipoApple.STATUS_ABIERTO, OTRA_TIPIFICACION)));
    }

    @IsTest
    static void pasaElCasoAEnCursoConCodigoDeCierre() {
        Case resultado = CaseCambioEquipoApple.buildUpdate(new Case());

        Assert.areEqual(CaseCambioEquipoApple.STATUS_EN_CURSO, resultado.Status);
        Assert.areEqual(CaseCambioEquipoApple.CODIGO_CAMBIO_EQUIPO, resultado.PVU_Codigo_de_Cierre__c);
    }

    @IsTest
    static void siemprePoneElSubEstadoEnGuion() {
        Case sinSubEstado = CaseCambioEquipoApple.buildUpdate(new Case());
        Case conGuion = CaseCambioEquipoApple.buildUpdate(new Case(PVU_Sub_Estado__c = CaseCambioEquipoApple.SUB_ESTADO_VACIO));

        Assert.areEqual(CaseCambioEquipoApple.SUB_ESTADO_VACIO, sinSubEstado.PVU_Sub_Estado__c);
        Assert.areEqual(CaseCambioEquipoApple.SUB_ESTADO_VACIO, conGuion.PVU_Sub_Estado__c);
    }

    @IsTest
    static void conservaElCreditoDelCaso() {
        Case resultado = CaseCambioEquipoApple.buildUpdate(new Case(
            FIN_NumeroCredito__c = 'CRED-CASO',
            Asset = new Asset(FIN_NumeroDeCredito__c = 'CRED-ASSET')
        ));

        Assert.areEqual('CRED-CASO', resultado.FIN_NumeroCredito__c);
    }

    @IsTest
    static void tomaElCreditoDelAssetSiElCasoNoLoTiene() {
        Case resultado = CaseCambioEquipoApple.buildUpdate(new Case(Asset = new Asset(FIN_NumeroDeCredito__c = 'CRED-ASSET')));

        Assert.areEqual('CRED-ASSET', resultado.FIN_NumeroCredito__c);
    }

    @IsTest
    static void dejaElCreditoVacioSinAsset() {
        Assert.isNull(CaseCambioEquipoApple.buildUpdate(new Case()).FIN_NumeroCredito__c);
    }

    @IsTest
    static void actualizaElCasoDespuesDeCrearlo() {
        Case nuevo = caso(CaseCambioEquipoApple.STATUS_ABIERTO, CaseCambioEquipoApple.LEVEL3_APPLE);

        Test.startTest();
        insert nuevo;
        Test.stopTest();

        // La clase lo deja En curso; en la misma transacción PVU_UpdateCase_CasosCerrados puede cerrarlo,
        // así que se valida que salió de Abierto y quedó con el código de cierre.
        Case guardado = [SELECT Status, PVU_Codigo_de_Cierre__c FROM Case WHERE Id = :nuevo.Id];
        Assert.areNotEqual(CaseCambioEquipoApple.STATUS_ABIERTO, guardado.Status);
        Assert.areEqual(CaseCambioEquipoApple.CODIGO_CAMBIO_EQUIPO, guardado.PVU_Codigo_de_Cierre__c);
    }

    @IsTest
    static void noTocaCasosDeOtraTipificacion() {
        Case otro = caso(CaseCambioEquipoApple.STATUS_ABIERTO, OTRA_TIPIFICACION);

        Test.startTest();
        insert otro;
        Test.stopTest();

        Assert.areEqual(CaseCambioEquipoApple.STATUS_ABIERTO, [SELECT Status FROM Case WHERE Id = :otro.Id].Status);
    }

    // PVU_Level3__c es una lista restringida que depende de PVU_Level2__c, y esta de PVU_Level1__c.
    private static final String LEVEL1 = 'Solicitud de información y modificaciones';
    private static final String LEVEL2 = 'Actualización de datos';
    private static final String OTRA_TIPIFICACION = 'Actualización datos personales';

    private static Case caso(String status, String level3) {
        return new Case(
            Subject = 'Prueba cambio de equipo',
            Status = status,
            PVU_Level1__c = LEVEL1,
            PVU_Level2__c = LEVEL2,
            PVU_Level3__c = level3
        );
    }
}
