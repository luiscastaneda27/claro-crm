public with sharing class AI_EngagementInteractionTimeoutBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    
    private static final Integer DEFAULT_TIMEOUT_MINUTES = 60;
    private static final String TIMEOUT_MINUTES_CONFIG_NAME = 'EngagementInteractionTimeout';
    
    @TestVisible
    private Integer timeoutMinutes;
    @TestVisible
    private String cause;
    @TestVisible
    private String action;
    @TestVisible
    private String reason;
    
    @TestVisible
    private Integer processedCount = 0;
    @TestVisible
    private Integer successCount = 0;
    @TestVisible
    private Integer failureCount = 0;
    
    // Datos inyectados unicamente por las pruebas (nunca utilizados en produccion).
    @TestVisible private static Map<String, List<Map<String, String>>> historialesPrueba;
    @TestVisible private static Map<String, String> ultimasRespuestasPrueba;
    @TestVisible private static Map<String, Datetime> ultimasFechasPrueba;
    @TestVisible private static String respuestaPromptPrueba;

    private AI_EngagementInteractionSelector selector;
    
    public AI_EngagementInteractionTimeoutBatch() {
        this.selector = new AI_EngagementInteractionSelector();
    }
    
    @TestVisible
    private AI_EngagementInteractionTimeoutBatch(
        AI_EngagementInteractionSelector selector,
        Integer timeoutMinutes,
        String cause,
        String action,
        String reason
    ) {
        this.selector = selector;
        this.timeoutMinutes = timeoutMinutes;
        this.cause = cause;
        this.action = action;
        this.reason = reason;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        if (timeoutMinutes == null) {
            timeoutMinutes = getTimeoutMinutesFromConfig(
                AI_EngagementInteractionTimeoutBatch.TIMEOUT_MINUTES_CONFIG_NAME
            );
        }
        
        if (cause == null) {
            cause = getConfigStringValue(
                'EngagementInteractionTimeoutCause'
            );
        }
        
        if (action == null) {
            action = getConfigStringValue(
                'EngagementInteractionTimeoutAction'
            );
        }
        
        if (reason == null) {
            reason = getConfigStringValue(
                'EngagementInteractionTimeoutReason'
            );
        }
        
        return selector.getRecordsForTimeout(timeoutMinutes);
    }
    
    public void execute(
        Database.BatchableContext context,
        List<EngagementInteraction> scope
    ) {
        if (scope == null || scope.isEmpty()) return;
        processedCount += scope.size();

        Map<String, EngagementInteraction> registrosPorConversacion =
            new Map<String, EngagementInteraction>();
        Set<String> idsConversacion = new Set<String>();
        for (EngagementInteraction ei : scope) {
            if (String.isNotBlank(ei.ExternalIdentifier)) {
                idsConversacion.add(ei.ExternalIdentifier);
                registrosPorConversacion.put(ei.ExternalIdentifier, ei);
            } else {
                System.debug(LoggingLevel.WARN,
                    'AIDA: EngagementInteraction sin ExternalIdentifier: ' + ei.Id);
            }
        }
        if (idsConversacion.isEmpty()) return;

        // Recuperar directamente los mensajes estandar de Agentforce.
        // No depende del Data Transform ni de ACTION_STEP.
        // Buscar el valor EXACTO de ConversationId dentro de VariableText.
        List<String> condiciones = new List<String>();
        for (String idConversacion : idsConversacion) {
            condiciones.add(
                'ssot__VariableText__c LIKE \'%"ConversationId":"' +
                String.escapeSingleQuotes(idConversacion) + '"%\''
            );
        }
        String sqlSesiones =
            'SELECT ssot__Id__c, ssot__VariableText__c ' +
            'FROM ssot__AiAgentSession__dlm WHERE ' +
            String.join(condiciones, ' OR ');

        Map<String, String> conversacionPorSesion = new Map<String, String>();
        Set<String> sesionesEncontradas = new Set<String>();
        // Separar la consulta del recorrido para permitir mocks SOQL en tests.
        List<SObject> sesionesDmo = Database.query(sqlSesiones);
        for (SObject sesion : sesionesDmo) {
            String idInterno = (String) sesion.get('ssot__Id__c');
            String variablesTexto = (String) sesion.get('ssot__VariableText__c');
            if (String.isBlank(idInterno) || String.isBlank(variablesTexto)) continue;
            try {
                Map<String, Object> variables = (Map<String, Object>)
                    JSON.deserializeUntyped(variablesTexto);
                String idExterno = (String) variables.get('ConversationId');
                if (idsConversacion.contains(idExterno)) {
                    conversacionPorSesion.put(idInterno, idExterno);
                    sesionesEncontradas.add(idExterno);
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN,
                    'AIDA: no se pudo interpretar VariableText para la sesion ' +
                    idInterno + ': ' + ex.getMessage());
            }
        }

        Map<String, List<Map<String, String>>> historiales =
            new Map<String, List<Map<String, String>>>();
        Map<String, String> preguntaPendiente = new Map<String, String>();
        Map<String, String> ultimaRespuestaPorConversacion = new Map<String, String>();
        Map<String, Datetime> ultimaFechaPorConversacion = new Map<String, Datetime>();

        if (Test.isRunningTest() && historialesPrueba != null) {
            // Solo tests: evita SOQL for de DMO, no admitido por SoqlStubProvider.
            historiales.putAll(historialesPrueba);
            if (ultimasRespuestasPrueba != null)
                ultimaRespuestaPorConversacion.putAll(ultimasRespuestasPrueba);
            if (ultimasFechasPrueba != null)
                ultimaFechaPorConversacion.putAll(ultimasFechasPrueba);
        } else if (!conversacionPorSesion.isEmpty()) {
            Set<String> idsSesiones = conversacionPorSesion.keySet();
            // SOQL for: procesa los mensajes en bloques sin asignar
            // todo el resultado a una lista (apto para volumen mayor).
            for (ssot__AiAgentInteractionMessage__dlm mensaje : [
                SELECT ssot__AiAgentSessionId__c,
                       ssot__AiAgentInteractionMessageType__c,
                       ssot__ContentText__c,
                       ssot__MessageSentTimestamp__c
                FROM ssot__AiAgentInteractionMessage__dlm
                WHERE ssot__AiAgentSessionId__c IN :idsSesiones
                ORDER BY ssot__MessageSentTimestamp__c ASC
            ]) {
                String idExterno = conversacionPorSesion.get(
                    mensaje.ssot__AiAgentSessionId__c);
                if (String.isBlank(idExterno)) continue;
                String tipo = mensaje.ssot__AiAgentInteractionMessageType__c;
                String texto = mensaje.ssot__ContentText__c;
                if (tipo != 'Input' && tipo != 'Output') continue;
                if (!historiales.containsKey(idExterno)) {
                    historiales.put(idExterno, new List<Map<String, String>>());
                }
                if (tipo == 'Input') {
                    // Preservar mensajes consecutivos del cliente antes de la respuesta.
                    String anterior = preguntaPendiente.get(idExterno);
                    preguntaPendiente.put(idExterno,
                        String.isBlank(anterior) ? texto : anterior + '\n' + texto);
                } else {
                    historiales.get(idExterno).add(new Map<String, String>{
                        'MensajeCliente' => preguntaPendiente.get(idExterno),
                        'RespuestaAgente' => texto
                    });
                    preguntaPendiente.remove(idExterno);
                    if (String.isNotBlank(texto)) {
                        ultimaRespuestaPorConversacion.put(idExterno, texto);
                        ultimaFechaPorConversacion.put(idExterno,
                            fechaMensaje(mensaje.get('ssot__MessageSentTimestamp__c')));
                    }
                }
            }
            // Conservar una ultima pregunta si todavia no tiene respuesta del agente.
            for (String idExterno : preguntaPendiente.keySet()) {
                historiales.get(idExterno).add(new Map<String, String>{
                    'MensajeCliente' => preguntaPendiente.get(idExterno),
                    'RespuestaAgente' => ''
                });
            }
        }

        Map<Id, EngagementInteraction> pendientes =
            new Map<Id, EngagementInteraction>();
        List<Map<String, Object>> conversacionesJson =
            new List<Map<String, Object>>();

        for (String idConversacion : idsConversacion) {
            EngagementInteraction original = registrosPorConversacion.get(idConversacion);
            List<Map<String, String>> historial = historiales.get(idConversacion);

            if (historial == null || historial.isEmpty()) {
                if (!sesionesEncontradas.contains(idConversacion)) {
                    // Si la propia sesion aun no esta en Data 360, no cerrarla:
                    // podria ser retraso de ingesta, no ausencia de mensajes.
                    System.debug(LoggingLevel.WARN,
                        'AIDA: sesion no disponible en Data 360: ' + idConversacion);
                    continue;
                }
                // Sesion existente sin mensajes despues del timeout: abandono.
                EngagementInteraction parche = nuevoCierre(original.Id, 'ABANDONO CLIENTE');
                parche.AI_Sentiment_Detail__c =
                    'No hay informacion suficiente para evaluar la satisfaccion.';
                parche.Reason = 'No se registraron interacciones para analizar';
                pendientes.put(original.Id, parche);
                continue;
            }

            conversacionesJson.add(new Map<String, Object>{
                'ConversationId' => idConversacion,
                'Interacciones' => historial
            });
        }

        if (!conversacionesJson.isEmpty()) {
            try {
                String textoGenerado;
                if (Test.isRunningTest() && respuestaPromptPrueba != null) {
                    textoGenerado = respuestaPromptPrueba;
                } else {
                    ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
                        new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                    promptInput.additionalConfig =
                        new ConnectApi.EinsteinLlmAdditionalConfigInput();
                    promptInput.additionalConfig.applicationName =
                        'PromptBuilderPreview';
                    promptInput.isPreview = false;

                    ConnectApi.WrappedValue inputConversaciones =
                        new ConnectApi.WrappedValue();
                    inputConversaciones.value = conversacionesJson;
                    promptInput.inputParams = new Map<String, ConnectApi.WrappedValue>{
                        'Input:conversations' => inputConversaciones
                    };

                    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation salida =
                        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                            'Identificar_conversacion', promptInput);
                    if (salida == null || salida.generations == null ||
                        salida.generations.isEmpty() ||
                        String.isBlank(salida.generations[0].text)) {
                        throw new AidaRecoveryException('El prompt devolvió una respuesta vacía');
                    }

                    textoGenerado = salida.generations[0].text;
                }
                List<Object> resultados = (List<Object>) JSON.deserializeUntyped(textoGenerado);
                for (Object item : resultados) {
                    Map<String, Object> resultado = (Map<String, Object>) item;
                    String idConversacion = (String) resultado.get('ConversationId');
                    if (String.isBlank(idConversacion) ||
                        !registrosPorConversacion.containsKey(idConversacion) ||
                        !historiales.containsKey(idConversacion)) continue;

                    String sentimiento = (String) resultado.get('Sentiment');
                    String detalle = (String) resultado.get('SentimentDetail');
                    String motivo = (String) resultado.get('Reason');
                    String memoria = (String) resultado.get('ConversationSummary');
                    if (String.isBlank(sentimiento) || String.isBlank(detalle) ||
                        String.isBlank(motivo) || String.isBlank(memoria)) {
                        System.debug(LoggingLevel.WARN,
                            'AIDA: respuesta incompleta del prompt: ' + idConversacion);
                        continue; // Sigue pendiente para nuevo intento.
                    }

                    String valorSentimiento = normalizarSentimiento(sentimiento);
                    if (valorSentimiento == null &&
                        sentimiento.trim().toUpperCase() != 'SIN_INFORMACION_SUFICIENTE') {
                        System.debug(LoggingLevel.WARN,
                            'AIDA: Sentiment no permitido: ' + sentimiento);
                        continue;
                    }

                    String ultimaRespuesta =
                        ultimaRespuestaPorConversacion.get(idConversacion);
                    Datetime ultimaFecha =
                        ultimaFechaPorConversacion.get(idConversacion);

                    EngagementInteraction original =
                        registrosPorConversacion.get(idConversacion);
                    EngagementInteraction parche = nuevoCierre(original.Id,
                        clasificarCausa(ultimaRespuesta));
                    parche.Sentiment = valorSentimiento;
                    parche.AI_Sentiment_Detail__c = limitar(detalle,
                        EngagementInteraction.AI_Sentiment_Detail__c.getDescribe().getLength());
                    parche.Reason = limitar(motivo,
                        EngagementInteraction.Reason.getDescribe().getLength());
                    parche.ConversationSummary__c = limitar(memoria, 3000);
                    if (ultimaFecha != null) parche.EndDateTime = ultimaFecha;
                    pendientes.put(original.Id, parche);
                }
            } catch (Exception ex) {
                // Las conversaciones con mensajes permanecen pendientes. De este
                // modo, un error de Prompt Builder no genera cierres incompletos.
                System.debug(LoggingLevel.ERROR,
                    'AIDA: error analizando conversaciones: ' + ex.getMessage());
            }
        }

        if (pendientes.isEmpty()) return;
        // No sobrescribir registros que el agente haya completado entretanto.
        Set<Id> idsActualizar = pendientes.keySet();
        Map<Id, EngagementInteraction> estadoActual = new Map<Id, EngagementInteraction>([
            SELECT Id, Status FROM EngagementInteraction WHERE Id IN :idsActualizar
        ]);
        List<EngagementInteraction> paraActualizar = new List<EngagementInteraction>();
        for (Id idRegistro : pendientes.keySet()) {
            if (estadoActual.containsKey(idRegistro) &&
                estadoActual.get(idRegistro).Status != 'Completado') {
                paraActualizar.add(pendientes.get(idRegistro));
            }
        }
        if (paraActualizar.isEmpty()) return;
        Database.SaveResult[] resultadosDml = Database.update(paraActualizar, false);
        for (Integer i = 0; i < resultadosDml.size(); i++) {
            if (resultadosDml[i].isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                for (Database.Error err : resultadosDml[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'AIDA: Error DML ' + paraActualizar[i].Id + ': ' + err.getMessage());
                }
            }
        }
    }

    private static EngagementInteraction nuevoCierre(Id registroId, String causa) {
        EngagementInteraction parche = new EngagementInteraction(Id = registroId);
        parche.Status = 'Completado';
        parche.AI_Action__c = 'CIERRE DE CASO';
        parche.AI_Cause__c = causa;
        return parche;
    }

    @TestVisible
    private static String clasificarCausa(String ultimaRespuesta) {
        if (String.isBlank(ultimaRespuesta)) return 'ABANDONO CLIENTE';
        String texto = ultimaRespuesta.toUpperCase();
        // Los marcadores terminales prevalecen sobre INFORM.
        if (texto.contains('[ESCALATE]')) return 'TRANSFERENCIA A ASESOR';
        if (texto.contains('[TRANSACTION]')) return 'SOLUCITUD DE TRANSFERENCIA';
        if (texto.contains('[DEFLECTION]')) return 'CUENTA PROPIA';
        if (texto.contains('[ANSWER]') || texto.contains('[ASWER]'))
            return 'FINALIZA CONVERSACION';
        if (texto.contains('[CUENTAS]')) return 'OTRA PERSONA';
        if (texto.contains('[CLOSE]')) return 'CIERRE EXPLICITO';
        if (texto.contains('[INFORM]')) return 'ABANDONO CLIENTE';
        return 'SIN ETIQUETA RECONOCIDA';
    }

    @TestVisible
    private static String normalizarSentimiento(String texto) {
        if (String.isBlank(texto)) return null;
        String canonico = texto.trim().toUpperCase();
        if (canonico == 'SIN_INFORMACION_SUFICIENTE') return null;
        String castellano;
        String ingles;
        if (canonico == 'POSITIVO' || canonico == 'POSITIVE') {
            castellano = 'POSITIVO'; ingles = 'POSITIVE';
        } else if (canonico == 'NEGATIVO' || canonico == 'NEGATIVE') {
            castellano = 'NEGATIVO'; ingles = 'NEGATIVE';
        } else if (canonico == 'NEUTRO' || canonico == 'NEUTRAL') {
            castellano = 'NEUTRO'; ingles = 'NEUTRAL';
        } else return null;
        // Respeta el valor API configurado en el campo standard Sentiment.
        for (Schema.PicklistEntry opcion :
            EngagementInteraction.Sentiment.getDescribe().getPicklistValues()) {
            if (!opcion.isActive()) continue;
            String valor = opcion.getValue().toUpperCase();
            String etiqueta = opcion.getLabel().toUpperCase();
            if (valor == castellano || etiqueta == castellano ||
                valor == ingles || etiqueta == ingles) {
                return opcion.getValue();
            }
        }
        return null;
    }

    private static Datetime fechaMensaje(Object valor) {
        if (valor == null) return null;
        if (valor instanceof Datetime) return (Datetime) valor;
        if (valor instanceof String) {
            String fecha = (String) valor;
            if (fecha.length() >= 19 &&
                (fecha.endsWith('+00:00') || fecha.endsWith('Z'))) {
                try {
                    return Datetime.valueOfGmt(fecha.substring(0, 19).replace('T', ' '));
                } catch (Exception err) {
                    System.debug(LoggingLevel.WARN,
                        'AIDA: no pudo interpretar fecha ' + fecha);
                }
            }
        }
        return null;
    }

    private static String limitar(String valor, Integer maximo) {
        if (valor == null || maximo == null || maximo <= 0 ||
            valor.length() <= maximo) return valor;
        return valor.substring(0, maximo);
    }

    private class AidaRecoveryException extends Exception {}

    public void finish(
        Database.BatchableContext context
    ) {
        System.debug(
            'AI_EngagementInteractionTimeoutBatch completed.'
        );
        
        System.debug(
            'Total Processed: ' +
            processedCount
        );
        
        System.debug(
            'Successful Updates: ' +
            successCount
        );
        
        System.debug(
            'Failed Updates: ' +
            failureCount
        );
    }
    
    @TestVisible
    private Integer getTimeoutMinutesFromConfig(
        String configName
    ) {
        String configValue =
            getConfigStringValue(
                configName
            );
        
        try {
            Integer parsedValue =
                Integer.valueOf(
                    configValue
                );
            
            return parsedValue > 0
                ? parsedValue
                : DEFAULT_TIMEOUT_MINUTES;
                
        } catch (Exception e) {
            return DEFAULT_TIMEOUT_MINUTES;
        }
    }
    
    private String getConfigStringValue(
        String developerName
    ) {
        AI_Agentforce_Configs__mdt config =
            AI_Agentforce_Configs__mdt.getInstance(
                developerName
            );
        
        String value =
            config?.AI_Value__c;
        
        return String.isNotBlank(value)
            ? value.trim()
            : '';
    }
}