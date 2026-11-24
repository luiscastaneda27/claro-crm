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
    // HDU 819649: true solo en el primer eslabón de la cadena de purga. Se usa para
    // nulear el semáforo de habilitación una única vez al arrancar el proceso.
    private Boolean isFirstBatch;

    /**
     * @description Constructor que recibe el objeto a depurar y los parámetros para la siguiente clase CATDataExtractionService.
     */
    public CATCustomObjectPurgeService(String objectApiName, List<String> objectsRemaining, String objetoControlId, List<String> prodCodeList, List<String> promotionCodeList, String tipoCarga,Boolean incluirCompatibilidad) {
        this(objectApiName, objectsRemaining, objetoControlId, prodCodeList, promotionCodeList, tipoCarga, incluirCompatibilidad, false);
    }

    /**
     * @description HDU 819649 - Sobrecarga con isFirstBatch. El Orchestrator lo invoca con
     * isFirstBatch=true para el primer objeto; la re-instanciación en finish() usa false.
     */
    public CATCustomObjectPurgeService(String objectApiName, List<String> objectsRemaining, String objetoControlId, List<String> prodCodeList, List<String> promotionCodeList, String tipoCarga, Boolean incluirCompatibilidad, Boolean isFirstBatch) {
        this.objectApiName = objectApiName;
        this.objectsRemaining = objectsRemaining;
        this.objetoControlId = objetoControlId;
        this.prodCodeList = prodCodeList;
        this.promotionCodeList = promotionCodeList;
        this.tipoCarga = tipoCarga;
        this.incluirCompatibilidad = incluirCompatibilidad;
        this.isFirstBatch = isFirstBatch;
    }

    /**
     * @description Define la consulta para los registros a procesar.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Iniciando batch job para el objeto: ' + objectApiName);

        // HDU 819649: Bloqueo de segunda ejecución. Al arrancar el proceso (primer eslabón),
        // se nulea CAT_ObjetoSeguimiento__c de los registros de seguimiento existentes. Ese
        // campo en 'X' es el semáforo que el Flow lee para habilitar un nuevo proceso; mientras
        // la purga corre, el registro del run anterior sigue vivo con 'X' hasta que se depura
        // CAT_SeguimientoProductosExportados__c (último objeto de la lista), dejando una ventana
        // en la que el Flow permitiría una segunda ejecución. Nularlo aquí cierra esa ventana.
        // Best-effort: si el update falla, se registra y el proceso continúa.
        if (isFirstBatch == true) {
            lockNuevaEjecucion();
        }

        return Database.getQueryLocator('SELECT Id FROM ' + objectApiName + ' WITH SECURITY_ENFORCED');
    }

    /**
     * @description HDU 819649 - Nulea el semáforo CAT_ObjetoSeguimiento__c en los registros
     * de seguimiento existentes para impedir que el Flow habilite una segunda ejecución
     * mientras este proceso está en curso.
     */
    private void lockNuevaEjecucion() {
        try {
            List<CAT_SeguimientoProductosExportados__c> seguimientos = [
                SELECT Id, CAT_ObjetoSeguimiento__c
                FROM CAT_SeguimientoProductosExportados__c
                WHERE CAT_ObjetoSeguimiento__c != null
            ];
            if (!seguimientos.isEmpty()) {
                for (CAT_SeguimientoProductosExportados__c seg : seguimientos) {
                    seg.CAT_ObjetoSeguimiento__c = null;
                }
                update seguimientos;
                System.debug('HDU 819649: Se bloqueó una nueva ejecución nulando ' + seguimientos.size() + ' registro(s) de seguimiento.');
            }
        } catch (Exception e) {
            // Best-effort: no frenar el proceso si no se pudo nular el semáforo.
            System.debug('HDU 819649: No se pudo nular el semáforo de seguimiento: ' + e.getMessage());
        }
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
                this.incluirCompatibilidad,
                false // HDU 819649: eslabones siguientes no repiten el bloqueo
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