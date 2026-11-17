/**
 * @description REST API endpoint for TMF622 Product Ordering Management
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
@RestResource(urlMapping='/tmforum/v5/productOrder/*')
global with sharing class FVU_TMF622Rest {
    
    /**
     * @description HTTP POST - Creates a new Product Order
     * @return JSON response with created ticket or errors
     */
    @HttpPost
    global static void createProductOrder() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Parse request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            // Process through TMF622Processing
            FVU_TMF622Processing processor = new FVU_TMF622Processing();
            Object result = processor.processRequest('POST', payload);
            
            // Set response
            Map<String, Object> resultMap = (Map<String, Object>)result;
            
            if (resultMap.containsKey('errors')) {
                // Extract HTTP status from first error
                List<Object> errors = (List<Object>)resultMap.get('errors');
                if (!errors.isEmpty()) {
                    Map<String, Object> firstError = (Map<String, Object>)errors[0];
                    String statusStr = (String)firstError.get('status');
                    res.statusCode = statusStr != null ? Integer.valueOf(statusStr) : 400;
                } else {
                res.statusCode = 400;
                }
            } else {
                res.statusCode = 201;
            }
            
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(result));
            
        } catch (Exception e) {
            handleException(res, e);
        }
    }
    
    /**
     * @description HTTP GET - Retrieves Product Order(s)
     * @return JSON response with ticket(s) or errors
     */
    @HttpGet
    global static void getProductOrders() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Extract query parameters
            Map<String, Object> payload = new Map<String, Object>();
            
            Map<String, String> params = req.params;
            if (params.containsKey('fields')) {
                payload.put('fields', params.get('fields'));
            }
            if (params.containsKey('offset')) {
                payload.put('offset', Integer.valueOf(params.get('offset')));
            }
            if (params.containsKey('limit')) {
                payload.put('limit', Integer.valueOf(params.get('limit')));
            }
            if (params.containsKey('filter')) {
                payload.put('filter', params.get('filter'));
            }
            
            // Check if requesting specific ticket
            String requestUri = req.requestURI;
            if (requestUri.endsWith('/troubleticket/') == false && 
                requestUri.split('/').size() > 4) {
                // Extract ticket ID from URI
                String orderId = requestUri.substringAfterLast('/');
                payload.put('id', orderId);
            }
            
            // Process through TMF622Processing
            FVU_TMF622Processing processor = new FVU_TMF622Processing();
            Object result = processor.processRequest('GET', payload);
            
            // Set response
            Map<String, Object> resultMap = (Map<String, Object>)result;
            
            if (resultMap.containsKey('errors')) {
                res.statusCode = 404;
            } else {
                res.statusCode = 200;
            }
            
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(result));
            
        } catch (Exception e) {
            handleException(res, e);
        }
    }
    
    /**
     * @description HTTP PATCH - Updates an existing Product Order
     * @return JSON response with updated order or errors
     */
    @HttpPatch
    global static void updateProductOrder() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Extract order ID from URI
            String requestUri = req.requestURI;
            String orderId = requestUri.substringAfterLast('/');
            
            // Parse request body
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            payload.put('id', orderId);
            
            // Process through TMF622Processing
            FVU_TMF622Processing processor = new FVU_TMF622Processing();
            Object result = processor.processRequest('PATCH', payload);
            
            // Set response
            Map<String, Object> resultMap = (Map<String, Object>)result;
            
            if (resultMap.containsKey('errors')) {
                List<Object> errors = (List<Object>)resultMap.get('errors');
                Map<String, Object> firstError = (Map<String, Object>)errors[0];
                String status = (String)firstError.get('status');
                res.statusCode = Integer.valueOf(status);
            } else {
                res.statusCode = 200;
            }
            
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serialize(result));
            
        } catch (Exception e) {
            handleException(res, e);
        }
    }
    
    /**
     * @description HTTP DELETE - Deletes a Product Order
     * @return JSON response with status or errors
     */
    @HttpDelete
    global static void deleteProductOrder() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Extract order ID from URI
            String requestUri = req.requestURI;
            String orderId = requestUri.substringAfterLast('/');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('id', orderId);
            
            // Process through TMF622Processing
            FVU_TMF622Processing processor = new FVU_TMF622Processing();
            Object result = processor.processRequest('DELETE', payload);
            
            // Set response
            res.statusCode = 204;
            res.addHeader('Content-Type', 'application/json');
            
        } catch (Exception e) {
            handleException(res, e);
        }
    }
    
    /**
     * @description Centralized exception handler
     */
    private static void handleException(RestResponse res, Exception e) {
        Map<String, Object> errorResponse = new Map<String, Object>();
        errorResponse.put('status', 'error');
        
        List<Map<String, Object>> errors = new List<Map<String, Object>>();
        Map<String, Object> error = new Map<String, Object>();
        error.put('code', 'TMF-500-999');
        error.put('message', e.getMessage());
        error.put('status', '500');
        errors.add(error);
        
        errorResponse.put('errors', errors);
        errorResponse.put('timestamp', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        
        res.statusCode = 500;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
    }
}