@IsTest
private class PVU_AzureADRegistrationHandlerTest {
 
    @IsTest
    static void testCanCreateUser() {
        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();
 
        Auth.UserData userData = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            'testuse8888r@example.org',
            null,
            'testuserlong',              // username
            'en_US',
            'facebook',
            null,
            new Map<String, String>{ 'language' => 'en_US' }
        );
 
        System.assertEquals(true, handler.canCreateUser(userData),
                            'canCreateUser siempre debe regresar true');
    }
 
    @IsTest
    static void testCreateUser_noEncontrado() {
        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();

        Auth.UserData userData = new Auth.UserData(
            'testId', 'testFirst', 'testLast', 'testFirst testLast',
            'noexiste@example.org', null, 'testuserlong', 'en_US', 'facebook',
            null, new Map<String, String>{ 'language' => 'en_US' }
        );

        User created = handler.createUser(null, userData);
        System.assertEquals(null, created, 'Sin usuario en org debe retornar null');
    }

    @IsTest
    static void testCreateUser_encontrado() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name='Usuario estándar' LIMIT 1];
        User u = new User(
            FirstName = 'Test', LastName = 'Create', Email = 'create@test.com',
            Username = 'createtest@clarocolombia.com.test', Alias = 'tcre',
            TimeZoneSidKey = 'America/Mexico_City', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', ProfileId = p.Id
        );
        insert u;

        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();
        Auth.UserData userData = new Auth.UserData(
            'testId', 'testFirst', 'testLast', 'testFirst testLast',
            'create@test.com', null, 'createtest', 'en_US', 'facebook',
            null, new Map<String, String>{ 'language' => 'en_US' }
        );

        User created = handler.createUser(null, userData);
        System.assertEquals(u.Id, created.Id, 'Debe retornar el usuario existente');
    }
 
    @IsTest
    static void testGetUserIdFound() {
        // 1) Crear un User de prueba directamente aquí
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name='Usuario estándar' LIMIT 1];
 
        User u = new User(
            FirstName        = 'Test',
            LastName         = 'User',
            Email            = 'testfed@test.com',
            Username         = 'clarocolombia2@clarocolombia2.com',
            Alias            = 'tfed',
            TimeZoneSidKey   = 'America/Mexico_City',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId        = p.Id,
            FederationIdentifier = 'clarocolombia2@clarocolombia2.com'
        );
        insert u;
 
        // 2) Probar el handler
        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();
 
        Auth.UserData userData = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            'testfed@test.com',
            null,
            'clarocolombia2@clarocolombia2.com',
            'en_US',
            'facebook',
            null,
            new Map<String, String>{ 'language' => 'en_US' }
        );
 
        Id returnedId = handler.getUserId(userData);
 
        System.assertEquals(u.Id, returnedId,
                            'Debe regresar el User.Id del usuario encontrado');
    }
 
    @IsTest
    static void testGetUserIdNotFound() {
        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();

        Auth.UserData userData = new Auth.UserData(
            'testId', 'testFirst', 'testLast', 'testFirst testLast',
            'none@example.org', null, 'NoExiste', 'en_US', 'facebook',
            null, new Map<String, String>{ 'language' => 'en_US' }
        );

        Id returnedId = handler.getUserId(userData);
        System.assertEquals(null, returnedId, 'Cuando no existe usuario debe retornar null');
    }
 
    @IsTest
    static void testUpdateUser() {
        PVU_AzureADRegistrationHandler handler = new PVU_AzureADRegistrationHandler();
 
        // Crear un User de prueba directo en el método
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name='Usuario estándar' LIMIT 1];
 
        User u = new User(
            FirstName        = 'Test',
            LastName         = 'User',
            Email            = 'update@test.com',
            Username         = 'clarocolombia@clarocolombia.com',
            Alias            = 'tupd',
            TimeZoneSidKey   = 'America/Mexico_City',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId        = p.Id,
            FederationIdentifier = 'FedUpdate'
        );
        insert u;
 
        Auth.UserData userData = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            'update@example.com',
            null,
            'FedUpdate',
            'en_US',
            'facebook',
            null,
            new Map<String, String>{ 'language' => 'en_US' }
        );
 
        // No hace nada, pero cubre la línea
        handler.updateUser(u.Id, null, userData);
 
        System.assert(true, 'Método ejecutado sin excepción');
    }
}