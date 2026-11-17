/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase para convertir un archivo CSV en una cadena para el uso de GlobalKeys de productos en Flow.
Code Coverage: 100%
History
<Date> 		<Author>	 	<Description>		 <Version>
04-Sep-25	 Alan Semino  						inicial version
----------------------------------------------------------------------------*/
public with sharing class CATReadCSVFileAction {
    
    /*
    * @description 622605 - Clase apex que depura el contenido de archivo excel (CVS) para contenido especifico de GlobalKeys. 
    * @param  contentDocumentIds: Parametro inputs para Id de ContentDocument.
    * @return results : Lista de resultados de globalKeys dentro del documento.
    */
    @InvocableMethod(label='Leer archivo CSV' description='Lee el CSV y devuelve las Global Keys')
    public static List<List<String>> parseSingleCSV(List<List<String>> contentDocumentIds) {
        
        List<List<String>> results = new List<List<String>>();
        
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            results.add(new List<String>());
            return results;
        }
        
        ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentIds[0]  WITH SECURITY_ENFORCED LIMIT 1];
        
        List<String> globalKeys = new List<String>();
        if (cv != null && cv.VersionData != null) {
            String fileContent = cv.VersionData.toString();
            List<String> lines = fileContent.split('\n');
            
            for (Integer i = 1; i < lines.size(); i++) {
                String key = lines[i];
                if (key != null && key.trim() != '') {
                    globalKeys.add(key.trim());
                }
            }
        }
        
        results.add(globalKeys);
        return results;
    }
}