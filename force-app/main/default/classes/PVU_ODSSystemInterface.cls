/****************************************************************
 * Autor: Federico Mandri
 * Equipo: PosVentas
 * Fecha: 2/5/23
 * Descripcion: Clase apex para encapsular el llamado a IP: PVU_IPsvcGetODSWrapper. 
				Se ultiliza como data source de Flexcard: FVU_ServiceOrders para mostrar las órdenes de servicio en la v360
*******************************************************************/				
global class PVU_ODSSystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
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
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_ODSSystemInterface.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    
    public static Map<String, Object> callIP(Map<String, Object> request){
        try{
            system.debug('PVU_ODSSystemInterface.callIP request: '+ request);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            if(path == 'PVU_IPsvcGetODS' || path == 'PVU_IPsvcGetODSWrapper'){
                String idCuenta = (String)request.get('contextId');
                ipInputMap.put('idCuenta', idCuenta);
            }
            if(!Test.isRunningTest()){
                result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, ipInputMap, ipOptions);
            	system.debug('PVU_IMEISystemInterface.callIP result: '+ result);
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
            System.debug('PVU_ODSSystemInterface.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
}