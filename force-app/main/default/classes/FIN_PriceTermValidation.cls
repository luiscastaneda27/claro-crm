/**
 * @description Implementa funciones de validación de plazos y precios para
 *              integraciones OmniStudio (VlocityOpenInterface2).
 *  <Date>            <Author>             <Description>
    28-NOV-25         Eduardo Wentancur    Ajuste de PMD
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.AvoidGlobalModifier, PMD.StdCyclomaticComplexity')
global with sharing class FIN_PriceTermValidation implements vlocity_cmt.VlocityOpenInterface2 {

    /**
     * @description Punto de entrada estándar para VlocityOpenInterface2.
     * @param methodName Nombre del método expuesto a OmniStudio.
     * @param input Mapa de entrada con parámetros de negocio.
     * @param outMap Mapa de salida donde se escriben los resultados.
     * @param options Opciones adicionales de ejecución.
     * @return true si la invocación se procesa sin error lógico.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Boolean invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options

    ) {
        if (methodName.equals('getPlazosByPrice')) {
            List<String> result = getPlazosByPrice(input);
            String valueMax = getMaxPVPMaxAsString(input);
            Integer rangos = obtenerNumeroMayor(result);
            String getMinPVP = getMinPVPMinAsString(input);

            outMap.put('Plazos', result);
            outMap.put('MaxPVPMax', valueMax);
            outMap.put('numeroMayor', rangos);
            outMap.put('MinPVP', getMinPVP);
        } else if (methodName.equals('getPlazosByTasaInteres')) {
            List<Map<String, Object>> result = getPlazosByTasaInteres(input);
            outMap.put('PlazosTotal', result);
        }
        return true;
    }

    /**
     * @description Obtiene los nombres de los campos cuyo valor booleano es true
     *              dentro de la estructura DecisionMatrixAction.
     * @param input Mapa de entrada que contiene la clave 'DecisionMatrixAction'.
     * @return Lista de claves (plazos) que están en true.
     */
    public static List<String> getPlazosByPrice(Map<String, Object> input) {
        List<String> trueKeys = new List<String>();

        if (input == null || !input.containsKey('DecisionMatrixAction')) {
            return trueKeys;
        }

        Object obj = input.get('DecisionMatrixAction');
        if (!(obj instanceof List<Object>)) {
            return trueKeys;
        }

        for (Object item : (List<Object>) obj) {
            if (item instanceof Map<String, Object>) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                for (String key : itemMap.keySet()) {
                    Object val = itemMap.get(key);
                    if (val instanceof Boolean && (Boolean) val) {
                        trueKeys.add(key);
                    }
                }
            }
        }
        return trueKeys;
    }

    /**
     * @description Consulta FIN_PlazosPrecios__c para obtener el mayor FIN_PVP_Max__c
     *              vigente en el día para el producto enviado.
     * @param input Mapa de entrada que contiene 'Producto' y opcionalmente 'FechaActual' (ISO).
     * @return Valor máximo de PVP formateado con separadores de miles, o 'No disponible'.
     */
    public static String getMaxPVPMaxAsString(Map<String, Object> input) {
        String producto = (String) input.get('Producto');

        DateTime fechaActual = input != null && input.containsKey('FechaActual')
            ? DateTime.valueOfGmt(((String) input.get('FechaActual')).replace('T', ' ').removeEnd('Z'))
            : System.now();

        Date d = fechaActual.date();
        DateTime startOfDay = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = DateTime.newInstance(d, Time.newInstance(23, 59, 59, 999));

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_PlazosPrecios__c.isAccessible()) {
            return 'No disponible';
        }

        List<FIN_PlazosPrecios__c> regs = [
            SELECT FIN_PVP_Max__c, FIN_PVP_Min__c
            FROM FIN_PlazosPrecios__c
            WHERE FIN_Producto__c = :producto
              AND FIN_Desde__c <= :endOfDay
              AND FIN_Hasta__c >= :startOfDay WITH SECURITY_ENFORCED
        ];

        Decimal maxPvp = 0;
        for (FIN_PlazosPrecios__c r : regs) {
            String maxStr = r.FIN_PVP_Max__c;
            if (maxStr != null && maxStr.isNumeric()) {
                Decimal val = Decimal.valueOf(maxStr);
                if (val > maxPvp) {
                    maxPvp = val;
                }
            }
        }

        // Convertir el valor máximo de PVP en formato con separadores de miles
        return maxPvp > 0 ? maxPvp.format() : 'No disponible';
    }

    /**
     * @description Expande una lista de rangos de plazos (ej. "1-6") en una lista
     *              de opciones individuales (label/value).
     * @param input Mapa de entrada que contiene la clave 'Plazos'.
     * @return Lista de mapas con 'label' y 'value' para cada plazo.
     */
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts')
    public static List<Map<String, Object>> getPlazosByTasaInteres(Map<String, Object> input) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        if (input == null || !input.containsKey('Plazos') || !(input.get('Plazos') instanceof List<Object>)) {
            return result;
        }

        for (Object plazoObj : (List<Object>) input.get('Plazos')) {
            String plazo = String.valueOf(plazoObj);
            List<String> parts = plazo.split('-');

            if (parts.size() == 2) {
                try {
                    Integer startVal = Integer.valueOf(parts[0].trim());
                    Integer endVal = Integer.valueOf(parts[1].trim());
                    for (Integer i = startVal; i <= endVal; i++) {
                        result.add(new Map<String, Object>{
                            'label' => String.valueOf(i),
                            'value' => i
                        });
                    }
                } catch (Exception e) {
                    // Si el rango es inválido, se omite y se continúa con el siguiente
                    continue;
                }
            }
        }
        return result;
    }

    /**
     * @description Obtiene el límite superior más alto de una lista de rangos
     *              de plazos con formato "inicio-fin".
     * @param rangos Lista de rangos de plazos (por ejemplo: ["1-6","7-12"]).
     * @return El número mayor encontrado en los extremos superiores.
     */
    public static Integer obtenerNumeroMayor(List<String> rangos) {
        Integer maxNum = 0;
        if (rangos == null) {
            return maxNum;
        }

        for (String rango : rangos) {
            List<String> lim = rango.split('-');
            if (lim.size() == 2 && lim[1].trim().isNumeric()) {
                Integer m = Integer.valueOf(lim[1].trim());
                if (m > maxNum) {
                    maxNum = m;
                }
            }
        }
        return maxNum;
    }

        /**
     * @description Consulta FIN_PlazosPrecios__c para obtener el menor FIN_PVP_Min__c
     *              vigente para el producto enviado y plazos habilitados.
     * @param input Mapa de entrada que contiene 'Producto' y opcionalmente 'FechaActual' (ISO).
     * @return Valor mínimo de PVP formateado con separadores de miles, o 'No disponible'.
     */
    public static String getMinPVPMinAsString(Map<String, Object> input) {
        // Guard clause: sin input o sin producto -> nada que hacer
        if (input == null || !input.containsKey('Producto')) {
            return 'No disponible';
        }

        String producto = (String) input.get('Producto');

        // Obtener la fecha actual de entrada (si se proporciona, sino usar la fecha del sistema)
        DateTime fechaActual = input.containsKey('FechaActual')
            ? DateTime.valueOfGmt(((String) input.get('FechaActual')).replace('T', ' ').removeEnd('Z'))
            : System.now();

        Date d = fechaActual.date();
        DateTime startOfDay = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay   = DateTime.newInstance(d, Time.newInstance(23, 59, 59, 999));

        // Seguridad: validar permiso de lectura antes del SOQL
        if (!Schema.sObjectType.FIN_PlazosPrecios__c.isAccessible()) {
            return 'No disponible';
        }

        List<FIN_PlazosPrecios__c> regs = [
            SELECT FIN_PVP_Min__c, FIN_Producto__c, FIN_Desde__c, FIN_Hasta__c,
                FIN_Plazo_1_6__c, FIN_Plazo_7_12__c, FIN_Plazo_13_18__c,
                FIN_Plazo_19_24__c, FIN_Plazo_25_36__c
            FROM FIN_PlazosPrecios__c
            WHERE FIN_Producto__c = :producto
            AND (
                FIN_Plazo_1_6__c = 'SI' OR 
                FIN_Plazo_7_12__c = 'SI' OR
                FIN_Plazo_13_18__c = 'SI' OR
                FIN_Plazo_19_24__c = 'SI' OR
                FIN_Plazo_25_36__c = 'SI'
            ) WITH SECURITY_ENFORCED
        ];

        Decimal minPvp = Decimal.valueOf('999999999');

        for (FIN_PlazosPrecios__c r : regs) {
            DateTime startDate = r.FIN_Desde__c;
            DateTime endDate   = r.FIN_Hasta__c;

            // Si no está vigente, salteamos rápido
            if (startDate > endOfDay || endDate < startOfDay) {
                continue;
            }

            String minStr = r.FIN_PVP_Min__c;
            // Si el valor no es numérico, seguimos de largo
            if (minStr == null || !minStr.isNumeric()) {
                continue;
            }

            Decimal val = Decimal.valueOf(minStr);
            if (val < minPvp) {
                minPvp = val;
            }
        }

        return minPvp < Decimal.valueOf('999999999') ? minPvp.format() : 'No disponible';
    }

}