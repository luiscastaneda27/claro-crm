/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase Batchable para depurar registros y orquestar el siguiente
 * paso de la extracción.
 * Code Coverage: 96%
 * History
 * <Date> 	 	<Author> 	 	<Description>	 	 						<Version>
 * 07-Sep-25	Hugo Revuelta	Version inicial 						 	0.1
 * 20-Sep-25	Hugo Revuelta   Depuración enqueueable						1.0
 
 ----------------------------------------------------------------------------*/
public with sharing class CATCustomObjectPurgeService implements Database.Batchable<SObject>, Database.Stateful {
    
    private String objectApiName;
    private List<String> objectsRemaining;
    private String objetoControlId;
    private List<String> prodCodeList;
    private List<String> promotionCodeList;
    private String tipoCarga;
    private Boolean incluirCompatibilidad;

    /**
     * @description Constructor que recibe el objeto a depurar y los parámetros para la siguiente clase CATDataExtractionService.
     */
    public CATCustomObjectPurgeService(String objectApiName, List<String> objectsRemaining, String objetoControlId, List<String> prodCodeList, List<String> promotionCodeList, String tipoCarga,Boolean incluirCompatibilidad) {
        this.objectApiName = objectApiName;
        this.objectsRemaining = objectsRemaining;
        this.objetoControlId = objetoControlId;
        this.prodCodeList = prodCodeList;
        this.promotionCodeList = promotionCodeList;
        this.tipoCarga = tipoCarga;
        this.incluirCompatibilidad = incluirCompatibilidad;
    }

    /**
     * @description Define la consulta para los registros a procesar.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Iniciando batch job para el objeto: ' + objectApiName);
        return Database.getQueryLocator('SELECT Id FROM ' + objectApiName + ' WITH SECURITY_ENFORCED');
    }

    /**
     * @description Procesa cada lote de registros.
     */
    public void execute(Database.BatchableContext bc, List<SObject> recordsToDelete) {
        if (!recordsToDelete.isEmpty()) {
            try {
                // Borra el lote completo en una única operación DML.
                Database.delete(recordsToDelete, false);
                Database.emptyRecycleBin(recordsToDelete);
                System.debug('Se eliminaron ' + recordsToDelete.size() + ' registros de ' + objectApiName + '.');
            } catch(Exception e) {
                System.debug('Error en el batch para ' + objectApiName + ': ' + e.getMessage());
            }
        }
    }

    /**
     * @description El método final que se ejecuta una vez que el batch ha terminado.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job para ' + objectApiName + ' finalizado con éxito.');

        if (!objectsRemaining.isEmpty()) {
            String nextObject = objectsRemaining.remove(0); 
            // Encola el siguiente batch en la cadena.
            CATCustomObjectPurgeService nextPurgeBatch = new CATCustomObjectPurgeService(
                nextObject,
                objectsRemaining,
                this.objetoControlId,
                this.prodCodeList,
                this.promotionCodeList,
                this.tipoCarga,
                this.incluirCompatibilidad
            );
            Database.executeBatch(nextPurgeBatch);
        } else {
            // La depuración ha terminado. Invoca la clase de extracción.
            System.debug('La depuración ha finalizado. Iniciando el proceso de extracción de datos.');
            try {
              
                CAT_SeguimientoProductosExportados__c logRecord = new CAT_SeguimientoProductosExportados__c( CAT_FechaInicioSfSeguimiento__c = datetime.NOW(), CAT_JobIdSfSeguimiento__c  = objetoControlId);
        		System.debug('Se crea registro de seguimiento para: '+objetoControlId);
                insert logRecord;
                
                CATDataExtractionService.extractAndLoadData(
                    this.objetoControlId, 
                    logRecord.Id,
                    this.prodCodeList, 
                    this.promotionCodeList,
                    this.tipoCarga,
                	this.incluirCompatibilidad
                );
            } catch (Exception e) {
                System.debug('Error durante la extracción: ' + e.getMessage());
            }
        }
    }
}