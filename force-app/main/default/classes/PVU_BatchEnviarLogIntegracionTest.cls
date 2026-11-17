/*--------------------------------------------------------------------------
 Author: Eduardo Wentancur - 
 Company: Salesforce.com
 Description: Test Batch Enviar correos con los Logs Integracion
 Code Coverage: 100%
 History
 <Date>     <Author>        <Description>                       <Version>
 11-Sep-25  Eduardo W       Clase de test para batch de correos  1ra version
----------------------------------------------------------------------------*/

@isTest
private class PVU_BatchEnviarLogIntegracionTest {

    @testSetup
    static void setupData() {
        // Crear registros que cumplan con los filtros del batch
        insert new PVU_LogIntegracion__c(
            Name = 'PFARelaUpdateImei',
            PVU_StatusCode__c = '200', // distinto de 202
            PVU_Descripcion__c = '{Fecha de cambio de Imei.=2025-09-03T16:09:00, IMEI del equipo a enrolar.=353465084373842}'
        );

        // Este registro no debería entrar porque tiene StatusCode 202
        insert new PVU_LogIntegracion__c(
            Name = 'PFARelaUpdateImei',
            PVU_StatusCode__c = '202',
            PVU_Descripcion__c = '{IMEI del equipo a enrolar.=999999}'
        );

        // Este registro no debería entrar porque tiene otro Name
        insert new PVU_LogIntegracion__c(
            Name = 'OtroProceso',
            PVU_StatusCode__c = '200',
            PVU_Descripcion__c = '{IMEI del equipo a enrolar.=111111}'
        );
    }

    @isTest
    static void testBatchEjecuta() {
        Test.startTest();
        Database.executeBatch(new PVU_BatchEnviarLogIntegracion(), 200);
        Test.stopTest();

        // Validar que los registros de prueba existen
        Integer countValid = [
            SELECT COUNT() 
            FROM PVU_LogIntegracion__c 
            WHERE Name = 'PFARelaUpdateImei' AND PVU_StatusCode__c = '200'
        ];
        System.assertEquals(1, countValid, 'Debe existir 1 registro válido para el batch');

        Integer countInvalid = [
            SELECT COUNT() 
            FROM PVU_LogIntegracion__c 
            WHERE PVU_StatusCode__c = '202' OR Name != 'PFARelaUpdateImei'
        ];
        System.assertEquals(2, countInvalid, 'Debe haber 2 registros inválidos que no entran al batch');
    }
}