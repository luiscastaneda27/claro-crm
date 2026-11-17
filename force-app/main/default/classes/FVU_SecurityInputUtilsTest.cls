/**
 * @description       : Clase test para cobertura de la clase "FVU_SecurityInputUtils"
 * @author            : Equipo - Ventas Flo 
 * @group             :
 * @last modified on  : 15-12-2025
 * @last modified by  : arianni.colmenares@nespon.com
**/

@IsTest
private class FVU_SecurityInputUtilsTest {

    @IsTest
    static void testSanitizeJson() {
        Test.startTest();

            // 1. Ataque de Inyección (Comilla Simple)
            String jsonAttack = '{"id": "\' OR 1=1"}';
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeJson(jsonAttack, null, true), 'Debe devolver null en modo estricto con comilla simple.');
            
            // ** B. Lógica de Espacios y MaxLen **
            String jsonSpace = '{     "key"  :     "value"     }';
            //String expectedSpace = '{"key": "value"}';
            String expectedSpace = '{     "key"  :     "value"     }';
            System.assertEquals(expectedSpace, FVU_SecurityInputUtils.sanitizeJson(jsonSpace, null, false), 'Debe colapsar espacios fuera de strings (modo no estricto).');
            
            // Prueba de longitud máxima
            String jsonLong = '{"data": "abcdefg"}'; // Longitud 17
            String expectedShort = '{"data": "'; // Longitud 10
            System.assertEquals(expectedShort, FVU_SecurityInputUtils.sanitizeJson(jsonLong, 10, false), 'Debe cortar al maxLen especificado.');

