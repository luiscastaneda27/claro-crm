/**
 * @description      Handler principal para la lógica del objeto FIN_CuotaInicialProducto__c.
 *                   Gestiona duplicados, solapamientos de fechas, y validaciones para garantizar
 *                   la consistencia de los productos configurados por Plazo, Canal y Vigencia.
 * @author           
 * @date             2025-11-27
 */

 @SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.StdCyclomaticComplexity,PMD.ApexCRUDViolation,PMD.EmptyCatchBlock,PMD.NcssMethodCount,PMD.AvoidNonRestrictiveQueries,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class FIN_CuotaInicialProductoHandler {

        /** Control de reentrada para after-insert */
    public static Boolean enEjecucion = false;
    
    /**
     * @description Execute logic after insert (caller: trigger).
     * @param nuevosRegistros Lista de registros recién insertados.
     */
    public static void handleInsert(List<FIN_CuotaInicialProducto__c> nuevosRegistros) {
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
     * @description Execute logic before insert (caller: trigger).
     * @param nuevos Lista de registros nuevos antes de ser insertados.
     */
    public static void handleBeforeInsert(List<FIN_CuotaInicialProducto__c> nuevos) {
        // Ajustar zona horaria si es carga masiva
        for (FIN_CuotaInicialProducto__c record : nuevos) {
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
                FIN_CuotaInicialProducto__c registroPrincipal = nuevos[i];

            if (!camposClaveLlenos(registroPrincipal) ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                    continue;
                }

                for (Integer j = 0; j < nuevos.size(); j++) {
                    if (i == j) { 
                        continue; 
                    }

                    FIN_CuotaInicialProducto__c registroComparado = nuevos[j];

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
     * @description  // Método para ajustar las fechas "Hasta" después de insertar
     * @param nuevos 
     */
    private static void ajustarFechasHasta(List<FIN_CuotaInicialProducto__c> nuevos) {
        if (nuevos.isEmpty()) {
            return;
        }
        Set<String> claves = new Set<String>();
        for (FIN_CuotaInicialProducto__c reg : nuevos) {
            if (camposClaveLlenos(reg)) {
                claves.add(obtenerClave(reg));
        }
        }

        // Consulta los registros existentes
        List<FIN_CuotaInicialProducto__c> existentes = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c,
                   FIN_Desde__c, FIN_Hasta__c
            FROM FIN_CuotaInicialProducto__c
            WHERE FIN_Desde__c != null AND FIN_Hasta__c != null
            WITH SECURITY_ENFORCED
        ];

            List<FIN_CuotaInicialProducto__c> ajustes = new List<FIN_CuotaInicialProducto__c>();

        // Comparar registros nuevos con los existentes
            for (FIN_CuotaInicialProducto__c nuevo : nuevos) {
                if (!camposClaveLlenos(nuevo)) continue;

                for (FIN_CuotaInicialProducto__c vigente : existentes) {
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
            }
        }
    }

    /**
     * @description  // Método para eliminar registros duplicados (mismo documento, tipo y vigencia)
     * @param nuevosRegistros 
     */
    private static void eliminarDuplicados(List<FIN_CuotaInicialProducto__c> nuevosRegistros) {
        Datetime ahora = Datetime.now();
        
        // Identificar claves únicas de los nuevos registros futuros
        Map<String, FIN_CuotaInicialProducto__c> nuevosMap = new Map<String, FIN_CuotaInicialProducto__c>();
        Set<String> clavesUnicas = new Set<String>();
        
        for (FIN_CuotaInicialProducto__c nuevo : nuevosRegistros) {
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
        List<FIN_CuotaInicialProducto__c> existentes = [
            SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Desde__c, FIN_Hasta__c
            FROM FIN_CuotaInicialProducto__c
            WHERE FIN_Desde__c > :ahora
            AND FIN_Hasta__c > :ahora
            AND Id NOT IN :nuevosRegistros
            WITH SECURITY_ENFORCED
        ];
        
        // Filtrar por claves únicas para optimizar
        List<FIN_CuotaInicialProducto__c> existentesFiltrados = new List<FIN_CuotaInicialProducto__c>();
        for (FIN_CuotaInicialProducto__c existente : existentes) {
            if (clavesUnicas.contains(obtenerClave(existente))) {
                existentesFiltrados.add(existente);
            }
        }
        
        List<FIN_CuotaInicialProducto__c> paraEliminar = new List<FIN_CuotaInicialProducto__c>();
        
        for (FIN_CuotaInicialProducto__c existente : existentesFiltrados) {
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
            } catch (DmlException e) {
                
            }
        }
    }
     
     /**
     * @description  // Verificar si todos los campos clave están completos
     * @param r 
     * @return true si tiene los campos de la clave llenos.
     */
    public static Boolean camposClaveLlenos(FIN_CuotaInicialProducto__c r) {
        return r.FIN_Canal__c != null && r.FIN_Material__c != null;
    }

    /**
     * @description  // Crear la clave única para comparar los registros
     * @param r de registros.
     * @return clave generada.
     */
    public static String obtenerClave(FIN_CuotaInicialProducto__c r) {
        return r.FIN_Canal__c + '|' + r.FIN_Material__c;
    }

    /**
     * @description Orquesta las validaciones separadas (reduce complejidad por método).
     * @param triggerNew de registros validacionesCuotaInicialProducto.
     */ 
    public static void validacionesCuotaInicialProducto(List<FIN_CuotaInicialProducto__c>triggerNew){
        Set<String> claves = new Set<String>();
    Date hoy = Date.today();

    List<FIN_CuotaInicialProducto__c> existentes = [
        SELECT Id, FIN_Canal__c, FIN_Material__c, FIN_Plazo_Minimo__c, FIN_Plazo_Maximo__c, FIN_CuotaInicial__c,
               FIN_Desde__c, FIN_Hasta__c
        FROM FIN_CuotaInicialProducto__c
        WITH SECURITY_ENFORCED
    ];

    for (FIN_CuotaInicialProducto__c reg : triggerNew) {
    
        // Regla 3 - Canal solo admite valores válidos parametrizables (CAV, TMK, etc.)
        Set<String> valoresPermitidos = new Set<String>();

        // Obtener la descripción del campo
        Schema.DescribeFieldResult campoDescribe = FIN_CuotaInicialProducto__c.FIN_Canal__c.getDescribe();

        // Verificar si es picklist
        if (campoDescribe.getType() == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> valores = campoDescribe.getPicklistValues();
    
            for (Schema.PicklistEntry v : valores) {
                if (v.isActive()) {
                    valoresPermitidos.add(v.getValue());
                }
            }
        }

            if (reg.FIN_Canal__c != null && !valoresPermitidos.contains(reg.FIN_Canal__c)) {
            reg.FIN_Canal__c.addError('Canal inválido: valores disponibles: ' + String.join(new List<String>(valoresPermitidos), ', '));
    }

        // Regla 4 - Material debe ser entero sin decimales (solo números enteros sin punto)
        if (reg.FIN_Material__c != null) {
            if (!Pattern.matches('^\\d+$', reg.FIN_Material__c)) {
                reg.FIN_Material__c.addError('Material debe ser un número entero sin decimales ni símbolos.');
            }
    }

        // Regla 5 - Plazos deben estar dentro de los valores válidos definidos por el picklist
        Integer minValor = 9999;
        Integer maxValor = -1;

        Schema.DescribeFieldResult plazoDescribe = FIN_CuotaInicialProducto__c.FIN_Plazo_Minimo__c.getDescribe();

         if (plazoDescribe.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry v : plazoDescribe.getPicklistValues()) {
                if (v.isActive()) {
                    Integer val = Integer.valueOf(v.getValue());
                    if (val < minValor) minValor = val;
                    if (val > maxValor) maxValor = val;
                }
            }
        }

            if (reg.FIN_Plazo_Minimo__c != null) {
            try {
                Integer plazoMin = Integer.valueOf(reg.FIN_Plazo_Minimo__c);
                if (plazoMin < minValor || plazoMin > maxValor) {
                    reg.FIN_Plazo_Minimo__c.addError('Plazo Mínimo inválido: debe estar entre ' + minValor + ' y ' + maxValor + '.');
            }
            } catch (Exception e) {reg.FIN_Plazo_Minimo__c.addError('Plazo Mínimo debe ser un número válido.');
            }
        }

        if (reg.FIN_Plazo_Maximo__c != null) {
        try {
                Integer plazoMax = Integer.valueOf(reg.FIN_Plazo_Maximo__c);
                if (plazoMax < minValor || plazoMax > maxValor) {
                    reg.FIN_Plazo_Maximo__c.addError('Plazo Máximo inválido: debe estar entre ' + minValor + ' y ' + maxValor + '.');
            }
            } catch (Exception e) {reg.FIN_Plazo_Maximo__c.addError('Plazo Máximo debe ser un número válido.');
        }
    }

        // Regla 5.1 - Plazo min no puede ser mayor al max
        
        if (reg.FIN_Plazo_Minimo__c != null && reg.FIN_Plazo_Maximo__c != null) {
        
            if (Integer.valueof(reg.FIN_Plazo_Minimo__c) > Integer.valueof(reg.FIN_Plazo_Maximo__c)) {
                    reg.FIN_Plazo_Minimo__c.addError('El Plazo Minimo no puede ser mayor al Plazo Maximo.');
                }
        }    
        
        // Regla 6 - Cuota Inicial como porcentaje entero sin decimales
            if (!String.isBlank(reg.FIN_CuotaInicial__c)) {
                try {
                    Integer cuotaInicial = Integer.valueOf(reg.FIN_CuotaInicial__c);
        
                    if (cuotaInicial < 1 || cuotaInicial > 100) {
                        reg.FIN_CuotaInicial__c.addError('Cuota Inicial debe ser un número entero válido.');
                    }
                } catch (Exception e) {reg.FIN_CuotaInicial__c.addError('Cuota Inicial debe ser un número entero válido.');
                }
            }

        
        // Regla 7 - Validar formato, fecha y hora
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
            if (reg.FIN_Hasta__c.time() < ahoraTime) { reg.FIN_Hasta__c.addError('Hasta < hoy.');
            }
    }

            // Validar Fin >= Inicio (considerando hora)
        if (reg.FIN_Hasta__c < reg.FIN_Desde__c) {
            reg.FIN_Hasta__c.addError('Hasta < desde.');
        }
    
            // Validar diferencia mínima (opcional)
            Long diferenciaMinutos = ((reg.FIN_Hasta__c.getTime() - reg.FIN_Desde__c.getTime()) / (1000 * 60));
                if (diferenciaMinutos < 15) {
                reg.FIN_Hasta__c.addError('Hasta < desde.');
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
            reg.FIN_CuotaInicial__c,
            reg.FIN_Plazo_Minimo__c,
            reg.FIN_Plazo_Maximo__c
                
        }, '-');

        // Validar duplicados ya existentes
            for (FIN_CuotaInicialProducto__c existente : existentes) {
            String claveExistente = String.join(new List<String>{
                String.valueOf(existente.FIN_Desde__c),
                String.valueOf(existente.FIN_Hasta__c),
                existente.FIN_Canal__c,
                existente.FIN_Material__c,
                existente.FIN_CuotaInicial__c,
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