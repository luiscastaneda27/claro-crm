/**
 * @description Handler class for Case trigger events.
 * Manages afterInsert and afterUpdate events to track case time metrics.
 * Extends the TriggerHandler framework for consistent trigger processing.
 */
public with sharing class CaseTriggerHandler extends TriggerHandler {
    
    protected override void afterInsert() {
        procesarControlTiempos();
        CaseCambioEquipoApple.handle((List<Case>) Trigger.new);
    }

    protected override void afterUpdate() {
        procesarControlTiempos();
        CaseCambioEquipoApple.handle((List<Case>) Trigger.new);
    }

    /**
     * @description Encapsula el llamado a la lógica de control de tiempos.
     * Realiza el cast seguro de las variables de contexto del trigger.
     */
    private void procesarControlTiempos() {
        List<Case> registrosNuevos = (List<Case>) Trigger.new;
        Map<Id, Case> registrosAntiguosMap = (Map<Id, Case>) Trigger.oldMap;
        
        CaseTimeTrackerHandler.handleCaseChanges(registrosNuevos, registrosAntiguosMap);
    }
}