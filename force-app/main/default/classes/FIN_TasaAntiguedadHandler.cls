/**
 * @description Handler de negocio para gestionar vigencias, duplicados
 *              y validaciones del objeto FIN_TasaPorAntiguedadCliente__c.
 *  <Date>            <Author>             <Description>
    28-NOV-25         Eduardo Wentancur    Ajuste de PMD
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts')
public with sharing class FIN_TasaAntiguedadHandler {

    /**
     * @description Flag estático para evitar ejecuciones recursivas del handler.
     */
    public static Boolean enEjecucion = false;
    
    /**
     * @description Lógica after insert: ajusta vigencias y elimina duplicados.
     * @param nuevosRegistros Registros provenientes de Trigger.new.
     */
    public static void handleInsert(List<FIN_TasaPorAntiguedadCliente__c> nuevosRegistros) {
        if (enEjecucion) {
            return;
        }
        enEjecucion = true;
        
        try {
            ajustarFechasHasta(nuevosRegistros);
            eliminarDuplicados(nuevosRegistros);
        } finally {
            enEjecucion = false;
        }
    }

    /**
     * @description Lógica before insert: ajusta fechas en carga masiva
     *              y recorta solapamientos dentro del mismo lote.
     * @param nuevosRegistros Registros provenientes de Trigger.new.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
    public static void handleBeforeInsert(List<FIN_TasaPorAntiguedadCliente__c> nuevosRegistros) {
        // Ajuste de zona horaria para carga masiva
        for (FIN_TasaPorAntiguedadCliente__c record : nuevosRegistros) {
            if (record.FIN_Masivo__c) {
                if (record.FIN_Desde__c != null) {
                    record.FIN_Desde__c = record.FIN_Desde__c.addHours(5);
                }
                if (record.FIN_Hasta__c != null) {
                    record.FIN_Hasta__c = record.FIN_Hasta__c.addHours(5);
                }
            }
        }

        // Recorte entre nuevos registros para evitar solapamientos
        for (Integer i = 0; i < nuevosRegistros.size(); i++) {
            FIN_TasaPorAntiguedadCliente__c registroPrincipal = nuevosRegistros[i];

            if (!camposClaveLlenos(registroPrincipal) ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevosRegistros.size(); j++) {
                if (i == j) {
                    continue;
                }

                FIN_TasaPorAntiguedadCliente__c registroComparado = nuevosRegistros[j];

                if (!camposClaveLlenos(registroComparado) ||
                    registroComparado.FIN_Desde__c == null ||
                    registroComparado.FIN_Hasta__c == null) {
                    continue;
                }

                if (clave(registroPrincipal) == clave(registroComparado) &&
                    registroComparado.FIN_Desde__c > registroPrincipal.FIN_Desde__c &&
                    registroComparado.FIN_Desde__c < registroPrincipal.FIN_Hasta__c) {
                    
                    registroPrincipal.FIN_Hasta__c = registroComparado.FIN_Desde__c;
                }
            }
        }
    }

        /**
     * @description Ajusta FIN_Hasta__c de registros existentes cuando
     *              se insertan nuevas vigencias que se solapan.
     * @param nuevosRegistros Registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.NcssMethodCount')
    private static void ajustarFechasHasta(List<FIN_TasaPorAntiguedadCliente__c> nuevosRegistros) {
        if (nuevosRegistros.isEmpty()) {
            return;
        }

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorAntiguedadCliente__c.isAccessible()) {
            return;
        }

        Set<String> claves = new Set<String>();
        for (FIN_TasaPorAntiguedadCliente__c reg : nuevosRegistros) {
            if (camposClaveLlenos(reg)) {
                claves.add(clave(reg));
            }
        }

        List<FIN_TasaPorAntiguedadCliente__c> existentes = [
            SELECT Id, FIN_Calificacion_Cliente__c, FIN_Antiguedad_maxima_meses__c,
                   FIN_Antiguedad_minima_meses__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorAntiguedadCliente__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];

        List<FIN_TasaPorAntiguedadCliente__c> ajustes = new List<FIN_TasaPorAntiguedadCliente__c>();

        for (FIN_TasaPorAntiguedadCliente__c nuevo : nuevosRegistros) {
            if (!camposClaveLlenos(nuevo)) {
                continue;
            }

            for (FIN_TasaPorAntiguedadCliente__c existente : existentes) {
                if (!camposClaveLlenos(existente)) {
                    continue;
                }

                Boolean mismaClave = (clave(nuevo) == clave(existente));
                Boolean solapa =
                    nuevo.FIN_Desde__c > existente.FIN_Desde__c &&
                    nuevo.FIN_Desde__c <= existente.FIN_Hasta__c;

                if (mismaClave && solapa) {
                    existente.FIN_Hasta__c = nuevo.FIN_Desde__c;
                    ajustes.add(existente);
                }
            }
        }

        if (!ajustes.isEmpty()) {
            // Seguridad: validar permiso de UPDATE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorAntiguedadCliente__c.isUpdateable()) {
                return;
            }

            try {
                update ajustes;
            } catch (DmlException e) {
                // Sin System.debug, se reporta un error genérico
                for (FIN_TasaPorAntiguedadCliente__c reg : nuevosRegistros) {
                    reg.addError('Error al ajustar fechas de registros existentes.');
                    break;
                }
            }
        }
    }

        /**
     * @description Elimina registros futuros duplicados (misma clave + mismas fechas).
     * @param nuevosRegistros Registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    private static void eliminarDuplicados(List<FIN_TasaPorAntiguedadCliente__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        Map<String, FIN_TasaPorAntiguedadCliente__c> nuevosMap = 
            new Map<String, FIN_TasaPorAntiguedadCliente__c>();
        Set<String> clavesUnicas = new Set<String>();
        
        for (FIN_TasaPorAntiguedadCliente__c nuevo : nuevosRegistros) {
            if (camposClaveLlenos(nuevo) && 
                nuevo.FIN_Desde__c != null &&
                nuevo.FIN_Hasta__c != null &&
                nuevo.FIN_Desde__c > ahora) {
                
                String claveCompuesta = clave(nuevo) + '|' + 
                                        nuevo.FIN_Desde__c.format('yyyy-MM-dd') + '|' + 
                                        nuevo.FIN_Hasta__c.format('yyyy-MM-dd');
                
                nuevosMap.put(claveCompuesta, nuevo);
                clavesUnicas.add(clave(nuevo));
            }
        }
        
        if (nuevosMap.isEmpty()) {
            return;
        }
        
        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorAntiguedadCliente__c.isAccessible()) {
            return;
        }
        
        List<FIN_TasaPorAntiguedadCliente__c> existentes = [
            SELECT Id, FIN_Calificacion_Cliente__c, FIN_Antiguedad_maxima_meses__c,
                   FIN_Antiguedad_minima_meses__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorAntiguedadCliente__c
            WHERE FIN_Desde__c > :ahora
            AND FIN_Hasta__c > :ahora
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];
        
        List<FIN_TasaPorAntiguedadCliente__c> paraEliminar = 
            new List<FIN_TasaPorAntiguedadCliente__c>();
        
        for (FIN_TasaPorAntiguedadCliente__c existente : existentes) {
            String claveExistente = clave(existente) + '|' + 
                                    existente.FIN_Desde__c.format('yyyy-MM-dd') + '|' + 
                                    existente.FIN_Hasta__c.format('yyyy-MM-dd');
            
            if (nuevosMap.containsKey(claveExistente)) {
                paraEliminar.add(existente);
            }
        }
        
        if (!paraEliminar.isEmpty()) {
            // Seguridad: validar permiso de DELETE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorAntiguedadCliente__c.isDeletable()) {
                return;
            }

            try {
                delete paraEliminar;
            } catch (DmlException e) {
                for (FIN_TasaPorAntiguedadCliente__c reg : nuevosRegistros) {
                    reg.addError('Error al eliminar registros duplicados.');
                    break;
                }
            }
        }
    }

    /**
     * @description Indica si los campos clave (calificación + antigüedad min/max)
     *              están informados en el registro.
     * @param r Registro a validar.
     * @return true si todos los campos clave están completos.
     */
    private static Boolean camposClaveLlenos(FIN_TasaPorAntiguedadCliente__c r) {
        return r.FIN_Calificacion_Cliente__c != null &&
               r.FIN_Antiguedad_maxima_meses__c != null &&
               r.FIN_Antiguedad_minima_meses__c != null;
    }

    /**
     * @description Obtiene la clave compuesta Calificación|AntigüedadMax|AntigüedadMin.
     * @param r Registro de tasa por antigüedad.
     * @return Cadena con la clave compuesta.
     */
    private static String clave(FIN_TasaPorAntiguedadCliente__c r) {
        return r.FIN_Calificacion_Cliente__c + '|' +
               r.FIN_Antiguedad_maxima_meses__c + '|' +
               r.FIN_Antiguedad_minima_meses__c;
    }
    
        /**
     * @description Ejecuta las validaciones de negocio para FIN_TasaPorAntiguedadCliente__c
     *              en contexto de trigger before insert / update.
     * @param triggerNew Registros del trigger (Trigger.new).
     */
    @SuppressWarnings('PMD.NcssMethodCount,PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.AvoidDeeplyNestedIfStmts')
    public static void validacionesTasaAntiguedad(List<FIN_TasaPorAntiguedadCliente__c> triggerNew) {
        Set<String> claves = new Set<String>();
        DateTime ahora = DateTime.now();

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorAntiguedadCliente__c.isAccessible()) {
            for (FIN_TasaPorAntiguedadCliente__c regSinPermiso : triggerNew) {
                regSinPermiso.addError('No tiene permisos para leer FIN_TasaPorAntiguedadCliente__c.');
            }
            return;
        }

        // Cargar registros existentes para evitar duplicados (con filtro para PMD.AvoidNonRestrictiveQueries)
        List<FIN_TasaPorAntiguedadCliente__c> existentes = [
            SELECT Id, FIN_Calificacion_Cliente__c,
                   FIN_Antiguedad_maxima_meses__c, 
                   FIN_Antiguedad_minima_meses__c,
                   FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c,
                   FIN_Tasa_Interes__c, FIN_Desde__c, 
                   FIN_Hasta__c
            FROM FIN_TasaPorAntiguedadCliente__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null WITH SECURITY_ENFORCED
        ];

        // Describe cacheado para evitar EagerlyLoadedDescribeSObjectResult
        Schema.DescribeSObjectResult describeResult =
            FIN_TasaPorAntiguedadCliente__c.SObjectType.getDescribe(SObjectDescribeOptions.FULL);
        Map<String, Schema.SObjectField> camposMapa = describeResult.fields.getMap();

        // Validación de Calificación Cliente como picklist válido
        Set<String> calificacionesPermitidas = new Set<String>();
        Schema.DescribeFieldResult calificDesc = 
            FIN_TasaPorAntiguedadCliente__c.FIN_Calificacion_Cliente__c.getDescribe();
        if (calificDesc.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry val : calificDesc.getPicklistValues()) {
                if (val.isActive()) {
                    calificacionesPermitidas.add(val.getValue());
                }
            }
        }

        for (FIN_TasaPorAntiguedadCliente__c reg : triggerNew) {

            // Validar Calificación Cliente como picklist válido
            if (reg.FIN_Calificacion_Cliente__c != null &&
                !calificacionesPermitidas.contains(reg.FIN_Calificacion_Cliente__c)) {
                reg.FIN_Calificacion_Cliente__c.addError(
                    'Calificación inválida. Valores permitidos: ' +
                    String.join(new List<String>(calificacionesPermitidas), ', ')
                );
            }

            // Validar que antigüedades contengan solo números y estén en el rango 0-9999
            if (!Pattern.matches('^\\d{1,4}$', reg.FIN_Antiguedad_minima_meses__c)) {
                reg.FIN_Antiguedad_minima_meses__c.addError(
                    'La antigüedad mínima debe ser un número entre 0 y 9999.'
                );
            }
            if (!Pattern.matches('^\\d{1,4}$', reg.FIN_Antiguedad_maxima_meses__c)) {
                reg.FIN_Antiguedad_maxima_meses__c.addError(
                    'La antigüedad máxima debe ser un número entre 0 y 9999.'
                );
            }

            // Validar que mínima no sea mayor que máxima
            try {
                Integer minVal = Integer.valueOf(reg.FIN_Antiguedad_minima_meses__c);
                Integer maxVal = Integer.valueOf(reg.FIN_Antiguedad_maxima_meses__c);
                if (minVal > maxVal) {
                    reg.FIN_Antiguedad_minima_meses__c.addError(
                        'La antigüedad mínima no puede ser mayor que la máxima.'
                    );
                }
            } catch (Exception eAnt) {
                reg.addError('Antigüedad inválida.');
            }

            // Validar formato de tasa de interés
            if (String.isBlank(reg.FIN_Tasa_Interes__c)) {
                reg.FIN_Tasa_Interes__c.addError('Tasa requerida.');
            } else {
                try {
                    String tasa = reg.FIN_Tasa_Interes__c.trim();
                    if (!Pattern.matches('^\\d{1,2}(,\\d{1,2})?$', tasa)) {
                        reg.FIN_Tasa_Interes__c.addError(
                            'Formato inválido. Use coma decimal (ej: 5,23 o 12,50)'
                        );
                    } else {
                        if (!tasa.contains(',')) {
                            tasa += ',00';
                        } else {
                            String[] partes = tasa.split(',');
                            if (partes[1].length() == 1) {
                                tasa += '0';
                            }
                        }
                        reg.FIN_Tasa_Interes__c = tasa;
                    }
                } catch (Exception eTasa) {
                    reg.FIN_Tasa_Interes__c.addError('Error en tasa de interés.');
                }
            }

            // Validar fechas requeridas y consistencia
            if (reg.FIN_Desde__c == null || reg.FIN_Hasta__c == null) {
                reg.addError('Ambas fechas (Desde y Hasta) son requeridas.');
            } else {
                if (reg.FIN_Desde__c < ahora && reg.CreatedDate == null) {
                    reg.FIN_Desde__c.addError('Desde < hoy');
                }
                if (reg.FIN_Hasta__c < ahora) {
                    reg.FIN_Hasta__c.addError('Hasta < hoy');
                }
                if (reg.FIN_Hasta__c <= reg.FIN_Desde__c) {
                    reg.FIN_Hasta__c.addError('Hasta < desde.');
                }

                Long minutos = 
                    (reg.FIN_Hasta__c.getTime() - reg.FIN_Desde__c.getTime()) / (1000 * 60);
                if (minutos < 15) {
                    reg.FIN_Hasta__c.addError('Hasta < desde.');
                }
            }
        
            // Validar que los valores de los picklist estén dentro del rango permitido
            List<String> camposPicklist = 
                new List<String>{'FIN_Plazo_Minimo__c', 'FIN_Plazo_Maximo__c'};
            for (String campo : camposPicklist) {
                try {
                    Schema.SObjectField fieldRef = camposMapa.get(campo);
                    Schema.DescribeFieldResult fieldDescribe = fieldRef.getDescribe();
                    String valor = (String)reg.get(campo);
                    if (valor != null) {
                        Integer val = Integer.valueOf(valor);
                        Integer min = 9999;
                        Integer max = -1;
                        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            if (entry.isActive()) {
                                Integer num = Integer.valueOf(entry.getValue());
                                if (num < min) {
                                    min = num;
                                }
                                if (num > max) {
                                    max = num;
                                }
                            }
                        }
                        if (val < min || val > max) {
                            reg.put(campo, null);
                            reg.addError(
                                'Valor de ' + campo.replace('__c','') +
                                ' fuera de rango (' + min + ' a ' + max + ').'
                            );
                        }
                    }
                } catch (Exception eCampo) {
                    reg.addError(
                        'Error al validar ' + campo.replace('__c','') + 
                        ': ' + eCampo.getMessage()
                    );
                }
            }
        
            // Regla 5.1 - Plazo min no puede ser mayor al max
            if (reg.FIN_Plazo_Minimo__c != null && reg.FIN_Plazo_Maximo__c != null) {
                if (Integer.valueOf(reg.FIN_Plazo_Minimo__c) >
                    Integer.valueOf(reg.FIN_Plazo_Maximo__c)) {
                    reg.FIN_Plazo_Minimo__c.addError('Plazo máximo < plazo mínimo.');
                }
            }    

            // Componer clave sin incluir todos los campos
            String claveCarga = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Calificacion_Cliente__c,
                reg.FIN_Antiguedad_maxima_meses__c,
                reg.FIN_Antiguedad_minima_meses__c
            }, '-');

            if (claves.contains(claveCarga)) {
                reg.addError(
                    'Registro duplicado en la carga: misma calificación, antigüedad cliente y periodo de vigencia.'
                );
            } else {
                claves.add(claveCarga);
            }
        
            // Componer clave con todos los campos
            String claveTotal = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Calificacion_Cliente__c,
                reg.FIN_Antiguedad_maxima_meses__c,
                reg.FIN_Antiguedad_minima_meses__c,
                reg.FIN_Plazo_Minimo__c,
                reg.FIN_Plazo_Maximo__c,
                reg.FIN_Tasa_Interes__c  
            }, '-');

            // Validar duplicados ya existentes
            for (FIN_TasaPorAntiguedadCliente__c existente : existentes) {
                String claveExistente = String.join(new List<String>{
                    String.valueOf(existente.FIN_Desde__c),
                    String.valueOf(existente.FIN_Hasta__c),
                    existente.FIN_Calificacion_Cliente__c,
                    existente.FIN_Antiguedad_maxima_meses__c,
                    existente.FIN_Antiguedad_minima_meses__c,
                    existente.FIN_Plazo_Minimo__c,
                    existente.FIN_Plazo_Maximo__c,
                    existente.FIN_Tasa_Interes__c  
                }, '-');

                if (claveTotal == claveExistente) {
                    reg.addError('Ya existe un registro en salesforce.');
                    break;
                }
            }
        }
    }
}