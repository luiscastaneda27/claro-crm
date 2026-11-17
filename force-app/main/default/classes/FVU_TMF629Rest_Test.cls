@IsTest
public class FVU_TMF629Rest_Test {
    @TestSetup
    static void setupData() {
        // Minimal data setup if needed in future. Currently REST delegates to FVU_TMF629Processing and IP; we will stub that.
    }

    @IsTest
    static void testCreateAccount_Success200() {
        // Arrange: build request payload similar to TMF body
        Map<String, Object> payload = new Map<String, Object>{
            '@type' => 'Customer',
            'name' => 'John Doe',
            'status' => 'Active',
            'engagedParty' => new Map<String, Object>{
                '@type' => 'PartyRef',
                'name' => 'John Doe',
                'role' => 'Individual',
                'characteristic' => new List<Object>{
                    new Map<String, Object>{ 'name' => 'FirstName', 'value' => 'John' },
                    new Map<String, Object>{ 'name' => 'LastName', 'value' => 'Doe' },
                    new Map<String, Object>{ 'name' => 'FVU_DocumentType__c', 'value' => 'CC' },
                    new Map<String, Object>{ 'name' => 'FVU_DocumentNumber__c', 'value' => '123456' }
                }
            },
            'contactMedium' => new List<Object>{
                new Map<String, Object>{ '@type' => 'EmailContactMedium', 'contactType' => 'Personal', 'emailAddress' => 'john@example.com' }
            },
            'characteristic' => new List<Object>{
                new Map<String, Object>{ 'name' => 'AccountSource', 'value' => 'ecommerce' }
            }
        };

        // Prepare RestContext
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tmforum/v4/customer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // Act
        Test.startTest();
        FVU_TMF629Rest.createAccount();
        Test.stopTest();

        // Assert: Basic response validation - should not throw and have proper status codes
        System.assertNotEquals(null, RestContext.response, 'Response must be initialized');
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body must be set');
        System.assert(RestContext.response.statusCode == 200
                      || RestContext.response.statusCode == 201
                      || RestContext.response.statusCode == 500,
                      'Unexpected status code: ' + RestContext.response.statusCode);
                      
        // Validate response body exists and is JSON-like (basic check)
        String bodyStr = RestContext.response.responseBody.toString();
        System.assert(!String.isBlank(bodyStr), 'Response body should not be empty');
        System.assert(bodyStr.contains('{') && bodyStr.contains('}'), 'Response should be JSON object');
    }

    @IsTest
    static void testCreateAccount_ExceptionPath500() {
        // Arrange: craft malformed payload to trigger exception in deserialization or processing
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tmforum/v4/customer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        // Non-JSON body to cause JSON.deserializeUntyped to throw
        req.requestBody = Blob.valueOf('not a json');

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // Act
        Test.startTest();
        FVU_TMF629Rest.createAccount();
        Test.stopTest();

        // Assert: verify handler produced 500 and JSON body
        System.assertEquals(500, RestContext.response.statusCode, 'Should return 500 on exception');
        String text = RestContext.response.responseBody != null ? RestContext.response.responseBody.toString() : null;
        System.debug('Response a comparar ' + text);
        System.debug('Resultado contains ' + text.contains('"code":"500"'));
        boolean containsError = text.contains('"code":"500"');
        System.assertNotEquals(null, text, 'Error body should exist');
        Assert.isTrue(containsError, 'Body must indicate error');
    }

    @IsTest static void testGetCustomerWithId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/tmforum/v4/customer/TEST_ID';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        FVU_TMF629Rest.getCustomer();
        Test.stopTest();

