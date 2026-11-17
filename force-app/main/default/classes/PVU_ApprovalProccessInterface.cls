/*******************************************************************************
* Autor: hllanos
* Fecha: 2024-04-02
* Equipo: Pos-Ventas
* Descripcion: Interfaz para generar approval process

/**
 * NOTA DE SEGURIDAD: Se utiliza el keyword 'WITH SYSTEM_MODE' en las consultas a objetos 
 * de sistema (Group, CustomNotificationType). 
 * * Razón: Los usuarios estándar carecen de permisos sobre estos metadatos, 
 * lo que generaba el error INVOKE-200. 'WITH SYSTEM_MODE' ejecuta el query en modo sistema, permitiendo que el proceso administrativo 
 * continúe sin comprometer la seguridad del resto de la lógica.
 */

global with sharing class PVU_ApprovalProccessInterface implements vlocity_cmt.VlocityOpenInterface {
	class MyException extends Exception{}
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('approvalCaseDuplicadoIMEI')){
                Map<String, Object> response = createApproval(inputMap , outMap);
            }else{
                if (methodName.Equals('sendPushNotiToQueue')){
                    Map<String, Object> response = sendPushNotificationToQueue(inputMap , outMap);
                }
                if (methodName.Equals('sendPushNotiToUser')){
                    Map<String, Object> response = sendPushNotificationToUser(inputMap , outMap);
                } 
            }
        } catch(Exception ex) {
            outMap.put('error', ex.getMessage()); 
            outmap.put('isSuccess', false);
            result = false; 
        }
        return result;
    }
    
    global Map<String,Object> createApproval(Map<String,Object> inputMap, Map<String,Object> outMap){
        // Create an approval request
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Enviando solicitud para aprobación.');
        req1.setObjectId((String)inputMap.get('CaseId'));
        
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId() ); 
        
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId((String)inputMap.get('ApprovalProccessName'));
        req1.setSkipEntryCriteria(true);
        
        // user approver
        if(inputMap.get('NextApproverId') != null){
            List<String> myStringList = new List<String>{(String)inputMap.get('NextApproverId')};
        	req1.setNextApproverIds(myStringList);
        }
    	
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        outMap.put('isSuccess', result.isSuccess());
        outMap.put('error', result.getErrors());
        outMap.put('instanceId', result.getInstanceId());

        return outmap;
    }
    
    global Map<String,Object>  sendPushNotificationToQueue(Map<String,Object> inputMap, Map<String,Object> outMap){
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='CaseUpdate' WITH SYSTEM_MODE];
        
        List<GroupMember> members = new List<GroupMember>();
        try{
            if(Test.isRunningTest()){
                Group cola = [select Id from Group where Type = 'Queue' AND DeveloperNAME = 'PVU_CAV_Aguachica' WITH SYSTEM_MODE];
                GroupMember gm = new GroupMember(GroupId = cola.Id, UserOrGroupId = UserInfo.getUserId());
                members.add(gm);
            }else{
                members = [SELECT UserOrGroupId, GroupId, id FROM GroupMember WHERE Group.Name =:(String)inputMap.get('queueName') WITH SYSTEM_MODE LIMIT 50000];
            }
        }catch(Exception ex){
            system.debug('Error al generar notificaciones : ' + ex.getMessage()); 
            outMap.put('isSuccess', 'fail');
            outMap.put('error', 'cola sin miembros a notificar');
            return outMap;
        }
        
        // Create a new custom notification
        for(GroupMember member : members){
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle((String)inputMap.get('title'));
            notification.setBody((String)inputMap.get('body'));
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId((String)inputMap.get('targetId'));
            try {
                Set<String> recipentIds = new Set<String>();
                recipentIds.add(member.UserOrGroupId);
                notification.send(recipentIds);
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
                outMap.put('isSuccess', 'fail');
                outMap.put('error', 'Problem sending notification: ' + e.getMessage());
                return outMap;
            }
        }  
        outMap.put('isSuccess', 'ok');
        return outMap;
    }

    global Map<String,Object>  sendPushNotificationToUser(Map<String,Object> inputMap, Map<String,Object> outMap){
        // Get the Id for our custom notification type
        System.debug('prueba');
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='CaseUpdate' WITH SYSTEM_MODE];
        Case caso = [SELECT Id, CreatedById From Case WHERE Id =:(String)inputMap.get('caseId') WITH SECURITY_ENFORCED];
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
       
       	notification.setTitle((String)inputMap.get('title'));
       	notification.setBody((String)inputMap.get('body'));
       	notification.setNotificationTypeId(notificationType.Id);
       	notification.setTargetId((String)inputMap.get('caseId'));
       	System.debug('caso: ' +(String)inputMap.get('caseId'));
        Set<String> recipentIds = new Set<String>();
        recipentIds.add(caso.CreatedById);
        System.debug('caso: ' +(String)caso.CreatedById);
        notification.send(recipentIds);
        outMap.put('isSuccess', 'ok');
        return outMap;
        
    }
}