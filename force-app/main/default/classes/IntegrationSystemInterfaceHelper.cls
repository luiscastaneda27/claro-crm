public with sharing class IntegrationSystemInterfaceHelper {
    
    public static final String TECH_ATTR_CATEGORY_NAME = 'TechAttributesDecompose';
	
    // Invoke DR
    public static List<Map <String, Object>> callDrExtract(Map<String, Object> inputParams, String drName){
        
        //Call DR
        vlocity_cmt.DRProcessResult result = vlocity_cmt.DRGlobal.process(inputParams, drName);    
        List<Map <String, Object>> transformResult = (List<Map <String, Object>>) result.toJsonList();
        System.debug('=====check output==='+ transformResult);
        return transformResult;
    }
    
    public static String getTechAttributeCategoryCode(){
        return [SELECT vlocity_cmt__Code__c FROM vlocity_cmt__AttributeCategory__c WHERE Name =: TECH_ATTR_CATEGORY_NAME WITH SECURITY_ENFORCED].vlocity_cmt__Code__c ;
    }
    
}