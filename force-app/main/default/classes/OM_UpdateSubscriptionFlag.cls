/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    	<Version>
28-10-24      	Hever Salas    Utility class to update the flags in Subscription      			1.0
----------------------------------------------------------------------------*/

global with sharing class OM_UpdateSubscriptionFlag implements vlocity_cmt.VlocityOpenInterface {
    class MyException extends Exception{}
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('updateFlags')){
                updateFlags(inputMap, outMap, options);
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
    
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se actualizan las banderas de la suscripción
    IN:			    MSISDNList: Lista de numeros telefonicos que se deben actualizar
                    flags: nombre de los atributos que se deben actualizar
    OUT:			Se debe actualizar los registros y devolver la lista con casos de éxito y error
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    private static void updateFlags(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        Boolean existRoamingCAN = true;
        List<String> listResultSuccess = new List<String>();
        List<String> listResultFail = new List<String>();
        List<Object> listMSISDN = (List<Object>)inputMap.get('MSISDNList');
        List<String> listStrMSISDN = new List<String>();
        String SusByCollectionsFlag = (String)inputMap.get('SusByCollectionsFlag');
        String SusByCustomerFlag = (String)inputMap.get('SusByCustomerFlag');
        String SusByFraudFlag = (String)inputMap.get('SusByFraudFlag');
        String SusByLostFlag = (String)inputMap.get('SusByLostFlag');
        String SusByTheftFlag = (String)inputMap.get('SusByTheftFlag');
        String SusByWarrantyFlag = (String)inputMap.get('SusByWarrantyFlag');
        
        Boolean bloqueoRoamingCAN = false;
        if(inputMap.containsKey('bloqueoRoamingCAN') && String.isNotBlank(String.valueOf(inputMap.get('bloqueoRoamingCAN')))){
            bloqueoRoamingCAN = (Boolean)inputMap.get('bloqueoRoamingCAN');
        }else{
            existRoamingCAN = false;
        }
        
        
        for(Object itemStr :listMSISDN){
            listStrMSISDN.add(String.valueOf(itemStr));
        }
        
        
        
        List<vlocity_cmt__Subscription__c> lstSubscription = [SELECT Id, OM_RoamingCANBlocking__c, OM_SusByCollectionsFlag__c, OM_SusByCustomerFlag__c, 
                                                              OM_SusByFraudFlag__c, OM_SusByLostFlag__c, OM_SusByTheftFlag__c, OM_SusByWarrantyFlag__c 
                                                              FROM vlocity_cmt__Subscription__c 
                                                              WHERE vlocity_cmt__Status__c IN ('Suspended','Active') 
                                                              AND OM_MSISDN__c IN :listStrMSISDN];
        
        for(vlocity_cmt__Subscription__c item: lstSubscription){
            
            if(SusByCollectionsFlag != null) item.OM_SusByCollectionsFlag__c = SusByCollectionsFlag;
            if(SusByCustomerFlag != null) item.OM_SusByCustomerFlag__c = SusByCustomerFlag;
            if(SusByFraudFlag != null) item.OM_SusByFraudFlag__c = SusByFraudFlag;
            if(SusByLostFlag != null) item.OM_SusByLostFlag__c = SusByLostFlag;
            if(SusByTheftFlag != null) item.OM_SusByTheftFlag__c = SusByTheftFlag;
            if(SusByWarrantyFlag != null) item.OM_SusByWarrantyFlag__c = SusByWarrantyFlag;
            if(existRoamingCAN){
                if(String.isNotBlank(String.valueOf(bloqueoRoamingCAN))) item.OM_RoamingCANBlocking__c = bloqueoRoamingCAN;
            }
        }
        
        try{
            Database.SaveResult[] srList = Database.update(lstSubscription, false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    listResultSuccess.add(sr.getId());
                }else{             
                    listResultFail.add(sr.getId());
                }
            }
			List<String> listMSISDNtSuccess = getMSISDN(listResultSuccess);
            List<String> listMSISDNtFail = getMSISDN(listResultFail);
            
            outMap.put('result', 'OK');
            outMap.put('OK', listMSISDNtSuccess);
            outMap.put('ERROR', listMSISDNtFail);
        }catch(Exception e){
            outMap.put('result', 'Error');
            outMap.put('Message', e.getStackTraceString());
        }    
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se obtienen los MSISDN de los registros actualizados
    IN:			    listSubsId: Lista de salesforceId para el objeto Subscription
    OUT:			Se devuelve la lista de MSISDN
	---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static List<String> getMSISDN(List<String> listSubsId){
        
        List<String> resultList = new List<String>();
        
        for(vlocity_cmt__Subscription__c item: [SELECT Id,  OM_MSISDN__c
                                                FROM vlocity_cmt__Subscription__c 
                                                WHERE vlocity_cmt__Status__c IN ('Suspended','Active') 
                                                AND Id IN :listSubsId]){
                                                                                        
        	resultList.add(item.OM_MSISDN__c);
        }
       return resultList;
    }
    
}