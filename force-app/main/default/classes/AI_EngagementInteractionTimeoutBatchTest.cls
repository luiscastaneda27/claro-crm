@isTest
private class AI_EngagementInteractionTimeoutBatchTest {

    private static final Integer TEST_TIMEOUT_MINUTES = 65;

    @TestSetup
    static void setupTestData() {
        EngagementInteraction eligibleInteraction = new EngagementInteraction(
            Status = 'Nuevo',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addDays(1),
            CommunicationChannel = AI_EngagementInteractionSelector.COMMUNICATION_CHANNEL
        );

        EngagementInteraction notEligibleInteraction = new EngagementInteraction(
            Status = 'Nuevo',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addDays(1),
            CommunicationChannel = AI_EngagementInteractionSelector.COMMUNICATION_CHANNEL
        );
        
        EngagementInteraction completedInteraction = new EngagementInteraction(
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addDays(1),
            CommunicationChannel = AI_EngagementInteractionSelector.COMMUNICATION_CHANNEL,
            Reason = 'Reason'
        );
        
        EngagementInteraction wrongChannelInteraction = new EngagementInteraction(
            Status = 'Nuevo',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addDays(1),
            CommunicationChannel = 'Chat web'
        );
        
        insert new List<EngagementInteraction>{ 
            eligibleInteraction, 
            notEligibleInteraction,
            completedInteraction, 
            wrongChannelInteraction 
        };
        
        completedInteraction.Status = AI_EngagementInteractionSelector.COMPLETED_STATUS;
        update completedInteraction;
        
        Test.setCreatedDate(eligibleInteraction.Id, Datetime.now().addMinutes(-150));
    }

    @isTest
    static void testBatchHappyPath() {
        EngagementInteraction eligibleInteraction = getEligibleInteraction();

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = createBatch();
        batch.execute(null, new List<EngagementInteraction>{ eligibleInteraction });
        Test.stopTest();

        System.assertEquals(1, batch.successCount, 'Should update one eligible interaction');
        
        EngagementInteraction updatedInteraction = [
            SELECT Status, Reason, AI_Cause__c, AI_Action__c
            FROM EngagementInteraction
            WHERE Id = :eligibleInteraction.Id
            WITH USER_MODE
        ];
        System.assertEquals(AI_EngagementInteractionSelector.COMPLETED_STATUS, updatedInteraction.Status);
        System.assertEquals('TestReason', updatedInteraction.Reason);
        System.assertEquals('TestCause', updatedInteraction.AI_Cause__c);
        System.assertEquals('TestAction', updatedInteraction.AI_Action__c);
    }

    @isTest
    static void testBatchEmptyScope() {
        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = createBatch();
        batch.execute(null, new List<EngagementInteraction>());
        Test.stopTest();

        System.assertEquals(0, batch.processedCount, 'Processed count should be zero');
        System.assertEquals(0, batch.successCount, 'Success count should be zero');
    }

    @isTest
    static void testBatchMultipleRecords() {
        List<EngagementInteraction> testInteractions = new List<EngagementInteraction>();
        
        for (Integer i = 0; i < 3; i++) {
            testInteractions.add(new EngagementInteraction(
                Status = 'Nuevo',
                StartDateTime = Datetime.now(),
                EndDateTime = Datetime.now().addDays(1),
                CommunicationChannel = AI_EngagementInteractionSelector.COMMUNICATION_CHANNEL
            ));
        }
        insert testInteractions;

        Test.startTest();
        AI_EngagementInteractionTimeoutBatch batch = createBatch();
        batch.execute(null, testInteractions);
        Test.stopTest();

        System.assertEquals(3, batch.processedCount, 'Should process three records');
        System.assertEquals(3, batch.successCount, 'Should successfully update three records');
    }

    @isTest
    static void testSchedulerExecute() {
        Test.startTest();
        AI_EngagementInteractionTimeoutScheduler scheduler = new AI_EngagementInteractionTimeoutScheduler();
        String cronExpression = '0 0 * * * ?';
        System.schedule('AI_EngagementInteractionTimeoutSchedulerTest', cronExpression, scheduler);
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id,
                   CronJobDetail.Name,
                   State
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'AI_EngagementInteractionTimeoutSchedulerTest'
            WITH USER_MODE
        ];

        Assert.isFalse(jobs.isEmpty(), 'Batch job should be scheduled');
    }

    @isTest
    static void testGetTimeoutMinutesFromConfigWithInvalidValue() {
        AI_EngagementInteractionTimeoutBatch batch = createBatch();
        batch.getTimeoutMinutesFromConfig('EngagementInteractionTimeoutInvalid');
        System.assertEquals(TEST_TIMEOUT_MINUTES, batch.timeoutMinutes, 'Should fallback to default timeout when config is invalid or missing');
    }

    private static AI_EngagementInteractionTimeoutBatch createBatch() {
        AI_EngagementInteractionSelector selector = new AI_EngagementInteractionSelector();
        return new AI_EngagementInteractionTimeoutBatch(
            selector, 
            TEST_TIMEOUT_MINUTES, 
            'TestCause', 
            'TestAction', 
            'TestReason'
        );
    }

    private static EngagementInteraction getEligibleInteraction() {
        return [
            SELECT Id, Status
            FROM EngagementInteraction
            WHERE CommunicationChannel = :AI_EngagementInteractionSelector.COMMUNICATION_CHANNEL
            AND Status != :AI_EngagementInteractionSelector.COMPLETED_STATUS
            WITH USER_MODE
            LIMIT 1
        ];
    }
}