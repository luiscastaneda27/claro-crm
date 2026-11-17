/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase apex test para clase apex CATNotificationService.
Code Coverage: -
History
<Date> 			<Author>	 				<Description>		 		<Version>
07-Oct-25	   Alan Semino  											inicial version
13-Ene-26      Alan Semino  		Update Request/Response (TMF)		V1
----------------------------------------------------------------------------*/
@IsTest
class CATNotificationServiceTest {

    /*
    * @description 577309 - Creación de datos de prueba: Objeto Control Interno (Id) y Seguimiento Productos Exportados (JobId)
    */
    @TestSetup
    static void setupData() {

        CAT_Control_Interno_Digital__c ctrl = new CAT_Control_Interno_Digital__c(
            Name                   = 'CTRL-TEST',
            CAT_Tipo__c            = 'Total',
            CAT_Listado_Procesar__c= 'ECOMMERCE'
        );
        insert ctrl;

        insert new CAT_SeguimientoProductosExportados__c(
            Name = 'Seg-Test',
            CAT_JobIdSfSeguimiento__c = ctrl.Id
        );
    }

    // obtener Id del control creado en TestSetup
    private static Id getControlId() {
        return [SELECT Id FROM CAT_Control_Interno_Digital__c WHERE Name = 'CTRL-TEST' LIMIT 1].Id;
    }

    // obtener seguimiento por JobIdSf
    private static CAT_SeguimientoProductosExportados__c getSegByJobId(Id controlId) {
        return [SELECT CAT_JobIdGlobalSeguimiento__c, CAT_FechaNotificacionSeguimiento__c, CAT_DetalleResultadoGlobalSeguimiento__c
            	FROM CAT_SeguimientoProductosExportados__c
            	WHERE CAT_JobIdSfSeguimiento__c = :controlId LIMIT 1];
    }

    /*
    * Helpers para REQUEST (TMF)
    */
    private static void assertTmfRequest(HttpRequest req, Id expectedControlId) {
        System.assertEquals('POST', req.getMethod(), 'Método esperado POST');
        System.assert(req.getEndpoint().endsWith('/exportJob'), 'Debe terminar en /exportJob');

        String body = req.getBody();
        System.assert(!String.isBlank(body), 'Body no puede venir vacío');

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);

        // externalIdentifier
        System.assert(root.containsKey('externalIdentifier'), 'Debe venir externalIdentifier');
        List<Object> ext = (List<Object>) root.get('externalIdentifier');
        System.assert(ext != null && !ext.isEmpty(), 'externalIdentifier no puede venir vacío');

        Map<String, Object> ext0 = (Map<String, Object>) ext[0];
        System.assertEquals(String.valueOf(expectedControlId), String.valueOf(ext0.get('id')), 'id debe ser el controlId');
        System.assertEquals('Salesforce', String.valueOf(ext0.get('owner')), 'owner debe ser Salesforce');

        // characteristic
        System.assert(root.containsKey('characteristic'), 'Debe venir characteristic');
        List<Object> chars = (List<Object>) root.get('characteristic');
        System.assert(chars != null && chars.size() >= 2, 'characteristic debe traer al menos 2 elementos');

        Map<String, String> charMap = new Map<String, String>();
        for (Object o : chars) {
            Map<String, Object> c = (Map<String, Object>) o;
            String name  = c.get('name')  == null ? null : String.valueOf(c.get('name'));
            String value = c.get('value') == null ? null : String.valueOf(c.get('value'));
            if (!String.isBlank(name)) charMap.put(name, value);
        }

