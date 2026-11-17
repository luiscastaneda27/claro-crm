/**
 * @description Handler de negocio para gestionar vigencias, duplicados
 *              y validaciones del objeto FIN_TasaPorDocumentoCliente__c.
 *  <Date>            <Author>             <Description>
    28-NOV-25         Eduardo Wentancur    Ajuste de PMD
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
public with sharing class FIN_TasaDocumentoHandler 
{
    /**
     * @description Flag estático para evitar ejecuciones recursivas del handler.
     */
    public static Boolean enEjecucion = false;
    
    /**
     * @description Lógica before insert: ajusta fechas en cargas masivas.
     * @param nuevosRegistros Lista de registros provenientes de Trigger.new.
     */
    public static void handleBeforeInsert(List<FIN_TasaPorDocumentoCliente__c> nuevosRegistros) {
        ajustarFechasMasivo(nuevosRegistros);
    }
    
    /**
     * @description Lógica after insert: ajusta vigencias y elimina duplicados.
     * @param nuevosRegistros Lista de registros provenientes de Trigger.new.
     */
    public static void handleInsert(List<FIN_TasaPorDocumentoCliente__c> nuevosRegistros) {
        if (enEjecucion) {
            return;
        }
        enEjecucion = true;
        
        try {
            // Ejecutar lógica de ajuste de fechas
            ajustarFechasHasta(nuevosRegistros);
            
            // Ejecutar lógica de eliminación de duplicados
            eliminarDuplicados(nuevosRegistros);
        } finally {
            enEjecucion = false;
        }
    }
    
    /**
     * @description Ajusta fechas (zona horaria) en carga masiva y recorta
     *              solapamientos dentro del mismo lote.
     * @param nuevosRegistros Lista de registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
    private static void ajustarFechasMasivo(List<FIN_TasaPorDocumentoCliente__c> nuevosRegistros) {
        for (FIN_TasaPorDocumentoCliente__c record : nuevosRegistros) {
            if (record.FIN_Masivo__c) {
                if (record.FIN_Desde__c != null) {
                    record.FIN_Desde__c = record.FIN_Desde__c.addHours(5);
                }
                if (record.FIN_Hasta__c != null) {
                    record.FIN_Hasta__c = record.FIN_Hasta__c.addHours(5);
                }
            }
        }

        // Lógica de recorte entre nuevos registros para evitar solapamientos
        for (Integer i = 0; i < nuevosRegistros.size(); i++) {
            FIN_TasaPorDocumentoCliente__c registroPrincipal = nuevosRegistros[i];

            if (!camposClaveLlenos(registroPrincipal) ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevosRegistros.size(); j++) {
                if (i == j) {
                    continue;
                }

                FIN_TasaPorDocumentoCliente__c registroComparado = nuevosRegistros[j];

                if (!camposClaveLlenos(registroComparado) ||
                    registroComparado.FIN_Desde__c == null ||
                    registroComparado.FIN_Hasta__c == null) {
                    continue;
                }

                Boolean mismaClave = 
                    registroPrincipal.FIN_Documento__c == registroComparado.FIN_Documento__c &&
                    registroPrincipal.FIN_Tipo_documento__c == registroComparado.FIN_Tipo_documento__c;

                Boolean solapa =
                    registroComparado.FIN_Desde__c > registroPrincipal.FIN_Desde__c &&
                    registroComparado.FIN_Desde__c < registroPrincipal.FIN_Hasta__c;

                if (mismaClave && solapa) {
                    // Recortar la fecha fin del registro principal
                    registroPrincipal.FIN_Hasta__c = registroComparado.FIN_Desde__c;
                }
            }
        }
    }
    
    /**
     * @description Ajusta FIN_Hasta__c de registros existentes cuando
     *              se insertan nuevas vigencias que se solapan.
     * @param nuevosRegistros Lista de registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.NcssMethodCount')
    private static void ajustarFechasHasta(List<FIN_TasaPorDocumentoCliente__c> nuevosRegistros) {
        if (nuevosRegistros.isEmpty()) {
            return;
        }

        // ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorDocumentoCliente__c.isAccessible()) {
            return;
        }

        Set<String> claves = new Set<String>();
        for (FIN_TasaPorDocumentoCliente__c r : nuevosRegistros) {
            if (camposClaveLlenos(r)) {
                claves.add(obtenerClave(r));
            }
        }

        List<FIN_TasaPorDocumentoCliente__c> existentes = [
            SELECT Id, FIN_Documento__c, FIN_Tipo_documento__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorDocumentoCliente__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];

        List<FIN_TasaPorDocumentoCliente__c> ajustes = new List<FIN_TasaPorDocumentoCliente__c>();

        for (FIN_TasaPorDocumentoCliente__c nuevo : nuevosRegistros) {
            if (!camposClaveLlenos(nuevo)) {
                continue;
            }

            for (FIN_TasaPorDocumentoCliente__c existente : existentes) {
                if (!camposClaveLlenos(existente)) {
                    continue;
                }

                Boolean mismaClave =
                    nuevo.FIN_Documento__c == existente.FIN_Documento__c &&
                    nuevo.FIN_Tipo_documento__c == existente.FIN_Tipo_documento__c;

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
            // ApexCRUDViolation - validar permiso de UPDATE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorDocumentoCliente__c.isUpdateable()) {
                return;
            }

            try {
                update ajustes;
            } catch (DmlException e) {
                for (FIN_TasaPorDocumentoCliente__c reg : nuevosRegistros) {
                    reg.addError('Error al ajustar fechas de registros existentes.');
                    break;
                }
            }
        }
    }
    
    /**
     * @description Elimina registros futuros duplicados (mismo documento,
     *              tipo y periodo de vigencia).
     * @param nuevosRegistros Lista de registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.NcssMethodCount')
    private static void eliminarDuplicados(List<FIN_TasaPorDocumentoCliente__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        // Identificar claves únicas de los nuevos registros futuros
        Map<String, FIN_TasaPorDocumentoCliente__c> nuevosMap = new Map<String, FIN_TasaPorDocumentoCliente__c>();
        Set<String> clavesUnicas = new Set<String>();
        
        for (FIN_TasaPorDocumentoCliente__c nuevo : nuevosRegistros) {
            if (camposClaveLlenos(nuevo) && 
                nuevo.FIN_Desde__c != null &&
                nuevo.FIN_Hasta__c != null &&
                nuevo.FIN_Desde__c > ahora) {
                
                // Clave única: TipoDoc + Documento + Fechas formateadas
                String clave = nuevo.FIN_Tipo_documento__c + '-' + 
                               nuevo.FIN_Documento__c + '-' + 
                               nuevo.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                               nuevo.FIN_Hasta__c.format('yyyy-MM-dd');
                
                nuevosMap.put(clave, nuevo);
                clavesUnicas.add(obtenerClave(nuevo));
            }
        }
        
        if (nuevosMap.isEmpty()) {
            return;
        }
        
        // ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorDocumentoCliente__c.isAccessible()) {
            return;
        }
        
        // Buscar registros existentes FUTUROS con misma combinación
        List<FIN_TasaPorDocumentoCliente__c> existentes = [
            SELECT Id, FIN_Tipo_documento__c, FIN_Documento__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorDocumentoCliente__c
            WHERE FIN_Desde__c > :ahora
            AND FIN_Hasta__c > :ahora
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];
        
        // Filtrar por claves únicas para optimizar
        List<FIN_TasaPorDocumentoCliente__c> existentesFiltrados = new List<FIN_TasaPorDocumentoCliente__c>();
        for (FIN_TasaPorDocumentoCliente__c existente : existentes) {
            if (clavesUnicas.contains(obtenerClave(existente))) {
                existentesFiltrados.add(existente);
            }
        }
        
        List<FIN_TasaPorDocumentoCliente__c> paraEliminar = new List<FIN_TasaPorDocumentoCliente__c>();
        
        for (FIN_TasaPorDocumentoCliente__c existente : existentesFiltrados) {
            String claveExistente = existente.FIN_Tipo_documento__c + '-' + 
                                    existente.FIN_Documento__c + '-' + 
                                    existente.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                                    existente.FIN_Hasta__c.format('yyyy-MM-dd');
            
            if (nuevosMap.containsKey(claveExistente)) {
                paraEliminar.add(existente);
            }
        }
        
        if (!paraEliminar.isEmpty()) {
            // ApexCRUDViolation - validar permiso de DELETE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorDocumentoCliente__c.isDeletable()) {
                return;
            }

            try {
                delete paraEliminar;
            } catch (DmlException e) {
                for (FIN_TasaPorDocumentoCliente__c reg : nuevosRegistros) {
                    reg.addError('Error al eliminar registros duplicados.');
                    break;
                }
            }
        }
    }
    
    /**
     * @description Indica si los campos clave (Documento + Tipo de documento)
     *              están informados en el registro.
     * @param r Registro a validar.
     * @return true si ambos campos clave están cargados.
     */
    private static Boolean camposClaveLlenos(FIN_TasaPorDocumentoCliente__c r) {
        return r.FIN_Documento__c != null && r.FIN_Tipo_documento__c != null;
    }

    /**
     * @description Obtiene la clave compuesta Documento|TipoDocumento
     *              para comparar registros.
     * @param r Registro de tasa por documento.
     * @return Cadena con la clave compuesta.
     */
    private static String obtenerClave(FIN_TasaPorDocumentoCliente__c r) {
        return r.FIN_Documento__c + '|' + r.FIN_Tipo_documento__c;
    }

        /**
     * @description Ejecuta las validaciones de negocio para FIN_TasaPorDocumentoCliente__c
     *              en contexto de trigger before insert / update.
     * @param triggerNew Lista de registros del trigger (Trigger.new).
     */
    @SuppressWarnings('PMD.NcssMethodCount, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.AvoidDeeplyNestedIfStmts')
    public static void validacionesTasaPorDocumento(List<FIN_TasaPorDocumentoCliente__c> triggerNew)
    {
        Set<String> claves = new Set<String>();
        DateTime ahora = DateTime.now();

        // ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorDocumentoCliente__c.isAccessible()) {
            for (FIN_TasaPorDocumentoCliente__c reg : triggerNew) {
                reg.addError('No tiene permisos para leer FIN_TasaPorDocumentoCliente__c.');
            }
            return;
        }

        // Consulta para detectar duplicados ya existentes
        List<FIN_TasaPorDocumentoCliente__c> existentes = [
            SELECT Id, FIN_Desde__c, FIN_Hasta__c, FIN_Tipo_documento__c, FIN_Documento__c,
                FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorDocumentoCliente__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null WITH SECURITY_ENFORCED
        ];

        // Describe cacheado para evitar EagerlyLoadedDescribeSObjectResult
        Schema.DescribeSObjectResult describeResult =
            FIN_TasaPorDocumentoCliente__c.SObjectType.getDescribe(SObjectDescribeOptions.FULL);
        Map<String, Schema.SObjectField> camposMapa = describeResult.fields.getMap();

        // Validar picklist de tipo de documento
        Set<String> tiposPermitidos = new Set<String>();
        Schema.DescribeFieldResult tipoDesc = FIN_TasaPorDocumentoCliente__c.FIN_Tipo_documento__c.getDescribe();
        if (tipoDesc.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry val : tipoDesc.getPicklistValues()) {
                if (val.isActive()) {
                    tiposPermitidos.add(val.getValue());
                }
            }
        }

        for (FIN_TasaPorDocumentoCliente__c reg : triggerNew) {

            // Validación de tipo de documento válido
            if (reg.FIN_Tipo_documento__c != null && !tiposPermitidos.contains(reg.FIN_Tipo_documento__c)) {
                reg.FIN_Tipo_documento__c.addError('Tipo de documento inválido. Valores permitidos: ' +
                    String.join(new List<String>(tiposPermitidos), ', '));
            }

            // Validar tasa de interés
            if (String.isBlank(reg.FIN_Tasa_Interes__c)) {
                reg.FIN_Tasa_Interes__c.addError('Tasa de interés requerida.');
            } else {
                try {
                    String tasa = reg.FIN_Tasa_Interes__c.trim();
                    if (!Pattern.matches('^\\d{1,2}(,\\d{1,2})?$', tasa)) {
                        reg.FIN_Tasa_Interes__c.addError('Formato inválido. Use coma decimal, ej: 5,23 o 12,00.');
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
                } catch (Exception e) {
                    reg.FIN_Tasa_Interes__c.addError('Error procesando la tasa de interés.');
                }
            }

            // Validación de fechas
            if (reg.FIN_Desde__c == null || reg.FIN_Hasta__c == null) {
                reg.addError('Desde y Hasta son obligatorios.');
            } else {
                if (reg.FIN_Desde__c < ahora && reg.CreatedDate == null) {
                    reg.FIN_Desde__c.addError('Desde < hoy.');
                }
                if (reg.FIN_Hasta__c < ahora) {
                    reg.FIN_Hasta__c.addError('Hasta < hoy.');
                }
                if (reg.FIN_Hasta__c < reg.FIN_Desde__c) {
                    reg.FIN_Hasta__c.addError('Hasta < desde.');
                }

                Long diffMin = (reg.FIN_Hasta__c.getTime() - reg.FIN_Desde__c.getTime()) / (1000 * 60);
                if (diffMin < 15) {
                    reg.FIN_Hasta__c.addError('Hasta < desde.');
                }
            }
            
            // Validar que los valores de los picklist estén dentro del rango permitido
            List<String> camposPicklist = new List<String>{'FIN_Plazo_Minimo__c', 'FIN_Plazo_Maximo__c'};
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
                            reg.addError('Valor de ' + campo.replace('__c','') + ' fuera de rango (' + min + ' a ' + max + ').');
                        }
                    }
                } catch (Exception e) {
                    reg.addError('Error al validar ' + campo.replace('__c','') + ': ' + e.getMessage());
                }
            }
            
            // Regla 5.1 - Plazo min no puede ser mayor al max
            if (reg.FIN_Plazo_Minimo__c != null && reg.FIN_Plazo_Maximo__c != null) {
                if (Integer.valueof(reg.FIN_Plazo_Minimo__c) > Integer.valueof(reg.FIN_Plazo_Maximo__c)) {
                    reg.FIN_Plazo_Minimo__c.addError('Plazo máximo < plazo mínimo.');
                }
            } 
            
            // Componer clave sin incluir todos los campos
            String clave = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Documento__c,
                reg.FIN_Tipo_documento__c
            }, '-');

            if (claves.contains(clave)) {
                reg.addError('Registro duplicado en la carga: mismo tipo de Documento, documento y periodo de vigencia.');
            } else {
                claves.add(clave);
            }
            
            // Componer clave todos los campos
            String claveTotal = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Documento__c,
                reg.FIN_Tipo_documento__c,
                reg.FIN_Plazo_Minimo__c,
                reg.FIN_Plazo_Maximo__c,
                reg.FIN_Tasa_Interes__c      
            }, '-');

            // Validar duplicados ya existentes
            for (FIN_TasaPorDocumentoCliente__c existente : existentes) {
                String claveExistente = String.join(new List<String>{
                    String.valueOf(existente.FIN_Desde__c),
                    String.valueOf(existente.FIN_Hasta__c),
                    existente.FIN_Documento__c,
                    existente.FIN_Tipo_documento__c,
                    existente.FIN_Plazo_Minimo__c,
                    existente.FIN_Plazo_Maximo__c,
                    existente.FIN_Tasa_Interes__c
                }, '-');

                if (claveTotal == claveExistente) {
                    reg.addError('Este registro ya existe en Salesforce.');
                    break;
                }
            }   
        }
    }
}