@isTest
public class CAT_ejecutarActualizacionPreciosTyT_Test {
    @isTest
    static void actualizarPreciosTyTTest () {
        CATActualizacionPreciosSAPBatchTest.setup();
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2025-08-13', CAT_Id_Job_Externo__c = '2344', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = ''
        );
        insert precio;

        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.addParameter('jobId', precio.CAT_Id_Job_Externo__c);
        
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        Id jobId = CAT_ejecutarActualizacionPreciosTyT.actualizarPreciosTyT();
        Test.stopTest();
        
        List<CAT_Informacion_Precios_SAP_tmp__c> jobList = [SELECT CAT_Id_Job_Procesamiento__c FROM CAT_Informacion_Precios_SAP_tmp__c WHERE CAT_Equipo__c = '70012345' WITH USER_MODE];
        System.assertEquals(1, jobList.size(), 'El job id se actualizó correctamente');
    }
}