global class PVU_IMEISystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
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
            if(path == 'PVU_IPsvcConsultaTipoIdentificacion'){
                String tipoDoc = (String) request.get('AccountTipoDoc');
                ipInputMap.put('tipodocumento', tipoDoc);
                System.debug('IPinputMap: ' + ipInputMap);
                System.debug('Tipo Documento: ' + tipoDoc);
            }
            else if(path == 'PVU_IPsvcImeiValidacionLuhn' || path == 'PVU_IPsvcImeiComcel'){
                String imei = (String) request.get('imei');
                System.debug('Validacion Imei -> Imei input: ' + imei);
                ipInputMap.put('imei', imei);
            }
            else if(path == 'PVU_IPsvcbdoNegativo' || path == 'PVU_IPsvcConsultaTAC'){
                String imei = (String) request.get('imei');
                System.debug('BDO Positivo -> Imei input: ' + imei);
                ipInputMap.put('movilImei', imei);
            }
            else if(path == 'PVU_IPsvcBdaPositivo'){
                String imei = (String) request.get('imei');
                System.debug('BDA Positivo -> Imei input: ' + imei);
                String tipoIdentificacion = (String) request.get('tipoIdentificacion');
                System.debug('BDA Positivo -> Tipo Identificacion input: ' + tipoIdentificacion);
                String identificacion = (String) request.get('identificacion');
                System.debug('BDA Positivo -> Numero Identificacion input: ' + identificacion);
                ipInputMap.put('imei', imei);
                ipInputMap.put('tipoIdentificacion', tipoIdentificacion);
                ipInputMap.put('identificacion', identificacion);
            }
            else if(path == 'PVU_IPsvcBdoPositivo'){
                String tipoIdentificacion = (String) request.get('tipoIdentificacion');
                System.debug('BDO Positivo -> Tipo Identificacion input: ' + tipoIdentificacion);
                String identificacion = (String) request.get('identificacion');
                System.debug('BDO Positivo -> Numero Identificacion input: ' + identificacion);
                String imei = (String) request.get('imei');
                System.debug('BDO Positivo -> Imei input: ' + imei);
                ipInputMap.put('tipoIdentificacion', tipoIdentificacion);
                ipInputMap.put('identificacion', identificacion);
                ipInputMap.put('imei', imei);
            }
            else if(path == 'PVU_IPsvcLiberarImei'){
				String imei = (String) request.get('imei');
				System.debug('Liberar Imei -> Imei input: ' + imei);
				String tipoReporte = (String) request.get('tipoReporte');   
                System.debug('Liberar Imei -> Tipo reporte input: ' + tipoReporte);
                String msisdn = (String) request.get('msisdn');
                System.debug('Liberar Imei -> Msisdn input: ' + msisdn);
                String idUsuario = (String) request.get('idUsuario');
                System.debug('Liberar Imei -> Id usuario input: ' + idUsuario);
                ipInputMap.put('imei', imei);
                ipInputMap.put('tipoReporte', tipoReporte);
                ipInputMap.put('msisdn', msisdn);
                ipInputMap.put('idUsuario', idUsuario);
            }
            else if(path == 'PVU_IPsvcConsultaTipoReporte'){
                String tipoReporte = (String) request.get('tipoReporte');   
                System.debug('Consulta Tipo reporte -> Tipo reporte input: ' + tipoReporte);
                ipInputMap.put('tipoReporte', tipoReporte);
                
            }
            else if(path == 'PVU_IPsvcReportarImeiBdo'){
                String idUsuario = (String) request.get('idUsuario');
                System.debug('Reportar Imei -> Id usuario input: ' + idUsuario);
                
                String idCuenta = (String) request.get('idCuenta');
                System.debug('Reportar Imei -> Id cuenta input: ' + idCuenta);
                
                String fiscalia = (String) request.get('fiscalia');
                System.debug('Reportar Imei -> Fiscalia input: ' + fiscalia);
                
                String tipoDocReporte = (String) request.get('tipoDocReporte');
                System.debug('Reportar Imei -> Tipo Documento Reporte input: ' + tipoDocReporte);
                
                String numIdReporte = (String) request.get('numIdReporte');
                System.debug('Reportar Imei -> Numero Documento Reporte input: ' + numIdReporte);
                
                String nombreReporte = (String) request.get('nombreReporte');
                System.debug('Reportar Imei -> Nombre Reporte input: ' + nombreReporte);
                
                //String tipoReporte = (String) request.get('tipoReporte');
                //System.debug('Reportar Imei -> Tipo Reporte input: ' + tipoReporte);
                
                String telContactoReporte = (String) request.get('telContactoReporte');
                System.debug('Reportar Imei -> Telefono Contacto Reporte input: ' + telContactoReporte);
                
                String direccionHechos = (String) request.get('direccionHechos');
                System.debug('Reportar Imei -> Direccion Hechos input: ' + direccionHechos);
                
                String departamentoReporte = (String) request.get('departamentoReporte');
                System.debug('Reportar Imei -> Departamento Reporte input: ' + departamentoReporte);
                
                String ciudadReporte = (String) request.get('ciudadReporte');
                System.debug('Reportar Imei -> Ciudad input: ' + ciudadReporte);
                
                String imei = (String) request.get('imeiInput');
                System.debug('Reportar Imei -> Imei input: ' + imei);
                
                String min = (String) request.get('minInput');
                System.debug('Reportar Imei -> Min input: ' + min);
                
                String msisdn = (String) request.get('msisdnInput');
                System.debug('Reportar Imei -> MSISDN input: ' + msisdn);
                
                String tipoArma = (String) request.get('tipoArma');
                System.debug('Reportar Imei -> Tipo Arma input: ' + tipoArma);
                
                String tipoReporteAbd = (String) request.get('tipoReporteAbd');
                System.debug('Reportar Imei -> Tipo Tecnologia input: ' + tipoReporteAbd);
                
                String marca = (String) request.get('marcaInput');
                System.debug('Reportar Imei -> Marca input: ' + marca);
                
                String modelo = (String) request.get('modeloInput');
                System.debug('Reportar Imei -> Modelo input: ' + modelo);
                
                String descripcionEvento = (String) request.get('descripcionEvento');
                System.debug('Reportar Imei -> Descripcion Evento input: ' + descripcionEvento);
                
                String menorEdad = (String) request.get('menorEdad');
                System.debug('Reportar Imei -> Menor Edad input: ' + menorEdad);
                
                String empleoViolencia = (String) request.get('empleoViolencia');
                System.debug('Reportar Imei -> Violencia input: ' + empleoViolencia);
                
                String correo = (String) request.get('correo');
                System.debug('Reportar Imei -> Correo input: ' + correo);
                
                ipInputMap.put('idUsuario', idUsuario);
                ipInputMap.put('idCuenta', idCuenta);
                ipInputMap.put('fiscalia', fiscalia);
                ipInputMap.put('tipoDocReporte', tipoDocReporte);
                ipInputMap.put('numIdReporte', numIdReporte);
                //ipInputMap.put('tipoReporte', tipoReporte);
                ipInputMap.put('telContactoReporte', telContactoReporte);
                ipInputMap.put('nombreReporte', nombreReporte);
                ipInputMap.put('reporteFiscalia', nombreReporte);
                ipInputMap.put('direccionHechos', direccionHechos);
                ipInputMap.put('direccionReporte', direccionHechos);
                ipInputMap.put('departamento', departamentoReporte);
                ipInputMap.put('ciudad', ciudadReporte);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                ipInputMap.put('msisdn', msisdn);
                ipInputMap.put('tipoArma', tipoArma);
                ipInputMap.put('tipoReporteAbd', tipoReporteAbd);
                ipInputMap.put('marca', marca);
                ipInputMap.put('modelo', modelo);
                ipInputMap.put('descripcionEvento', descripcionEvento);
                ipInputMap.put('menorEdad', menorEdad);
                ipInputMap.put('victimaMenorEdad', menorEdad);
                ipInputMap.put('empleoViolencia', empleoViolencia);
                ipInputMap.put('correo', correo);
                System.debug('Reportar Imei -> Ip Map input: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcCesionUsuario'){
                String imei = (String) request.get('imeiInput');
                System.debug('Cesion Imei -> Imei input: ' + imei);
                String userId = (String) request.get('userIdInput');
                System.debug('Cesion Imei -> Id Usuario input: ' + userId);
                String tipoDocCedente = (String) request.get('tipoDocCedenteInput');
                System.debug('Cesion Imei -> Tipo Documento Cedente input: ' + tipoDocCedente);
                String numDocCedente = (String) request.get('numDocCedenteInput');
                System.debug('Cesion Imei -> Numero Documento Cedente input: ' + numDocCedente);
                String numLineaCesionario = (String) request.get('numLineaCesionarioInput');
                System.debug('Cesion Imei -> Numero Linea Cesionario input: ' + numLineaCesionario);
                String nombreCesionario = (String) request.get('nombreCesionarioInput');
                System.debug('Cesion Imei -> Nombre Cesionario input: ' + nombreCesionario);
                String direccionCesionario = (String) request.get('direccionCesionarioInput');
                System.debug('Cesion Imei -> Direccion Cesionario input: ' + direccionCesionario);
                String ciudadCesionario = (String) request.get('ciudadCesionarioInput');
                System.debug('Cesion Imei -> Ciudad Cesionario input: ' + ciudadCesionario);
                String departamentoCesionario = (String) request.get('departamentoCesionarioInput');
                System.debug('Cesion Imei -> Departamento Cesionario input: ' + departamentoCesionario);
                String tipoDocCesionario = (String) request.get('tipoDocCesionarioInput');
                System.debug('Cesion Imei -> Tipo Doc Cesionario input: ' + tipoDocCesionario);
                String numDocCesionario = (String) request.get('numDocCesionarioInput');
                System.debug('Cesion Imei -> Numero Doc Cesionario input: ' + numDocCesionario);
                ipInputMap.put('imei', imei);
                ipInputMap.put('userId', userId);
                ipInputMap.put('tipoDocCedente', tipoDocCedente);
                ipInputMap.put('numDocCedente', numDocCedente);
                ipInputMap.put('numLineaCesionario', numLineaCesionario);
                ipInputMap.put('nombreCesionario', nombreCesionario);
                ipInputMap.put('direccionCesionario', direccionCesionario);
                ipInputMap.put('ciudadCesionario', ciudadCesionario);
                ipInputMap.put('departamentoCesionario', departamentoCesionario);
                ipInputMap.put('tipoDocCesionario', tipoDocCesionario);
                ipInputMap.put('numDocCesionario', numDocCesionario);
                System.debug('Cesion Imei -> Ip Map input: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcConsultaDuplicados'){
                String imei = (String) request.get('imei');
                System.debug('ConsultaDuplicados Imei -> ' + imei);
                String min = (String) request.get('min');
                System.debug('ConsultaDuplicados min -> ' + min);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                System.debug('ConsultaDuplicados Ip -> Ip Map input: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcConsultaDuplasPorId'){
                String numeroIdentificacion = (String) request.get('numeroIdentificacion');
                System.debug('ConsultaDuplasPorId numeroIdentificacion -> ' + numeroIdentificacion);
                String tipoIdentificacion = (String) request.get('tipoIdentificacion');
                System.debug('ConsultaDuplasPorId tipoIdentificacion -> ' + tipoIdentificacion);
                ipInputMap.put('numeroIdentificacion', numeroIdentificacion);
                ipInputMap.put('tipoIdentificacion', tipoIdentificacion);
                System.debug('ConsultaDuplasPorId Ip -> Ip Map input: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcGestionDuplicados'){
                String nombres = (String) request.get('nombres');
                System.debug('Gestion Duplicados Nombres -> ' + nombres);
                String apellidos = (String) request.get('apellidos');
                System.debug('Gestion Duplicados Apellidos -> ' + apellidos);
                String tipoDoc = (String) request.get('tipoDoc');
                System.debug('Gestion Duplicados Tipo Documento -> ' + tipoDoc);
                String numeroDoc = (String) request.get('numeroDoc');
                System.debug('Gestion Duplicados Numero Documento -> ' + numeroDoc);
                String marca = (String) request.get('marca');
                System.debug('Gestion Duplicados Marca -> ' + marca);
                String modelo = (String) request.get('modelo');
                System.debug('Gestion Duplicados Modelo -> ' + modelo);
                String imei = (String) request.get('imei');
                System.debug('Gestion Duplicados Imei -> ' + imei);
                String min = (String) request.get('min');
                System.debug('Gestion Duplicados Min -> ' + min);
                String imsi = (String) request.get('imsi');
                System.debug('Gestion Duplicados Imsi -> ' + imsi);
                String detalle = (String) request.get('detalle');
                System.debug('Gestion Duplicados Detalle -> ' + detalle);
                String direccion = (String) request.get('direccion');
                System.debug('Gestion Duplicados Direccion -> ' + direccion);
                String ciudad = (String) request.get('ciudad');
                System.debug('Gestion Duplicados Ciudad -> ' + ciudad);
                String tipoOperacion = (String) request.get('tipoOperacion');
                System.debug('Gestion Duplicados Tipo Operacion -> ' + tipoOperacion);
                String infoLegal = (String) request.get('infoLegal');
                System.debug('Gestion Duplicados Info Legal -> ' + infoLegal);
                String userId = (String) request.get('userId');
                System.debug('Gestion Duplicados User Id -> ' + userId);
                ipInputMap.put('nombres', nombres);
                ipInputMap.put('apellidos', apellidos);
                ipInputMap.put('tipoDoc', tipoDoc);
                ipInputMap.put('numeroDoc', numeroDoc);
                ipInputMap.put('marca', marca);
                ipInputMap.put('modelo', modelo);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                ipInputMap.put('imsi', imsi);
                ipInputMap.put('detalle', detalle);
                ipInputMap.put('direccion', direccion);
                ipInputMap.put('ciudad', ciudad);
                ipInputMap.put('tipoOperacion', tipoOperacion);
                ipInputMap.put('infoLegal', infoLegal);
                ipInputMap.put('userId', userId);
                System.debug('Gestion Duplicados -> Ip Map input: ' + ipInputMap);
            }
            else if(path == 'PVU_IPsvcImeiDataList'){
                String imei = (String) request.get('imei');
                System.debug('ImeiDataList Imei -> ' + imei);
                String min = (String) request.get('min');
                System.debug('ImeiDataList Min -> ' + min);
                String nombres = (String) request.get('nombres');
                System.debug('ImeiDataList Nombres -> ' + nombres);
                String apellidos = (String) request.get('apellidos');
                System.debug('ImeiDataList Apellidos -> ' + apellidos);
                String tipoDoc = (String) request.get('tipoDoc');
                System.debug('ImeiDataList Tipo Documento -> ' + tipoDoc);
                String numeroDoc = (String) request.get('numeroDoc');
                System.debug('ImeiDataList Numero Documento -> ' + numeroDoc);
                String marca = (String) request.get('marca');
                System.debug('ImeiDataList Marca -> ' + marca);
                String modelo = (String) request.get('modelo');
                System.debug('ImeiDataList Modelo -> ' + modelo);
                String imsi = (String) request.get('imsi');
                System.debug('ImeiDataList Imsi -> ' + imsi);
                String detalle = (String) request.get('detalle');
                System.debug('ImeiDataList Detalle -> ' + detalle);
                String direccion = (String) request.get('direccion');
                System.debug('ImeiDataList Direccion -> ' + direccion);
                String ciudad = (String) request.get('ciudad');
                System.debug('ImeiDataList Ciudad -> ' + ciudad);
                String tipoOperacion = (String) request.get('tipoOperacion');
                System.debug('ImeiDataList Tipo Operacion -> ' + tipoOperacion);
                String infoLegal = (String) request.get('infoLegal');
                System.debug('ImeiDataList Info Legal -> ' + infoLegal);
                String userId = (String) request.get('userId');
                System.debug('ImeiDataList User Id -> ' + userId);
                ipInputMap.put('nombres', nombres);
                ipInputMap.put('apellidos', apellidos);
                ipInputMap.put('tipoDoc', tipoDoc);
                ipInputMap.put('numeroDoc', numeroDoc);
                ipInputMap.put('marca', marca);
                ipInputMap.put('modelo', modelo);
                ipInputMap.put('imei', imei);
                ipInputMap.put('min', min);
                ipInputMap.put('imsi', imsi);
                ipInputMap.put('detalle', detalle);
                ipInputMap.put('direccion', direccion);
                ipInputMap.put('ciudad', ciudad);
                ipInputMap.put('tipoOperacion', tipoOperacion);
                ipInputMap.put('infoLegal', infoLegal);
                ipInputMap.put('userId', userId);
                System.debug('ImeiDataList -> Ip Map input: ' + ipInputMap);
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
    
    public class CustomException extends Exception {}
    
}