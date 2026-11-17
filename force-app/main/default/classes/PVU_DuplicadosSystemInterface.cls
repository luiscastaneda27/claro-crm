global class PVU_DuplicadosSystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try{
            if(methodName == 'callIP'){
                //Map<String, Object> request = (Map<String, Object>)inputMap.get('request');
                //String path = (String)inputMap.get('nameIP'); 
                //Map<String, Object> response =  callIP(request, path);
                Map<String, Object> response =  callIP(inputMap);
                outputMap.put('response', response);
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In PVU_IMEISystemInterface.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    public static Map<String, Object> callIP(Map<String, Object> request) {
        try{
            system.debug('PVU_IMEISystemInterface.callIP request: '+ request);
            //system.debug('PVU_IMEISystemInterface.callIP path: '+path);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipInputMap = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            String path = (String) request.get('procedureName');
            System.debug('Procedure Name: ' + path);
            
            if(path == 'PVU_IPsvcConsultaDuplicados'){
                String imei = (String) request.get('imei');
                System.debug('ConsultaDuplicados imei: ' + imei);
                String min = (String) request.get('min');
                System.debug('ConsultaDuplicados min: ' + min);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                System.debug('ConsultaDuplicados IPinputMap: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcConsultaDuplasPorId'){
                String numeroIdentificacion = (String) request.get('numeroIdentificacion');
                System.debug('ConsultaDuplasPorId numeroIdentificacion: ' + numeroIdentificacion);
                String tipoIdentificacion = (String) request.get('tipoIdentificacion');
                System.debug('ConsultaDuplasPorId tipoIdentificacion: ' + tipoIdentificacion);
                ipInputMap.put('numeroIdentificacion', numeroIdentificacion);
                ipInputMap.put('tipoIdentificacion', tipoIdentificacion);
                System.debug('ConsultaDuplasPorId IPinputMap: ' + ipInputMap);
                
            }
            else if(path == 'PVU_IPsvcValidarDuplasAdicion'){
                String imei = (String) request.get('imei');
                System.debug('ValidarDuplasAdicion imei: ' + imei);
                String min = (String) request.get('min');
                System.debug('ValidarDuplasAdicion min: ' + min);
                String numeroIdentificacion = (String) request.get('numeroIdentificacion');
                System.debug('ValidarDuplasAdicion numeroIdentificacion: ' + numeroIdentificacion);
                String tipoIdentificacion = (String) request.get('tipoIdentificacion');
                System.debug('ValidarDuplasAdicion tipoIdentificacion: ' + tipoIdentificacion);
                String cantDuplas = (String) request.get('cantDuplas');
                System.debug('ValidarDuplasAdicion cantDuplas: ' + cantDuplas);
                String imsi = (String) request.get('imsi');
                System.debug('ValidarDuplasAdicion imsi: ' + imsi);
                String nombres = (String) request.get('nombres');
                System.debug('ValidarDuplasAdicion Nombres -> ' + nombres);
                String apellidos = (String) request.get('apellidos');
                System.debug('ValidarDuplasAdicion Apellidos -> ' + apellidos);
                String marca = (String) request.get('marca');
                System.debug('ValidarDuplasAdicion Marca -> ' + marca);
                String modelo = (String) request.get('modelo');
                System.debug('ValidarDuplasAdicion Modelo -> ' + modelo);
                String detalle = (String) request.get('detalle');
                System.debug('ValidarDuplasAdicion Detalle -> ' + detalle);
                String direccion = (String) request.get('direccion');
                System.debug('ValidarDuplasAdicion Direccion -> ' + direccion);
                String ciudad = (String) request.get('ciudad');
                System.debug('ValidarDuplasAdicion Ciudad -> ' + ciudad);
                String tipoOperacion = (String) request.get('tipoOperacion');
                System.debug('ValidarDuplasAdicion Tipo Operacion -> ' + tipoOperacion);
                String infoLegal = (String) request.get('infoLegal');
                System.debug('ValidarDuplasAdicion Info Legal -> ' + infoLegal);
                String userId = (String) request.get('userId');
                System.debug('ValidarDuplasAdicion User Id -> ' + userId);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                ipInputMap.put('numeroIdentificacion', numeroIdentificacion);
                ipInputMap.put('tipoIdentificacion', tipoIdentificacion);
                ipInputMap.put('cantDuplas', cantDuplas);
                ipInputMap.put('imsi', imsi);
                ipInputMap.put('nombres', nombres);
                ipInputMap.put('apellidos', apellidos);
                ipInputMap.put('marca', marca);
                ipInputMap.put('modelo', modelo);
                ipInputMap.put('detalle', detalle);
                ipInputMap.put('direccion', direccion);
                ipInputMap.put('ciudad', ciudad);
                ipInputMap.put('tipoOperacion', tipoOperacion);
                ipInputMap.put('infoLegal', infoLegal);
                ipInputMap.put('userId', userId);
                System.debug('ValidarDuplasAdicion IPinputMap: ' + ipInputMap);
                
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
            System.debug('PVU_IMEISystemInterface.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }
}