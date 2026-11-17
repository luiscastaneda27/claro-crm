/*******************************************************************************
* Autor: Nahir Arrejoria
* Fecha: 2025-05-06
* Equipo: Catálogo
* Code Coverage:82%
* Descripcion: Servicio para consultar gestiones Masivas
* History
<Date>          <Author>             <Description>                                <Version>
2025-05-06      Nahir Arrejoria      Versión Inicial                                 01
2025-09-03		Nahir Arrejoria		Se modifica forma de calcular registros pendientes 01.1
***********************************************************************************/
@RestResource(urlMapping='/consultaJobActualizacionPrecios/*')
global with sharing class CAT_consultaJobActualizacionPrecios {
    global class responseObject {
        public Boolean jobComplete;
        public Integer completedRecords;
        public Integer pendingRecords;
        public Integer errorRecords;
        public Integer total;
        public String jobId;
        public String message;


        public responseObject(String message){
            this.message = message;
        }


        public responseObject(String jobId, Integer completedRecords,Integer pendingRecords, Integer errorRecords, Integer total , Boolean jobComplete) {
            this.jobId = jobId;
            this.completedRecords = completedRecords;
            this.pendingRecords = pendingRecords;
            this.errorRecords = errorRecords;
            this.total = total;
            this.jobComplete = jobComplete;   
        }
    }

    @HttpGet
    global static responseObject getNumber() {
         try {
            // Obtener parámetros de la solicitud
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            String jobId; 
            String internalJobId = req.params.get('jobId');
            String externalJobId = req.params.get('externalJobId');
            // Validar parámetro
            if (!String.isEmpty(internalJobId) ) {
                jobId = internalJobId;
            } else if (!String.isEmpty(externalJobId) ) {
                List<CAT_Informacion_Precios_SAP_tmp__c> infoPrecios = [SELECT Id,CAT_Id_Job_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE CAT_Id_Job_Externo__c =:externalJobId WITH USER_MODE];          
                if (infoPrecios.isEmpty() == false && infoPrecios[0].CAT_Id_Job_Procesamiento__c == null){
                    return new responseObject('Aún no se ha solicitado inicio de procesamiento para el job ' + externalJobId);
                } else if (infoPrecios.isEmpty() == false){
                    jobId = infoPrecios[0].CAT_Id_Job_Procesamiento__c;
                }
            } else {
                return new responseObject('Es necesario enviar un Id de job para realizar la consulta');
            }
            if (String.isEmpty(jobId) ) {
                return new responseObject('No se encontró un job con el Id informado');
            }

             System.debug('jobId: ' + jobId );

            //Querys y llenado de variables
            AsyncApexJob apexJob = [SELECT Id, CreatedDate, ApexClass.Name, ApexClassId, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate FROM AsyncApexJob WHERE Id = :jobId WITH USER_MODE];
            Integer completedRecords = [SELECT COUNT() FROM CAT_Informacion_Precios_SAP_tmp__c WHERE CAT_Id_Job_Procesamiento__c = :jobId AND CAT_Resultado_Procesamiento__c = 'Éxito' WITH USER_MODE];
            Integer errorRecords = [SELECT COUNT() FROM CAT_Informacion_Precios_SAP_tmp__c WHERE CAT_Id_Job_Procesamiento__c = :jobId AND CAT_Resultado_Procesamiento__c = 'Error' WITH USER_MODE];
            Integer pendingRecords = apexJob.TotalJobItems - completedRecords - errorRecords;
            Boolean jobComplete = (pendingRecords == 0);
            Integer total = completedRecords + errorRecords + pendingRecords;

            System.debug('completedRecords: ' + completedRecords );
            System.debug('pendingRecords: '+ pendingRecords );
            System.debug('errorRecords: ' + errorRecords );
            System.debug('jobComplete: ' + jobComplete );
            System.debug('total: '+ total );

            //respuesta del servicio , si el valor del total (que son las sumas de los 3 contadores solicitados) 
            //son nulos o 0 indica que no habian registros para el jobId consultado.
            //caso contrario retorna los valores .
            if((total == 0) || (total == null)){
                return new responseObject('Job ID is not valid');
            }
            return new responseObject(jobId, completedRecords,pendingRecords,errorRecords,total,jobComplete);
        } /*catch (IllegalArgumentException e) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf(e.getMessage());
            return null;
        }  */catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error interno del servidor.');
            return null;
        }
    
    }
}