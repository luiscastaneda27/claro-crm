/*-------------------------------------------------------------------------- 
 Author: Eduardo Wentancure 
 Company: Salesforce.com 
 Description: Clase para cerrar Casos Digitales
 Code Coverage: 90%
 History 
 <Date>     <Author>        <Description>                                      		<Version> 
03-Oct-25  Eduardo         cerrar Casos Digitales  	1ra versión 
----------------------------------------------------------------------------*/


global with sharing class PVU_CierreCasoDigitales implements vlocity_cmt.VlocityOpenInterface {

   
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName == 'cerrarCasoDigitales') {
            return cerrarCasoDigitales(input, outMap, options);
        }
        return true;
    }

    
    private Boolean cerrarCasoDigitales(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        outMap.put('success', false);

        try {
            Id accountId     = (Id) (input != null ? input.get('AccountId') : null);
            String vozOrigen = (String) (input != null ? input.get('vozDeCliente') : null);

            if (accountId == null) {
                outMap.put('message', 'Falta AccountId en la entrada.');
                return true;
            }
            if (String.isBlank(vozOrigen)) {
                outMap.put('message', 'No se recibió Voz de Cliente.');
                outMap.put('closedCount', 0);
                outMap.put('closedIds', new List<Id>());
                outMap.put('success', true);
                return true;
            }

           
            List<String> targetVOCs = new List<String>();
            String codigoCierre;

            if (vozOrigen == 'Cancelación Voluntaria') {
                targetVOCs.add('Cancelación Voluntaria Digital');
                codigoCierre = 'Cancelación Digital';

            } else if (vozOrigen == 'Cambio de pospago a prepago') {
                targetVOCs.add('Cambio de pospago a prepago Digital');
                codigoCierre = 'Paso a prepago Digital';

            } else if (vozOrigen == 'Cambio de plan móvil') {
                targetVOCs.add('Cambio de plan móvil Digital DW');
                codigoCierre = 'Cambio plan DW Digital';

            } else {
                outMap.put('message', 'VOC de origen no aplica a reglas de cierre automático.');
                outMap.put('closedCount', 0);
                outMap.put('closedIds', new List<Id>());
                outMap.put('success', true);
                return true;
            }

            
            List<Case> candidatos = [
                SELECT Id, Status, AccountId, PVU_Level3__c
                FROM Case
                WHERE AccountId = :accountId
                  AND Status IN ('Abierto','En curso')
                  AND PVU_Level3__c IN :targetVOCs
                  WITH USER_MODE
            ];

            
            for (Case c : candidatos) {
                c.PVU_Observaciones__c   = 'Solicitud atendida en WhatsApp';
                c.PVU_Codigo_de_Cierre__c = codigoCierre;
                c.Status                 = 'Cerrado';
            }
            if (!candidatos.isEmpty()) {
                update as system candidatos;
            }

           
            List<Id> ids = new List<Id>();
            for (Case c : candidatos) {
                ids.add(c.Id);
            }

            outMap.put('success', true);
            outMap.put('closedCount', candidatos.size());
            outMap.put('closedIds', ids);
            outMap.put('message', candidatos.isEmpty()
                ? 'No se encontraron casos a cerrar.'
                : 'Casos cerrados correctamente.');
            return true;

        } catch (Exception e) {
            outMap.put('success', false);
            outMap.put('message', 'Error al cerrar casos digitales: ' + e.getMessage());
            return true;
        }
    }
}