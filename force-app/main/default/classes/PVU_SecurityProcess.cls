/*--------------------------------------------------------------------------

Author:         Eduardo Wentancur 
Company:        Salesforce.com
Description:    Clase para verificar los procesos
Code Coverage:  100%
History
<Date>            <Author>             <Description>            			 <Version>
01-OCT-24         Eduardo Wentancur    Clase para verificar los procesos     inicial version            

----------------------------------------------------------------------------*/
global without sharing class PVU_SecurityProcess implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('getIsAccessTheProcess')) {
                getIsAccessTheProcess(inputMap, outMap, options);
            }else if(methodName.equals('getIsAccessTheProcessByPSG')) {
                getIsAccessTheProcessByPSG(inputMap, outMap, options);
            }else if(methodName.equals('getIsAccessTheProcessByCP')) {
                getIsAccessTheProcessByCP(inputMap, outMap, options);
            } else {
                result = false;
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;
        
    }

/*------------------------------------------------------------
    Author:		Luis Mendoza
    Company:		Salesforce.com
    Description:   	method to verify if can access the process cross
    IN:	inputMap		
    OUT: isAccess variable 			
    History
    <Date>      <Author>     <Description>
    15/05/2024   	Luis Mendoza	Initial Version
------------------------------------------------------------*/
public static void getIsAccessTheProcess(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {

    String compentName = (String) inputMap.get('compentName');
    Boolean isAccess = (Boolean) inputMap.get('isAccess');
    String userId = UserInfo.getUserId();
    List<String> permisoss = new List<String>();
    List<String> permissionSetGroupIdList = new List<String>();


    try {

        List<User> usr = [SELECT id, profile.name FROM User WHERE Id =:userId AND Profile.Name like '%Admin%' WITH SYSTEM_MODE];
        if (usr.size() == 0) {

            List<accesosProcesos__c> accesosProcesos  = [SELECT grupo_permisos__c FROM accesosProcesos__c WHERE Access__c = :isAccess AND Componente__c =:compentName WITH SYSTEM_MODE];
   
            for (accesosProcesos__c acc : accesosProcesos) {
             permisoss.add(acc.grupo_permisos__c);
            }
            System.debug('access result :::' + permisoss);
            
            List<PermissionSetGroup> permissionSetGroupList  = [SELECT developername, id FROM PermissionSetGroup WHERE DeveloperName IN : permisoss WITH SYSTEM_MODE];
            
            for (PermissionSetGroup permss : permissionSetGroupList) {
                permissionSetGroupIdList.add(permss.id);
             }
             
            System.debug('permissionSetGroupIdList result :::' + permissionSetGroupIdList);
            
            List<PermissionSetAssignment> permissionSetAssignmentList  = [SELECT permissionsetgroupid, assignee.name, id, assigneeid FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetGroupId IN :permissionSetGroupIdList WITH SYSTEM_MODE];
         
         
            Boolean isAccessProcess = permissionSetAssignmentList.size() > 0 ? true : false;
         
            outMap.put('isAccessProcess', isAccessProcess);
          
        }else {
            outMap.put('isAccessProcess', true);
        }


    } catch(Exception e) {
        System.debug('Error:: ' + e.getMessage() + ' ' + e.getCause() + ' ' + e.getLineNumber());
        outMap.put('code', '406');
        outMap.put('reason', e.getCause());
        outMap.put('message', e.getMessage());
        outMap.put('status', 'Failed');
    }

    outMap.remove('errorCode');
    outMap.remove('error');
    }
  

/*------------------------------------------------------------
    Author:		Luis Mendoza
    Company:		Salesforce.com
    Description:   	method to verify if can access the process for permission set group
    IN:	inputMap		
    OUT: isAccess variable 			
    History
    <Date>      <Author>     <Description>
    15/05/2024   	Luis Mendoza	Initial Version
------------------------------------------------------------*/
public static void getIsAccessTheProcessByPSG(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {

    Boolean isAccess = (Boolean) inputMap.get('isAccess');
    String userId = UserInfo.getUserId();
    List<String> permissionSetGroupIdList = new List<String>();
    Map<String,Object> mapIsAccessProcess = new Map<String,Object>();
    
    
    try {
        
            List<User> usr = [SELECT id, profile.name FROM User WHERE Id =:userId AND Profile.Name like '%Admin%' WITH SYSTEM_MODE LIMIT 1 ];
            
            System.debug('usr :::' + usr);

            List<PermissionSetAssignment> permissionSetAssignmentList  = [SELECT permissionsetgroupid, assignee.name, id, assigneeid, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = :userId WITH SYSTEM_MODE];
            
            for (PermissionSetAssignment permss : permissionSetAssignmentList) {
                permissionSetGroupIdList.add(permss.PermissionSetGroup.DeveloperName);
            }
            
            System.debug('permissionSetGroupIdList result :::' + permissionSetGroupIdList);

            List<accesosProcesos__c> accesosProcesos  = [SELECT grupo_permisos__c, Componente__c, IsActive__c, Access__c FROM accesosProcesos__c WHERE Grupo_Permisos__c IN :permissionSetGroupIdList WITH SYSTEM_MODE];
        	List<accesosProcesos__c> accesosProcesosAdm  = [SELECT Componente__c FROM accesosProcesos__c WITH SYSTEM_MODE];
                      
            System.debug('access result :::' + accesosProcesos);

            if (accesosProcesos.size() > 0) {
                
                for (accesosProcesos__c acc : accesosProcesos) {
                    mapIsAccessProcess.put(acc.Componente__c, acc.Access__c);
                   
                }
                
            }else{
                for (accesosProcesos__c acc : accesosProcesosAdm) {
                    mapIsAccessProcess.put(acc.Componente__c, true);
                   
                }
                
                mapIsAccessProcess.put('isAccessProcess', false);
            }
            Boolean isAdmin = usr.size() > 0 ? true : false;
            mapIsAccessProcess.put('isAdmin',isAdmin);
            
            outMap.put('accessProcess', mapIsAccessProcess);
          
       


    } catch(Exception e) {
        System.debug('Error:: ' + e.getMessage() + ' ' + e.getCause() + ' ' + e.getLineNumber());
        outMap.put('code', '406');
        outMap.put('reason', e.getCause());
        outMap.put('message', e.getMessage());
        outMap.put('status', 'Failed');
    }

    outMap.remove('errorCode');
    outMap.remove('error');

}


    /*******************************************************************************************************
    * @description retorna los custom permissions
    * @param input obtiene los parametros declarados
    * @param outMap Mapa que devuelve el resultado
    * @param options parámetros adicionales
    */
    public static void getIsAccessTheProcessByCP(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) 
    {
    	Boolean isAccess = (Boolean) inputMap.get('isAccess');
   		String userId = UserInfo.getUserId();
    	Map<String,Object> customPermissionList = new Map<String,Object>();
    
    	try {
        
        	List<User> usr = [SELECT id, profile.name FROM User WHERE Id =:userId AND Profile.Name like '%Admin%' WITH SYSTEM_MODE LIMIT 1 ];
        	// Consulta para obtener todas las Custom Permissions
        	List<CustomPermission> customPermission  = [SELECT id, DeveloperName FROM CustomPermission WITH SYSTEM_MODE];
        	// Verifica si el usuario tiene acceso a las Custom Permissions
            for (CustomPermission permss : customPermission) {
                Boolean hasPermission = FeatureManagement.checkPermission(permss.DeveloperName);
                if (hasPermission){
                    customPermissionList.put(permss.DeveloperName,hasPermission);
                }
            }
        	Boolean isAdmin = usr.size() > 0 ? true : false;
            if(isAdmin){
                customPermissionList.put('isAdmin',isAdmin);
                for (CustomPermission permss : customPermission) {
                	customPermissionList.put(permss.DeveloperName,isAdmin); 
            	}
            }
         	
         	outMap.put('accessProcess', customPermissionList);
      
    	} catch(Exception e) {
        	System.debug('Error:: ' + e.getMessage() + ' ' + e.getCause() + ' ' + e.getLineNumber());
        	outMap.put('code', '406');
        	outMap.put('reason', e.getCause());
        	outMap.put('message', e.getMessage());
        	outMap.put('status', 'Failed');
    	}

    	outMap.remove('errorCode');
    	outMap.remove('error');

	}

    /** ------------------------------------------------------------ */
    /**
     * Author:		Juan Pablo Rodríguez
     * Company:		ISalesforce.com
     * Description:   	Method for obtaining object-level access security 
     * IN:	List<String> sobjectsToValidate		
     * OUT: Schema.DescribeSObjectResult[]	
     * History
     * <Date>           <Author>                <Description>                                               <Version>
     * 18/12/2024   	Juan Pablo Rodríguez	Method for obtaining object-level access security           Initial Version
    **/
    /** ------------------------------------------------------------ */
    public static Schema.DescribeSObjectResult[] getAccessLabel(List<String> sobjectsToValidate) {
        Schema.DescribeSObjectResult[] descResults = Schema.describeSObjects(sobjectsToValidate);
        return descResults;
    }

    /** ------------------------------------------------------------ */
    /**
     * Author:		Juan Pablo Rodríguez
     * Company:		Salesforce.com
     * Description:   	Method to obtain files related to the record
     * IN:	String recordId, String sobjectType
     * OUT: Map<String, Object>
     * History
     * <Date>           <Author>                        <Description>                                           <Version>
     * 18/12/2024   	Juan Pablo Rodríguez	        Method to obtain files related to the record            Initial Version
    **/
    /** ------------------------------------------------------------ */
    public static Map<String, Object> getContentVersions(String recordId, String sobjectType) {
        List<String> sobjectTypes = new String[]{sobjectType};
        Boolean readOnlyPermission = false;
        Boolean editPermission = false;
        List<ContentVersion> contents = new List<ContentVersion>();
        Map<String, Object> answer = new Map<String, Object>();
        Set<Id> contentDocumentsIds=new Set<Id>(); 
        
        try {
            Schema.DescribeSObjectResult[] objectResults = getAccessLabel(sobjectTypes);
            for(Schema.DescribeSObjectResult objRes : objectResults) {
                if(objRes.isAccessible() && !objRes.isCreateable() && !objRes.isUpdateable()) { readOnlyPermission = true; }
                else if(objRes.isAccessible() && (objRes.isCreateable() || objRes.isUpdateable())) { editPermission = true; }
            }
            contents = [SELECT Id, Title, ContentDocumentId, FileType, ContentSize, FileExtension, VersionNumber, CreatedDate, VersionData, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :recordId WITH SYSTEM_MODE ORDER BY CreatedDate DESC];
            if(contents.isEmpty()){
                List<ContentDocumentLink> contentLink= [SELECT Id, ContentDocumentId,LinkedEntityId FROM ContentDocumentLink  WHERE LinkedEntityId  =:recordId WITH SYSTEM_MODE];
                for(ContentDocumentLink cdl:contentLink){
                    contentDocumentsIds.add(cdl.ContentDocumentId);
                }
                if(!contentLink.isEmpty()){
                    contents = [SELECT Id, Title, ContentDocumentId, FileType, ContentSize, FileExtension, VersionNumber, CreatedDate, VersionData, FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentsIds WITH SYSTEM_MODE ORDER BY CreatedDate DESC];
                }    
            }
            
            
            answer.put('data', contents);

            System.debug('Data');
            System.debug(answer);
            if(!readOnlyPermission || editPermission) {
                answer.put('isReadOnlyPermission', readOnlyPermission);
                answer.put('isEditPermission', editPermission);
                answer.put('message', 'Registros de arhivos consultados exitosamente.');
            } else {
                answer.put('isReadOnlyPermission', readOnlyPermission);
                answer.put('isEditPermission', editPermission);
                answer.put('message', 'No posee los niveles de permisos necesarios para leer los archivos, contacte a su administrador.');
            }
        } catch(Exception ex) {             
 		throw ex;}
        
        return answer;
    }
    
    
    /** ------------------------------------------------------------ */
    /**
     * Author:		Ángeles Pérez - maria.perez@nespon.com
     * Company:		Nespon
     * Description:   	Method to obtain files related to the record
     * IN:	String recordId, String sobjectType
     * OUT: Map<String, Object>
     * History
     * <Date>           <Author>                        <Description>                                           <Version>
     * 17/09/2025    María Ángeles Pérez         Method to obtain files related to the record               Initial Version
    **/
    /** ------------------------------------------------------------ */
    public static Map<String, Object> getContentVersionsFromCDL(String recordId, String sobjectType) {
        List<String> sobjectTypes = new String[]{sobjectType};
        Boolean readOnlyPermission = false;
        Boolean editPermission     = false;
        Map<String, Object> answer = new Map<String, Object>();
        
        try {
            Schema.DescribeSObjectResult[] objectResults = getAccessLabel(sobjectTypes);
            for (Schema.DescribeSObjectResult objRes : objectResults) {
                if (objRes.isAccessible() && !objRes.isCreateable() && !objRes.isUpdateable()) readOnlyPermission = true;
                else if (objRes.isAccessible() && (objRes.isCreateable() || objRes.isUpdateable())) editPermission = true;
            }
        
            List<ContentDocumentLink> links = [ SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId
                                                FROM   ContentDocumentLink
                                                WHERE  LinkedEntityId = :recordId
                                                WITH SYSTEM_MODE
                                            ];
            Set<Id> versionIds = new Set<Id>();
            for (ContentDocumentLink l : links) {
                if (l.ContentDocument.LatestPublishedVersionId != null) {
                    versionIds.add(l.ContentDocument.LatestPublishedVersionId);
                }
            }
            List<ContentVersion> contents = versionIds.isEmpty() ? new List<ContentVersion>()
                : [SELECT Id, Title, FileExtension, ContentDocumentId, CreatedDate
                   FROM   ContentVersion
                   WHERE  Id IN :versionIds
                   WITH SYSTEM_MODE
                   ORDER  BY CreatedDate DESC];

            answer.put('data', contents);

            System.debug('Data');
            System.debug(answer);
            if(!readOnlyPermission || editPermission) {
                answer.put('isReadOnlyPermission', readOnlyPermission);
                answer.put('isEditPermission', editPermission);
                answer.put('message', 'Registros de arhivos consultados exitosamente.');
            } else {
                answer.put('isReadOnlyPermission', readOnlyPermission);
                answer.put('isEditPermission', editPermission);
                answer.put('message', 'No posee los niveles de permisos necesarios para leer los archivos, contacte a su administrador.');
            }
        } catch(Exception ex) {             
 		throw ex;}
        
        return answer;
	}


}