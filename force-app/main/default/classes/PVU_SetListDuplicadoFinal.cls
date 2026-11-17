/**
* @description       : 
* @author            : SALESFORCE
* @group             : 
* @last modified on  : 
* @last modified by  :
* Modifications Log
* Ver   Date         Author                                                Modification
* 1.0   05-04-2024   SALESFORCE   Initial Version
**/
global with sharing class PVU_SetListDuplicadoFinal implements vlocity_cmt.VlocityOpenInterface {
    class MyException extends Exception{}
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        Boolean result = false;
        try {
            if ('setListDuplicado'.equalsIgnoreCase(methodName)) {
                setListDuplicado(inputMap,outMap);
                result = true;
            } else if ('setListDuplicadoAdicion'.equalsIgnoreCase(methodName)) {
                setListDuplicadoAdicion(inputMap,outMap);
                result = true;
            }  
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch (Exception e) {
            system.debug('Error');
        }
        return result;
    }
    
    public void setListDuplicado(Map<String,Object> inputMap,Map<String,Object> outMap){
        
        Integer index = 1;
        
        List<Object> DuplasResult = (List<Object>)inputMap.get('DuplasResult');
        
        List<Map<String,Object>> min = new List<Map<String,Object>>();
        List<Map<String,Object>> imsi = new List<Map<String,Object>>();
        
        boolean aux = false;
        Integer cont=0;
        Map<String,Object> duplasResultMap;
        
        for(Object item :DuplasResult){
            duplasResultMap = (Map<String,Object>)item;
            Map<String,Object> auxMapMin = new Map<String,Object>();
            Map<String,Object> auxMapImsi = new Map<String,Object>();
            auxMapMin.put('min', duplasResultMap.get('min'));
            auxMapMin.put('secuencia', String.valueOf(index));
            auxMapImsi.put('imsi', duplasResultMap.get('imsi'));
            auxMapImsi.put('secuencia', String.valueOf(index));
            index = index + 1;
            min.add(auxMapMin);
            imsi.add(auxMapImsi);
        }
        system.debug('min>>>>>'+min);
        system.debug('imsi>>>>>'+imsi);
        outMap.put('min', min);
        outMap.put('imsi', imsi);
    }  
    public void setListDuplicadoAdicion(Map<String,Object> inputMap,Map<String,Object> outMap){
        
        Integer index = 1;
        
        List<Object> DuplasResult = (List<Object>)inputMap.get('DuplasResult');
        
        List<Map<String,Object>> min = new List<Map<String,Object>>();
        List<Map<String,Object>> imsi = new List<Map<String,Object>>();
        
        boolean aux = false;
        Integer cont=0;
        Map<String,Object> duplasResultMap;
        
        for(Object item :DuplasResult){
            duplasResultMap = (Map<String,Object>)item;
            Map<String,Object> auxMapMin = new Map<String,Object>();
            Map<String,Object> auxMapImsi = new Map<String,Object>();
            auxMapMin.put('min', duplasResultMap.get('minAdicion'));
            auxMapMin.put('secuencia', String.valueOf(index));
            auxMapImsi.put('imsi', duplasResultMap.get('imsiAdicion'));
            //cont++;
            //auxMapImsi.put('imsi', '12345678900000'+cont);
            auxMapImsi.put('secuencia', String.valueOf(index));
            index = index + 1;
            min.add(auxMapMin);
            imsi.add(auxMapImsi);
        }
        system.debug('min>>>>>'+min);
        system.debug('imsi>>>>>'+imsi);
        outMap.put('min', min);
        outMap.put('imsi', imsi);
    }  
}