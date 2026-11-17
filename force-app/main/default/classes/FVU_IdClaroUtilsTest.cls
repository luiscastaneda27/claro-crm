@isTest
public class FVU_IdClaroUtilsTest {

    @isTest
    static void isValidSalesforceIdTest() {
        // Test a valid Salesforce ID
        Boolean isValid = FVU_IdClaroUtils.isValidSalesforceId('0012K00001ABCDe');
        System.assertEquals(true, isValid);

        // Test an invalid Salesforce ID
        isValid = FVU_IdClaroUtils.isValidSalesforceId('123456');
        System.assertEquals(false, isValid);
    }

    @isTest
    static void isValidAccountIdTest() {
        // Test a valid Account ID
        Boolean isValid = FVU_IdClaroUtils.isValidAccountId('0012K00001ABCDe');
        System.assertEquals(true, isValid);

        // Test an invalid Account ID
        isValid = FVU_IdClaroUtils.isValidAccountId('0052K00001ABCDe'); // Starts with '005', not '001'
        System.assertEquals(false, isValid);
    }

    @isTest
    static void isValidUserIdTest() {
        // Test a valid User ID
        Boolean isValid = FVU_IdClaroUtils.isValidUserId('0052K00001ABCDe');
        System.assertEquals(true, isValid);

        // Test an invalid User ID
        isValid = FVU_IdClaroUtils.isValidUserId('0012K00001ABCDe'); // Starts with '001', not '005'
        System.assertEquals(false, isValid);
    }

    @isTest
    static void isValidOrderIdTest() {
        // Test a valid Order ID
        Boolean isValid = FVU_IdClaroUtils.isValidOrderId('8012K00001ABCDe');
        System.assertEquals(true, isValid);

        // Test an invalid User ID
        isValid = FVU_IdClaroUtils.isValidOrderId('0012K00001ABCDe'); // Starts with '001', not '801'
        System.assertEquals(false, isValid);
    }

    @isTest
    static void isValidCaseIdTest() {
        // Test a valid Case ID
        Boolean isValid = FVU_IdClaroUtils.isValidCaseId('5002K00001ABCDe');
        System.assertEquals(true, isValid);

        // Test an invalid Case ID
        isValid = FVU_IdClaroUtils.isValidCaseId('0012K00001ABCDe'); // Starts with '001', not '500'
        System.assertEquals(false, isValid);
    }
}