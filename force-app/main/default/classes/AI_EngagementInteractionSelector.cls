public with sharing class AI_EngagementInteractionSelector {
    public static final String COMPLETED_STATUS = 'Completado';
    public static final String COMMUNICATION_CHANNEL = 'AIDA';

    /**
     * Retrieves EngagementInteraction records that should be timed out.
     * @param minutes Number of minutes from current time to filter records
     * @return Database.QueryLocator for batch processing
     */
    public Database.QueryLocator getRecordsForTimeout(Integer minutes) {
        Datetime cutoffTime = Datetime.now().addMinutes(-minutes);
        
        return Database.getQueryLocator([
            SELECT Id, Status
            FROM EngagementInteraction
            WHERE Status != :COMPLETED_STATUS
            AND CreatedDate <= :cutoffTime
            AND CommunicationChannel = :COMMUNICATION_CHANNEL
            WITH USER_MODE
        ]);
    }
}