/**
 * @description Batch de cierre diario de Quotes de financiación no aprobadas.
 *              La Quote maestra se cancela (Cerrada Perdida) para conservar su
 *              trazabilidad (HU 836632); las demás Quotes y las fianzas
 *              relacionadas se eliminan.
 */
public with sharing class FIN_BatchDeleteQuotes implements Database.Batchable<sObject> {

    // Constantes en MAYÚSCULAS para cumplir FieldNamingConventions
    private static final String QUOTE_STATUS    = 'Approved';
    private static final String QUOTE_TYPE      = 'Financiacion';
    private static final String CANCELED_STATUS = 'Cerrada Perdida';

    /**
     * @description Retorna las Quotes de financiación no aprobadas
     *              que serán procesadas por el batch. Las maestras ya
     *              canceladas solo se procesan si aún tienen fianza.
     *
     * @param bc Contexto del batch proporcionado por el framework.
     * @return   QueryLocator con las Quotes a procesar.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        String query = 'SELECT Id, Status, FIN_MasterQuote__c, FIN_Fianza_Id__c ' +
                       'FROM Quote ' +
                       'WHERE FIN_tipoDeVenta__c = :QUOTE_TYPE' +
                       ' AND Status != :QUOTE_STATUS' +
                       ' AND (FIN_MasterQuote__c = false' +
                       ' OR Status != :CANCELED_STATUS' +
                       ' OR FIN_Fianza_Id__c != null)';

        return Database.getQueryLocator(query);
    }

    /**
     * @description Elimina primero las fianzas relacionadas, luego cancela
     *              las Quotes maestras y elimina las demás.
     *
     * @param bc    Contexto del batch proporcionado por el framework.
     * @param scope Lote de registros (Quotes) a procesar en esta ejecución.
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {

        List<Quote> lstQuotesToDelete = new List<Quote>();
        List<Quote> lstQuotesToCancel = new List<Quote>();

        Set<Id> fianzaIds = new Set<Id>();
        for (Quote quoteRecord : (List<Quote>) scope) {
            if (quoteRecord.FIN_Fianza_Id__c != null) {
                fianzaIds.add(quoteRecord.FIN_Fianza_Id__c);
            }
            if (!quoteRecord.FIN_MasterQuote__c) {
                lstQuotesToDelete.add(quoteRecord);
            } else if (quoteRecord.Status != CANCELED_STATUS) {
                lstQuotesToCancel.add(new Quote(Id = quoteRecord.Id, Status = CANCELED_STATUS));
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

        if (!lstQuotesToCancel.isEmpty()) {
            update lstQuotesToCancel;
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