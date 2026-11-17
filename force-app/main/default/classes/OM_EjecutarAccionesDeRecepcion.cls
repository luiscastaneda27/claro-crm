/*--------------------------------------------------------------------------
Autor: Hever Salas - hever.salas@nespon.com
Compania: Salesforce.com
Descripcion:    
Clase de Prueba: OM_EjecutarAccionesDeRecepcionTest
Cobertura:  96%
Historial
<Fecha>       <Version>	  <Autor>          <Descripcion>             					
22-01-2026     1.0.0     Hever Salas      	Initial        
----------------------------------------------------------------------------*/

global with sharing class OM_EjecutarAccionesDeRecepcion implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    class notificationException extends Exception{}
  
    
    global  void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {
        Map <String, Object> ipInput = new Map <String, Object> ();
        Map <String, Object> ipOutput = new Map <String, Object> ();
        Map <String, Object> ipOptions = new Map <String, Object> ();

        vlocity_cmt__OrchestrationItem__c orchesItem = [SELECT Id, vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c,
                                                        vlocity_cmt__OrchestrationPlanId__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.Type,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.FVU_OrderSubType__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.AccountId,
                                                        vlocity_cmt__FulfilmentRequestLineId__c,
                                                        vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SubAction__c,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.OrderNumber,
                                                        vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c
                                                        FROM vlocity_cmt__OrchestrationItem__c
                                                        where id = :item[0].Id
                                                        WITH SECURITY_ENFORCED
                                                        LIMIT 1];
        
        List<OrderItem> lstOrderItem = [SELECT Id, vlocity_cmt__SubscriptionId__r.OM_MSISDN__c, vlocity_cmt__SerialNumber__c,
                                        vlocity_cmt__SubscriptionId__r.OM_Contract__c, Product2.vlocity_cmt__Type__c,
                                        vlocity_cmt__Action__c, Product2.ProductCode
                                        FROM OrderItem
                                        WHERE OrderId = :orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c 
                                        WITH SECURITY_ENFORCED];
        
        String suscriberNumber = '';
        String serialNumber = '';
        String customerId = orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c;
        String customerOrderStatus = OrderIntegrationSystemInterfaceConstants.getValue('O_R_PRO');
        String externalId = orchesItem.vlocity_cmt__OrchestrationPlanId__c;
        String serviceOrderStatus = OrderIntegrationSystemInterfaceConstants.getValue('C_C');
        String type = OrderIntegrationSystemInterfaceConstants.getValue('ServiceOrderNotification');
        Datetime dateFechaActual = Datetime.now();
        String strFechaActual = dateFechaActual.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        String CrmOrderId = OrderIntegrationSystemInterfaceConstants.getValue('ORDSFQ')+orchesItem.vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__r.OrderNumber;
        String fulfilmentRequestLineId = orchesItem.vlocity_cmt__FulfilmentRequestLineId__c;
        String orderType = OrderIntegrationSystemInterfaceConstants.getValue('ORDER_TYPE');
        String contractId = '';
        List<String> lstProductos = new List<String>();
        
        if(lstOrderItem.size() > 0){
            for(OrderItem oi: lstOrderItem){
                if(oi.Product2.vlocity_cmt__Type__c == OrderIntegrationSystemInterfaceConstants.getValue('SIM_CARD_STR')){
                    suscriberNumber = oi.vlocity_cmt__SubscriptionId__r.OM_MSISDN__c;
                    serialNumber = oi.vlocity_cmt__SerialNumber__c;
                    contractId = oi.vlocity_cmt__SubscriptionId__r.OM_Contract__c;
                }
                if(oi.vlocity_cmt__Action__c == 'Add'){
                    lstProductos.add(oi.Product2.ProductCode);
                }
            }
        }
        
        ipInput.put('channel', 'Salesforce');
        ipInput.put('customerId', customerId);
        ipInput.put('customerOrderStatus', customerOrderStatus);
        ipInput.put('externalId', externalId);
        ipInput.put('serviceOrderDate', strFechaActual);
        ipInput.put('serviceOrderStatus', serviceOrderStatus);
        ipInput.put('serviceOrderSubType', 'Configuration Change');
        ipInput.put('serviceOrderType', 'Change');
        ipInput.put('suscriberNumber', suscriberNumber);
        ipInput.put('type', type);
        
        Map<String,Object> mapOrderItems = new Map<String,Object>();
        List<Map<String,Object>> lstOrderItems = new List<Map<String,Object>>();
        
        //Se agrega el producto PO_MovPosBasico
        Map<String,Object> mapInputParam = new Map<String,Object>();
        mapInputParam.put('CrmOrderId',CrmOrderId);
        mapInputParam.put('fulfilmentRequestLineId',fulfilmentRequestLineId);
        mapInputParam.put('contractId',contractId);
        mapInputParam.put('serialNumber',serialNumber);
        mapInputParam.put('strFechaActual',strFechaActual);
        mapInputParam.put('orderType',orderType);
        mapInputParam.put('action', OrderIntegrationSystemInterfaceConstants.getValue('ACTION_NO_CHANGE'));
        mapInputParam.put('nombreProducto',OrderIntegrationSystemInterfaceConstants.getValue('TECHNICAL_PARENT_PRODUCT'));
        mapOrderItems = agregarProductos(mapInputParam);
        lstOrderItems.add(mapOrderItems);
        
        //Se agrega el resto de productos con Accion Add
        for(String strItem :lstProductos){
            mapInputParam = new Map<String,Object>();
            mapOrderItems = new Map<String,Object>();
            mapInputParam.put('CrmOrderId',CrmOrderId);
            mapInputParam.put('fulfilmentRequestLineId',fulfilmentRequestLineId);
            mapInputParam.put('contractId',contractId);
            mapInputParam.put('serialNumber',serialNumber);
            mapInputParam.put('strFechaActual',strFechaActual);
            mapInputParam.put('orderType',orderType);
            mapInputParam.put('action',OrderIntegrationSystemInterfaceConstants.getValue('S_ADD'));
            mapInputParam.put('nombreProducto',strItem);
            mapOrderItems = agregarProductos(mapInputParam);
        	lstOrderItems.add(mapOrderItems);
        }
        
        ipInput.put('orderItems', lstOrderItems);
        ipInput.put('frlSubAction', orchesItem.vlocity_cmt__FulfilmentRequestLineId__r.vlocity_cmt__SubAction__c);
        
        if(!Test.isRunningTest()) {             
        	 ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('OM_ReceptionMilestoneNotification', ipInput, ipOptions);
        }else{
            Map <String, Object> descripcion = new Map <String, Object> ();
            ipOutput.put('responseCode', 400);
            ipOutput.put('message', 'Error');
        }
        
        if(ipOutput.get('responseCode') != 200){
            Map <String, Object> mapError = new Map <String, Object> ();
            throw new notificationException('Error al consumir el IP milestone notification. descripcion:' + ipOutput.get('message'));
        }        
    }
    
    /**
    * @description: Arma la estructura de los productos
    * @author Hever Salas | 03-03-2026 
    * @param mapInput 
    **/
    global virtual Map<String,Object> agregarProductos(Map<String,Object> mapInputParam){
        Map<String,Object> mapOutput = new Map<String,Object>();
        String CrmOrderId = (String)mapInputParam.get('CrmOrderId');
        String fulfilmentRequestLineId = (String)mapInputParam.get('fulfilmentRequestLineId');
        String contractId = (String)mapInputParam.get('contractId');
        String serialNumber = (String)mapInputParam.get('serialNumber');
        String strFechaActual = (String)mapInputParam.get('strFechaActual');
        String orderType = (String)mapInputParam.get('orderType');
        String nombreProducto = (String)mapInputParam.get('nombreProducto');
        String action = (String)mapInputParam.get('action');
        
        //Se agregan los atributos
        List<Map<String,Object>> lstAttr = new List<Map<String,Object>>();
        Map<String,Object> mapAttr = new Map<String,Object>();
        mapAttr.put('name', 'CrmOrderId');
        mapAttr.put('value', CrmOrderId);
		lstAttr.add(mapAttr);
        mapAttr = new Map<String,Object>();
        mapAttr.put('name', 'fulfilmentRequestLineId');
        mapAttr.put('value', fulfilmentRequestLineId);
		lstAttr.add(mapAttr);
        
        //Se arma el nodo producto
        List<Map<String,Object>> lstProdChar = new List<Map<String,Object>>();
        Map<String,Object> mapProdCharAtt = new Map<String,Object>();
        mapProdCharAtt.put('name', 'contractId');
        mapProdCharAtt.put('value', contractId);
		lstProdChar.add(mapProdCharAtt);
        Map<String,Object> mapProductChar = new Map<String,Object>();
		mapProductChar.put('productCharacteristics', lstProdChar);
        
        //Se arma el nodo productOffering
        Map<String,Object> mapProdOfferAttr = new Map<String,Object>();
        mapProdOfferAttr.put('effectiveDate', strFechaActual);
        mapProdOfferAttr.put('id', nombreProducto);
        
        //Se arma el nodo relatedEntities
        List<Map<String,Object>> lstRelatedEntities = new List<Map<String,Object>>();
        Map<String,Object> mapRelatedEntities = new Map<String,Object>();
        mapRelatedEntities.put('name', 'ContractId');
        mapRelatedEntities.put('reference', contractId);
        mapRelatedEntities.put('type', 'Contract');
		lstRelatedEntities.add(mapRelatedEntities);
        
        //Se arma el nodo resources
        List<Map<String,Object>> lstResource = new List<Map<String,Object>>();
        List<Map<String,Object>> lstResourceCharac = new List<Map<String,Object>>();
        Map<String,Object> mapResourceCharac = new Map<String,Object>();
        mapResourceCharac.put('name', 'iccid');
        mapResourceCharac.put('value', serialNumber);
        lstResourceCharac.add(mapResourceCharac);
        Map<String,Object> mapResource = new Map<String,Object>();
        mapResource.put('resourceCharacteristics', lstResourceCharac);
        mapResource.put('serialNumber', serialNumber);
        lstResource.add(mapResource);
        
        //Se arma el nodo ITEM del json
        Map<String,Object> mapItem = new Map<String,Object>();
        mapItem.put('attrs', lstAttr);
        mapItem.put('createdDate', strFechaActual);
        mapItem.put('lastModifiedDate', strFechaActual);
        mapItem.put('orderType', orderType);
        mapItem.put('product', mapProductChar);
        mapItem.put('productOffering', mapProdOfferAttr);
        mapItem.put('relatedEntities', lstRelatedEntities);
        mapItem.put('resources', lstResource);
        mapItem.put('action', action);
        
        mapOutput.put('item', mapItem);
		return mapOutput;
    }
}