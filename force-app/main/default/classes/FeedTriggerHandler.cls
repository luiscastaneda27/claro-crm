/*--------------------------------------------------------------------------
Author:         Julian Giraldo - julian.giraldo@vasscompany.com
Company:        Vass
Description:    Prevent users to join delete or modify a chatter feed, this class is called from triggers from Chatter Feed and Comments.
History
<Date>            <Author>             <Description>             	  <Version>
26-Nov-24         Julian Giraldo       Initial                   		1.0.0
----------------------------------------------------------------------------*/
public class FeedTriggerHandler {
    
    static final String EDIT_CHATTER_FEED = 'CanEditChatterFeed';
    static final String DELETE_CHATTER_FEED = 'CanDeleteChatterFeed';
    static final String MENSAJE_ERROR_EDIT = System.Label.canEditChatterFeed;
    static final String MENSAJE_ERROR_DELETE = System.Label.canDeleteChatterFeed;
    
    public static void handleBeforeUpdate(List<SObject> oldItems, List<SObject> newItems) {
        checkEditChatterPermission(newItems);
    }

    public static void handleBeforeDelete(List<SObject> oldItems) {
        checkDeleteChatterPermission(oldItems);
    }
    
    private static void checkEditChatterPermission (List<SObject> newItems){
        // Verifica si el usuario tiene el Custom Permission CanEditChatterFeed
        if (!FeatureManagement.checkPermission(EDIT_CHATTER_FEED)) {
            for (SObject newItem : newItems) {
                newItem.addError(MENSAJE_ERROR_EDIT);
            }
        }
    }
    
    private static void checkDeleteChatterPermission (List<SObject> oldItems){
        // Verifica si el usuario tiene el Custom Permission CanDeleteChatterFeed
        if (!FeatureManagement.checkPermission(DELETE_CHATTER_FEED)) {
            for (SObject feedItem : oldItems) {
                feedItem.addError(MENSAJE_ERROR_DELETE);
            }
        }
    }
}