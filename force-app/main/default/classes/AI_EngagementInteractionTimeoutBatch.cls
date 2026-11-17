public with sharing class AI_EngagementInteractionTimeoutBatch implements Database.Batchable<SObject>, Database.Stateful {

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
            timeoutMinutes = getTimeoutMinutesFromConfig(AI_EngagementInteractionTimeoutBatch.TIMEOUT_MINUTES_CONFIG_NAME);
        }
        if (cause == null) {
            cause = getConfigStringValue('EngagementInteractionTimeoutCause');
        }
        if (action == null) {
            action = getConfigStringValue('EngagementInteractionTimeoutAction');
        }
        if (reason == null) {
            reason = getConfigStringValue('EngagementInteractionTimeoutReason');
        }
        return selector.getRecordsForTimeout(timeoutMinutes);
    }

    public void execute(Database.BatchableContext context, List<EngagementInteraction> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (EngagementInteraction record : scope) {
            record.Status = AI_EngagementInteractionSelector.COMPLETED_STATUS;
            record.Reason = reason;
            record.AI_Cause__c = cause;
            record.AI_Action__c = action;
            record.EndDateTime = Datetime.now();
        }

        Database.SaveResult[] results = Database.update(scope, false, AccessLevel.USER_MODE);
        
        processedCount += scope.size();
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error updating EngagementInteraction ' + result.getId() + ': ' + error.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('AI_EngagementInteractionTimeoutBatch completed.');
        System.debug('Total Processed: ' + processedCount);
        System.debug('Successful Updates: ' + successCount);
        System.debug('Failed Updates: ' + failureCount);
    }

    @TestVisible
    private Integer getTimeoutMinutesFromConfig(String configName) {
        String configValue = getConfigStringValue(configName);
        try {
            Integer parsedValue = Integer.valueOf(configValue);
            return parsedValue > 0 ? parsedValue : DEFAULT_TIMEOUT_MINUTES;
        } catch (Exception e) {
            return DEFAULT_TIMEOUT_MINUTES;
        }
    }

    private String getConfigStringValue(String developerName) {
        AI_Agentforce_Configs__mdt config = AI_Agentforce_Configs__mdt.getInstance(developerName);
        String value = config?.AI_Value__c;
        return String.isNotBlank(value) ? value.trim() : '';
    }
}