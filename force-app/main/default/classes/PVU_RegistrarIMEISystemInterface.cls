global with sharing class PVU_RegistrarIMEISystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try{
            if(methodName == 'callIP'){
                Map<String, Object> response =  callIP(inputMap);
                outputMap.put('response', response);
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_RegistrarIMEISystemInterface.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    public static Map<String, Object> callIP(Map<String, Object> request) {
        try{
            system.debug('PVU_RegistrarIMEISystemInterface.callIP request: '+ request);
            //system.debug('PVU_RegistrarIMEISystemInterface.callIP path: '+path);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            if(path == 'PVU_IPsvcRegistroImei'){
                String imei = (String) request.get('Serial');
                ipInputMap.put('Serial', imei);

                String tipoPersona = (String) request.get('tipoPersona');
                ipInputMap.put('tipoPersona', tipoPersona);

                String tipoId = (String) request.get('tipoldentificacion');
                ipInputMap.put('tipoldentificacion', tipoId);
                
                String docNumber = (String) request.get('docNumber');
                ipInputMap.put('docNumber', docNumber);

                String name = (String) request.get('Name');
                ipInputMap.put('Name', name);

                String dir = (String) request.get('Direccion');
                ipInputMap.put('Direccion', dir);

                String tel = (String) request.get('TelefonoContacto');
                ipInputMap.put('TelefonoContacto', tel);

                String dep = (String) request.get('Departamento');
                ipInputMap.put('Departamento', dep);

                String cid = (String) request.get('Ciudad');
                ipInputMap.put('Ciudad', cid);

                System.debug('IPinputMap: ' + ipInputMap);
            }else{
                //if we have a new IP for this omniscript, add here
            }
            if(!Test.isRunningTest()){
                result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputMap, ipOptions);
            	system.debug('PVU_RegistrarIMEISystemInterface.callIP result: '+ result);
            }
            else{
                Map<String, Object> mockedOutput = new Map<String, Object>{
                    'testCalled' => true,
                    'Serial' => '352527091504668'
                };
                result.putAll(mockedOutput);
                
            }
            
            return result;
        }
        catch(Exception e){
            System.debug('PVU_RegistrarIMEISystemInterface.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
}