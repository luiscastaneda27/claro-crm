/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Validation Engine Class for Promotions
Code Coverage:  82%
History
<Date>            <Author>             <Description>             <Version>
20-Sep-24         Josue Pineda         inicial version
29-Dec-26		  Hugo Revuelta		   Bug fix 701576
18-Nov-26         VASS                 Validación: solo una promoción Bundle por línea (OrderItem)
----------------------------------------------------------------------------*/
global with sharing class CATValidationPromosEngine implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('promotionClassValidation')) {
                System.debug('Calling promotionClassValidation method');
                promotionClassValidation(input, output, options);
            } 
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void promotionClassValidation(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        
        System.debug('OrderIdMap ID: ' + input);
        System.debug('OrderIdMap ID: ' + input.get('OrderId'));

        Id orderId = (Id) input.get('OrderId');
        System.debug('orderId: ' + orderId);
        String promotionClass = (String) input.get('PromotionClass');
        System.debug('promotionClass: ' + promotionClass);
        String promotionCode = (String) input.get('PromotionCode');
        System.debug('promotionCode: ' + promotionCode);
        // Desde Cambio de Plan el IP envía OrderItemId vacío (""): se trata como null para no lanzar "Invalid id"
        String orderItemIdStr = (String) input.get('OrderItemId');
        Id orderItemId = String.isBlank(orderItemIdStr) ? null : (Id) orderItemIdStr;
        System.debug('orderItemId: ' + orderItemId);

        // Solo se permite una promoción Bundle por línea (OrderItem)
        if (BUNDLE_CLASS.equalsIgnoreCase(promotionClass) && hasBundleApplied(orderId, orderItemId)) {
            output.put('errorMessage', getBundleErrorMessage());
            output.put('promotionClassValidation', 'InvalidPromo');
            return;
        }

        Boolean hasRecords = false;
        Boolean validarCompatibilidad = true;

        /*Guardar el product code del plan orderitem
        OrderItem orderItems = [SELECT Product2.ProductCode FROM OrderItem WHERE OrderId = :orderId AND Product2.vlocity_cmt__IsOrderable__c = true AND CAT_ProductType__c = 'Plan Móvil Pospago'];
        System.debug('orderItems: ' + orderItems);
        String orderItemProductCode = orderItems.Product2.ProductCode;
        System.debug('orderItemProductCode: ' + orderItemProductCode);*/

        String clasesNoObligatorias = '';
        List<String> clasesNoObligatoriasList = new List<String>();

        if (!Test.isRunningTest()){
            //Leer la matriz de Clases de Beneficio no obligatorias
            Invocable.Action action = Invocable.Action.createCustomAction('runDecisionMatrix', 'CATClaseBeneficiosNoObligatorios');
            action.setInvocationParameter('BeneficiosNoObligatorios', 'Obtener');
            List<Invocable.Action.Result> results = action.invoke();
            System.debug('results runDecisionMatrix: ' + results);

            if (results.size() > 0 && results[0].isSuccess()) {
                clasesNoObligatorias = (String)results[0].getOutputParameters().get('CAT_PromotionClass__c');
                System.debug('clasesNoObligatorias: ' + clasesNoObligatorias); 
                clasesNoObligatoriasList = clasesNoObligatorias.split(','); 
                System.debug('clasesNoObligatoriasList: ' + JSON.serialize(clasesNoObligatoriasList));
            }
        } else{
            clasesNoObligatoriasList = (List<String>) input.get('clasesNoObligatoriasList');
            System.debug('clasesNoObligatoriasList: ' + clasesNoObligatoriasList);
        }

        // Obtener los OrderAppliedPromotionItems relacionados con la orden
        Map<Id, Id> promoIdToOrderItemIdMap = new Map<Id, Id>();

        for(vlocity_cmt__OrderAppliedPromotionItem__c promoItem : [SELECT vlocity_cmt__OrderItemId__c, vlocity_cmt__OrderAppliedPromotionId__c FROM vlocity_cmt__OrderAppliedPromotionItem__c WHERE vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__OrderId__c = :orderId WITH USER_MODE]){
            promoIdToOrderItemIdMap.put(promoItem.vlocity_cmt__OrderAppliedPromotionId__c, promoItem.vlocity_cmt__OrderItemId__c);
        }
        System.debug('promoIdToOrderItemIdMap: ' + promoIdToOrderItemIdMap);

        //Recorrer promociones aplicadas a la orden
        for (vlocity_cmt__OrderAppliedPromotion__c promotionsApplied : [SELECT Id, vlocity_cmt__PromotionId__r.CAT_PromotionClass__c, vlocity_cmt__Action__c FROM vlocity_cmt__OrderAppliedPromotion__c WHERE vlocity_cmt__OrderId__c= :orderId WITH USER_MODE]) {

            String appliedClass = promotionsApplied.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c;
            String action = promotionsApplied.vlocity_cmt__Action__c;
            Id relatedOrderItemId = promoIdToOrderItemIdMap.get(promotionsApplied.Id);
            System.debug('appliedClass (for): ' + appliedClass);
            System.debug('relatedOrderItemId: ' + relatedOrderItemId);
            System.debug('clasesNoObligatoriasList (for): ' + clasesNoObligatoriasList);

            // Procesar la respuesta de la matriz para obtener las clases exentas
            if (clasesNoObligatoriasList.size() > 0) {


                //Remover la variable 'Bundle' de clasesNoObligatoriasList
                if(clasesNoObligatoriasList.contains('Bundle')){
                    Integer indexBundle = clasesNoObligatoriasList.indexOf('Bundle');
                    String stringBundle = clasesNoObligatoriasList.remove(indexBundle);
                    System.debug('stringBundle: ' + stringBundle);
                    System.debug('clasesNoObligatoriasList: ' + JSON.serialize(clasesNoObligatoriasList));
                }

                Boolean containsPromoClass = clasesNoObligatoriasList.contains(promotionClass);
                System.debug('containsPromoClass: ' + containsPromoClass);

                // Validar si la promoción que se intenta agregar es al mismo orderItem
                if ((action == 'Add' || action == 'Change') && containsPromoClass == false && appliedClass == promotionClass && relatedOrderItemId == orderItemId) {
                    System.debug('appliedClass:' + appliedClass);
                    System.debug('promotionClass:' + promotionClass);
                    hasRecords = true;
                    String errorMessage = 'Ya existe esta clase de promoción en el carrito, agregue una diferente a ' + promotionClass;
                    System.debug('errorMessage: ' + errorMessage);
                    output.put('errorMessage', errorMessage);
                    output.put('promotionClassValidation', 'InvalidPromo');
                }
            }
        }
        if (hasRecords == false) {
            validarCompatibilidad = true;
            System.debug('hasRecords es false, no promos en el carrito de este PromotionClass');
        }else{
            validarCompatibilidad = false;
            System.debug('hasRecords es true, ya existe esta clase de promoción en el carrito');
        }
        if(validarCompatibilidad == true){
            
            //Variable para fines de clase de prueba
            Map<String, Object> testMatrixData = new Map<String, Object>();
            String testObligatorias;
            String testIncompatibles;

            //VALIDACIÓN DE COMPATIBILIDAD AL AGREGAR (solamente)
            //Llamar la nueva clase de: CATValidacionCompatibilidadPromos
            String errorMessage = CATValidacionCompatibilidadPromos.validacionCompatibilidadPromos(promotionCode, orderId, testMatrixData, testObligatorias, testIncompatibles);
            System.debug('Entró al método "CATValidacionCompatibilidadPromos.validacionCompatibilidadPromos"');
            System.debug('errorMessage: ' + errorMessage);
            if(errorMessage == ''){
                output.put('promotionClassValidation', 'ValidPromo');
            }else{
                output.put('promotionClassValidation', 'InvalidPromo');
                output.put('errorMessage', errorMessage);
            }
            System.debug('validarCompatibilidad: ' + validarCompatibilidad);
        }
        System.debug('output: ' + output);
    }

    @TestVisible
    private static final String BUNDLE_CLASS = 'Bundle';
    @TestVisible
    private static final String BUNDLE_MESSAGE_CODE = 'MSG017';
    // Solo se usa si el registro de MensajesPersonalizados__mdt no existe o no tiene mensaje
    private static final String BUNDLE_DEFAULT_MESSAGE = 'No es posible agregar la promoción.';

    // Obtiene el mensaje de error de Bundle desde MensajesPersonalizados__mdt
    @TestVisible
    private static String getBundleErrorMessage() {
        String mensaje = MensajesPersonalizados__mdt.getInstance(BUNDLE_MESSAGE_CODE)?.Mensaje__c;
        return String.isBlank(mensaje) ? BUNDLE_DEFAULT_MESSAGE : mensaje;
    }

    /*
     * Indica si ya existe una promoción Bundle agregada (Add/Change) en la orden para el OrderItem indicado.
     * Una promoción Bundle puede aplicar a varios OrderItems (plan e hijos), por eso se revisan todos sus items.
     * Si no se recibe OrderItemId no se bloquea, para no mostrar un mensaje equivocado.
     */
    private static Boolean hasBundleApplied(Id orderId, Id orderItemId) {
        for (vlocity_cmt__OrderAppliedPromotion__c applied : [
                SELECT Id,
                    (SELECT vlocity_cmt__OrderItemId__c FROM vlocity_cmt__OrderAppliedPromotionAffectedItems__r)
                FROM vlocity_cmt__OrderAppliedPromotion__c
                WHERE vlocity_cmt__OrderId__c = :orderId
                    AND vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = :BUNDLE_CLASS
                    AND vlocity_cmt__Action__c IN ('Add', 'Change')
                WITH USER_MODE]) {
            for (vlocity_cmt__OrderAppliedPromotionItem__c item : applied.vlocity_cmt__OrderAppliedPromotionAffectedItems__r) {
                if (String.isNotBlank(orderItemId) && item.vlocity_cmt__OrderItemId__c == orderItemId) {
                    return true;
                }
            }
        }
        return false;
    }
}