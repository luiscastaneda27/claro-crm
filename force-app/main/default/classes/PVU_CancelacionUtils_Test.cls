/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 01-09-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   01-09-2025   SALESFORCE   Initial Version
**/
@isTest
public class PVU_CancelacionUtils_Test {
	
    @TestSetup
    private static void dataSetup(){
        RecordType rt = [SELECT id, Name from RecordType WHERE DeveloperName = 'GestionCasosPosventa'][0];
        // Create products
        Product2 prod1 = new Product2 (Name='Product 1', ProductCode = 'B2C-FIJA-OFR-ULTRAWIFI', FVU_Beneficios__c = '');
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
        
        /*****Creacion de subscripcion****/
        vlocity_cmt__Subscription__c subs1 = new vlocity_cmt__Subscription__c();
        subs1.OM_MSISDN__c = '123456789';
        subs1.vlocity_cmt__SubscriptionNumber__c = '00001';
        insert subs1;

        /*******Creacion de Assets***/
        Asset ast = new Asset();
        ast.Name = 'Test Asset';
        ast.AccountId = acc.Id;
        ast.vlocity_cmt__SubscriptionId__c = subs1.Id;
        insert ast;
        /***************************/
        
        /****Creacion de ordenes****/
        Order orden1 = new Order();
        orden1.Status = 'Draft';
        orden1.EffectiveDate = System.Today();
        orden1.AccountId = acc.Id;
        orden1.Pricebook2Id = pricebookId;
        orden1.vlocity_cmt__OrderStatus__c = 'Cancelled';
        insert orden1;

        Order orden2 = new Order();
        orden2.Status = 'Draft';
        orden2.EffectiveDate = System.Today();
        orden2.AccountId = acc.Id;
        orden2.Pricebook2Id = pricebookId;
        orden2.vlocity_cmt__OrderStatus__c = 'Queued';
        insert orden2;

        /****Creacion de orden item****/
        OrderItem orderItem1 = new OrderItem();
        orderItem1.OrderId = orden2.Id;
        orderItem1.Product2Id = prod1.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.Quantity = 1;
        orderItem1.UnitPrice = 10;
        orderItem1.vlocity_cmt__LineNumber__c = '0001';
        orderItem1.vlocity_cmt__Action__c = 'Add';
        orderItem1.vlocity_cmt__ProvisioningStatus__c = 'New';
        orderItem1.vlocity_cmt__ServiceAccountId__c = acc.Id;
        orderItem1.FVU_OneTimeTotalIncTaxes__c = 2000000;
        orderItem1.FVU_ProductDeliveryStatus__c = 'ReadyForPickup';
        orderItem1.vlocity_cmt__AssetId__c = ast.Id;
        insert orderItem1;
        
        /*****Creacion de casos****/
        Case caso1 = new Case();
        caso1.status = 'Abierto';
        caso1.AccountId = acc.Id;
        caso1.AssetId = ast.Id;
        caso1.RecordTypeId = rt.Id;
        caso1.PVU_Order__c = orden1.Id;
        insert caso1;
    }
    
    @isTest
    public static void updateCaseTest(){
        Order orden = [SELECT Id FROM Order][0];
        String orderId = orden.Id;
        String mensajeCase = 'La orden {1} y el caso {0} son canceladas por Cancelación Voluntaria/Fallecimiento solicitada por el cliente.';
 		String ordenProcesadaValue = 'No Exitosa';
        
        String methodName = 'updateCase';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('orderId','123');
        input.put('mensajeCase',mensajeCase);
        input.put('ordenProcesadaValue',ordenProcesadaValue);
        
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            cancelacionUtils.invokeMethod(methodName, input, output, options);
            input.put('orderId',orderId);
        	cancelacionUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();

		System.debug('** output cancelacionUtils.updateCase: ' + output.get('caseUpdated'));
        
    }

    @isTest
    public static void getOrdenesFuturasTest(){
        Boolean result = false;
        
        String methodName = 'getOrdenesFuturas';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('min','123456789');
        
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            result = cancelacionUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');    
    }

    @isTest
    public static void getOrdenesFuturasCatchErrorTest(){
        Boolean result = false;
        
        String methodName = 'getOrdenesFuturas';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('min',123456789);
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            result = cancelacionUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,false, 'El método '+ methodName + ' fue invocado');    
    }

    @isTest
    public static void catchErrorPpalTest(){
        Boolean result = false;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            result = cancelacionUtils.invokeMethod(null, input, output, options);
        Test.stopTest();
        System.assertEquals(result,false, 'El método principal fue invocado');    
    }

    @isTest
    public static void setDatetimeGmtTest(){
        Boolean result = false;
        
        String methodName = 'setDatetimeGmt';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('date','2024-01-01');
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            result = cancelacionUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');    
    }
    

    @isTest
    public static void datesByCycleTest(){
        Boolean result = false; 

        String methodName = 'datesByCycle';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('ciclo','15');
        PVU_CancelacionUtils cancelacionUtils = new PVU_CancelacionUtils();
        Test.startTest();
            result = cancelacionUtils.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.assertEquals(result,true, 'El método '+ methodName + ' fue invocado');  
    }
    
        @isTest
    public static void updateAssetFallecimientoTest() {

        // Obtener Account y Asset creados en TestSetup
        Account acc = [SELECT Id FROM Account where Name ='Test Account'  LIMIT 1];
        Asset ast = [SELECT Id, AccountId FROM Asset where Name = 'Test Asset' LIMIT 1];

        // Preparamos input JSON simulado tal como lo recibe el método real
        Map<String, Object> financingNode = new Map<String, Object>();
        financingNode.put('chargeBillingAccount', 'ABC123');

        List<Object> financingList = new List<Object>();
        financingList.add(financingNode);

        Map<String, Object> financings = new Map<String, Object>();
        financings.put('financing', financingList);

        Map<String, Object> root = new Map<String, Object>();
        root.put('financings', financings);

        Map<String, Object> input = new Map<String, Object>();
        input.put('IPGetFinancingInfo', root);
        input.put('accountId', acc.Id);

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Actualizar el Asset para que coincida con chargeBillingAccount
        ast.FIN_IdReferenciaDelCredito92__c = 'ABC123';
        update ast;

        PVU_CancelacionUtils cancelUtils = new PVU_CancelacionUtils();

        Test.startTest();
        Boolean ok = cancelUtils.invokeMethod('updateAssetFallecimiento', input, output, options);
        Test.stopTest();

        System.assertEquals(true, ok, 'El método fue invocado correctamente');

        // Validar actualización
        Asset updated = [SELECT PVU_GestionPorFallecimiento__c 
                         FROM Asset WHERE Id = :ast.Id];

        System.assertEquals(
            'Crédito cliente fallecido',
            updated.PVU_GestionPorFallecimiento__c,
            'El campo debe actualizarse correctamente'
        );
    }


    @isTest
    public static void updateAssetFallecimientoCatchTest() {

        // Input inválido → Provoca error controlado
        Map<String, Object> input = new Map<String, Object>();
        input.put('accountId', null);
        input.put('IPGetFinancingInfo', null);

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        PVU_CancelacionUtils cancelUtils = new PVU_CancelacionUtils();

        Test.startTest();
        Boolean ok = cancelUtils.invokeMethod('updateAssetFallecimiento', input, output, options);
        Test.stopTest();

        System.assertEquals(
            true,
            ok,
            'El método no debería lanzar excepción ni romper ejecución'
        );
    }

    
}