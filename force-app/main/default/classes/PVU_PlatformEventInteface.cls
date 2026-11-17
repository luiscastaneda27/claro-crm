/*******************************************************************************
* Autor: hllanos
* Fecha: 2024-05-28
* Equipo: Pos-Ventas
* Descripcion: Utility class para publicar eventos de plataforma para ejecutar ip asyncronos
* History
<Date>            <Author>             <Description>             <Version>
2026-01-21        Hllanos               creacion                   01
***********************************************************************************/
global class PVU_PlatformEventInteface implements vlocity_cmt.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('publishCompletionEvent')){
                Map<String, Object> response = publishCompletionEvent(inputMap, outMap, options);
            }
            
        } catch(Exception ex) {
            outMap.put('error', ex.getMessage()); 
            outmap.put('isSuccess', false);
            result = false; 
        }
        return result;
    }
    
    
    global Map<String,Object> publishCompletionEvent(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        system.debug('publishCompletionEvent init:' + DateTime.now().getTime());
        // 1. Extract variables from the Input Map (sent from IP)
        String correlationId = (String) inputMap.get('correlationId');
        Object rawPayload = inputMap.get('payload');
        
        // 2. Create the Event Instance
        PVU_Async_Process__e event = new PVU_Async_Process__e();
        event.PVU_CorrelationId__c = correlationId;
        if (rawPayload != null) {
            try {
                event.PVU_PayLoad__c = JSON.serialize(rawPayload);
            } catch (Exception e) {
                System.debug('Error serializando payload: ' + e.getMessage());
            }
        }
        
        // 3. Publish the Event
        Database.SaveResult result = EventBus.publish(event);
        
        // 4. Check results and return to IP
        if (result.isSuccess()) {
            System.debug('Successfully published event: ' + correlationId);
            outMap.put('success', true);
        } else {
            for (Database.Error err : result.getErrors()) {
                System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
            outMap.put('success', false);
            outMap.put('error', 'Failed to publish event');
        }
        
        return outMap;
    }
}