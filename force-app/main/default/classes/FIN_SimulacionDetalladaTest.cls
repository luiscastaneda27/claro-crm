@IsTest
public class FIN_SimulacionDetalladaTest {
    private static final String METHOD_NAME = 'getPlazosDisponibles';
    public static Id product2ClassRTId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Class').getRecordTypeId();


    @TestSetup
    static void makeData(){
        PricebookEntry pricebookEntry = OrderMgtTestDataFactory.createProduct('Test Product', 'TST-PRD');

        Account account = new Account(Name = 'Test Account');
        insert account;

        Opportunity oportunidad = new Opportunity(
            AccountId = account.Id,
            StageName = 'Diseño de la Oferta',
            Name = 'Test Oportunidad',
            CloseDate = Date.today()
        );
        insert oportunidad;

        Quote quote = new Quote(
            OpportunityId = oportunidad.Id,
            FIN_MasterQuote__c = false,
            FIN_PlazoMeses__c = 6,
            Name = 'Test Quote',
            Pricebook2Id = System.Test.getStandardPricebookId()
        );
        insert quote;

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        QuoteLineItem qli = new QuoteLineItem(
            UnitPrice = 1000,
            Quantity = 1,
            QuoteId = quote.Id,
            Product2Id = product.Id,
            PricebookEntryId = pricebookEntry.Id
        );
        insert qli;
    }

    @IsTest
    public static void test(){
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity oportunidad = [SELECT Id FROM Opportunity LIMIT 1];
        List<Object> objList = new List<Object>();
        Map<String, Object> objMap = new Map<String, Object>();
        objMap.put('value','6');
        objMap.put('label','6');
        objList.add(objMap);
        objList.add(objMap);
        
        FIN_SimulacionDetallada controller = new FIN_SimulacionDetallada();
        Test.StartTest();
		Boolean controllerResult = controller.invokeMethod(METHOD_NAME, new Map<String, Object>{ 'lstMapInputPlazos' => objList, 'idProduct' => product.id, 'idOpportunity' => oportunidad.Id}, new Map<String, Object>(), new Map<String, Object>());
        Test.StopTest();
        Assert.areEqual(true, controllerResult, 'Error al obtener plazos disponibles.');
    }
}