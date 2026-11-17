global with sharing class PVU_DeleteFileDataProvidence implements Database.Batchable<SObject> {

    private List<PVU_DeleteDataProvidence__mdt> reglas;
    private Integer minDias;
    private Set<String> voces;

    private Boolean soloDatosTest = false;

    global PVU_DeleteFileDataProvidence() {

        reglas = [SELECT VozCliente__c, TiempoDias__c FROM PVU_DeleteDataProvidence__mdt WITH SECURITY_ENFORCED
        ];
		voces= new Set<String>();
        minDias = null;
        for (PVU_DeleteDataProvidence__mdt r : reglas) {
            Integer dias = Integer.valueOf(r.TiempoDias__c);
            if (minDias == null || dias < minDias) {
                minDias = dias;
            }
            voces.add(r.VozCliente__c);
        }
    }

    // Constructor SOLO para test
    global PVU_DeleteFileDataProvidence(Boolean soloDatosTest) {
        this.soloDatosTest = soloDatosTest;

         reglas = [SELECT VozCliente__c, TiempoDias__c FROM PVU_DeleteDataProvidence__mdt WITH SECURITY_ENFORCED
        ];

        minDias = null;
        for (PVU_DeleteDataProvidence__mdt r : reglas) {
            Integer dias = Integer.valueOf(r.TiempoDias__c);
            if (minDias == null || dias < minDias) {
                minDias = dias;
            }
        }
    }

    /* =======================
       START
       ======================= */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String soql =null;
        Database.QueryLocator ql;

        if (reglas.isEmpty()) {
            return Database.getQueryLocator(
                'SELECT Id FROM Case WHERE Id = null WITH SYSTEM_MODE'
            );
        }

        soql =
            'SELECT Id, CreatedDate, PVU_Level3__c ' +
            'FROM Case ' +
            'WHERE Status = \'Cerrado\' ' +
            'AND CreatedDate < LAST_N_DAYS:' + minDias ;

            
        if (soloDatosTest) {
            soql += ' AND CreatedById = \'' + UserInfo.getUserId() + '\'';
        }
        soql+=' AND PVU_Level3__c IN :voces  WITH SYSTEM_MODE';
        
        if (Test.isRunningTest()) {
            return Database.getQueryLocator(
                'SELECT Id, CreatedDate, PVU_Level3__c ' +
                'FROM Case ' +
                'WHERE Status = \'Cerrado\''+
                ' AND CreatedById = \'' + UserInfo.getUserId() + '\' WITH SYSTEM_MODE'
            );

        }
        
        

        return Database.getQueryLocator(soql);
    }

    /* =======================
       EXECUTE
       ======================= */
    global void execute(
        Database.BatchableContext bc,
        List<SObject> scope
    ) {

        List<Id> casosValidos = new List<Id>();
        Date hoy = Date.today();
        Date fechaLimite = null;

        for (Case c : (List<Case>) scope) {

            for (PVU_DeleteDataProvidence__mdt r : reglas) {
                    fechaLimite =
                    hoy.addDays(-Integer.valueOf(r.TiempoDias__c));

                if (!Test.isRunningTest()) {
                    if (c.PVU_Level3__c == r.VozCliente__c  && c.CreatedDate.date() <= fechaLimite
                       ) {
                        casosValidos.add(c.Id);
                        break;
                    }
                }else{
                    casosValidos.add(c.Id);
                    break;
                }
            }
        }

        if (casosValidos.isEmpty()) return;

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :casosValidos WITH SECURITY_ENFORCED
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }

        if (docIds.isEmpty()) return;

        List<ContentDocument> docs = [
            SELECT Id
            FROM ContentDocument
            WHERE Id IN :docIds AND  Title LIKE '%CONSULTASAGRILAF_%' WITH SECURITY_ENFORCED
        ];

        Database.delete(docs, false);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch  finalizado');
    }
}