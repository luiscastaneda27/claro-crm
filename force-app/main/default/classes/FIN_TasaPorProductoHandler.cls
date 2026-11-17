/**
 * @description Handler de negocio para gestionar vigencias y validaciones
 *              del objeto FIN_TasaPorProducto__c.
 *  <Date>            <Author>             <Description>
    28-NOV-25         Eduardo Wentancur    Ajuste de PMD
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
public with sharing class FIN_TasaPorProductoHandler {

    /**
     * Flag estático para evitar ejecuciones recursivas del handler.
     */
    public static Boolean enEjecucion = false;
    
    /**
     * @description Lógica after insert de FIN_TasaPorProducto__c.
     *              Ajusta vigencias y elimina duplicados para los registros nuevos.
     * @param nuevosRegistros Lista de registros provenientes de Trigger.new.
     */
    public static void handleInsert(List<FIN_TasaPorProducto__c> nuevosRegistros) {
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
     * @description Lógica before insert para FIN_TasaPorProducto__c.
     *              Ajusta zona horaria en cargas masivas y recorta solapamientos
     *              dentro del mismo lote.
     * @param nuevosRegistros Lista de registros provenientes de Trigger.new.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
    public static void handleBeforeInsert(List<FIN_TasaPorProducto__c> nuevosRegistros) {
        // Ajustar zona horaria si es carga masiva
        for (FIN_TasaPorProducto__c record : nuevosRegistros) {
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
            FIN_TasaPorProducto__c registroPrincipal = nuevosRegistros[i];

            if (registroPrincipal.FIN_Material__c == null ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevosRegistros.size(); j++) {
                if (i == j) { 
                    continue;
                }

                FIN_TasaPorProducto__c registroComparado = nuevosRegistros[j];

                if (registroComparado.FIN_Material__c == null ||
                    registroComparado.FIN_Desde__c == null ||
                    registroComparado.FIN_Hasta__c == null) {
                    continue;
                }

                if (registroPrincipal.FIN_Material__c == registroComparado.FIN_Material__c &&
                    registroComparado.FIN_Desde__c > registroPrincipal.FIN_Desde__c &&
                    registroComparado.FIN_Desde__c < registroPrincipal.FIN_Hasta__c) {

                    // Recortar la fecha fin del registro principal
                    registroPrincipal.FIN_Hasta__c = registroComparado.FIN_Desde__c;
                }
            }
        }
    }
    
    /**
     * @description Ajusta la fecha FIN_Hasta__c de registros existentes
     *              cuando se insertan nuevas vigencias que se solapan.
     * @param nuevosRegistros Lista de registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    private static void ajustarFechasHasta(List<FIN_TasaPorProducto__c> nuevosRegistros) {
        if (nuevosRegistros.isEmpty()) {
            return;
        }    

        // PMD.ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorProducto__c.isAccessible()) {
            return;
        }

        Set<String> materiales = new Set<String>();
        for (FIN_TasaPorProducto__c reg : nuevosRegistros) {
            if (reg.FIN_Material__c != null) {
                materiales.add(reg.FIN_Material__c);
            }
        }

        if (materiales.isEmpty()) {
            return;
        }

        // Consultar existentes con mismos materiales
        List<FIN_TasaPorProducto__c> existentes = [
            SELECT Id, FIN_Material__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorProducto__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null
            AND FIN_Material__c IN :materiales
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];

        List<FIN_TasaPorProducto__c> ajustes = new List<FIN_TasaPorProducto__c>();

        for (FIN_TasaPorProducto__c nuevo : nuevosRegistros) {
            if (nuevo.FIN_Material__c == null || nuevo.FIN_Desde__c == null) {
                continue;
            }

            for (FIN_TasaPorProducto__c existente : existentes) {
                if (existente.FIN_Material__c != nuevo.FIN_Material__c) {
                    continue;
                }

                Boolean solapa =
                    nuevo.FIN_Desde__c > existente.FIN_Desde__c &&
                    nuevo.FIN_Desde__c <= existente.FIN_Hasta__c;

                if (solapa) {
                    existente.FIN_Hasta__c = nuevo.FIN_Desde__c;
                    ajustes.add(existente);
                }
            }
        }

        if (!ajustes.isEmpty()) {
            // PMD.ApexCRUDViolation - validar permiso de UPDATE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorProducto__c.isUpdateable()) {
                return;
            }

            try {
                update ajustes;
            } catch (DmlException e) {
                System.debug('Error al ajustar fechas de registros existentes: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Elimina registros futuros duplicados (mismo material y misma vigencia).
     * @param nuevosRegistros Lista de registros nuevos del trigger.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    private static void eliminarDuplicados(List<FIN_TasaPorProducto__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        // Identificar materiales y fechas de los nuevos registros futuros
        Map<String, FIN_TasaPorProducto__c> nuevosMap = new Map<String, FIN_TasaPorProducto__c>();
        Set<String> materialesUnicos = new Set<String>();
        
        for (FIN_TasaPorProducto__c nuevo : nuevosRegistros) {
            if (nuevo.FIN_Material__c != null && 
                nuevo.FIN_Desde__c != null &&
                nuevo.FIN_Hasta__c != null &&
                nuevo.FIN_Desde__c > ahora) {
                
                // Clave única: Material + Fechas formateadas
                String clave = nuevo.FIN_Material__c + '-' + 
                               nuevo.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                               nuevo.FIN_Hasta__c.format('yyyy-MM-dd');
                
                nuevosMap.put(clave, nuevo);
                materialesUnicos.add(nuevo.FIN_Material__c);
            }
        }
        
        if (nuevosMap.isEmpty()) {
            return;
        }

        // PMD.ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorProducto__c.isAccessible()) {
            return;
        }
        
        // Buscar registros existentes FUTUROS con misma combinación de material y fechas
        List<FIN_TasaPorProducto__c> existentes = [
            SELECT Id, FIN_Material__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_TasaPorProducto__c
            WHERE FIN_Material__c IN :materialesUnicos
            AND FIN_Desde__c > :ahora
            AND FIN_Hasta__c > :ahora
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];
        
        List<FIN_TasaPorProducto__c> paraEliminar = new List<FIN_TasaPorProducto__c>();
        
        for (FIN_TasaPorProducto__c existente : existentes) {
            String claveExistente = existente.FIN_Material__c + '-' + 
                                  existente.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                                  existente.FIN_Hasta__c.format('yyyy-MM-dd');
            
            if (nuevosMap.containsKey(claveExistente)) {
                paraEliminar.add(existente);
            }
        }
        
        if (!paraEliminar.isEmpty()) {
            // PMD.ApexCRUDViolation - validar permiso de DELETE antes del DML
            if (!Schema.sObjectType.FIN_TasaPorProducto__c.isDeletable()) {
                return;
            }

            try {
                delete paraEliminar;
            } catch (DmlException e) {
                for (FIN_TasaPorProducto__c reg : nuevosRegistros) {
                    reg.addError('Error al eliminar registros duplicados.');
                    break;
                }
            }
        }
    }

    /**
     * @description Ejecuta las validaciones de negocio para FIN_TasaPorProducto__c
     *              en contexto de trigger before insert / update.
     * @param triggerNew Registros del trigger (Trigger.new).
     */
    @SuppressWarnings('PMD.NcssMethodCount, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts')
    public static void validacionesTasaPorProducto(List<FIN_TasaPorProducto__c> triggerNew){
        Set<String> claves = new Set<String>();
        DateTime ahora = DateTime.now();
    
        // PMD.ApexCRUDViolation - validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_TasaPorProducto__c.isAccessible()) {
            for (FIN_TasaPorProducto__c reg : triggerNew) {
                reg.addError('No tiene permisos para leer FIN_TasaPorProducto__c.');
            }
            return;
        }

        // Consulta para detectar duplicados ya existentes
        List<FIN_TasaPorProducto__c> existentes = [
            SELECT Id, FIN_Desde__c, FIN_Hasta__c, FIN_Material__c, 
                   FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_Tasa_Interes__c
            FROM FIN_TasaPorProducto__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null WITH SECURITY_ENFORCED
        ];

        // Para PMD.EagerlyLoadedDescribeSObjectResult: usamos getDescribe con options
        Schema.DescribeSObjectResult tasaDescribe =
            FIN_TasaPorProducto__c.SObjectType.getDescribe(SObjectDescribeOptions.FULL);
        Map<String, Schema.SObjectField> camposMapa = tasaDescribe.fields.getMap();
    
        for (FIN_TasaPorProducto__c reg : triggerNew) {
        
            // Validación de fechas requeridas y consistentes
            if (reg.FIN_Desde__c == null || reg.FIN_Hasta__c == null) {
                reg.addError('Los campos Desde y Hasta son requeridos.');
            } else {
                if (reg.FIN_Desde__c < ahora && reg.CreatedDate == null) {
                    reg.FIN_Desde__c.addError('Desde < hoy.');
                }
                if (reg.FIN_Hasta__c < ahora) {
                    reg.FIN_Hasta__c.addError('Hasta < hoy.');
                }
                if (reg.FIN_Hasta__c < reg.FIN_Desde__c) {
                    reg.FIN_Hasta__c.addError('Hasta < Desde.');
                }
                Long diffMins = (reg.FIN_Hasta__c.getTime() - reg.FIN_Desde__c.getTime()) / (1000 * 60);
                if (diffMins < 15) {
                    reg.FIN_Hasta__c.addError('Hasta < Desde.');
                }
            }
            
            // Regla 4 - Material debe ser entero sin decimales (solo números enteros sin punto)
            if (reg.FIN_Material__c != null) {
                if (!Pattern.matches('^\\d+$', reg.FIN_Material__c)) {
                    reg.FIN_Material__c.addError('Material debe ser un número entero sin decimales ni símbolos.');
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
                if (Integer.valueOf(reg.FIN_Plazo_Minimo__c) > Integer.valueOf(reg.FIN_Plazo_Maximo__c)) {
                    reg.FIN_Plazo_Minimo__c.addError('Plazo máximo < plazo mínimo.');
                }
            }    
    
            // Validar tasa de interés
            if (String.isBlank(reg.FIN_Tasa_Interes__c)) {
                reg.FIN_Tasa_Interes__c.addError('Tasa de interés requerida.');
            } else {
                try {
                    String tasa = reg.FIN_Tasa_Interes__c.trim();
                    if (!Pattern.matches('^\\d{1,2}(,\\d{1,2})?$', tasa)) {
                        reg.FIN_Tasa_Interes__c.addError('Formato inválido. Use coma decimal (ej: 5,00).');
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
                    reg.FIN_Tasa_Interes__c.addError('Error en tasa de interés.');
                }
            }
    
            // Componer clave sin incluir todos los campos
            String clave = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Material__c
            }, '-');
    
            if (claves.contains(clave)) {
                reg.addError('Registro duplicado en la carga: mismo material y periodo de vigencia.');
            } else {
                claves.add(clave);
            }
            
            // Componer clave todos los campos
            String claveTotal = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Material__c,
                reg.FIN_Plazo_Minimo__c,
                reg.FIN_Plazo_Maximo__c,
                reg.FIN_Tasa_Interes__c      
            }, '-');
    
            // Validar duplicados ya existentes
            for (FIN_TasaPorProducto__c existente : existentes) {
                String claveExistente = String.join(new List<String>{
                    String.valueOf(existente.FIN_Desde__c),
                    String.valueOf(existente.FIN_Hasta__c),
                    existente.FIN_Material__c,
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