global class FINPlazoByPaymentInitial implements vlocity_cmt.VlocityOpenInterface2 {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        if (methodName.equals('obtenerPlazosValidos')) {
            List<String> result = obtenerPlazosValidos(input);
            Integer rangos = obtenerNumeroMayor(result);
            outMap.put('Plazos_Validos_HDC', result);  // Devuelve los plazos en rangos
            outMap.put('Numero_Mayor', rangos);
        }
        return true;
    }
    
    public static List<String> obtenerPlazosValidos(Map<String, Object> data) {
        List<Integer> plazosValidos = new List<Integer>();
        
        if (data.containsKey('PaymentInitial')) {
            Map<String, Object> paymentInitial = (Map<String, Object>) data.get('PaymentInitial');
            if (paymentInitial.containsKey('Product') && paymentInitial.containsKey('Quote')) {
                Map<String, Object> product = (Map<String, Object>) paymentInitial.get('Product');
                Map<String, Object> quote = (Map<String, Object>) paymentInitial.get('Quote');
                
                if (product.containsKey('TipoDeProducto')) {
                    String tipoDeProducto = (String) product.get('TipoDeProducto');
                    
                    if (tipoDeProducto.equals('Terminales') && quote.containsKey('PagosInicialesTerminales')) {
                        Map<String, Object> terminales = (Map<String, Object>) quote.get('PagosInicialesTerminales');
                        plazosValidos.addAll(validarPagosTerminales(terminales));
                    } else if (!tipoDeProducto.equals('Terminales') && quote.containsKey('PagosInicialesTecnologia')) {
                        Map<String, Object> tecnologia = (Map<String, Object>) quote.get('PagosInicialesTecnologia');
                        plazosValidos.addAll(validarPagosTecnologia(tecnologia));
                    }
                }
            }
        }
        
        plazosValidos.sort(); // Ordenar la lista de plazos válidos antes de retornarla
        return plazosValidos.isEmpty() ? new List<String>() : agruparEnRangos(plazosValidos);
    }
    
    private static List<Integer> validarPagosTecnologia(Map<String, Object> pagos) {
        List<Integer> plazos = new List<Integer>();
        
        for (String key : pagos.keySet()) {
            if (esPagoValido(pagos.get(key))) {
                String plazoStr = key.replaceAll('\\D+', ''); // Extrae solo los números
                if (!String.isBlank(plazoStr)) {
                    plazos.add(Integer.valueOf(plazoStr));
                }
            }
        }
        return plazos;
    }

    private static List<Integer> validarPagosTerminales(Map<String, Object> pagos) {
        List<Integer> plazos = new List<Integer>();
        Map<String, Integer> rangosTerminales = new Map<String, Integer>{
            'pagoInicialTerminales_1' => 6,
            'pagoInicialTerminales_6' => 12,
            'pagoInicialTerminales_12' => 18,
            'pagoInicialTerminales_18' => 24,
            'pagoInicialTerminales_24' => 36
        };

        for (String key : rangosTerminales.keySet()) {
            if (pagos.containsKey(key) && esPagoValido(pagos.get(key))) {
                plazos.add(rangosTerminales.get(key));
            }
        }
        return plazos;
    }

    private static Boolean esPagoValido(Object pago) {
        String valor = String.valueOf(pago);
        return String.isNotBlank(valor) && valor != '100' && valor != 'null';
    }

    private static List<String> agruparEnRangos(List<Integer> plazos) {
        Set<String> rangos = new Set<String>();

        for (Integer plazo : plazos) {
            if (plazo >= 1 && plazo <= 6) {
                rangos.add('1-6');
            } else if (plazo >= 7 && plazo <= 12) {
                rangos.add('7-12');
            } else if (plazo >= 13 && plazo <= 18) {
                rangos.add('13-18');
            } else if (plazo >= 19 && plazo <= 24) {
                rangos.add('19-24');
            } else if (plazo >= 25 && plazo <= 36) {
                rangos.add('25-36');
            }
        }

        List<String> listaRangos = new List<String>(rangos);
        listaRangos.sort(); // Ordenar la lista de rangos antes de retornarla
        return listaRangos;
    }
    
    public static Integer obtenerNumeroMayor(List<String> rangos) {
    Integer maxNumero = 0;
    
    for (String rango : rangos) {
        List<String> limites = rango.split('-'); // Divide el rango en dos números
        if (limites.size() == 2) {
            Integer maxRango = Integer.valueOf(limites[1]); // Tomamos el número mayor del rango
            if (maxRango > maxNumero) {
                maxNumero = maxRango;
            }
        }
    }
    
    return maxNumero;
}
}