@isTest
private class CAT_consultaJobActualizacionPrecios_Test {
 @isTest
    static void testGetNumber_ValidJobId_InternalJobId() {
        CATActualizacionPreciosSAPBatchTest.setup();
        Id jobId;
        String jobId15;
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016901',CAT_Precio_IVA_Final_Red_ZP05__c= '1016901', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2200-08-13',CAT_Id_Job_Externo__c ='2345', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = ''
        );
        insert precio;
        RestRequest req1  = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.addParameter('jobId', precio.CAT_Id_Job_Externo__c);
        
        RestContext.request  = req1;
        RestContext.response = res1;

        Test.startTest();
            jobId = CAT_ejecutarActualizacionPreciosTyT.actualizarPreciosTyT();
        Test.stopTest();
        jobId15 = jobId.to15();
        System.debug('Consulta Test actualizarPreciosTyT jobId: ' + jobId);
        System.debug('Consulta Test actualizarPreciosTyT jobId15: ' + jobId15);

        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = : jobId];

        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri   = '/services/apexrest/consultaJobActualizacionPrecios?jobId=' + jobId15;
        req.httpMethod   = 'GET';
        req.addParameter('jobId', jobId15);

        RestContext.request  = req;
        RestContext.response = res;

        CAT_consultaJobActualizacionPrecios.responseObject resObj = CAT_consultaJobActualizacionPrecios.getNumber();
        System.debug('apex job: ' + job);
        System.debug('resObj ' + resObj);
        List<CAT_Informacion_Precios_SAP_tmp__c> resultadoProcRecords = [SELECT CAT_Equipo__c,CAT_Desc_Comercial__c,CAT_Lista_Precio__c,CAT_FechaInicioVigencia__c,CAT_Id_Job_Procesamiento__c,CAT_Resultado_Procesamiento__c,CAT_Descripcion_Procesamiento__c,CAT_Id_Job_Externo__c FROM CAT_Informacion_Precios_SAP_tmp__c WITH USER_MODE];
        System.debug('resultadoProcRecords: ' + JSON.serialize(resultadoProcRecords));

        Assert.areEqual(jobId15, resObj.jobId);
        Assert.areEqual(job.JobItemsProcessed, resObj.completedRecords);
        Assert.areEqual(job.TotalJobItems - job.JobItemsProcessed, resObj.pendingRecords);
        Assert.areEqual(job.NumberOfErrors, resObj.errorRecords);
        Assert.areEqual(true, resObj.total >= 0);
        Assert.areNotEqual(null, resObj.jobComplete);
    }

    @isTest
    static void testGetNumber_ValidJobId_ExternalJobId() {
        CATActualizacionPreciosSAPBatchTest.setup();
        Id jobId;
        CAT_Informacion_Precios_SAP_tmp__c precio = new CAT_Informacion_Precios_SAP_tmp__c(
            CAT_Equipo__c = '70012345', CAT_Desc_Comercial__c = 'Product handset', CAT_Lista_Precio__c = '04_SF TEC', CAT_Precio_sin_IVA_ZP06__c ='1016900',CAT_Precio_IVA_Final_Red_ZP05__c= '1016900', 
            CAT_ValorDescuento__c = '0', CAT_FechaInicioVigencia__c ='2199-08-13',CAT_Id_Job_Externo__c ='2345', CAT_Id_Job_Procesamiento__c = '', CAT_Resultado_Procesamiento__c = ''
        );
        insert precio;
        RestRequest req1  = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.addParameter('jobId', precio.CAT_Id_Job_Externo__c);
        
        RestContext.request  = req1;
        RestContext.response = res1;
  
        Test.startTest();
            jobId = CAT_ejecutarActualizacionPreciosTyT.actualizarPreciosTyT();
        Test.stopTest();
        System.debug('actualizarPreciosTyT jobId: ' + jobId);
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id = : jobId];
        
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri   = '/services/apexrest/consultaJobActualizacionPrecios?externalJobId=' + precio.CAT_Id_Job_Externo__c;
        req.httpMethod   = 'GET';
        req.addParameter('externalJobId', precio.CAT_Id_Job_Externo__c);
        
        RestContext.request  = req;
        RestContext.response = res;

        CAT_consultaJobActualizacionPrecios.responseObject resObj = CAT_consultaJobActualizacionPrecios.getNumber();
        System.debug('resObj ' + resObj);

        Assert.areEqual(job.Id, resObj.jobId);
        Assert.areEqual(job.JobItemsProcessed, resObj.completedRecords);
        Assert.areEqual(job.TotalJobItems - job.JobItemsProcessed, resObj.pendingRecords);
        Assert.areEqual(job.NumberOfErrors, resObj.errorRecords);
        Assert.areEqual(true, resObj.total >= 0);
        Assert.areNotEqual(null, resObj.jobComplete);
    }

    @isTest
    static void testGetNumber_MissingJobId() {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri   = '/services/apexrest/consultaJobActualizacionPrecios';
        req.httpMethod   = 'GET';
        RestContext.request  = req;
        RestContext.response = res;

        CAT_consultaJobActualizacionPrecios.responseObject response = CAT_consultaJobActualizacionPrecios.getNumber();

        Assert.areEqual('Es necesario enviar un Id de job para realizar la consulta', response.message);
    }
}