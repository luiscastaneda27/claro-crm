/**
 * @description Batch que elimina Quotes de financiación no aprobadas
 *              y sus registros de fianza relacionados.
 */
public with sharing class FIN_BatchDeleteQuotes implements Database.Batchable<sObject> {

    // Constantes en MAYÚSCULAS para cumplir FieldNamingConventions
    private static final String QUOTE_STATUS = 'Approved';
    private static final String QUOTE_TYPE   = 'Financiacion';
    
    /**
     * @description Retorna las Quotes de financiación no aprobadas
     *              que serán procesadas por el batch.
     *
     * @param bc Contexto del batch proporcionado por el framework.
     * @return   QueryLocator con las Quotes a procesar.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        String query = 'SELECT Id, FIN_Fianza_Id__c ' + 
                       'FROM Quote ' + 
                       'WHERE FIN_tipoDeVenta__c = :QUOTE_TYPE' + 
                       ' AND Status != :QUOTE_STATUS';

        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Elimina primero las fianzas relacionadas
     *              y luego las Quotes.
     *
     * @param bc    Contexto del batch proporcionado por el framework.
     * @param scope Lote de registros (Quotes) a procesar en esta ejecución.
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        List<Quote> lstQuotesToDelete = (List<Quote>) scope;
        
        Set<Id> fianzaIds = new Set<Id>();
        for (Quote quoteRecord : lstQuotesToDelete) {
            if (quoteRecord.FIN_Fianza_Id__c != null) {
                fianzaIds.add(quoteRecord.FIN_Fianza_Id__c);
            }
        }

        if (!fianzaIds.isEmpty()) {
            delete [
                SELECT Id 
                FROM FIN_Fianza__c 
                WHERE Id IN :fianzaIds
                WITH SECURITY_ENFORCED
            ];
        }

        if (!lstQuotesToDelete.isEmpty()) {
            delete lstQuotesToDelete;           
        }
    }
    
    /**
     * @description Lógica de cierre del batch.
     *              Método intencionalmente vacío.
     *
     * @param bc Contexto del batch proporcionado por el framework.
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext bc) {
        // No-op: no se requiere lógica de cierre por el momento.
    }
}