public with sharing class DeletePermissionSetAssignmentsBatch implements Database.Batchable<SObject> {

    private List<String> psgs;
    public DeletePermissionSetAssignmentsBatch(List<String> psgs){
        this.psgs = psgs;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName IN :psgs
            AND PermissionSetGroup.Status = 'Updated' WITH SECURITY_ENFORCED
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            delete scope;
        } catch (DmlException e) {
            System.debug('Error deleting records: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Batch Process Completed Successfully.');
    }
}