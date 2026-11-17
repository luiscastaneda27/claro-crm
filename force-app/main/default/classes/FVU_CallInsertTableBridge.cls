public with sharing class FVU_CallInsertTableBridge {
    
    private final static String IP_TABLE_BRIDGE = 'FVU_CallInsertDataInTableBridge';

    @InvocableMethod(label='CallInsertTableBridge' description='Send request an Integration Procedure.' category='General')
    public static void callInsertTableBridge( List<String> assetId ){

        Map<String, Object> options =  new Map<String, Object>();
        Map<String, Object> inputMap =  new Map<String, Object>(); 
        inputMap.put('assetId', assetId.get(0));
        
        callProcedure(IP_TABLE_BRIDGE, JSON.serialize(inputMap), JSON.serialize(options)); 
    }

    @future(callout=true)
	public static void callProcedure(String procedureName, String inputMapStr, String optionsStr) {
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapStr);
        Map<String, Object> options = (Map<String, Object>)JSON.deserializeUntyped(optionsStr);
        Map<String, Object> args = new Map<String, Object>();
       	
        args.put('input', inputMap);
        args.put('options', options);

        FVU_CallSystemInterface callInterface = new FVU_CallSystemInterface();
        callInterface.call(procedureName, args);
    }
}