@isTest 
public class FIN_BatchDeleteQuotesTest {

    @TestSetup
    static void makeData(){

        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity oportunidad = new Opportunity(
            AccountId = account.Id,
            StageName = 'Diseño de la Oferta',
            Name = 'Test Oportunidad',
            CloseDate = Date.today()
        );
        insert oportunidad;
        
        // Creamos Fianzas para asociar a las Quotes
        List<FIN_Fianza__c> lstFianzas = new List<FIN_Fianza__c>();
        for (Integer i = 0; i < 10; i++) {
            lstFianzas.add(new FIN_Fianza__c(
                Name = 'Test Fianza ' + i
            ));
        }
        insert lstFianzas;
        
        List<Quote> lstQuotes = new List<Quote>();
        for (Integer i = 0; i < 10; i++) {
            Quote quote = new Quote(
                OpportunityId       = oportunidad.Id,
                FIN_MasterQuote__c  = false,
                FIN_tipoDeVenta__c  = 'Financiacion',
                Status              = 'Denied',
                Name                = 'Test Quote ' + i,
                Pricebook2Id        = System.Test.getStandardPricebookId(),
                FIN_Fianza_Id__c       = lstFianzas[i].Id // relacionamos la fianza
            );
            lstQuotes.add(quote);
        }
        insert lstQuotes;
    }

    @IsTest
    public static void test(){

        Test.startTest();
            FIN_BatchDeleteQuotes obj = new FIN_BatchDeleteQuotes();
            DataBase.executeBatch(obj, 20); 
        Test.stopTest();

        List<Quote> lstQuotesDeleted      = [SELECT Id FROM Quote];
        List<FIN_Fianza__c> lstFianzasDel = [SELECT Id FROM FIN_Fianza__c];

        System.assertEquals(0, lstQuotesDeleted.size(), 'La eliminación de registros Quote ha fallado');
        System.assertEquals(0, lstFianzasDel.size(), 'La eliminación de registros FIN_Fianza__c ha fallado');
    }

}