@IsTest
public class CATDeviceProductTSVExporterTest {
    @testSetup
    static void setupDataDeviceHandset() {

        // Crear productos
        List<Product2> products = new List<Product2>{
            new Product2(Name='Product 1', ProductCode = 'Terminal1', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = 'Descripción Larga',Short_Description__c = 'Descripción Corta'),
            new Product2(Name='Product 2', ProductCode = 'Terminal2', Family = 'Device', vlocity_cmt__Type__c = 'Handset', Description = '' ,Short_Description__c = '')
        };
        insert products;

        // Crear Regla
        List<vlocity_cmt__Rule__c> rules = new List<vlocity_cmt__Rule__c>{
            new vlocity_cmt__Rule__c(Name = 'Regla', vlocity_cmt__Description__c = 'Descripción Regla', vlocity_cmt__IsActive__c = true)
        };
        insert rules;

        // Crear Asignación de Regla
        List<vlocity_cmt__RuleAssignment__c> ruleAssignments = new List<vlocity_cmt__RuleAssignment__c>{
            new vlocity_cmt__RuleAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id, vlocity_cmt__RuleId__c = rules[0].Id)
        };
        insert ruleAssignments;

        // Crear datos de prueba para PricingVariable
        List<vlocity_cmt__PricingVariable__c> pricingVariables = new List<vlocity_cmt__PricingVariable__c>{
            new vlocity_cmt__PricingVariable__c(Name = 'One Time Std Price', vlocity_cmt__Code__c = 'OT_STD_PRC')
        };
        insert pricingVariables;

        //Crear datos de prueba para PricingElement
        List<vlocity_cmt__PricingElement__c> pricingElements = new List<vlocity_cmt__PricingElement__c>{
            new vlocity_cmt__PricingElement__c(Name = 'Test pricingElement1',vlocity_cmt__Amount__c = 955.55,vlocity_cmt__PricingVariableId__c = pricingVariables[0].Id,vlocity_cmt__AdjustmentValue__c = null)
        };
        insert pricingElements;

        // Crear datos de prueba para PriceList
        List<vlocity_cmt__PriceList__c> priceLists = new List<vlocity_cmt__PriceList__c>{
            new vlocity_cmt__PriceList__c(Name = 'Cliente Masivo', vlocity_cmt__Code__c = 'PL-B2C')
        };
        insert priceLists;

        // Crear datos de prueba para PriceListEntry
        List<vlocity_cmt__PriceListEntry__c> priceListEntries = new List<vlocity_cmt__PriceListEntry__c>{
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__IsActive__c = true, vlocity_cmt__IsBasePrice__c = true, vlocity_cmt__EffectiveUntilDate__c = null, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[0].Id, vlocity_cmt__ProductId__c = products[0].Id, vlocity_cmt__DisplayText__c = 'Display Text ple1', vlocity_cmt__EffectiveFromDate__c = Date.today()),
            new vlocity_cmt__PriceListEntry__c(vlocity_cmt__IsActive__c = true, vlocity_cmt__IsBasePrice__c = true, vlocity_cmt__EffectiveUntilDate__c = null, vlocity_cmt__PriceListId__c = priceLists[0].Id, vlocity_cmt__PricingElementId__c = pricingElements[0].Id, vlocity_cmt__ProductId__c = products[1].Id, vlocity_cmt__DisplayText__c = 'Display Text ple2',  vlocity_cmt__EffectiveFromDate__c = Date.today())
        };
        insert priceListEntries;

        // Crear Categoría de Atributo
        List<vlocity_cmt__AttributeCategory__c> attrCategories = new List<vlocity_cmt__AttributeCategory__c>{
            new vlocity_cmt__AttributeCategory__c(Name = 'Cat Atributo', vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1)
        };
        insert attrCategories;

        // Crear Atributos
        List<vlocity_cmt__Attribute__c> attributes = new List<vlocity_cmt__Attribute__c>{
            new vlocity_cmt__Attribute__c(Name = 'Cantidad Max Permitida por cliente', vlocity_cmt__Code__c = 'B2C-ATTR-CANT-COMPRA-PERMITIDA', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Number'),
            new vlocity_cmt__Attribute__c(Name = 'Garantía', vlocity_cmt__Code__c = 'B2C-ATTR-GARANTIA-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'ID Material', vlocity_cmt__Code__c = 'B2C-ATTR-MATERIAL-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'Límite UVT Impuesto',vlocity_cmt__Code__c = 'B2C-ATTR-EXC-IMP-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Number'),
            new vlocity_cmt__Attribute__c(Name = 'Marca', vlocity_cmt__Code__c = 'B2C-ATTR-MARCA-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'Modelo',vlocity_cmt__Code__c = 'B2C-ATTR-MODELO-TERM',vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'Muerto en Caja',vlocity_cmt__Code__c = 'B2C-ATTR-TEC-DOA',vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'Producto Aplica Financiación',vlocity_cmt__Code__c = 'B2C-ATTR-FINANC-TERM',vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text')
        };
        insert attributes;

        // Crear AttrAssignment
        List<vlocity_cmt__AttributeAssignment__c> attrAssignments = new List<vlocity_cmt__AttributeAssignment__c>{
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id, vlocity_cmt__AttributeId__c = attributes[0].Id, vlocity_cmt__Value__c = '10'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[1].Id,vlocity_cmt__Value__c = '10'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[2].Id,vlocity_cmt__Value__c = '123456'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[3].Id,vlocity_cmt__Value__c = '10'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[4].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[5].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[6].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[0].Id,vlocity_cmt__AttributeId__c = attributes[7].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[0].Id,vlocity_cmt__Value__c = '20'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[1].Id,vlocity_cmt__Value__c = '20'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[2].Id,vlocity_cmt__Value__c = '123456'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[3].Id,vlocity_cmt__Value__c = '10'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[4].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[5].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[6].Id,vlocity_cmt__Value__c = 'value'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = products[1].Id,vlocity_cmt__AttributeId__c = attributes[7].Id,vlocity_cmt__Value__c = 'value')
        };
        insert attrAssignments;

    }

    // Llamar al método de prueba
    @isTest
    static void testDeviceHandset() {
        List<Product2> products = [SELECT Id FROM Product2 WHERE vlocity_cmt__Type__c = 'Handset' AND Family = 'Device' WITH USER_MODE];

        List<Id> productIds = new List<Id>();
        for(Product2 prod : products){
            productIds.add(prod.Id);
        }

        List<List<Id>> productIdsList = new List<List<Id>>{productIds};
        Test.startTest();
        List<Id> contentVersionId = CATDeviceProductTSVExporter.generateDeviceHandsetProductTSV(productIdsList);
        List<ContentVersion> contentVersionList = [SELECT Id FROM ContentVersion WHERE Id = :contentVersionId[0] WITH USER_MODE];
        Test.stopTest();
        Assert.areEqual(1, contentVersionList.size(),'No se generó archivo tsv en ContentVersion.');
    }
}