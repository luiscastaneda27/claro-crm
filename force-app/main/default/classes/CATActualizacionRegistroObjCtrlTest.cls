/*******************************************************************************
* Autor: Alan Semino
* Fecha: 2025-09-25
* Equipo: Catálogo
* Code Coverage:
* Descripcion: Clase Test para clase apex CATActualizacionRegistroObjetoControl.
* History
<Date>            <Author>             <Description>       <Version>
2025-09-25        Alan Semino                              Versión Inicial                              
***********************************************************************************/
@isTest
class CATActualizacionRegistroObjCtrlTest {
  
    /*
    * @description 634311 - Configura una petición REST POST con JSON y la carga en RestContext.
    */
    private static void setPostRequest(String bodyJson) {
          RestRequest requestRef = new RestRequest();
          requestRef.requestUri  = '/services/apexrest/actualizacionEstadoExportacionDatos';
          requestRef.httpMethod  = 'POST';
          requestRef.addHeader('Content-Type', 'application/json');
          requestRef.requestBody = Blob.valueOf(bodyJson);

          RestContext.request  = requestRef;
          RestContext.response = new RestResponse();
    }

    /*
    * @description 634311 - Crea una petición POST sin body para validar el 400 por body vacío.
    */
    private static void setEmptyPostRequest() {
        // request sin body para cubrir requestBody == null
        RestRequest requestRef = new RestRequest();
        requestRef.requestUri  = '/services/apexrest/actualizacionEstadoExportacionDatos';
        requestRef.httpMethod  = 'POST';
        RestContext.request  = requestRef;
        RestContext.response = new RestResponse();
    }

    /*
    * @description 634311 - Deserializa el body de la respuesta REST a un Map para asserts.
    */
    private static Map<String, Object> readResponseJson() {
          String raw = RestContext.response.responseBody != null
              ? RestContext.response.responseBody.toString()
              : '{}';
          return (Map<String, Object>) JSON.deserializeUntyped(raw);
    }

    /*
    * @description 634311 - Genera registros de prueba.
    */
    @TestSetup
    static void makeData() {
        //En Progreso para éxito sin depuración
        CAT_SeguimientoProductosExportados__c segOk = new CAT_SeguimientoProductosExportados__c();
        segOk.Name = 'Seguimiento OK';
        segOk.CAT_JobIdGlobalSeguimiento__c = 'J-OK-001';
        segOk.CAT_ResultadoGlobalSeguimiento__c = 'En Progreso';
        insert segOk;

        //En Progreso para error con depuración
        CAT_SeguimientoProductosExportados__c segErrDep = new CAT_SeguimientoProductosExportados__c();
        segErrDep.Name = 'Seguimiento ERR DEP';
        segErrDep.CAT_JobIdGlobalSeguimiento__c = 'J-ERR-DEP-001';
        segErrDep.CAT_ResultadoGlobalSeguimiento__c = 'En Progreso';
        insert segErrDep;

        //En Progreso para error sin depuración (tu código igual marca X por else-if)
        CAT_SeguimientoProductosExportados__c segErrNoDep = new CAT_SeguimientoProductosExportados__c();
        segErrNoDep.Name = 'Seguimiento ERR NODEP';
        segErrNoDep.CAT_JobIdGlobalSeguimiento__c = 'J-ERR-NODEP-001';
        segErrNoDep.CAT_ResultadoGlobalSeguimiento__c = 'En Progreso';
        insert segErrNoDep;

        // En Progreso para isoNowUtc (sin fecha)
        insert new CAT_SeguimientoProductosExportados__c(
            Name = 'Seguimiento NO FECHA',
            CAT_JobIdGlobalSeguimiento__c = 'J-NO-FECHA-001',
            CAT_ResultadoGlobalSeguimiento__c = 'En Progreso'
        );

        // En Progreso para provocar 500 (detalle demasiado largo)
        insert new CAT_SeguimientoProductosExportados__c(
            Name = 'Seguimiento 500',
            CAT_JobIdGlobalSeguimiento__c = 'J-500-001',
            CAT_ResultadoGlobalSeguimiento__c = 'En Progreso'
        );
    }

