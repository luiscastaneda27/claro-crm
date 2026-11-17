@isTest
private class PVU_DeleteDocumentTemplateTest {

    @testSetup
    static void setupData() {
        // Crear un Case base
        insert new Case(
            Subject = 'Caso de prueba para borrar documentos',
            Origin = 'Phone',
            Status = 'New'
        );
    }

    @isTest
    static void testDeleteDocument_Success() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        // Crear archivo (ContentVersion → ContentDocument → ContentDocumentLink)
        ContentVersion cv = new ContentVersion(
            Title = 'ArchivoPrueba',
            PathOnClient = 'ArchivoPrueba.pdf',
            VersionData = Blob.valueOf('Contenido de prueba')
        );
        insert cv;

        // Recuperar ContentDocumentId
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Vincular archivo al Case
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V'
        );

        // Input simulando Integration Procedure
        Map<String, Object> input = new Map<String, Object>{
            'caseId' => c.Id
        };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_DeleteDocumentTemplate().invokeMethod('deleteDocument', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, ((String)output.get('result')).startsWith('Documentos eliminados con éxito'));
    }

    @isTest
    static void testDeleteDocument_NoDocs() {
        // Case nuevo sin archivos
        Case c = new Case(
            Subject = 'Caso sin docs',
            Origin = 'Email',
            Status = 'New'
        );
        insert c;

        Map<String, Object> input = new Map<String, Object>{ 'caseId' => c.Id };
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_DeleteDocumentTemplate().invokeMethod('deleteDocument', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('El caso no tiene documentos relacionados', (String)output.get('result'));
    }

    @isTest
    static void testDeleteDocument_NoCaseId() {
        Map<String, Object> input = new Map<String, Object>(); // vacío
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_DeleteDocumentTemplate().invokeMethod('deleteDocument', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('Sin caseId recibido', (String)output.get('result'));
    }

    @isTest
    static void testDeleteDocument_InvalidCaseId() {
        Map<String, Object> input = new Map<String, Object>{ 'caseId' => 'ABC123' }; // inválido
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        new PVU_DeleteDocumentTemplate().invokeMethod('deleteDocument', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assert(((String)output.get('result')).startsWith('caseId inválido'));
    }
}