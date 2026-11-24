/**
 * @description       : ApexClass para generar request para servicio de IMEI
 * @author            : mauricio.oros@nespon.com
 * @group             : 
 * @last modified on  : 12-11-2025
 * @last modified by  : mauricio.oros@nespon.com
**/

global with sharing class PVU_IMEIBodyBuilder implements vlocity_cmt.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName == 'buildBody') {
                buildBody(inputMap,outMap);
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e.getStackTraceString());
            result = false;
        }
        
        return result;   
    }

    private static String buildBody(Map<String,Object> inputMap, Map<String,Object> outMap) {
        String category = normalizeCategory((String) inputMap.get('category'));
        String imei     = (String) inputMap.get('imei');
        String tipoReporteAbd     = (String) inputMap.get('tipoReporteAbd');
        String usuario     = (String) inputMap.get('usuario');
        String msisdn     = (String) inputMap.get('msisdn');
        String imsi     = (String) inputMap.get('imsi');
        String fiscalia     = (String) inputMap.get('fiscalia');
        String empleoViolencia     = (String) inputMap.get('empleoViolencia');
        String tipoArma     = (String) inputMap.get('tipoArma');
        String victimaMenorEdad     = (String) inputMap.get('victimaMenorEdad');
        String nombreReporte     = (String) inputMap.get('nombreReporte');
        String numIdReporte     = (String) inputMap.get('numIdReporte');
        String tipoDocReporte     = (String) inputMap.get('tipoDocReporte');
        String telContactoReporte     = (String) inputMap.get('telContactoReporte');
        String modelo     = (String) inputMap.get('modelo');
        String idCuenta     = (String) inputMap.get('idCuenta');
        String direccionReporte     = (String) inputMap.get('direccionReporte');
        String marca     = (String) inputMap.get('marca');
        String departamento     = (String) inputMap.get('departamento');
        String correo     = (String) inputMap.get('correo');
        String ciudad     = (String) inputMap.get('ciudad');
        String accion     = (String) inputMap.get('accion');
        String apellidos     = (String) inputMap.get('apellidos');
        String nombres     = (String) inputMap.get('nombres');
        String tipoDocumento     = (String) inputMap.get('tipoDocumento');
        String detalle     = (String) inputMap.get('detalle');
        String direccion     = (String) inputMap.get('direccion');
        String numeroDocumento     = (String) inputMap.get('numeroDocumento');
        String aceptaInfoLegal     = (String) inputMap.get('aceptaInfoLegal');
        String usuarioRed     = (String) inputMap.get('usuarioRed');
        Object compList     = inputMap.get('compList');
        
        Map<String, Object> body = new Map<String, Object>();

        List<Object> productOrderItemList = new List<Object>();
        Map<String, Object> productOrderItem = new Map<String, Object>();

        Map<String, Object> product = new Map<String, Object>();

        Map<String, Object> productSpecification = new Map<String, Object>();
        

        switch on category {
            when 'reporteIMEI' {
                productSpecification.put('name', 'Registro de IMEI');
                productSpecification.put('@type', 'ProductSpecificationRef');
            }
            when 'liberacionIMEI' {
                productSpecification.put('name', 'Registro de IMEI');
                productSpecification.put('@type', 'ProductSpecificationRef');
            }
            when 'registroIMEI' {
                productSpecification.put('name', 'Registro de IMEI');
                productSpecification.put('@type', 'ProductSpecificationRef');
            }
             when 'gestionDuplicadosIMEI' {
                productSpecification.put('name', 'Gestion Duplicados de IMEI');
                productSpecification.put('@type', 'ProductSpecificationRef');
            }
        }

        List<Object> pcList = new List<Object>();
        Asset assetIMEI = new Asset();
        String fechaActual;
        String docType;
		PVU_ParametrosIMEI__mdt prmIMEI = new PVU_ParametrosIMEI__mdt();
        
        if(category != 'registroIMEI' && imei != null){
            fechaActual = Datetime.now().format('dd/MM/yyyy HH:mm:ss');
            
            switch on category {
                when 'reporteIMEI' {
                    prmIMEI = [SELECT ID, DeveloperName, PVU_Canal__c, PVU_Operador__c,PVU_Password__c,PVU_tipoOperacion__c 
                               FROM PVU_ParametrosIMEI__mdt where DeveloperName = 'PVU_Reporte' WITH SECURITY_ENFORCED LIMIT 1];
                }
                when 'liberacionIMEI' {
                    prmIMEI = [SELECT ID, DeveloperName, PVU_Canal__c, PVU_Operador__c,PVU_Password__c,PVU_tipoOperacion__c 
                               FROM PVU_ParametrosIMEI__mdt where DeveloperName = 'PVU_Liberacion' WITH SECURITY_ENFORCED LIMIT 1];
                }
                when 'gestionDuplicadosIMEI' {
                    prmIMEI = [SELECT ID, DeveloperName, PVU_Canal__c, PVU_Operador__c,PVU_Password__c,PVU_tipoOperacion__c 
                               FROM PVU_ParametrosIMEI__mdt where DeveloperName = 'PVU_Duplicado' WITH SECURITY_ENFORCED LIMIT 1];
                }
            }
        }
        
        switch on category {
            when 'reporteIMEI' {
                pcList.add(makeCharacteristic('imei', imei));
                pcList.add(makeCharacteristic('tipoOperacion', prmIMEI.PVU_tipoOperacion__c));
                pcList.add(makeCharacteristic('Operador', prmIMEI.PVU_Operador__c));
                pcList.add(makeCharacteristic('usuario', usuario));
                pcList.add(makeCharacteristic('nombreReporte', nombreReporte));
                pcList.add(makeCharacteristic('direccionReporte', direccionReporte));
                pcList.add(makeCharacteristic('tipoDocReporte', tipoDocReporte));
                pcList.add(makeCharacteristic('numIdReporte', numIdReporte));
                pcList.add(makeCharacteristic('telContactoReporte', telContactoReporte));
                pcList.add(makeCharacteristic('departamentoReporte', departamento));
                pcList.add(makeCharacteristic('tipoReporteAbd', tipoReporteAbd));
                pcList.add(makeCharacteristic('msisdn', msisdn));
                pcList.add(makeCharacteristic('fiscalia', fiscalia));
                pcList.add(makeCharacteristic('empleoViolencia', empleoViolencia));
                pcList.add(makeCharacteristic('tipoArma', tipoArma));
                pcList.add(makeCharacteristic('victimaMenorEdad', victimaMenorEdad));
                pcList.add(makeCharacteristic('correo', correo));
                pcList.add(makeCharacteristic('marca', marca));
                pcList.add(makeCharacteristic('modelo', modelo));
                pcList.add(makeCharacteristic('fechaReporte', fechaActual));
                pcList.add(makeCharacteristic('canal', prmIMEI.PVU_Canal__c));
                pcList.add(makeCharacteristic('ciudadReporte', ciudad));
                pcList.add(makeCharacteristic('Password', prmIMEI.PVU_Password__c));
            }
            when 'liberacionIMEI' {
                pcList.add(makeCharacteristic('imei', imei));
                pcList.add(makeCharacteristic('tipoOperacion', prmIMEI.PVU_tipoOperacion__c));
                pcList.add(makeCharacteristic('Operador', prmIMEI.PVU_Operador__c));
                pcList.add(makeCharacteristic('usuario', usuario));
                pcList.add(makeCharacteristic('tipoReporteAbd', mapTipoReporteAbdToId(tipoReporteAbd)));
                pcList.add(makeCharacteristic('msisdn', msisdn));
                pcList.add(makeCharacteristic('fechaReporte', fechaActual));
                pcList.add(makeCharacteristic('canal', prmIMEI.PVU_Canal__c));
                pcList.add(makeCharacteristic('Password', prmIMEI.PVU_Password__c));
            }
            when 'registroIMEI' {
                pcList.add(makeCharacteristic('imei', imei));
                pcList.add(makeCharacteristic('msisdn', msisdn));
                pcList.add(makeCharacteristic('imsi', imsi));
            }
            when 'gestionDuplicadosIMEI' {
                //cargar la lista de duplas
                pcList.add(makeCharacteristic('nombres', nombres));
                pcList.add(makeCharacteristic('apellidos', apellidos));
                pcList.add(makeCharacteristic('tipoDocumento', tipoDocumento));
                pcList.add(makeCharacteristic('numeroDocumento', numeroDocumento));
                pcList.add(makeCharacteristic('marca', marca));
                pcList.add(makeCharacteristic('modelo', modelo));
                pcList.add(makeCharacteristic('imei', imei));
                //el valor es una lista
                pcList.add(makeCharacteristic('compList', normalizeCompList(compList)));
                
                pcList.add(makeCharacteristic('detalle', detalle));
                pcList.add(makeCharacteristic('direccion', direccion));
                pcList.add(makeCharacteristic('ciudad', ciudad));
                pcList.add(makeCharacteristic('canal', prmIMEI.PVU_Canal__c));
              
                pcList.add(makeCharacteristic('tipoOperacion', accion == 'add' ? '1' : '2'));
                pcList.add(makeCharacteristic('aceptaInfoLegal', aceptaInfoLegal));
                pcList.add(makeCharacteristic('usuarioRed', usuarioRed));
                pcList.add(makeCharacteristic('correo', correo));
                pcList.add(makeCharacteristic('Password', prmIMEI.PVU_Password__c));


            }
        }
        product.put('productCharacteristic', pcList);
        product.put('productSpecification', productSpecification);
        product.put('@type', 'Product');
        productOrderItem.put('product', product);
        productOrderItem.put('@type', 'ProductOrderItem');
        if(category == 'registroIMEI'){
            List<Object> noteList = new List<Object>{
                new Map<String,Object>{
                    '@type' => 'Note',
                    'text'  => null
                }
            };
    
            productOrderItem.put('note', noteList);
        }
        switch on category {
            when 'reporteIMEI' {
                productOrderItem.put('action', 'add');
            }
            when 'liberacionIMEI' {
                productOrderItem.put('action', 'add');
            }
            when 'registroIMEI' {
                productOrderItem.put('action', null);
            }
             when 'gestionDuplicadosIMEI' {
                // adicion o delete
                productOrderItem.put('action', accion);
            }
        }
        
        productOrderItem.put('id', '1');

        productOrderItemList.add(productOrderItem);
   
        Map<String, Object> channelWrapper = new Map<String, Object>{
            'channel' => new Map<String,Object>{
                'name' => 'SALESFORCE',
                'id' => 'SF'                
            },
            '@type' => 'RelatedChannel',
            'role' => 'POSVENTA'
        };
		
        body.put('@baseType', 'ProductOrder');
        body.put('@type', 'ProductOrder');
        body.put('channel', new List<Object>{ channelWrapper });
        body.put('relatedParty', new List<Object>());
        body.put('productOrderItem', productOrderItemList);
        
        switch on category {
            when 'reporteIMEI' {
                body.put('description', 'Solicitud de reporte de IMEI');
            }
            when 'liberacionIMEI' {
                body.put('description', 'Solicitud de liberación de IMEI');
            }
            when 'registroIMEI' {
                body.put('description', 'Solicitud de registro de IMEI');
            }
            when 'gestionDuplicadosIMEI' {
                body.put('description', 'Solicitud de Gestion Duplicados de IMEI');
            }
        }
        body.put('category', category);
        
        outMap.put('body', body);
        outMap.put('category', category);
        outMap.put('imei', imei);
        return JSON.serialize(body);
    }

    private static Map<String,Object> makeCharacteristic(String name, Object value) {
        return new Map<String,Object>{
            'valueType' => value instanceof List<Object> ? 'array' : 'string',
            'value' => value,
            'name' => name
        };
    }

    private static String normalizeCategory(String category) {
        if (String.isBlank(category)) {
            return category;
        }

        String normalized = category.trim();

        if (normalized == 'duplicado' || normalized == 'duplicadoIMEI') {
            return 'gestionDuplicadosIMEI';
        }

        return normalized;
    }

    private static Object normalizeCompList(Object compList) {
        if (!(compList instanceof List<Object>)) {
            return compList;
        }

        List<Object> normalizedList = new List<Object>();

        for (Object item : (List<Object>) compList) {
            if (!(item instanceof Map<String,Object>)) {
                normalizedList.add(item);
                continue;
            }

            Map<String,Object> source = (Map<String,Object>) item;
            Map<String,Object> normalizedItem = new Map<String,Object>();
            normalizedItem.put('imsi', source.containsKey('imsi') ? source.get('imsi') : source.get('imsiAdicion'));
            normalizedItem.put('min', source.containsKey('min') ? source.get('min') : source.get('minAdicion'));
            normalizedList.add(normalizedItem);
        }

        return normalizedList;
    }

    private static String mapTipoReporteAbdToId(String tipoReporteAbd) {
        if (String.isBlank(tipoReporteAbd)) {
            return tipoReporteAbd;
        }

        String normalizedValue = normalizeTipoReporteAbd(tipoReporteAbd);

        switch on normalizedValue {
            when '1', 'ROBO/HURTO', 'ROBO HURTO', 'ROBOHURTO', 'ROBO', 'HURTO' {
                return '1';
            }
            when '2', 'EXTRAVIO' {
                return '2';
            }
            when '3', 'BLOQUEO' {
                return '3';
            }
            when '4', 'INVALIDO' {
                return '4';
            }
            when '6', 'DUPLICADO' {
                return '6';
            }
            when '7', 'REINCIDENTE' {
                return '7';
            }
            when '8', 'ADMINISTRATIVO' {
                return '8';
            }
            when '9', 'DIJIN' {
                return '9';
            }
            when else {
                return tipoReporteAbd;
            }
        }
    }

    private static String normalizeTipoReporteAbd(String value) {
        String normalized = value.trim().toUpperCase();
        normalized = normalized.replace('Á', 'A');
        normalized = normalized.replace('É', 'E');
        normalized = normalized.replace('Í', 'I');
        normalized = normalized.replace('Ó', 'O');
        normalized = normalized.replace('Ú', 'U');
        normalized = normalized.replace('Ü', 'U');

        while (normalized.contains('  ')) {
            normalized = normalized.replace('  ', ' ');
        }

        return normalized;
    }

}