/**
* @description       : Clase para filtrar los asset 
* @author            : Eduardo Wentancur
* @last modified on  : 11-19-2024
* @last modified by  : 
**/
global with sharing class PVU_AdditionalServicesData implements vlocity_cmt.VlocityOpenInterface2 {

    
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        if (outMap == null) outMap = new Map<String, Object>();

        if (String.isBlank(methodName)) {
            outMap.put('error', 'methodName vacío');
            return false;
        }
		// 1) Solo mergear assets + consumos
        if (methodName == 'mergeAssetsConsumos') {
            List<Map<String, Object>> merged = mergeAssetsConsumosFromInput(input);
            outMap.put('listAsset', merged);
            return true;
        }
        if (methodName == 'filterAdditionalServicesJson') {
            // Se espera que "input" venga con la lista (ver extractListFromInput)
            List<Map<String, Object>> items = extractListFromInput(input);
            List<Map<String, Object>> result = filterAdditionalServices(items);
            outMap.put('listAsset', result);
            return true;
        }

        outMap.put('error', 'Método no soportado: ' + methodName);
        return false;
    }

        /*******************************************************************************************************
    * @description 
    * @param methodName nombre del metodo
    * @param inputMap obtiene los parametros declarados
    * @param outMap Mapa que devuelve el resultado
    * @param options parámetros adicionales
    * @return Metodo
    */
    public static List<Map<String, Object>> filterAdditionalServices(List<Map<String, Object>> items) {
        if (items == null) return new List<Map<String, Object>>();

        List<Map<String, Object>> outList = new List<Map<String, Object>>();
        for (Map<String, Object> row : items) {
            String subtipo = getString(row, 'Subtipo');

            if ('Datos'.equalsIgnoreCase(subtipo)) {
                if (validateDatos(row)) outList.add(row);
                continue;
            }
            if ('LDI'.equalsIgnoreCase(subtipo)) {
                if (validateLDI(row)) outList.add(row);
                continue;
            }
            if ('Roaming Internacional'.equalsIgnoreCase(subtipo) || 'Roaming'.equalsIgnoreCase(subtipo)) {
                if (validateRoaming(row)) outList.add(row);
                continue;
            }

            // Otros subtipos (ej. OTT) pasan tal cual
            outList.add(row);
        }
        return outList;
    }

    // --------------------------------------------
    // Variante: entrada como JSON crudo (opcional)
    // --------------------------------------------
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> filterAdditionalServicesJson(String rawJson) {
        if (String.isBlank(rawJson)) return new List<Map<String, Object>>();
        Object parsed = JSON.deserializeUntyped(rawJson);
        if (!(parsed instanceof List<Object>)) return new List<Map<String, Object>>();

        List<Map<String, Object>> input = new List<Map<String, Object>>();
        for (Object o : (List<Object>) parsed) {
            if (o instanceof Map<String, Object>) input.add((Map<String, Object>) o);
        }
        return filterAdditionalServices(input);
    }

    // ---------------------------------
    // Validaciones por subtipo (ajustables)
    // ---------------------------------
    private static Boolean validateDatos(Map<String, Object> row) {
        Boolean vencido     = getBoolean(row, 'vencido');
        Boolean tieneDatos  = getBoolean(row, 'tieneDatos');
        // Regla: no vencido y con saldo de datos
        return (vencido == false) && (tieneDatos == true);
    }

    private static Boolean validateLDI(Map<String, Object> row) {
        Boolean vencido = getBoolean(row, 'vencido');
        Boolean tieneDatos  = getBoolean(row, 'tieneDatos');

        return (vencido == false) && (tieneDatos == true);
    }

    private static Boolean validateRoaming(Map<String, Object> row) {
        Boolean vencido = getBoolean(row, 'vencido');
        return (vencido == false);
    }

    // --------------------
    // Helpers de conversión
    // --------------------
    private static String getString(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) return null;
        return String.valueOf(m.get(key));
    }
    private static Boolean getBoolean(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) return false;
        Object v = m.get(key);
        if (v instanceof Boolean) return (Boolean) v;
        String s = String.valueOf(v);
        return 'true'.equalsIgnoreCase(s) || '1'.equals(s);
    }

    // ----------------------------------------------------------------------
    // Extrae la lista desde "input" del OpenInterface (viene como una lista)
    // Soporta varias convenciones: items, list, records, raw(JSON), etc.
    // ----------------------------------------------------------------------
    private static List<Map<String, Object>> extractListFromInput(Map<String, Object> input) {
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        if (input == null || input.isEmpty()) return items;

        // 1) Claves típicas donde puede venir la lista
        List<String> candidates = new List<String>{ 'items', 'list', 'records', 'data', 'listAsset' };
        for (String k : candidates) {
            if (input.containsKey(k) && input.get(k) instanceof List<Object>) {
                for (Object o : (List<Object>) input.get(k)) {
                    if (o instanceof Map<String, Object>) items.add((Map<String, Object>) o);
                }
                if (!items.isEmpty()) return items;
            }
        }

        // 2) Si te mandan la lista como JSON crudo en alguna clave
        List<String> jsonCandidates = new List<String>{ 'raw', 'json', 'payload' };
        for (String k : jsonCandidates) {
            if (input.containsKey(k) && input.get(k) != null) {
                String raw = String.valueOf(input.get(k));
                List<Map<String, Object>> parsed = filterAdditionalServicesJson(raw);
                if (!parsed.isEmpty()) return parsed;
            }
        }

        // 3) Si te pasan directamente una List<Map> bajo cualquier clave (fallback)
        for (String k : input.keySet()) {
            Object v = input.get(k);
            if (v instanceof List<Object>) {
                for (Object o : (List<Object>) v) {
                    if (o instanceof Map<String, Object>) items.add((Map<String, Object>) o);
                }
                if (!items.isEmpty()) return items;
            }
        }

        return items;
    }
    
       public static List<Map<String, Object>> mergeAssetsConsumosFromInput(Map<String, Object> input) {
        List<Map<String, Object>> assets   = extractNamedList(input,
            new List<String>{'assets', 'DRTAdditionalServicesDatasets', 'listAsset'});
        List<Map<String, Object>> consumos = extractNamedList(input,
            new List<String>{'consumos', 'LoopServices:consumos', 'dataConsumos', 'recordsConsumos'});

        return mergeAssetsConsumos(assets, consumos);
    }

    public static List<Map<String, Object>> mergeAssetsConsumos(
        List<Map<String, Object>> assets,
        List<Map<String, Object>> consumos
    ) {
        if (assets == null)   assets = new List<Map<String, Object>>();
        if (consumos == null) consumos = new List<Map<String, Object>>();

        // Index de consumos por clave compuesta msisdn|productCode
        Map<String, List<Map<String, Object>>> idx = new Map<String, List<Map<String, Object>>>();
        for (Object o : consumos) {
            if (!(o instanceof Map<String, Object>)) continue;
            Map<String, Object> c = (Map<String, Object>) o;

            String msisdn      = getString(c, 'msisdn');
            String prodConsumo = getString(c, 'productCode');
            String key         = makeKey(msisdn, prodConsumo);
            if (String.isBlank(key)) continue;

            if (!idx.containsKey(key)) idx.put(key, new List<Map<String, Object>>());
            idx.get(key).add(c);
        }

        // Merge sobre assets
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Object o : assets) {
            if (!(o instanceof Map<String, Object>)) continue;
            Map<String, Object> a = (Map<String, Object>) o;

            String numeroTelefono = getString(a, 'numeroTelefono');
            String prodAsset      = getString(a, 'productCode');
            String key            = makeKey(numeroTelefono, prodAsset);

            if (!String.isBlank(key) && idx.containsKey(key)) {
                for (Map<String, Object> c : idx.get(key)) {
                    // Mezclamos campos de consumo dentro del asset.
                    // Si un campo ya existe en el asset, lo sobreescribe con el valor de consumo.
                    for (String k : c.keySet()) {
                        a.put(k, c.get(k));
                    }
                }
            }

            result.add(a);
        }

        return result;
    }
    private static String makeKey(String a, String b) {
        String s1 = String.isBlank(a) ? '' : a.trim();
        String s2 = String.isBlank(b) ? '' : b.trim();
        if (String.isBlank(s1) || String.isBlank(s2)) return null;
        return s1 + '|' + s2;
    }
    // ----------------------------------------------------------------------
    // NUEVO: extrae una lista por nombres posibles (para assets y consumos)
    // ----------------------------------------------------------------------
    private static List<Map<String, Object>> extractNamedList(Map<String, Object> input, List<String> names) {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        if (input == null || input.isEmpty()) return out;
        for (String name : names) {
            if (input.containsKey(name) && input.get(name) instanceof List<Object>) {
                for (Object o : (List<Object>) input.get(name)) {
                    if (o instanceof Map<String, Object>) out.add((Map<String, Object>) o);
                }
                if (!out.isEmpty()) return out;
            }
        }
        return out;
    }

}