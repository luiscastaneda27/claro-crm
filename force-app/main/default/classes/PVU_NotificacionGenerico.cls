/*--------------------------------------------------------------------------
 Author: Eduardo Wentancur
 Company: Salesforce.com
 Description: Servicio genérico para enviar notificaciones
 Code Coverage: 100%
 History
 <Date> 	<Author> 	<Description>									<Version>
 15-Sep-25 	Eduardo W 	Servicio genérico para enviar notificaciones 	1ra version
----------------------------------------------------------------------------*/
global with sharing class PVU_NotificacionGenerico implements vlocity_cmt.VlocityOpenInterface {

    /**
     * Método principal invocado desde OmniStudio.
     */
    global Boolean invokeMethod(
        String methodName,
        Map<String,Object> inputMap,
        Map<String,Object> outMap,
        Map<String,Object> options
    ) {
        Boolean result = true;
        try {
            if (methodName == 'sendNotification') {
                sendNotification(inputMap, outMap);
            } else {
                outMap.put('success', false);
                outMap.put('message', 'Método no soportado: ' + methodName);
                result = false;
            }
        } catch (Exception e) {
            outMap.put('success', false);
            outMap.put('message', 'Error en ejecución: ' + e.getMessage());
            result = false;
        }
        return result;
    }

    /**
     * Envía una notificación a un usuario específico.
     *
     * @param inputMap Debe contener:
     *   - notificationDevName (String): DeveloperName del NotificationType
     *   - recordId (Id): Id del registro relacionado
     *   - userId (Id): Usuario destino
     *   - titulo (String, opcional)
     *   - cuerpo (String, opcional)
     */
    private void sendNotification(Map<String,Object> inputMap, Map<String,Object> outMap) {
        String notificationDevName = (String) inputMap.get('notificationDevName');
        String titulo = (String) inputMap.get('titulo');
        String cuerpo = (String) inputMap.get('cuerpo');
    
        // Normalizar recordId
        Id recordId;
        if (inputMap.containsKey('recordId') && inputMap.get('recordId') != null) {
            recordId = Id.valueOf(String.valueOf(inputMap.get('recordId')));
        }
    
        // Normalizar userId
        Id userId;
        if (inputMap.containsKey('userId') && inputMap.get('userId') != null) {
            userId = Id.valueOf(String.valueOf(inputMap.get('userId')));
        }
    
        if (String.isBlank(notificationDevName) || recordId == null || userId == null) {
            outMap.put('success', false);
            outMap.put('message', 'Parámetros inválidos. Se requiere notificationDevName, recordId y userId.');
            return;
        }
    
        try {
            Id notificationTypeId = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = :notificationDevName
                WITH SYSTEM_MODE
                LIMIT 1
            ].Id;
    
            Messaging.CustomNotification notificacion = new Messaging.CustomNotification();
            notificacion.setTitle(!String.isBlank(titulo) ? titulo : 'Notificación');
            notificacion.setBody(!String.isBlank(cuerpo) ? cuerpo : 'Tienes una nueva notificación.');
            notificacion.setNotificationTypeId(notificationTypeId);
            notificacion.setTargetId(recordId);
    
            notificacion.send(new Set<String>{ String.valueOf(userId) });
    
            outMap.put('success', true);
            outMap.put('message', 'Notificación enviada correctamente.');
        } catch (Exception e) {
            outMap.put('success', false);
            outMap.put('message', 'Error al enviar notificación: ' + e.getMessage());
        }
    }

}