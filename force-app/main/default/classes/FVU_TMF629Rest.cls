/**
 * @description REST API endpoint for TMF629 (Customer Management)
 * Following TM Forum standards for Customer API v4.
 * @author Ventas Flo
 * @version 2.0
 */

@RestResource(urlMapping='/tmforum/v4/customer/*')
global with sharing class FVU_TMF629Rest {

    /**
     * @description HTTP GET - Retrieve customer details
     * Example: /tmforum/v4/customer/{id}
     */
    @HttpGet
    global static void getCustomer() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
     
        try {
            // Get Id
            String path = req.requestURI;
            String customerId = null;

            String[] pathSegments = path.split('/');
            String lastSegment = pathSegments[pathSegments.size() - 1];

            if (!lastSegment.equalsIgnoreCase('customer')) {
                customerId = lastSegment;
            }
        
            // Get query values
            Map<String, String> queryParams = req.params;
            Map<String, Object> params = new Map<String, Object>{
                'id' => customerId,
                'filters' => queryParams 
            };

            FVU_TMF629Processing processor = new FVU_TMF629Processing(); 
            Object result = processor.processRequest('GET', params); 
            res.statusCode = Integer.valueOf(200);

            if (result instanceof Map<String, Object>) {
                
                Map<String, Object> resultMap = (Map<String, Object>)result;
            
                if (resultMap.containsKey('status') && resultMap.get('status') == 'error') {

                    List<Map<String,Object>> errors = resultMap.containsKey('errors') ? (List<Map<String,Object>>) resultMap.get('errors'): new List<Map<String,Object>>();
                    String code = !errors.isEmpty() ? (String) errors.get(0).get('status') : '500';
                    res.statusCode = Integer.valueOf(code); 
                    
                } 
            }
            
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(result));

        } catch (Exception e) {
            handleException(res, e);
        }
    }
    
    /**
     * @description HTTP POST - Create an account
     * @return JSON response with created account or errors
     */
    @HttpPost
    global static void createAccount() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Parse request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            // Process through TMF629Processing
            FVU_TMF629Processing processor = new FVU_TMF629Processing(); 
            Object result = processor.processRequest('POST', payload);
            
            // Set response
            Map<String, Object> resultMap = (Map<String, Object>)result;
            
            res.addHeader('Content-Type', 'application/json');
            res.statusCode = Integer.valueOf(resultMap.get('statusCode'));
            res.responseBody = Blob.valueOf(JSON.serialize(resultMap.get('body')));
            
        } catch (Exception e) {
            System.debug('Error creating an accountt'+ e.getMessage());
            System.debug(e.getStackTraceString());
            handleException(res, e);
        }
    }
    
    /**
     * @description HTTP PATCH - Update customer information
     * Custom Behavior: 
     * - Lookup Strategy: Uses docNumber + docType OR email Query Parameters to identify the Parent Customer
     * - Also supports direct Salesforce ID in path: /customer/{salesforceId}
     * @return JSON response with updated customer or errors
     */
    @HttpPatch
    global static void updateCustomer() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // 1. Extract Salesforce ID from path if present
            String path = req.requestURI;
            String salesforceId = null;
            
            String[] pathSegments = path.split('/');
            String lastSegment = pathSegments[pathSegments.size() - 1];
            
            if (!lastSegment.equalsIgnoreCase('customer')) {
                salesforceId = lastSegment;
            }
            
            // 2. Get query parameters
            Map<String, String> queryParams = req.params;
            
            // 3. Parse request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            // 4. Build identification parameters - move query params to payload
            Map<String, Object> identificationParams = new Map<String, Object>();
            
            if (String.isNotBlank(salesforceId)) {
                identificationParams.put('id', salesforceId);
            }
            
            if (queryParams.containsKey('docNumber') && queryParams.containsKey('docType')) {
                identificationParams.put('docNumber', queryParams.get('docNumber'));
                identificationParams.put('docType', queryParams.get('docType'));
            } else if (queryParams.containsKey('email')) {
                identificationParams.put('email', queryParams.get('email'));
            }
            
            // 5. Add identification to payload
            payload.put('identificationParams', identificationParams);
            
            // 6. Process through TMF629Processing
            FVU_TMF629Processing processor = new FVU_TMF629Processing(); 
            Object result = processor.processRequest('PATCH', payload);
            
            // 7. Set response - follow GET pattern for error handling
            res.statusCode = 200;
            
            if (result instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)result;
                
                // Check if it's an error response from Processing
                if (resultMap.containsKey('status') && resultMap.get('status') == 'error') {
                    List<Map<String,Object>> errors = resultMap.containsKey('errors') ? (List<Map<String,Object>>) resultMap.get('errors') : new List<Map<String,Object>>();
                    String code = !errors.isEmpty() ? (String) errors.get(0).get('status') : '500';
                    res.statusCode = Integer.valueOf(code);
                    
                } else if (resultMap.containsKey('statusCode')) {
                    // If Processing returns statusCode (from IP response), use it
                    res.statusCode = Integer.valueOf(resultMap.get('statusCode'));
                    result = resultMap.get('body');
                }
            }
            
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(result));
            
        } catch (Exception e) {
            System.debug('Error updating customer: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            handleException(res, e);
        }
    }
    
    /**
     * @description Centralized exception handler
     */
    private static void handleException(RestResponse res, Exception e) {
        Map<String, Object> errorResponse = new Map<String, Object>();
        Map<String, Object> error = new Map<String, Object>();
        
        error.put('code', '500');
        error.put('statusmessage', 'INTERNAL_SERVER_ERROR');
        error.put('message', e.getMessage());
        errorResponse.put('status', '500');
        errorResponse.put('timestamp', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        
        res.statusCode = 500;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(error));
    }
}