/*-------------------------------------------------------------------------------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    Esta clase se utilizara para agregar todos los metodos y funciones necesarios para soportar la clase OrderIntegrationOrderItem
Code Coverage:  92%
History
<Date>       <Version>     	<Author> 				<Description>          											         
2025-03-28     1.0         Hever Salas    	    HDU-559799:[CESION] Familia y amigos generación de JSON-SOM 
2025-04-11     1.1         Hever Salas      	HDU-522166:[CESION]  Crear Orden SOM
2025-04-16     1.2         Gabriel Alvis      	BUG-592336: Evitar envio de característica newResourceNumber en productos distintos al PO_MovPosBasico
2025-04-30     1.3         Hever Salas      	BUG-574609: QA - Medium - BUG - Falta Mapeo de atributo PCcos
2025-05-14     1.4         Karen Sanchez     	HDU580978: Se agrega una nueva condición en el método setProdCharacWithoutMetaData para mandar una nueva caracteristica "activeEndDate" en el PO de cancelación.
                                                Adicional se agregan 3 métodos para la validación de que el orderType y subtype corresponden a los valores del metadata (estos son los unicos permitidos para mandar la fecha de caseInfo en el JSON a Ericsson)
2025-10-01     2.0         Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
2025-11-11     2.1         Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
2025-12-15     2.2         Hever Salas    	    HDU-691571: [EVOLUTIVOS OM]Modificación atributos de info Activación y conciliación de paq adicionales
---------------------------------------------------------------------------------------------------------------------------------------------------*/
global with sharing class OM_OrderIntegrationHelper{
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se verifica el campo vlocity_cmt__AttributeDefaultValues__c si tiene valor behavior entonces se duplica el item
    IN:			    childOrderItem Item actual que se esta formando en OrderIntegrationOrderItem
                    childOrderMap contiene la lista de item que se envian a ericsson
                    AttributeDefaultValues mapa con los valores almacenados del dentro del atributo TechAttrProductDetail
    OUT:			Se retorna la lista childOrderMap con el item duplicado
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static Integer duplicateItem(Map<String,Object> mapParams){
        EricsonRequestJSON.child_cls_orderItems childOrderItem = (EricsonRequestJSON.child_cls_orderItems)mapParams.get('childOrderItem');
        Map<String, List<EricsonRequestJSON.child_cls_orderItems>> childOrderMap = (Map<String, List<EricsonRequestJSON.child_cls_orderItems>>)mapParams.get('childOrderMap');
        String currentProductFamily = (String)mapParams.get('currentProductFamily');
        String strProductId = (String)mapParams.get('strProductId');
        Integer parentProductId = (Integer)mapParams.get('parentProductId');
        Boolean boolIsDuplicate = (Boolean)mapParams.get('boolIsDuplicate');
        Map<String,String> mapServiceId = (Map<String,String>)mapParams.get('mapServiceId');
        Map<String,String> mapResourceId = (Map<String,String>)mapParams.get('mapResourceId');
        List<EricsonRequestJSON.cls_resources> resourcesListInstance = (List<EricsonRequestJSON.cls_resources>)mapParams.get('resourcesListInstance');
        List<EricsonRequestJSON.cls_services> servicesListInstance = (List<EricsonRequestJSON.cls_services>)mapParams.get('servicesListInstance');
        List<EricsonRequestJSON.cls_resources> resourcesListInstanceClone = new List<EricsonRequestJSON.cls_resources>();
        List<EricsonRequestJSON.cls_services> servicesListInstanceClone = new List<EricsonRequestJSON.cls_services>();

        if(boolIsDuplicate){
            EricsonRequestJSON.child_cls_orderItems childOrderItemClone = new EricsonRequestJSON.child_cls_orderItems();
            childOrderItemClone.item = new EricsonRequestJSON.child_cls_item();
            parentProductId++;
            childOrderItemClone.item.id = String.valueOf(parentProductId);
            childOrderItemClone.item.orderType = childOrderItem.item.orderType;
            childOrderItem.item.action = OrderIntegrationSystemInterfaceConstants.VALUE_DELETE;
            childOrderItemClone.item.action = OrderIntegrationSystemInterfaceConstants.S_ADD;
            childOrderItemClone.item.productOffering = childOrderItem.item.productOffering;
            //Products
            childOrderItemClone.item.product = new EricsonRequestJSON.cls_product();
            childOrderItemClone.item.product.productCharacteristics = childOrderItem.item.product.productCharacteristics;
            childOrderItemClone.item.product.productId = strProductId;
            childOrderItemClone.item.product.productSpecification = childOrderItem.item.product.productSpecification;
            childOrderItemClone.item.product.productPrice = childOrderItem.item.product.productPrice;
            //Resources
            childOrderItemClone.item.resources = new List<EricsonRequestJSON.cls_resources>();
            
            for(EricsonRequestJSON.cls_resources itemResource :resourcesListInstance){
                EricsonRequestJSON.cls_resources OIResourceInstanceClone = new EricsonRequestJSON.cls_resources();
                OIResourceInstanceClone.resourceSpecification = itemResource.resourceSpecification;
                OIResourceInstanceClone.resourceCandidate = itemResource.resourceCandidate;
                OIResourceInstanceClone.isLogical = itemResource.isLogical;
                OIResourceInstanceClone.isCompound = itemResource.isCompound;
                OIResourceInstanceClone.parentId = itemResource.parentId;
                OIResourceInstanceClone.physicalResourceId = itemResource.physicalResourceId;
                OIResourceInstanceClone.resourceType = itemResource.resourceType;
                OIResourceInstanceClone.serialNumber = itemResource.serialNumber;
                OIResourceInstanceClone.action = itemResource.action;
                if(mapResourceId.containsKey(itemResource.resourceSpecification) && mapResourceId.get(itemResource.resourceSpecification) != null){
                    OIResourceInstanceClone.resourceId = mapResourceId.get(itemResource.resourceSpecification);
                }
                resourcesListInstanceClone.add(OIResourceInstanceClone);
            }
            childOrderItemClone.item.resources = (!resourcesListInstanceClone.isEmpty() && resourcesListInstanceClone <> null)? resourcesListInstanceClone : null;
            //Services
            childOrderItemClone.item.services = new List<EricsonRequestJSON.cls_services>();
            for(EricsonRequestJSON.cls_services itemService :servicesListInstance){
                EricsonRequestJSON.cls_services OIServicesInstanceClone = new EricsonRequestJSON.cls_services();
                OIServicesInstanceClone.serviceCharacteristics = itemService.serviceCharacteristics;
                OIServicesInstanceClone.cfsSpecification = itemService.cfsSpecification;
                OIServicesInstanceClone.serviceType = itemService.serviceType;
                OIServicesInstanceClone.action = OrderIntegrationSystemInterfaceConstants.S_ADD;
                OIServicesInstanceClone.state = itemService.state;
                if(mapServiceId.containsKey(itemService.cfsSpecification) && mapServiceId.get(itemService.cfsSpecification) != null){
                    OIServicesInstanceClone.serviceId = mapServiceId.get(itemService.cfsSpecification);
                }
                OIServicesInstanceClone.serviceCandidate = itemService.serviceCandidate;
                servicesListInstanceClone.add(OIServicesInstanceClone);
            }
            for(EricsonRequestJSON.cls_services itemOriginal:childOrderItem.item.services){
                itemOriginal.action = OrderIntegrationSystemInterfaceConstants.VALUE_DELETE;
            }
            childOrderItemClone.item.services = (!servicesListInstanceClone.isEmpty() && servicesListInstanceClone <> null)? servicesListInstanceClone : null; 
            childOrderItemClone.item.exceptions = childOrderItem.item.exceptions;
            childOrderItemClone.item.attrs = childOrderItem.item.attrs;
            childOrderItemClone.item.relatedEntities = new List<EricsonRequestJSON.cls_OIrelatedEntities>();
            //RelatedEntities
            for(EricsonRequestJSON.cls_OIrelatedEntities itemRelatedEntities:childOrderItem.item.relatedEntities){
                if(itemRelatedEntities.Type != OrderIntegrationSystemInterfaceConstants.S_CONTRACT){
                    childOrderItemClone.item.relatedEntities.add(itemRelatedEntities);
                }  
            }
            childOrderItemClone.item.relatedParties = null;
            if(!childOrderMap.containsKey(currentProductFamily)){
                childOrderMap.put(currentProductFamily, new List<EricsonRequestJSON.child_cls_orderItems>());
            }
            childOrderMap.get(currentProductFamily).add(childOrderItemClone);
        }
        return parentProductId;
    }
    
     /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Gabriel Alvis
    Company:	    Salesforce.com
    Description:   	Determina el resourceNumber que debe ser enviada en el JSON request
    IN:			    EricsonRequestJSON.cls_resources resources: instancia de clase resources correspondiente al objeto en el JSON Ericsson
                    String subAction: sub acción correspondiente en el FulfilmentRequestLine
                    Map<String, Map<String, Object>> attrCodeValueMap: información de atributos estructurada por clases y con los nombres propios de Ericsson
                    String cfsSpec: especificación (sea de producto o servicio) correspondiente el producto técnico
                    vlocity_cmt__Subscription__c subscription: suscripción relacionada a la orden
    OUT:			la información se retorna por referencia en la instancia de clase resources
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static void setOIResource_ResourceNumber(EricsonRequestJSON.cls_resources resources, String subAction, Map<String, Map<String, Object>> attrCodeValueMap, String cfsSpec, vlocity_cmt__Subscription__c subscription){
        
        if(   (   subAction == OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT 
               || subAction == OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION  )
           && cfsSpec == OrderIntegrationSystemInterfaceConstants.RS_LRSMOVNUMERO
           && subscription != null && String.isNotBlank(subscription.OM_MSISDN_Temporary__c)){
            resources.resourceNumber = subscription.OM_MSISDN_Temporary__c;
        }
        else {
            resources.resourceNumber =  getNewResourceNumber(attrCodeValueMap, cfsSpec);
        }
    }
    
     /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregan las Resources and its characteristics 
    IN:			    EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance: instancia de clase resourceCharacteristics correspondiente al objeto en el JSON Ericsson
					String actionStr: valor del campo Action del FulfilmentRequestLine actual
                    String derivedStrSubAction: valor del campo SubAction del FulfilmentRequestLine actual
                    String cfsCharac: Caracteristica del recurso actual (ej: ki, subMarket, simCardClass, etc)
                    String cfsSpec: Caracteristica que engloba el recurso actual (ej: PRS_SimCard, LRS_MovNumero, etc) 
                    List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList: Lista de las instancias de clase resourceCharacteristics correspondiente al objeto en el JSON Ericsson
                    Map<String, Map<String, Object>> attrCodeValueMap: información de atributos estructurada por clases y con los nombres propios de Ericsson
                    Order orderInstance: Instancia de la orden en salesforce
                    vlocity_cmt__Subscription__c subscription: suscripción relacionada a la orden
                    EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource: Instancia de clase productCharacteristics correspondiente al objeto en el JSON Ericsson
    OUT:			la información se retorna por referencia en la instancia de clase resourceCharacteristics
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static void setOIResourcesCharacteristics(EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance, String actionStr, String derivedStrSubAction, String cfsCharac, String cfsSpec, List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList,  Map<String, Map<String, Object>> attrCodeValueMap, Order orderInstance, vlocity_cmt__Subscription__c subscription, EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource, String resourceNRN, String topOrderType){
        
        System.debug('===cfsCharac==='+cfsCharac);
        orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
        
        if(OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).containskey(cfsCharac)){
            
            orderItemResourceCharacInstance.name = cfsCharac;
            orderItemResourceCharacInstance.value = OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(cfsCharac);
            orderItemResourceCharacInstance.isConfigurable = true;
            oIResourceCharacList.add(orderItemResourceCharacInstance);
            
        }else if(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).containskey(cfsCharac) 
                 && String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(cfsCharac))){
                     
                     orderItemResourceCharacInstance.name = cfsCharac;
                     
                     //v1.0.17 PORT_IN_ORDER = PortInOrder && PORTOUT_ORDERTYPE = RollbackPortIn
                     //v1.0.30 PORT_OUT_ROLLBACK = RollbackPortOut - PORT_OUT_ORDER = PortOutOrder
                     if(cfsSpec == OrderIntegrationSystemInterfaceConstants.RS_LRSMOVNUMERO
                        && cfsCharac == OrderIntegrationSystemInterfaceConstants.PORTABILITY_NETWORK 
                        && (   topOrderType == OrderIntegrationSystemInterfaceConstants.PORT_IN_ORDER
                            || topOrderType == OrderIntegrationSystemInterfaceConstants.PORTOUT_ORDERTYPE
                            || topOrderType == OrderIntegrationSystemInterfaceConstants.PORT_OUT_ROLLBACK
                            || topOrderType == OrderIntegrationSystemInterfaceConstants.PORT_OUT_ORDER)
                        && String.IsNotBlank(resourceNRN)
                        && String.valueOf(resourceNRN) != OrderIntegrationSystemInterfaceConstants.VALUE_NRN){
                            
                            orderItemResourceCharacInstance.value = OrderIntegrationSystemInterfaceConstants.VALUE_PON1;
                     
                     }else if(cfsCharac == OrderIntegrationSystemInterfaceConstants.PORTABILITY_STATUS 
                               && String.valueOf(orderInstance.Type) == OrderIntegrationSystemInterfaceConstants.PORTABILITY_TYPE
                               && String.valueOf(orderInstance.FVU_OrderSubType__c) == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBTYPE){
                                   
                                   // HDU-340689 Se asigna Portation_status proveniente de la orden y tenía valor anterior en FRL
                                   orderItemResourceCharacInstance.value = String.valueOf(orderInstance.OM_PortabilityStatus__c);
                      
                     }else if(cfsCharac == OrderIntegrationSystemInterfaceConstants.PORTABILITY_NRN
                               && String.valueOf(orderInstance.Type) == OrderIntegrationSystemInterfaceConstants.PORTABILITY_TYPE
                               && String.valueOf(orderInstance.FVU_OrderSubType__c) == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBTYPE){
                                   
                                   // HDU-340689 Se asigna NRN proveniente de la orden y tenía valor anterior en FRL
                                   orderItemResourceCharacInstance.value = String.valueOf(orderInstance.OM_NRN__c);
                                   
                     }else if(    (   derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT 
                                   || derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION ) 
                               && cfsCharac == OrderIntegrationSystemInterfaceConstants.C_RESOURCENUMBER
                               && subscription != null && String.isNotBlank(subscription.OM_MSISDN_Temporary__c)){
                                   
                                   orderItemResourceCharacInstance.value = subscription.OM_MSISDN_Temporary__c;
                                   if(orderItemPCNewResource!= null){
                                       orderItemPCNewResource.value = String.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(cfsCharac));
                                   }
                     }else{
                         // Se asignan todas las caractericticas provenientes del FRL
                         orderItemResourceCharacInstance.value = String.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(cfsCharac));
                     }
                     
                     orderItemResourceCharacInstance.isConfigurable = true;
                     oIResourceCharacList.add(orderItemResourceCharacInstance);
                     
        }else{
            if(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).containskey(cfsCharac) 
               && String.isBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(cfsCharac))
               && cfsCharac == OrderIntegrationSystemInterfaceConstants.PORTABILITY_NRN){
                   
                   // HDU-340689 Se asigna NRN proveniente de la orden cuando no tiene valor anterior
                   orderItemResourceCharacInstance.name = cfsCharac;
                   orderItemResourceCharacInstance.value = String.valueOf(orderInstance.OM_NRN__c);
                   orderItemResourceCharacInstance.isConfigurable = true;
                   oIResourceCharacList.add(orderItemResourceCharacInstance);
            }
        }
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregan las product characteristics que no vienen de la metadata
    IN:			    String derivedStrSubAction: valor del campo SubAction del FulfilmentRequestLine actual
                    vlocity_cmt__Subscription__c subscription: suscripción relacionada a la orden
                    EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource: Instancia de clase productCharacteristics correspondiente al objeto en el JSON Ericsson
					String productCode:  valor del producto tecnico principal "Po_MovPosBasico"
					EricsonRequestJSON.cls_product productinstance:  Instancia de clase product correspondiente al objeto en el JSON Ericsson
            		Map<String,String> mapAgrupado: Mapa con los valores rootItemId de los PO que deben agruparse
            		Id derivedFRLId: Identificador salesforce para el producto tecnico actual
					Map<String,Map<String, Object>> getOrderLineItemPriceByFRL: Mapa que contiene los precios de los productos
    OUT:			la información se retorna por referencia en la instancia de clase resourceCharacteristics
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static void setProdCharacWithoutMetaData(Map<String, Object> input) {
        Order orderInstance = (Order)input.get('orderInstance');
        Id derivedFRLId = (Id)input.get('derivedFRLId');
        String PO_Product = (String)input.get('PO_Product');
        String derivedStrSubAction = (String)input.get('derivedStrSubAction');
        String productCode = (String)input.get('productCode');
        List<Object> lstParents = (List<Object>)input.get('lstParents');
        Map<String, String> mapAgrupado = (Map<String, String>)input.get('mapAgrupado');
        Map<String, Map<String, Object>> getOrderLineItemPriceByFRL = (Map<String, Map<String, Object>>)input.get('getOrderLineItemPriceByFRL');
        Map<String, Map<String, Object>> MapGen = (Map<String, Map<String, Object>>)input.get('MapGen');
        Map<String, Object> AttributeDefaultValues = (Map<String, Object>)input.get('AttributeDefaultValues');
        EricsonRequestJSON.cls_product productinstance = (EricsonRequestJSON.cls_product)input.get('productinstance');
        vlocity_cmt__Subscription__c subscription = (vlocity_cmt__Subscription__c)input.get('subscription');

        Map<String, Object> mapProductosConVigencia = (Map<String, Object>)input.get('mapProductosConVigencia');
        Datetime fechaCreacion = (Datetime)input.get('fechaCreacion');

        //Se agrega caracteristica activeEndDate
        if(mapProductosConVigencia != null && mapProductosConVigencia.containsKey(productCode)){ 
            if (derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.getValue('ACTIVATION_ADD')||
               derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACTION_CHANGE_SERVICE_PROD')){
                Integer vigencia = 0;
                Datetime activeEndDate;
                switch on (String)mapProductosConVigencia.get(productCode){
                    when 'Vigencia diaria', 'Diaria'{
                        vigencia = 1;
                    }	
                    when '30 días', '30' {
                        vigencia = 30;
                    }
                    when '15 días' {
                        vigencia = 15;
                    }
                    when '7 días' {
                        vigencia = 7;
                    }
                    when '5 días' {
                        vigencia = 5;
                    }
                }
                activeEndDate = fechaCreacion.addDays(vigencia);
                addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.getValue('ACTIVEENDDATE'), activeEndDate, true);
                mapProductosConVigencia.put(productCode,activeEndDate);
            }else if(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY')){
                addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.getValue('ACTIVEENDDATE'), (Datetime)mapProductosConVigencia.get(productCode), true);
            }
        }

        Map<String, Map<String, Object>> attrCodeValueMap = (Map<String, Map<String, Object>>)input.get('attrCodeValueMap');

        
        // Característica de fecha para cancelación
        if (PO_Product == OrderIntegrationSystemInterfaceConstants.getValue('ProductoCancelacion') && verificarTipoSubtipoCancelacion(orderInstance)) {
            Map<String, Object> caseInfoMap = (Map<String, Object>) JSON.deserializeUntyped(orderInstance.PVU_CaseInfo__c);
            if (caseInfoMap.containsKey(OrderIntegrationSystemInterfaceConstants.KEY_FECHAFINCANC) && caseInfoMap.get(OrderIntegrationSystemInterfaceConstants.KEY_FECHAFINCANC) != null) {
                addProductCharacteristic(productinstance,OrderIntegrationSystemInterfaceConstants.getValue('CharacteristicProductCancel'),caseInfoMap.get(OrderIntegrationSystemInterfaceConstants.KEY_FECHAFINCANC),true);
            }
        }

        if (PO_Product == OrderIntegrationSystemInterfaceConstants.FAF_PRODUCT) {
            if (derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN)|| 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORTINRETOMA)|| 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN_A)|| 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_ADD)|| 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT)) {
                addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.VALUE_FAF_LIST_VOICE, new List<Object>(), true);
            } else {
                addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.VALUE_FAF_LIST_VOICE, lstParents, true);
            }
        }

        if (
            (derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT
            || derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION)
            && productCode == OrderIntegrationSystemInterfaceConstants.TECHNICAL_PARENT_PRODUCT
            && subscription != null && String.isNotBlank(subscription.OM_MSISDN_Temporary__c)) {
            addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.C_NEWRESOURCENUMBER, getNewResourceNumber(attrCodeValueMap, OrderIntegrationSystemInterfaceConstants.RS_LRSMOVNUMERO), null);
        }

        if (mapAgrupado != null && mapAgrupado.containsKey(derivedFRLId)) {
            addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.VALUE_AGRUPACION, mapAgrupado.get(derivedFRLId), true);
        }

        if (getOrderLineItemPriceByFRL.containsKey(productCode + '_' + derivedStrSubAction)) {
            String totalPrice = '';
            Map<String, Object> getOrderItemPrices = getOrderLineItemPriceByFRL.get(productCode + '_' + derivedStrSubAction);
            if (productCode == OrderIntegrationSystemInterfaceConstants.TECHNICAL_SIMCARD_PRODUCT) {
                totalPrice = getOrderItemPrices.containsKey(OrderIntegrationSystemInterfaceConstants.ONETIME_CHARGE_TAXES)? String.valueOf(getOrderItemPrices.get(OrderIntegrationSystemInterfaceConstants.ONETIME_CHARGE_TAXES)): '';
            } else {
                totalPrice = getOrderItemPrices.containsKey(OrderIntegrationSystemInterfaceConstants.RECURRING_CHARGE_TAXES)? String.valueOf(getOrderItemPrices.get(OrderIntegrationSystemInterfaceConstants.RECURRING_CHARGE_TAXES)): '';
            }
            addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.VALUE_TOTAL_PRICE, totalPrice, true);
        }
        if (MapGen.containsKey(productCode)) {
            Map<String, Object> mapProductCode = MapGen.get(productCode);
            if (mapProductCode.containsKey(OrderIntegrationSystemInterfaceConstants.SERVI_ID)) {
                addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.SERVI_ID, mapProductCode.get(OrderIntegrationSystemInterfaceConstants.SERVI_ID), true);
            }
            if (mapProductCode.containsKey(OrderIntegrationSystemInterfaceConstants.TECHNICAL_DETAILS)) {
                Map<String, Object> mapTecDetail = (Map<String, Object>)mapProductCode.get(OrderIntegrationSystemInterfaceConstants.TECHNICAL_DETAILS);
                if(OrderIntegrationSystemInterfaceUtility.technicalDetails != null){
                    Map<String, Map<String, Object>> technicalDetails = OrderIntegrationSystemInterfaceUtility.technicalDetails;
                    if(technicalDetails.containsKey((String)orderInstance.Type+'|'+(String)orderInstance.FVU_OrderSubType__c+'|'+(String)orderInstance.FVU_OriginalChannel__c+'|'+(String)productCode)){
                        mapTecDetail.putAll((Map<String, Object>)technicalDetails.get((String)orderInstance.Type+'|'+(String)orderInstance.FVU_OrderSubType__c+'|'+(String)orderInstance.FVU_OriginalChannel__c+'|'+(String)productCode));
                    }
                }
                for (String TecDet : mapTecDetail.keySet()) {
                    addProductCharacteristic(productinstance, TecDet, mapTecDetail.get(TecDet), true);
                }
            }
        }

        if (AttributeDefaultValues.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_SERV_ID) && String.isNotBlank((String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_SERV_ID))) {
            addProductCharacteristic(productinstance, OrderIntegrationSystemInterfaceConstants.SERVI_ID, (String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_SERV_ID), true);
        }

        if (AttributeDefaultValues.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_TECH_DET) && String.isNotBlank((String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_TECH_DET))) {
            Map<String, Object> mapTecDetailProdTec = (Map<String, Object>)JSON.deserializeUntyped((String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_TECH_DET));
            if(OrderIntegrationSystemInterfaceUtility.technicalDetails != null){
                Map<String, Map<String, Object>> technicalDetails = OrderIntegrationSystemInterfaceUtility.technicalDetails;
                if(technicalDetails.containsKey((String)orderInstance.Type+'|'+(String)orderInstance.FVU_OrderSubType__c+'|'+(String)orderInstance.FVU_OriginalChannel__c+'|'+(String)productCode)){
                    mapTecDetailProdTec.putAll((Map<String, Object>)technicalDetails.get((String)orderInstance.Type+'|'+(String)orderInstance.FVU_OrderSubType__c+'|'+(String)orderInstance.FVU_OriginalChannel__c+'|'+(String)productCode));
                }
            }
            for (String TecDet : mapTecDetailProdTec.keySet()) {
                addProductCharacteristic(productinstance, TecDet, mapTecDetailProdTec.get(TecDet), true);
            }
        }
    }

    // Método genérico para agregar características al producto
    private static void addProductCharacteristic(EricsonRequestJSON.cls_product productInstance,String name,Object value,Boolean isConfigurable) {
        EricsonRequestJSON.cls_productCharacteristics characteristic = new EricsonRequestJSON.cls_productCharacteristics();
        characteristic.name = name;
        characteristic.value = value;
        characteristic.isConfigurable = isConfigurable;
        productInstance.productCharacteristics.add(characteristic);
    }

    // Sobrecarga para cuando no se necesita el valor
    private static void addProductCharacteristic(EricsonRequestJSON.cls_product productInstance,String name,Boolean isConfigurable) {
        addProductCharacteristic(productInstance, name, null, isConfigurable);
    }


    /**
    * @description: Hace la validación de que el tipo de la orden de Cancelación sea el permitido junto con los subtipos, si empata regresa un booleano = true
    * @author karsanchez | 05-14-2025 
    * @param objOrder 
    * @return Boolean 
    **/
    public static Boolean verificarTipoSubtipoCancelacion(Order objOrder) {
        Boolean bisValid = false;
        if (esTipoOrdenValido(objOrder.Type) && esSubtipoOrdenValido(objOrder.FVU_OrderSubType__c)  && String.isNotBlank(objOrder.PVU_CaseInfo__c)) {
            bisValid = true;
        }
        return bisValid;
    }

    /**
    * Verifica si el tipo de orden está en la lista de tipos permitidos para vigencia de cancelación.
    * @param tipoOrden El tipo de orden a validar
    * @return true si el tipo de orden es válido, false en caso contrario
    */
    private static Boolean esTipoOrdenValido(String tipoOrden) {
        return esValorPermitido(tipoOrden, 'TiposVigenciaCancelacion');
    }

    /**
    * Verifica si el subtipo de orden está en la lista de subtipos permitidos para vigencia de cancelación.
    * @param subtipoOrden El subtipo de orden a validar
    * @return true si el subtipo de orden es válido, false en caso contrario
    */
    private static Boolean esSubtipoOrdenValido(String subtipoOrden) {
        return esValorPermitido(subtipoOrden, 'SubtiposVigenciaCancelacion');
    }

    /**
    * Verifica si un valor está en la lista de valores permitidos según una clave de configuración.
    * @param valor El valor a verificar
    * @param claveConfiguracion La clave de configuración que contiene los valores permitidos
    * @return true si el valor está en la lista, false en caso contrario
    */
    private static Boolean esValorPermitido(String valor, String claveConfiguracion) {
        String valoresPermitidos = OrderIntegrationSystemInterfaceConstants.getValue(claveConfiguracion);
        if (String.isBlank(valoresPermitidos)) {
            return false;
        }
        
        List<String> listaValores = new List<String>();
        for (String itemValor : valoresPermitidos.split(',')) {
            listaValores.add(itemValor.trim());
        }
        return listaValores.contains(valor);
    }


    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregan el nodo Exceptions proveniente del campo vlocity_cmt__AttributeDefaultValues__c
    IN:			  
                    MapGen es un mapa que viene de la clase orderIntegrationAccountDetails que viene con los product Code que cumplen con la condicion de tener el atributo B2C-ATTR-PRC-DET
					String productCode:  valor del producto en el que se encuentra el atributo B2C-ATTR-PRC-DET
                    mapProductCode mapa con los valores de productCode para acceder a 'Process_Details' 
                    mapProcessDetails mapa con los valores almacenados del dentro del atributo B2C-ATTR-PRC-DET 
					lstExceptions si mapProcessDetails contiene exceptions se almacenan en la lista los objetos contenidos en el nodo exceptions "B2C-ATTR-PRC-DET":"{"exceptions":[{"activation_simple":true, "change_sim":false,"suspend_0":false, "reactivate_0":false}]}"}
                    Si la lista lstExceptions es mayor a 0 se le pasan los valores a la lista de objetos exceptionsListInstance
    OUT:			la información retorna una lista de objetos contenidos originalmente a nivel producto comercial para colocarla en el nuevo nodo exceptions "exceptions": [{"activation_simple": true, "change_sim": false, "suspend_0":false, "reactivate_0":false}]
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static List<object> setExceptions(Map<String,Object> inputExceptionsList){
        
        String productCode = (String)inputExceptionsList.get('productCode');
        Map<String,Map<String,Object>> MapGen = (Map<String,Map<String,Object>>)inputExceptionsList.get('MapGen');
        Map<String,Object> AttributeDefaultValues = (Map<String,Object>)inputExceptionsList.get('AttributeDefaultValues');
        
        //childOrderItem = new EricsonRequestJSON.child_cls_orderItems();
        //item = new EricsonRequestJSON.child_cls_item();
        
        List<object> exceptionsListInstance = new List<object>();
        List<Object> lstExceptions = new List<Object>();
        Map<String,Object> mapProductCode = new Map<String,Object>();
        Map<String, Object> mapProcessDetails = new Map<String,Object>();
        
        if(MapGen.containsKey(productCode)) {
            mapProductCode = (Map<String,Object>)MapGen.get(productCode);
            if(mapProductCode.containsKey(OrderIntegrationSystemInterfaceConstants.PROCESS_DETAILS)){
                mapProcessDetails = (Map<String, Object>)mapProductCode.get(OrderIntegrationSystemInterfaceConstants.PROCESS_DETAILS);
                
                if(mapProcessDetails.containsKey(OrderIntegrationSystemInterfaceConstants.EXCEPTIONS)){
                    lstExceptions = (List<Object>)mapProcessDetails.get(OrderIntegrationSystemInterfaceConstants.EXCEPTIONS);
                    
                    if(lstExceptions.size() > 0){
                        exceptionsListInstance = lstExceptions;
                    }
                }
            }
        }else{
            if(AttributeDefaultValues.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_PRC_DET)
              && String.IsNotBlank((String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_PRC_DET))){
                mapProcessDetails = (Map<String, Object>)JSON.deserializeUntyped((String)AttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_PRC_DET));
                
                if(mapProcessDetails.containsKey(OrderIntegrationSystemInterfaceConstants.EXCEPTIONS)){
                    lstExceptions = (List<Object>)mapProcessDetails.get(OrderIntegrationSystemInterfaceConstants.EXCEPTIONS);
                    
                    if(lstExceptions.size() > 0){
                        exceptionsListInstance = lstExceptions;
                    }
                }
            }
        }
        
        return exceptionsListInstance;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se descartan los fulfilment request line que no se envian a Ericsson
    IN:			  
                    String derivedStrAction: valor del campo Action del FulfilmentRequestLine actual
					String derivedStrSubAction: valor del campo SubAction del FulfilmentRequestLine actual
                    String orderType: Tipo de orden
                    String orderSubType: Sub tipo de la orden
                    String derivedStrTechProductSubType: Tipo de producto que viene de la metadata ActionDerivation
                    List<Id> lstIdFRL: Lista de los fulfilment request line que se deben eliminar
                    Id derivedFRLId: Identificador salesforce para el producto tecnico actual
    OUT:			Retorna un booleano que indica si el FRL actual se debe ignorar o no
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static Boolean ignoreFRL(String derivedStrAction, String derivedStrSubAction, String orderType, String orderSubType, String derivedStrTechProductSubType, List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL, Id derivedFRLId){
        Boolean varContinue = false;
        if(derivedStrAction == OrderIntegrationSystemInterfaceConstants.S_DISCONNECT && derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN){
            varContinue = true;
        }
        
        if(((orderType == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CANCELACION) ||
            (orderType == OrderIntegrationSystemInterfaceConstants.PORTABILITY_TYPE && (orderSubType == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBTYPE || 
                                                                                        orderSubType == OrderIntegrationSystemInterfaceConstants.NEG_PORTIN))) &&
           !(OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.containskey(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType))){
                vlocity_cmt__FulfilmentRequestLine__c frl = new vlocity_cmt__FulfilmentRequestLine__c(Id = derivedFRLId);
                lstFRL.add(frl);
                varContinue = true;
        }
        return varContinue;
    }

     /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Obtiene la caracteristica solicitada de la lista
    IN:			    lstInventoryItemCesion Lista de las caracteristicas de un inventoryItem
                    strCfsSpec nombre de la caracteristica desea
    OUT:			Se retorna la lista childOrderMap con el item duplicado
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static String getcfsSpecId(Map<String,Object> mapParams){
        if(mapParams.get('lstInventoryItemCesion') != null && mapParams.get('lstInventoryItemCesion') != ''){
            List<Object> lstInventoryItemCesion = (List<Object>)mapParams.get('lstInventoryItemCesion');
            String strCfsSpec = (String)mapParams.get('cfsSpec');
            for(Object item: lstInventoryItemCesion){
                Map<String,Object> mapItem = (Map<String,Object>)item;
                if(mapItem.containsKey(strCfsSpec) && mapItem.get(strCfsSpec) != null){
                    return (String)mapItem.get(strCfsSpec);
                }
            }
        }
        return null;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se verifica el campo vlocity_cmt__AttributeDefaultValues__c si tiene valor behavior entonces se duplica el item
    IN:			    String orderSubType: Sub tipo de la orden
                    AttributeDefaultValues mapa con los valores almacenados del dentro del atributo TechAttrProductDetail
    OUT:			Si el producto debe duplicarse entonces se retorna true
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static Boolean isDuplicate(Map<String,Object> mapParams){
        Map<String, Object> mapAttributeDefaultValues = (Map<String, Object>)mapParams.get('AttributeDefaultValues');
        String orderSubType = (String)mapParams.get('orderSubType');

        if(mapAttributeDefaultValues.containsKey(OrderIntegrationSystemInterfaceConstants.TECH_ATT_PROD_DET) &&
            String.IsNotBlank(String.valueOf(mapAttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.TECH_ATT_PROD_DET)))){     
            Map<String,Object> mapTechAttrProductDetail = (Map<String,Object>)JSON.DeserializeUntyped(String.valueOf(mapAttributeDefaultValues.get(OrderIntegrationSystemInterfaceConstants.TECH_ATT_PROD_DET)));
            if(mapTechAttrProductDetail.containsKey(OrderIntegrationSystemInterfaceConstants.VALUE_BEHAVIOR) &&
                String.IsNotBlank(String.valueOf(mapTechAttrProductDetail.get(OrderIntegrationSystemInterfaceConstants.VALUE_BEHAVIOR)))){
                for(Object item : (List<Object>)mapTechAttrProductDetail.get(OrderIntegrationSystemInterfaceConstants.VALUE_BEHAVIOR)){
                    Map<String,Object> mapBehavior = (Map<String,Object>)item;
                    if(mapBehavior.containsKey(OrderIntegrationSystemInterfaceConstants.VALUE_SUB_TYPE) && 
                        mapBehavior.get(OrderIntegrationSystemInterfaceConstants.VALUE_SUB_TYPE) == orderSubType){
                        if(mapBehavior.containsKey(OrderIntegrationSystemInterfaceConstants.ACTION.toLowerCase()) && 
                        mapBehavior.get(OrderIntegrationSystemInterfaceConstants.ACTION.toLowerCase()) == OrderIntegrationSystemInterfaceConstants.VALUE_DUPLICATE){
                            return true;
                        }
                    }
                }
            }      
        }
        return false;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Obtiene el valor del atributo cos desde una matriz de decision
    IN:			    Map<String, Map<String, Object>> attrCodeValueMap: información de atributos estructurada por clases y con los nombres propios de Ericsson
    OUT:			retorna el valor que devuelve la salida de la matriz
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static String invokeDecisionMatrixCos(Map<String,Object> mapParams){
        
        Map<String, Map<String, Object>> attrCodeValueMap = (Map<String, Map<String, Object>>)mapParams.get('attrCodeValueMap');
        String cos = '';

        Invocable.Action action = Invocable.Action.createCustomAction('runDecisionMatrix', OrderIntegrationSystemInterfaceConstants.DECISION_MATRIX_COS);
        action.setInvocationParameter(OrderIntegrationSystemInterfaceConstants.PARAM_SRVVVM, Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(OrderIntegrationSystemInterfaceConstants.PARAM_SRVVVM)));
        action.setInvocationParameter(OrderIntegrationSystemInterfaceConstants.PARAM_BRRNLOST, Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(OrderIntegrationSystemInterfaceConstants.PARAM_BRRNLOST)));
        action.setInvocationParameter(OrderIntegrationSystemInterfaceConstants.PARAM_BRRMARYA, Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(OrderIntegrationSystemInterfaceConstants.PARAM_BRRMARYA)));
        List<Invocable.Action.Result> results = action.invoke();
        for(Invocable.Action.Result item: results){
            Map<String,Object> mapOutput = (Map<String,Object>)JSON.deserializeUntyped((String)JSON.Serialize(item));
            if(mapOutput.containsKey('outputParameters') && mapOutput.get('outputParameters') != null){
                Map<String,Object> mapCos = (Map<String,Object>)mapOutput.get('outputParameters');
                if(mapCos.containsKey('cos') && mapCos.get('cos') != null){
                    cos = (String)mapCos.get('cos');
                }
            }
        }
        return cos;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Toma el FRL con producto PO_MovPosFunBloq y le actualiza el JSONAttribute 
    IN:			    String cos: nuevo valor cos que va hacia el FRL
                    Map<String, Object> mapFRL mapa con los FRL asociados al plan de orquestacion
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static void updateCosToFRL(Map<String, Object> inputMap){
        Map<String, Object> mapFRL = (Map<String,Object>)inputMap.get('mapFRL');
        String cos = (String)inputMap.get('cos');

        vlocity_cmt__FulfilmentRequestLine__c objFRL = [SELECT Id, vlocity_cmt__JSONAttribute__c
                                                        FROM vlocity_cmt__FulfilmentRequestLine__c 
                                                        WHERE Id IN :mapFRL.keyset()
                                                        AND vlocity_cmt__Product2Id__r.ProductCode = 'PO-MOV-POS-FUN-BLOQ' WITH SECURITY_ENFORCED LIMIT 1];
        if(objFRL != null){
            String attributeCodeToValue = OrderIntegrationSystemInterfaceConstants.ATT_COS;
            String newValueAttribute = cos;
            List<Object> lstAttributes = new List<Object>();
            Map<String,Object> jsonAttribute = (Map<String,Object>)JSON.deserializeUntyped(objFRL.vlocity_cmt__JSONAttribute__c);
            lstAttributes = (List<Object>)jsonAttribute.values()[0];
            
            for(Object ItemAttribute: lstAttributes){
                Map<String,Object> attribute = new Map<String,Object>();
                attribute = (Map<String,Object>)ItemAttribute;
                if(attribute.get('attributeuniquecode__c') == attributeCodeToValue){
                    Map<String, Object> attributeRunTimeInfo = new Map<String,Object>();
                    attributeRunTimeInfo = (Map<String,Object>)attribute.get('attributeRunTimeInfo');
                    attributeRunTimeInfo.put('value', newValueAttribute);
                    attribute.put('attributeRunTimeInfo', attributeRunTimeInfo);
                    attribute.put('SegmentValue', newValueAttribute);
                    ItemAttribute = attribute;
                }
            }
            jsonAttribute = new Map<String,Object>();
            jsonAttribute.put('223541c2-e1cb-fe89-a86d-b07a65470f1b', lstAttributes);
            vlocity_cmt__FulfilmentRequestLine__c objFRLAux = (vlocity_cmt__FulfilmentRequestLine__c)mapFRL.get(objFRL.Id);
            objFRLAux.vlocity_cmt__JSONAttribute__c = JSON.serialize(jsonAttribute);
            mapFRL.put(objFRL.Id,objFRLAux);
        }
    }
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	SE AGREGAN LAS EXCEPCIONES CONFIGURADAS EN EL OBJETO OM_ProductoTecnico__c
    IN:			  
                    orderType: Tipo de la orden
					orderSubType: Sub tipo de la orden
                    origin: valor del campo OriginalChannel de la orden
                    productCode: PO_ del producto actual
					exceptionsListInstance: Lista de excepciones que estan configuradas en el producto tecnico
    OUT:			A la lista de exceptionsListInstance se le agregan los valores que coincidan con el objeto OM_ProductoTecnicoExcepcion__c
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static void agregarExcepcionesAdicionales(Map<String,Object> inputExceptionsList){
        List<object> exceptionsListInstance = (List<object>)inputExceptionsList.get('exceptionsListInstance');
        String orderType = (String)inputExceptionsList.get('orderType');
        String orderSubType = (String)inputExceptionsList.get('orderSubType');
        String origin = (String)inputExceptionsList.get('origin');
        String productCode = (String)inputExceptionsList.get('productCode');
        Map<String, Map<String, Object>> mapPTE = new Map<String, Map<String, Object>>();
        if(OrderIntegrationSystemInterfaceUtility.excepciones != null){
            mapPTE = OrderIntegrationSystemInterfaceUtility.excepciones;
            
            if(!mapPTE.isEmpty() && mapPTE.containsKey(orderType+'|'+orderSubType+'|'+origin+'|'+productCode) && mapPTE.get(orderType+'|'+orderSubType+'|'+origin+'|'+productCode) != null){
                List<Object> lstException = (List<Object>)mapPTE.get(orderType+'|'+orderSubType+'|'+origin+'|'+productCode).get('exceptions');
                Map<String, Object> mapException = (Map<String, Object>)lstException[0];
                Map<String,Object> mapInstance;
                for(Object item :exceptionsListInstance){
                    mapInstance = (Map<String,Object>)item;
                    mapInstance.putAll(mapException);
                }
                exceptionsListInstance = new List<Object>();
                exceptionsListInstance.add((Object)mapInstance);
            }
        }
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Gabriel Alvis, Leonardo Carranza
    Company:	    Salesforce.com
    Description:   	Retornar newResourceNumber
    IN:			  
                    attrCodeValueMap: Map String Object
					cfsSpec: String                    
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/    
    public static String getNewResourceNumber (Map<String, Map<String, Object>> attrCodeValueMap, String cfsSpec){
        String resNumberEricssonField = (String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).ResourceNumber__c;
        String newResourceNumber =  attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR) && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).containsKey(resNumberEricssonField)
                                      ? (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(resNumberEricssonField) 
                                      : (String.isNotBlank(resNumberEricssonField) ? resNumberEricssonField : '');
        return newResourceNumber;
    }
}