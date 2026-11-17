/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Test data factory class for creating reusable test data
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>
15-Jan-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
@isTest
public class CATTestDataFactory {
    // Fecha actual simulada       
    private static Datetime currentTime = System.now();

    /**
     * Creates a Pricebook2 record
     * @param empty no params
     * @return The inserted Pricebook2 record
     */
    public static Pricebook2 createPriceBook(){ 
        //Create Price Book Entry for the new created Product
        Pricebook2 testPricebook =  new Pricebook2(
            Id = Test.getStandardPricebookId(), 
            Name = 'TestPricebook', 
            IsActive = true
        );
        return testPricebook;
    }

    /**
     * Creates a Product__c record with its corresponding pricebook entry record
     * @param productName 
     * @param productType Type of the product: Terminal;Tech;Plan;Add On;SIM Card;Fee
     * @param productSubType SubType of the product: Plan -> Postpaid;SIM Card -> SIM Card,eSIM; Add On -> Datos,Roaming Internacional,LDI,OTT,AddOns,Otros Adicionales;Fee -> Cambio de SIM,Cargo de Envío
     * @return The inserted Product__c record
     */

    public static List<SObject> createProductAndPriceBookEntry( Pricebook2 testPricebook, String productType, Integer productUnitPrice, Integer productRecurringPrice) {
        List <SObject> productAndPriceBookEntryReturn = new List <SObject>();
        String productFamily;
        String productSubType;
        String productSpecificationType = 'Offer';
        String productSpecificationSubType;
        if (productType == 'Handset' || productType == 'Tech' || productType == 'SIM Card') {
            productFamily = 'Device';
            productSubType = null;
        }
        else if (productType == 'Plan' || productType == 'Add On') {
            productFamily = 'Mobile';
            if (productType == 'Plan') {
                productSubType = 'Postpaid';
                productSpecificationSubType = 'Bundle';
            }
        }
        else if (productType == 'Fee') {
            productSubType = 'Cargo de Envío';
            productFamily = 'Cargos Administrativos';
        }
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-PROD',
            Short_Description__c = 'Test',
            Description = 'Test product description',
            Family = productFamily,
            vlocity_cmt__Type__c = productType,
            vlocity_cmt__SubType__c = productSubType,
            vlocity_cmt__SpecificationType__c = productSpecificationType,
            vlocity_cmt__SpecificationSubType__c = productSpecificationSubType,
            vlocity_cmt__IsOrderable__c = true,
            IsActive = true,
            vlocity_cmt__SellingStartDate__c = currentTime.addDays(-10),
            vlocity_cmt__SellingEndDate__c = currentTime.addDays(10)
        );
        insert product;

