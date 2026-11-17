/**
 * @description Sincroniza el campo Case.Grupo_Resolutor__c con la cola asignada al caso.
 * Cuando el OwnerId cambia (o en inserción) y apunta a una Queue, copia DeveloperName/Name
 * de la cola al picklist Grupo_Resolutor__c si el valor existe activo en el picklist.
 */
public with sharing class CaseGrupoResolutorSync {

    /**
     * @description Ejecuta la sincronización para los casos cuyo Owner cambió a (o fue creado en) una Queue.
     * Realiza una actualización DML separada, segura para contextos After Trigger.
     * @param newCases Lista de casos en su estado nuevo (Trigger.new).
     * @param oldMap Mapa de casos en su estado previo (Trigger.oldMap); null en inserción.
     */
    public static void sync(List<Case> newCases, Map<Id, Case> oldMap) {
        Set<Id> queueIds = collectQueueIdsFromChangedOwners(newCases, oldMap);
        if (queueIds.isEmpty()) {
            return;
        }

        Map<Id, Group> queueMap = loadQueueMap(queueIds);
        Set<String> validValues = loadActivePicklistValues();
        List<Case> casesToUpdate = buildUpdates(newCases, queueMap, validValues);

        if (!casesToUpdate.isEmpty()) {
            applyUpdates(casesToUpdate);
        }
    }

    private static Set<Id> collectQueueIdsFromChangedOwners(List<Case> newCases, Map<Id, Case> oldMap) {
        Set<Id> queueIds = new Set<Id>();
        for (Case c : newCases) {
            if (isQueueOwnerAssignment(c, oldMap)) {
                queueIds.add(c.OwnerId);
            }
        }
        return queueIds;
    }

    private static Boolean isQueueOwnerAssignment(Case c, Map<Id, Case> oldMap) {
        if (c.OwnerId == null || c.OwnerId.getSObjectType() != Group.SObjectType) {
            return false;
        }
        Case oldCase = (oldMap != null) ? oldMap.get(c.Id) : null;
        return oldCase == null || c.OwnerId != oldCase.OwnerId;
    }

    private static Map<Id, Group> loadQueueMap(Set<Id> queueIds) {
        return new Map<Id, Group>([
            SELECT Id, DeveloperName, Name
            FROM Group
            WHERE Type = 'Queue' AND Id IN :queueIds
            WITH SYSTEM_MODE
        ]);
    }

    private static Set<String> loadActivePicklistValues() {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : Case.Grupo_Resolutor__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static List<Case> buildUpdates(List<Case> newCases, Map<Id, Group> queueMap, Set<String> validValues) {
        List<Case> updates = new List<Case>();
        for (Case c : newCases) {
            Group queueObj = queueMap.get(c.OwnerId);
            if (queueObj == null) {
                continue;
            }
            String assigned = resolveValue(queueObj, validValues);
            if (assigned != null && c.Grupo_Resolutor__c != assigned) {
                updates.add(new Case(Id = c.Id, Grupo_Resolutor__c = assigned));
            }
        }
        return updates;
    }

    private static String resolveValue(Group queueObj, Set<String> validValues) {
        if (validValues.contains(queueObj.DeveloperName)) {
            return queueObj.DeveloperName;
        }
        if (validValues.contains(queueObj.Name)) {
            return queueObj.Name;
        }
        return null;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static void applyUpdates(List<Case> casesToUpdate) {
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, casesToUpdate);
            update decision.getRecords();
        } catch (DmlException e) {
            // Best-effort: la sincronización no debe romper el flujo del Case.
            System.debug(LoggingLevel.ERROR, 'CaseGrupoResolutorSync error: ' + e.getMessage());
        }
    }
}