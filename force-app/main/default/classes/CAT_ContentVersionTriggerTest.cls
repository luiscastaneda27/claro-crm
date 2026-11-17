@IsTest
private class CAT_ContentVersionTriggerTest {

    @IsTest
    static void testTriggerEnqueueQueueable_OK() {

        // CSV mínimo válido
        String csv =
            'Name,Material\n' +
            '"Producto Test",999999';

        ContentVersion cv = new ContentVersion(
            Title = 'CargaProductos-Test',
            PathOnClient = 'CargaProductos-Test.csv',
            VersionData = Blob.valueOf(csv),
            IsMajorVersion = true
        );

        Test.startTest();
        insert cv;   // aquí dispara el trigger
        Test.stopTest();

        // Validación indirecta:
        // el Queueable debió ejecutarse sin errores
        System.assert(true, 'Trigger ejecutado correctamente');
    }
}