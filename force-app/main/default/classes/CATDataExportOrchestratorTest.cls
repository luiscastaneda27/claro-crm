/*---------------------------------------------------------------------------------------------------------------
Autor: Nahir Arrejoria 
Fecha: 2025-09-20
Equipo: Catálogo
Descripcion: Test class for CATDataExportOrchestrator
Code Coverage: N/A
History
<Date>            <Author>        	     <Description>             <Version>
2025-09-20         Nahir Arrejoria       Versión Inicial            0.1
----------------------------------------------------------------------------------------------------------------*/
@IsTest
private class CATDataExportOrchestratorTest {

    // Helper para crear un registro de CAT_Control_Interno_Digital__c
    private static CAT_Control_Interno_Digital__c createControlRecord() {
        CAT_Control_Interno_Digital__c control = new CAT_Control_Interno_Digital__c(
            CAT_Estado_Final__c = 'En proceso'
        );
        insert control;
        return control;
    }

    // Helper para crear registros de prueba en CAT_PreciosProductosExportados__c
    private static List<CAT_PreciosProductosExportados__c> createSampleRecords() {
        List<CAT_PreciosProductosExportados__c> records = new List<CAT_PreciosProductosExportados__c>();
        for (Integer i = 0; i < 2; i++) {
            records.add(new CAT_PreciosProductosExportados__c(
                CAT_CodigoProductoPrecios__c = 'TEST_PROD_' + i
            ));
        }
        insert records;
        return records;
    }

    @IsTest
    private static void testStartProcessing_Success() {
        // 1. Configuración de datos de prueba.
        createSampleRecords();
        CAT_Control_Interno_Digital__c controlRecord = createControlRecord();

        CATDataExportOrchestrator.InputRequest inputRequest = new CATDataExportOrchestrator.InputRequest();
        inputRequest.objetoControlId = controlRecord.Id;
        inputRequest.productCodes = new List<String>{'PROD1', 'PROD2'};
        inputRequest.promotionCodes = new List<String>{'PROMO1', 'PROMO2'};
        List<CATDataExportOrchestrator.InputRequest> inputs = new List<CATDataExportOrchestrator.InputRequest>{inputRequest};

        // 2. Ejecución del método.
        Test.startTest();

        List<List<String>> result = new List<List<String>>();
        try {
            // Simulamos la ejecución del InvocableMethod.
            result = CATDataExportOrchestrator.startProcessing(inputs);
        } catch(Exception e) {
            System.assert(false, 'Se encontró una excepción inesperada: ' + e.getMessage());
        }

        // Simulamos el procesamiento asíncrono del Batch Apex.
        Test.stopTest();

        // 3. Verificación de los resultados.
        // Se verifica que el método devolvió el resultado esperado.
        System.assertEquals(1, result.size(), 'La lista de salida debería contener un solo elemento.');
        System.assertEquals('Éxito', result[0][0], 'El primer elemento de la sublista debería ser "Éxito".');
        System.assertEquals('Proceso asíncrono iniciado.', result[0][1], 'El segundo elemento de la sublista debería ser el mensaje de éxito esperado.');
        
        // No se puede verificar directamente ApexJob. En su lugar,
        // se asume que si el método se ejecutó sin errores, el batch fue encolado.
        // Para una prueba más completa, se podría verificar la lógica del batch
        // en otra clase de prueba.
    }

    @IsTest
    private static void testStartProcessing_NoInput() {
        // 1. Configuración de datos de prueba: sin entrada.
        CATDataExportOrchestrator.InputRequest inputRequest = new CATDataExportOrchestrator.InputRequest();
        inputRequest.tipoCarga = 'Total';
        List<CATDataExportOrchestrator.InputRequest> inputs = new List<CATDataExportOrchestrator.InputRequest>{inputRequest};
        // 2. Ejecución del método.
        Test.startTest();
        List<List<String>> result = CATDataExportOrchestrator.startProcessing(inputs);
        Test.stopTest();

        // 3. Verificación de los resultados: se espera un mensaje de error.
        System.assertEquals(1, result.size(), 'La lista de salida debería contener un solo elemento.');
        System.assertEquals('ERROR', result[0][0], 'El primer elemento de la sublista debería ser "ERROR".');
        System.assertEquals('La entrada del Flow no puede estar vacía.', result[0][1], 'El mensaje de error debería ser el esperado.');
    }
}