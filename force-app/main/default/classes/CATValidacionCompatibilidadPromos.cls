/*-----------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Verify promotion compatibility according to decision matrix
Code Coverage:  70%
History
<Date>            <Author>                <Description>             <Version>
29-Abr-25         Fernanda Maldonado                                inicial version
-------------------------------------------------------------------------------------*/

public with sharing class CATValidacionCompatibilidadPromos {
    public static String validacionCompatibilidadPromos(String promotionCode, Id orderId, Map<String, Object> testMatrixData, String testObligatorias, String testIncompatibles){

        System.debug('promotionCode: ' + promotionCode);
        System.debug('orderId: ' + orderId);
        System.debug('testMatrixData: ' + testMatrixData);
        System.debug('testObligatorias: ' + testObligatorias);
        System.debug('testIncompatibles: ' + testIncompatibles);

        String errorMessage;

        // Obtener las promociones en el carrito
        List<String> promoCodesInCart = new List<String>();
        for(vlocity_cmt__OrderAppliedPromotion__c promotionsApplied : [SELECT vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c FROM vlocity_cmt__OrderAppliedPromotion__c  WHERE vlocity_cmt__OrderId__c = :orderId WITH SECURITY_ENFORCED]){
            String code = promotionsApplied.vlocity_cmt__PromotionId__r.vlocity_cmt__Code__c;
            System.debug('code: ' + code);
            
            if(String.isNotBlank(code)){
                promoCodesInCart.add(code);
                System.debug('promoCodesInCart: ' + promoCodesInCart);
            }
        }
        System.debug('promoCodesInCart: ' + promoCodesInCart);

        Map<String, Object> outputParams = new Map<String, Object>();
        List<String> obligatorias = new List<String>();
        List<String> incompatibles = new List<String>();
        String promosObligatorias;
        String promosIncompatibles;
        

        if (!Test.isRunningTest()){
            //Llamar a la matriz de decisión
            Invocable.Action action = Invocable.Action.createCustomAction('runDecisionMatrix', 'CATPromocionesCompatibles');
            action.setInvocationParameter('PromocionAgregada', promotionCode);
            action.setInvocationParameter('Accion', 'Agregar');
            List<Invocable.Action.Result> results = action.invoke();
            System.debug('results CATPromocionesCompatibles: ' + results);

            //Procesar el output de la matriz
            outputParams = results[0].getOutputParameters();
            System.debug('outputParams: ' + outputParams);

            if(outputParams != null){
                if(outputParams.containsKey('PromocionesObligatorias')){
                    promosObligatorias = (String) outputParams.get('PromocionesObligatorias');
                    System.debug('promosObligatorias: ' + promosObligatorias);
                }
            
                if(outputParams.containsKey('PromocionesIncompatibles')){
                    promosIncompatibles = (String) outputParams.get('PromocionesIncompatibles');
                    System.debug('promosIncompatibles: ' + promosIncompatibles);
                }
            }
        } else{
            outputParams = ( Map<String, Object>) testMatrixData;
            System.debug('outputParams: ' + outputParams);
            promosObligatorias = testObligatorias;
            System.debug('promosObligatorias: ' + promosObligatorias);
            promosIncompatibles = testIncompatibles;
            System.debug('promosIncompatibles: ' + promosIncompatibles);
        }

        //Escenario 1: la promoción agregada no está en la matriz de compatibilidad
        if(outputParams == null){
            System.debug('outputParams está vacío');
            errorMessage = '';
            return errorMessage;
        }

        if(promosObligatorias!= null){
            obligatorias = promosObligatorias.split(',');
            System.debug('obligatorias: ' + obligatorias);
        }

        if(promosIncompatibles!= null){
            incompatibles = promosIncompatibles.split(',');
            System.debug('incompatibles: ' + incompatibles);
        }

        //Escenario 2: la orden contiene al menos una promoción obligatoria en el carrito
        Set<String> obligatoriasList = new Set<String>(obligatorias);
        System.debug('obligatoriasList: ' + obligatoriasList);
        obligatoriasList.retainAll(promoCodesInCart);
        Boolean hasRequired = !obligatorias.isEmpty() && !obligatoriasList.isEmpty();
        System.debug('hasRequired: ' + hasRequired);

        //Escenario 3: la orden contiene al menos una promoción incompatible en el carrito
        Set<String> incompatiblesList = new Set<String>(incompatibles);
        System.debug('incompatiblesList: ' + incompatiblesList);
        incompatiblesList.retainAll(promoCodesInCart);
        Boolean hasIncompatible = !incompatiblesList.isEmpty();
        System.debug('hasIncompatible: ' + hasIncompatible);

        if(!hasRequired){
            errorMessage = 'Se necesita que exista en el carrito una promoción compatible para poder agregarla. Cosultar matriz de compatibilidad.';
        }else if(hasIncompatible){
            errorMessage = 'Hay una promoción incompatible en el carrito que impide agregarla. Se debe eliminar. Cosultar matriz de incompatibilidad.';
        }
        else{
            errorMessage = '';
        }
        return errorMessage;
    }
}