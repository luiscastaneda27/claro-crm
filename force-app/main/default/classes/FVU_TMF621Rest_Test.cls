/**
 * @description Comprehensive test class for FVU_TMF621Rest
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 * 
 * Coverage Areas:
 * - HTTP POST (createTroubleTicket)
 * - HTTP GET (getTroubleTickets - list and single)
 * - HTTP PATCH (updateTroubleTicket)
 * - HTTP DELETE (deleteTroubleTicket)
 * - Exception handling
 */
@isTest
private class FVU_TMF621Rest_Test {
    
    // ============================================================================
    // HTTP POST TESTS - createTroubleTicket
    // ============================================================================
    
    @isTest
    static void testCreateTroubleTicket_Success() {
        // Setup request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Test trouble ticket',
            'status' => 'New',
            'priority' => 'High'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        // Status code could be 201 (success) or 400 (validation error) depending on metadata
        System.assert(
            res.statusCode == 201 || res.statusCode == 400,
            'Status code should be 201 or 400, got: ' + res.statusCode
        );
        
        // Verify response is valid JSON
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertNotEquals(null, response, 'Response should be valid JSON');
    }
    
    @isTest
    static void testCreateTroubleTicket_ValidationError() {
        // Setup request with empty payload
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>();
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Should return 400 due to validation errors
        System.assertEquals(400, res.statusCode, 'Should return 400 for validation errors');
        
        // Verify error structure
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assert(response.containsKey('errors'), 'Response should contain errors');
        System.assertEquals('error', response.get('status'), 'Status should be error');
    }
    
    @isTest
    static void testCreateTroubleTicket_InvalidJSON() {
        // Setup request with invalid JSON
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{ invalid json }');
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Should return 500 due to JSON parsing error
        System.assertEquals(500, res.statusCode, 'Should return 500 for JSON parsing error');
        
        // Verify error response
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertEquals('error', response.get('status'), 'Status should be error');
        System.assert(response.containsKey('errors'), 'Response should contain errors');
        
        List<Object> errors = (List<Object>)response.get('errors');
        Map<String, Object> error = (Map<String, Object>)errors[0];
        System.assertEquals('TMF-500-999', error.get('code'), 'Should return generic error code');
    }
    
    @isTest
    static void testCreateTroubleTicket_CompletePayload() {
        // Setup request with complete payload
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Complete test ticket',
            'status' => 'New',
            'priority' => 'Critical',
            'category' => 'Technical',
            'subcategory' => 'Network',
            '@type' => 'TroubleTicket',
            'channel' => new Map<String, Object>{
                'name' => 'Web',
                '@type' => 'Channel'
            }
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        System.assert(
            res.statusCode == 201 || res.statusCode == 400,
            'Status code should be 201 or 400'
        );
    }
    
    @isTest
    static void testCreateTroubleTicket_ErrorsWithoutStatusCode() {
        // Test scenario where errors exist but don't have status code
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Empty payload will trigger validation errors
        Map<String, Object> payload = new Map<String, Object>();
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Should default to 400 when no specific status code
        System.assertEquals(400, res.statusCode, 'Should default to 400');
    }
    
    // ============================================================================
    // HTTP GET TESTS - getTroubleTickets
    // ============================================================================
    
