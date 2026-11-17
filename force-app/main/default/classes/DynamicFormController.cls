public with sharing class DynamicFormController {
    
    @AuraEnabled(cacheable=true)
    public static String getMetadataField(String recordId) {
    return CaseCatalogsService.getMetadataFields(recordId);
       
    }

    @AuraEnabled(cacheable=true)
    public static string getChangeOwnerFields(String level3Field,String subCauseField, String areaField) {

        CaseCatalogUtils catalogUtils = new CaseCatalogUtils(new Set<String>{level3Field},new Set<String>{subCauseField}, new List<String>{areaField});
        return catalogUtils.getDisplayFields(null,level3Field, subCauseField, areaField);
        
}
}