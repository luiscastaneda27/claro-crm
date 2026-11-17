@isTest
private class FVU_UserHistoryTriggerTest {

    @isTest
    private static void updateTest() {
        FVU_User_History__c userRegistro = new FVU_User_History__c();
        userRegistro.Name = 'TEST'; 
        insert userRegistro;

        Test.startTest();
            userRegistro.Name = 'TEST UPDATE';
            try {
                update userRegistro; 
            } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    private static void deleteTest() {
        FVU_User_History__c userRegistro = new FVU_User_History__c();
        userRegistro.Name = 'TEST'; 
        insert userRegistro;

        Test.startTest();
            try {
                delete userRegistro; 
            } catch (Exception e) {}
        Test.stopTest();
    }
}