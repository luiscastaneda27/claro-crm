/**
 * @description Handler para la gestión de FIN_PlazosHabilitados__c.
 *              Incluye validaciones, ajuste de fechas, control de duplicados
 *              y lógica de cargas masivas.
 * @author      Ezequiel Olivera
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.ApexCRUDViolation,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.AvoidNonRestrictiveQueries')
public with sharing class FIN_PlazosHabilitadosHandler {
    // Variable estática para controlar recursividad
    public static Boolean enEjecucion = false;
    
        /**
    * @description Ejecuta lógica after insert para ajuste de fechas y eliminación de duplicados.
    * @param nuevosRegistros Lista de registros recién insertados.
    */
    // Método principal para manejar inserciones
    public static void handleInsert(List<FIN_PlazosHabilitados__c> nuevosRegistros) {
        if (enEjecucion) return;
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
    * @description Ejecuta lógica before insert para ajustes previos y resolución de solapamientos.
    * @param nuevos Lista de registros a insertar.
    */
    // Método para before insert (ajuste de horas masivas)
    public static void handleBeforeInsert(List<FIN_PlazosHabilitados__c> nuevos) {
        // Ajustar zona horaria si es carga masiva
        for (FIN_PlazosHabilitados__c record : nuevos) {
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
        for (Integer i = 0; i < nuevos.size(); i++) {
            FIN_PlazosHabilitados__c registroPrincipal = nuevos[i];

            if (!camposClaveLlenos(registroPrincipal) ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevos.size(); j++) {
                if (i == j) continue;

                FIN_PlazosHabilitados__c registroComparado = nuevos[j];

                if (!camposClaveLlenos(registroComparado) ||
                    registroComparado.FIN_Desde__c == null ||
                    registroComparado.FIN_Hasta__c == null) {
                    continue;
                }

                Boolean mismaClave = 
                    registroPrincipal.FIN_Canal__c == registroComparado.FIN_Canal__c &&
                    registroPrincipal.FIN_Material__c == registroComparado.FIN_Material__c
                    ;

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
    * @description Ejecuta lógica after insert para ajuste de fechas.
    * @param nuevos Lista de registros recién insertados.
    */
    // Método para ajustar las fechas "Hasta" después de insertar
    private static void ajustarFechasHasta(List<FIN_PlazosHabilitados__c> nuevos) {
        if (nuevos.isEmpty()) return;

        Set<String> claves = new Set<String>();
        for (FIN_PlazosHabilitados__c reg : nuevos) {
            if (camposClaveLlenos(reg)) {
                claves.add(obtenerClave(reg));
            }
        }

        // Consulta los registros existentes
        List<FIN_PlazosHabilitados__c> existentes = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c,
                   FIN_Desde__c, FIN_Hasta__c
            FROM FIN_PlazosHabilitados__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null
            WITH SECURITY_ENFORCED
        ];

        List<FIN_PlazosHabilitados__c> ajustes = new List<FIN_PlazosHabilitados__c>();

        // Comparar registros nuevos con los existentes
        for (FIN_PlazosHabilitados__c nuevo : nuevos) {
            if (!camposClaveLlenos(nuevo)) continue;

            for (FIN_PlazosHabilitados__c vigente : existentes) {
                if (!camposClaveLlenos(vigente)) continue;

                Boolean mismaClave =
                    nuevo.FIN_Canal__c == vigente.FIN_Canal__c &&
                    nuevo.FIN_Material__c == vigente.FIN_Material__c ;

                Boolean solapa =
                    nuevo.FIN_Desde__c > vigente.FIN_Desde__c &&
                    nuevo.FIN_Desde__c <= vigente.FIN_Hasta__c;

                if (mismaClave && solapa) {
                    // Actualizar la fecha "Hasta" del registro vigente
                    vigente.FIN_Hasta__c = nuevo.FIN_Desde__c;
                    ajustes.add(vigente);
                }
            }
        }

        if (!ajustes.isEmpty()) {
            try {
                update ajustes;
            } catch (DmlException e) {
                e.getMessage();
            }
        }
    }
     /**
    * @description Ejecuta lógica after insert para eliminación de duplicados.
    * @param nuevosRegistros Lista de registros recién insertados.
    */
    // Método para eliminar registros duplicados (mismo documento, tipo y vigencia)
    private static void eliminarDuplicados(List<FIN_PlazosHabilitados__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        // Identificar claves únicas de los nuevos registros futuros
        Map<String, FIN_PlazosHabilitados__c> nuevosMap = new Map<String, FIN_PlazosHabilitados__c>();
        Set<String> clavesUnicas = new Set<String>();
        
        for (FIN_PlazosHabilitados__c nuevo : nuevosRegistros) {
            if (camposClaveLlenos(nuevo) && 
                nuevo.FIN_Desde__c != null &&
                nuevo.FIN_Hasta__c != null &&
                nuevo.FIN_Desde__c > ahora) {
                
                // Clave única: FIN_Canal__c + FIN_Material__c + Fechas formateadas
                String clave = nuevo.FIN_Canal__c + '-' + 
                               nuevo.FIN_Material__c + '-' + 
                               nuevo.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                               nuevo.FIN_Hasta__c.format('yyyy-MM-dd');
                
                nuevosMap.put(clave, nuevo);
                clavesUnicas.add(obtenerClave(nuevo));
            }
        }
        
        if (nuevosMap.isEmpty()) return;
        
        // Buscar registros existentes FUTUROS con misma combinación
        List<FIN_PlazosHabilitados__c> existentes = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_PlazosHabilitados__c
            WHERE FIN_Desde__c > :ahora
            AND FIN_Hasta__c > :ahora
            AND Id NOT IN :nuevosRegistros
            WITH SECURITY_ENFORCED
        ];
        
        // Filtrar por claves únicas para optimizar
        List<FIN_PlazosHabilitados__c> existentesFiltrados = new List<FIN_PlazosHabilitados__c>();
        for (FIN_PlazosHabilitados__c existente : existentes) {
            if (clavesUnicas.contains(obtenerClave(existente))) {
                existentesFiltrados.add(existente);
            }
        }
        
        List<FIN_PlazosHabilitados__c> paraEliminar = new List<FIN_PlazosHabilitados__c>();
        
        for (FIN_PlazosHabilitados__c existente : existentesFiltrados) {
            String claveExistente = existente.FIN_Canal__c + '-' + 
                                  existente.FIN_Material__c + '-' + 
                                  existente.FIN_Desde__c.format('yyyy-MM-dd') + '-' + 
                                  existente.FIN_Hasta__c.format('yyyy-MM-dd');
            
            if (nuevosMap.containsKey(claveExistente)) {
                paraEliminar.add(existente);
            }
        }
        
        if (!paraEliminar.isEmpty()) {
            try {
                delete paraEliminar;
            } catch (DmlException e) { e.getMessage();
            }
        }
    }
    
        /**
     * @description Valida si los campos clave obligatorios están informados.
     * @param r Registro FIN_PlazosHabilitados__c a validar.
     * @return Boolean true si Canal y Material están completos, false en caso contrario.
     */
    public static Boolean camposClaveLlenos(FIN_PlazosHabilitados__c r) {
        return r.FIN_Canal__c != null && r.FIN_Material__c != null;
    }

    /**
     * @description Genera la clave única del registro basada en Canal y Material.
     * @param r Registro FIN_PlazosHabilitados__c.
     * @return String Clave única con formato Canal|Material.
     */
    public static String obtenerClave(FIN_PlazosHabilitados__c r) {
        return r.FIN_Canal__c + '|' + r.FIN_Material__c;
    }

    /**
    * @description Ejecuta validaciones de negocio para los registros entrantes.
    * @param triggerNew Lista de registros del trigger.
    */
    public static void validacionesPlazosHabilitados(List<FIN_PlazosHabilitados__c>triggerNew){
    	Set<String> claves = new Set<String>();
        Date hoy = Date.today();

        List<FIN_PlazosHabilitados__c> existentes = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, 
                FIN_Plazo_Maximo__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_PlazosHabilitados__c
            WITH SECURITY_ENFORCED
        ];

        for (FIN_PlazosHabilitados__c reg : triggerNew) {
            // Validación de canal como picklist válido
            Set<String> valoresPermitidos = new Set<String>();
            Schema.DescribeFieldResult canalDesc = FIN_PlazosHabilitados__c.FIN_Canal__c.getDescribe();
            if (canalDesc.getType() == Schema.DisplayType.Picklist) {
                for (Schema.PicklistEntry val : canalDesc.getPicklistValues()) {
                    if (val.isActive()) valoresPermitidos.add(val.getValue());
                }
            }
            if (reg.FIN_Canal__c != null && !valoresPermitidos.contains(reg.FIN_Canal__c)) {
                reg.FIN_Canal__c.addError('Canal inválido: valores disponibles: ' + String.join(new List<String>(valoresPermitidos), ', '));
            }

            // Validación de Material entero sin decimales
            if (reg.FIN_Material__c != null && !Pattern.matches('^\\d+$', reg.FIN_Material__c)) {
                reg.FIN_Material__c.addError('Material debe ser un número entero sin símbolos ni decimales.');
            }

            // Validación de plazos válidos dentro del picklist
            Integer minValor = 9999;
            Integer maxValor = -1;

            Schema.DescribeFieldResult plazoDesc = FIN_PlazosHabilitados__c.FIN_Plazo_Minimo__c.getDescribe();
            if (plazoDesc.getType() == Schema.DisplayType.Picklist) {
                for (Schema.PicklistEntry v : plazoDesc.getPicklistValues()) {
                    if (v.isActive()) {
                        Integer val = Integer.valueOf(v.getValue());
                        minValor = Math.min(minValor, val);
                        maxValor = Math.max(maxValor, val);
                    }
                }
            }

            if (reg.FIN_Plazo_Minimo__c != null) {
                try {
                    Integer plazoMin = Integer.valueOf(reg.FIN_Plazo_Minimo__c);
                    if (plazoMin < minValor || plazoMin > maxValor) {
                        reg.FIN_Plazo_Minimo__c.addError('Plazo Mínimo inválido: debe estar entre ' + minValor + ' y ' + maxValor + '.');
                    }
                } catch (Exception e) { reg.FIN_Plazo_Minimo__c.addError('Plazo Mínimo debe ser un número válido.');
                }
            }

            if (reg.FIN_Plazo_Maximo__c != null) {
                try {
                    Integer plazoMax = Integer.valueOf(reg.FIN_Plazo_Maximo__c);
                    if (plazoMax < minValor || plazoMax > maxValor) {
                        reg.FIN_Plazo_Maximo__c.addError('Plazo Máximo inválido: debe estar entre ' + minValor + ' y ' + maxValor + '.');
                    }
                } catch (Exception e) { reg.FIN_Plazo_Maximo__c.addError('Plazo Máximo debe ser un número válido.');
                }
            }

            // Validación de que el mínimo no supere al máximo
            if (reg.FIN_Plazo_Minimo__c != null && reg.FIN_Plazo_Maximo__c != null) {
                if (Integer.valueOf(reg.FIN_Plazo_Minimo__c) > Integer.valueOf(reg.FIN_Plazo_Maximo__c)) {
                    reg.FIN_Plazo_Minimo__c.addError('El Plazo Mínimo no puede ser mayor al Plazo Máximo.');
                }
            }

     
            // Regla 4 - Validar formato, fecha y hora
            if (reg.FIN_Desde__c == null || reg.FIN_Hasta__c == null) {
            reg.addError('Ambas fechas (inicio y fin) son requeridas.');
            } else {
                DateTime ahora = DateTime.now();
                hoy = ahora.date();
                Time ahoraTime = ahora.time();
    
                // Validar Fecha Inicio
                if (reg.FIN_Desde__c.date() < hoy) {
                        reg.FIN_Desde__c.addError('Desde < hoy');
                } else if (reg.FIN_Desde__c.date() == hoy) {
                    // Si es hoy, validar la hora
                        if (reg.FIN_Desde__c.time() < ahoraTime) { reg.FIN_Desde__c.addError('Desde < hoy');
                        }
                    }
    
                // Validar Fecha Fin
                if (reg.FIN_Hasta__c.date() < hoy) {
                    reg.FIN_Hasta__c.addError('Hasta < hoy');
                } else if (reg.FIN_Hasta__c.date() == hoy) {
                    // Si es hoy, validar la hora
                    if (reg.FIN_Hasta__c.time() < ahoraTime) { reg.FIN_Hasta__c.addError('Hasta < hoy');
                    }
                }
    
                // Validar Fin >= Inicio (considerando hora)
                if (reg.FIN_Hasta__c < reg.FIN_Desde__c) {
                    reg.FIN_Hasta__c.addError('Fecha/hora hasta < fecha/hora desde.');
                }
    
                // Validar diferencia mínima (opcional)
                Long diferenciaMinutos = ((reg.FIN_Hasta__c.getTime() - reg.FIN_Desde__c.getTime()) / (1000 * 60));
                    if (diferenciaMinutos < 15) {
                    reg.FIN_Hasta__c.addError('La diferencia mínima entre inicio y fin debe ser de 15 minutos.');
                }
            }
       
            // Componer clave sin incluir todos los campos
            String clave = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Canal__c,
                reg.FIN_Material__c
            }, '-');

            if (claves.contains(clave)) {
               reg.addError('Registro duplicado en la carga: mismo material,canal y periodo de vigencia.');
            } else {
                claves.add(clave);
            }
        
            // Componer clave todos los campos
            String claveTotal = String.join(new List<String>{
                String.valueOf(reg.FIN_Desde__c),
                String.valueOf(reg.FIN_Hasta__c),
                reg.FIN_Canal__c,
                reg.FIN_Material__c,
                reg.FIN_Plazo_Minimo__c,
                reg.FIN_Plazo_Maximo__c
                
            }, '-');

            // Validar duplicados ya existentes
            for (FIN_PlazosHabilitados__c existente : existentes) {
                String claveExistente = String.join(new List<String>{
                    String.valueOf(existente.FIN_Desde__c),
                    String.valueOf(existente.FIN_Hasta__c),
                    existente.FIN_Canal__c,
                    existente.FIN_Material__c,
                    existente.FIN_Plazo_Minimo__c,
                    existente.FIN_Plazo_Maximo__c
                }, '-');

                if (claveTotal == claveExistente) {
                    reg.addError('Este registro ya existe en Salesforce.');break;
                }
            }

        }
    }
}