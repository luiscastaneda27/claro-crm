/*--------------------------------------------------------------------------
Author:         Mamata - 
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    				<Version>
2023-09-05		  Mamata		EricsonRequestJSON for OM Stream			     						1.0.0
2024-06-07      Hever Salas    	Agregar objeto para AdminCHARGE         			    				1.0.1
2024-11-25     Josue Aguilar    Change amount definition, from integer to decimal       				1.0.2
2024-12-18      Hever Salas    	HDU-417695 - Creacion orden SOM de familia y amigos 					1.0.3
2025-03-06      Hever Salas     HDU-544910: Identificacion de Items sin accion          				1.0.4
2025-04-02      Hever Salas    	HDU-522166: PV - [CESION]  Crear Orden SOM								1.0.5
2025-04-16      Omar Flores    	HDU-517240: Nuevo Wrapper para productos con atts diferentes			1.0.6
----------------------------------------------------------------------------*/
public class EricsonRequestJSON
{ 
	public String orderType = '';	//ProductOfferingOrder
	public String createdDate = '';	//2023-03-07T14:40:48.894Z
	public String description = '';	//ORDMD282406
    public String requestedStartDate = '';
    public cls_orderSpecification orderSpecification = new cls_orderSpecification();
	public cls_relatedParties[] relatedParties = new List<cls_relatedParties>();
	public String correlationID = '';	//1678200050
	public boolean run = false;
	public cls_relatedEntities[] relatedEntities = new List<cls_relatedEntities>();
	public Integer version = 0;	//0
	public Object[] orderItems = new List<Object>();
	public String requestedCompletionDate = '';	//2023-03-11T14:40:48.894Z
	public cls_orderSpec orderSpec = new cls_orderSpec();
	public cls_attributes[] attrs = new List<cls_attributes>();
    public Object[] FaF = new List<Object>();
    
    public class cls_orderSpecification {
	}
    
    public class cls_childRelatedParties {
		public String reference = '';	//93000000000181
		public String role = '';	//Customer
	}
	public class cls_relatedParties {
		public String reference = '';	//93000000000181
		public String role = '';	//Customer
		public cls_party party = new cls_party();
	}
	public class cls_party {
		public cls_CustomerInformation CustomerInformation = new cls_CustomerInformation();
	}
	public class cls_CustomerInformation {
		public cls_attributes[] attributes = new List<cls_attributes>();
	}
	public class cls_attributes {
		public String name = '';	//MARKET
		public String value = '';	//GSM
        
        public cls_attributes(String name, String value){
			this.name = name;
			this.value = value;
		}
        
        public cls_attributes(){
			
		}
	}
    
    public class cls_childattributes {
		public String name = '';	//MARKET
		public List<String> value = new List<String>();	//GSM
        
        public cls_childattributes(String name, List<String> value){
			this.name = name;
			this.value = value;
		}
        
        public cls_childattributes(){
			
		}
	}
    
	public class cls_OIrelatedEntities {
		public String type = '';	//Contract
		public String name = '';	//ContractId
		public String reference = '';	//CONTR0000
		public cls_OIentity entity;
        
        public cls_OIrelatedEntities(String type, String name, String reference, cls_OIentity entity){
            this.type = type;
            this.name = name;
            this.reference = reference;
            this.entity = entity;
        }
        
        public cls_OIrelatedEntities(){}
	}
    
    public class cls_relatedEntities {
		public String type = '';	//Contract
		public String id = '';	//ContractId
		public String reference = '';	//CONTR0000
		public cls_entity entity;
        public String name = '';
        
        public cls_relatedEntities(String type, String id, String reference, cls_entity entity,String name){
            this.type = type;
            this.id = id;
            this.reference = reference;
            this.entity = entity;
            this.name = name;
        }
        
        public cls_relatedEntities(){}
        
	}
    
	public class cls_OIentity {
		public cls_contractCreationInformation contractCreationInformation;
		public cls_CustomerAccountInformation customerAccountInformation;
		public cls_OIentity(String type){
			if(type == OrderIntegrationSystemInterfaceConstants.S_CONTRACT){
				this.contractCreationInformation = new cls_contractCreationInformation(); 
			}else{
				this.customerAccountInformation = new cls_CustomerAccountInformation();
			}
		}
	}
    
    public class cls_entity {
		public cls_locationInformation locationInformation;
		public cls_CustomerAccountInformation customerAccountInformation; 
		public cls_entity(String type){
			if(type == OrderIntegrationSystemInterfaceConstants.S_PLACE){
				this.locationInformation = new cls_locationInformation(); 
			}else{
				this.customerAccountInformation = new cls_CustomerAccountInformation();
			}
		}
	}
	public class cls_locationInformation {
		public cls_attributes[] attributes = new List<cls_attributes>();
	}
	public class cls_CustomerAccountInformation {
		public cls_attributes[] attributes = new List<cls_attributes>();
	}
	public class cls_orderItems {
		public cls_item item = new cls_item();
	}
    public class child_cls_orderItems {
		public child_cls_item item = new child_cls_item();
	}
	public class child_cls_item {
		public String id = '';	//0
		public String orderType = '';	//ProductOfferingOrder
		public String action = '';	//Add
		public cls_productOffering productOffering = new cls_productOffering();
		public cls_product product = new cls_product();
		public cls_resources[] resources = new List<cls_resources>();
		public cls_services[] services = new List<cls_services>();
        public object[] exceptions = new List<object>();
		public cls_relatedOrderItems[] relatedOrderItems = new List<cls_relatedOrderItems>();
		public cls_OIrelatedEntities[] relatedEntities = new List<cls_OIrelatedEntities>();
        public cls_childattributes[] attrs = new List<cls_childattributes>();
        public cls_childRelatedParties[] relatedParties = new List<cls_childRelatedParties>();
	}
    
