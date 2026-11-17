@IsTest
public class GestionCanalesTriggerHandlerTest {
   
    @TestSetup
    public static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
       
        List<User> usuarios = new List<User>{
            new User(Alias = 'testUser', Email = 'testUser@testdomain.com', ProfileId = p.Id, EmailEncodingKey = 'UTF-8', LastName='Testing',
                     LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/New_York', UserName = 'clarocolombia3@clarocolombia3.com',
                     FederationIdentifier = 'clarocolombia3@clarocolombia3.com')
                     
        };
        insert usuarios;
    }
   
    @isTest
    static void usuarioExistente() {
        GestionCanalesUsuario__c gcu = new GestionCanalesUsuario__c(FederationIdentifier__c = 'clarocolombia3@clarocolombia3.com', FVU_DANE_Punto_de_Venta__c = 'Test');
        insert gcu;
        System.debug('gcu ' + gcu);
       
        List<User> usuarios = [SELECT Id FROM User WHERE Email = 'testUser@testdomain.com'];
        List<GestionCanalesUsuario__c> lgcu = [SELECT Id,User__c FROM GestionCanalesUsuario__c WHERE Id =: gcu.Id];
        System.debug('usuarios ' + usuarios);
        System.debug('lgcu ' + lgcu);
       
        Assert.areEqual(lgcu[0].User__c, usuarios[0].Id);
    }
 
}