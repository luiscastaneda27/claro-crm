public class FVU_UserTriggerHandler {

    private static final String NAME_OBJECT = 'User'; // Object API name.
    private static final List<String> TRACKING_FIELDS = getFieldsAudit();

    private static List<String> getFieldsAudit() {

        List<String> fields = new List<String>();
        List<FVU_AuditField__c>  auditFields = FVU_AuditField__c.getAll().values();

        for(FVU_AuditField__c auditField: auditFields){
            if(auditField.FVU_ObjectName__c == NAME_OBJECT){
                fields.add(auditField.FVU_FieldName__c);    
            }
        }

        return fields;
    }
        
    public static void afterInsertUser(List<User> newUser){
        try {
            List<FVU_User_History__c> listUserHistory = new List<FVU_User_History__c>();
        
            for(User currentUser :newUser){
                Map<String, Object> userNewMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(currentUser));
                
                for(String field :TRACKING_FIELDS){
                    if(userNewMap.containsKey(field) && userNewMap.get(field) != null){
                        FVU_User_History__c userChange = new FVU_User_History__c();
                        userChange.FVU_Date__c = System.now();
                        userChange.FVU_Field__c = field;
                        userChange.FVU_User__c = currentUser.Id;
                        userChange.FVU_UserModifiedBy__c = currentUser.LastModifiedById;
                        userChange.FVU_New_Value__c = String.valueOf(userNewMap.get(field));
                        
                        listUserHistory.add(userChange);
                    }
                }
            }
            
            if(!listUserHistory.isEmpty()){
                insert as user listUserHistory;
            }
        } catch (Exception e) {
            System.debug('Exception in the creation of the audit record: ' + e.getMessage());
        }
    }
    
    public static void afterUpdateUser(List<User> newUser, Map<Id,User> mapOldUser){
        try {
            List<FVU_User_History__c> listUserHistory = new List<FVU_User_History__c>();
            
            for(User currentUser :newUser){
                Map<String, Object> userNewMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(currentUser));
                Map<String, Object> userOldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(mapOldUser.get(currentUser.Id)));
                
                for(String field :TRACKING_FIELDS){
                    if(userNewMap.containsKey(field) && userNewMap.get(field) != userOldMap.get(field)){
                        FVU_User_History__c userChange = new FVU_User_History__c();
                        userChange.FVU_Date__c = System.now();
                        userChange.FVU_Field__c = field;
                        userChange.FVU_User__c = currentUser.Id;
                        userChange.FVU_UserModifiedBy__c = currentUser.LastModifiedById;
                        userChange.FVU_Original_Value__c = String.valueOf(userOldMap.get(field));
                        userChange.FVU_New_Value__c = String.valueOf(userNewMap.get(field));
                        
                        listUserHistory.add(userChange);
                    }
                }
            }
            
            if(!listUserHistory.isEmpty()){
                insert as user listUserHistory;
            }
        } catch (Exception e) {
            System.debug('Exception in the update of the audit record: ' + e.getMessage());
        }
    }
}