@IsTest
private class CaseTriggerHandlerTest {

    @TestSetup
    static void configurarDatosPrueba() {
        // Asignación a lista para prevenir System.QueryException
        List<Profile> perfiles = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar') LIMIT 1];
        
        // Mecanismo de respaldo en caso de que los perfiles hayan sido renombrados
        if (perfiles.isEmpty()) {
            perfiles = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];
        }
        
        User usuarioPrueba = new User(
            Alias = 'usrtest',
            Email = 'usuario.prueba.sfca@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PruebaSFCA',
            LanguageLocaleKey = 'es',
            LocaleSidKey = 'es_CO',
            ProfileId = perfiles[0].Id,
            TimeZoneSidKey = 'America/Bogota',
            UserName = 'usuario.prueba.sfca' + DateTime.now().getTime() + '@testorg.com'
        );
        insert usuarioPrueba;
    }

    @IsTest
    static void validarEjecucionAfterInsert() {
        List<User> usuarios = [SELECT Id FROM User WHERE LastName = 'PruebaSFCA' LIMIT 1];
        System.assertEquals(false, usuarios.isEmpty(), 'El usuario de prueba debe existir en el contexto.');
        
        List<Case> casosParaInsertar = new List<Case>();
        
        for (Integer i = 0; i < 200; i++) {
            casosParaInsertar.add(new Case(
                Subject = 'Caso de prueba masiva ' + i,
                Status = 'New',
                Origin = 'Web'
            ));
        }
        
        System.runAs(usuarios[0]) {
            Test.startTest();
            insert casosParaInsertar;
            Test.stopTest();
        }
        
        List<Case> casosInsertados = [SELECT Id, Subject FROM Case WHERE Origin = 'Web'];
        System.assertEquals(200, casosInsertados.size(), 'Se deben haber insertado 200 casos correctamente bajo el contexto del usuario de prueba.');
    }

    @IsTest
    static void validarEjecucionAfterUpdate() {
        List<User> usuarios = [SELECT Id FROM User WHERE LastName = 'PruebaSFCA' LIMIT 1];
        System.assertEquals(false, usuarios.isEmpty(), 'El usuario de prueba debe existir en el contexto.');
        
        List<Case> casosParaInsertar = new List<Case>();
        
        for (Integer i = 0; i < 200; i++) {
            casosParaInsertar.add(new Case(
                Subject = 'Caso inicial ' + i,
                Status = 'New',
                Origin = 'Web'
            ));
        }
        insert casosParaInsertar;
        
        for (Case casoActual : casosParaInsertar) {
            casoActual.Status = 'Working';
        }
        
        System.runAs(usuarios[0]) {
            Test.startTest();
            update casosParaInsertar;
            Test.stopTest();
        }
        
        List<Case> casosActualizados = [SELECT Id, Status FROM Case WHERE Status = 'Working'];
        System.assertEquals(200, casosActualizados.size(), 'Los 200 casos deben haber actualizado su estado a Working, detonando el evento After Update.');
    }
    
    @IsTest
    static void validarBypassEnCaseTrigger() {
        List<User> usuarios = [SELECT Id FROM User WHERE LastName = 'PruebaSFCA' LIMIT 1];
        System.assertEquals(false, usuarios.isEmpty(), 'El usuario de prueba debe existir en el contexto.');
        
        System.runAs(usuarios[0]) {
            TriggerHandler.bypass('CaseTriggerHandler');
            
            Case casoBypass = new Case(Subject = 'Caso Bypass', Status = 'New', Origin = 'Web');
            
            Test.startTest();
            insert casoBypass;
            Test.stopTest();
            
            System.assertEquals(true, TriggerHandler.isBypassed('CaseTriggerHandler'), 'El manejador CaseTriggerHandler debe registrarse como omitido.');
        }
    }
}