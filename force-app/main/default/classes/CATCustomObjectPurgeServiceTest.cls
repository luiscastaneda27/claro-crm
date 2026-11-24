/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase apex test para clase apex CATCustomObjectPurgeService.
Code Coverage: N/A
History
<Date> 			<Author>	 	<Description>		 <Version>
20-Sep-25	   Alan Semino 		inicial version
----------------------------------------------------------------------------*/
@IsTest
private class CATCustomObjectPurgeServiceTest {

    // Helper para crear registros de prueba en un objeto personalizado de forma dinámica
    private static List<SObject> createSampleRecords(String objectName, Integer count) {
        List<SObject> records = new List<SObject>();
        for (Integer i = 0; i < count; i++) {
            records.add(Schema.getGlobalDescribe().get(objectName).newSObject());
        }
        insert records;
        return records;
    }
    
    // Helper para crear un registro de control
    private static CAT_Control_Interno_Digital__c createControlRecord() {
        CAT_Control_Interno_Digital__c control = new CAT_Control_Interno_Digital__c(
            CAT_Estado_Final__c = 'En proceso'
        );
        insert control;
        return control;
    }
    
    // Test para los métodos start() y execute() para una purga simple.
    @IsTest
    private static void testPurgeBatch_Execution() {
        // 1. Configuración: Crea datos de prueba para la depuración.
        String objectToTest = 'CAT_ProductosExportados__c';
        createSampleRecords(objectToTest, 50);

        // 2. Ejecución: Instancia y ejecuta el batch.
        Test.startTest();
        // Le pasamos una lista vacía de objetos restantes para que no encadene.
        CATCustomObjectPurgeService purgeBatch = new CATCustomObjectPurgeService(
            objectToTest, new List<String>(), null, null, null, null, null
        );
        Database.executeBatch(purgeBatch);
        Test.stopTest();

        // 3. Verificaciones: Asegura que los registros fueron eliminados.
        Integer recordsAfterPurge = Database.countQuery('SELECT COUNT() FROM ' + objectToTest);
        System.assertEquals(0, recordsAfterPurge, 'Todos los registros deberían haber sido eliminados por el batch.');
    }
    
    // Test para el método finish() cuando encadena el siguiente batch.
    @IsTest
    private static void testPurgeBatch_Finish_ChainNextBatch() {
        // 1. Configuración: Crea datos de prueba para dos objetos.
        String firstObject = 'CAT_ProductosExportados__c';
        String secondObject = 'CAT_PromocionesExportadas__c';
        createSampleRecords(firstObject, 10);
        createSampleRecords(secondObject, 5);
        
        // La lista de encadenamiento contiene el segundo objeto.
        List<String> objectsToChain = new List<String>{secondObject};

        // 2. Ejecución: Se corre el batch para el primer objeto.
        Test.startTest();
        CATCustomObjectPurgeService firstPurgeBatch = new CATCustomObjectPurgeService(
            firstObject, objectsToChain, null, null, null, null, null
        );
        Database.executeBatch(firstPurgeBatch);
        Test.stopTest(); // Esto ejecuta el primer batch y su finish(), que encola el segundo batch.

        // 3. Verificaciones: Se asegura que los registros de ambos objetos fueron eliminados.
        Integer recordsInFirstObject = Database.countQuery('SELECT COUNT() FROM ' + firstObject);
        System.assertEquals(0, recordsInFirstObject, 'Los registros del primer objeto deben ser eliminados.');
        
        Integer recordsInSecondObject = Database.countQuery('SELECT COUNT() FROM ' + secondObject);
        System.assertEquals(0, recordsInSecondObject, 'Los registros del segundo objeto deben ser eliminados por el encadenamiento.');
    }
    
    // HDU 819649: El primer eslabón (isFirstBatch=true) debe nular el semáforo
    // CAT_ObjetoSeguimiento__c para bloquear una segunda ejecución.
    @IsTest
    private static void testPurgeBatch_BloqueaSegundaEjecucion() {
        // 1. Configuración: un registro de seguimiento habilitado ('X') de un run anterior.
        CAT_SeguimientoProductosExportados__c seg = new CAT_SeguimientoProductosExportados__c(
            CAT_ObjetoSeguimiento__c = 'X'
        );
        insert seg;
        String objectToTest = 'CAT_ProductosExportados__c';
        createSampleRecords(objectToTest, 5);

        // 2. Ejecución: primer eslabón con isFirstBatch=true, sin encadenar.
        Test.startTest();
        CATCustomObjectPurgeService purgeBatch = new CATCustomObjectPurgeService(
            objectToTest, new List<String>(), null, null, null, null, null, true
        );
        Database.executeBatch(purgeBatch);
        Test.stopTest();

        // 3. Verificación: el semáforo quedó en null (bloqueado) en el start().
        CAT_SeguimientoProductosExportados__c updated = [
            SELECT CAT_ObjetoSeguimiento__c FROM CAT_SeguimientoProductosExportados__c WHERE Id = :seg.Id
        ];
        System.assertEquals(null, updated.CAT_ObjetoSeguimiento__c, 'El semáforo debe quedar en null para bloquear una segunda ejecución.');
    }

    // Test para el finish() cuando es el último batch y debe llamar al servicio de extracción.
    @IsTest
    private static void testPurgeBatch_Finish_CallExtractionService() {
        // 1. Configuración: Crea datos de prueba y un registro de control.
        String objectToTest = 'CAT_PreciosProductosExportados__c';
        createSampleRecords(objectToTest, 10);

        List<String> objectsRemaining = new List<String>(); // Lista vacía para detener la cadena.
        CAT_Control_Interno_Digital__c controlRecord = createControlRecord();
        
        // El uso de Test.setMock es incorrecto para una clase concreta.
        // En su lugar, se confía en que la llamada a la clase de extracción real se hará.
        
        // 2. Ejecución: Se ejecuta el último batch de depuración.
        Test.startTest();
        CATCustomObjectPurgeService purgeBatch = new CATCustomObjectPurgeService(
            objectToTest, objectsRemaining, controlRecord.Id, new List<String>{'PROD_A'}, new List<String>{'PROMO_B'}, 'Total', false
        );
        Database.executeBatch(purgeBatch);
        Test.stopTest();

        // 3. Verificaciones: Se asegura que la depuración fue exitosa y que el servicio de extracción real actualizó el registro de control.
        Integer recordsAfterPurge = Database.countQuery('SELECT COUNT() FROM ' + objectToTest);
        System.assertEquals(0, recordsAfterPurge, 'Los registros del objeto de prueba deben ser eliminados.');
        
        // Verificamos el efecto secundario esperado del servicio de extracción.
        CAT_Control_Interno_Digital__c updatedControl = [SELECT CAT_Estado_Final__c FROM CAT_Control_Interno_Digital__c WHERE Id = :controlRecord.Id];
        System.assertEquals('Procesado', updatedControl.CAT_Estado_Final__c, 'El estado del registro de control debe ser actualizado por el proceso de extracción.');
    }
}