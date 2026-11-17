/*--------------------------------------------------------------------------
Author:         Mamata Poomagamme Mahesh - mpoomagammemahesh@salesforce.com
Company:        Salesforce.com
Description:    Defines constants required in the different orchestration scenarios
Test Class:     OrderMgtOrderActivation_Test
Code Coverage:  100%
History
<Date>            <Version>   <Author>             <Description>             
05-Sep-23         1.0.0       Mamata Poomagamme    Initial                   
24-Apr-24         1.0.1       Gabriel Alvis        HDU 590896 - Suspension   
22-May-24         1.0.2       Gabriel Alvis        HDU 562582 - Reporting    
05-06-24          1.0.3       Hever Salas          HDU 736685 - Reactivacion 
08-07-24          1.0.4       Emmanuel Ruarte      HDU 335682 - Cambio de Plan 
22-07-24          1.0.5       Hever Salas      	   BUG-743267				 
31-07-24          1.0.6       Hever Salas      	   BUG-338157-340689 - Portout	
19-08-24          1.0.7       Karen Sanchez        HDU 362385: Portout Negación, Se agregan nuevos valores para utilizarlos en la clase OrderIntegrationAccountDetails para enviarlos a Ericsson. 
19-08-24          1.0.8       Hever Salas          HDU 366794: Negación de PortIn
26-08-24          1.0.9       Emmanuel Ruarte      HDU 398249: Promociones
19-09-24	      1.0.10	  Hever Salas		   HDU 335144 - Se Agrega el valor del Producto Tecnico Simcard (PO_SIM7012268)
20-09-24          1.0.11      Karen Sanchez        HDU 413297: Se agrega nuevo valor para usar PortIn-Retoma
20-09-24          1.0.12      Gabriel Alvis        HDU 403314: Adición de Product Characteristic para envío de número Dummy en negación de PortOut
24-09-24		  1.0.13	  Hever Salas		   HDU 407460: Se envian los parametros PerfilCAN y NoCanUsage
27-09-24		  1.0.14	  Hever Salas		   HDU-407460: Se agrega nuevo valor para usar Action Change
08-10-24          1.0.15      Emmanuel Ruarte      HDU-433747: Cambio de número
11-10-24		  1.0.16	  Hever Salas		   HDU-441151: Ajuste Campo Network
24-10-24		  1.0.17	  Hever Salas		   HDU-434093: Actualizar las POP donde se deben enviar los precios sin impuesto
28-10-24          1.0.18      Emmanuel Ruarte      HDU-479623: Reinstalación
04-11-24		  1.0.19	  Hever Salas		   HDU-409739: Agrupacion Ofertas
27-11-24          1.0.20      Emmanuel Ruarte      HDU-494773: Generación de una orden SOM para permitir la venta de OTT
11-12-24          1.0.21      Karen Sanchez        HDU-504835: Se crean dos nuevos métodos para invocar un CM para hacer que los parametros constantes puedan ser modificados desde la configuración (getValues)
16-12-24          1.0.22      Hever Salas          HDU-417695: Creacion orden SOM de familia y amigos
22-01-25          1.0.23      Hever Salas          BUG-538070: Cambio de plan producto adicional
06-02-25          1.0.24      Emmanuel Ruarte      HDU-542154: Activaciones acciones no definidas
05-03-25          1.0.25      Hever Salas      	   HDU-547949: Activaciones acciones no definidas en cancelaciones
06-03-25          1.0.26      Hever Salas      	   HDU-544910: Identificacion de Items sin accion
13-03-25		  1.0.27      Karen Sanchez		   BUG-564960: Se agrega ORD_SUBTYPE_CHANGESIM para contemplar el subtipo de la orden que contenga ChangeSim
31-03-25          1.0.28      Hever Salas      	   HDU-559799: [CESION] Familia y amigos generación de JSON-SOM 
02-04-25          1.0.29      Hever Salas      	   HDU-522166: PV - [CESION]  Crear Orden SOM
02-04-25          1.0.30      Hever Salas      	   BUG-574609: QA - Medium - BUG - Falta Mapeo de atributo PCcos
08-05-25          1.0.31      Hever Salas    	   HDU-520180: [CANALES] Envio informacion al recibir ordenes de canales
08-05-25          1.0.32      Karen Sanchez    	   HDU-580978: Se agregan 1 nueva constante utilizada en OM_OrderIntegrationHelper para cuando hay una PO de cancelación
26-05-25          1.0.33      Hever Salas    	   HDU-561645: [CAMBIOS] Creación de ordenes de servicio (SOM Ericsson)  CONCICLIACION  BSCS-OM RED
11-05-25          1.0.34      Hever Salas    	   BUG-620821: R5-SIT-E2 Se evidencia que al realizar una desactivación con la causal 266, Des No Aprobación DPC, el sistema genera error en el plan de orquestación relacionado con el servicio Adicional Activo
13-05-25          1.0.35      Hever Salas    	   BUG-621423: R5-SIT-E3- Al registrar un caso de cesión de contrato, no se realiza el cierre automático
----------------------------------------------------------------------------*/

