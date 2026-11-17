/**
 * The FVU_CaseSelector class provides methods to retrieve case data from Salesforce.
 */
public with sharing class FVU_CaseSelector {

    public FVU_CaseSelector() {}

    // Retrieves case information for the Id Claro application based on the provided Order Id.
    public Case getCaseIdClaroData(String caseId) {
    List<Case> caseList = [
        SELECT Id, PVU_AuthorizedPersonData__c
        FROM Case
        WHERE Id = :caseId
        WITH USER_MODE
        LIMIT 1
    ];

    return (caseList.isEmpty()) ? null : caseList[0];
    } 
}