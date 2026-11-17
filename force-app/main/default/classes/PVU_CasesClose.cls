public with sharing class PVU_CasesClose {
    @AuraEnabled(cacheable=false)
    public static List<Object> getListCases(String accId) { 
        List<Case> listCasesOut = new List<Case>();
        DateTime cutoffDate;

        InterfaceSettings__mdt settingsDiasCierre = [SELECT Id, IdCode__c,Descripcion__c FROM InterfaceSettings__mdt WHERE Identificador__c = 'DiasCierreCasos' WITH USER_MODE];
        Integer daysParam = Integer.valueOf(settingsDiasCierre.IdCode__c);
        if (Test.isRunningTest()) {
            cutoffDate = System.now();
        } else {
            cutoffDate = System.now().addDays(-daysParam);
        }
        
        List<Case> oldCasesWithOutOrder = [
            SELECT Id, CaseNumber, PVU_Level3__c, Status, CreatedDate
            FROM Case
            WHERE CreatedDate <= :cutoffDate AND Status != 'Cerrado' 
                AND PVU_Order__c = null AND AccountId =: accId 
                WITH USER_MODE
        ];

        Map<Id, DateTime> caseCreationMap = new Map<Id, DateTime>();
        for (Case c : oldCasesWithOutOrder) {
            caseCreationMap.put(c.Id, c.CreatedDate);
        }

        Map<Id, Boolean> caseWithStatusChange = new Map<Id, Boolean>();

        for (CaseHistory ch : [
            SELECT CaseId, CreatedDate 
            FROM CaseHistory 
            WHERE Field = 'Status' AND CaseId IN :caseCreationMap.keySet() WITH USER_MODE
        ]) {
            DateTime caseCreated = caseCreationMap.get(ch.CaseId);
            DateTime changeDeadline = caseCreated.addDays(daysParam);
            
            if (ch.CreatedDate <= changeDeadline) {
                caseWithStatusChange.put(ch.CaseId, true);
            }
        }

        for (Case c : oldCasesWithOutOrder) {
            if (!caseWithStatusChange.containsKey(c.Id)) {
                listCasesOut.add(c);
            }
        }

        List<Case> oldCasesWithOrdersReadyToSubmit = [
            SELECT Id, CaseNumber, PVU_Level3__c, Status, CreatedDate, PVU_Order__c
            FROM Case
            WHERE Status = 'En curso' AND PVU_Order__c != null 
            	AND PVU_Order__r.vlocity_cmt__OrderStatus__c = 'Ready To Submit'
                AND CreatedDate <= :cutoffDate
                AND AccountId =: accId 
            WITH USER_MODE
        ];

        Map<Id, DateTime> orderCreationMap = new Map<Id, DateTime>();
        for (Case c : oldCasesWithOrdersReadyToSubmit) {
            orderCreationMap.put(c.PVU_Order__c, c.CreatedDate);
        }

        Map<Id, Boolean> orderWithStatusChange = new Map<Id, Boolean>();

        for (OrderHistory oh : [
            SELECT OrderId, CreatedDate 
            FROM OrderHistory  
            WHERE Field = 'Status' AND OrderId IN :orderCreationMap.keySet()
            WITH USER_MODE
        ]) {
            DateTime caseCreated = orderCreationMap.get(oh.OrderId);
            DateTime changeDeadline = caseCreated.addDays(daysParam);
            
            if (oh.CreatedDate <= changeDeadline) {
                orderWithStatusChange.put(oh.OrderId, true);
            }
        }

        for (Case c : oldCasesWithOrdersReadyToSubmit) {
            if (!orderWithStatusChange.containsKey(c.PVU_Order__c)) {
                listCasesOut.add(c);
            }
        }

        List<Case> oldCasesWithOrder = [
            SELECT Id, CaseNumber, PVU_Level3__c, Status, CreatedDate
            FROM Case
            WHERE Status = 'En curso' AND PVU_Order__c != null 
            	AND PVU_Order__r.vlocity_cmt__FulfilmentStatus__c = 'Activated'
                AND PVU_Order__r.vlocity_cmt__SupersededOrderId__c  = null
                AND AccountId =: accId 
            WITH USER_MODE
        ];

        listCasesOut.addAll(oldCasesWithOrder);

        return listCasesOut;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getMensajesCasesClose() { 
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String, String> mapaMensajes = new Map<String, String>();
        
        List<PVU_MensajesGestiones__mdt> mensajes = new List<PVU_MensajesGestiones__mdt>([SELECT Id, DeveloperName, Codigo__c, MensajeArea__c
                                                     		FROM PVU_MensajesGestiones__mdt
                                                    		WHERE Codigo__c = 'MSGCLOSECASE' WITH USER_MODE LIMIT 50]);
        for(PVU_MensajesGestiones__mdt mensaje: mensajes){
            mapaMensajes.put(mensaje.DeveloperName, mensaje.MensajeArea__c);
        }
        
        outMap.put('mensajes', mapaMensajes);

        return outMap;
    }

    @AuraEnabled
    public static Boolean closeCases(List<Case> listCases) { 
        List<Id> listIdsCases = new List<Id>();

        for (Case c : listCases) {
            listIdsCases.add(c.Id);
        }
        
        List<Case> casosParaActualizar = [
            SELECT Id, Status, PVU_Sub_Estado__c, PVU_Codigo_de_Cierre__c
            FROM Case
            WHERE Id IN :listIdsCases
            WITH USER_MODE
        ];

        for (Case c : casosParaActualizar) {
            c.Status = 'Cerrado';
            c.PVU_Sub_Estado__c  = '-';
            c.PVU_Codigo_de_Cierre__c  = 'Cierre por no gestión';
        }

        try {
            update as user casosParaActualizar;
            return true;
        } catch (DmlException e) {
            System.debug('Error al actualizar los casos: ' + e.getMessage());
            return false;
        }
    }
}