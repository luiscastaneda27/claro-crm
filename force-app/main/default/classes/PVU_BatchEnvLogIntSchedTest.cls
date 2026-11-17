@isTest
private class PVU_BatchEnvLogIntSchedTest {
    @isTest
    static void testExecute() {
        Test.startTest();
        new PVU_BatchEnviarLogIntegracionScheduler().execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void testSchedule() {
        String cron = '0 0 0 * * ?';
        Test.startTest();
        System.schedule('TestJob', cron, new PVU_BatchEnviarLogIntegracionScheduler());
        Test.stopTest();
    }
}