    /*
    * @description 634311 - Valida el flujo de éxito sin depuración: no marca X, guarda detalle y respeta la fecha enviada.
    */
    @IsTest
    static void testSuccessWithoutDepuracion() {
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-OK-001",' +
          '"resultado":"Extracción completada",' + // normalize
          '"detallesResultado":"Extracción correcta",' +
          '"fechaGlobal":"2025-09-25T12:34:56Z",' +
          '"controlDepuracion":""' +
        '}';

        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> payload = readResponseJson();
        System.assertEquals('Éxito', (String)payload.get('respuesta'));

        CAT_SeguimientoProductosExportados__c rec = [
            SELECT CAT_ResultadoGlobalSeguimiento__c, CAT_ObjetoSeguimiento__c,
                   CAT_DetalleResultadoGlobalSeguimiento__c, CAT_FechaFinGlobalSeguimiento__c,
                   CAT_JobIdGlobalSeguimiento__c
              FROM CAT_SeguimientoProductosExportados__c
             WHERE CAT_JobIdGlobalSeguimiento__c = 'J-OK-001'
             LIMIT 1
        ];

        System.assertEquals('Finalizado con Éxito', rec.CAT_ResultadoGlobalSeguimiento__c);
        System.assertEquals(null, rec.CAT_ObjetoSeguimiento__c, 'No debe marcar X sin controlDepuracion');
        System.assertEquals('Extracción correcta', rec.CAT_DetalleResultadoGlobalSeguimiento__c);
        System.assertEquals('2025-09-25T12:34:56Z', rec.CAT_FechaFinGlobalSeguimiento__c);
        System.assertEquals('J-OK-001', rec.CAT_JobIdGlobalSeguimiento__c,'Debe copiar el jobId al Global si estaba vacío');
    }

    /*
    * @description 634311 - Valida error con controlDepuracion='x': marca X y guarda el detalle de error.
    */
    @IsTest
    static void testErrorWithDepuracionFlag() {
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-ERR-DEP-001",' +
          '"resultado":"Error canal",' + // normalize
          '"detallesResultado":"Falló envío a ECOMMERCE",' +
          '"fechaGlobal":"2025-09-26T08:00:00Z",' +
          '"controlDepuracion":"x"' +
        '}';

        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CAT_SeguimientoProductosExportados__c rec = [
            SELECT CAT_ResultadoGlobalSeguimiento__c, CAT_ObjetoSeguimiento__c,
                   CAT_DetalleResultadoGlobalSeguimiento__c, CAT_FechaFinGlobalSeguimiento__c
              FROM CAT_SeguimientoProductosExportados__c
             WHERE CAT_JobIdGlobalSeguimiento__c = 'J-ERR-DEP-001'
             LIMIT 1
        ];

        System.assertEquals('Error', rec.CAT_ResultadoGlobalSeguimiento__c);
        System.assertEquals('X', rec.CAT_ObjetoSeguimiento__c, 'Debe marcar X por controlDepuracion');
        System.assertEquals('Falló envío a ECOMMERCE', rec.CAT_DetalleResultadoGlobalSeguimiento__c);
        System.assertEquals('2025-09-26T08:00:00Z', rec.CAT_FechaFinGlobalSeguimiento__c);
    }

    /*
    * @description 634311 - Valida error con detalle pero sin depuración.
    */
    @IsTest
    static void testErrorWithoutDepuracionButWithDetail() {
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-ERR-NODEP-001",' +
          '"resultado":"Error",' +
          '"detallesResultado":"Falla de canal",' +
          '"fechaGlobal":"2025-09-27T09:30:00Z",' +
          '"controlDepuracion":""' +
        '}';

        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CAT_SeguimientoProductosExportados__c rec = [
            SELECT CAT_ResultadoGlobalSeguimiento__c, CAT_ObjetoSeguimiento__c,
                   CAT_DetalleResultadoGlobalSeguimiento__c, CAT_FechaFinGlobalSeguimiento__c
              FROM CAT_SeguimientoProductosExportados__c
             WHERE CAT_JobIdGlobalSeguimiento__c = 'J-ERR-NODEP-001'
             LIMIT 1
        ];
        System.assertEquals('Error', rec.CAT_ResultadoGlobalSeguimiento__c);
        System.assertEquals('Falla de canal', rec.CAT_DetalleResultadoGlobalSeguimiento__c);
        System.assertEquals('2025-09-27T09:30:00Z', rec.CAT_FechaFinGlobalSeguimiento__c);
    }

    /*
    * @description 634311 - Valida respuesta 404 cuando el jobIdGlobal no existe.
    */
    @IsTest
    static void testNotFoundReturns404() {
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-NO-EXISTE",' +
          '"resultado":"Success",' +
          '"fechaGlobal":"2025-10-02T00:00:00Z"' +
        '}';

        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    /*
    * @description 634311 - Valida 400 por parámetros obligatorios faltantes (resultado).
    */
    @IsTest
    static void testBadRequestMissingParams() {
        // Falta resultado
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-OK-001",' +
          '"fechaGlobal":"2025-10-03T10:00:00Z"' +
        '}';
        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode);
    }

