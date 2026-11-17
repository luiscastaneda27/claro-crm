@IsTest
public class PVU_ScheduleMassiveJobTest {

    // Método de prueba para invocar el método 'programBatch' exitosamente
    @IsTest
    static void testProgramBatchSuccess() {
        // Datos de prueba
        PVU_Gestiones_Masivas__c ejemplo1 = new PVU_Gestiones_Masivas__c();
        ejemplo1.PVU_Action__c = 'SUSPENSION';
        ejemplo1.PVU_BillingAccountId__c = '123123123';
        ejemplo1.PVU_Source__c = 'COLLECTIONS';
        ejemplo1.PVU_ReasonId__c = '221' ;
        ejemplo1.PVU_SuspensionLevel__c = '1';
        ejemplo1.PVU_Status__c = 'Pendiente';
        ejemplo1.PVU_JobIdentifier__c = 'TestJob123';
        ejemplo1.PVU_CustNum__c='312321321312';
        insert ejemplo1;
        Map<String, Object> input = new Map<String, Object>();
        input.put('minutes', 1);
        input.put('jobId', 'TestJob123');

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Llamada al método 'invokeMethod'
        Test.startTest();
        Boolean result = PVU_ScheduleMassiveJob.invokeMethod('programBatch', input, output, options);
        Test.stopTest();

        // Validaciones
        System.assertEquals(true, result, 'El método debería devolver true.');
        System.assertEquals(true, output.get('success'), 'La API fue correcta');
        System.assert(output.get('jobId') != null, 'El jobId debería estar presente en la salida.');
        System.assert(output.get('dateExecute') != null, 'La fecha de ejecución debería estar presente en la salida.');
    }

    // Método de prueba para manejo de excepción
    @IsTest
    static void testProgramBatchExceptionMinutes() {
        // Datos de prueba con valores incorrectos para provocar una excepción
        Map<String, Object> input = new Map<String, Object>();
        input.put('minutes', null); // Esto causará una excepción
        input.put('jobId', 'TestJobError');

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Llamada al método 'invokeMethod'
        Test.startTest();
        Boolean result = PVU_ScheduleMassiveJob.invokeMethod('programBatch', input, output, options);
        Test.stopTest();

        // Validaciones
        System.assertEquals(false, output.get('success'), 'Deberia ser False el resultado');
        System.assertEquals('The "minutes" parameter must be a positive integer', output.get('message'), 'Mensaje de error');
    }
     // Método de prueba para manejo de excepción jobId = Null
     @IsTest
     static void testProgramBatchExceptionJobId() {
         // Datos de prueba con valores incorrectos para provocar una excepción
         Map<String, Object> input = new Map<String, Object>();
         input.put('minutes', 1); 
         input.put('jobId', null); // Esto causará una excepción
 
         Map<String, Object> output = new Map<String, Object>();
         Map<String, Object> options = new Map<String, Object>();
 
         // Llamada al método 'invokeMethod'
         Test.startTest();
         Boolean result = PVU_ScheduleMassiveJob.invokeMethod('programBatch', input, output, options);
         Test.stopTest();
 
         // Validaciones
         System.assertEquals(false, output.get('success'), 'Deberia ser False el resultado');
         System.assertEquals('The JobId parameter must not be null or empty', output.get('message'), 'Mensaje de error');
     }

    // Método de prueba para invocar un método no existente
    @IsTest
    static void testMethodNotFound() {
        Map<String, Object> input = new Map<String, Object>();
        input.put('minutes', 1);
        input.put('jobId', 'TestJobNotFound');

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Llamada a un método inexistente
        Test.startTest();
        Boolean result = PVU_ScheduleMassiveJob.invokeMethod('unknownMethod', input, output, options);
        Test.stopTest();

        // Validaciones
        System.assertEquals(false, result, 'Deberia ser False el resultado');
        System.assertEquals('Method not found', output.get('error'), 'El mensaje de error debería indicar que el método no fue encontrado.');
    }
    // Método de prueba para manejar excepción por JobId sin registros pendientes
    @IsTest
    static void testProgramBatchNoPendingRecords() {
        // Insertar datos de prueba sin pendientes
        

        Map<String, Object> input = new Map<String, Object>();
        input.put('minutes', 1);
        input.put('jobId', 'test111');

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Llamada al método
        Test.startTest();
        Boolean result = PVU_ScheduleMassiveJob.invokeMethod('programBatch', input, output, options);
        Test.stopTest();

        // Validaciones
        System.assertEquals(false, output.get('success'), 'La ejecución debería fallar.');
        System.assertEquals('There are no pending registrations with the given JobId', output.get('message'), 'El mensaje de error debería coincidir.');
    }

}