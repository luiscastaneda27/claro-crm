/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    <Version>
22-11-2024      Hever Salas    		Utility class to Custom metadata      				Initial version
20-02-2025      Emmanuel Ruarte     Bug-551874                                          1.0.2
----------------------------------------------------------------------------*/
global with sharing class OM_MetadataUtility {    
    
    public static InterfaceSettings__mdt getInterfaceSettings (String orderType, String orderSubType, String reasonCodeOI){                                     
        InterfaceSettings__mdt interSetmdt;
        Map<String, Map<String, InterfaceSettings__mdt>> interfaceSettings = new Map<String, Map<String, InterfaceSettings__mdt>>();
        //Se filtra la busqueda de la metadata a traves del Type de la orden asociada al plan de orquestación
        List<InterfaceSettings__mdt> lstInterfaceSettings = [SELECT Id, reasonCodeFDO__c, subCausalFDO__c, orderTypeFDO__c, 
                                                             OM_OrderTypeNew__c, orderSubTypeFDO__c,
                                                             OM_OrderSubtypeNew__c, OM_Reason__c
                                                             FROM InterfaceSettings__mdt
                                                             WHERE OM_OrderTypeNew__c = :orderType
                                                             AND IdCode__c = :reasonCodeOI];
        
        for(InterfaceSettings__mdt  interSet : lstInterfaceSettings){
            //Se valida si contiene el campo OM_OrderTypeNew con valor
            if(!interfaceSettings.containsKey(interSet.OM_OrderTypeNew__c) ){
                interfaceSettings.put(interSet.OM_OrderTypeNew__c , new Map<String, InterfaceSettings__mdt>());
            }
            //Se valida si contiene el campo OM_OrderSubtypeNew__c con valor
            if(interSet.OM_OrderSubtypeNew__c != null && !interfaceSettings.get(interSet.OM_OrderTypeNew__c).containskey(interSet.OM_OrderSubtypeNew__c)){
                interfaceSettings.get(interSet.OM_OrderTypeNew__c).put(interSet.OM_OrderSubtypeNew__c, interSet);
                
            }else if(interSet.OM_OrderSubtypeNew__c == null ){
                //Para los registros que no contienen OM_OrderSubtypeNew__c y OM_OrderTypeNew se utiliza el valor * como clave genérica
                interfaceSettings.get(interSet.OM_OrderTypeNew__c).put('*', interSet);
            }
        }

        if(interfaceSettings != null && interfaceSettings.get(orderType) != null){
            interSetmdt = interfaceSettings.get(orderType).containsKey('*')?interfaceSettings.get(orderType).get('*'):interfaceSettings.get(orderType).get(orderSubType);
        }
        
        return interSetmdt;
    }

    public static InterfaceSettings__mdt getInterfaceSettingsReasonTop (String orderType, String orderSubType){             // 1.0.2                           
        
        InterfaceSettings__mdt interfaceSettings;
        //Se filtra la busqueda de la metadata a traves del Type de la orden asociada al plan de orquestación
        List<InterfaceSettings__mdt> lstInterfaceSettings = [SELECT Id, reasonCodeFDO__c, subCausalFDO__c, orderTypeFDO__c, 
                                                             OM_OrderTypeNew__c, orderSubTypeFDO__c,
                                                             OM_OrderSubtypeNew__c, OM_Reason__c
                                                             FROM InterfaceSettings__mdt
                                                             WHERE OM_OrderTypeNew__c = :orderType
                                                             AND OM_OrderSubtypeNew__c = :orderSubType];

    if (lstInterfaceSettings.size()>0) {

        for(InterfaceSettings__mdt  interSet : lstInterfaceSettings){
            //Se valida si contiene el campo OM_OrderTypeNew con valor
            if(String.isnotblank((String)interSet.OM_Reason__c) ){
                interfaceSettings = interSet;
                Break;
            }   
        }
        if (interfaceSettings==null) {

            interfaceSettings = lstInterfaceSettings[0];
        }
            
    }
        
        return interfaceSettings;
    }
}