        //Create Price Book Entry for the new created Product
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = product.Id, 
            UnitPrice = productUnitPrice, 
            vlocity_cmt__RecurringPrice__c = productRecurringPrice, 
            IsActive = true
        );
        insert pbe;
        productAndPriceBookEntryReturn.add(product);
        productAndPriceBookEntryReturn.add(pbe);
        return productAndPriceBookEntryReturn;
    }

    //*------------------------------------------------- Creación  de Datos de Prueba para Precios en Producto ----------------------------------------------------------*/
    public static vlocity_cmt__PriceList__c createPriceList( String priceListName ) {
        // Crear datos de prueba para PriceList
        String plCode;
        if (priceListName == 'Cliente Masivo') {
            plCode = 'PL-B2C';
        } else if (priceListName =='24 meses') {
            plCode = 'B2C-PL-ANT-MAYOR-24M';
        }
        vlocity_cmt__PriceList__c priceList = new vlocity_cmt__PriceList__c (
            Name = priceListName, 
            vlocity_cmt__Code__c = plCode
        );
        insert priceList;
        return priceList;
    }

    public static vlocity_cmt__PricingVariable__c createPricingVariable( String pricingVariable ) {
        // Crear datos de prueba para PricingVariable
        vlocity_cmt__PricingVariable__c pricingVariableTest = new vlocity_cmt__PricingVariable__c(); // Pricing Variable sin impuestos y sin adjustment method
        if (pricingVariable == 'OT Std' ) {
            pricingVariableTest.Name = 'One Time Std Price';
            pricingVariableTest.vlocity_cmt__Aggregation__c = 'Unit';
            pricingVariableTest.vlocity_cmt__ChargeType__c = 'One-time';
            pricingVariableTest.vlocity_cmt__Code__c = 'OT_STD_PRC';
            pricingVariableTest.vlocity_cmt__CurrencyType__c = 'Currency';
            pricingVariableTest.vlocity_cmt__IsActive__c = true;
            pricingVariableTest.vlocity_cmt__Scope__c = 'Line';
            pricingVariableTest.vlocity_cmt__SubType__c = 'Standard';
            pricingVariableTest.vlocity_cmt__Type__c = 'Price';
            pricingVariableTest.vlocity_cmt__ValueType__c = 'Pricing Element';
            insert pricingVariableTest;
        } else if (pricingVariable == 'Monthly Std') {
            pricingVariableTest.Name = 'Recurring Monthly Std Price';
            pricingVariableTest.vlocity_cmt__Aggregation__c = 'Unit';
            pricingVariableTest.vlocity_cmt__ChargeType__c = 'Charge Type';
            pricingVariableTest.vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC';
            pricingVariableTest.vlocity_cmt__CurrencyType__c = 'Currency';
            pricingVariableTest.vlocity_cmt__IsActive__c = true;
            pricingVariableTest.vlocity_cmt__Scope__c = 'Line';
            pricingVariableTest.vlocity_cmt__SubType__c = 'Standard';
            pricingVariableTest.vlocity_cmt__Type__c = 'Price';
            pricingVariableTest.vlocity_cmt__ValueType__c = 'Pricing Element';
            insert pricingVariableTest;
        }
        return pricingVariableTest;
    }

    public static vlocity_cmt__PricingElement__c createPricingElementEntry( Id priceListId, Id pricingVariableTest, String pricingVariable, Decimal amount) {

        vlocity_cmt__PricingElement__c pricingElementTest = new vlocity_cmt__PricingElement__c(); // Pricing Element con ajuste absolute y sin impuestos
        if (pricingVariable == 'OT Std') {
            pricingElementTest.Name = 'One Time Std Price ' + String.valueOf(amount);
            pricingElementTest.vlocity_cmt__AdjustmentValue__c = null;
            pricingElementTest.vlocity_cmt__CalculationType__c = 'Simple';
            pricingElementTest.vlocity_cmt__Amount__c = amount;
            pricingElementTest.vlocity_cmt__Code__c = 'One Time Std Price_' + String.valueOf(amount) + 'COP_a2r780000000CmWAAU';
            pricingElementTest.vlocity_cmt__CurrencyCode__c = 'COP';
            pricingElementTest.vlocity_cmt__DisplayText__c = 'One Time Std Price ' + String.valueOf(amount);
            pricingElementTest.vlocity_cmt__IsActive__c = true;
            pricingElementTest.vlocity_cmt__IsOverride__c = false;
            pricingElementTest.vlocity_cmt__IsReusable__c = true;
            pricingElementTest.vlocity_cmt__PriceListId__c = priceListId;
            pricingElementTest.vlocity_cmt__PricingVariableId__c = pricingVariableTest;
            insert pricingElementTest;
        } else if (pricingVariable == 'Monthly Std'){
            pricingElementTest.Name = 'Recurring Monthly Std Price 99900';
            pricingElementTest.vlocity_cmt__AdjustmentValue__c = null;
            pricingElementTest.vlocity_cmt__CalculationType__c = 'Simple';
            pricingElementTest.vlocity_cmt__Amount__c = amount;
            pricingElementTest.vlocity_cmt__Code__c = 'One Time Std Price_932900_COP_a2r780000000CmWAAU';
            pricingElementTest.vlocity_cmt__CurrencyCode__c = 'COP';
            pricingElementTest.vlocity_cmt__DisplayText__c = 'One Time Std Price 932900';
            pricingElementTest.vlocity_cmt__IsActive__c = true;
            pricingElementTest.vlocity_cmt__IsOverride__c = false;
            pricingElementTest.vlocity_cmt__IsReusable__c = true;
            pricingElementTest.vlocity_cmt__PriceListId__c = priceListId;
            pricingElementTest.vlocity_cmt__PricingVariableId__c = pricingVariableTest;
            insert pricingElementTest;
        }
        return pricingElementTest;
    }
    public static void createPriceListEntry( Id priceListId, Id productId, Id pricebookEntryId, Id pricingElementTestId) {

        vlocity_cmt__PriceListEntry__c priceListEntryTest = new vlocity_cmt__PriceListEntry__c(
            vlocity_cmt__PriceListId__c = priceListId,
            vlocity_cmt__PricingElementId__c = pricingElementTestId,
            vlocity_cmt__DisplayText__c = 'Test Price',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__IsBasePrice__c = true,
            vlocity_cmt__IsOverride__c = false,
            vlocity_cmt__IsVirtualPrice__c = false,
            vlocity_cmt__ProductId__c = productId,
            vlocity_cmt__PromotionId__c = null,
            vlocity_cmt__PriceBookEntryId__c = pricebookEntryId
        );
        insert priceListEntryTest;
    }
    //Variable & Method for maintaining a sequence
    private static Integer sequence = 0;
    private static Integer getNextSequence() {
        return ++sequence;
    }

    //*------------------------------------------------- Creación  de Datos de Prueba para Atributos ----------------------------------------------------------*/
    public static List<Id> createAttr( String attrName ) {
        Integer sequence = 0;
        List <Id> createAttrReturn = new List <Id>();
        //Create Attribute Category
        vlocity_cmt__AttributeCategory__c attrCat = new vlocity_cmt__AttributeCategory__c(
            Name = attrName,
            vlocity_cmt__Code__c = attrName,
            vlocity_cmt__Description__c = 'Test',
            vlocity_cmt__ApplicableTypes__c = 'Product2',
            vlocity_cmt__IsActive__c = true,
            vlocity_cmt__DisplaySequence__c = getNextSequence()
        );
        insert attrCat;

        //Create Attribute
        String attrCode;
        if (attrName == 'Marca') {
            attrCode = 'B2C-ATTR-MARCA-TERM';
        } else if (attrName == 'URL'){
            attrCode = 'B2C-ATTR-MARCA-URL';
        } else if (attrName == 'MarcaTech') {
            attrCode = 'B2C-ATTR-TEC-MARCA';
        } else if (attrName == 'CatTech'){
            attrCode = 'B2C-ATTR-TEC-CAT-PROD';
        } else if (attrName == 'SubCatTech'){
            attrCode = 'B2C-ATTR-TEC-SUP-CAT-PROD';
        }
        vlocity_cmt__Attribute__c attr = new vlocity_cmt__Attribute__c (
            Name = attrName,
            vlocity_cmt__Code__c = attrCode,
            vlocity_cmt__ActiveFlg__c = true,
            vlocity_cmt__AttributeCategoryId__c = attrCat.Id,
            vlocity_cmt__ValueType__c = 'Text'
        );
        insert attr;
        createAttrReturn.add(attrCat.Id);
        createAttrReturn.add(attr.Id);
        return createAttrReturn;
    }

        public static void createAttrAssgn( Id productId, Id attrCat, Id attr ) {
        // Create Attribute Assignments
        vlocity_cmt__AttributeAssignment__c attrAssg = new vlocity_cmt__AttributeAssignment__c(
            Name = 'Test',
            vlocity_cmt__IsReadOnly__c = true,
            vlocity_cmt__Value__c = 'Apple',
            vlocity_cmt__ObjectId__c = productId,
            vlocity_cmt__AttributeCategoryId__c = attrCat,
            vlocity_cmt__AttributeId__c = attr
        );
        insert attrAssg;
    }

    public static void createAttach( Id productId ) {
        // Create Attribute Assignments
        vlocity_cmt__VlocityAttachment__c attach = new vlocity_cmt__VlocityAttachment__c(
            Name = 'Test',
            vlocity_cmt__IsDefaultImage__c = true,
            vlocity_cmt__UrlLong__c = 'https://www.google.com/',
            vlocity_cmt__ObjectId__c = productId,
            vlocity_cmt__ContentType__c = 'Image'
        );
        insert attach;
    }

    public static Asset createAsset(Id accountId, Id productId ) {
        // Create Attribute Assignments
        Asset asset = new Asset(
            Name = 'Test Asset 1',
            AccountId = accountId,
            Product2Id = productId
        );
        insert asset;
        return asset;
    }
    /**
     * Creates an Account record
     * @param IVA The Account is created with a Country with or without IVA (San Andres || Bogotá)
     * @return The inserted Order__c record
     */
    public static Account createAccount(Boolean IVA) {
        String daneCode = '88001000'; //San Andres
        if (IVA == true) {
            daneCode =  '11001000'; //Bogotá
        } 
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = 'Calle 123 45 - 67',
            BillingCity = 'Bogotá D.C',
            BillingState = 'Bogotá D.C',
            BillingCountry = 'Colombia',
            ShippingStreet = 'Calle 123 45 - 67',
            ShippingCity = 'Bogotá D.C',
            ShippingState = 'Bogotá D.C',
            ShippingCountry = 'Colombia',
            FVU_ServiceDaneCode__c = daneCode 
        );
        insert testAccount;
        return testAccount;
    }

    /**
     * Creates an Order__c record
     * @param orderName Name of the order
     * @param status Status of the order
     * @return The inserted Order__c record
     */
    public static Order createOrder(Account testAccount, Pricebook2 testPricebook, String deliveryMethod, Boolean IVA) {
        String channel = 'SF_CAV';
        String daneCiudadCAVCode = '88001000';
        String daneBodegaEnvioCode = '88001';
        Boolean isIVAExempt =  true;
        if ((deliveryMethod == 'Delivery' || deliveryMethod == 'PickUp') && IVA == true) {
            daneCiudadCAVCode = '11001000';
        }
        else {
            IsIVAExempt = false;
        }
        Order order = new Order(
            Name='Test Order',
            EffectiveDate=System.today(),
            status='Draft',
            AccountId = testAccount.Id, 
            Pricebook2Id = testPricebook.Id, 
            vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,
            FVU_TiendaRetiroDaneCode__c=daneCiudadCAVCode,
            FVU_BodegaEnvioDaneCode__c=daneBodegaEnvioCode, 
            FVU_Channel__c = channel, 
            FVU_DaneCiudadCAVOrden__c = daneCiudadCAVCode,
            vlocity_cmt__DeliveryMethod__c= deliveryMethod, 
            FVU_IsIVAExempt__c = isIVAExempt
        );
        insert order;
        return order;
    }
    /**
     * Creates an Order__c record
     * @param parentOrder ParentOrder Record
     * @param testAccount Account of the order
     * @return The inserted Order__c record
     */
    public static Order createOrderWorkingCart(Order parentOrder, Account testAccount, Pricebook2 testPricebook, String deliveryMethod) {
        String channel = deliveryMethod;
        Boolean isIVAExempt =  true;
        if (deliveryMethod != 'Immediatepickup') {
            channel = null;
            IsIVAExempt = false;
        }
        Id workingCartOrderRTId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('WorkingCart').getRecordTypeId();

        Order OrderWorkingCart = new Order(
            Name='testOrderWorkingCart',
            EffectiveDate=System.today(),
            status='Draft',
            AccountId = testAccount.Id, 
            Pricebook2Id = testPricebook.Id, 
            vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,
            FVU_TiendaRetiroDaneCode__c='88001',
            FVU_BodegaEnvioDaneCode__c='88001', 
            RecordtypeId = workingCartOrderRTId, 
            FVU_DaneCiudadCAVOrden__c = '88001000',
            vlocity_cmt__DeliveryMethod__c= deliveryMethod, 
            vlocity_cmt__ParentOrderId__c = parentOrder.Id
        );
        insert OrderWorkingCart;
        return OrderWorkingCart;
    }
    /**
     * Creates an OrderItem__c record
     * @param orderId The Id of the associated Order__c record
     * @param productId The Id of the associated Product__c record
     * @param quantity The quantity of the product in the order
     * @return The inserted OrderItem__c record
     */
    public static OrderItem createOrderItem(Id orderId, Product2 product, PricebookEntry pricebookEntry, Id testAccountId) {
        OrderItem orderItem = new OrderItem ();
        if (product.vlocity_cmt__Type__c == 'Fee') {
            orderItem.OrderId = orderId;
            orderItem.Product2Id = product.Id;
            orderItem.vlocity_cmt__Product2Id__c = product.Id;
            orderItem.PricebookEntryId = pricebookEntry.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '00001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            orderItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-EXC-IMP-TERM":0,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TIPO-TERM":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
            orderItem.CAT_ExternalPrice__c = 2500;
        }
        else if (product.vlocity_cmt__Type__c == 'Tech') {
            orderItem.OrderId = orderId;
            orderItem.Product2Id = product.Id;
            orderItem.vlocity_cmt__Product2Id__c = product.Id;
            orderItem.PricebookEntryId = pricebookEntry.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '00001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            orderItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-TEC-LIMITE-UVT":1,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TEC-SUP-CAT-PROD":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
        } else{
            orderItem.OrderId = orderId;
            orderItem.Product2Id = product.Id;
            orderItem.vlocity_cmt__Product2Id__c = product.Id;
            orderItem.PricebookEntryId = pricebookEntry.Id;
            orderItem.Quantity = 1;
            orderItem.UnitPrice = 10;
            orderItem.vlocity_cmt__LineNumber__c = '00001';
            orderItem.vlocity_cmt__Action__c = 'Add';
            orderItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            orderItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            orderItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-EXC-IMP-TERM":0,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TIPO-TERM":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
        }
        insert orderItem;
        return orderItem;
    }
    /**
     * Creates an FVU_Exencion_IVA_EI__c record
     * @param empty no params
     * @return The inserted FVU_Exencion_IVA_EI__c record
     */
    public static FVU_Exencion_IVA_EI__c CreateExencionIVAEI() {
        FVU_Exencion_IVA_EI__c exencionIVAEI = new FVU_Exencion_IVA_EI__c(
            FVU_EEI_Aplica_IVA__c = 'No',
            FVU_EEI_DaneDpto_CAV__c = '88'
        );
        insert exencionIVAEI;
        return exencionIVAEI;
    }
    /**
     * Creates an FVU_Exencion_IVA_Dom__c record
     * @param empty no params
     * @return The inserted FVU_Exencion_IVA_Dom__c record
     */
    public static FVU_Exencion_IVA_Dom__c CreateExencionIVADom() {
        FVU_Exencion_IVA_Dom__c exencionIVADom = new FVU_Exencion_IVA_Dom__c(
            FVU_EDOM_Aplica_IVA__c = 'No',
            FVU_EDOM_Canal_Venta__c = 'SF_CAV',
            FVU_EDOM_Cod_Depto_Destino__c = '88'
        );
        insert exencionIVADom;
        return exencionIVADom;
    }
        /**
     * Creates an FVU_Exencion_IVA_Bodega_Envio__c record
     * @param empty no params
     * @return The inserted FVU_Exencion_IVA_Bodega_Envio__c record
     */
    public static FVU_Exencion_IVA_Bodega_Envio__c CreateExencionIVABODG() {
        FVU_Exencion_IVA_Bodega_Envio__c exencionIVABODG = new FVU_Exencion_IVA_Bodega_Envio__c(
            FVU_EBODG_Aplica_IVA__c = 'No',
            FVU_EBODG_Cod_Dept_Bodega__c = '88'
        );
        insert exencionIVABODG;
        return exencionIVABODG;
    }
    /**
     * Creates an FVU_Exencion_IVA_Ret_Tienda__c record
     * @param empty no params
     * @return The inserted FVU_Exencion_IVA_Ret_Tienda__c record
     */
    public static FVU_Exencion_IVA_Ret_Tienda__c CreateExencionIVARetTienda() {
        FVU_Exencion_IVA_Ret_Tienda__c exencionIVARetTienda = new FVU_Exencion_IVA_Ret_Tienda__c(
            FVU_ERT_Aplica_IVA__c = 'No',
            FVU_ERT_Canal_Venta__c = 'SF_CAV',
            FVU_ERT_Cod_Depto_Tienda__c = '88'
        );
        insert exencionIVARetTienda;
        return exencionIVARetTienda;
    }
    /**
     * Creates an FVU_UVT_info__c record
     * @param empty no params
     * @return The inserted FVU_UVT_info__c record
     */
    public static FVU_UVT_info__c CreateUVTInfo() {
        // Fecha actual simulada       
        Date currentTime = System.today();
        FVU_UVT_info__c UVTInfo = new FVU_UVT_info__c(
            FVU_UVT_Fecha_Inicial_Vigencia__c = currentTime.addDays(-10), // Fecha inicial en el pasado
            FVU_UVT_Fecha_Final_Vigencia__c = currentTime.addDays(10), // Fecha final en el futuro,
            FVU_Valor_UVT__c = 49799
        );
        insert UVTInfo;
        return UVTInfo;
    }
    /**
     * Creates an FVU_IVA_info__c record
     * @param empty no params
     * @return The inserted FVU_IVA_info__c record
     */
    public static FVU_IVA_info__c createIVAInfo() {
        FVU_IVA_info__c ivaInfo = new FVU_IVA_info__c(
            FVU_IVA_Fecha_Inicial_Vigencia__c = currentTime.addDays(-10), // Fecha inicial en el pasado
            FVU_IVA_Fecha_Final_Vigencia__c = currentTime.addDays(10), // Fecha final en el futuro,
            FVU_Valor_IVA__c = 19,
            FVU_IVA_Tipo_de_equipo__c = 'Defecto',
            FVU_IVA_Subtipo_de_equipo__c= 'Defecto'
        );
        insert IVAInfo;
        return IVAInfo;
    }
        /**
     * Creates an CAT_Opciones_Precio_Buscador_Productos__c record
     * @param empty no params
     * @return The inserted FVU_IVA_info__c record
     */
    public static CAT_Opciones_Precio_Buscador_Productos__c  createPriceObjectLWCInfo(String priceOptionProductType) {
        CAT_Opciones_Precio_Buscador_Productos__c priceLWCInfo = new CAT_Opciones_Precio_Buscador_Productos__c(
            CAT_Precio_Minimo__c = 0,
            CAT_Precio_Maximo__c = 199999,
            Name = 'Rango Test',
            CAT_Tipo_de_Producto__c = priceOptionProductType
        );
        insert priceLWCInfo;
        return priceLWCInfo;
    }
    //*------------------------------------------------- Creación  de Datos de Prueba para QUOTE ----------------------------------------------------------*/
    /**
     * Creates an Opportunity record
     * @param NA No param needed
     * @return The inserted Opportunity record
     */
    public static Opportunity createOpp(Account testAcc) {
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            Budget_Confirmed__c=false,
            Discovery_Completed__c= false,
            ROI_Analysis_Completed__c = false,
            StageName = 'Diseño de la Oferta',
            IsPrivate = false,
            ForecastCategoryName = 	'Best Case',
            AccountId = testAcc.Id,
            CloseDate = Date.today()
        );
        insert opp;
        return opp;
    }
    /**
     * Creates an Quote record
     * @param orderName Name of the order
     * @param status Status of the order
     * @return The inserted Quote record
     */
    public static Quote createQuote(Account testAccount, Pricebook2 testPricebook, Opportunity Opp, String deliveryMethod) {
        String channel = 'SF_CAV';
        if (deliveryMethod != 'Immediatepickup') {
            channel = null;
        }
        Quote quote = new Quote(
            Name='Test Quote',
            OpportunityId = Opp.Id,
            vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,
            FVU_Channel__c = channel, 
            FVU_DaneCiudadCAVOrden__c = '88001000',
            CAT_DeliveryMethod__c= deliveryMethod
        );
        insert quote;
        return quote;
    }
    public static Quote createQuoteWorkingCart(Quote parentQuote, Account testAccount, Pricebook2 testPricebook, Opportunity Opp, String deliveryMethod) {
        String channel = deliveryMethod;
        if (deliveryMethod != 'Immediatepickup') {
            channel = null;
        }
        Id workingCartQuoteRTId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('WorkingCart').getRecordTypeId();
        Quote testQuoteWorkingCart = new Quote(
            Name='Test Working Cart Quote',
            status='Draft',
            OpportunityId = Opp.Id,
            Pricebook2Id = testPricebook.Id, 
            vlocity_cmt__DefaultServiceAccountId__c = testAccount.Id,
            FVU_TiendaRetiroDaneCode__c='88001',
            FVU_BodegaEnvioDaneCode__c='88001', 
            FVU_Channel__c = channel, 
            FVU_DaneCiudadCAVOrden__c = '88001000',
            CAT_DeliveryMethod__c= deliveryMethod, 
            CanCreateQuoteLineItems = false,
            FIN_MasterQuote__c = false,
            RecordtypeId = workingCartQuoteRTId,
            vlocity_cmt__ParentQuoteId__c = parentQuote.Id
        );
        insert testQuoteWorkingCart;
        return testQuoteWorkingCart;
    }
    /**
     * Creates an QuoteLineItem record
     * @param quoteId The Quote Id of the associated QuoteLineItem record
     * @param productId The Id of the associated Product__c record
     * @return The inserted QuoteLineItem record
     */
    public static QuoteLineItem createQuoteItem(Id quoteId, Product2 product, PricebookEntry pricebookEntry, Id testAccountId) {
        QuoteLineItem quoteLineItem = new QuoteLineItem ();
        if (product.vlocity_cmt__Type__c == 'Fee') {
            quoteLineItem.QuoteId = quoteId;
            quoteLineItem.Product2Id = product.Id;
            quoteLineItem.vlocity_cmt__Product2Id__c = product.Id;
            quoteLineItem.PricebookEntryId = pricebookEntry.Id;
            quoteLineItem.Quantity = 1;
            quoteLineItem.UnitPrice = 10;
            quoteLineItem.vlocity_cmt__LineNumber__c = '00001';
            quoteLineItem.vlocity_cmt__Action__c = 'Add';
            quoteLineItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            quoteLineItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            quoteLineItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-EXC-IMP-TERM":0,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TIPO-TERM":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
        }
        else if (product.vlocity_cmt__Type__c == 'Tech') {
            quoteLineItem.QuoteId = quoteId;
            quoteLineItem.Product2Id = product.Id;
            quoteLineItem.vlocity_cmt__Product2Id__c = product.Id;
            quoteLineItem.PricebookEntryId = pricebookEntry.Id;
            quoteLineItem.Quantity = 1;
            quoteLineItem.UnitPrice = 10;
            quoteLineItem.vlocity_cmt__LineNumber__c = '00001';
            quoteLineItem.vlocity_cmt__Action__c = 'Add';
            quoteLineItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            quoteLineItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            quoteLineItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-TEC-LIMITE-UV":0,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TEC-SUP-CAT-PROD":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
        } else{
            quoteLineItem.QuoteId = quoteId;
            quoteLineItem.Product2Id = product.Id;
            quoteLineItem.vlocity_cmt__Product2Id__c = product.Id;
            quoteLineItem.PricebookEntryId = pricebookEntry.Id;
            quoteLineItem.Quantity = 1;
            quoteLineItem.UnitPrice = 10;
            quoteLineItem.vlocity_cmt__LineNumber__c = '00001';
            quoteLineItem.vlocity_cmt__Action__c = 'Add';
            quoteLineItem.vlocity_cmt__ProvisioningStatus__c = 'New';
            quoteLineItem.vlocity_cmt__ServiceAccountId__c = testAccountId;
            quoteLineItem.vlocity_cmt__AttributeSelectedValues__c = '{"B2C-ATTR-TEC-TERM":["2G","3G","4G"],"B2C-ATTR-COLOR-TERM":"Medianoche","B2C-ATTR-EXC-IMP-TERM":0,"B2C-ATTR-FINANC-TERM":null,"B2C-ATTR-GAMA-TERM":"Premium","B2C-ATTR-LINEA-PROD-TERM":"Preventa","B2C-ATTR-MARCA-TERM":"Apple","B2C-ATTR-MATERIAL-TERM":"70049198","B2C-ATTR-MODELO-TERM":"Watch S8","B2C-ATTR-TIPO-TERM":"Smartwatch","B2C-ATTR-CORREA-RELOJ":"Sintetico","B2C-ATTR-MARCO-RELOJ":"Aluminio","B2C-ATTR-RECP-LLM-TERM":"si","B2C-ATTR-TAM-CORREA-RELOJ":["No Disponible"],"B2C-ATTR-VAL-CORP-TERM":["Oxigeno en la sangre","Temperatura Corporal","Frecuencia Cardiaca"],"B2C-ATTR-MEM-EXP-TERM":"no","B2C-ATTR-TAM-PANT-TERM":"45 mm","B2C-ATTR-TIPO-PANT-TERM":"Retina Oled","B2C-ATTR-REFRES-TERM":"No Disponible","B2C-ATTR-RES-PANT-TERM":"396 X 484","B2C-ATTR-CONECT-TERM":["Bluetooth","Wifi"],"B2C-ATTR-GARANTIA-TERM":"12 meses","B2C-ATTR-BATERIA-TERM":"Hasta 18 horas","B2C-ATTR-CARG-CARGRAP-TERM":"Cable Carga Rapida","B2C-ATTR-CARG-INAL-TERM":"no","B2C-ATTR-CARGRAP-TERM":"si","B2C-ATTR-MOD-PROC-TERM":"Chip S8 SIP","B2C-ATTR-PROC-TERM":"Apple","B2C-ATTR-SO-TERM":"WatchOS","B2C-ATTR-DUAL-SIM-TERM":"no","B2C-ATTR-TIPO-SIM-TERM":"eSIM","B2C-ATTR-DIM-TERM":"48 x 38 x 10,7","B2C-ATTR-PESO-TERM":"51,5 gr","B2C-ATTR-PROT-TERM":"IP6X","B2C-ATTR-OBSQ-TERM":"No"}';
        }
        insert quoteLineItem;
        return quoteLineItem;
    }
}