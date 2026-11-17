/**
 * @description Handler BEFORE para FIN_PlazosPrecios__c.
 * Valida duplicados, formatos, vigencias y reglas de negocio
 * sin modificar la lógica original.
 */
@SuppressWarnings('PMD')
public with sharing class FIN_PlazosPreciosTriggerHandler {

    /**
     * @description Valida duplicados, valores permitidos y reglas de fechas
     * tanto en la carga como contra registros existentes.
     *
     * @param nuevosRegistros Registros a validar
     */
    @SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssMethodCount,PMD.AvoidDeeplyNestedIfStmts,PMD.LocalVariableNamingConventions,PMD.AvoidDebugStatements')
    public static void validarDuplicados(List<FIN_PlazosPrecios__c> nuevosRegistros) {

        Set<String> clavesUnicas = new Set<String>();
        Map<String, FIN_PlazosPrecios__c> mapaNuevos = new Map<String, FIN_PlazosPrecios__c>();

        // =========================
        // P2 – Picklist Producto
        // =========================
        Set<String> valoresPermitidos = new Set<String>();
        Schema.DescribeFieldResult campoDescribe =
            FIN_PlazosPrecios__c.FIN_Producto__c.getDescribe();

        if (campoDescribe.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry v : campoDescribe.getPicklistValues()) {
                if (v.isActive()) {
                    valoresPermitidos.add(v.getValue());
                }
            }
        }

        // =========================
        // Picklist Plazos
        // =========================
        Set<String> valoresPicklistPlazo = new Set<String>();
        Schema.DescribeFieldResult campoDescribePlazo =
            FIN_PlazosPrecios__c.FIN_Plazo_1_6__c.getDescribe();

        if (campoDescribePlazo.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry v : campoDescribePlazo.getPicklistValues()) {
                if (v.isActive()) {
                    valoresPicklistPlazo.add(v.getValue());
                }
            }
        }

        // =========================
        // P1 – Validaciones en carga
        // =========================
        for (FIN_PlazosPrecios__c nuevo : nuevosRegistros) {

            String clave = String.join(
                new List<String>{
                    String.valueOf(nuevo.FIN_Desde__c),
                    String.valueOf(nuevo.FIN_Hasta__c),
                    nuevo.FIN_Producto__c,
                    nuevo.FIN_PVP_Min__c,
                    nuevo.FIN_PVP_Max__c
                },
                '-'
            );

            if (clavesUnicas.contains(clave)) {
                nuevo.addError(
                    'Registro duplicado en la carga: mismo producto, PVP Min, PVP Max y periodo de vigencia.'
                );
            } else {
                clavesUnicas.add(clave);
            }

            if (nuevo.FIN_Producto__c != null &&
                !valoresPermitidos.contains(nuevo.FIN_Producto__c)) {
                nuevo.FIN_Producto__c.addError(
                    'Producto inválido: valores disponibles: ' +
                    String.join(new List<String>(valoresPermitidos), ', ')
                );
            }

            if (nuevo.FIN_PVP_Min__c != null) {
                Pattern patternNumeros = Pattern.compile('^[0-9]+$');
                Matcher matcherMin = patternNumeros.matcher(nuevo.FIN_PVP_Min__c);

                if (!matcherMin.matches()) {
                    nuevo.addError('PVP Mínimo solo se permite numeros sin decimales.');
                } else if (nuevo.FIN_PVP_Max__c != 'Adelante') {

                    Matcher matcherMax =
                        patternNumeros.matcher(nuevo.FIN_PVP_Max__c);

                    if (!matcherMax.matches()) {
                        nuevo.addError(
                            'PVP Máximo solo se permite numeros sin decimales o la palabra Adelante.'
                        );
                    } else {
                        Double pvpMax = Double.valueOf(nuevo.FIN_PVP_Max__c);
                        Double pvpMin = Double.valueOf(nuevo.FIN_PVP_Min__c);

                        if (pvpMin > pvpMax) {
                            nuevo.addError(
                                'PVP Mínimo no puede ser mayor que el PVP Máximo.'
                            );
                        }
                    }
                }
            }

            if (!valoresPicklistPlazo.contains(nuevo.FIN_Plazo_1_6__c) ||
                !valoresPicklistPlazo.contains(nuevo.FIN_Plazo_7_12__c) ||
                !valoresPicklistPlazo.contains(nuevo.FIN_Plazo_13_18__c) ||
                !valoresPicklistPlazo.contains(nuevo.FIN_Plazo_19_24__c) ||
                !valoresPicklistPlazo.contains(nuevo.FIN_Plazo_25_36__c)) {

                nuevo.addError(
                    'El campo Plazos es inválido. Valores disponibles: ' +
                    String.join(new List<String>(valoresPicklistPlazo), ' o ')
                );
            }

            DateTime ahora = DateTime.now();
            Date hoy = ahora.date();
            Time ahoraTime = ahora.time();

            if (nuevo.FIN_Desde__c.date() < hoy) {
                nuevo.FIN_Desde__c.addError('La fecha desde no puede ser anterior al día actual.');
            } else if (nuevo.FIN_Desde__c.date() == hoy &&
                       nuevo.FIN_Desde__c.time() < ahoraTime) {
                nuevo.FIN_Desde__c.addError('La hora desde no puede ser anterior a la hora actual.');
            }

            if (nuevo.FIN_Hasta__c.date() < hoy) {
                nuevo.FIN_Hasta__c.addError('La fecha hasta no puede ser anterior al día actual.');
            } else if (nuevo.FIN_Hasta__c.date() == hoy &&
                       nuevo.FIN_Hasta__c.time() < ahoraTime) {
                nuevo.FIN_Hasta__c.addError('La hora hasta no puede ser anterior a la hora actual.');
            }

            if (nuevo.FIN_Hasta__c != null &&
                nuevo.FIN_Desde__c != null &&
                nuevo.FIN_Hasta__c <= nuevo.FIN_Desde__c) {
                nuevo.FIN_Hasta__c.addError(
                    'La fecha hasta debe ser mayor que la fecha desde.'
                );
            }

            mapaNuevos.put(nuevo.Id, nuevo);
        }

        // =========================
        // Duplicados en BD
        // =========================
        List<FIN_PlazosPrecios__c> existentes = [
            SELECT Id,
                   FIN_Producto__c,
                   FIN_PVP_Min__c,
                   FIN_PVP_Max__c,
                   FIN_Plazo_1_6__c,
                   FIN_Plazo_7_12__c,
                   FIN_Plazo_13_18__c,
                   FIN_Plazo_19_24__c,
                   FIN_Plazo_25_36__c,
                   FIN_Desde__c,
                   FIN_Hasta__c
            FROM FIN_PlazosPrecios__c
            WHERE FIN_Producto__c != null
              AND FIN_PVP_Min__c != null
              AND FIN_PVP_Max__c != null
              AND FIN_Desde__c != null
              AND FIN_Hasta__c != null
            WITH SECURITY_ENFORCED
        ];

        Set<String> clavesExistentes = new Set<String>();
        for (FIN_PlazosPrecios__c p : existentes) {
            clavesExistentes.add(generarClave(p));
        }

        for (FIN_PlazosPrecios__c nuevo : nuevosRegistros) {
            if (clavesExistentes.contains(generarClave(nuevo))) {
                nuevo.addError(
                    'Ya existe un registro con la misma combinación de Producto, PVP Min, PVP Max, Plazos, Desde y Hasta.'
                );
            }
        }
    }

    /**
     * @description Ajusta fechas para carga masiva y recorta solapamientos
     * entre registros nuevos. Lógica original intacta.
     */
    @SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity')
    public static void validarYPreparar(List<FIN_PlazosPrecios__c> nuevos) {

        if (nuevos.isEmpty()) {
            return;
        }

        for (FIN_PlazosPrecios__c nuevo : nuevos) {
            if (nuevo.FIN_Masivo__c) {
                if (nuevo.FIN_Desde__c != null) {
                    nuevo.FIN_Desde__c = nuevo.FIN_Desde__c.addHours(5);
                }
                if (nuevo.FIN_Hasta__c != null) {
                    nuevo.FIN_Hasta__c = nuevo.FIN_Hasta__c.addHours(5);
                }
            }
        }

        for (Integer i = 0; i < nuevos.size(); i++) {
            FIN_PlazosPrecios__c registroPrincipal = nuevos[i];

            if (!camposClaveLlenos(registroPrincipal) ||
                registroPrincipal.FIN_Desde__c == null ||
                registroPrincipal.FIN_Hasta__c == null) {
                continue;
            }

            for (Integer j = 0; j < nuevos.size(); j++) {
                if (i == j) {
                    continue;
                }

                FIN_PlazosPrecios__c registroComparado = nuevos[j];

                if (!camposClaveLlenos(registroComparado) ||
                    registroComparado.FIN_Desde__c == null ||
                    registroComparado.FIN_Hasta__c == null) {
                    continue;
                }

                Boolean mismaClave =
                    registroPrincipal.FIN_Producto__c == registroComparado.FIN_Producto__c &&
                    registroPrincipal.FIN_PVP_Min__c == registroComparado.FIN_PVP_Min__c &&
                    registroPrincipal.FIN_PVP_Max__c == registroComparado.FIN_PVP_Max__c;

                Boolean solapa =
                    registroComparado.FIN_Desde__c > registroPrincipal.FIN_Desde__c &&
                    registroComparado.FIN_Desde__c < registroPrincipal.FIN_Hasta__c;

                if (mismaClave && solapa) {
                    registroPrincipal.FIN_Hasta__c = registroComparado.FIN_Desde__c;
                }
            }
        }
    }

    /**
     * @description Genera clave única completa del registro.
     */
    private static String generarClave(FIN_PlazosPrecios__c p) {
        return String.valueOf(p.FIN_Producto__c) + '|' +
               String.valueOf(p.FIN_PVP_Min__c) + '|' +
               String.valueOf(p.FIN_PVP_Max__c) + '|' +
               String.valueOf(p.FIN_Plazo_1_6__c) + '|' +
               String.valueOf(p.FIN_Plazo_7_12__c) + '|' +
               String.valueOf(p.FIN_Plazo_13_18__c) + '|' +
               String.valueOf(p.FIN_Plazo_19_24__c) + '|' +
               String.valueOf(p.FIN_Plazo_25_36__c) + '|' +
               String.valueOf(p.FIN_Desde__c) + '|' +
               String.valueOf(p.FIN_Hasta__c);
    }

    /**
     * @description Verifica si los campos clave están completos.
     */
    public static Boolean camposClaveLlenos(FIN_PlazosPrecios__c r) {
        return r.FIN_Producto__c != null &&
               r.FIN_PVP_Min__c != null &&
               r.FIN_PVP_Max__c != null;
    }
}