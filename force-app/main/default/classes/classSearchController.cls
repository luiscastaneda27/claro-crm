/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 06-04-2024
 * @last modified by  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   02-13-2024   SALESFORCE   Initial Version
 * 1.1   05-06-2024   SALESFORCE                                            - Se agrega el filtrado por el tipo de Objeto. 
**/



public with sharing class classSearchController {
        @AuraEnabled(cacheable=true)
        public static Map<String, accesoWrapper> getObjectList(Id recordId) {  
            String ObjName = recordId.getSObjectType().getDescribe().getName();
            Map<String, accesoWrapper> accesosMap = new Map<String, accesoWrapper>(); 
            List<accesosProcesos__c> lstAccesos = new List<accesosProcesos__c>();
            String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
                        
            if(userProfileName == 'System Administrator' || userProfileName == 'Administrador de Sistema' || userProfileName == 'Administrador del sistema'){
                try {
                    lstAccesos = [SELECT Canal__c, Componente__c, Tipo__c, Descripcion__c,Grupo_Permisos__c ,DetalleComponente__c,Objetivo__c from accesosProcesos__c 
                                    WHERE IsActive__c = true 
                                    AND ObjectName__c =:ObjName 
                                    AND Tipo__c IN('OmniScript','FLOW') ]; 
                } catch (Exception e) {
                    System.debug('ERROR AL TRAER EL OBJETO DE LOS ACCESOS PARA USER ADMIN: ' + e.getmessage());
                }
                 
            }else{
                try {
                    lstAccesos = [SELECT Canal__c, Componente__c, Tipo__c, Descripcion__c,Grupo_Permisos__c ,DetalleComponente__c,Objetivo__c from accesosProcesos__c 
                    WHERE Grupo_Permisos__c IN:viewPerpissionsGroups() AND 
                    IsActive__c = true 
                    AND Access__c = true
                    AND ObjectName__c =:ObjName 
                    AND Tipo__c IN('OmniScript','FLOW')];
                } catch (Exception e) {
                    System.debug('ERROR AL TRAER EL OBJETO DE LOS ACCESOS PARA LOS GRUPOS DE PERMISOS DEL USUARIO: ' + e.getmessage());
                } 
            }

                for (accesosProcesos__c s : lstAccesos) {                   
                    accesoWrapper o = new accesoWrapper();
                    o.nombre = s.Componente__c;
                    o.label = s.DetalleComponente__c + ': ' + s.Descripcion__c;
                    o.tipo = s.Tipo__c;
                    o.objetivo = s.Objetivo__c;
                    o.apiNameObj = s.DetalleComponente__c;
                    o.grupoPermisos = s.Grupo_Permisos__c;
                    system.debug('OBJETO::::' + o);                    
                    accesosMap.put(o.label, o);

                } 
                return accesosMap;    
        }
    

        /**
        * @description Metodo que retorna una lista de los nombre de los PSG ligados al usuario. 
        * @author SALESFORCE | 02-26-2024 
        * @return List<String> 
        **/
        public static List<String> viewPerpissionsGroups(){
            String userId = UserInfo.getUserId();          
           
            // Consultar los conjuntos de permisos asignados al usuario
            List<String> lstPsgGroup = new List<String>();
            List<PermissionSetAssignment> permissionSetAssignments = [  SELECT  
                                                                        PermissionSetGroup.DeveloperName
                                                                        FROM PermissionSetAssignment
                                                                        WHERE AssigneeId = :userId AND PermissionSetGroup.DeveloperName <> null            
            ];

            // Iterar a través de los conjuntos de permisos asignados
           for (PermissionSetAssignment psa : permissionSetAssignments) {
                String namePermissionSetGroup = psa.PermissionSetGroup.DeveloperName;
                lstPsgGroup.add(namePermissionSetGroup);
            }
            return lstPsgGroup;
        }
    
        public class accesoWrapper{
            @AuraEnabled public String nombre {get; set;} 
            @AuraEnabled public String tipo {get; set;} 
            @AuraEnabled public String label {get; set;}
            @AuraEnabled public String objetivo {get; set;}
            @AuraEnabled public String grupoPermisos {get; set;}
            @AuraEnabled public String apiNameObj {get; set;}

        }
}