/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Description:    
Code Coverage:  98%
History
<Date>         <Author>             	<Description>                                    <Version>
21-05-2024   Hever Salas   	  Utility class to create technical attributes JSON       inicial version
17-06-2024 	 Hever Salas   	  Add new Attributes values in response       				1.1
----------------------------------------------------------------------------*/

global with sharing class OM_CreateJsonTechnicalAttributes implements vlocity_cmt.VlocityOpenInterface {
    
    class MyException extends Exception{}
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try {
            if (methodName.Equals('createJSON')){
                createJSON(inputMap, outMap, options);
            }else{
                if (methodName.Equals('getAttributeJSON')){
                    getAttributeJSON(inputMap, outMap, options);
                }
            }
            if(Test.isRunningTest()){
                throw new MyException();
            }
        } catch(Exception ex) {
            outMap.put('error', ex.getStackTraceString()); 
            result = false; 
        }
        return result;
    }
    
    public void createJSON(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        String ProductName = String.valueOf(inputMap.get('ProductName'));
        String ProductOfferingId = String.valueOf(inputMap.get('ProductOfferingId'));
        String listOtherProducts = JSON.serialize(inputMap.get('listOtherProducts'));
        String listOtherProductsNew = '';
        
        if(String.IsNotBlank(ProductName) && String.IsNotBlank(ProductOfferingId)){
            listOtherProductsNew = listOtherProducts.replace(ProductName, ProductOfferingId);
        }else{
            listOtherProductsNew = listOtherProducts;
        } 
        Map<String,Object> msisdnList = new Map<String,Object>();
        Map<String,Object> products = new Map<String,Object>();
        List<Object> lstResult = new List<Object>();
        List<Object> lstProducts = new List<Object>();
        Map<String,Object> mapAttributes = new Map<String,object>();
        Map<String,Object> objectAttribute = (Map<String,Object>)inputMap.get('InventoryItem'); 
        mapAttributes = (Map<String,Object>)inputMap.get('mapAttributes');      
        Set<String> setAttributes = mapAttributes.keyset(); 
        for(Object ItemAttribute: (List<Object>)objectAttribute.values()[0]){
            
            Map<String, Object> mapResult = new Map<String,Object>();
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            
            if(setAttributes.contains((String)attribute.get('Code'))){
                mapResult.put('SegmentValue', attribute.get('SegmentValue'));
                mapResult.put('Code', attribute.get('Code'));
                mapResult.put('Name', mapAttributes.get((String)attribute.get('Code')));
                lstResult.add(mapResult);
                if(mapResult.get('Code') == 'TechRCresourceNumber'){
                    msisdnList.put('msisdn', mapResult.get('SegmentValue'));
                }
            }
        }
        products.put('attributes', lstResult);
        products.put('serviceId', (List<Object>)inputMap.get('serviceId'));
        products.put('productId', (List<Object>)inputMap.get('productId'));
        products.put('resourceId', (List<Object>)inputMap.get('resourceId'));
        products.put('productOffering', (String)inputMap.get('productOffering'));
        lstProducts.add((Object)products);
        lstProducts.addAll((List<Object>)JSON.deserializeUntyped(listOtherProductsNew));
        msisdnList.put('products', lstProducts);
        outMap.put('msisdnList', msisdnList);
    }
    
    public void getAttributeJSON(Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options){
        String ProductOfferingId = '';
        String attributeCodeToValue = (String)inputMap.get('attributeCodeToValue');
        Map<String,Object> objectAttribute = (Map<String,Object>)inputMap.get('JSONAttr'); 
        for(Object ItemAttribute: (List<Object>)objectAttribute.values()[0]){
            Map<String,Object> attribute = new Map<String,Object>();
            attribute = (Map<String,Object>)ItemAttribute;
            if(attribute.get('attributeuniquecode__c') == attributeCodeToValue){
                ProductOfferingId = (String)attribute.get('SegmentValue');
                break;
            }
        }
        outMap.put('ProductOfferingId', ProductOfferingId);
    }
}