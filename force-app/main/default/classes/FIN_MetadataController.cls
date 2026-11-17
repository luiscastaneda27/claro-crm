public with sharing class FIN_MetadataController {
    // Clase Wrapper para devolver ambos conjuntos de datos en una sola respuesta
    public class MetadataWrapper {
        @AuraEnabled public List<Fin_Parametros__mdt> parametros;
        @AuraEnabled public List<FIN_CustomMessages__mdt> mensajes;
    }

    @AuraEnabled(cacheable=true)
    public static MetadataWrapper getMetadataRecords() {
        MetadataWrapper wrapper = new MetadataWrapper();

        // Obtener los parámetros
        wrapper.parametros = [
            SELECT DeveloperName, FIN_Valor__c 
            FROM Fin_Parametros__mdt  
            WHERE DeveloperName = 'ValorMinimoADiferir'
        ];

        // Obtener los mensajes personalizados
        wrapper.mensajes = [
            SELECT Message__c 
            FROM FIN_CustomMessages__mdt 
            WHERE Message_Code__c = 'FIN015' 
            LIMIT 1
        ];

        return wrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static MetadataWrapper getMetadataRecordsMultiFactura() {
        MetadataWrapper wrapper = new MetadataWrapper();

        // Obtener los mensajes personalizados
        wrapper.mensajes = [
            SELECT DeveloperName, Message__c, Message_Code__c 
            FROM FIN_CustomMessages__mdt 
            WHERE Message_Code__c in ('PVU008','PVU009','PVU010')
            ORDER by Message_Code__c
        ];

        return wrapper;
    }
}