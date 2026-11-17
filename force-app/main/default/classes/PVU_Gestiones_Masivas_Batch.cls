/*******************************************************************************
* Autor: Ame
* Fecha: 2024-10-25
* Equipo: Pos-Ventas
* Descripcion: Batch para el proceso de gestiones masivas.
* History
<Date>            <Author>             <Description>             <Version>
2024-10-25         Ame                 creacion                        01
2025-03-07         HLLANOS         Se Agregan campos marca cobranzas   02
***********************************************************************************/
global with sharing class PVU_Gestiones_Masivas_Batch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    // Los registros nuevos vendrian sin status
    // private static final String PENDING_STATUS = '';
    private String JobId;
    
    //Establecer configuraciones iniciales del batch en caso que se requiera.
    global PVU_Gestiones_Masivas_Batch(){
        
    }
    global PVU_Gestiones_Masivas_Batch(String JobId){
        this.JobId = JobId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Recorrido de la tabla
        return Database.getQueryLocator([SELECT Id, Name, PVU_Status__c, PVU_Action__c, PVU_CustNum__c, PVU_BillingAccountId__c, PVU_Source__c, PVU_Message__c, PVU_ReasonId__c, PVU_SuspensionLevel__c, PVU_CaseId__c, PVU_Status_OM__c, PVU_Description__c, PVU_Motivo__c,
                                         PVU_FeaturesOrServices__c,
                                         PVU_MSISDN__c,
                                         PVU_FechaVentaCartera__c,
                                         PVU_CiudadComprador__c,
                                         PVU_ConvenioPago__c,
                                         PVU_Producto__c,
                                         PVU_ObligacionNo__c,
                                         PVU_Saldo__c,
                                         PVU_CorreoElectronico__c,
                                         PVU_PaginaWeb__c,
                                         PVU_Nit__c,
                                         PVU_DireccionComprador__c,
                                         PVU_TelefonoComprador__c,
                                         PVU_ContractId__c,
                                         PVU_NombreCompradorCartera__c,
                                         PVU_Marca__c
                                         FROM PVU_Gestiones_Masivas__c 
                                         WHERE PVU_CustNum__c <> null AND PVU_Status__c = null AND PVU_JobIdentifier__c =: JobId
                                         WITH SYSTEM_MODE]);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {

        List<PVU_Gestiones_Masivas__c> gmasivas = (List<PVU_Gestiones_Masivas__c>) scope;
        
        // Lógica de suspensión
        PVU_Gestiones_Masivas_Handler service = new PVU_Gestiones_Masivas_Handler();
        service.assetService(gmasivas[0]);
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch PVU_Gestiones_Masivas_Batch finalizado.');
    }
}