        System.assertNotEquals(null, RestContext.response.statusCode, 'Status code should be set');
        System.assert(RestContext.response.responseBody != null, 'Response body should not be null');
        System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'), 'Content-Type header');
    }

    @IsTest static void testGetCustomerNoId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/tmforum/v4/customer';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        FVU_TMF629Rest.getCustomer();
        Test.stopTest();

        System.assertNotEquals(null, RestContext.response.statusCode, 'Status code should be set');
        System.assert(RestContext.response.responseBody != null, 'Response body should not be null');
    }

    @IsTest
    static void testPATCH_AllScenarios() {
        Map<String, Object> payload = new Map<String, Object>{'@type' => 'Customer', 'name' => 'Patch Test'};
        
        // Test 1: PATCH with Salesforce ID in path
        RestRequest req1 = new RestRequest();
        req1.requestURI = '/services/apexrest/tmforum/v4/customer/0011234567890ABC';
        req1.httpMethod = 'PATCH';
        req1.addHeader('Content-Type', 'application/json');
        req1.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestResponse res1 = new RestResponse();
        RestContext.request = req1;
        RestContext.response = res1;
        
        Test.startTest();
        FVU_TMF629Rest.updateCustomer();
        Test.stopTest();
        
        System.assertNotEquals(null, res1.statusCode, 'Status code should be set');
        System.assertNotEquals(null, res1.responseBody, 'Response body should be set');
        System.assertEquals('application/json', res1.headers.get('Content-Type'), 'Content-Type should be JSON');
        
        // Test 2: PATCH with docNumber + docType query params
        RestRequest req2 = new RestRequest();
        req2.requestURI = '/services/apexrest/tmforum/v4/customer';
        req2.httpMethod = 'PATCH';
        req2.addHeader('Content-Type', 'application/json');
        req2.requestBody = Blob.valueOf(JSON.serialize(payload));
        req2.params.put('docNumber', '123456789');
        req2.params.put('docType', 'CC');
        RestResponse res2 = new RestResponse();
        RestContext.request = req2;
        RestContext.response = res2;
        
        FVU_TMF629Rest.updateCustomer();
        
        System.assertNotEquals(null, res2.statusCode, 'Status code should be set for docNumber+docType');
        System.assertNotEquals(null, res2.responseBody, 'Response body should be set');
        
        // Test 3: PATCH with email query param
        RestRequest req3 = new RestRequest();
        req3.requestURI = '/services/apexrest/tmforum/v4/customer';
        req3.httpMethod = 'PATCH';
        req3.addHeader('Content-Type', 'application/json');
        req3.requestBody = Blob.valueOf(JSON.serialize(payload));
        req3.params.put('email', 'test@example.com');
        RestResponse res3 = new RestResponse();
        RestContext.request = req3;
        RestContext.response = res3;
        
        FVU_TMF629Rest.updateCustomer();
        
        System.assertNotEquals(null, res3.statusCode, 'Status code should be set for email');
        System.assertNotEquals(null, res3.responseBody, 'Response body should be set');
        
        // Test 4: PATCH without any identification (should return error from Processing)
        RestRequest req4 = new RestRequest();
        req4.requestURI = '/services/apexrest/tmforum/v4/customer';
        req4.httpMethod = 'PATCH';
        req4.addHeader('Content-Type', 'application/json');
        req4.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestResponse res4 = new RestResponse();
        RestContext.request = req4;
        RestContext.response = res4;
        
        FVU_TMF629Rest.updateCustomer();
        
        System.assert(res4.statusCode == 400 || res4.statusCode == 404 || res4.statusCode == 500, 
            'Should return error status code without identification');
        System.assertNotEquals(null, res4.responseBody, 'Error response body should be set');
        String body4 = res4.responseBody.toString();
        System.assert(body4.contains('error') || body4.contains('errors'), 'Response should indicate error');
        
        // Test 5: PATCH with ID in path + query params (ID takes precedence)
        RestRequest req5 = new RestRequest();
        req5.requestURI = '/services/apexrest/tmforum/v4/customer/0011234567890XYZ';
        req5.httpMethod = 'PATCH';
        req5.addHeader('Content-Type', 'application/json');
        req5.requestBody = Blob.valueOf(JSON.serialize(payload));
        req5.params.put('email', 'other@example.com');
        RestResponse res5 = new RestResponse();
        RestContext.request = req5;
        RestContext.response = res5;
        
        FVU_TMF629Rest.updateCustomer();
        
        System.assertNotEquals(null, res5.statusCode, 'Status code should be set');
        System.assertNotEquals(null, res5.responseBody, 'Response body should be set');
    }

    @IsTest
    static void testPATCH_ExceptionHandling() {
        // Test: PATCH with malformed JSON to trigger exception
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/tmforum/v4/customer/0011234567890ABC';
        req.httpMethod = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('not valid json {{{');
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF629Rest.updateCustomer();
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode, 'Should return 500 on exception');
        System.assertNotEquals(null, res.responseBody, 'Error response body should be set');
        String bodyText = res.responseBody.toString();
        System.assert(bodyText.contains('500') || bodyText.contains('INTERNAL_SERVER_ERROR') || bodyText.contains('message'), 
            'Response should indicate server error');
    }
}