    /*
    * @description 634311 - Valida 400 cuando la petición llega sin body.
    */
    @IsTest
    static void testBodyEmptyReturns400() {
        setEmptyPostRequest(); // request sin body
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode, 'Debe devolver 400 por body vacío');
    }

    /*
    * @description 634311 - Valida 400 cuando el JSON está malformado.
    */
    @IsTest
    static void testJsonInvalidReturns400_strong() {
      // JSON claramente inválido (coma colgando y llave sin cerrar)
      setPostRequest('{"jobIdGlobal":"X", "resultado":"Success", }');
      Test.startTest();
      CATActualizacionRegistroObjetoControl.doPost();
      Test.stopTest();
      System.assertEquals(400, RestContext.response.statusCode, 'Debe disparar el catch de JSON inválido');
    }

    /*
    * @description 634311 - Valida 400 cuando el resultado no se reconoce
    */
    @IsTest
    static void testMappedStatusNullReturns400() {
      setPostRequest('{' +
          '"jobIdGlobal":"J-OK-001",' +
          '"resultado":"Pendiente",' +      // No lo reconoce normalizeResultado
          '"detallesResultado":"n/a"' +
      '}');
      Test.startTest();
      CATActualizacionRegistroObjetoControl.doPost();
      Test.stopTest();
      System.assertEquals(400, RestContext.response.statusCode, 'mappedStatus == null debe devolver 400');
    }

    /*
    * @description 634311 - Valida 400 cuando resultado=Error no incluye detallesResultado.
    */
    @IsTest
    static void testErrorWithoutDetailsReturns400() {
        // Sin detallesResultado
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-ERR-NODEP-001",' +
          '"resultado":"Error"' +
        '}';
        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode, 'Debe devolver 400 si Error no trae detalles');
    }

    /*
    * @description 634311 - Valida que, sin fecha enviada, se use isoNowUtc().
    */
    @IsTest
    static void testSuccessNoFecha_UsesIsoNowUtc() {
        
        String bodyJson =
        '{' +
          '"jobIdGlobal":"J-NO-FECHA-001",' +
          '"resultado":"Success",' +
          '"detallesResultado":"ok sin fecha",' +
          '"controlDepuracion":""' +
        '}';
        setPostRequest(bodyJson);
        Test.startTest();
        CATActualizacionRegistroObjetoControl.doPost();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);

        CAT_SeguimientoProductosExportados__c rec = [
            SELECT CAT_FechaFinGlobalSeguimiento__c
            FROM CAT_SeguimientoProductosExportados__c
            WHERE CAT_JobIdGlobalSeguimiento__c = 'J-NO-FECHA-001'
            LIMIT 1
        ];
        System.assertNotEquals(null, rec.CAT_FechaFinGlobalSeguimiento__c, 'Debe setear una fecha');
        // Formato ISO: yyyy-MM-ddTHH:mm:ssZ
        String fecha = rec.CAT_FechaFinGlobalSeguimiento__c;
        System.assertEquals(true, fecha.contains('T'), 'Debe contener T');
        System.assertEquals(true, fecha.endsWith('Z'), 'Debe terminar en Z');
        System.assertEquals(20, fecha.length(), 'Debe ser yyyy-MM-ddTHH:mm:ssZ');
    }

    /*
    * @description 634311 - Fuerza DML Exception con detalle >255
    */
    @IsTest
    static void testInternalServerError_DetailTooLong() {
      
      insert new CAT_SeguimientoProductosExportados__c(
          Name = 'Seguimiento 500',
          CAT_JobIdGlobalSeguimiento__c = 'J-500-001',
          CAT_ResultadoGlobalSeguimiento__c = 'En Progreso'
      );
      // 300 caracteres
      String longDetail = String.valueOf('A').repeat(300);

      setPostRequest('{' +
          '"jobIdGlobal":"J-500-001",' +
          '"resultado":"Success",' +
          '"detallesResultado":"' + longDetail + '"' +
      '}');

      Test.startTest();
      CATActualizacionRegistroObjetoControl.doPost();
      Test.stopTest();

      System.assertEquals(500, RestContext.response.statusCode, 'Debe caer en el catch general (500)');
    }
}