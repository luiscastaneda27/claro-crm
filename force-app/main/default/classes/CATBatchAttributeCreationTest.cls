@IsTest
private class CATBatchAttributeCreationTest {

    // Define constants used in the Product query and assignments
    private static final String PRODUCT_SPEC_NAME = 'Accesorios PS';
    private static final String VLOCITY_ATTR_CODE_1 = 'ATTR_CODE_1';
    private static final String VLOCITY_ATTR_CODE_2 = 'ATTR_CODE_2';
    
    // --- Test Setup Method ---
    @TestSetup
    static void setupTestData() {
        
         //1. Crear Categoría de Atributo
        List<vlocity_cmt__AttributeCategory__c> attrCategories = new List<vlocity_cmt__AttributeCategory__c>{
            new vlocity_cmt__AttributeCategory__c(Name = 'Cat Atributo', vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1)
        };
        insert attrCategories;
        // 2. Create a Vlocity Attribute (vlocity_cmt__Attribute__c) for assignments
        vlocity_cmt__Attribute__c vlocityAttr1 = new vlocity_cmt__Attribute__c(
            Name = 'Test Vlocity Attr 1',
            vlocity_cmt__Code__c = VLOCITY_ATTR_CODE_1,vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'
        );
        vlocity_cmt__Attribute__c vlocityAttr2 = new vlocity_cmt__Attribute__c(
            Name = 'Test Vlocity Attr 2',
            vlocity_cmt__Code__c = VLOCITY_ATTR_CODE_2,vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id, vlocity_cmt__ValueType__c = 'Text'
        );
        insert new List<vlocity_cmt__Attribute__c>{vlocityAttr1, vlocityAttr2};

        // 2. Create Product2 Records (Scope for the Batch)
        Product2 prodAccesorios = new Product2 (Name='Accesorios PS', ProductCode = 'B2C-MOV-PRD-TEC-PS', Family = 'Device', vlocity_cmt__Type__c = 'Tech', vlocity_cmt__SpecificationType__c = 'Product');
        insert prodAccesorios;
        Product2 prod1 = new Product2(
            Name = 'Product One',
            ProductCode = 'P001',
            vlocity_cmt__ProductSpecId__c = prodAccesorios.Id // Matches query
        );
        Product2 prod2 = new Product2(
            Name = 'Product Two',
            ProductCode = 'P002',
            vlocity_cmt__ProductSpecId__c = prodAccesorios.Id // Matches query
        );
        insert new List<Product2>{prod1, prod2};

        // 3. Create CAT_AtInformativos__c Records (Inner Loop)
        CAT_AtInformativos__c infoAttr1 = new CAT_AtInformativos__c(
            Name = 'Info Attr 1',
            CAT_Product_Spec__c = 'Accesorios PS',
            CAT_Codigo__c = VLOCITY_ATTR_CODE_1 // Matching code 
        );
        CAT_AtInformativos__c infoAttr2 = new CAT_AtInformativos__c(
            Name = 'Info Attr 2',
            CAT_Product_Spec__c = 'Accesorios PS',
            CAT_Codigo__c = 'NON_MATCHING_CODE' // Non-matching code
        );
        insert new List<CAT_AtInformativos__c>{infoAttr1, infoAttr2};

        // 4. Create Vlocity Attribute Assignment (to test successful mapping)
        vlocity_cmt__AttributeAssignment__c va = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = prod1.Id,
            vlocity_cmt__AttributeId__c = vlocityAttr1.Id, // Link to matching attribute
            vlocity_cmt__IsHidden__c = true,
            vlocity_cmt__IsReadOnly__c = false,
            vlocity_cmt__Value__c = 'Mapped Value Test'
        );
        insert va;
        
