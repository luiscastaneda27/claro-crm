global with sharing class PVU_LiberacionIMEISystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
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
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_LiberacionIMEISystemInterface.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    public static Map<String, Object> callIP(Map<String, Object> request) {
        try{
            system.debug('PVU_LiberacionIMEISystemInterface.callIP request: '+ request);
            //system.debug('PVU_IMEISystemInterface.callIP path: '+path);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            if(path == 'PVU_IPsvcPinGeneration'){
                String imei = (String) request.get('imei');
                ipInputMap.put('imei', imei);
                String vchDataHalfShipmen = (String) request.get('vchDataHalfShipmen');
                ipInputMap.put('vchDataHalfShipmen', vchDataHalfShipmen);
                String clientID = (String) request.get('clientID');
                ipInputMap.put('clientID', clientID);
                Boolean isEmail = (Boolean) request.get('isEmail');
                ipInputMap.put('isEmail', isEmail);
                System.debug('IPinputMap: ' + ipInputMap);
            }else if(path == 'PVU_IPsvcValidatePin'){
                String imei = (String) request.get('imei');
                ipInputMap.put('imei', imei);
                String clientID = (String) request.get('clientID');
                ipInputMap.put('clientID', clientID);
                String pin = (String) request.get('pin');
                ipInputMap.put('pin', pin);
                System.debug('IPinputMap: ' + ipInputMap);
            }
            if(!Test.isRunningTest()){
                result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputMap, ipOptions);
            	system.debug('PVU_LiberacionIMEISystemInterface.callIP result: '+ result);
            }
            else{
                Map<String, Object> mockedOutput = new Map<String, Object>{
                    'testCalled' => true,
                     'imei' => '111111111111111'
                };
                result.putAll(mockedOutput);
                
            }
            
            return result;
        }
        catch(Exception e){
            System.debug('PVU_LiberacionIMEISystemInterface.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
}