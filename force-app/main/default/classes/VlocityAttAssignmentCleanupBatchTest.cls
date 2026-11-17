@IsTest
private class VlocityAttAssignmentCleanupBatchTest {

    private static final String TEST_PROD_SPEC = 'Accesorios PS';
    private static final String TEST_OBJ_CLASS = 'OT Accesorios';
    
    // Attribute IDs to be used across the test methods
    private static Id validAttrId;
    private static Id obsoleteAttrId;
    private static Id targetProductId;
    
    // --- Test Setup Method ---
    @TestSetup
    static void setupTestData() {
        
        // 1. Create Vlocity Attribute Categories
        List<vlocity_cmt__AttributeCategory__c> attrCategories = new List<vlocity_cmt__AttributeCategory__c>{
            new vlocity_cmt__AttributeCategory__c(Name = 'Cat Atributo', vlocity_cmt__Description__c = 'Descripción Cat Atributo', vlocity_cmt__DisplaySequence__c = 1)
        };
            insert attrCategories;
        // 2.  Create Vlocity Attributes
        vlocity_cmt__Attribute__c attrValid = new vlocity_cmt__Attribute__c(Name = 'ValidAttr', vlocity_cmt__Code__c = 'VA',vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id);
        vlocity_cmt__Attribute__c attrObsolete = new vlocity_cmt__Attribute__c(Name = 'ObsoleteAttr', vlocity_cmt__Code__c = 'OA',vlocity_cmt__AttributeCategoryId__c = attrCategories[0].Id);
        insert new List<vlocity_cmt__Attribute__c>{attrValid, attrObsolete};
        validAttrId = attrValid.Id;
        obsoleteAttrId = attrObsolete.Id;

        // 2. Create Object Class (The source of truth for valid attributes)
        vlocity_cmt__ObjectClass__c objClass = new vlocity_cmt__ObjectClass__c(Name = TEST_OBJ_CLASS,vlocity_cmt__ObjectApiName__c = 'Product2');
        insert objClass;

        // 3. Create Assignment linking ONLY the Valid Attribute to the Object Class
        vlocity_cmt__AttributeAssignment__c classAssignment = new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = objClass.Id, // ObjectClass is the owner
            vlocity_cmt__AttributeId__c = validAttrId 
        );
        insert classAssignment;
        
        // 4. Create Target Product (The scope of the batch)
        Product2 prodAccesorios = new Product2 (Name='Accesorios PS', ProductCode = 'B2C-MOV-PRD-TEC-PS', Family = 'Device', vlocity_cmt__Type__c = 'Tech', vlocity_cmt__SpecificationType__c = 'Product');
        insert prodAccesorios;
        Product2 targetProd = new Product2(
            Name = 'Target Product',
            ProductCode = 'TGT001',
            vlocity_cmt__ProductSpecId__c = prodAccesorios.Id
        );
        insert targetProd;
        targetProductId = targetProd.Id;

        // 5. Create Attribute Assignments on the Product (The records to be processed/deleted)
        List<vlocity_cmt__AttributeAssignment__c> productAssignments = new List<vlocity_cmt__AttributeAssignment__c>();

