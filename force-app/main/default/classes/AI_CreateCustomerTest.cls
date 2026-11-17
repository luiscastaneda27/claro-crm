@isTest
private class AI_CreateCustomerTest {
    
    private static final String TEST_PAYLOAD_VALID_CUSTOMER = '{"customerInformation":{"firstName":"CustomerName","lastName":"CustomerLastName","email":"customer@test.com","documentType":"CC","documentNumber":"12345678901","origin":"whatsapp","customerCharacteristics":[{"name":"Phone","value":"9876543210"}]}}';
    
    private static final String TEST_PAYLOAD_MISSING_CUSTOMER_INFO = '{"otherField":"value"}';

    private static final String TEST_PAYLOAD_MISSING_CUSTOMER_CHARACTERISTICS = '{"customerInformation":{"firstName":"CustomerName","lastName":"CustomerLastName","email":"customer@test.com","documentType":"CC","documentNumber":"12345678901","origin":"whatsapp"}}';

    private static final String TEST_PAYLOAD_INVALID_CUSTOMER_CHARACTERISTICS = '{"customerInformation":{"firstName":"CustomerName","lastName":"CustomerLastName","email":"customer@test.com","documentType":"CC","documentNumber":"12345678901","origin":"whatsapp","customerCharacteristics":{"name":"OtherField","value":"someValue"}}}';
    
    private static final String TEST_PAYLOAD_MISSING_PHONE = '{"customerInformation":{"firstName":"CustomerName","lastName":"CustomerLastName","email":"customer@test.com","documentType":"CC","documentNumber":"12345678901","origin":"whatsapp","customerCharacteristics":[{"name":"OtherField","value":"someValue"}]}}';
    
    private static final String TEST_PAYLOAD_EMPTY_PHONE = '{"customerInformation":{"firstName":"CustomerName","lastName":"CustomerLastName","email":"customer@test.com","documentType":"CC","documentNumber":"12345678901","origin":"whatsapp","customerCharacteristics":[{"name":"Phone","value":""}]}}';
    
    private static final String TEST_PAYLOAD_INVALID_JSON = '{"invalid":"json"';
    
    private static final String TEST_ACCOUNT_ID = '001000000000000AAA';
    
