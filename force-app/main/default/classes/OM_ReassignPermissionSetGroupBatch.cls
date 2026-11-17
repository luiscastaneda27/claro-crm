/**
 * @Autor         : Gabriel Alvis
 * @Empresa       : Salesforce.com
 * @Descripción   : Realiza la reasignación del esquema de permisos R4 de OM al esquema R5
 * @Test          : OM_ReassignPermissionSetGroupBatchTest
 * 
 * Ver   Fecha        Autor           Modificación
 * 1.0   2025-05-28   Gabriel Alvis   Versión inicial - HDU 550805
**/

public with sharing class OM_ReassignPermissionSetGroupBatch implements Database.Batchable<SObject>, Database.Stateful{
    private Boolean isTest = false;
    private List<PermissionSetGroup> lstPSGOM = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE DeveloperName IN ('OM_Backoffice', 'OM_Estandar', 'OM_Supervisor')
        WITH SECURITY_ENFORCED
        ORDER BY DeveloperName
    ];
    private List<User> lstAdmUser = new List<User>();

    public OM_ReassignPermissionSetGroupBatch(Boolean isTest){
        this.isTest = isTest;
    }

    /**
    * @description Realiza consulta para obtener los usuarios por actualizar permisos
    * @param batchContext Información del contexto de ejecución
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {
        String query = 
            'SELECT Id, AssigneeId, Assignee.AboutMe, PermissionSetGroup.DeveloperName ' +
            'FROM PermissionSetAssignment ' +
            'WHERE (PermissionSetGroup.DeveloperName IN (\'SFI_OMRuntimeUser\', \'OM_Backoffice\') OR Assignee.AboutMe = \'En migración a nuevo Permission Set Group\') ' +
            'AND   Assignee.IsActive = true ' +
            (isTest ? 'AND Assignee.Username = \'apextestuser@clarosfi.com.co\'' : '');

        return Database.getQueryLocator(query);
    } 

    /**
    * @description Procesa un bloque de registros de usuario en una transacción separada y con límites asíncronos de APEX
    * @param batchContext Información del contexto de ejecución
    * @param lstAssignments Lista de Usuarios a procesar
    **/
    public void execute(Database.BatchableContext batchContext, List<PermissionSetAssignment> lstAssignments) {
        List<PermissionSetAssignment> lstAssignmentsToDelete = new List<PermissionSetAssignment>();
        Set<PermissionSetAssignment> setAssignmentsToAdd = new Set<PermissionSetAssignment>();
        Set<Id> setUserIds = new Set<Id>();
        Map<Id, User> mapAdmUserBatch = new Map<Id, User>();

        for (PermissionSetAssignment psa : lstAssignments) {
            setUserIds.add(psa.AssigneeId);
            // Añade PSG OM Estándar
            setAssignmentsToAdd.add(new PermissionSetAssignment(PermissionSetGroupId = lstPSGOM[1].Id, AssigneeId = psa.AssigneeId));
            // El PSG SFI_OMRuntimeUser es obsoleto por esto se debe eliminar
            if(psa.PermissionSetGroup.DeveloperName == 'SFI_OMRuntimeUser'){
                lstAssignmentsToDelete.add(psa);
            }
            // Los usuarios OM Supervisor fueron migrados de un PSG obsoleto y marcados con un mensaje en el campo AboutMe del User
            if(psa.Assignee.AboutMe == 'En migración a nuevo Permission Set Group'){
                setAssignmentsToAdd.add(new PermissionSetAssignment(AssigneeId = psa.AssigneeId, PermissionSetGroupId = lstPSGOM[0].Id));
                setAssignmentsToAdd.add(new PermissionSetAssignment(AssigneeId = psa.AssigneeId, PermissionSetGroupId = lstPSGOM[2].Id));
                mapAdmUserBatch.put(psa.AssigneeId, new User(Id = psa.AssigneeId, AboutMe = null));
            }
        }

        // Consulta de PSAs existentes con los nuevos PSGs para los usuarios afectados
        List<PermissionSetAssignment> lstNewPSAUser = [
            SELECT AssigneeId, PermissionSetGroupId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :setUserIds
            AND   PermissionSetGroup.DeveloperName IN ('OM_Backoffice', 'OM_Estandar', 'OM_Supervisor')
            WITH SECURITY_ENFORCED
        ];

        // Indexación de PSAs para búsqueda
        Set<String> setKeysPSA = new Set<String>();
        for(PermissionSetAssignment psa: lstNewPSAUser){
            setKeysPSA.add(psa.AssigneeId + '-' + psa.PermissionSetGroupId);
        }

        // Cruce de permisos existentes con nuevos para evitar error de duplicidad de permisos
        List<PermissionSetAssignment> lstPSADelete = new List<PermissionSetAssignment>();
        for(PermissionSetAssignment psa : setAssignmentsToAdd){
            if(setKeysPSA.contains(psa.AssigneeId + '-' + psa.PermissionSetGroupId)){
                lstPSADelete.add(psa);
            }
        }

        setAssignmentsToAdd.removeAll(lstPSADelete);

        // DMLs
        insert new List<PermissionSetAssignment>(setAssignmentsToAdd);
        delete lstAssignmentsToDelete;
        update mapAdmUserBatch.values();
    }

    /**
    * @description Procesamiento de cierre de actualización de usuarios
    * @param batchContext Información del contexto de ejecución
    **/
    public void finish(Database.BatchableContext batchContext) {
        System.debug('Ejecución Batch finalizada correctamente.');
    }
}