/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class for giving format to the input of the API call for getting promotions in the cart
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
20-Sep-24         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
global with sharing class CATPromotionsQualification implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('promotionsQualification')) {
                System.debug('Calling promotionsQualification method');
                System.debug(JSON.serialize(input));
                System.debug(JSON.serialize(input.get('PromotionsList')));
                List<Map<String, Object>> promotionsFinalList = new List<Map<String, Object>>();
                //PromotionsList viene List<Map> en ejecuciones normales.
                //PromotionsList viene List<ANY> en ejecuciones que se hacen desde omnistudio luego de usar el componente de adjuntar archivos (BUG).
                    //Se debe asegurar que en los dos caso se transforma List<ANY> (List<Object>) a List<Map<String, Object>> para poder llamar al método promotionsQualification.
                List<Object> promotionsList = (List<Object>)input.get('PromotionsList');
                for (Object promotionInfo : promotionsList) {
                    Map<String, Object> promotionMap = (Map<String, Object>) promotionInfo;
                    promotionsFinalList.add(promotionMap);
                }
                System.debug('promotionsFinalList: ' + JSON.serialize(promotionsFinalList));
                promotionsQualification(promotionsFinalList, output, options);
            } 
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void promotionsQualification(List<Map<String, Object>> PromotionsList, Map<String, Object> output, Map<String, Object> options) {
        String qualifiedPromotions = '';
        System.debug('PromotionsList size: ' + PromotionsList.size());
        
        for (Integer i = 0; i < PromotionsList.size(); i++) {
            Map<String, Object> PromotionsListObject = PromotionsList[i];
            String promotionId = (String) PromotionsListObject.get('Id');
            System.debug('Promotion ID from ListMapIP: ' + promotionId);
            
            if (i == PromotionsList.size() - 1) {
                // Handle the last iteration withouth '_'
                qualifiedPromotions += promotionId;
            } else {
                qualifiedPromotions += promotionId + '_';
            }
        }

        output.put('qualifiedPromotions', qualifiedPromotions);
        System.debug('qualifiedPromotions: ' + qualifiedPromotions);
    }
}