global class FVU_IdClaroVerifyInterface implements vlocity_cmt.VlocityOpenInterface2 {

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            if (methodName == 'generateRequest') {
                result = generateRequest(inputMap, outputMap, options);
            }
        } catch (Exception e) {

        }
        return result;
    }
    
    public Boolean generateRequest(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
            outputMap.put('trace', inputMap.get('trace'));
            outputMap.put('accessKey', inputMap.get('accessKey'));
            outputMap.put('application', inputMap.get('application'));
            outputMap.put('company', inputMap.get('company'));
            outputMap.put('documentClient', inputMap.get('documentClient'));
            
            Map<String,Object> requestHeader = new Map<String,Object>();
            requestHeader.put('traceabilityId', inputMap.get('traceabilityId'));
            requestHeader.put('ipApplication', inputMap.get('ipApplication'));
            requestHeader.put('requestDate', inputMap.get('requestDate'));
            requestHeader.put('password', inputMap.get('password'));
            requestHeader.put('user', inputMap.get('user'));
            requestHeader.put('target', inputMap.get('target'));
            requestHeader.put('system', inputMap.get('system'));
            requestHeader.put('transactionId', inputMap.get('transactionId'));
            outputMap.put('headerRequest', requestHeader);

            outputMap.remove('errorCode');
            outputMap.remove('error');

            return true;
        } catch (Exception e) {
            throw e;
        }
    }
}