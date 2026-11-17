/**
 * The FVU_CityMetadataSelector class provides methods to retrieve FVU_CityMetadata__mdt data from Salesforce.
 */
public with sharing class FVU_CityMetadataSelector {

    public FVU_CityMetadataSelector() { }

    // Retrieves city information based on a provided expeditionSite, that must match the name of the "Centro Poblado"
    public FVU_CityMetadata__mdt getCityMetadata(String expeditionSite) {
        List<FVU_CityMetadata__mdt> cityMetadataList = [
            SELECT FVU_DaneMunicipality__c, FVU_DaneDepartment__c 
            FROM FVU_CityMetadata__mdt 
            WHERE FVU_CentroPobladoName__c = :expeditionSite
            WITH USER_MODE LIMIT 1  
        ];

        return (cityMetadataList.isEmpty()) ? null : cityMetadataList[0];
    }
}