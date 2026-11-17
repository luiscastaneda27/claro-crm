/**
 * Batch Apex class to clean up vlocity_cmt__AttributeAssignment__c records,
 * accepting the Product Specification Name and Object Class Name via constructor.
 */
public with sharing class VlocityAttAssignmentCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Global variables to hold the input values and data queried in start
    private Set<Id> validAttributeIds = new Set<Id>();
    private final String productSpecName;      // Holds 'Accesorios PS'
    private final String objectClassName;      // Holds 'OT Accesorios'

    // --- CONSTRUCTOR: Accepts the non-hardcoded values ---
    public VlocityAttAssignmentCleanupBatch(String prodSpecName, String objClassName) {
        this.productSpecName = prodSpecName;
        this.objectClassName = objClassName;
    }

    // --- 1. START Method: Identify Valid Attributes and Define Deletion Scope ---
    public Database.QueryLocator start(Database.BatchableContext bc) {

        // --- Step 1 & 2: Get Valid Attributes from Object Class ---
        // 1. Obtain the Object Class ID using the input variable
        vlocity_cmt__ObjectClass__c objectClass = [
            SELECT Id
            FROM vlocity_cmt__ObjectClass__c
            WHERE Name = :this.objectClassName // USE VARIABLE HERE
            WITH USER_MODE
            LIMIT 1
        ];

        if (objectClass == null) {
            System.debug('PROCESS ABORTED: Object Class "' + this.objectClassName + '" not found.');
            return null;
        }

        // 2. Obtain the Attribute Assignments associated with that Object Class
        List<vlocity_cmt__AttributeAssignment__c> validClassAssignments = [
            SELECT vlocity_cmt__AttributeId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__ObjectId__c = :objectClass.Id
            AND vlocity_cmt__AttributeId__c != NULL
            WITH USER_MODE
        ];

        // Populate the set of VALID Attribute IDs
        for (vlocity_cmt__AttributeAssignment__c assignment : validClassAssignments) {
            this.validAttributeIds.add(assignment.vlocity_cmt__AttributeId__c);
        }
        System.debug('Batch Start: Identified ' + this.validAttributeIds.size() + ' valid Attribute IDs.');
        
        if (this.validAttributeIds.isEmpty()) {
            System.debug('PROCESS ABORTED: Object Class "' + this.objectClassName + '" has no valid attribute assignments.');
            return null;
        }


        // --- Step 3 & 4: Define Deletion Scope (Assignments linked to target Product2 records) ---
        
        // 3. Obtain the list of target Product2 IDs using the input variable
        Set<Id> targetProductIds = new Set<Id>();
        for (Product2 prod : [
            SELECT Id 
            FROM Product2 
            WHERE vlocity_cmt__ProductSpecName__c = :this.productSpecName // products that have the PS assigned
            OR Name = :this.productSpecName // the PS itself
            WITH USER_MODE
        ]) {
            targetProductIds.add(prod.Id);
        }

        if (targetProductIds.isEmpty()) {
            System.debug('PROCESS ABORTED: No Product2 records found for ProductSpecName: ' + this.productSpecName);
            return null;
        }

        // 4. Set the scope to iterate over all Attribute Assignments related to these target products
        return Database.getQueryLocator([
            SELECT Id, vlocity_cmt__AttributeId__c, vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__ObjectId__c IN :targetProductIds
            AND vlocity_cmt__AttributeId__c != NULL
            WITH USER_MODE
        ]);
    }

    // --- 2. EXECUTE Method (Remains the same as logic only uses validAttributeIds) ---
    public void execute(Database.BatchableContext bc, List<vlocity_cmt__AttributeAssignment__c> scope) {

        List<vlocity_cmt__AttributeAssignment__c> assignmentsToDelete = new List<vlocity_cmt__AttributeAssignment__c>();
        
        for (vlocity_cmt__AttributeAssignment__c currentAssignment : scope) {
            
            Id attributeId = currentAssignment.vlocity_cmt__AttributeId__c;

            // Check if the current assignment's Attribute ID is NOT in the list of valid IDs
            if (!this.validAttributeIds.contains(attributeId)) { // Use 'this' reference to global variable
                assignmentsToDelete.add(currentAssignment);
            }
        }
        
        if (!assignmentsToDelete.isEmpty()) {
            try {
                delete as user assignmentsToDelete;
                System.debug('SUCCESS: Deleted ' + assignmentsToDelete.size() + ' obsolete Attribute Assignments in this batch.');
            } catch (DmlException e) {
                System.debug('DML Error deleting assignments: ' + e.getMessage());
            }
        }
    }

    // --- 3. FINISH Method ---
    public void finish(Database.BatchableContext bc) {
        System.debug('Vlocity Attribute Assignment Cleanup Batch finished.');
    }
}