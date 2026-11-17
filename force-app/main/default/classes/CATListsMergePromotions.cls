/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class for handling the merge of 2 lists in OmniStudio
Code Coverage:  89%
History
<Date>            <Author>             <Description>             <Version>
20-Sep-24         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
global with sharing class CATListsMergePromotions implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('getpromotionsList')) {
                System.debug('Calling getpromotionsList method');
                getpromotionsList((List<Map<String, Object>>) input.get('ListMapDR'), (List<Map<String, Object>>) input.get('ListMapIP'), output, options);
            } 
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void getpromotionsList(List<Map<String, Object>> ListMapDR, List<Map<String, Object>> ListMapIP, Map<String, Object> output, Map<String, Object> options) {
        List<Map<String, Object>> duplicates = new List<Map<String, Object>>();
        List<String> promoIdsList = new List<String>();

        System.debug('ListMapDR size: ' + ListMapDR.size());
        System.debug('ListMapIP size: ' + ListMapIP.size());

        for (Map<String, Object> promotionsMapIP : ListMapIP) {
            String promotionIdIP = (String) promotionsMapIP.get('Id');
            System.debug('Promotion ID from ListMapIP: ' + promotionIdIP);
            promoIdsList.add(promotionIdIP);
        }

        for (Map<String, Object> promotionsMapDR : ListMapDR) {
            String promotionIdDR = (String) promotionsMapDR.get('Id');
            System.debug('Promotion ID from ListMapDR: ' + promotionIdDR);
            if (promoIdsList.contains(promotionIdDR)) {
                duplicates.add(promotionsMapDR);
                System.debug('Duplicate found: ' + promotionsMapDR);
            }
        }

        output.put('duplicates', duplicates);
        System.debug('Duplicates: ' + duplicates);
    }
}