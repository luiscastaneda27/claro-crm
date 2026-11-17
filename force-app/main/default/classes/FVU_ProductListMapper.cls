global with sharing class FVU_ProductListMapper implements vlocity_cmt.VlocityOpenInterface2 {    
    
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        try {
            if (methodName == 'ProductListMapper') {
                return ProductListMapper(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug('Error in invoke method: ' + e.getMessage());
            throw e;
        }
        return false;
    }

    public Boolean ProductListMapper(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        List<Map<String, String>> listProductList = new List<Map<String, String>>();
        List<Map<String, String>> finalList = new List<Map<String, String>>();
        try{
        Map<String, Object> plMap = (Map<String, Object>) inputMap.get('productList');
        Object purchaseType = (Object) inputMap.get('purchaseType');
        Object getTerminalId = (Object) inputMap.get('terminalId');
        Decimal terminalId = (Decimal) getTerminalId;
        Boolean col = false;
        if(plMap.get('productCode') instanceof List<Object> && plMap.get('productNum') instanceof List<Object>){
                col = true;
        }
        

            if(col == true){
                List<Object> productCodesList = (List<Object>) plMap.get('productCode');
                List<Object> pnumList = (List<Object>) plMap.get('productNum');

                
                for (Integer i=0; i < productCodesList.size(); i++) {
                        Integer qty = (Integer) pnumList.get(i);
                        Map<String, String> newEntry = new Map<String, String>();
                        newEntry.put('productCode', (String) productCodesList.get(i));
                        newEntry.put('productNum',  String.valueOf(qty));
                        if((String) purchaseType == 'ATT'){
                            newEntry.put('groupId', String.valueOf(terminalId));
                        }
                        listProductList.add(newEntry);

                }

            }
            else {
               Object productCodesObj = (Object) plMap.get('productCode');
               Object pnumObj = (Object) plMap.get('productNum');
               Integer qty;
               
               Map<String, String> newEntry = new Map<String, String>();
               if(pnumObj instanceof Integer){
                qty = (Integer) pnumObj;
                newEntry.put('productNum',  String.valueOf(qty));
               }
               else {
                newEntry.put('productNum',  (String) pnumObj);
               }
               newEntry.put('productCode', (String) productCodesObj);
              
               if((String) purchaseType == 'ATT'){
                   newEntry.put('groupId', String.valueOf(terminalId));
               }
               listProductList.add(newEntry);
            }
        
            outputMap.put('productListMapped', listProductList);
            return true;
        }catch(Exception e){
            System.debug('Error in ProductListMapper: ' + e.getMessage());
            throw e;
        }

    }


}