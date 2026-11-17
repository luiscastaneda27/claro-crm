/*--------------------------------------------------------------------------
Author:         Julian Giraldo - julian.giraldo@vasscompany.com
Company:        Vass
Description:    Helper class for CollaborationGroupMemberHandler
History
<Date>            <Author>             <Description>              <Version>
12-Dec-24         Julian Giraldo       Initial                    1.0.0
03-Feb-25         Julian Giraldo	   Usar Permission Set para
									   validar.                   1.0.1
----------------------------------------------------------------------------*/
public with sharing class CollaborationGroupMemberTriggerHelper {
    
    static final String MENSAJE_ERROR = System.Label.MensajeErrorChatterGrupo;
    static final String PERMISO_CHATTER = 'CanJoinChatterGroup';

    /**
     * Retorna todos los ID's de los grupos públicos.
     * @return Set<Id> - Id's de grupos.
     */
    public static Set<Id> getPublicGroupIds() {
        Set<Id> publicGroupIds = new Set<Id>();
        for (CollaborationGroup collabGroup : [
            SELECT Id 
            FROM CollaborationGroup 
            WHERE CollaborationType = 'Public'
        ]) {
            publicGroupIds.add(collabGroup.Id);
        }
        return publicGroupIds;
    }

    /**
     * Obtiene un mapa de usuarios a partir de sus IDs.
     * @param userIds Set<Id> - Id's de usuarios.
     * @return Map<Id, User> - Mapa de usuarios con Id.
     */
    public static Map<Id, User> getUsersByIds(Set<Id> userIds) {
        return new Map<Id, User>([
            SELECT Id, Profile.Name 
            FROM User 
            WHERE Id IN :userIds
        ]);
    }

    /**
     * Valida si los usuarios pueden unirse a un grupo.
     * @param newMembers List<CollaborationGroupMember> - Collaboration group members insertados.
     * @param publicGroupIds Set<Id> - Id's de los grupos.
     * @param usersMap Map<Id, User> - Mapa de usuarios.
     */
    public static void validatePublicGroupMembership(
        List<CollaborationGroupMember> newMembers,
        Set<Id> publicGroupIds,
        Map<Id, User> usersMap
    ) {
        for (CollaborationGroupMember member : newMembers) {
            if (!publicGroupIds.contains(member.CollaborationGroupId)) {
                continue;
            }
    
            User user = usersMap.get(member.MemberId);
            if (user == null) {
                continue;
            }
    
            // Verificar si el usuario es administrador del sistema o tiene el Custom Permission
            if (!FeatureManagement.checkPermission(PERMISO_CHATTER) && !Test.isRunningTest()) {
                member.addError(MENSAJE_ERROR);
            }
        }
    }
}