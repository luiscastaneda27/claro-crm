/**
 * The FVU_IdClaroMetadataSelector class provides methods to retrieve FVU_IdClaroMetadata__mdt data from Salesforce.
 */
public with sharing class FVU_IdClaroMetadataSelector {
    public FVU_IdClaroMetadataSelector() {}

    // Retrieves metadata based on the provided application and channel
    public FVU_IdClaroMetadata__mdt getIdClaroMetadata(String application, String channel) {
        List<FVU_IdClaroMetadata__mdt> metadataList = [
            SELECT FVU_AccessKey__c, FVU_AccountType__c, FVU_Application__c, FVU_ChanelTypeCode__c, FVU_Company__c, FVU_MethodSendOK__c, FVU_MethodSendReturn__c, FVU_UrlOK__c, FVU_UrlReturn__c
            FROM FVU_IdClaroMetadata__mdt
            WHERE FVU_Application__c = :application AND FVU_ChanelTypeCode__c = :channel
            LIMIT 1
        ];

        return (metadataList.isEmpty()) ? null : metadataList[0];
    }
}