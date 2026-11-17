@IsTest
public class FIN_UtilsTest {
    
    @IsTest
    static void testConvertToNumber() {
        // Setup
        FIN_Utils utils = new FIN_Utils();
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        // Test Case 1: Simple integer amount
        input.put('currencyString', '$1000');
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1000, output.get('currencyNumber'), 'Simple integer amount failed');
        
        // Test Case 2: Amount with thousand separator
        input.put('currencyString', '$1.000');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1000, output.get('currencyNumber'), 'Amount with thousand separator failed');
        
        // Test Case 3: Large amount with multiple thousand separators
        input.put('currencyString', '$1.000.000');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1000000, output.get('currencyNumber'), 'Large amount with separators failed');
        
        // Test Case 4: Amount with decimal places
        input.put('currencyString', '$1.000,50');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1000.50, output.get('currencyNumber'), 'Amount with decimal places failed');
        
        // Test Case 5: Complex amount with multiple separators and decimals
        input.put('currencyString', '$1.234.567,89');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1234567.89, output.get('currencyNumber'), 'Complex amount failed');
        
        // Test Case 6: Empty string
        input.put('currencyString', '');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(0, output.get('currencyNumber'), 'Empty string should return 0');
        
        // Test Case 7: Null value
        input.put('currencyString', null);
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(0, output.get('currencyNumber'), 'Null value should return 0');
        
        // Test Case 8: Amount without currency symbol
        input.put('currencyString', '1.234,56');
        output.clear();
        utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(1234.56, output.get('currencyNumber'), 'Amount without currency symbol failed');
    }

    @IsTest
    static void testconvertNumberToCurrency() {
        // Setup
        FIN_Utils utils = new FIN_Utils();
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        // Test Case 1: Simple integer
        input.put('number', 1000);
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$1.000', output.get('currencyString'), 'Simple integer conversion failed');
        
        // Test Case 2: Large integer
        input.put('number', 1000000);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$1.000.000', output.get('currencyString'), 'Large integer conversion failed');
        
        // Test Case 3: Decimal number
        input.put('number', 1000.50);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$1.000,50', output.get('currencyString'), 'Decimal number conversion failed');
        
        // Test Case 4: Complex decimal
        input.put('number', 1234567.89);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$1.234.567,89', output.get('currencyString'), 'Complex decimal conversion failed');
        
        // Test Case 5: Zero value
        input.put('number', 0);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$0', output.get('currencyString'), 'Zero value conversion failed');
        
        // Test Case 6: Null value
        input.put('number', null);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$0', output.get('currencyString'), 'Null value should return $0');
        
        // Test Case 7: Small decimal
        input.put('number', 0.99);
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$0,99', output.get('currencyString'), 'Small decimal conversion failed');
        
        // Test Case 8: String number input
        input.put('number', '1234.56');
        output.clear();
        utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals('$1.234,56', output.get('currencyString'), 'String number input conversion failed');
    }
    
    @IsTest
    static void testInvalidMethod() {
        // Setup
        FIN_Utils utils = new FIN_Utils();
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        // Test invalid method name
        Boolean result = utils.invokeMethod('invalidMethod', input, output, options);
        System.assertEquals(true, result, 'Invalid method should still return true');
    }
    
    @IsTest
    static void testInvalidInput() {
        // Setup
        FIN_Utils utils = new FIN_Utils();
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        // Test Case: Invalid number format
        input.put('currencyString', '$1,234.56'); // Invalid format (comma before dot)
        Boolean result = utils.invokeMethod('convertToNumber', input, output, options);
        System.assertEquals(false, result, 'Invalid number format should return false');
        System.assertNotEquals(null, output.get('error'), 'Error message should be present');

        // Test invalid input for convertNumberToCurrency
        input.clear();
        output.clear();
        input.put('number', 'not_a_number');
        result = utils.invokeMethod('convertNumberToCurrency', input, output, options);
        System.assertEquals(false, result, 'Invalid number input should return false');
        System.assertNotEquals(null, output.get('error'), 'Error message should be present for invalid number');
    }
    

    @isTest
    static void testConvertToCurrency_EmptyInput() {
        Map<String, Object> input = new Map<String, Object>{ 'convertToCurrency' => '' };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_Utils utils = new FIN_Utils();
        Boolean result = utils.invokeMethod('convertToCurrency', input, outMap, options);

        System.assert(result, 'El método debe devolver true para entradas vacías.');
        System.assertEquals(0, outMap.get('convertToCurrency'), 'El valor predeterminado no es correcto.');
    }

    

    @isTest
    static void testConvertToCurrency_NullInput() {
        Map<String, Object> input = new Map<String, Object>{ 'convertToCurrency' => null };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        FIN_Utils utils = new FIN_Utils();
        Boolean result = utils.invokeMethod('convertToCurrency', input, outMap, options);

        System.assert(result, 'El método debe devolver true para entradas nulas.');
        System.assertEquals(0, outMap.get('convertToCurrency'), 'El valor predeterminado no es correcto.');
    }
    
}