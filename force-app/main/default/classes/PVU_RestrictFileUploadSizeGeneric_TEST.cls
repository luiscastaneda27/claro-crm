/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class Test to manage the coverage code for the class PVU_RestrictFileUploadSizeGeneric
History
<Date>          <Author>        <Change Description>
23/10/2024      Luis Mendoza 	Initial Version
06/02/2025      Mariana Olay    Se modifica cobertura clase para que el componente
								sea dinamico con "n" número de documentos.
------------------------------------------------------------*/
@isTest
private class PVU_RestrictFileUploadSizeGeneric_TEST {

    @TestSetup
    static void methodName() {
        Integer fileSizeInBytes = (1024 * 1024) * 3;
        Blob largeFileBlob = Blob.valueOf(String.valueOf('A').repeat(fileSizeInBytes));
        String fileContentBase64 = EncodingUtil.base64Encode(largeFileBlob);
		ContentVersion contentVersionInsert = new ContentVersion();
        contentVersionInsert.Title = 'Test';
        contentVersionInsert.PathOnClient = 'Test.jpg';
        contentVersionInsert.VersionData = EncodingUtil.base64Decode(fileContentBase64);
        contentVersionInsert.IsMajorVersion = true;
        insert contentVersionInsert; 
        
        ContentVersion contentVersionInsert2 = new ContentVersion();
        contentVersionInsert2.Title = 'Test2';
        contentVersionInsert2.PathOnClient = 'Test2.jpg';
        contentVersionInsert2.VersionData = Blob.valueOf('Test Upload File 2.0');
        contentVersionInsert2.IsMajorVersion = true;
        insert contentVersionInsert2;
    }

    @isTest
    static void contentSizeTest() {
        ContentDocument docObj = [SELECT id FROM ContentDocument 
        WHERE Title = 'Test' WITH SYSTEM_MODE limit 1] ;
        Map<String, List<String>> msg = PVU_RestrictFileUploadSizeGeneric.contentSize(new List<String>{docObj.id});
        Assert.areEqual('ERROR', msg.get('status').get(0), 'OK message');
        
        ContentDocument docObj2 = [SELECT id FROM ContentDocument 
        WHERE Title = 'Test2' WITH SYSTEM_MODE limit 1] ;
        Map<String, List<String>> msg2 = PVU_RestrictFileUploadSizeGeneric.contentSize(new List<String>{docObj2.id});
        Assert.areEqual('SUCCSESS', msg2.get('status').get(0), 'OK message');
    }
}