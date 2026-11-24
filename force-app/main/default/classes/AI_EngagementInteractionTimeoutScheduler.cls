global class AI_EngagementInteractionTimeoutScheduler
    implements Schedulable {

    private static final Integer DEFAULT_BATCH_SIZE = 10;

    global void execute(SchedulableContext context) {

        Integer batchSize = DEFAULT_BATCH_SIZE;

        AI_Agentforce_Configs__mdt config =
            AI_Agentforce_Configs__mdt.getInstance(
                'EngagementInteractionBatchSize'
            );

        if (config != null &&
            String.isNotBlank(config.AI_Value__c)) {

            try {
                Integer value = Integer.valueOf(
                    config.AI_Value__c.trim()
                );

                if (value > 0) {
                    batchSize = value;
                }
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.WARN,
                    'AIDA: Batch size invalido. Usando valor por defecto.'
                );
            }
        }

        // Recomendado: 10-20 registros por lote.
        Database.executeBatch(
            new AI_EngagementInteractionTimeoutBatch(),
            batchSize
        );
    }
}