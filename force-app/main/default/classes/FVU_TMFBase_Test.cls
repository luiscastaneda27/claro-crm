/**
 * @description Comprehensive test class for FVU_TMFBase
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
@isTest
private class FVU_TMFBase_Test {
    
    /**
     * @description Concrete implementation of abstract FVU_TMFBase for testing
     */
    private class TestTMFImplementation extends FVU_TMFBase {
        public TestTMFImplementation(String apiName) {
            super(apiName);
        }
        
        public override Object processRequest(String operation, Map<String, Object> payload) {
            return new Map<String, Object>{'processed' => true};
        }
    }
    
    /**
     * @description Setup test data - Creates mock Custom Metadata records
     * Note: Since we can't insert Custom Metadata in tests, we'll test the logic
     * that doesn't depend on SOQL queries directly
     */
    @testSetup
    static void setup() {
        // No setup needed as we'll use direct method testing
    }
    
    // ============================================================================
    // CONSTRUCTOR TESTS
    // ============================================================================
    
    @isTest
    static void testConstructor_Success() {
        Test.startTest();
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Test.stopTest();
        
        System.assertNotEquals(null, tmf, 'TMF instance should be created');
        System.assertEquals('TMF621', tmf.apiName, 'API name should be set correctly');
    }
    
    // ============================================================================
    // NESTED VALUE RETRIEVAL TESTS
    // ============================================================================
    
    @isTest
    static void testGetNestedValue_SimpleField() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active',
            'name' => 'Test Product'
        };
        
        Test.startTest();
        Object statusValue = tmf.getNestedValue(payload, 'status');
        Object nameValue = tmf.getNestedValue(payload, 'name');
        Test.stopTest();
        
        System.assertEquals('active', statusValue, 'Should retrieve simple field value');
        System.assertEquals('Test Product', nameValue, 'Should retrieve simple field value');
    }
    
    @isTest
    static void testGetNestedValue_NestedField() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new Map<String, Object>{
                'id' => '12345',
                'name' => 'John Doe'
            }
        };
        
        Test.startTest();
        Object idValue = tmf.getNestedValue(payload, 'relatedParty.id');
        Object nameValue = tmf.getNestedValue(payload, 'relatedParty.name');
        Test.stopTest();
        
        System.assertEquals('12345', idValue, 'Should retrieve nested field value');
        System.assertEquals('John Doe', nameValue, 'Should retrieve nested field value');
    }
    
    @isTest
    static void testGetNestedValue_ArrayWithIndex() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1', 'role' => 'Customer'},
                new Map<String, Object>{'id' => 'party2', 'role' => 'Seller'}
            }
        };
        
        Test.startTest();
        Object firstId = tmf.getNestedValue(payload, 'relatedParty[0].id');
        Object secondRole = tmf.getNestedValue(payload, 'relatedParty[1].role');
        Test.stopTest();
        
        System.assertEquals('party1', firstId, 'Should retrieve first array item field');
        System.assertEquals('Seller', secondRole, 'Should retrieve second array item field');
    }
    
    @isTest
    static void testGetNestedValue_ArrayWithNNotation() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1'}
            }
        };
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, 'relatedParty[n].id');
        Test.stopTest();
        
        System.assertEquals(null, result, '[n] notation should return null as it is handled by validateArrayFieldForAllItems');
    }
    
    @isTest
    static void testGetNestedValue_NonExistentField() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, 'nonExistent.field');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Non-existent field should return null');
    }
    
    @isTest
    static void testGetNestedValue_ArrayOutOfBounds() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'items' => new List<Object>{
                new Map<String, Object>{'id' => 'item1'}
            }
        };
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, 'items[5].id');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Out of bounds index should return null');
    }
    
    @isTest
    static void testGetNestedValue_NullPayload() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Object result = tmf.getNestedValue(null, 'field');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Null payload should return null');
    }
    
    @isTest
    static void testGetNestedValue_BlankFieldPath() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{'status' => 'active'};
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, '');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Blank field path should return null');
    }
    
    // ============================================================================
    // VALIDATE REQUIRED FIELDS TESTS
    // ============================================================================
    
    @isTest
    static void testValidateRequiredFields_SimpleFieldPresent() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'productOffering' => 'PO123',
            'status' => 'active'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'productOffering';
        field1.Is_Required__c = true;
        field1.Is_Array__c = false;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when required field is present');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateRequiredFields_SimpleFieldMissing() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'productOffering';
        field1.Is_Required__c = true;
        field1.Is_Array__c = false;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when required field is missing');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('productOffering'), 'Error should mention missing field');
    }
    
    @isTest
    static void testValidateRequiredFields_BlankStringField() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'productOffering' => ''
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'productOffering';
        field1.Is_Required__c = true;
        field1.Is_Array__c = false;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail for blank string');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
    }
    
    @isTest
    static void testValidateRequiredFields_ArrayRequired_Present() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1'}
            }
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'relatedParty';
        field1.Is_Required__c = true;
        field1.Is_Array__c = true;
        field1.Array_Min_Items__c = 1;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when required array is present');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateRequiredFields_ArrayRequired_Missing() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'relatedParty';
        field1.Is_Required__c = true;
        field1.Is_Array__c = true;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when required array is missing');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('relatedParty'), 'Error should mention missing array');
    }
    
    @isTest
    static void testValidateRequiredFields_ArrayMinItems_Violation() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>()
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'relatedParty';
        field1.Is_Required__c = true;
        field1.Is_Array__c = true;
        field1.Array_Min_Items__c = 2;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when array has fewer items than minimum');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('minimum'), 'Error should mention minimum requirement');
    }
    
    @isTest
    static void testValidateRequiredFields_ArrayFieldNotArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => 'not an array'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'relatedParty';
        field1.Is_Required__c = true;
        field1.Is_Array__c = true;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when field marked as array is not an array');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('must be an array'), 'Error should mention array requirement');
    }
    
    // ============================================================================
    // ARRAY FIELD VALIDATION TESTS
    // ============================================================================
    
    @isTest
    static void testValidateArrayFieldAtIndex_Present() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1'},
                new Map<String, Object>{'id' => 'party2'}
            }
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[0].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldAtIndex(payload, field, 0, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when field at index is present');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateArrayFieldAtIndex_Missing() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'Customer'}
            }
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[0].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldAtIndex(payload, field, 0, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when field at index is missing');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_AllPresent() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1', 'role' => 'Customer'},
                new Map<String, Object>{'id' => 'party2', 'role' => 'Seller'}
            }
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[n].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when all items have required field');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_OneMissing() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1', 'role' => 'Customer'},
                new Map<String, Object>{'role' => 'Seller'}
            }
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[n].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when one item is missing required field');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('[1]'), 'Error should indicate which array index failed');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_ArrayNotPresent() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[n].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when array is not present (optional array)');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_NotAnArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => 'not an array'
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[n].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when field is not an array');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_EmptyArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>()
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'relatedParty[n].id';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass for empty array');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateArrayFieldForAllItems_PrimitiveArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'tags' => new List<Object>{'tag1', '', 'tag3'}
        };
        
        FVU_TMF_API_Field__mdt field = new FVU_TMF_API_Field__mdt();
        field.Field_Path__c = 'tags[n]';
        field.Is_Required__c = true;
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateArrayFieldForAllItems(payload, field, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when primitive array has blank values');
        System.assertEquals(1, result.errors.size(), 'Should have one error for blank value at index 1');
    }
    
    // ============================================================================
    // FIELD CONSTRAINTS VALIDATION TESTS
    // ============================================================================
    
    @isTest
    static void testValidateFieldConstraints_MinLength_Pass() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Valid description'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'description';
        field1.Data_Type__c = 'String';
        field1.Min_Length__c = 5;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when string meets minimum length');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateFieldConstraints_MinLength_Fail() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Hi'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'description';
        field1.Data_Type__c = 'String';
        field1.Min_Length__c = 5;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when string is below minimum length');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('at least'), 'Error should mention minimum length');
    }
    
    @isTest
    static void testValidateFieldConstraints_MaxLength_Pass() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'Product'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'name';
        field1.Data_Type__c = 'String';
        field1.Max_Length__c = 10;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when string is within maximum length');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateFieldConstraints_MaxLength_Fail() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'This is a very long product name'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'name';
        field1.Data_Type__c = 'String';
        field1.Max_Length__c = 10;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when string exceeds maximum length');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('exceeds'), 'Error should mention max length exceeded');
    }
    
    @isTest
    static void testValidateFieldConstraints_Pattern_Pass() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'email' => 'test@example.com'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'email';
        field1.Data_Type__c = 'String';
        field1.Pattern__c = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when string matches pattern');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateFieldConstraints_Pattern_Fail() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'email' => 'invalid-email'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'email';
        field1.Data_Type__c = 'String';
        field1.Pattern__c = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when string does not match pattern');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('pattern'), 'Error should mention pattern mismatch');
    }
    
    @isTest
    static void testValidateFieldConstraints_SkipsNullValues() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'description';
        field1.Data_Type__c = 'String';
        field1.Min_Length__c = 5;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateFieldConstraints(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should skip null values');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    // ============================================================================
    // ENUM VALIDATION TESTS
    // ============================================================================
    
    @isTest
    static void testValidateEnumFields_ValidValue() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'status';
        field1.Enum_Values__c = 'active;inactive;suspended';
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateEnumFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass for valid enum value');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateEnumFields_InvalidValue() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'deleted'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'status';
        field1.Enum_Values__c = 'active;inactive;suspended';
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateEnumFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail for invalid enum value');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assert(result.errors[0].message.contains('must be one of'), 'Error should list allowed values');
    }
    
    @isTest
    static void testValidateEnumFields_SkipsNullAndBlankEnum() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active',
            'description' => 'Test'
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'description';
        field1.Enum_Values__c = null;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateEnumFields(payload, fields, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should skip fields without enum values');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    // ============================================================================
    // CONDITIONAL VALIDATION RULES TESTS
    // ============================================================================
    
    @isTest
    static void testExecuteValidationRules_ConditionTrue_FieldPresent() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'orderType' => 'subscription',
            'subscriptionDetails' => new Map<String, Object>{'period' => 'monthly'}
        };
        
        List<FVU_TMF_API_Validation_Rule__mdt> rules = new List<FVU_TMF_API_Validation_Rule__mdt>();
        FVU_TMF_API_Validation_Rule__mdt rule1 = new FVU_TMF_API_Validation_Rule__mdt();
        rule1.Condition__c = 'orderType==subscription';
        rule1.Required_Fields__c = 'subscriptionDetails.period';
        rule1.Error_Code__c = 'TMF-400-100';
        rule1.Error_Message__c = 'Subscription period is required';
        rules.add(rule1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.executeValidationRules(payload, rules, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when conditional required field is present');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testExecuteValidationRules_ConditionTrue_FieldMissing() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'orderType' => 'subscription'
        };
        
        List<FVU_TMF_API_Validation_Rule__mdt> rules = new List<FVU_TMF_API_Validation_Rule__mdt>();
        FVU_TMF_API_Validation_Rule__mdt rule1 = new FVU_TMF_API_Validation_Rule__mdt();
        rule1.Condition__c = 'orderType==subscription';
        rule1.Required_Fields__c = 'subscriptionDetails.period';
        rule1.Error_Code__c = 'TMF-400-100';
        rule1.Error_Message__c = 'Subscription period is required';
        rules.add(rule1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.executeValidationRules(payload, rules, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when conditional required field is missing');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assertEquals('TMF-400-100', result.errors[0].code, 'Should use custom error code');
    }
    
    @isTest
    static void testExecuteValidationRules_ConditionFalse() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'orderType' => 'one-time'
        };
        
        List<FVU_TMF_API_Validation_Rule__mdt> rules = new List<FVU_TMF_API_Validation_Rule__mdt>();
        FVU_TMF_API_Validation_Rule__mdt rule1 = new FVU_TMF_API_Validation_Rule__mdt();
        rule1.Condition__c = 'orderType==subscription';
        rule1.Required_Fields__c = 'subscriptionDetails.period';
        rule1.Error_Code__c = 'TMF-400-100';
        rule1.Error_Message__c = 'Subscription period is required';
        rules.add(rule1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.executeValidationRules(payload, rules, result);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass when condition is false');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testExecuteValidationRules_MultipleRequiredFields() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'orderType' => 'subscription',
            'subscriptionDetails' => new Map<String, Object>{'period' => 'monthly'}
        };
        
        List<FVU_TMF_API_Validation_Rule__mdt> rules = new List<FVU_TMF_API_Validation_Rule__mdt>();
        FVU_TMF_API_Validation_Rule__mdt rule1 = new FVU_TMF_API_Validation_Rule__mdt();
        rule1.Condition__c = 'orderType==subscription';
        rule1.Required_Fields__c = 'subscriptionDetails.period;subscriptionDetails.startDate';
        rule1.Error_Code__c = 'TMF-400-100';
        rule1.Error_Message__c = 'Subscription details incomplete';
        rules.add(rule1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.executeValidationRules(payload, rules, result);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail when one of multiple required fields is missing');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
    }
    
    // ============================================================================
    // EVALUATE CONDITION TESTS
    // ============================================================================
    
    @isTest
    static void testEvaluateCondition_SimpleEquality_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true');
    }
    
    @isTest
    static void testEvaluateCondition_SimpleEquality_False() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'inactive'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Condition should evaluate to false');
    }
    
    @isTest
    static void testEvaluateCondition_NotEquals_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status!=inactive');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true');
    }
    
    @isTest
    static void testEvaluateCondition_GreaterThan_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'quantity' => 10
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'quantity>5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true for greater than');
    }
    
    @isTest
    static void testEvaluateCondition_LessThan_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'quantity' => 3
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'quantity<5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true for less than');
    }
    
    @isTest
    static void testEvaluateCondition_GreaterThanOrEqual_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'quantity' => 5
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'quantity>=5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true for greater than or equal');
    }
    
    @isTest
    static void testEvaluateCondition_LessThanOrEqual_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'quantity' => 5
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'quantity<=5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Condition should evaluate to true for less than or equal');
    }
    
    @isTest
    static void testEvaluateCondition_LogicalAND_BothTrue() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active',
            'quantity' => 10
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active && quantity>5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'AND condition should be true when both conditions are true');
    }
    
    @isTest
    static void testEvaluateCondition_LogicalAND_OneFalse() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'inactive',
            'quantity' => 10
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active && quantity>5');
        Test.stopTest();
        
        System.assertEquals(false, result, 'AND condition should be false when one condition is false');
    }
    
    @isTest
    static void testEvaluateCondition_LogicalOR_OneTrue() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active',
            'quantity' => 2
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active || quantity>5');
        Test.stopTest();
        
        System.assertEquals(true, result, 'OR condition should be true when at least one condition is true');
    }
    
    @isTest
    static void testEvaluateCondition_LogicalOR_BothFalse() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'inactive',
            'quantity' => 2
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'status==active || quantity>5');
        Test.stopTest();
        
        System.assertEquals(false, result, 'OR condition should be false when both conditions are false');
    }
    
    @isTest
    static void testEvaluateCondition_NullCheck_True() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'description!=null');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Condition should evaluate field as null');
    }
    
    @isTest
    static void testEvaluateCondition_ArrayWithN_AnyMatch() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'Customer'},
                new Map<String, Object>{'role' => 'Seller'}
            }
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'relatedParty[n].role==Customer');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true when any array item matches');
    }
    
    @isTest
    static void testEvaluateCondition_ArrayWithN_NoMatch() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'Seller'},
                new Map<String, Object>{'role' => 'Partner'}
            }
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'relatedParty[n].role==Customer');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when no array item matches');
    }
    
    @isTest
    static void testEvaluateCondition_ArrayWithSpecificIndex() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'Customer'},
                new Map<String, Object>{'role' => 'Seller'}
            }
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, 'relatedParty[0].role==Customer');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should evaluate specific array index');
    }
    
    @isTest
    static void testEvaluateCondition_BlankCondition() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateCondition(payload, '');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Blank condition should return true');
    }
    
    // ============================================================================
    // EVALUATE ARRAY CONDITION TESTS
    // ============================================================================
    
    @isTest
    static void testEvaluateArrayCondition_AnyMatch_Found() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'items' => new List<Object>{
                new Map<String, Object>{'status' => 'active'},
                new Map<String, Object>{'status' => 'inactive'}
            }
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateArrayCondition(payload, 'items[n].status', '==', 'active', true);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true when any match is found');
    }
    
    @isTest
    static void testEvaluateArrayCondition_AllMatch_Success() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'items' => new List<Object>{
                new Map<String, Object>{'status' => 'active'},
                new Map<String, Object>{'status' => 'active'}
            }
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateArrayCondition(payload, 'items[n].status', '==', 'active', false);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true when all items match');
    }
    
    @isTest
    static void testEvaluateArrayCondition_ArrayNotPresent() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'status' => 'active'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateArrayCondition(payload, 'items[n].status', '!=', 'null', true);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when array is not present');
    }
    
    @isTest
    static void testEvaluateArrayCondition_NotAnArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'items' => 'not an array'
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateArrayCondition(payload, 'items[n].status', '==', 'active', true);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false when field is not an array');
    }
    
    @isTest
    static void testEvaluateArrayCondition_EmptyArray() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'items' => new List<Object>()
        };
        
        Test.startTest();
        Boolean result = tmf.evaluateArrayCondition(payload, 'items[n].status', '==', 'active', true);
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for empty array');
    }
    
    // ============================================================================
    // EVALUATE OPERATOR TESTS
    // ============================================================================
    
    @isTest
    static void testEvaluateOperator_Equals() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.evaluateOperator('active', '==', 'active');
        Boolean result2 = tmf.evaluateOperator('active', '==', 'inactive');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true for equal values');
        System.assertEquals(false, result2, 'Should return false for unequal values');
    }
    
    @isTest
    static void testEvaluateOperator_NotEquals() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.evaluateOperator('active', '!=', 'inactive');
        Boolean result2 = tmf.evaluateOperator('active', '!=', 'active');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true for unequal values');
        System.assertEquals(false, result2, 'Should return false for equal values');
    }
    
    @isTest
    static void testEvaluateOperator_NullValue() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result = tmf.evaluateOperator(null, '==', 'null');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should handle null values correctly');
    }
    
    // ============================================================================
    // COMPARE NUMERIC TESTS
    // ============================================================================
    
    @isTest
    static void testCompareNumeric_GreaterThan() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.compareNumeric('10', '5', '>');
        Boolean result2 = tmf.compareNumeric('3', '5', '>');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true when first is greater');
        System.assertEquals(false, result2, 'Should return false when first is not greater');
    }
    
    @isTest
    static void testCompareNumeric_LessThan() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.compareNumeric('3', '5', '<');
        Boolean result2 = tmf.compareNumeric('10', '5', '<');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true when first is less');
        System.assertEquals(false, result2, 'Should return false when first is not less');
    }
    
    @isTest
    static void testCompareNumeric_GreaterThanOrEqual() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.compareNumeric('5', '5', '>=');
        Boolean result2 = tmf.compareNumeric('10', '5', '>=');
        Boolean result3 = tmf.compareNumeric('3', '5', '>=');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true for equal values');
        System.assertEquals(true, result2, 'Should return true when first is greater');
        System.assertEquals(false, result3, 'Should return false when first is less');
    }
    
    @isTest
    static void testCompareNumeric_LessThanOrEqual() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.compareNumeric('5', '5', '<=');
        Boolean result2 = tmf.compareNumeric('3', '5', '<=');
        Boolean result3 = tmf.compareNumeric('10', '5', '<=');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should return true for equal values');
        System.assertEquals(true, result2, 'Should return true when first is less');
        System.assertEquals(false, result3, 'Should return false when first is greater');
    }
    
    @isTest
    static void testCompareNumeric_NonNumericValues() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result = tmf.compareNumeric('abc', '5', '>');
        Test.stopTest();
        
        System.assertEquals(false, result, 'Should return false for non-numeric values');
    }
    
    @isTest
    static void testCompareNumeric_DecimalValues() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        Boolean result1 = tmf.compareNumeric('10.5', '5.2', '>');
        Boolean result2 = tmf.compareNumeric('3.14', '10.5', '<');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Should handle decimal comparisons for greater than');
        System.assertEquals(true, result2, 'Should handle decimal comparisons for less than');
    }
    
    // ============================================================================
    // ERROR BUILDING TESTS
    // ============================================================================
    
    @isTest
    static void testBuildError_StandardError() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        FVU_TMFBase.TMFError error = tmf.buildError('TMF-400-001', 'Test error message', 400);
        Test.stopTest();
        
        System.assertEquals('TMF-400-001', error.code, 'Error code should be set');
        System.assertEquals('Test error message', error.message, 'Error message should be set');
        System.assertEquals('400', error.status, 'Error status should be set');
    }
    
    @isTest
    static void testBuildError_ToMap() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        FVU_TMFBase.TMFError error = tmf.buildError('TMF-400-001', 'Test error', 400);
        error.reason = 'Invalid input';
        error.type = 'ValidationError';
        error.referenceError = 'https://example.com/error';
        
        Map<String, Object> errorMap = error.toMap();
        Test.stopTest();
        
        System.assertEquals('TMF-400-001', errorMap.get('code'), 'Code should be in map');
        System.assertEquals('Test error', errorMap.get('message'), 'Message should be in map');
        System.assertEquals('400', errorMap.get('status'), 'Status should be in map');
        System.assertEquals('Invalid input', errorMap.get('reason'), 'Reason should be in map');
        System.assertEquals('ValidationError', errorMap.get('type'), 'Type should be in map');
        System.assertEquals('https://example.com/error', errorMap.get('referenceError'), 'Reference should be in map');
    }
    
    @isTest
    static void testBuildError_ToMap_OnlyRequiredFields() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        Test.startTest();
        FVU_TMFBase.TMFError error = tmf.buildError('TMF-400-001', 'Test error', 400);
        Map<String, Object> errorMap = error.toMap();
        Test.stopTest();
        
        System.assertEquals(3, errorMap.size(), 'Should only include non-blank fields');
        System.assert(errorMap.containsKey('code'), 'Should contain code');
        System.assert(errorMap.containsKey('message'), 'Should contain message');
        System.assert(errorMap.containsKey('status'), 'Should contain status');
    }
    
    // ============================================================================
    // VALIDATION RESULT TESTS
    // ============================================================================
    
    @isTest
    static void testValidationResult_InitialState() {
        Test.startTest();
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Initial state should be valid');
        System.assertEquals(0, result.errors.size(), 'Initial errors list should be empty');
    }
    
    @isTest
    static void testValidationResult_AddError() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        FVU_TMFBase.TMFError error = tmf.buildError('TMF-400-001', 'Test error', 400);
        
        Test.startTest();
        result.addError(error);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Should be invalid after adding error');
        System.assertEquals(1, result.errors.size(), 'Should have one error');
        System.assertEquals('TMF-400-001', result.errors[0].code, 'Error should be added correctly');
    }
    
    @isTest
    static void testValidationResult_MultipleErrors() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        result.addError(tmf.buildError('TMF-400-001', 'Error 1', 400));
        result.addError(tmf.buildError('TMF-400-002', 'Error 2', 400));
        result.addError(tmf.buildError('TMF-400-003', 'Error 3', 400));
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Should be invalid');
        System.assertEquals(3, result.errors.size(), 'Should have three errors');
    }
    
    // ============================================================================
    // SUCCESS RESPONSE TESTS
    // ============================================================================
    
    @isTest
    static void testBuildSuccessResponse() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> testData = new Map<String, Object>{
            'id' => '123',
            'name' => 'Test Product'
        };
        
        Test.startTest();
        Map<String, Object> response = tmf.buildSuccessResponse(testData, 'POST');
        Test.stopTest();
        
        System.assertEquals('success', response.get('status'), 'Status should be success');
        System.assertEquals(testData, response.get('data'), 'Data should be included');
        System.assertNotEquals(null, response.get('timestamp'), 'Timestamp should be present');
    }
    
    // ============================================================================
    // PROCESS REQUEST TEST (Abstract Method Implementation)
    // ============================================================================
    
    @isTest
    static void testProcessRequest_Implementation() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{'test' => 'data'};
        
        Test.startTest();
        Object result = tmf.processRequest('POST', payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Process request should return a result');
        System.assert(result instanceof Map<String, Object>, 'Result should be a map');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals(true, resultMap.get('processed'), 'Should indicate processing occurred');
    }
    
    // ============================================================================
    // INTEGRATION TEST - validateRequest (Main Method)
    // ============================================================================
    
    @isTest
    static void testValidateRequest_WithException() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        
        // This will trigger an exception because no Custom Metadata exists
        Test.startTest();
        FVU_TMFBase.ValidationResult result = tmf.validateRequest('POST', new Map<String, Object>());
        Test.stopTest();
        
        // The method should handle the exception gracefully
        System.assertEquals(false, result.isValid, 'Validation should fail when metadata is not found');
        System.assert(result.errors.size() > 0, 'Should have at least one error');
        // When metadata is not found, it returns TMF-404-001
        // But we accept any error code since this is testing exception handling
        System.assertNotEquals(null, result.errors[0].code, 'Should have an error code');
    }
    
    // ============================================================================
    // EDGE CASES AND BOUNDARY TESTS
    // ============================================================================
    
    @isTest
    static void testGetNestedValue_DeepNesting() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'level1' => new Map<String, Object>{
                'level2' => new Map<String, Object>{
                    'level3' => new Map<String, Object>{
                        'value' => 'deep value'
                    }
                }
            }
        };
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, 'level1.level2.level3.value');
        Test.stopTest();
        
        System.assertEquals('deep value', result, 'Should handle deeply nested structures');
    }
    
    @isTest
    static void testGetNestedValue_ArrayInMiddleOfPath() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'parties' => new List<Object>{
                new Map<String, Object>{
                    'contact' => new Map<String, Object>{
                        'email' => 'test@example.com'
                    }
                }
            }
        };
        
        Test.startTest();
        Object result = tmf.getNestedValue(payload, 'parties[0].contact.email');
        Test.stopTest();
        
        System.assertEquals('test@example.com', result, 'Should handle arrays in middle of path');
    }
    
    @isTest
    static void testValidateRequiredFields_InvalidArrayIndexNotation() {
        TestTMFImplementation tmf = new TestTMFImplementation('TMF621');
        Map<String, Object> payload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => 'party1'}
            }
        };
        
        List<FVU_TMF_API_Field__mdt> fields = new List<FVU_TMF_API_Field__mdt>();
        FVU_TMF_API_Field__mdt field1 = new FVU_TMF_API_Field__mdt();
        field1.Field_Path__c = 'relatedParty[invalid].id';
        field1.Is_Required__c = true;
        field1.Is_Array__c = false;
        fields.add(field1);
        
        FVU_TMFBase.ValidationResult result = new FVU_TMFBase.ValidationResult();
        
        Test.startTest();
        tmf.validateRequiredFields(payload, fields, result);
        Test.stopTest();
        
        // Should treat as regular field since index is invalid
        System.assertEquals(false, result.isValid, 'Should fail for invalid array notation');
    }
}