    public class cls_item {
		public String id = '';	//0
		public String orderType = '';//ProductOfferingOrder
		public String orderSpecification = '';//e
		public String action = '';	//Add
		public cls_productOffering productOffering = new cls_productOffering();
		public cls_product product = new cls_product();
		public cls_resources[] resources = new List<cls_resources>();
		public cls_services[] services = new List<cls_services>();
		public cls_relatedOrderItems[] relatedOrderItems = new List<cls_relatedOrderItems>();
		public cls_OIrelatedEntities[] relatedEntities = new List<cls_OIrelatedEntities>();
		public cls_attributes[] attrs = new List<cls_attributes>();
        public Object[] FaF = new List<Object>();
	}
	public class cls_productOffering {
		public String id = '';	//PO_MovPosBasico
	}
	public class cls_product {
		public cls_productCharacteristics[] productCharacteristics = new List<cls_productCharacteristics>();
		public String productId = '';	//12360943224
		public cls_productPrice[] productPrice = new List<cls_productPrice>();
        public String productSpecification = '';//PS_MovPosBasico
		public boolean isBundled = false;
	}
	public class cls_productCharacteristics {
		public String name = '';//RPName
		public Object value = '';	//Servicio Movil Postpago
		public boolean isConfigurable = false;
	}
	public class cls_productPrice {
		public Decimal amount = 0.00;	//380
		public cls_taxCode taxCode = new cls_taxCode();
		//public String v_currency = '';	//COP ---- commenting as agreed with Ericsson, 20 March. Ashish tested with customer
		public String chargeTypeCode = '';	//CT_SimCarTaxIVA
		public String popId = '';	//Tax_IVA
		public cls_characteristics[] characteristics = new List<cls_characteristics>();
	}
	public class cls_taxCode {
	}
	
	public class cls_characteristics {
		public String name = '';	//loadInstalledBaseStrategy
		public String value = '';	//NOSR
        
        public cls_characteristics(String name, String value){
            this.name = name;
            this.value = value;
        }
        
        public cls_characteristics(){}
	}
	public class cls_externalIDs {
	}
	public class cls_unitOfMeasure {
	}
	public class cls_overrideAmount {
	}
	public class cls_resources {
		public cls_resourceCharacteristics[] resourceCharacteristics = new List<cls_resourceCharacteristics>();
		public String resourceId = '';	//1917667068
		public String resourceSpecification = '';	//PRS_SimCard
		public String resourceCandidate = '';
		public boolean isLogical = false;
		public boolean isCompound = false;
		public String parentId = '';
		public String physicalResourceId = '';
		public String resourceType = '';	//Accessory
		public String resourceNumber = '';
		public String serialNumber = '';	//8957101100000100353
        public String action = '';
	}
	public class cls_resourceCharacteristics {
		public String name = '';	//CodigoMaterial
		public String value = '';//cls_value type -------------- to be re-considered
		public boolean isConfigurable = false;
	}
	public class cls_value {
	}
	public class cls_resourceCandidate {
	}
	public class cls_parentId {
	}
	public class cls_physicalResourceId {
	}
	public class cls_resourceNumber {
	}
	public class cls_services {
		public cls_serviceCharacteristics[] serviceCharacteristics = new List<cls_serviceCharacteristics>();
		public cls_serviceCandidate serviceCandidate = new cls_serviceCandidate();
		public String serviceId = '';	//1917667069
		public String cfsSpecification = '';	//CFSS_MovPosBasico
		public String serviceType = '';	//CustomerFacingServiceSpec
        public String action = '';
        public String state = '';
	}
	public class cls_serviceCharacteristics {
        public String name = '';	//CodigoMaterial
		public String value = '';//cls_value type -------------- to be re-considered
		public boolean isConfigurable = false;
	}
	public class cls_serviceCandidate {
	}
	public class cls_relatedOrderItems {
        public String role = '';
        public String reference = '';
	}
	public class cls_contractCreationInformation {
		public cls_attributes[] attributes = new List<cls_attributes>();
	}
	
	public class cls_orderSpec {
		public String name = '';	//ProductOrder
		public cls_characteristics[] characteristics = new List<cls_characteristics>();
	}
	public static EricsonRequestJSON parse(String json){
		return (EricsonRequestJSON) System.JSON.deserialize(json, EricsonRequestJSON.class);
	}
    
    public class ProdWithoutAction {
		public String ApiName = '';
        public String ErrorCode = '';
        public String orderId = '';
        public Map<String,Object> response = new Map<String,Object>();
        public String orderType = '';
        public String orderSubType = '';
	}

	// Wrapper para valores anteriores y nuevos de atributos 517240
	public class ProdWithDiffAttrs{
		public String keyName= '';
		public String prodNAme = '';
		public String attrName = '';
		public String attrValorNuevo ='';
		public String attrValorAnterior='';
		
		public ProdWithDiffAttrs(String pName, String aName, String valorNuevo, String valorAnterior){
			this.prodNAme = pName;
			this.attrName = aName;
			this.attrValorNuevo = valorNuevo;
			this.attrValorAnterior = valorAnterior;
			this.keyName = pName + '-' + aName;
		}
	}
	
}