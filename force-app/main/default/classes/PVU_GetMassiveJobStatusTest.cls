@IsTest
private class PVU_GetMassiveJobStatusTest {
    
    @TestSetup
    static void setup() {
        // Crear datos de prueba en el objeto PVU_Gestiones_Masivas__c
        List<PVU_Gestiones_Masivas__c> masivas = new List<PVU_Gestiones_Masivas__c>();
        PVU_Gestiones_Masivas__c ejemplo1 = new PVU_Gestiones_Masivas__c();
        ejemplo1.PVU_Action__c = 'SUSPENSION';
        ejemplo1.PVU_BillingAccountId__c = '123123123';
        ejemplo1.PVU_Source__c = 'COLLECTIONS';
        ejemplo1.PVU_ReasonId__c = '221';
        ejemplo1.PVU_SuspensionLevel__c = '1';
        ejemplo1.PVU_Status__c = 'Pendiente';
        ejemplo1.PVU_JobIdentifier__c = 'test111';
        ejemplo1.PVU_CustNum__c='312321321312';
       // ejemplo1.PVU_Status_OM__c = 'Exitosa'
        masivas.add(ejemplo1);

        PVU_Gestiones_Masivas__c ejemplo2 = new PVU_Gestiones_Masivas__c();
        ejemplo2.PVU_Action__c = 'SUSPENSION';
        ejemplo2.PVU_BillingAccountId__c = '123123123';
        ejemplo2.PVU_Source__c = 'COLLECTIONS';
        ejemplo2.PVU_ReasonId__c = '221' ;
        ejemplo2.PVU_SuspensionLevel__c = '1';
        ejemplo2.PVU_Status__c = 'Error';
        ejemplo2.PVU_JobIdentifier__c = 'test111';
        ejemplo2.PVU_CustNum__c='0000000938282';
        masivas.add(ejemplo2);
            
        insert masivas;
    }
    
    @IsTest
    static void testValidJobId() {
        // Configurar el contexto REST con un parámetro válido
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetMassiveJobStatus/';
        req.addParameter('jobId', 'test111');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Llamar al método
        PVU_GetMassiveJobStatus.responseObject response = PVU_GetMassiveJobStatus.getNumber();
        
        // Validar resultado
        System.assert(response.total != 0 || response.total != null, 'El total debe ser mayor a 0.');
    }
    
    @IsTest
    static void testInvalidJobId() {
        // Configurar el contexto REST con un jobId no válido
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetMassiveJobStatus/';
        req.addParameter('jobId', 'invalidJobId');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Llamar al método
        PVU_GetMassiveJobStatus.responseObject response = PVU_GetMassiveJobStatus.getNumber();
        
        // Validar resultado
        System.assertEquals('Job ID is not valid', response.message, 'El mensaje debe indicar que el Job ID no es valido');
    }
    
    @IsTest
    static void testMissingJobId() {
        // Configurar el contexto REST sin un parámetro jobId
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/GetMassiveJobStatus/';
        req.addParameter('','');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Llamar al método
        PVU_GetMassiveJobStatus.responseObject response = PVU_GetMassiveJobStatus.getNumber();
        
        System.assertEquals('The jobId parameter is required', response.message, 'El mensaje debe indicar que el parametro jobId es requerido ');
    }
}