global with sharing class PVU_MessageMgmt implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        System.debug('Method Name: '+methodName);
        System.debug('inputMap '+inputMap);
        System.debug('outputMap '+ outputMap);
        System.debug('options '+ options);
        
        Boolean result = true;
        try{
            if(methodName == 'callIP'){
                Map<String, Object> response =  callIP(inputMap);
                outputMap.put('response', response);
            }
            if (methodName == 'UpdateMessage') {  
                UpdateMessage(inputMap, outputMap, options);
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_MessageMgmt.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        
        return result;
    }
    
    public static Map<String, Object> callIP(Map<String, Object> request) {
        try{
            system.debug('PVU_MessageMgmt.callIP request: '+ request);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            if(path == 'PVU_IPsvcCaseInfo'){
                String ContextId = (String) request.get('ContextId');
                ipInputMap.put('CaseId', ContextId);
            }
            if(!Test.isRunningTest()){
                result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputMap, ipOptions);
                system.debug('PVU_MessageMgmt.callIP result: '+ result);
                
            }
            else{
                Map<String, Object> mockedOutput = new Map<String, Object>{
                    'testCalled' => true,
                        'messageCallIP' => 'Successful test'
                        };
                            result.putAll(mockedOutput);
                
            }
            
            return result;
        }
        catch(Exception e){
            System.debug('PVU_MessageMgmt.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
    
    public void UpdateMessage( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        try{
            String message = (String)input.get('Message');
            String accountNameReplacement = (String)input.get('AccountName');
            String target = '%accountName%';
            String messageResult = message.replace(target, accountNameReplacement);
            
            String ordenNumeroReplacement = String.valueOf(input.get('OrdenNumero'));
            if(!String.isBlank(ordenNumeroReplacement) || !String.isEmpty(ordenNumeroReplacement)){
                String ordenNumero = '%ordenNumero%';
                messageResult = messageResult.replace(ordenNumero, ordenNumeroReplacement);
            }

            String dateNowReplacement = String.valueOf(input.get('dateNow'));
            if(!String.isBlank(dateNowReplacement) || !String.isEmpty(dateNowReplacement)){
                String dateNow = '%dateNow%';
                messageResult = messageResult.replace(dateNow, dateNowReplacement);
            }

            /*
            String nombreTerceroReplacement = (String)input.get('NombreTercero');
            if(!String.isBlank(nombreTerceroReplacement) || !String.isEmpty(nombreTerceroReplacement)){
                String nombreTercero = '%nombreTercero%';
                messageResult = messageResult.replace(nombreTercero, nombreTerceroReplacement);
            }            
            
            String direccionReplacement = (String)input.get('Direccion');
            if(!String.isBlank(direccionReplacement) || !String.isEmpty(direccionReplacement)){
                String direccion = '%direccion%';
                messageResult = messageResult.replace(direccion, direccionReplacement);
            }  
			*/ 
            
            outMap.put('messageResult',messageResult);
            
            if(Test.isRunningTest()){
                Map<String, Object> result = new Map<String, Object>();
                Map<String, Object> mockedOutput = new Map<String, Object>{
                    'testCalled' => true,
                        'UpdateMessageOutput' => 'Successful test'
                        };
                            result.putAll(mockedOutput);
            }
        }catch(Exception e){
            System.debug('PVU_MessageMgmt.UpdateMessage - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
        
    }
}