@isTest
public class FVU_CaseSelectorTest {
    
    @isTest
    static void testGetCaseIdClaroData() {

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Case testCase = new Case(
            AccountId = testAccount.Id
        );
        insert testCase;

        FVU_CaseSelector caseSelector = new FVU_CaseSelector();

        Case resultCase = caseSelector.getCaseIdClaroData(testCase.Id);
        System.assertEquals(testCase.Id, resultCase.Id);
    }
}