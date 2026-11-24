/**----------------------------------------------------------------------------------------------------------------------------------------------
Author:         Mamata - 16-10-23
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date MM-dd-YY>   @version     <Author>             <Description>                                                                                       
05-06-24		  1.0.1         Hever Salas		    HDU 736685 - Reactivacion 		                                                                    
12-06-24		  1.0.2         Gabriel Alvis		HDU 739902 - Mapeo de external ID se cambio desde Service Account hacia Billing Account 		    
20-jul-24		  1.0.3         Hever Salas			Actualizar reasonCode								  											
31-jul-24		  1.0.4         Hever Salas		    HDU 340689 - Nuevo Order type para portout	- Agregar tiempo extra para requestedCompletionDate		
19-08-24		  1.0.5         Hever Salas		    HDU-366794 - Neg PortIn	
19-08-24          1.0.6         Karen Sanchez       HDU 362385 - Portout Negación: Se agrega nueva logica para mandar el valor de portout en OrderType.
19-09-24	      1.0.7			Hever Salas			HDU 335144 - Se debe enviar precio en 0 cuando FVU_Paid__c es igual a true
20-09-24          1.0.8         Karen Sanchez       HDU 413297 - Se agrega nueva condicional en el método de orderTypeAssigment para considerar el flujo de Portin retoma
20-09-24          1.0.9         Gabriel Alvis       HDU 403314 - Consulta de MSISDN Dummy para envío en caso de Negación de PortOut
15-10-24		  1.0.10	  	Hever Salas		   	HDU-441151 - Ajuste Campo Network
04-11-24		  1.0.11	  	Hever Salas		   	HDU-409739 - Agrupacion Ofertas
12-11-24          1.0.12        Emmanuel Ruarte     BUG-491129 - fechaActivacion Reinstalación
15-11-24          1.0.13        Emmanuel Ruarte     HDU-433767 - Identificar el canal de atencion
20-11-24          1.0.14        Hever Salas     	HDU-341223 - Plan de orquestación Crear orden de Cancelación de Servicio automática futura
25-11-24          1.0.15        Edwalis Avila     	HDU-434114 - [Vista Ordenes]  Tipificacion de las Ordenes
27-11-24          1.0.16        Karen Sanchez     	HDU-336030 - Se agregan nuevas condicionales para enviar Origin,Channel y BackendAction para cuando es cancelación cartera
27-11-24          1.0.17        Emmanuel Ruarte     HDU-494773 - Generación de una orden SOM para permitir la venta de OTT
20-11-24		  1.0.18        Gonzalo Martínez    REQ000005575701 - se cambia parametro de 1 a 8 en los días esperados para completitud de orden en Ericsson
12-12-24          1.0.19        Karen Sanchez       HDU-504835: Se requiere que la fecha de expiración de una orden de portabilidad sea de 45 días de lo contrario debe ser 8 días, se agrega logica dinamica
17-12-24		  1.0.20		Emmanuel Ruarte     BUG-522462 - Error en PO - nodo ""OM Generar JSON SOM Posventa""
18-12-24      	  1.0.21      	Hever Salas     	HDU-417695 - Creacion orden SOM de familia y amigos
20-02-25          1.0.22        Emmanuel Ruarte     BUG-551874 - R4-SIT-E3-No se esta procesando la orden de suspensión masiva por fraude
06-03-25          1.0.23      	Hever Salas      	HDU-544910: Identificacion de Items sin accion
31-03-25          1.0.24        Hever Salas      	HDU-559799: [CESION] Familia y amigos generación de JSON-SOM
02-04-25          1.0.25        Karen Sanchez      	HDU-538800: Se crea nuevo metodo para obtener un mapa con los codigos del objeto vlocity_cmt__Attribute__c y poder mapear el nombre del atributo con el la caracteristica description_offer
04-02-25          1.0.26        Hever Salas    	    HDU-522166: PV - [CESION]  Crear Orden SOM
08-05-25          1.0.27        Hever Salas    	    HDU-520180: [CANALES] Envio informacion al recibir ordenes de canales
25-09-25          2.0           Hever Salas    	    HDU-627710: [CANALES] Identificacion del sistema y usuario origen de creación de la orden
01-10-25          2.1           Hever Salas    	    HDU-522202: [INNOVACION]-Configuracion para recibir solicitudes de productos de innovacion
11-11-2025        2.2           Hever Salas    	    HDU-629197: [INNOVACION] Integracion SOM compra paquetes en productos de innovacion
15-12-2025        2.3           Hever Salas    	    HDU-691571: [EVOLUTIVOS OM]Modificación atributos de info Activación y conciliación de paq adicionales
18-05-2026        2.4           Hllanos   		    HDU-755515: [Evolutivo] Establecer la hora de ejecución para el disparador en SOM
01-06-2026		  2.4.1			Fábrica VASS		HDU-774014: [Proyecto Tráfico Offline - Cambio de ciclo de facturación asíncrono]-En la consulta SOQL "orderInstance" se agrega el field "PVU_NewBillCycle__c"
------------------------------------------------------------------------------------------------------------------------------------------------*/
    global with sharing class OrderIntegrationAccountDetails {
    
        public static Map<String, Map<String, String>> refeByRoleRelatedEntities = new Map<String, Map<String, String>>{
            'Contact'=> new Map<String, String>{
                'FIRSTNAME'=>'FirstName',
                    //'MIDDLENAME'=>'MiddleName', -- Ashish Commented
                    'LASTNAME'=>'LastName'       //------ Ashish Need LastName + FVU_SecondLastName__c Note: FVU_SecondLastName__c can be empty
                    },
                        'Account'=>new Map<String, String>{       
                            'DOCID'=>'FVU_DocumentNumber__c',
                                'TYPE_DOC'=>'FVU_DocumentType__c',
                                //'CUSTOMERCATEGORY'=>'', -------------- add values when ready
                                'PASSWORD_CUSTOMER'=>'',//--------------value assignment handled in code
                                'EMAIL_CUSTOMER'=>'FVU_Email__c',
                                'CONTACT_PHONE_NUMBER'=>'Phone'
                                //'ACEPTA_INFO_LEGAL'=>''
                                }    
        };
                
        public static Map<String, String> relatedEntitiesEntities = new Map<String, String>{
            'DIRECCION'=>'FVU_ServiceShortAddress__c',
                //'REGIONAL'=>'',
                'CIUDAD'=>'FVU_ServiceMunicipality__c',
                'CITY_CODE'=>'FVU_ServiceDaneCode__c',
                'DISCTRICTO'=>'FVU_ServiceState__c',
                'ID'=>'FVU_SerciveMerId__c',
                'DANE'=>'FVU_ServiceDaneCode__c'
                //'ESTRATO'=>'FVU_ServiceExtract__c'
                //'HHPPID'=>'',
                // 'NODE'=>'FVU_AddressNode__c'
                };	

        
    public static String setAccountDetails(Map<String, Object> ipInput, Map<String, Object> inputParamsDR, String url, String path, EricsonRequestJSON.ProdWithoutAction objProdWithoutAction){
        
         /**********************************************************
			Get All CustomMetaData Values ====== Begin
		**********************************************************/
        OrderIntegrationSystemInterfaceUtility.getOMEricsonMappings();//get all custom metadata records by classname with source and target
        OrderIntegrationSystemInterfaceUtility.getOMEricsonProductToCFSSpec();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonCFSspecToCharacteristics();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonTopLevelProductSpec();
        OrderIntegrationSystemInterfaceUtility.getOMOMEricsonChargeTypeSpec();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonActionDerivation();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonResourceSpecNodesMap();
        OrderIntegrationSystemInterfaceUtility.getOMEricsonTipoCodingoMap();
        OrderIntegrationSystemInterfaceUtility.getOMProductoTecnico();
        /**********************************************************
			Get All CustomMetaData Values ====== End
		**********************************************************/
        
        Id orderId = (Id)(ipInput.containsKey(OrderIntegrationSystemInterfaceConstants.ORDER_ID) ? ipInput.get(OrderIntegrationSystemInterfaceConstants.ORDER_ID) : '');
        Id accountId = (Id)(ipInput.containsKey(OrderIntegrationSystemInterfaceConstants.ACCOUNT_ID) ? ipInput.get(OrderIntegrationSystemInterfaceConstants.ACCOUNT_ID) : '');
        Datetime fechaCreacion = Datetime.now();
        String ordCreateDate =  fechaCreacion.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        EricsonRequestJSON instEricsonReq = new EricsonRequestJSON();
        
        Account orderAccount = new Account();
        Account orderServiceAccount = new Account();
        Account orderBillingAccount = new Account();
        Contact orderPrimaryContact = new Contact();
        LIST<OrderItem> orderOrderItem = new List<OrderItem>();
        String topOrderType;
        vlocity_cmt__Subscription__c subscription;
        OrderItem orderItemInstance = new OrderItem();
        Boolean orderItemEstaPagado = false;
        Map<String,String> mapAgrupado = new Map<String,String>();
        InterfaceSettings__mdt interSetmdt;
        Map<String,Map<String,Object>> MapGen = new Map<String,Map<String,Object>>();
        List<Object> lstParents = new List<Object>();
        Map<String,Object> mapProductosConVigencia = new Map<String,Object>();
        
        Order orderInstance = [SELECT Id, OrderNumber, AccountId, FVU_OriginalChannel__c, PVU_SuspensionLevel__c,
                               vlocity_cmt__DefaultServiceAccountId__c, vlocity_cmt__DefaultBillingAccountId__c,
                               vlocity_cmt__OrchestrationPlanId__c, OM_PortabilityProcessId__c, Type, FVU_OrderSubType__c,
                               OM_NRN__c, OM_PortabilityStatus__c, CreatedBy.FVU_BusinessChannel__c, CreatedBy.FederationIdentifier,
                               vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c, PVU_CaseInfo__c, CreatedBy.FVU_CodigoD__c,
                               OM_Canal__c, PVU_NewBillCycle__c, OM_RequestedStartDateSOM__c // V. 2.4.1
                               FROM Order WHERE Id =: orderId WITH SECURITY_ENFORCED LIMIT 1];
        String Channel = (String)orderInstance.CreatedBy.FVU_BusinessChannel__c;
        String Person = (String)orderInstance.CreatedBy.FederationIdentifier;
        String Origin = (String)orderInstance.FVU_OriginalChannel__c;
        String SuspensionLevel = (String)orderInstance.PVU_SuspensionLevel__c;
        String Type = (String)orderInstance.Type;
        String SubType = (String)orderInstance.FVU_OrderSubType__c;
        System.debug('========Channel======='+Channel);
        System.debug('========Person======='+Person);
        String MSISDN = '';
        
        Map<String, String> mapAttribVigencia = OM_AccountDetailsHelper.obtAtributosConVigencia();
        List<OrderItem> lstOrderItems = new List<OrderItem>();
        if(orderInstance.Id <> null){
            lstOrderItems = [SELECT Id, Product2Id, OM_ActiveEndDate__c, vlocity_cmt__RootItemId__c, vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, 
                             FVU_ReasonCode__c, vlocity_cmt__ParentItemId__c, vlocity_cmt__ReliesOnItemId__c, 
                             OM_Status__c, OM_SubCausal__c, Product2.ProductCode, Product2.vlocity_cmt__AttributeDefaultValues__c,Product2.Family, Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SpecificationSubType__c,  Product2.vlocity_cmt__SpecificationType__c, 
                             FVU_Paid__c, vlocity_cmt__SubscriptionId__c, CAT_GroupCharges__c, vlocity_cmt__AttributeSelectedValues__c,
                             (SELECT Id, vlocity_cmt__DestinationFulfilmentRequestLineId__C
                              FROM vlocity_cmt__DestinationDecompositionRelationships__r 
                              WHERE (vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name = :OrderIntegrationSystemInterfaceConstants.TECHNICAL_PLAN_PRODUCT 
                                     OR vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c != '') 
                              AND vlocity_cmt__SourceOrderItemId__r.CAT_GroupCharges__c = true)
                             FROM OrderItem
                             WHERE OrderId =: orderId WITH SECURITY_ENFORCED
                             ORDER BY vlocity_cmt__Action__c DESC // Permite que en casos de Cambio de Plan se presente primero el Action Delete
                            ];
        	
            
            for(OrderItem ordItem : lstOrderItems){
				
                String jsonString = ordItem.Product2.vlocity_cmt__AttributeDefaultValues__c;
                String Family = ordItem.Product2.Family;
                String SpecifType = ordItem.Product2.vlocity_cmt__SpecificationType__c ;
                String SpecifSubType = ordItem.Product2.vlocity_cmt__SpecificationSubType__c ;
                String ProdType = ordItem.Product2.vlocity_cmt__Type__c;
                
                // Asignación del primer elemento raíz de la oferta (en el caso de Cambio de Plan el de Delete)
                if(orderItemInstance.Id == null && ordItem.vlocity_cmt__ParentItemId__c == null && ordItem.vlocity_cmt__ReliesOnItemId__c == null){
                    orderItemInstance = ordItem;
                }

                // Se toma el order item de tipo simcard y se obtiene el valor del campo FVU_Paid__c - Hever Salas | 09-19-2024 
                if(    (ordItem.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD || ordItem.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD)
                    && ordItem.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_ADD ){
                    orderItemEstaPagado = ordItem.FVU_Paid__c;
                   
                }
                
                if(ordItem.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER){
                    Map<String,Object> mapMSISDN = (Map<String, Object>)JSON.deserializeUntyped(ordItem.vlocity_cmt__AttributeSelectedValues__c);
                    
                    if(mapMSISDN.containsKey(OrderIntegrationSystemInterfaceConstants.ATTR_MSISDN) && String.IsNotBlank((String)mapMSISDN.get(OrderIntegrationSystemInterfaceConstants.ATTR_MSISDN))){
                        MSISDN = (String)mapMSISDN.get(OrderIntegrationSystemInterfaceConstants.ATTR_MSISDN);
                    }
                }
                
                //Se condiciona para que ingrese en caso de tener attributos en campo de OItem vlocity_cmt__AttributeDefaultValues__c HDU-494773
                
                if (String.isnotblank(jsonString) && Family == 'Mobile' && SpecifType == 'Offer' && ((ProdType == 'Plan' && SpecifSubType == 'Bundle' ) || (ProdType == 'Add On' && SpecifSubType == 'Simple') )  ) {
                    
                    Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
                    Map<String,Object> ServiceMap = new Map<String,Object>();
                    // Se extraen atributos
                    if (jsonMap.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_SERV_ID)) {
                        String servId = (String)jsonMap.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_SERV_ID);
                        if (String.isNotBlank(servId)) { //1.0.20
                            ServiceMap.put(OrderIntegrationSystemInterfaceConstants.SERVI_ID, servId);
                        }
                    }
                    if (jsonMap.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_TECH_DET)) {
                        String techDet = (String)jsonMap.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_TECH_DET);
                        if (String.isNotBlank(techDet)) { //1.0.20
                            Map<String, Object> maptechDet = (Map<String, Object>)JSON.deserializeUntyped(techDet);
                            ServiceMap.put(OrderIntegrationSystemInterfaceConstants.TECHNICAL_DETAILS, maptechDet);
                        }
                    }
                    //Se asume que el arreglo del campo OM_ProcessDetails__c en el objeto OM_ProductoTecnico__c solo contiene 1 posicion
                    if (jsonMap.containsKey(OrderIntegrationSystemInterfaceConstants.PRODUCT_PRC_DET)) {
                        String prcDet = (String)jsonMap.get(OrderIntegrationSystemInterfaceConstants.PRODUCT_PRC_DET);
                        if (String.isNotBlank(prcDet)) {  //1.0.20
                            Map<String, Object> mapPrcDet = (Map<String, Object>)JSON.deserializeUntyped(prcDet);
                            ServiceMap.put(OrderIntegrationSystemInterfaceConstants.PROCESS_DETAILS, mapPrcDet);
                        }
                    } 
                    MapGen.put(ordItem.Product2.ProductCode,ServiceMap);
                }
                System.debug('------MAPGEN---'+MapGen);
                
                //Se obtiene el mapa de los productos que se deben agrupar
        		for (vlocity_cmt__FulfilmentRequestLineDecompRelationship__c  relation : ordItem.vlocity_cmt__DestinationDecompositionRelationships__r) {
                    if(String.IsNotBlank((String)relation.vlocity_cmt__DestinationFulfilmentRequestLineId__c)){
                    	mapAgrupado.put(relation.vlocity_cmt__DestinationFulfilmentRequestLineId__c, String.IsNotBlank(ordItem.vlocity_cmt__ReliesOnItemId__c) ? ordItem.vlocity_cmt__ReliesOnItemId__c : ordItem.vlocity_cmt__RootItemId__c);
                	}
        		}
                
                //SE ARMA LISTA DE PRODUCTOS QUE TIENEN VIGENCIA
                if(mapAttribVigencia.containsKey(ordItem.Product2Id)){
                    if(ordItem.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.getValue('S_ADD')){
                        mapProductosConVigencia.put(ordItem.Product2.ProductCode, mapAttribVigencia.get(ordItem.Product2Id));
                    }else if(ordItem.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY')){
                        mapProductosConVigencia.put(ordItem.Product2.ProductCode, ordItem.OM_ActiveEndDate__c);
                    }
                }
            }
            
            List<vlocity_cmt__Subscription__c> lstSubscription = [
                SELECT Id, OM_MSISDN_Temporary__c
                FROM vlocity_cmt__Subscription__c
                WHERE Id = :orderItemInstance.vlocity_cmt__SubscriptionId__c WITH SECURITY_ENFORCED
            ];

            subscription = lstSubscription.isEmpty() ? null : lstSubscription[0];
            
            topOrderType = OM_AccountDetailsHelper.orderTypeAssigment(orderItemInstance.vlocity_cmt__SubAction__c); // HDU 362385: Se agrega nuevo metodo para almacenar el OrderType dependiendo las subactions de los OIs
        	interSetmdt = OM_MetadataUtility.getInterfaceSettingsReasonTop(Type, SubType);
        }
        
        if(orderInstance.AccountId <> null){
            orderAccount = [SELECT Id, vlocity_cmt__PersonContactId__c, vlocity_cmt__PersonContactId__r.FirstName,
                                vlocity_cmt__PersonContactId__r.MiddleName, vlocity_cmt__PersonContactId__r.LastName, 
                                FVU_DocumentType__c, FVU_DocumentNumber__c, Phone, OM_BSCSID__c, FVU_Email__c, vlocity_cmt__PrimaryContactId__c
                                FROM Account WHERE Id =: orderInstance.AccountId WITH SECURITY_ENFORCED LIMIT 1
                               ];
            
            if(orderAccount.vlocity_cmt__PrimaryContactId__c <> null){
                orderPrimaryContact = [SELECT Id, FirstName, MiddleName, LastName 
                                       FROM Contact WHERE Id =: orderAccount.vlocity_cmt__PrimaryContactId__c WITH SECURITY_ENFORCED LIMIT 1];
            }
        }
        
		if(orderInstance.vlocity_cmt__DefaultServiceAccountId__c <> null){        
        	orderServiceAccount = [SELECT Id, FVU_ServiceState__c, FVU_ServiceShortAddress__c, FVU_ServiceMunicipality__c, FVU_ServiceDaneCode__c, 
                                   FVU_SerciveMerId__c, FVU_ServiceExtract__c   
                                FROM Account WHERE Id =: orderInstance.vlocity_cmt__DefaultServiceAccountId__c WITH SECURITY_ENFORCED LIMIT 1
                               ];
        }
        
        if(orderInstance.vlocity_cmt__DefaultBillingAccountId__c <> null){
            orderBillingAccount = [SELECT Id, OM_BSCSID__c, OM_BSCSIntID__c, vlocity_cmt__BillCycle__c, FVU_AccountExternalID__c        // HDU 739902 - Mapeo de external ID se cambio desde Service Account hacia Billing Account
                                    FROM Account WHERE Id =: orderInstance.vlocity_cmt__DefaultBillingAccountId__c WITH SECURITY_ENFORCED LIMIT 1
                                   ];
            
            if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
                String caseInfo = (String)orderInstance.PVU_CaseInfo__c;
                if(String.IsNotBlank(caseInfo) && caseInfo.contains('cedenteBillingAccount') ){
                    Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped(caseInfo);                      
                    Account billingAccountCesion = [SELECT Id, OM_BSCSID__c, OM_BSCSIntID__c, vlocity_cmt__BillCycle__c, FVU_AccountExternalID__c
                                                    FROM Account
                                                    WHERE Id = :(String)mapCaseInfo.get('cedenteBillingAccount') WITH SECURITY_ENFORCED];
                    ipInput.put('billingAccountCesion', billingAccountCesion);
                }
            }
        }
        
        instEricsonReq.relatedParties = new List<EricsonRequestJSON.cls_relatedParties>();
        instEricsonReq.relatedEntities = new List<EricsonRequestJSON.cls_relatedEntities>();

        Map<String,Object> mapParamsParties = new Map<String,Object>();
        mapParamsParties.put('orderBillingAccount',orderBillingAccount);
        mapParamsParties.put('orderAccount',orderAccount);
        mapParamsParties.put('orderPrimaryContact',orderPrimaryContact);
        mapParamsParties.put('orderItemInstance',orderItemInstance);
        mapParamsParties.put('refeByRoleRelatedEntities',refeByRoleRelatedEntities);
        mapParamsParties.put('relatedParties', instEricsonReq.relatedParties);

        Map<String,Object> mapParamsEntities = new Map<String,Object>();
        mapParamsEntities.put('relatedEntitiesEntities', relatedEntitiesEntities);
        mapParamsEntities.put('orderServiceAccount',orderServiceAccount);
        mapParamsEntities.put('orderBillingAccount',orderBillingAccount);
        mapParamsEntities.put('relatedEntities', instEricsonReq.relatedEntities);
        mapParamsEntities.put('orderItemInstance',orderItemInstance);

        /**********************************************************
			Value Assignment of top level nodes in JSON - BEGIN
		**********************************************************/
        OM_AccountDetailsHelper.topRelatedParties(mapParamsParties);
        instEricsonReq.orderType = topOrderType;//ProductOfferingOrder
        instEricsonReq.createdDate = ordCreateDate;  //Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        instEricsonReq.description = OrderIntegrationSystemInterfaceConstants.ORDSF+(orderInstance.OrderNumber);
        // --- 522147	[Evolutivo] Establecer la hora de ejecución para SOM ---
        if (orderInstance.OM_RequestedStartDateSOM__c != null) {
            instEricsonReq.requestedStartDate = orderInstance.OM_RequestedStartDateSOM__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        } else {
            instEricsonReq.requestedStartDate = null;
        }
        // ---------------------------------------------
        instEricsonReq.orderSpecification = null; // mostly to be added to custom setting, discuss
        instEricsonReq.correlationID = null;
        instEricsonReq.run = true;
        OM_AccountDetailsHelper.topRelatedEntity(mapParamsEntities);
        instEricsonReq.version = 0;
        /**********************************************************
			Value Assignment of Order Items Node based on FRL - BEGIN
		**********************************************************/
        lstParents.add(OM_AccountDetailsHelper.searchCommunityByParent(MSISDN));
        
        ipInput.put('inputParamsDR',inputParamsDR);
        ipInput.put('url',url);
        ipInput.put('path',path);
        ipInput.put('lstParents',lstParents);
        ipInput.put('orderServiceAccount',orderServiceAccount);
        ipInput.put('orderBillingAccount',orderBillingAccount);
        ipInput.put('orderInstance',orderInstance);
        ipInput.put('Status',orderItemInstance.OM_Status__c);
        ipInput.put('orderItemEstaPagado',orderItemEstaPagado);
        ipInput.put('subscription',subscription);
        ipInput.put('topOrderType',topOrderType);
        ipInput.put('mapAgrupado',mapAgrupado);
        ipInput.put('ordCreateDate',ordCreateDate);
        ipInput.put('MapGen',MapGen);
        ipInput.put('mapAttNamesAndCodes',OM_AccountDetailsHelper.getAttributeCodeNameMap());
        ipInput.put('mapProductosConVigencia', mapProductosConVigencia);
        ipInput.put('fechaCreacion', fechaCreacion);
        instEricsonReq.orderItems = OrderIntegrationOrderItems.setAllOrderItems(ipInput, objProdWithoutAction);
        if(instEricsonReq.orderItems == null){
            return '';
        }
        if(SubType == OrderIntegrationSystemInterfaceConstants.getValue('ORD_TYPE_ACTIVATION') || 
           SubType == OrderIntegrationSystemInterfaceConstants.getValue('ORD_SUBTYPE_ADICION_ADICIONALES') ||
           SubType == OrderIntegrationSystemInterfaceConstants.getValue('ORD_SUBTYPE_ACT_SERV_PAQ')){
            List<OrderItem> lstOrderItemToUpdate = new List<OrderItem>();
            for(OrderItem objOI: lstOrderItems){
                if(mapProductosConVigencia.containsKey(objOI.Product2.ProductCode)){
                    OrderItem oi = new OrderItem();
                    oi = objOI;
                    oi.OM_ActiveEndDate__c = (Datetime)mapProductosConVigencia.get(objOI.Product2.ProductCode);
                    lstOrderItemToUpdate.add(oi);
                }
            }
            if(!lstOrderItemToUpdate.isEmpty()){
                UPDATE lstOrderItemToUpdate;
            }
        }
        
        OM_AccountDetailsHelper.searchCommunityByChildren(MSISDN, lstParents);
        instEricsonReq.FaF = lstParents;
        /**********************************************************
			Value Assignment of Order Items Node based on FRL - END
		**********************************************************/
        
        System.debug('=======instEricsonReq.orderItems======'+instEricsonReq.orderItems);
        
        /**********************************************************
			HDU-340689 Para ordenes de portabilidad se agregan 31 dias adicionales
            HDU-504835: Se requiere que la fecha de expiración de una orden de portabilidad sea de 45 días de lo contrario debe ser 8 días
		**********************************************************/

        Integer completionDays;

        if(topOrderType == OrderIntegrationSystemInterfaceConstants.PORT_IN_ORDER || topOrderType == OrderIntegrationSystemInterfaceConstants.PORT_OUT_ORDER){
            completionDays = Integer.valueOf(OrderIntegrationSystemInterfaceConstants.getValue(topOrderType));
        }else{
            completionDays = OrderIntegrationSystemInterfaceConstants.DEFAULTCOMPLETION;
        }
        instEricsonReq.requestedCompletionDate = Datetime.now().addDays(completionDays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        EricsonRequestJSON.cls_orderSpec instOrderSpec = new EricsonRequestJSON.cls_orderSpec();
        instOrderSpec.name = OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.get('cls_orderSpec').get('name');
        instOrderSpec.characteristics = new List<EricsonRequestJSON.cls_characteristics>();
        System.debug('====instOrderSpec.name======'+instOrderSpec.name);
        for(String strChar : OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.get('cls_orderSpec.characteristics').keySet()){
            System.debug('=======strChar===1===='+strChar);
            System.debug('=====strChar====2====='+OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.get('cls_orderSpec.characteristics'));
            System.debug('=====strChar====3====='+OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.get('cls_orderSpec.characteristics').get(strChar));
            instOrderSpec.characteristics.add(new EricsonRequestJSON.cls_characteristics(strChar, OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction.get('cls_orderSpec.characteristics').get(strChar)));
        }
        instEricsonReq.orderSpec = instOrderSpec;

        Map<String,Object> mapParams  = new Map<String,Object>();
        mapParams.put('Type',Type);
        mapParams.put('mapAttr', OrderIntegrationSystemInterfaceUtility.defaultValueByClassNameWoAction);
        mapParams.put('SubType',SubType);
        mapParams.put('Origin',Origin);
        mapParams.put('SuspensionLevel',SuspensionLevel);
        mapParams.put('orderBillingAccount',orderBillingAccount);
        mapParams.put('orderInstance',orderInstance);
        mapParams.put('orderItemInstance',orderItemInstance);
        mapParams.put('interSetmdt',interSetmdt);
        mapParams.put('Channel',Channel);
        mapParams.put('Person',Person);
        mapParams.put('inputParamsDR',inputParamsDR);
        
        instEricsonReq.attrs = OM_AccountDetailsHelper.topAttributes(mapParams);//Set Top Attributes
        
        /**********************************************************
			Value Assignment of top level nodes in JSON - END
		**********************************************************/
        
        OM_UpdateValuesAdminCharge om_updateValuesAdminCharge = new OM_UpdateValuesAdminCharge();
		Map<String, Object> jsoninstEricsonReq = om_updateValuesAdminCharge.updateValuesAdminCharge(JSON.serialize(instEricsonReq, true));
        System.debug('======JSON===='+JSON.serializePretty(jsoninstEricsonReq, true));
        return JSON.serializePretty(jsoninstEricsonReq, true);
        
    }
}