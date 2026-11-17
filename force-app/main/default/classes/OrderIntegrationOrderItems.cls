/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Author:         Mamata - 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>         <Version>      <Author>                          <Description>                       
2023-10-16      1.0.0       Mamata              OrderIntegrationOrderItems for OM Stream            
2024-06-07      1.0.1       Hever Salas         Utility class to create technical attributes JSON   
2024-06-12      1.0.2       Hever Salas         formatear hora de activacion BUG-739902             
08-07-24        1.0.3       Emmanuel Ruarte     HDU 335682 - Cambio de Plan                         
16-07-24        1.0.4       Hever Salas         HDU-335678 - Formato de fecha                       
23-07-24        1.0.5       Ashish Paymode      HDU-743267 - Utilizar siempre cfsSpec para evitar el tema de DUMMY PS                                       
2024-08-02      1.0.7       Hever Salas         BUG-340689 - Caracteristicas para portabilidad      
2024-08-05      1.0.8       Gabriel Alvis       BUG-372765 - ContractId de padre Disconnect         
2024-08-19      1.0.9       Hever Salas         HDU-366794 - Negación de PortIn                     
2024-08-20      1.0.10      Karen Sanchez       HDU-362385 - Agregar atributos a la Negación de PortOut 
2024-08-22      1.0.11      Emmanuel Ruarte     HDU-398249 - Promociones           
2024-09-19	    1.0.12		Hever Salas			HDU 335144 - Se debe enviar precio en 0 cuando FVU_Paid__c es igual a true
2024-09-20      1.0.13      Karen Sanchez       HDU 413297 - Se agrega nueva condicional para agregar el atributo portability process
2024-09-20      1.0.14      Gabriel Alvis       HDU 403314 - Envío de MSISDN dummy en caso de Negación de portout
2024-09-24		1.0.15		Hever Salas			HDU 407460 - Se envian los parametros PerfilCAN y NoCanUsage
2024-10-08      1.0.16      Emmanuel Ruarte     HDU 433747 - Cambio de Numero
2024-10-11		1.0.17	  	Hever Salas		   	HDU-441151 - Ajuste Campo Network
2024-10-28      1.0.18      Emmanuel Ruarte     HDU-479623 - Reinstalación
2024-11-04		1.0.19	  	Hever Salas		   	HDU-409739 - Agrupacion Ofertas
2024-11-12      1.0.20      Emmanuel Ruarte     BUG-491129 - fechaActivacion Reinstalación
2024-11-25      1.0.21      Emmanuel Ruarte     HDU-494773 - Generación de una orden SOM para permitir la venta de OTT
2024-11-25      1.0.22      Josue Aguilar       Change productPrice definition, from integer to decimal
2024-12-18      1.0.23      Hever Salas     	HDU-417695 - Creacion orden SOM de familia y amigos
2025-01-14		1.0.24		Hever Salas     	HDU-513840 - CAMBIO DE PARAMETROS OFERTAS CLARO MUSICA - VIDEO Y DRIVE
2025-01-22      1.0.25      Hever Salas         BUG-538070: Cambio de plan producto adicional
2025-02-07      1.2.26      Emmanuel Ruarte     HDU 542154 - Activaciones acciones no definidas
2025-03-05      1.0.27      Hever Salas      	HDU-547949: Activaciones acciones no definidas en cancelaciones
2025-03-06      1.0.28      Hever Salas      	HDU-544910: Identificacion de Items sin accion
2025-03-31      1.0.29      Hever Salas      	HDU-559799: [CESION] Familia y amigos generación de JSON-SOM 
2025-03-12      1.0.30      Gabriel Alvis       BUG-558229 - Envío de PON1 en network en caso de cualquier portabilidad (in / out)
2025-04-02      1.0.31      Karen Sanchez      	HDU-538800: Se crea nuevo metodo para obtener un mapa con los codigos del objeto vlocity_cmt__Attribute__c y poder mapear el nombre del atributo con el la caracteristica description_offer
2025-04-16      1.0.32      Omar Flores         HDU-517240 - Se guarda en orden el registro de diferencias entre FRL vs InvItem
2025-04-30      1.0.33      Hever Salas      	BUG-574609: QA - Medium - BUG - Falta Mapeo de atributo PCcos
2025-05-14      1.0.34      Karen Sanchez     	HDU580978: Se agrega una nueva llave a inputProdCharac para agregar una nueva caracteristica cuando no se tiene como atributo
2025-05-11      1.0.35      Hever Salas    	    BUG-620821: R5-SIT-E2 Se evidencia que al realizar una desactivación con la causal 266, Des No Aprobación DPC, el sistema genera error en el plan de orquestación relacionado con el servicio Adicional Activo
2025-05-13      1.0.36      Hever Salas    	    BUG-621423: R5-SIT-E3- Al registrar un caso de cesión de contrato, no se realiza el cierre automático
2025-07-31      1.0.37      Gabriel Alvis    	BUG-645536: R5-UAT-SMOKE- ServiceIds y ResourceIds no se están heredando del Asset del Cedente
2025-09-03       2.0        Hever Salas    	    HDU-522209: [EVOLUTIVO OM] ENVIO PRECIOS EN CONCILIACIONES
2025-09-16       2.1        Hever Salas    	    BUG-663090: Cuando genero un plan de orquestación correspondiente a Conciliación de red entonces no se está enviando en el JSON el OrderType ni el Tipo Split
2025-10-01       2.2        Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
2025-11-11       2.3        Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
2025-12-15       2.4        Hever Salas    	    HDU-691571: [EVOLUTIVOS OM]Modificación atributos de info Activación y conciliación de paq adicionales
2026-01-24      2.4.1       Gabriel Alvis    	BUG-715936: Mantener productId, servicesIds y resourceIds en producto Reassign en el Cambio de Plan
2026-01-27      2.4.2       Gabriel Alvis    	BUG-715415: Enviar attrCodeValueMap en OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
2026-03-06       2.5        Hever Salas    		BUG-723384: [Evolutivos OM]-Envio parametro custom price en ordenes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class OrderIntegrationOrderItems {
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Mamata
    Company:	    Salesforce.com
    Description:   	Construye la información de OrderItems que se envía en el Request hacia Ericsson para realizar la creación de órdenes SOM
    IN:			    Map<String, Object> ipInput: información proveniente de la clase que instancia el System Interface relacionadas con el plan de Orquestación
                    Map<String, Object> inputParamsDR: información base para invocar los Data Mappers Extract que alimentan el proceso
                    String  url: URL base para envío del request - no aplica para este proceso
                    String  path: Integration Procedure para envío del request - no aplica para este proceso
                    Account orderServiceAccount: cuenta de servicio relacionada con la orden
                    Account orderBillingAccount: cuenta de facturación relacionada con la orden
                    Order   orderInstance: orden relacionada al plan de orquestación
                    String  orderItemStatus: estado de  del Producto de Pedido raíz
                    Boolean orderItemEstaPagado: indica si la SIMCARD ya ha sido pagada o no
                    vlocity_cmt__Subscription__c subscription: registro de suscripción relacionado con la orden
    OUT:			List<Object>: lista de objetos de tipo OrderItem la cual es una clase que refleja la estructura del JSON esperada por Ericsson para este elemento.
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static List<Object> setAllOrderItems(Map<String, Object> ipInput, EricsonRequestJSON.ProdWithoutAction objProdWithoutAction){
        
        Long DescProductId = 0;
        Long DescServiceId = 0;
        Map<String, Object> ipOptions = new Map<String, Object>();
        Map<String, Object> inputParamsDR = (Map<String, Object>)ipInput.get('inputParamsDR');
        String url = (String)ipInput.get('url');
        String path =  (String)ipInput.get('path');
        List<Object> lstParents = (List<Object>)ipInput.get('lstParents');
        Account orderServiceAccount = (Account)ipInput.get('orderServiceAccount');
        Account orderBillingAccount = (Account)ipInput.get('orderBillingAccount');
        Order orderInstance = (Order)ipInput.get('orderInstance');
        String orderItemStatus = (String)ipInput.get('Status');
        Boolean orderItemEstaPagado = (Boolean)ipInput.get('orderItemEstaPagado');
        vlocity_cmt__Subscription__c subscription = (vlocity_cmt__Subscription__c)ipInput.get('subscription');
        String topOrderType = (String)ipInput.get('topOrderType');
        Map<String,String> mapAgrupado = (Map<String,String>)ipInput.get('mapAgrupado');
        String ordCreateDate = (String)ipInput.get('ordCreateDate');
        Map<String,Map<String,Object>> MapGen = (Map<String,Map<String,Object>>)ipInput.get('MapGen');
        Map<String, Object> mapProductosConVigencia = (Map<String, Object>)ipInput.get('mapProductosConVigencia');
        Datetime fechaCreacion = (Datetime)ipInput.get('fechaCreacion');
        Map<String, String> mapAttNamesAndCodes = (Map<String, String>)ipInput.get('mapAttNamesAndCodes');
        Account billingAccountCesion = ipInput.containsKey('billingAccountCesion') ? (Account)ipInput.get('billingAccountCesion') : null;
        List<Object> listProductosDiff = new List<Object>();    

        /**********************************************************
        Get FRL JSON Attributes list - BEGIN
        **********************************************************/
        List<Map <String, Object>> getDRResult = OrderIntegrationSystemInterfaceHelper.callDrExtract(inputParamsDR, OrderIntegrationSystemInterfaceConstants.GET_DR_RESULT);
        // Agrupa FFRLs por productOfferingId y Acción/Subacción - v. 2.4.1
        Map<String, Map <String, Id>> mapProductoTecnico = OrderIntegrationSystemInterfaceHelper.agruparProductoTecnicoSOMAccion(getDRResult);
        /**********************************************************
        Get FRL JSON Attributes list - END
        **********************************************************/
        
        /**********************************************************
        Get OAP JSON Attributes list - BEGIN
        **********************************************************/
        List<Map <String, Object>> getDRAppliedPromotion = OrderIntegrationSystemInterfaceHelper.callDrExtract(inputParamsDR, OrderIntegrationSystemInterfaceConstants.GET_DR_APPLIED_PROMOTION);
        List<Map <String, Object>> mapAppliedPromotionOtros  ;
        List<Map <String, Object>> mapAppliedPromotionObsequio  ;
        //se condiciona de acuerdo a respuesta de DR orderAppliedPromotion para respuesta en forma de lista o un solo elemento
        if (getDRAppliedPromotion != null && !getDRAppliedPromotion.isEmpty()) {
            Object applPromOtros = getDRAppliedPromotion[0].get(OrderIntegrationSystemInterfaceConstants.ITEM_ADDON) ;
            Object applPromoObseq = getDRAppliedPromotion[0].get(OrderIntegrationSystemInterfaceConstants.GIFT) ;
            if (applPromOtros != null &&  applPromOtros instanceof List<Map <String, Object>> ){
                mapAppliedPromotionOtros = (List<Map <String, Object>>)applPromOtros; 
            }else if(applPromOtros != null &&  applPromOtros instanceof Map <String, Object>){ 
                mapAppliedPromotionOtros = new List<Map <String, Object>>();
                mapAppliedPromotionOtros.add((Map <String, Object>)applPromOtros); 
            }
            
            if (applPromoObseq != null &&  applPromoObseq instanceof List<Map <String, Object>> ){
                mapAppliedPromotionObsequio = (List<Map <String, Object>>)applPromoObseq; 
            }else if(applPromoObseq != null &&  applPromoObseq instanceof Map <String, Object>){ 
                mapAppliedPromotionObsequio = new List<Map <String, Object>>();
                mapAppliedPromotionObsequio.add((Map <String, Object>)applPromoObseq); 
            }
            
        }
        
        /**********************************************************
        Get OAP JSON Attributes list - END
        **********************************************************/
        
        Map<String, Map<String, Object>> attrCodeValueMap = new Map<String, Map<String, Object>>(); //for each class item, assign value to target key : Map<ClassName, Map<TargetKey, Value>>
        
        String attrCatCode = OrderIntegrationSystemInterfaceHelper.getTechAttributeCategoryCode();//get category code of attribute category -> ex : 223541c2-e1cb-fe89-a86d-b07a65470f1b
        
        String environmentIdentifierStr = '';
        
        String envtDateStr = '';
        
        Map<String,Map<String, Object>> getOrderLineItemPriceByFRL = OrderIntegrationSystemInterfaceHelper.getOrderItemPrice(ipInput);
        System.debug('======getOrderLineItemPriceByFRL===='+JSON.serializePretty(getOrderLineItemPriceByFRL, true));
        String rootAssetStatusStr = OrderIntegrationSystemInterfaceHelper.getOrderItemState(ipInput);
        System.debug('======rootAssetStatusStr===='+rootAssetStatusStr);
        Map<String, Map<String, Map<String, String>>> serviceProductResourceIdsByFulfilmentNo = OrderIntegrationSystemInterfaceHelper.getInventoryServiceResourceProductIdForSuspension(ipInput);
        
        Map<String, Map<String, String>> frlInventoryJSONByFRLId = OrderIntegrationSystemInterfaceHelper.getFRLAndInventoryJSON(ipInput);
        Map<String, Map<String, Object>> mapInventoryItemCesion = new Map<String, Map<String, Object>>();
        if(orderInstance.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){
            Map<String,String> mapInputInventoryItems = new Map<String,String>();
            mapInputInventoryItems.put(OrderIntegrationSystemInterfaceConstants.ORDER_ID,(String)orderInstance.Id);
            mapInventoryItemCesion = OrderIntegrationSystemInterfaceHelper.getInventoryItemsOldJSON(mapInputInventoryItems);
        }

        String FRL_JSON_STR = OrderIntegrationSystemInterfaceConstants.FRL_JSON_STR;
        String INV_JSON_STR = OrderIntegrationSystemInterfaceConstants.INV_JSON_STR;
        
        
        System.debug('======serviceProductResourceIdsByFulfilmentNo===='+JSON.serializePretty(serviceProductResourceIdsByFulfilmentNo, true));
        
        EricsonRequestJSON instEricsonReq = new EricsonRequestJSON();
        
        instEricsonReq.orderItems = new List<Object>();
        
        EricsonRequestJSON.cls_orderItems parentOrderItem;
        
        EricsonRequestJSON.child_cls_orderItems childOrderItem;
        
        Map<String, List<EricsonRequestJSON.child_cls_orderItems>> childOrderMap = new Map<String, List<EricsonRequestJSON.child_cls_orderItems>>();//key=> productFamily, value=>childOrderItems
        
        Map<String, EricsonRequestJSON.cls_orderItems> parentOrderMap = new Map<String, EricsonRequestJSON.cls_orderItems>();//key=> productFamily, value=>childOrderItems
        
        Integer parentProductId = 0;
        
        String currentProductFamily = '';
        
        Map<String, Map<String, Set<Object>>> prodResServiceIdByFRL = new Map<String, Map<String, Set<Object>>>(); //store fulfilmentrequest line associated serviceId, ResourceId, ProductId

        EricsonRequestJSON.cls_productCharacteristics orderItemPCNewResource;       // v. 1.0.14
        
        String actionStr = '';
        
        String derivedStrAction = '';
        
        String derivedStrSubAction = '';
        
        String resourceNRN = '';
        
        String derivedStrTechProductSubType = '';
        
        String contractIdStr = '';
        
        String contractIdDisconnectStr= '';                             // v. 1.0.8
        
        String contractIdTmpStr= '';                                    // v. 1.0.8
        
        String ffrlParentIdAdd = '';
        
        String ffrlParentIdDisconnect = '';
        
        String ffrlJsonAttrDisconnect ='';
        
        String ffrlJsonAttrTmp = '';
        
        String ffrlParentIdTmp = '';
        
        String strMessage = '';

        String strfulfilmentProductName = '';
        
        String strProductId = '';

        List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = new List<vlocity_cmt__FulfilmentRequestLine__c>();

        Map<String,String> mapServiceId = new Map<String,String>();

        Map<String,String> mapResourceId = new Map<String,String>();

        Boolean updateCos = false;

        String cos = '';
        /**********************************************************
        Iterate over all FRS JSON generated from DR - BEGIN
        **********************************************************/
        
        for(Map <String, Object> outputDRMap : getDRResult){ // iterate over all FRLs JSON received
            System.debug('====key====='+outputDRMap);
            Map<String, Object> tempMap = new Map<String, Object>(); //FRS each item characteristics as key and value
            List<Object> lstFrl_TecAttr = new List<Object>();
            Map<String, Object> AttributeDefaultValues = new Map<String, Object>();
            if(outputDRMap.containsKey('AttributeDefaultValues')){
                AttributeDefaultValues = (Map<String, Object>)outputDRMap.get('AttributeDefaultValues');
                outputDRMap.remove('AttributeDefaultValues');
            }
            
            attrCodeValueMap.clear();
            attrCodeValueMap.put(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS,new Map<String,Object>());
            Map<String, Object> FRL_JSONAttr = new Map<String, Object>();
            // Obtiene la información general del FRL (attrCodeValueMap) y su lista de atributos (lstFrl_TecAttr)
            for(String key1 : outputDRMap.keySet()){
                if(!key1.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.SERIALISED_JSON_STR)){
                    attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).put(key1,(String)outputDRMap.get(key1));
                }else {
                    FRL_JSONAttr = (Map<String, Object>)outputDRMap.get(key1) ; //attributecategory id=>all techAttribute items
                    lstFrl_TecAttr.addAll((List<Object>)FRL_JSONAttr.get(attrCatCode));// add list of attributes per attribute category node of each FR
                }
            }
           
            Boolean boolIsDuplicate = false;
            if(orderInstance.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){
                Map<String,Object> mapInputIsDuplicate = new Map<String,Object>();
                mapInputIsDuplicate.put('AttributeDefaultValues', AttributeDefaultValues);
                mapInputIsDuplicate.put('orderSubType', (String)orderInstance.FVU_OrderSubType__c);
                boolIsDuplicate = OM_OrderIntegrationHelper.isDuplicate(mapInputIsDuplicate);
            }

            actionStr = OrderIntegrationSystemInterfaceConstants.DEFAULT_STR;
            derivedStrAction = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.ACTION);
            derivedStrSubAction = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.SUB_ACTION);
            Id derivedFRLId = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.FULFILMENTID); // Ashish temp code as Currency decomp mapping is not working.
            strfulfilmentProductName = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.FULFILMENT_PRODUCT_NAME);
			
            System.debug('===========derivedStrAction==========='+derivedStrAction);
            System.debug('===========derivedStrSubAction==========='+derivedStrSubAction);
            System.debug('===========derivedFRLId==========='+derivedFRLId);
            System.debug('===========derivefulfilmentProductName==========='+strfulfilmentProductName);
            
            // Obtiene la información de clase de atributo (usando sourceKeyClassMap i.e.: TechATRfamily => cls_item.cls_attributes) para guardarlo en el mapa attrCodeValueMap con su valor correspondiente
            Map<String,Object> attrMap = new Map<String,Object>();
            for(Object attr : lstFrl_TecAttr){
                attrMap = (Map<String, Object>)attr;
                if(    OrderIntegrationSystemInterfaceUtility.sourceKeyClassMap.containskey(actionStr) //sourceKeyClassMap relaciona el atributo origen con sus clases
                && OrderIntegrationSystemInterfaceUtility.sourceKeyClassMap.get(actionStr).containskey((String)attrMap.get(OrderIntegrationSystemInterfaceConstants.CODE))){ // check if utility source map contains values for incoming action and techAttr
                    for(String classKey: OrderIntegrationSystemInterfaceUtility.sourceKeyClassMap.get(actionStr).get((String)attrMap.get(OrderIntegrationSystemInterfaceConstants.CODE))){
                        if(!attrCodeValueMap.containsKey(classKey)){
                            attrCodeValueMap.put(classKey, new Map<String,Object>());   
                        }
                        attrCodeValueMap.get(classKey).put((OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName).get(actionStr).get(classKey).get((String)attrMap.get(OrderIntegrationSystemInterfaceConstants.CODE)) , (String)attrMap.get(OrderIntegrationSystemInterfaceConstants.SEG_VALUE)); //using sourceAndTargetAttrByClassName to get target attribute name based on tempMap's source attribute       
                    }
                }                
            }

            derivedStrTechProductSubType = attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_SUB_TYPE)?(String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_SUB_TYPE).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_SUB_TYPE) : '';
            String productCode = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID);
            String ActionCalculated = OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.containskey(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType)?
                    OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.get(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType) : '' ;
            
            if(OM_OrderIntegrationHelper.ignoreFRL(derivedStrAction, derivedStrSubAction, (String)orderInstance.Type, (String)orderInstance.FVU_OrderSubType__c, derivedStrTechProductSubType, lstFRL, derivedFRLId)){
                continue;
            }
            
            if(!OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.containskey(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType)){
                if(!(derivedStrTechProductSubType == OrderIntegrationSystemInterfaceConstants.PRODUCT_SUB_TYPE && derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_ADD)){
                    objProdWithoutAction.ApiName = 'GenerarJSON';
                    objProdWithoutAction.ErrorCode = 'GenerarJSON_01';
                    strMessage = '{"responseStatus":{"message":"El order Item '+productCode+' no tiene una acción definida ya que no esta en los activos del cliente","status":"ERROR"}}';
                    objProdWithoutAction.response = (Map<String,Object>)JSON.deserializeUntyped(strMessage); 
                    objProdWithoutAction.orderType = (String)orderInstance.Type;
                    objProdWithoutAction.orderSubType = (String)orderInstance.FVU_OrderSubType__c;
                    objProdWithoutAction.orderId = (String)orderInstance.Id;
                    return null;
                }
            }

            System.debug('====CLS ORDER ITEM======1======'+actionStr);
            
            for(String classKey: OrderIntegrationSystemInterfaceUtility.sourceKeyClassMap.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.ACTION)){
                
                if(attrCodeValueMap.containskey(classKey))
                attrCodeValueMap.get(classKey).put(OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(classKey).get(OrderIntegrationSystemInterfaceConstants.ACTION) , attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.ACTION)); // add action value for target json, add action based on class name associated value
                
            }
            
            if(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR) <> null){
                resourceNRN = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get(OrderIntegrationSystemInterfaceConstants.PORTABILITY_NRN);
            }
           
            Boolean isRequestTargetId = (OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.containsKey(actionStr) && OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).containsKey(OrderIntegrationSystemInterfaceConstants.CLS_ATTRIBUTE) && OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_ATTRIBUTE).containsKey(OrderIntegrationSystemInterfaceConstants.REQUEST_TARGET_ID));
            environmentIdentifierStr = isRequestTargetId ? (String)OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_ATTRIBUTE).get(OrderIntegrationSystemInterfaceConstants.REQUEST_TARGET_ID):'';
            envtDateStr = environmentIdentifierStr+String.ValueOf(Datetime.now().format(OrderIntegrationSystemInterfaceConstants.YY_Y))+String.ValueOf(Datetime.now().format(OrderIntegrationSystemInterfaceConstants.MM_M));
            String fulfilmentIdStr = (attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS) && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).containsKey(OrderIntegrationSystemInterfaceConstants.FULFILMENTID))?((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.FULFILMENT_NO)).replace(OrderIntegrationSystemInterfaceConstants.FRL, '') : '';
            
            /**
            * Beginning of value assignments to Ericson
            *=================================================================================================================================================================================================================
            * add attributes list for top level products -> attrs[]  ----- BEGIN
            *=================================================================================================================================================================================================================
            */
            
            List<EricsonRequestJSON.cls_attributes> attrs = new List<EricsonRequestJSON.cls_attributes>();
            String tempDescription = orderInstance.OrderNumber;
            if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_ATTR_FLAG) && Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ATTR_FLAG).get(OrderIntegrationSystemInterfaceConstants.CLS_ATTR_FLAG))){
                for(String key : attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).keyset()){
                    EricsonRequestJSON.cls_attributes orderItemAttrInstance = new EricsonRequestJSON.cls_attributes();
                    
                    if(String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key))){
                        orderItemAttrInstance.name = key;
                        orderItemAttrInstance.value = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key);
                        attrs.add(orderItemAttrInstance);
                        
                    }                
                }
                
                attrs.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.CRM_ORDER_ID, OrderIntegrationSystemInterfaceConstants.ORDSF+(tempDescription.deleteWhitespace()))); // Ashish Changed from 'ORDFS0' to 'ORDSF'
                attrs.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.FULFILMENT_REQUEST_LINE_ID, (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.ITEM_ATTR_CLS).get(OrderIntegrationSystemInterfaceConstants.FULFILMENTID)));
                
                //HDU-340689-366794-362385 - Para ordenes de portabilidad se agrega el atributo portability process id
                if (derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN) || 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORTINRETOMA) || 
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBACTION) ||
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.NEG_PORTIN_SUBACTION) ||
                derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT)){
                    attrs.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.PORTABILITY_PROCESS_ID, (String)(orderInstance.OM_PortabilityProcessId__c) ));
                }
            }
            /*
            *=================================================================================================================================================================================================================
            * add attributes list for top level products -> attrs[]  ----- END
            *=================================================================================================================================================================================================================
            */
            
            /*
            *=================================================================================================================================================================================================================
            * add attributes list for child products -> attrs[]  ----- BEGIN
            *=================================================================================================================================================================================================================
            */
            
            List<EricsonRequestJSON.cls_childattributes> childAttrs = new List<EricsonRequestJSON.cls_childattributes>();
            System.debug('==strCHANGEATTR==='+frlInventoryJSONByFRLId.containskey(derivedFRLId) + derivedFRLId);
            if(    OrderIntegrationSystemInterfaceConstants.TECHNICAL_PRODUCT_ACTION_MODIFY.contains(productCode)           // Comparación de atributos técnicos de productos de funcionalidades
            && frlInventoryJSONByFRLId.containskey(derivedFRLId) && derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.MODIFY)){
                String diffAttrStr = OrderIntegrationSystemInterfaceUtility.extractDiferringAttributes(frlInventoryJSONByFRLId.get(derivedFRLId).get(FRL_JSON_STR), frlInventoryJSONByFRLId.get(derivedFRLId).get(INV_JSON_STR));
                List<String> diffAttrs = new List<String>();
                // Cambios para guardar valor nuevo y anterior 517240
                Map<String,Object> diffAttrMap = (Map<String,Object>)JSON.deserializeUntyped(diffAttrStr);

                for(String str : diffAttrMap.keySet()){
                   
                    diffAttrs.add(str);
                    List<Object> attValues = (List<Object>)diffAttrMap.get(str);
                    System.debug('==nuevo-str==='+str);
                    System.debug('==nuevo-attValues==='+JSON.serialize(attValues));

                    listProductosDiff.add(new EricsonRequestJSON.ProdWithDiffAttrs(strfulfilmentProductName,str,(String)attValues.get(0),(String)attvalues.get(1)));
                    System.debug('==nuevo-listProductosDiff==='+listProductosDiff.toString());
                }


                childAttrs.add(new EricsonRequestJSON.cls_childattributes(OrderIntegrationSystemInterfaceConstants.CHANGE_CFS, diffAttrs));

            }
            String po_AdminCharge = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get('id');
            System.debug('==strCHANGEATTR Add==='+derivedStrAction);                                                                               
            
            if((derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ADD) && (po_AdminCharge == OrderIntegrationSystemInterfaceConstants.ADMIN_CHARGE_PRODUCT))){
                
                for(String key : attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).keyset()){
                    EricsonRequestJSON.cls_childattributes orderItemChildAttrInstance = new EricsonRequestJSON.cls_childattributes();                        
                    if(String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key))){
                        if(key != OrderIntegrationSystemInterfaceConstants.S_FAMILY){
                            orderItemChildAttrInstance.name = key;
                            if(key != OrderIntegrationSystemInterfaceConstants.TAXES){
                                if(key == OrderIntegrationSystemInterfaceConstants.PRICE){
                                    String priceReal = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key);
                                    orderItemChildAttrInstance.value.add(priceReal.substringBefore('.00'));
                                }else{
                                    orderItemChildAttrInstance.value.add((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key));
                                } 
                            }else{
                                Decimal priceAux = Decimal.valueOf((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(OrderIntegrationSystemInterfaceConstants.PRICE));
                                Decimal taxesAux = Decimal.valueOf((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(key));
                                String taxesReal = String.valueOf(taxesAux - priceAux);
                                orderItemChildAttrInstance.value.add(taxesReal.substringBefore('.00'));
                            }
                            childAttrs.add(orderItemChildAttrInstance);
                        }
                    }                
                }                
            }
            /*
            *=================================================================================================================================================================================================================
            * add attributes list for child products -> attrs[]  ----- END
            *=================================================================================================================================================================================================================
            */
            
            
            /*
            *=================================================================================================================================================================================================================
            * add product offering Id for all products : productOffering -> Id  ----- BEGIN
            *=================================================================================================================================================================================================================
            */
            EricsonRequestJSON.cls_productOffering orderItemProductOfferingInstance = new EricsonRequestJSON.cls_productOffering();
            orderItemProductOfferingInstance = (EricsonRequestJSON.cls_productOffering)System.JSON.deserialize(JSON.serialize(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING)), EricsonRequestJSON.cls_productOffering.class);
            /*
            *=================================================================================================================================================================================================================
            * add product offering Id for all products : productOffering -> Id  ----- END
            *=================================================================================================================================================================================================================
            */
            
            
            
            /*
            *=================================================================================================================================================================================================================
            * add all products, prices and applicable product characteristics ---- BEGIN
            *=================================================================================================================================================================================================================
            */
            Integer productCounter = 1;
            
            EricsonRequestJSON.cls_product productinstance = new EricsonRequestJSON.cls_product();
            
            EricsonRequestJSON.cls_productPrice orderItemPProductPriceInstance = new EricsonRequestJSON.cls_productPrice();
            
            List<EricsonRequestJSON.cls_productPrice> oIProductPriceList = new List<EricsonRequestJSON.cls_productPrice>();
            
            if(    attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG) 
                && Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG).get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG)) 
                && OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).containsKey((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                
                productinstance = (EricsonRequestJSON.cls_product)System.JSON.deserialize(JSON.serialize(OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT)), EricsonRequestJSON.cls_product.class);
                
                productinstance.productCharacteristics = new List<EricsonRequestJSON.cls_productCharacteristics>();
                
                System.debug('===product12345=cfsSpec=before for====='+OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID))));
                
                for(String cfsSpec : OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                    System.debug('===product12345=cfsSpec======'+cfsSpec);
                    productinstance.productSpecification = cfsSpec != null && cfsSpec.startsWith(OrderIntegrationSystemInterfaceConstants.PS_IGNORE) ? '' : cfsSpec;        // GAL 2024-04-24: Dummy Prod Spec should be ommited
                    
                    String productIdTemp = '';
                    
                    if(DescProductId == 0){
                        productIdTemp = envtDateStr + fulfilmentIdStr + (productCounter < 10 ? (OrderIntegrationSystemInterfaceConstants.DOUBLE_ZERO) : (productCounter < 100 ? (OrderIntegrationSystemInterfaceConstants.S_ZERO) : '')) + productCounter ;
                        DescProductId = Long.valueOf(productIdTemp) + 50;
                    }                                        
                    /*------Ashish Along with productId, add product specification ------*/
                    /*------Only generate productId for Action Add--------*/
                    if(!prodResServiceIdByFRL.containsKey(derivedFRLId)){
                        prodResServiceIdByFRL.put(derivedFRLId, new Map<String, Set<Object>>());
                    }
                    if(!prodResServiceIdByFRL.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID)){
                        prodResServiceIdByFRL.get(derivedFRLId).put(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID , new Set<Object>());
                    }
                    if (derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ADD)){
                        System.debug('=====inside productId assignment If add====');
                        if(!prodResServiceIdByFRL.containsKey(derivedFRLId)){
                            prodResServiceIdByFRL.put(derivedFRLId, new Map<String, Set<Object>>());
                        }
                        if(orderInstance.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){

                            if(boolIsDuplicate){
                                strProductId = envtDateStr + fulfilmentIdStr + (productCounter < 10 ? (OrderIntegrationSystemInterfaceConstants.DOUBLE_ZERO) : (productCounter < 100 ? (OrderIntegrationSystemInterfaceConstants.S_ZERO) : '')) + productCounter ;
                                productCounter++;
                            }
                            Map<String,Object> mapInputGetcfsSpecId = new Map<String,Object>();
                            if(strfulfilmentProductName == OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT){
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(productCode).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS));
                            }else{
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(strfulfilmentProductName).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS));
                            }
                            mapInputGetcfsSpecId.put('cfsSpec',cfsSpec);
                            productinstance.productId = OM_OrderIntegrationHelper.getcfsSpecId(mapInputGetcfsSpecId);
                        }
                        // Si se está realizando una reasignación de producto técnico en un Cambio de plan se toma el ProductId (SOM) que se encuentra en el Inventory Item relacionado al FFRL correspondiente y se hereda al nuevo FFRL v. 2.4.1
                        else if(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN){
                            String ffrlIdOrg = mapProductoTecnico.get(productCode).get(OrderIntegrationSystemInterfaceConstants.S_DISCONNECT +'/'+OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN);
                            String productId = '';
                            if(   serviceProductResourceIdsByFulfilmentNo.containsKey(ffrlIdOrg) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS).containsKey(cfsSpec)){
                                productId = serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS).get(cfsSpec);
                            }
                            productinstance.productId = productId;
                        }else{
                            productinstance.productId = envtDateStr + fulfilmentIdStr + (productCounter < 10 ? (OrderIntegrationSystemInterfaceConstants.DOUBLE_ZERO) : (productCounter < 100 ? (OrderIntegrationSystemInterfaceConstants.S_ZERO) : '')) + productCounter ;
                            productCounter++;
                        }

                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID).add(JSON.deserializeUntyped('{"'+cfsSpec+'":"'+productinstance.productId+'"}'));
                    }else{
                        System.debug('====inside productId assignment suspend====');
                        System.debug('====inside productId assignment suspend===derivedFRLId='+serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId));
                        System.debug('====inside productId assignment suspend===productIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS));
                        System.debug('====inside productId assignment suspend===productIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS));
                        System.debug('====inside productId assignment suspend==get=productIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS));
                        productinstance.productId = (serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId) && 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS) &&
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS).containsKey(cfsSpec)) ? 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS).get(cfsSpec) : '';
                        System.debug('===productinstance.productId===='+productinstance.productId+ 'Product Specification:'+cfsSpec); /* HDU-743267 Utilizar siempre cfsSpec para evitar el tema de DUMMY PS */
                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_ID).add(JSON.deserializeUntyped('{"'+cfsSpec+'":"'+productinstance.productId+'"}'));
                    }
                    if(OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.containsKey(OrderIntegrationSystemInterfaceConstants.S_PRODUCT) && OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).containsKey(cfsSpec)){
                        Boolean isActivation = false;
                        if(derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORTINRETOMA)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN_A)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_DELETE)
                                                                || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_ADD)){
                               isActivation = true;
                        }
                        for(String cfsCharac : OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).get(cfsSpec)){
                            System.debug('===product12345=cfsCharac======'+cfsCharac);
                            
                            EricsonRequestJSON.cls_productCharacteristics orderItemPProductCharacInstance = new EricsonRequestJSON.cls_productCharacteristics();
                            
                            //----Este bloque consume la matriz de decision para obtener el valor de COS-----------
                            if(cfsCharac.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.TARGET_ATTRIBUTE_COS) && (derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_ADD) ||
                                        derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN) || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PRE_POST_MIGRA) ||
                                        derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_MODIFY))){ 
                                
                                Map<String,Object> mapInputCos = new Map<String,Object>();        
                                mapInputCos.put('attrCodeValueMap',attrCodeValueMap);
                                cos = OM_OrderIntegrationHelper.invokeDecisionMatrixCos(mapInputCos);
                                updateCos = true;
                            }
                            //--------------------------------------------------------------------------------------
                            
                            if(attrCodeValueMap.containskey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC)&& attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).containskey(cfsCharac) && String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(cfsCharac))){
                                
                                Boolean flagSusp = false;
                                if( cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_COLLECTIONS) || 
                                    cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_CUSTOMER) ||
                                    cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_FRAUD) ||
                                    cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_LOST) || 
                                    cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_THEFT) || 
                                    cfsCharac.equals(OrderIntegrationSystemInterfaceConstants.SUSBY_WARRANTY)){ 
                                    flagSusp = true;
                                }
                                if(cfsCharac == OrderIntegrationSystemInterfaceConstants.DESCRIPTION_OFFER_KEY && ((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(cfsCharac)).contains(OrderIntegrationSystemInterfaceConstants.SUB_DESCRIPTION_OFFER)){
                                    OM_SaveAttributeName_cls.createAttName(cfsCharac,attrCodeValueMap,mapAttNamesAndCodes,orderItemPProductCharacInstance);
                                    productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                                } else if(cfsCharac.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.TARGET_ATTRIBUTE_COS)){
                                    orderItemPProductCharacInstance.name = cfsCharac;
                                    if(derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_MODIFY)){
                                        orderItemPProductCharacInstance.value = cos; 
                                    }else{
                                        orderItemPProductCharacInstance.value = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(cfsCharac);
                                    }  
                                    orderItemPProductCharacInstance.isConfigurable = true;
                                    productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                                
                                } else if((isActivation == false || (cfsCharac != OrderIntegrationSystemInterfaceConstants.PERFIL_CAN && cfsCharac != OrderIntegrationSystemInterfaceConstants.NO_CAN_USAGE )) 
                                            && !(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION && flagSusp == true ) ){
                                    
                                    orderItemPProductCharacInstance.name = cfsCharac;
                                    String valueProductChar = '';

                                    if (cfsCharac == 'fechaActivacion' && derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.REINSTALL_SUBACTION) {
                                        valueProductChar = ordCreateDate;
                                    } else {
                                        valueProductChar = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(cfsCharac);
                                    }
                                    
                                    System.debug('===valueProductChar--fechaActivacion======='+valueProductChar);
                                    
                                    //START - PARA LA FECHA DE ACTIVACIÓN SE FORMATEA A HORARIO GMT BUG-739902
                                    if(cfsCharac == 'fechaActivacion'){
                                        if(!valueProductChar.contains('Z') && !valueProductChar.contains('T')){
                                            Datetime fechaActivacion = Datetime.valueOfgmt(valueProductChar);
                                            orderItemPProductCharacInstance.value = fechaActivacion.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                                        }else{
                                            orderItemPProductCharacInstance.value = valueProductChar;
                                        }   
                                    }else{
                                        orderItemPProductCharacInstance.value = valueProductChar.substringBefore('.00'); //elimina los decimales
                                    }
                                    //END - PARA LA FECHA DE ACTIVACIÓN SE FORMATEA A HORARIO GMT BUG-739902
                                    orderItemPProductCharacInstance.isConfigurable = true;
                                    productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                                }
                            } else if( cfsCharac == OrderIntegrationSystemInterfaceConstants.BENEFIT_TYPE && mapAppliedPromotionOtros  != null ){  //1.0.11
                                for (Map <String, Object> outputOAPDRMapPromo : mapAppliedPromotionOtros) {
                                    if (productCode == outputOAPDRMapPromo.get(OrderIntegrationSystemInterfaceConstants.CODE) ) {
                                        System.debug('====outputOAPDRMapPromo====='+outputOAPDRMapPromo);
                                        orderItemPProductCharacInstance.name = cfsCharac;
                                        orderItemPProductCharacInstance.value = (String)outputOAPDRMapPromo.get(OrderIntegrationSystemInterfaceConstants.CAT_TYPE); 
                                        orderItemPProductCharacInstance.isConfigurable = true;
                                        productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                                    }
                                }
                            } else if(cfsCharac.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.TARGET_ATTRIBUTE_COS) &&
                                        (derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_ADD) ||
                                        derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN) ||
                                        derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PRE_POST_MIGRA))){ 
                                    orderItemPProductCharacInstance.name = cfsCharac;
                                    orderItemPProductCharacInstance.value = cos; 
                                    orderItemPProductCharacInstance.isConfigurable = true;
                                    productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                            } else if(OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.containskey(actionStr) && OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC)){
                                System.debug('===product12345=key before======t'+OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC));
                                System.debug('===product12345=key before======t'+OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT));
                                for(String key : OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).keySet()){
                                    if(key.equalsIgnoreCase(cfsCharac)){
                                        System.debug('====getOrderLineItemPriceByFRL====='+getOrderLineItemPriceByFRL);
                                        System.debug('====getOrderLineItemPriceByFRL===cfsCharac=='+cfsCharac);
                                        String recurringChargeStr = '';
                                        if(getOrderLineItemPriceByFRL.containsKey(productCode+'_'+derivedStrSubAction)){
                                            recurringChargeStr = (getOrderLineItemPriceByFRL.get(productCode+'_'+derivedStrSubAction).containsKey(OrderIntegrationSystemInterfaceConstants.RECURRING_CHARGE)) ? String.valueOf(getOrderLineItemPriceByFRL.get(productCode+'_'+derivedStrSubAction).get(OrderIntegrationSystemInterfaceConstants.RECURRING_CHARGE)) : '';
                                        }
                                        String attrValueStr = (cfsCharac.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.PLAN_CFM) || cfsCharac.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.TOTAL_CARG_INFO)) ? recurringChargeStr : (String)OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(key);
                                        System.debug('====getOrderLineItemPriceByFRL===cfsCharac====attrValueStr===='+attrValueStr);
                                        orderItemPProductCharacInstance.name = cfsCharac;
                                        orderItemPProductCharacInstance.value = attrValueStr; 
                                        orderItemPProductCharacInstance.isConfigurable = true;
                                        productinstance.productCharacteristics.add(orderItemPProductCharacInstance);
                                    }
                                }
                            }
                        }    
                    }
                    //Se agregan los product characteristics que no estan en la metadata
                    String PO_Product = (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get('id');
                    Map<String, Object> inputProdCharac = new Map<String, Object>();
                    inputProdCharac.put('lstParents',lstParents);
                    inputProdCharac.put('PO_Product',PO_Product);
                    inputProdCharac.put('orderItemPCNewResource',orderItemPCNewResource);
                    inputProdCharac.put('derivedStrSubAction',derivedStrSubAction);
                    inputProdCharac.put('productCode',productCode);
                    inputProdCharac.put('subscription',subscription);
                    inputProdCharac.put('productinstance',productinstance);
                    inputProdCharac.put('mapAgrupado',mapAgrupado);
                    inputProdCharac.put('derivedFRLId',derivedFRLId);
                    inputProdCharac.put('getOrderLineItemPriceByFRL',getOrderLineItemPriceByFRL);
                    inputProdCharac.put('MapGen',MapGen);
                    inputProdCharac.put('AttributeDefaultValues',AttributeDefaultValues);
                    inputProdCharac.put('orderInstance',orderInstance);
                    inputProdCharac.put('mapProductosConVigencia', mapProductosConVigencia);
                    inputProdCharac.put('fechaCreacion', fechaCreacion);
                    inputProdCharac.put('attrCodeValueMap', attrCodeValueMap);
                    OM_OrderIntegrationHelper.setProdCharacWithoutMetaData(inputProdCharac);
                }
                
                productinstance.productPrice = new List<EricsonRequestJSON.cls_productPrice>();
                
                if(    !derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.SUSPEND_DEACTIVATE) 
                    && OrderIntegrationSystemInterfaceUtility.priceMappingByTechnicalProduct.containsKey((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                    /*
                    *=================================================================================================================================================================================================================
                    * product price List preparation ---- BEGIN
                    *=================================================================================================================================================================================================================
                    */
                    for(OMEricsonChargeTypeSpec__mdt key : OrderIntegrationSystemInterfaceUtility.priceMappingByTechnicalProduct.get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                        if(key.ChargeType__c.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('CUSTOM_PRICE'))){                                                      
                            if(!derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('S_ADD'))){    
                                if(!derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACTION_CON_RED')) &&
                                   !derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY')) &&
                                   !derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACT_ACTIVATION_PORT_IN')) &&
                                   !derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACT_REINSTALL')) &&
                                   !derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACT_REACTIVATION_PORTOUT'))){
                                       
                                       continue;
                                   }
                            }
                        }
                       
                        orderItemPProductPriceInstance = new EricsonRequestJSON.cls_productPrice();
                        orderItemPProductPriceInstance.taxCode = null;
                        //orderItemPProductPriceInstance.v_currency = 'COP'; ---- commenting as agreed with Ericsson, 20 March. Ashish tested with customer
                        orderItemPProductPriceInstance.chargeTypeCode = key.ChargeType__c;
                        orderItemPProductPriceInstance.popId = key.PopId__c ;
                        
                        System.debug('====orderItemPProductPriceInstance.chargeTypeCode========'+orderItemPProductPriceInstance.chargeTypeCode);
                        
                        System.debug('=====key.Price__c=========='+key.Price__c+'Price'+getOrderLineItemPriceByFRL.get(productCode+'_'+derivedStrSubAction));//.get(key.Price__c));
                        Decimal productPrice = 0.00;
                        if(getOrderLineItemPriceByFRL.containsKey(productCode+'_'+derivedStrSubAction)){
                            productPrice = (getOrderLineItemPriceByFRL.get(productCode+'_'+derivedStrSubAction).containsKey(key.Price__c))? Decimal.valueOf(String.valueOf(getOrderLineItemPriceByFRL.get(productCode+'_'+derivedStrSubAction).get(key.Price__c))) : 0.00;
                            productPrice = productPrice.setScale(2, RoundingMode.HALF_UP);
                        }
                        orderItemPProductPriceInstance.amount = productPrice;
                        /**
						* @description: Si el valor del campo FVU_Paid__c es true y es una (activacion-portin) entonces se envia precio en 0
						* @author Hever Salas | 09-19-2024 
						**/
                        if(productCode == OrderIntegrationSystemInterfaceConstants.TECHNICAL_SIMCARD_PRODUCT 
                           && ((derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ADD) && orderItemEstaPagado == true) 
                               || (derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('MODIFY')) 
                                   && (derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACTION_CON_RED'))
                                       || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY'))
                                       || derivedStrSubAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_NOCHANGE'))))
                               || derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('S_NOCHANGE'))
                               || derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('S_RESUME'))
                               || derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('S_SUSPEND'))
                               || derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.getValue('S_DISCONNECT')))){
                                   orderItemPProductPriceInstance.amount = 0.00;
                               }
                        System.debug('=====orderItemPProductPriceInstance.amount=========='+orderItemPProductPriceInstance.amount); 
                        
                        orderItemPProductPriceInstance.characteristics = new List<EricsonRequestJSON.cls_characteristics>();
                        
                        if(OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_PRICE).get(key.ChargeType__c) <> null){                        
                            
                            for(String cfsCharac : OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_PRICE).get(key.ChargeType__c)){
                                System.debug('===cfsCharacTest13-05======='+cfsCharac);
                                System.debug('===cfsCharac======='+cfsCharac);
                                Boolean isProductChar = (OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC) && OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC).containskey(OrderIntegrationSystemInterfaceConstants.CFS_CHAR));
                                Boolean isAttributeEmpty = (attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC) && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC).containskey(cfsCharac));
                                String productPriceCharStr = (isAttributeEmpty) ? (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC).get(cfsCharac) : (isProductChar) ? (OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_PRICE_CHARAC).get(cfsCharac)) : null ;
                                orderItemPProductPriceInstance.characteristics.add(new EricsonRequestJSON.cls_characteristics(cfsCharac, productPriceCharStr));
                            }
                        }
                        
                        productinstance.productPrice.add(orderItemPProductPriceInstance);
                            
                        /*
						*=================================================================================================================================================================================================================
                        * product price List preparation ---- END
                        *=================================================================================================================================================================================================================
                        */
                    }
                }
            }else if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG) && Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG).get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_FLAG))){
                // add error handling if no product specification available
            }
            
            /*
            *=================================================================================================================================================================================================================
            * add all products, prices and applicable product characteristics ---- END
            *=================================================================================================================================================================================================================
            */
            
            
            /*
            *=================================================================================================================================================================================================================
            * Services and its characteristics - BEGIN
            *=================================================================================================================================================================================================================
            */
            
            List<EricsonRequestJSON.cls_services> servicesListInstance = new  List<EricsonRequestJSON.cls_services>();
            EricsonRequestJSON.cls_services OIServicesInstance;
            EricsonRequestJSON.cls_serviceCharacteristics orderItemServiceCharacInstance = new EricsonRequestJSON.cls_serviceCharacteristics();
            List<EricsonRequestJSON.cls_serviceCharacteristics> oIServiceCharacList;
            Integer serviceCounter = 101;
            
            if(    attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_FLAG)
                && Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_FLAG).get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_FLAG))
                && OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).containsKey((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                
                System.debug('=====OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(Service)====='+OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE));
                System.debug('=======123=========='+OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID))));
                
                for(String cfsSpec : OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                    
                    String serviceIdTemp = '';
                    if(DescServiceId == 0){
                        serviceIdTemp = envtDateStr + fulfilmentIdStr + (serviceCounter);
                        DescServiceId = Long.valueOf(serviceIdTemp) + 50;
                    }           
                    
                    system.debug('===cfsSpec===='+cfsSpec);
                    
                    OIServicesInstance = new EricsonRequestJSON.cls_services();
                    oIServiceCharacList = new List<EricsonRequestJSON.cls_serviceCharacteristics>();
                    
                    if(OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).get(cfsSpec) <> null){
                        
                        for(String cfsCharac : OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).get(cfsSpec)){
                            
                            System.debug('===cfsCharac==='+cfsCharac);
                            System.debug('==attrCodeValueMap.get(cls_serviceCharacteristics)==='+attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR));
                            
                            orderItemServiceCharacInstance = new EricsonRequestJSON.cls_serviceCharacteristics();
                            
                            if(OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR).containskey(cfsCharac)){
                                
                                orderItemServiceCharacInstance.name = cfsCharac;
                                orderItemServiceCharacInstance.value = OrderIntegrationSystemInterfaceUtility.sourceAndTargetAttrByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR).get(cfsCharac);
                                orderItemServiceCharacInstance.isConfigurable = true;
                                oIServiceCharacList.add(orderItemServiceCharacInstance);
                                
                            }else if(   attrCodeValueMap.containskey(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR) 
                                     && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR).containskey(cfsCharac)
                                     && String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR).get(cfsCharac))){
                                
                                orderItemServiceCharacInstance.name = cfsCharac;
                                orderItemServiceCharacInstance.value = String.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_SERVICE_CHAR).get(cfsCharac));
                                orderItemServiceCharacInstance.isConfigurable = true;
                                oIServiceCharacList.add(orderItemServiceCharacInstance);
                            }                           
                        }
                    }

                    OIServicesInstance.serviceCharacteristics = oIServiceCharacList;
                    OIServicesInstance.cfsSpecification = cfsSpec;
                    OIServicesInstance.serviceType = OrderIntegrationSystemInterfaceConstants.SERVICES_SERVICE_TYPE;
                    
                    OIServicesInstance.action = OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.get(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType);
                    OIServicesInstance.state = rootAssetStatusStr; //(derivedStrSubAction.equalsIgnoreCase('Suspend-Deactivate'))? rootAssetStatusStr : '' ;
                    
                    /*-------Ashish Along with serviceId, copy CFS Specification--------*/
                    /*------Only generate serviceId for Action Add--------*/
                    if(!prodResServiceIdByFRL.containsKey(derivedFRLId)){
                        prodResServiceIdByFRL.put(derivedFRLId, new Map<String, Set<Object>>());
                    }
                    if(!prodResServiceIdByFRL.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.SERVICE_ID)){
                        prodResServiceIdByFRL.get(derivedFRLId).put(OrderIntegrationSystemInterfaceConstants.SERVICE_ID , new Set<Object>());
                    }
                    if (derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ADD)){
                        System.debug('====inside service assignment Add====');
                        
                        if(orderInstance.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){

                            if(boolIsDuplicate){
                                mapServiceId.put(cfsSpec,envtDateStr + fulfilmentIdStr + (serviceCounter));
                                serviceCounter++;
                            }
                            Map<String,Object> mapInputGetcfsSpecId = new Map<String,Object>();
                            if(strfulfilmentProductName == OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT){
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(productCode).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS));
                            }else{
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(strfulfilmentProductName).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS));
                            }
                            mapInputGetcfsSpecId.put('cfsSpec', cfsSpec);
                            OIServicesInstance.serviceId = OM_OrderIntegrationHelper.getcfsSpecId(mapInputGetcfsSpecId);

                        }
                        // Si se está realizando una reasignación de producto técnico en un Cambio de plan se toma el ProductId (SOM) que se encuentra en el Inventory Item relacionado al FFRL correspondiente y se hereda al nuevo FFRL v. 2.4.1
                        else if(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN){
                            String ffrlIdOrg = mapProductoTecnico.get(productCode).get(OrderIntegrationSystemInterfaceConstants.S_DISCONNECT +'/'+OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN);
                            String serviceId = '';
                            if(   serviceProductResourceIdsByFulfilmentNo.containsKey(ffrlIdOrg) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).containsKey(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS).containsKey(cfsSpec)){
                                serviceId = serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS).get(cfsSpec);
                            }
                            OIServicesInstance.serviceId = serviceId;
                        }else{
                            OIServicesInstance.serviceId = envtDateStr + fulfilmentIdStr + (serviceCounter) ;
                            serviceCounter++;
                        }
                        
                        
                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.SERVICE_ID).add(JSON.deserializeUntyped('{"'+OIServicesInstance.cfsSpecification+'":"'+OIServicesInstance.serviceId+'"}'));  
                    }else{
                        System.debug('====inside serviceId assignment suspend====');
                        System.debug('====inside serviceId assignment suspend===derivedFRLId='+serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId));
                        System.debug('====inside serviceId assignment suspend===serviceIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS));
                        System.debug('====inside serviceId assignment suspend===serviceIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS));
                        System.debug('====inside serviceId assignment suspend==get=serviceIds='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS));
                        
                        OIServicesInstance.serviceId = (serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId) && 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS) && 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS).containsKey(cfsSpec)) ? 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS).get(cfsSpec) : '';
                        
                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.SERVICE_ID).add(JSON.deserializeUntyped('{"'+OIServicesInstance.cfsSpecification+'":"'+OIServicesInstance.serviceId+'"}'));                        
                    }
                    
                    OIServicesInstance.serviceCandidate = null;
                    servicesListInstance.add(OIServicesInstance);
                    
                    System.debug('====OIServicesInstance==='+JSON.serializePretty(OIServicesInstance));
                }
            }

            /*=================================================================================================================================================================================================================
            * Services and its characteristics --- END
            *=================================================================================================================================================================================================================
            */
            
            
            /*=================================================================================================================================================================================================================
            * Resources and its characteristics - BEGIN
            *=================================================================================================================================================================================================================
            */
            
            List<EricsonRequestJSON.cls_resources> resourcesListInstance = new  List<EricsonRequestJSON.cls_resources>();
            EricsonRequestJSON.cls_resources OIResourceInstance;
            EricsonRequestJSON.cls_resourceCharacteristics orderItemResourceCharacInstance = new EricsonRequestJSON.cls_resourceCharacteristics();
            List<EricsonRequestJSON.cls_resourceCharacteristics> oIResourceCharacList;
            Integer resourceCounter = 201;
            
            if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_FLAG) && Boolean.valueOf(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_FLAG).get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_FLAG))){
                
                for(String cfsSpec : OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE).get((String)(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID)))){
                    
                    system.debug('===cfsSpec===='+cfsSpec);
                    OIResourceInstance = new EricsonRequestJSON.cls_resources();
                    
                    if(OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE).get(cfsSpec) <> null){
                        
                        oIResourceCharacList = new List<EricsonRequestJSON.cls_resourceCharacteristics>();
                        
                        for(String cfsCharac : OrderIntegrationSystemInterfaceUtility.characteristicByCfsSpec.get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE).get(cfsSpec)){
                            
                            OM_OrderIntegrationHelper.setOIResourcesCharacteristics(orderItemResourceCharacInstance, actionStr, derivedStrSubAction, cfsCharac, cfsSpec, oIResourceCharacList, attrCodeValueMap, orderInstance, subscription, orderItemPCNewResource, resourceNRN, topOrderType);
                        }
                        
                        OIResourceInstance.resourceCharacteristics = oIResourceCharacList;
                        
                    }
                    
                    OIResourceInstance.resourceSpecification = cfsSpec;
                    OIResourceInstance.resourceCandidate = '';
                    OIResourceInstance.isLogical = OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).isLogical__c;
                    OIResourceInstance.isCompound = false;
                    OIResourceInstance.parentId = '';
                    OIResourceInstance.physicalResourceId = '';
                    OIResourceInstance.resourceType = (String.isNotBlank((String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).ResourceType__c))? (String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).ResourceType__c : '';
                    OM_OrderIntegrationHelper.setOIResource_ResourceNumber(OIResourceInstance, derivedStrSubAction, attrCodeValueMap, cfsSpec, subscription);
                    
                    OIResourceInstance.serialNumber = (attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR) && 
                    String.isNotBlank((String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).SerialNumber__c) && 
                    attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).containsKey((String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).SerialNumber__c )) ? 
                    (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_RESOURCE_CHAR).get((String)OrderIntegrationSystemInterfaceUtility.ericsonResourceSpecByNodes.get(cfsSpec).SerialNumber__c ) : '' ;
                    OIResourceInstance.action = OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.get(derivedStrAction+derivedStrSubAction+derivedStrTechProductSubType);
                    
                    /*--------Ashish Along with resourceId, copy resourceSpecification-----------*/
                    /*------Only generate resourceId for Action Add--------*/
                    if(!prodResServiceIdByFRL.containsKey(derivedFRLId)){
                        prodResServiceIdByFRL.put(derivedFRLId, new Map<String, Set<Object>>());
                    }
                    if(!prodResServiceIdByFRL.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID)){
                        prodResServiceIdByFRL.get(derivedFRLId).put(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID , new Set<Object>());
                    }
                    if (derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_ADD)){
                        System.debug('====inside resourceId assignment Add====');

                        if(orderInstance.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){

                            if(boolIsDuplicate){
                                mapResourceId.put(cfsSpec,envtDateStr + fulfilmentIdStr + resourceCounter);
                                resourceCounter++;
                            }
                            Map<String,Object> mapInputGetcfsSpecId = new Map<String,Object>();
                            if(strfulfilmentProductName == OrderIntegrationSystemInterfaceConstants.TECHNICAL_OTT_PRODUCT){
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(productCode).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS));
                            }else{
                                mapInputGetcfsSpecId.put('lstInventoryItemCesion' , mapInventoryItemCesion.get(strfulfilmentProductName).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS));
                            }
                            mapInputGetcfsSpecId.put('cfsSpec', cfsSpec);
                            OIResourceInstance.resourceId = OM_OrderIntegrationHelper.getcfsSpecId(mapInputGetcfsSpecId);

                        }
                        // Si se está realizando una reasignación de producto técnico en un Cambio de plan se toma el ProductId (SOM) que se encuentra en el Inventory Item relacionado al FFRL correspondiente y se hereda al nuevo FFRL v. 2.4.1
                        else if(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN){
                            String ffrlIdOrg = mapProductoTecnico.get(productCode).get(OrderIntegrationSystemInterfaceConstants.S_DISCONNECT +'/'+OrderIntegrationSystemInterfaceConstants.CHANGEPLAN_REASSIGN);
                            String resourceId = '';
                            if(   serviceProductResourceIdsByFulfilmentNo.containsKey(ffrlIdOrg) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).containsKey(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS) 
                               && serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS).containsKey(cfsSpec)){
                                resourceId = serviceProductResourceIdsByFulfilmentNo.get(ffrlIdOrg).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS).get(cfsSpec);
                            }
                            OIResourceInstance.resourceId = resourceId;
                        }else{
                            OIResourceInstance.resourceId = envtDateStr + fulfilmentIdStr + resourceCounter;
                            resourceCounter++;
                        }
                        
                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID).add(JSON.deserializeUntyped('{"'+OIResourceInstance.resourceSpecification+'":"'+OIResourceInstance.resourceId+'"}')); 
                    }else{
                        System.debug('====inside resourceId assignment suspend====');
                        System.debug('====inside resourceId assignment suspend===derivedFRLId='+serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId));
                        System.debug('====inside resourceId assignment suspend===resourceId='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID));
                        System.debug('====inside resourceId assignment suspend===resourceId='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID));
                        System.debug('====inside resourceId assignment suspend==get=resourceId='+serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID));
                        
                        OIResourceInstance.resourceId = (serviceProductResourceIdsByFulfilmentNo.containsKey(derivedFRLId) && 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).containsKey(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS) &&
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS).containsKey(cfsSpec)) ? 
                        serviceProductResourceIdsByFulfilmentNo.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS).get(cfsSpec) : '';
                        
                        prodResServiceIdByFRL.get(derivedFRLId).get(OrderIntegrationSystemInterfaceConstants.RESOURCE_ID).add(JSON.deserializeUntyped('{"'+OIResourceInstance.resourceSpecification+'":"'+OIResourceInstance.resourceId+'"}'));
                    }   
                    
                    resourcesListInstance.add(OIResourceInstance);
                    
                }
                
            }
            /*=================================================================================================================================================================================================================
            *
            * Resources and its characteristics - END
            *=================================================================================================================================================================================================================
            */
            
			/*=================================================================================================================================================================================================================
            * Exceptions - BEGIN
            *=================================================================================================================================================================================================================
            */
            Map<String, Object> inputExceptionsList = new Map<String, Object>();
            inputExceptionsList.put('productCode',productCode);
            inputExceptionsList.put('MapGen',MapGen);
            inputExceptionsList.put('AttributeDefaultValues',AttributeDefaultValues);
            
            List<object> exceptionsListInstance = OM_OrderIntegrationHelper.setExceptions(inputExceptionsList);
            
            //SE AGREGAN LAS EXCEPCIONES CONFIGURADAS EN EL OBJETO OM_ProductoTecnico__c
            Map<String, Object> inputExcepcionesAdicionales = new Map<String, Object>();
            inputExcepcionesAdicionales.put('exceptionsListInstance',exceptionsListInstance);
            inputExcepcionesAdicionales.put('orderSubType',(String)orderInstance.FVU_OrderSubType__c);
            inputExcepcionesAdicionales.put('orderType',(String)orderInstance.Type);
            inputExcepcionesAdicionales.put('origin',(String)orderInstance.OM_Canal__c);
            inputExcepcionesAdicionales.put('productCode',productCode);
            OM_OrderIntegrationHelper.agregarExcepcionesAdicionales(inputExcepcionesAdicionales);
            /*=================================================================================================================================================================================================================
            *
            * Exceptions - END
            *=================================================================================================================================================================================================================
            */
                
                
            currentProductFamily = ((attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR) && 
            attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).containsKey(OrderIntegrationSystemInterfaceConstants.S_FAMILY))? 
            (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM_ATTR).get(OrderIntegrationSystemInterfaceConstants.S_FAMILY) : '');
            
            /*
            * test above ternary operator generation and uncomment if needed
            * if(attrCodeValueMap.containsKey('cls_item.cls_attributes') && attrCodeValueMap.get('cls_item.cls_attributes').containsKey('family'))
            currentProductFamily = (String)attrCodeValueMap.get('cls_item.cls_attributes').get('family');
            */
            
            if(    attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING)
                && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).containsKey(OrderIntegrationSystemInterfaceConstants.S_ID) 
                && OrderIntegrationSystemInterfaceUtility.topLevelProductByFamily.containsKey(currentProductFamily)){
                
                if(OrderIntegrationSystemInterfaceUtility.topLevelProductByFamily.get(currentProductFamily).equalsIgnoreCase((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PRODUCT_OFFERING).get(OrderIntegrationSystemInterfaceConstants.S_ID))){
                    
                    contractIdStr = (attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC) && attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).containsKey(OrderIntegrationSystemInterfaceConstants.CONTRACT_ID))?
                    (String) attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_PROD_CHARAC).get(OrderIntegrationSystemInterfaceConstants.CONTRACT_ID) : '';
                    
                    /*=================================================================================================================================================================================================================
                    * Related Entities only for top level product - BEGIN
                    *=================================================================================================================================================================================================================
                    */
                    
                    EricsonRequestJSON.cls_OIentity oiEntity = new EricsonRequestJSON.cls_OIentity(OrderIntegrationSystemInterfaceConstants.S_CONTRACT);
                    
                    EricsonRequestJSON.cls_contractCreationInformation oiContractCreationInstance = new EricsonRequestJSON.cls_contractCreationInformation();
                    oiContractCreationInstance.attributes = new List<EricsonRequestJSON.cls_attributes>();
                    for(String key : OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY).keySet()){
                        oiContractCreationInstance.attributes.add(new EricsonRequestJSON.cls_attributes(key, (String)OrderIntegrationSystemInterfaceUtility.defaultValueByClassName.get(actionStr).get(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY).get(key)));
                    }
                    
                    if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY)){
                        for(String str : attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY).keySet()){
                            oiContractCreationInstance.attributes.add(new EricsonRequestJSON.cls_attributes(str, String.isNotBlank((String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY).get(str))? 
                            (String)attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_OIT_CLS_RELATED_ENTITY).get(str) : ''));
                        }
                    }
                    
                    oiEntity.contractCreationInformation = oiContractCreationInstance;
                    
                    /*=================================================================================================================================================================================================================
                    * Related Entities only for top level product - END
                    *=================================================================================================================================================================================================================
                    */
                    
                    
                    /*=================================================================================================================================================================================================================
                    * Assign values for Parent Order Item - BEGIN
                    *=================================================================================================================================================================================================================
                    */
                    
                    parentOrderItem = new EricsonRequestJSON.cls_orderItems();
                    parentOrderItem.item = new EricsonRequestJSON.cls_item();
                    if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_ITEM))
                    parentOrderItem.item = (EricsonRequestJSON.cls_item)System.JSON.deserialize(JSON.serialize(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM)), EricsonRequestJSON.cls_item.class);
                    
                    parentOrderItem.item.id = String.valueOf(parentProductId);
                    parentOrderItem.item.productOffering = orderItemProductOfferingInstance;
                    parentOrderItem.item.action = ActionCalculated;
                    
                    parentOrderItem.item.product = (productinstance <> null)? productinstance : null;
                    parentOrderItem.item.resources = (!resourcesListInstance.isEmpty() && resourcesListInstance <> null)? resourcesListInstance : null;
                    parentOrderItem.item.services = (!servicesListInstance.isEmpty() && servicesListInstance <> null)? servicesListInstance : null;
                    parentOrderItem.item.relatedOrderItems = new List<EricsonRequestJSON.cls_relatedOrderItems>();
                    parentOrderItem.item.relatedEntities = new List<EricsonRequestJSON.cls_OIrelatedEntities>();
                    parentOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.S_CONTRACT, OrderIntegrationSystemInterfaceConstants.S_CONTRACT_ID, contractIdStr, oiEntity));
                    parentOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.S_PLACE, null, orderServiceAccount.FVU_SerciveMerId__c, null));
                    if(derivedStrSubAction != OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
                        parentOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)orderBillingAccount.OM_BSCSIntID__c, (String)orderBillingAccount.OM_BSCSIntID__c, null));
                    }else{
                        EricsonRequestJSON.cls_OIentity oiEntityCesionTarget = new EricsonRequestJSON.cls_OIentity(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT);
                        EricsonRequestJSON.cls_OIentity oiEntityCesionSource = new EricsonRequestJSON.cls_OIentity(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT);
                        EricsonRequestJSON.cls_CustomerAccountInformation oiAccountInformationCesionTarget = new EricsonRequestJSON.cls_CustomerAccountInformation();
                        EricsonRequestJSON.cls_CustomerAccountInformation oiAccountInformationCesionSource = new EricsonRequestJSON.cls_CustomerAccountInformation();
                        oiAccountInformationCesionTarget.attributes = new List<EricsonRequestJSON.cls_attributes>();
                        oiAccountInformationCesionSource.attributes = new List<EricsonRequestJSON.cls_attributes>();
                        oiAccountInformationCesionTarget.attributes.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_TARGET));
                        oiAccountInformationCesionSource.attributes.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_SOURCE));
                        oiEntityCesionTarget.customerAccountInformation = oiAccountInformationCesionTarget;
                        oiEntityCesionSource.customerAccountInformation = oiAccountInformationCesionSource;
                        parentOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)billingAccountCesion.OM_BSCSIntID__c, (String)billingAccountCesion.OM_BSCSIntID__c, oiEntityCesionSource));
                        parentOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)orderBillingAccount.OM_BSCSIntID__c, (String)orderBillingAccount.OM_BSCSIntID__c, oiEntityCesionTarget));
                        
                    }
                    
                    parentOrderItem.item.attrs = (!attrs.isEmpty() && attrs <> null)? attrs : null;
                    
                    // Selección de producto padre en caso de Cambio de Plan. Sólo se considera tener dos productos padre en este escenario. Por definición en Ericsson el producto padre original se mantiene. V. 1.0.3
                    // Se guarda información del FFRL padre del plan anterior para heredarlo en el nuevo
                    if (parentOrderMap.containsKey(currentProductFamily) ) {
                        if ( derivedStrAction.equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.S_DISCONNECT)) {
                            parentOrderMap.put(currentProductFamily, parentOrderItem);
                            ffrlJsonAttrDisconnect = JSON.serialize(FRL_JSONAttr);
                            ffrlParentIdAdd = ffrlParentIdTmp;
                            ffrlParentIdDisconnect = derivedFRLId;
                            contractIdDisconnectStr = contractIdStr;
                        }else {
                            ffrlJsonAttrDisconnect = ffrlJsonAttrTmp;
                            ffrlParentIdAdd = derivedFRLId;
                            ffrlParentIdDisconnect = ffrlParentIdTmp;
                            contractIdDisconnectStr = contractIdTmpStr;
                        }
                        prodResServiceIdByFRL.put(ffrlParentIdAdd, new Map<String, Set<Object>>{
                            OrderIntegrationSystemInterfaceConstants.JSON_ATTR => new Set<Object>{ffrlJsonAttrDisconnect},
                            OrderIntegrationSystemInterfaceConstants.PRODUCT_ID_SER => new Set<Object>{frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect) != null ? frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect).get(OrderIntegrationSystemInterfaceConstants.PRODUCT_IDS): null},
                            OrderIntegrationSystemInterfaceConstants.SERVICE_ID_SER => new Set<Object>{frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect) != null ? frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect).get(OrderIntegrationSystemInterfaceConstants.S_SERVICE_IDS): null},
                            OrderIntegrationSystemInterfaceConstants.RESOURCE_ID_SER => new Set<Object>{frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect) != null ? frlInventoryJSONByFRLId.get(ffrlParentIdDisconnect).get(OrderIntegrationSystemInterfaceConstants.S_RESOURCE_IDS): null}
                        }); 
                    }else {
                        parentOrderMap.put(currentProductFamily, parentOrderItem);
                        ffrlJsonAttrTmp = JSON.serialize(FRL_JSONAttr);
                        ffrlParentIdTmp = derivedFRLId;
                        contractIdTmpStr = contractIdStr;
                    }
                    
                    /*=================================================================================================================================================================================================================
                    * Assign values for Parent Order Item - END
                    *=================================================================================================================================================================================================================
                    */
                    
                }else{
                    
                    /*=================================================================================================================================================================================================================
                    * Assign values for Child Order Item - BEGIN
                    *=================================================================================================================================================================================================================
                    */
                    
                    childOrderItem = new EricsonRequestJSON.child_cls_orderItems();
                    childOrderItem.item = new EricsonRequestJSON.child_cls_item();
                    
                    if(attrCodeValueMap.containsKey(OrderIntegrationSystemInterfaceConstants.CLS_ITEM)){
                        childOrderItem.item = (EricsonRequestJSON.child_cls_item)System.JSON.deserialize(JSON.serialize(attrCodeValueMap.get(OrderIntegrationSystemInterfaceConstants.CLS_ITEM)), EricsonRequestJSON.child_cls_item.class);
                    }
                    
                    childOrderItem.item.id = String.valueOf(parentProductId);
                    childOrderItem.item.action = ActionCalculated;
                    
                    if(!childOrderMap.containsKey(currentProductFamily)){
                        childOrderMap.put(currentProductFamily, new List<EricsonRequestJSON.child_cls_orderItems>());
                    }
                    childOrderMap.get(currentProductFamily).add(childOrderItem);
                    
                    if(po_AdminCharge != OrderIntegrationSystemInterfaceConstants.ADMIN_CHARGE_PRODUCT){
                        childOrderItem.item.productOffering = orderItemProductOfferingInstance;
                        childOrderItem.item.product = (productinstance <> null)? productinstance : null;
                        childOrderItem.item.resources = (!resourcesListInstance.isEmpty() && resourcesListInstance <> null)? resourcesListInstance : null;
                        childOrderItem.item.services = (!servicesListInstance.isEmpty() && servicesListInstance <> null)? servicesListInstance : null; 
                        childOrderItem.item.exceptions = (!exceptionsListInstance.isEmpty() && exceptionsListInstance <> null)? exceptionsListInstance : null; 
                    }else{
                        List<EricsonRequestJSON.cls_childRelatedParties> lstRelatedParties = new List<EricsonRequestJSON.cls_childRelatedParties>();
                        EricsonRequestJSON.cls_childRelatedParties relatedPartiesItem = new EricsonRequestJSON.cls_childRelatedParties();
                        relatedPartiesItem.reference = (String)orderInstance.vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c; 
                        relatedPartiesItem.role = OrderIntegrationSystemInterfaceConstants.S_CUSTOMER;
                        lstRelatedParties.add(relatedPartiesItem);
                        childOrderItem.item.relatedParties = lstRelatedParties;
                        
                        childOrderItem.item.orderType = OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_ADMIN_CHARGE;
                    }
                    childOrderItem.item.attrs = childAttrs;
                    
                    childOrderItem.item.relatedEntities = new List<EricsonRequestJSON.cls_OIrelatedEntities>();
                    childOrderItem.item.relatedEntities.addAll(new List<EricsonRequestJSON.cls_OIrelatedEntities>{
                        new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.S_PLACE, null, orderServiceAccount.FVU_SerciveMerId__c, null),
                        new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)orderBillingAccount.OM_BSCSIntID__c, (String)orderBillingAccount.OM_BSCSIntID__c, null)
                    });
                    if(derivedStrSubAction == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
                        childOrderItem.item.relatedEntities.add(new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)billingAccountCesion.OM_BSCSIntID__c, (String)billingAccountCesion.OM_BSCSIntID__c, null));
                    }

                    /*=================================================================================================================================================================================================================
                    * Assign values for Child Order Item - END
                    *=================================================================================================================================================================================================================
                    */
                    
                    /*=================================================================================================================================================================================================================
                    * Duplicate Item for Cesion - BEGIN
                    *=================================================================================================================================================================================================================
                    */
                    Map<String,object> mapParams = new Map<String,object>();
                    mapParams.put('childOrderItem', childOrderItem);
                    mapParams.put('childOrderMap', childOrderMap);
                    mapParams.put('AttributeDefaultValues', AttributeDefaultValues);
                    mapParams.put('orderSubType', (String)orderInstance.FVU_OrderSubType__c);
                    mapParams.put('currentProductFamily', currentProductFamily);
                    mapParams.put('boolIsDuplicate', boolIsDuplicate);
                    mapParams.put('strProductId', strProductId);
                    mapParams.put('mapServiceId', mapServiceId);
                    mapParams.put('mapResourceId', mapResourceId);
                    mapParams.put('resourcesListInstance', resourcesListInstance);
                    mapParams.put('servicesListInstance', servicesListInstance);
                    mapParams.put('parentProductId', parentProductId);
                    parentProductId = OM_OrderIntegrationHelper.duplicateItem(mapParams);
                    /*=================================================================================================================================================================================================================
                    * Duplicate Item for Cesion - END
                    *=================================================================================================================================================================================================================
                    */
                    
                    
                }
                parentProductId++;
            }
        }

         /*=================================================================================================================================================================================================================
        *  Delete FFRL con action ADD en Cancelacion Voluntaria - BEGIN
        *=================================================================================================================================================================================================================
        */
        DELETE lstFRL;

         /*=================================================================================================================================================================================================================
        *  Delete FFRL con action ADD en Cancelacion Voluntaria - End
        *=================================================================================================================================================================================================================
        */

        
        /*=================================================================================================================================================================================================================
        *  Assign values for Child Order Item(Applied Promotion) - BEGIN
        *=================================================================================================================================================================================================================
        */
        
        if (mapAppliedPromotionObsequio != null ) {
            
            for(Map <String, Object> outputOAPDRMap : mapAppliedPromotionObsequio){ // iterate over all OAP JSON received
                
                System.debug('====outputOAPDRMap====='+outputOAPDRMap);
                childOrderItem = new EricsonRequestJSON.child_cls_orderItems();
                childOrderItem.item = new EricsonRequestJSON.child_cls_item();
                EricsonRequestJSON.cls_product appliedPromotionproduct = new EricsonRequestJSON.cls_product();
                EricsonRequestJSON.cls_productOffering appliedPromotionProductOffering = new EricsonRequestJSON.cls_productOffering();
                List<EricsonRequestJSON.cls_services> appliedPromotionServicesList = new  List<EricsonRequestJSON.cls_services>();
                EricsonRequestJSON.cls_services appliedPromotionOIServices= new EricsonRequestJSON.cls_services();
                childOrderItem.item.relatedEntities = new List<EricsonRequestJSON.cls_OIrelatedEntities>();
                
                List<String> productCfsSpecOAP = new List<String>();
                productCfsSpecOAP = OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_PRODUCT).get((String)outputOAPDRMap.get(OrderIntegrationSystemInterfaceConstants.CODE));
                System.debug('====productCfsSpecOAP====='+productCfsSpecOAP);
                childOrderItem.item.id = String.valueOf(parentProductId);
                childOrderItem.item.orderType = OrderIntegrationSystemInterfaceConstants.ORDER_TYPE;
                childOrderItem.item.action = OrderIntegrationSystemInterfaceConstants.S_ADD;
                appliedPromotionProductOffering.id = (String)outputOAPDRMap.get(OrderIntegrationSystemInterfaceConstants.CODE);
                childOrderItem.item.productOffering = appliedPromotionProductOffering;
                appliedPromotionproduct.productCharacteristics = new List<EricsonRequestJSON.cls_productCharacteristics>();
                appliedPromotionproduct.productSpecification =  (String)productCfsSpecOAP[0]; //respuesta de la metadata
                appliedPromotionproduct.productId = String.valueOf(DescProductId);
                appliedPromotionproduct.isBundled = false;
                childOrderItem.item.product = appliedPromotionproduct;
                childOrderItem.item.resources = null;
                appliedPromotionOIServices.serviceCharacteristics = new List<EricsonRequestJSON.cls_serviceCharacteristics>();
                appliedPromotionOIServices.serviceCandidate = null;
                appliedPromotionOIServices.action = OrderIntegrationSystemInterfaceConstants.S_ADD;
                appliedPromotionOIServices.serviceId = String.valueOf(DescServiceId);
                List<String> serviceCfsSpecOAP = new List<String>();
                serviceCfsSpecOAP = OrderIntegrationSystemInterfaceUtility.cfsSpecByProduct.get(OrderIntegrationSystemInterfaceConstants.S_SERVICE).get((String)outputOAPDRMap.get(OrderIntegrationSystemInterfaceConstants.CODE));
                appliedPromotionOIServices.cfsSpecification = (String)serviceCfsSpecOAP[0];//respuesta de la metadata
                appliedPromotionOIServices.serviceType = OrderIntegrationSystemInterfaceConstants.SERVICES_SERVICE_TYPE;
                appliedPromotionServicesList.add(appliedPromotionOIServices);
                childOrderItem.item.services = appliedPromotionServicesList;
                childOrderItem.item.relatedEntities.addAll(new List<EricsonRequestJSON.cls_OIrelatedEntities>{
                    new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.S_PLACE, null, orderServiceAccount.FVU_SerciveMerId__c, null),
                    new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, (String)orderBillingAccount.OM_BSCSIntID__c, (String)orderBillingAccount.OM_BSCSIntID__c, null)
                });
                if(!test.isRunningTest()){
                    childOrderMap.get('Mobile').add(childOrderItem);
                }
                DescProductId++;
                DescServiceId++;
                parentProductId++;
            }
        }
        /*=================================================================================================================================================================================================================
        * Assign values for Child Order Item(Applied Promotion) - END
        *=================================================================================================================================================================================================================
        */
        
        EricsonRequestJSON.cls_relatedOrderItems relatedOIInstance;
        Object orderItem;
        for(String strFam :childOrderMap.keySet()){
            System.debug('===strFam===='+strFam);
            if(parentOrderMap.containsKey(strFam)){
                instEricsonReq.orderItems.add((Object)parentOrderMap.get(strFam));
                relatedOIInstance = new EricsonRequestJSON.cls_relatedOrderItems();
                relatedOIInstance.role = OrderIntegrationSystemInterfaceConstants.CHILD_OF;
                relatedOIInstance.reference = parentOrderMap.get(strFam).item.id;
                for(EricsonRequestJSON.child_cls_orderItems childOI :childOrderMap.get(strFam)){
                    if(childOI.item.action != OrderIntegrationSystemInterfaceConstants.ACTION_ADMIN_CHARGE){
                        childOI.item.relatedOrderItems = new List<EricsonRequestJSON.cls_relatedOrderItems>();
                        childOI.item.relatedOrderItems.add(relatedOIInstance);
                    }
                    // Herencia de contractId del producto padre a los hijos. En caso de cambio de plan se toma el padre con acción Desconexión v. 1.0.8
                    childOI.item.relatedEntities.addAll(new List<EricsonRequestJSON.cls_OIrelatedEntities>{
                        new EricsonRequestJSON.cls_OIrelatedEntities(OrderIntegrationSystemInterfaceConstants.S_CONTRACT, OrderIntegrationSystemInterfaceConstants.S_CONTRACT_ID, String.isNotBlank(contractIdDisconnectStr) ? contractIdDisconnectStr : contractIdStr, null)
                    });
                        
                    instEricsonReq.orderItems.add((Object)childOI);
                }    
            }
        } 
        
        /*------Update FRL with productId, serviceId and resourceId for Action Add--------*/
        Map<String, Object> mapInputIdPopulate = new Map<String, Object>();
        mapInputIdPopulate.put('prodResServiceIdByFRL',prodResServiceIdByFRL);
        mapInputIdPopulate.put('updateCos',updateCos);
        mapInputIdPopulate.put('cos',cos);
        OrderIntegrationSystemInterfaceHelper.getFulfilmentRequestLineIdPopulate(mapInputIdPopulate);

        String tempId = (String)orderInstance.Id;
        Order orderToUpdate = [SELECT Id, OM_prodsAttrDiff__c FROM Order WHERE Id = :tempId WITH SECURITY_ENFORCED LIMIT 1];
        orderToUpdate.OM_prodsAttrDiff__c = JSON.serialize(listProductosDiff);

        update orderToUpdate;
        
        return instEricsonReq.orderItems;
    }
}