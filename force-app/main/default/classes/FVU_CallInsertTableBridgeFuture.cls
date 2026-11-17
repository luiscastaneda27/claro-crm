global class FVU_CallInsertTableBridgeFuture implements vlocity_cmt.VlocityOpenInterface2{
    
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        try {
            if (methodName == 'callTBFuture') {
                return callTBFuture(inputMap, outputMap, options);
            }
            if (methodName == 'callUpdateAssetAndTB') {
                return callUpdateAssetAndTB(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug('Error in invoke method callTBFuture: ' + e.getMessage());
            throw e;
        }
        return false;
    }
    
    public Boolean callTBFuture(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
                
        System.debug('Entro al metodo callTBFuture');
        String assetId = (String) inputMap.get('assetId');
        callProcedureFutureTB(assetId);
        
        return true;
    }
    
    @Future(callout=true)
    private static void callProcedureFutureTB(String assetId) {
        
        System.debug('Entro al metodo callProcedureFutureTB con el assetId --> ' + assetId);
        Map<String, Object> inputmap = new Map<String, Object>();
        Map<String, Object> outputmap = new Map<String, Object>();
        Map<String, Object> optionsmap = new Map<String, Object>();        
        inputmap.put('assetId', assetId);
        String ipName='FVU_CallInsertDataInTableBridge';
        Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(ipName, inputmap, optionsmap);
        System.debug('result --> ' + result);
       // System.debug('result --> ' + JSON.deserialize(result));
        
    }
    
    /**
    * Prepares the data required to invoke an Integration Procedure asynchronously.
    *
    * This method receives the Integration Procedure name and the payload, serializes
    * the payload and delegates the execution to the future method callProcedureFutureUpdateAssetAndTB.
    *
    * @param inputMap   Contains the procedureName and the payload to be sent to the IP.
    * @param outputMap  Output map required by the VlocityOpenInterface2 interface.
    * @param options    Execution options (not used in this implementation).
    */
    public Boolean callUpdateAssetAndTB(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        System.debug('Executed method callUpdateAssetListAndTB');        
        String procedureName = (String) inputMap.get('procedureName');        
        
        try{
            Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, inputMap, options);        
        }catch(Exception e){
            System.debug('Error calling Integration Procedure: ' + e.getMessage());
        }
        return true;
    }      
}