    @isTest
    static void testCreateCustomer_EmptyRequestBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for empty request body');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Request body cannot be empty', responseBody.get('message'), 'Message should indicate empty body');
    }
    
    @isTest
    static void testCreateCustomer_MissingCustomerInformation() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_MISSING_CUSTOMER_INFO);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for missing customerInformation');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('customerInformation is required', responseBody.get('message'), 'Message should indicate missing customerInformation');
    }
    
    @isTest
    static void testCreateCustomer_MissingCustomerCharacteristics() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_MISSING_CUSTOMER_CHARACTERISTICS);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for missing phone');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Phone number is required in customerCharacteristics', responseBody.get('message'), 'Message should indicate missing phone');
    }

    @isTest
    static void testCreateCustomer_InvalidCustomerCharacteristics() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_INVALID_CUSTOMER_CHARACTERISTICS);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for missing phone');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Phone number is required in customerCharacteristics', responseBody.get('message'), 'Message should indicate missing phone');
    }

    @isTest
    static void testCreateCustomer_MissingPhone() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_MISSING_PHONE);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for missing phone');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Phone number is required in customerCharacteristics', responseBody.get('message'), 'Message should indicate missing phone');
    }
    
    @isTest
    static void testCreateCustomer_EmptyPhone() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_EMPTY_PHONE);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for empty phone');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Phone number is required in customerCharacteristics', responseBody.get('message'), 'Message should indicate empty phone');
    }
    
    @isTest
    static void testCreateCustomer_InvalidJSON() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_INVALID_JSON);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for invalid JSON');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assert(((String)responseBody.get('message')).contains('Invalid JSON format'), 'Message should indicate invalid JSON');
    }
    
    @isTest
    static void testCreateCustomer_Success() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_VALID_CUSTOMER);
        RestContext.request = req;
        RestContext.response = res;
        
        Map<String, Object> mockOutMap = new Map<String, Object>{
            'status' => 'Success',
            'accountId' => TEST_ACCOUNT_ID,
            'message' => 'Customer created successfully'
        };
        AI_CreateCustomer.mockOutMap = mockOutMap;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode, 'Should return 200 for success');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('200', responseBody.get('code'), 'Response code should be 200');
        System.assertEquals('Success', responseBody.get('status'), 'Status should be Success');
        System.assertEquals('Customer created successfully', responseBody.get('message'), 'Message should match');
        
        Map<String, Object> attributes = (Map<String, Object>) responseBody.get('attributes');
        System.assertEquals(TEST_ACCOUNT_ID, attributes.get('Id'), 'Account ID should match');
        System.assertNotEquals('', attributes.get('href'), 'Href should not be empty');
        System.assertEquals('Account', attributes.get('type'), 'Type should be Account');
        
        Map<String, Object> address = (Map<String, Object>) responseBody.get('address');
        System.assertEquals('', address.get('idAddressService'), 'Address service should be empty');
        System.assertEquals('', address.get('idAddressBilling'), 'Address billing should be empty');
    }
    
    @isTest
    static void testCreateCustomer_BusinessLogicFailure() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_VALID_CUSTOMER);
        RestContext.request = req;
        RestContext.response = res;
        
        Map<String, Object> mockOutMap = new Map<String, Object>{
            'status' => 'Failed',
            'accountId' => '',
            'message' => 'Cuenta ya existente con ese numero de documento y tipo de documento'
        };
        AI_CreateCustomer.mockOutMap = mockOutMap;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for business logic failure');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('400', responseBody.get('code'), 'Response code should be 400');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('Cuenta ya existente con ese numero de documento y tipo de documento', responseBody.get('message'), 'Message should match');
        
        Map<String, Object> attributes = (Map<String, Object>) responseBody.get('attributes');
        System.assertEquals('', attributes.get('Id'), 'Account ID should be empty');
        System.assertEquals('', attributes.get('href'), 'Href should be empty');
        System.assertEquals('', attributes.get('type'), 'Type should be empty');
    }

    @isTest
    static void testCreateCustomer_GeneralFailure() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_VALID_CUSTOMER);
        RestContext.request = req;
        RestContext.response = res;
        
        Map<String, Object> mockOutMap = new Map<String, Object>{
            'status' => 'Error',
            'accountId' => '',
            'message' => 'An unexpected error occurred: Error al crear el cliente'
        };
        AI_CreateCustomer.mockOutMap = mockOutMap;
        
        Test.startTest();
        AI_CreateCustomer.createCustomer();
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode, 'Should return 500 for business logic failure');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('500', responseBody.get('code'), 'Response code should be 500');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assertEquals('An unexpected error occurred: Error al crear el cliente', responseBody.get('message'), 'Message should match');
        
        Map<String, Object> attributes = (Map<String, Object>) responseBody.get('attributes');
        System.assertEquals('', attributes.get('Id'), 'Account ID should be empty');
        System.assertEquals('', attributes.get('href'), 'Href should be empty');
        System.assertEquals('', attributes.get('type'), 'Type should be empty');
    }
    
    @isTest
    static void testCreateCustomer_ExceptionHandling() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_VALID_CUSTOMER);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        try {
            AI_CreateCustomer.createCustomer();
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception, should handle gracefully');
        }
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertNotEquals(null, responseBody.get('status'), 'Status should be present');
    }
    
    @isTest
    static void testCreateCustomer_GeneralExceptionHandler_NullStatus() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(TEST_PAYLOAD_VALID_CUSTOMER);
        RestContext.request = req;
        RestContext.response = res;
        
        Map<String, Object> mockOutMap = new Map<String, Object>{
            'status' => null,
            'accountId' => TEST_ACCOUNT_ID,
            'message' => 'Test message'
        };
        AI_CreateCustomer.mockOutMap = mockOutMap;
        
        Test.startTest();
        try {
            AI_CreateCustomer.createCustomer();
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception, should handle gracefully in catch block');
        }
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode, 'Should return 500 for general exception');
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('500', responseBody.get('code'), 'Response code should be 500');
        System.assertEquals('Error', responseBody.get('status'), 'Status should be Error');
        System.assert(((String)responseBody.get('message')).contains('An unexpected error occurred'), 'Message should indicate unexpected error');
        System.assert(((String)responseBody.get('message')).contains('Line:'), 'Message should contain line number');
        
        Map<String, Object> attributes = (Map<String, Object>) responseBody.get('attributes');
        System.assertEquals('', attributes.get('Id'), 'Account ID should be empty');
        System.assertEquals('', attributes.get('href'), 'Href should be empty');
        System.assertEquals('', attributes.get('type'), 'Type should be empty');
        
        Map<String, Object> address = (Map<String, Object>) responseBody.get('address');
        System.assertEquals('', address.get('idAddressService'), 'Address service should be empty');
        System.assertEquals('', address.get('idAddressBilling'), 'Address billing should be empty');
    } 
}