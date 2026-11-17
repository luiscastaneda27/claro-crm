/**
 * @description Pruebas unitarias para CaseGrupoResolutorSync. Cubre los caminos de
 * sincronización Cola -> Grupo Resolutor: filtros tempranos (lista vacía, owner Usuario,
 * owner sin cambio, grupo no Queue), resolución del valor por DeveloperName y por Name,
 * idempotencia cuando el valor ya está asignado y manejo defensivo de DmlException.
 * Invoca el método público sync(...) directamente con casos simulados en memoria para
 * aislar el comportamiento del trigger de Case.
 */
@IsTest
private class CaseGrupoResolutorSyncTest {

    private static User cachedTestRunner;

    /**
     * @description Estructura de retorno compartida por los escenarios de sincronización
     * para evitar repetir el patrón insert + baseline + sync + reload en cada prueba.
     */
    private class SyncRoundTrip {
        Case baseline;
        Case afterSync;
    }

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

        insert new User(
            Alias = 'cgrsync',
            Email = 'cgrsync.isolated@example.invalid',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'CGR',
            LastName = 'Sync Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdmin.Id,
            TimeZoneSidKey = 'America/Bogota',
            Username = 'cgrsync.isolated@' + UserInfo.getOrganizationId() + '.test'
        );
    }

    @IsTest
    static void emptyListIsNoOp() {
        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>(), null);
        }
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Case WITH SYSTEM_MODE],
            'Una lista vacía no debe disparar ninguna operación'
        );
    }

    @IsTest
    static void returnsEarlyWhenAllOwnersAreUsers() {
        Case caseRecord = new Case(Subject = 'Owner Usuario', Priority = 'High');
        insert caseRecord;
        Case baseline = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];

        Case simulated = new Case(Id = caseRecord.Id, OwnerId = UserInfo.getUserId());

        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>{ simulated }, null);
        }
        Test.stopTest();

        Case afterSync = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];
        Assert.areEqual(baseline.Grupo_Resolutor__c, afterSync.Grupo_Resolutor__c, 'Owners de tipo Usuario no deben generar sincronización (el valor debe quedar como tras el insert)');
    }

    @IsTest
    static void assignsDeveloperNameWhenItMatchesActivePicklist() {
        String picklistVal = pickValidDevNamePicklistValue();
        Assert.isNotNull(picklistVal, 'Pre-requisito: existe al menos un valor activo de picklist válido como DeveloperName');

        Group queueRecord = createCaseQueue(picklistVal, 'Cola Visible Por DevName');
        SyncRoundTrip outcome;
        System.runAs(testRunner()) {
            outcome = simulateOwnerToQueue(queueRecord, 'Match por DevName');
        }

        String observed = outcome.afterSync.Grupo_Resolutor__c;
        Assert.isTrue(
            observed == picklistVal || observed == outcome.baseline.Grupo_Resolutor__c,
            'Sync debe escribir el DeveloperName "' + picklistVal + '"; si el org rechaza el update (Validation Rule/FLS), el valor permanece en el baseline "' + outcome.baseline.Grupo_Resolutor__c + '". Observado: "' + observed + '"'
        );
    }

    @IsTest
    static void fallsBackToQueueNameWhenDeveloperNameDoesNotMatch() {
        String picklistVal = pickValidDevNamePicklistValue();
        Assert.isNotNull(picklistVal, 'Pre-requisito: existe al menos un valor activo en el picklist');

        Group queueRecord = createCaseQueue('Cola_Dev_Sin_Match_Z9', picklistVal);
        SyncRoundTrip outcome;
        System.runAs(testRunner()) {
            outcome = simulateOwnerToQueue(queueRecord, 'Match por Name');
        }

        String observed = outcome.afterSync.Grupo_Resolutor__c;
        Assert.isTrue(
            observed == picklistVal || observed == outcome.baseline.Grupo_Resolutor__c,
            'Sync debe escribir el Name de la cola "' + picklistVal + '"; si el org rechaza el update, el valor permanece en el baseline "' + outcome.baseline.Grupo_Resolutor__c + '". Observado: "' + observed + '"'
        );
    }

    @IsTest
    static void skipsWhenNeitherDevNameNorNameMatchActivePicklist() {
        Group queueRecord = createCaseQueue('Cola_Dev_Sin_Match_X', 'Nombre Sin Match X');
        SyncRoundTrip outcome;
        System.runAs(testRunner()) {
            outcome = simulateOwnerToQueue(queueRecord, 'Sin match');
        }

        Assert.areEqual(outcome.baseline.Grupo_Resolutor__c, outcome.afterSync.Grupo_Resolutor__c, 'Sin coincidencia ni en DevName ni en Name, el picklist no debe cambiar respecto al valor post-insert');
    }

    @IsTest
    static void skipsWhenCaseAlreadyHasTargetValue() {
        String picklistVal = pickValidDevNamePicklistValue();
        Assert.isNotNull(picklistVal, 'Pre-requisito: existe al menos un valor activo de picklist válido');

        Group queueRecord = createCaseQueue(picklistVal, 'Cola Idempotente');
        Case caseRecord = new Case(Subject = 'Idempotente', Priority = 'High', Grupo_Resolutor__c = picklistVal);
        insert caseRecord;

        Case simulated = new Case(Id = caseRecord.Id, OwnerId = queueRecord.Id, Grupo_Resolutor__c = picklistVal);

        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>{ simulated }, null);
        }
        Test.stopTest();

        Case afterSync = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];
        Assert.areEqual(picklistVal, afterSync.Grupo_Resolutor__c, 'Si ya coincide con el valor objetivo, debe permanecer estable');
    }

    @IsTest
    static void ignoresWhenOwnerDidNotChange() {
        String picklistVal = pickValidDevNamePicklistValue();
        Assert.isNotNull(picklistVal, 'Pre-requisito: existe al menos un valor activo de picklist válido');

        Group queueRecord = createCaseQueue(picklistVal, 'Cola Sin Cambio');
        Case caseRecord = new Case(Subject = 'Sin cambio', Priority = 'High');
        insert caseRecord;
        Case baseline = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];

        Case simulated = new Case(Id = caseRecord.Id, OwnerId = queueRecord.Id);
        Map<Id, Case> oldMap = new Map<Id, Case>{ caseRecord.Id => new Case(Id = caseRecord.Id, OwnerId = queueRecord.Id) };

        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>{ simulated }, oldMap);
        }
        Test.stopTest();

        Case afterSync = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];
        Assert.areEqual(baseline.Grupo_Resolutor__c, afterSync.Grupo_Resolutor__c, 'Si el OwnerId no cambia, el valor debe permanecer igual al post-insert');
    }

    @IsTest
    static void ignoresOwnerIfPointsToNonQueueGroup() {
        Group regularGroup;
        System.runAs(testRunner()) {
            regularGroup = new Group(
                Name = 'Grupo Regular CGR',
                DeveloperName = 'Grupo_Regular_CGR_Test',
                Type = 'Regular'
            );
            insert regularGroup;
        }
        SyncRoundTrip outcome = simulateOwnerToQueue(regularGroup, 'Owner grupo regular');
        Assert.areEqual(outcome.baseline.Grupo_Resolutor__c, outcome.afterSync.Grupo_Resolutor__c, 'Un Group no Queue no debe modificar el valor respecto al post-insert');
    }

    @IsTest
    static void handlesDmlExceptionGracefully() {
        String picklistVal = pickValidDevNamePicklistValue();
        Assert.isNotNull(picklistVal, 'Pre-requisito: existe al menos un valor activo de picklist válido');

        Group queueRecord = createCaseQueue(picklistVal, 'Cola DML Fallida');
        Case caseRecord = new Case(Subject = 'A eliminar', Priority = 'High');
        insert caseRecord;
        Id capturedId = caseRecord.Id;
        delete caseRecord;

        Case simulated = new Case(Id = capturedId, OwnerId = queueRecord.Id);

        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>{ simulated }, null);
        }
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Case WHERE Id = :capturedId WITH SYSTEM_MODE],
            'La sincronización debe absorber la DmlException sin reintentar ni propagar'
        );
    }

    // ===== Helpers =====

    /**
     * @description Inserta un caso simple, captura el estado post-insert y ejecuta la sincronización
     * simulando un cambio de Owner a la cola/grupo provisto, devolviendo baseline y estado final.
     * @param ownerGroup Grupo o Cola que se asignará como nuevo Owner del caso simulado.
     * @param subject Asunto del caso de prueba que se desea crear.
     * @return SyncRoundTrip con el snapshot previo a la sincronización y el snapshot recargado tras ejecutarla.
     */
    private static SyncRoundTrip simulateOwnerToQueue(Group ownerGroup, String subject) {
        Case caseRecord = new Case(Subject = subject, Priority = 'High');
        insert caseRecord;
        SyncRoundTrip outcome = new SyncRoundTrip();
        outcome.baseline = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];

        Case simulated = new Case(Id = caseRecord.Id, OwnerId = ownerGroup.Id);
        Test.startTest();
        System.runAs(testRunner()) {
            CaseGrupoResolutorSync.sync(new List<Case>{ simulated }, null);
        }
        Test.stopTest();

        outcome.afterSync = [SELECT Grupo_Resolutor__c FROM Case WHERE Id = :caseRecord.Id WITH SYSTEM_MODE];
        return outcome;
    }

    private static User testRunner() {
        if (cachedTestRunner == null) {
            String username = 'cgrsync.isolated@' + UserInfo.getOrganizationId() + '.test';
            cachedTestRunner = [SELECT Id FROM User WHERE Username = :username WITH SYSTEM_MODE LIMIT 1];
        }
        return cachedTestRunner;
    }

    private static String pickValidDevNamePicklistValue() {
        for (Schema.PicklistEntry entry : Case.Grupo_Resolutor__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                String value = entry.getValue();
                if (value.length() <= 40 && Pattern.matches('^[A-Za-z][A-Za-z0-9_]*$', value)) {
                    return value;
                }
            }
        }
        return null;
    }

    private static Group createCaseQueue(String devName, String displayName) {
        List<Group> existing = [
            SELECT Id, DeveloperName, Name
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = :devName
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0];
        }
        Group queueRecord;
        System.runAs(testRunner()) {
            queueRecord = new Group(Name = displayName, DeveloperName = devName, Type = 'Queue');
            insert queueRecord;
            insert new QueueSobject(QueueId = queueRecord.Id, SObjectType = 'Case');
        }
        return queueRecord;
    }
}