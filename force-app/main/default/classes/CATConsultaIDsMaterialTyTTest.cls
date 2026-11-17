@IsTest
private class CATConsultaIDsMaterialTyTTest {
    @TestSetup
    static void setup() {
        List<SObject> sObjList = new List<SObject>();
        // Create products
        Product2 prod1 = new Product2 (Name='Product handset', ProductCode = 'B2C-TERM-X7A-AZUL-128GB', Family = 'Device', vlocity_cmt__Type__c = 'Handset', vlocity_cmt__SpecificationType__c = 'Offer');
        Product2 prod2 = new Product2 (Name='Product tech', ProductCode = 'B2C-TEC-OFR-7017440', Family = 'Device', vlocity_cmt__Type__c = 'Tech', vlocity_cmt__SpecificationType__c = 'Offer');
        sObjList.add(prod1);
        sObjList.add(prod2);
        insert sObjList;
         // Crear Categoría de Atributo
        List<vlocity_cmt__AttributeCategory__c> attrCategories = new List<vlocity_cmt__AttributeCategory__c>{
            new vlocity_cmt__AttributeCategory__c(Name = 'Cat Atributo', vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1)
        };
        insert attrCategories;
        // Crear Atributos
        List<vlocity_cmt__Attribute__c> attributes = new List<vlocity_cmt__Attribute__c>{
            new vlocity_cmt__Attribute__c(Name = 'ID Material', vlocity_cmt__Code__c = 'B2C-ATTR-TEC-MATERIAL', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'),
            new vlocity_cmt__Attribute__c(Name = 'ID Material', vlocity_cmt__Code__c = 'B2C-ATTR-MATERIAL-TERM', vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text')
        };
        insert attributes;
        // Crear AttrAssignment
        List<vlocity_cmt__AttributeAssignment__c> attrAssignments = new List<vlocity_cmt__AttributeAssignment__c> {
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = prod1.Id, vlocity_cmt__AttributeId__c = attributes[0].Id, vlocity_cmt__Value__c = '10'),
            new vlocity_cmt__AttributeAssignment__c(vlocity_cmt__ObjectId__c = prod2.Id, vlocity_cmt__AttributeId__c = attributes[1].Id, vlocity_cmt__Value__c = '10')

        };
        insert attrAssignments;
    }
    
    @IsTest
    static void testValidJobId() {
        // Configurar el contexto REST con un parámetro válido
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/consultaIdsMaterialTyT/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Llamar al método
        Test.startTest();
        List<String> response = CATConsultaIDsMaterialTyT.consultaIdsMaterialTyT();
        Test.stopTest();
        
        // Validar resultado
        Assert.areEqual(2, response.size(), 'La lista debe tener 2 elementos');
    }
    

}