/*------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:    Mock data to apex class test "PVu_CalloutHandlerDocumentTEST"
MOCK Class:    	PVU_MockCalloutHandlerDocument
History
<Date>      	<Author>     	<Change Description>
29-Abril-2024	Luis Mendoza	Initial Version
------------------------------------------------------------*/
@isTest
global class PVU_MockCalloutHandlerDocument implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"data":{"message":"Documentos cargados exitosamente"},"message":"Ok","responseCode":200,"transactionId":"bcbc07d6-9013-44f3-af9c-74db1ec5148f"}');
        response.setStatusCode(200);
        return response;
    }
}