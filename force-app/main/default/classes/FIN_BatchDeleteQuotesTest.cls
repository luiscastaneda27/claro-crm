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

    @IsTest
    public static void testMasterQuotes(){

        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        FIN_Fianza__c fianzaBorrador  = new FIN_Fianza__c(Name = 'Fianza maestra borrador');
        FIN_Fianza__c fianzaCancelada = new FIN_Fianza__c(Name = 'Fianza maestra cancelada');
        insert new List<FIN_Fianza__c>{ fianzaBorrador, fianzaCancelada };

        Quote borrador          = masterQuote(oportunidad.Id, 'Borrador', fianzaBorrador.Id);
        Quote canceladaFianza   = masterQuote(oportunidad.Id, 'Cerrada Perdida', fianzaCancelada.Id);
        Quote cancelada         = masterQuote(oportunidad.Id, 'Cerrada Perdida', null);
        Quote aprobada          = masterQuote(oportunidad.Id, 'Approved', null);
        insert new List<Quote>{ borrador, canceladaFianza, cancelada, aprobada };

        Test.startTest();
            DataBase.executeBatch(new FIN_BatchDeleteQuotes(), 20);
        Test.stopTest();

        Map<Id, Quote> masters = new Map<Id, Quote>([
            SELECT Id, Status
            FROM Quote
            WHERE FIN_MasterQuote__c = true
        ]);

        System.assertEquals(4, masters.size(), 'Las Quotes maestras no se deben eliminar');
        System.assertEquals('Cerrada Perdida', masters.get(borrador.Id).Status, 'La maestra en Borrador debe quedar cancelada');
        System.assertEquals('Cerrada Perdida', masters.get(canceladaFianza.Id).Status, 'La maestra cancelada sigue cancelada');
        System.assertEquals('Approved', masters.get(aprobada.Id).Status, 'La maestra aprobada no cambia');
        System.assertEquals('Cerrada Perdida', masters.get(cancelada.Id).Status, 'La maestra cancelada sin fianza no cambia');
        System.assertEquals(0, [SELECT COUNT() FROM FIN_Fianza__c WHERE Id IN (:fianzaBorrador.Id, :fianzaCancelada.Id)], 'Las fianzas de las maestras se eliminan');
        System.assertEquals(0, [SELECT COUNT() FROM Quote WHERE FIN_MasterQuote__c = false], 'Las Quotes hijas no aprobadas se eliminan');
    }

    private static Quote masterQuote(Id opportunityId, String status, Id fianzaId){
        return new Quote(
            OpportunityId       = opportunityId,
            FIN_MasterQuote__c  = true,
            FIN_tipoDeVenta__c  = 'Financiacion',
            Status              = status,
            Name                = 'Test Master ' + status,
            Pricebook2Id        = System.Test.getStandardPricebookId(),
            FIN_Fianza_Id__c    = fianzaId
        );
    }

}