global class FVU_CloseOrderDeliveryTypeFuture implements vlocity_cmt.VlocityOpenInterface2{
    
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        try {
            if (methodName == 'callCloseDelTypeFuture') {
                return callCloseDelTypeFuture(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug('Error in invoke method callTBFuture: ' + e.getMessage());
            throw e;
        }
        return false;
    }
    
    public Boolean callCloseDelTypeFuture(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        String orderId = (String) inputMap.get('orderId');
        
        return true;
    }
    
    @InvocableMethod(label='Call IP callCloseDelTypeFuture' description='Calls an Integration Procedure callCloseDelTypeFuture.' category='General')
    public static void callProCloseDelTypeFuture(List<ProcedureWrapper> lstProcedureWrapper) {
        
        Map<String, Object> inputmap = new Map<String, Object>();
        Map<String, Object> outputmap = new Map<String, Object>();
        Map<String, Object> optionsmap = new Map<String, Object>();        
        inputmap.put('orderId', lstProcedureWrapper[0].orderId);
        String ipName='FVU_CloseOrderDeliveryType';
        Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(ipName, inputmap, optionsmap);
        
    }
    
    public class ProcedureWrapper {
        
        @InvocableVariable(required=true)
        public String orderId;
        
    }
    
}