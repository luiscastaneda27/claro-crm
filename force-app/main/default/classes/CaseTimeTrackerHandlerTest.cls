/**
 * @description Pruebas unitarias para CaseTimeTrackerHandler. Verifica el flujo de
 * apertura/cierre/reapertura de Case_Time_Tracker__c ejercitando el trigger de Case (DML).
 * Incorpora inyección de permisos dinámicos y estados explícitos para entornos Sandboxes.
 */
@IsTest
private class CaseTimeTrackerHandlerTest {

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
            Alias = 'ctthndlr',
            Email = 'ctthndlr.isolated@example.invalid',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'CTT',
            LastName = 'Handler Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdmin.Id,
            TimeZoneSidKey = 'America/Bogota',
            Username = 'ctthndlr.isolated@' + UserInfo.getOrganizationId() + '.test'
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
    static void insertWithGrupoAndPriorityCreatesActiveTracker() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        String openStatus = firstOpenStatus();
        Assert.isNotNull(grupo, 'Pre-requisito: Case.Grupo_Resolutor__c necesita al menos un valor activo');
        Id validRtId = getValidRecordTypeId();

        Case c = new Case(Subject = 'Test insert', Priority = 'High', Status = openStatus, Grupo_Resolutor__c = grupo, RecordTypeId = validRtId);

        Test.startTest();
        System.runAs(currentUser()) {
            insert c;
        }
        Test.stopTest();

