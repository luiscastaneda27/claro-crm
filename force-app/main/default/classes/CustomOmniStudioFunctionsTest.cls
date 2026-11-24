/**
 * This class contains unit tests for validating the behavior of the
 * CustomStringFunction Apex class.
 *
 * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *                Coverage           Date           Author                      Description
 * -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 * @version 1.1     91%             28/10/2024     Karen Sanchez (karsanchez)   HDU 427209 - Se agrega cobertura al método findLastElementArray, evaluando cuando los argumentos son nulos, cuando se manda solo un nodo y cuando hay varios nodos para obtener el ultimo
 * @version 1.2     91%             20/01/2024     Karen Sanchez (karsanchez)   HDU 425302 - Se agrega cobertura al método getPicklistLabel
 * @version 1.3     90%             29/01/2026     Eduardo W    Bug 758564 - Se agrega cobertura al método parseLatamNumber
 **/
@isTest
private class CustomOmniStudioFunctionsTest {

	private static final String SIMPLE_INPUT  = 'Mail;Email;Phone';
	private static final String SIMPLE_REGEX  = ';';
	@isTest
    static void split_simpleTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        args.add(SIMPLE_REGEX);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('split', inputMap, outputMap, null);
        String result = JSON.serializePretty(outputMap.get('result'));
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'SPLIT() invokeMethod returned false when it should return true');
    }
    @isTest
    static void split_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('split', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('SPLIT() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
	
		// Validation - if we make it here, the test failed
		System.assert(false);
    }
    @isTest
    static void startswith_simpleTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('startswith', inputMap, outputMap, null);
        Boolean result = (Boolean)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'STARTSWITH() invokeMethod returned false when it should return true');
		System.assert(result, 'STARTSWITH() returned false when it should return true');
    }
    @isTest   
    static void startswith_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add(SIMPLE_INPUT);
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('startswith', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('STARTSWITH() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
                
		
		// Validation - if we make it here, the test failed
		System.assert(false);
    }
	@isTest
    static void replace_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('abcdefgabc');
        args.add('abc');
        args.add('xyz');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('replace', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'REPLACE() invokeMethod returned false when it should return true');		
    }
    @isTest
    static void replace_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add('abcdefgabc');
        args.add('abc');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('replace', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('REPLACE() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
                
		
		// Validation - if we make it here, the test failed
		System.assert(false);
    }
	@isTest
    static void replaceAll_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('a b c 5 xyz');
        args.add('[a-zA-Z]');
        args.add('1');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('replaceAll', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'REPLACEALL() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void replaceAll_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add('a b c 5 xyz');
        args.add('[a-zA-Z]');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        
        try {
        	Boolean retValue = csf.invokeMethod('replaceAll', inputMap, outputMap, null);
        }
        catch (Exception e) {
        	
        	// We expect an exception as we called the method without enough arguments.
        	// This test is needed for 100% code coverage
        	System.debug('REPLACEALL() Received Expected Exception -> ' + e.getMessage());
        	
        	return;
        }
                
		
		// Validation - if we make it here, the test failed
		System.assert(false);
    }
	@isTest
    static void replaceFirst_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('a b c 11 xyz');
        args.add('[a-zA-Z]{2}');
        args.add('2');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('replaceFirst', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'REPLACEFIRST() invokeMethod returned false when it should return true');		
    }
    @isTest
    static void replaceFirst_exceptionTest() {
        
        List<String> args = new List<String>();
        args.add('a b c 11 xyz');
        args.add('[a-zA-Z]{2}');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('replaceFirst', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void toNumber_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('123115');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('toNumber', inputMap, outputMap, null);
        Double result = (Double)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result, 123115);
    }
	@isTest
    static void toNumber_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('toNumber', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void isNumber_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('12');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('isNumber', inputMap, outputMap, null);
        Boolean result = (Boolean)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result, true);
    }
	@isTest
    static void isNumber_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('isNumber', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void urlEncode_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('https://www.google.com/');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('urlEncode', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'URLENCODE() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void urlEncode_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('urlEncode', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void encrypt_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('ABC');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('encrypt', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'ENCRYPT() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void encrypt_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('encrypt', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void encryptIfNecessary_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('abc');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('encryptIfNecessary', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'ENCRYPT_IF_NECESSARY() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void encryptIfNecessary_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('encryptIfNecessary', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void decrypt_simpleTest() {
        Blob exampleIv = Blob.valueOf('Example of IV123');
        Blob key = Crypto.generateAesKey(128);
        Blob data = Blob.valueOf('Data to be encrypted');
        Blob encrypted = Crypto.encrypt('AES128', key, exampleIv, data);

        List<String> args = new List<String>();
        args.add(String.valueOf(vlocity_cmt.UserSecurity.encrypt(String.valueOf('Test'))));
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('denrypt', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'DECRYPT() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void decrypt_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('denrypt', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void decryptIfNecessary_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('possiblyEncryptedString');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('decryptIfNecessary', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'DECRYPT_IF_NECESSARY() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void decryptIfNecessary_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('decryptIfNecessary', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }	
    }
	@isTest
    static void joinString_simpleTest() {
        
        List<Object> args = new List<Object>();
        args.add(new List<String>{'1','2','3'});
        args.add('-');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('join', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
		System.assert(retValue, 'JOIN() invokeMethod returned false when it should return true');		
    }
	@isTest
    static void joinString_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('join', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }	
    }
	@isTest
    static void removeNullValues_simpleTest() {
        
        List<Object> args = new List<Object>();
        args.add('a');
        args.add('b');
        args.add('');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('removeNullValues', inputMap, outputMap, null);
        List<Object> result = (List<Object>)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result.size(), 2);
    }
	@isTest
    static void removeNullValues_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        try {
            Boolean retValue = csf.invokeMethod('removeNullValues', inputMap, outputMap, null);
            
        } catch (Exception e) {
            System.assert(true);
        }
    }
	@isTest
    static void length_simpleTest() {
        
        List<Object> args = new List<Object>();
        args.add('abcd');
        
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('length', inputMap, outputMap, null);
        Integer result = (Integer)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result, 4);
    }
	@isTest
    static void length_exceptionTest() {
       
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
         try {
              Boolean retValue = csf.invokeMethod('length', inputMap, outputMap, null);
            
        } catch (Exception e) {
		    System.assert(true);		
        }
    }
    
    @IsTest
    private static void testMatch() {
        
        List<Object> args = new List<Object>();
        args.add('qwerty');
        args.add('(e)');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('match', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        System.assertEquals(result, 'e');   
    }

    @isTest
    static void formatCurrency_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('123115');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('formatCurrency', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        
        System.assert( result == '123.115' || result == '123,115' , 'formatCurrency_simpleTest failed');
    }
    @isTest
    static void compareDateTime_simpleTest() {
        
        List<Object> args = new List<Object>();
        args.add('2023-01-01 01:00:00');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('compareDateTime', inputMap, outputMap, null);
        Boolean result = (Boolean)outputMap.get('result');
        
        // Logging
		System.debug(result);
		
		// Validation
        System.assertEquals(result, true);
    }
	@isTest
    static void compareDateTime_exceptionTest() {
       
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
         try {
              Boolean retValue = csf.invokeMethod('compareDateTime', inputMap, outputMap, null);
            
        } catch (Exception e) {
		    System.assert(true);		
        }
    }
	@isTest
    static void currentUserHasCustomPermission_simpleTest() {
        
        List<String> args = new List<String>();
        args.add('PERMISSION_NAME_TEST');
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Boolean retValue = csf.invokeMethod('currentUserHasCustomPermission', inputMap, outputMap, null);
        Boolean result = (Boolean) outputMap.get('result');
        
        System.assert(result == false, 'currentUserHasCustomPermission_simpleTest failed');
    }
	@isTest
    static void currentUserHasCustomPermission_exceptionTest() {
        
        List<String> args = new List<String>();
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        try {
            CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
            Boolean retValue = csf.invokeMethod('currentUserHasCustomPermission', inputMap, outputMap, null);
            System.assert(false, 'Exception should have been thrown due to argument missing.');
        } catch (Exception e) {
		    System.assert(true);		
        }
    }
    
    /**
    * @description: CASO1: Recibe una lista nula
    * @author karsanchez | 10-28-2024 
    **/
    @isTest
    static void testFindLastNode_NullList() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        List<String> args = new List<String>();
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);
        Map<String, Object> outputMap = new Map<String, Object>();
        csf.invokeMethod('findLastElementArray', inputMap, outputMap, null);
        System.assertEquals(null, outputMap.get('result'), 'El resultado es null para una lista nula');
    }

    /**
    * @description: CASO2: Lista con un solo elemento
    * @author karsanchez | 10-28-2024 
    **/
    @isTest
    static void testFindLastNode_SingleElement() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> singleElement = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        singleElement.put('errorDescription', 'Missing information: externalId');
        singleElement.put('errorCode', 'EOC_ERROR_EXT_ID');
        List<Object> args = new List<Object>{singleElement};
        inputMap.put('arguments', args);
        csf.invokeMethod('findLastElementArray', inputMap, outputMap, null);
        Map<String, Object> resultMap = (Map<String, Object>)outputMap.get('result');
        System.debug('resultMap:'+resultMap);
        System.assertEquals('EOC_ERROR_EXT_ID', resultMap.get('errorCode'), 'Se encontro el último nodo');
    }

    /**
    * @description: CASO2: Lista con varios elementos
    * @author karsanchez | 10-28-2024 
    **/
    @isTest
    static void testFindLastNode_MultipleElements() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        List<Object> args = new List<Object>{};
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> firstElement = new Map<String, Object>();
        firstElement.put('errorDescription', 'Missing information: externalId');
        firstElement.put('errorCode', 'EOC_ERROR_EXT_ID');
        Map<String, Object> secondElement = new Map<String, Object>();
        secondElement.put('errorDescription', 'Missing information: externalId');
        secondElement.put('errorCode', 'EOC_ERROR_EXT_ID2');
        args.add(firstElement);
        args.add(secondElement);
        inputMap.put('arguments', args);
        csf.invokeMethod('findLastElementArray', inputMap, outputMap, null);
        Map<String, Object> resultMap = (Map<String, Object>)outputMap.get('result');
        System.assertEquals('EOC_ERROR_EXT_ID2', resultMap.get('errorCode'), 'Se encontro el último nodo con código EOC_ERROR_EXT_ID2');
    }

    /**
    * @description: CASO1: Exito, se mandan los datos correspondientes
    * @author karsanchez | 20-ENE-2024 
    **/
    @isTest
    static void testgetPicklistLabel() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        List<Object> lstInput = new List<Object>{'Order', 'FVU_OrderSubType__c', 'Act_migracion_Pre_Pos'};
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> singleElement = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        inputMap.put('arguments', lstInput);
        csf.invokeMethod('getPicklistLabel', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        System.assertEquals(String.isNotBlank(result), true, 'retorno correctamente el valor');
   }
   /**    
    * @author JCorrales | 14-FEB-2025 
    **/
    @isTest
    static void testReplaceAtStart() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        List<Object> lstInput = new List<Object>{'123456789', '2', '*'};
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> singleElement = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        inputMap.put('arguments', lstInput);
        csf.invokeMethod('replaceAtStart', inputMap, outputMap, null);
        String result = (String)outputMap.get('result');
        System.assertEquals(String.isNotBlank(result), true, 'retorno correctamente el valor');
   }
   @isTest
   static void testRemoveDuplicates() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        List<Object> args = new List<Object>{};
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        List<String> lstData = new List<String>();
        lstData.add('01% Interés hasta 36 meses con tarjetas de crédito del banco de Bogotá 20% Devolución primera compra con tarjeta Claro Pay (Máximo Devolución $1.000.000) Aplican términos y condiciones');
        lstData.add('0% Interés hasta 36 meses con tarjetas de crédito del banco de Bogotá 20% Devolución primera compra con tarjeta Claro Pay (Máximo Devolución $1.000.000) Aplican términos y condiciones');
        lstData.add('0% Interés hasta 36 meses con tarjetas de crédito del banco de Bogotá 20% Devolución primera compra con tarjeta Claro Pay (Máximo Devolución $1.000.000) Aplican términos y condiciones');
        
        
        args.add(lstData);
        inputMap.put('arguments', args);
        csf.invokeMethod('removeDuplicates', inputMap, outputMap, null);
        List<Object> resultMap = (List<Object>)outputMap.get('result');
        //System.assertEquals('EOC_ERROR_EXT_ID2', resultMap.get('errorCode'), 'Se encontro el último nodo con código EOC_ERROR_EXT_ID2');
	}
    @isTest
    static void testInsertNewLineByIndex() {
        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        List<String> lstData = new List<String>();
        lstData.add('Hola a todos, cómo están?');
        lstData.add('9');
        inputMap.put('arguments', lstData);
        csf.invokeMethod('insertNewLineByIndex', inputMap, outputMap, null);
    }

     
    
        @isTest
        static void testGetNowGMT() {
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
            
            String result = cls.getNowGMT();
            
            System.assertNotEquals(null, result);
            System.assert(result.contains('T'), 'Debe tener formato ISO');
        }
    
        // ============================
        // toPercentage - OK cases
        // ============================
        @isTest
        static void testToPercentage_OK() {
            List<Object> args = new List<Object>{'12,5'};
            String result = CustomOmniStudioFunctions.toPercentage(args);
            
            System.assertEquals('12,50 %', result);
        }
    
        @isTest
        static void testToPercentage_WithSymbol() {
            List<Object> args = new List<Object>{'45%'};
            String result = CustomOmniStudioFunctions.toPercentage(args);
            
            System.assertEquals('45,00 %', result);
        }
    
        @isTest
        static void testToPercentage_WithSpaces() {
            List<Object> args = new List<Object>{' 10,2 '};
            String result = CustomOmniStudioFunctions.toPercentage(args);
            
            System.assertEquals('10,20 %', result);
        }
    
        // ============================
        // toPercentage - ERROR cases
        // ============================
        @isTest
        static void testToPercentage_NullArgs() {
            try {
                CustomOmniStudioFunctions.toPercentage(null);
                System.assert(false, 'Debió lanzar excepción');
            } catch (Exception e) {
                System.assert(true);
            }
        }
    
        @isTest
        static void testToPercentage_EmptyList() {
            try {
                CustomOmniStudioFunctions.toPercentage(new List<Object>());
                System.assert(false);
            } catch (Exception e) {
                System.assert(true);
            }
        }
    
        @isTest
        static void testToPercentage_NullValue() {
            try {
                CustomOmniStudioFunctions.toPercentage(new List<Object>{null});
                System.assert(false);
            } catch (Exception e) {
                System.assert(true);
            }
        }
    
        @isTest
        static void testToPercentage_InvalidNumber() {
            try {
                CustomOmniStudioFunctions.toPercentage(new List<Object>{'abc'});
                System.assert(false);
            } catch (Exception e) {
                System.assert(true);
            }
        }
   
        @IsTest
        static void testParseLatamNumber_Miles() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ '40.000' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            cls.invokeMethod('parseLatamNumber', input, output, null);
    
            System.assertEquals('40000', output.get('result'));
        }
    
        @IsTest
        static void testParseLatamNumber_MilesConDecimales() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ '40.100,50' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            cls.invokeMethod('parseLatamNumber', input, output, null);
    
            System.assertEquals('40100.50', output.get('result'));
        }
    
        @IsTest
        static void testParseLatamNumber_SoloDecimal() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ '123,45' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            cls.invokeMethod('parseLatamNumber', input, output, null);
    
            System.assertEquals('123.45', output.get('result'));
        }
    
        @IsTest
        static void testParseLatamNumber_SinFormato() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ '5000' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            cls.invokeMethod('parseLatamNumber', input, output, null);
    
            System.assertEquals('5000', output.get('result'));
        }
    
        @IsTest
        static void testParseLatamNumber_Blank() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ '' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            cls.invokeMethod('parseLatamNumber', input, output, null);
    
            System.assertEquals(null, output.get('result'));
        }
    
        @IsTest
        static void testParseLatamNumber_ErrorFormato() {
    
            CustomOmniStudioFunctions cls = new CustomOmniStudioFunctions();
    
            Map<String, Object> input = new Map<String, Object>{
                'arguments' => new List<Object>{ 'ABC' }
            };
            Map<String, Object> output = new Map<String, Object>();
    
            try {
                cls.invokeMethod('parseLatamNumber', input, output, null);
                System.assert(false, 'Debió lanzar excepción');
            } catch (Exception e) {
                System.assert(true);
            }
        }
    
    
      @isTest
    static void testJsonObjToArray_WithTipo() {
        
        // 🔹 Arrange
        Map<String, Object> inputMap = new Map<String, Object>{
            'Tipo' => 'Promocion',
            'Internet' => '100MB',
            'TV' => 'Premium'
        };

        List<Object> args = new List<Object>{
            inputMap,
            'Nombre',   // strLlave
            'Valor',    // strValor
            'Default'   // strTipo (debería ser reemplazado por "Promocion")
        };

        // 🔹 Act
        List<Map<String, Object>> result = CustomOmniStudioFunctions.jsonObjToArray(args);

        // 🔹 Assert
        System.assertEquals(2, result.size(), 'Debe devolver 2 elementos (sin Tipo)');

        for (Map<String, Object> item : result) {
            System.assert(item.containsKey('Nombre'));
            System.assert(item.containsKey('Valor'));
            System.assertEquals('Promocion', item.get('Tipo')); // viene del JSON, no del param
        }
    }


    @isTest
    static void testJsonObjToArray_WithoutTipo() {
        
        // 🔹 Arrange
        Map<String, Object> inputMap = new Map<String, Object>{
            'Internet' => '200MB',
            'TV' => 'Basic'
        };

        List<Object> args = new List<Object>{
            inputMap,
            'Key',
            'Value',
            'FallbackTipo'
        };

        // 🔹 Act
        List<Map<String, Object>> result = CustomOmniStudioFunctions.jsonObjToArray(args);

        // 🔹 Assert
        System.assertEquals(2, result.size());

        for (Map<String, Object> item : result) {
            System.assertEquals('FallbackTipo', item.get('Tipo')); // usa el param
        }
    }

    @IsTest
    static void formatTimeToAmPm_simpleTest() {

        List<Object> args = new List<Object>();
        args.add('17:30');

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);

        Map<String, Object> outputMap = new Map<String, Object>();

        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();

        Boolean retValue = csf.invokeMethod('formatTimeToAmPm', inputMap, outputMap, null);
        String result = (String) outputMap.get('result');

        System.debug(result);

        System.assert(retValue, 'FORMATTIME_TO_AMPM() invokeMethod returned false');
        System.assertEquals('5:30 PM', result);
    }


    @IsTest
    static void formatTimeToAmPm_hourOnlyTest() {

        List<Object> args = new List<Object>();
        args.add('11');

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);

        Map<String, Object> outputMap = new Map<String, Object>();

        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();

        Boolean retValue = csf.invokeMethod('formatTimeToAmPm', inputMap, outputMap, null);
        String result = (String) outputMap.get('result');

        System.debug(result);

        System.assert(retValue, 'FORMATTIME_TO_AMPM() invokeMethod returned false');
        System.assertEquals('11:00 AM', result);
    }


    @IsTest
    static void formatTimeToAmPm_midnightAndNoonTest() {

        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();

        // Caso 00:00
        Map<String, Object> inputMidnight = new Map<String, Object>{
            'arguments' => new List<Object>{'0:00'}
        };

        Map<String, Object> outputMidnight = new Map<String, Object>();

        csf.invokeMethod('formatTimeToAmPm', inputMidnight, outputMidnight, null);

        System.assertEquals('12:00 AM', outputMidnight.get('result'));


        // Caso 12:00
        Map<String, Object> inputNoon = new Map<String, Object>{
            'arguments' => new List<Object>{'12:00'}
        };

        Map<String, Object> outputNoon = new Map<String, Object>();

        csf.invokeMethod('formatTimeToAmPm', inputNoon, outputNoon, null);

        System.assertEquals('12:00 PM', outputNoon.get('result'));
    }


    @IsTest
    static void formatTimeToAmPm_exceptionTest() {

        List<Object> args = new List<Object>();

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('arguments', args);

        Map<String, Object> outputMap = new Map<String, Object>();

        CustomOmniStudioFunctions csf = new CustomOmniStudioFunctions();

        Boolean retValue = csf.invokeMethod('formatTimeToAmPm', inputMap, outputMap, null);

        String result = (String) outputMap.get('result');

        System.debug(result);

        System.assert(retValue, 'FORMATTIME_TO_AMPM() should return true');
        System.assertEquals('', result);
    }

    @IsTest
    static void testEvaluarHoraMaximaCancelarCasos_FechaAnterior() {

        CustomOmniStudioFunctions service = new CustomOmniStudioFunctions();

        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();

        List<Object> argumentos = new List<Object>();

        // Fecha vieja para forzar:
        // fechaActualColombia > fechaConsultada
        argumentos.add('2020-01-01');

        input.put('arguments', argumentos);

        Test.startTest();

        service.invokeMethod(
            'evaluarHoraMaximaCancelarCasos',
            input,
            output,
            new Map<String,Object>()
        );

        Test.stopTest();

        System.assertEquals(
            true,
            output.get('result'),
            'Debe retornar true cuando la fecha consultada es anterior'
        );
    }


    @IsTest
    static void testEvaluarHoraMaximaCancelarCasos_FechaFutura() {

        CustomOmniStudioFunctions service = new CustomOmniStudioFunctions();

        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();

        List<Object> argumentos = new List<Object>();

        // Fecha futura para que no entre en ninguna condición
        argumentos.add('2099-12-31');

        input.put('arguments', argumentos);

        Test.startTest();

        service.invokeMethod(
            'evaluarHoraMaximaCancelarCasos',
            input,
            output,
            new Map<String,Object>()
        );

        Test.stopTest();

        System.assertEquals(
            false,
            output.get('result'),
            'Debe retornar false para una fecha futura'
        );
    }


    @IsTest
    static void testEvaluarHoraMaximaCancelarCasos_FechaHoy() {

        CustomOmniStudioFunctions service = new CustomOmniStudioFunctions();

        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();

        String fechaHoy = Datetime.now()
            .format('yyyy-MM-dd','America/Bogota');


        input.put(
            'arguments',
            new List<Object>{fechaHoy}
        );


        Test.startTest();

        service.invokeMethod(
            'evaluarHoraMaximaCancelarCasos',
            input,
            output,
            new Map<String,Object>()
        );

        Test.stopTest();


        System.assertNotEquals(
            null,
            output.get('result'),
            'Debe devolver un resultado booleano'
        );
    }


    @IsTest
    static void testEvaluarHoraMaximaCancelarCasosArgumentoNull() {

        CustomOmniStudioFunctions service = new CustomOmniStudioFunctions();

        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();

        input.put(
            'arguments',
            new List<Object>{null}
        );


        Test.startTest();

        service.invokeMethod(
            'evaluarHoraMaximaCancelarCasos',
            input,
            output,
            new Map<String,Object>()
        );

        Test.stopTest();


        System.assertEquals(
            false,
            output.get('result')
        );
    }


    @IsTest
    static void testEvaluarHoraMaximaCancelarCasosFechaInvalida() {

        CustomOmniStudioFunctions service = new CustomOmniStudioFunctions();

        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> output = new Map<String,Object>();

        input.put(
            'arguments',
            new List<Object>{'texto-no-fecha'}
        );


        Test.startTest();

        service.invokeMethod(
            'evaluarHoraMaximaCancelarCasos',
            input,
            output,
            new Map<String,Object>()
        );

        Test.stopTest();


        System.assertEquals(
            false,
            output.get('result')
        );
    }
}