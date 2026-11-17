global with sharing class PVU_ServiceOrdersRequestBuilder implements vlocity_cmt.VlocityOpenInterface, Callable{
    public PVU_ServiceOrdersRequestBuilder() {

    }
    public Object call(String action, Map<String, Object> args) {
        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        Boolean result = true;
        
        if(methodName == 'buildRequest'){
            result = buildRequest(inputMap, outputMap, options);
        }
        
        if(methodName == 'buildRequestByOds'){
            result = buildRequestByOds(inputMap, outputMap, options);
        }
        
        if(methodName == 'getInterfazSettringMTDByName'){
            result = getMetadataInterface(inputMap, outputMap, options);
        }
        return result;
    }

    public static Boolean buildRequest(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        Map<String, Object> requestHeader = new Map<String, Object>();
        requestHeader.put('documentNumber', inputMap.get('documentNumber'));
        requestHeader.put('documentType', inputMap.get('documentType'));
        requestHeader.put('headerRequest',inputMap.get('headerRequest'));
        outputMap.put('body', requestHeader);
        return true;
    }
    
    public static Boolean buildRequestByOds(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        Map<String, Object> requestHeader = new Map<String, Object>();
        requestHeader.put('idOds', inputMap.get('idOds'));
        requestHeader.put('headerRequest',inputMap.get('headerRequest'));
        outputMap.put('body', requestHeader);
        return true;
    }
    
    public static Boolean getMetadataInterface(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        Map<String, String> metadataMap = new Map<String, String> ();
        List<Object> arguments = (List<Object>) inputMap.get('arguments');
        String Key = (String)arguments[0];
        for(InterfaceSettings__mdt mtd : [SELECT Id, DeveloperName,  Identificador__c, IdCode__c FROM InterfaceSettings__mdt  where DeveloperName =: Key WITH SYSTEM_MODE])
        {
            outputMap.put('result', mtd.IdCode__c);
        } 
        return true;
    }
}