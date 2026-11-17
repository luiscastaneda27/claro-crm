/*****************************************************************************
* Autor: Sara Garrido
* Fecha: 2024-05-07
* Equipo: Pos-Ventas
* Descripcion: Clase utilitaria para Activación y Desactivación
* Modificaciones: 2024-05-07 
* Version  Date          Developer             Modification
* 1.0      2024-05-07    Sara Garrido          Initial version
* 1.1      15/01/2025    Leonardo Carranza     Bug 712610, en método invokeMethod devolver OrderCaseInfo si no hay promociones.
***********************************************************************************/

global with sharing class PVU_ActivacionDesactivacionUtils implements vlocity_cmt.VlocityOpenInterface{
    public  Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Boolean result = true;
        try{
            if (methodName.equals('getDataOrder')){
            	getDataOrder(input, outMap, options);
        	}
        }
        catch(Exception ex){
            outMap.put('error', ex.getStackTraceString()); 
            outMap.put('MensajeExcepcion', ex.getMessage());
            outMap.put('Linea', ex.getLineNumber());
            outMap.put('Causa', ex.getCause());
           
            result = false;
        }
        
        return result;
    }
    
    /************************************************************************
     * Autor: Sara Garrido
     * Fecha: 2024-05-07
     * Equipo: Pos-Ventas
     * HU: 
     * Input: OrderId
     * Descripcion: este metodo se usa para traer información de la Orden y Orden Items
     * update: se agrega order.caseinfo en la respuesta
     * update: se agrega casos relacionados a la orden
	*/
    public void getDataOrder(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        try{
            String orderId = (String)input.get('OrderId');
            List<Object> lstOrderItemsFilter = new List<Object>();
            List<Case> lstCases = new List<Case>();
            String vozCliente = 'N/A';
            String accountId = '';
            
            List<OrderItem> lstOrderItemsAll = [SELECT vlocity_cmt__action__c, 
                                                    FVU_EffectiveRecurringTotalIncTaxes__c, 
                                                    Product2.Name,Product2.vlocity_cmt__SubType__c,
                                                    Product2.ProductCode,Order.FVU_OrderSubType__c,
                                                    Order.AccountId, vlocity_cmt__AssetId__c, 
                                                    vlocity_cmt__ReliesOnItemId__c, order.PVU_CaseInfo__c,
                                                	FVU_EffectiveOneTimeTotalIncTaxes__c
                                                    FROM OrderItem 
                                                    WHERE OrderId =: orderId WITH USER_MODE];
            
            
            lstCases = [SELECT Id, PVU_Order__c, CaseNumber FROM Case WHERE PVU_Order__c =: orderId WITH USER_MODE];
            
            
            if (!lstOrderItemsAll.isEmpty()) {
                accountId = lstOrderItemsAll[0].Order.AccountId;

                //GetCaseInfo
                Map<String, Object> caseInfoMap =  (Map<String, Object>)JSON.deserializeUntyped(lstOrderItemsAll[0].Order.PVU_CaseInfo__c);
				Boolean esRetencion = (Boolean)caseInfoMap.get('esRetencion');
                outMap.put('esRetencion', esRetencion);
                String vozclienteSource = (String)caseInfoMap.get('vozCliente');
                
                if(esRetencion == true && vozclienteSource != null){
                    vozCliente = vozclienteSource;
                }else{
                    if (lstOrderItemsAll[0].Order.FVU_OrderSubType__c == 'Adicion_de_Adicionales'){
                        vozCliente = 'Activación de servicios adicionales';
                    } else if (lstOrderItemsAll[0].Order.FVU_OrderSubType__c == 'Eliminacion_de_Adicionales'){
                        vozCliente = 'Desactivación de servicios adicionales';
                    }
                }

                String actionFilter;
                if (vozCliente == 'Activación de servicios adicionales') {
                    actionFilter = 'Add';
                }else if (vozCliente == 'Desactivación de servicios adicionales') {
                    actionFilter = 'Disconnect';
                }else if (vozCliente == 'Beneficios para tu plan') {
                    actionFilter = 'SearchPromos';
                }
                
                if(vozCliente == 'Activación de servicios adicionales' || vozCliente == 'Desactivación de servicios adicionales'){
                    for(OrderItem ordItem : lstOrderItemsAll){
                        if (actionFilter != null && actionFilter == ordItem.vlocity_cmt__action__c) {                            
                            Map<String, String> orderItemObj = new Map<String, String>();
                            orderItemObj.put('price',String.valueOf(ordItem.FVU_EffectiveRecurringTotalIncTaxes__c != 0? 
                                                                    ordItem.FVU_EffectiveRecurringTotalIncTaxes__c:
                                                                    ordItem.FVU_EffectiveOneTimeTotalIncTaxes__c));
                            orderItemObj.put('productName', ordItem.Product2.Name);
                            orderItemObj.put('releaseOnItemId', ordItem.vlocity_cmt__ReliesOnItemId__c);
                            orderItemObj.put('subType', ordItem.Product2.vlocity_cmt__SubType__c);
                            orderItemObj.put('productCode', ordItem.Product2.ProductCode);
                            orderItemObj.put('caseInfo', ordItem.order.PVU_CaseInfo__c);
                            lstOrderItemsFilter.add(orderItemObj);
                        }
                    }
                }else{
                    if(vozCliente == 'Beneficios para tu plan'){
                        //Buscamos si existe alguna promocion tipo CFM agregada al carrito
                        List <vlocity_cmt__OrderAppliedPromotionItem__c> listPromos;
                        listPromos = [SELECT Id,vlocity_cmt__OrderItemId__r.FVU_EffectiveRecurringTotalIncTaxes__c,vlocity_cmt__OrderItemId__r.Product2.Name, 
                                          vlocity_cmt__OrderItemId__r.vlocity_cmt__ReliesOnItemId__c,vlocity_cmt__OrderItemId__r.Product2.vlocity_cmt__SubType__c,
                                          vlocity_cmt__OrderItemId__r.Product2.ProductCode, vlocity_cmt__OrderItemId__r.order.PVU_CaseInfo__c,vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.Name,
                                           vlocity_cmt__OrderItemId__r.vlocity_cmt__AssetReferenceId__c
                                          FROM vlocity_cmt__OrderAppliedPromotionItem__c
                                          WHERE vlocity_cmt__OrderItemId__r.OrderId =:orderId
                                          AND vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = 'Obsequios de CFM' 
                                          AND  vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__Action__c = 'Add'
                                          WITH USER_MODE];
                            system.debug('listPromos'+listPromos);
                        
                        
                        if(listPromos.size() > 0){
                            Map<String, String> orderItemObj = new Map<String, String>();
                            orderItemObj.put('price', String.valueOf(listPromos[0].vlocity_cmt__OrderItemId__r.FVU_EffectiveRecurringTotalIncTaxes__c));
                            orderItemObj.put('productName', listPromos[0].vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.Name);
                            orderItemObj.put('releaseOnItemId', listPromos[0].vlocity_cmt__OrderItemId__r.vlocity_cmt__AssetReferenceId__c);
                            orderItemObj.put('subType', listPromos[0].vlocity_cmt__OrderItemId__r.Product2.vlocity_cmt__SubType__c);
                            orderItemObj.put('productCode', listPromos[0].vlocity_cmt__OrderItemId__r.Product2.ProductCode);
                            orderItemObj.put('caseInfo', listPromos[0].vlocity_cmt__OrderItemId__r.order.PVU_CaseInfo__c);
                            lstOrderItemsFilter.add(orderItemObj);
                        }else{
                            Map<String, String> orderItemObj = new Map<String, String>();
                            outMap.put('OrderCaseInfo', lstOrderItemsAll[0].Order.PVU_CaseInfo__c);
                        }
                    }
                }
            }

            String paramMessage = '';

            for(Object obj : lstOrderItemsFilter){
                Map<String, String> orderItemObj =  (Map<String, String>) obj;
                if(vozCliente != 'Beneficios para tu plan'){
                    paramMessage += orderItemObj.get('productName') + ' con costo mensual '+ orderItemObj.get('price') + ', ';
                }else{
                	paramMessage += orderItemObj.get('productName');
                }
                
            }
            paramMessage = paramMessage.trim().removeEnd(',');

            outMap.put('lstOrderItems', lstOrderItemsFilter);
            outMap.put('lstOrderItemsSize', lstOrderItemsFilter.size());
            outMap.put('paramMessage', paramMessage);
            outMap.put('VozCliente', vozCliente);
            outMap.put('AccountId', accountId);
            if(lstCases.size() > 0 ){
                Map<String, String> caseRelated = new Map<String, String> ();
                caseRelated.put('CaseId', lstCases[0].Id);
                caseRelated.put('CaseNumber', lstCases[0].CaseNumber);
                outMap.put('RelatedCaseInfo', caseRelated);
            }
            if(lstOrderItemsFilter.size() >0 ){
                Map<String, String> firstOrderItem =  (Map<String, String>) lstOrderItemsFilter[0];
            	outMap.put('OrderCaseInfo', firstOrderItem.get('caseInfo'));
            }
        }catch(Exception ex){
            system.debug('error:' + ex.getMessage());
            throw ex;
        }
    }

}