/*--------------------------------------------------------------------------------
Author:
Company:
Description:  API que crea un job asíncrono para ejecutar el proceso batch de actualización de precios para Terminales y Tecnología
Code Coverage:  NA
History
<Date>            <Author>             <Description>             <Version>

----------------------------------------------------------------------------------*/
@RestResource(urlMapping='/ejecutarActualizacionPreciosTyT/*')
global with sharing class CAT_ejecutarActualizacionPreciosTyT {

   @HttpPost
   global static String actualizarPreciosTyT() {
      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
      String bulkJobId = req.params.get('jobId');
      System.debug('bulkJobId: ' + bulkJobId);
      System.debug('actualizarPreciosTyT POST Request: ' + JSON.serialize(req));
      //CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch();
      CATActualizacionPreciosSAPBatch actualizarPreciosTyTBatch = new CATActualizacionPreciosSAPBatch(bulkJobId);
      String jobId = Database.executeBatch(actualizarPreciosTyTBatch,1);
       System.debug('actualizarPreciosTyT jobId: ' + jobId);
      return jobId;
   }
}