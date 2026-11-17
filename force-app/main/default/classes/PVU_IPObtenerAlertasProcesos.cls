/**
 * @description Integration Procedure Open Interface:
 * Obtiene las alertas de procesos desde Case.PVU_AlertasProcesos__c y las devuelve
 * como una lista de alerts para consumo de LWC/OmniStudio.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.StdCyclomaticComplexity')
global with sharing class PVU_IPObtenerAlertasProcesos implements vlocity_cmt.VlocityOpenInterface {

    /**
     * @description Entry point invocado por OmniStudio (Vlocity Open Interface).
     *
     * @param methodName Nombre del método configurado en la Integration Procedure.
     * @param inputMap   Input map (espera "CaseId").
     * @param outputMap  Output map (devuelve "alertsJson" y opcionalmente "message"/"error").
     * @param options    Opciones extra provistas por OmniStudio.
     * @return true si la ejecución terminó correctamente (aunque no haya datos).
     */
    @SuppressWarnings('PMD.ExcessiveParameterList,PMD.ApexDoc')
    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outputMap,
        Map<String, Object> options
    ) {
        // Omni suele llamar al "Method Name" que pongas en la IP.
        // Lo hacemos tolerante para que no te explote por naming.
        if (String.isBlank(methodName)) {
            methodName = 'getAlerts';
        }

        if (methodName == 'getAlerts' || methodName == 'getAlertas' || methodName == 'invoke') {
            return doGetAlerts(inputMap, outputMap);
        }

        // Si llamaron un método que no existe, devolvemos false (y no drama queen).
        outputMap.put('error', 'Method not supported: ' + methodName);
        return false;
    }

    private static Boolean doGetAlerts(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        Id caseId = (Id) inputMap.get('CaseId');
        if (caseId == null) {
            outputMap.put('alertsJson', new List<Object>());
            outputMap.put('message', 'CaseId is required');
            return true;
        }

        // CRUD/FLS (PMD ApexCRUDViolation): validamos antes de consultar.
        if (!Schema.sObjectType.Case.isAccessible()
            || !Schema.sObjectType.Case.fields.PVU_AlertasProcesos__c.isAccessible()) {
            outputMap.put('alertsJson', new List<Object>());
            outputMap.put('message', 'Insufficient access to Case / PVU_AlertasProcesos__c');
            return true;
        }

        Case c = [
            SELECT Id, PVU_AlertasProcesos__c
            FROM Case
            WHERE Id = :caseId
            WITH SECURITY_ENFORCED
        ];

        List<Object> alerts = buildAlerts(c.PVU_AlertasProcesos__c);

        // Esto es lo que tu LWC ya busca en parsed.IPResult.alertsJson
        outputMap.put('alertsJson', alerts);

        return true;
    }

    private static List<Object> buildAlerts(String raw) {
        List<Object> out = new List<Object>();
        if (String.isBlank(raw)) {
            return out;
        }

        List<String> successPoints = new List<String>();
        List<String> errorPoints   = new List<String>();

        fillPointsFromRaw(raw, successPoints, errorPoints);

        // Creamos como máximo 2 alerts: uno success y uno error
        addAlertIfAny(out, successPoints, 'success-1');
        addAlertIfAny(out, errorPoints, 'error-1');

        return out;
    }

    private static void fillPointsFromRaw(String raw, List<String> successPoints, List<String> errorPoints) {
        for (String p : raw.split(';')) {
            if (p == null) {
                continue;
            }

            String msg = p.trim();
            if (msg == '') {
                continue;
            }

            Boolean isSuccess = startsWithExito(msg);
            String cleanMsg   = stripSuccessPrefixIfAny(msg, isSuccess);

            if (String.isBlank(cleanMsg)) {
                continue;
            }

            if (isSuccess) {
                successPoints.add(cleanMsg);
            } else {
                errorPoints.add(cleanMsg);
            }
        }
    }

    private static String stripSuccessPrefixIfAny(String msg, Boolean isSuccess) {
        if (!isSuccess) {
            return msg;
        }

        Integer colonPos = msg.indexOf(':');
        if (colonPos >= 0 && colonPos < msg.length() - 1) {
            return msg.substring(colonPos + 1).trim();
        }

        return '';
    }

    private static void addAlertIfAny(List<Object> out, List<String> points, String idValue) {
        if (points == null || points.isEmpty()) {
            return;
        }

        String variantValue = idValue != null && idValue.startsWith('success') ? 'success' : 'error';

        out.add(new Map<String, Object>{
            'dismissible' => true,
            'id'          => idValue,
            'order'       => 20,
            'points'      => points,
            'variant'     => variantValue
        });
    }

    private static Boolean startsWithExito(String msg) {
        String m = msg.trim();
        // Soporta "Exito:" y "Éxito:" (por si alguien se pone académico)
        String lower = m.toLowerCase();
        return lower.startsWith('exito:') || lower.startsWith('éxito:');
    }
}