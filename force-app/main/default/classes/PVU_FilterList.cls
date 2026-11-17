/**
* @description       : 
* @author            : SALESFORCE
* @group             : 
* @last modified on  : 
* @last modified by  :
* Modifications Log
* Ver   Date         Author                                                Modification
* 1.0   03-04-2024   SALESFORCE   											Initial Version
  2.0   16-06-2026   SOPORTE-SALESFORCE 									Se agregó el método mergePaymentFinancing
**/

global with sharing class PVU_FilterList implements vlocity_cmt.VlocityOpenInterface {
    class MyException extends Exception{}
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        Boolean result = false;
        try {
            if ('getFilterList'.equalsIgnoreCase(methodName)) {
                getFilterList(inputMap,outMap);
                result = true;
            }else if ('addMinAdicion'.equalsIgnoreCase(methodName)) {
                    addMinAdicion(inputMap,outMap);
                    result = true;
            }
            else if ('splitByComa'.equalsIgnoreCase(methodName)) {
                    splitByComa(inputMap,outMap);
                    result = true;
            }else if ('unSplitByComa'.equalsIgnoreCase(methodName)) {
                    unSplitByComa(inputMap,outMap);
                    result = true;
            }else if ('promoNoValida'.equalsIgnoreCase(methodName)) {
                    promoNoValida(inputMap,outMap);
                    result = true;
            }else if ('getCasesCCV'.equalsIgnoreCase(methodName)) {
                getCasesCCV(inputMap,outMap);
                result = true;
            }else if ('mergePaymentFinancing'.equalsIgnoreCase(methodName)) {
                mergePaymentFinancing(inputMap, outMap);
                result = true;
            }
            
             
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch (Exception e) {
            system.debug('Error :' + e.getMessage());
        }
        return result;
    }
    
    public void getFilterList(Map<String,Object> inputMap,Map<String,Object> outMap){
        system.debug('filter list:' + inputMap.get('keyPrincipal'));
        system.debug('filter list:' + inputMap.get('principal'));
        String keyPrincipal = (String)inputMap.get('keyPrincipal');
        String keySecundaria = (String)inputMap.get('keySecundaria');
        List<Object> listaPrincipal =new List<Object>();
        List<Object> listaSecundaria =new List<Object>();
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        try{
            try{
                listaPrincipal = (List<Object>)inputMap.get('principal');
            }catch(Exception exList){
                //listaPrincipal = (String)inputMap.get('principal');
                listaPrincipal = new List<Object>();
            }
            
            try{
                listaSecundaria = (List<Object>)inputMap.get('secundaria');
            }catch(Exception exList){
                //listaSecundaria = (String)inputMap.get('secundaria');
                listaSecundaria = new List<Object>();
            }
            
            //system.debug('listaPrincipal:' + inputMap.get('principal'));
            //List<Object> listaPrincipal = (List<Object>)inputMap.get('principal');
            //List<Object> listaSecundaria = (List<Object>)inputMap.get('secundaria');
                                    
            boolean aux = false;
            
            Map<String,Object> itemPrincipalMap;
            Map<String,Object> itemSecundarioMap;
            
            for(Object itemPrincipal :listaPrincipal){
                itemPrincipalMap = (Map<String,Object>)itemPrincipal;
                for(Object itemSecundario :listaSecundaria){
                    itemSecundarioMap = (Map<String,Object>)itemSecundario;
                    if(itemSecundarioMap.get(keySecundaria) == itemPrincipalMap.get(keyPrincipal)){
                        aux = true;
                    }
                }
                if(aux == false){
                    result.add(itemPrincipalMap);
                }
                aux = false;
            }
        }catch(Exception ex){
            system.debug('Exception>>>causa:' + ex.getCause() + ' traza>>>>'+ex.getStackTraceString());
        }
        outMap.put('Borrado', result);
    }
    
    public void addMinAdicion(Map<String,Object> inputMap,Map<String,Object> outMap){
        String keyPrincipal = (String)inputMap.get('keyPrincipal');   
        List<Object> listaPrincipal = (List<Object>)inputMap.get('principal');
        List<Map<String,Object>> result = new List<Map<String,Object>>(); 
        Map<String,Object> itemPrincipalMap;
        
        for(Object itemPrincipal :listaPrincipal){
            itemPrincipalMap = new Map<String,Object>();
            itemPrincipalMap.put(keyPrincipal, (String)itemPrincipal);
            result.add(itemPrincipalMap);
        }
        outMap.put('Duplas', result);
    }  
    
    public void splitByComa(Map<String,Object> inputMap,Map<String,Object> outMap){        
        List<Object> listaPrincipal = (List<Object>)inputMap.get('lista');        
        Map<String,Object> itemPrincipalMap;
        String Result='';
        for(Object itemPrincipal :listaPrincipal){
            itemPrincipalMap = new Map<String,Object>();
            if(!String.isEmpty(result)){
                result=result+',';
            }
            result=result + (String)itemPrincipal;            
        }
        outMap.put('result', result);
    }  
    public void unSplitByComa(Map<String,Object> inputMap,Map<String,Object> outMap){        
        String listaPrincipal = (String)inputMap.get('lista');        
        Map<String,Object> itemPrincipalMap;
        List<String> listaResult=new List<String>();        
        listaResult=listaPrincipal.split(',');
        
        outMap.put('result', listaResult);
    }  

    public void promoNoValida(Map<String,Object> inputMap,Map<String,Object> outMap){        
        List<Object> validas = (List<Object>)inputMap.get('validas');        
        List<Object> promos=(List<Object>)inputMap.get('promos');          
        String campo=(String)inputMap.get('campo');          
        Integer index;
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (Object promociones : promos) {
            Map<String,Object> obj=(Map<String,Object>)promociones;
            result.add(obj);            
            system.debug('AÑADE A RESULT>>>>>>>>>>>>>>>>>>:' +result);         
        }
        for (Object variable : validas) {
            Map<String,Object> valida=(Map<String,Object>) variable;
            index=0;
            for (Object promo : promos) {
                Map<String,Object> promocion=(Map<String,Object>) promo;
                if (valida.get(campo) == promocion.get(campo)) {
                    result.remove(index); 
                    system.debug('REMOVIO PROMO>>>>>>>>>>>>>>>>>>:' + promocion.get('Id') +' Y '+valida.get('Id'));                   
                }   
                index++;
            }                    

        }                 
        outMap.put('result', result);
        system.debug('RESULT>>>>>>>>>>>>>>>>>>:' +result);               
    }
    
    public void getCasesCCV(Map<String,Object> inputMap, Map<String,Object> outMap) {
        
        Object rawCuentasMarcaCobranza = inputMap.get('cuentasMarcaCobranza');
        
        List<Object> rawList = (List<Object>) rawCuentasMarcaCobranza;
        List<Map<String, Object>> cuentasMarcaCobranza = new List<Map<String, Object>>();
        
        for (Object item : rawList) {
            if (item instanceof Map<String, Object>) {
                cuentasMarcaCobranza.add((Map<String, Object>) item);
            }
        }
        
        Set<String> cuentaIds = new Set<String>();
        Map<String, String> idToExternalId = new Map<String, String>();
        
        for (Map<String, Object> cuenta : cuentasMarcaCobranza) {
            if (cuenta.containsKey('Id') && cuenta.get('Id') != null &&
                cuenta.containsKey('ExternalId') && cuenta.get('ExternalId') != null) {
                    
                    String cuentaId = String.valueOf(cuenta.get('Id'));
                    String externalId = String.valueOf(cuenta.get('ExternalId'));
                    
                    cuentaIds.add(cuentaId);
                    idToExternalId.put(cuentaId, externalId);
                }
        }
        
        if (cuentaIds.isEmpty()) {
            return;
        }
        
        Map<String, Case> firstCaseByCuentaId = new Map<String, Case>();
        
        for (Case c : [
            SELECT Id, AccountId, vlocity_cmt__BillingAccountId__c, PVU_TipoSolicitudMasivos__c 
            FROM Case 
            WHERE vlocity_cmt__BillingAccountId__c IN :cuentaIds 
            AND PVU_Level3__c = 'Proceso Cobranza'
            AND PVU_TipoSolicitudMasivos__c IN ('ACTIVATE_CCV', 'DEACTIVATE_CCV')
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ]) {
            firstCaseByCuentaId.put(c.vlocity_cmt__BillingAccountId__c, c);
        }
        
        List<Map<String, Object>> casesList = new List<Map<String, Object>>();
        
        for (String cuentaId : idToExternalId.keySet()) {
            Map<String, Object> caseData = new Map<String, Object>();
            caseData.put('ExternalId', idToExternalId.get(cuentaId));
            caseData.put('Id', cuentaId);
            caseData.put('caseMarcaCobranzaId', firstCaseByCuentaId.containsKey(cuentaId) ? firstCaseByCuentaId.get(cuentaId).Id : null);
            
            casesList.add(caseData);
        }
        
        outMap.put('casesCVV', casesList);
    }
	
    /**
    * Realiza un merge entre dos listas utilizando el campo chargeBillingAccount como llave de relación.
    * Input:
    * - PaymentRef  : List<Object>
    * - Financing   : List<Object>
    *
    * Output:
    * - MergedResult: List<Map<String,Object>>
    **/
    public void mergePaymentFinancing(Map<String,Object> inputMap, Map<String,Object> outMap)
    {           
        List<Object> paymentRefsList;
        List<Object> financingsList;
    
        try{
            paymentRefsList = (List<Object>)inputMap.get('PaymentRef');    
            financingsList = (List<Object>)inputMap.get('Financing');
    
        }catch(Exception ex){               
            outMap.put('MergedResult',new List<Map<String,Object>>());
            return;
        }    	
        Map<String, Map<String,Object>> paymentMap = new Map<String, Map<String,Object>>();    
        List<Map<String,Object>> mergedResult = new List<Map<String,Object>>();
                    
        for(Object obj : paymentRefsList){
    
            Map<String,Object> payment = (Map<String,Object>) obj;    
                
            if(String.isNotBlank(String.valueOf(payment.get('chargeBillingAccount')))){
                paymentMap.put(String.valueOf(payment.get('chargeBillingAccount')),payment);
            }
        }
    
    	//Merge
        for(Object obj : financingsList){    
            Map<String,Object> financing = (Map<String,Object>)obj;    
            Map<String,Object> merged = new Map<String,Object>();
            String billingAccount = String.valueOf(financing.get('chargeBillingAccount'));                
    
            if(String.isNotBlank(billingAccount) && paymentMap.containsKey(billingAccount))
            {
                merged.putAll(paymentMap.get(billingAccount));
            }
    
            merged.putAll(financing);    
            mergedResult.add(merged);
        }    
        outMap.put('MergedResult',mergedResult);
    }
}