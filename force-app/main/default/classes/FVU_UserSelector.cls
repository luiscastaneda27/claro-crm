/**
 * The FVU_UserSelector class provides methods to retrieve user data from Salesforce.
 */
public with sharing class FVU_UserSelector {
    
    public FVU_UserSelector() {}

    // Retrieves user information for the Id Claro application based on the provided User Id.
    public User getUserIdClaroData(String userId) {
        List<User> userList = [
            SELECT Id, PVU_Usuario_Red__c, FVU_BusinessChannel__c, FVU_CAV__c, FVU_IDZona__c, FVU_NITDelEmpleador__c, FVU_CodigoD__c
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        return (userList.isEmpty()) ? null : userList[0];
    }
}