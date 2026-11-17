global with sharing class PVUCustomerVoice implements vlocity_cmt.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            
            if (methodName.Equals('getCustomerVoice')){
                 getCustomerVoice(inputMap,outMap, options);
            }             
        } catch(Exception ex) {
            outMap.put('error', ex.getStackTraceString()); 
            result = false; 
        }
        return result;
    }
    
    public void getCustomerVoice( Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        System.debug(LoggingLevel.DEBUG,'options__'+options); 
        
        List<Map<String,Object>> optionsList = new List<Map<String,Object>>();
        String warranty = (String) inputMap.get('Warranty');
        String notConforming =(String) inputMap.get('notConforming');        
        String RetractoCompra =(String) inputMap.get('RetractoCompra');
        Boolean flagAfterDateThreeDays =(Boolean) inputMap.get('flagAfterDateThreeDays'); 
        system.debug('notConforming>>>>>'+notConforming);
                            
        Map<String,Object> option1= new Map<String,Object>();
        option1.put('label',warranty);
        option1.put('value',warranty);
        optionsList.add(option1);
        if(!String.isBlank(notConforming)){
            Map<String,Object> option2= new Map<String,Object>();
            option2.put('label',notConforming);
            option2.put('value',notConforming);
            optionsList.add(option2);
        }
         if(flagAfterDateThreeDays){
        Map<String,Object> option3= new Map<String,Object>();
        option3.put('label','Falla técnica en la entrega (Muerto en Caja-DOA)');
        option3.put('value','Falla técnica en la entrega (Muerto en Caja-DOA)');
        optionsList.add(option3);
        }     
        Map<String,Object> option4= new Map<String,Object>();
        option4.put('label','Configuración de Equipo (Solución en Primer Contacto)');
        option4.put('value','Configuración de Equipo (Solución en Primer Contacto)');
        optionsList.add(option4);
        if(!String.isBlank(RetractoCompra)){
            Map<String,Object> option5= new Map<String,Object>();
            option5.put('label',RetractoCompra);
            option5.put('value',RetractoCompra);
            optionsList.add(option5);
        }
        
        outMap.put('ListOptions',optionsList);
        
        
    }   

}