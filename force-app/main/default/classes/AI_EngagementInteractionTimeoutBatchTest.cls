@IsTest
private class AI_EngagementInteractionTimeoutBatchTest {

    private static final String CHANNEL = 'AIDA';
    private static final String PENDING = 'En curso';
    private static final String COMPLETED = 'Completado';

    private static EngagementInteraction createInteraction(String externalId, String channel, String status) {
        EngagementInteraction ei = new EngagementInteraction(
            ExternalIdentifier = externalId,
            CommunicationChannel = channel,
            Status = status,
            StartDateTime = Datetime.now().addMinutes(-15),
            Type = 'Entrante'
        );
        insert ei;
        return ei;
    }

    private static AI_EngagementInteractionTimeoutBatch injectedBatch() {
        return new AI_EngagementInteractionTimeoutBatch(
            new AI_EngagementInteractionSelector(),
            60,
            'TestCause',
            'TestAction',
            'TestReason'
        );
    }

    // Simula respuestas de AiAgentSession: el batch consulta este DMO
    // directamente, sin usar el DMO personalizado de la version anterior.
    private class SessionStub extends SoqlStubProvider {
        private List<Map<String, Object>> values;
        public Integer calls = 0;

        SessionStub(List<Map<String, Object>> values) {
            this.values = values;
        }

        public override List<SObject> handleSoqlQuery(
            SObjectType targetType,
            String rawQuery,
            Map<String, Object> binds
        ) {
            calls++;
            System.assertEquals(ssot__AiAgentSession__dlm.SObjectType, targetType);
            List<SObject> rows = new List<SObject>();
            for (Map<String, Object> value : values) {
                rows.add(Test.createStubQueryRow(targetType, value));
            }
            return rows;
        }
    }

    @IsTest
    static void testSelectorAppliesChannelStatusAndTimeout() {
        EngagementInteraction eligible = createInteraction('UT-AIDA-ELIGIBLE', CHANNEL, PENDING);
        EngagementInteraction recent = createInteraction('UT-AIDA-RECENT', CHANNEL, PENDING);
        // En Hotfix, insertar directamente como Completado puede activar automatizaciones
        // que intenten actualizarlo y disparen PVU_NotUpdateAfterComplete.
        EngagementInteraction completedRecord = createInteraction('UT-AIDA-COMPLETE', CHANNEL, PENDING);
        completedRecord.Status = COMPLETED;
        completedRecord.Reason = 'Cierre de prueba unitaria';
        update completedRecord;
        EngagementInteraction otherChannel = createInteraction('UT-AIDA-OTHER', 'Chat web', PENDING);

        Datetime oldDate = Datetime.now().addMinutes(-130);
        Test.setCreatedDate(eligible.Id, oldDate);
        Test.setCreatedDate(completedRecord.Id, oldDate);
        Test.setCreatedDate(otherChannel.Id, oldDate);

        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        Test.startTest();
        Database.QueryLocatorIterator cursor = batch.start(null).iterator();
        Set<Id> found = new Set<Id>();
        while (cursor.hasNext()) {
            EngagementInteraction ei = (EngagementInteraction) cursor.next();
            found.add(ei.Id);
        }
        Test.stopTest();

        System.assertEquals(new Set<Id>{ eligible.Id }, found,
            'Solo debe seleccionarse AIDA pendiente con timeout cumplido.');
        System.assertEquals(60, batch.timeoutMinutes);
    }

