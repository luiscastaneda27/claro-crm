public with sharing class CaseCatalogUtils {
    
    private Map<String, Map<String, PVU_CaseCatagorySpecification__c>> catalogsByAreaByCause;
    private Map<Id, Entitlement> entitlementsByAccount;
    
    /**
     * Constructor that will initialize all CaseCatalogs and Entitlements to be potentially used
     */
    public CaseCatalogUtils(Set<String> level3,Set<String> subCauses, List<String> areas) {

        catalogsByAreaByCause = new Map<String, Map<String, PVU_CaseCatagorySpecification__c>>();
        system.debug('catalogsByAreaByCause>>>>>>>'+catalogsByAreaByCause);
        entitlementsByAccount = new Map<Id, Entitlement>();
        getCatalogsAndEntitlements(level3,subCauses, areas);
    }
    
    /**
     * Method that retrieves all fields to be shown, defined by a Catalog.
     * It can be specified to only bring required fields
     */
    public String getDisplayFields(Boolean required, String level3,  String subCause, String area) {
        
        // If required is null, the method is going to retrieve all fields.
        // Otherwise, the method will retrieve fields that matches with the required criteria.        
        PVU_CaseCatagorySpecification__c caseCatalog = getCaseCatalog(level3,subCause, area);
        
        List<PVU_CaseCatagoryFields__c> catalogFields = caseCatalog.CamposCatalogo__r;
        
        //If only required are needed, filtering of the list
        if (required != null && required) {

            List<PVU_CaseCatagoryFields__c> requiredCatalogFields = new List<PVU_CaseCatagoryFields__c>();
            for (PVU_CaseCatagoryFields__c catalogField : catalogFields) {

                if (catalogField.PVU_Required__c) {

                    requiredCatalogFields.add(catalogField);
                }
            }
            catalogFields = requiredCatalogFields;
        }
        return JSON.serialize(catalogFields);
    }
	

    /**
     * Method that returns the Case Catalog that verifies a given subcause and area
     * 
     * @param subCause: the subcause to check
     * @param area: the area to check
     */
    public PVU_CaseCatagorySpecification__c getCaseCatalog(String level3,String subCause, String area) {
		//system.debug(catalogsByAreaByCause.get(subCause).get(area));
        return catalogsByAreaByCause.get(subCause) != null ? catalogsByAreaByCause.get(subCause).get(area) : null;
    }

    /**
     * Method that returns the Entitlement related to a given Account
     * 
     * @param accountId: the account's Id
     * @param area: the area to check
     */
   /* public Entitlement getEntitlement(Id accountId) {

        return entitlementsByAccount.get(accountId);
    }

    /**
     * Method that queries for all Catalogs that have a Subcause and an Area found in a list of Subcauses and Areas.
     * Also, it queries all Entitlements related to the Accounts that are linked to the Catalogs found
     * 
     * @param catalogsByAreByCause: container param to return all found catalogs. Catalogs are indexed by Subcause and then by Area
     * @param entitlementsByAccount: container to return the Entitlements. Entitlements are indexed by Account Id
     * @param subCauses: set of subcauses to use on the catalog query
     * @param areas: set of areas to use on the catalog query
     */
    private void getCatalogsAndEntitlements(Set<String> level3,Set<String> subCauses, List<String> areas) {
        
        //Getting all CaseCatalogs that match agains a Subcase and Area found
        List<Id> accountIds = new List<Id>();
        String areasParameter = ObjectUtils.getQueryParameterArrayFromList(areas);

        String query = 'SELECT Id, PVU_Level1__c, PVU_Level2__c, PVU_Level3__c, PVU_ServiceClient__c, OwnerId, Owner.Name, ';

        // NUEVO: agregamos PVU_FilterField__c y PVU_FilterValue__c al subquery
        query += '(SELECT PVU_FieldName__c, PVU_FieldLabel__c, PVU_Required__c, PVU_ReadOnly__c, PVU_Secuencia__c, ' +
                 '        PVU_FilterField__c, PVU_FilterValue__c ' +
                 ' FROM CamposCatalogo__r ORDER BY PVU_Secuencia__c ASC )';

        query +=  ' FROM PVU_CaseCatagorySpecification__c WHERE PVU_Level2__c IN :subCauses AND PVU_Level3__c IN :level3 ';
        if (!String.isBlank(areasParameter)) {
            query +=  'AND PVU_Level1__c INCLUDES ' + areasParameter;
        }
        
        for (PVU_CaseCatagorySpecification__c caseCatalog : Database.query(query)) {            
            //Initializing variable for the subcause if needed, and storing catalog under its subcause.area
            if (catalogsByAreaByCause.get(caseCatalog.PVU_Level2__c) == null) {
                catalogsByAreaByCause.put(caseCatalog.PVU_Level2__c, new Map<String, PVU_CaseCatagorySpecification__c>());               
            }
            for(string areaString: caseCatalog.PVU_Level1__c.split(';')){
                catalogsByAreaByCause.get(caseCatalog.PVU_Level2__c).put(areaString, caseCatalog);                
            }
            //catalogsByAreaByCause.get(caseCatalog.PVU_Level2__c).put(caseCatalog.Level2__c, caseCatalog);
           // accountIds.add(caseCatalog.PVU_ServiceClient__c);
        }
        //Getting all Entitlements represented by previously obtained Case Catalogs (using related Account)
       /* for (Entitlement ent : [SELECT Id, AccountId FROM Entitlement WHERE AccountId IN :accountIds]) {
            entitlementsByAccount.put(ent.AccountId, ent);
        }*/
    }
}