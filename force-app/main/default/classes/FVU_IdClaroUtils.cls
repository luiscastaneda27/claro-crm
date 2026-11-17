public with sharing class FVU_IdClaroUtils {
 
    // Checks if a given string is a valid Salesforce record ID.
    public static Boolean isValidSalesforceId(String recordId){
        // Check if the recordId matches the pattern for Salesforce record IDs
        if (Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(recordId).matches()){
            return true;
        }
        return false;
    }

    // Checks if a given string is a valid Salesforce Account ID.
    public static Boolean isValidAccountId(String recordId){
        // Check if the recordId is a valid Salesforce ID and starts with '001' (Account ID)
        if (FVU_IdClaroUtils.isValidSalesforceId(recordId) && recordId.startsWith('001')){
            return true;
        }
        return false;
    }

    // Checks if a given string is a valid Salesforce User ID.
    public static Boolean isValidUserId(String recordId){
        // Check if the recordId is a valid Salesforce ID and starts with '005' (User ID)
        if (FVU_IdClaroUtils.isValidSalesforceId(recordId) && recordId.startsWith('005')){
            return true;
        }
        return false;
    }

    // Checks if a given string is a valid Salesforce Order ID.
    public static Boolean isValidOrderId(String recordId){
        // Check if the recordId is a valid Salesforce ID and starts with '801' (Order ID)
        if (FVU_IdClaroUtils.isValidSalesforceId(recordId) && recordId.startsWith('801')){
            return true;
        }
        return false;
    }

    // Checks if a given string is a valid Salesforce Case ID.
    public static Boolean isValidCaseId(String recordId){
        // Check if the recordId is a valid Salesforce ID and starts with '500' (Case ID)
        if (FVU_IdClaroUtils.isValidSalesforceId(recordId) && recordId.startsWith('500')){
            return true;
        }
        return false;
    }
}