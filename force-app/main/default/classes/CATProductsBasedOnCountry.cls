/*-----------------------------------------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Regresa los IDs de los productos filtrados por el país seleccionado
Code Coverage:  %
History
<Date>            <Author>             <Description>                                                          <Version>
01-Nov-24         Fernanda Maldonado    Regresa los IDs de los productos filtrados por el país seleccionado   1
------------------------------------------------------------------------------------------------------------------------*/

global with sharing class CATProductsBasedOnCountry implements vlocity_cmt.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        Boolean result = true;
        System.debug('methodName: ' + methodName);
        System.debug('input Method: ' + input);
        try{
            if (methodName.equalsIgnoreCase('getCompatibleProduct')) {
                getCompatibleProduct(input, output, options);
            } 
        }
        catch(Exception e){
            result = false;
            System.debug('Exception in CATProductsBasedOnCountry: ' + e.getMessage());
        }
        return result;
    }

    public void getCompatibleProduct(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options){
        System.debug('selectedCountry: ' + input.get('selectedCountry'));
        System.debug('input: ' + input);
        // Obtener la lista de países seleccionados desde el input del IP
        List<String> selectedCountry = new List<String>();
        for(String selectedCountryI : String.valueOf(input.get('selectedCountry')).split(';')){
            selectedCountry.add(selectedCountryI);
        }

        System.debug('selectedCountry: ' + selectedCountry);
        String selectedCountries = '(\'' + String.join(selectedCountry, '\', \'') + '\')';
        System.debug('selectedCountries: ' + selectedCountries);

        // Query para obtener los productos con el país seleccionado
        List<Product2> compatibleProduct = database.query('SELECT Id FROM Product2 WHERE vlocity_cmt__IsOrderable__c = true  AND IsActive = true AND CAT_ApplicableCountries__c INCLUDES ' + selectedCountries);

        // Variable de tipo string donde guardaremos los IDs separados por guión bajo (_)
        String compatibleProductIds = '';

        for(Integer i=0; i<compatibleProduct.size(); i++){
            Product2 product = compatibleProduct[i];
            String productId = product.Id;
            System.debug('productId: ' + productId);

            if(i == compatibleProduct.size() - 1){
                compatibleProductIds += productId;
            }else{
                compatibleProductIds += productId + '_';
            }
        }

        output.put('compatibleProductIds', compatibleProductIds);
        System.debug('compatibleProductIds: ' + compatibleProductIds);
    }
}