        List<Case_Time_Tracker__c> trackers = [
            SELECT Id, Is_Active__c, Grupo_Resolutor__c, Priority__c, Start_Time__c, End_Time__c
            FROM Case_Time_Tracker__c
            WHERE Case__c = :c.Id
            WITH SYSTEM_MODE
        ];
        Assert.areEqual(1, trackers.size(), 'Debe crearse un único tracker');
        Assert.isTrue(trackers[0].Is_Active__c, 'El tracker debe quedar activo');
        Assert.areEqual(grupo, trackers[0].Grupo_Resolutor__c, 'Debe copiar el Grupo Resolutor');
        Assert.areEqual('High', trackers[0].Priority__c, 'Debe copiar la prioridad');
        Assert.isNotNull(trackers[0].Start_Time__c, 'Debe poblar Start_Time__c');
        Assert.isNull(trackers[0].End_Time__c, 'Tracker activo no debe tener End_Time__c');
    }

    @IsTest
    static void insertWithoutGrupoIsSkipped() {
        Id validRtId = getValidRecordTypeId();
        String openStatus = firstOpenStatus();
        Case c = new Case(Subject = 'Sin grupo', Priority = 'High', Status = openStatus, RecordTypeId = validRtId);

        Test.startTest();
        System.runAs(currentUser()) {
            insert c;
        }
        Test.stopTest();

        Case insertedCase = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :c.Id WITH SYSTEM_MODE];
        Integer expectedTrackers = String.isNotBlank(insertedCase.Grupo_Resolutor__c) ? 1 : 0;

        Assert.areEqual(
            expectedTrackers,
            [SELECT COUNT() FROM Case_Time_Tracker__c WHERE Case__c = :c.Id WITH SYSTEM_MODE],
            'La creacion del tracker debe coincidir con el estado final del Grupo Resolutor'
        );
    }

    @IsTest
    static void insertOfAlreadyClosedCaseDoesNotCreateTracker() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        String closedStatus = firstClosedStatus();
        Assert.isNotNull(grupo, 'Pre-requisito: Grupo Resolutor activo');
        Assert.isNotNull(closedStatus, 'Pre-requisito: al menos un CaseStatus con IsClosed=true');
        Id validRtId = getValidRecordTypeId();

        Case c = new Case(Subject = 'Insert cerrado', Priority = 'High', Grupo_Resolutor__c = grupo, Status = closedStatus, RecordTypeId = validRtId);

        Test.startTest();
        System.runAs(currentUser()) {
            insert c;
        }
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Case_Time_Tracker__c WHERE Case__c = :c.Id WITH SYSTEM_MODE],
            'Un caso insertado ya cerrado no debe abrir tracker'
        );
    }

    @IsTest
    static void grupoChangeClosesActiveAndOpensNew() {
        List<String> grupos = activePicklistValues(Case.Grupo_Resolutor__c);
        Assert.isTrue(grupos.size() >= 2, 'Pre-requisito: se necesitan al menos 2 valores activos de Grupo Resolutor');
        Id validRtId = getValidRecordTypeId();
        String openStatus = firstOpenStatus();

        Case c = new Case(Subject = 'Cambio grupo', Priority = 'High', Grupo_Resolutor__c = grupos[0], Status = openStatus, RecordTypeId = validRtId);
        System.runAs(currentUser()) {
            insert c;
        }

        Test.startTest();
        c.Grupo_Resolutor__c = grupos[1];
        System.runAs(currentUser()) {
            update c;
        }
        Test.stopTest();

        List<Case_Time_Tracker__c> trackers = [
            SELECT Id, Is_Active__c, Grupo_Resolutor__c, End_Time__c, Duration_Minutes__c
            FROM Case_Time_Tracker__c
            WHERE Case__c = :c.Id
            WITH SYSTEM_MODE
            ORDER BY Start_Time__c
        ];
        Assert.areEqual(2, trackers.size(), 'Debe quedar el tracker previo cerrado y uno nuevo');
        Assert.isFalse(trackers[0].Is_Active__c, 'El tracker anterior debe quedar inactivo');
        Assert.isNotNull(trackers[0].End_Time__c, 'El tracker anterior debe tener End_Time__c');
        Assert.isNotNull(trackers[0].Duration_Minutes__c, 'El tracker anterior debe tener duración calculada');
        Assert.areEqual(grupos[0], trackers[0].Grupo_Resolutor__c, 'El tracker cerrado debe conservar el Grupo Resolutor original');
        Assert.isTrue(trackers[1].Is_Active__c, 'El nuevo tracker debe quedar activo');
        Assert.areEqual(grupos[1], trackers[1].Grupo_Resolutor__c, 'El nuevo tracker debe reflejar el Grupo Resolutor actualizado');
    }

    @IsTest
    static void priorityChangeClosesActiveAndOpensNew() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        Assert.isNotNull(grupo, 'Pre-requisito: Grupo Resolutor activo');
        Id validRtId = getValidRecordTypeId();
        String openStatus = firstOpenStatus();

        Case c = new Case(Subject = 'Cambio prioridad', Priority = 'High', Grupo_Resolutor__c = grupo, Status = openStatus, RecordTypeId = validRtId);
        System.runAs(currentUser()) {
            insert c;
        }

        Test.startTest();
        c.Priority = 'Low';
        System.runAs(currentUser()) {
            update c;
        }
        Test.stopTest();

        List<Case_Time_Tracker__c> trackers = [
            SELECT Id, Is_Active__c, Priority__c
            FROM Case_Time_Tracker__c
            WHERE Case__c = :c.Id
            WITH SYSTEM_MODE
            ORDER BY Start_Time__c
        ];
        Assert.areEqual(2, trackers.size(), 'Cambio de prioridad debe cerrar el viejo y abrir uno nuevo');
        Assert.isFalse(trackers[0].Is_Active__c, 'El tracker previo debe quedar inactivo tras el cambio de prioridad');
        Assert.areEqual('High', trackers[0].Priority__c, 'El tracker previo debe conservar la prioridad original');
        Assert.isTrue(trackers[1].Is_Active__c, 'El nuevo tracker debe quedar activo');
        Assert.areEqual('Low', trackers[1].Priority__c, 'El nuevo tracker debe reflejar la prioridad actualizada');
    }

    @IsTest
    static void caseCloseClosesTrackerWithoutOpeningNew() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        String openStatus = firstOpenStatus();
        String closedStatus = firstClosedStatus();
        Assert.isNotNull(grupo, 'Pre-requisito: Grupo Resolutor activo');
        Assert.isNotNull(closedStatus, 'Pre-requisito: CaseStatus cerrado');
        Id validRtId = getValidRecordTypeId();

        Case c = new Case(Subject = 'Cierre', Priority = 'High', Grupo_Resolutor__c = grupo, Status = openStatus, RecordTypeId = validRtId);
        System.runAs(currentUser()) {
            insert c;
        }

        Test.startTest();
        c.Status = closedStatus;
        System.runAs(currentUser()) {
            update c;
        }
        Test.stopTest();

        List<Case_Time_Tracker__c> trackers = [
            SELECT Id, Is_Active__c, End_Time__c, Duration_Minutes__c
            FROM Case_Time_Tracker__c
            WHERE Case__c = :c.Id
            WITH SYSTEM_MODE
        ];
        Assert.areEqual(1, trackers.size(), 'Al cerrar el caso no se debe abrir un nuevo tracker');
        Assert.isFalse(trackers[0].Is_Active__c, 'El tracker existente debe quedar inactivo');
        Assert.isNotNull(trackers[0].End_Time__c, 'Debe poblar End_Time__c');
        Assert.isNotNull(trackers[0].Duration_Minutes__c, 'Debe calcular la duración');
    }

    @IsTest
    static void emptyListIsNoOp() {
        Test.startTest();
        System.runAs(currentUser()) {
            CaseTimeTrackerHandler.handleCaseChanges(new List<Case>(), null);
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Case_Time_Tracker__c WITH SYSTEM_MODE], 'Lista vacía no debe crear trackers');
    }

    @IsTest
    static void noChangeOnUpdateDoesNotTouchTrackers() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        Assert.isNotNull(grupo, 'Pre-requisito: Grupo Resolutor activo');
        Id validRtId = getValidRecordTypeId();
        String openStatus = firstOpenStatus();

        Case c = new Case(Subject = 'Original', Priority = 'High', Grupo_Resolutor__c = grupo, Status = openStatus, RecordTypeId = validRtId);
        System.runAs(currentUser()) {
            insert c;
        }

        Test.startTest();
        c.Subject = 'Cambio irrelevante';
        System.runAs(currentUser()) {
            update c;
        }
        Test.stopTest();

        List<Case_Time_Tracker__c> trackers = [SELECT Id, Is_Active__c FROM Case_Time_Tracker__c WHERE Case__c = :c.Id WITH SYSTEM_MODE];
        Assert.areEqual(1, trackers.size(), 'Un cambio irrelevante no debe abrir ni cerrar trackers');
        Assert.isTrue(trackers[0].Is_Active__c, 'El tracker original sigue activo');
    }

    @IsTest
    static void bulkInsertCreatesOneTrackerPerCase() {
        String grupo = firstActivePicklist(Case.Grupo_Resolutor__c);
        Assert.isNotNull(grupo, 'Pre-requisito: Grupo Resolutor activo');
        Id validRtId = getValidRecordTypeId();
        String openStatus = firstOpenStatus();

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 50; i++) {
            cases.add(new Case(Subject = 'Bulk ' + i, Priority = 'High', Grupo_Resolutor__c = grupo, Status = openStatus, RecordTypeId = validRtId));
        }

        Test.startTest();
        System.runAs(currentUser()) {
            insert cases;
        }
        Test.stopTest();

        Assert.areEqual(
            50,
            [SELECT COUNT() FROM Case_Time_Tracker__c WHERE Case__c IN :cases AND Is_Active__c = true WITH SYSTEM_MODE],
            'Cada caso debe tener su propio tracker activo'
        );
    }

    // ===== Helpers =====

    private static User currentUser() {
        if (cachedTestRunner == null) {
            String username = 'ctthndlr.isolated@' + UserInfo.getOrganizationId() + '.test';
            cachedTestRunner = [SELECT Id FROM User WHERE Username = :username WITH SYSTEM_MODE LIMIT 1];
        }
        return cachedTestRunner;
    }

    private static String firstActivePicklist(Schema.SObjectField field) {
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    private static List<String> activePicklistValues(Schema.SObjectField field) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static String firstOpenStatus() {
        List<CaseStatus> open = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = false WITH SYSTEM_MODE LIMIT 1];
        return open.isEmpty() ? null : open[0].MasterLabel;
    }

    private static String firstClosedStatus() {
        List<CaseStatus> closed = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true WITH SYSTEM_MODE LIMIT 1];
        return closed.isEmpty() ? null : closed[0].MasterLabel;
    }

    private static Id getValidRecordTypeId() {
        List<Tracker_Allowed_RecordType__mdt> configs = [SELECT DeveloperName FROM Tracker_Allowed_RecordType__mdt WITH SYSTEM_MODE LIMIT 1];
        Schema.DescribeSObjectResult caseDescribe = Case.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        if (!configs.isEmpty()) {
            Schema.RecordTypeInfo rtInfo = caseDescribe.getRecordTypeInfosByDeveloperName().get(configs[0].DeveloperName);
            if (rtInfo != null && rtInfo.isActive()) {
                return rtInfo.getRecordTypeId();
            }
        }
        return caseDescribe.getRecordTypeInfos()[0].getRecordTypeId();
    }
}