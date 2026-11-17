/**
 * @description Pruebas unitarias para CaseTimeTrackerController.
 * Verifica la correcta instanciación de la clase envolvente SlaTrackerWrapper,
 * los cálculos de tiempo comercial restante y el manejo de excepciones por falta de datos.
 */
@IsTest
private class CaseTimeTrackerControllerTest {

    private static User cachedTestRunner;

    @TestSetup
    static void seedIsolatedUser() {
        Profile sysAdmin = [SELECT Id
            FROM Profile
            WHERE UserType = 'Standard'
            AND PermissionsModifyAllData = true
            AND PermissionsViewAllData = true
            AND PermissionsManageUsers = true
            AND PermissionsAuthorApex = true
            AND PermissionsCustomizeApplication = true
            AND PermissionsManageProfilesPermissionsets = true
            AND PermissionsViewSetup = true
            WITH SYSTEM_MODE
            LIMIT 1];
        User u = new User(
            Alias = 'ctctrl',
            Email = 'ctctrl.isolated@example.invalid',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'CTC',
            LastName = 'Controller Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdmin.Id,
            TimeZoneSidKey = 'America/Bogota',
            Username = 'ctctrl.isolated@' + UserInfo.getOrganizationId() + '.test'
        );
        insert u;

        PermissionSet ps = [
            SELECT Id FROM PermissionSet
            WHERE Name = 'Supervisor_de_Soporte_Multinivel'
            WITH SYSTEM_MODE LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void returnsNullWhenCaseIdIsBlank() {
        Test.startTest();
        CaseTimeTrackerController.SlaTrackerWrapper result;
        System.runAs(currentUser()) {
            result = CaseTimeTrackerController.getActiveTracker(null);
        }
        Test.stopTest();

        Assert.isNull(result, 'El resultado debe ser nulo cuando el identificador del caso está en blanco');
    }

    @IsTest
    static void returnsNullWhenNoActiveTrackerExists() {
        Case testCase = createTestCase();

        Test.startTest();
        System.runAs(currentUser()) {
            CaseTimeTrackerController.SlaTrackerWrapper result = CaseTimeTrackerController.getActiveTracker(testCase.Id);
            Assert.isNull(result, 'El resultado debe ser nulo si el caso no posee rastreadores activos');
        }
        Test.stopTest();
    }

    @IsTest
    static void returnsWrapperNotOverdueWhenTargetInFuture() {
        Case testCase = createTestCase();
        BusinessHours defaultBh = getDefaultBusinessHours();

        Case_Time_Tracker__c tracker = new Case_Time_Tracker__c(
            Case__c = testCase.Id,
            Is_Active__c = true,
            Business_Hours__c = defaultBh.Id,
            Start_Time__c = System.now(),
            Target_End_Time__c = System.now().addDays(1)
        );
        insert tracker;

        Test.startTest();
        CaseTimeTrackerController.SlaTrackerWrapper result;
        System.runAs(currentUser()) {
            result = CaseTimeTrackerController.getActiveTracker(testCase.Id);
        }
        Test.stopTest();

        Assert.isNotNull(result, 'El wrapper de respuesta no debe ser nulo');
        Assert.isNotNull(result.record, 'El registro del rastreador debe estar instanciado dentro del wrapper');
        Assert.isFalse(result.isOverdue, 'El hito no debe estar marcado como vencido');
        Assert.isTrue(result.remainingBusinessMs >= 0, 'Los milisegundos restantes calculados deben ser positivos o cero');
    }

    @IsTest
    static void returnsWrapperOverdueWhenTargetInPast() {
        Case testCase = createTestCase();
        BusinessHours defaultBh = getDefaultBusinessHours();

        Case_Time_Tracker__c tracker = new Case_Time_Tracker__c(
            Case__c = testCase.Id,
            Is_Active__c = true,
            Business_Hours__c = defaultBh.Id,
            Start_Time__c = System.now().addDays(-2),
            Target_End_Time__c = System.now().addDays(-1)
        );
        insert tracker;

        Test.startTest();
        CaseTimeTrackerController.SlaTrackerWrapper result;
        System.runAs(currentUser()) {
            result = CaseTimeTrackerController.getActiveTracker(testCase.Id);
        }
        Test.stopTest();

        Assert.isNotNull(result, 'El wrapper de respuesta no debe ser nulo');
        Assert.isTrue(result.isOverdue, 'El hito debe estar marcado explícitamente como vencido');
        Assert.isTrue(result.remainingBusinessMs >= 0, 'Los milisegundos de retraso deben calcularse como un valor absoluto positivo o cero');
    }

    @IsTest
    static void handlesNullTargetEndTime() {
        Case testCase = createTestCase();

        Case_Time_Tracker__c tracker = new Case_Time_Tracker__c(
            Case__c = testCase.Id,
            Is_Active__c = true,
            Start_Time__c = System.now()
        );
        insert tracker;

        Test.startTest();
        CaseTimeTrackerController.SlaTrackerWrapper result;
        System.runAs(currentUser()) {
            result = CaseTimeTrackerController.getActiveTracker(testCase.Id);
        }
        Test.stopTest();

        Assert.isNotNull(result, 'El wrapper de respuesta no debe ser nulo');
        Assert.isFalse(result.isOverdue, 'El rastreador no debe marcarse como vencido si carece de fecha objetivo');
        Assert.areEqual(0, result.remainingBusinessMs, 'El tiempo restante debe ser cero en ausencia de un límite temporal');
    }

    @IsTest
    static void handlesNullBusinessHoursFallback() {
        Case testCase = createTestCase();

        Case_Time_Tracker__c tracker = new Case_Time_Tracker__c(
            Case__c = testCase.Id,
            Is_Active__c = true,
            Business_Hours__c = null,
            Start_Time__c = System.now(),
            Target_End_Time__c = System.now().addDays(1)
        );
        insert tracker;

        Test.startTest();
        CaseTimeTrackerController.SlaTrackerWrapper result;
        System.runAs(currentUser()) {
            result = CaseTimeTrackerController.getActiveTracker(testCase.Id);
        }
        Test.stopTest();

        Assert.isNotNull(result, 'El wrapper no debe ser nulo al ejecutar la regla de contingencia de calendario');
        Assert.isNotNull(result.isWithinBusinessHours, 'El sistema debe evaluar la disponibilidad horaria usando el calendario predeterminado');
    }

    // ===== Helpers =====

    private static User currentUser() {
        if (cachedTestRunner == null) {
            String username = 'ctctrl.isolated@' + UserInfo.getOrganizationId() + '.test';
            cachedTestRunner = [SELECT Id FROM User WHERE Username = :username WITH SYSTEM_MODE LIMIT 1];
        }
        return cachedTestRunner;
    }

    private static Case createTestCase() {
        Case c = new Case(
            Subject = 'Prueba Controlador Interfaz',
            Priority = 'High'
        );
        insert c;
        return c;
    }

    private static BusinessHours getDefaultBusinessHours() {
        return [SELECT Id FROM BusinessHours WHERE IsDefault = true WITH SYSTEM_MODE LIMIT 1];
    }
}