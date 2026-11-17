/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : Para cobertura de codigo de la clase apex--> PVU_NotifyOldInteractionsBatchScheduler
 * @Cobertura de Código      : -
 * @Ultima modificación en   : 10-10-2024
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   10-10-2024   SALESFORCE   Initial Version
**/
@isTest
public class PVU_NotifyOldInteractionsBtcSchTest {
    
    @isTest
    static void testExecute() {
        Test.startTest();
        
        PVU_NotifyOldInteractionsBatchScheduler scheduler = new PVU_NotifyOldInteractionsBatchScheduler();
        
        // Simula la ejecución del scheduler llamando al método execute
        String jobId = System.schedule('Test Scheduled Job', '0 0 12 * * ?', scheduler);
        
        Test.stopTest();
        
        // Verifica que el job se haya programado correctamente
        System.assertNotEquals(null, jobId, 'El job debería haberse programado');
    }
}