    @IsTest
    static void testStartLoadsConfigAndFallback() {
        AI_EngagementInteractionTimeoutBatch batch =
            new AI_EngagementInteractionTimeoutBatch();

        Test.startTest();
        Database.QueryLocator locator = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, locator);
        System.assert(batch.timeoutMinutes > 0);
        System.assertEquals(60,
            batch.getTimeoutMinutesFromConfig('UT_CONFIG_INEXISTENTE'));
    }

    @IsTest
    static void testSessionNotYetAvailableDoesNotCloseInteraction() {
        EngagementInteraction ei = createInteraction('UT-AIDA-NO-SESSION', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>());
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ ei });
        Test.stopTest();

        EngagementInteraction result = [
            SELECT Status, AI_Cause__c, AI_Action__c, ConversationSummary__c
            FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(PENDING, result.Status,
            'Sin sesion ingerida, debe permanecer pendiente.');
        System.assertEquals(null, result.AI_Cause__c);
        System.assertEquals(null, result.ConversationSummary__c);
        System.assertEquals(1, stub.calls);
        System.assertEquals(1, batch.processedCount);
        System.assertEquals(0, batch.successCount);
    }

    @IsTest
    static void testSeveralSessionsNotAvailableRemainPending() {
        EngagementInteraction a = createInteraction('UT-AIDA-MULTI-1', CHANNEL, PENDING);
        EngagementInteraction b = createInteraction('UT-AIDA-MULTI-2', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>());
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ a, b });
        Test.stopTest();

        Set<Id> idsToCheck = new Set<Id>{ a.Id, b.Id };
        for (EngagementInteraction result : [
            SELECT Status, AI_Cause__c FROM EngagementInteraction
            WHERE Id IN :idsToCheck
        ]) {
            System.assertEquals(PENDING, result.Status);
            System.assertEquals(null, result.AI_Cause__c);
        }
        System.assertEquals(2, batch.processedCount);
        System.assertEquals(1, stub.calls);
    }

    @IsTest
    static void testInvalidSessionVariablesDoNotCloseInteraction() {
        EngagementInteraction ei = createInteraction('UT-AIDA-BAD-JSON', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'UT-INTERNAL-INVALID',
                'ssot__VariableText__c' => '{invalid json'
            },
            new Map<String, Object>{
                'ssot__Id__c' => 'UT-INTERNAL-OTHER',
                'ssot__VariableText__c' => '{"ConversationId":"OTHER-ID"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);

        Test.startTest();
        injectedBatch().execute(null, new List<EngagementInteraction>{ ei });
        Test.stopTest();

        EngagementInteraction result = [
            SELECT Status, AI_Cause__c FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(PENDING, result.Status);
        System.assertEquals(null, result.AI_Cause__c);
        System.assertEquals(1, stub.calls);
    }

    @IsTest
    static void testEmptyScopeAndMissingExternalId() {
        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>());
        batch.execute(null, null);
        batch.execute(null, new List<EngagementInteraction>{
            new EngagementInteraction(Status = PENDING, CommunicationChannel = CHANNEL)
        });
        Test.stopTest();

        System.assertEquals(1, batch.processedCount);
        System.assertEquals(0, batch.successCount);
        System.assertEquals(0, batch.failureCount);
    }

    @IsTest
    static void testCauseClassificationAndPriority() {
        System.assertEquals('ABANDONO CLIENTE',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa(null));
        System.assertEquals('ABANDONO CLIENTE',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('Hola [INFORM]'));
        System.assertEquals('TRANSFERENCIA A ASESOR',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[INFORM] [ESCALATE]'));
        System.assertEquals('SOLUCITUD DE TRANSFERENCIA',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[TRANSACTION]'));
        System.assertEquals('CUENTA PROPIA',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[DEFLECTION]'));
        System.assertEquals('FINALIZA CONVERSACION',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[ANSWER]'));
        System.assertEquals('FINALIZA CONVERSACION',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[ASWER]'));
        System.assertEquals('OTRA PERSONA',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[CUENTAS]'));
        System.assertEquals('CIERRE EXPLICITO',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('[CLOSE]'));
        System.assertEquals('SIN ETIQUETA RECONOCIDA',
            AI_EngagementInteractionTimeoutBatch.clasificarCausa('Sin marcador'));
    }

    @IsTest
    static void testSentimentNormalization() {
        System.assertEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento(null));
        System.assertEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento('SIN_INFORMACION_SUFICIENTE'));
        System.assertEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento('DESCONOCIDO'));
        System.assertNotEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento('POSITIVO'));
        System.assertNotEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento('NEGATIVE'));
        System.assertNotEquals(null,
            AI_EngagementInteractionTimeoutBatch.normalizarSentimiento('neutral'));
    }

    @IsTest
    static void testFinish() {
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        System.assertEquals(0, batch.processedCount);
    }

    // La segunda clase modificada: cubre execute() del Scheduler.
    // No insertamos candidatos al timeout: el batch encolado no necesita
    // realizar consultas reales a Data 360 durante esta prueba.
    @IsTest
    static void testSchedulerLaunchesBatch() {
        Test.startTest();
        new AI_EngagementInteractionTimeoutScheduler().execute(null);
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'AI_EngagementInteractionTimeoutBatch'
              AND JobType = 'BatchApex'
            LIMIT 10
        ];
        System.assert(!jobs.isEmpty(),
            'El scheduler debe encolar el batch de AIDA.');
    }

    // Datos simulados: el batch recibe el mismo historial ya reconstruido
    // que recibira en produccion, sin mockear SOQL for ni invocar Prompt Builder.
    private static void simularHistorial(String externalId, String pregunta,
        String respuesta, Datetime fecha) {
        AI_EngagementInteractionTimeoutBatch.historialesPrueba =
            new Map<String, List<Map<String, String>>>{
                externalId => new List<Map<String, String>>{
                    new Map<String, String>{
                        'MensajeCliente' => pregunta,
                        'RespuestaAgente' => respuesta
                    }
                }
            };
        AI_EngagementInteractionTimeoutBatch.ultimasRespuestasPrueba =
            new Map<String, String>{ externalId => respuesta };
        AI_EngagementInteractionTimeoutBatch.ultimasFechasPrueba =
            new Map<String, Datetime>{ externalId => fecha };
    }

    private static String analizar(String externalId, String sentimiento,
        String detalle, String motivo, String resumen) {
        return JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'ConversationId' => externalId,
                'Sentiment' => sentimiento,
                'SentimentDetail' => detalle,
                'Reason' => motivo,
                'ConversationSummary' => resumen
            }
        });
    }

    @IsTest
    static void testSessionWithoutMessagesIsAbandonment() {
        EngagementInteraction ei = createInteraction('UT-AIDA-EMPTY-MESSAGES', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'SESSION-EMPTY',
                'ssot__VariableText__c' => '{"ConversationId":"' + ei.ExternalIdentifier + '"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);
        AI_EngagementInteractionTimeoutBatch.historialesPrueba =
            new Map<String, List<Map<String, String>>>();

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ei});
        Test.stopTest();

        EngagementInteraction r = [
            SELECT Status, AI_Action__c, AI_Cause__c, Sentiment,
                   ConversationSummary__c, Reason
            FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(COMPLETED, r.Status);
        System.assertEquals('ABANDONO CLIENTE', r.AI_Cause__c);
        System.assertEquals('CIERRE DE CASO', r.AI_Action__c);
        System.assertEquals(null, r.Sentiment);
        System.assertEquals(null, r.ConversationSummary__c);
        System.assertEquals(1, batch.successCount);
    }

    @IsTest
    static void testPromptCompletesConversation() {
        EngagementInteraction ei = createInteraction('UT-AIDA-ANALYZED', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'SESSION-ANALYZED',
                'ssot__VariableText__c' => '{"ConversationId":"' + ei.ExternalIdentifier + '"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);
        Datetime whenMessage = Datetime.now().addMinutes(-5);
        simularHistorial(ei.ExternalIdentifier, 'Como descargo mi factura?',
            'Ve a la oficina virtual. [ANSWER]', whenMessage);
        AI_EngagementInteractionTimeoutBatch.respuestaPromptPrueba = analizar(
            ei.ExternalIdentifier, 'NEUTRO', 'Atencion adecuada',
            'Descarga de factura', 'Se explico como descargar la factura.');

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ei});
        Test.stopTest();

        EngagementInteraction r = [
            SELECT Status, AI_Action__c, AI_Cause__c, Sentiment,
                   AI_Sentiment_Detail__c, Reason, ConversationSummary__c, EndDateTime
            FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(COMPLETED, r.Status);
        System.assertEquals('FINALIZA CONVERSACION', r.AI_Cause__c);
        System.assertEquals('CIERRE DE CASO', r.AI_Action__c);
        System.assertEquals('Descarga de factura', r.Reason);
        System.assertNotEquals(null, r.Sentiment);
        System.assert(String.isNotBlank(r.ConversationSummary__c));
        System.assertNotEquals(null, r.EndDateTime);
        System.assertEquals(1, batch.successCount);
    }

    @IsTest
    static void testPromptReturnsNoAnalysisLeavesPending() {
        EngagementInteraction ei = createInteraction('UT-AIDA-MISSING-ANALYSIS', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'SESSION-MISSING-ANALYSIS',
                'ssot__VariableText__c' => '{"ConversationId":"' + ei.ExternalIdentifier + '"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);
        simularHistorial(ei.ExternalIdentifier, 'Hola', 'Hola [INFORM]', Datetime.now());
        AI_EngagementInteractionTimeoutBatch.respuestaPromptPrueba = '[]';

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ei});
        Test.stopTest();

        EngagementInteraction r = [
            SELECT Status, AI_Cause__c FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(PENDING, r.Status);
        System.assertEquals(null, r.AI_Cause__c);
        System.assertEquals(0, batch.successCount);
    }

    @IsTest
    static void testInvalidAnalysisLeavesPending() {
        EngagementInteraction ei = createInteraction('UT-AIDA-INVALID-ANALYSIS', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'SESSION-INVALID-ANALYSIS',
                'ssot__VariableText__c' => '{"ConversationId":"' + ei.ExternalIdentifier + '"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);
        simularHistorial(ei.ExternalIdentifier, 'Hola', 'Hola [INFORM]', Datetime.now());
        AI_EngagementInteractionTimeoutBatch.respuestaPromptPrueba = analizar(
            ei.ExternalIdentifier, 'NO_EXISTE', 'Detalle', 'Motivo', 'Resumen');

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ei});
        Test.stopTest();

        EngagementInteraction r = [
            SELECT Status, AI_Cause__c FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(PENDING, r.Status);
        System.assertEquals(null, r.AI_Cause__c);
        System.assertEquals(0, batch.successCount);
    }

    @IsTest
    static void testMalformedAnalysisLeavesPending() {
        EngagementInteraction ei = createInteraction('UT-AIDA-MALFORMED-ANALYSIS', CHANNEL, PENDING);
        SessionStub stub = new SessionStub(new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Id__c' => 'SESSION-MALFORMED-ANALYSIS',
                'ssot__VariableText__c' => '{"ConversationId":"' + ei.ExternalIdentifier + '"}'
            }
        });
        Test.createSoqlStub(ssot__AiAgentSession__dlm.SObjectType, stub);
        simularHistorial(ei.ExternalIdentifier, 'Hola', 'Hola [INFORM]', Datetime.now());
        AI_EngagementInteractionTimeoutBatch.respuestaPromptPrueba = '{no-es-json';

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = injectedBatch();
        batch.execute(null, new List<EngagementInteraction>{ei});
        Test.stopTest();

        EngagementInteraction r = [
            SELECT Status, AI_Cause__c FROM EngagementInteraction WHERE Id = :ei.Id
        ];
        System.assertEquals(PENDING, r.Status);
        System.assertEquals(null, r.AI_Cause__c);
        System.assertEquals(0, batch.successCount);
    }

}