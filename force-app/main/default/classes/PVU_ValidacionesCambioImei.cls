/*--------------------------------------------------------------------------
 Author: Eduardo Wentancur - wentancure@salesforce.com
 Company: Salesforce.com
 Description: Validaciones para imei financiados
 Code Coverage: 100%
 History
 <Date> 	<Author> 	<Description>		<Version>
 04-Sep-25 	Eduardo W 	validaciones imei 	1ra version
----------------------------------------------------------------------------*/

global with sharing class PVU_ValidacionesCambioImei implements vlocity_cmt.VlocityOpenInterface {
	
    // === Constantes ===
    private static final String NOTIF_DEV_NAME = 'CaseUpdate'; // DeveloperName del tipo de notificación
    
    /*
     * @description: Punto de entrada para invocaciones desde Vlocity/OmniStudio. Direcciona a los métodos soportados y maneja errores.
     * @param methodName: nombre del método a invocar.
     * @param inputMap: parámetros de entrada provenientes de OmniScript/Integration Procedure.
     * @param outMap: mapa de salida donde se colocan los resultados de la validación.
     * @param options: opciones adicionales o contexto de ejecución.
     * @return true si la invocación fue exitosa; false si el método no existe o ocurrió una excepción (outMap incluye detalle).
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        try {
            if(methodName.equals('validacionDevolucion')) {
                validacionDevolucion(inputMap, outMap, options);
            } else {
                result = false;
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> line: ' + e.getLineNumber());
            outMap.put('esValido', false);
            outMap.put('mensaje', 'Error en ejecución: ' + e.getMessage());
            result = false;
        }
        return result;
    }
    
    /*
     * @description: Validar reglas de devolución para IMEI financiado según estado de crédito y casos relacionados; si no es válido, actualizar el Case y notificar al owner.
     * @param inputMap: parámetros de entrada (estadoCredito/status, numeroCredito, imei, clienteId, caseId).
     * @param outMap: salida con llaves 'esValido' (Boolean) y 'mensaje' (String) describiendo el resultado de la validación.
     * @param options: opciones adicionales sin uso obligatorio en esta versión.
     * @return void. Los resultados se publican en outMap y, de corresponder, se actualiza el Case (PVU_Validacion_Imei__c = true) y se dispara una notificación.
     */ 
    global void validacionDevolucion(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        // Acepta tanto "estadoCredito" como "status"
        String estadoCredito = (String)inputMap.get('estadoCredito');
        if (estadoCredito == null) {
            estadoCredito = (String)inputMap.get('status');
        }

        String numeroCredito   = (String)inputMap.get('numeroCredito');
        String imei            = (String)inputMap.get('imei');
        Id clienteId           = (Id)inputMap.get('clienteId');
        Id caseId              = (Id)inputMap.get('caseId'); // Nuevo: recibimos el CaseId

        Boolean esValido = true;
        String mensaje   = 'Validación exitosa, puede continuar.';
        
        // 0. Validar que venga el status
        if (String.isBlank(estadoCredito)) {
            esValido = false;
            mensaje = 'No se envió status';
        }
        // 1. Validar estado del crédito
        else if (estadoCredito == 'X - FRAUDE' || estadoCredito == 'H - CREDITO CANCELADO') {
            esValido = false;
            mensaje = 'El crédito no es válido por su estado: ' + estadoCredito;
        }
        // 2. Casos de devolución abiertos/en curso
        else {
            List<PVU_Relacion_de_servicios_y_equipos__c> relAbiertos = [
                SELECT Id,
                       PVU_caso_relacionado__r.CaseNumber,
                       PVU_caso_relacionado__r.Status
                FROM PVU_Relacion_de_servicios_y_equipos__c
                WHERE PVU_Numero_de_Credito__c = :numeroCredito
                  AND PVU_caso_relacionado__r.PVU_Level1__c = 'Facturación y pagos'
                  AND PVU_caso_relacionado__r.PVU_Level2__c = 'Devolución de dinero'
                  AND PVU_caso_relacionado__r.Status IN ('Abierto','En curso')
                  WITH SECURITY_ENFORCED
            ];
            if (!relAbiertos.isEmpty()) {
                esValido = false;
                mensaje = 'Existe un caso de devolución abierto o en curso con causal "Cambio de equipo".';
            }
        }
        
        // 3. Casos de devolución cerrados con código "Dinero entregado"
        if (esValido) {
            List<PVU_Relacion_de_servicios_y_equipos__c> relCerrados = [
                SELECT Id,
                       PVU_caso_relacionado__r.CaseNumber,
                       PVU_caso_relacionado__r.Status,
                       PVU_caso_relacionado__r.PVU_Codigo_de_Cierre__c
                FROM PVU_Relacion_de_servicios_y_equipos__c
                WHERE PVU_Numero_de_Credito__c = :numeroCredito
                  AND PVU_caso_relacionado__r.Status = 'Cerrado'
                  AND PVU_caso_relacionado__r.PVU_Codigo_de_Cierre__c = 'Se realiza devolución'
                  WITH SECURITY_ENFORCED
            ];
            if (!relCerrados.isEmpty()) {
                esValido = false;
                mensaje = 'Ya existe un caso cerrado con código de cierre "Dinero entregado".';
            }
        }

        // Colocar la salida
        outMap.put('esValido', esValido);
        outMap.put('mensaje', mensaje);

        // Si es inválido y viene caseId → actualizar el Case
        if (!esValido && caseId != null) {
            try {
                enviarNotificacionValidacion(new Set<Id>{caseId});
                Case c = new Case(Id = caseId);
                c.PVU_Validacion_Imei__c = true;
                update as system c;
            } catch (Exception ex) {
                System.debug('Error actualizando Case: ' + ex.getMessage());
            }
        }
    }
   	/*
     * @description: Enviar Custom Notification al owner de cada Case indicado, apuntando como target al propio Case.
     * @param caseIds: conjunto de Ids de Case a notificar.
     * @return void. Se intentan enviar notificaciones por cada Case; cualquier error puntual se registra en debug y no detiene las demás.
    */
    public static void enviarNotificacionValidacion(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;

        // 1) Obtener casos con Owner
        List<Case> casos = [
            SELECT Id, LastModifiedBy.Id, CaseNumber, OwnerId, Owner.Name,LastModifiedBy.Name
            FROM Case
            WHERE Id = :caseIds WITH SECURITY_ENFORCED
        ];
        if (casos.isEmpty()) return;

        // 2) Obtener Id del tipo de notificación (cacheable en estática si deseas)
        Id notificationTypeId;
        try {
            CustomNotificationType t = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = :NOTIF_DEV_NAME
                WITH SYSTEM_MODE
                LIMIT 1 
            ];
            notificationTypeId = t.Id;
        } catch (Exception e) {
            System.debug('No se encontró CustomNotificationType con DeveloperName=' + NOTIF_DEV_NAME + '. Detalle: ' + e.getMessage());
            return;
        }

        // 3) Enviar una notificación por Case (respetando bulk)
        for (Case c : casos) {
            try {
                
                String nombreAsesor = (c.LastModifiedBy.Name != null) ? c.LastModifiedBy.Name : 'Asesor';
                String titulo = 'Caso requiere revisión';
                String cuerpo = 'Sr./Sra. ' + nombreAsesor + 
                                ', el caso #' + c.CaseNumber + 
                                ' requiere tu pronta revisión.\n' +
                                'Accede aquí para revisar los detalles y tomar acciones.';

                Messaging.CustomNotification n = new Messaging.CustomNotification();
                n.setTitle(titulo);
                n.setBody(cuerpo);
                n.setNotificationTypeId(notificationTypeId);
                n.setTargetId(c.Id);                 // al hacer clic → abre el Case
                // Opcional: indicar remitente
                // n.setSenderId(UserInfo.getUserId());
                n.send(new Set<String>{ String.valueOf(c.LastModifiedBy.Id) });

            } catch (Exception ex) {
                System.debug('Error enviando notificación para Case ' + c.LastModifiedBy.Id + ': ' + ex.getMessage());
            }
        }
    }
}