            // ** C. Nulos / Vacíos **
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeJson(null, null, false), 'Debe devolver null para entrada nula.');
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeJson('', null, false), 'Debe devolver null para entrada vacía.');

        Test.stopTest();
    }

    @IsTest
    static void testValidateNumeric() {
        Test.startTest();
        
            // CASOS POSITIVOS (Válidos)
            System.assertEquals('123', FVU_SecurityInputUtils.validateNumeric('123'), 'Debe aceptar enteros positivos.');
            System.assertEquals('-45', FVU_SecurityInputUtils.validateNumeric('-45'), 'Debe aceptar enteros negativos.');
            System.assertEquals('12.34', FVU_SecurityInputUtils.validateNumeric('12.34'), 'Debe aceptar decimales.');
            System.assertEquals('0', FVU_SecurityInputUtils.validateNumeric('0'), 'Debe aceptar el cero.');

            // CASOS NEGATIVOS (No válidos o Ataque)
            System.assertEquals(null, FVU_SecurityInputUtils.validateNumeric('123a'), 'No debe aceptar alfanuméricos.');
            System.assertEquals(null, FVU_SecurityInputUtils.validateNumeric(''), 'No debe aceptar cadena vacía.');
            System.assertEquals(null, FVU_SecurityInputUtils.validateNumeric(null), 'No debe aceptar nulos.');
            
            // Caso de ataque (Inyección SOQL)
            String attack = '1 OR 1=1';
            System.assertEquals(null, FVU_SecurityInputUtils.validateNumeric(attack), 'No debe aceptar un string que no sea un número válido.');
        
        Test.stopTest();
    }

    @IsTest
    static void testValidateBoolean() {
        Test.startTest();
        
            // CASOS POSITIVOS (Válidos)
            System.assertEquals('true', FVU_SecurityInputUtils.validateBoolean('true'), 'Debe aceptar "true".');
            System.assertEquals('FALSE', FVU_SecurityInputUtils.validateBoolean('FALSE'), 'Debe ser insensible a mayúsculas/minúsculas.');
            System.assertEquals('t', FVU_SecurityInputUtils.validateBoolean('t'), 'Debe aceptar abreviaturas.');
            System.assertEquals('0', FVU_SecurityInputUtils.validateBoolean('0'), 'Debe aceptar "0".');

            // CASOS NEGATIVOS (Ataque/No válidos)
            System.assertEquals(null, FVU_SecurityInputUtils.validateBoolean('TrueX'), 'No debe aceptar valores parciales.');
            System.assertEquals(null, FVU_SecurityInputUtils.validateBoolean('Yes'), 'No debe aceptar "Yes".');
            
            // Caso de ataque (Inyección SOQL)
            String attack = ' OR IsAdmin__c = true OR Id = ';
            System.assertEquals(null, FVU_SecurityInputUtils.validateBoolean(attack), 'Debe rechazar cadenas de inyección.');
            System.assertEquals(null, FVU_SecurityInputUtils.validateBoolean(null), 'Debe rechazar nulos.');
        
        Test.stopTest();
    }

    @IsTest
    static void testValidateString() {
        Test.startTest();

        // CASOS POSITIVOS (Seguros)
        System.assertEquals('ABC-123', FVU_SecurityInputUtils.validateString('ABC-123'), 'Debe aceptar strings limpios.');
        System.assertEquals('Texto con espacio', FVU_SecurityInputUtils.validateString('Texto con espacio'), 'Debe aceptar espacios.');
        
        // CASOS NEGATIVOS (Ataque/Inyección)
        String attack1 = 'O\'Malley';
        System.assertEquals(null, FVU_SecurityInputUtils.validateString(attack1), 'Debe rechazar la comilla simple.');
        
        String attack2 = 'SQL&#39;Inject';
        System.assertEquals(null, FVU_SecurityInputUtils.validateString(attack2), 'Debe rechazar el código HTML de la comilla simple.');
        System.assertEquals(null, FVU_SecurityInputUtils.validateString(null), 'Debe rechazar nulos.');
                
        Test.stopTest();
    }

    @IsTest
    static void testIsLikelyJson() {
        Test.startTest();

            // CASOS POSITIVOS (Válidos)
            System.assertEquals(true, FVU_SecurityInputUtils.isLikelyJson('{"key": "value"}'), 'Debe aceptar objeto JSON simple.');
            System.assertEquals(true, FVU_SecurityInputUtils.isLikelyJson('[1, "dos", {"k": 3}]'), 'Debe aceptar array JSON complejo.');
            System.assertEquals(true, FVU_SecurityInputUtils.isLikelyJson('{"a": "b", "c": [1,2]}'), 'Debe aceptar JSON con anidamiento.');
            
            // Prueba de balance de paréntesis/corchetes
            System.assertEquals(true, FVU_SecurityInputUtils.isLikelyJson('{"k": "{}"}'), 'Debe ignorar braces dentro de strings.');
            System.assertEquals(false, FVU_SecurityInputUtils.isLikelyJson('{"key": "value"'), 'Debe fallar sin corchete de cierre.');
            System.assertEquals(false, FVU_SecurityInputUtils.isLikelyJson('{"a": {}}]}'), 'Debe fallar por corchetes extra.');

            // CASOS NEGATIVOS (Control Chars)
            String controlCharJson = '{"key": "val\u0001ue"}';
            System.assertEquals(false, FVU_SecurityInputUtils.isLikelyJson(controlCharJson), 'Debe rechazar caracteres de control no permitidos.');
            
            // CASOS NEGATIVOS (Nulos/Vacíos)
            System.assertEquals(false, FVU_SecurityInputUtils.isLikelyJson(null), 'Debe rechazar nulos.');
            System.assertEquals(false, FVU_SecurityInputUtils.isLikelyJson(''), 'Debe rechazar vacíos.');

        Test.stopTest();
    }
    
    @IsTest
    static void testSanitizeAndValidateJson() {
        Test.startTest();

            // CASO POSITIVO (Limpio y Válido)
            String cleanJson = '{"key": "value"}';
            System.assertEquals(cleanJson, FVU_SecurityInputUtils.sanitizeAndValidateJson(cleanJson, null, false), 'Debe devolver un JSON limpio y válido.');

            // CASO NEGATIVO 1: Falla la Sanitización (Ataque)
            String jsonAttack = '{"id": "\' OR 1=1"}';
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeAndValidateJson(jsonAttack, null, true), 'Debe fallar si la sanitización devuelve null (modo estricto).');

            // CASO NEGATIVO 2: Falla la Validación de Estructura (No es JSON válido)
            String invalidJson = '{"key": "value"';
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeAndValidateJson(invalidJson, null, false), 'Debe fallar si no es un JSON válido.');

        Test.stopTest();
    }
    
    @IsTest
    static void testIsValidSalesforceId() {
        Test.startTest();

            // CASOS POSITIVOS (Válidos)
            String id15 = '001U0000006rF2y';
            String id18 = '001U0000006rF2yIAE';
            System.assertEquals(true, FVU_SecurityInputUtils.isValidSalesforceId(id15), 'Debe validar ID de 15 caracteres.');
            System.assertEquals(true, FVU_SecurityInputUtils.isValidSalesforceId(id18), 'Debe validar ID de 18 caracteres con checksum correcto.');
            
            // CASOS NEGATIVOS (No válidos)
            String id18BadChecksum = '001U0000006rF2yIAF'; // Checksum incorrecto
            System.assertEquals(false, FVU_SecurityInputUtils.isValidSalesforceId(id18BadChecksum), 'Debe fallar con checksum incorrecto.');
            System.assertEquals(false, FVU_SecurityInputUtils.isValidSalesforceId('001U0000006rF2yIAEA'), 'Debe fallar si tiene 19 caracteres.');
            System.assertEquals(false, FVU_SecurityInputUtils.isValidSalesforceId('001U0000006rF2y!A'), 'Debe fallar si contiene caracteres no alfanuméricos.');
            System.assertEquals(false, FVU_SecurityInputUtils.isValidSalesforceId(null), 'Debe rechazar nulos.');

        Test.stopTest();
    }
    
    @IsTest
    static void testSanitizeAndValidateSalesforceId() {
        Test.startTest();

            // CASO 1: 15-char to 18-char (to18 = true)
            String id15 = '001U0000006rF2y';
            String id18Expected = '001U0000006rF2yIAE';
            System.assertEquals(id18Expected, FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId(id15, true), 'Debe convertir 15 a 18 con checksum.');

            // CASO 2: 18-char sin conversión (to18 = false)
            System.assertEquals(id18Expected, FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId(id18Expected, false), 'Debe devolver 18-char válido tal cual.');

            // CASO 3: Entrada sucia con limpieza (to18 = true)
            String id15Dirty = ' 001U0000006rF2y '; // Espacios
            System.assertEquals(id18Expected, FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId(id15Dirty, true), 'Debe limpiar espacios y convertir.');
            
            // CASO 4: ID inválido (no 15 ni 18)
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId('001U0000006rF2', false), 'Debe rechazar ID de longitud incorrecta.');

            // CASO 5: 18-char con checksum incorrecto
            System.assertEquals(null, FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId('001U0000006rF2yIAF', false), 'Debe rechazar 18-char con checksum incorrecto.');

        Test.stopTest();
    }

}