/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class to restrict file size
Test Class:     PVU_RestrictFileUploadSizeGeneric_TEST
History
<Date>          <Author>        <Change Description>
23/10/2024      Luis Mendoza 	Initial Version
06/02/2025      Mariana Olay    Se modifica la clase para que el componente
								sea dinamico con "n" número de documentos.
------------------------------------------------------------*/
public with sharing class PVU_RestrictFileUploadSizeGeneric {
    @AuraEnabled
    public static Map<String, List<String>> contentSize(List<String> lstrecordId) {
        Integer size;
        List<ContentDocument> invalidDocsObj = new List<ContentDocument>();
        List<String> invalidDocsId = new List<String>();
        List<String> statusDocs = new List<String>();
        Map<String, List<String>> responseInvalidDocs = new Map<String, List<String>>();
        List<ContentDocument> docObj = [SELECT id,contentsize, Title  FROM ContentDocument 
                                        WHERE id  IN :lstrecordId WITH SYSTEM_MODE] ;

        InterfaceSettings__mdt sizeFile = [SELECT idcode__c, descripcion__c, identificador__c FROM InterfaceSettings__mdt 
                                            WHERE DeveloperName = 'PVU_MaxSizeFile_Tercero' WITH SYSTEM_MODE LIMIT 1];  
        
        for(ContentDocument file : docObj) {
            size = file.contentsize;
            if(size > Integer.valueOf(sizeFile.idcode__c)){
                invalidDocsObj.add(file);
                invalidDocsId.add(file.Id);
            }
        }
        if(invalidDocsObj.size() > 0) {
            responseInvalidDocs.put('lstDocsId',invalidDocsId);
            statusDocs.add('ERROR');
            responseInvalidDocs.put('status',statusDocs);
            delete as system invalidDocsObj;
            return responseInvalidDocs;
        } else {
            statusDocs.add('SUCCSESS');
            responseInvalidDocs.put('status',statusDocs);
            return responseInvalidDocs;
        }
    }
}