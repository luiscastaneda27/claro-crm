/**
 * @description Acts as a universal gateway proxy for Data Cloud endpoints. Exposes REST entry
 * points for GET, POST, PUT, PATCH and DELETE and forwards requests to the
 * configured Data Cloud callout after validating headers, allowed paths and
 * exchanging tokens.
 *
 * Allowed path prefixes are driven by DC_Allowed_Path__mdt records so they can
 * be managed without a code deployment.
 */
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
@RestResource(urlMapping='/DataCloud/UniversalProxy/*')
global with sharing class DataCloudUniversalProxyAPI {

    /**
     * @description Parameter wrapper used to pass request data to sendDataCloudRequest
     * without exceeding the recommended parameter count.
     */
    private class DataCloudRequestParams {
        String httpMethod;
        String endpoint;
        String dcToken;
        HttpRequestData requestData;
    }

    /**
     * @description Wrapper for the inbound HTTP request payload.
     * Bundles content type and body so they travel together through the call chain.
     *
     * @param contentType  Value of the inbound Content-Type header.
     * @param requestBody  Raw body of the inbound request as a Blob.
     */
    private class HttpRequestData {
        String contentType;
        Blob requestBody;

        HttpRequestData(String contentType, Blob requestBody) {
            this.contentType = contentType;
            this.requestBody = requestBody;
        }
    }

    // ── HTTP verb interceptors ────────────────────────────────────────────────

    /**
     * @description Handles HTTP GET requests by delegating to processRequest.
     * @see #processRequest(String)
     */
    @HttpGet
    global static void handleGet() { processRequest('GET'); }

    /**
     * @description Handles HTTP POST requests by delegating to processRequest.
     * @see #processRequest(String)
     */
    @HttpPost
    global static void handlePost() { processRequest('POST'); }

    /**
     * @description Handles HTTP PUT requests by delegating to processRequest.
     * @see #processRequest(String)
     */
    @HttpPut
    global static void handlePut() { processRequest('PUT'); }

    /**
     * @description Handles HTTP PATCH requests by delegating to processRequest.
     * @see #processRequest(String)
     */
    @HttpPatch
    global static void handlePatch() { processRequest('PATCH'); }

    /**
     * @description Handles HTTP DELETE requests by delegating to processRequest.
     * This global method is exposed for external callers and must remain global.
     * @see #processRequest(String)
     */
    @HttpDelete
    global static void handleDelete() { processRequest('DELETE'); }

    // ── Central dispatcher ────────────────────────────────────────────────────

    /**
     * @description Central dispatch method invoked by every HTTP verb handler.
     *
     * Orchestrates the full proxy flow in order:
     *   1. Reads the Core session token from the current user context.
     *   2. Extracts the target URI from the inbound request path.
     *   3. Validates the target URI against the CMT-backed allowlist.
     *   4. Builds the forwarded query string from inbound parameters.
     *   5. Exchanges the Core token for a Data Cloud-scoped token.
     *   6. Forwards the request to Data Cloud via the named credential callout.
     *
     * Writes directly to RestContext.response; returns void.
     * Sets HTTP 500 with a generic error body on any unhandled exception.
     *
     * @param httpMethod  The HTTP verb to forward (GET, POST, PUT, PATCH, DELETE).
     */
    private static void processRequest(String httpMethod) {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String coreToken = UserInfo.getSessionId();
            String targetUri = req.requestURI.substringAfter('/DataCloud/UniversalProxy');

            if (!validateAllowedPath(targetUri, res)) {
                return;
            }

            String queryString = buildQueryString(req.params);

            String dcToken = exchangeToken(coreToken, res);
            if (dcToken == null) {
                return;
            }

            DataCloudRequestParams params = new DataCloudRequestParams();
            params.httpMethod  = httpMethod;
            params.endpoint    = targetUri + queryString;
            params.dcToken     = dcToken;
            params.requestData = new HttpRequestData(req.headers.get('Content-Type'), req.requestBody);

            sendDataCloudRequest(params, res);

        } catch (Exception e) {
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf('{"error": "Error interno del Gateway Universal"}');
        }
    }

    // ── Path validation via Custom Metadata ──────────────────────────────────

    /**
     * @description Validates that the target URI starts with one of the allowed path prefixes.
     *
     * Queries active DC_Allowed_Path__mdt records and checks whether targetUri
     * starts with any of their Path_Prefix__c values. To add or remove an allowed
     * prefix, create or deactivate a CMT record — no code change required.
     *
     * @param targetUri  The extracted URI path to validate.
     * @param res        The RestResponse to populate if access is denied.
     * @return           true if the URI matches an active prefix; false otherwise.
     *                   Sets HTTP 403 on the response when returning false.
     */
    private static Boolean validateAllowedPath(String targetUri, RestResponse res) {
        List<DC_Allowed_Path__mdt> allowedPaths = [
            SELECT Path_Prefix__c
            FROM   DC_Allowed_Path__mdt
            WHERE  Is_Active__c = TRUE
            WITH USER_MODE
        ];

        for (DC_Allowed_Path__mdt record : allowedPaths) {
            if (targetUri.startsWith(record.Path_Prefix__c)) {
                return true;
            }
        }

        res.statusCode   = 403;
        res.responseBody = Blob.valueOf(
            '{"error": "La ruta de destino solicitada no está autorizada en el Gateway [' + targetUri + '] "}'
        );
        return false;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * @description Builds a URL-encoded query string from the inbound request parameters map.
     *
     * Keys and values are individually encoded with UTF-8 to prevent injection.
     * Returns an empty string when the map is null or empty so callers can
     * concatenate the result directly onto the endpoint without a null check.
     *
     * @param params  Map of query parameter key-value pairs from the inbound request.
     * @return        A query string starting with '?' (e.g. '?key=value&key2=value2'),
     *                or an empty string if params is null or empty.
     */
    private static String buildQueryString(Map<String, String> params) {
        if (params == null || params.isEmpty()) {
            return '';
        }
        String queryString = '?';
        for (String key : params.keySet()) {
            queryString += EncodingUtil.urlEncode(key, 'UTF-8') + '=' +
                           EncodingUtil.urlEncode(params.get(key), 'UTF-8') + '&';
        }
        return queryString.removeEnd('&');
    }

    /**
     * @description Exchanges a Salesforce Core session token for a Data Cloud-scoped access token.
     *
     * Calls the /services/a360/token endpoint of the current org using the
     * urn:salesforce:grant-type:external:cdp grant type. On success, returns the
     * access_token string from the JSON response. On failure, propagates the
     * upstream status code and body to the caller's RestResponse and returns null.
     *
     * @param coreToken  The Salesforce session ID obtained from UserInfo.getSessionId().
     * @param res        The RestResponse to populate if the exchange fails.
     * @return           The Data Cloud access token string, or null on failure.
     */
    private static String exchangeToken(String coreToken, RestResponse res) {
        Http        http        = new Http();
        HttpRequest exchangeReq = new HttpRequest();
        exchangeReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/a360/token');
        exchangeReq.setMethod('POST');
        exchangeReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        exchangeReq.setTimeout(15000);

        String encodedToken = EncodingUtil.urlEncode(coreToken, 'UTF-8');
        exchangeReq.setBody(
            'grant_type=urn:salesforce:grant-type:external:cdp' +
            '&subject_token='      + encodedToken +
            '&subject_token_type=urn:ietf:params:oauth:token-type:access_token'
        );

        HttpResponse exchangeRes = http.send(exchangeReq);

        if (exchangeRes.getStatusCode() != 200) {
            res.statusCode   = exchangeRes.getStatusCode();
            res.responseBody = exchangeRes.getBodyAsBlob();
            return null;
        }

        Map<String, Object> exchangeMap =
            (Map<String, Object>) JSON.deserializeUntyped(exchangeRes.getBody());
        return (String) exchangeMap.get('access_token');
    }

    /**
     * @description Forwards the prepared request to the Data Cloud endpoint via named credential.
     *
     * Constructs an HttpRequest from the provided params, attaches the Data Cloud
     * Bearer token, and conditionally sets the body for write verbs (POST, PUT, PATCH).
     * The upstream response status code and body are written directly to res.
     *
     * @param params  Fully populated DataCloudRequestParams with method, endpoint,
     *                DC token, and request data.
     * @param res     The RestResponse that will receive the upstream status and body.
     */
    private static void sendDataCloudRequest(DataCloudRequestParams params, RestResponse res) {
        Http        http  = new Http();
        HttpRequest dcReq = new HttpRequest();
        dcReq.setEndpoint('callout:DataCloud_Ingestion_API' + params.endpoint);
        dcReq.setMethod(params.httpMethod);
        dcReq.setHeader('Authorization', 'Bearer ' + params.dcToken);
        dcReq.setTimeout(20000);

        if (String.isNotBlank(params.requestData.contentType)) {
            dcReq.setHeader('Content-Type', params.requestData.contentType);
        }

        if (params.requestData.requestBody != null &&
            (params.httpMethod == 'POST' || params.httpMethod == 'PUT' || params.httpMethod == 'PATCH')) {
            dcReq.setBodyAsBlob(params.requestData.requestBody);
        }

        HttpResponse dcRes   = http.send(dcReq);
        res.statusCode       = dcRes.getStatusCode();

        Map<String, Object> responseBodyMap = new Map<String, Object>();
        String rawBody = dcRes.getBody();
        
        if (String.isNotBlank(rawBody)) {
            try {
                responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(rawBody);
            } catch (Exception e) {
                responseBodyMap.put('originalBody', rawBody);
            }
        }
        
        responseBodyMap.put('statusCode', dcRes.getStatusCode());
        
        res.responseBody = Blob.valueOf(JSON.serialize(responseBodyMap));
    }
}