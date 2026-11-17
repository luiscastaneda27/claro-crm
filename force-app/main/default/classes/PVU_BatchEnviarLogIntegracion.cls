/*--------------------------------------------------------------------------
 Author: Eduardo Wentancur -
 Company: Salesforce.com
 Description: Batch Enviar correos con los Logs Integracion
 Code Coverage: 100%
 History
 <Date>     <Author>    <Description>                <Version>
 11-Sep-25  Eduardo W   envío de correo logs         1ra versión
 12-Sep-25  ChatGPT      Ajuste split correos TextArea long
----------------------------------------------------------------------------*/

global with sharing class PVU_BatchEnviarLogIntegracion 
    implements Database.Batchable<SObject>, Database.Stateful {

    private String bodyEmail = '';

    // ========================
    // INICIO DEL BATCH
    // ========================
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, PVU_Descripcion__c
            FROM PVU_LogIntegracion__c
            WHERE CreatedDate = TODAY 
              AND Name = 'PFARelaUpdateImei'
            WITH SECURITY_ENFORCED
        ]);
    }

    // ========================
    // EJECUCIÓN POR LOTE
    // ========================
    global void execute(Database.BatchableContext bc, List<PVU_LogIntegracion__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return; // nada que procesar
        }
        for (PVU_LogIntegracion__c log : scope) {
            bodyEmail += formatDescripcion(log.PVU_Descripcion__c) + 
                         '\n\n----------------------------------\n\n';
        }
    }

    // ========================
    // FINALIZACIÓN
    // ========================
    global void finish(Database.BatchableContext bc) {
        if (String.isNotBlank(bodyEmail)) {
            // Obtener correos desde Custom Metadata
                List<Correos_logs__mdt> metas = [
                SELECT PVU_Correos_electronicos__c 
                FROM Correos_logs__mdt
                WITH SECURITY_ENFORCED
            ];
            
            List<String> destinatarios = new List<String>();
            
            for (Correos_logs__mdt m : metas) {
                if (String.isNotBlank(m.PVU_Correos_electronicos__c)) {
                    List<String> correos = m.PVU_Correos_electronicos__c.split('[,;\\n]+');
                    for (String c : correos) {
                        if (String.isNotBlank(c)) {
                            destinatarios.add(c.trim());
                        }
                    }
                }
            }


            if (!destinatarios.isEmpty()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(destinatarios);
                mail.setSubject(
                    'Logs de Integración PFARelaUpdateImei - ' + Date.today().format()
                );
                mail.setPlainTextBody(
                    'Se listan los registros que fallaron en la integración PFARelaUpdateImei hoy:\n\n' 
                    + bodyEmail
                );

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } else {
                System.debug('No se encontraron correos válidos en Correos_logs__mdt');
            }
        }
    }

    private String formatDescripcion(String raw) {
    if (String.isBlank(raw)) return '';
    
    String resultado = '';
    
    // separar los bloques por { y }
    List<String> bloques = raw.split('}\\s*\\{');
    
    for (String bloque : bloques) {
        String clean = bloque.replace('{','').replace('}','');
        if (String.isBlank(clean)) continue;
        
        List<String> pares = clean.split(',');
        for (String p : pares) {
            String linea = p.trim();
            if (String.isBlank(linea)) continue;
            
            // puede venir como "campo":"valor"
            if (linea.contains('":"')) {
                List<String> kv = linea.split('":"');
                if (kv.size() == 2) {
                    resultado += kv[0].replace('"','').trim() + ': ' + kv[1].replace('"','').trim() + '\n';
                } else {
                    resultado += linea + '\n';
                }
            }
            // puede venir como campo=valor
            else if (linea.contains('=')) {
                List<String> kv = linea.split('=');
                if (kv.size() == 2) {
                    resultado += kv[0].trim() + ': ' + kv[1].trim() + '\n';
                } else {
                    resultado += linea + '\n';
                }
            } else {
                resultado += linea + '\n';
            }
        }
        resultado += '\n----------------------------------\n\n';
    }
    
    return resultado;
}

}