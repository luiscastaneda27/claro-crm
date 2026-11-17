@IsTest
public class CATAttributeTSVExporterTest {

    @IsTest
    public static void testAttrTSVExporter() {

        // Crear productos (plan móvil)
        Product2 prod1 = new Product2 (
            Name='Product 1', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer',
            vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert prod1;

        Product2 prod2 = new Product2 (
            Name='Product 2', 
            ProductCode = 'PlanMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer',
            vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert prod2;

        // Crear producto spec internet móvil
        Product2 ps = new Product2 (
            Name='Plan Internet Móvil PS', 
            ProductCode = 'B2C-MOV-PLAN-INTERNET-PS', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Product',
            vlocity_cmt__SpecificationSubType__c = 'Bundle'
        );
        insert ps;

        // Crear plan internet móvil (no tiene atributo Familia y Amigos - posición 12)
        Product2 prod3 = new Product2 (
            Name='Product 3', 
            ProductCode = 'PlanInternetMovil', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Offer',
            vlocity_cmt__SpecificationSubType__c = 'Simple',
            vlocity_cmt__ProductSpecId__c = ps.Id
        );
        insert prod3;

        // Crear Categoría de Atributo
        vlocity_cmt__AttributeCategory__c attrCat = new vlocity_cmt__AttributeCategory__c(
            Name = 'Cat Atributo', 
            vlocity_cmt__Description__c = 'Descripción Cat Atributo',
            vlocity_cmt__DisplaySequence__c = 1
        );
        insert attrCat;

        // Crear Atributos
        vlocity_cmt__Attribute__c attr1 = new vlocity_cmt__Attribute__c(
            Name = 'Facebook',
            vlocity_cmt__Code__c = 'B2C-ATTR1',
            vlocity_cmt__AttributeCategoryId__c = attrCat.Id,
            vlocity_cmt__ValueType__c = 'Checkbox'
        );
        insert attr1;

        vlocity_cmt__Attribute__c attr2 = new vlocity_cmt__Attribute__c(
            Name = 'Datos',
            vlocity_cmt__Code__c = 'B2C-ATTR2',
            vlocity_cmt__AttributeCategoryId__c = attrCat.Id, 
            vlocity_cmt__ValueType__c = 'Text'
        );
        insert attr2;

        // Crear AttrAssignment
        vlocity_cmt__AttributeAssignment__c attrAssignment1 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod1.Id,
            vlocity_cmt__AttributeId__c = attr1.Id,
            vlocity_cmt__Value__c = 'true'
        );
        insert attrAssignment1;

        vlocity_cmt__AttributeAssignment__c attrAssignment2 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod1.Id,
            vlocity_cmt__AttributeId__c = attr2.Id,
            vlocity_cmt__Value__c = 'Value prod1'
        );
        insert attrAssignment2;

        vlocity_cmt__AttributeAssignment__c attrAssignment3 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod2.Id,
            vlocity_cmt__AttributeId__c = attr1.Id,
            vlocity_cmt__Value__c = 'false'
        );
        insert attrAssignment3;

        vlocity_cmt__AttributeAssignment__c attrAssignment4 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod2.Id,
            vlocity_cmt__AttributeId__c = attr2.Id,
            vlocity_cmt__Value__c = 'Value prod2'
        );
        insert attrAssignment4;

        vlocity_cmt__AttributeAssignment__c attrAssignment5 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod2.Id,
            vlocity_cmt__AttributeId__c = attr1.Id,
            vlocity_cmt__Value__c = 'true'
        );
        insert attrAssignment5;

        vlocity_cmt__AttributeAssignment__c attrAssignment6 = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod3.Id,
            vlocity_cmt__AttributeId__c = attr2.Id,
            vlocity_cmt__Value__c = 'Value prod3'
        );
        insert attrAssignment6;

        // Crear lista de Product Ids
        List<Id> prodIds = new List<String>{
            prod1.Id,
            prod2.Id,
            prod3.Id
        };

        // Llamar al método que se está probando
        List<List<Id>> productIdsList = new List<List<Id>>{prodIds};
        List<Id> contentVersionId = CATAttributeTSVExporter.generateAttrTSV(productIdsList);
        List<ContentVersion> contentVersionList = [SELECT Id FROM ContentVersion WHERE Id = :contentVersionId[0] WITH USER_MODE];
        System.assertEquals(1, contentVersionList.size(),'No se generó archivo tsv en ContentVersion.');
    }
}