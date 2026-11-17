/*-----------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Clase para borrar promociones obligatorias del carrito
Code Coverage:  95%
History
<Date>            <Author>                <Description>             <Version>
29-Abr-25         Fernanda Maldonado                                inicial version
-------------------------------------------------------------------------------------*/

global with sharing class CATBorrarPromosObligatorias implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('borrarPromosObligatorias')) {
                System.debug('Calling borrarPromosObligatorias method');
                System.debug(JSON.serialize(input));
                System.debug(JSON.serialize(input.get('PromotionsList')));

                //Obtener código de promociones
                String promotions = (String)input.get('PromotionsList');
                System.debug('promotions: ' + promotions);
                List<String> promotionCodes = promotions.split(',');
                System.debug('promotionCodes: ' + JSON.serialize(promotionCodes));

                //Obtener Id orden
                String orderId = (String)input.get('OrderId');
                System.debug('orderId: ' + orderId);

                Map<String, Object> borrarPromosObligatoriasInput = new Map<String, Object>();
                borrarPromosObligatoriasInput.put('promotionCodes', promotionCodes);
                borrarPromosObligatoriasInput.put('orderId', orderId);
                System.debug('borrarPromosObligatoriasInput: ' + borrarPromosObligatoriasInput);

                borrarPromosObligatorias(borrarPromosObligatoriasInput, output, options);

            } else if(methodName.equalsIgnoreCase('borrarPromo')){

                //Obtener Id orden
                String orderId = (String)input.get('OrderId');
                System.debug('orderId: ' + orderId);

                //Obtener order applied promotion id
                String orderAppliedPromoId = (String)input.get('OrderAppliedPromotionId');
                System.debug('orderAppliedPromoId: ' + orderAppliedPromoId);

                Map<String, Object> borrarPromoInput = new Map<String, Object>();
                borrarPromoInput.put('orderAppliedPromoId', orderAppliedPromoId);
                borrarPromoInput.put('orderId', orderId);
                System.debug('borrarPromoInput: ' + borrarPromoInput);

                borrarPromo(borrarPromoInput, output, options);

            }
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void borrarPromosObligatorias(Map<String, Object> borrarPromosObligatoriasInput, Map<String, Object> output, Map<String, Object> options) {

        String orderId = (String)borrarPromosObligatoriasInput.get('orderId');
        System.debug('borrarPromosObligatorias orderId: ' + orderId);
        List<String> promotionCodes = (List<String>)borrarPromosObligatoriasInput.get('promotionCodes');
        System.debug('borrarPromosObligatorias promotionCodes: ' + JSON.serialize(promotionCodes));


        for (vlocity_cmt__OrderAppliedPromotion__c promotionsApplied : [SELECT Id FROM vlocity_cmt__OrderAppliedPromotion__c WHERE vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c IN :promotionCodes AND vlocity_cmt__OrderId__c = :orderId WITH USER_MODE]){
            System.debug('promotionsApplied.Id: ' + promotionsApplied.Id);

            //Definir mapas para llamada del método "deleteAppliedPromoItems" desde el cpqAppHandler
            Map<String, Object> deletePromoInput = new Map<String, Object> ();
            Map<String, Object> deletePromoOutput = new Map<String, Object> ();
            Map<String, Object> deletePromoOptions = new Map<String, Object> ();
            deletePromoInput.put('cartId', orderId);
            deletePromoInput.put('price', false);
            deletePromoInput.put('id', promotionsApplied.Id);
            deletePromoInput.put('externalRefresh', true);
            deletePromoInput.put('classMethodName', 'deleteAppliedPromoItems');
            System.debug('DeleteCartPromotion deletePromoInput: ' + deletePromoInput);
            vlocity_cmt.VOIInvoker voi = vlocity_cmt.VOIInvoker.getInstance();
            voi.invoke('vlocity_cmt.CpqAppHandler', 'invokeClass', deletePromoInput, deletePromoOutput, deletePromoOptions);
        }
    }

    public void borrarPromo(Map<String, Object> borrarPromoInput, Map<String, Object> output, Map<String, Object> options) {

        String orderId = (String)borrarPromoInput.get('orderId');
        System.debug('borrarPromoInput orderId: ' + orderId);
        String orderAppliedPromoId = (String)borrarPromoInput.get('orderAppliedPromoId');
        System.debug('borrarPromoInput orderAppliedPromoId: ' + orderAppliedPromoId );

        Map<String, Object> deletePromoInput = new Map<String, Object> ();
        Map<String, Object> deletePromoOutput = new Map<String, Object> ();
        Map<String, Object> deletePromoOptions = new Map<String, Object> ();
        deletePromoInput.put('cartId', orderId);
        deletePromoInput.put('price', false);
        deletePromoInput.put('id', orderAppliedPromoId);
        deletePromoInput.put('externalRefresh', true);
        deletePromoInput.put('classMethodName', 'deleteAppliedPromoItems');
        System.debug('DeleteCartPromotion deletePromoInput: ' + deletePromoInput);
        vlocity_cmt.VOIInvoker voi = vlocity_cmt.VOIInvoker.getInstance();
        voi.invoke('vlocity_cmt.CpqAppHandler', 'invokeClass', deletePromoInput, deletePromoOutput, deletePromoOptions);
    }
}