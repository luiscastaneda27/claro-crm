/**----------------------------------------------------------------------------------------------------------------------------------------------
Author:         Fabio Farath
Company:        Salesforce.com
Description:    
Code Coverage:  90%
History
<Date MM-dd-YY>   @version     <Author>             <Description>
2025-10-03         1.0.0   	  Fabio Farath          	Initial
2025-10-16         1.0.1      Hever Salas         Fix to handle BOOLEAN fields in search
--------------------------------------------------------------------------------------------------------------------------------------------------*/

public with sharing class OM_TechnicalCatalogController {
    public class SObjectSearchResult {
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;

        public SObjectSearchResult(List<SObject> recs, Integer total, Integer page, Integer size) {
            records = recs;
            totalRecords = total;
            pageNumber = page;
            pageSize = size;
        }
    }

    @AuraEnabled(cacheable=true)
    public static SObjectSearchResult fetchRecords(String objectApiName, String fieldsCsv, String searchTerm, String searchFields, String filter, Integer pageSize, Integer pageNumber) {
        String safeObjectName = String.isBlank(objectApiName) ? 'Product2' : sanitizeObjectName(objectApiName);
        String safeFields = buildSelectFields(fieldsCsv, safeObjectName);
        String safeSearchFields = String.isBlank(searchFields) ? 'Name' : searchFields;
        String safeFilter = String.isBlank(filter) ? '' : filter;
        Integer safePageSize = (pageSize == null || pageSize <= 0) ? 10 : Math.min(pageSize, 200);
        Integer safePageNumber = (pageNumber == null || pageNumber <= 0) ? 1 : pageNumber;
        Integer offsetRows = (safePageNumber - 1) * safePageSize;
        Integer limitRows = safePageSize;

        // ensure Id is always selected
        String selectFields = ensureCoreFields(safeFields, safeObjectName);

        List<SObject> rows = new List<SObject>();
        Integer totalRecords = 0;
        
        Schema.SObjectType sType = Schema.getGlobalDescribe().get(safeObjectName);
		Schema.DescribeSObjectResult d = sType != null ? sType.getDescribe() : null;

        String whereClause = buildWhereClause(searchTerm, safeSearchFields, safeFilter, d);
        
        String countQuery = 'SELECT COUNT() FROM ' + safeObjectName + whereClause;
        totalRecords = (Integer)Database.countQuery(countQuery);

        if (totalRecords > 0) {
            String soql = 'SELECT ' + selectFields + ' FROM ' + safeObjectName + whereClause + ' ORDER BY Name NULLS LAST LIMIT :limitRows OFFSET :offsetRows';
            rows = Database.query(soql);
        }
        
        return new SObjectSearchResult(rows, totalRecords, safePageNumber, safePageSize);
    }

    public class RecordDetailsResult {
        @AuraEnabled public String Name;
        @AuraEnabled public String Description;
        @AuraEnabled public String ServiceId;
        @AuraEnabled public List<AttributeDetail> TechnicalDetails;
        @AuraEnabled public List<AttributeDetail> ProcessDetails;
    }

    public class AttributeDetail {
        @AuraEnabled public String key;
        @AuraEnabled public String value;
        
        public AttributeDetail(String k, String v) {
            this.key = k;
            this.value = v;
        }
    }

    @AuraEnabled(cacheable=true)
    public static RecordDetailsResult fetchRecordDetails(String recordId, String objectApiName) {
        String safeObjectName = String.isBlank(objectApiName) ? 'Product2' : sanitizeObjectName(objectApiName);
        
        // Build SOQL to fetch Name, Description, and AttributeDefaultValues fields
        String soql = 'SELECT Id, Name';
        
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(safeObjectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Add Description field if it exists
        if (fieldMap.containsKey('Description')) {
            soql += ', Description';
        }
        
        // Add vlocity AttributeDefaultValues field if it exists
        if (fieldMap.containsKey('vlocity_cmt__AttributeDefaultValues__c')) {
            soql += ', vlocity_cmt__AttributeDefaultValues__c';
        }
        
        soql += ' FROM ' + safeObjectName + ' WHERE Id = :recordId LIMIT 1';
        
        List<SObject> records = Database.query(soql);
        if (records.isEmpty()) {
            return null;
        }
        
        SObject record = records[0];
        RecordDetailsResult result = new RecordDetailsResult();
        result.Name = (String)record.get('Name');
        result.Description = (String)record.get('Description');
        result.TechnicalDetails = new List<AttributeDetail>();
        result.ProcessDetails = new List<AttributeDetail>();
        
        // Parse JSON from vlocity_cmt__AttributeDefaultValues__c
        String attributeJson = (String)record.get('vlocity_cmt__AttributeDefaultValues__c');
        if (String.isNotBlank(attributeJson)) {
            try {
                Map<String, Object> jsonData = (Map<String, Object>)JSON.deserializeUntyped(attributeJson);
                
                // Extract Service ID from B2C-ATTR-SERV-ID
                if (jsonData.containsKey('B2C-ATTR-SERV-ID')) {
                    result.ServiceId = String.valueOf(jsonData.get('B2C-ATTR-SERV-ID'));
                }
                
                // Extract Technical Details from B2C-ATTR-TECH-DET (nested JSON string)
                if (jsonData.containsKey('B2C-ATTR-TECH-DET') && jsonData.get('B2C-ATTR-TECH-DET') != null) {
                    String techDetailsJson = String.valueOf(jsonData.get('B2C-ATTR-TECH-DET'));
                    if (String.isNotBlank(techDetailsJson) && techDetailsJson != 'null') {
                        try {
                            Map<String, Object> techDetails = (Map<String, Object>)JSON.deserializeUntyped(techDetailsJson);
                            for (String key : techDetails.keySet()) {
                                String value = String.valueOf(techDetails.get(key));
                                result.TechnicalDetails.add(new AttributeDetail(key, value));
                            }
                        } catch (Exception e) {
                            System.debug('Error parsing technical details JSON: ' + e.getMessage());
                        }
                    }
                }
                
                // Extract Process Details from B2C-ATTR-PRC-DET -> exceptions (nested JSON string)
                if (jsonData.containsKey('B2C-ATTR-PRC-DET') && jsonData.get('B2C-ATTR-PRC-DET') != null) {
                    String processDetailsJson = String.valueOf(jsonData.get('B2C-ATTR-PRC-DET'));
                    if (String.isNotBlank(processDetailsJson) && processDetailsJson != 'null') {
                        try {
                            Map<String, Object> processDetails = (Map<String, Object>)JSON.deserializeUntyped(processDetailsJson);
                            // Go one level deeper into the "exceptions" array
                            if (processDetails.containsKey('exceptions') && processDetails.get('exceptions') instanceof List<Object>) {
                                List<Object> exceptions = (List<Object>)processDetails.get('exceptions');
                                for (Object exceptionItem : exceptions) {
                                    if (exceptionItem instanceof Map<String, Object>) {
                                        Map<String, Object> exceptionMap = (Map<String, Object>)exceptionItem;
                                        for (String key : exceptionMap.keySet()) {
                                            String value = String.valueOf(exceptionMap.get(key));
                                            result.ProcessDetails.add(new AttributeDetail(key, value));
                                        }
                                    }
                                }
                            }
                        } catch (Exception e) {
                            System.debug('Error parsing process details JSON: ' + e.getMessage());
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug('Error parsing AttributeDefaultValues JSON: ' + e.getMessage());
            }
        }
        
        return result;
    }

    private static String sanitizeObjectName(String objectName) {
        // Only allow alphanumeric characters and underscores, must end with __c for custom objects or be a standard object
        if (Pattern.compile('^[A-Za-z][A-Za-z0-9_]*(__c)?$').matcher(objectName).matches()) {
            return objectName;
        }
        return 'Product2'; // fallback to safe default
    }

    private static String ensureCoreFields(String selectFields, String objectName) {
        Set<String> includeFields = new Set<String>{ 'Id' };
        // Add Name if the object has it
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        if (objDescribe.fields.getMap().containsKey('Name')) {
            includeFields.add('Name');
        }
        
        List<String> existing = new List<String>();
        for (String token : selectFields.split(',')) {
            if (String.isBlank(token)) continue;
            existing.add(token.trim().toLowerCase());
        }
        for (String f : includeFields) {
            if (!existing.contains(f.toLowerCase())) {
                selectFields += ', ' + f;
            }
        }
        return selectFields;
    }

    private static String buildSelectFields(String fieldsCsv, String objectName) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<String> raw = (fieldsCsv == null) ? new List<String>() : fieldsCsv.split(',');
        Set<String> clean = new Set<String>();
        for (String f : raw) {
            if (String.isBlank(f)) continue;
            String trimmed = f.trim();
            // allow only word chars and underscores; no relationship paths or functions
            if (Pattern.compile('^[A-Za-z][A-Za-z0-9_]*(__c)?$').matcher(trimmed).matches() && fieldMap.containsKey(trimmed)) {
                clean.add(trimmed);
            }
        }
        if (!clean.contains('Id')) clean.add('Id');
        return String.join(new List<String>(clean), ', ');
    }

    private static String buildWhereClause(String searchTerm, String searchFields, String filter, Schema.DescribeSObjectResult d) {
        String whereClause = '';
        List<String> conditions = new List<String>();
        
        // Add filter condition
        if (!String.isBlank(filter)) {
            conditions.add('(' + filter + ')');
        }
        
        // Add search condition
        String term = (searchTerm == null) ? '' : searchTerm.trim();
        if (term != '' && d != null) {
            List<String> searchConditions = new List<String>();
            String likePattern = '%' + String.escapeSingleQuotes(term) + '%';
            List<String> fields = searchFields.split(',');
            for (String field : fields) {
                String trimmedField = field.trim();
                String dataType = String.valueOf(d.fields.getMap().get(trimmedField).getDescribe().getType());
                if (Pattern.compile('^[A-Za-z][A-Za-z0-9_]*(__c)?$').matcher(trimmedField).matches()) {
                    if(dataType != 'BOOLEAN'){
                        searchConditions.add(trimmedField + ' LIKE \'' + likePattern + '\'');
                    }else{
                        if(term.containsIgnoreCase('true') || term.containsIgnoreCase('false')){
                            searchConditions.add(trimmedField + ' = ' + term);
                        }
                    }
                }
            }
            if (!searchConditions.isEmpty()) {
                conditions.add('(' + String.join(searchConditions, ' OR ') + ')');
            }
        }
        
        if (!conditions.isEmpty()) {
            whereClause = ' WHERE ' + String.join(conditions, ' AND ');
        }
        return whereClause;
    }

    @AuraEnabled(cacheable=true)
    public static ProductSpecificationResult fetchProductSpecifications(String productCode) {
        ProductSpecificationResult result = new ProductSpecificationResult();
        result.ProductCode = productCode;
        result.Specifications = new List<SpecificationDetail>();
        
        try {
            // Query OMEricsonProductToCFSSpec custom metadata where TechnicalProduct = productCode
            List<OMEricsonProductToCFSSpec__mdt> specs = [
                SELECT CFSSpecification__c, TechnicalProduct__c 
                FROM OMEricsonProductToCFSSpec__mdt 
                WHERE TechnicalProduct__c = :productCode
                WITH SECURITY_ENFORCED
                LIMIT 100
            ];
            
            for (OMEricsonProductToCFSSpec__mdt spec : specs) {
                result.Specifications.add(new SpecificationDetail(
                    spec.CFSSpecification__c, 
                    spec.TechnicalProduct__c
                ));
            }
            
        } catch (Exception e) {
            System.debug('Error fetching product specifications: ' + e.getMessage());
        }
        
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static ProductPriceConfigResult fetchProductPriceConfig(String productCode) {
        ProductPriceConfigResult result = new ProductPriceConfigResult();
        result.ProductCode = productCode;
        result.PriceConfigurations = new List<PriceConfigDetail>();
        
        try {
            // Query OMEricsonChargeTypeSpec custom metadata where TechnicalProduct = productCode
            List<OMEricsonChargeTypeSpec__mdt> priceConfigs = [
                SELECT ChargeType__c, PopId__c, Price__c, TechnicalProduct__c 
                FROM OMEricsonChargeTypeSpec__mdt 
                WHERE TechnicalProduct__c = :productCode
                WITH SECURITY_ENFORCED
                LIMIT 100
            ];
            
            for (OMEricsonChargeTypeSpec__mdt config : priceConfigs) {
                result.PriceConfigurations.add(new PriceConfigDetail(
                    config.ChargeType__c, 
                    config.PopId__c,
                    String.valueOf(config.Price__c),
                    config.TechnicalProduct__c
                ));
            }
            
        } catch (Exception e) {
            System.debug('Error fetching product price configuration: ' + e.getMessage());
        }
        
        return result;
    }

    // Inner classes for Product Specification
    public class ProductSpecificationResult {
        @AuraEnabled public String ProductCode { get; set; }
        @AuraEnabled public List<SpecificationDetail> Specifications { get; set; }
    }
    
    public class SpecificationDetail {
        @AuraEnabled public String CFSSpecification { get; set; }
        @AuraEnabled public String TechnicalProduct { get; set; }
        
        public SpecificationDetail(String cfsSpec, String techProduct) {
            this.CFSSpecification = cfsSpec;
            this.TechnicalProduct = techProduct;
        }
    }

    // Inner classes for Product Price Configuration
    public class ProductPriceConfigResult {
        @AuraEnabled public String ProductCode { get; set; }
        @AuraEnabled public List<PriceConfigDetail> PriceConfigurations { get; set; }
    }
    
    public class PriceConfigDetail {
        @AuraEnabled public String ChargeType { get; set; }
        @AuraEnabled public String PopId { get; set; }
        @AuraEnabled public String Price { get; set; }
        @AuraEnabled public String TechnicalProduct { get; set; }
        
        public PriceConfigDetail(String chargeType, String popId, String price, String techProduct) {
            this.ChargeType = chargeType;
            this.PopId = popId;
            this.Price = price; // Keep as String to preserve original values like field references
            this.TechnicalProduct = techProduct;
        }
    }

    @AuraEnabled(cacheable=true)
    public static AdditionalInformationResult fetchAdditionalInformation(String productCode) {
        AdditionalInformationResult result = new AdditionalInformationResult();
        result.ProductCode = productCode;
        result.AdditionalInfo = new List<AdditionalInfoDetail>();
        
        try {
            // Query vlocity_cmt__ProductChildItem__c to get the JSON attribute
            List<vlocity_cmt__ProductChildItem__c> childItems = [
                SELECT vlocity_cmt__ChildProductId__r.vlocity_cmt__JSONAttribute__c
                FROM vlocity_cmt__ProductChildItem__c 
                WHERE vlocity_cmt__ChildProductId__r.vlocity_cmt__SpecificationSubType__c = 'Simple' 
                AND vlocity_cmt__ParentProductId__r.ProductCode = :productCode
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!childItems.isEmpty() && childItems[0].vlocity_cmt__ChildProductId__r.vlocity_cmt__JSONAttribute__c != null) {
                String jsonAttribute = childItems[0].vlocity_cmt__ChildProductId__r.vlocity_cmt__JSONAttribute__c;
                
                // Parse the JSON
                Map<String, Object> jsonData = (Map<String, Object>)JSON.deserializeUntyped(jsonAttribute);
                
                // Extract data from B2C-ATTRCAT-SVC-ADC-DETAILS and B2C-ATTRCAT-CAT-GRL-DETAILS
                List<String> targetCategories = new List<String>{
                    'B2C-ATTRCAT-SVC-ADC-DETAILS', 
                    'B2C-ATTRCAT-CAT-GRL-DETAILS'
                };
                
                for (String categoryCode : targetCategories) {
                    if (jsonData.containsKey(categoryCode) && jsonData.get(categoryCode) instanceof List<Object>) {
                        List<Object> categoryItems = (List<Object>)jsonData.get(categoryCode);
                        
                        for (Object item : categoryItems) {
                            if (item instanceof Map<String, Object>) {
                                Map<String, Object> itemMap = (Map<String, Object>)item;
                                
                                String grupo = (String)itemMap.get('categoryname__c');
                                String atributo = (String)itemMap.get('attributedisplayname__c');
                                String valor = (String)itemMap.get('value__c');
                                
                                // Only add if all required fields are present
                                if (String.isNotBlank(grupo) && String.isNotBlank(atributo)) {
                                    result.AdditionalInfo.add(new AdditionalInfoDetail(grupo, atributo, valor));
                                }
                            }
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error fetching additional information: ' + e.getMessage());
        }
        
        return result;
    }

    // Inner classes for Additional Information
    public class AdditionalInformationResult {
        @AuraEnabled public String ProductCode { get; set; }
        @AuraEnabled public List<AdditionalInfoDetail> AdditionalInfo { get; set; }
    }
    
    public class AdditionalInfoDetail {
        @AuraEnabled public String Grupo { get; set; }
        @AuraEnabled public String Atributo { get; set; }
        @AuraEnabled public String Valor { get; set; }
        
        public AdditionalInfoDetail(String grupo, String atributo, String valor) {
            this.Grupo = grupo;
            this.Atributo = atributo;
            this.Valor = valor != null ? valor : '';
        }
    }
}