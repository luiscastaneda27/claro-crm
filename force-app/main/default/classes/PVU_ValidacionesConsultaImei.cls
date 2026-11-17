/**
 * @description  Validaciones para respuesta de Consulta IMEI (BDA/BDO) según documentación:
 *               - BDA Positiva: codigo "01" => Registrado | codigo "07" => No Registrado
 *               - BDO Negativo: si isReported=true o codigo="1" => hay reporte negativo
 *
 * @notes        Diseñada para invocarse desde OmniStudio (VlocityOpenInterface).
 *               Entrada esperada: JSON completo (String) o Map ya parseado.
 *
 *               methodName soportado: "validarConsultaImei"
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.NcssMethodCount,PMD.AvoidDeeplyNestedIfStmts')
global without sharing class PVU_ValidacionesConsultaImei implements vlocity_cmt.VlocityOpenInterface {

    // === Constantes ===
    private static final String METHOD_VALIDAR = 'validarConsultaImei';

    private static final String BDA_COD_REGISTRADO    = '01';
    private static final String BDA_COD_NO_REGISTRADO = '07';

    // Keys candidatas donde suele venir el JSON desde OmniStudio/IP
    private static final List<String> JSON_KEYS_CANDIDATAS = new List<String>{
        'json', 'payload', 'response', 'responseBody', 'body', 'jsonConsultaImei', 'consultaImeiJson'
    };

    /**
     * @description Punto de entrada para invocaciones desde Vlocity/OmniStudio.
     * @param methodName Nombre del método solicitado desde OmniScript/IP.
     * @param inputMap   Parámetros de entrada (JSON o payload transformado).
     * @param outMap     Mapa de salida a devolver a OmniStudio.
     * @param options    Mapa de opciones adicionales (opcional).
     * @return true si la invocación se procesó correctamente, false si el método no es soportado o hubo error.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Boolean invokeMethod(
        String methodName,
        Map<String,Object> inputMap,
        Map<String,Object> outMap,
        Map<String,Object> options
    ) {
        Boolean result = true;

        try {
            if (METHOD_VALIDAR.equalsIgnoreCase(methodName)) {
                validarConsultaImei(inputMap, outMap, options);
            } else {
                result = false;
                outMap.put('esValido', false);
                outMap.put('mensaje', 'Método no soportado: ' + methodName);
                outMap.put('accionSugerida', 'ERROR_METODO');
            }
        } catch (Exception e) {
            outMap.put('esValido', false);
            outMap.put('mensaje', 'Error en ejecución: ' + e.getMessage());
            outMap.put('linea', e.getLineNumber());
            outMap.put('accionSugerida', 'ERROR_EXCEPCION');
            result = false;
        }

        return result;
    }

    // =========================
    // ====== Método main ======
    // =========================

    /**
     * @description Valida respuesta de consulta IMEI y determina si está registrado.
     *              Basado en:
     *              - BDA Positiva codigo: 01 registrado, 07 no registrado
     *              Además expone:
     *              - tieneReporteNegativo (BDO Negativo)
     *              - accionSugerida (para OmniScript/IP)
     * @param inputMap Mapa de entrada que contiene el payload original.
     * @param outMap   Mapa de salida donde se coloca el resultado de la validación.
     * @param options  Mapa de opciones adicionales (no obligatorio).
     */
    private static void validarConsultaImei(
        Map<String,Object> inputMap,
        Map<String,Object> outMap,
        Map<String,Object> options
    ) {

        // 1) Obtener payload como Map
        Map<String, Object> payload = getPayloadAsMap(inputMap);

        // 2) Validar estructura: customer.product[]
        Map<String, Object> customer = asMap(payload.get('customer'));
        if (customer == null) {
            fail(outMap, 'Payload inválido: no viene nodo "customer".');
            return;
        }

        List<Object> products = asList(customer.get('product'));
        if (products == null || products.isEmpty()) {
            fail(outMap, '"customer.product" vacío o inexistente.');
            return;
        }

        // 3) Procesar productos (por si viene más de uno)
        List<Map<String, Object>> resultados = new List<Map<String, Object>>();
        Boolean algunoDecidible = false;

        for (Object p : products) {
            Map<String, Object> prod = asMap(p);
            if (prod == null) {
                continue;
            }

            Map<String, Object> resProd = evaluarProducto(prod);
            resultados.add(resProd);

            if (asBoolean(resProd.get('esValido')) == true) {
                algunoDecidible = true;
            }
        }

        // 4) Salida
        outMap.put('esValido', algunoDecidible);
        outMap.put('productos', resultados);

        // Atajo: si hay un solo producto, promovemos campos al top-level
        if (resultados.size() == 1) {
            Map<String, Object> r = resultados[0];
            outMap.put('imei', r.get('imei'));
            outMap.put('bdaCodigo', r.get('bdaCodigo'));
            outMap.put('estaRegistrado', r.get('estaRegistrado'));
            outMap.put('accionSugerida', r.get('accionSugerida'));
            outMap.put('tieneReporteNegativo', r.get('tieneReporteNegativo'));
            outMap.put('mensaje', r.get('mensaje'));
            outMap.put('bdoCodigo', r.get('bdoCodigo'));
        } else {
            outMap.put(
                'mensaje',
                algunoDecidible
                    ? 'Validación completada para ' + resultados.size() + ' productos.'
                    : 'No se pudo determinar estado (ningún producto con BDA codigo 01/07).'
            );
            outMap.put('accionSugerida', algunoDecidible ? 'OK_MULTIPRODUCTO' : 'ERROR_INDETERMINADO');
        }
    }

    // =========================
    // ===== Lógica core =======
    // =========================

    /**
     * @description Evalúa un producto y decide registrado/no registrado usando BDA (01/07)
     *              y aplica el guardrail de BDO Negativo.
     * @param prod Nodo "product" del payload a evaluar.
     * @return Mapa con resultado de la evaluación (esValido, estaRegistrado, accionSugerida,
     *         tieneReporteNegativo, imei, códigos BDA/BDO, etc.).
     */
    private static Map<String, Object> evaluarProducto(Map<String, Object> prod) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('esValido', false);

        // Campos útiles
        out.put('productId', prod.get('id'));
        out.put('status', prod.get('status'));

        // Leer productCharacteristic
        List<Object> chars = asList(prod.get('productCharacteristic'));
        Map<String, Object> blacklistWrap = null;
        String imei = null;
        Boolean isValid = null;

        if (chars != null) {
            for (Object c : chars) {
                Map<String, Object> ch = asMap(c);
                if (ch == null) {
                    continue;
                }

                String name = (String) ch.get('name');
                Object val = ch.get('value');

                if ('imei'.equalsIgnoreCase(name)) {
                    imei = (val == null) ? null : String.valueOf(val);
                } else if ('isValid'.equalsIgnoreCase(name)) {
                    if (val instanceof Boolean) {
                        isValid = (Boolean) val;
                    } else if (val instanceof String) {
                        isValid = asBoolean(val);
                    }
                } else if ('blacklist'.equalsIgnoreCase(name)) {
                    blacklistWrap = asMap(val);
                } else if ('brand'.equalsIgnoreCase(name)) {
                    out.put('brand', (val == null) ? null : String.valueOf(val));
                } else if ('model'.equalsIgnoreCase(name)) {
                    out.put('model', (val == null) ? null : String.valueOf(val));
                }
            }
        }

        out.put('imei', imei);
        out.put('isValid', isValid);

        if (blacklistWrap == null) {
            out.put('mensaje', 'Sin "blacklist" en productCharacteristic; no se puede evaluar BDA (01/07).');
            out.put('accionSugerida', 'ERROR_PAYLOAD');
            return out;
        }

        // ====== BDA Positiva ======
        Map<String, Object> bdaPositivo = asMap(blacklistWrap.get('bdaPositivo'));
        String bdaCodigo = (bdaPositivo == null) ? null : asString(bdaPositivo.get('codigo'));
        String bdaCodigoError = (bdaPositivo == null) ? null : asString(bdaPositivo.get('codigoError'));
        String bdaDesc = (bdaPositivo == null) ? null : asString(bdaPositivo.get('descripcionError'));

        out.put('bdaCodigo', bdaCodigo);
        out.put('bdaDescripcion', bdaDesc);
        if (bdaCodigoError != null) {
            out.put('bdaCodigoError', bdaCodigoError);
        }

        // ====== BDO Negativo (guardrail) ======
        Map<String, Object> bdoNegativo = asMap(blacklistWrap.get('bdoNegativo'));
        Boolean tieneReporteNegativo = false;
        String bdoCodigo = null;

        if (bdoNegativo != null) {
            bdoCodigo = asString(bdoNegativo.get('codigo'));
            Boolean isReported = asBoolean(bdoNegativo.get('isReported'));

            // Según doc/práctica: codigo="1" o isReported=true => reporte negativo
            if (isReported == true || bdoCodigo == '1') {
                tieneReporteNegativo = true;
            }
        }

        out.put('bdoCodigo', bdoCodigo);
        out.put('tieneReporteNegativo', tieneReporteNegativo);

        // ========= Regla maestra =========
        if (BDA_COD_REGISTRADO.equals(bdaCodigo)) {
            out.put('esValido', true);
            out.put('estaRegistrado', true);
            out.put('accionSugerida', 'CONTINUAR_PUNTO_2');
            out.put('mensaje', buildMsg('Registrado (BDA=01).', tieneReporteNegativo));
            return out;

        } else if (BDA_COD_NO_REGISTRADO.equals(bdaCodigo)) {
            out.put('esValido', true);
            out.put('estaRegistrado', false);
            out.put('accionSugerida', (tieneReporteNegativo ? 'REGISTRAR_CON_ALERTA_BDO' : 'REGISTRAR_EN_BDA_BDO'));
            out.put('mensaje', buildMsg('No Registrado (BDA=07).', tieneReporteNegativo));
            return out;
        }

        // ========= Indeterminado =========
        out.put('estaRegistrado', null);
        if (bdaCodigoError != null) {
            out.put(
                'mensaje',
                'No se pudo determinar estado: BDA Positiva devolvió error (' +
                bdaCodigoError +
                ') ' +
                safe(bdaDesc)
            );
            out.put('accionSugerida', 'ERROR_INTEGRACION_BDA');
        } else {
            out.put(
                'mensaje',
                'No se pudo determinar estado: BDA Positiva sin codigo 01/07. codigo=' +
                safe(bdaCodigo) +
                ' ' +
                safe(bdaDesc)
            );
            out.put('accionSugerida', 'ERROR_INDETERMINADO');
        }

        return out;
    }

    private static String buildMsg(String base, Boolean tieneReporteNegativo) {
        if (tieneReporteNegativo == true) {
            return base + ' Atención: BDO Negativo indica reporte (isReported/codigo). Revisar antes de avanzar.';
        }
        return base + ' Sin reportes negativos en BDO (o no informado).';
    }

    // =========================
    // ===== Helpers ===========
    // =========================

    /**
     * @description Obtiene el JSON de inputMap como Map.
     *              Evita el bug de "JSON" pisado usando System.JSON siempre.
     * @param inputMap Mapa de entrada proveniente de OmniStudio/IP.
     * @return Mapa deserializado que representa el payload de consulta IMEI.
     */
    private static Map<String, Object> getPayloadAsMap(Map<String,Object> inputMap) {
        if (inputMap == null) {
            return new Map<String, Object>();
        }

        // 1) Si ya viene un Map directo en alguna key típica
        for (String k : JSON_KEYS_CANDIDATAS) {
            Object v = inputMap.get(k);
            if (v instanceof Map<String, Object>) {
                return (Map<String, Object>) v;
            }
        }

        // 2) Si viene como String JSON en alguna key típica
        String jsonStr = null;
        for (String k : JSON_KEYS_CANDIDATAS) {
            Object v = inputMap.get(k);
            if (v instanceof String && String.isNotBlank((String) v)) {
                jsonStr = (String) v;
                break;
            }
        }

        // 3) Si inputMap ya parece ser el payload (trae customer), úsalo como payload
        if (String.isBlank(jsonStr) && inputMap.containsKey('customer')) {
            return (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(inputMap));
        }

        // 4) Si no hay string, último recurso: serializar inputMap entero
        if (String.isBlank(jsonStr)) {
            return (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(inputMap));
        }

        // 5) Parse del string
        return (Map<String, Object>) System.JSON.deserializeUntyped(jsonStr);
    }

    private static void fail(Map<String,Object> outMap, String msg) {
        outMap.put('esValido', false);
        outMap.put('mensaje', msg);
        outMap.put('accionSugerida', 'ERROR_PAYLOAD');
    }

    private static Map<String, Object> asMap(Object o) {
        return (o instanceof Map<String, Object>) ? (Map<String, Object>) o : null;
    }

    private static List<Object> asList(Object o) {
        return (o instanceof List<Object>) ? (List<Object>) o : null;
    }

    private static String asString(Object o) {
        return (o == null) ? null : String.valueOf(o);
    }

    /**
     * @description Convierte un valor genérico a Boolean, soportando Boolean y String 'true'/'false'.
     * @param o Valor proveniente del payload.
     * @return Boolean equivalente o null si no se puede interpretar.
     */
    private static Boolean asBoolean(Object o) {
        if (o instanceof Boolean) {
            return (Boolean) o;
        }
        if (o instanceof String) {
            String s = ((String)o).trim().toLowerCase();
            if (s == 'true') {
                return true;
            }
            if (s == 'false') {
                return false;
            }
        }
        return null;
    }

    private static String safe(String s) {
        return String.isBlank(s) ? '' : ('- ' + s);
    }
}