        // Ensure that the Product2 query for existingAssignments can see the Vlocity Attribute Code
        // (This usually works because of the relationship fields, but we ensure the related data exists)
    }

    // --- Test 1: Successful Execution and Data Mapping ---
    @IsTest
    static void testBatchSuccessAndMapping() {
        
        List<Product2> products = [SELECT Id FROM Product2 WHERE vlocity_cmt__ProductSpecName__c = :PRODUCT_SPEC_NAME];
        List<CAT_AtInformativos__c> infoAttributes = [SELECT Id FROM CAT_AtInformativos__c];
        
        // Sanity Check: Expect 2 products * 2 attributes = 4 new assignments
        Integer expectedCount = products.size() * infoAttributes.size();

        Test.startTest();
        
        // Execute the batch class
        CATBatchAttributeCreation batchJob = new CATBatchAttributeCreation(PRODUCT_SPEC_NAME);
        Database.executeBatch(batchJob, 200); // Batch size 200 is fine for test

        Test.stopTest();
        
        // --- ASSERTIONS ---
        List<CAT_AsignacionAt__c> assignments = [
            SELECT Id, CAT_Producto__c, CAT_Atributo_Informativo__c, CAT_Oculto__c, 
                   CAT_Solo_lectura__c, CAT_Valor__c, CAT_Asignacion_activa__c 
            FROM CAT_AsignacionAt__c
        ];

        // 1. Assert Total Records Created
        System.assertEquals(expectedCount, assignments.size(), 'Should have created one assignment for every product/attribute pair.');
        
        // 2. Assert Success Mapping (Prod1 + Attr1 should have MAPPED data)
        Id prod1Id = products[0].Id;
        Id infoAttr1Id = infoAttributes[0].Id;

        // Find the record that should have been mapped
        CAT_AsignacionAt__c mappedAssignment = [
            SELECT CAT_Oculto__c, CAT_Solo_lectura__c, CAT_Valor__c, CAT_Asignacion_activa__c
            FROM CAT_AsignacionAt__c
            WHERE CAT_Producto__c = :prod1Id AND CAT_Atributo_Informativo__c = :infoAttr1Id
            LIMIT 1
        ];

        System.assertEquals(true, mappedAssignment.CAT_Oculto__c, 'CAT_Oculto__c should be true (mapped from Vlocity assignment).');
        System.assertEquals(false, mappedAssignment.CAT_Solo_lectura__c, 'CAT_Solo_lectura__c should be false (mapped from Vlocity assignment).');
        System.assertEquals('Mapped Value Test', mappedAssignment.CAT_Valor__c, 'CAT_Valor__c should be the Mapped Value.');
        System.assertEquals(true, mappedAssignment.CAT_Asignacion_activa__c, 'CAT_Asignacion_activa__c should be true when mapped.');


        // 3. Assert Default Mapping (Prod2 + Attr2 should have DEFAULT data, assuming Attr2 has a non-matching code)
        Id prod2Id = products[1].Id;
        Id infoAttr2Id = infoAttributes[1].Id; // This attribute code was not used in Vlocity Assignment

        // Find the record that should have been defaulted
        CAT_AsignacionAt__c defaultAssignment = [
            SELECT CAT_Oculto__c, CAT_Solo_lectura__c, CAT_Valor__c, CAT_Asignacion_activa__c
            FROM CAT_AsignacionAt__c
            WHERE CAT_Producto__c = :prod2Id AND CAT_Atributo_Informativo__c = :infoAttr2Id
            LIMIT 1
        ];

        // Assert the default values used in the ELSE block of your class
        System.assertEquals(false, defaultAssignment.CAT_Oculto__c, 'CAT_Oculto__c should be false (default value).');
        System.assertEquals(true, defaultAssignment.CAT_Solo_lectura__c, 'CAT_Solo_lectura__c should be true (default value).');
       // System.assertEquals('', defaultAssignment.CAT_Valor__c, 'CAT_Valor__c should be empty string (default value).');
        System.assertEquals(true, defaultAssignment.CAT_Asignacion_activa__c, 'CAT_Asignacion_activa__c should be true (default value).');
    }
    
        // --- Test 2: Handling Empty CAT_AtInformativos__c ---
        @IsTest
        static void testBatchNoInfoAttributes() {
            
            // Delete all CAT_AtInformativos__c records so infoAttributesMap will be empty
            delete [SELECT Id FROM CAT_AtInformativos__c];
            
            Test.startTest(); 
            CATBatchAttributeCreation batchJob = new CATBatchAttributeCreation(PRODUCT_SPEC_NAME);   
            // Explicitly call the start method and verify the return value is null.
            Database.QueryLocator result = batchJob.start(null);
            // The execution should not proceed.
            System.assertEquals(null, result, 'The start method should return null when CAT_AtInformativos__c records are not found.');
            Test.stopTest();
            
            // Assert that no records were created (the setup ensured products exist, but the lack of attributes aborted the process)
            System.assertEquals(0, [SELECT Count() FROM CAT_AsignacionAt__c], 'No assignments should be created if CAT_AtInformativos__c is empty.');
        }
    
    // --- Test 3: Handling Empty Product2 Scope ---
    @IsTest
    static void testBatchNoProduct2Scope() {
        // Set up a new test environment where no products match the criteria
        // (The TestSetup creates 2 matching products, so we delete them)
        delete [SELECT Id FROM Product2 WHERE vlocity_cmt__ProductSpecName__c = :PRODUCT_SPEC_NAME];
        
        Test.startTest();
        
        CATBatchAttributeCreation batchJob = new CATBatchAttributeCreation(PRODUCT_SPEC_NAME);
        // The start method will return null, and the execute method will not run.
        Database.executeBatch(batchJob, 200);

        Test.stopTest();
        
        // Assert that no records were created
        System.assertEquals(0, [SELECT Count() FROM CAT_AsignacionAt__c], 'No assignments should be created if Product2 scope is empty.');
    }
}