/**
 * @description Controlador Apex para el componente LWC de seguimiento de SLA de grupos.
 * Proporciona cálculos de tiempo hábiles precisos mediante una clase envolvente.
 */
public with sharing class CaseTimeTrackerController {

    /**
     * @description Clase envolvente que consolida el estado del hito bajo el horario laboral asignado.
     */
    @SuppressWarnings('PMD.AvoidBooleanMethodParameters')
    public class SlaTrackerWrapper {
        /** @description Registro activo del rastreador de tiempo del caso. */
        @AuraEnabled public Case_Time_Tracker__c record { get; set; }
        /** @description Tiempo restante en milisegundos dentro del horario laboral. */
        @AuraEnabled public Long remainingBusinessMs { get; set; }
        /** @description Indica si el momento actual está dentro del horario laboral. */
        @AuraEnabled public Boolean isWithinBusinessHours { get; set; }
        /** @description Indica si el SLA ha sido excedido. */
        @AuraEnabled public Boolean isOverdue { get; set; }
    }

    /**
     * @description Obtiene el wrapper de seguimiento de tiempo activo con métricas comerciales.
     * @param caseId ID del caso en evaluación.
     * @return Instancia de SlaTrackerWrapper o nulo si no se encuentra registro activo.
     */
    @AuraEnabled(cacheable=true)
    public static SlaTrackerWrapper getActiveTracker(Id caseId) {
        if (String.isBlank(caseId)) {
            return null;
        }

        List<Case_Time_Tracker__c> trackers = [
            SELECT Id, Grupo_Resolutor__c, Priority__c, Start_Time__c, Target_Time_Minutes__c, Target_End_Time__c, Business_Hours__c
            FROM Case_Time_Tracker__c
            WHERE Case__c = :caseId AND Is_Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        if (trackers.isEmpty()) {
            return null;
        }

        Case_Time_Tracker__c tracker = trackers[0];
        SlaTrackerWrapper wrapper = new SlaTrackerWrapper();
        wrapper.record = tracker;

        Id bhId = resolveBusinessHoursId(tracker.Business_Hours__c);
        if (bhId != null) {
            wrapper.isWithinBusinessHours = BusinessHours.isWithin(bhId, System.now());
            populateRemainingTime(wrapper, tracker.Target_End_Time__c, bhId);
        }
        return wrapper;
    }

    /**
     * @description Resuelve el calendario laboral aplicable usando el del rastreador o, en su defecto, el predeterminado de la organización.
     * @param trackerBhId Identificador de horario laboral asociado al rastreador (puede ser nulo).
     * @return Identificador efectivo de horario laboral o nulo si no existe predeterminado.
     */
    private static Id resolveBusinessHoursId(Id trackerBhId) {
        if (trackerBhId != null) {
            return trackerBhId;
        }
        List<BusinessHours> defaultBh = [SELECT Id FROM BusinessHours WHERE IsDefault = true WITH SYSTEM_MODE LIMIT 1];
        return defaultBh.isEmpty() ? null : defaultBh[0].Id;
    }

    /**
     * @description Calcula el tiempo restante o de retraso del rastreador relativo al horario laboral.
     * @param wrapper Instancia destino donde se persisten los milisegundos y el estado de vencimiento.
     * @param targetEnd Marca temporal objetivo del rastreador (puede ser nula).
     * @param bhId Identificador del calendario de horario laboral aplicable.
     */
    private static void populateRemainingTime(SlaTrackerWrapper wrapper, Datetime targetEnd, Id bhId) {
        if (targetEnd == null) {
            wrapper.remainingBusinessMs = 0;
            wrapper.isOverdue = false;
            return;
        }
        Datetime now = System.now();
        Boolean overdue = now >= targetEnd;
        Datetime fromDt = overdue ? targetEnd : now;
        Datetime toDt = overdue ? now : targetEnd;
        wrapper.remainingBusinessMs = BusinessHours.diff(bhId, fromDt, toDt);
        wrapper.isOverdue = overdue;
    }
}