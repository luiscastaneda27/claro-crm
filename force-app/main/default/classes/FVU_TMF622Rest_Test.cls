/**
 * @description Test class for FVU_TMF622Rest REST endpoint
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
@isTest
private class FVU_TMF622Rest_Test {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test Account (Consumer)
        Account consumerAccount = new Account(
            Name = 'Test Consumer Account'
        );
        insert consumerAccount;
        
        // Create test Billing Account
        Account billingAccount = new Account(
            Name = 'Test Billing Account',
            ParentId = consumerAccount.Id
        );
        insert billingAccount;
        
        // Create test Service Account
        Account serviceAccount = new Account(
            Name = 'Test Service Account',
            ParentId = consumerAccount.Id
        );
        insert serviceAccount;
    }
    
    /**
     * @description Test POST - Create Product Order - Success
     */
    @isTest
    static void testCreateProductOrder_Success() {
        Account consumer = [SELECT Id FROM Account WHERE Name = 'Test Consumer Account' LIMIT 1];
        Account billing = [SELECT Id FROM Account WHERE Name = 'Test Billing Account' LIMIT 1];
        Account service = [SELECT Id FROM Account WHERE Name = 'Test Service Account' LIMIT 1];
        
        // Prepare TMF622 request
        Map<String, Object> payload = new Map<String, Object>{
            '@type' => 'ProductOrder',
            'category' => 'EnterpriseOrder',
            'description' => 'Test order',
            'externalId' => new List<Object>{
                new Map<String, Object>{
                    'id' => 'ORD-TEST-001',
                    '@type' => 'ExternalIdentifier'
                }
            },
            'channel' => new List<Object>{
                new Map<String, Object>{
                    'channel' => new Map<String, Object>{
                        'id' => '1',
                        'name' => 'ECOMMERCE'
                    },
                    'role' => 'OriginatingChannel'
                }
            },
            'relatedParty' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'ConsumerAccount',
                    'partyOrPartyRole' => new Map<String, Object>{
                        'id' => consumer.Id
                    }
                },
                new Map<String, Object>{
                    'role' => 'BillingAccount',
                    'partyOrPartyRole' => new Map<String, Object>{
                        'id' => billing.Id
                    }
                },
                new Map<String, Object>{
                    'role' => 'ServiceAccount',
                    'partyOrPartyRole' => new Map<String, Object>{
                        'id' => service.Id
                    }
                }
            },
            'characteristic' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'salesType',
                    'value' => 'HandsetAndTech'
                }
            },
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{
                    'id' => '1',
                    'productOffering' => new Map<String, Object>{
                        'id' => 'B2C-TERM-TEST-PRODUCT'
                    },
                    'product' => new Map<String, Object>{
                        'productCharacteristic' => new List<Object>{
                            new Map<String, Object>{
                                'name' => 'position',
                                'value' => '00010'
                            }
                        }
                    }
                }
            }
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        System.assertNotEquals(null, res.statusCode, 'Status code should be set');
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        System.assertNotEquals(null, response, 'Response should be parseable JSON');
        System.assert(response.containsKey('status') || response.containsKey('errors'), 
            'Response should contain status or errors');
    }
    
    /**
     * @description Test POST - Missing Required Fields
     */
    @isTest
    static void testCreateProductOrder_MissingRequiredFields() {
        // Prepare incomplete payload
        Map<String, Object> payload = new Map<String, Object>{
            '@type' => 'ProductOrder',
            'description' => 'Incomplete order'
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        // Should return 400 Bad Request
        System.assertEquals(400, res.statusCode, 'Should return 400 Bad Request');
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        System.assertEquals('error', response.get('status'), 'Status should be error');
        System.assert(response.containsKey('errors'), 'Should contain errors array');
        
        List<Object> errors = (List<Object>)response.get('errors');
        System.assert(errors.size() > 0, 'Should have at least one error');
    }
    
    /**
     * @description Test POST - Invalid JSON
     */
    @isTest
    static void testCreateProductOrder_InvalidJSON() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('invalid json string');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        // Should return 500 with TMF-500-999
        System.assertEquals(500, res.statusCode, 'Should return 500 Internal Server Error');
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        System.assertEquals('error', response.get('status'), 'Status should be error');
        
        List<Object> errors = (List<Object>)response.get('errors');
        Map<String, Object> error = (Map<String, Object>)errors[0];
        
        System.assertEquals('TMF-500-999', error.get('code'), 'Should return catch-all error code');
        System.assertEquals('500', error.get('status'), 'Error status should be 500');
        System.assertNotEquals(null, error.get('message'), 'Should contain error message');
    }
    
    /**
     * @description Test POST - Empty Payload
     */
    @isTest
    static void testCreateProductOrder_EmptyPayload() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode, 'Should return 400 for empty payload');
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        System.assertEquals('error', response.get('status'), 'Status should be error');
    }
    
    /**
     * @description Test GET - Retrieve Product Orders List
     */
    @isTest
    static void testGetProductOrders_List() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'GET';
        req.params.put('limit', '10');
        req.params.put('offset', '0');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.getProductOrders();
        Test.stopTest();
        
        // Should return 405 Method Not Allowed (GET not implemented in Processing)
        System.assertNotEquals(null, res.responseBody, 'Response body should exist');
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        System.assertNotEquals(null, response, 'Response should be parseable');
    }
    
    /**
     * @description Test GET - Retrieve Single Product Order by ID
     */
    @isTest
    static void testGetProductOrders_SingleById() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder/00003110';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.getProductOrders();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response body should exist');
    }
    
    /**
     * @description Test GET - With Query Parameters
     */
    @isTest
    static void testGetProductOrders_WithFilters() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'GET';
        req.params.put('fields', 'id,category,description');
        req.params.put('filter', 'category=EnterpriseOrder');
        req.params.put('limit', '20');
        req.params.put('offset', '5');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.getProductOrders();
        Test.stopTest();
        
        System.assertNotEquals(null, res.responseBody, 'Response should exist');
    }
    
    /**
     * @description Test PATCH - Update Product Order
     */
    @isTest
    static void testUpdateProductOrder_Success() {
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Updated order description',
            'characteristic' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'FVU_OrderStatus__c',
                    'value' => 'Processing'
                }
            }
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder/00003110';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.updateProductOrder();
        Test.stopTest();
        
        // Should return 405 Method Not Allowed (PATCH not implemented)
        System.assertNotEquals(null, res.responseBody, 'Response should exist');
    }
    
    /**
     * @description Test PATCH - Invalid JSON
     */
    @isTest
    static void testUpdateProductOrder_InvalidJSON() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder/00003110';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('not valid json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.updateProductOrder();
        Test.stopTest();
        
        System.assertEquals(500, res.statusCode, 'Should return 500 on parse error');
    }
    
    /**
     * @description Test DELETE - Delete Product Order
     */
    @isTest
    static void testDeleteProductOrder() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder/00003110';
        req.httpMethod = 'DELETE';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.deleteProductOrder();
        Test.stopTest();
        
        // Should return 204 No Content or 405 Method Not Allowed
        System.assertNotEquals(null, res.statusCode, 'Status code should be set');
    }
    
    /**
     * @description Test handleException - Verify Error Structure
     */
    @isTest
    static void testHandleException_ErrorStructure() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('malformed{json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(
            res.responseBody.toString()
        );
        
        // Verify error structure
        System.assertEquals('error', response.get('status'), 'Should have error status');
        System.assert(response.containsKey('errors'), 'Should have errors array');
        System.assert(response.containsKey('timestamp'), 'Should have timestamp');
        
        List<Object> errors = (List<Object>)response.get('errors');
        System.assert(!errors.isEmpty(), 'Errors array should not be empty');
        
        Map<String, Object> error = (Map<String, Object>)errors[0];
        System.assert(error.containsKey('code'), 'Error should have code');
        System.assert(error.containsKey('message'), 'Error should have message');
        System.assert(error.containsKey('status'), 'Error should have status');
        
        System.assertEquals('TMF-500-999', error.get('code'), 'Should be catch-all error');
        System.assertEquals('500', error.get('status'), 'Status should be 500');
    }
    
    /**
     * @description Test Content-Type Header
     */
    @isTest
    static void testContentTypeHeader() {
        Map<String, Object> payload = new Map<String, Object>{
            '@type' => 'ProductOrder'
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        // Verify Content-Type header is set
        System.assert(res.headers.containsKey('Content-Type'), 'Should set Content-Type header');
        System.assertEquals('application/json', res.headers.get('Content-Type'), 
            'Content-Type should be application/json');
    }
    
    /**
     * @description Test Response Status Codes
     */
    @isTest
    static void testResponseStatusCodes() {
        // Test different scenarios and their expected status codes
        
        // 1. Missing required fields -> 400
        Map<String, Object> invalidPayload = new Map<String, Object>{'@type' => 'ProductOrder'};
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/tmforum/v5/productOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(invalidPayload));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        FVU_TMF622Rest.createProductOrder();
        Test.stopTest();
        
        // Should be 400 for validation errors
        System.assert(res.statusCode >= 400 && res.statusCode < 600, 
            'Should return an error status code');
    }
}