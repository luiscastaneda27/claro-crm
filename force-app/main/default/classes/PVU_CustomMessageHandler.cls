/**
* Created Date:
* Created By: 
* Description: Utility Class to handle custom messages in posventa's flows
-----------------------------------------------------------------------------
* Modified Date: 20240215
* Modify By: Federico Mandri
* HU: 
* Changes: New methods getMensajesPorVozDeCliente, setParametrosEnMensaje
-----------------------------------------------------------------------------
* Modified Date: 20240226
* Modify By: Hllanos
* HU: 
* Changes: new method getNotificationMessage implement to allow calling from flow
*
*/
global with sharing class PVU_CustomMessageHandler implements vlocity_cmt.VlocityOpenInterface {
    
    class MyException extends Exception{}
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            
            if (methodName.Equals('getConfirmationMsg')){
                 getConfirmationMsg(outMap, options);
            }
            else if(methodName.Equals('getMensajesPorVozDeCliente')){
                getMensajesPorVozDeCliente(inputMap,outMap, options);
            }
            else if(methodName.Equals('setParametrosEnMensaje')){
                setParametrosEnMensaje(inputMap,outMap, options);
            }
            else if(methodName.Equals('setParametrosEnMensajeIndex')){
                setParametrosEnMensajeIndex(inputMap,outMap, options);
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
    
     public void getConfirmationMsg( Map<String,Object> outMap, Map<String,Object> options)
    {
        System.debug('options__'+options); 
        List<Object> params = null;
        String codMSG = options.get('codeMSG') == null ? 'ERR001':(String) options.get('codeMSG');
        try{
            params = options.get('confirmationParams') == null ? new List<Object>(): (List<Object>) options.get('confirmationParams');
        }
        catch(Exception e)
        {
            params =new List<Object>();
        }
        
        String title = '';
        String message = '';
        String code = '';
        String action = '';
        
        String details = '';
        String icon = '';
        system.debug('>>>codMSG...>>>>>>>>>>>>>>>>= '+codMSG);
        List<MensajesPersonalizados__mdt> msgs = [SELECT Mensaje__c,Titulo__c,Codigo__c,Accion__c FROM MensajesPersonalizados__mdt where Codigo__c = :codMSG WITH SYSTEM_MODE];
        system.debug('>>>msgs...>>>>>>>>>>>>>>>>= '+msgs);   
        if (!msgs.isEmpty()){
            title = msgs[0].Titulo__c;
            message = msgs[0].Mensaje__c;
            action=msgs[0].Accion__c;
            
            //code = msgs[0].Codigo__c;                     
            Integer paramNumber= 0;
            
            for (Object param : params){  
               //Added the below IF condition to handle NULL value of 'message__c' field of record of Custom Metadata Type 'MensajesPersonalizados__mdt' 
                IF(message != NULL){
                message = message.replace('{'+paramNumber+'}', String.valueOf(param));
                system.debug('paramNumber***'+paramNumber + '>>>message>>>>>>>>>>>>>>>>= '+message);   
                paramNumber++;
                }
            }
        } 
        system.debug('>>>message>>>>>>>>>>>>>>>>= '+message);   
        Map<String,String> confirmation = new Map<String,String>();
        confirmation.put('message',message);
        confirmation.put('title',title);
        confirmation.put('action',action);
        
        /*Map<String,String> selectableIconConfig = new Map<String,String>();
        selectableIconConfig.put('size','large');
        selectableIconConfig.put('category','utility');
        selectableIconConfig.put('icon',icon);*/
        
        outMap.put('confirmation',confirmation);
      //  outMap.put('selectableIconConfig',selectableIconConfig);  
      system.debug('----configuration message out-----:'+ outMap);   
        
    }
    
    /*
	* Created Date: 20240215
	* Created By: Federico Mandri
	* HU: 
	* Description: return within output map key/value pairs Codigo/Mensaje from Custom Metadata PVU_MensajesGestiones__mdt
	*/
    public void getMensajesPorVozDeCliente(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        
        String vozCliente = (String)inputMap.get('VozCliente');
        
        Map<String, String> mapaMensajes = new Map<String, String>();
        
        List<PVU_MensajesGestiones__mdt> mensajes = new List<PVU_MensajesGestiones__mdt>([SELECT Id, Codigo__c, MensajeArea__c, VozCliente__c
                                                     		FROM PVU_MensajesGestiones__mdt
                                                    		WHERE VozCliente__c = :vozCliente WITH SYSTEM_MODE LIMIT 50]);
        for(PVU_MensajesGestiones__mdt mensaje: mensajes){
            mapaMensajes.put(mensaje.Codigo__c, mensaje.MensajeArea__c);
        }
        
        outMap.put('mensajes', mapaMensajes);
    }
    
    /*
	* Created Date: 20240422
	* Created By: Hllanos
	* HU: 
	* Description: return within output map key/value pairs Codigo/Mensaje from Custom Metadata PVU_MensajesGestiones__mdt
	*/
    public static Map<String, String> getMensajesPorCodigo(String keymsj){
        Map<String, String> mapaMensajes = new Map<String, String>();
        
        List<PVU_MensajesGestiones__mdt> mensajes = new List<PVU_MensajesGestiones__mdt>([SELECT Id, Codigo__c, MensajeArea__c, VozCliente__c
                                                     		FROM PVU_MensajesGestiones__mdt
                                                    		WHERE Codigo__c = :keymsj WITH SYSTEM_MODE LIMIT 50]);
        for(PVU_MensajesGestiones__mdt mensaje: mensajes){
            mapaMensajes.put(mensaje.Codigo__c, mensaje.MensajeArea__c);
        }
        
        return mapaMensajes;
    }
    
     /*
	* Created Date: 20240215
	* Created By: Federico Mandri
	* HU: 
	* Description: given parameters and message within options map, replace the parameteres in the message
	*/
    public void setParametrosEnMensaje(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        String mensaje = (String)inputMap.get('mensaje');
        List<Object> parametros = (List<Object>)inputMap.get('parametros');
        System.debug('Mensaje: ' + mensaje);
        System.debug('Parametros: ' + parametros);
        
        if(String.isNotBlank(mensaje) && !parametros.isEmpty()){
            Integer paramIndex = 0;
            for(Object parametro: parametros){
                mensaje = mensaje.replace('{'+paramIndex+'}', String.valueOf(parametro));
                paramIndex ++;
                System.debug('Mensaje parseado parcial: ' + mensaje);
            }
            
            outMap.put('mensajeParametrizado', mensaje);
            System.debug('Mensaje a la salida: ' + outMap.get('mensajeParametrizado'));
        }
        else{
            outMap.put('errorCode','400');
            outMap.put('errorMessage', 'No hay parametros para reemplazar en el mensaje o el mensaje está vacío');
        }
    }
    
    /*
	* Created Date: 20240408
	* Created By: Hever Salas
	* HU: 
	* Description: given parameters and message within options map, replace the parameteres in the message
	*/
    public void setParametrosEnMensajeIndex(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        String mensaje = (String)inputMap.get('mensaje');
        Integer paramIndex = Integer.valueOf(inputMap.get('index'));
        List<Object> parametros = (List<Object>)inputMap.get('parametros');
        System.debug('Mensaje: ' + mensaje);
        System.debug('Parametros: ' + parametros);
        
        if(String.isNotBlank(mensaje) && !parametros.isEmpty()){
            //Integer paramIndex = 0;
            for(Object parametro: parametros){
                mensaje = mensaje.replace('{'+paramIndex+'}', String.valueOf(parametro));
                paramIndex ++;
                System.debug('Mensaje parseado parcial: ' + mensaje);
            }
            
            outMap.put('mensajeParametrizado', mensaje);
            System.debug('Mensaje a la salida: ' + outMap.get('mensajeParametrizado'));
        }
        else{
            outMap.put('errorCode','400');
            outMap.put('errorMessage', 'No hay parametros para reemplazar en el mensaje o el mensaje está vacío');
        }
    }
    
     /*
	* Created Date: 20240226
	* Created By: hllanos
	* HU: 
	* Description: Implementation from flow call - given parameters and message within options map, replace the parameteres in the message
	*/
    @InvocableMethod(label='buildNotificationMessage' description='Get text message from metadata')
    public static List<getNotificationMessageOutput> getNotificationMessage( List<getNotificationMessageInput> input ){
        //get notification text from codemsj
        PVU_CustomMessageHandler cl = new PVU_CustomMessageHandler();
        Map<String, String> map_text_message = getMensajesPorCodigo(input.get(0).msgId);
        
        //Set Params in message
        Map<String, Object> inputMap2 = new Map<String, Object>();
        Map<String,Object> outMap2 = new Map<String,Object>();
        List<Object> parametros = (List<Object>)input.get(0).fieldValuesToReplace;
        inputMap2.put('mensaje', map_text_message.get(input.get(0).msgId));
        inputMap2.put('parametros', parametros);
        cl.setParametrosEnMensaje(inputMap2, outMap2, null);
        
        getNotificationMessageOutput output = new getNotificationMessageOutput();
        List <getNotificationMessageOutput> listOutput = new List <getNotificationMessageOutput>();
        output.mensaje = (String)outMap2.get('mensajeParametrizado');
        listOutput.add(output);
        
        return listOutput;
    }
    
     public class getNotificationMessageInput {
        @InvocableVariable (label = 'Message Metadata Id') public String msgId;
        @InvocableVariable (label = 'Field Values to Replace') public List<String> fieldValuesToReplace;
     }
    
    global class getNotificationMessageOutput{
        @InvocableVariable(label = 'Message text') public String mensaje;
    }
}