/*-------------------------------------------------------------------------- 
 Author: Johana Dutan 
 Company: Salesforce.com 
 Description: Clase para ejecutar Integration Procedures con reintentos 
 Code Coverage: 100%
 History 
 <Date>     <Author>        <Description>                                      		<Version> 
 12-Sep-25  Johana D        Creación inicial de la clase con manejo de reintentos  	1ra versión 
----------------------------------------------------------------------------*/
global with sharing class PVU_UploadCaseFilG implements vlocity_cmt.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        try {  
            if (methodName.equals('pHandlerDocument')) {
                pHandlerDocument(input, outMap, options);
            } else {
                outMap.put('errormessage', 'Método no soportado: ' + methodName);
                return false;
            }
        } catch (Exception e) {
            outMap.put('errormessage', e.getMessage());
            return false;
        }  
        return true;
    }

    /**
     * Llama al IP con hasta 2 intentos si responseCode != 200.
     */
    global static void pHandlerDocument(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        if (input == null) input = new Map<String, Object>();
        if (options == null) options = new Map<String, Object>();

        Integer maxRetries = Integer.valueOf(String.valueOf(input.get('maxRetries')));
        String ipName = String.valueOf(input.get('nameIP'));
        Integer attempt = 0;
        Boolean success = false;
        Map<String, Object> response = new Map<String, Object>();

        while (attempt < maxRetries && !success) {
            attempt++;
            try {
                if (Test.isRunningTest() && input.containsKey('fakeResponse')) {
                    // 👇 Siempre damos respuesta controlada desde test
                    response = (Map<String, Object>) input.get('fakeResponse');
                } else {
                response = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                    ipName,
                    input,
                    options
                );
                }

                System.debug('Intento ' + attempt + ' → Respuesta: ' + JSON.serializePretty(response));

                if (response.containsKey('responseCode') && String.valueOf(response.get('responseCode')) == '200') {
                    success = true;
                } else {
                    System.debug('Falló intento ' + attempt + ', responseCode: ' + response.get('responseCode'));
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Excepción en intento ' + attempt + ': ' + e.getMessage());
                response.put('error', e.getMessage());
            }
        }

        // Copiar la última respuesta al outMap
        outMap.putAll(response);

        if (!success) {
            outMap.put('errormessage', 'No se obtuvo código 200 tras ' + maxRetries + ' intentos');
        }
    }

    
}