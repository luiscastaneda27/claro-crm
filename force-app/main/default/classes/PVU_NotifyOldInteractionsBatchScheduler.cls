/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : Para el llamado del batch PVU_NotifyOldInteractionsBatch
 * @Cobertura de Código      : 100%
 * @Ultima modificación en   : 10-10-2024
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   10-08-2024   SALESFORCE   Initial Version
**/
public with sharing class PVU_NotifyOldInteractionsBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sC){
        Database.executeBatch(new PVU_NotifyOldInteractionsBatch());
    }
}