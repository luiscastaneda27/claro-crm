/*--------------------------------------------------------------------------
Author:         Julian Giraldo - julian.giraldo@vasscompany.com
Company:        Vass
Description:    Test Class
History
<Date>            <Author>             <Description>             	  <Version>
26-Nov-24         Julian Giraldo       Initial                   		1.0.0
----------------------------------------------------------------------------*/
@isTest
private class FeedTriggerHandler_Test {
    
    private static Profile getAdminProfile(){
        return [SELECT Id, Name FROM Profile WHERE PermissionsModifyAllData = true LIMIT 1];
    }
    
    private static User getSystemAdminUser() {
        Profile sysAdminProfile = getAdminProfile();
        
        // Crear usuario de prueba con perfil de System Administrator
        User testAdmin = new User(
            Alias = 'testadm',
            Email = 'testadmin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testadmin_' + Datetime.now().getTime() + '@test.com'
        );
        insert testAdmin;
        return testAdmin;
    }
    
    // Métodos de prueba para FeedItem Trigger
    @isTest
    static void testFeedItemTriggerBeforeUpdate() {
        User adminUser = getSystemAdminUser();
        
        System.runAs(adminUser) {
            // Crear un FeedItem en la base de datos
            FeedItem feedItem = new FeedItem(Body = 'Test post');
            feedItem.ParentId = adminUser.Id;
            insert feedItem;
            
            Test.startTest();
            
            // Modificar el FeedItem para activar el trigger before update
            feedItem.Body = 'Updated post';
            
            // Capturar la excepción que se lanzará debido a la falta de permisos
            Boolean exceptionThrown = false;
            try {
                update feedItem;
            } catch (System.DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains(System.Label.canEditChatterFeed), 
                             'El mensaje de error debe indicar falta de permiso');
            }
            
            System.assert(exceptionThrown, 'Se esperaba una excepción debido a la falta de permisos');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testFeedItemTriggerBeforeDelete() {
        User adminUser = getSystemAdminUser();
        
        System.runAs(adminUser) {
            // Crear un FeedItem en la base de datos
            FeedItem feedItem = new FeedItem(Body = 'Test post');
            feedItem.ParentId = adminUser.Id;
            insert feedItem;
            
            Test.startTest();
            
            // Intentar eliminar el FeedItem para activar el trigger before delete
            Boolean exceptionThrown = false;
            try {
                delete feedItem;
            } catch (System.DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains(System.Label.canDeleteChatterFeed), 
                             'El mensaje de error debe indicar falta de permiso');
            }
            
            System.assert(exceptionThrown, 'Se esperaba una excepción debido a la falta de permisos');
            
            Test.stopTest();
        }
    }
    
    // Nuevos métodos de prueba para FeedComment Trigger
    @isTest
    static void testFeedCommentTriggerBeforeUpdate() {
        User adminUser = getSystemAdminUser();
        
        System.runAs(adminUser) {
            // Crear un FeedItem como padre
            FeedItem feedItem = new FeedItem(Body = 'Test post');
            feedItem.ParentId = adminUser.Id;
            insert feedItem;
            
            // Crear un FeedComment
            FeedComment comment = new FeedComment(
                CommentBody = 'Test comment',
                FeedItemId = feedItem.Id
            );
            insert comment;
            
            Test.startTest();
            
            // Modificar el comentario para activar el trigger before update
            comment.CommentBody = 'Updated comment';
            
            // Capturar la excepción que se lanzará debido a la falta de permisos
            Boolean exceptionThrown = false;
            try {
                update comment;
            } catch (System.DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains(System.Label.canEditChatterFeed), 
                             'El mensaje de error debe indicar falta de permiso');
            }
            
            System.assert(exceptionThrown, 'Se esperaba una excepción debido a la falta de permisos');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testFeedCommentTriggerBeforeDelete() {
        User adminUser = getSystemAdminUser();
        
        System.runAs(adminUser) {
            // Crear un FeedItem como padre
            FeedItem feedItem = new FeedItem(Body = 'Test post');
            feedItem.ParentId = adminUser.Id;
            insert feedItem;
            
            // Crear un FeedComment
            FeedComment comment = new FeedComment(
                CommentBody = 'Test comment',
                FeedItemId = feedItem.Id
            );
            insert comment;
            
            Test.startTest();
            
            // Intentar eliminar el comentario para activar el trigger before delete
            Boolean exceptionThrown = false;
            try {
                delete comment;
            } catch (System.DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains(System.Label.canDeleteChatterFeed), 
                             'El mensaje de error debe indicar falta de permiso');
            }
            
            System.assert(exceptionThrown, 'Se esperaba una excepción debido a la falta de permisos');
            
            Test.stopTest();
        }
    }
    
    // Métodos de prueba directa del handler
    @isTest
    static void testHandleBeforeUpdateWithoutPermission() {
        User adminUser = getSystemAdminUser();
        Test.startTest();
        // Crear un FeedItem en la base de datos
        FeedItem feedItem = new FeedItem(Body = 'Test post');
        feedItem.ParentId = adminUser.Id;
        insert feedItem;
        
        // Simular que el usuario NO tiene el permiso CanEditChatterFeed
        System.runAs(adminUser) {
            List<FeedItem> newItems = new List<FeedItem>{ [SELECT Id FROM FeedItem WHERE Id = :feedItem.Id] };
            
            FeedTriggerHandler.handleBeforeUpdate(new List<SObject>(), newItems);
            
            System.assert(newItems[0].getErrors().size() > 0, 'Se esperaba que el item tuviera errores');
            System.assertEquals(System.Label.canEditChatterFeed, newItems[0].getErrors()[0].getMessage(), 'El mensaje de error debe indicar falta de permiso');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testHandleBeforeDeleteWithoutPermission() {
        User adminUser = getSystemAdminUser();
        Test.startTest();
        // Crear un FeedItem en la base de datos
        FeedItem feedItem = new FeedItem(Body = 'Test post');
        feedItem.ParentId = adminUser.Id;
        insert feedItem;
        
        // Simular que el usuario NO tiene el permiso CanDeleteChatterFeed
        System.runAs(adminUser) {
            List<FeedItem> oldItems = new List<FeedItem>{ [SELECT Id FROM FeedItem WHERE Id = :feedItem.Id] };
            
            FeedTriggerHandler.handleBeforeDelete(oldItems);
            
            System.assert(oldItems[0].getErrors().size() > 0, 'Se esperaba que el item tuviera errores');
            System.assertEquals(System.Label.canDeleteChatterFeed, oldItems[0].getErrors()[0].getMessage(), 'El mensaje de error debe indicar falta de permiso');
        }
        Test.stopTest();
    }
}