/**
 * @description       Clase que construye el body de contrato de Fianza
 *                    y lo expone como una Open Interface para OmniStudio.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessiveParameterList, PMD.NcssMethodCount, PMD.CyclomaticComplexity')
global with sharing class FIN_SendContractFianza implements vlocity_cmt.VlocityOpenInterface2 {
    
    /**
     * @description Conjunto de claves monetarias que deben ir con el signo '$'
     *              antepuesto en el valor.
     */
    private static final Set<String> CURRENCY_KEYS = new Set<String>{
        'ValorProductoFinanciado',
        'CuotaProductoFinanciado',
        'ValorFinanciadoFianza',
        'CuotaFianza',
        'ValorTotalFinanciadoFianza',
        'ValorCuotaMensualFinanciado'
    };
    
    /**
     * @description Punto de entrada requerido por Vlocity Open Interface.
     *              Despacha la ejecución según el nombre del método.
     * @param methodName Nombre del método a invocar (por ejemplo, 'sendContractFianza').
     * @param input      Mapa de entrada recibido desde la IP/OmniScript.
     * @param outMap     Mapa de salida donde se deben colocar los resultados.
     * @param options    Mapa de opciones adicionales (si aplica).
     * @return           true si la invocación fue resuelta sin errores.
     */
    public Boolean invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        if (methodName == 'sendContractFianza') {
            sendContractFianza(input, outMap, options);
        }
        return true;
    }
    
    /**
     * @description Construye el nodo bodyFianza con la estructura requerida
     *              para el envío del contrato de Fianza.
     * @param input   Mapa de entrada recibido desde la IP/OmniScript.
     * @param outMap  Mapa de salida donde se agrega el nodo 'bodyFianza'.
     * @param options Mapa de opciones adicionales (no utilizado actualmente).
     */
    public void sendContractFianza(
        Map<String, Object> input,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        // 1) Tomamos los nodos principales del input
        Map<String, Object> body       = (Map<String, Object>) input.get('body');
        Map<String, Object> fianzaBody = (Map<String, Object>) input.get('fianzaBody');
        
        if (body == null) {
            return;
        }
        
        // 2) Obtenemos el nodo Fianza
        Map<String, Object> fianza = fianzaBody != null
            ? (Map<String, Object>) fianzaBody.get('Fianza')
            : null;
        
        // 2.1) Tomamos la tipoVenta que nos mandan
        Object tipoVentaInput = input.get('tipoVenta');
        if (tipoVentaInput == null && fianza != null && fianza.containsKey('tipoVenta')) {
            tipoVentaInput = fianza.get('tipoVenta');
        }
        
        // 3) Obtenemos el map/mapEntry existente
        Map<String, Object> mapWrapper = (Map<String, Object>) body.get('map');
        if (mapWrapper == null) {
            mapWrapper = new Map<String, Object>();
        }
        
        List<Object> mapEntries = (List<Object>) mapWrapper.get('mapEntry');
        if (mapEntries == null) {
            mapEntries = new List<Object>();
            mapWrapper.put('mapEntry', mapEntries);
        }
        
        // 4) Agregamos los campos de Fianza como nuevos mapEntry
        addMapEntryFromFianza(mapEntries, 'ValorFianzaIva',              fianza);
        addMapEntryFromFianza(mapEntries, 'ValorProductoFinanciado',     fianza);
        addMapEntryFromFianza(mapEntries, 'CuotaProductoFinanciado',     fianza);
        addMapEntryFromFianza(mapEntries, 'ValorFinanciadoFianza',       fianza);
        addMapEntryFromFianza(mapEntries, 'CuotaFianza',                 fianza);
        addMapEntryFromFianza(mapEntries, 'ValorTotalFinanciadoFianza',  fianza);
        addMapEntryFromFianza(mapEntries, 'NumeroMes',                   fianza);
        addMapEntryFromFianza(mapEntries, 'ValorCuotaMensualFinanciado', fianza);
        
        // 4.1) Actualizamos/creamos TipoVenta en base al parámetro tipoVenta
        if (tipoVentaInput != null) {
            upsertMapEntry(mapEntries, 'TipoVenta', String.valueOf(tipoVentaInput));
        }
        
        // 5) Armamos el nodo bodyFianza con la estructura requerida
        Map<String, Object> bodyFianza = new Map<String, Object>();
        
        bodyFianza.put('huellaYFirmaCliente', body.get('huellaYFirmaCliente'));
        bodyFianza.put('map', mapWrapper);
        
        Object targetValue = body.get('target');
        bodyFianza.put('target', targetValue != null ? String.valueOf(targetValue) : null);
        
        // 6) Devolvemos TODO bajo el nodo bodyFianza
        outMap.put('bodyFianza', bodyFianza);
    }
    
    /**
     * @description Agrega un mapEntry al listado a partir de un valor
     *              en el nodo Fianza. Si la clave es monetaria, antepone '$'.
     * @param mapEntries Lista de mapEntry donde se agregará el nuevo elemento.
     * @param keyName    Nombre de la clave en el nodo Fianza y en el mapEntry.
     * @param fianza     Nodo Fianza que contiene los valores originales.
     */
    private void addMapEntryFromFianza(
        List<Object> mapEntries,
        String keyName,
        Map<String, Object> fianza
    ) {
        if (fianza == null || !fianza.containsKey(keyName)) {
            return;
        }
        
        Object rawValue = fianza.get(keyName);
        String strValue = rawValue != null ? String.valueOf(rawValue) : null;
        
        // Si es campo monetario, anteponer $
        if (strValue != null && CURRENCY_KEYS.contains(keyName)) {
            if (!strValue.startsWith('$')) {
                strValue = '$' + strValue;
            }
        }
        
        Map<String, Object> entry = new Map<String, Object>();
        entry.put('key', keyName);
        entry.put('value', strValue);
        
        mapEntries.add(entry);
    }
    
    /**
     * @description Crea o actualiza un mapEntry para la clave indicada.
     *              Si ya existe un mapEntry con esa key, sólo actualiza el value.
     * @param mapEntries Lista de mapEntry a inspeccionar/actualizar.
     * @param keyName    Clave a buscar dentro de los mapEntry.
     * @param value      Valor a asignar a la clave.
     */
    private void upsertMapEntry(
        List<Object> mapEntries,
        String keyName,
        String value
    ) {
        for (Object o : mapEntries) {
            Map<String, Object> entry = (Map<String, Object>) o;
            if (entry != null && entry.containsKey('key') && (String) entry.get('key') == keyName) {
                entry.put('value', value);
                return;
            }
        }
        
        Map<String, Object> newEntry = new Map<String, Object>();
        newEntry.put('key', keyName);
        newEntry.put('value', value);
        mapEntries.add(newEntry);
    }
}