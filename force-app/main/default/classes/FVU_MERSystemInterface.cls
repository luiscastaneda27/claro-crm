global class FVU_MERSystemInterface implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            if (methodName == 'RequestConstruirDireccionHhpp') {
                result = requestConstruirDireccionHhpp(inputMap, outputMap, options);

            } else if (methodName == 'GenerateHeaderRequest') {
                result = generateHeaderRequest(inputMap, outputMap, options);

            } else if (methodName == 'CallIP') {
                Map<String, Object> request = (Map<String, Object>)inputMap.get('request');
                String path = (String)inputMap.get('nameIP'); 
                Map<String, Object> response =  callIP(request, path);
                outputMap.put('response', response);
            
            } else if (methodName == 'RequestObtenerBarrioListHhpp') {
                result = requestObtenerBarrioListHhpp(inputMap, outputMap, options);
            
            } else if (methodName == 'RequestConsultaDireccionGeneral') {
                result = requestConsultaDireccionGeneral(inputMap, outputMap, options);
            
            } else if (methodName == 'RequestConsultaDireccion') {
            result = requestConsultaDireccion(inputMap, outputMap, options);
            }


        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In FVU_MERSystemInterface.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }

    public static Boolean generateHeaderRequest(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
            Map<String,Object> requestHeader = new Map<String,Object>();
            requestHeader.put('traceabilityId', inputMap.get('traceabilityId'));
            requestHeader.put('ipApplication', inputMap.get('ipApplication'));
            requestHeader.put('requestDate', DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS'));
            requestHeader.put('password', inputMap.get('password'));
            requestHeader.put('user', inputMap.get('user'));
            requestHeader.put('system', inputMap.get('system'));
            requestHeader.put('transactionId', inputMap.get('transactionId'));
            outputMap.put('headerRequest', requestHeader);
            return true;

        } catch (Exception e) {
            throw e;
        }
    }

    public static Boolean requestConstruirDireccionHhpp(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
            String addressType =(String) inputMap.get('typeAddress');
            String tipoAdicion =(String) inputMap.get('tipoAdicion');
           
            Map<String,Object> request = new Map<String,Object>();
            Map<String,Object> direccion = new Map<String,Object>();
            request.put('idUsuario', 'hitss');
            
            if (tipoAdicion == 'P' || tipoAdicion == 'C' || tipoAdicion == 'A') {
                request.put('valorNivel', inputMap.get('valorNivel')); 
                request.put('tipoNivel', inputMap.get('tipoNivel')); 
            }

            request.put('tipoAdicion',tipoAdicion);
            request.put('comunidad', inputMap.get('dane'));

            if (addressType == 'CK') {
                request.put('direccionStr', inputMap.get('street')); 
            }

            if (!inputMap.containsKey('drDireccion') || inputMap.get('drDireccion') == null || inputMap.get('drDireccion') == '') 
            {
                 direccion.put('idTipoDireccion', addressType);
                 if (addressType == 'CK' && inputMap.containsKey('barrio') && String.isNotBlank(String.valueOf(inputMap.get('barrio')))) {
                        direccion.put('barrio', inputMap.get('barrio'));
                 }
                 if (addressType == 'CK' && inputMap.containsKey('multiorigen') && Boolean.valueOf(inputMap.get('multiorigen'))) {
                    direccion.put('barrio','SalesForce');
                 }
                 request.put('drDireccion', direccion); 
            } else {
                Map<String,Object> drDireccion = (Map<String,Object>)inputMap.get('drDireccion');
                
                if (drDireccion.containsKey('usuarioEdicion')) {
                    direccion.put('usuarioEdicion', drDireccion.get('usuarioEdicion'));
                }
                if (drDireccion.containsKey('usuarioCreacion')) {
                    direccion.put('usuarioCreacion', drDireccion.get('usuarioCreacion'));
                }
                if (drDireccion.containsKey('tipoViaPrincipal')) {
                    direccion.put('tipoViaPrincipal', drDireccion.get('tipoViaPrincipal'));
                }
                if (drDireccion.containsKey('tipoViaGeneradora')) {
                    direccion.put('tipoViaGeneradora', drDireccion.get('tipoViaGeneradora'));
                }
                if (drDireccion.containsKey('placaDireccion')) {
                    direccion.put('placaDireccion', drDireccion.get('placaDireccion'));
                }
                if (drDireccion.containsKey('perfilEdicion')) {
                    direccion.put('perfilEdicion', drDireccion.get('perfilEdicion'));
                }
                if (drDireccion.containsKey('perfilCreacion')) {
                    direccion.put('perfilCreacion', drDireccion.get('perfilCreacion'));
                }
                if (drDireccion.containsKey('numViaPrincipal')) {
                    direccion.put('numViaPrincipal', drDireccion.get('numViaPrincipal'));
                }
                if (drDireccion.containsKey('numViaGeneradora')) {
                    direccion.put('numViaGeneradora', drDireccion.get('numViaGeneradora'));
                }
                if (drDireccion.containsKey('nlPostViaP')) {
                    direccion.put('nlPostViaP', drDireccion.get('nlPostViaP'));
                }
                if (drDireccion.containsKey('nlPostViaG')) {
                    direccion.put('nlPostViaG', drDireccion.get('nlPostViaG'));
                }
                if (drDireccion.containsKey('mzValorNivel6')) {
                    direccion.put('mzValorNivel6', drDireccion.get('mzValorNivel6'));
                }
                if (drDireccion.containsKey('mzValorNivel5')) {
                    direccion.put('mzValorNivel5', drDireccion.get('mzValorNivel5'));
                }
                if (drDireccion.containsKey('mzValorNivel4')) {
                    direccion.put('mzValorNivel4', drDireccion.get('mzValorNivel4'));
                }
                if (drDireccion.containsKey('mzValorNivel3')) {
                    direccion.put('mzValorNivel3', drDireccion.get('mzValorNivel3'));
                }
                if (drDireccion.containsKey('mzValorNivel2')) {
                    direccion.put('mzValorNivel2', drDireccion.get('mzValorNivel2'));
                }
                if (drDireccion.containsKey('mzValorNivel1')) {
                    direccion.put('mzValorNivel1', drDireccion.get('mzValorNivel1'));
                }
                if (drDireccion.containsKey('mzTipoNivel6')) {
                    direccion.put('mzTipoNivel6', drDireccion.get('mzTipoNivel6'));
                }
                if (drDireccion.containsKey('mzTipoNivel5')) {
                    direccion.put('mzTipoNivel5', drDireccion.get('mzTipoNivel5'));
                }
                if (drDireccion.containsKey('mzTipoNivel4')) {
                    direccion.put('mzTipoNivel4', drDireccion.get('mzTipoNivel4'));
                }
                if (drDireccion.containsKey('mzTipoNivel3')) {
                    direccion.put('mzTipoNivel3', drDireccion.get('mzTipoNivel3'));
                }
                if (drDireccion.containsKey('mzTipoNivel2')) {
                    direccion.put('mzTipoNivel2', drDireccion.get('mzTipoNivel2'));
                }
                if (drDireccion.containsKey('mzTipoNivel1')) {
                    direccion.put('mzTipoNivel1', drDireccion.get('mzTipoNivel1'));
                }if (drDireccion.containsKey('ltViaPrincipal')) {
                    direccion.put('ltViaPrincipal', drDireccion.get('ltViaPrincipal'));
                }
                if (drDireccion.containsKey('ltViaGeneradora')) {
                    direccion.put('ltViaGeneradora', drDireccion.get('ltViaGeneradora'));
                }
                if (drDireccion.containsKey('letra3G')) {
                    direccion.put('letra3G', drDireccion.get('letra3G'));
                }
                if (drDireccion.containsKey('itValorPlaca')) {
                    direccion.put('itValorPlaca', drDireccion.get('itValorPlaca'));
                }
                if (drDireccion.containsKey('itTipoPlaca')) {
                    direccion.put('itTipoPlaca', drDireccion.get('itTipoPlaca'));
                }
                if (drDireccion.containsKey('idTipoDireccion')) {
                    direccion.put('idTipoDireccion', drDireccion.get('idTipoDireccion'));
                }
                if (drDireccion.containsKey('idSolicitud')) {
                    direccion.put('idSolicitud', drDireccion.get('idSolicitud'));
                }
                if (drDireccion.containsKey('idDirCatastro')) {
                    direccion.put('idDirCatastro', drDireccion.get('idDirCatastro'));
                }
                if (drDireccion.containsKey('id')) {
                    direccion.put('id', drDireccion.get('id'));
                }
                if (drDireccion.containsKey('fechaEdicion')) {
                    direccion.put('fechaEdicion', drDireccion.get('fechaEdicion'));
                }
                if (drDireccion.containsKey('fechaCreacion')) {
                    direccion.put('fechaCreacion', drDireccion.get('fechaCreacion'));
                }
                if (drDireccion.containsKey('estrato')) {
                    direccion.put('estrato', drDireccion.get('estrato'));
                }
                if (drDireccion.containsKey('estadoRegistro')) {
                    direccion.put('estadoRegistro', drDireccion.get('estadoRegistro'));
                }
                if (drDireccion.containsKey('estadoDirGeo')) {
                    direccion.put('estadoDirGeo', drDireccion.get('estadoDirGeo'));
                }
                if (drDireccion.containsKey('dirPrincAlt')) {
                    direccion.put('dirPrincAlt', drDireccion.get('dirPrincAlt'));
                }
                if (drDireccion.containsKey('dirEstado')) {
                    direccion.put('dirEstado', drDireccion.get('dirEstado'));
                }
                if (drDireccion.containsKey('cuadViaPrincipal')) {
                    direccion.put('cuadViaPrincipal', drDireccion.get('cuadViaPrincipal'));
                }
                if (drDireccion.containsKey('cuadViaGeneradora')) {
                    direccion.put('cuadViaGeneradora', drDireccion.get('cuadViaGeneradora'));
                }
                if (drDireccion.containsKey('cpValorNivel6')) {
                    direccion.put('cpValorNivel6', drDireccion.get('cpValorNivel6'));
                }
                if (drDireccion.containsKey('cpValorNivel5')) {
                    direccion.put('cpValorNivel5', drDireccion.get('cpValorNivel5'));
                }
                if (drDireccion.containsKey('cpValorNivel4')) {
                    direccion.put('cpValorNivel4', drDireccion.get('cpValorNivel4'));
                }
                if (drDireccion.containsKey('cpValorNivel3')) {
                    direccion.put('cpValorNivel3', drDireccion.get('cpValorNivel3'));
                }
                if (drDireccion.containsKey('cpValorNivel2')) {
                    direccion.put('cpValorNivel2', drDireccion.get('cpValorNivel2'));
                }
                if (drDireccion.containsKey('cpValorNivel1')) {
                    direccion.put('cpValorNivel1', drDireccion.get('cpValorNivel1'));
                }
                if (drDireccion.containsKey('cpTipoNivel6')) {
                    direccion.put('cpTipoNivel6', drDireccion.get('cpTipoNivel6'));
                }
                if (drDireccion.containsKey('cpTipoNivel5')) {
                    direccion.put('cpTipoNivel5', drDireccion.get('cpTipoNivel5'));
                }
                if (drDireccion.containsKey('cpTipoNivel4')) {
                    direccion.put('cpTipoNivel4', drDireccion.get('cpTipoNivel4'));
                }
                if (drDireccion.containsKey('cpTipoNivel3')) {
                    direccion.put('cpTipoNivel3', drDireccion.get('cpTipoNivel3'));
                }
                if (drDireccion.containsKey('cpTipoNivel2')) {
                    direccion.put('cpTipoNivel2', drDireccion.get('cpTipoNivel2'));
                }
                if (drDireccion.containsKey('cpTipoNivel1')) {
                    direccion.put('cpTipoNivel1', drDireccion.get('cpTipoNivel1'));
                }
                if (drDireccion.containsKey('bisViaPrincipal')) {
                    direccion.put('bisViaPrincipal', drDireccion.get('bisViaPrincipal'));
                }
                if (drDireccion.containsKey('bisViaGeneradora')) {
                    direccion.put('bisViaGeneradora', drDireccion.get('bisViaGeneradora'));
                }
                if (drDireccion.containsKey('barrioTxtBM')) {
                    direccion.put('barrioTxtBM', drDireccion.get('barrioTxtBM'));
                }
                if (drDireccion.containsKey('barrio')) {
                    direccion.put('barrio', drDireccion.get('barrio'));
                } 
                if (addressType == 'CK' && inputMap.containsKey('multiorigen') && Boolean.valueOf(inputMap.get('multiorigen'))) {
                    direccion.put('barrio','SalesForce');
                 }
                request.put('drDireccion', direccion);
            }
            
            request.put('headerRequest', inputMap.get('headerRequest'));

            outputMap.put('request', request);
            System.debug('RESPONSE - requestConstruirDireccionHhpp: '+JSON.serialize(request));
            return true;
        } catch (Exception e) {
            throw e;
        }
    }

    public static Map<String, Object> callIP(Map<String, Object> request, String path) {
        try{
            system.debug('FVU_MERSystemInterface.callIP request: '+request);
            system.debug('FVU_MERSystemInterface.callIP path: '+path);
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            result = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(path, request, ipOptions);
            system.debug('FVU_MERSystemInterface.callIP result: '+result);
            return result;
        }catch(Exception e){
            System.debug('FVU_MERSystemInterface.callIP - Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
            throw e;
        }
    }

    public static Boolean requestObtenerBarrioListHhpp(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
                      
            Map<String,Object> request = new Map<String,Object>();
            Map<String,Object> direccion = new Map<String,Object>();
            request.put('idUsuario', 'hitss');
            request.put('comunidad', inputMap.get('dane'));
            if (inputMap.containsKey('drDireccion')) {
               
                Map<String,Object> drDireccion = (Map<String,Object>)inputMap.get('drDireccion');
                
                if (drDireccion.containsKey('usuarioEdicion')) {
                    direccion.put('usuarioEdicion', drDireccion.get('usuarioEdicion'));
                }
                if (drDireccion.containsKey('usuarioCreacion')) {
                    direccion.put('usuarioCreacion', drDireccion.get('usuarioCreacion'));
                }
                if (drDireccion.containsKey('tipoViaPrincipal')) {
                    direccion.put('tipoViaPrincipal', drDireccion.get('tipoViaPrincipal'));
                }
                if (drDireccion.containsKey('tipoViaGeneradora')) {
                    direccion.put('tipoViaGeneradora', drDireccion.get('tipoViaGeneradora'));
                }
                if (drDireccion.containsKey('placaDireccion')) {
                    direccion.put('placaDireccion', drDireccion.get('placaDireccion'));
                }
                if (drDireccion.containsKey('perfilEdicion')) {
                    direccion.put('perfilEdicion', drDireccion.get('perfilEdicion'));
                }
                if (drDireccion.containsKey('perfilCreacion')) {
                    direccion.put('perfilCreacion', drDireccion.get('perfilCreacion'));
                }
                if (drDireccion.containsKey('numViaPrincipal')) {
                    direccion.put('numViaPrincipal', drDireccion.get('numViaPrincipal'));
                }
                if (drDireccion.containsKey('numViaGeneradora')) {
                    direccion.put('numViaGeneradora', drDireccion.get('numViaGeneradora'));
                }
                if (drDireccion.containsKey('nlPostViaP')) {
                    direccion.put('nlPostViaP', drDireccion.get('nlPostViaP'));
                }
                if (drDireccion.containsKey('nlPostViaG')) {
                    direccion.put('nlPostViaG', drDireccion.get('nlPostViaG'));
                }
                if (drDireccion.containsKey('mzValorNivel6')) {
                    direccion.put('mzValorNivel6', drDireccion.get('mzValorNivel6'));
                }
                if (drDireccion.containsKey('mzValorNivel5')) {
                    direccion.put('mzValorNivel5', drDireccion.get('mzValorNivel5'));
                }
                if (drDireccion.containsKey('mzValorNivel4')) {
                    direccion.put('mzValorNivel4', drDireccion.get('mzValorNivel4'));
                }
                if (drDireccion.containsKey('mzValorNivel3')) {
                    direccion.put('mzValorNivel3', drDireccion.get('mzValorNivel3'));
                }
                if (drDireccion.containsKey('mzValorNivel2')) {
                    direccion.put('mzValorNivel2', drDireccion.get('mzValorNivel2'));
                }
                if (drDireccion.containsKey('mzValorNivel1')) {
                    direccion.put('mzValorNivel1', drDireccion.get('mzValorNivel1'));
                }
                if (drDireccion.containsKey('mzTipoNivel6')) {
                    direccion.put('mzTipoNivel6', drDireccion.get('mzTipoNivel6'));
                }
                if (drDireccion.containsKey('mzTipoNivel5')) {
                    direccion.put('mzTipoNivel5', drDireccion.get('mzTipoNivel5'));
                }
                if (drDireccion.containsKey('mzTipoNivel4')) {
                    direccion.put('mzTipoNivel4', drDireccion.get('mzTipoNivel4'));
                }
                if (drDireccion.containsKey('mzTipoNivel3')) {
                    direccion.put('mzTipoNivel3', drDireccion.get('mzTipoNivel3'));
                }
                if (drDireccion.containsKey('mzTipoNivel2')) {
                    direccion.put('mzTipoNivel2', drDireccion.get('mzTipoNivel2'));
                }
                if (drDireccion.containsKey('mzTipoNivel1')) {
                    direccion.put('mzTipoNivel1', drDireccion.get('mzTipoNivel1'));
                }if (drDireccion.containsKey('ltViaPrincipal')) {
                    direccion.put('ltViaPrincipal', drDireccion.get('ltViaPrincipal'));
                }
                if (drDireccion.containsKey('ltViaGeneradora')) {
                    direccion.put('ltViaGeneradora', drDireccion.get('ltViaGeneradora'));
                }
                if (drDireccion.containsKey('letra3G')) {
                    direccion.put('letra3G', drDireccion.get('letra3G'));
                }
                if (drDireccion.containsKey('itValorPlaca')) {
                    direccion.put('itValorPlaca', drDireccion.get('itValorPlaca'));
                }
                if (drDireccion.containsKey('itTipoPlaca')) {
                    direccion.put('itTipoPlaca', drDireccion.get('itTipoPlaca'));
                }
                if (drDireccion.containsKey('idTipoDireccion')) {
                    direccion.put('idTipoDireccion', drDireccion.get('idTipoDireccion'));
                }
                if (drDireccion.containsKey('idSolicitud')) {
                    direccion.put('idSolicitud', drDireccion.get('idSolicitud'));
                }
                if (drDireccion.containsKey('idDirCatastro')) {
                    direccion.put('idDirCatastro', drDireccion.get('idDirCatastro'));
                }
                if (drDireccion.containsKey('id')) {
                    direccion.put('id', drDireccion.get('id'));
                }
                if (drDireccion.containsKey('fechaEdicion')) {
                    direccion.put('fechaEdicion', drDireccion.get('fechaEdicion'));
                }
                if (drDireccion.containsKey('fechaCreacion')) {
                    direccion.put('fechaCreacion', drDireccion.get('fechaCreacion'));
                }
                if (drDireccion.containsKey('estrato')) {
                    direccion.put('estrato', drDireccion.get('estrato'));
                }
                if (drDireccion.containsKey('estadoRegistro')) {
                    direccion.put('estadoRegistro', drDireccion.get('estadoRegistro'));
                }
                if (drDireccion.containsKey('estadoDirGeo')) {
                    direccion.put('estadoDirGeo', drDireccion.get('estadoDirGeo'));
                }
                if (drDireccion.containsKey('dirPrincAlt')) {
                    direccion.put('dirPrincAlt', drDireccion.get('dirPrincAlt'));
                }
                if (drDireccion.containsKey('dirEstado')) {
                    direccion.put('dirEstado', drDireccion.get('dirEstado'));
                }
                if (drDireccion.containsKey('cuadViaPrincipal')) {
                    direccion.put('cuadViaPrincipal', drDireccion.get('cuadViaPrincipal'));
                }
                if (drDireccion.containsKey('cuadViaGeneradora')) {
                    direccion.put('cuadViaGeneradora', drDireccion.get('cuadViaGeneradora'));
                }
                if (drDireccion.containsKey('cpValorNivel6')) {
                    direccion.put('cpValorNivel6', drDireccion.get('cpValorNivel6'));
                }
                if (drDireccion.containsKey('cpValorNivel5')) {
                    direccion.put('cpValorNivel5', drDireccion.get('cpValorNivel5'));
                }
                if (drDireccion.containsKey('cpValorNivel4')) {
                    direccion.put('cpValorNivel4', drDireccion.get('cpValorNivel4'));
                }
                if (drDireccion.containsKey('cpValorNivel3')) {
                    direccion.put('cpValorNivel3', drDireccion.get('cpValorNivel3'));
                }
                if (drDireccion.containsKey('cpValorNivel2')) {
                    direccion.put('cpValorNivel2', drDireccion.get('cpValorNivel2'));
                }
                if (drDireccion.containsKey('cpValorNivel1')) {
                    direccion.put('cpValorNivel1', drDireccion.get('cpValorNivel1'));
                }
                if (drDireccion.containsKey('cpTipoNivel6')) {
                    direccion.put('cpTipoNivel6', drDireccion.get('cpTipoNivel6'));
                }
                if (drDireccion.containsKey('cpTipoNivel5')) {
                    direccion.put('cpTipoNivel5', drDireccion.get('cpTipoNivel5'));
                }
                if (drDireccion.containsKey('cpTipoNivel4')) {
                    direccion.put('cpTipoNivel4', drDireccion.get('cpTipoNivel4'));
                }
                if (drDireccion.containsKey('cpTipoNivel3')) {
                    direccion.put('cpTipoNivel3', drDireccion.get('cpTipoNivel3'));
                }
                if (drDireccion.containsKey('cpTipoNivel2')) {
                    direccion.put('cpTipoNivel2', drDireccion.get('cpTipoNivel2'));
                }
                if (drDireccion.containsKey('cpTipoNivel1')) {
                    direccion.put('cpTipoNivel1', drDireccion.get('cpTipoNivel1'));
                }
                if (drDireccion.containsKey('bisViaPrincipal')) {
                    direccion.put('bisViaPrincipal', drDireccion.get('bisViaPrincipal'));
                }
                if (drDireccion.containsKey('bisViaGeneradora')) {
                    direccion.put('bisViaGeneradora', drDireccion.get('bisViaGeneradora'));
                }
                if (drDireccion.containsKey('barrioTxtBM')) {
                    direccion.put('barrioTxtBM', drDireccion.get('barrioTxtBM'));
                }
                if (drDireccion.containsKey('barrio')) {
                    direccion.put('barrio', drDireccion.get('barrio'));
                }
                request.put('drDireccion', direccion);
            }
            
            request.put('headerRequest', inputMap.get('headerRequest'));

            outputMap.put('request', request);
            System.debug('RESPONSE - requestObtenerBarrioListHhpp: '+JSON.serialize(request));
            return true;
        } catch (Exception e) {
            throw e;
        }
    }

    public static Boolean requestConsultaDireccionGeneral(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
                      
            Map<String,Object> request = new Map<String,Object>();
            Map<String,Object> direccion = new Map<String,Object>();
            
            if (inputMap.containsKey('drDireccion')) {
               
                Map<String,Object> direccionTabulada = (Map<String,Object>)inputMap.get('drDireccion');
                if (direccionTabulada.containsKey('idDireccionDetallada')) {
                    direccion.put('idDireccionDetallada', direccionTabulada.get('idDireccionDetallada'));
                }
                if (direccionTabulada.containsKey('letra3G')) {
                    direccion.put('letra3G', direccionTabulada.get('letra3G'));
                }
                if (direccionTabulada.containsKey('estadoDirGeo')) {
                    direccion.put('estadoDirGeo', direccionTabulada.get('estadoDirGeo'));
                }
                if (direccionTabulada.containsKey('itValorPlaca')) {
                    direccion.put('itValorPlaca', direccionTabulada.get('itValorPlaca'));
                }
                if (direccionTabulada.containsKey('itTipoPlaca')) {
                    direccion.put('itTipoPlaca', direccionTabulada.get('itTipoPlaca'));
                }
                if (direccionTabulada.containsKey('mzValorNivel6')) {
                    direccion.put('mzValorNivel6', direccionTabulada.get('mzValorNivel6'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel6')) {
                    direccion.put('mzTipoNivel6', direccionTabulada.get('mzTipoNivel6'));
                }
                if (direccionTabulada.containsKey('idDirCatastro')) {
                    direccion.put('idDirCatastro', direccionTabulada.get('idDirCatastro'));
                }
                if (direccionTabulada.containsKey('mzValorNivel5')) {
                    direccion.put('mzValorNivel5', direccionTabulada.get('mzValorNivel5'));
                }
                if (direccionTabulada.containsKey('mzValorNivel4')) {
                    direccion.put('mzValorNivel4', direccionTabulada.get('mzValorNivel4'));
                }
                if (direccionTabulada.containsKey('mzValorNivel3')) {
                    direccion.put('mzValorNivel3', direccionTabulada.get('mzValorNivel3'));
                }
                if (direccionTabulada.containsKey('mzValorNivel2')) {
                    direccion.put('mzValorNivel2', direccionTabulada.get('mzValorNivel2'));
                }
                if (direccionTabulada.containsKey('mzValorNivel1')) {
                    direccion.put('mzValorNivel1', direccionTabulada.get('mzValorNivel1'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel5')) {
                    direccion.put('mzTipoNivel5', direccionTabulada.get('mzTipoNivel5'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel4')) {
                    direccion.put('mzTipoNivel4', direccionTabulada.get('mzTipoNivel4'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel3')) {
                    direccion.put('mzTipoNivel3', direccionTabulada.get('mzTipoNivel3'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel2')) {
                    direccion.put('mzTipoNivel2', direccionTabulada.get('mzTipoNivel2'));
                }
                if (direccionTabulada.containsKey('mzTipoNivel1')) {
                    direccion.put('mzTipoNivel1', direccionTabulada.get('mzTipoNivel1'));
                }
                if (direccionTabulada.containsKey('cpValorNivel6')) {
                    direccion.put('cpValorNivel6', direccionTabulada.get('cpValorNivel6'));
                }
                if (direccionTabulada.containsKey('cpValorNivel5')) {
                    direccion.put('cpValorNivel5', direccionTabulada.get('cpValorNivel5'));
                }
                if (direccionTabulada.containsKey('cpValorNivel4')) {
                    direccion.put('cpValorNivel4', direccionTabulada.get('cpValorNivel4'));
                }
                if (direccionTabulada.containsKey('cpValorNivel3')) {
                    direccion.put('cpValorNivel3', direccionTabulada.get('cpValorNivel3'));
                }
                if (direccionTabulada.containsKey('cpValorNivel2')) {
                    direccion.put('cpValorNivel2', direccionTabulada.get('cpValorNivel2'));
                }
                if (direccionTabulada.containsKey('cpValorNivel1')) {
                    direccion.put('cpValorNivel1', direccionTabulada.get('cpValorNivel1'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel6')) {
                    direccion.put('cpTipoNivel6', direccionTabulada.get('cpTipoNivel6'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel5')) {
                    direccion.put('cpTipoNivel5', direccionTabulada.get('cpTipoNivel5'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel4')) {
                    direccion.put('cpTipoNivel4', direccionTabulada.get('cpTipoNivel4'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel3')) {
                    direccion.put('cpTipoNivel3', direccionTabulada.get('cpTipoNivel3'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel2')) {
                    direccion.put('cpTipoNivel2', direccionTabulada.get('cpTipoNivel2'));
                }
                if (direccionTabulada.containsKey('cpTipoNivel1')) {
                    direccion.put('cpTipoNivel1', direccionTabulada.get('cpTipoNivel1'));
                }
                if (direccionTabulada.containsKey('placaDireccion')) {
                    direccion.put('placaDireccion', direccionTabulada.get('placaDireccion'));
                }
                if (direccionTabulada.containsKey('cuadViaGeneradora')) {
                    direccion.put('cuadViaGeneradora', direccionTabulada.get('cuadViaGeneradora'));
                }
                if (direccionTabulada.containsKey('bisViaGeneradora')) {
                    direccion.put('bisViaGeneradora', direccionTabulada.get('bisViaGeneradora'));
                }
                if (direccionTabulada.containsKey('nlPostViaG')) {
                    direccion.put('nlPostViaG', direccionTabulada.get('nlPostViaG'));
                }
                if (direccionTabulada.containsKey('ltViaGeneradora')) {
                    direccion.put('ltViaGeneradora', direccionTabulada.get('ltViaGeneradora'));
                }
                if (direccionTabulada.containsKey('numViaGeneradora')) {
                    direccion.put('numViaGeneradora', direccionTabulada.get('numViaGeneradora'));
                }
                if (direccionTabulada.containsKey('tipoViaGeneradora')) {
                    direccion.put('tipoViaGeneradora', direccionTabulada.get('tipoViaGeneradora'));
                }
                if (direccionTabulada.containsKey('cuadViaPrincipal')) {
                    direccion.put('cuadViaPrincipal', direccionTabulada.get('cuadViaPrincipal'));
                }
                if (direccionTabulada.containsKey('bisViaPrincipal')) {
                    direccion.put('bisViaPrincipal', direccionTabulada.get('bisViaPrincipal'));
                }
                if (direccionTabulada.containsKey('nlPostViaP')) {
                    direccion.put('nlPostViaP', direccionTabulada.get('nlPostViaP'));
                }
                if (direccionTabulada.containsKey('ltViaPrincipal')) {
                    direccion.put('ltViaPrincipal', direccionTabulada.get('ltViaPrincipal'));
                }
                if (direccionTabulada.containsKey('numViaPrincipal')) {
                    direccion.put('numViaPrincipal', direccionTabulada.get('numViaPrincipal'));
                }
                if (direccionTabulada.containsKey('tipoViaPrincipal')) {
                    direccion.put('tipoViaPrincipal', direccionTabulada.get('tipoViaPrincipal'));
                }
                if (direccionTabulada.containsKey('barrio')) {
                    direccion.put('barrio', direccionTabulada.get('barrio'));
                }
                if (inputMap.containsKey('multiorigen') && Boolean.valueOf(inputMap.get('multiorigen'))) {
                    direccion.put('barrio', inputMap.get('barrio'));
                }
                if (direccionTabulada.containsKey('dirPrincAlt')) {
                    direccion.put('dirPrincAlt', direccionTabulada.get('dirPrincAlt'));
                }
                if (direccionTabulada.containsKey('idTipoDireccion')) {
                    direccion.put('idTipoDireccion', direccionTabulada.get('idTipoDireccion'));
                }
                
        
                request.put('direccionTabulada', direccion);
            }
            request.put('user', 'hitss');
            request.put('codigoDane', inputMap.get('dane'));
            request.put('headerRequest', inputMap.get('headerRequest'));
    
            outputMap.put('request', request);
            System.debug('RESPONSE - requestConsultaDireccionGeneral: '+JSON.serialize(request));
            return true;
        } catch (Exception e) {
            throw e;
        }
    }

    public static Boolean requestConsultaDireccion(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
                      
            Map<String,Object> request = new Map<String,Object>();
            
            request.put('proyecto', 'P_INS');
            request.put('segmento', 'residencial');
            request.put('idDireccion', inputMap.get('idDireccion'));
            request.put('headerRequest', inputMap.get('headerRequest'));

    
            outputMap.put('request', request);
            System.debug('RESPONSE - requestConsultaDireccion: '+JSON.serialize(request));
            return true;
        } catch (Exception e) {
            throw e;
        }
    }
}