@isTest
public class FIN_ScheduleDeleteQuotesTest {
    
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
        
        List<Quote> lstQuotes = new List<Quote>();
        for(Integer i=0 ;i <10;i++) {
            Quote quote = new Quote(
                OpportunityId = oportunidad.Id,
                FIN_MasterQuote__c = false,
                FIN_tipoDeVenta__c = 'Financiacion',
                Status = 'Denied',
                Name = 'Test Quote ' + i,
                Pricebook2Id = System.Test.getStandardPricebookId()
            );
            lstQuotes.add(quote);
        }
        insert lstQuotes;

    }
    
     @isTest
     static void testOrderBatchSchedule() {

        Test.startTest();
        FIN_ScheduleDeleteQuotes scheduler = new FIN_ScheduleDeleteQuotes();
        scheduler.execute(null);
        Test.stopTest();
        List<Quote> lstQuotesDeleted = [SELECT Id FROM Quote];
        Assert.areEqual(lstQuotesDeleted.Size(),0,'La eliminación de registros Quote ha fallado');
     }

}