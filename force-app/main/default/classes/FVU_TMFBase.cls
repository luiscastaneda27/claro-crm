/**
 * @description Base class for all TMForum API implementations
 * @author Josue Aguilar - Salesforce 
 * @version 1.1
 */
public with sharing abstract class FVU_TMFBase {
    
    // Constants
    private static final String CMDT_NAMESPACE = 'TMF_API_Definition__mdt';
    private static final Integer DEFAULT_LIMIT = 100;
    
    // Instance variables
    @TestVisible protected String apiName;
    protected String operationName;
    protected Map<String, Object> validationCache;
    
    /**
     * @description Constructor
     * @param apiName The TMF API name (TMF621, TMF620, etc.)
     */
    public FVU_TMFBase(String apiName) {
        this.apiName = apiName;
        this.validationCache = new Map<String, Object>();
    }
    
    /**
     * @description Main validation orchestrator
     * @param operation HTTP operation (POST, GET, PATCH, etc.)
     * @param payload Request payload as Map
     * @return ValidationResult with status and errors
     */
    public ValidationResult validateRequest(String operation, Map<String, Object> payload) {
        ValidationResult result = new ValidationResult();
        
        try {
            // 1. Validate operation exists
            FVU_TMF_API_Operation__mdt operationMdt = getOperationMetadata(operation);
            if (operationMdt == null) {
                result.addError(buildError('TMF-404-001', 'Operation not found', 404));
                return result;
            }
            
            // 2. Validate required fields
            List<FVU_TMF_API_Field__mdt> requiredFields = getRequiredFields(operationMdt.Id);
            validateRequiredFields(payload, requiredFields, result);
            
            // 3. Validate field formats and constraints
            validateFieldConstraints(payload, requiredFields, result);
            
            // 4. Execute conditional validation rules
            List<FVU_TMF_API_Validation_Rule__mdt> rules = getValidationRules(operationMdt.Id);
            executeValidationRules(payload, rules, result);
            
            // 5. Validate enum values
            validateEnumFields(payload, requiredFields, result);
            
        } catch (Exception e) {
            result.addError(buildError('TMF-500-001', 'Internal validation error: ' + e.getMessage(), 500));
        }
        
        return result;
    }
    
    /**
     * @description Validates required fields from CMDT
     */
    @TestVisible
    private void validateRequiredFields(Map<String, Object> payload, 
                                       List<FVU_TMF_API_Field__mdt> fields, 
                                       ValidationResult result) {
        for (FVU_TMF_API_Field__mdt field : fields) {
            if (!field.Is_Required__c) continue;
            
            // Check if field path contains array notation
            if (field.Field_Path__c.contains('[') && field.Field_Path__c.contains(']')) {
                // This is a field INSIDE an array (e.g., relatedParty[n].id)
                String indexStr = field.Field_Path__c.substringBetween('[', ']');
                
                if (indexStr == 'n') {
                    // [n] means validate ALL items in array (if array exists)
                    validateArrayFieldForAllItems(payload, field, result);
                } else {
                    // Check if indexStr is numeric
                    Boolean isNumeric = true;
                    try {
                        Integer.valueOf(indexStr);
                    } catch (Exception e) {
                        isNumeric = false;
                    }
                    
                    if (isNumeric) {
                    // [0], [1], [2]... means validate specific index only
                    validateArrayFieldAtIndex(payload, field, Integer.valueOf(indexStr), result);
                    } else {
                    // Invalid notation, treat as regular field
                        Object value = getNestedValue(payload, field.Field_Path__c);
                        if (value == null || (value instanceof String && String.isBlank((String)value))) {
                            result.addError(buildError(
                                'TMF-400-002',
                                'Required field missing: ' + field.Field_Path__c,
                                400
                            ));
                        }
                    }
                }
            } else if (field.Is_Array__c) {
                // This is the ARRAY ITSELF as required (e.g., relatedParty)
                // The array must exist (not null or empty based on Array_Min_Items__c)
                Object arrayValue = getNestedValue(payload, field.Field_Path__c);
                
                if (arrayValue == null) {
                    result.addError(buildError(
                        'TMF-400-002',
                        'Required array missing: ' + field.Field_Path__c,
                        400
                    ));
                } else if (arrayValue instanceof List<Object>) {
                    List<Object> arrayList = (List<Object>)arrayValue;
                    
                    // Validate minimum items if specified
                    if (field.Array_Min_Items__c != null && 
                        arrayList.size() < field.Array_Min_Items__c) {
                        result.addError(buildError(
                            'TMF-400-003',
                            'Array ' + field.Field_Path__c + ' requires minimum ' + 
                            field.Array_Min_Items__c + ' items',
                            400
                        ));
                    }
                } else {
                    // Field is marked as array but value is not an array
                    result.addError(buildError(
                        'TMF-400-002',
                        'Field ' + field.Field_Path__c + ' must be an array',
                        400
                    ));
                }
            } else {
                // Standard single field validation
                Object value = getNestedValue(payload, field.Field_Path__c);
                
                if (value == null || (value instanceof String && String.isBlank((String)value))) {
                    result.addError(buildError(
                        'TMF-400-002',
                        'Required field missing: ' + field.Field_Path__c,
                        400
                    ));
                }
            }
        }
    }
    
    /**
     * @description Validates a field at a SPECIFIC index in an array
     * Example: relatedParty[0].id validates ONLY the first item
     * @param payload Request payload
     * @param field Field metadata
     * @param index Specific array index to validate
     * @param result Validation result accumulator
     */
    @TestVisible
    private void validateArrayFieldAtIndex(Map<String, Object> payload,
                                          FVU_TMF_API_Field__mdt field,
                                          Integer index,
                                          ValidationResult result) {
        String fieldPath = field.Field_Path__c;
        
        // Use existing getNestedValue which already handles [index] notation
        Object value = getNestedValue(payload, fieldPath);
        
        if (value == null || (value instanceof String && String.isBlank((String)value))) {
            result.addError(buildError(
                'TMF-400-002',
                'Required field missing: ' + fieldPath,
                400
            ));
        }
    }
    
    /**
     * @description Validates a field in ALL items of an array (supports nested arrays)
     * Example: relatedParty[n].id validates id in ALL relatedParty items
     * Example: productOrderItem[n].product.productCharacteristic[n].@type validates @type in nested arrays
     * NOTE: If the array doesn't exist in payload, validation is skipped (optional array)
     * @param payload Request payload
     * @param field Field metadata with [n] notation
     * @param result Validation result accumulator
     */
    @TestVisible
    private void validateArrayFieldForAllItems(Map<String, Object> payload,
                                              FVU_TMF_API_Field__mdt field,
                                              ValidationResult result) {
        String fieldPath = field.Field_Path__c;
        
        // Check if there are multiple [n] in the path (nested arrays)
        Integer arrayCount = fieldPath.countMatches('[n]');
        
        if (arrayCount > 1) {
            // Handle nested arrays recursively
            validateNestedArrayField(payload, fieldPath, result);
        } else {
            // Original single-level array logic
            validateSingleLevelArrayField(payload, fieldPath, result);
        }
    }
    
    /**
     * @description Validates single-level array fields (existing logic)
     */
    @TestVisible
    private void validateSingleLevelArrayField(Map<String, Object> payload,
                                              String fieldPath,
                                              ValidationResult result) {
        String arrayName = fieldPath.substringBefore('[');
        String nestedField = fieldPath.contains('.') ? 
            fieldPath.substringAfter('].') : null;
        
        Object arrayObj = getNestedValue(payload, arrayName);
        
        if (arrayObj == null) {
            return; // Array not present - no validation needed
        }
        
        if (!(arrayObj instanceof List<Object>)) {
            result.addError(buildError(
                'TMF-400-002',
                'Field ' + arrayName + ' must be an array',
                400
            ));
            return;
        }
        
        List<Object> arrayList = (List<Object>)arrayObj;
        
        if (arrayList.isEmpty()) {
            return;
        }
        
        for (Integer i = 0; i < arrayList.size(); i++) {
            Object item = arrayList[i];
            
            if (item instanceof Map<String, Object>) {
                Map<String, Object> itemMap = (Map<String, Object>)item;
                
                if (nestedField != null && nestedField.contains('.')) {
                    String parentObject = nestedField.substringBefore('.');
                    
                    if (!itemMap.containsKey(parentObject) || itemMap.get(parentObject) == null) {
                        continue;
                    }
                }
                
                Object fieldValue = nestedField != null ? 
                    getNestedValue(itemMap, nestedField) : item;
                
                if (fieldValue == null || 
                    (fieldValue instanceof String && String.isBlank((String)fieldValue))) {
                    result.addError(buildError(
                        'TMF-400-002',
                        'Required field missing in ' + arrayName + '[' + i + ']: ' + 
                        (nestedField != null ? nestedField : 'value'),
                        400
                    ));
                }
            } else if (nestedField == null) {
                if (item == null || (item instanceof String && String.isBlank((String)item))) {
                    result.addError(buildError(
                        'TMF-400-002',
                        'Required value missing in ' + arrayName + '[' + i + ']',
                        400
                    ));
                }
            }
        }
    }
    
    /**
     * @description Validates nested array fields recursively
     * Example: productOrderItem[n].product.productCharacteristic[n].@type
     * @param payload Request payload
     * @param fieldPath Full field path with multiple [n] notations
     * @param result Validation result accumulator
     */
    @TestVisible
    private void validateNestedArrayField(Map<String, Object> payload,
                                         String fieldPath,
                                         ValidationResult result) {
        validateNestedArrayFieldRecursive(payload, fieldPath, '', result);
    }
    
    /**
     * @description Recursive helper for nested array validation with full path tracking
     * @param payload Current level payload
     * @param fieldPath Remaining field path to validate
     * @param parentPath Accumulated parent path for error messages
     * @param result Validation result accumulator
     */
    @TestVisible
    private void validateNestedArrayFieldRecursive(Map<String, Object> payload,
                                                  String fieldPath,
                                                  String parentPath,
                                                  ValidationResult result) {
        // Find the first [n] in the path
        Integer firstArrayIndex = fieldPath.indexOf('[n]');
        
        if (firstArrayIndex == -1) {
            // No more arrays, validate as regular field
            Object value = getNestedValue(payload, fieldPath);
            if (value == null || (value instanceof String && String.isBlank((String)value))) {
                String fullPath = String.isNotBlank(parentPath) ? 
                    parentPath + '.' + fieldPath : fieldPath;
                result.addError(buildError(
                    'TMF-400-002',
                    'Required field missing: ' + fullPath,
                    400
                ));
            }
            return;
        }
        
        // Extract first array name
        String pathBeforeArray = fieldPath.substring(0, firstArrayIndex);
        
        // Get the remaining path after [n].
        String remainingPath = fieldPath.substring(firstArrayIndex + 3); // Skip [n]
        if (remainingPath.startsWith('.')) {
            remainingPath = remainingPath.substring(1); // Remove leading dot
        }
        
        // Get the array from payload
        Object arrayObj = getNestedValue(payload, pathBeforeArray);
        
        if (arrayObj == null) {
            return; // Array not present - no validation needed
        }
        
        if (!(arrayObj instanceof List<Object>)) {
            String fullPath = String.isNotBlank(parentPath) ? 
                parentPath + '.' + pathBeforeArray : pathBeforeArray;
            result.addError(buildError(
                'TMF-400-002',
                'Field ' + fullPath + ' must be an array',
                400
            ));
            return;
        }
        
        List<Object> arrayList = (List<Object>)arrayObj;
        
        if (arrayList.isEmpty()) {
            return;
        }
        
        // Recursively validate each item
        for (Integer i = 0; i < arrayList.size(); i++) {
            Object item = arrayList[i];
            
            if (item instanceof Map<String, Object>) {
                Map<String, Object> itemMap = (Map<String, Object>)item;
                
                // Build the full path for this array item
                String currentArrayPath = String.isNotBlank(parentPath) ? 
                    parentPath + '.' + pathBeforeArray + '[' + i + ']' : 
                    pathBeforeArray + '[' + i + ']';
                
                // Check if remaining path has more [n]
                if (remainingPath.contains('[n]')) {
                    // Recursive call for nested arrays
                    validateNestedArrayFieldRecursive(itemMap, remainingPath, currentArrayPath, result);
                } else {
                    // Final field validation
                    Object fieldValue = getNestedValue(itemMap, remainingPath);
                    
                    if (fieldValue == null || 
                        (fieldValue instanceof String && String.isBlank((String)fieldValue))) {
                        result.addError(buildError(
                            'TMF-400-002',
                            'Required field missing in ' + currentArrayPath + ': ' + remainingPath,
                            400
                        ));
                    }
                }
            }
        }
    }
    
    /**
     * @description Validates field constraints (length, pattern, etc.)
     */
    @TestVisible
    private void validateFieldConstraints(Map<String, Object> payload,
                                         List<FVU_TMF_API_Field__mdt> fields,
                                         ValidationResult result) {
        for (FVU_TMF_API_Field__mdt field : fields) {
            Object value = getNestedValue(payload, field.Field_Path__c);
            if (value == null) continue;
            
            // String length validation
            if (field.Data_Type__c == 'String' && value instanceof String) {
                String strValue = (String)value;
                
                if (field.Min_Length__c != null && strValue.length() < field.Min_Length__c) {
                    result.addError(buildError(
                        'TMF-400-004',
                        field.Field_Path__c + ' must be at least ' + field.Min_Length__c + ' characters',
                        400
                    ));
                }
                
                if (field.Max_Length__c != null && strValue.length() > field.Max_Length__c) {
                    result.addError(buildError(
                        'TMF-400-005',
                        field.Field_Path__c + ' exceeds maximum length of ' + field.Max_Length__c,
                        400
                    ));
                }
                
                // Pattern validation
                if (String.isNotBlank(field.Pattern__c)) {
                    Pattern p = Pattern.compile(field.Pattern__c);
                    if (!p.matcher(strValue).matches()) {
                        result.addError(buildError(
                            'TMF-400-006',
                            field.Field_Path__c + ' does not match required pattern',
                            400
                        ));
                    }
                }
            }
        }
    }
    
    /**
     * @description Executes conditional validation rules
     */
    @TestVisible
    private void executeValidationRules(Map<String, Object> payload,
                                       List<FVU_TMF_API_Validation_Rule__mdt> rules,
                                       ValidationResult result) {
        for (FVU_TMF_API_Validation_Rule__mdt rule : rules) {
            if (evaluateCondition(payload, rule.Condition__c)) {
                // Check required fields for this rule
                if (String.isNotBlank(rule.Required_Fields__c)) {
                    List<String> reqFields = rule.Required_Fields__c.split(';');
                    for (String fieldPath : reqFields) {
                        Object value = getNestedValue(payload, fieldPath.trim());
                        if (value == null) {
                            result.addError(buildError(
                                rule.Error_Code__c,
                                rule.Error_Message__c,
                                400
                            ));
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description Validates enum field values
     */
    @TestVisible
    private void validateEnumFields(Map<String, Object> payload,
                                   List<FVU_TMF_API_Field__mdt> fields,
                                   ValidationResult result) {
        for (FVU_TMF_API_Field__mdt field : fields) {
            if (String.isBlank(field.Enum_Values__c)) continue;
            
            Object value = getNestedValue(payload, field.Field_Path__c);
            if (value == null) continue;
            
            Set<String> allowedValues = new Set<String>(field.Enum_Values__c.split(';'));
            if (!allowedValues.contains(String.valueOf(value))) {
                result.addError(buildError(
                    'TMF-400-007',
                    field.Field_Path__c + ' must be one of: ' + field.Enum_Values__c,
                    400
                ));
            }
        }
    }
    
    /**
     * @description Gets nested value from payload using dot notation
     * Supports: simple paths (status), nested (relatedParty.id), arrays (relatedParty[0].id)
     * NOTE: Does NOT support [n] notation - that's handled by validateArrayFieldForAllItems
     */
    @TestVisible
    private Object getNestedValue(Map<String, Object> payload, String fieldPath) {
        if (payload == null || String.isBlank(fieldPath)) return null;
        
        List<String> pathParts = fieldPath.split('\\.');
        Object currentValue = payload;
        
        for (String part : pathParts) {
            if (currentValue == null) return null;
            
            // Handle array notation: fieldName[0], fieldName[1], etc.
            if (part.contains('[')) {
                String fieldName = part.substringBefore('[');
                String indexStr = part.substringBetween('[', ']');
                
                // Skip if it's [n] - this should be handled by validateArrayFieldForAllItems
                if (indexStr == 'n') {
                    return null;
                }
                
                // Parse numeric index
                Integer index;
                try {
                    index = Integer.valueOf(indexStr);
                } catch (Exception e) {
                    System.debug('Invalid array index: ' + indexStr);
                    return null;
                }
                
                if (currentValue instanceof Map<String, Object>) {
                    currentValue = ((Map<String, Object>)currentValue).get(fieldName);
                }
                
                if (currentValue instanceof List<Object>) {
                    List<Object> listValue = (List<Object>)currentValue;
                    if (index >= listValue.size()) return null;
                    currentValue = listValue[index];
                }
            } else {
                // Simple field access
                if (currentValue instanceof Map<String, Object>) {
                    currentValue = ((Map<String, Object>)currentValue).get(part);
                } else {
                    return null;
                }
            }
        }
        
        return currentValue;
    }
    
    /**
     * @description Evaluates conditional expressions with support for arrays
     * Supports:
     * - Simple: field=='value', field!='value'
     * - Numeric: field>10, field<=5
     * - Arrays with [n]: array[n].field=='value' (ANY match)
     * - Arrays with [0]: array[0].field=='value' (specific index)
     * - Existence: field!=null, array[n]!=null
     * - Logical: condition1 && condition2, condition1 || condition2
     */
    @TestVisible
    private Boolean evaluateCondition(Map<String, Object> payload, String condition) {
        if (String.isBlank(condition)) return true;
        
        condition = condition.trim();
        
        // Handle logical operators (AND, OR)
        if (condition.contains('&&')) {
            List<String> parts = condition.split('&&');
            for (String part : parts) {
                if (!evaluateCondition(payload, part.trim())) {
                    return false; // All must be true for AND
                }
            }
            return true;
        }
        
        if (condition.contains('||')) {
            List<String> parts = condition.split('\\|\\|');
            for (String part : parts) {
                if (evaluateCondition(payload, part.trim())) {
                    return true; // Any can be true for OR
                }
            }
            return false;
        }
        
        // Determine operator
        String operator = null;
        if (condition.contains('==')) operator = '==';
        else if (condition.contains('!=')) operator = '!=';
        else if (condition.contains('>=')) operator = '>=';
        else if (condition.contains('<=')) operator = '<=';
        else if (condition.contains('>')) operator = '>';
        else if (condition.contains('<')) operator = '<';
        
        if (operator == null) return true;
        
        // Split by operator
        List<String> parts = condition.split(Pattern.quote(operator));
        if (parts.size() != 2) return true;
        
        String fieldPath = parts[0].trim().replace('\'', '').replace('"', '');
        String expectedValue = parts[1].trim().replace('\'', '').replace('"', '');
        
        // Check if field path contains array notation
        if (fieldPath.contains('[') && fieldPath.contains(']')) {
            String indexStr = fieldPath.substringBetween('[', ']');
            
            if (indexStr == 'n') {
                // [n] means evaluate condition for ANY item in array
                return evaluateArrayCondition(payload, fieldPath, operator, expectedValue, true);
            } else if (indexStr.isNumeric()) {
                // [0], [1], etc. means evaluate specific index
                Object actualValue = getNestedValue(payload, fieldPath);
                return evaluateOperator(actualValue, operator, expectedValue);
            }
        }
        
        // Standard field evaluation
        Object actualValue = getNestedValue(payload, fieldPath);
        return evaluateOperator(actualValue, operator, expectedValue);
    }
    
    /**
     * @description Evaluates a condition against array items
     * @param payload Request payload
     * @param fieldPath Field path with [n] notation (e.g., "array[n].field")
     * @param operator Comparison operator (==, !=, >, <, etc.)
     * @param expectedValue Expected value to compare against
     * @param anyMatch If true, returns true if ANY item matches; if false, ALL must match
     * @return Boolean indicating if condition is met
     */
    @TestVisible
    private Boolean evaluateArrayCondition(Map<String, Object> payload,
                                          String fieldPath,
                                          String operator,
                                          String expectedValue,
                                          Boolean anyMatch) {
        // Extract array name and nested field
        String arrayName = fieldPath.substringBefore('[');
        String nestedField = fieldPath.contains('.') ? 
            fieldPath.substringAfter('].') : null;
        
        // Get the array from payload
        Object arrayObj = getNestedValue(payload, arrayName);
        
        if (arrayObj == null) {
            // Special case: checking if array exists
            if (operator == '!=' && expectedValue == 'null') {
                return false; // array is null, condition "array!=null" is false
            }
            return false;
        }
        
        if (!(arrayObj instanceof List<Object>)) {
            return false;
        }
        
        List<Object> arrayList = (List<Object>)arrayObj;
        
        if (arrayList.isEmpty()) {
            return false;
        }
        
        Integer matchCount = 0;
        
        // Iterate through array items
        for (Object item : arrayList) {
            Object fieldValue;
            
            if (nestedField != null && item instanceof Map<String, Object>) {
                // Get nested field from item
                fieldValue = getNestedValue((Map<String, Object>)item, nestedField);
            } else {
                // Use item directly
                fieldValue = item;
            }
            
            if (evaluateOperator(fieldValue, operator, expectedValue)) {
                matchCount++;
                if (anyMatch) {
                    return true; // ANY match found
                }
            } else {
                if (!anyMatch) {
                    return false; // ALL match required, one failed
                }
            }
        }
        
        // If anyMatch=true and we're here, no matches found
        // If anyMatch=false and we're here, all matched
        return !anyMatch;
    }
    
    /**
     * @description Evaluates an operator between actual and expected values
     * @param actualValue The actual value from payload
     * @param operator The comparison operator
     * @param expectedValue The expected value (as String)
     * @return Boolean result of comparison
     */
    @TestVisible
    private Boolean evaluateOperator(Object actualValue, String operator, String expectedValue) {
        String actualStr = actualValue != null ? String.valueOf(actualValue) : 'null';
        
        switch on operator {
            when '==' {
                return actualStr == expectedValue;
            }
            when '!=' {
                return actualStr != expectedValue;
            }
            when '>' {
                return compareNumeric(actualStr, expectedValue, '>');
            }
            when '<' {
                return compareNumeric(actualStr, expectedValue, '<');
            }
            when '>=' {
                return compareNumeric(actualStr, expectedValue, '>=');
            }
            when '<=' {
                return compareNumeric(actualStr, expectedValue, '<=');
            }
        }
        
        return false;
    }
    
    /**
     * @description Compares numeric values
     * @param actualStr Actual value as string
     * @param expectedStr Expected value as string
     * @param operator Comparison operator (>, <, >=, <=)
     * @return Boolean result of comparison
     */
    @TestVisible
    private Boolean compareNumeric(String actualStr, String expectedStr, String operator) {
        try {
            Decimal actualNum = Decimal.valueOf(actualStr);
            Decimal expectedNum = Decimal.valueOf(expectedStr);
            
            switch on operator {
                when '>' {
                    return actualNum > expectedNum;
                }
                when '<' {
                    return actualNum < expectedNum;
                }
                when '>=' {
                    return actualNum >= expectedNum;
                }
                when '<=' {
                    return actualNum <= expectedNum;
                }
            }
        } catch (Exception e) {
            // Not numeric, return false
            return false;
        }
        
        return false;
    }
    
    /**
     * @description Retrieves operation metadata from CMDT
     */
    private FVU_TMF_API_Operation__mdt getOperationMetadata(String httpMethod) {
        String cacheKey = apiName + '_' + httpMethod;
        
        if (validationCache.containsKey(cacheKey)) {
            return (FVU_TMF_API_Operation__mdt)validationCache.get(cacheKey);
        }
        
        List<FVU_TMF_API_Operation__mdt> operations = [
            SELECT Id, Operation_Name__c, HTTP_Method__c, Processing_Class__c,
                   Endpoint_Pattern__c, Is_Bulk_Operation__c, Max_Response_Size__c
            FROM FVU_TMF_API_Operation__mdt
            WHERE TMF_API_Definition__r.API_Name__c = :apiName
            AND HTTP_Method__c = :httpMethod
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (!operations.isEmpty()) {
            validationCache.put(cacheKey, operations[0]);
            return operations[0];
        }
        
        return null;
    }
    
    /**
     * @description Retrieves required fields for an operation
     */
    private List<FVU_TMF_API_Field__mdt> getRequiredFields(String operationId) {
        String cacheKey = 'fields_' + operationId;
        
        if (validationCache.containsKey(cacheKey)) {
            return (List<FVU_TMF_API_Field__mdt>)validationCache.get(cacheKey);
        }
        
        List<FVU_TMF_API_Field__mdt> fields = [
            SELECT Field_Path__c, Is_Required__c, Is_Array__c, Data_Type__c,
                   Min_Length__c, Max_Length__c, Pattern__c, Enum_Values__c,
                   Array_Min_Items__c, Parent_Field__c
            FROM FVU_TMF_API_Field__mdt
            WHERE TMF_API_Operation__c = :operationId
            WITH SECURITY_ENFORCED
            ORDER BY Field_Path__c
        ];
        
        validationCache.put(cacheKey, fields);
        return fields;
    }
    
    /**
     * @description Retrieves validation rules for an operation
     */
    private List<FVU_TMF_API_Validation_Rule__mdt> getValidationRules(String operationId) {
        return [
            SELECT Rule_Name__c, Condition__c, Required_Fields__c,
                   Error_Message__c, Error_Code__c, Severity__c, Execution_Order__c
            FROM FVU_TMF_API_Validation_Rule__mdt
            WHERE TMF_API_Operation__c = :operationId
            WITH SECURITY_ENFORCED
            ORDER BY Execution_Order__c
        ];
    }
    
    /**
     * @description Builds standardized TMF error response
     */
    public TMFError buildError(String code, String message, Integer httpStatus) {
        FVU_TMF_Error_Catalog__mdt errorDef = getErrorDefinition(code);
        
        TMFError error = new TMFError();
        error.code = code;
        error.message = message;
        error.status = String.valueOf(httpStatus);
        
        if (errorDef != null) {
            error.reason = errorDef.Error_Reason__c;
            error.type = errorDef.Error_Type__c;
            error.referenceError = errorDef.RFC7807_Type__c;
        }
        
        return error;
    }
    
    /**
     * @description Retrieves error definition from catalog
     */
    private FVU_TMF_Error_Catalog__mdt getErrorDefinition(String errorCode) {
        List<FVU_TMF_Error_Catalog__mdt> errors = [
            SELECT Error_Message__c, Error_Reason__c, RFC7807_Type__c,
                   HTTP_Status__c, Error_Type__c, Is_Retriable__c
            FROM FVU_TMF_Error_Catalog__mdt
            WHERE Error_Code__c = :errorCode
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return errors.isEmpty() ? null : errors[0];
    }
    
    /**
     * @description Creates success response wrapper
     */
    @TestVisible
    protected Map<String, Object> buildSuccessResponse(Object data, String operation) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('data', data);
        response.put('status', 'success');
        response.put('timestamp', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        return response;
    }
    
    // Inner Classes
    
    /**
     * @description Validation result wrapper
     */
    public class ValidationResult {
        public Boolean isValid { get; set; }
        public List<TMFError> errors { get; set; }
        
        public ValidationResult() {
            this.isValid = true;
            this.errors = new List<TMFError>();
        }
        
        public void addError(TMFError error) {
            this.isValid = false;
            this.errors.add(error);
        }
    }
    
    /**
     * @description TMF Error structure following RFC 7807
     * Converts to Map for JSON serialization
     */
    public class TMFError {
        public String code { get; set; }
        public String reason { get; set; }
        public String message { get; set; }
        public String status { get; set; }
        public String type { get; set; }
        public String referenceError { get; set; }
        
        /**
         * @description Converts TMFError to Map for JSON serialization
         */
        public Map<String, Object> toMap() {
            Map<String, Object> errorMap = new Map<String, Object>();
            errorMap.put('code', this.code);
            errorMap.put('message', this.message);
            errorMap.put('status', this.status);
            if (String.isNotBlank(this.reason)) {
                errorMap.put('reason', this.reason);
            }
            if (String.isNotBlank(this.type)) {
                errorMap.put('type', this.type);
            }
            if (String.isNotBlank(this.referenceError)) {
                errorMap.put('referenceError', this.referenceError);
            }
            return errorMap;
        }
    }
    
    /**
     * @description Abstract method to be implemented by child classes
     */
    public abstract Object processRequest(String operation, Map<String, Object> payload);
}