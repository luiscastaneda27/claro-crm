@isTest
public class PVU_validacionGestionImeiTest {
	
    @TestSetup
    private static void dataSetup(){
        List<Asset> assets = new List<Asset>();
        List<Order> ordenes = new List<Order>();
        List<Case> casos = new List<Case>();
        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '', Family = 'Device');
        insert prod1;
        
        // Create Price Book Entries     
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pricebookId;
        pbe1.Product2Id = prod1.Id;
        pbe1.UnitPrice = 1;
        pbe1.IsActive = true;
        // pbe1.UseStandardPrice = false;
        insert pbe1;                            
        
        /*****Creacion de la cuenta*****/
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert acc;
        /*******************************/
        
        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset';
        ast.AccountId = acc.Id;
        ast.PVU_IMEI__c = '100000000000003';
        assets.add(ast);
        
        Asset ast2 = new Asset();
        ast2.Name = 'Test Asset';
        ast2.AccountId = acc.Id;
        assets.add(ast2);
        insert assets;
        /***************************/
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Análisis de Necesidad';
        orden1.FVU_ClosingReason__c = 'Desistimiento del cliente antes de entrega';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        ordenes.add(orden1);
        
        Order orden2 = new Order();
        orden2.Status = 'Análisis de Necesidad';
        orden2.FVU_ClosingReason__c = 'Muerto en caja sin cambio';
        orden2.EffectiveDate = System.Today();
        orden2.AccountId = acc.Id;
        orden2.Pricebook2Id = pricebookId;
        ordenes.add(orden2);
        
        //Orden 3 y 4 entradas para fucnionalidad pagos no abonados
        Order orden3 = new Order();
        orden3.AccountId = acc.Id;
        orden3.Status = 'Análisis de Necesidad';
        orden3.FVU_ClosingReason__c = 'Cancelado por no finalización de orden';
        orden3.EffectiveDate = System.Today();
        orden3.Pricebook2Id = pricebookId;
        ordenes.add(orden3);
        
        Order orden4 = new Order();
        orden4.AccountId = acc.Id;
        orden4.Status = 'Análisis de Necesidad';
        orden4.FVU_PaymentStatus__c = 'PP';
        orden4.EffectiveDate = System.Today();
        orden4.Pricebook2Id = pricebookId;
        ordenes.add(orden4);
        //  system.debug('recordtype>>>>'+orden1.RecordTypeId);
        insert ordenes;
        /*****************************/




    }
    
    @isTest
    private static void duplicadoImeiAccountTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'duplicadoImeiAccount';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
        
        input.put('AccountId',(String)cuenta.Id);
        input.put('Imei','100000000000003');
        
        Test.startTest();
            // PVU_validacionGestionImei validation = new PVU_validacionGestionImei();
            // result = validation.invokeMethod(methodName, input, output, options);
        result = PVU_validacionGestionImei.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }

    @isTest
    private static void isImeiClaroTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        String methodName = 'isImeiClaro';
        Boolean result = false;
        
        Account cuenta = [SELECT Id FROM Account][0];
                
        input.put('Imei','100000000000003');
        
        Test.startTest();
            // PVU_validacionGestionImei validation = new PVU_validacionGestionImei();
            // result = validation.invokeMethod(methodName, input, output, options);
        result = PVU_validacionGestionImei.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');
    }
}