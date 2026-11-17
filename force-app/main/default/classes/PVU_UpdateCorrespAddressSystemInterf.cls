global with sharing class PVU_UpdateCorrespAddressSystemInterf implements vlocity_cmt.VlocityOpenInterface, Callable {
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
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_UpdateCorrespAddressSystemInterf.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    public static Map<String, Object> callIP(Map<String, Object> request) {
        try{
            system.debug('PVU_UpdateCorrespAddressSystemInterface.callIP request: '+ request);
            //system.debug('PVU_UpdateCorrespAddressSystemInterface.callIP path: '+path);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            if(path == 'PVU_IPsvcUpdateCorrespondenceAddress'){
                String accountNumber = (String) request.get('accountNumber');
                ipInputMap.put('accountNumber', accountNumber);

                String state = (String) request.get('state');
                ipInputMap.put('state', state);

                String city = (String) request.get('city');
                ipInputMap.put('city', city);
                
                String street = (String) request.get('street');
                ipInputMap.put('street', street);

                String cityArea = (String) request.get('cityArea');
                ipInputMap.put('cityArea', cityArea);

                String dane = (String) request.get('dane');
                ipInputMap.put('dane', dane);

                System.debug('IPinputMap: ' + ipInputMap);
            }else{
                //if we have a new IP for this omniscript, add here
            }
            if(!Test.isRunningTest()){
                result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputMap, ipOptions);
            	system.debug('PVU_IPsvcUpdateCorrespondenceAddress.callIP result: '+ result);
            }
            else{
                Map<String, Object> mockedOutput = new Map<String, Object>{
                    'testCalled' => true,
                    'accountNumber' => 'CUST0000000064'
                };
                result.putAll(mockedOutput);
                
            }
            
            return result;
        }
        catch(Exception e){
            System.debug('PVU_IPsvcUpdateCorrespondenceAddress.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
}