/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase responsable de extraer datos de Salesforce y cargarlos 
 * en objetos custom para su posterior exportación.
 * Code Coverage: 91%
 * History
 * <Date>       <Author>        <Description>       											<Version>
 * 07-Oct-25	Nahir Arrejoria	Implementación de logica de extracción y llenado de objetos		0.1
 * 
 *----------------------------------------------------------------------------*/
public with sharing class CATCompatibilityExportBatch implements Database.Batchable<SObject>{
    
    // Start method: Queries all the records to be processed.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // This query will select all CatalogProductRelationship records and pass them to the execute method in chunks.
        return Database.getQueryLocator([
            SELECT vlocity_cmt__Product2Id__c, vlocity_cmt__CatalogId__r.Name, vlocity_cmt__CatalogId__r.vlocity_cmt__CatalogCode__c,
                   vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.Name, vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.vlocity_cmt__Code__c,
                   vlocity_cmt__Product2Id__r.Name, vlocity_cmt__Product2Id__r.ProductCode, vlocity_cmt__CatalogId__r.vlocity_cmt__StartDateTime__c,
                   vlocity_cmt__CatalogId__r.vlocity_cmt__EndDateTime__c, vlocity_cmt__CatalogId__r.vlocity_cmt__IsActive__c
            FROM vlocity_cmt__CatalogProductRelationship__c
            WITH SECURITY_ENFORCED
        ]);
    }
    
    
    // Execute method: Contains the core processing logic for each chunk of records.
    public void execute(Database.BatchableContext bc, List<vlocity_cmt__CatalogProductRelationship__c> scope) {
        System.debug('Processing a batch of ' + scope.size() + ' records.');

        List<CAT_CompatibilidadProductosExportados__c> compatibilidadProdExportados = new List<CAT_CompatibilidadProductosExportados__c>();

        for(vlocity_cmt__CatalogProductRelationship__c catalogProdRel : scope) {
            CAT_CompatibilidadProductosExportados__c infoCompatibProdExportados = new CAT_CompatibilidadProductosExportados__c();
            
            // Mapeo de campos
            infoCompatibProdExportados.CAT_NombreCatalogoCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.Name;
            infoCompatibProdExportados.CAT_CodigoCatalogoCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__CatalogCode__c;
            infoCompatibProdExportados.CAT_ListaPrecioCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.Name;
            infoCompatibProdExportados.CAT_CodigoListaPrecioCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__DefaultPriceListId__r.vlocity_cmt__Code__c;
            infoCompatibProdExportados.CAT_FinVigenciaCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__EndDateTime__c;
            infoCompatibProdExportados.CAT_InicioVigenciaCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__StartDateTime__c;
            infoCompatibProdExportados.CAT_NombreProductoCompatibilidad__c = catalogProdRel.vlocity_cmt__Product2Id__r.Name;
            infoCompatibProdExportados.CAT_CodigoProductoCompatibilidad__c = catalogProdRel.vlocity_cmt__Product2Id__r.ProductCode;
            infoCompatibProdExportados.CAT_ActivoCompatibilidad__c = catalogProdRel.vlocity_cmt__CatalogId__r.vlocity_cmt__IsActive__c;

            compatibilidadProdExportados.add(infoCompatibProdExportados);
        }
        
        if (!compatibilidadProdExportados.isEmpty()) {
            insert compatibilidadProdExportados;
        }
    }
    
    // Finish method: Optional for post-processing logic
    public void finish(Database.BatchableContext bc) {
        
        System.debug('Batch process for catalogproductRelationship completed.');
    }

}