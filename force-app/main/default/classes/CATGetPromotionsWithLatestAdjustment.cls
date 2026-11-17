/*--------------------------------------------------------------------------
Author:         Juan Mojica - jmojica@salesforce.com
Company:        Salesforce.com
Description:    Clase que llama la lista de promociones compatibles con un plan (ya debe recibir la lista de Promotion IDs) y regresa la información en el mismo formato que getCartsPromotions, en las promociones que tienen ajustes de precios únicamente regresa el último ajuste creado. El objetivo es retornar la información necesaria para mostar el valor del descuento en la FlexCard "Ver Promociones".
Code Coverage:  93%
History
<Date>            <Author>             <Description>             <Version>
03-Feb-25         Juan Mojica                                    Versión inicial
27-Nov-25         Alan Semino          Campo custom en promocion  v1
----------------------------------------------------------------------------*/
global with sharing class CATGetPromotionsWithLatestAdjustment implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('getPromotionsWithLatestAdj')) {
                System.debug('Calling getPromotionsWithLatestAdj method');
                System.debug(JSON.serialize(input));
                System.debug(JSON.serialize(input.get('PromotionsList')));

                getPromotionsWithLatestAdj(input, output, options);
                System.debug('CATGetPromotionsWithLatestAdjustment output map:');
                System.debug(JSON.serialize(output));
            } 
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void getPromotionsWithLatestAdj(Map<String, Object> inputMap, Map<String, Object> output, Map<String, Object> options) {
        String promotionIdsStr = '';
        String orderId = '';
        System.debug('getCartsPromotionsResponse: ' + JSON.serialize(inputMap));
        promotionIdsStr = (String) inputMap.get('PromotionsList');
        System.debug('promotionIdsStr: ' + promotionIdsStr);
        orderId = (String) inputMap.get('OrderId');
        System.debug('orderId: ' + orderId);

        vlocity_cmt.CpqAppHandler cpqAppHandlerCall = new vlocity_cmt.CpqAppHandler();

        Object getCartsPromotionsResponse = cpqAppHandlerCall.invokeMethod('getCartsPromotions', new map<String, Object>{'methodName'=>'getCartsPromotions','cartId'=>orderId,'filters'=>'Id:' + promotionIdsStr,'fields'=>'CAT_Type__c,CAT_PromotionClass__c, CAT_Oferta_Retencion__c' }, output, options);

        System.debug('getCartsPromotionsResponse: ' + getCartsPromotionsResponse);
        String getCartsPromotionsResponseStr = JSON.serialize(getCartsPromotionsResponse);
        System.debug('--- getCartsPromotionsResponseStr: ' + JSON.serialize(getCartsPromotionsResponseStr));
        System.debug('getCartsPromotions Output: ' + JSON.serialize(output));

        vlocity_cmt.JSONResult responseResult = (vlocity_cmt.JSONResult)output.get('result');
        System.debug('responseResult: '+ responseResult);

        for(vlocity_cmt.JSONRecord record : responseResult.records)
        {
            System.debug('record: '+ record);
            System.debug('recordDisplaySequence: '+ record.displaySequence);
            Decimal discountAmount = 0;

            Map<String,Object> recordFields = (Map<String,Object>)record.fields;
            System.debug('recordFields: '+ recordFields);

            if (recordFields.containsKey('Discount')) {
                System.debug('The recordFields map has a key named Discount.');
                List<Object> discountList = (List<Object>)recordFields.get('Discount');
                System.debug('discountList: '+ discountList);
                discountList = new List<Object>{discountList[discountList.size() - 1]};
                Map<String,Object> discountAmountObj = (Map<String,Object>)discountList[0];
                System.debug('discountAmountObj: '+ JSON.serialize(discountAmountObj));
                discountAmount = (Decimal)discountAmountObj.get('value');
                System.debug('discountAmount: '+ discountAmount);
                //Agregar discountValue como elemento extra, de lo contrario la FlexCard no lo deja leer.
                recordFields.put('Discount', discountList);
                recordFields.put('DiscountAmount', discountAmount);
                System.debug('Updated discountList: '+ discountList);
            }
        }
        System.debug('Updated Output Map: ' + JSON.serialize(output));
        //output.put('getPromoOutput', output);
    }
}