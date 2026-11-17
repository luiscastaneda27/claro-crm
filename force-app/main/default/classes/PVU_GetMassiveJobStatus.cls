/*******************************************************************************
* Autor: Gabriel Oros
* Fecha: 2024-11-20
* Equipo: Pos-Ventas
* Descripcion: Servicio para consultar gestiones Masivas
* History
<Date>            <Author>             <Description>                                <Version>
2024-11-20         Gabriel Oros         Ajuste de Query WITH USER_MODE                   02
***********************************************************************************/
@RestResource(urlMapping='/GetMassiveJobStatus/*')
global with sharing class PVU_GetMassiveJobStatus {
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
            String jobId = req.params.get('jobId');
            // Validar parámetro
            if (String.isEmpty(jobId) ) {
                return new responseObject('The jobId parameter is required');
            }
			
            //Querys y llenado de variables
            Integer completedRecords = [SELECT COUNT() FROM PVU_Gestiones_Masivas__c WHERE PVU_JobIdentifier__c = :jobId and PVU_Status_OM__c='Exitosa' and PVU_Status__c='Exitoso' WITH USER_MODE];
            Integer pendingRecords = [SELECT COUNT() FROM PVU_Gestiones_Masivas__c WHERE PVU_JobIdentifier__c = :jobId AND ((PVU_Status__c= NULL) OR (PVU_Status__c!='Error' AND PVU_Status_OM__c= NULL)) WITH USER_MODE];
            Integer errorRecords = [SELECT COUNT() FROM PVU_Gestiones_Masivas__c WHERE PVU_JobIdentifier__c = :jobId and (PVU_Status__c='Error' OR PVU_Status_OM__c='No Exitosa') WITH USER_MODE];
            Boolean jobComplete = (pendingRecords == 0);
            Integer total = completedRecords + errorRecords + pendingRecords;

            System.debug('completedRecords' + completedRecords );
            System.debug('pendingRecords'+ pendingRecords );
            System.debug('errorRecords' + errorRecords );
            System.debug('jobComplete' + jobComplete );
            System.debug('total'+ total );

                //respuesta del servicio , si el valor del total (que son las sumas de los 3 contadores solicitados) 
                //son nulos o 0 indica que no habian registros para el jobId consultado.
                //caso contrario retorna los valores .
                if((total == 0) || (total == null)){
                    return new responseObject('Job ID is not valid');
                }

               return new responseObject(jobId, completedRecords,pendingRecords,errorRecords,total,jobComplete);
            

        } catch (IllegalArgumentException e) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf(e.getMessage());
            return null;
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error interno del servidor.');
            return null;
        }
    
    }
}