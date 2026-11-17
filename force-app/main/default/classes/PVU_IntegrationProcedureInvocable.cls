/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 04-16-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
2025-03-05         hllanos            se agrega una version con chanaible             02
2025-03-18         hllanos            se agrega una version con queuable              03
2025-03-25         hllanos            En caso que esta clase se llame desde un 
                                     contexto queuable el ip se ejecuta en linea 
                                      para evitar excepciones  
2025-04-16        hmachuca         Ajustes para levantar el evento para ejecución del flujo en otro contexto fuera de OM.
2025-04-21        molay            Ajustes para Añadir Cambio de Plan con el evento para ejecución del flujo en otro contexto fuera de OM.
**/
global with sharing class PVU_IntegrationProcedureInvocable {
    @InvocableMethod(label = 'Integration Procedure')
    global static List < IntegrationProcedureOutput > runIntegrationServiceInvocable(List < IntegrationProcedureInput > input) {
        System.debug(LoggingLevel.Error, 'INPUT>>>>>'+JSON.serialize(input));
        IntegrationProcedureOutput result = new IntegrationProcedureOutput();
        List<ProcedureMapping> inputList=input[0].input;
        List<IntegrationProcedureOutput> output=new List<IntegrationProcedureOutput>(); 
        
        String integrationName=input[0].procedureAPIName;
        String valueKey,valContexto, valueIPName, valueBody, valueSubject, valueMappingProcesosIMEI;
        Map<String,Object> inputMap=new Map<String,Object>();
        Map<String,Object> outputMap=new Map<String,Object>();
        for (ProcedureMapping keyValueMap : inputList) {
            System.debug(LoggingLevel.debug, 'keyValueMap.key>>>>>'+keyValueMap.key);
            System.debug(LoggingLevel.debug, 'keyValueMap.key>>>>>'+keyValueMap.value);
            inputMap.put(keyValueMap.key,keyValueMap.value);
            if( keyValueMap.key == 'CaseId'){
                valueKey = keyValueMap.value;
            }
            if( keyValueMap.key == 'Contexto'){
                valContexto = keyValueMap.value;
            }
            if( keyValueMap.key == 'IPName'){
                valueIPName = keyValueMap.value;
            }
            if( keyValueMap.key == 'Body' || keyValueMap.key == 'emailMessage'|| keyValueMap.key == 'smsMessage'){
                valueBody = keyValueMap.value;
            }
            if( keyValueMap.key == 'Subject'|| keyValueMap.key == 'asuntoCorreo'){
                valueSubject = keyValueMap.value;
            }
            if( keyValueMap.key == 'mappingIP'){
                valueMappingProcesosIMEI = keyValueMap.value;
            }
        }
        ID jobID;
        IntegrationProcedureOutput ipo= new IntegrationProcedureOutput();
        System.debug(LoggingLevel.debug, 'inputMap>>>>>'+JSON.serialize(inputMap));
        if(Test.isRunningTest()){
            ProcedureMapping pm=new ProcedureMapping();
            pm.key='test';
            pm.value='OK';  
            List<ProcedureMapping> out= new List<ProcedureMapping>();
            out.add(pm);
            ipo.output=out;
            output.add(ipo);
        }else { 
                Map <String,Object> mapa =new Map <String,Object>();
                if(valContexto == 'FlowStatus'||valContexto == 'FlowStatusReporteIMEI'||valContexto == 'FlowStatusLiberacionIMEI'){                    
                    List<PVU_EngagementInteraction__e> eventos = new List<PVU_EngagementInteraction__e>();
                    PVU_EngagementInteraction__e eventoPlataforma = new PVU_EngagementInteraction__e();
                    eventoPlataforma.PVU_Actions__c = valContexto=='FlowStatus'? valueKey: valContexto;
                    eventoPlataforma.PVU_IPName__c = integrationName;
                    //Si es FlowStatusLiberacionIMEI o FlowStatusReporteIMEI se manda todo el inputMap que contiene la información para liberar o reportar el IMEI del equipo
                    eventoPlataforma.PVU_Body__c = valContexto=='FlowStatusReporteIMEI'||valContexto=='FlowStatusLiberacionIMEI'? JSON.serialize(inputMap): valueBody;
                    eventoPlataforma.PVU_Subject__c = valueSubject;
                    eventos.add(eventoPlataforma);
                    List<Database.SaveResult> results = EventBus.publish(eventos);
                    System.debug(LoggingLevel.debug,'Ingresando a  PVU_PublishPlatformEvent');    
                }else{
                    if(System.isQueueable() || valContexto == 'FlowStatusRunSync'){                    
                        vlocity_cmt.IntegrationProcedureService.runIntegrationService(integrationName,inputMap,new Map <String,Object>());
                        System.debug(LoggingLevel.debug,'Ingresando a  vlocity_cmt.IntegrationProcedureService.runIntegrationService');                    
                        //System.debug('OUTPUT ------------' + mapa);
                    }else{

                        //Si viene de contexto FlowEventoIMEI hay que deserealizar el campo body donde viene todo el input del IP
                        if(valContexto=='FlowEventoIMEI'){
                            inputMap = (Map<String, Object>) JSON.deserializeUntyped(valueMappingProcesosIMEI);
                            inputMap.remove('Contexto');
                            System.debug(LoggingLevel.debug,'FlowEventoIMEI::'+inputMap);      
                        }

                        jobID = vlocity_cmt.IntegrationProcedureService.runIntegrationProcedureQueueable(integrationName,inputMap,new Map <String,Object>());
                        System.debug(LoggingLevel.debug,'Ingresando a  vlocity_cmt.IntegrationProcedureService.runIntegrationProcedureQueueable');
                }
                }
               }
        /*System.debug(LoggingLevel.debug, 'outputMap>>>>>'+JSON.serialize(outputMap));
        IntegrationProcedureOutput ipo= new IntegrationProcedureOutput();
        for (String key : outputMap.keySet()) {
            ProcedureMapping pm=new ProcedureMapping();
            pm.key=key;
            pm.value=(String)outputMap.get(key);
           // IntegrationProcedureOutput ipo= new IntegrationProcedureOutput();
            ipo.output.add(pm);
            
            
        }
        output.add(ipo);*/
        System.debug(LoggingLevel.debug,'SE EJECUTO LA IP>>>'+ integrationName);
        
        return output;
    }

    global class IntegrationProcedureInput{
        @InvocableVariable(label = 'Procedure Name') global String procedureAPIName;
        @InvocableVariable(label = 'Input') global List<ProcedureMapping> input;
    }

    global class IntegrationProcedureOutput{
        @InvocableVariable(label = 'Output') global List<ProcedureMapping> output;
    }
}