global with sharing class PVU_CreateArrayIMEI implements vlocity_cmt.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Boolean result = true;
        try{
            if(methodName == 'arrayIMEI'){
                Map<String, Object> response =  arrayIMEI(inputMap);
                outputMap.put('response', response);
            }
        }
        catch(Exception e){
            result = false; 
            Map<String,Object> resultMap = new Map<String,Object>();
            resultMap.put('Message',  e.getMessage() + ', Line#: ' + e.getLineNumber() );
            outputMap.put('EXCEPTION', resultMap);
        }
        return result;
    }
    
    public static Map<String,Object> arrayIMEI(Map<String,Object> input){

        List<Object> reportes = (List<Object>) input.get('listaReportesBean');
        String msisdnInput = (String) input.get('msisdnInput');

        List<Map<String,Object>> editBlock2 = new List<Map<String,Object>>();
        List<Map<String,Object>> editBlock4 = new List<Map<String,Object>>();
        
        Map<String,String> operadores = new Map<String,String>();
        for (PVU_OperadorIMEI__mdt op : [SELECT CODIGO__c, DESCRIPCION__c FROM PVU_OperadorIMEI__mdt WITH SECURITY_ENFORCED]){
            operadores.put(op.CODIGO__c, op.DESCRIPCION__c);
        }
        
        Set<String> msisdnSet = new Set<String>();
        
        for(Object rep : reportes){

            Map<String,Object> lista = (Map<String,Object>) rep;
            String msisdn = (String) lista.get('msisdn');
            msisdnSet.add(msisdn);

            String masked = '';
            if(msisdn != null && msisdn.length() > 2){
                for(Integer i=0;i<msisdn.length()-2;i++){
                    masked += '*';
                }
                masked += msisdn.substring(msisdn.length()-2);
            }
            String operador = (String) lista.get('operador');
            String opText = (String) operadores.get(operador);
            
            if(opText == null){
                opText = operador;
            }

            editBlock2.add(new Map<String,Object>{
                'tipoReporte' => lista.get('tipoReporte'),
                'operador' => opText,
                'fechaReporte' => lista.get('fechaReporte'),
                'msisdn' => masked
            });

            editBlock4.add(new Map<String,Object>{
                'tipoReporte1' => lista.get('tipoReporte'),
                'msisdn1' => masked,
                'fechaReporte1' => lista.get('fechaReporte'),
                'operador1' => opText
            });
        }
		Boolean bdoMinCoincide = false;        

        if (msisdnSet.contains(msisdnInput)){
            bdoMinCoincide = true;
        }
        
        return new Map<String,Object>{
            'EditBlock2' => editBlock2,
            'EditBlock4' => editBlock4,
            'bdoMinCoincide' => bdoMinCoincide
        };
    }
}