/**
 * @description Mock implementation of HttpCalloutMock for testing Data Cloud Universal API callouts.
 * Simulates token exchange and all Data Cloud API endpoint responses (ingest, profile, jobs).
 */
@IsTest
public with sharing class DataCloudUniversalProxyAPI_Mock implements HttpCalloutMock {

    /**
     * @description Responds to mock HTTP requests by returning simulated HttpResponse objects
     * for token exchange and Data Cloud API endpoints (ingest, profile, jobs).
     *
     * @param req The incoming HTTPRequest to inspect
     * @return HttpResponse A simulated response for the given test endpoint
     */
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();
        String body = req.getBody() != null ? req.getBody() : '';

        if (endpoint.endsWith('/services/a360/token')) {
            if (body.contains('token_invalido')) {
                res.setStatusCode(401);
                res.setBody('{"error": "invalid_subject_token"}');
            } else if (body.contains('forzar_excepcion')) {
                throw new CalloutException('Error de red simulado en Salesforce');
            } else {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mock_dc_token_12345", "instance_url": "https://mock.c360a.salesforce.com"}');
            }
        } else if (endpoint.contains('/api/v1/profile/')) {
            res.setStatusCode(200);
            res.setBody('{"data": {}}');
        } else if (endpoint.contains('/api/v1/ingest/sources/')) {
            res.setStatusCode(202);
            res.setBody('{"status": "Accepted"}');
        } else if (endpoint.contains('/api/v1/ingest/jobs')) {
            res.setStatusCode(202);
            res.setBody('{"status": "Accepted"}');
        } else {
            res.setStatusCode(200);
            res.setBody('{"status": "OK"}');
        }

        return res;
    }
}