/*--------------------------------------------------------------------------
 Author: Eduardo Wentancur
 Company: Salesforce.com
 Description: Elimina los documentos de Salesforce relacionados a un Case
 Code Coverage: 100%
 History
 <Date>     <Author>   <Description>                       <Version>
 15-Sep-25  Eduardo W  Proceso genérico usando caseId      2da version
----------------------------------------------------------------------------*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PVU_DeleteDocumentTemplate implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        if (methodName.equalsIgnoreCase('deleteDocument')) {
            output.put('result', deleteDocument(input, output, options));
        }
        return true;
    }

    public static String deleteDocument(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        String caseIdStr = (String) input.get('caseId');
        if (String.isBlank(caseIdStr)) {
            return 'Sin caseId recibido';
        }

        Id caseId;
        try {
            caseId = Id.valueOf(caseIdStr);
        } catch (Exception e) {
            return 'caseId inválido: ' + caseIdStr;
        }

        // 1) Obtener ContentDocumentIds vinculados al caso
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
            WITH SECURITY_ENFORCED
        ];
        if (docLinks.isEmpty()) {
            return 'El caso no tiene documentos relacionados';
        }

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
        }

        // 2) Consultar y eliminar ContentDocument
        if (Schema.sObjectType.ContentDocument.isDeletable()) {
            List<ContentDocument> docs = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :docIds
                WITH SECURITY_ENFORCED
            ];
            delete docs;
            return 'Documentos eliminados con éxito: ' + docs.size();
        } else {
            return 'No tienes permisos para eliminar ContentDocument';
        }
    }
}