/*---------------------------------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Cpq App Handler Hook for custom pricing calculations in the cart
Code Coverage:  84%
History
<Date>            <Author>             <Description>             						<Version>
20-Sep-24         Josue Pineda                            								inicial version
15-Jul-25		  Fernanda Maldonado	Añadir manejo de proceso 'Cambio de Plan'
15-Ago-25         Gabriel Alvis        Ajuste en validación del límite de crédito       1.1
03-Feb-26         Silvia Tovar         Si omite HDC = true (Proceso de reversión) no valida limite de credito
13-Nov-26         Nicolas Ibarra       HU 826417: en migración con eSIM se reemplaza la SIM Card por eSIM
---------------------------------------------------------------------------------------------------------*/
global with sharing class CpqAppHandlerHookCustomImpl implements vlocity_cmt.VlocityOpenInterface
{
    @TestVisible private static Boolean deletingCFMItems = false;
    //Evita que el CPQ_AddChildItems del reemplazo de SIM vuelva a disparar el reemplazo
    @TestVisible private static Boolean swappingSimToEsim = false;
    private static final String SIM_CARD_PRODUCT_CODE = 'B2C-MOV-OFR-SIMCARD';
    private static final String ESIM_PRODUCT_CODE = 'B2C-MOB-OFR-ESIM';
    private static final String PLAN_AND_TERMINAL_PURCHASE_TYPE = 'ATT';

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        try
        {
            System.debug('____ CpqAppHandlerHookCustomImpl ' + methodName);
            //System.debug(JSON.serialize(input));
            System.debug(JSON.serialize(output));
            System.debug(options);
            String ultraWifiProdCode = 'B2C-FIJA-OFR-ULTRAWIFI';

            if (methodName == 'getCartsProducts.PreInvoke'){
                //Add include attachments to the call
                input.put('includeAttachment', true);
                System.debug('--- getCartsProducts.PreInvoke input: ' + JSON.serialize(input));
                System.debug('--- getCartsProducts.PreInvoke options: ' + JSON.serialize(options));
                //Add the FVU_Beneficios__c custom field to the response
                String customFields = 'Product2.FVU_Beneficios__c'; // comma separated list of custom fields
                //String customFields = 'Product2.Beneficios__c'; // comma separated list of custom fields
                // if fields is passed in, append the custom fields to the parameter value
                if (String.isNotBlank((String)input.get('fields')))
                {
                    input.put('fields', input.get('fields') + ',' + customFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                else {
                    //If fields is not passed in, just add the custom fields
                    input.put('fields', customFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                //Get Princicipal Governor Limits
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
            }
            else if (methodName == 'getCartsProducts.PostInvoke'){
                System.debug('--- getCartsProducts.PostInvoke input: ' + JSON.serialize(input));
                System.debug('--- getCartsProducts.PostInvoke output: ' + JSON.serialize(output));
                System.debug('--- getCartsProducts.PostInvoke options: ' + JSON.serialize(options));
                /*Get Princicipal Governor Limits
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));*/
            }
            else if (methodName == 'getCartsItems.PreInvoke' || methodName == 'postCartsPromoItems.PreInvoke'){
                //Obtener el Id del carrito para identificar si se trata de una Orden o de una cotización
                Id cartId = (String)input.get('cartId');
                //HU 826417: respaldo del reemplazo de SIM Card por eSIM al recargar los items del carrito
                if(methodName == 'getCartsItems.PreInvoke' && !swappingSimToEsim){
                    swapSimCardToEsim(cartId);
                }
                System.debug('CartId Object Type: ' + cartId.getSObjectType().getDescribe().getName());
                String priceCustomFields;
                if (cartId.getSObjectType().getDescribe().getName() == 'Quote'){
                    priceCustomFields = 'FVU_OneTimeTotalIncTaxes__c,vlocity_cmt__BaseOneTimeCharge__c,vlocity_cmt__BaseOneTimeTotal__c,FVU_RecurringTotalIncTaxes__c,vlocity_cmt__BaseRecurringCharge__c,vlocity_cmt__BaseRecurringTotal__c,Quote.FIN_MasterQuote__c,Quote.Id';
                } else {
                    priceCustomFields = 'FVU_OneTimeTotalIncTaxes__c,vlocity_cmt__BaseOneTimeCharge__c,vlocity_cmt__BaseOneTimeTotal__c,FVU_RecurringTotalIncTaxes__c,vlocity_cmt__BaseRecurringCharge__c,vlocity_cmt__BaseRecurringTotal__c,Order.Type,Order.FVU_OrderSubType__c, Order.StatusCode, Order.AccountId, Order.FVU_PurchaseType__c, Order.PVU_Retencion__c';
                }

                // if fields is passed in, append the custom fields to the parameter value
                if (String.isNotBlank((String)input.get('fields')))
                {
                    input.put('fields', input.get('fields') + ',' + priceCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                } else {
                    //If fields is not passed in, just add the custom fields
                    input.put('fields', priceCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                //Get Princicipal Governor Limits
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
            } else if (methodName == 'getCartsItems.PostInvoke' || methodName == 'postCartsPromoItems.PostInvoke'){
                vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)output.get('result');

                // Process each message inside the 'message' array
                for(vlocity_cmt.JSONMessage message : result.messages) {
                    // If the message code is 310, we process it so it's clearer
                    if(message.code.equals('310')) {
                        System.debug('Original message: ' + message.message);
                        // Devide the message by colon (:)
                        List<String> splitByColon = message.message.split(':');
                        if(splitByColon.size()>1){
                            String extractedMessage = splitByColon[1].trim();
                            // Devide by comma (,)
                            List<String> splitByComma = extractedMessage.split(',');
                            if(splitByComma.size()>1){
                                // We only take the text error message we want to show
                                message.message = splitByComma[1].trim();
                            } else{
                                // If there's no comma, we use the message after the colon
                                message.message = extractedMessage;
                            }
                        }
                        System.debug('Final error message: ' + message.message);
                    }
                }
                //Get Princicipal Governor Limits
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
            }
            else if (methodName == 'postCartsItems.PreInvoke'){
                System.debug('--- postCartsItems.PreInvoke input: ' + JSON.serialize(input));
                System.debug('--- postCartsItems.PreInvoke options: ' + JSON.serialize(options));
                //Get cartId
                Id cartId = (String)input.get('cartId');
                // Identificar si se está intentando agregar un item desde un Order o un Quote
                System.debug('CartId Object Type: ' + cartId.getSObjectType().getDescribe().getName());
                String objectTypeName = cartId.getSObjectType().getDescribe().getName();
                String postCartsItemsCustomFields;
                if(objectTypeName == 'Quote'){
                    //Lista de los campos que se deben agregar en la respuesta
                    postCartsItemsCustomFields = 'FVU_OneTimeTotalIncTaxes__c,vlocity_cmt__BaseOneTimeCharge__c,vlocity_cmt__BaseOneTimeTotal__c, FVU_RecurringTotalIncTaxes__c,vlocity_cmt__BaseRecurringCharge__c,vlocity_cmt__BaseRecurringTotal__c,Quote.FIN_MasterQuote__c,Quote.Id';
                } else{
                    //Lista de los campos que se deben agregar en la respuesta
                    postCartsItemsCustomFields = 'FVU_OneTimeTotalIncTaxes__c,vlocity_cmt__BaseOneTimeCharge__c,vlocity_cmt__BaseOneTimeTotal__c, FVU_RecurringTotalIncTaxes__c,vlocity_cmt__BaseRecurringCharge__c,vlocity_cmt__BaseRecurringTotal__c,Order.Type';
                }
                // if fields is passed in, append the custom fields to the parameter value
                if (String.isNotBlank((String)input.get('fields')))
                {
                    input.put('fields', input.get('fields') + ',' + postCartsItemsCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                else {
                    //If fields is not passed in, just add the custom fields
                    input.put('fields', postCartsItemsCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }

                //Si se está intentando agregar un item desde una cotización en esta clase no se requiere análisis adicional.
                if ( objectTypeName == 'Quote') {return true;}
                //1- Get items.itemId
                List<Object> itemsList = (List<Object>)input.get('items');
                //For the Ultrawifi: [{"parentId":"80278000000JuH4AAK","parentHierarchyPath":"01t78000000pCpjAAE","itemId":"01u78000001vVxAAAU","parentRecord":{"records":["Map of size 76 too large to display"]}}]
                Map<String, Object> itemObject = (Map<String, Object>)itemsList[0];
                Id itemId = (Id)itemObject.get('itemId');

                //Consultar el Cupo Disponible de la orden
                //TODO: Agregar análisi de Cupo Disponible para financiación cuando se tenga el campo de donde se debe obtener.
                List<SObject> remainingQuotaList = [SELECT FVU_RemainingQuota__c,FVU_OrderSubType__c, FVU_IsIVAExempt__c,PVU_OmitirHDC__c,FVU_MigraData__c,FVU_PurchaseType__c FROM Order WHERE Id = :cartId WITH USER_MODE LIMIT 1];
                Decimal remainingQuota = (Decimal)remainingQuotaList[0].get('FVU_RemainingQuota__c');
                String orderSubtype = (String)remainingQuotaList[0].get('FVU_OrderSubType__c');
                Boolean isIVAExemptOrder = (Boolean)remainingQuotaList[0].get('FVU_IsIVAExempt__c');
                Boolean omitHDC = (Boolean)remainingQuotaList[0].get('PVU_OmitirHDC__c');
                system.debug('IsIvaOrder: ' + isIVAExemptOrder);

                //HU 826417: en migración con eSIM no se permite agregar la SIM Card (el grupo "Escoja SIM Card" solo debe tener eSIM)
                Boolean esimSaleOrder = !swappingSimToEsim && remainingQuotaList[0].get('FVU_PurchaseType__c') != PLAN_AND_TERMINAL_PURCHASE_TYPE
                                        && isEsimSale((String)remainingQuotaList[0].get('FVU_MigraData__c'));
                if(esimSaleOrder){
                    if([SELECT COUNT() FROM PricebookEntry WHERE Id = :itemId AND Product2.ProductCode = :SIM_CARD_PRODUCT_CODE WITH USER_MODE] > 0){
                        System.debug('--- postCartsItems.PreInvoke Limpiar items: SIM Card en migración con eSIM');
                        input.put('simcardnotallowed', true);
                        input.put('items', null);
                        return true;
                    }
                }

                //Consultar con el itemId (PriceBook Entry Id) el Id (product2), Family, Type y Subtype del producto.
                //En la consulta filtrar usando las condiciones que identifican a un plan móvil. Si la consulta retorna 0 resultados, el producto
                //que está siendo agregado al carrito no es un Plan Móvil y no es una cotización no se debe hacer análisis de Cupo de Crédito.
                List<SObject> planOrAddOnList = [SELECT Product2.Id,Product2.Name, Product2.Family, Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SubType__c, Product2.vlocity_cmt__SpecificationType__c FROM PricebookEntry WHERE Id = :itemId AND Product2.Family = 'Mobile' AND ((Product2.vlocity_cmt__Type__c ='Plan' AND Product2.vlocity_cmt__SubType__c = 'Postpaid' AND Product2.vlocity_cmt__SpecificationType__c = 'Offer' AND Product2.vlocity_cmt__SpecificationSubType__c = 'Bundle') OR (Product2.vlocity_cmt__Type__c ='Add On' AND Product2.vlocity_cmt__SpecificationType__c = 'Offer' AND Product2.vlocity_cmt__SpecificationSubType__c = 'Simple')) WITH USER_MODE];
                System.debug('planOrAddOnList: ' + planOrAddOnList);

                Boolean creditLimitDebug = input.containsKey('CreditLimit') && String.isNotBlank(String.valueOf(input.get('CreditLimit')));  //v 1.1
                System.debug('creditLimitDebug: ' + creditLimitDebug);
                //Se deja con comentario la línea de abajo ya que Checkmarx marca el nombre de la variable como sensible y reporta un fallo de seguridad.
                //System.debug('Credit Limit' + creditLimitDebug );

                if(planOrAddOnList.size() == 0){
                    //Si el producto siendo agregado al carrito no es un plan móvil o no es un Add-On MÓVIL y no es una cotización, no se ejecuta nada adicional
                    return true;
                }
                //Si el producto es un Add On y no se paso el Credit Limit como parámetro de entrada se sale del hook, esto se hace para mantener la funcionalidad OOB de la llamada a PostCartsItems.
                //Si la orden es cambio de plan, se sale del hook.
                //Si omite HDC = true (Proceso de reversión) no valida limite de credito
                String productType = (String)planOrAddOnList[0].getSObject('Product2').get('vlocity_cmt__Type__c');
                System.debug('productType: ' + productType);
                //HU 826417: al agregar el plan en migración con eSIM se avisa que la SIM Card se reemplaza por eSIM
                if(esimSaleOrder && productType == 'Plan'){
                    input.put('esimSale', true);
                }
                if (creditLimitDebug == false && (productType == 'Add On' || orderSubtype == 'Cambio de Plan' || omitHDC == true )) {
                    return true;
                }

                //Analizar si el producto agregado es un Mobile-AddOn
                if(productType == 'Add On'){
                    System.Debug('El producto que se busca agregar es un AddOn.');
                    String creditLimitType = (String)input.get('CreditLimitType');
                    String planOrderItemId = (String)input.get('PlanOrderItemId');
                    Decimal creditLimit = (Decimal)input.get('CreditLimit');
                    System.Debug('creditLimit: ' + creditLimit);

                    //Obtener el Id (Product2) del AddOn
                    String addOnId = (String)planOrAddOnList[0].getSObject('Product2').get('Id');
                    System.Debug('addOnId: ' + addOnId);
                    //Consultar price list entry almacenado en la variable REC_MNTH_STD_PRC_INC_TAXES (Guarda el precio con impuestos).
                    //Si es 0 entonces no se necesita hacer análisis de cupo de crédito.
                    //Si la orden está excenta de impuestos, se consulta el precio sin impuestos y viceversa, el precio se usa para el análisis del límite de crédito
                    List<SObject> addOnPriceListAmount;
                    if(isIVAExemptOrder == true){
                        addOnPriceListAmount = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :addOnId AND (vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC' OR vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'OT_STD_PRC') AND vlocity_cmt__IsActive__c = true AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null AND vlocity_cmt__PromotionId__c = null AND (vlocity_cmt__EffectiveUntilDate__c > TODAY OR vlocity_cmt__EffectiveUntilDate__c = null) AND vlocity_cmt__EffectiveFromDate__c <= TODAY WITH USER_MODE ORDER BY CreatedDate DESC];
                    }else{
                        addOnPriceListAmount = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :addOnId AND (vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_INC_TAXES' OR vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'OT_STD_PRC_INC_TAXES') AND vlocity_cmt__IsActive__c = true AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null AND vlocity_cmt__PromotionId__c = null AND (vlocity_cmt__EffectiveUntilDate__c > TODAY OR vlocity_cmt__EffectiveUntilDate__c = null) AND vlocity_cmt__EffectiveFromDate__c <= TODAY WITH USER_MODE ORDER BY CreatedDate DESC];
                    }
                    System.debug('addOnPriceListAmount: ' + addOnPriceListAmount);

                    Decimal recAddOnPrice = 0;
                    if (!Test.isRunningTest()) {
                        if(addOnPriceListAmount.size() == 0){
                            NoDataFoundException e = new NoDataFoundException();
                            e.setMessage('No hay precio con impuestos activo');
                            throw e;
                        }
                        recAddOnPrice = (Decimal)addOnPriceListAmount[0].get('vlocity_cmt__PricingElementAmount__c');
                    } else{
                        recAddOnPrice = (Decimal)input.get('recPrice');
                    }
                    System.debug('recAddOnPrice: ' + recAddOnPrice);

                    //Se revisa el límite de crédito basado en diferentes condiciones
                    Decimal addOnPriceRounded = recAddOnPrice.setScale(0, RoundingMode.HALF_UP);
                    System.Debug('addOnPriceRounded: ' + addOnPriceRounded);
                    Decimal newCreditLimit = creditLimit - addOnPriceRounded;
                    System.debug('newCreditLimit: ' + newCreditLimit);
                     //Primer caso: Mayor o igual a 0 
                     //Se agrega el paquete al carrito y luego en el método postInvoke se actualizan los nuevos valores de límites de crédito en OrderItem.
                    if(newCreditLimit >= 0){
                        System.debug('--- postCartsItems.PreInvoke Preparar variables para actualizar campos de Límite de crédito en Order Item del Plan');
                        input.put('addOnAdded', true);
                        input.put('planOrderItemId',planOrderItemId);
                        input.put('creditLimitType',creditLimitType);
                        input.put('newCreditLimit',newCreditLimit);
                        return true;
                    }
                    //Segundo caso: Menor a 0
                     //No se actualiza el valor del límite, no se agrega el paquete adicional al carrito y se muestra un mensaje de error (misma lógica decupo de   crédito).
                    else if (newCreditLimit < 0) {
                        System.debug('--- postCartsItems.PreInvoke Limpiar items para evitar que se agregue al carrito');
                        input.put('abovecreditlimit', true);
                        input.put('errormessage','Los servicios seleccionados superan el cupo crédito disponible. Ajuste la selección para continuar.');
                        input.put('items', null);
                        return true;
                    }
                }

                //Esto se ejecuta SOLO para Plan Móvil
                //Obtener el Id (Product2) del Plan
                String mobilePlanId = (String)planOrAddOnList[0].getSObject('Product2').get('Id');

                //Consultar price list entry almacenado en la variable REC_MNTH_STD_PRC_INC_TAXES (Guarda el precio con impuestos).
                //Si es 0 entonces no se necesita hacer análisis de cupo de crédito.
                //Si la orden está excenta de impuestos, se consulta el precio sin impuestos y viceversa, el precio se usa para el análisis del cupo de crédito
                List<SObject> planPriceListAmount;
                if(isIVAExemptOrder == true){
                    planPriceListAmount = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :mobilePlanId AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC' AND vlocity_cmt__IsActive__c = true WITH USER_MODE ORDER BY CreatedDate DESC];
                }else{
                    planPriceListAmount = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :mobilePlanId AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC_INC_TAXES' AND vlocity_cmt__IsActive__c = true WITH USER_MODE ORDER BY CreatedDate DESC];
                }
                Decimal recPriceDecAmount = 0;
                if (!Test.isRunningTest()) {
                    if(planPriceListAmount.size() == 0){
                        NoDataFoundException e = new NoDataFoundException();
                        e.setMessage('No hay precio recurrente con impuestos activo (Mensual con impuestos)');
                        throw e;
                    }
                    recPriceDecAmount = (Decimal)planPriceListAmount[0].get('vlocity_cmt__PricingElementAmount__c');
                }
                else{
                    recPriceDecAmount = (Decimal)input.get('recPrice');
                }
                System.Debug('recPriceDecAmount: ' + recPriceDecAmount);
                
                //Revisar si el cupo es menor al precio del plan.
                //Si es menor limpiar "items" y luego capturar el error en PostInvoke.
                Decimal planPriceRounded = recPriceDecAmount.setScale(0, RoundingMode.HALF_UP);
                System.Debug('planPriceRounded: ' + planPriceRounded);
                System.Debug('remainingQuota: ' + remainingQuota);

                if(remainingQuota < planPriceRounded && planPriceRounded > 0){
                    System.debug('--- postCartsItems.PreInvoke Limpiar items para evitar que se agregue al carrito');
                    input.put('abovecreditlimit', true);
                    input.put('errormessage','Has excedido el Cupo de Crédito para compra de planes');
                    input.put('items', null);
                    return true;
                }

                // Consultar los items de la orden que corresponden a planes móviles y almecenarlos en lista
                List<SObject> mobilePlans = [SELECT Product2Id, Product2.Family, Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SubType__c, Product2.vlocity_cmt__SpecificationType__c, Product2.vlocity_cmt__SpecificationSubType__c FROM OrderItem WHERE OrderId = : cartId AND Product2.Family = 'Mobile' AND Product2.vlocity_cmt__Type__c ='Plan' AND Product2.vlocity_cmt__SubType__c = 'Postpaid' AND Product2.vlocity_cmt__SpecificationType__c = 'Offer' AND Product2.vlocity_cmt__SpecificationSubType__c = 'Bundle' AND vlocity_cmt__Action__c != 'Disconnect' WITH USER_MODE];

                // Identificar si el Item que se está agregando al carrito es un Plan Móvil
                if(mobilePlans.size() > 0) 
                {
                    //Limpiar el objeto "items" del input, de igual forma se debe asignar valor a un identificador específico del error y salir del método
                    input.put('morethanoneplan', true);
                    input.put('items', null);
                    return true;
                }
                //Get Princicipal Governor Limits
                /*
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
                return true;
            } 
            else if (methodName == 'postCartsItems.PostInvoke'){
                Boolean abovecreditlimit = (Boolean)input.get('abovecreditlimit');
                Boolean morethanoneplan = (Boolean)input.get('morethanoneplan');
                Boolean addOnAdded = (Boolean)input.get('addOnAdded');
                String errorMessage = (String)input.get('errormessage');

                //Se deja con comentario la línea de abajo ya que Checkmarx marca el nombre de la variable como sensible y reporta un fallo de seguridad.
                //System.debug('abovecreditlimit: ' + abovecreditlimit); 
                System.debug('morethanoneplan: ' + morethanoneplan); 
                System.debug('addOnAdded: ' + addOnAdded);

                //System.debug('--- postCartsItems.PostInvoke input: ' + JSON.serialize(input));
                //System.debug('--- postCartsItems.PostInvoke output: ' + JSON.serialize(output));
                //System.debug('--- postCartsItems.PostInvoke options: ' + JSON.serialize(options));

                if(input.get('abovecreditlimit') != null && (Boolean)input.get('abovecreditlimit'))
                {
                    vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)output.get('result');
                    System.debug('postCartsItems.PostInvoke: result-->'+result);
                    for(vlocity_cmt.JSONMessage message : result.messages)
                    {
                        if(message.code.equals('143'))
                        {
                            System.debug(message);
                            message.message = errorMessage;
                        }
                    }
                }

                //Identificar si en el input se encuentra el identificador del error específico para cuando se está intentando agregar más de un plan en el carrito
                if(input.get('morethanoneplan') != null && (Boolean)input.get('morethanoneplan'))
                {
                    //Identificar si el error tiene código "143"
                    vlocity_cmt.JSONResult morethanoneplanResult = (vlocity_cmt.JSONResult)output.get('result');
                    for(vlocity_cmt.JSONMessage morethanoneplanMessage : morethanoneplanResult.messages)
                    {
                        if(morethanoneplanMessage.code.equals('143'))
                        {
                            //Si se cumplen las condiciones anteriores indicar que se devuelva al carrito el mensaje específico
                            morethanoneplanMessage.message = 'No es posible agregar más de un plan móvil al carrito. Por favor, asegúrate de revisar y eliminar cualquier plan adicional antes de proceder con la compra';
                        }
                    }
                }

                //HU 826417: mensajes para migración con eSIM
                if(input.get('simcardnotallowed') != null && (Boolean)input.get('simcardnotallowed'))
                {
                    vlocity_cmt.JSONResult simCardResult = (vlocity_cmt.JSONResult)output.get('result');
                    for(vlocity_cmt.JSONMessage simCardMessage : simCardResult.messages)
                    {
                        if(simCardMessage.code.equals('143'))
                        {
                            simCardMessage.message = 'Esta venta es una migración con eSIM: no es posible agregar SIM Card física.';
                        }
                    }
                }
                else if(input.get('esimSale') != null && (Boolean)input.get('esimSale'))
                {
                    vlocity_cmt.JSONResult esimSaleResult = (vlocity_cmt.JSONResult)output.get('result');
                    for(vlocity_cmt.JSONMessage esimSaleMessage : esimSaleResult.messages)
                    {
                        if(esimSaleMessage.code.equals('150'))
                        {
                            esimSaleMessage.message += ' Migración con eSIM: la SIM Card se reemplaza automáticamente por eSIM; si aún la ves, recarga el carrito.';
                        }
                    }
                }

                //Identificar si el producto agregado es un AddOn y fue agregado exitosamente (Código 150)
                if(input.get('addOnAdded') != null && (Boolean)input.get('addOnAdded'))
                {
                    vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)output.get('result');
                    System.debug('postCartsItems.PostInvoke: result-->'+result);
                    Id planOrderItemId = (String)input.get('planOrderItemId');
                    OrderItem orderItemRecord = [SELECT CAT_ServicesCreditLimit__c, CAT_AddOnCreditLimit__c,CAT_RoamingCreditLimit__c  FROM OrderItem WHERE Id = :planOrderItemId WITH USER_MODE LIMIT 1];
                    Boolean updateOrderItemRequired = false;
                    for(vlocity_cmt.JSONMessage message : result.messages)
                    {
                        if(message.code.equals('150'))
                        {
                            Decimal newCreditLimit = (Decimal)input.get('newCreditLimit');
                            String creditLimitType = (String)input.get('creditLimitType');
                            //Se dejan con comentario las dos líneas de abajo ya que Checkmarx marca el nombre de la variable como sensible y reporta un fallo de seguridad.
                            //System.debug('newCreditLimit: ' + newCreditLimit);
                            //System.debug('creditLimitType: ' + creditLimitType);
                            System.debug('planOrderItemId: ' + planOrderItemId);

                            if (creditLimitType == 'Límite Nacional Servicios') {
                                orderItemRecord.CAT_ServicesCreditLimit__c = newCreditLimit;
                            }
                            else if (creditLimitType == 'Límite Nacional Paquetes') {
                                orderItemRecord.CAT_AddOnCreditLimit__c = newCreditLimit;
                            }else if (creditLimitType == 'Límite Nacional Roaming'){
                                orderItemRecord.CAT_RoamingCreditLimit__c = newCreditLimit;
                            }
                            updateOrderItemRequired = true;
                        }
                    }
                    if(updateOrderItemRequired){
                        Update as user orderItemRecord;
                    }
                }
                //Processing any error messages that comes from the flow
                vlocity_cmt.JSONResult result = (vlocity_cmt.JSONResult)output.get('result');
                // Process each message inside the 'message' array
                for(vlocity_cmt.JSONMessage message : result.messages) {
                    // If the message code is 109, we process it so it's clearer
                    if(message.code.equals('109') || message.code.equals('146')) {
                        System.debug('Original message: ' + message.message);
                        // Devide the message by colon (:)
                        List<String> splitByColon = message.message.split(':');
                        if(splitByColon.size()>1){
                            String extractedMessage = splitByColon[1].trim();
                            // Devide by comma (,)
                            List<String> splitByComma = extractedMessage.split(',');
                            if(splitByComma.size()>1){
                                // We only take the text error message we want to show
                                message.message = splitByComma[1].trim();
                            } else{
                                // If there's no comma, we use the message after the colon
                                message.message = extractedMessage;
                            }
                        }
                        System.debug('Final error message: ' + message.message);
                    }
                }
                //Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                /*
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            } else if (methodName == 'putCartsItems.PreInvoke'){
                System.debug('--- putCartsItems.PreInvoke input: ' + input);

                //1- Get items: input.get(items)
                //Object items = input.get('items.records');
                //Object items = input.get('items');
                Map<String, Object> itemsMap = (Map<String, Object>)input.get('items');
                //2- Get items->records
                List<Object> itemsRecordsList = (List<Object>)itemsMap.get('records');
                //System.debug('--- postCartsItems.PreInvoke itemsRecordsList: ' + JSON.serialize(itemsRecordsList));
                //3- Get lineItems
                Map<String, Object> itemsRecordsMap = (Map<String, Object>)itemsRecordsList[0];
                //System.debug('--- postCartsItems.PreInvoke itemsRecordsMap: ' + JSON.serialize(itemsRecordsMap));
                if(itemsRecordsMap.containsKey('lineItems') == false){
                    //When changing the Quantity for a root item there is no lineItems object
                    return true;
                }
                Map<String, Object> lineItemsMap = (Map<String, Object>)itemsRecordsMap.get('lineItems');
                //4- Get lineItems -> records
                List<Object> lineItemsRecordsList = (List<Object>)lineItemsMap.get('records');
                Map<String, Object> lineItemsRecordsMap = (Map<String, Object>)lineItemsRecordsList[0];
                //5- Check if ProductCode is "B2C-FIJA-OFR-ULTRAWIFI"
                String updatedProductCode = (String) lineItemsRecordsMap.get('ProductCode');
                if (updatedProductCode == ultraWifiProdCode){
                    System.debug('--- putCartsItems.PreInvoke ---- UltraWifi is being modified!!!');
                    //6- Get Quantity -> value
                    Map<String, Object> updatedProductQtyMap = (Map<String, Object>)lineItemsRecordsMap.get('Quantity');
                    Decimal updatedProductQty = (Decimal)updatedProductQtyMap.get('value');
                    //7- If value = 1, set value = 2.
                    if (updatedProductQty == 1){
                        System.debug('--- putCartsItems.PreInvoke ---- UltraWifi Qty is 1, setting it to 2');
                        updatedProductQtyMap.put('value',2);
                        //System.debug(JSON.serialize(input));
                    }
                }
                //Get Principal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                /*
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            }
            else if (methodName == 'getCarts.PreInvoke'){
                //Add headerFieldSet to the call
                //Incluir en la respuesta los campos definidos en el Custom Settings -> Field Settings Identificado con feature: "ClaroTotalesCarrito"
                input.put('headerFieldSet', 'ClaroTotalesCarrito');
                System.debug(input);
                //Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                /*
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            }
            else if (methodName == 'getCartsPromotions.PreInvoke'){
                System.debug('getCartsPromotions.PreInvoke Input: ' + input);
                System.debug('getCartsPromotions.PreInvoke Output: ' + output);
                System.debug('getCartsPromotions.PreInvoke Options: ' + options);

                Id cartId = (Id)input.get('cartId');
                System.debug('getCartsPromotions.PreInvoke cartId: ' + cartId);

                List<Order> carts = [SELECT Account.FVU_StatusTodoClaro__c FROM Order WHERE Id = :cartId WITH USER_MODE];

                String accStatusTodoClaro;
                if(!carts.isEmpty()){
                    Order cart = carts[0];
                    accStatusTodoClaro = cart.Account.FVU_StatusTodoClaro__c;
                }
                System.debug('accStatusTodoClaro: ' + accStatusTodoClaro);

                //Verificar si hay un plan en el carrito
                List<OrderItem> planOrderItem = [SELECT Id FROM OrderItem WHERE OrderId = :cartId AND CAT_ProductType__c = 'Plan Móvil Pospago' WITH USER_MODE];
                System.debug('planOrderItem: ' + planOrderItem);

                String filters = (String)input.get('filters');
                System.debug('filters: ' + filters);

                


                if(accStatusTodoClaro == 'Potencial' && planOrderItem.isEmpty() && filters != null){
                    //Guardar Id de Promo que no quiero que aparezca
                    List<vlocity_cmt__Promotion__c> promos = [SELECT Id FROM vlocity_cmt__Promotion__c WHERE CAT_PromotionClass__c = 'Descuento Todo Claro' AND CAT_Type__c = 'TodoClaro' WITH USER_MODE];
                    //System.debug('List promos: ' + JSON.serialize(promos));
                    if(!promos.isEmpty()){
                        Set<String> promoIds = new Set<String>();
                        for(vlocity_cmt__Promotion__c promo : promos){
                            promoIds.add(promo.Id);
                        }
                        System.debug('Promotions not included (promoId): ' + promoIds);
                        //Separar por guiones bajos
                        List<String> filterList = filters.split('_');
                        System.debug('filterList: ' + filterList);
                        System.debug('filterList[0]: ' + filterList[0]);

                        //Quitamos el string "Id" de la respuesta de filters
                        if(filterList[0].startsWith('Id')){
                            filterList[0] = filterList[0].replace('Id:','');
                        }

                        //Eliminar las promociones a excluir de la llamada
                        for(Integer i = filterList.size() - 1; i >= 0; i--){
                            if(promoIds.contains(filterList[i])){
                                filterList.remove(i);
                            }
                        }

                        //Unir nuevamente los IDs
                        filterList[0] = 'Id:' + filterList[0];
                        System.debug('filterList: ' + filterList);
                        String updatedFilters = String.join(filterList, '_');
                        input.put('filters', updatedFilters);

                        System.debug('updatedFilters: ' + updatedFilters);
                    }
                    else{
                        System.debug('No se encontraron promociones a excluir.');
                    }
                }

                String promotionCustomFields = 'CAT_Type__c,CAT_PromotionClass__c'; // comma separated list of custom fields
                //String customFields = 'Product2.Beneficios__c'; // comma separated list of custom fields
                // if fields is passed in, append the custom fields to the parameter value
                if (String.isNotBlank((String)input.get('fields')))
                {
                    input.put('fields', input.get('fields') + ',' + promotionCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                else {
                    //If fields is not passed in, just add the custom fields
                    input.put('fields', promotionCustomFields);
                    System.debug('____ Provided Fields ' + input.get('fields'));
                }
                //Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                /*
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            }
            else if(methodName == 'deleteAppliedPromoItems.PreInvoke') {
                System.debug('deleteAppliedPromoItems.PreInvoke input: ' + input);
                System.debug('deleteAppliedPromoItems.PreInvoke output: ' + output);
                System.debug('deleteAppliedPromoItems.PreInvoke options: ' + options);
                // Obtener el valor de vlocity_cmt__OrderAppliedPromotionId__c del input map.
                String orderAppliedPromotionId = (String) input.get('id');
                vlocity_cmt__OrderAppliedPromotion__c orderAppliedPromotion = [SELECT Id, vlocity_cmt__PromotionId__c, vlocity_cmt__PromotionId__r.CAT_PromotionClass__c FROM vlocity_cmt__OrderAppliedPromotion__c WHERE Id = :orderAppliedPromotionId WITH USER_MODE];
                String promotionClass = orderAppliedPromotion.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c;
                System.debug('orderAppliedPromotionId PreInvoke: ' + orderAppliedPromotionId);
                /// lista de valores correspondientes a vlocity_cmt__OrderItemId__c, para borrar esos Order Items, usando el valor de vlocity_cmt__OrderAppliedPromotionId__c obtenido del input map
                List<vlocity_cmt__OrderAppliedPromotionItem__c> appliedPromoItems = [SELECT vlocity_cmt__OrderItemId__c, vlocity_cmt__OrderItemId__r.Product2.vlocity_cmt__Type__c FROM vlocity_cmt__OrderAppliedPromotionItem__c WHERE vlocity_cmt__OrderAppliedPromotionId__c =:orderAppliedPromotionId WITH USER_MODE];
                System.debug('appliedPromoItems: ' + appliedPromoItems.size());
                // Si hay resultados , se procesan, antes de eliminarlos.
                Map<Id, String> orderItemMap = new Map<Id, String>();
                //Se guardan los valores de vlocity_cmt__OrderItemId__c en la lista orderItemIdList
                for (vlocity_cmt__OrderAppliedPromotionItem__c appliedPromoItem : appliedPromoItems) {
                    Id orderItemId = (Id)appliedPromoItem.get('vlocity_cmt__OrderItemId__c');
                    System.debug('orderItemId: ' + orderItemId);
                    String orderItemProductType = (String)appliedPromoItem.getSObject('vlocity_cmt__OrderItemId__r').getSObject('Product2').get('vlocity_cmt__Type__c');

                    System.debug('orderItemProductType: ' + orderItemProductType);

                    orderItemMap.put(orderItemId, orderItemProductType);
                }
                System.debug('orderItemIdMap: ' + orderItemMap);
                //Se agregan las entradas de OrderItem al input map del metodo deleteAppliedPromoItems.
                input.put('orderItemIds', orderItemMap);
                input.put('promotionClass', promotionClass);
                input.put('promotionId', orderAppliedPromotion.vlocity_cmt__PromotionId__c);
                System.debug('orderItemIdsList: ' + orderItemMap);

                /*Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño

                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            } 
			else if (methodName == 'getCartsPromotions.PostInvoke') {
                Id cartId = (Id)input.get('cartId');
         		System.debug('++getCartsPromotions.PostInvoke');
                System.debug('CPQ Output Keys: ' + output.keySet());
            	// 1. Only run this if the cart is a Quote
                if (cartId != null && cartId.getSObjectType().getDescribe().getName() == 'Quote') {
                    
                    // 2. Get the 'result' map
                    Object resultObj = output.get('result');
                    if (resultObj == null) return true;
                    // 3. Drill down to 'records' (or 'items') inside result
                    String jsonStr = JSON.serialize(resultObj);
        			Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(jsonStr);
                    List<Object> records = (List<Object>)resultMap.get('records');
                    System.debug('records.size: '+ records.size() );
                    if (records == null || records.isEmpty()) return true;
        
                    List<Object> filteredItems = new List<Object>();
        
                    for (Object itemObj : records) {
                        Map<String, Object> item = (Map<String, Object>)itemObj;
                        System.debug('++item: '+ item);
                        // 3. Check your specific field (e.g., CAT_PromotionClass__c)
                        // Note: The CPQ API often prefixes fields with the namespace or 'vlocity_cmt__'
                        String promoClass ; 
                        String promoCode; 
                        if (item.containsKey('fields')) {
                            Map<String, Object> fieldsMap = (Map<String, Object>)item.get('fields');
                
                            // Promote values from 'fields' to the top level to match 'before.json'
                            for (String key : fieldsMap.keySet()) {
                                item.put(key, fieldsMap.get(key));
                            }
                            
                            // Remove the 'fields' node entirely to clean up the structure
                            item.remove('fields');
                        }
                        // 2. Now get the class from the promoted top-level
                        promoClass = (String)item.get('CAT_PromotionClass__c');
                        System.debug('++promoClass: '+ promoClass);
                        if (promoClass != 'Descuento') {
                            System.debug('item added: '+ promoCode);
                            filteredItems.add(item);
                        } else{
                            System.debug('item removed: '+ promoCode);
                        }
                    }
                    System.debug('filteredItems.size: '+ filteredItems.size() );
        
                    output.remove('result'); // Remove the old nested structure
                    output.put('records', filteredItems);
                    output.put('totalSize', filteredItems.size());
                    output.put('messages', new List<Object>()); // Matches before.json
                    
                    // Clear metadata keys often added by handlers that aren't in before.json
                    output.remove('errorCode');
                    output.remove('error');
                    
                }
                
            } 
            else if(methodName == 'deleteAppliedPromoItems.PostInvoke') {
                System.debug('inputPostInvoke input: ' + input);
                System.debug('inputPostInvokeOrderItemList: ' + input.get('orderItemIds'));
                //Obtener el valor del Id del carrito del input map.
                String cartId = (String) input.get('cartId');
                String promotionClass = (String) input.get('promotionClass');
                System.debug('promotionClass: ' + promotionClass); 
                //Obtener el valor de vlocity_cmt__OrderAppliedPromotionId__c del input map y Castear la lista "orderItemIds" del input a una Lista de Strings.
                Map<Id, String> orderItemIdMap = new Map<Id, String>();
                orderItemIdMap = (Map<Id, String>) input.get('orderItemIds');
                System.debug('orderItemIdMap: ' + orderItemIdMap); 
                Boolean externalRefresh = (Boolean) input.get('externalRefresh');
                System.debug('externalRefresh: ' + externalRefresh); 
                OrderItem orderItemPlan = new OrderItem ();
                Map<String, Object> ipInput = new Map<String, Object> ();
                Map<String, Object> ipOutput = new Map<String, Object> ();
                Map<String, Object> ipOptions = new Map<String, Object> ();
                String procedureName;
                for (Id orderItemId : orderItemIdMap.keySet()){
                    String productType = orderItemIdMap.get(orderItemId);
                    System.debug('productType: ' + productType); 
                    if(productType == 'Add On') {
                        System.debug('inputPostInvokeOrderItemString: ' +  orderItemId);
                        // When the deleted promotion is a Bundle, the Add On may still have
                        // OrderAppliedPromotionItem__c records from other promotions (e.g. Descuento, Claro Video).
                        // We delete only those specific junction records — NOT the whole OrderAppliedPromotion —
                        // so the other promotions remain applied to the Plan.
                        if (promotionClass == 'Bundle') {
                            List<vlocity_cmt__OrderAppliedPromotionItem__c> blockingPromoItems = [
                                SELECT Id
                                FROM vlocity_cmt__OrderAppliedPromotionItem__c
                                WHERE vlocity_cmt__OrderItemId__c = :orderItemId
                                AND vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__OrderId__c = :cartId
                                WITH USER_MODE
                            ];
                            System.debug('blockingPromoItems for Add On ' + orderItemId + ': ' + blockingPromoItems);
                            if (!blockingPromoItems.isEmpty()) {
                                delete as user blockingPromoItems;
                                System.debug('Deleted ' + blockingPromoItems.size() + ' blocking OrderAppliedPromotionItem records');
                            }
                        }
                        procedureName = 'CPQ_DeleteItemFromCart';
                        ipInput.put('cartId', cartId);
                        ipInput.put('id', orderItemId);
                        ipInput.put('price', false);
                        ipInput.put('validate', false);
                        System.debug('ipInput: ' + ipInput);
                        ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
                        System.debug('ipOutput: ' + ipOutput);
                    }
                    if( productType == 'Handset' || productType == 'Tech') { // se quita producttype = plan para que tenga su propia lógica
                        //Se obtiene el valor de vlocity_cmt__OrderItemId__c del OrderItem de tipo Plan.
                        orderItemPlan.Id = orderItemId;
                        orderItemPlan.vlocity_cmt__Modification__c = 0; 
                    }
                    else if(productType == 'Plan') {
                        System.debug('dentro productType = Plan');
                        orderItemPlan.Id = orderItemId;
                        OrderItem orderprod = [SELECT id, Product2.ProductCode FROM OrderItem where id = :orderItemId WITH USER_MODE LIMIT 1];
                       // String orderItemProductCode = orderprod.Product2.ProductCode;
                        String orderItemProductCode = orderprod.Product2.ProductCode;

                        System.debug('orderItemProductCode: ' + orderItemProductCode);
                        Invocable.Action action = Invocable.Action.createCustomAction('runDecisionMatrix', 'CATObligatoriedadClasesBeneficio');
                        action.setInvocationParameter('producto', orderItemProductCode);
                        //action.setInvocationParameter('v2', 2);
                        List<Invocable.Action.Result> results = action.invoke();
                        Boolean conservarPlan;
                        Boolean resultadosObtenidos = false;
                        String clasesBeneficio;
                        List<String> clasesBeneficioList;
                        if (results.size() > 0 && results[0].isSuccess() && results[0].getOutputParameters() != null) {
                            resultadosObtenidos = true; 
                            conservarPlan = (Boolean)results[0].getOutputParameters().get('quitarCarrito');
                            clasesBeneficio = (String)results[0].getOutputParameters().get('clasesBeneficio');
                            clasesBeneficioList = String.isNotBlank(clasesBeneficio) ? clasesBeneficio.split(',') : new List<String>();
                        }
                        //eliminaProd = false; No eliminar la promo del carrito
                        
                        System.debug('Result conservarPlan is: ' + conservarPlan);
                        System.debug('Result clasesBeneficioList is: ' + JSON.serialize(clasesBeneficioList) );
                        System.debug('results runDecisionMatrix: ' + results); 
                        System.debug('results.getOutputParameters(): ' +  resultadosObtenidos + ' ' + results[0].getOutputParameters());

                        //if ( resultadosObtenidos && clasesBeneficio and ) {                            
                            if((resultadosObtenidos && clasesBeneficioList.contains(promotionClass) && conservarPlan != true)  ){
                                Boolean planTieneOtraPromo = false;
                                System.debug('Se debe eliminar el plan');
                                List<vlocity_cmt__OrderAppliedPromotionItem__c> segundaOrderAppliedPromos = [SELECT Id, vlocity_cmt__OrderAppliedPromotionId__c, vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.Name FROM vlocity_cmt__OrderAppliedPromotionItem__c WHERE vlocity_cmt__OrderItemId__c = :orderItemId WITH USER_MODE];
                                if (segundaOrderAppliedPromos != null) {
                                    for (vlocity_cmt__OrderAppliedPromotionItem__c segundaOrderAppliedPromo : segundaOrderAppliedPromos) {
                                        System.debug('Se debe eliminar promoción adicional');
                                        //Definir mapas para llamada del método "deleteAppliedPromoItems" desde el cpqAppHandler
                                        Map<String, Object> deletePromoInput = new Map<String, Object> ();
                                        Map<String, Object> deletePromoOutput = new Map<String, Object> ();
                                        Map<String, Object> deletePromoOptions = new Map<String, Object> ();
                                        deletePromoInput.put('cartId', cartId);
                                        deletePromoInput.put('price', false);
                                        deletePromoInput.put('id', segundaOrderAppliedPromo.vlocity_cmt__OrderAppliedPromotionId__c);
                                        System.debug('DeleteCartPromotion deletePromoInput: ' + deletePromoInput);
                                        vlocity_cmt.CpqAppHandler cpqAppHandlerCall = new vlocity_cmt.CpqAppHandler();
                                        Object deleteCartPromotion = cpqAppHandlerCall.invokeMethod('deleteAppliedPromoItems', deletePromoInput, deletePromoOutput, deletePromoOptions);
                                        System.debug('DeleteCartPromotion deletePromoOutput: ' + deletePromoOutput);

                                    }
                                    
                                }
                                //Construir String de OrderItemIds.
                        		System.debug('inputPostInvokeOrderItemString: ' +  orderItemId);
                                // Inicializar variables para el borrado se puede usar llamando el Integration Procedure CPQ_DeleteItemFromCart (es el mismo que usa el carrito al borrar productos)
                                procedureName = 'CPQ_DeleteItemFromCart';
                                // Llamar IP para borrar los items
                                // Populating input map for an Integration Procedure, with CartId and the String of OrderItemIds. 
                                ipInput.put('cartId', cartId);
                                ipInput.put('id', orderItemId);
                                ipInput.put('price', false);
                                ipInput.put('validate', false);
                                System.debug('ipInput: ' + ipInput);
                                // Call the IP via runIntegrationService, and save the output to ipOutput 
                                ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
                                System.debug('ipOutput: ' + ipOutput);

                            } else if (promotionClass == 'Obsequios de CFM') {
                                if (!deletingCFMItems) {
                                deletingCFMItems = true;
                                try {
                                System.debug('promotionClass is Obsequios de CFM — deleting all other promos and all products from the cart');
                                // Step 1: delete all other OrderAppliedPromotions in the cart
                                List<vlocity_cmt__OrderAppliedPromotion__c> allOtherPromos = [
                                    SELECT Id
                                    FROM vlocity_cmt__OrderAppliedPromotion__c
                                    WHERE vlocity_cmt__OrderId__c = :cartId
                                    WITH USER_MODE
                                ];
                                System.debug('allOtherPromos to delete: ' + allOtherPromos.size());
                                for (vlocity_cmt__OrderAppliedPromotion__c otherPromo : allOtherPromos) {
                                    Map<String, Object> deletePromoInput = new Map<String, Object>();
                                    Map<String, Object> deletePromoOutput = new Map<String, Object>();
                                    Map<String, Object> deletePromoOptions = new Map<String, Object>();
                                    deletePromoInput.put('cartId', cartId);
                                    deletePromoInput.put('price', false);
                                    deletePromoInput.put('id', otherPromo.Id);
                                    deletePromoInput.put('externalRefresh', true);
                                    System.debug('Deleting OrderAppliedPromotion: ' + otherPromo.Id);
                                    vlocity_cmt.CpqAppHandler cpqHandler = new vlocity_cmt.CpqAppHandler();
                                    cpqHandler.invokeMethod('deleteAppliedPromoItems', deletePromoInput, deletePromoOutput, deletePromoOptions);
                                    System.debug('deleteAppliedPromoItems output: ' + deletePromoOutput);
                                }
                                // Step 2: delete all OrderItems via CPQ IP (needed for Vlocity triggers).
                                // Re-entrant hook calls from within this IP are blocked by deletingCFMItems guard above.
                                List<OrderItem> allOrderItems = [
                                    SELECT Id
                                    FROM OrderItem
                                    WHERE OrderId = :cartId
                                    WITH USER_MODE
                                ];
                                System.debug('allOrderItems to delete: ' + allOrderItems.size());
                                for (OrderItem oi : allOrderItems) {
                                    try {
                                        Map<String, Object> deleteItemInput = new Map<String, Object>();
                                        Map<String, Object> deleteItemOptions = new Map<String, Object>();
                                        deleteItemInput.put('cartId', cartId);
                                        deleteItemInput.put('id', oi.Id);
                                        deleteItemInput.put('price', false);
                                        deleteItemInput.put('validate', false);
                                        ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_DeleteItemFromCart', deleteItemInput, deleteItemOptions);
                                        System.debug('CPQ_DeleteItemFromCart output: ' + ipOutput);
                                    } catch (Exception ex) {
                                        System.debug('CPQ_DeleteItemFromCart failed for OrderItem ' + oi.Id + ': ' + ex.getMessage());
                                    }
                                }
                                } finally {
                                    deletingCFMItems = false;
                                }
                                } else {
                                    System.debug('Skipping CFM deletion — already in progress (re-entrant call)');
                                }
                            }
                    }
                }
                if(orderItemPlan != null) {
                    System.debug(JSON.serialize(orderItemPlan));
                    //Si el usuario tiene permiso para actualizar el campo vlocity_cmt__Modification__c del objeto OrderItem,
                    //se ejecuta la actualización, de lo contrario no se ejecuta y se levanta una exepción.
                    try {

                        if (Schema.sObjectType.OrderItem.fields.vlocity_cmt__Modification__c.isUpdateable()) {
                            Update orderItemPlan;
                         } else{
                            NoAccessException e = new NoAccessException();
                            e.setMessage('Se está intentanto actualizar un campo sin tener permiso al mismo!');
                            throw e;
                         }
                    } catch(Exception e) {
                        System.debug('An exception occurred: ' + e.getMessage());
                    }
                }
                // Inicializar variables llamar actualización de los precios de la orden
                // Esto evita que cuando se borre una promoción el precio del plan se quede en $0.
                if(externalRefresh != true){
                    procedureName = 'CPQ_GetCartLineItemPrices';
                    // Se llena el input map del IP, para el IP GetCartLineItemPrices solo se necesita el ID de la orden
                    ipInput.clear();
                    ipInput.put('cartId', cartId);
                    System.debug('GetCartLineItemPrices ipInput: ' + ipInput);
                    // Call the IP via runIntegrationService, and save the output to ipOutput 
                    ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
                    System.debug('GetCartLineItemPrices ipOutput: ' + ipOutput);
                }

                //Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño

                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));

            } else if(methodName == 'deleteCartsItems.PostInvoke') {
                System.debug('inputdeleteCartsItems.PostInvoke: ' + input);
                System.debug('outputdeleteCartsItems.PostInvoke: ' + JSON.serialize(output));
                System.debug('outputdeleteCartsItems.PostInvoke modifiedItems: ' + output.get('modifiedItems'));
                //Obtener OrderId
                Id cartId = (Id)input.get('cartId');
                //Obtener el mapa de los items modificados
                Map<Id, Object> modifiedOrderItems = (Map<Id, Object>)output.get('modifiedItems');
                System.debug('dataMap: ' + modifiedOrderItems);
                List<OrderItem> orderItemEntriesList = new List<OrderItem>();
                //Obtener el orderItem del producto desconectado
                List<OrderItem> orderItemDisconnectedProduct = [SELECT Id, Product2Id FROM OrderItem WHERE OrderId = :cartId AND vlocity_cmt__Action__c = 'Disconnect' WITH USER_MODE LIMIT 1];
                String productIdDisconnected = orderItemDisconnectedProduct[0].Product2Id;
                System.debug('--- productIdDisconnected: ' + productIdDisconnected);
                List<String> orderItemIds = new List<String>();
                //Obtener Id de los orderItems del carrito
                List<OrderItem> orderItemList = [SELECT Id, vlocity_cmt__ProductHierarchyPath__c FROM OrderItem WHERE OrderId = :cartId WITH USER_MODE];
                System.debug('--- orderItemList: ' + orderItemList);
                for(OrderItem orderItem : orderItemList){
                    //Add the order item IDs to the list
                    if(orderItem.vlocity_cmt__ProductHierarchyPath__c != null && orderItem.vlocity_cmt__ProductHierarchyPath__c.contains(productIdDisconnected)){
                        orderItemIds.add(orderItem.Id);
                    }
                    System.debug('--- orderItemIds: ' + orderItemIds);
                }
                //Loop a través de los order items y se actualiza el valor de los precios
                for (String key : modifiedOrderItems.keySet()) {
                    if(orderItemIds.contains(key)){
                        System.debug('ID: ' + key);
                        // Create a new OrderItem object
                        OrderItem oi = new OrderItem();
                        // Set the Id field of the OrderItem to the current key
                        oi.Id = key;
                        //Actualizar precios personalizados de order items con Action Disconnect
                        //Set Pricing Field Values to 0
                        oi.FVU_OneTimeChargeIncTaxes__c = 0;
                        oi.FVU_OneTimeTotalIncTaxes__c = 0;
                        oi.FVU_EffectiveOneTimeTotalIncTaxes__c = 0;
                        oi.FVU_RecurringChargeIncTaxes__c = 0;
                        oi.FVU_RecurringTotalIncTaxes__c = 0;
                        oi.FVU_EffectiveRecurringTotalIncTaxes__c = 0;
                        // Add the new OrderItem to the list of all OrderItems
                        orderItemEntriesList.add(oi);
                        System.debug('orderItemEntriesList: ' + orderItemEntriesList);
                    }
                } 
                //Se actualizan todos los order items en bulk.
                Update as user orderItemEntriesList;

                //Lógica para borrar promoción de producto TyT
                Order cart = [SELECT Account.FVU_StatusTodoClaro__c FROM Order WHERE Id = :cartId WITH USER_MODE];
                String accStatusTodoClaro = cart.Account.FVU_StatusTodoClaro__c;
                System.debug('accStatusTodoClaro: ' + accStatusTodoClaro);

                String procedureName;
                Map<String, Object> ipInput = new Map<String, Object> ();
                Map<String, Object> ipOutput = new Map<String, Object> ();
                Map<String, Object> ipOptions = new Map<String, Object> ();

                //Definir mapas para llamada del método "deleteAppliedPromoItems" desde el cpqAppHandler
                Map<String, Object> deletePromoInput = new Map<String, Object> ();
                Map<String, Object> deletePromoOutput = new Map<String, Object> ();
                Map<String, Object> deletePromoOptions = new Map<String, Object> ();

                //Verificar si hay un plan en la orden
                List<OrderItem> planOrderItem = [SELECT Id FROM OrderItem WHERE OrderId = :cartId AND CAT_ProductType__c = 'Plan Móvil Pospago' WITH USER_MODE];
                System.debug('planOrderItem: ' + planOrderItem);

                //Verificar si hay terminal o tecnología en la orden
                List<OrderItem> tytOrderItems = [SELECT Id FROM OrderItem WHERE OrderId = :cartId AND CAT_ProductType__c = 'TyT' WITH USER_MODE LIMIT 1];
                System.debug('tytOrderItems: ' + tytOrderItems);

                if(accStatusTodoClaro == 'Potencial' && planOrderItem.isEmpty() && !tytOrderItems.isEmpty()){
                    //Buscar si hay promoción asociada al producto TyT
                    System.debug('tytOrderItems[0].Id: ' + tytOrderItems[0].Id);

                    List<vlocity_cmt__OrderAppliedPromotionItem__c> orderAppliedPromosTyT = [SELECT vlocity_cmt__OrderAppliedPromotionId__c FROM vlocity_cmt__OrderAppliedPromotionItem__c WHERE vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_Type__c = 'TodoClaro' AND vlocity_cmt__OrderAppliedPromotionId__r.vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = 'Descuento Todo Claro' AND vlocity_cmt__OrderItemId__c = :tytOrderItems[0].Id WITH USER_MODE];
                    System.debug('orderAppliedPromosTyT: ' + orderAppliedPromosTyT);

                    if(!orderAppliedPromosTyT.isEmpty()){
                        //Llamar remote method DeleteAppliedPromotionItems
                        deletePromoInput.put('cartId', cartId);
                        deletePromoInput.put('id', orderAppliedPromosTyT[0].vlocity_cmt__OrderAppliedPromotionId__c);
                        System.debug('DeleteCartPromotion deletePromoInput: ' + deletePromoInput);
                        vlocity_cmt.CpqAppHandler cpqAppHandlerCall = new vlocity_cmt.CpqAppHandler();
                        Object deleteCartPromotion = cpqAppHandlerCall.invokeMethod('deleteAppliedPromoItems', deletePromoInput, deletePromoOutput, deletePromoOptions);
                        System.debug('DeleteCartPromotion deletePromoOutput: ' + deletePromoOutput);
                    }

                    procedureName = 'CPQ_GetCartLineItemPrices';
                    System.debug('procedureName: ' + procedureName); 
                    ipInput.clear();
                    ipInput.put('cartId', cartId);
                    System.debug('GetCartLineItemPrices ipInput: ' + ipInput);
                    ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
                    System.debug('GetCartLineItemPrices ipOutput: ' + ipOutput);
                }

                /*Get Princicipal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                System.debug('<<<<<< Class: CpqAppHandlerHookCustomImpl -  Method: ' + methodName);
                Integer myDMLLimit = Limits.getDMLStatements();
                Integer globalDMLLimit = Limits.getLimitDMLStatements();
                System.debug('--- myDMLLimit: ' + myDMLLimit +' of ' +globalDMLLimit + ' - Remaining: ' + (globalDMLLimit - myDMLLimit));
                Integer myCPUTimeLimit = Limits.getCpuTime();
                Integer globalCPUTimeLimit = Limits.getLimitCpuTime();
                System.debug('--- myCPUTimeLimit: ' + myCPUTimeLimit +' of ' +globalCPUTimeLimit + ' - Remaining: ' + (globalCPUTimeLimit - myCPUTimeLimit));
                Integer myQueriesLimit = Limits.getQueries();
                Integer globalQueriesLimit = Limits.getLimitQueries();
                System.debug('--- myQueriesLimit: ' + myQueriesLimit +' of ' +globalQueriesLimit + ' - Remaining: ' + (globalQueriesLimit - myQueriesLimit));
                Integer myHeapSizeLimit = Limits.getHeapSize();
                Integer globalHeapSizeLimit = Limits.getLimitHeapSize();
                System.debug('--- myHeapSizeLimit: ' + myHeapSizeLimit +' of ' +globalHeapSizeLimit + ' - Remaining: ' + (globalHeapSizeLimit - myHeapSizeLimit));
                Integer myQueryRowsLimit = Limits.getQueryRows();
                Integer globalQueryRowsLimit = Limits.getLimitQueryRows();
                System.debug('--- myQueryRowsLimit: ' + myQueryRowsLimit +' of ' +globalQueryRowsLimit + ' - Remaining: ' + (globalQueryRowsLimit - myQueryRowsLimit));
                Integer myDMLRowsLimit = Limits.getDMLRows();
                Integer globalDMLRowsLimit = Limits.getLimitDMLRows();
                System.debug('--- myDMLRowsLimit: ' + myDMLRowsLimit +' of ' +globalDMLRowsLimit + ' - Remaining: ' + (globalDMLRowsLimit - myDMLRowsLimit));
                */
            }
            else if (methodName == 'getCartLineItemPrices.PreInvoke'){
                //HU 826417: la pantalla recalcula precios después de agregar un plan, en una transacción aparte.
                //Se reemplaza la SIM Card por eSIM antes de ese cálculo.
                if(!swappingSimToEsim && input.get('cartId') != null){
                    swapSimCardToEsim((Id)input.get('cartId'));
                }
            }
            return true;
        }
        catch (Exception ex)
        {
            System.debug('--- Exception: ' + ex.getMessage());
            System.debug('--- Stack Trace: ' + ex.getStackTraceString());
            throw ex;
        }
    }

    /*
    HU 826417: en una migración pre-pos con eSIM (SimType = eSIM en FVU_MigraData__c) el carrito debe quedar solo con eSIM.
    Las reglas de elegibilidad no aplican a hijos del bundle, por eso se reemplaza la SIM Card por eSIM dentro de su
    "Escoja SIM Card" con los IP CPQ_DeleteItemFromCart y CPQ_AddChildItems.
    Se ejecuta en getCartLineItemPrices.PreInvoke y getCartsItems.PreInvoke, no en el alta del plan: sumado a postCartsItems
    supera el límite de 100 SOQL del namespace vlocity_cmt (medido: alta 57, borrado 12, alta de hijo 12, precios 19).
    Si el grupo ya tiene eSIM (p. ej. el asesor agregó la SIM Card a mano) solo se borra la SIM Card.
    Solo actúa en órdenes Draft y no en Plan + Terminal (ATT), donde el catálogo no permite eSIM.
    Si no se puede agregar la eSIM, se vuelve a poner la SIM Card.
    Al final se recalculan precios con price = true; sin ese parámetro el IP solo lee los precios y la eSIM queda sin valores.
    Si algo falla no se interrumpe la operación del carrito: la orden queda con SIM Card como hasta ahora.
    */
    @TestVisible
    private static void swapSimCardToEsim(Id cartId)
    {
        if(cartId.getSObjectType() != Order.SObjectType){
            return;
        }
        List<Order> orders = [SELECT Pricebook2Id, Status, FVU_PurchaseType__c, FVU_MigraData__c FROM Order WHERE Id = :cartId WITH USER_MODE LIMIT 1];
        //Solo carritos en Draft; en Plan + Terminal (ATT) el flow CAT_OrderItemProductType no permite eSIM
        if(orders.isEmpty() || orders[0].Status != 'Draft' || orders[0].FVU_PurchaseType__c == PLAN_AND_TERMINAL_PURCHASE_TYPE
           || !isEsimSale(orders[0].FVU_MigraData__c)){
            return;
        }
        List<OrderItem> simCardItems = new List<OrderItem>();
        //Grupos "Escoja SIM Card" que ya tienen eSIM: ahí solo se borra la SIM Card
        Set<String> groupsWithEsim = new Set<String>();
        for(OrderItem simItem : [SELECT Id, vlocity_cmt__ParentItemId__c, Product2.ProductCode FROM OrderItem
                                 WHERE OrderId = :cartId AND Product2.ProductCode IN (:SIM_CARD_PRODUCT_CODE, :ESIM_PRODUCT_CODE) WITH USER_MODE]){
            if(simItem.Product2.ProductCode == SIM_CARD_PRODUCT_CODE){
                simCardItems.add(simItem);
            } else {
                groupsWithEsim.add(simItem.vlocity_cmt__ParentItemId__c);
            }
        }
        if(simCardItems.isEmpty()){
            return;
        }
        Id esimEntryId;
        Id simCardEntryId;
        for(PricebookEntry entry : [SELECT Id, Product2.ProductCode FROM PricebookEntry
                                    WHERE Pricebook2Id = :orders[0].Pricebook2Id AND Product2.ProductCode IN (:SIM_CARD_PRODUCT_CODE, :ESIM_PRODUCT_CODE) AND IsActive = true
                                    WITH USER_MODE]){
            if(entry.Product2.ProductCode == ESIM_PRODUCT_CODE){
                esimEntryId = entry.Id;
            } else {
                simCardEntryId = entry.Id;
            }
        }
        if(esimEntryId == null){
            System.debug('--- swapSimCardToEsim: no hay PricebookEntry activa de eSIM en la lista de precios de la orden');
            return;
        }
        Set<String> parentReferences = new Set<String>();
        for(OrderItem simCardItem : simCardItems){
            parentReferences.add(simCardItem.vlocity_cmt__ParentItemId__c);
        }
        //El padre de la SIM Card es el "Escoja SIM Card" del plan
        Map<String, OrderItem> simGroupByReference = new Map<String, OrderItem>();
        for(OrderItem simGroupItem : [SELECT Id, PricebookEntryId, vlocity_cmt__ProductHierarchyPath__c, vlocity_cmt__AssetReferenceId__c
                                      FROM OrderItem WHERE OrderId = :cartId AND vlocity_cmt__AssetReferenceId__c IN :parentReferences WITH USER_MODE]){
            simGroupByReference.put(simGroupItem.vlocity_cmt__AssetReferenceId__c, simGroupItem);
        }

        swappingSimToEsim = true;
        try{
            Boolean cartChanged = false;
            for(OrderItem simCardItem : simCardItems){
                OrderItem simGroupItem = simGroupByReference.get(simCardItem.vlocity_cmt__ParentItemId__c);
                if(simGroupItem == null){
                    continue;
                }
                Map<String, Object> deleteInput = new Map<String, Object>{
                    'cartId' => cartId, 'id' => simCardItem.Id, 'price' => false, 'validate' => false
                };
                Map<String, Object> deleteOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_DeleteItemFromCart', deleteInput, new Map<String, Object>());
                System.debug('--- swapSimCardToEsim CPQ_DeleteItemFromCart output: ' + deleteOutput);
                cartChanged = true;
                if(groupsWithEsim.contains(simCardItem.vlocity_cmt__ParentItemId__c)){
                    continue;
                }

                if(addChildToSimGroup(cartId, simGroupItem, esimEntryId)){
                    groupsWithEsim.add(simCardItem.vlocity_cmt__ParentItemId__c);
                } else if(simCardEntryId != null){
                    //Compensación: si no se pudo agregar la eSIM se vuelve a poner la SIM Card para no dejar el grupo vacío
                    addChildToSimGroup(cartId, simGroupItem, simCardEntryId);
                }
            }
            if(cartChanged){
                Map<String, Object> priceOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_GetCartLineItemPrices', new Map<String, Object>{'cartId' => cartId, 'price' => true}, new Map<String, Object>());
                System.debug('--- swapSimCardToEsim CPQ_GetCartLineItemPrices output: ' + priceOutput);
            }
        }
        catch(Exception ex){
            System.debug('--- swapSimCardToEsim Exception: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        finally{
            swappingSimToEsim = false;
        }
    }

    //Agrega un hijo al "Escoja SIM Card" con el mismo input que arma CATAgregarProductosHijosAlCarrito. True si CPQ responde "Añadido" (código 150).
    private static Boolean addChildToSimGroup(Id cartId, OrderItem simGroupItem, Id pricebookEntryId)
    {
        Map<String, Object> parentRecord = new Map<String, Object>{
            'records' => new List<Object>{ new Map<String, Object>{
                'Pricebook2Id' => simGroupItem.PricebookEntryId,
                'productHierarchyPath' => simGroupItem.vlocity_cmt__ProductHierarchyPath__c
            }}
        };
        Map<String, Object> addInput = new Map<String, Object>{
            'methodName' => 'CPQ_AddChildItems',
            'cartId' => cartId,
            'price' => true,
            'validate' => false,
            'includeAttachment' => false,
            'items' => new List<Object>{ new Map<String, Object>{
                'parentId' => simGroupItem.Id,
                'parentHierarchyPath' => simGroupItem.vlocity_cmt__ProductHierarchyPath__c,
                'itemId' => pricebookEntryId,
                'parentRecord' => parentRecord
            }}
        };
        Map<String, Object> addOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService('CPQ_AddChildItems', addInput, new Map<String, Object>());
        System.debug('--- swapSimCardToEsim CPQ_AddChildItems output: ' + addOutput);
        return hasMessageCode(addOutput, '150');
    }

    @TestVisible
    private static Boolean hasMessageCode(Map<String, Object> ipOutput, String code)
    {
        if(ipOutput == null || !(ipOutput.get('messages') instanceof List<Object>)){
            return false;
        }
        for(Object message : (List<Object>)ipOutput.get('messages')){
            if(message instanceof Map<String, Object> && code.equals(String.valueOf(((Map<String, Object>)message).get('code')))){
                return true;
            }
        }
        return false;
    }

    //FVU_MigraData__c es una lista JSON: [{"ICCID":"...","SimType":"eSIM",...}]
    @TestVisible
    private static Boolean isEsimSale(String migraData)
    {
        if(String.isBlank(migraData)){
            return false;
        }
        try{
            Object parsed = JSON.deserializeUntyped(migraData);
            List<Object> entries = parsed instanceof List<Object> ? (List<Object>)parsed : new List<Object>{parsed};
            for(Object entry : entries){
                if(entry instanceof Map<String, Object> && 'eSIM'.equals(((Map<String, Object>)entry).get('SimType'))){
                    return true;
                }
            }
        }
        catch(JSONException ex){
            System.debug('--- isEsimSale: FVU_MigraData__c no es JSON válido: ' + ex.getMessage());
        }
        return false;
    }
}