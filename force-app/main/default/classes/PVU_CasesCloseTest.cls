@isTest
private class PVU_CasesCloseTest {
    @TestSetup
    private static void dataSetup(){
        List<Asset> assets = new List<Asset>();
        List<Order> ordenes = new List<Order>();
        List<Case> casos = new List<Case>();
        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        
        /***** Create Price Book Entries******/
        Id pricebookId = Test.getStandardPricebookId();
        
        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert acc;
        
        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset1';
        ast.AccountId = acc.Id;
        assets.add(ast);
        insert assets;
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.FVU_BusinessChannel__c='CAV';
        orden1.FVU_PaymentMethod__c='Contado';
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Ready To Submit';
        insert orden1;
        
        /*****Creacion de casos****/
        Case caso1 = new Case();
        caso1.PVU_Level1__c = 'Facturación y pagos';
        caso1.PVU_Level2__c = 'Pagos';
        caso1.PVU_Level3__c = 'Pago no abonado'; 
        caso1.status = 'Abierto';
        caso1.PVU_NR__c = '00000001';
        caso1.AccountId = acc.Id;
        caso1.AssetId = ast.Id;
        caso1.RecordTypeId = rt.Id;
        caso1.OwnerId  = UserInfo.getUserId();
        casos.add(caso1);
        
        Case caso2 = new Case();
        caso2.PVU_Level1__c = 'Facturación y pagos';
        caso2.PVU_Level2__c = 'Pagos';
        caso2.PVU_Level3__c = 'Pago no abonado'; 
        caso2.status = 'En curso';
        caso2.PVU_NR__c = '00000002';
        caso2.AccountId = acc.Id;
        caso2.AssetId = ast.Id;
        caso2.RecordTypeId = rt.Id;
        caso2.PVU_Order__c = orden1.Id;
        caso2.OwnerId  = UserInfo.getUserId();
        casos.add(caso2);
        
        insert casos;
        
		
    }

    @isTest
    static void getListCasesTest() {
        Account cuenta = [SELECT Id FROM Account][0];
        Test.startTest();
        List<Object> listCases = PVU_CasesClose.getListCases(cuenta.Id);
        Test.stopTest();
        System.AssertEquals(true, listCases.size() > 0, 'El metodo getListCases fue invocado');
    }
    
    @isTest
    static void getMensajesCasesCloseTest() {
        Test.startTest();
        Map<String,Object> listMsg = PVU_CasesClose.getMensajesCasesClose();
        Test.stopTest();
        System.AssertEquals(true, listMsg.size() > 0, 'El metodo getMensajesCasesClose fue invocado');
    }
    
    @isTest
    static void closeCasesTest() {
        List<Case> listCases = [SELECT Id FROM Case];
        Test.startTest();
        Boolean result = PVU_CasesClose.closeCases(listCases);
        Test.stopTest();
        System.AssertEquals(true, result, 'El metodo closeCases fue invocado');
    }
}