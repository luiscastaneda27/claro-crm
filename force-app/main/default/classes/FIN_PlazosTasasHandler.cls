/**
 * @description
 * Handler central para la lógica de plazos y tasas:
 * - Ajuste de fechas para evitar solapamientos.
 * - Reemplazo/eliminación de registros futuros duplicados.
 * - Validaciones de negocio sobre FIN_Plazos_y_Tasas_info__c.
 *  <Date>            <Author>             <Description>
    28-NOV-25         Eduardo Wentancur    Ajuste de PMD
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.NcssMethodCount,PMD.MethodNamingConventions,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class FIN_PlazosTasasHandler {

    // Variable estática para controlar recursividad
    public static Boolean enEjecucion = false;
    
    /**
     * @description
     * Método principal para manejar inserciones AFTER INSERT del objeto FIN_Plazos_y_Tasas_info__c.
     * Ejecuta ajuste de fechas y luego reemplazo de tasas/plazos futuros duplicados.
     * @param nuevosRegistros lista de registros del trigger (Trigger.new).
     */
    public static void handleInsert(List<FIN_Plazos_y_Tasas_info__c> nuevosRegistros) {
        if (enEjecucion) {
            return;
        }
        enEjecucion = true;
        
        try {
            // Primero ejecutar lógica de actualización de fechas
            ajustarFechaFin(nuevosRegistros);
            
            // Luego ejecutar lógica de reemplazo de tasas/plazos
            reemplazarTasasPlazos(nuevosRegistros);
        } finally {
            enEjecucion = false;
        }
    }
    
    /**
     * @description
     * Ajusta FIN_Fecha_Fin__c de registros existentes para que no se solapen
     * con los nuevos registros insertados, para cada plazo.
     * @param nuevosRegistros lista de registros nuevos del trigger.
     */
    private static void ajustarFechaFin(List<FIN_Plazos_y_Tasas_info__c> nuevosRegistros) {
        Set<String> plazosRelacionados = new Set<String>();

        for (FIN_Plazos_y_Tasas_info__c nuevoRegistro : nuevosRegistros) {
            if (nuevoRegistro.FIN_Plazo__c != null) {
                plazosRelacionados.add(nuevoRegistro.FIN_Plazo__c);
            }
        }

        if (plazosRelacionados.isEmpty()) {
            return;
        }

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_Plazos_y_Tasas_info__c.isAccessible()) {
            return;
        }

        // Consultar registros existentes
        List<FIN_Plazos_y_Tasas_info__c> registrosExistentes = [
            SELECT Id, FIN_Plazo__c, FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c
            FROM FIN_Plazos_y_Tasas_info__c
            WHERE FIN_Plazo__c IN :plazosRelacionados
            AND FIN_Fecha_Inicio__c != NULL
            AND FIN_Fecha_Fin__c != NULL
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];

        List<FIN_Plazos_y_Tasas_info__c> registrosParaActualizar = new List<FIN_Plazos_y_Tasas_info__c>();

        // Ajustar registros existentes para no solaparse con los nuevos
        for (FIN_Plazos_y_Tasas_info__c nuevoRegistro : nuevosRegistros) {
            if (nuevoRegistro.FIN_Plazo__c == null || nuevoRegistro.FIN_Fecha_Inicio__c == null) {
                continue;
            }

            for (FIN_Plazos_y_Tasas_info__c registroExistente : registrosExistentes) {
                if (registroExistente.FIN_Plazo__c != nuevoRegistro.FIN_Plazo__c) {
                    continue;
                }

                if (nuevoRegistro.FIN_Fecha_Inicio__c > registroExistente.FIN_Fecha_Inicio__c &&
                    nuevoRegistro.FIN_Fecha_Inicio__c <= registroExistente.FIN_Fecha_Fin__c) {

                    registroExistente.FIN_Fecha_Fin__c = nuevoRegistro.FIN_Fecha_Inicio__c;
                    registrosParaActualizar.add(registroExistente);
                }
            }
        }

        if (!registrosParaActualizar.isEmpty()) {
            // Seguridad: validar permiso de UPDATE antes del DML
            if (!Schema.sObjectType.FIN_Plazos_y_Tasas_info__c.isUpdateable()) {
                return;
            }

            try {
            update registrosParaActualizar;
            } catch (DmlException e) {
             String mensajeError = e.getMessage();
            for (FIN_Plazos_y_Tasas_info__c reg : nuevosRegistros) {
                reg.addError('Error al actualizar registros existentes: ' + mensajeError);
            }
            }
        }
    }

    /**
     * @description
     * Elimina registros FUTUROS que tengan misma combinación de
     * plazo + rango de fechas que los registros nuevos futuros (reemplazo).
     * @param nuevosRegistros lista de registros nuevos del trigger.
     */
    private static void reemplazarTasasPlazos(List<FIN_Plazos_y_Tasas_info__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        // Identificar plazos y fechas de los nuevos registros futuros
        Map<String, FIN_Plazos_y_Tasas_info__c> nuevosMap = new Map<String, FIN_Plazos_y_Tasas_info__c>();
        Set<String> plazosUnicos = new Set<String>();
        
        for (FIN_Plazos_y_Tasas_info__c nuevo : nuevosRegistros) {
            if (nuevo.FIN_Plazo__c != null && 
                nuevo.FIN_Fecha_Inicio__c != null &&
                nuevo.FIN_Fecha_Fin__c != null &&
                nuevo.FIN_Fecha_Inicio__c > ahora) {
                
                // Clave única: Plazo + Fechas formateadas
                String clave = nuevo.FIN_Plazo__c + '-' + 
                               nuevo.FIN_Fecha_Inicio__c.format('yyyy-MM-dd') + '-' + 
                               nuevo.FIN_Fecha_Fin__c.format('yyyy-MM-dd');
                
                nuevosMap.put(clave, nuevo);
                plazosUnicos.add(nuevo.FIN_Plazo__c);
            }
        }
        
        if (nuevosMap.isEmpty()) {
            return;
        }

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_Plazos_y_Tasas_info__c.isAccessible()) {
            return;
        }
        
        // Buscar registros existentes FUTUROS con misma combinación de plazo y fechas
        List<FIN_Plazos_y_Tasas_info__c> existentes = [
            SELECT Id, FIN_Plazo__c, FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c
            FROM FIN_Plazos_y_Tasas_info__c
            WHERE FIN_Plazo__c IN :plazosUnicos
            AND FIN_Fecha_Inicio__c > :ahora
            AND FIN_Fecha_Fin__c > :ahora
            AND Id NOT IN :nuevosRegistros WITH SECURITY_ENFORCED
        ];
        
        List<FIN_Plazos_y_Tasas_info__c> paraEliminar = new List<FIN_Plazos_y_Tasas_info__c>();
        
        for (FIN_Plazos_y_Tasas_info__c existente : existentes) {
            String claveExistente = existente.FIN_Plazo__c + '-' + 
                                    existente.FIN_Fecha_Inicio__c.format('yyyy-MM-dd') + '-' + 
                                    existente.FIN_Fecha_Fin__c.format('yyyy-MM-dd');
            
            if (nuevosMap.containsKey(claveExistente)) {
                paraEliminar.add(existente);
            }
        }
        
        if (!paraEliminar.isEmpty()) {
            // Seguridad: validar permiso de DELETE antes del DML
            if (!Schema.sObjectType.FIN_Plazos_y_Tasas_info__c.isDeletable()) {
                return;
            }

            try {
                delete paraEliminar;
            } catch (DmlException e) {
                 String mensajeError = e.getMessage();
                for (FIN_Plazos_y_Tasas_info__c reg : nuevosRegistros) {
                    reg.addError('Error al actualizar registros existentes: ' + mensajeError);
                }
            }

        }
    }
    
    /**
     * @description
     * BEFORE INSERT: ajusta fechas por carga masiva (+5 horas)
     * y recorta internamente para evitar solapamientos entre registros nuevos.
     * @param nuevosRegistros lista de registros del trigger (Trigger.new).
     */
    public static void handleBeforeInsert(List<FIN_Plazos_y_Tasas_info__c> nuevosRegistros) {
        // Ajustar zona horaria si es carga masiva
        for (FIN_Plazos_y_Tasas_info__c record : nuevosRegistros) {
            if (record.FIN_Masivo__c) {
                if (record.FIN_Fecha_Inicio__c != null) {
                    record.FIN_Fecha_Inicio__c = record.FIN_Fecha_Inicio__c.addHours(5);
                }
                if (record.FIN_Fecha_Fin__c != null) {
                    record.FIN_Fecha_Fin__c = record.FIN_Fecha_Fin__c.addHours(5);
                }
            }
        }

        // Lógica de recorte entre nuevos registros para evitar solapamientos
        for (Integer i = 0; i < nuevosRegistros.size(); i++) {
            FIN_Plazos_y_Tasas_info__c registroPrincipal = nuevosRegistros[i];

            if (registroPrincipal.FIN_Plazo__c == null ||
                registroPrincipal.FIN_Fecha_Inicio__c == null ||
                registroPrincipal.FIN_Fecha_Fin__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevosRegistros.size(); j++) {
                if (i == j) {
                    continue;
                }

                FIN_Plazos_y_Tasas_info__c registroComparado = nuevosRegistros[j];

                if (registroComparado.FIN_Plazo__c == null ||
                    registroComparado.FIN_Fecha_Inicio__c == null ||
                    registroComparado.FIN_Fecha_Fin__c == null) {
                    continue;
                }

                if (registroPrincipal.FIN_Plazo__c == registroComparado.FIN_Plazo__c &&
                    registroComparado.FIN_Fecha_Inicio__c > registroPrincipal.FIN_Fecha_Inicio__c &&
                    registroComparado.FIN_Fecha_Inicio__c < registroPrincipal.FIN_Fecha_Fin__c) {

                    // Recortar la fecha fin del registro principal
                    registroPrincipal.FIN_Fecha_Fin__c = registroComparado.FIN_Fecha_Inicio__c;
                }
            }
        }
    }

    /**
     * @description
     * BEFORE INSERT / BEFORE UPDATE: valida reglas de negocio para
     * plazo, tasa, fechas y duplicados sobre FIN_Plazos_y_Tasas_info__c.
     * @param nuevosRegistros lista de registros del trigger (Trigger.new).
     */
    public static void handleValidaciones(List<FIN_Plazos_y_Tasas_info__c> nuevosRegistros) {
        Set<String> claves = new Set<String>();
    
        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_Plazos_y_Tasas_info__c.isAccessible()) {
            for (FIN_Plazos_y_Tasas_info__c reg : nuevosRegistros) {
                reg.addError('No tiene permisos para leer FIN_Plazos_y_Tasas_info__c.');
            }
            return;
        }

        // Cargar registros similares para verificar duplicados
        List<FIN_Plazos_y_Tasas_info__c> existentes = [
            SELECT Id, FIN_Plazo__c, FIN_Tasa_de_Interes__c, FIN_Fecha_Inicio__c, FIN_Fecha_Fin__c
            FROM FIN_Plazos_y_Tasas_info__c
            WHERE FIN_Fecha_Inicio__c != null AND FIN_Fecha_Fin__c != null WITH SECURITY_ENFORCED
        ];
        
        //  Validar que el plazo esté en el rango permitido
        for (FIN_Plazos_y_Tasas_info__c reg : nuevosRegistros) {

            //  Validar que el plazo esté en el rango permitido
            try {
                Schema.DescribeFieldResult plazoDescribe = FIN_Plazos_y_Tasas_info__c.FIN_Plazo__c.getDescribe();
                if (plazoDescribe.getType() == Schema.DisplayType.Picklist && reg.FIN_Plazo__c != null) {
                    Integer val = Integer.valueOf(reg.FIN_Plazo__c);
                    Integer minVal = 9999;
                    Integer maxVal = -1;

                    for (Schema.PicklistEntry entry : plazoDescribe.getPicklistValues()) {
                        if (entry.isActive()) {
                            Integer num = Integer.valueOf(entry.getValue());
                            if (num < minVal) {
                                minVal = num;
                            }
                            if (num > maxVal) {
                                maxVal = num;
                            }
                        }
                    }

                    if (val < minVal || val > maxVal) {
                        reg.FIN_Plazo__c.addError('Plazo fuera de rango (' + minVal + ' a ' + maxVal + ').');
                    }
                }
            } catch (Exception e) {
                reg.FIN_Plazo__c.addError('Plazo inválido.');
            }

            // Validar formato de tasa de interés
            if (String.isBlank(reg.FIN_Tasa_de_Interes__c)) {
                reg.FIN_Tasa_de_Interes__c.addError('Tasa requerida.');
            } else {
                try {
                    String tasa = reg.FIN_Tasa_de_Interes__c.trim();
                    if (!Pattern.matches('^\\d{1,2}(,\\d{1,2})?$', tasa)) {
                        reg.FIN_Tasa_de_Interes__c.addError('Formato inválido. Use números con coma decimal (ej: 5,23 o 12,50)');
                    } else {
                        if (!tasa.contains(',')) {
                            tasa += ',00';
                        } else {
                            String[] partes = tasa.split(',');
                            if (partes[1].length() == 1) {
                                tasa += '0';
                            }
                        }
                        reg.FIN_Tasa_de_Interes__c = tasa;
                    }
                } catch (Exception e) {
                    reg.FIN_Tasa_de_Interes__c.addError('Error en tasa de interés.');
                }
            }

            //  Validar fechas requeridas y consistentes
            if (reg.FIN_Fecha_Inicio__c == null || reg.FIN_Fecha_Fin__c == null) {
                reg.addError('Ambas fechas (inicio y fin) son requeridas.');
            } else {
                DateTime ahora = DateTime.now();
                if (reg.FIN_Fecha_Inicio__c < ahora && reg.CreatedDate == null) {
                    reg.FIN_Fecha_Inicio__c.addError('Fecha inicio < fecha actual');
                }
                if (reg.FIN_Fecha_Fin__c < ahora) {
                    reg.FIN_Fecha_Fin__c.addError('Fecha fin < fecha actual');
                }
                if (reg.FIN_Fecha_Fin__c < reg.FIN_Fecha_Inicio__c) {
                    reg.FIN_Fecha_Fin__c.addError('Fecha fin < fecha inicio');
                }

                Long diffMins = (reg.FIN_Fecha_Fin__c.getTime() - reg.FIN_Fecha_Inicio__c.getTime()) / (1000 * 60);
                if (diffMins < 15) {
                    reg.FIN_Fecha_Fin__c.addError('Fecha fin < fecha inicio');
                }
            }

            // Componer clave sin incluir todos los campos
            String clave = String.join(new List<String>{
                String.valueOf(reg.FIN_Fecha_Inicio__c),
                String.valueOf(reg.FIN_Fecha_Fin__c),
                reg.FIN_Plazo__c
            }, '-');

            if (claves.contains(clave)) {
                reg.addError('Registro duplicado en la carga: mismo plazo y periodo de vigencia.');
            } else {
                claves.add(clave);
            }
            
            // Componer clave todos los campos
            String claveTotal = String.join(new List<String>{
                String.valueOf(reg.FIN_Fecha_Inicio__c),
                String.valueOf(reg.FIN_Fecha_Fin__c),
                reg.FIN_Plazo__c,
                reg.FIN_Tasa_de_Interes__c      
            }, '-');

            // Validar duplicados ya existentes
            for (FIN_Plazos_y_Tasas_info__c existente : existentes) {
                String claveExistente = String.join(new List<String>{
                    String.valueOf(existente.FIN_Fecha_Inicio__c),
                    String.valueOf(existente.FIN_Fecha_Fin__c),
                    existente.FIN_Plazo__c,
                    existente.FIN_Tasa_de_Interes__c
                }, '-');

                if (claveTotal == claveExistente) {
                    reg.addError('Este registro ya existe en Salesforce.');
                    break;
                }
            }
        }
    }

}