public with sharing class OrderIntegrationSystemInterfaceConstants {
    // Mapa estático para almacenar los valores cargados desde el Custom Metadata
    private static final Map<String, OM_ApexConstants__mdt> metadataMap = new Map<String, OM_ApexConstants__mdt>();

    // Inicialización estática para cargar los valores al inicio
    static {
        List<OM_ApexConstants__mdt> records = [
            SELECT OM_Key__c, OM_Value__c 
            FROM OM_ApexConstants__mdt WITH SECURITY_ENFORCED
        ];
        for (OM_ApexConstants__mdt record : records) {
            metadataMap.put(record.OM_Key__c,record);
        }
    }

    public static final String ORDER_TYPE = 'ProductOfferingOrder';
    public static final String FULFILMENTID = 'FulfilmentId';
    public static final String FULFILMENTID_AND_ACTION = 'FulfilmentId,Action';
    public static final String TECH_ATTR_CATEGORY_NAME = 'TechAttributesDecompose';
    public static final String TECHNICAL_PARENT_PRODUCT = 'PO_MovPosBasico';
    public static final String TECHNICAL_SIMCARD_PRODUCT = 'PO_SIM7012268';
    public static final String SERVICES_SERVICE_TYPE = 'CustomerFacingServiceSpec';
    public static final Set<String> TECHNICAL_PRODUCT_ACTION_MODIFY = new Set<String>{'PO_MovPosFunBloq','PO_MovPosFunBloqDon','PO_MovPosFunBloqCont'};
    public static final String FRL_JSON_STR = 'FRLJSON';
    public static final String INV_JSON_STR = 'INVJSON';
    public static final String GET_DR_RESULT = 'OM_DR_GetRequestLineItemByOrchPlanId';
    public static final String GET_DR_APPLIED_PROMOTION = 'OM_DR_GetOrderAppliedPromotion';
    public static final String ITEM_ATTR_CLS = 'itemAttributes_cls';
    public static final String SERIALISED_JSON_STR = 'SerialisedJSONAttr';
    public static final String DEFAULT_STR = 'default';
    public static final String ACTION = 'Action';
    public static final String SUB_ACTION = 'SubAction';
    public static final String CODE = 'Code';
    public static final String SEG_VALUE = 'SegmentValue';
    public static final String CLS_PROD_SUB_TYPE = 'cls_productsubtype';
    public static final String CLS_ATTRIBUTE = 'cls_attributes';
    public static final String REQUEST_TARGET_ID = 'requestTargetId';
    public static final String FULFILMENT_NO = 'FulfilmentNumber';
    public static final String FRL = 'FRL';
    public static final String YY_Y = 'YY';
    public static final String MM_M = 'MM';
    public static final String CLS_ATTR_FLAG = 'cls_attributes.flag';
    public static final String CLS_ITEM_ATTR = 'cls_item.cls_attributes';
    public static final String CRM_ORDER_ID = 'CrmOrderId';
    public static final String ORDSF = 'ORDSF';
    public static final String FULFILMENT_REQUEST_LINE_ID = 'fulfilmentRequestLineId';
    public static final String ACTIVATION_PORT_IN = 'Activation-PortIn';
    public static final String PORTABILITY_PROCESS_ID = 'PortabilityProcessId';
    public static final String MODIFY = 'Modify';
    public static final String CHANGE_CFS = 'change.cfs';
    public static final String CLS_PRODUCT_OFFERING = 'cls_productOffering';
    public static final String CLS_PRODUCT_FLAG = 'cls_product.flag';
    public static final String S_PRODUCT = 'Product';
    public static final String CLS_PRODUCT = 'cls_product';
    public static final String S_ID = 'id';
    public static final String PRODUCT_ID = 'productId';
    public static final String PRODUCT_IDS = 'productIds';
    public static final String SUSPEND_DEACTIVATE = 'Suspend-Deactivate';
    public static final String ACTIVATION_ADD = 'Activation-Add';
    public static final String ACTIVATION_PORT_IN_A = 'Activation-PortInA';
    public static final String CLS_PROD_CHARAC = 'cls_productCharacteristics';
    public static final String RECURRING_CHARGE = 'vlocity_cmt__RecurringCharge__c';
    public static final String TOTAL_CARG_INFO = 'TotalCargoInformativo';
    public static final String S_PRICE = 'Price';
    public static final String CLS_PROD_PRICE_CHARAC = 'cls_productPriceCharacteristics';
    public static final String CFS_CHAR = 'cfsCharac';
    public static final String PLAN_CFM = 'PlanCFM';
    public static final String CLS_SERVICE_FLAG = 'cls_services.flag';
    public static final String S_SERVICE = 'Service';
    public static final String CLS_SERVICE_CHAR = 'cls_serviceCharacteristics';
    public static final String SERVICE_ID = 'serviceId';
    public static final String S_SERVICE_IDS = 'serviceIds';
    public static final String S_ADD = 'Add';
    public static final String CLS_RESOURCE_FLAG = 'cls_resources.flag';
    public static final String S_RESOURCE = 'Resource';
    public static final String C_RESOURCENUMBER = 'resourceNumber';                                 // V. 1.0.12
    public static final String C_NEWRESOURCENUMBER = 'newResourceNumber';                           // V. 1.0.12
    public static final String RS_LRSMOVNUMERO = 'LRS_MovNumero';                                   // V. 1.0.12
    public static final String CLS_RESOURCE_CHAR = 'cls_resourceCharacteristics';
    public static final String RESOURCE_ID = 'resourceId';
    public static final String S_RESOURCE_IDS = 'resourceIds';
    public static final String S_FAMILY = 'family';
    public static final String CONTRACT_ID = 'contractId';
    public static final String CLS_OIT_CLS_RELATED_ENTITY = 'cls_orderItem.cls_relatedEntities.cls_entity';
    public static final String CLS_ITEM = 'cls_item';
    public static final String S_CONTRACT = 'Contract';
    public static final String S_CONTRACT_ID = 'ContractId';
    public static final String S_PLACE = 'Place';
    public static final String CUSTOMER_ACCOUNT = 'CustomerAccount';
    public static final String CHILD_OF = 'ChildOf';
    public static final String DOUBLE_ZERO = '00';
    public static final String S_ZERO = '0';
    public static final String S_ONE = '1';
    public static final String ORDER_ID = 'OrderId';
    public static final String ACCOUNT_ID = 'AccountId';
    public static final String PORT_IN_ORDER = 'PortInOrder';           
    public static final String S_CUSTOMER = 'Customer';
    public static final String FVU_DOCUMENT_TYPE = 'FVU_DocumentType__c';
    public static final String S_CONTACT = 'Contact';
    public static final String S_ACCOUNT = 'Account';
    public static final String PWD_CUSTOMER = 'PASSWORD_CUSTOMER';
    public static final String TYPE_DOC = 'TYPE_DOC';
    public static final String FVU_DOCUMENT_NO = 'FVU_DocumentNumber__c';
    public static final String CITY_CODE = 'CITY_CODE';
    public static final String FVU_SERVICE_EXTRACT = 'FVU_ServiceExtract__c';
    public static final String VLOCITY_ONETIME_TOTAL = 'vlocity_cmt__EffectiveOneTimeTotal__c';
    public static final String VLOCITY_RECURRING_CHARGE = 'vlocity_cmt__RecurringCharge__c';
    public static final String S_ACTIVE = 'Active';
    public static final String S_INACTIVE = 'INACTIVE';
    public static final String S_PRO_ACT = 'PRO_ACT';
    public static final String S_SUSPENDED = 'Suspended';
    public static final String PS_IGNORE = 'DUMMY';                         // V. 1.0.1
    public static final String PR_MOBILE_NUMBER = 'B2C-MOV-MSISDN-PS';      // V. 1.0.2 
    public static final String PR_SIM_CARD = 'B2C-MOV-OFR-SIMCARD';       // V. 1.0.2
    public static final String PR_ESIM_CARD = 'B2C-MOB-OFR-ESIM';           // V. 1.0.2
    public static final String ATTR_MSISDN = 'B2C-ATTR-MSISDN';             // V. 1.0.2
    public static final String ORDER_TYPE_CHANGE = 'ChangeSuspendedResources';
    public static final String REACTIVATE_CHANGESIM = 'Resume-Reactivate-ChangeSim';
    public static final String ADMIN_CHARGE_PRODUCT = 'PO_MovPosAdChgCamSimCardG001';
    public static final String ORDER_TYPE_ADMIN_CHARGE = 'CustomerChangeOrder';
    public static final String TAXES = 'Taxes';
    public static final String PRICE = 'Price';
    public static final String ACTION_ADMIN_CHARGE = 'AddAdminCharge';
    public static final String S_NOCHANGE ='NoChange' ;                     // V. 1.0.4
    public static final String S_CHANGE = 'Change';                     
    public static final String JSON_ATTR ='JSONattrs' ;                     // V. 1.0.4
    public static final String PRODUCT_ID_SER = 'productIdSerialized';      // V. 1.0.4
    public static final String SERVICE_ID_SER = 'serviceIdSerialized';      // V. 1.0.4
    public static final String RESOURCE_ID_SER = 'resourceIdSerialized';    // V. 1.0.4
    public static final String EOC_WITHOUTEOC = 'withoutEOC';
    public static final String S_DISCONNECT = 'Disconnect';
    public static final String CHANGESERVICE_PRODUCT = 'ChangeService-Product';
    public static final String PORTABILITY_TYPE = 'Portabilidad';
    public static final String PORTABILITY_SUBTYPE = 'Portout';
    public static final String PORTABILITY_SUBACTION = 'Disconnect-PortOut';
    public static final String PORT_OUT_ORDER = 'PortOutOrder';         
    public static final String PORTABILITY_NRN = 'NRN';
    public static final String PORTABILITY_STATUS = 'portation_status';
    public static final String PORTABILITY_SUBTYPEREINST = 'PortOut-Reinstalacion'; //1.0.7
    public static final String REACTIVATION_PORTOUT = 'Resume-Reactivate-PortOut';  //1.0.7
    public static final String PORTOUT_ORDERTYPE = 'RollbackPortIn';                //1.0.7
    public static final String NEG_PORTIN_SUBACTION = 'Disconnect-Delete-PortIn'; 	// V. 1.0.8
    public static final String PORT_OUT_ROLLBACK = 'RollbackPortOut';				// V. 1.0.8
    public static final String BENEFIT_TYPE = 'TipoBeneficio';				        // V. 1.0.9
    public static final String ITEM_ADDON = 'ItemAddon';				                    // V. 1.0.9
    public static final String GIFT = 'Obsequio';				                    // V. 1.0.9
    public static final String CAT_TYPE = 'CAT_Type';                               // V. 1.0.9
    public static final String ACTIVATION_PORTINRETOMA = 'Activation-Retoma-Port'; // V. 1.0.11
    public static final String PERFIL_CAN = 'PerfilCAN';							
    public static final String NO_CAN_USAGE = 'NoCanUsage';							
    public static final String CHANGEPLAN_DELETE = 'ChangePlan-Delete';
    public static final String CHANGEMSISDN_MODIFY = 'ChangeMsisdn-Modify'; //1.0.15
    public static final String C_NEWRNR = 'newNRN';	//1.0.15
    public static final String PORTABILITY_NETWORK = 'network';						//v. 1.0.16
    public static final String VALUE_NRN = '132';									//v. 1.0.16
    public static final String VALUE_PON1 = 'PON1';									//v. 1.0.16
    public static final String REINSTALL_SUBACTION = 'Resume-Reinstall';            //v. 1.0.18
    public static final String SUSBY_COLLECTIONS = 'susByCollections';              //v. 1.0.18
    public static final String SUSBY_CUSTOMER = 'susByCustomer';                    //v. 1.0.18
    public static final String SUSBY_FRAUD = 'susByFraud';                          //v. 1.0.18
    public static final String SUSBY_LOST = 'susByLost';                            //v. 1.0.18
    public static final String SUSBY_THEFT = 'susByTheft';                          //v. 1.0.18
    public static final String SUSBY_WARRANTY = 'susByWarranty';                    //v. 1.0.18
    public static final String TECHNICAL_PLAN_PRODUCT = 'PO_MovPosPlanPostpaid';	//v. 1.0.19
    public static final String VALUE_AGRUPACION = 'agrupacion';						//v. 1.0.19
    public static final String RECURRING_CHARGE_TAXES = 'FVU_RecurringChargeIncTaxes__c'; //v. 1.0.19
    public static final String ONETIME_CHARGE = 'vlocity_cmt__OneTimeCharge__c'; 	//v. 1.0.19
    public static final String ONETIME_CHARGE_TAXES = 'FVU_OneTimeTotalIncTaxes__c';//v. 1.0.19
    public static final String VALUE_TOTAL_PRICE = 'totalPrice';					//v. 1.0.19
    public static final String PRODUCT_CODE_ESIM = 'B2C-MOB-OFR-ESIM';				//v. 1.0.19
    public static final String PRODUCT_SERV_ID = 'B2C-ATTR-SERV-ID';				//v. 1.0.20
    public static final String PRODUCT_TECH_DET = 'B2C-ATTR-TECH-DET';				//v. 1.0.20
    public static final String PRODUCT_PRC_DET = 'B2C-ATTR-PRC-DET';				//v. 1.0.20
    public static final String SERVI_ID = 'service_id';				                //v. 1.0.20
    public static final String TECHNICAL_DETAILS = 'Technical_Details';				//v. 1.0.20
    public static final String PROCESS_DETAILS = 'Process_Details';				    //v. 1.0.20
    public static final String EXCEPTIONS = 'exceptions';				            //v. 1.0.20
    public static final Integer DEFAULTCOMPLETION = Integer.valueof(getValue('DEFAULTCOMPLETION')); //v. 1.0.21
    public static final String FAF_PRODUCT = 'PO_MovPosOptFaFVozProv';				//v. 1.0.22
    public static final String VALUE_FAF_LIST_VOICE = 'FaFListVoice';				//v. 1.0.22
    public static final String CHANGEPLAN_REASSIGN = 'ChangePlan-Reassign';			//v. 1.0.23
    public static final String ORDER_TYPE_CANCELACION = 'Cancelacion';              //v. 1.0.24
    public static final String ORDER_SUBTYPE_VOLUNTARIA = 'Voluntaria';             //v. 1.0.24
    public static final String PRODUCT_CANCELACION = 'PO_MovPosAddOnCancelacion';   //v. 1.0.24
    public static final String NEG_PORTIN = 'PortIn-Cancelacion';					//v. 1.0.25
    public static final String ROLLBACK_PORTOUT = 'PortOut-Reinstalacion';			//v. 1.0.26
    public static final String ORD_TYPE_PORTIN = 'PortIn';							//v. 1.0.26
    public static final String ORD_SUBTYPE_NEG_PORTIN = 'PortIn';					//v. 1.0.26
    public static final String ORD_SUBTYPE_CHANGESIM = 'ChangeSim';					//v. 1.0.27
    public static final String TECH_ATT_PROD_DET = 'TechAttrProductDetail';			//V. 1.0.28
    public static final String VALUE_BEHAVIOR = 'behavior';						    //V. 1.0.28
    public static final String VALUE_SUB_TYPE = 'orderSubType';						//V. 1.0.28
    public static final String VALUE_DUPLICATE = 'Duplicate';						//V. 1.0.28
    public static final String SUB_ACTION_CESION = 'Cession-Transfer';			    //V. 1.0.28
    public static final String TOP_ORDER_TYPE_CESION = 'ContractTakeOver';			//V. 1.0.28
    public static final String VALUE_DELETE = 'Delete';						        //V. 1.0.28
    public static final String ATT_TRANSACTION = 'TRANSACTION';				        //V. 1.0.29
    public static final String ATT_SOURCE = 'source';				                //V. 1.0.29
    public static final String ATT_TARGET = 'target';				                //V. 1.0.29
    public static final String S_TWO = '2';				                            //V. 1.0.29
    public static final String S_THREE = '3';				                        //V. 1.0.29
    public static final String DESCRIPTION_OFFER_KEY = 'description_offer';
    public static final String PRODUCT_SUB_TYPE = 'BaseTechProduct';                //V. 1.0.29
    public static final String CHANGEPLAN_ADD = 'ChangePlan-Add';                   //V. 1.0.29
    public static final String ORDER_TYPE_CESION = 'Cesion';                        //V. 1.0.29
    public static final String FULFILMENT_PRODUCT_NAME = 'FulfilmentProductName';   //V. 1.0.29
    public static final String TARGET_ATTRIBUTE_COS = 'cos';                        //V. 1.0.30
    public static final String CHANGESERVICE_MODIFY = 'ChangeService-Modify';       //V. 1.0.30
    public static final String PRE_POST_MIGRA = 'PrePostMigra';                     //V. 1.0.30
    public static final String DECISION_MATRIX_COS = 'OM_MatrizCos';                //V. 1.0.30
    public static final String PARAM_SRVVVM = 'SRVVVM';                             //V. 1.0.30
    public static final String PARAM_BRRNLOST = 'BRRNLOST';                         //V. 1.0.30
    public static final String PARAM_BRRMARYA = 'BRRMARYA';                         //V. 1.0.30
    public static final String ATT_COS = 'TechPCcos';                               //V. 1.0.30
    public static final String ATT_DEFAULT_CODDEALER = 'NA';                        //V. 1.0.31
    public static final String KEY_FECHAFINCANC= 'fechaFinCanc';	     			//V. 1.0.32
    public static final String VALUE_LINEA = 'Linea';	     			            //V. 1.0.33
    public static final String SUB_ACTION_CON_RED = 'Concile-Line';	     			//V. 1.0.33
    public static final String CON_RED_ORDERTYPE = 'Conciliation';	     			//V. 1.0.33
    public static final String SUB_DESCRIPTION_OFFER = 'B2C-ATTR';					//V. 1.0.34
    public static final String TECHNICAL_OTT_PRODUCT = 'PO_MovPosOptOTT';			//V. 1.0.35
    
    /**
    * @description: Métodos para obtener valores de un custom metadata a través de la Clave
    * @author karsanchez | 12-11-2024 
    * @param key 
    * @return String 
    * v. 1.0.21
    **/
    public static String getValue(String key) {
        return metadataMap.containsKey(key) ? metadataMap.get(key).OM_Value__c : null;
    }

}