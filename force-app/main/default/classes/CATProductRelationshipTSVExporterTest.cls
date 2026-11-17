@IsTest
public class CATProductRelationshipTSVExporterTest {

    @IsTest
    public static void testProductRelationshipTSVExporter() {

        // Crear PS
        Product2 ps1 = new Product2 (
            Name='Plan PS', 
            ProductCode = 'PLAN-PS', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__SpecificationType__c = 'Product',
            vlocity_cmt__SpecificationSubType__c = 'Bundle'
        );
        insert ps1;

        Product2 ps2 = new Product2 (
            Name='SIM Card PS', 
            ProductCode = 'SIM-CARD-PS', 
            Family = '', 
            vlocity_cmt__Type__c = 'SIM Card', 
            vlocity_cmt__SubType__c = 'None',
            vlocity_cmt__SpecificationType__c = 'Product',
            vlocity_cmt__SpecificationSubType__c = 'Simple'
        );
        insert ps2;

        // Crear plan móvil - bundle
        Product2 prod1 = new Product2 (
            Name='Product 1', 
            ProductCode = 'PROD1', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid'
        );
        insert prod1;

        Product2 prod2 = new Product2 (
            Name='Product 2', 
            ProductCode = 'PROD2',
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid'
        );
        insert prod2;

        // Crear plan móvil - simple
        Product2 planProd1 = new Product2 (
            Name='Plan Product 1', 
            ProductCode = 'PLAN-PROD1', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__ProductSpecId__c = ps1.Id
        );
        insert planProd1;

        Product2 planProd2 = new Product2 (
            Name='Plan Product 2', 
            ProductCode = 'PLAN-PROD2', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__ProductSpecId__c = ps1.Id
        );
        insert planProd2;

        // Crear prod 'Escoja SIM Card'
        Product2 prod3 = new Product2 (
            Name='Escoja SIM Card', 
            ProductCode = 'PROD3', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid'
        );
        insert prod3;

        // Crear prod 'SIM Card'
        Product2 prod4 = new Product2 (
            Name='SIM Card', 
            ProductCode = 'PROD4', 
            Family = 'Mobile', 
            vlocity_cmt__Type__c = 'Plan', 
            vlocity_cmt__SubType__c = 'Postpaid',
            vlocity_cmt__ProductSpecId__c = ps2.Id
        );
        insert prod4;

        // Crear ProductChildItem Relationships
        vlocity_cmt__ProductChildItem__c pCIR1 = new vlocity_cmt__ProductChildItem__c(
            vlocity_cmt__ParentProductId__c = prod1.Id,
            vlocity_cmt__ChildProductId__c = planProd1.Id,
            vlocity_cmt__ChildLineNumber__c = '1'
        );
        insert pCIR1;

        vlocity_cmt__ProductChildItem__c pCIR2 = new vlocity_cmt__ProductChildItem__c(
            vlocity_cmt__ParentProductId__c = prod2.Id,
            vlocity_cmt__ChildProductId__c = planProd2.Id,
            vlocity_cmt__ChildLineNumber__c = '1'
        );
        insert pCIR2;

        vlocity_cmt__ProductChildItem__c pCIR3 = new vlocity_cmt__ProductChildItem__c(
            vlocity_cmt__ParentProductId__c = prod3.Id,
            vlocity_cmt__ChildProductId__c = prod4.Id,
            vlocity_cmt__ChildLineNumber__c = '1'
        );
        insert pCIR3;

        // Crear lista de Product Ids
        List<Id> prodCIIds = new List<String>{
            pCIR1.Id,
            pCIR2.Id,
            pCIR3.Id
        };

        // Llamar al método que se está probando
        List<List<Id>> productChildItemList = new List<List<Id>>{prodCIIds};
        List<Id> contentVersionId = CATProductRelationshipTSVExporter.generateProductRelationshipTSV(productChildItemList);
        List<ContentVersion> contentVersionList = [SELECT Id FROM ContentVersion WHERE Id = :contentVersionId[0] WITH USER_MODE];
        System.assertEquals(1, contentVersionList.size(),'No se generó archivo tsv en ContentVersion.');
    }
}