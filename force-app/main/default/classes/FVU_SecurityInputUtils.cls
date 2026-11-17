/**
 * @description       : Clase para validación y sanitización de datos de entrada (filtro de seguridad para asegurar los datos).
 * @author            : Equipo - Ventas Flo 
 * @group             :
 * @last modified on  : 15-12-2025
 * @last modified by  : arianni.colmenares@nespon.com
 * 
 * Notes:
 * - Use in controller layers, Flows (via invocable wrapper), and before database operations.
 * - Sanitize first, then validate, then persist.
**/

public with sharing class FVU_SecurityInputUtils {

    // Validate integer number
    public static String validateNumeric(String input) {

        if (String.isBlank(input)){ return null; }

        try {
            Decimal.valueOf(input);
            return input;
       } catch (System.TypeException e) {
            return null;
        }
    }

    // Validate Boolean
    public static String validateBoolean(String input) {

        if (String.isBlank(input)){ return null; }

        String lowerInput = input.trim().toLowerCase();

        if (lowerInput== 'true' || lowerInput== 'false' || lowerInput== 't' || lowerInput== 'f' || lowerInput== '1' || lowerInput== '0') {
            return input;
        } else {
            return null;
        }
    }

    // Validate String
    // - Validates if the string contains a single quote or its HTML code (' or &39;).
    public static String validateString(String input) {

        if (String.isBlank(input)){ return null; }

        if (input.contains('\'') || input.contains('&#39;')) {
            return null;
        }
        
        String sanitized = input.replaceAll('[\\x00-\\x1F]', '');
        return sanitized;
    }

    // Validate app name
    public static String validateAppName(String nameApp) {

        if (String.isBlank(nameApp)) {return null;}
        if (!FVU_IdClaroMetadata__mdt.sObjectType.getDescribe().isAccessible()) {
            return null; 
        }

        String recordName = validateString(nameApp);
        try {
            List<FVU_IdClaroMetadata__mdt> records = [
                SELECT DeveloperName 
                FROM FVU_IdClaroMetadata__mdt 
                WHERE FVU_Application__c = :recordName 
                LIMIT 1
            ];

            if (!records.isEmpty()) {
                return recordName; 
            } else {
                return null;
            }

        } catch (System.QueryException e) {
            System.debug('ERROR: Fallo al consultar FVU_IdClaroMetadata__mdt: ' + e.getMessage());
            return null;
        }
    }

    // --- JSON validation/sanitization utilities ---

    // Basic JSON structure validation: checks for matching braces/brackets and disallows control chars.
    // This is a lightweight guard; it does not fully parse JSON.
    public static Boolean isLikelyJson(String input) {

        if (String.isBlank(input)) return false; 

        String s = input.trim();
        if (!( (s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']')) )) {
            return false;
        }
        // Disallow unescaped control characters except tab/newline/carriage return
        if (Pattern.compile('[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]').matcher(s).find()) {
            return false;
        }
        Integer brace = 0;
        Integer bracket = 0;
        Boolean inString = false;
        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i+1);
            if (ch == '"') {
                // count preceding backslashes to detect escaped quote
                Integer bs = 0;
                Integer j = i - 1;
                while (j >= 0 && s.substring(j, j+1) == '\\') { bs++; j--; }
                if (Math.mod(bs, 2) == 0) {
                    inString = !inString;
                }
            }
            if (inString) { 
                continue; 
            }
            if (ch == '{') {
                brace++;
            } else if (ch == '}') {
                brace--;
            } else if (ch == '[') {
                bracket++;
            } else if (ch == ']') {
                bracket--;
            }
            if (brace < 0 || bracket < 0) {
                return false;
            }
        }
        return brace == 0 && bracket == 0;
    }

    // Sanitizes a JSON string for safe storage/logging:
    // - Trims and collapses excessive whitespace outside strings
    // - Optionally enforces max length
    // - Optionally allow only a safe character set (keeps quotes, braces, brackets, colon, comma, backslash)
    // - Specific Injection Detection: Single Quote (Specific Character).
    public static String sanitizeJson(String input, Integer maxLen, Boolean strictChars) {

        if (String.isBlank(input)){ return null; }
        
        String s = input.trim();

        if (strictChars == true) {
            
            if (s.contains('\'')) { 
                return null; 
            }

            // Eliminar caracteres de control (excepto tab/newline/carriage return)
            s = s.replaceAll('[^\\x20-\\x7E\\t\\n\\r]', '');
        }
        
        List<String> outList = new List<String>();
        Boolean inString = false;
        
        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i+1);

            if (ch == '"') {
                Integer bs = 0; Integer j = i - 1;
                while (j >= 0 && s.substring(j, j+1) == '\\') { bs++; j--; }
                if (Math.mod(bs, 2) == 0) {
                    inString = !inString;
                }
                outList.add(ch); 
                continue;
            }
            
            if (!inString && Pattern.compile('\\s').matcher(ch).matches()) {
                String lastChar = outList.isEmpty() ? null : outList.get(outList.size()-1);
                if (outList.isEmpty() || lastChar == null || !Pattern.compile('\\s').matcher(lastChar).matches()) {
                    outList.add(' '); 
                }
            } else {
                outList.add(ch); 
            }
        }
        
        String result = String.join(outList, '').trim(); 
        
        if (maxLen != null && result.length() > maxLen) {
            result = result.substring(0, maxLen);
        }

        return result;
    }

    // Combined validate + sanitize for JSON
    public static String sanitizeAndValidateJson(String input, Integer maxLen, Boolean strictChars) {
        String sanitized = sanitizeJson(input, maxLen, strictChars);
        if (sanitized == null) {
            return null;
        }
        return isLikelyJson(sanitized) ? sanitized : null;
    }

    // --- Salesforce Record Id utilities ---

    // Validates a Salesforce Id (15 or 18 chars). For 18-char Ids, validates checksum against the
    // first 15 characters per Salesforce algorithm.
    public static Boolean isValidSalesforceId(String input) {

        if (String.isBlank(input)) return false; 

        String id = input.trim();
        if (!(id.length() == 15 || id.length() == 18)) {
            return false;
        }
        if (!Pattern.compile('^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$').matcher(id).matches()) {
            return false;
        }

        // Validate 18-char checksum when present
        if (id.length() == 18) {
            String base = id.substring(0, 15);
            String expectedSuffix = computeIdChecksum(base);
            String actualSuffix = id.substring(15, 18);
            return expectedSuffix == actualSuffix;
        }
        return true;
    }

    // Computes the 3-character checksum for a 15-char Id per Salesforce case-insensitive algorithm.
    private static String computeIdChecksum(String fifteen) {
        // For each 5-char chunk, build a bit mask of uppercase letters positions; map to A-Z via base32-like map.
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
        String suffix = '';
        for (Integer i = 0; i < 3; i++) {
            Integer bit = 0;
            for (Integer j = 0; j < 5; j++) {
                Integer idx = (i * 5) + j;
                String c = fifteen.substring(idx, idx + 1);
                if (c.toUpperCase() == c && Pattern.compile('[A-Z]').matcher(c).matches()) {
                    bit += (1 << j);
                }
            }
            suffix += chars.substring(bit, bit + 1);
        }
        return suffix;
    }

    // Sanitizes a candidate Id:
    // - Trims whitespace
    // - Optionally converts 15-char Id to 18-char by adding checksum (if to18 == true)
    // - Returns null if invalid
    public static String sanitizeAndValidateSalesforceId(String input, Boolean to18) {
        
        if (String.isBlank(input)){ return null; }

        String id = input.trim();
        // Remove any non-alphanumeric characters just in case inputs came with separators
        id = id.replaceAll('[^a-zA-Z0-9]', '');
        if (!(id.length() == 15 || id.length() == 18)) {
            return null;
        }
        if (id.length() == 18) {
            return isValidSalesforceId(id) ? id : null;
        }
        // 15-char path
        if (!Pattern.compile('^[a-zA-Z0-9]{15}$').matcher(id).matches()) {
            return null;
        }
        if (to18 == true) {
            return id + computeIdChecksum(id);
        }
        return id;
    }
}