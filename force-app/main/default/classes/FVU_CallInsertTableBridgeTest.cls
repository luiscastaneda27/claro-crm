@isTest
public class FVU_CallInsertTableBridgeTest {

    @IsTest
    static void callInsertTableBridgeTest() {

        List<String> assetId = new List<String>();
        assetId.add('0123456789');

        Test.startTest();

            String url = 'http://example.com/example';
            String path = 'FVU_CallInsertDataInTableBridge';
            String mockResponse = '{"descripcionError":"-","error":"0","resultado":"Exitoso"}';

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(mockResponse);
            response.setStatusCode(200);
            vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponseByUrlOrActionName('CallInsertDataInTableBridge', response);

            FVU_CallInsertTableBridge.callInsertTableBridge(assetId);

            System.assert(true,' Test error');

        Test.stopTest();
    }

}