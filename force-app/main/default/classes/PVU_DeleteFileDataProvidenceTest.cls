@IsTest(SeeAllData=true)
private class PVU_DeleteFileDataProvidenceTest {

    @IsTest
    static void testBatch() {

        Case c = new Case(
            Subject = 'Caso Test',
            Status = 'Cerrado',
            PVU_Level1__c = 'Solicitud de información y modificaciones',
            PVU_Level2__c = 'Reconexión de servicios',
            PVU_Level3__c = 'Reconexión Suspensión Temporal Voluntaria'
            
        );
        insert c;

        ContentVersion cv = new ContentVersion(
            Title = 'Archivo Test',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('contenido')
        );
        insert cv;


          /* Obtener ContentDocumentId */
        ContentVersion cvInserted = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id WITH SYSTEM_MODE
        ];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = c.Id,
            ContentDocumentId = cvInserted.ContentDocumentId,
            ShareType = 'V'
           
        );
        insert cdl;

        Test.startTest();
        Database.executeBatch(
            new PVU_DeleteFileDataProvidence(true),
            200
        );
        Test.stopTest();

        Integer archivos = [
            SELECT COUNT()
            FROM ContentDocument
        ];

        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentDocument WHERE Id = :cvInserted.ContentDocumentId WITH SYSTEM_MODE]
        );
        
    }

     @IsTest
    static void testSchedule() {

        Test.startTest();
        String jobId = System.schedule(
            'Test Schedule',
            '0 0 0 1 1 ? 2099',
            new PVU_DeleteFileDataProvidenceBatch()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}