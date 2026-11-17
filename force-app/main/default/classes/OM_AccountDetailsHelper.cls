/*-------------------------------------------------------------------------------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    Esta clase se utilizara para agregar todos los metodos y funciones necesarios para soportar la clase OrderIntegrationAccountDetails
Code Coverage:  92%
History
<Date>       <Version>     	<Author> 				<Description>          											         
2025-04-02     1.0         Hever Salas    	    HDU-522166: PV - [CESION]  Crear Orden SOM
2025-05-08     1.1         Hever Salas    	    HDU-520180: [CANALES] Envio informacion al recibir ordenes de canales
2025-05-26     1.2         Hever Salas    	    HDU-561645: [CAMBIOS] Creación de ordenes de servicio (SOM Ericsson)  CONCICLIACION  BSCS-OM RED
2025-09-16     2.0         Hever Salas    	    BUG-663090: Cuando genero un plan de orquestación correspondiente a Conciliación de red entonces no se está enviando en el JSON el OrderType ni el Tipo Split
2025-09-25     2.1         Hever Salas    	    HDU-627710: [CANALES] Identificacion del sistema y usuario origen de creación de la orden
2025-09-23     2.2         Luis Mendoza    	    Cambios para evitar vulneravilidades
2025-12-15     2.3         Hever Salas    	    HDU-691571: [EVOLUTIVOS OM]Modificación atributos de info Activación y conciliación de paq adicionales
2026-02-24     2.3         Hllanos   	        HDU:346607 Reconexion temp voluntaria
---------------------------------------------------------------------------------------------------------------------------------------------------*/
global with sharing class OM_AccountDetailsHelper{
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agrega el atributo TRANSACTION y ademas se agrega otra party con los valores de la cuenta cesionaria
    IN:			    orderBillingAccount Instancia de la cuenta facturacion 
                    orderAccount Instancia de la cuenta cliente
                    orderPrimaryContact Instancia del contacto asociado a la cuenta cliente
                    orderItemInstance Orderitem raiz de la orden
                    refeByRoleRelatedEntities mapa que contiene la estructura del party
                    relatedEntities contiene la lista de los parties que se van a generar
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static void topRelatedEntity(Map<String,Object> mapParams){
        Map<String, String> relatedEntitiesEntities = (Map<String, String>)mapParams.get('relatedEntitiesEntities');
        Account orderServiceAccount = (Account)mapParams.get('orderServiceAccount');
        Account orderBillingAccount = (Account)mapParams.get('orderBillingAccount');
        OrderItem orderItemInstance = (OrderItem)mapParams.get('orderItemInstance');
        List<EricsonRequestJSON.cls_relatedEntities> relatedEntities = (List<EricsonRequestJSON.cls_relatedEntities>)mapParams.get('relatedEntities');
        
        EricsonRequestJSON.cls_entity instRelatedEntityEntity = new EricsonRequestJSON.cls_entity(OrderIntegrationSystemInterfaceConstants.S_PLACE);
        EricsonRequestJSON.cls_locationInformation instRelatedEntityLocation = new EricsonRequestJSON.cls_locationInformation();
        List<EricsonRequestJSON.cls_attributes> instRelatedEntityAttributeList = new List<EricsonRequestJSON.cls_attributes>();
        
        for(String str : relatedEntitiesEntities.keySet()){
            if(orderServiceAccount <> null && String.isNotBlank((String)orderServiceAccount.get(relatedEntitiesEntities.get(str)))){
                Boolean isCityCode = ((String)orderServiceAccount.get(relatedEntitiesEntities.get(str))).equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.CITY_CODE);
                String attrValueStr = (!isCityCode)? (String)orderServiceAccount.get(relatedEntitiesEntities.get(str)) : ((String)orderServiceAccount.get(relatedEntitiesEntities.get(str))).substring(0, 6);
            	instRelatedEntityAttributeList.add(new EricsonRequestJSON.cls_attributes(str, attrValueStr)); 
            }
        }
        instRelatedEntityAttributeList.add(new EricsonRequestJSON.cls_attributes('ESTRATO', string.valueof(orderServiceAccount.get(OrderIntegrationSystemInterfaceConstants.FVU_SERVICE_EXTRACT))));
        if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
            instRelatedEntityAttributeList.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_TARGET));
        }
        instRelatedEntityLocation.attributes = instRelatedEntityAttributeList;
        instRelatedEntityEntity.locationInformation = instRelatedEntityLocation;
        if(orderServiceAccount <> null && orderBillingAccount <> null){
            relatedEntities.add(new EricsonRequestJSON.cls_relatedEntities(OrderIntegrationSystemInterfaceConstants.S_PLACE, OrderIntegrationSystemInterfaceConstants.S_ZERO, orderServiceAccount.FVU_SerciveMerId__c, instRelatedEntityEntity, null));  //. ---- Ashish changed 'null' to null
            if(orderItemInstance.vlocity_cmt__SubAction__c != OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
                relatedEntities.add(new EricsonRequestJSON.cls_relatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, OrderIntegrationSystemInterfaceConstants.S_ONE, (String)orderBillingAccount.OM_BSCSIntID__c, null, (String)orderBillingAccount.OM_BSCSIntID__c));    // --- Ashish changed OM_BSCSID__c to OM_BSCSIntID__c
            }else{
                EricsonRequestJSON.cls_entity instRelatedCustomer = new EricsonRequestJSON.cls_entity(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT);
                List<EricsonRequestJSON.cls_attributes> AttributeListCustomer = new List<EricsonRequestJSON.cls_attributes>();
                EricsonRequestJSON.cls_CustomerAccountInformation customerAccountInformation = new EricsonRequestJSON.cls_CustomerAccountInformation();
                AttributeListCustomer.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_TARGET));
                customerAccountInformation.attributes = AttributeListCustomer;
                instRelatedCustomer.customerAccountInformation = customerAccountInformation;
                relatedEntities.add(new EricsonRequestJSON.cls_relatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, OrderIntegrationSystemInterfaceConstants.S_ONE, (String)orderBillingAccount.OM_BSCSIntID__c, instRelatedCustomer, (String)orderBillingAccount.OM_BSCSIntID__c));
            }
        }

        if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){

            String caseInfo = [SELECT Id, Order.PVU_CaseInfo__c
                                FROM OrderItem
                                WHERE Id = :orderItemInstance.Id WITH SECURITY_ENFORCED].Order.PVU_CaseInfo__c;
            
            if(String.IsNotBlank(caseInfo) && caseInfo.contains('cedenteServiceAccount') && caseInfo.contains('cedenteCustomerAccount')){
                
                Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped(caseInfo);
                
                Account ServiceAccountCesion = [SELECT Id, FVU_ServiceState__c, FVU_ServiceShortAddress__c, FVU_ServiceMunicipality__c, 
                                                        FVU_ServiceDaneCode__c, FVU_SerciveMerId__c, FVU_ServiceExtract__c 
                                                FROM Account
                                                WHERE Id = :(String)mapCaseInfo.get('cedenteServiceAccount') WITH SECURITY_ENFORCED];
                                                
                Account billingAccountCesion = [SELECT Id, OM_BSCSID__c, OM_BSCSIntID__c, vlocity_cmt__BillCycle__c, FVU_AccountExternalID__c
                                                FROM Account
                                                WHERE Id = :(String)mapCaseInfo.get('cedenteBillingAccount') WITH SECURITY_ENFORCED];
                
                Account customerAccountCesion = [SELECT Id, vlocity_cmt__PrimaryContactId__c
                                                FROM Account
                                                WHERE Id = :(String)mapCaseInfo.get('cedenteCustomerAccount') WITH SECURITY_ENFORCED];

                Contact primaryContactCesion = [SELECT Id, FirstName, MiddleName, LastName
                                                FROM Contact
                                                WHERE Id = :customerAccountCesion.vlocity_cmt__PrimaryContactId__c WITH SECURITY_ENFORCED];

                EricsonRequestJSON.cls_entity instRelatedEntityEntityCesion = new EricsonRequestJSON.cls_entity(OrderIntegrationSystemInterfaceConstants.S_PLACE);
                EricsonRequestJSON.cls_locationInformation instRelatedEntityLocationCesion = new EricsonRequestJSON.cls_locationInformation();
                List<EricsonRequestJSON.cls_attributes> instRelatedEntityAttributeListCesion = new List<EricsonRequestJSON.cls_attributes>();
                
                for(String str : relatedEntitiesEntities.keySet()){
                    if(ServiceAccountCesion <> null && String.isNotBlank((String)ServiceAccountCesion.get(relatedEntitiesEntities.get(str)))){
                        Boolean isCityCode = ((String)ServiceAccountCesion.get(relatedEntitiesEntities.get(str))).equalsIgnoreCase(OrderIntegrationSystemInterfaceConstants.CITY_CODE);
                        String attrValueStr = (!isCityCode)? (String)ServiceAccountCesion.get(relatedEntitiesEntities.get(str)) : ((String)ServiceAccountCesion.get(relatedEntitiesEntities.get(str))).substring(0, 6);
                        instRelatedEntityAttributeListCesion.add(new EricsonRequestJSON.cls_attributes(str, attrValueStr)); 
                    }
                }
                instRelatedEntityAttributeListCesion.add(new EricsonRequestJSON.cls_attributes('ESTRATO', string.valueof(ServiceAccountCesion.get(OrderIntegrationSystemInterfaceConstants.FVU_SERVICE_EXTRACT))));
                instRelatedEntityAttributeListCesion.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_SOURCE));
                instRelatedEntityLocationCesion.attributes = instRelatedEntityAttributeListCesion;
                instRelatedEntityEntityCesion.locationInformation = instRelatedEntityLocationCesion;
                if(ServiceAccountCesion <> null && billingAccountCesion <> null){
                    relatedEntities.add(new EricsonRequestJSON.cls_relatedEntities(OrderIntegrationSystemInterfaceConstants.S_PLACE, OrderIntegrationSystemInterfaceConstants.S_TWO, ServiceAccountCesion.FVU_SerciveMerId__c, instRelatedEntityEntityCesion, null));  //. ---- Ashish changed 'null' to null
                    EricsonRequestJSON.cls_entity instRelatedCustomerCesion = new EricsonRequestJSON.cls_entity(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT);
                    List<EricsonRequestJSON.cls_attributes> AttributeListCustomerCesion = new List<EricsonRequestJSON.cls_attributes>();
                    EricsonRequestJSON.cls_CustomerAccountInformation customerAccountInformationCesion = new EricsonRequestJSON.cls_CustomerAccountInformation();
                    AttributeListCustomerCesion.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_SOURCE));
                    customerAccountInformationCesion.attributes = AttributeListCustomerCesion;
                    instRelatedCustomerCesion.customerAccountInformation = customerAccountInformationCesion;
                    relatedEntities.add(new EricsonRequestJSON.cls_relatedEntities(OrderIntegrationSystemInterfaceConstants.CUSTOMER_ACCOUNT, OrderIntegrationSystemInterfaceConstants.S_THREE, (String)billingAccountCesion.OM_BSCSIntID__c, instRelatedCustomerCesion, (String)billingAccountCesion.OM_BSCSIntID__c));
                }
            }
        }
    }
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregar el atributo TRANSACTION y ademas se agrega otra party con los valores de la cuenta cesionaria
    IN:			    orderBillingAccount Instancia de la cuenta facturacion 
                    orderAccount Instancia de la cuenta cliente
                    orderPrimaryContact Instancia del contacto asociado a la cuenta cliente
                    orderItemInstance Orderitem raiz de la orden
                    refeByRoleRelatedEntities mapa que contiene la estructura del party
                    relatedParties contiene la lista de los parties que se van a generar
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static void topRelatedParties(Map<String,Object> mapParams){
        
        Account orderBillingAccount = (Account)mapParams.get('orderBillingAccount');
        Account orderAccount = (Account)mapParams.get('orderAccount');
        Contact orderPrimaryContact = (Contact)mapParams.get('orderPrimaryContact');
        OrderItem orderItemInstance = (OrderItem)mapParams.get('orderItemInstance');
        Map<String, Map<String, String>> refeByRoleRelatedEntities = (Map<String, Map<String, String>>)mapParams.get('refeByRoleRelatedEntities');
        List<EricsonRequestJSON.cls_relatedParties> relatedParties = (List<EricsonRequestJSON.cls_relatedParties>)mapParams.get('relatedParties');
        
    	EricsonRequestJSON.cls_relatedParties instRelatedParties = new EricsonRequestJSON.cls_relatedParties();
        instRelatedParties.reference = (orderBillingAccount <> null && String.isNotBlank(orderBillingAccount.FVU_AccountExternalID__c) ) ? orderBillingAccount.FVU_AccountExternalID__c : null;//replace with default service account FVU_AccountExternalId
        instRelatedParties.role = OrderIntegrationSystemInterfaceConstants.S_CUSTOMER;
        EricsonRequestJSON.cls_CustomerInformation relatedPartycustomInfoInstance = new EricsonRequestJSON.cls_CustomerInformation();
        relatedPartycustomInfoInstance.attributes = new List<EricsonRequestJSON.cls_attributes>();
        String tipoCodingoStr = (String.isNotBlank((String)orderAccount.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE)) && 
                                 OrderIntegrationSystemInterfaceUtility.tipoByCodingo.containsKey((String)orderAccount.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE))) ? 
            					(String)(OrderIntegrationSystemInterfaceUtility.tipoByCodingo.get((String)orderAccount.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE))) : '';
        for(String str : refeByRoleRelatedEntities.keySet()){
            for(String valueStr : refeByRoleRelatedEntities.get(str).keySet()){
                if(str.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.S_CONTACT) && orderPrimaryContact <> null){
                    relatedPartycustomInfoInstance.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, (String)orderPrimaryContact.get(refeByRoleRelatedEntities.get(str).get(valueStr)))); 
                }else if(str.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.S_ACCOUNT) && orderAccount <> null){
                    if(!valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.PWD_CUSTOMER) && !valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.TYPE_DOC)){
                        relatedPartycustomInfoInstance.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, String.valueOf(orderAccount.get(refeByRoleRelatedEntities.get(str).get(valueStr))))); 
                    }else if(valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.PWD_CUSTOMER)){
                        relatedPartycustomInfoInstance.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, (((String)orderAccount.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_NO))+'|'+tipoCodingoStr))); 
                    }else if(valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.TYPE_DOC)){
                        relatedPartycustomInfoInstance.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, tipoCodingoStr)); 
                    }
                } 
            }
        }

        if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
            relatedPartycustomInfoInstance.attributes.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_TARGET)); 
        }

        EricsonRequestJSON.cls_party instClsParty = new EricsonRequestJSON.cls_party();
        instClsParty.CustomerInformation = relatedPartycustomInfoInstance;
        instRelatedParties.party = instClsParty;//instEricsonReq.relatedParties
        relatedParties.add(instRelatedParties);
        
        if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){

            String caseInfo = [SELECT Id, Order.PVU_CaseInfo__c
                                FROM OrderItem
                                WHERE Id = :orderItemInstance.Id WITH SECURITY_ENFORCED].Order.PVU_CaseInfo__c;
            
            if(String.IsNotBlank(caseInfo) && caseInfo.contains('cedenteBillingAccount') && caseInfo.contains('cedenteCustomerAccount')){                   
                Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped(caseInfo);
                
                Account billingAccountCesion = [SELECT Id, FVU_AccountExternalID__c
                                                FROM Account
                                                WHERE Id = :(String)mapCaseInfo.get('cedenteBillingAccount') WITH SECURITY_ENFORCED];
                                                
                Account customerAccountCesion = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c, Phone, FVU_Email__c, vlocity_cmt__PrimaryContactId__c
                                                FROM Account
                                                WHERE Id = :(String)mapCaseInfo.get('cedenteCustomerAccount') WITH SECURITY_ENFORCED];
                
                Contact primaryContactCesion = [SELECT Id, FirstName, MiddleName, LastName
                                                FROM Contact
                                                WHERE Id = :customerAccountCesion.vlocity_cmt__PrimaryContactId__c WITH SECURITY_ENFORCED];

                EricsonRequestJSON.cls_relatedParties instRelatedPartiesCesion = new EricsonRequestJSON.cls_relatedParties();
                instRelatedPartiesCesion.reference = (billingAccountCesion <> null && String.isNotBlank(billingAccountCesion.FVU_AccountExternalID__c) ) ? billingAccountCesion.FVU_AccountExternalID__c : null;//replace with default service account FVU_AccountExternalId
                instRelatedPartiesCesion.role = OrderIntegrationSystemInterfaceConstants.S_CUSTOMER;
                EricsonRequestJSON.cls_CustomerInformation relatedPartycustomInfoInstanceCesion = new EricsonRequestJSON.cls_CustomerInformation();
                relatedPartycustomInfoInstanceCesion.attributes = new List<EricsonRequestJSON.cls_attributes>();
                String strTipoCodingo = (String.isNotBlank((String)customerAccountCesion.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE)) && 
                                            OrderIntegrationSystemInterfaceUtility.tipoByCodingo.containsKey((String)customerAccountCesion.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE))) ? 
                                        (String)(OrderIntegrationSystemInterfaceUtility.tipoByCodingo.get((String)customerAccountCesion.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_TYPE))) : '';
                for(String str : refeByRoleRelatedEntities.keySet()){
                    for(String valueStr : refeByRoleRelatedEntities.get(str).keySet()){
                        if(str.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.S_CONTACT) && primaryContactCesion <> null){
                            relatedPartycustomInfoInstanceCesion.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, (String)primaryContactCesion.get(refeByRoleRelatedEntities.get(str).get(valueStr)))); 
                        }else if(str.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.S_ACCOUNT) && customerAccountCesion <> null){
                            if(!valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.PWD_CUSTOMER) && !valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.TYPE_DOC)){
                                relatedPartycustomInfoInstanceCesion.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, String.valueOf(customerAccountCesion.get(refeByRoleRelatedEntities.get(str).get(valueStr))))); 
                            }else if(valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.PWD_CUSTOMER)){
                                relatedPartycustomInfoInstanceCesion.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, (((String)customerAccountCesion.get(OrderIntegrationSystemInterfaceConstants.FVU_DOCUMENT_NO))+'|'+strTipoCodingo))); 
                            }else if(valueStr.equalsignoreCase(OrderIntegrationSystemInterfaceConstants.TYPE_DOC)){
                                relatedPartycustomInfoInstanceCesion.attributes.add(new EricsonRequestJSON.cls_attributes(valueStr, strTipoCodingo)); 
                            }
                        } 
                    }
                }
                if(orderItemInstance.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
                    relatedPartycustomInfoInstanceCesion.attributes.add(new EricsonRequestJSON.cls_attributes(OrderIntegrationSystemInterfaceConstants.ATT_TRANSACTION, OrderIntegrationSystemInterfaceConstants.ATT_SOURCE)); 
                }
                EricsonRequestJSON.cls_party instClsPartyCesion = new EricsonRequestJSON.cls_party();
                instClsPartyCesion.CustomerInformation = relatedPartycustomInfoInstanceCesion;
                instRelatedPartiesCesion.party = instClsPartyCesion;//instEricsonReq.relatedParties
                relatedParties.add(instRelatedPartiesCesion);
            }
        }
    }

    /**
    * @description: Se toma el campo subAction del orderItem para asignarle un valor distinto dependicendo de la condicional a topOrderType 
    * @author karsanchez | 08-19-2024 
    * @param SubAction 
    * @return String 
    **/
    public static String orderTypeAssigment(String SubAction) {
        String topOrderType;
        if (SubAction == OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORT_IN || SubAction == OrderIntegrationSystemInterfaceConstants.ACTIVATION_PORTINRETOMA) {
            topOrderType = OrderIntegrationSystemInterfaceConstants.PORT_IN_ORDER;
        } else if (SubAction == OrderIntegrationSystemInterfaceConstants.REACTIVATE_CHANGESIM) {
            topOrderType = OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CHANGE;
        } else if (SubAction == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBACTION) {
            topOrderType = OrderIntegrationSystemInterfaceConstants.PORT_OUT_ORDER;
        } else if (SubAction == OrderIntegrationSystemInterfaceConstants.NEG_PORTIN_SUBACTION) {
            topOrderType = OrderIntegrationSystemInterfaceConstants.PORT_OUT_ROLLBACK;
        } else if (SubAction == OrderIntegrationSystemInterfaceConstants.REACTIVATION_PORTOUT) {
            topOrderType = OrderIntegrationSystemInterfaceConstants.PORTOUT_ORDERTYPE;
        }else if(SubAction == OrderIntegrationSystemInterfaceConstants.SUB_ACTION_CESION){
            topOrderType = OrderIntegrationSystemInterfaceConstants.TOP_ORDER_TYPE_CESION;
        }else if(SubAction == OrderIntegrationSystemInterfaceConstants.getValue('SUB_ACTION_CON_RED')
                 || SubAction == OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY') 
                 || SubAction == OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_NOCHANGE')){
            topOrderType = OrderIntegrationSystemInterfaceConstants.CON_RED_ORDERTYPE;
        } else {
            topOrderType = OrderIntegrationSystemInterfaceConstants.ORDER_TYPE;
        }
        return topOrderType;
    }
        
    /**
    * @description: Obtiene el mapa con el MSISDN como un valor Padre
    * @author Hever Salas | 12-17-2024 
    * @param MSISDN 
    * @return Map<String,Object> 
    **/
    public static Map<String,Object> searchCommunityByParent(String MSISDN) {
        Map<String,Object> result = new Map<String,Object>();
        String concat = '';
        List<PVU_Community__c> lstCommunity = [SELECT Id
                                               FROM PVU_Community__c
                                               WHERE PVU_Linea_Padre__r.OM_MSISDN__c = :MSISDN
                                               AND PVU_Estatus__c = 'Activa' WITH SECURITY_ENFORCED
                                               LIMIT 1];
        
        if(lstCommunity.size() > 0){
            List<PVU_Community_Member__c> lstCommunity_Member = [SELECT Id, PVU_Linea_Hija__c
                                                                 FROM PVU_Community_Member__c
                                                                 WHERE PVU_Comunidad__c = :lstCommunity[0].Id WITH SECURITY_ENFORCED];
            
            for(PVU_Community_Member__c item : lstCommunity_Member){
                if(String.IsNotBlank(concat)){
                    concat = concat + ',' + item.PVU_Linea_Hija__c;
                }else{
                    concat = item.PVU_Linea_Hija__c;
                } 
            }
            result.put('parent',MSISDN);
            result.put('miembro',concat);
        }
        return result;
    }
        
    /**
    * @description: Obtiene el mapa con el MSISDN como un valor hijo
    * @author Hever Salas | 12-17-2024 
    * @param MSISDN 
    * @return Map<String,Object> 
    **/
    public static void searchCommunityByChildren(String MSISDN, List<Object> lstParents) {

        List<PVU_Community_Member__c> lstCommunity_Member = [SELECT Id, PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c
                                                                 FROM PVU_Community_Member__c
                                                                 WHERE PVU_Linea_Hija__c = :MSISDN WITH SECURITY_ENFORCED];
        
        if(lstCommunity_Member.size() > 0){
            for(PVU_Community_Member__c item :lstCommunity_Member){
                lstParents.add((Object)searchCommunityByParent(item.PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c));
            }
        }        
    }  
    /**
    * @description: Devuelve un mapa con Code__c como clave y Name como valor para los atributos de la categoría 'B2C-ATTRCAT-SVC-ADC-DETAILS' 
    * @author karsanchez| 03-31-2025 
    * @return Map<String, String> Mapa con Code__c como clave y Name como valor
    **/
    public static Map<String, String> getAttributeCodeNameMap() {
        Map<String, String> mapaCodigoNombre = new Map<String, String>();
        List<String> categoryCodes = new List<String>();
        List<OM_AttributeCode__mdt> lstAttsCodesMD = [SELECT OM_CategoryCode__c FROM OM_AttributeCode__mdt WITH SECURITY_ENFORCED];
        for (OM_AttributeCode__mdt config : lstAttsCodesMD) {
            categoryCodes.add(config.OM_CategoryCode__c);
        }
        List<vlocity_cmt__Attribute__c> atributos = [
            SELECT Id, vlocity_cmt__Code__c, Name 
            FROM vlocity_cmt__Attribute__c 
            WHERE vlocity_cmt__AttributeCategoryCode__c IN :categoryCodes WITH SECURITY_ENFORCED
        ];
        
        for(vlocity_cmt__Attribute__c attr : atributos) {
            if(attr.vlocity_cmt__Code__c != null) {
                mapaCodigoNombre.put(attr.vlocity_cmt__Code__c, attr.Name);
            }
        }
        System.debug('Mapa código-nombre: ' + mapaCodigoNombre);
        return mapaCodigoNombre;
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregan los atributos que van en el top del json hacia Ericsson
    IN:			    Type tipo de la orden
                    SubType sub tipo de la orden
                    Person Federation Identifier del usuario
                    Channel Business Channel del usuario
                    Origin Original Channel del usuario
                    SuspensionLevel Nivel de suspension configurado en la orden
                    orderBillingAccount Instancia de la cuenta facturacion 
                    orderInstance Instancia de la orden
                    orderItemInstance Orderitem raiz de la orden
                    interSetmdt Metadata que contiene los motivos
                    mapAttr mapa que contiene todos los atributos obtenidos de la metadata OMEricsonMapping__mdt
    OUT:            List<EricsonRequestJSON.cls_attributes> Lista de atributos generada
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static List<EricsonRequestJSON.cls_attributes> topAttributes(Map<String,Object> mapParams){
        
        List<EricsonRequestJSON.cls_attributes> lstAtt = new List<EricsonRequestJSON.cls_attributes>();
        String Type = (String)mapParams.get('Type');
        String Person = (String)mapParams.get('Person');
        String Channel = (String)mapParams.get('Channel');
        String SubType = (String)mapParams.get('SubType');
        String Origin = (String)mapParams.get('Origin');
        String SuspensionLevel = (String)mapParams.get('SuspensionLevel');
        Account orderBillingAccount = (Account)mapParams.get('orderBillingAccount');
        Order orderInstance = (Order)mapParams.get('orderInstance');
        OrderItem orderItemInstance = (OrderItem)mapParams.get('orderItemInstance');
        InterfaceSettings__mdt interSetmdt = (InterfaceSettings__mdt)mapParams.get('interSetmdt');
        Map<String, Map<String, String>> mapAttr = (Map<String, Map<String, String>>)mapParams.get('mapAttr');
        Map<String, Object> inputParamsDR = (Map<String, Object>)mapParams.get('inputParamsDR');
            
        for(String str : mapAttr.get('cls_attributes').keySet()){
            if(str.equalsIgnoreCase('Origin')) {
                if((((Type == 'Suspension' || Type == 'Cancelacion') && (SubType == 'Fraude_GPT' || SubType == 'Cartera')) || (Type == 'Reconexion' && SubType == 'Cartera'))&& String.isNotBlank(Origin)){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, Origin));
                }
            }else if(str.equalsIgnoreCase('BackendAction')){
                if(Type == 'Suspension' && SubType == 'Cartera' && Origin == 'COLLECTIONS'){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'SUSPENSION'));
                }else if(Type == 'Reconexion' && SubType == 'Cartera' && Origin == 'COLLECTIONS'){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'REACTIVATION'));
                }else if(Type == 'Cancelacion' && SubType == 'Cartera' && Origin == 'COLLECTIONS'){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'DEACTIVATION'));
                }
            }else if(str.equalsIgnoreCase('SuspensionLevel')){
                if((Type == 'Suspension' || Type == 'Cancelacion') &&  SubType == 'Cartera'){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, SuspensionLevel));
                }
            }else if(str.equalsIgnoreCase('billCycleId')){
                lstAtt.add(new EricsonRequestJSON.cls_attributes(str, (String)orderBillingAccount.get(mapAttr.get('cls_attributes').get(str))));
            }else if(str.equalsIgnoreCase('externalId')){
                lstAtt.add(new EricsonRequestJSON.cls_attributes(str, (String)orderInstance.get(mapAttr.get('cls_attributes').get(str))));
            }else if(str.equalsIgnoreCase('Reason')){
                lstAtt.add(new EricsonRequestJSON.cls_attributes(str, (interSetmdt!=null && String.IsNotBlank(interSetmdt.OM_Reason__c))? interSetmdt.OM_Reason__c : ''));
            }else if(str.equalsIgnoreCase('TipoFlujo')){
                if(Boolean.valueOf(inputParamsDR.get('IsNotEOC')) == true){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, mapAttr.get('cls_attributes').get(str)));
                }
            }else if(str.equalsIgnoreCase('Channel') ){
                if((Type == 'Suspension' || Type == 'Cancelacion' || Type == 'Reconexion') && SubType == 'Cartera'){
                    if(Origin.equalsIgnoreCase('COLLECTIONS')){
                        lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'ix'));
                    }else{
                        lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'Integracion'));
                    }
                }else if (String.isNotBlank(Person)) {
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, Channel));
                }else {
                    if(String.IsNotBlank(Origin)){
                        lstAtt.add(new EricsonRequestJSON.cls_attributes(str, Origin));
                    }else{
                        lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'Integracion'));
                    }
                }
            }else if(str.equalsIgnoreCase('salesPerson')){
                if(String.isNotBlank(Person)){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, Person));
                }else{       
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, 'Default'));     
                }
            }else if(str.equalsIgnoreCase('CodDealer')){
                if(String.isNotBlank(orderInstance.CreatedBy.FVU_CodigoD__c) && orderInstance.CreatedBy.FVU_CodigoD__c != OrderIntegrationSystemInterfaceConstants.ATT_DEFAULT_CODDEALER){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, orderInstance.CreatedBy.FVU_CodigoD__c));
                }
            }else if(str.equalsIgnoreCase('Scope')){
                if(SubType == 'Conciliacion_red'){
                    lstAtt.add(new EricsonRequestJSON.cls_attributes(str, OrderIntegrationSystemInterfaceConstants.VALUE_LINEA));
                }
            }else{
                lstAtt.add(new EricsonRequestJSON.cls_attributes(str, mapAttr.get('cls_attributes').get(str))); 
            }
        }
        return lstAtt;
    }
    
    
    /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    Author:		    Hever Salas
    Company:	    Salesforce.com
    Description:   	Se agregan a un mapa los atributos que tienen vigencia y como clave se utiliza el Product2Id
    IN:			    lstAttributeAssignment Lista de Atributos que tienen vigencia
	OUT:            Map<String,String> que contiene {<Product2Id, 30 Días>}
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/ 
    public static Map<String,String> obtAtributosConVigencia(){
        Map<String,String> response = new Map<String,String>();
        List<vlocity_cmt__AttributeAssignment__c> lstAttributeAssignment = [SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__Value__c
                                                                            FROM vlocity_cmt__AttributeAssignment__c
                                                                            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c in (:OrderIntegrationSystemInterfaceConstants.getValue('ATTR_PAQ_DIAS_VIGENCIA'),:OrderIntegrationSystemInterfaceConstants.getValue('ATTR_PAQ_VIGENCIA'))
                                                                            AND vlocity_cmt__Value__c != '' WITH SECURITY_ENFORCED];
        if(lstAttributeAssignment != null && !lstAttributeAssignment.isEmpty()){
            for(vlocity_cmt__AttributeAssignment__c item: lstAttributeAssignment){
                response.put(item.vlocity_cmt__ObjectId__c, item.vlocity_cmt__Value__c);
            }
        }
        return response;
    }
}