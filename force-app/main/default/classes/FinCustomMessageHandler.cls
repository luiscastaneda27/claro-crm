@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class FinCustomMessageHandler implements vlocity_cmt.VlocityOpenInterface {
    
    class MyException extends Exception{}
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            
            if (methodName.Equals('getConfirmationMsg')){
                 getConfirmationMsg(inputMap,outMap, options);
            }  
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch(Exception ex) {
            outMap.put('error', ex.getStackTraceString()); 
            result = false; 
        }
        return result;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
public void getConfirmationMsg( Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options)
    {
        System.debug(LoggingLevel.DEBUG,'options__'+options); 
        List<Object> params = null;
        Map<String,Object> messageMap = (Map<String,Object>) options.get('Message');
        try{
            params = options.get('confirmationParams') == null ? new List<Object>(): (List<Object>) options.get('confirmationParams');
        }
        catch(Exception e)
        {
            params =new List<Object>();
        }
        
        
        String title = '';
        String message = '';
        String type = '';
        String action = '';
        system.debug(LoggingLevel.DEBUG,'parametro ' + params);
        
        // List<ApplicationMSGs__mdt> msgs = [SELECT details__c,DeveloperName,icon__c,MasterLabel,message__c,title__c FROM ApplicationMSGs__mdt where MasterLabel = :codMSG];
        if (messageMap != null){
            title = (String) messageMap.get('TitleMessage');
            message =  (String) messageMap.get('MainMessage');
            
            type = (String)  messageMap.get('Type');
            action =  (String) messageMap.get('Action');    
            Integer paramNumber= 0;
            
            for (Object param : params){  
               //US-0053397: Added the below IF condition to handle NULL value of 'message__c' field of record of Custom Metadata Type 'ApplicationMSGs__mdt'
               system.debug(LoggingLevel.DEBUG,'moi ' + message); 
                IF(message != NULL){
                message = message.replace('{'+paramNumber+'}', String.valueOf(param));
                system.debug(LoggingLevel.DEBUG,'paramNumber***'+paramNumber + '>>>message>>>>>>>>>>>>>>>>= '+message);   
                paramNumber++;
                }
            }
        }
        
        system.debug(LoggingLevel.DEBUG,'>>>message>>>>>>>>>>>>>>>>= '+message);   
        Map<String,String> confirmation = new Map<String,String>();
        confirmation.put('TitleMessage',title);
        confirmation.put('MainMessage',message);
        confirmation.put('Type',type);
        confirmation.put('Action',action);
        
        
        outMap.put('Message',confirmation);
        
        
    }
}