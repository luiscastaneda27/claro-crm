/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase Orquestadora responsable de ejecutar los procesos de extracción/actualización de catalogo.
 * Code Coverage: 93%
 * History
 * <Date> 	 	<Author> 	 	<Description>	 	 		<Version>
 * 07-Sep-25	Hugo Revuelta	Version inicial 	 		0.1
 * 20-Sep-25	Hugo Revuelta   Encadenamiento asíncrono	1.0
 
 ----------------------------------------------------------------------------*/
public with sharing class CATDataExportOrchestrator {
    
    // La firma del método se mantiene exactamente igual para no romper el Flow.
    @InvocableMethod(label='Iniciar Proceso de Exportación' description='Inicia la depuración y exportación de datos de manera asíncrona.')
    public static List<List<String>> startProcessing(List<InputRequest> input) {
        List<List<String>> processOutputList = new List<List<String>>();
		System.debug('input.get(0).tipoCarga: '+ input.get(0).tipoCarga);        
        if (input == null || input.isEmpty() || (input.get(0).tipoCarga != 'Compatibilidad' && (input.get(0).productCodes == null && input.get(0).promotionCodes == null )) ){
            // Retorna una respuesta de error con el formato esperado.
            processOutputList.add(new List<String>{'ERROR', 'La entrada del Flow no puede estar vacía.'});
            return processOutputList;
        }

        try {
            // Lista completa de objetos a depurar.
            List<String> objectsToPurge = new List<String>{
                'CAT_ProductosExportados__c',
                'CAT_PromocionesExportadas__c',
                'CAT_AtributosProductosExportados__c',
                'CAT_CompatibilidadProductosExportados__c',
                'CAT_PreciosProductosExportados__c',
                'CAT_SeguimientoProductosExportados__c'
            };
            
            // Se extraen los parámetros del Flow.
            String objetoControlId = input.get(0).objetoControlId;
            List<String> prodCodeList = input.get(0).productCodes;
            List<String> promotionCodeList = input.get(0).promotionCodes;
            String tipoCarga = input.get(0).tipoCarga;
            Boolean incluirCompatibilidad = input.get(0).incluirCompatibilidad;
            // Inicia el proceso asíncrono encolando el primer Batch.
            if (!objectsToPurge.isEmpty()) {
                String firstObjectToPurge = objectsToPurge.remove(0);
                
                CATCustomObjectPurgeService purgeBatch = new CATCustomObjectPurgeService(
                    firstObjectToPurge,
                    objectsToPurge, // Pasa la lista de objetos restantes para la cadena.
                    objetoControlId,
                    prodCodeList,
                    promotionCodeList,
                    tipoCarga,
                    incluirCompatibilidad
                    
                );
                Database.executeBatch(purgeBatch);
            }
            
            // Retorna inmediatamente una respuesta de éxito.
            processOutputList.add(new List<String>{'Éxito', 'Proceso asíncrono iniciado.'});
            //CATDataExtractionService.extractAndLoadData(objetoControlId,prodCodeList,promotionCodeList);
            
        } catch (Exception e) {
            // Retorna una respuesta de error si falla la orquestación inicial.
            processOutputList.add(new List<String>{'ERROR', e.getMessage()});
        }
        
        return processOutputList;
    }
    
    // InputRequest.
    @TestVisible
    public class InputRequest {
        @InvocableVariable public String objetoControlId;
        @InvocableVariable public List<String> productCodes;
        @InvocableVariable public List<String> promotionCodes;
        @InvocableVariable public String tipoCarga;
        @InvocableVariable public Boolean incluirCompatibilidad;
    }
}