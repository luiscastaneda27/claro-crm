@IsTest
public with sharing class FVU_IdClaroCanvasLifecycleHandlerTest {

    @IsTest
    public static void testDefaultMockValues(){
        // Test handler using the default mock RenderContext Canvas.Test creates
        FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();
        Canvas.Test.testCanvasLifecycle(handler,null);
    }

    @IsTest
    public static void testOverriddenAppValues(){
        // Test handler with some mock application context values
        Map<String,String> appValues = new Map<String,String>();
        appValues.put(Canvas.Test.KEY_CANVAS_URL,'https://myserver.com:6000/myAppPath');
        appValues.put(Canvas.Test.KEY_VERSION,'3.0');
        
        Canvas.RenderContext mock = Canvas.Test.mockRenderContext(appValues,null);
        FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();
        Canvas.Test.testCanvasLifecycle(handler,mock);
    }

    @IsTest
    public static void testOverriddenEnvironmentValues(){
        // Test handler with some mock environment context values
        Map<String,String> envValues = new Map<String,String>();
        envValues.put(Canvas.Test.KEY_DISPLAY_LOCATION,'Chatter');
        envValues.put(Canvas.Test.KEY_LOCATION_URL,
            'https://myinstance.salesforce.com/_ui/core/chatter/ui/ChatterPage');
        FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();
        Canvas.RenderContext mock = Canvas.Test.mockRenderContext(null,envValues);
        // Directly update the mock RenderContext and set the custom parameters
        mock.getEnvironmentContext().setParametersAsJSON(
            '{\"one\":1,\"two\":2,\"bool\":true,\"stringVal\":\"some string\"}');
        Canvas.Test.testCanvasLifecycle(handler,mock);
    }

    @IsTest
    public static void excludeContextTypesTest() {
        FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();
        Set<Canvas.ContextTypeEnum> excluded = handler.excludeContextTypes();

        System.assertNotEquals(null, excluded);
    }

    @IsTest
    public static void encryptTokenTest(){
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
        
        Contact contact = new Contact();
        contact.AccountId = account.Id;
        contact.FirstName = 'Test';
        contact.LastName = 'Contact';
        contact.FVU_ExpeditionSite__c = 'BOGOTÁ';
        account.vlocity_cmt__PrimaryContactId__c = contact.Id;

        Order order = new Order();
        order.Name = 'Test Order';
        order.AccountId = account.Id;
        order.EffectiveDate = System.today();
        order.Status = 'Draft';
        order.FVU_DeliveryData__c = '{"PickUpData":{"selectedPickupDate":{"avaDate":""},"pickupPointCode":""},"DeliveryMethod":"PickUp","DeliveryData":{"selectedPromise":{"productList":[{"productNum":"","groupId":"","productCode":""}],"fulfillGroup":"","promiseEndDate":"","promiseStartDate":"","promiseId":"","promiseCode":""},"fullfillGroup":"","StartDate":"","Name":"","EndDate":"","Code":""},"AuthorizedPersonData":{"SecondLastName":"","Phone":"","Name":"","LastName":"","DocumentType":"","Document":""}}';
        insert order;

        Case testCase = new Case();
        testCase.AccountId = account.Id;
        testCase.PVU_AuthorizedPersonData__c = '{"AuthorizedPersonData":{"SecondLastName":"","Phone":"123456789","Email":"test@email.com","Name":"Marcos","LastName":"Higgs","DocumentType":"CC","Document":"123456789"}}';
        insert testCase;

        String userId = UserInfo.getUserId();
        String accountId = account.Id;
        String orderId = order.Id;
        String caseId = testCase.Id;
        
        Map<String, Object> testParameters = new Map<String, Object>();

        testParameters.put('userId', userId);
        testParameters.put('accountId', accountId);
        testParameters.put('recordId', orderId);
        testParameters.put('application', 'RETIRO_DE_TERMINAL_EN_TIENDA_SF');
        testParameters.put('channel', '1');
        testParameters.put('isAuthorizedPerson', 'false');
        testParameters.put('isAuthorizedPersonPV', 'false');
        testParameters.put('thirdPersonData', '{"TipoDoc":"PP","NumDoc":"12345678","primerNombre":"Juan","segundoNombre":"Carlos","primerApellido":"Pérez","segundoApellido":"Gómez","telefono":"5551234567","mail":"juan.perez@example.com"}');
		
        
        
		FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();        

        String encryptedToken1 = handler.encryptToken(testParameters);
        System.assertNotEquals(null, encryptedToken1);
        
        testParameters.put('isAuthorizedPerson', 'true');
		String encryptedToken2 = handler.encryptToken(testParameters);
        System.assertNotEquals(null, encryptedToken2);

        testParameters.put('recordId', caseId);
        String encryptedToken3 = handler.encryptToken(testParameters);
        System.assertNotEquals(null, encryptedToken2);

        testParameters.put('isAuthorizedPerson', 'false');
        testParameters.put('isAuthorizedPersonPV', 'true');
        testParameters.put('recordId', '');
        testParameters.put('accountId', '');
        String encryptedToken4 = handler.encryptToken(testParameters);
        System.assertNotEquals(null, encryptedToken4);

        

    }
}