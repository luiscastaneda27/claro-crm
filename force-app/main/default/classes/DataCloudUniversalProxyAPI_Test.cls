@IsTest
public with sharing class DataCloudUniversalProxyAPI_Test {

    /**
     * @description Crea el usuario de prueba con perfil de administrador utilizado en todos los métodos @IsTest de la clase.
     */
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE PermissionsModifyAllData = true LIMIT 1];

        String uniqueSuffix = String.valueOf(DateTime.now().getTime());

        User testUser = new User(
            Alias = 'usrtest',
            Email = 'testproxy@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestingProxy',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Bogota',
            UserName = 'integration_test_' + uniqueSuffix + '@example.com.devkairos'
        );
        insert testUser;
    }

    /**
     * @description Recupera el usuario de prueba creado en setupTestData para usarlo con System.runAs.
     * @return User El usuario de prueba con alias 'usrtest'.
     */
    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Alias = 'usrtest' AND LastName = 'TestingProxy' LIMIT 1];
    }

    private class RestContextConfig {
        String method;
        String targetPath;
        Map<String, String> queryParams;
        String payload;
        Boolean skipContentType;

        /**
         * @description Inicializa la configuración con el método HTTP y la ruta destino; Content-Type se incluye por defecto.
         * @param method Método HTTP (GET, POST, PUT, PATCH, DELETE).
         * @param targetPath Segmento de ruta que se añade al URI base del proxy.
         */
        RestContextConfig(String method, String targetPath) {
            this.method = method;
            this.targetPath = targetPath;
            this.skipContentType = false;
        }
    }

    /**
     * @description Configura RestContext.request y RestContext.response a partir de un RestContextConfig,
     *              permitiendo simular llamadas REST entrantes en los métodos de prueba.
     * @param config Objeto con el método HTTP, ruta, query params, payload y flag de Content-Type.
     */
    private static void configureRestContext(RestContextConfig config) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String baseUri = '/services/apexrest/DataCloud/UniversalProxy';
        req.requestURI = baseUri + (config.targetPath != null ? config.targetPath : '');
        req.httpMethod = config.method;

        if (!config.skipContentType) {
            req.headers.put('Content-Type', 'application/json');
        }

        if (config.queryParams != null && !config.queryParams.isEmpty()) {
            req.params.putAll(config.queryParams);
        }

        if (config.payload != null) {
            req.requestBody = Blob.valueOf(config.payload);
        }

        RestContext.request = req;
        RestContext.response = res;
    }

    /**
     * @description POST exitoso a Ingestion API — verifica 202 Accepted.
     */
    @IsTest
    static void handlePostSuccess() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('POST', '/api/v1/ingest/sources/API/Pago');
            config.payload = '{"data":[{"custcode":"33333"}]}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePost();
            Test.stopTest();

            Assert.areEqual(202, RestContext.response.statusCode, 'El POST debe ser exitoso y devolver 202 Accepted');
        }
    }

    /**
     * @description GET exitoso a Profile API con query parameters — verifica 200 OK.
     */
    @IsTest
    static void handleGetSuccess() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('GET', '/api/v1/profile/UnifiedIndividual__dlm/123');
            config.queryParams = new Map<String, String>{'fields' => 'FirstName__c'};
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handleGet();
            Test.stopTest();

            Assert.areEqual(200, RestContext.response.statusCode, 'El GET debe ser exitoso y devolver 200 OK');
        }
    }

    /**
     * @description PUT exitoso a ingest/jobs — verifica 202 Accepted.
     */
    @IsTest
    static void handlePutSuccess() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('PUT', '/api/v1/ingest/jobs');
            config.payload = '{"object":"Order"}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePut();
            Test.stopTest();

            Assert.areEqual(202, RestContext.response.statusCode, 'El PUT debe ser exitoso (202)');
        }
    }

    /**
     * @description PATCH exitoso a ingest/jobs — verifica 202 Accepted.
     */
    @IsTest
    static void handlePatchSuccess() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('PATCH', '/api/v1/ingest/jobs/123');
            config.payload = '{"state":"UploadComplete"}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePatch();
            Test.stopTest();

            Assert.areEqual(202, RestContext.response.statusCode, 'El PATCH debe ser exitoso (202)');
        }
    }

    /**
     * @description DELETE exitoso a ingest/sources — verifica 202 Accepted.
     */
    @IsTest
    static void handleDeleteSuccess() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('DELETE', '/api/v1/ingest/sources/API/Pago');
            config.queryParams = new Map<String, String>{'ids' => '12345'};
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handleDelete();
            Test.stopTest();

            Assert.areEqual(202, RestContext.response.statusCode, 'El DELETE debe ser exitoso (202)');
        }
    }

    /**
     * @description Token Exchange fallido — el proxy propaga el 401 recibido de /services/a360/token.
     */
    @IsTest
    static void exchangeTokenFailure() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new TokenExchangeErrorMock());

            RestContextConfig config = new RestContextConfig('POST', '/api/v1/ingest/error_401');
            config.payload = '{"data":[]}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePost();
            Test.stopTest();

            Assert.areEqual(401, RestContext.response.statusCode, 'El proxy debe propagar el error 401 si falla el Token Exchange en Salesforce');
        }
    }

    /**
     * @description Excepción no controlada — el proxy captura el error y devuelve 500 con mensaje de error interno.
     */
    @IsTest
    static void internalExceptionHandling() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new InternalErrorMock());

            RestContextConfig config = new RestContextConfig('POST', '/api/v1/ingest/forzar_excepcion');
            config.payload = '{"data":[]}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePost();
            Test.stopTest();

            Assert.areEqual(500, RestContext.response.statusCode, 'El proxy debe capturar excepciones no controladas y devolver 500 Internal Server Error');
            Assert.isTrue(RestContext.response.responseBody.toString().contains('Error interno'), 'El JSON de respuesta debe indicar un error interno del Gateway');
        }
    }

    /**
     * @description Ruta no autorizada — validateAllowedPath devuelve 403 con mensaje descriptivo.
     */
    @IsTest
    static void validateAllowedPathReturns403ForUnauthorizedPath() {
        System.runAs(getTestUser()) {
            RestContextConfig config = new RestContextConfig('POST', '/unauthorized_path_test_xyz');
            config.payload = '{"data":[]}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePost();
            Test.stopTest();

            Assert.areEqual(403, RestContext.response.statusCode, 'El proxy debe rechazar rutas no autorizadas con 403 Forbidden');
            Assert.isTrue(
                RestContext.response.responseBody.toString().contains('no está autorizada'),
                'La respuesta debe indicar que la ruta no está autorizada'
            );
        }
    }

    /**
     * @description Respuesta con body no-JSON de Data Cloud — cubre el catch de JSON.deserializeUntyped (líneas 272-273).
     */
    @IsTest
    static void handleResponseWithNonJsonBody() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new NonJsonResponseMock());
            RestContextConfig config = new RestContextConfig('POST', '/api/v1/ingest/sources/API/Pago');
            config.payload = '{"data":[{"custcode":"99999"}]}';
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handlePost();
            Test.stopTest();

            String responseStr = RestContext.response.responseBody.toString();
            Assert.isTrue(responseStr.contains('originalBody'), 'Cuando Data Cloud devuelve texto plano, la respuesta debe contener originalBody');
            Assert.isTrue(responseStr.contains('statusCode'), 'La respuesta siempre debe incluir statusCode');
        }
    }

    /**
     * @description GET sin Content-Type — cubre la rama false de isNotBlank en sendDataCloudRequest.
     */
    @IsTest
    static void handleGetSuccessWithoutContentType() {
        System.runAs(getTestUser()) {
            Test.setMock(HttpCalloutMock.class, new DataCloudUniversalProxyAPI_Mock());
            RestContextConfig config = new RestContextConfig('GET', '/api/v1/profile/UnifiedIndividual__dlm/456');
            config.skipContentType = true;
            configureRestContext(config);

            Test.startTest();
            DataCloudUniversalProxyAPI.handleGet();
            Test.stopTest();

            Assert.areEqual(200, RestContext.response.statusCode, 'GET sin Content-Type debe completarse exitosamente');
        }
    }

    // ============================================================================
    // CLASES MOCK INTERNAS PARA ESCENARIOS DE ERROR
    // ============================================================================

    private class TokenExchangeErrorMock implements HttpCalloutMock {
        /**
         * @description Responds to an HTTP request with a mocked HttpResponse. If the
         * request endpoint contains '/services/a360/token' a 401 response with an
         * authentication failure body is returned; otherwise a 200 status is returned.
         * @param req The incoming HTTPRequest to process
         * @return HttpResponse The generated HttpResponse
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/services/a360/token')) {
                res.setStatusCode(401);
                res.setBody('{"error": "invalid_grant", "error_description": "authentication failure"}');
            } else {
                res.setStatusCode(200);
            }
            return res;
        }
    }

    private class InternalErrorMock implements HttpCalloutMock {

        /**
         * @description Responds to an HTTP request by throwing a CalloutException indicating a read timeout from Data Cloud.
         * @param req The incoming HTTPRequest.
         * @return HTTPResponse (not returned because an exception is thrown).
         */
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Read timed out from Data Cloud');
        }
    }

    private class NonJsonResponseMock implements HttpCalloutMock {
        /**
         * @description Token exchange returns valid JSON; the Data Cloud endpoint returns
         * plain text so that JSON.deserializeUntyped throws and the catch branch on
         * line 273 (originalBody fallback) is exercised.
         *
         * @param req The incoming HTTPRequest to handle
         * @return HttpResponse containing the mocked response body and status
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('/services/a360/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mock_dc_token_12345", "instance_url": "https://mock.c360a.salesforce.com"}');
            } else {
                res.setStatusCode(202);
                res.setBody('Operation accepted');
            }
            return res;
        }
    }
}