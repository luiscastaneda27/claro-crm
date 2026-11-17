/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase apex que hace un callout para notificar la finalización del proceso y registra el JobIdGlobal y la fecha de notificación.
Code Coverage: 93%
History
<Date> 		<Author>	 				<Description>		 				<Version>
26-Sep-25	 Alan Semino  													inicial version
13-Ene-26    Alan Semino  		Update Request/Response (TMF)				V1
----------------------------------------------------------------------------*/
public with sharing class CATNotificationService implements Queueable, Database.AllowsCallouts {

    /*
    * @description 577309 - URL Endpoint para el callout HTTP POST al servicio expuesto.
    */
     private static final String ENDPOINT = 'callout:CapaMediaAuthenticated/ros-rest/APIMProdCatgMng/exportJob';

    /*
    * @description 577309 - Parámetros inmutables del proceso asíncrono.
    */
    private final String jobIdSalesforce, tipoExtraccion, canales;

    /*
    * @description 577309 - Respuesta SUCCESS del servicio.
    */
    private class RosJobSuccessResponse {
        public String id;
        public String creationDate; // viene como String ISO
        public String status;
    }

    /*
    * @description 577309 - Respuesta ERROR del servicio.
    */
    private class RosJobErrorResponse {
        public String code;
        public String message;
        public String status;
    }
     
    /*
    * @description 577309 - Parametros de entrada del proceso asíncrono.
    * @param  jobIdSalesforce: Identificador del proceso en Salesforce para correlación.
    * @param  tipoExtraccion: Tipo de extracción a notificar
    * @param  canales: Canales a notificar
    */
    public CATNotificationService(String jobIdSalesforce, String tipoExtraccion, String canales) {
        this.jobIdSalesforce = jobIdSalesforce;
        this.tipoExtraccion  = tipoExtraccion;
        this.canales         = canales;
    }

    /*
    * @description 577309 - Valida parámetros de entrada y encola la ejecución del proceso (Queueable).
    * @param  objetoControlId : Id del registro de control (para tipo de extraccion, canales y JobId para el request).
    * @return Id del AsyncApexJob encolado.
    */
    public static Id enqueue(String objetoControlId) {
        if (String.isBlank(objetoControlId)) {
            throw new AuraHandledException('objetoControlId es obligatorio.');
        }

        // Query de control
        CAT_Control_Interno_Digital__c ctrl = [SELECT Id, CAT_Listado_Procesar__c, CAT_Tipo__c
            								   FROM CAT_Control_Interno_Digital__c
            								   WHERE Id = :objetoControlId WITH USER_MODE LIMIT 1];

        String jobIdSalesforce = objetoControlId;

        // Normalización de tipo (Total o Parcial a TOTAL o PARCIAL)
        String tipoExtraccion = ctrl.CAT_Tipo__c == null ? '' : ctrl.CAT_Tipo__c.trim().toUpperCase();

        // Normalización de canales
        Set<String> canalesSet = new Set<String>();
        if (!String.isBlank(ctrl.CAT_Listado_Procesar__c)) {
            for (String raw : ctrl.CAT_Listado_Procesar__c.split(';')) {
                String canal = raw == null ? '' : raw.trim().toUpperCase();
                if (!String.isBlank(canal)) canalesSet.add(canal);
            }
        }
        String canales = String.join(new List<String>(canalesSet), ';');

        return System.enqueueJob(new CATNotificationService(jobIdSalesforce, tipoExtraccion, canales));
    }

    /*
    * @description 577309 - Proceso asíncrono (Queueable).
    * @param  qc: Contexto de ejecución del Queueable.
    */
    public void execute(QueueableContext qc) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        // REQUEST (TMF)
        Map<String, Object> payload = new Map<String, Object>();

        payload.put('externalIdentifier', new List<Object>{
            new Map<String, Object>{
                'id'    => jobIdSalesforce,
                'owner' => 'Salesforce'
            }
        });

        payload.put('characteristic', new List<Object>{
            new Map<String, Object>{
                'name'  => 'tipoExtraccion',
                'value' => tipoExtraccion
            },
            new Map<String, Object>{
                'name'  => 'canal',
                'value' => canales
            }
        });

        req.setBody(JSON.serialize(payload));

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception e) {
            System.debug('Error en callout a ROS: ' + e.getMessage());
            finalizeTracking(null, Datetime.now(), 'EXCEPTION: ' + e.getMessage());
            return;
        }

        Integer code = res.getStatusCode();
        String body  = res.getBody();
        System.debug('ROS status=' + code + ' body=' + body);

        // Finaliza por respuesta no exitosa o sin body.
        if (!(code >= 200 && code < 300) || String.isBlank(body)) {
            System.debug('ROS devolvió código no exitoso: ' + code);
            finalizeTracking(null, Datetime.now(), 'HTTP_' + String.valueOf(code) + (String.isBlank(body) ? '_EMPTY_BODY' : ''));
            return;
        }

        try {
            // Parse genérico para decidir si es SUCCESS o ERROR
            Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(body);
            String statusResp = resp != null && resp.get('status') != null ? String.valueOf(resp.get('status')).trim() : null;

            // RESPONSE - ERROR
            if (statusResp != null && statusResp.equalsIgnoreCase('ERROR')) {
                RosJobErrorResponse err = (RosJobErrorResponse) JSON.deserialize(body, RosJobErrorResponse.class);
                String errCode = err.code;
                String errMsg  = err.message;
                
                finalizeTracking(null, Datetime.now(), 'ERROR' + (String.isBlank(errCode) ? '' : ('_' + errCode)) + ': ' + errMsg);
                return;
            }

            // RESPONSE - SUCCESS
            RosJobSuccessResponse success = (RosJobSuccessResponse) JSON.deserialize(body, RosJobSuccessResponse.class);

            // Finaliza marcando JobId (si vino) y creationDate (si viene) -> Datetime
            Datetime completion = null;
            if (success != null && !String.isBlank(success.creationDate)) {
                completion = parseToDatetime(success.creationDate);
            }

            if (completion == null) {
                // fallback si viene sin creationDate o raro
                completion = Datetime.now();
            }

            String finalStatus = (success != null && !String.isBlank(success.status)) ? success.status : 'SUCCESS';
            String rosId = (success != null) ? success.id : null;

            finalizeTracking(rosId, completion, finalStatus);

        } catch (Exception pe) {
            System.debug('No se pudo procesar la respuesta de ROS: ' + pe.getMessage());
            finalizeTracking(null, Datetime.now(), 'UNEXPECTED_RESPONSE: ' + pe.getMessage());
        }
    }

    /*
    * @description 577309 -  Devolución de respuesta del servicio expuesto. 
                             Finaliza el seguimiento (éxito/error/excepción)
    * @param  rosId: Id del JobIdGlobal devuelto por el servicio
    * @param  fecha: Dato de la Fecha/hora de finalización a registrar.
    * @param  status: Detalle del resultado
    */
    private void finalizeTracking(String rosId, Datetime fecha, String status) {
        try {
            CAT_SeguimientoProductosExportados__c seg = [
                SELECT Id, CAT_JobIdGlobalSeguimiento__c, CAT_FechaNotificacionSeguimiento__c, CAT_DetalleResultadoGlobalSeguimiento__c
                FROM CAT_SeguimientoProductosExportados__c
                WHERE CAT_JobIdSfSeguimiento__c = :jobIdSalesforce
                WITH USER_MODE
                LIMIT 1
            ];

            seg.CAT_JobIdGlobalSeguimiento__c = rosId;
            seg.CAT_FechaNotificacionSeguimiento__c = fecha;
            seg.CAT_DetalleResultadoGlobalSeguimiento__c = status;
            update seg;

        } catch (QueryException qx) {
            System.debug('No se encontró seguimiento para jobIdSalesforce=' + jobIdSalesforce);
        } catch (Exception ex) {
            System.debug('Error al finalizar seguimiento: ' + ex.getMessage());
        }
    }

    /*
    * @description 577309 -  Conversión de 'completionDate'a Datetime en GMT
    * @param  iso: Cadena recibida en el JSON para su parseo.
    * @return Datetime : retorna el dato en formato Datetime GMT o null si el formato no es válido.
    */
    @TestVisible private static Datetime parseToDatetime(String iso) {
        if (String.isBlank(iso)) return null;
        try {
            String stringTime = iso.trim();
            if (stringTime.endsWith('Z')) stringTime = stringTime.substring(0, stringTime.length()-1);
            if (stringTime.contains('.')) stringTime = stringTime.substring(0, stringTime.indexOf('.'));
            stringTime = stringTime.replace('T', ' ');
            if (stringTime.length() == 'yyyy-MM-dd HH:mm'.length()) stringTime += ':00';
            return Datetime.valueOfGmt(stringTime);
        } catch (Exception e) {
            System.debug('parseToDatetime falló con "' + iso + '": ' + e.getMessage());
            return null;
        }
    }
}