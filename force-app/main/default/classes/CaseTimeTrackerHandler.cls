/**
 * @description Manejador del ciclo de vida de Case_Time_Tracker__c. Detecta inserciones, cambios de
 * grupo/prioridad y cierres de caso, cierra el tracker activo (calculando duración con BusinessHours)
 * e inserta un nuevo tracker cuando aplica. Delega la sincronización Cola -> Grupo Resolutor en
 * CaseGrupoResolutorSync. Filtra dinámicamente los tipos de registro permitidos mediante Custom Metadata.
 */
@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class CaseTimeTrackerHandler {

    /**
     * @description Punto de entrada del manejador de triggers de Case.
     * @param newCases Lista de casos en su estado nuevo (Trigger.new).
     * @param oldMap Mapa de casos en su estado previo (Trigger.oldMap); null en contexto de inserción.
     */
    public static void handleCaseChanges(List<Case> newCases, Map<Id, Case> oldMap) {
        Set<Id> allowedRecordTypeIds = getAllowedRecordTypeIds();
        List<Case> validCases = new List<Case>();

        for (Case c : newCases) {
            if (allowedRecordTypeIds.contains(c.RecordTypeId)) {
                validCases.add(c);
            }
        }

        if (validCases.isEmpty()) {
            return;
        }

        CaseGrupoResolutorSync.sync(validCases, oldMap);

        Set<Id> caseIdsToProcess = identifyCasesToProcess(validCases, oldMap);
        if (caseIdsToProcess.isEmpty()) {
            return;
        }

        TrackerContext ctx = loadTrackerContext();
        List<Case_Time_Tracker__c> trackersToUpdate = getTrackersToClose(caseIdsToProcess, ctx.defaultBhId);
        List<Case_Time_Tracker__c> trackersToInsert = createNewTrackers(validCases, caseIdsToProcess, ctx);

        executeDmlOperations(trackersToUpdate, trackersToInsert);
    }

    // ===== Configuración de Tipos de Registro Permitidos =====

    private static Set<Id> getAllowedRecordTypeIds() {
        Set<Id> allowedIds = new Set<Id>();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

        for (Tracker_Allowed_RecordType__mdt config : [
            SELECT DeveloperName
            FROM Tracker_Allowed_RecordType__mdt
            WITH SYSTEM_MODE
            LIMIT 10000
        ]) {
            if (rtMap.containsKey(config.DeveloperName)) {
                allowedIds.add(rtMap.get(config.DeveloperName).getRecordTypeId());
            }
        }
        return allowedIds;
    }

    // ===== Identificación de casos =====

    private static Set<Id> identifyCasesToProcess(List<Case> newCases, Map<Id, Case> oldMap) {
        Set<Id> ids = new Set<Id>();
        for (Case c : newCases) {
            if (shouldProcessCase(c, oldMap)) {
                ids.add(c.Id);
            }
        }
        return ids;
    }

    private static Boolean shouldProcessCase(Case c, Map<Id, Case> oldMap) {
        if (String.isBlank(c.Grupo_Resolutor__c)) {
            return false;
        }
        Case oldCase = (oldMap != null) ? oldMap.get(c.Id) : null;
        if (oldCase == null) {
            return true;
        }
        return c.Grupo_Resolutor__c != oldCase.Grupo_Resolutor__c
            || c.Priority != oldCase.Priority
            || (c.IsClosed && !oldCase.IsClosed);
    }

    // ===== Carga de configuración =====

    private static TrackerContext loadTrackerContext() {
        TrackerContext ctx = new TrackerContext();
        loadBusinessHours(ctx);
        ctx.slaMap = loadSlaConfiguration();
        return ctx;
    }

    private static void loadBusinessHours(TrackerContext ctx) {
        for (BusinessHours bh : [
            SELECT Id, Name, IsDefault
            FROM BusinessHours
            WHERE IsActive = true
            WITH SYSTEM_MODE
            LIMIT 10000
        ]) {
            if (String.isNotBlank(bh.Name)) {
                ctx.bhMap.put(bh.Name.trim().toLowerCase(), bh.Id);
            }
            if (bh.IsDefault) {
                ctx.defaultBhId = bh.Id;
            }
        }
    }

    private static Map<String, SlaConfig> loadSlaConfiguration() {
        Map<String, SlaConfig> slaMap = new Map<String, SlaConfig>();
        for (Matriz_SLA_Resolutores__mdt sla : [
            SELECT Grupo_Resolutor__c, Priority__c, Target_Time_Minutes__c, Business_Hours_Name__c
            FROM Matriz_SLA_Resolutores__mdt
            WHERE Grupo_Resolutor__c != null AND Priority__c != null
            WITH SYSTEM_MODE
            LIMIT 10000
        ]) {
            String key = (sla.Grupo_Resolutor__c.trim() + '-' + sla.Priority__c.trim()).toLowerCase();
            SlaConfig config = new SlaConfig();
            config.targetMinutes = sla.Target_Time_Minutes__c;
            config.bhName = String.isNotBlank(sla.Business_Hours_Name__c) ? sla.Business_Hours_Name__c.trim().toLowerCase() : null;
            slaMap.put(key, config);
        }
        return slaMap;
    }

    // ===== Ciclo de vida de trackers =====

    private static List<Case_Time_Tracker__c> getTrackersToClose(Set<Id> caseIdsToProcess, Id defaultBhId) {
        List<Case_Time_Tracker__c> toClose = new List<Case_Time_Tracker__c>();
        for (Case_Time_Tracker__c tracker : [
            SELECT Id, Case__c, Start_Time__c, Business_Hours__c
            FROM Case_Time_Tracker__c
            WHERE Case__c IN :caseIdsToProcess AND Is_Active__c = true
            WITH SYSTEM_MODE
        ]) {
            closeTracker(tracker, defaultBhId);
            toClose.add(tracker);
        }
        return toClose;
    }

    private static void closeTracker(Case_Time_Tracker__c tracker, Id defaultBhId) {
        tracker.Is_Active__c = false;
        tracker.End_Time__c = System.now();

        Id bhId = tracker.Business_Hours__c != null ? tracker.Business_Hours__c : defaultBhId;
        if (bhId != null && tracker.Start_Time__c != null) {
            Long elapsedMs = BusinessHours.diff(bhId, tracker.Start_Time__c, tracker.End_Time__c);
            tracker.Duration_Minutes__c = elapsedMs / 60000;
        }
    }

    private static List<Case_Time_Tracker__c> createNewTrackers(List<Case> newCases, Set<Id> caseIdsToProcess, TrackerContext ctx) {
        List<Case_Time_Tracker__c> toInsert = new List<Case_Time_Tracker__c>();
        for (Case c : newCases) {
            if (canCreateTracker(c, caseIdsToProcess)) {
                toInsert.add(buildTracker(c, ctx));
            }
        }
        return toInsert;
    }

    private static Boolean canCreateTracker(Case c, Set<Id> caseIdsToProcess) {
        return !c.IsClosed
            && caseIdsToProcess.contains(c.Id)
            && String.isNotBlank(c.Grupo_Resolutor__c)
            && String.isNotBlank(c.Priority);
    }

    private static Case_Time_Tracker__c buildTracker(Case c, TrackerContext ctx) {
        String key = (c.Grupo_Resolutor__c.trim() + '-' + c.Priority.trim()).toLowerCase();
        SlaConfig config = ctx.slaMap.get(key);

        Decimal targetMinutes = (config != null && config.targetMinutes != null) ? config.targetMinutes : 0;
        String bhName = (config != null) ? config.bhName : null;
        Id bhId = (String.isNotBlank(bhName) && ctx.bhMap.containsKey(bhName)) ? ctx.bhMap.get(bhName) : ctx.defaultBhId;

        Case_Time_Tracker__c tracker = new Case_Time_Tracker__c(
            Case__c = c.Id,
            Grupo_Resolutor__c = c.Grupo_Resolutor__c,
            Priority__c = c.Priority,
            Start_Time__c = System.now(),
            Is_Active__c = true,
            Target_Time_Minutes__c = targetMinutes,
            Business_Hours__c = bhId
        );

        if (targetMinutes > 0 && bhId != null) {
            Long targetMs = (Long)(targetMinutes * 60000);
            tracker.Target_End_Time__c = BusinessHours.add(bhId, tracker.Start_Time__c, targetMs);
        }
        return tracker;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static void executeDmlOperations(List<Case_Time_Tracker__c> trackersToUpdate, List<Case_Time_Tracker__c> trackersToInsert) {
        try {
            if (!trackersToUpdate.isEmpty()) {
                SObjectAccessDecision updateDecision = Security.stripInaccessible(AccessType.UPDATABLE, trackersToUpdate);
                update updateDecision.getRecords();
            }
            if (!trackersToInsert.isEmpty()) {
                SObjectAccessDecision insertDecision = Security.stripInaccessible(AccessType.CREATABLE, trackersToInsert);
                insert insertDecision.getRecords();
            }
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'CaseTimeTrackerHandler error: ' + e.getMessage());
        }
    }

    private class TrackerContext {
        public Map<String, Id> bhMap = new Map<String, Id>();
        public Id defaultBhId;
        public Map<String, SlaConfig> slaMap;
    }

    private class SlaConfig {
        public Decimal targetMinutes;
        public String bhName;
    }
}