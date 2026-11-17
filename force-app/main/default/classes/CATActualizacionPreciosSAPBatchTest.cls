/*---------------------------------------------------------------------------------------------------------------
Autor: Victor Hugo Jiménez 
Fecha: 2025-05-22
Equipo: Catálogo
Descripcion: Test class for CATActualizacionPreciosSAPBatch
Code Coverage: N/A
History
<Date>            <Author>             <Description>             <Version>
2025-05-13                            Versión Inicial                01
----------------------------------------------------------------------------------------------------------------*/

@IsTest
public class CATActualizacionPreciosSAPBatchTest {
    @TestSetup
    public static void setup() {
        // Create pricelists
        List<vlocity_cmt__PriceList__c> priceLists = new List<vlocity_cmt__PriceList__c> {
            new vlocity_cmt__PriceList__c  (Name='ClienteMasivo', vlocity_cmt__Code__c ='PL-B2C'),
            new vlocity_cmt__PriceList__c  (Name='6 a 23 meses', vlocity_cmt__Code__c ='B2C-PL-ANT-6-23M'),
            new vlocity_cmt__PriceList__c  (Name='mayor a 24 meses', vlocity_cmt__Code__c ='B2C-PL-ANT-MAYOR-24M'),
            new vlocity_cmt__PriceList__c  (Name='menor a 5 mese', vlocity_cmt__Code__c ='PL-ECOM-B2C'),
		    new vlocity_cmt__PriceList__c  (Name='6 a 23 meses', vlocity_cmt__Code__c ='B2C-PL-ECOM-ANT-6-23M'),
	        new vlocity_cmt__PriceList__c  (Name='mayor a 24 meses', vlocity_cmt__Code__c ='B2C-PL-ECOM-ANT-MAYOR-24M')
        };
        insert priceLists;
        // Create object class
        SObject sObj = [SELECT Id, SobjectType, DeveloperName FROM RecordType WHERE IsActive = TRUE and SobjectType = 'vlocity_cmt__ObjectClass__c' and DeveloperName = 'ObjectType' LIMIT 1];
        List<vlocity_cmt__ObjectClass__c> objClasses = new List<vlocity_cmt__ObjectClass__c> {
            new vlocity_cmt__ObjectClass__c  (Name='Discount', vlocity_cmt__ObjectApiName__c = 'PricingElement__c', RecordTypeId = sObj.Id),
            new vlocity_cmt__ObjectClass__c  (Name='Charge',vlocity_cmt__ObjectApiName__c = 'PricingElement__c', RecordTypeId = sObj.Id) 
        };
        insert objClasses;

        // Create pricing variables
        List<vlocity_cmt__PricingVariable__c> pricingVariables = new List<vlocity_cmt__PricingVariable__c> {
            new vlocity_cmt__PricingVariable__c  (Name = 'One Time Std Price', vlocity_cmt__Code__c = 'OT_STD_PRC',vlocity_cmt__Aggregation__c = 'Unit',
                vlocity_cmt__ChargeType__c='One-time',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
                vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency'),
            new vlocity_cmt__PricingVariable__c  (Name = 'One Time Std Price', vlocity_cmt__Code__c = 'OT_STD_PRC_ADJ_ABS',vlocity_cmt__Aggregation__c = 'Unit',
                vlocity_cmt__ChargeType__c='One-time',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
                vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency')
        };
        insert pricingVariables;

        List<SObject> sObjListProducts = new List<SObject>();
        // Create products
        Product2 prodTermninales = new Product2 (Name='Terminales PS', ProductCode = 'B2C-MOV-PRD-TERM-PS', Family = 'Device', vlocity_cmt__Type__c = 'Terminales', vlocity_cmt__SpecificationType__c = 'Product');
        insert prodTermninales;
        Product2 prod1 = new Product2 (Name='Product handset', ProductCode = 'B2C-TERM-TEST', CAT_Canales__c = 'ECOMMERCE;SUPERAPP', Family = 'Device', vlocity_cmt__Type__c = 'Handset',vlocity_cmt__ProductSpecId__c= prodTermninales.Id, vlocity_cmt__SpecificationType__c = 'Offer');
        Product2 prod2 = new Product2 (Name='Product tech', ProductCode = 'B2C-TEC-TEST', CAT_Canales__c = 'ECOMMERCE;SUPERAPP', Family = 'Device', vlocity_cmt__Type__c = 'Tech',vlocity_cmt__ProductSpecId__c=prodTermninales.Id , vlocity_cmt__SpecificationType__c = 'Offer');
        Product2 prod3 = new Product2 (Name='Product test', ProductCode = 'B2C-TST-TEST', CAT_Canales__c = 'ECOMMERCE;SUPERAPP', Family = 'Device', vlocity_cmt__Type__c = 'Tech',vlocity_cmt__ProductSpecId__c=prodTermninales.Id , vlocity_cmt__SpecificationType__c = 'Offer');
        sObjListProducts.add(prod1);
        sObjListProducts.add(prod2);
        sObjListProducts.add(prod3);
        insert sObjListProducts;

         // Crear Categoría de Atributo
        List<vlocity_cmt__AttributeCategory__c> attrCategories = new List<vlocity_cmt__AttributeCategory__c>{
            new vlocity_cmt__AttributeCategory__c(Name = 'Cat Atributo', vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1)
        };
        insert attrCategories;
        // Crear Atributos
        List<vlocity_cmt__Attribute__c> attributes = new List<vlocity_cmt__Attribute__c>{
            new vlocity_cmt__Attribute__c(Name = 'ID Material', vlocity_cmt__Code__c = 'B2C-ATTR-MATERIAL-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text')
        };
        insert attributes;
        // Crear AttrAssignment
        List<vlocity_cmt__AttributeAssignment__c> attrAssignments = new List<vlocity_cmt__AttributeAssignment__c> {
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = prod1.Id, vlocity_cmt__AttributeId__c = attributes[0].Id, vlocity_cmt__Value__c = '70012345'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = prod2.Id, vlocity_cmt__AttributeId__c = attributes[0].Id, vlocity_cmt__Value__c = '70011111'),  //###
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = prod3.Id, vlocity_cmt__AttributeId__c = attributes[0].Id, vlocity_cmt__Value__c = '70000000')  //###    
        };
        insert attrAssignments;

        // Crear Regla
        List<vlocity_cmt__Rule__c> rules = new List<vlocity_cmt__Rule__c>{
            new vlocity_cmt__Rule__c(Name = 'Cliente Antiguedad Menor 5 Meses', vlocity_cmt__Description__c = 'Descripción Regla', vlocity_cmt__IsActive__c = true),
			new vlocity_cmt__Rule__c(Name = 'Canales - Cliente Antiguedad Menor 5 Meses', vlocity_cmt__Description__c = 'Descripción Regla', vlocity_cmt__IsActive__c = true),                
		    new vlocity_cmt__Rule__c(Name = 'Canales - Cliente Antiguedad Entre 6 y 23 Meses', vlocity_cmt__Description__c = 'Descripción Regla', vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__Rule__c(Name = 'Canales - Cliente Antiguedad Mayor 24 Meses', vlocity_cmt__Description__c = 'Descripción Regla', vlocity_cmt__IsActive__c = true)
        };
        insert rules;


        //Entradas de precios existentes
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = pricebookId, IsActive = true);
        update standardPricebook;      

        List<PriceBookEntry> pricebookEntries = new List<PriceBookEntry>{
            new PriceBookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod1.Id, UnitPrice = 0, UseStandardPrice = false, vlocity_cmt__RecurringPrice__c = 0, vlocity_cmt__RecurringUOM__c = 'vlocity_cmt__RecurringUOM__c'),
            new PriceBookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod2.Id, UnitPrice = 0, UseStandardPrice = false, vlocity_cmt__RecurringPrice__c = 0, vlocity_cmt__RecurringUOM__c = 'vlocity_cmt__RecurringUOM__c'),
            new PriceBookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = prod3.Id, UnitPrice = 0, UseStandardPrice = false, vlocity_cmt__RecurringPrice__c = 0, vlocity_cmt__RecurringUOM__c = 'vlocity_cmt__RecurringUOM__c')
        };
        insert pricebookEntries;

        List<vlocity_cmt__PricingElement__c> pricingElements = new List<vlocity_cmt__PricingElement__c>{
            new vlocity_cmt__PricingElement__c(Name = 'PElm1', vlocity_cmt__Amount__c = 11111, vlocity_cmt__CurrencyCode__c = 'COP', vlocity_cmt__ObjectTypeId__c = objClasses[0].Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingVariableId__c = pricingVariables[0].Id),
            new vlocity_cmt__PricingElement__c(Name = 'PElm2', vlocity_cmt__AdjustmentValue__c = -111,   vlocity_cmt__CurrencyCode__c = 'COP', vlocity_cmt__ObjectTypeId__c = objClasses[0].Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingVariableId__c = pricingVariables[0].Id)
        };
        insert pricingElements;

        List<vlocity_cmt__Promotion__c> promociones = new List<vlocity_cmt__Promotion__c>{
            new vlocity_cmt__Promotion__c(Name='TestPromo', vlocity_cmt__Code__c = 'B2C-PROMO-TEST', CAT_PromotionClass__c = 'Descuento Todo Claro', CAT_Type__c = 'TodoClaro', vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__IsActive__c = true)
        };
        insert promociones;

        List<vlocity_cmt__Promotion__c> promocionDescuento = new List<vlocity_cmt__Promotion__c>{
            new vlocity_cmt__Promotion__c(Name='TestPromoDesc', vlocity_cmt__Code__c = 'B2C-PROMO-TESTDESC', CAT_PromotionClass__c = 'Descuento', CAT_Type__c = 'Estandar', CAT_Canales__c = 'ECOMMERCE;SUPERAPP', vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__IsActive__c = true)
        };
        insert promocionDescuento;

        List<vlocity_cmt__PromotionItem__c> promoItems = new List<vlocity_cmt__PromotionItem__c>{
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promociones[0].Id, vlocity_cmt__ProductId__c = prod3.Id, vlocity_cmt__ProductHierarchyPath__c = prod3.Id)
        };
        insert promoItems;

        List<vlocity_cmt__PromotionItem__c> promoItemsDesc = new List<vlocity_cmt__PromotionItem__c>{
            new vlocity_cmt__PromotionItem__c(Name = 'TestPI-Desc', vlocity_cmt__IsActive__c = true, vlocity_cmt__MaxQuantity__c = 9999, vlocity_cmt__MinQuantity__c = 0, vlocity_cmt__Quantity__c = 1, vlocity_cmt__PromotionId__c = promocionDescuento[0].Id, vlocity_cmt__ProductId__c = prod3.Id, vlocity_cmt__ProductHierarchyPath__c = prod3.Id)
        };
        insert promoItemsDesc;

        List<vlocity_cmt__PriceListEntry__c> plEntries = new List<vlocity_cmt__PriceListEntry__c>{
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__ProductId__c = prod1.Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[0].Id, vlocity_cmt__PriceBookEntryId__c = String.valueOf(pricebookEntries[0].Id), vlocity_cmt__IsBasePrice__c = true, vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__ProductId__c = prod2.Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[0].Id, vlocity_cmt__PriceBookEntryId__c = String.valueOf(pricebookEntries[0].Id), vlocity_cmt__IsBasePrice__c = true, vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__ProductId__c = prod3.Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[1].Id, vlocity_cmt__PriceBookEntryId__c = String.valueOf(pricebookEntries[0].Id), vlocity_cmt__PromotionId__c = promociones[0].Id, vlocity_cmt__PromotionItemId__c = promoItems[0].Id, vlocity_cmt__IsBasePrice__c = false, vlocity_cmt__IsActive__c = true),
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__ProductId__c = prod3.Id, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[1].Id, vlocity_cmt__PriceBookEntryId__c = String.valueOf(pricebookEntries[0].Id), vlocity_cmt__PromotionId__c = promocionDescuento[0].Id, vlocity_cmt__PromotionItemId__c = promoItemsDesc[0].Id, vlocity_cmt__IsBasePrice__c = false, vlocity_cmt__IsActive__c = true)
        };
        insert plEntries;

        List<vlocity_cmt__RuleAssignment__c> ruleAssigments = new List<vlocity_cmt__RuleAssignment__c>{
            new vlocity_cmt__RuleAssignment__c(Name = 'TestRA', vlocity_cmt__ObjectId__c = String.valueOf(plEntries[1].Id), vlocity_cmt__RuleId__c = rules[0].Id)
        };
        insert ruleAssigments;

    }
    
    @IsTest
    static void insertaPrecioECOM24() {
        CAT_Informacion_Precios_SAP_tmp__c r = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c='70012345',
            CAT_Desc_Comercial__c='Product handset',
            CAT_Lista_Precio__c='04_SF_TER_EC24',
            CAT_Precio_sin_IVA_ZP06__c='3000',
            CAT_Precio_IVA_Final_Red_ZP05__c='3570',
            CAT_ValorDescuento__c='0',
            CAT_FechaInicioVigencia__c='2199-08-13',
            CAT_Id_Job_Externo__c='JOB-EC24'
        );
        insert r;
    
        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('JOB-EC24'), 1);
        Test.stopTest();
    
        r = [SELECT CAT_Resultado_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id=:r.Id];
        System.assertEquals('Éxito', r.CAT_Resultado_Procesamiento__c);
    }
    
    @IsTest
    static void insertaPrecioECOM23() {
        CAT_Informacion_Precios_SAP_tmp__c r = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c='70012345',
            CAT_Desc_Comercial__c='Product handset',
            CAT_Lista_Precio__c='04_SF_TER_EC06',
            CAT_Precio_sin_IVA_ZP06__c='2000',
            CAT_Precio_IVA_Final_Red_ZP05__c='2380',
            CAT_ValorDescuento__c='0',
            CAT_FechaInicioVigencia__c='2199-08-13',
            CAT_Id_Job_Externo__c='JOB-EC06'
        );
        insert r;
    
        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('JOB-EC06'), 1);
        Test.stopTest();
    
        r = [SELECT CAT_Resultado_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id=:r.Id];
        System.assertEquals('Éxito', r.CAT_Resultado_Procesamiento__c);
    }
    
    @IsTest
    static void insertaPrecioECOMsinRegla() {
        CAT_Informacion_Precios_SAP_tmp__c r = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c='70012345',
            CAT_Desc_Comercial__c='Product handset',
            CAT_Lista_Precio__c='04_SF_TEC_ECO',
            CAT_Precio_sin_IVA_ZP06__c='1000',
            CAT_Precio_IVA_Final_Red_ZP05__c='1190',
            CAT_ValorDescuento__c='0',
            CAT_FechaInicioVigencia__c='2199-08-13',
            CAT_Id_Job_Externo__c='JOB-TECECO'
        );
        insert r;
    
        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('JOB-TECECO'), 1);
        Test.stopTest();
    
        r = [SELECT CAT_Resultado_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id=:r.Id];
        System.assertEquals('Éxito', r.CAT_Resultado_Procesamiento__c);
    }
    
    @IsTest
    static void insertaPrecioECOM05() {
        CAT_Informacion_Precios_SAP_tmp__c r = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c='70012345',
            CAT_Desc_Comercial__c='Product handset',
            CAT_Lista_Precio__c='04_SF_TER_EC00',
            CAT_Precio_sin_IVA_ZP06__c='1000',
            CAT_Precio_IVA_Final_Red_ZP05__c='1190',
            CAT_ValorDescuento__c='0',
            CAT_FechaInicioVigencia__c='2199-08-13',
            CAT_Id_Job_Externo__c='54334'
        );
        insert r;
    
        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('54334'), 1);
        Test.stopTest();
    
        r = [SELECT CAT_Resultado_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id=:r.Id];
        System.assertEquals('Éxito', r.CAT_Resultado_Procesamiento__c);
    }
    
    @IsTest
    static void insertaFechaInvalida() {
        CAT_Informacion_Precios_SAP_tmp__c r = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '99999999',
            CAT_Desc_Comercial__c = 'Dummy',
            CAT_Lista_Precio__c = '04_SF TEC',
            CAT_Precio_sin_IVA_ZP06__c = '1000',
            CAT_Precio_IVA_Final_Red_ZP05__c = '1190',
            CAT_ValorDescuento__c = '0',
            CAT_FechaInicioVigencia__c = '2025-02-31',
            CAT_Id_Job_Externo__c = '56347834'
        );
        insert r;
    
        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('56347834'), 1);
        Test.stopTest();

        r = [SELECT CAT_Resultado_Procesamiento__c, CAT_Descripcion_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :r.Id];
        System.assertEquals('Error', r.CAT_Resultado_Procesamiento__c, 'Debe terminar en error por producto inexistente (y ya cubrimos el catch de la fecha).');
    }

    @IsTest
    static void creaPromo_usaCanalDeProducto() {

        vlocity_cmt__PriceList__c pl = [SELECT Id FROM vlocity_cmt__PriceList__c WHERE vlocity_cmt__Code__c = 'PL-B2C' LIMIT 1];

        insert new vlocity_cmt__Promotion__c( 
        Name                        = 'Product handset Pago de contado',
        vlocity_cmt__Code__c        = 'B2C-PROMO-70012345-CONTADO',
        vlocity_cmt__PriceListId__c = pl.Id,
        vlocity_cmt__IsOrderable__c = true,
        CAT_Type__c                 = 'Estandar',
        CAT_PromotionClass__c       = 'Descuento'
        );

        insert new CAT_Informacion_Precios_SAP_tmp__c(
        CAT_Equipo__c                 = '70012345',
        CAT_Desc_Comercial__c         = 'Product handset',
        CAT_Lista_Precio__c           = '04_SF_TER_EC00',
        CAT_Precio_sin_IVA_ZP06__c    = '0',
        CAT_Precio_IVA_Final_Red_ZP05__c = '0',
        CAT_ValorDescuento__c         = '-100', 
        CAT_FechaInicioVigencia__c    = '2199-08-13',
        CAT_Id_Job_Externo__c         = 'UT-JOB-1'
        );

        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('UT-JOB-1'), 1);
        Test.stopTest();

        vlocity_cmt__Promotion__c promotion = [SELECT Id, CAT_Canales__c FROM vlocity_cmt__Promotion__c WHERE vlocity_cmt__Code__c = 'B2C-PROMO-70012345-CONTADO' LIMIT 1];
        System.assertEquals('ECOMMERCE;SUPERAPP', promotion.CAT_Canales__c,'La promoción debe tomar CAT_Canales__c desde Product2');
    }


    @IsTest
    static void promoExistente_actualizaCanal() {
        Product2 prod = [SELECT Id, Name, ProductCode, CAT_Canales__c FROM Product2 WHERE ProductCode = 'B2C-TEC-TEST' LIMIT 1];

        vlocity_cmt__PriceList__c pl = [SELECT Id FROM vlocity_cmt__PriceList__c WHERE vlocity_cmt__Code__c = 'PL-B2C' LIMIT 1];

        // Promo existente con canal distinto
        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(
        Name                        = prod.Name + ' Pago de contado',
        vlocity_cmt__Code__c        = 'B2C-PROMO-' + prod.ProductCode + '-CONTADO',
        vlocity_cmt__PriceListId__c = pl.Id,
        vlocity_cmt__IsOrderable__c = true,
        CAT_Type__c                 = 'Estandar',
        CAT_PromotionClass__c       = 'Descuento',
        CAT_Canales__c              = 'ECOMMERCE'
        );
            insert promo;

        // Vincular el producto a la promo
        insert new vlocity_cmt__PromotionItem__c(
        vlocity_cmt__PromotionId__c = promo.Id,
        vlocity_cmt__ProductId__c   = prod.Id,
        vlocity_cmt__IsActive__c    = true
        );

        // TMP del mismo material del prod (70011111 de tu @TestSetup)
        insert new CAT_Informacion_Precios_SAP_tmp__c(
        CAT_Equipo__c                 = '70011111',
        CAT_Lista_Precio__c           = '04_SF_TER_EC00',
        CAT_Precio_sin_IVA_ZP06__c    = '0',
        CAT_Precio_IVA_Final_Red_ZP05__c = '0',
        CAT_ValorDescuento__c         = '0',
        CAT_FechaInicioVigencia__c    = '2199-08-13',
        CAT_Id_Job_Externo__c         = 'UT-JOB-2'
        );

        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('UT-JOB-2'), 1);
        Test.stopTest();

        promo = [SELECT CAT_Canales__c FROM vlocity_cmt__Promotion__c WHERE Id = :promo.Id];
        System.assertEquals('ECOMMERCE;SUPERAPP', promo.CAT_Canales__c, 'La promo existente debe actualizar su canal al del Product2');
    }

        @IsTest
    static void canal_noActualizarSiVacio() {
        // Producto SIN canal
        Product2 prod = [ SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode = 'B2C-TST-TEST' LIMIT 1];
        update new Product2(Id = prod.Id, CAT_Canales__c = null);

        vlocity_cmt__PriceList__c pl = [SELECT Id FROM vlocity_cmt__PriceList__c WHERE vlocity_cmt__Code__c = 'PL-B2C' LIMIT 1];

        // Promo existente con un canal previo
        vlocity_cmt__Promotion__c promo = new vlocity_cmt__Promotion__c(
            Name                        = prod.Name + ' Pago de contado',
            vlocity_cmt__Code__c        = 'B2C-PROMO-' + prod.ProductCode + '-CONTADO',
            vlocity_cmt__PriceListId__c = pl.Id,
            vlocity_cmt__IsOrderable__c = true,
            CAT_Type__c                 = 'Estandar',
            CAT_PromotionClass__c       = 'Descuento',
            CAT_Canales__c              = 'ECOMMERCE'
        );
        insert promo;

        insert new vlocity_cmt__PromotionItem__c(
            vlocity_cmt__PromotionId__c = promo.Id,
            vlocity_cmt__ProductId__c   = prod.Id,
            vlocity_cmt__IsActive__c    = true
        );

        insert new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c              = '70000000',  
            CAT_ValorDescuento__c      = '100', 
            CAT_FechaInicioVigencia__c = '2199-08-13',
            CAT_Id_Job_Externo__c      = 'UT-JOB-3'
        );

        Test.startTest();
        Database.executeBatch(new CATActualizacionPreciosSAPBatch('UT-JOB-3'), 1);
        Test.stopTest();

         promo = [SELECT CAT_Canales__c FROM vlocity_cmt__Promotion__c WHERE Id = :promo.Id];
        System.assertEquals('ECOMMERCE', promo.CAT_Canales__c, 'Sin canal en Product2, no debe modificarse el valor existente');
    }

    @isTest
    static void insertaEntradaPreciosNueva() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13',CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void crearEntradaPreciosDuplicada() {  //executeBatch
       	CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        
        CAT_Informacion_Precios_SAP_tmp__c precio2 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c = '234455', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio2;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch2 = new CATActualizacionPreciosSAPBatch(precio2.CAT_Id_Job_Externo__c);
        String jobId2 = Database.executeBatch(actualizarPreciosTyTBatch2,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio2.Id LIMIT 1];

        String resultado = 'Éxito: No se actualiza la entrada porque es el mismo precio de la entrada actual en el producto';
        Assert.areEqual(jobId2, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void actualizarEntradaPreciosExistente() {  //executeBatch
       	CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        
        CAT_Informacion_Precios_SAP_tmp__c precio2 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='2016900',CAT_Precio_IVA_Final_Red_ZP05__c= '2016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-05-13',CAT_Id_Job_Externo__c = '234455', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio2;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch2 = new CATActualizacionPreciosSAPBatch(precio2.CAT_Id_Job_Externo__c);
        String jobId2 = Database.executeBatch(actualizarPreciosTyTBatch2,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio2.Id LIMIT 1];

        String resultado = 'Exito: No se procesa por tener una vigencia anterior al precio activo actual';
        Assert.areEqual(jobId2, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaEntradaPreciosNuevaAntEntre6y24() {  //executeBatch
       	CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL06', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        
        CAT_Informacion_Precios_SAP_tmp__c precio2 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL06', CAT_Precio_sin_IVA_ZP06__c ='1026900',CAT_Precio_IVA_Final_Red_ZP05__c= '1026900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-09-13',CAT_Id_Job_Externo__c = '234455', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio2;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch2 = new CATActualizacionPreciosSAPBatch(precio2.CAT_Id_Job_Externo__c);
        String jobId2 = Database.executeBatch(actualizarPreciosTyTBatch2,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio2.Id LIMIT 1];

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId2, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaEntradaPreciosNuevaAntMayor24() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL24', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13',CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosExistente() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1017900',CAT_Precio_IVA_Final_Red_ZP05__c= '1017900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13', CAT_Id_Job_Externo__c = '2344A', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        // Validar resultado
        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosErrorValorPrecioSinIVA() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='text',CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c = '2324', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El precio sin IVA debe ser un valor numérico';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosErrorValorPrecioConIVA() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000',CAT_Precio_IVA_Final_Red_ZP05__c= 'text', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c='223', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El precio con IVA debe ser un valor numérico';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosErrorFecha() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000',CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025/08/13',CAT_Id_Job_Externo__c='223', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: La fecha debe estar en formato yyyy-mm-dd';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosErrorFechaVacia() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000',CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: La fecha de inicio viene vacía';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaEntradaPrecioSinIVAVacio() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00',CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El precio sin IVA debe tener un valor';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaEntradaPrecioConIVAVacio() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El precio con IVA debe tener un valor';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPrecioDescuentoMismoTiempo() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000', CAT_Precio_IVA_Final_Red_ZP05__c ='1111000',
            CAT_ValorDescuento__c = '-1000', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: No se puede crear un precio y un descuento al mismo tiempo.';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaMaterialInexistente() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '12and12', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1017900',CAT_Precio_IVA_Final_Red_ZP05__c= '1017900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13', CAT_Id_Job_Externo__c = '2344A', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        // Validar resultado
        String resultado = 'Error: No se encontró el producto con ID de Material ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaListaDePreciosInexistente() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '12and12', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = 'TEXTO', CAT_Precio_sin_IVA_ZP06__c ='1017900',CAT_Precio_IVA_Final_Red_ZP05__c= '1017900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13', CAT_Id_Job_Externo__c = '2344A', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        // Validar resultado
        String resultado = 'Error: La lista de precio asignada no existe';
        Assert.areEqual(jobId, precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPrecioConIVANegativo() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000', CAT_Precio_IVA_Final_Red_ZP05__c= '-1111000', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El valor de la lista de precios del producto es 0 o negativo, por ende no se debe actualizar';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaAjusteProdTech() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TEC TDCL', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-1000', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado[0].CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }
    @isTest
    static void insertaAjusteNullProdTech() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-1000', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        
        CAT_Informacion_Precios_SAP_tmp__c precio2 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '', CAT_FechaInicioVigencia__c ='2025-09-14',CAT_Id_Job_Externo__c='234545', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio2;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch2 = new CATActualizacionPreciosSAPBatch(precio2.CAT_Id_Job_Externo__c);
        String jobId2 = Database.executeBatch(actualizarPreciosTyTBatch2,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio2.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        
        String resultado = 'Valor descuento vacío, actualiza promoción a cero';
        Assert.areEqual(jobId2,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaAjusteNullPromoYaCero() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-1200', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='2346', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        
        CAT_Informacion_Precios_SAP_tmp__c precio2 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-09-14',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio2;
        
        CAT_Informacion_Precios_SAP_tmp__c precio3 = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product tech', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '', CAT_FechaInicioVigencia__c ='2025-09-15',CAT_Id_Job_Externo__c='23445', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio3;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch2 = new CATActualizacionPreciosSAPBatch(precio2.CAT_Id_Job_Externo__c);
        String jobId2 = Database.executeBatch(actualizarPreciosTyTBatch2,1);
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch3 = new CATActualizacionPreciosSAPBatch(precio3.CAT_Id_Job_Externo__c);
        String jobId3 = Database.executeBatch(actualizarPreciosTyTBatch3,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        CAT_Informacion_Precios_SAP_tmp__c precioResultado2 = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio2.Id WITH USER_MODE];
        CAT_Informacion_Precios_SAP_tmp__c precioResultado3 = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio3.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);
		System.debug('precioResultado -> ' + precioResultado.CAT_Descripcion_Procesamiento__c);
        System.debug('precioResultado2 -> ' + precioResultado2.CAT_Descripcion_Procesamiento__c);
        System.debug('precioResultado3 -> ' + precioResultado3.CAT_Descripcion_Procesamiento__c);
        // Validar resultado
        
        String resultado = 'Valor descuento vacío, tiene promoción ya tiene cero';
        Assert.areEqual(jobId3,     precioResultado3.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado3.CAT_Descripcion_Procesamiento__c);
    }
    @isTest
    static void insertaEntradaPrecioDescuentoVacio() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000', CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado[0].CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaNoHayPromocionActiva() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00',CAT_ValorDescuento__c = '', CAT_Precio_sin_IVA_ZP06__c ='0', CAT_Precio_IVA_Final_Red_ZP05__c= '0', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='88234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Valor descuento vacío, no tiene promoción activa';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaMaterialVacio() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='1111000', CAT_ValorDescuento__c = '0', CAT_Precio_IVA_Final_Red_ZP05__c= '1111000', CAT_FechaInicioVigencia__c ='2025-09-13',CAT_Id_Job_Externo__c='234', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El ID del material debe estar configurado';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosPromoTDCLTerm() {
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70011111', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC TDCL', CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-10000', CAT_FechaInicioVigencia__c ='2199-09-13',CAT_Id_Job_Externo__c='2224', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }
    
    @isTest
    static void insertaEntradaPreciosPromoTDCLTech() {
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70011111', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER TDCL', CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-2000', CAT_FechaInicioVigencia__c ='2199-09-13',CAT_Id_Job_Externo__c='2224', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosPromoDeContado5Meses() {
        System.debug(':: INICIA insertaEntradaPreciosPromoDeContado5Meses');
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70011111', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00' /*'04_SF TEC TDCL'*/, CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-10000', CAT_FechaInicioVigencia__c ='2199-09-13',CAT_Id_Job_Externo__c='245', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c, CAT_Descripcion_Procesamiento__c
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];

        System.debug('>> TEST: precioResultado -> ' + precioResultado);

        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);  
        System.debug(':: FIN insertaEntradaPreciosPromoExistente');
    }

    @isTest
    static void insertaEntradaPreciosPromoDeContado5MesesExistente() {
        System.debug(':: INICIA insertaEntradaPreciosPromoDeContado5MesesExistente');
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70011111', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '-1500', CAT_FechaInicioVigencia__c ='2199-10-13', CAT_Id_Job_Externo__c='211145', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];


        String resultado = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + precioResultado.CAT_Equipo__c;
        Assert.areEqual(jobId,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);  
        System.debug(':: FIN insertaEntradaPreciosPromoExistente');
    }

    @isTest
    static void insertaEntradaPreciosErrorValorDescuento() {  //executeBatch
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70000000', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = 'texto', CAT_FechaInicioVigencia__c ='2025-08-13',CAT_Id_Job_Externo__c='223', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;
        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        List<CAT_Informacion_Precios_SAP_tmp__c> precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c, CAT_Descripcion_Procesamiento__c
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id WITH USER_MODE];
        System.debug('>> TEST: jobId PL -> '  + jobId);
        System.debug('>> TEST: precio PL -> ' + precioResultado);

        // Validar resultado
        Assert.areEqual(1, precioResultado.size(), 'La lista debe tener 1 elemento');
        String resultado = 'Error: El valor de descuento debe ser numérico';
        Assert.areEqual(jobId,     precioResultado[0].CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado[0].CAT_Descripcion_Procesamiento__c);
    }

    @isTest
    static void insertaEntradaPreciosCero() {
        System.debug(':: INICIA insertaEntradaPreciosCero');
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70011111', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TER CL00', CAT_Precio_sin_IVA_ZP06__c ='0',CAT_Precio_IVA_Final_Red_ZP05__c= '0', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-10-13', CAT_Id_Job_Externo__c='211145', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = '', CAT_Descripcion_Procesamiento__c = ''
        );
        insert precio;

        Test.startTest();
        CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(precio.CAT_Id_Job_Externo__c);
        String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
        Test.stopTest();

        CAT_Informacion_Precios_SAP_tmp__c precioResultado = [SELECT Id,CAT_Equipo__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c 
                                                              FROM CAT_Informacion_Precios_SAP_tmp__c WHERE Id = :precio.Id LIMIT 1];


        String resultado = 'Éxito: No se crea ajuste nuevo, se está pidiendo crear un ajuste de $0 - lo que significa que se debe actualizar un registro existente - sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)';
        Assert.areEqual(jobId,     precioResultado.CAT_Id_Job_Procesamiento__c);
        Assert.areEqual(resultado, precioResultado.CAT_Descripcion_Procesamiento__c);  
        System.debug(':: FIN insertaEntradaPreciosCero');
    }
}