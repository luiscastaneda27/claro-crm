public with sharing class CaseCatalogsService {

    public static string getMetadataFields(String recordId) {

        Case record = [SELECT Id, 
                               PVU_Level1__c,
                               PVU_Level2__c,
                               PVU_Level3__c 
                             FROM Case
                           WHERE Id = :recordId
                           WITH SECURITY_ENFORCED]; 
        system.debug('RECORD>>>>>>>'+record);          
        CaseCatalogUtils catalogUtils = new CaseCatalogUtils(new Set<String>{record.PVU_Level3__c},new Set<String>{record.PVU_Level2__c}, new List<String>{record.PVU_Level1__c});
        return catalogUtils.getDisplayFields(null,record.PVU_Level3__c,record.PVU_Level2__c, record.PVU_Level1__c);
    }    
}