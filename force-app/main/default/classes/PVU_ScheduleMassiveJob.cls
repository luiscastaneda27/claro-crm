/*******************************************************************************
* Autor: Gabriel Oros
* Fecha: 2024-11-21
* Equipo: Pos-Ventas
* Descripcion: API para Schedulear Batch gestiones masivas
* History
<Date>            <Author>             <Description>                                      <Version>
2024-11-21         Gabriel Oros     Ajuste para verificar si el JobId existe                   02
***********************************************************************************/
global with sharing class PVU_ScheduleMassiveJob implements vlocity_cmt.VlocityOpenInterface {

    
        global static Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
            if(methodName.equalsIgnoreCase('programBatch')) {
                programBatch(input, output, options);
                
                return true;
            }
        
            output.put('error', 'Method not found');
            return false;
        }
            
      global static Map<String, Object>  programBatch (Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
   
       try {
        System.debug('Inputs ' + input);
        //Recuperacion de Inputs
        Integer timeExecution = (Integer) input.get('minutes');
        if (timeExecution == null || timeExecution <= 0) {
            throw new IllegalArgumentException('The "minutes" parameter must be a positive integer');
        }
        String jobIdInput = (String) input.get('jobId');
        if (String.isEmpty(jobIdInput)) {  
            throw new IllegalArgumentException('The JobId parameter must not be null or empty');
        }
        Integer pendingRecordsForJobId = [SELECT COUNT() FROM PVU_Gestiones_Masivas__c WHERE PVU_JobIdentifier__c = :jobIdInput AND ((PVU_Status__c= NULL) OR (PVU_Status__c!='Error' AND PVU_Status_OM__c= NULL)) WITH USER_MODE];
        if (pendingRecordsForJobId == 0) {
            throw new IllegalArgumentException('There are no pending registrations with the given JobId');
        }
        Integer scopeSize = 1;
        DateTime dateNow = DateTime.now();
        DateTime dateExecute = dateNow.addMinutes(timeExecution);
               
        System.debug('Fecha Actual: ' + dateNow);       
        System.debug('Fecha de Ejecucion: ' + dateExecute);
        //Instancia del Batch
        PVU_Gestiones_Masivas_Batch batch = new PVU_Gestiones_Masivas_Batch(jobIdInput);
               
         // Nombre del trabajo Batch
         String jobName = 'Actualizar Gestiones Masivas '+ jobIdInput;
         // Programar el Batch para que se ejecute en N minutos
         String jobIdSchedule = System.scheduleBatch(batch, jobName, timeExecution,scopeSize);
         System.debug('Batch Job ID: ' + jobIdSchedule);

         //Armado del output
          output.put('success',true);
          output.put('jobId',jobIdSchedule);
          output.put('dateExecute',dateExecute);
          return output;
        
       } catch (IllegalArgumentException e) {
        output.put('success',false);
        output.put('message',e.getMessage());
        return output;
        
       }catch (Exception e) {
        output.put('success',false);
        output.put('message','Batch job scheduled error');
        return output;
        
       }
   }
}