/**
 * W-000038: class containing useful methods for working with objects 
 */
public class ObjectUtils {
 
    /**
     * W-000038: method that given two objects and a list of field names, checks if both objects have the exact 
     * same values for all of those fields
     * 
     * @param baseObject: source object to compare
     * @param comparedObject: destination object to compare
     * @param fieldNames: list of fields to compare between objects
     */
   /* public static Boolean objectsFullyMatchFields(SObject baseObject, SObject comparedObject, List<String> fieldNames) {


        //If any field does not match, then objects are not equal
        Boolean foundUnmatchingField = baseObject.Id == comparedObject.Id;
        for (Integer i = 0; i < fieldNames.size() && !foundUnmatchingField; i++) {

            if (baseObject.get(fieldNames[i]) != comparedObject.get(fieldNames[i])) {
                foundUnmatchingField = true;
            }
        }
        return !foundUnmatchingField;
    }*/

    /**
     * W-000038: method to get a query parameter list from a list of objects 
     */
    public static String getQueryParameterArrayFromList(List<Object> objects) {
        
        String result = '';
        if (!objects.isEmpty()) {

            Boolean isString = isObjectAString(objects[0]);
            String initialString = '(';
            
            //Iteration on objects, adding them either as String or as object
            for (Integer i = 0; i < objects.size(); i++) {

                if (objects.get(i) != null) {

                    result += String.isBlank(result) ? initialString : ',';
                    result += isString && objects.get(i) != null ? '\'' + String.escapeSingleQuotes((String)objects.get(i)) + '\'' : objects.get(i);
                }
            }
            //Closure added only if String has content
            if (String.isNotBlank(result)) {
                result += ')';
            }
        }
        return result;
    }

    /**
     * W-000038: method to define if a given object is a String
     */
    private static Boolean isObjectAString(Object objectToCheck) {

        Boolean result = true;
        try {
            String convertedObject = (String)objectToCheck;
        }
        catch(Exception e) {
            result = false;
        }
        return result;
    }

    /**
     * W-000038: public inner clas to manage class's exceptions
     */
    public class  ObjectUtilsException extends Exception {}

}