global class FVU_CallSystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
    
	public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String procedureName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
        Boolean result = true;
        result = callProcedure(procedureName, inputMap, outputMap, options);      
        
        return result;
        
    }
    
    private static Boolean callProcedure(String procedureName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        
    	outputMap = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, inputMap, options);
        System.debug(!outputMap.containsKey('error'));
        return !outputMap.containsKey('error');
        
    }
    
    @InvocableMethod(label='Call Integration Procedure' description='Calls an Integration Procedure.' category='General')
    public static List<ProcedureResult> callProcedure(List<ProcedureWrapper> lstProcedureWrapper) {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<ProcedureResult> lstProcedureResult = new List<ProcedureResult>();
        String procedureName = '';
        List<ProcedureMapping> lstProcedureMapping = new List<ProcedureMapping>();
        for(ProcedureWrapper item: lstProcedureWrapper){
            procedureName = item.procedureName;
            lstProcedureMapping = item.mapping;
            
            for(ProcedureMapping procMapping : lstProcedureMapping) {
                inputMap.put(procMapping.key, procMapping.value);
            }
            ProcedureResult procResult = new ProcedureResult();
            Boolean callFuture = false;
            if(inputMap.containsKey('CallFuture')){
                callFuture = Boolean.valueOf(inputMap.get('CallFuture'));
            }
            
            if(callFuture){
                String OrderId = (String)inputMap.get('OrderId');
                String paramName = 'OrderId';
                
                if (inputMap.containsKey('OrderId')) {
                    OrderId = (String)inputMap.get('OrderId'); 
                    paramName = 'OrderId';
                } else if (inputMap.containsKey('orderId')) {
                    OrderId = (String)inputMap.get('orderId'); 
                    paramName = 'orderId';
                } else { 
                    throw new ProcedureException('OrderId is required!');
                }

                //Cuando se realiza un llamado a un método FUTRE la firma SOLO ACEPTA tipos primitivos
                callProcedureFuture(procedureName,OrderId, paramName);
            }
            else{
                procResult.result = JSON.serialize((Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, inputMap, options));
                lstProcedureResult.add(procResult);
            }
        }
        
        
        return lstProcedureResult;
        
    }
    
    @Future(callout=true)
    private static void callProcedureFuture(String methodName, String OrderId, String paramName) {
        
        Map<String, Object> inputmap = new Map<String, Object>();
        Map<String, Object> outputmap = new Map<String, Object>();
        Map<String, Object> optionsmap = new Map<String, Object>();        
        inputmap.put(paramName, OrderId);
        Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(methodName, inputmap, optionsmap);
        
    }

    public class ProcedureWrapper {
        
        @InvocableVariable(required=true)
        public String procedureName;
        @InvocableVariable(required=true)
        public List<ProcedureMapping> mapping;
        
    }
    
    public class ProcedureResult {
        
        @InvocableVariable(required=true)
        public String result;
        
    }

}