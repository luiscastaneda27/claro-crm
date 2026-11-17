/*---------------------------------------------------------------------------------------------------------------
Autor: Nahir Arrejoria 
Fecha: 2025-09-12
Equipo: Catálogo
Descripcion: Clase para crear masivamente los atributos técnicos para cada uno de los product specifications
Code Coverage: N/A
History
<Date>			<Author>			<Description>						<Version>
2025-12-16		Nahir Arrejoria		Versión Inicial						01
2026-01-19      Nahir Arrejoria     Mod para considerar multiples PS  	02
2026-01-21      Nahir Arrejoria     Validación para evitar duplicados  	02.1
----------------------------------------------------------------------------------------------------------------*/
public with sharing class CATBatchAttributeCreation implements Database.Batchable<SObject>, Database.Stateful {
    
    // Global member variable to store the input Product Specification Name
    private final String productSpecName;
    
    // Global variables to hold data queried in the start method (Stateful for sharing data across execute blocks)
    private Map<Id, CAT_Atinformativos__c> infoAttributesMap;
    private Map<String, vlocity_cmt__AttributeAssignment__c> vlocityAssignmentMap;

    // --- CONSTRUCTOR: Accepts the Product Specification Name ---
    public CATBatchAttributeCreation(String productSpecName) {
        this.productSpecName = productSpecName;
    }

    // --- 1. START Method: Prepare Data and Query Scope ---
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // --- 2. Pre-query Supporting Data (CAT_AtInformativos__c) ---
        String searchKey = '%' + this.productSpecName + '%';
        List<CAT_AtInformativos__c> infoAttributes = [
            SELECT Id, Name, CAT_Codigo__c
            FROM CAT_AtInformativos__c WHERE CAT_Product_Spec__c LIKE :searchKey
            WITH USER_MODE
        ];
        
        if (infoAttributes.isEmpty()) {
            System.debug('No CAT_AtInformativos__c records found. Exiting batch.');
            return null;
        }

        infoAttributesMap = new Map<Id, CAT_AtInformativos__c>(infoAttributes);
        System.debug('Batch Start: Mapped ' + infoAttributesMap.size() + ' CAT_AtInformativos__c records.');
        // --- 3. Query Vlocity Assignments to Map Values ---
        List<Product2> scopeProducts = [
            SELECT Id, ProductCode 
            FROM Product2
            WHERE vlocity_cmt__ProductSpecName__c = :this.productSpecName
            WITH SECURITY_ENFORCED
        ];
        System.debug('Batch Start: Mapped ' + scopeProducts.size() + ' product2 records.');
        
        Set<Id> productIds = new Map<Id, Product2>(scopeProducts).keySet();

        List<vlocity_cmt__AttributeAssignment__c> existingAssignments = [
            SELECT Id, vlocity_cmt__ObjectId__c, vlocity_cmt__IsHidden__c, 
                   vlocity_cmt__IsReadOnly__c, vlocity_cmt__Value__c,
                   vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c
            FROM vlocity_cmt__AttributeAssignment__c 
            WHERE vlocity_cmt__ObjectId__c IN :productIds
            WITH USER_MODE
        ];
        
        vlocityAssignmentMap = new Map<String, vlocity_cmt__AttributeAssignment__c>();
        for (vlocity_cmt__AttributeAssignment__c va : existingAssignments) {
            String key = va.vlocity_cmt__ObjectId__c + '_' + va.vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c;
            vlocityAssignmentMap.put(key, va);
        }
        System.debug('Batch Start: Mapped ' + vlocityAssignmentMap.size() + ' Vlocity assignments for lookups.');


        // --- Define Query Scope ---
        // Use the input variable in the WHERE clause
        return Database.getQueryLocator([
            SELECT Id, ProductCode, Name 
            FROM Product2 
            WHERE vlocity_cmt__ProductSpecName__c = :this.productSpecName // Using the input variable
            WITH USER_MODE
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Product2> scope) {
        
        List<CAT_AsignacionAt__c> assignmentsToInsert = new List<CAT_AsignacionAt__c>();
        Set<Id> scopeProductIds = new Map<Id, Product2>(scope).keySet();

        // VALIDATION: Query existing assignments using the CODE instead of the ID
        List<CAT_AsignacionAt__c> existingCustomAssignments = [
            SELECT Id, CAT_Producto__c, CAT_Atributo_Informativo__r.CAT_Codigo__c
            FROM CAT_AsignacionAt__c
            WHERE CAT_Producto__c IN :scopeProductIds
            WITH USER_MODE
        ];

        // Create a unique key (ProductID_AttributeCode) to track existing records
        Set<String> existingRecordsKeys = new Set<String>();
        for(CAT_AsignacionAt__c existing : existingCustomAssignments) {
            String code = existing.CAT_Atributo_Informativo__r.CAT_Codigo__c;
            existingRecordsKeys.add(existing.CAT_Producto__c + '_' + code);
        }

        for (Product2 prod : scope) {
            for (CAT_AtInformativos__c attr : infoAttributesMap.values()) {
                
                // Key Validation: Use CAT_Codigo__c to identify duplicates
                String uniqueKey = prod.Id + '_' + attr.CAT_Codigo__c;
                if (existingRecordsKeys.contains(uniqueKey)) {
                    continue; // Skip if this product already has a record for this attribute code
                }

                CAT_AsignacionAt__c newAssignment = new CAT_AsignacionAt__c();
                newAssignment.CAT_Producto__c = prod.Id; 
                newAssignment.CAT_Atributo_Informativo__c = attr.Id; 
                newAssignment.Name = prod.ProductCode + '-' + attr.Name;

                String lookupKey = prod.Id + '_' + attr.CAT_Codigo__c;
                vlocity_cmt__AttributeAssignment__c matchingVlocityAssignment = vlocityAssignmentMap.get(lookupKey);

                if (matchingVlocityAssignment != null) {
                    newAssignment.CAT_Oculto__c = matchingVlocityAssignment.vlocity_cmt__IsHidden__c;
                    newAssignment.CAT_Solo_lectura__c = matchingVlocityAssignment.vlocity_cmt__IsReadOnly__c;
                    newAssignment.CAT_Valor__c = matchingVlocityAssignment.vlocity_cmt__Value__c;
                    newAssignment.CAT_Asignacion_activa__c = true; 
                } else {
                    newAssignment.CAT_Asignacion_activa__c = true;
                    newAssignment.CAT_Oculto__c = false;
                    newAssignment.CAT_Solo_lectura__c = true;
                    newAssignment.CAT_Valor__c = '';
                }
                
                assignmentsToInsert.add(newAssignment);
                // Track the code for this chunk to prevent internal duplicates
                existingRecordsKeys.add(uniqueKey);
            }
        }

        if (!assignmentsToInsert.isEmpty()) {
            insert as user assignmentsToInsert;
        }
    }

    // --- 3. FINISH Method: Final Actions ---
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process for Product Assignments has completed.');
    }

}