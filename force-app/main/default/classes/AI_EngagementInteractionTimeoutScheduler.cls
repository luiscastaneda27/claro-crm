global class AI_EngagementInteractionTimeoutScheduler implements Schedulable {
    
    private final Integer DEFAULT_BATCH_SIZE = 200;
    private Integer batchSize;
    
    public AI_EngagementInteractionTimeoutScheduler() {
        this.batchSize = DEFAULT_BATCH_SIZE;
    }
    
    global void execute(SchedulableContext context) {
        AI_EngagementInteractionTimeoutBatch batch = new AI_EngagementInteractionTimeoutBatch();
        Database.executeBatch(batch, batchSize); 
    }
}