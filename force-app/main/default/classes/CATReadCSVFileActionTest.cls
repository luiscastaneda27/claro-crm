/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase  test para CATReadCSVFileAction.
Code Coverage: 100%
History
<Date> 			<Author>	 	<Description>	 	<Version>
10-Sep-25	 	Alan Semino  						inicial version
----------------------------------------------------------------------------*/
@IsTest(SeeAllData=false)
public class CATReadCSVFileActionTest {
    
    private static Id createCsvContentDocument(List<String> keys) {
        String csv = 'GLOBAL KEY\n' + String.join(keys, '\n') + '\n';
        
        ContentVersion cv = new ContentVersion();
        cv.Title        = 'test_global_keys.csv';
        cv.PathOnClient = 'test_global_keys.csv';
        cv.VersionData  = Blob.valueOf(csv);
        insert cv;
        
        return [SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1].ContentDocumentId;
    }

    @IsTest
    static void parseCSV_happyPath() {
        List<String> keys = new List<String>{ 'GK_001', 'GK_002', 'GK_003' };
        Id contentDocumentId = createCsvContentDocument(keys);

        List<List<String>> input = new List<List<String>>{
            new List<String>{ String.valueOf(contentDocumentId) }
        };

        Test.startTest();
        List<List<String>> result = CATReadCSVFileAction.parseSingleCSV(input);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe devolver una sola lista (posición 0).');
        System.assertNotEquals(null, result[0], 'La lista no debe ser null.');
        System.assertEquals(3, result[0].size(), 'Deben venir las 3 global keys');
    }

    @IsTest
    static void parseCSV_emptyInput_returnsEmptyList() {
        List<List<String>> emptyInput = new List<List<String>>();

        Test.startTest();
        List<List<String>> result = CATReadCSVFileAction.parseSingleCSV(emptyInput);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe devolver una lista contenedora.');
        System.assertNotEquals(null, result[0], 'La lista interna no debe ser null.');
        System.assertEquals(0, result[0].size(), 'La lista interna debe estar vacía.');
    }
}