        // A. Assignment that MUST BE KEPT (uses a VALID attribute)
        productAssignments.add(new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = targetProductId,
            vlocity_cmt__AttributeId__c = validAttrId 
        ));

        // B. Assignment that MUST BE DELETED (uses an OBSOLETE attribute)
        productAssignments.add(new vlocity_cmt__AttributeAssignment__c(
            vlocity_cmt__ObjectId__c = targetProductId,
            vlocity_cmt__AttributeId__c = obsoleteAttrId 
        ));
        
        insert productAssignments;
    }

    // --- Test 1: Successful Cleanup and Deletion ---
    @IsTest
    static void testSuccessfulCleanupAndDeletion() {
        
        // 1. Retrieve the critical IDs from the database to ensure they are available in the test context
        // This retrieval helps solidify the data state before the batch starts.
        Id validAttrId = [SELECT Id FROM vlocity_cmt__Attribute__c WHERE Name ='ValidAttr'].Id;
        Id obsoleteAttrId = [SELECT Id FROM vlocity_cmt__Attribute__c WHERE Name ='ObsoleteAttr'].Id;
        Product2 productToQuery = [SELECT Id FROM Product2 WHERE vlocity_cmt__ProductSpecName__c = :TEST_PROD_SPEC LIMIT 1];
        Id targetProductId = productToQuery.Id;
        vlocity_cmt__AttributeAssignment__c assignmentToDelete = [
            SELECT vlocity_cmt__AttributeId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__ObjectId__c = :targetProductId 
            AND vlocity_cmt__AttributeId__c = :obsoleteAttrId 
            //LIMIT 1
        ];
        
        // Initial Count Check: 
        // Expect 2 assignments on the product + 1 assignment on the ObjectClass = 3
        System.assertEquals(3, [SELECT COUNT() FROM vlocity_cmt__AttributeAssignment__c], 'Pre-check failed: Should have 3 total assignments before execution.');
    
        Test.startTest();
        
        // Initialize the batch with setup parameters
        VlocityAttAssignmentCleanupBatch batchJob = new VlocityAttAssignmentCleanupBatch(TEST_PROD_SPEC, TEST_OBJ_CLASS);
        Database.executeBatch(batchJob, 200);
    
        Test.stopTest();
        
        // --- ASSERTIONS ---
        
        // 1. Assert Final Count: 1 (valid product assignment) + 1 (object class assignment) = 2
        List<vlocity_cmt__AttributeAssignment__c> remainingAssignments = [
            SELECT Id, vlocity_cmt__AttributeId__c, vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c
        ];
    
        System.assertEquals(2, remainingAssignments.size(), 'Only the valid product assignment and the object class assignment should remain.');
        
        // 2. Assert that the correct assignment was kept (the one linked to validAttrId)
        vlocity_cmt__AttributeAssignment__c keptAssignment = [
             SELECT Id, vlocity_cmt__AttributeId__c
             FROM vlocity_cmt__AttributeAssignment__c
             WHERE vlocity_cmt__ObjectId__c = :targetProductId
             LIMIT 1
        ];
        
        System.assertEquals(validAttrId, keptAssignment.vlocity_cmt__AttributeId__c, 'The remaining assignment on the product must be linked to the valid attribute.');
    }

    /*
    // --- Test 2: Abort due to Object Class Not Found ---
    @IsTest
    static void testAbortNoObjectClass() {
        
        // Use a non-existent Object Class name
        VlocityAttAssignmentCleanupBatch batchJob = new VlocityAttAssignmentCleanupBatch(TEST_PROD_SPEC, 'NON_EXISTENT_CLASS');
        
        Test.startTest();
        
        // Explicitly call the start method to check the abort condition
        Database.QueryLocator result = batchJob.start(null);

        Test.stopTest();
        
        // Assert that the start method returned null
        System.assertEquals(null, result, 'Start should return null when Object Class is not found.');
        
        // Assert no DML occurred
        System.assertEquals(3, [SELECT COUNT() FROM vlocity_cmt__AttributeAssignment__c], 'No assignments should have been deleted.');
    }
*/
    // --- Test 3: Abort due to No Target Products Found ---
    @IsTest
    static void testAbortNoTargetProducts() {
        
        // Use a non-existent Product Spec Name
        VlocityAttAssignmentCleanupBatch batchJob = new VlocityAttAssignmentCleanupBatch('NON_EXISTENT_SPEC', TEST_OBJ_CLASS);
        
        Test.startTest();
        
        // Explicitly call the start method to check the abort condition
        Database.QueryLocator result = batchJob.start(null);

        Test.stopTest();
        
        // Assert that the start method returned null
        System.assertEquals(null, result, 'Start should return null when no target Product2 records are found.');
    }
}