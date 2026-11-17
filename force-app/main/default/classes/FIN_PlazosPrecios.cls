/**
 * @description Clase de integración Vlocity que permite obtener
 * los plazos habilitados según producto, PVP mínimo y fecha vigente.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidGlobalModifier,PMD.ExcessiveParameterList')
global with sharing class FIN_PlazosPrecios implements vlocity_cmt.VlocityOpenInterface2 {

    /**
     * @description Método estándar de entrada de Vlocity Open Interface.
     * Enruta la ejecución al método correspondiente según methodName.
     *
     * @param methodName Nombre del método a invocar
     * @param input Mapa de parámetros de entrada
     * @param outMap Mapa de salida
     * @param options Opciones adicionales
     * @return true si la invocación se ejecuta correctamente
     */
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        if (methodName == 'obtenerPlazos') {
            List<Map<String, Object>> result = obtenerPlazos(input);
            outMap.put('result', result);
        }
        return true;
    }

    /**
     * @description Obtiene los plazos disponibles para un producto en función
     * del PVP mínimo recibido y la fecha actual.
     *
     * @param inputMap Mapa con Producto, PVPMin y FechaActual
     * @return Lista de mapas con los plazos habilitados
     */
    public static List<Map<String, Object>> obtenerPlazos(Map<String, Object> inputMap) {

        // 1) Leer inputs
        String producto = String.valueOf(inputMap.get('Producto')).trim();
        Decimal pvpMin  = Decimal.valueOf(String.valueOf(inputMap.get('PVPMin')));

        // 2) Parsear FechaActual (ISO-8601)
        String iso = String.valueOf(inputMap.get('FechaActual'));
        iso = iso.replace('T', ' ');
        if (iso.endsWith('Z')) {
            iso = iso.substring(0, iso.length() - 1);
        }
        DateTime fechaActual = DateTime.valueOfGmt(iso);

        // Calcular rango del día completo para comparar solo la fecha
        Date fecha = fechaActual.date();
        DateTime startOfDay = DateTime.newInstance(fecha, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay   = DateTime.newInstance(fecha, Time.newInstance(23, 59, 59, 999));

        // 3) Traer registros vigentes para el producto
        List<FIN_PlazosPrecios__c> posibles = [
            SELECT FIN_PVP_Min__c, FIN_PVP_Max__c,
                   FIN_Plazo_1_6__c, FIN_Plazo_7_12__c, FIN_Plazo_13_18__c,
                   FIN_Plazo_19_24__c, FIN_Plazo_25_36__c,
                   FIN_Desde__c, FIN_Hasta__c
            FROM FIN_PlazosPrecios__c
            WHERE FIN_Producto__c = :producto
              AND FIN_Desde__c <= :endOfDay
              AND FIN_Hasta__c >= :startOfDay
            WITH SECURITY_ENFORCED
        ];

        // 3.1) Obtener valor máximo parametrizado desde Custom Metadata
        InterfaceSettings__mdt interfaceSetting = InterfaceSettings__mdt.getInstance('MaxPVP');
        String maxValorDefault = interfaceSetting.IdCode__c;

        // 4) Filtrar por rango de PVP y mapear resultados
        List<Map<String, Object>> resultados = new List<Map<String, Object>>();
        for (FIN_PlazosPrecios__c reg : posibles) {

            Decimal minRegistro = Decimal.valueOf(reg.FIN_PVP_Min__c);
            Decimal maxRegistro = reg.FIN_PVP_Max__c == 'Adelante'
                ? Decimal.valueOf(maxValorDefault)
                : Decimal.valueOf(reg.FIN_PVP_Max__c);

            if (pvpMin >= minRegistro && pvpMin <= maxRegistro) {
                resultados.add(new Map<String, Object>{
                    '1-6'   => reg.FIN_Plazo_1_6__c  == 'SI',
                    '7-12'  => reg.FIN_Plazo_7_12__c == 'SI',
                    '13-18' => reg.FIN_Plazo_13_18__c == 'SI',
                    '19-24' => reg.FIN_Plazo_19_24__c == 'SI',
                    '25-36' => reg.FIN_Plazo_25_36__c == 'SI',
                    'PVPMax'=> reg.FIN_PVP_Max__c
                });
            }
        }
        return resultados;
    }
}