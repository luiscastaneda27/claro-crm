@IsTest
private class TriggerHandlerTest {

    /**
     * Clase interna para simular el comportamiento de un manejador concreto.
     * Sobrescribe todos los hooks por contexto: cada override invoca la
     * implementación base (super) para ejercitar su cuerpo y luego marca un
     * indicador que permite verificar el enrutamiento desde las pruebas.
     */
    private class MockTriggerHandler extends TriggerHandler {
        public Boolean isBeforeInsertExecuted = false;
        public Boolean isBeforeUpdateExecuted = false;
        public Boolean isBeforeDeleteExecuted = false;
        public Boolean isAfterInsertExecuted = false;
        public Boolean isAfterUpdateExecuted = false;
        public Boolean isAfterDeleteExecuted = false;
        public Boolean isAfterUndeleteExecuted = false;

        protected override void beforeInsert() {
            super.beforeInsert();
            this.isBeforeInsertExecuted = true;
        }
        protected override void beforeUpdate() {
            super.beforeUpdate();
            this.isBeforeUpdateExecuted = true;
        }
        protected override void beforeDelete() {
            super.beforeDelete();
            this.isBeforeDeleteExecuted = true;
        }
        protected override void afterInsert() {
            super.afterInsert();
            this.isAfterInsertExecuted = true;
        }
        protected override void afterUpdate() {
            super.afterUpdate();
            this.isAfterUpdateExecuted = true;
        }
        protected override void afterDelete() {
            super.afterDelete();
            this.isAfterDeleteExecuted = true;
        }
        protected override void afterUndelete() {
            super.afterUndelete();
            this.isAfterUndeleteExecuted = true;
        }
    }

    /**
     * @description Crea un usuario de prueba completamente aislado para System.runAs.
     *              Todas las claves de idioma, locale, codificación y zona horaria se
     *              fijan de forma explícita para que la prueba no dependa del idioma
     *              del usuario que la ejecuta. El perfil se resuelve por UserType
     *              ('Standard', valor estable y no traducido) en lugar de por Name,
     *              que sí varía según el idioma de la org.
     * @return User no insertado, con idioma/locale/zona horaria fijos, listo para System.runAs.
     */
    private static User crearUsuarioPruebaAislado() {
        Profile perfilEstandar = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        String sufijoUnico = String.valueOf(DateTime.now().getTime());
        return new User(
            Alias = 'thtest',
            Email = 'trigger.handler.test@example.com.invalid',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PruebaTriggerHandler',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = perfilEstandar.Id,
            TimeZoneSidKey = 'GMT',
            Username = 'trigger.handler.test.' + sufijoUnico + '@example.com.invalid'
        );
    }

    @IsTest
    static void validarMecanismoBypassActivo() {
        User usuarioAislado = crearUsuarioPruebaAislado();

        System.runAs(usuarioAislado) {
            MockTriggerHandler manejadorPrueba = new MockTriggerHandler();
            String nombreManejador = String.valueOf(manejadorPrueba).split(':')[0];

            TriggerHandler.bypass(nombreManejador);

            Test.startTest();
            manejadorPrueba.run();
            Test.stopTest();

            System.assertEquals(true, TriggerHandler.isBypassed(nombreManejador), 'El manejador debería estar en estado de bypass.');
            System.assertEquals(false, manejadorPrueba.isBeforeInsertExecuted, 'El método virtual no debe ejecutarse si el bypass está activo.');
        }
    }

    @IsTest
    static void validarMecanismoBypassInactivo() {
        User usuarioAislado = crearUsuarioPruebaAislado();

        System.runAs(usuarioAislado) {
            MockTriggerHandler manejadorPrueba = new MockTriggerHandler();
            String nombreManejador = String.valueOf(manejadorPrueba).split(':')[0];

            TriggerHandler.bypass(nombreManejador);
            TriggerHandler.clearBypass(nombreManejador);

            System.assertEquals(false, TriggerHandler.isBypassed(nombreManejador), 'El manejador no debería estar en estado de bypass tras limpiarlo.');

            TriggerHandler.clearAllBypasses();
        }
    }

    @IsTest
    static void validarEnrutamientoPorContexto() {
        User usuarioAislado = crearUsuarioPruebaAislado();

        System.runAs(usuarioAislado) {
            MockTriggerHandler manejador = new MockTriggerHandler();

            Test.startTest();
            manejador.dispatch(System.TriggerOperation.BEFORE_INSERT);
            manejador.dispatch(System.TriggerOperation.BEFORE_UPDATE);
            manejador.dispatch(System.TriggerOperation.BEFORE_DELETE);
            manejador.dispatch(System.TriggerOperation.AFTER_INSERT);
            manejador.dispatch(System.TriggerOperation.AFTER_UPDATE);
            manejador.dispatch(System.TriggerOperation.AFTER_DELETE);
            manejador.dispatch(System.TriggerOperation.AFTER_UNDELETE);
            Test.stopTest();

            System.assertEquals(true, manejador.isBeforeInsertExecuted, 'beforeInsert debe ejecutarse en el contexto BEFORE_INSERT.');
            System.assertEquals(true, manejador.isBeforeUpdateExecuted, 'beforeUpdate debe ejecutarse en el contexto BEFORE_UPDATE.');
            System.assertEquals(true, manejador.isBeforeDeleteExecuted, 'beforeDelete debe ejecutarse en el contexto BEFORE_DELETE.');
            System.assertEquals(true, manejador.isAfterInsertExecuted, 'afterInsert debe ejecutarse en el contexto AFTER_INSERT.');
            System.assertEquals(true, manejador.isAfterUpdateExecuted, 'afterUpdate debe ejecutarse en el contexto AFTER_UPDATE.');
            System.assertEquals(true, manejador.isAfterDeleteExecuted, 'afterDelete debe ejecutarse en el contexto AFTER_DELETE.');
            System.assertEquals(true, manejador.isAfterUndeleteExecuted, 'afterUndelete debe ejecutarse en el contexto AFTER_UNDELETE.');
        }
    }

    @IsTest
    static void validarRunSinBypassNoEnrutaFueraDeContextoTrigger() {
        User usuarioAislado = crearUsuarioPruebaAislado();

        System.runAs(usuarioAislado) {
            MockTriggerHandler manejador = new MockTriggerHandler();
            String nombreManejador = String.valueOf(manejador).split(':')[0];

            Test.startTest();
            manejador.run();
            Test.stopTest();

            System.assertEquals(false, TriggerHandler.isBypassed(nombreManejador), 'El manejador no debería estar en estado de bypass.');
            System.assertEquals(false, manejador.isBeforeInsertExecuted, 'Sin contexto de trigger (operationType nulo) no debe enrutarse ningún método.');
        }
    }
}