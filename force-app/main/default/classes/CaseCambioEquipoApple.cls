/*--------------------------------------------------------------------------

Company:        VASS
Description:    Pasa a En curso los casos abiertos de cambio por fabricante de equipo financiado Apple.
                Reemplaza la rama cambioEquipoApple > openCase > Actualizar_Caso de PVU_Case_Assignment.

History
<Date>                    <Description>                    <Version>
18-11-26                  Creación de la clase             inicial version

----------------------------------------------------------------------------*/
public without sharing class CaseCambioEquipoApple implements Queueable, Database.AllowsCallouts {

    @TestVisible private static final String LEVEL3_APPLE = 'Cambio por fabricante equipo financiado Apple';
    @TestVisible private static final String STATUS_ABIERTO = 'Abierto';
    @TestVisible private static final String STATUS_EN_CURSO = 'En curso';
    @TestVisible private static final String CODIGO_CAMBIO_EQUIPO = 'Cambio de equipo';
    @TestVisible private static final String SUB_ESTADO_VACIO = '-';

    private final Set<Id> caseIds;

    private CaseCambioEquipoApple(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {
        applyChange(caseIds);
    }

    /**
     * @description Punto de entrada del trigger (afterInsert y afterUpdate).
     * @param cases Casos del contexto del trigger (Trigger.new).
     */
    public static void handle(List<Case> cases) {
        Set<Id> caseIds = new Set<Id>();
        for (Case c : cases) {
            if (isPending(c)) {
                caseIds.add(c.Id);
            }
        }
        if (caseIds.isEmpty()) {
            return;
        }

        // En contextos asíncronos solo se puede encolar un job.
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new CaseCambioEquipoApple(caseIds));
        } else {
            applyChange(caseIds);
        }
    }

    // Vuelve a consultar porque el caso pudo cambiar entre el trigger y la ejecución del job.
    private static void applyChange(Set<Id> caseIds) {
        List<Case> updates = new List<Case>();
        for (Case c : [
            SELECT Id, Status, PVU_Level3__c, PVU_Sub_Estado__c, FIN_NumeroCredito__c, Asset.FIN_NumeroDeCredito__c
            FROM Case
            WHERE Id IN :caseIds
            WITH SYSTEM_MODE
        ]) {
            if (isPending(c)) {
                updates.add(buildUpdate(c));
            }
        }
        // Sin captura a propósito: si falla, el job queda Failed con el error en ExtendedStatus.
        update updates;
    }

    @TestVisible
    private static Boolean isPending(Case c) {
        return c.Status == STATUS_ABIERTO && c.PVU_Level3__c == LEVEL3_APPLE;
    }

    // Mismos valores que Actualizar_Caso y sus fórmulas f_numeroCredito y f_subEstadoApple.
    @TestVisible
    private static Case buildUpdate(Case c) {
        return new Case(
            Id = c.Id,
            Status = STATUS_EN_CURSO,
            PVU_Codigo_de_Cierre__c = CODIGO_CAMBIO_EQUIPO,
            PVU_Sub_Estado__c = SUB_ESTADO_VACIO,
            FIN_NumeroCredito__c = String.isBlank(c.FIN_NumeroCredito__c) ? c.Asset?.FIN_NumeroDeCredito__c : c.FIN_NumeroCredito__c
        );
    }
}
