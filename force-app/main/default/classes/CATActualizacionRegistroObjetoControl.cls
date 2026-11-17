/*******************************************************************************
* Autor: Alan Semino
* Fecha: 2025-09-24
* Equipo: Catálogo
* Code Coverage: 99%
* Descripcion: API que crea una actualización síncrono de campos con datos desde Capa Media al obejto Seguimiento Exportación Datos Canales.
* History
<Date>            <Author>             <Description>       <Version>
2025-09-24        Alan Semino                              Versión Inicial                              
***********************************************************************************/
@RestResource(urlMapping='/actualizacionEstadoExportacionDatos/*')
global with sharing class CATActualizacionRegistroObjetoControl {

    /*
    * @description 634311 - Normaliza un texto removiendo acentos y pasa a minúsculas.
    * @param inputText : Cadena de entrada a normalizar
    * @return : Cadena normalizada en minúsculas sin acentos;
    */
    private static String removeAccents(String inputText) {
    if (String.isBlank(inputText)) return inputText;
        String normalized = inputText.toLowerCase();
        return normalized
        .replaceAll('[áàäâã]','a')
        .replaceAll('[éèëê]','e')
        .replaceAll('[íìïî]','i')
        .replaceAll('[óòöôõ]','o')
        .replaceAll('[úùüû]','u')
        .replaceAll('[ñ]','n');
    }

    /*
    * @description 634311 - Interpreta el valor normalizado y mapea valor  requerido: 'Finalizado con Éxito' o 'Error'.
    * @param  rawStatus : Cadena de estado que envía Capa Media
    * @return: Estados segun estados ingresados desde Capa Media.
    */
    private static String normalizeResultado(String rawStatus) {
        if (String.isBlank(rawStatus)) return null;
        String norm = removeAccents(rawStatus.trim()).toLowerCase();

        if (norm.contains('success') || norm.contains('exito') || norm.contains('complet')) {
         return 'Finalizado con Éxito';
        }
        if (norm.contains('error')|| norm.contains('fallo') || norm.contains('failed') || norm.contains('fail')){
             return 'Error';
        }
        return null;
    }

    /*
    * @description 634311 - Obtiene la fecha/hora actual
    * @return: Cadena con fecha/hora UTC (texto)
    */
    private static String isoNowUtc() {
        Datetime nowUtc = System.now();
        return nowUtc.formatGmt('yyyy-MM-dd') + 'T' + nowUtc.formatGmt('HH:mm:ss') + 'Z';
    }

    /*
    * @description 634311 - Endpoint REST (POST) que actualiza el objeto.
    */
    @HttpPost
    global static void doPost() {
        RestRequest requestRef = RestContext.request;
        RestResponse responseRef = RestContext.response;
        responseRef.addHeader('Content-Type', 'application/json');


        try {
            // Validacion de Body.
            if (requestRef == null || requestRef.requestBody == null) {
                responseRef.statusCode = 400;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => null,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'Body vacío'
                }));
                return;
            }

            //Parseo de JSON
            Map<String,Object> paramMap;
            try {
                paramMap = (Map<String,Object>) JSON.deserializeUntyped(requestRef.requestBody.toString());
            } catch (Exception parseError) {
                responseRef.statusCode = 400;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => null,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'JSON inválido: ' + parseError.getMessage()
                }));
                return;
            }

            //Parámetros de entrada
            String jobIdInput = (String) paramMap.get('jobIdGlobal');
            String fechaInput = (String) paramMap.get('fechaGlobal');
            String resultadoInput = (String) paramMap.get('resultado');
            String detalleInput = (String) paramMap.get('detallesResultado');
            String controlDepuracion = (String)paramMap.get('controlDepuracion');

            //Validaciones (respuesta 400)
            if (String.isBlank(jobIdInput) || String.isBlank(resultadoInput)) {
                responseRef.statusCode = 400;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => jobIdInput,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'Parámetros obligatorios: jobIdGlobal y resultado'
                }));
                return;
            }

            String mappedStatus = normalizeResultado(resultadoInput);
            if (mappedStatus == null) {
                responseRef.statusCode = 400;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => jobIdInput,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'resultado debe contener información'
                }));
                return;
            }

            if ('Error'.equals(mappedStatus) && String.isBlank(detalleInput)) {
                responseRef.statusCode = 400;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => jobIdInput,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'detallesResultado es requerido'
                }));
                return;
            }
            
            //Buscar objeto de SeguimientoProductosExportados
            List<CAT_SeguimientoProductosExportados__c> segList  = [
                SELECT Id, CAT_ResultadoGlobalSeguimiento__c, CAT_ObjetoSeguimiento__c,
                        CAT_JobIdSfSeguimiento__c, CAT_JobIdGlobalSeguimiento__c,
                        CAT_FechaFinGlobalSeguimiento__c
                FROM CAT_SeguimientoProductosExportados__c
                WHERE CAT_JobIdGlobalSeguimiento__c= :jobIdInput
                WITH USER_MODE
                LIMIT 1];

              if (segList.isEmpty()) {
                responseRef.statusCode = 404;
                responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                    'jobIdGlobal'     => jobIdInput,
                    'fechaRespuesta'  => Datetime.now(),
                    'respuesta'       => 'Error',
                    'detalleRespuesta'=> 'Job ID no encontrado'
                }));
                return;
            }

            CAT_SeguimientoProductosExportados__c segRecord = segList[0];

            // Actualización de objeto "CAT_SeguimientoProductosExportados__c"
            segRecord.CAT_ResultadoGlobalSeguimiento__c = mappedStatus;

            Boolean markDep = !String.isBlank(controlDepuracion)&& controlDepuracion.trim().toLowerCase() == 'x';
            if (markDep) {
                // Marca "x" para habilitar nuevos procesos.
                 segRecord.CAT_ObjetoSeguimiento__c = 'X';
            }

            if (!String.isBlank(detalleInput)) {
            segRecord.CAT_DetalleResultadoGlobalSeguimiento__c = detalleInput;
            }

            segRecord.CAT_FechaFinGlobalSeguimiento__c = String.isBlank(fechaInput) ? isoNowUtc() : fechaInput;

            if (String.isBlank(segRecord.CAT_JobIdGlobalSeguimiento__c)) {
                segRecord.CAT_JobIdGlobalSeguimiento__c = jobIdInput;
            }

            update as user segRecord;

            //Respuesta 200
            responseRef.statusCode = 200;
            responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                'jobIdGlobal'     => jobIdInput,
                'fechaRespuesta'  => Datetime.now(),
                'respuesta'       => 'Éxito',
                'detalleRespuesta'=> 'Objeto de seguimiento actualizado correctamente'
            }));

            // Respuesta 500
        } catch (Exception unexpectedError) {
            responseRef.statusCode = 500;
            responseRef.responseBody = Blob.valueOf(JSON.serialize(new Map<String,Object>{
                'jobIdGlobal'     => null,
                'fechaRespuesta'  => Datetime.now(),
                'respuesta'       => 'Error',
                'detalleRespuesta'=> 'Error en el procesamiento: ' + unexpectedError.getMessage()
            }));
        }
    }
}