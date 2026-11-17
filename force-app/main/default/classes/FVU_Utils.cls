global class FVU_Utils implements vlocity_cmt.VlocityOpenInterface, Callable {
    
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            if (methodName == 'ValidFraude') {
                result = validFraude(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG,'***** EXCEPTION  In FVU_Utils.invokeMethod() - e.getMessage(): ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause() );
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }

    public static Boolean validFraude(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        try {
            List<String> listMarkIdFraude = new List<String>{'FR', 'BCM', 'BLF'};
            Boolean existFraude = false;
            String fraude = '';

            Map<String, Object> mapAddresses = (Map<String, Object>) inputMap.get('addresses');
            if (mapAddresses.containsKey('listHhpps')) {
               List<Object> listHhpps = (List<Object>) mapAddresses.get('listHhpps');
               for (Object hhpp : listHhpps) {
                    Map<String, Object> mapHhpp = (Map<String, Object>) hhpp;
                    if (mapHhpp.containsKey('listAddresMarks') && !existFraude) {
                        List<Object> listAddresMarks = (List<Object>) mapHhpp.get('listAddresMarks');
                        for (Object addresMark : listAddresMarks) {
                            Map<String, Object> mapAddresMark = (Map<String, Object>) addresMark;
                            if (listMarkIdFraude.contains(String.valueOf(mapAddresMark.get('markId')))) {
                                existFraude = true;  
                                fraude = String.valueOf(mapAddresMark.get('markId'));
                                break;
                            }
                        }
                    }
               }
            }
            outputMap.put('fraudMarkExists', existFraude);
            outputMap.put('fraudMarkId', fraude);
            return true;

        } catch (Exception e) {
            throw e;
        }
    }
}