/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class to get JSON attribute and convert to productCharacteristic
Test Class:     PVU_GetProductCharacteristicTEST
History
<Date>          <Author>        <Change Description>
14/03/2024      Luis Mendoza    Initial Version
10/04/2024      Luis Mendoza    One time and recurring Price Add
------------------------------------------------------------*/
global with sharing class PVU_GetProductCharacteristic implements vlocity_cmt.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('getProductCharacteristic')) {
                System.debug('into method0');
                getProductCharacteristic(inputMap, outMap, options);
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;   

    }

    /*------------------------------------------------------------
        Author:         Luis Mendoza
        Company:        Salesforce.com
        Description:    method to get attr
        History
        <Date>          <Author>        <Change Description>
        14/03/2024      Luis Mendoza    Initial Version
    ------------------------------------------------------------*/
    public static void getProductCharacteristic(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        List<Object> listAssets = (List<Object>) inputMap.get('assetsList');
        List<Map<String,Object>> listAssetsMap = new List<Map<String,Object>>();
        
        try {

            List<vlocity_cmt__attribute__c> attrListObject = [Select Name , vlocity_cmt__Code__c, vlocity_cmt__ValueType__c FROM vlocity_cmt__attribute__c WITH SECURITY_ENFORCED LIMIT 500]; 

            for (Object instance : listAssets) {
                listAssetsMap.add((Map<String,Object>) instance);
            }
    
            for (Map<String,Object> assetMap : listAssetsMap) {
                List<Map<String,Object>> productCharacteristic =  new List<Map<String,Object>>();
                List<Map<String,Object>> productPriceList =  new List<Map<String,Object>>();

                if (assetMap.get('jsonattr') != null) {
                    Map<String, Object> mapListJSOn = (Map<String, Object>) JSON.deserializeUntyped( (String) assetMap.get('jsonattr'));
                    for (String key : mapListJSOn.keySet()) {
                        
                        for (vlocity_cmt__attribute__c attrObj : attrListObject) {
                            Map<String, Object> mapJsonAtt = new Map<String, Object>();
                            if (attrObj.vlocity_cmt__Code__c == key) {   
                                mapJsonAtt.put('value', String.valueOf(mapListJSOn.get(key)));
                                // mapJsonAtt.put('name', key.remove('B2C-ATTR-').removeEnd('-TERM'));
                                mapJsonAtt.put('name', attrObj.Name);
                                mapJsonAtt.put('attr', key);
                                productCharacteristic.add(mapJsonAtt);     
                            }
                        }
                    }
                }
                
                if(assetMap.get('OmConcatData') != null){
                    Map<String, Object> mapJsonAttCFSS = new Map<String, Object>();
                    mapJsonAttCFSS.put('value', assetMap.get('OmConcatData'));
                    mapJsonAttCFSS.put('name','CFSS');
                    mapJsonAttCFSS.put('attr', assetMap.get('productCodeRoot'));
                    productCharacteristic.add(mapJsonAttCFSS);
                    
                }                
            
                // Product Price construction
                //One time
                    Map<String, Object> productPriceMap0 = new Map<String, Object>();
                    Map<String, Object> priceMap1 = new Map<String, Object>();
                    Map<String, Object> priceMap2 = new Map<String, Object>();

                    productPriceMap0.put('unitOfMeasure', 'COP');
                    productPriceMap0.put('priceType', 'One-time');
                    productPriceMap0.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap0.put('name', 'AmountTotal');
                    productPriceMap0.put('description', 'Total amount with Tax');

                    priceMap2.put('value', assetMap.get('oneTimeWithTax'));
                    priceMap2.put('unit', 'COP');
                    priceMap1.put('price', priceMap2);
                    productPriceMap0.put('price', priceMap1);

                    productPriceList.add(productPriceMap0);
                    
                    Map<String, Object> productPriceMap1 = new Map<String, Object>();
                    Map<String, Object> priceMap11 = new Map<String, Object>();
                    Map<String, Object> priceMap12 = new Map<String, Object>();
                    
                    productPriceMap1.put('unitOfMeasure', 'COP');
                    productPriceMap1.put('priceType', 'One-time');
                    productPriceMap1.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap1.put('name', 'AmountWithoutTax');
                    productPriceMap1.put('description', 'Total amount without Tax');
                    
                    priceMap12.put('value', assetMap.get('oneTimeAmountWithoutTax'));
                    priceMap12.put('unit', 'COP');
                    priceMap11.put('price', priceMap12);
                    productPriceMap1.put('price', priceMap11);
                    productPriceList.add(productPriceMap1);
                    
                    Map<String, Object> productPriceMap2 = new Map<String, Object>();
                    Map<String, Object> priceMap111 = new Map<String, Object>();
                    Map<String, Object> priceMap112 = new Map<String, Object>();
                    
                    productPriceMap2.put('unitOfMeasure', 'COP');
                    productPriceMap2.put('priceType', 'One-time');
                    productPriceMap2.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap2.put('name', 'Tax');
                    productPriceMap2.put('description', 'Tax amount');
                    
                    priceMap112.put('value', assetMap.get('oneTimeTaxAmount'));
                    priceMap112.put('unit', 'COP');
                    priceMap111.put('price', priceMap112);
                    productPriceMap2.put('price', priceMap111);
                    productPriceList.add(productPriceMap2);
                    
                // Recurring

                    Map<String, Object> productPriceMap3 = new Map<String, Object>();
                    Map<String, Object> priceMapChild1 = new Map<String, Object>();
                    Map<String, Object> priceMapN1 = new Map<String, Object>();

                    productPriceMap3.put('unitOfMeasure', 'COP');
                    productPriceMap3.put('priceType', 'Recurring');
                    productPriceMap3.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap3.put('name', 'AmountTotal');
                    productPriceMap3.put('description', 'Total amount with Tax');

                    priceMapN1.put('value', assetMap.get('recurringWithTax'));
                    priceMapN1.put('unit', 'COP');
                    priceMapChild1.put('price', priceMapN1);
                    productPriceMap3.put('price', priceMapChild1);

                    productPriceList.add(productPriceMap3);
                    
                    Map<String, Object> productPriceMap4 = new Map<String, Object>();
                    Map<String, Object> priceMapChild2 = new Map<String, Object>();
                    Map<String, Object> priceMapN2 = new Map<String, Object>();
                    
                    productPriceMap4.put('unitOfMeasure', 'COP');
                    productPriceMap4.put('priceType', 'Recurring');
                    productPriceMap4.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap4.put('name', 'AmountWithoutTax');
                    productPriceMap4.put('description', 'Total amount without Tax');
                    
                    priceMapN2.put('value', assetMap.get('recurringTotalWithoutTax'));
                    priceMapN2.put('unit', 'COP');
                    priceMapChild2.put('price', priceMapN2);
                    productPriceMap4.put('price', priceMapChild2);
                    productPriceList.add(productPriceMap4);
                    
                    Map<String, Object> productPriceMap5 = new Map<String, Object>();
                    Map<String, Object> priceMapChild3 = new Map<String, Object>();
                    Map<String, Object> priceMapN3 = new Map<String, Object>();
                    
                    productPriceMap5.put('unitOfMeasure', 'COP');
                    productPriceMap5.put('priceType', 'Recurring');
                    productPriceMap5.put('paymentMethod', assetMap.get('paymentMethod'));
                    productPriceMap5.put('name', 'Tax');
                    productPriceMap5.put('description', 'Tax amount');
                    
                    priceMapN3.put('value', assetMap.get('recurringTotalAmount'));
                    priceMapN3.put('unit', 'COP');
                    priceMapChild3.put('price', priceMapN3);
                    productPriceMap5.put('price', priceMapChild3);
                    productPriceList.add(productPriceMap5);
                
                assetMap.put('productCharacteristic', productCharacteristic);
                assetMap.put('productPrice', productPriceList);
            }
            
        } catch (Exception e) {
            System.debug('Error get record: ' + e.getMessage());
            System.debug('Line: ' + e.getLineNumber());
            outMap.put('message', e.getMessage() + ' Line: ' + e.getLineNumber());
            outMap.put('status',  'Failed');
            outMap.put('code',  '500');
        }
       
        outMap.put('assets', listAssetsMap);
    
    }
}