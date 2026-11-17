/**
 * @description Handler AFTER para FIN_PlazosPrecios__c.
 * Gestiona ajustes de vigencia y eliminación de duplicados
 * manteniendo integridad temporal de los registros.
 */
@SuppressWarnings('PMD')
public with sharing class FIN_PlazosPreciosTriggerAfterHandler {

    /**
     * @description Controla la recursividad del trigger.
     */
    public static Boolean enEjecucion = false;

    /**
     * @description Maneja la lógica principal en after insert.
     * Ajusta fechas y elimina registros duplicados.
     *
     * @param nuevosRegistros Lista de registros insertados
     */
    public static void handleInsert(List<FIN_PlazosPrecios__c> nuevosRegistros) {
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
     * @description Ajusta la fecha Hasta de registros vigentes cuando
     * se insertan nuevos registros con la misma clave y vigencia solapada.
     *
     * @param nuevos Registros recién insertados
     */
    @SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ApexCRUDViolation')
    public static void ajustarFechasHasta(List<FIN_PlazosPrecios__c> nuevos) {

        if (nuevos.isEmpty()) {
            return;
        }

        Set<String> claves = new Set<String>();
        for (FIN_PlazosPrecios__c reg : nuevos) {
            if (todosCamposClaveLlenos(reg)) {
                claves.add(obtenerClave(reg));
            }
        }

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
            WHERE FIN_Desde__c != null
              AND FIN_Hasta__c != null
            WITH SECURITY_ENFORCED
        ];

        List<FIN_PlazosPrecios__c> ajustes = new List<FIN_PlazosPrecios__c>();

        for (FIN_PlazosPrecios__c nuevo : nuevos) {
            if (!todosCamposClaveLlenos(nuevo)) {
                continue;
            }

            for (FIN_PlazosPrecios__c vigente : existentes) {
                if (!todosCamposClaveLlenos(vigente)) {
                    continue;
                }

                Boolean mismaClave =
                    nuevo.FIN_Producto__c == vigente.FIN_Producto__c &&
                    nuevo.FIN_PVP_Min__c == vigente.FIN_PVP_Min__c &&
                    nuevo.FIN_PVP_Max__c == vigente.FIN_PVP_Max__c &&
                    nuevo.FIN_Plazo_1_6__c == vigente.FIN_Plazo_1_6__c &&
                    nuevo.FIN_Plazo_7_12__c == vigente.FIN_Plazo_7_12__c &&
                    nuevo.FIN_Plazo_13_18__c == vigente.FIN_Plazo_13_18__c &&
                    nuevo.FIN_Plazo_19_24__c == vigente.FIN_Plazo_19_24__c &&
                    nuevo.FIN_Plazo_25_36__c == vigente.FIN_Plazo_25_36__c;

                Boolean solapa =
                    nuevo.FIN_Desde__c > vigente.FIN_Desde__c &&
                    nuevo.FIN_Desde__c <= vigente.FIN_Hasta__c;

                if (mismaClave && solapa) {
                    vigente.FIN_Hasta__c = nuevo.FIN_Desde__c;
                    ajustes.add(vigente);
                }
            }
        }

        if (!ajustes.isEmpty()) {
            update ajustes;
        }
    }

    /**
     * @description Elimina registros futuros duplicados cuando
     * coinciden completamente con registros recién insertados.
     *
     * @param nuevosRegistros Registros insertados
     */
    @SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.ApexCRUDViolation')
    private static void eliminarDuplicados(List<FIN_PlazosPrecios__c> nuevosRegistros) {

        Datetime ahora = Datetime.now();

        Map<String, FIN_PlazosPrecios__c> nuevosMap = new Map<String, FIN_PlazosPrecios__c>();
        Set<String> clavesUnicas = new Set<String>();

        for (FIN_PlazosPrecios__c nuevo : nuevosRegistros) {
            if (todosCamposClaveLlenos(nuevo)
                && nuevo.FIN_Desde__c != null
                && nuevo.FIN_Hasta__c != null
                && nuevo.FIN_Desde__c > ahora) {

                String clave =
                    nuevo.FIN_Producto__c + '-' +
                    nuevo.FIN_PVP_Min__c + '-' +
                    nuevo.FIN_PVP_Max__c + '-' +
                    nuevo.FIN_Desde__c.format('yyyy-MM-dd') + '-' +
                    nuevo.FIN_Hasta__c.format('yyyy-MM-dd');

                nuevosMap.put(clave, nuevo);
                clavesUnicas.add(obtenerClave(nuevo));
            }
        }

        if (nuevosMap.isEmpty()) {
            return;
        }

        List<FIN_PlazosPrecios__c> existentes = [
            SELECT Id,
                   FIN_Producto__c,
                   FIN_PVP_Min__c,
                   FIN_PVP_Max__c,
                   FIN_Desde__c,
                   FIN_Hasta__c
            FROM FIN_PlazosPrecios__c
            WHERE FIN_Desde__c > :ahora
              AND FIN_Hasta__c > :ahora
              AND Id NOT IN :nuevosRegistros
            WITH SECURITY_ENFORCED
        ];

        List<FIN_PlazosPrecios__c> paraEliminar = new List<FIN_PlazosPrecios__c>();

        for (FIN_PlazosPrecios__c existente : existentes) {
            if (!clavesUnicas.contains(obtenerClave(existente))) {
                continue;
            }

            String claveExistente =
                existente.FIN_Producto__c + '-' +
                existente.FIN_PVP_Min__c + '-' +
                existente.FIN_PVP_Max__c + '-' +
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
                // Excepción controlada para evitar fallo del trigger
            }
        }
    }

    /**
     * @description Verifica que los campos clave estén completos.
     */
    private static Boolean todosCamposClaveLlenos(FIN_PlazosPrecios__c r) {
        return r.FIN_Producto__c != null
            && r.FIN_PVP_Min__c != null
            && r.FIN_PVP_Max__c != null;
    }

    /**
     * @description Genera la clave lógica única del registro.
     */
    private static String obtenerClave(FIN_PlazosPrecios__c r) {
        return r.FIN_Producto__c + '|' +
               r.FIN_PVP_Min__c + '|' +
               r.FIN_PVP_Max__c;
    }
}