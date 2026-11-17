/* -------------------------------------------------------------------------- */
/**
 * Author:         Juan Pablo Rodríguez
 * Company:        Salesforce.com
 * Description:    Clase para verificar los procesos
 * Code Coverage:  100%
 * History
 * <Date>            <Author>             <Description>                         <Version>
 * 01-OCT-24         Eduardo Wentancur    Clase para verificar los procesos     inicial version
 */
/* -------------------------------------------------------------------------- */
public without sharing class PVU_FileController {

    private static final String CASE_API_NAME       = 'Case';
    private static final String LEVEL3_MATCH_VALUE  = 'Ajuste de Credito';
    private static final Set<String> ORIGINS_UPPER  = new Set<String>{ 'V360', 'PQR', 'WEB' };

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFiles(String recordId, String sobjectType) {
        Map<String, Object> answer = new Map<String, Object>();

        try {
            if(shouldUseCdlPath(recordId, sobjectType)){
                answer = PVU_SecurityProcess.getContentVersionsFromCDL(recordId, sobjectType);
            }else{
                answer = PVU_SecurityProcess.getContentVersions(recordId, sobjectType);
            }
        } catch (Exception ex) { throw new AuraHandledException(ex.getMessage()); }

        return answer;
    }

    /** ------------------------------------------------------------ */
    /**
     * Author:		Ángeles Pérez - maria.perez@nespon.com
     * Company:		Nespon
     * Description:   	Method validate record Object and if its case with 'Ajuste de Credito' and Origin in {V360, PQR, Web}
     * IN:	String recordId, String sobjectType
     * OUT: Boolean
     * History
     * <Date>           <Author>                        <Description>                                           <Version>
     * 18/09/2025    María Ángeles Pérez         Method to validate object, origin and level 3              Initial Version
    **/
    /** ------------------------------------------------------------ */
    private static Boolean shouldUseCdlPath(Id recordId, String sobjectType) {

        Boolean isAjusteCreditoCase = false;

        if (!CASE_API_NAME.equalsIgnoreCase(sobjectType)) {
            return false;
        }

        List<Case> cases = [SELECT Origin, PVU_Level3__c FROM Case WHERE Id = :recordId WITH USER_MODE LIMIT 1];

        if (cases.isEmpty()) {
            return false;
        }

        Case caseData = cases[0];

        String level3 = caseData.PVU_Level3__c;
        String originU = (caseData.Origin == null) ? null : caseData.Origin.trim().toUpperCase();

        Boolean matchLevel3 = (level3 == LEVEL3_MATCH_VALUE);
        Boolean matchOrigin = (originU != null && ORIGINS_UPPER.contains(originU));

        if (matchLevel3 && matchOrigin) {
            isAjusteCreditoCase = true;
        }

        return isAjusteCreditoCase;
    }

}