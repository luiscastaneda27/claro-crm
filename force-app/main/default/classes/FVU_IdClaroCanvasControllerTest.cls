@IsTest
public with sharing class FVU_IdClaroCanvasControllerTest {

    @IsTest
    public static void IdClaroCanvasControllerTest() {
        PageReference pageRef = Page.FVU_IdClaroCanvas;
        Test.setCurrentPage(pageRef);

        String userId = UserInfo.getUserId();

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Order ord = new Order();
        ord.Name = 'Test Order';
        ord.EffectiveDate = System.today();
        ord.Status = 'Draft';
        ord.AccountId = acc.Id;
        insert ord;
        
        ApexPages.currentPage().getParameters().put('account', acc.id);
        ApexPages.currentPage().getParameters().put('record', ord.id);
        ApexPages.currentPage().getParameters().put('app', 'RETIRO_DE_TERMINAL_EN_TIENDA_SF');
        ApexPages.currentPage().getParameters().put('channel', '1');
        ApexPages.currentPage().getParameters().put('isThirdPerson', 'false');
        ApexPages.currentPage().getParameters().put('thirdPersonData', '{"TipoDoc":"PP","NumDoc":"12345678","primerNombre":"Juan","segundoNombre":"Carlos","primerApellido":"Pérez","segundoApellido":"Gómez","telefono":"5551234567","mail":"juan.perez@example.com"}');
        ApexPages.currentPage().getParameters().put('isThirdPersonPV','false');        
        FVU_IdClaroCanvasController controller = new FVU_IdClaroCanvasController();

        Map<String, String> mapToSerialize = new Map<String, String>();
        mapToSerialize.put('userId', userId);
        mapToSerialize.put('accountId', acc.Id);
        mapToSerialize.put('recordId', ord.Id);
        mapToSerialize.put('application', 'TEST_EXAMPLE');
        mapToSerialize.put('channel', 'Test');
        mapToSerialize.put('isAuthorizedPerson', 'false');
        String mapJSON = JSON.serialize(mapToSerialize);
    }
}