        System.assertEquals('TOTAL', charMap.get('tipoExtraccion'), 'tipoExtraccion debe ir normalizado');
        System.assertEquals('ECOMMERCE', charMap.get('canal'), 'canal debe ir normalizado');
    }

    /*
    * @description 577309 - Mock que simula 200 OK (SUCCESS con creationDate)
    */
    private class SuccessWithDateMock implements HttpCalloutMock {
        private final Id expectedControlId;
        SuccessWithDateMock(Id expectedControlId) {
            this.expectedControlId = expectedControlId;
        }
        public HttpResponse respond(HttpRequest req) {
            assertTmfRequest(req, expectedControlId);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            // NUEVO: creationDate (no completionDate)
            res.setBody('{"id":"59966864","creationDate":"2025-09-08T18:01:09.45Z","status":"Succeeded"}');
            return res;
        }
    }

    /*
    * @description 577309 - Mock que simula 200 OK sin creationDate
    */
    private class SuccessNoDateMock implements HttpCalloutMock {
        private final Id expectedControlId;
        SuccessNoDateMock(Id expectedControlId) {
            this.expectedControlId = expectedControlId;
        }
        public HttpResponse respond(HttpRequest req) {
            assertTmfRequest(req, expectedControlId);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody('{"id":"111","status":"Succeeded"}');
            return res;
        }
    }

    /*
    * @description 577309 - Mock que simula 200 OK con payload ERROR
    */
    private class ErrorPayloadMock implements HttpCalloutMock {
        private final Id expectedControlId;
        ErrorPayloadMock(Id expectedControlId) {
            this.expectedControlId = expectedControlId;
        }
        public HttpResponse respond(HttpRequest req) {
            assertTmfRequest(req, expectedControlId);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody('{"code":"-1","message":"Missing required body property: externalIdentifier","status":"ERROR"}');
            return res;
        }
    }

    /*
    * @description 577309 - Mock que simula 500
    */
    private class Error500Mock implements HttpCalloutMock {
        private final Id expectedControlId;
        Error500Mock(Id expectedControlId) {
            this.expectedControlId = expectedControlId;
        }
        public HttpResponse respond(HttpRequest req) {
            // Para 500 igual validamos que el request sea TMF
            assertTmfRequest(req, expectedControlId);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type','application/json');
            res.setBody('{"error":"server error"}');
            return res;
        }
    }

    /*
    * @description 577309 - Mock que simula 200 OK pero JSON inválido
    */
    private class InvalidJsonMock implements HttpCalloutMock {
        private final Id expectedControlId;
        InvalidJsonMock(Id expectedControlId) {
            this.expectedControlId = expectedControlId;
        }
        public HttpResponse respond(HttpRequest req) {
            assertTmfRequest(req, expectedControlId);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type','application/json');
            res.setBody('json'); // inválido a propósito
            return res;
        }
    }

    /*
    * @description 577309 - Valida un proceso success (con creationDate)
    */
    @IsTest
    static void test_success() {
        Id controlId = getControlId();

        Test.setMock(HttpCalloutMock.class, new SuccessWithDateMock(controlId));
        Test.startTest();
        Id asyncJobId = CATNotificationService.enqueue(controlId);
        Test.stopTest();

        CAT_SeguimientoProductosExportados__c out = getSegByJobId(controlId);
        System.assertEquals('59966864', out.CAT_JobIdGlobalSeguimiento__c, 'Debe guardar el id de ROS');

        Datetime expected = Datetime.newInstanceGmt(2025, 9, 8, 18, 1, 9);
        System.assertEquals(expected, out.CAT_FechaNotificacionSeguimiento__c, 'Debe parsear creationDate ISO');
        
        System.assertEquals('Succeeded', out.CAT_DetalleResultadoGlobalSeguimiento__c, 'Debe guardar el status del JSON');
    }

    /*
    * @description 577309 - Valida fallback cuando no viene creationDate.
    */
    @IsTest
    static void test_success_without_date() {
        Id controlId = getControlId();

        Test.setMock(HttpCalloutMock.class, new SuccessNoDateMock(controlId));
        Test.startTest();
        Id asyncJobId = CATNotificationService.enqueue(controlId);
        Test.stopTest();

        CAT_SeguimientoProductosExportados__c out = getSegByJobId(controlId);
        System.assertEquals('111', out.CAT_JobIdGlobalSeguimiento__c, 'Debe guardar el id cuando viene en el JSON');
        System.assertNotEquals(null, out.CAT_FechaNotificacionSeguimiento__c, 'Debe tener fecha');

        Long deltaMs = Math.abs(out.CAT_FechaNotificacionSeguimiento__c.getTime() - System.now().getTime());
        System.assert(deltaMs <= 60000, 'La fecha (now()) debe quedar cercana a la ejecución');
        
        System.assertEquals('Succeeded', out.CAT_DetalleResultadoGlobalSeguimiento__c, 'Debe guardar el status del JSON');
    }

    /*
    * @description 577309 - Valida finalización (error 500)
    */
    @IsTest
    static void test_error_500() {
        Id controlId = getControlId();

        Test.setMock(HttpCalloutMock.class, new Error500Mock(controlId));
        Test.startTest();
        Id asyncJobId = CATNotificationService.enqueue(controlId);
        Test.stopTest();

        CAT_SeguimientoProductosExportados__c out = getSegByJobId(controlId);
        System.assertEquals(null, out.CAT_JobIdGlobalSeguimiento__c, 'En error, el id debe quedar null');

        Long deltaMs = Math.abs(out.CAT_FechaNotificacionSeguimiento__c.getTime() - System.now().getTime());
        System.assert(deltaMs <= 60000, 'Debe finalizar con fecha now()');
        
        System.assertEquals('HTTP_500', out.CAT_DetalleResultadoGlobalSeguimiento__c, 'Debe guardar el detalle HTTP_500');
    }

    /*
    * @description 577309 - Valida manejo de JSON inválido
    */
    @IsTest
    static void test_invalid_json() {
        Id controlId = getControlId();

        Test.setMock(HttpCalloutMock.class, new InvalidJsonMock(controlId));
        Test.startTest();
        Id asyncJobId = CATNotificationService.enqueue(controlId);
        Test.stopTest();

        CAT_SeguimientoProductosExportados__c out = getSegByJobId(controlId);
        System.assertEquals(null, out.CAT_JobIdGlobalSeguimiento__c, 'Sin JSON válido no debe setear id');

        Long deltaMs = Math.abs(out.CAT_FechaNotificacionSeguimiento__c.getTime() - System.now().getTime());
        System.assert(deltaMs <= 60000, 'Debe finalizar con fecha now() en parseo inválido');

        System.assert(out.CAT_DetalleResultadoGlobalSeguimiento__c != null && out.CAT_DetalleResultadoGlobalSeguimiento__c.startsWith('UNEXPECTED_RESPONSE'),'Debe guardar UNEXPECTED_RESPONSE en detalle');
    }

    /*
    * @description 577309 - Valida respuesta ERROR (status=ERROR con code/message)
    */
    @IsTest
    static void test_error_payload() {
        Id controlId = getControlId();

        Test.setMock(HttpCalloutMock.class, new ErrorPayloadMock(controlId));
        Test.startTest();
        Id asyncJobId = CATNotificationService.enqueue(controlId);
        Test.stopTest();

        CAT_SeguimientoProductosExportados__c out = getSegByJobId(controlId);

        System.assertEquals(null, out.CAT_JobIdGlobalSeguimiento__c, 'En error payload, el id debe quedar null');
        System.assertNotEquals(null, out.CAT_FechaNotificacionSeguimiento__c, 'Debe finalizar con fecha');
        
        System.assert(out.CAT_DetalleResultadoGlobalSeguimiento__c != null && out.CAT_DetalleResultadoGlobalSeguimiento__c.startsWith('ERROR_-1:'),'Debe guardar ERROR_-1');
    }

    /*
    * @description 577309 - Cubre catch de parseToDatetime
    */
    @IsTest
    static void test_parseToDatetime_invalido() {
        Datetime out = CATNotificationService.parseToDatetime('2025-0X-ABTaa:bb:ccZ');
        System.assertEquals(null, out, 'formato inválido, debe retornar null');
    }
}