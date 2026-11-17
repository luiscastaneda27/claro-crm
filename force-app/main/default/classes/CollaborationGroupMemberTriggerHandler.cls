/*--------------------------------------------------------------------------
Author:         Julian Giraldo - julian.giraldo@vasscompany.com
Company:        Vass
Description:    Prevent users to join a public chatter group handler
Test Class:     tst_PreventJoinPublicGroups
Code Coverage:  100%
History
<Date>            <Author>             <Description>             	  <Version>
26-Nov-24         Julian Giraldo       Initial                   		1.0.0
----------------------------------------------------------------------------*/
public class CollaborationGroupMemberTriggerHandler {
    public static void handleBeforeInsert(List<CollaborationGroupMember> newMembers) {
        if (newMembers.isEmpty()) {
            return; // No hay registros para procesar
        }

        // Obtener los Ids de los grupos públicos
        Set<Id> publicGroupIds = CollaborationGroupMemberTriggerHelper.getPublicGroupIds();

        // Recopilar los MemberId de los CollaborationGroupMember
        Set<Id> memberUserIds = new Set<Id>();
        for (CollaborationGroupMember member : newMembers) {
            memberUserIds.add(member.MemberId);
        }

        // Obtener los perfiles de los usuarios involucrados
        Map<Id, User> usersMap = CollaborationGroupMemberTriggerHelper.getUsersByIds(memberUserIds);

        // Validar membresía en grupos públicos
        CollaborationGroupMemberTriggerHelper.validatePublicGroupMembership(newMembers, publicGroupIds, usersMap);
    }
}