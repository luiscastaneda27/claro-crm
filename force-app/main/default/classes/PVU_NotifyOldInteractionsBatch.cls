/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : Se utiliza para el envio de notificaciones de campana para las interacciones que tienen más de 2 horas de haber sido creadas y aún siguen en estado <> a completado.
 * @Cobertura de Código      : 100%
 * @Ultima modificación en   : 10-10-2024
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   10-08-2024   SALESFORCE   Initial Version
**/

public with sharing class PVU_NotifyOldInteractionsBatch implements Database.Batchable<SObject> {
    // Método de inicio: Query para obtener las interacciones con más de 2 horas de creadas
    public Database.QueryLocator start(Database.BatchableContext batchContext) {      
        return Database.getQueryLocator([
            SELECT Id, Name,InitiatingAttendeeId ,InitiatingAttendee.Name, OwnerId FROM EngagementInteraction WHERE                
                PVU_TimeOfCreation__c> = 2 AND Status <> 'Completado' AND (InitiatingAttendeeId != null OR InitiatingAttendeeId != '') and  Owner.IsActive = true
                WITH SYSTEM_MODE
        ]);
    } 

    // Método de ejecución: Se ejecuta en lotes
    /**
    * @description 
    * @author SALESFORCE | 10-07-2024 
    * @param Database.BatchableContext batchContext 
    * @param List<EngagementInteraction> scope
    **/
    public void execute(Database.BatchableContext batchContext, List<EngagementInteraction> scope) {
        CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'BulkNotifications' and CustomNotifTypeName ='BulkNotifications' WITH SECURITY_ENFORCED LIMIT 1];
        EmailTemplate template = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = 'PVU_TemplateInteraction' WITH SECURITY_ENFORCED LIMIT 1];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        for(EngagementInteraction interaction : scope) {
            System.debug('DEBUG::::ITERANDO LAS INTERACCIONES');
            String sObjectType = ((Id)interaction.InitiatingAttendeeId).getSobjectType().getDescribe().getName();
            if(sObjectType == 'Account'){
                sendNotification(interaction,type,template,notification);
            }            
        }
    }

    public void finish(Database.BatchableContext batchContext) {
        // Opcional: Lógica adicional para después de la ejecución del batch
        System.debug('Ejecución Batch finalizada correctamente.');

        
    }

    /**
    * @description 
    * @author SALESFORCE | 10-07-2024 
    * @param EngagementInteraction interactionId 
    **/
    private void sendNotification(EngagementInteraction interactionId,CustomNotificationType type,EmailTemplate template, Messaging.CustomNotification notification) {    
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.Id, UserInfo.getUserId(), interactionId.Id);
        notification.setTitle('Interacción Pendiente');
        notification.setBody(message.getPlainTextBody());
        notification.setTargetId(interactionId.Id);
        notification.setNotificationTypeId(type.id);
        notification.send(new Set<String>{interactionId.OwnerId});
    }

}