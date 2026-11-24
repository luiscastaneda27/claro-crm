/**
 * This class provides some useful functions that can be used within OmniStudio DataRaptor & Integration Procedure
 * formulas to manipulate strings.
 *  
 * I recommend you register each function with the org's Custom Metadata to make it easy to use, but this isn't necessary
 * as custom functions can now be called by the built-in FUNCTION() formula.
 *  
 * (Setup -> Custom Metadata Types -> Function Definition -> Manage Function Definitions -> New)
 * --------------------------------------------------------------------------
 *                         Date           Author                      Description
 * ---------------------------------------------------------------------------
 * @version 1.1           28/10/2024     Karen Sanchez (karsanchez)   HDU 427209 - Se agrega método findLastElementArray para encontrar el ultimo elemento de un JSON
 * @version 1.2           20/ENE/2024    Karen Sanchez (karsanchez)   HDU 425302 - Se agrega método getPicklistLabel para retornar el nombre de las label y no los APIS del campo tipo y subtipo de una orden
 * @version 1.3           13/FEB/2025    Gabriel Alvis                HDU 545234 - Se agrega método jSONObjToArray para trasponer los campos de un objeto en una lista de registros con campos Key y Value
 * @version 1.4           19/NOV/2025    Eduardo Wentancur            HDU 660967 - Se agrega método toDouble para transformar de string a double 
 * @version 1.5           29/ABR/2026     Eduardo W    	  			  Bug 758564 - Se agrega método parseLatamNumber para transformar de string a currency 
**/

 global class CustomOmniStudioFunctions implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure (OmniStudio)
	 *
     * @param action  - The action/method to execute
     * @param args    - The input, output, and options arguments
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
     public Object call(String action, Map<String, Object> args) {

        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
     }

    /**
	 * Top level call by an OmniStudio DataRaptor or Integration Procedure (OmniStudio for Vlocity)
	 *
     * @param inputMap  - The input provided by the function call (i.e. contains a single entry called 'arguments')
     * @param outputMap - Any output to be provided back to the DR/IP (must contain a single entry called 'result')
     * @param options   - Any options to aid in the execution of the method although DR/IP doesn't provide any when calling this function
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        if (methodName == 'length')                  outputMap.put('result', length((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'split')              outputMap.put('result', split((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'startsWith')         outputMap.put('result', startsWith((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replace')            outputMap.put('result', replace((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replaceAll')         outputMap.put('result', replaceAll((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replaceFirst')       outputMap.put('result', replaceFirst((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'replaceAtStart')       outputMap.put('result', replaceAtStart((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'toPercentage')       outputMap.put('result', toPercentage((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'toNumber')           outputMap.put('result', toNumber((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'isNumber')           outputMap.put('result', isNumber((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'toDouble')           outputMap.put('result', toDouble((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'urlEncode')          outputMap.put('result', urlEncode((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'encrypt')            outputMap.put('result', encrypt((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'encryptIfNecessary') outputMap.put('result', encryptIfNecessary((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'denrypt')            outputMap.put('result', decrypt((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'decryptIfNecessary') outputMap.put('result', decryptIfNecessary((List<Object>)inputMap.get('arguments'))); 
        else if (methodName == 'join')               outputMap.put('result', joinString((List<Object>)inputMap.get('arguments')));        
        else if (methodName == 'removeNullValues')   outputMap.put('result', removeNullValues((List<Object>)inputMap.get('arguments')));    
        else if (methodName == 'encryptDynamic')     outputMap.put('result', encryptDynamic((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'match')              outputMap.put('result', match((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'formatCurrency')     outputMap.put('result', formatCurrency((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'parseLatamNumber')     outputMap.put('result', parseLatamNumber((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'compareDateTime')    outputMap.put('result', compareDateTime((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'currentUserHasCustomPermission') outputMap.put('result', currentUserHasCustomPermission((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'findLastElementArray') outputMap.put('result', findLastElementArray((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'getPicklistLabel')   outputMap.put('result', getPicklistLabel((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'removeDuplicates')   outputMap.put('result', removeDuplicates((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'jsonObjToArray')     outputMap.put('result', jsonObjToArray((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'insertNewLineByIndex')     outputMap.put('result', insertNewLineByIndex((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'getNowGMT') 		 outputMap.put('result', getNowGMT());
        else if (methodName == 'formatTimeToAmPm')            outputMap.put('result', formatTimeToAmPm((List<Object>)inputMap.get('arguments')));
        else if (methodName == 'evaluarHoraMaximaCancelarCasos')            outputMap.put('result', evaluarHoraMaxima((List<Object>)inputMap.get('arguments')));

        return true;
    }
    
    /**
     * This method will return the length of a string
     *
     * The method is called by Formula as follows:
     *
     * LENGTH(<input-string>)
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The length of the string
     */     
     private Integer length(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then count the characters
             return String.valueOf(args.get(0)).length();
         }

         InvalidParameterValueException e = new InvalidParameterValueException('LENGTH', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method converts a simple string value into a JSON list by splitting the source string
     * using a specified regular expression.
     *
     * The method is called by a Formula as follows:
     *
     * SPLIT(<source>, <regex>)
     *
     * where,
     * <source>  the end-to-end string to split
     * <regex>   a regular expression to use in splitting the <source> string
     * 
     * For example:
     *
     * SPLIT('Mail;Email;Phone', ';')
     * 
     * Returns:
     *
     * [
     *   "Mail",
     *   "Email",
     *   "Phone"     
     * ]
     *
     * @param args - The list of input arguments provided to the function
     *
     * @returns The list
     */
    private List<Object> split(List<Object> args) {
    		
		List<Object> theList = new List<Object>();
		
		String source;
		String regex;
		
		// Handle SPLIT(<source>, <regex>)
		if (args.size() >= 2) {
 			source = String.valueOf(args.get(0));
 			regex  = String.valueOf(args.get(1));
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('SPLIT', 'The function must be called with at least 2 arguments');
			throw e;
		}
    	
    	// Split the string
    	String[] parts = source.split(regex);
    	for (String part : parts) theList.add(part);
    	    	
    	return theList;
    }
    
    /**
     * This method determines if the given string starts with the given substring
     *
     * The method is called by a Formula as follows:
     *
     * STARTSWITH(<source>, <match>)
     *
     * where,
     * <source>  the full string to test
     * <match>   the substring to test against the <source> string
     
     * @param args - The list of input arguments provided to the function
     *
     * @returns true if the string starts with the given substring, false otherwise
     */
     private Boolean startsWith(List<Object> args) {
     	
		String source;
		String match;
     	
     	// Handle STARTSWITH(<source>, <match>)
		if (args.size() >= 2) {
 			source = String.valueOf(args.get(0));
 			match  = String.valueOf(args.get(1));
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('STARTSWITH', 'The function must be called with at least 2 arguments');
			throw e;
		}
		
		// Test if <source> starts with <match>
		return source.startsWith(match);
     }

    /**
     * This method replaces all occurrences of a substring with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACE(<source>, <match>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <match>         the substring to look for in the <source> string
     * <replacemement> the replacement string to use when a <match> is found
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replace(List<Object> args) {
     	
     	// Handle REPLACE(<source>, <match>, <replacement>)
		if (args.size() == 3) return String.valueOf(args.get(0)).replace(String.valueOf(args.get(1)), String.valueOf(args.get(2)));

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACE', 'The function must be called with at 3 arguments');
		throw e;
     }

    /**
     * This method replaces all occurrences of a substring that matches the given pattern
     * with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACEALL(<source>, <regex>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <regex>         the regular expression used to identify patterns in the <source> string
     * <replacemement> the replacement string to use
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replaceAll(List<Object> args) {
     	
     	// Handle REPLACEALL(<source>, <regex>, <replacement>)
		if (args.size() == 3) return String.valueOf(args.get(0)).replaceAll(String.valueOf(args.get(1)), String.valueOf(args.get(2)));

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACEALL', 'The function must be called with at 3 arguments');
		throw e;
     }     

    /**
     * This method replaces the first occurrence of a substring that matches the given pattern
     * with a replacement string
     *
     * The method is called by Formula as follows:
     *
     * REPLACEFIRST(<source>, <regex>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <regex>         the regular expression used to identify patterns in the <source> string
     * <replacemement> the replacement string to use
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replaceFirst(List<Object> args) {
     	
     	// Handle REPLACEFIRST(<source>, <regex>, <replacement>)
		if (args.size() == 3) return String.valueOf(args.get(0)).replaceFirst(String.valueOf(args.get(1)), String.valueOf(args.get(2)));

		InvalidParameterValueException e = new InvalidParameterValueException('REPLACEFIRST', 'The function must be called with at 3 arguments');
		throw e;
     }
     
     /**
     *This method replaces the beginning of a string with another, the number of replaced characters will be the one indicated in the second parameter and the replacement character will be the third parameter
     *
     * The method is called by Formula as follows:
     *
     * REPLACEATSTART(<source>, <quantity>, <replacement>)
     *
     * where,
     * <source>        the full string to search
     * <quantity>        quantity of replaced characters
     * <replacemement> replacement character
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A new string with all replacements made
     */
     private String replaceAtStart(List<Object> args) {     	
     	// Handle REPLACEFIRST(<source>, <regex>, <replacement>)
        //LPAD(RIGHT(FVU_DocumentNumber__c, 4), LEN(FVU_DocumentNumber__c), '*')        
		if (args.size() == 3){
            String source =String.valueOf(args.get(0));            
            String aux=source.substring(source.length()-Integer.valueOf(args.get(1)),source.length());
            source=aux.leftPad(source.length(), String.valueOf(args.get(2)));
            return source;
        }
        
        InvalidParameterValueException e = new InvalidParameterValueException('REPLACEFIRST', 'The function must be called with at 3 arguments');
		throw e;        
     }

    /**
     * This method does its best to convert a string to a number.  This is useful for stripping currency symbols from 
     * values.  It will remove any characters from the incoming String that are not digits, decimals, or negative signs
     *
     * The method is called by Formula as follows:
     *
     * TONUMBER(<input-string>)
     *
     * where,
     * <input-string>  the string to convert
     * 
     * For example:
     *
     * "5"     ==> 5
     * "0.01"  ==> 0.01
     * "$2500" ==> 2500
     * "-$23"  ==> -23
     * ""      ==> throws InvalidParameterValueException
     * "abcd"  ==> throws InvalidParameterValueException
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A number that the string converts to
     */
     private Double toNumber(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then replace any non-digits/decimal/negative characters
             String str = String.valueOf(args.get(0)).replaceAll('[^\\d.-]', '');
             return Double.valueOf(str);
         }
         InvalidParameterValueException e = new InvalidParameterValueException('TONUMBER', 'The function must be called with a single argument');
         throw e;
     }
     
    /**
     * This method determines if the incoming value is a Number
     *
     * The method is called by Formula as follows:
     *
     * ISNUMBER(<input-string>)
     *
     * where,
     * <input-string>  the string to test
     * 
     * For example:
     *
     * "5"     ==> true
     * "0.01"  ==> true     
     * "-23"   ==> true
     * "0"     ==> true
     * "$2500" ==> false
     * ""      ==> false
     * "abcd"  ==> false
     " null    ==> false
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns True if the string is a number, false otherwise
     */
     private Boolean isNumber(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             try {
             	Decimal.valueOf(String.valueOf(args.get(0)));
             }
             catch (Exception e) {
             	return false;
             }
             
             // If we make it here, it's a number
             return true;             
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ISNUMBER', 'The function must be called with a single argument');
         throw e;
     }
     
     private Double toDouble(List<Object> args) {
    // Debe venir solo 1 argumento
    if (args.size() == 1) {
        String str = String.valueOf(args.get(0));
        
        if (String.isBlank(str)) {
            InvalidParameterValueException e =
                new InvalidParameterValueException('TODOUBLE', 'Input string is blank');
            throw e;
        }
        
        
        return Double.valueOf(str);
    }
    
    InvalidParameterValueException e =
        new InvalidParameterValueException('TODOUBLE', 'La función debe llamarse con un solo argumento.');
    throw e;
}
     
    /**
     * This method URL Encodes a string into the application/x-www-form-urlencoded format
     *
     * The method is called by a Formula as follows:
     *
     * URLENCODE(<input-string>)
     *
     * where,
     * <input-string>  the string to encode
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns The URL Encoded String
     */
     private String urlEncode(List<Object> args) {
     
         // We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encode it
             return EncodingUtil.urlEncode(String.valueOf(args.get(0)), 'UTF-8');
         }
         InvalidParameterValueException e = new InvalidParameterValueException('URLENCODE', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will encrypt sensitive data
     *
     * The method is called by Formula as follows:
     *
     * ENCRYPT(<input-string>)
     *
     * where,
     * <input-string>  the string to encrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns An encrypted string
     */     
     private String encrypt(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it
             return vlocity_cmt.UserSecurity.encrypt(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ENCRYPT', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will encrypt sensitive data if the DR/IP is being executed
     * by the guest user in a Community.  This is often useful/needed for encrypting
     * SObject Ids of sensitive objects (Account Id, Cart Id, etc.)
     *
     * The method is called by Formula as follows:
     *
     * ENCRYPT_IF_NECESSARY(<input-string>)
     *
     * where,
     * <input-string>  the string to encrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns An encrypted string if the user is the guest-user, otherwise the input string as-is
     */     
     private String encryptIfNecessary(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it if needed
             return vlocity_cmt.UserSecurity.encryptIfNecessary(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('ENCRYPT_IF_NECESSARY', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will decrypt sensitive data
     *
     * The method is called by a Formula as follows:
     *
     * DECRYPT(<input-string>)
     *
     * where,
     * <input-string>  the encrypted string to decrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A decrypted string
     */     
     private String decrypt(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it
             return vlocity_cmt.UserSecurity.decrypt(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('DECRYPT', 'The function must be called with a single argument');
         throw e;
     }

    /**
     * This method will decrypt sensitive data if the DR/IP is being executed
     * by the guest user in a Community.  This is often useful/needed for decrypting
     * SObject Ids of sensitive objects (Account Id, Cart Id, etc.)
     *
     * The method is called by a Formula as follows:
     *
     * DECRYPT_IF_NECESSARY(<input-string>)
     *
     * where,
     * <input-string>  the encrypted string to decrypt
     * 
     * @param args - The list of input arguments provided to the function
     *
     * @returns A decrypted string if the user is the guest-user, otherwise the input string as-is
     */     
     private String decryptIfNecessary(List<Object> args) {
             
     	// We should only ever have 1 argument passed to this function
         if (args.size() == 1) {
             
             // Force any object first to a String and then encrypt it if needed
             return vlocity_cmt.UserSecurity.decryptIfNecessary(String.valueOf(args.get(0)));
         }
         InvalidParameterValueException e = new InvalidParameterValueException('DECRYPT_IF_NECESSARY', 'The function must be called with a single argument');
         throw e;
     }
     
     private String joinString(List<Object> args) {
    				
		List<Object> iterableObj = new List<Object>();
		String separator;
		
		if (args.size() == 2) {
 			iterableObj = (List<Object>) args.get(0);
 			separator  = String.valueOf(args.get(1));
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('JOIN', 'The function must be called with 2 arguments');
			throw e;
		}
         
         return String.join(iterableObj, separator);
    }

    private List<Object> removeNullValues(List<Object> args) {
    				
		if (args.size() > 0) {
            for (Integer i = 0; i < args.size(); i++) {
                If(args.get(i) == null || args.get(i) == ''){
                        args.remove(i);
                }
            }
		}
		else {
			InvalidParameterValueException e = new InvalidParameterValueException('REMOVENULLVALUES', 'The function must be called with at least 1 arguments');
			throw e;
		}
         
         return args;
    }

    private Blob encryptDynamic(List<Object> args){
        // Generate an AES key for the purpose of this sample. 
        // Normally this key should be stored in a protected custom setting 
        // or an encrypted field on a custom object
        String cryptoKeyString = String.valueOf(args.get(0));
        Blob cryptoKey = Blob.valueOf(cryptoKeyString);
        // Generate the data to be encrypted.
        String dataString = JSON.serialize(args.get(2));
        Blob data = Blob.valueOf(dataString);
        // Encrypt the data and have Salesforce.com generate the initialization vector
        Blob encryptedData = Crypto.encryptWithManagedIV(String.valueOf(args.get(1)), cryptoKey, data);

        return encryptedData;
    }
     
    private String match(List<Object> args) {
        
        Pattern regPattern = Pattern.compile(String.valueOf(args.get(1)));
        Matcher regMatcher = regPattern.matcher(String.valueOf(args.get(0)));
        
        return (regMatcher.find()) ? regMatcher.group() : null;
        
    }

    private String formatCurrency(List<Object> args) {
     
        // We should only ever have 1 argument passed to this function
        if (args.size() == 1) {
            
            Double myNumber = Double.valueOf(args.get(0));
            String myNumberFormat = myNumber.format();
            return myNumberFormat;
        }
        InvalidParameterValueException e = new InvalidParameterValueException('TONUMBER', 'The function must be called with a single argument');
        throw e;
    }

    private Boolean compareDateTime(List<Object> args) {
             
        // We should only ever have 1 argument passed to this function
        if (args.size() == 1) {
            
            String inputString = (String) args.get(0);
            DateTime inputDate = DateTime.valueOf(inputString);

            return System.now().getTime() > inputDate.getTime();
        }

        InvalidParameterValueException e = new InvalidParameterValueException('COMPAREDATETIME', 'The function must be called with a single argument');
        throw e;
    }

    private Boolean currentUserHasCustomPermission(List<Object> args) {
             
        // We should only ever have 1 argument passed to this function
        if (args.size() == 1) {
            
            return FeatureManagement.checkPermission((String) args.get(0));
        }

        InvalidParameterValueException e = new InvalidParameterValueException('CURRENTUSERHASCUSTOMPERMISSION', 'The function must be called with a single argument');
        throw e;
    }
    
    /**
    * @description: Retorna el ultimo nodo de una estructura JSON , pero si el parametro de entrada es vacío entonces retonará NULL.
    * @author karsanchez| 10-28-2024 
    * @param args 
    * @return Map<String, Object> 
    **/
	public static Map<String, Object> findLastElementArray(List<Object> args) {
        if (args == null || args.isEmpty()) {
            return null; // Retorna null si no hay nodos
        }
        return (Map<String, Object>)args[args.size() - 1];
    }

    /**
    * @description:Método que recibe una lista de objetos como parámetro y devuelve el label correspondiente 
    * @author karsanchez | 01-20-2025 
    * @param args -> se mandan los parametros desde un DM FUNCTION('CustomOmniStudioFunctions','getPicklistLabel','Order','Type', %Order:Type% )
    * @return String 
    **/
    public static String getPicklistLabel(List<Object> args) {
        System.debug('args:'+args);

        String objectName = (String) args[0];  // Nombre del objeto, por ejemplo, 'Order'
        String fieldName = (String) args[1];   // Nombre API del campo, por ejemplo, 'FVU_OrderSubType__c'
        String apiValue = (String) args[2];    // Valor API del picklist, por ejemplo, 'Act_migracion_Pre_Pos'
        // Obtener el esquema del objeto dinámicamente
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        // Obtener la descripción del campo (metadata) para obtener los valores del picklist
        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldName).getDescribe();
        // Verificar si el campo es de tipo picklist
        if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
            // Obtener los valores del picklist
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            // Buscar el valor API en los valores del picklist y devolver el label correspondiente
            for (Schema.PicklistEntry picklistValue : picklistValues) {
                if (picklistValue.getValue() == apiValue) {
                    return picklistValue.getLabel();
                }
            }
        } 
        return 'Valor API no encontrado';
    }
     
    private List<Object> removeDuplicates(List<Object> args) {        
        String[] stringArray = new String[args.size()];
        for (Integer i = 0; i < args.size(); i++) {
            stringArray[i] = String.valueOf(args[i]);
        }
        
        Set<String> sinDuplicados = new Set<String>(stringArray);
        List<Object> lstSinDuplicados = new List<Object>();
        for (String result : sinDuplicados) {
            Map<String,String> addValue = new Map<String,String>();
            addValue.put('beneficio',result);
            lstSinDuplicados.add(addValue);
        }
        
        return lstSinDuplicados;
    }

      /**
    * @description: Convierte un objeto JSON en una lista de objetos con los campos del JSON original distribuidos como Clave y Valor (trasponer la información)
    * @author galvis | 2025-02-13 
    * @param args -> se mandan los parametros desde un DM FUNCTION('CustomOmniStudioFunctions','jsonObjToArray', JSON Obj )
    * @return String 
    **/
    public static List<Map<String, Object>> jsonObjToArray(List<Object> args) {
        List<Map<String, Object>> lstOutput;
            Map<String, Object> mapObj = (Map<String, Object>) args[0];
            String strLlave = (String) args[1];
            String strValor = (String) args[2];
            String strTipo = (String) args[3];
            lstOutput = new List<Map<String, Object>>();
            if (mapObj.containsKey('Tipo') && mapObj.get('Tipo') != null && String.isNotEmpty((String) mapObj.get('Tipo'))) {
                    strTipo = (String) mapObj.get('Tipo');  // Asignamos el valor de "Tipo" del mapa a strTipo
            }
            for (String objLlave : mapObj.keySet()) {
            // Asegurarnos de agregar solo las claves que no sean "Tipo"
            if (objLlave != 'Tipo') {
                lstOutput.add(new Map<String, Object>{
                    strLlave => objLlave,            // "Nombre"
                    strValor => mapObj.get(objLlave), // "Valor"
                    'Tipo' => strTipo                // "Tipo"
                });
            }
        }
        return lstOutput;
    }
    
    /**
    * @description: Inserta un salto de línea dado un indice por parametro. Si el indice corta una palabra, busca la palabra anterior e inserta el salto de línea ahi.
    * @author mpaterno | 2025-03-20 
    * @param args -> String cadena y Integer indice
    * @return String 
    **/
    public static String insertNewLineByIndex(List<Object> args) {
        
        String cadena = String.valueOf(args.get(0));
        Integer indice = Integer.valueOf(args.get(1));        
        if (indice <= 0 || indice >= cadena.length()) {
        	return cadena;
    	}
    
    	String resultado = '';
    	Integer start = 0;
    	while (start < cadena.length()) {
        	Integer fin = Math.min(start + indice, cadena.length());
        	if (fin < cadena.length() && !cadena.substring(fin, fin + 1).equals(' ')) {
            	while (fin > start && !cadena.substring(fin - 1, fin).equals(' ')) {
                fin--;
            }
            
            if (fin == start) {
                fin = Math.min(start + indice, cadena.length());
            }
        }
        
            resultado += cadena.substring(start, fin).trim() + '\n';
            start = fin;
    	}	
    
    	return resultado.trim();
    }
     
     /**
        * @description: Agrega N cantidad de minutos a una fecha creada al momento
        * @author hsalas | 2025-04-25 
        * @param args -> 
        * @return String 
        **/
     public String getNowGMT(){
         String fechaNueva = Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss');
         return fechaNueva; 
     }
     
           public static String toPercentage(List<Object> args) {
        // Validación de cantidad de argumentos
        if (args == null || args.size() != 1) {
            InvalidParameterValueException e = 
                new InvalidParameterValueException('TOPERCENTAGE', 'The function must be called with a single argument');
            throw e;
        }
    
        Object arg = args[0];
    
        // Validación de null explícito
        if (arg == null) {
            InvalidParameterValueException e =
                new InvalidParameterValueException('TOPERCENTAGE', 'Input value is null');
            throw e;
        }
    
        // Convertimos el argumento a String
        String str = String.valueOf(arg);
    
        // Validación de blanco
        if (String.isBlank(str)) {
            InvalidParameterValueException e =
                new InvalidParameterValueException('TOPERCENTAGE', 'Input string is blank');
            throw e;
        }
    
        // Normalizamos el string
        String value = str.trim();
    
        // Sacamos el símbolo % si viene
        if (value.endsWith('%')) {
            value = value.substring(0, value.length() - 1).trim();
        }
    
        // Reemplazamos espacios y usamos punto para parsear
        value = value.replace(' ', '');
        value = value.replace(',', '.');
    
        Decimal numberValue;
        try {
            numberValue = Decimal.valueOf(value);
        } catch (Exception ex) {
            InvalidParameterValueException e =
                new InvalidParameterValueException('TOPERCENTAGE', 'Input is not a valid number');
            throw e;
        }
    
        // Forzamos 2 decimales
        String formatted = String.valueOf(numberValue.setScale(2));
        // Cambiamos punto por coma
        formatted = formatted.replace('.', ',');
    
        // Siempre devolvemos con espacio y símbolo de porcentaje
        return formatted + ' %';
    }


    private String parseLatamNumber(List<Object> args) {
        
        if (args == null || args.size() != 1) {
            throw new InvalidParameterValueException('FORMATCURRENCY', 'Debe recibir 1 argumento');
        }
    
        String raw = String.valueOf(args.get(0));
    
        if (String.isBlank(raw)) return null;
    
        raw = raw.trim();
    
        try {
            raw = raw.replace('.', '');   // quita miles
            raw = raw.replace(',', '.'); // convierte decimal
    
            Decimal value = Decimal.valueOf(raw);
    
            return String.valueOf(value);
    
        } catch (Exception e) {
            throw new InvalidParameterValueException(
                'FORMATCURRENCY',
                'Formato inválido: ' + raw
            );
        }
    }

    /**
    * @description: Dado una determinada fecha, evalua si este momento es mas tarde que una hora parametrizada en el sistema
    * @author hllanos
    * @param arguments ->
    * @return String
    **/
    private Boolean evaluarHoraMaxima(List<Object> arguments) {
        // 1. Obtener los argumentos enviados desde la fórmula del DataRaptor
        if (arguments == null || arguments.isEmpty() || arguments[0] == null) {
            return false;
        }

        try {
            // Limpiamos el texto para extraer yyyy-MM-dd
            String inputDateStr = String.valueOf(arguments[0]).left(10);
            Date fechaConsultada = Date.valueOf(inputDateStr);

            // 2. Leer la hora maxima desde el Custom Metadata Type
            InterfaceSettings__mdt config = InterfaceSettings__mdt.getInstance('PVU_HoraMaximaCancelacionCasos');
            String horaConfigurada = (config != null && String.isNotBlank(config.IdCode__c))
                ? config.IdCode__c.trim()
                : '22';

            Integer horaMaxima = 22;
            Integer minutoMaximo = 0;

            if (horaConfigurada.contains(':')) {
                List<String> partes = horaConfigurada.split(':');
                horaMaxima = Integer.valueOf(partes[0]);
                minutoMaximo = Integer.valueOf(partes[1]);
            } else {
                horaMaxima = Integer.valueOf(horaConfigurada);
            }

            // 3. Obtener la Fecha y Hora actual forzando la zona horaria de Colombia
            Datetime ahora = Datetime.now();

            // Extraer la fecha en Colombia y convertirla a tipo Date para compararla seguro
            String fechaColombiaStr = ahora.format('yyyy-MM-dd', 'America/Bogota');
            Date fechaActualColombia = Date.valueOf(fechaColombiaStr);

            Time horaActualColombia = Time.newInstance(
                Integer.valueOf(ahora.format('H', 'America/Bogota')),
                Integer.valueOf(ahora.format('m', 'America/Bogota')),
                0,
                0
            );

            Time horaMaximaTime = Time.newInstance(
                horaMaxima,
                minutoMaximo,
                0,
                0
            );

            // 4. Evaluar la lógica
            if (fechaActualColombia > fechaConsultada) {
                return true;
            } else if (fechaActualColombia == fechaConsultada && horaActualColombia >= horaMaximaTime) {
                return true;
            }

            return false;

        } catch (Exception e) {
            // Manejo de error si la fecha viene en un formato no parseable por Date.valueOf()
            System.debug('Error en TimeValidationHelper: ' + e.getMessage());
            return false;
        }
    }

    public static String formatTimeToAmPm(List<Object> arguments) {
        try {
            if (arguments == null || arguments.isEmpty() || arguments[0] == null) {
                return '';
            }

            String hora = String.valueOf(arguments[0]).trim();

            List<String> partes = hora.split(':');

            Integer horas = Integer.valueOf(partes[0]);
            Integer minutos = 0;

            if (partes.size() > 1 && String.isNotBlank(partes[1])) {
                minutos = Integer.valueOf(partes[1]);
            }

            String periodo = horas >= 12 ? 'PM' : 'AM';

            Integer horas12 = Math.mod(horas, 12);
            if (horas12 == 0) {
                horas12 = 12;
            }

            return String.valueOf(horas12) + ':' +
                   String.valueOf(minutos).leftPad(2, '0') +
                   ' ' + periodo;

        } catch (Exception e) {
            System.debug('Error en formatTimeToAmPm: ' + e.getMessage());
            return '';
        }
    }
}