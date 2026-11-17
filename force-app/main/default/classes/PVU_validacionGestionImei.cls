/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 03-27-2024
 * @last modified by  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   03-27-2024   SALESFORCE   Initial Version
**/
global with sharing class PVU_validacionGestionImei implements vlocity_cmt.VlocityOpenInterface{
    
    static global Boolean invokeMethod(String methodName, Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){        
        if (methodName == 'duplicadoImeiAccount') {
            duplicadoImeiAccount(input, outMap, options);    
        }else if (methodName == 'isImeiClaro') {
            isImeiClaro(input, outMap, options);    
        }
        return true;
    }

    /* Dev: SALESFORCE
     * Descripcion: metodo para validaciones de Imei vendido por claro y mismo titular para Duplicado de Imei
     * Fecha: 27/03/2024
     * Input: AccountId
     * Input: Imei
     * Output: Variable Booleanas para validar mensajes.
    */
    static public void duplicadoImeiAccount( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('accountId');
        String imei = (String)input.get('imei');
    
        Boolean isVendidoClaroMismoTitular = false;

        List<Asset> asset = [SELECT AccountId, PVU_IMEI__c, FVU_IMEI2__c
                            FROM Asset 
                            WHERE AccountId =:accountId 
                            AND (FVU_IMEI2__c =: imei OR PVU_IMEI__c =:imei)
                            WITH USER_MODE LIMIT 1];

        List<OrderItem> orderItem = [SELECT FVU_IMEI2__c, FVU_IMEI__c 
                                    FROM OrderItem 
                                    WHERE (Order.AccountId =:accountId AND Order.Status = 'Activated' AND Product2.Family = 'Device') 
                                    AND (FVU_IMEI__c =: imei OR FVU_IMEI2__c =:imei)
                                    WITH USER_MODE LIMIT 1];

        if(asset.size() <> 0){
            if (orderItem.size() <> 0) {
                isVendidoClaroMismoTitular = true;
            }                      
        }
        outMap.put('isVendidoClaroMismoTitular', isVendidoClaroMismoTitular);
        
    }

    static public void isImeiClaro( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){        
        String imei = (String)input.get('imei');
        system.debug('imei>>>>>'+imei);
        Boolean isVendidoClaro = false;
        String numeroFactura=null;
        String accountId=null;
        List<Asset> asset = [SELECT AccountId, PVU_IMEI__c, FVU_IMEI2__c
                            FROM Asset 
                            WHERE (FVU_IMEI2__c =: imei OR PVU_IMEI__c =:imei)
                            WITH USER_MODE LIMIT 1];

        List<OrderItem> orderItem = [SELECT FVU_IMEI2__c, FVU_IMEI__c, FVU_sapBillingNbr__c, Order.AccountId 
                                    FROM OrderItem 
                                    WHERE ( Order.Status = 'Activated' AND Product2.Family = 'Device' AND FVU_sapBillingNbr__c <> '') 
                                    AND (FVU_IMEI__c =: imei OR FVU_IMEI2__c =:imei)
                                    WITH USER_MODE LIMIT 1 ];
                                    system.debug('asset.isEmpty()>>>>>'+asset.isEmpty());system.debug('asset>>>>>'+asset);system.debug('orderItem >>>>>'+orderItem);
        if(!asset.isEmpty()){
            if (!orderItem.isEmpty()) {
                isVendidoClaro = true;
                accountId=orderItem[0].Order.AccountId;
                numeroFactura=orderItem[0].FVU_sapBillingNbr__c;
            }                      
        }

        outMap.put('isVendidoClaro', isVendidoClaro);
        outMap.put('NumeroFactura', NumeroFactura);
        outMap.put('AccountId', accountId);

        system.debug('outMap en clase>>>>>'+outMap);

        
    }
}