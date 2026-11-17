global class FIN_Utils implements vlocity_cmt.VlocityOpenInterface2 {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {

        if (methodName.equals('convertToNumber')) {
            return convertToNumber(input, outMap, options);
        }else if (methodName.equals('convertToCurrency')) {
            return convertToCurrency(input, outMap, options);
        }
        else if (methodName.equals('convertNumberToCurrency')) {
            return convertNumberToCurrency(input, outMap, options);
        }
        
        return true;
    }
    
    private Boolean convertToNumber(Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        String currencyStr = (String)input.get('currencyString');
        
        if (String.isBlank(currencyStr)) {
            outMap.put('currencyNumber', 0);
            return true;
        }
        
        // Validar formato de entrada
        if (!isValidFormat(currencyStr)) {
            outMap.put('error', 'Formato de número inválido. Use formato con punto como separador de miles y coma para decimales.');
            outMap.put('currencyNumber', 0);
            return false;
        }
        
        // Remove $ and replace comma with dot for decimal point
        String cleanNumber = currencyStr
            .replace('$', '')    // Remove currency symbol
            .replace('.', '')    // Remove thousand separators
            .replace(',', '.');  // Replace comma with dot for decimal
        
        Decimal result = Decimal.valueOf(cleanNumber);
        outMap.put('currencyNumber', result);
        return true;
    }
    
    private Boolean isValidFormat(String value) {
        // Verificar que no tenga '.' después de ','
        if (value.contains(',.')) return false;
        
        // Verificar que no tenga ',' antes de '.'
        if (value.indexOf(',') != -1 && value.indexOf('.') != -1) {
            return value.indexOf(',') > value.indexOf('.');
        }
        
        return true;
    }
    
    private Boolean convertToCurrency(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
    String currencyStr = (String) input.get('convertToCurrency');

    if (String.isBlank(currencyStr)) {
        outMap.put('convertToCurrency', 0);
        return true;
    }

    

    try {
        // Convertir cadena a decimal y formatear
        Decimal decimalValue = Decimal.valueOf(currencyStr.replace('.', '').replace(',', '.'));
        String result = '$' + decimalValue.setScale(2).format();
        outMap.put('currencyStr', result);
    } catch (Exception e) {
        outMap.put('error', 'Error al convertir el valor. Asegúrese de que el formato sea correcto.');
        outMap.put('convertToCurrency', 0);
        return false;
    }

    return true;
}

    private Boolean convertNumberToCurrency(Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        Object numberObj = input.get('number');
        if (numberObj == null) {
            outMap.put('currencyString', '$0');
            return true;
        }
        
        // Convert input to string and normalize decimal separator to '.'
        String numberStr = String.valueOf(numberObj).replace(',', '.');
        
        // Validate if it's a valid number
        if (!isValidNumber(numberStr)) {
            outMap.put('error', 'Valor inválido. Debe ser un número.');
            outMap.put('currencyString', '$0');
            return false;
        }
        
        // Split number into integer and decimal parts
        List<String> parts = numberStr.split('\\.');
        String integerPart = parts[0];
        String decimalPart = parts.size() > 1 ? parts[1] : '';
        
        // Format integer part with thousand separators
        String formattedInteger = '';
        Integer len = integerPart.length();
        for (Integer i = 0; i < len; i++) {
            if (i > 0 && Math.mod(len - i, 3) == 0) {
                formattedInteger += '.';
            }
            formattedInteger += integerPart.substring(i, i + 1);
        }
        
        // Combine parts with proper separators
        String result = '$' + formattedInteger;
        if (!String.isEmpty(decimalPart)) {
            result += ',' + decimalPart;
        }
        
        outMap.put('currencyString', result);
        return true;
    }

    private Boolean isValidNumber(String value) {
        // Patrón que acepta números enteros o decimales, positivos o negativos
        Pattern numberPattern = Pattern.compile('^-?\\d*\\.?\\d+$');
        Matcher matcher = numberPattern.matcher(value);
        return matcher.matches();
    }

}