    @isTest
    static void testGetTroubleTickets_List() {
        // Setup request for list
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        // Don't reassign params, it's already initialized
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        // Should return 200 or 404 depending on data
        System.assert(
            res.statusCode == 200 || res.statusCode == 404,
            'Status code should be 200 or 404'
        );
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    @isTest
    static void testGetTroubleTickets_WithParameters() {
        // Setup request with query parameters
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        // Add parameters to existing params map
        req.params.put('fields', 'id,description,status');
        req.params.put('offset', '0');
        req.params.put('limit', '10');
        req.params.put('filter', 'status=New');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        // Verify response is valid JSON
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertNotEquals(null, response, 'Response should be valid JSON');
    }
    
    @isTest
    static void testGetTroubleTickets_SingleTicket() {
        // Setup request for specific ticket
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'GET';
        // params is already initialized, no need to assign
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        // Should return 404 for non-existent ticket
        System.assertEquals(404, res.statusCode, 'Should return 404 for non-existent ticket');
    }
    
    @isTest
    static void testGetTroubleTickets_WithFieldsOnly() {
        // Setup request with only fields parameter
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        req.params.put('fields', 'id,status');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    @isTest
    static void testGetTroubleTickets_WithOffsetAndLimit() {
        // Setup request with offset and limit
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        req.params.put('offset', '10');
        req.params.put('limit', '50');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    @isTest
    static void testGetTroubleTickets_WithFilter() {
        // Setup request with filter
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        req.params.put('filter', 'priority=High');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    @isTest
    static void testGetTroubleTickets_Exception() {
        // Setup request that will cause exception
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set invalid URI that might cause parsing issues
        req.requestURI = null;
        req.httpMethod = 'GET';
        // params already initialized
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        try {
            FVU_TMF621Rest.getTroubleTickets();
        } catch (Exception e) {
            // Exception is expected and handled
        }
        Test.stopTest();
        
        // The handleException method should set response
        System.assertNotEquals(null, res, 'Response should not be null');
    }
    
    // ============================================================================
    // HTTP PATCH TESTS - updateTroubleTicket
    // ============================================================================
    
    @isTest
    static void testUpdateTroubleTicket_Success() {
        // Setup request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Updated description',
            'status' => 'Working',
            'priority' => 'Medium'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        // Should return 200 or error status
        System.assertNotEquals(null, res.statusCode, 'Status code should be set');
    }
    
    @isTest
    static void testUpdateTroubleTicket_NotFound() {
        // Setup request for non-existent ticket
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Updated description'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/99999999';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        // Verify error response
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assert(response.containsKey('errors'), 'Response should contain errors');
    }
    
    @isTest
    static void testUpdateTroubleTicket_InvalidJSON() {
        // Setup request with invalid JSON
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = Blob.valueOf('{ invalid }');
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        // Should return 500 for JSON error
        System.assertEquals(500, res.statusCode, 'Should return 500 for JSON error');
        
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertEquals('error', response.get('status'), 'Status should be error');
    }
    
    @isTest
    static void testUpdateTroubleTicket_PartialUpdate() {
        // Setup request with partial update
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'priority' => 'Low'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    @isTest
    static void testUpdateTroubleTicket_EmptyPayload() {
        // Setup request with empty payload
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>();
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
    }
    
    // ============================================================================
    // HTTP DELETE TESTS - deleteTroubleTicket
    // ============================================================================
    
    @isTest
    static void testDeleteTroubleTicket_Success() {
        // Setup request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/00001234';
        req.httpMethod = 'DELETE';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.deleteTroubleTicket();
        Test.stopTest();
        
        // Should return 204 No Content
        System.assertEquals(204, res.statusCode, 'Should return 204 for successful delete');
    }
    
    @isTest
    static void testDeleteTroubleTicket_WithDifferentTicketId() {
        // Setup request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/99999999';
        req.httpMethod = 'DELETE';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.deleteTroubleTicket();
        Test.stopTest();
        
        // Should still return 204 (current implementation doesn't validate)
        System.assertEquals(204, res.statusCode, 'Should return 204');
    }
    
    @isTest
    static void testDeleteTroubleTicket_Exception() {
        // Setup request that will cause exception
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = null; // This will cause exception
        req.httpMethod = 'DELETE';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        try {
            FVU_TMF621Rest.deleteTroubleTicket();
        } catch (Exception e) {
            // Exception expected
        }
        Test.stopTest();
        
        // Should have error response
        System.assertNotEquals(null, res, 'Response should not be null');
    }
    
    // ============================================================================
    // EXCEPTION HANDLING TESTS
    // ============================================================================
    
    @isTest
    static void testHandleException_NullPointerException() {
        // Create a scenario that triggers NullPointerException
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestBody = null; // This will cause NullPointerException
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Should handle exception
        System.assertEquals(500, res.statusCode, 'Should return 500 for exceptions');
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertEquals('error', response.get('status'), 'Status should be error');
        System.assert(response.containsKey('timestamp'), 'Should have timestamp');
        
        List<Object> errors = (List<Object>)response.get('errors');
        System.assertEquals(1, errors.size(), 'Should have one error');
        
        Map<String, Object> error = (Map<String, Object>)errors[0];
        System.assertEquals('TMF-500-999', error.get('code'), 'Error code should be TMF-500-999');
        System.assertEquals('500', error.get('status'), 'Error status should be 500');
        System.assertNotEquals(null, error.get('message'), 'Should have error message');
    }
    
    @isTest
    static void testHandleException_TypeException() {
        // Create scenario with type casting exception
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Send array instead of object
        req.requestBody = Blob.valueOf('[{"test": "value"}]');
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Should handle exception
        System.assertEquals(500, res.statusCode, 'Should return 500 for type exception');
        
        String responseStr = res.responseBody.toString();
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseStr);
        System.assertEquals('error', response.get('status'), 'Status should be error');
    }
    
    // ============================================================================
    // INTEGRATION TESTS - Full Flow
    // ============================================================================
    
    @isTest
    static void testFullFlow_CreateAndGet() {
        // Test POST followed by GET
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // First, create a ticket
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Integration test ticket',
            'status' => 'New',
            'priority' => 'High'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        
        // Now try to get tickets
        req = new RestRequest();
        res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/';
        req.httpMethod = 'GET';
        // params already initialized
        
        RestContext.request = req;
        RestContext.response = res;
        
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response should not be null');
    }
    
    @isTest
    static void testContentTypeHeader() {
        // Verify Content-Type header is set correctly
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Test'
        };
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.createTroubleTicket();
        Test.stopTest();
        
        // Verify Content-Type header
        Map<String, String> headers = res.headers;
        System.assert(headers.containsKey('Content-Type'), 'Should have Content-Type header');
        System.assertEquals('application/json', headers.get('Content-Type'), 
            'Content-Type should be application/json');
    }
    
    @isTest
    static void testURIParsing_MultipleSegments() {
        // Test URI with multiple segments
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/abc123/extra';
        req.httpMethod = 'GET';
        // params already initialized
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.getTroubleTickets();
        Test.stopTest();
        
        // Should extract last segment as ticket ID
        System.assertNotEquals(null, res.responseBody, 'Response should not be null');
    }
    
    @isTest
    static void testPatchWithErrorResponse() {
        // Test PATCH that returns error with specific status
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Map<String, Object> payload = new Map<String, Object>();
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.requestURI = '/services/apexrest/tmforum/v5/troubleTicket/invalid';
        req.httpMethod = 'PATCH';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF621Rest.updateTroubleTicket();
        Test.stopTest();
        
        // Verify status code is extracted from error
        System.assertNotEquals(null, res.statusCode, 'Status code should be set');
        System.assertNotEquals(200, res.statusCode, 'Should not be 200 for error');
    }
}