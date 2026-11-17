/*------------------------------------------------------------
Author:        	Luis Mendoza
Company:       	Salesforce.com
Description:   	Class to call service handle document
Test Class:    	ProductOrderPaymentConfirmation_Test
History
<Date>      	<Author>     	<Change Description>
29-Abril-2024	Luis Mendoza	Initial Version
05-May-2024	    Luis Mendoza	version change to method add "type" and "name" document
30-Oct-2024	    Luis Mendoza	version change to add new paramaters  
20-Feb-2026		Fabian Quintero	version change to modify input map for document_ext
------------------------------------------------------------*/
global with sharing class PVU_CalloutHandlerDocument implements vlocity_cmt.VlocityOpenInterface {


    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('getCallOutHandlerDocument')) {
                getCallOutHandlerDocument(inputMap, outMap, options);
            } else {
                result = false;
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;
        
    }

    global static void getCallOutHandlerDocument(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Map<String,String> dataResp = new Map<String,String>();
        Map<String, Object> bodyJs = new Map<String, Object>();
        try {

            String idDocument = (String) inputMap.get('idDocument');
            String caseNumber = (String) inputMap.get('CaseNumber');
            String contentVersionId =   String.isBlank(idDocument) ? (String) inputMap.get('contentVersionId') : idDocument;  
            Map<String, Object> document = (Map<String, Object>) inputMap.get('document');
            //Map<String, Object> document_ext = (Map<String, Object>) inputMap.get('document_ext'); -- modified by accepting null values
            Object extObj = inputMap.get('document_ext');
			Map<String, Object> document_ext = null; // Initialized as null

			if (extObj instanceof Map<String, Object>) {
    			document_ext = (Map<String, Object>) extObj;
				} else {
		    System.debug('Warning: document_ext is not a valid map (received empty or null).');
						}
            

            String docName = (String) inputMap.get('docName');
            String target = (String) String.valueOf(inputMap.get('target'));
            String serieDocumental = (String) String.valueOf(inputMap.get('serieDocumental'));

            String apiKey = (String) inputMap.get('apiKey');
            String urlPath = (String) inputMap.get('urlPath');

            List<ContentVersion> contVers =  [SELECT id, VersionData, ContentDocument.Title, FileType FROM ContentVersion WHERE Id = :contentVersionId WITH USER_MODE LIMIT 1];
            
            if(contVers.size()> 0){
                String fileType = contVers[0].FileType;
                String docNameString = String.isBlank(docName) ? caseNumber +'_'+ contVers[0].ContentDocument.Title + '.' + fileType.toLowerCase() : docName;
                
                bodyJs.put('idDocument', idDocument);
                bodyJs.put('docContent', contVers[0].VersionData);
                bodyJs.put('docName', docNameString); 
                bodyJs.put('document', document);  
                bodyJs.put('document_ext', document_ext);  
                bodyJs.put('serieDocumental',  String.isBlank(serieDocumental) ? '1' : serieDocumental);
                bodyJs.put('target', String.isBlank(target) ? '1' : target); 

                System.debug('body:::: ' + JSON.serialize(bodyJs));
            
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:NamedCredentialIntegrations'+ urlPath);
                req.setTimeout(60000);
                req.setMethod('POST');
                req.setHeader('ApkSitSfic',apiKey);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(bodyJs));
              
                Http h = new Http();
               // Send the request, and return a response
               HttpResponse res = h.send(req);
               outMap.put('resultService', JSON.deserializeUntyped(res.getBody()));
               
            }else{
                dataResp.put('message', 'ContentVersion not found');
                outMap.put('code', '400');
                outMap.put('data', dataResp);
                outMap.put('message', 'ERROR');
            }            
            
        } catch (Exception e) {
            System.debug('Error'+ e.getMessage() + ' ' + e.getCause() + ' ' + e.getLineNumber());
            dataResp.put('message', e.getMessage());
            outMap.put('code', '400');
            outMap.put('data', dataResp);
            outMap.put('message', 'ERROR');
        }

        outMap.remove('errorCode');
        outMap.remove('error');
      }
}