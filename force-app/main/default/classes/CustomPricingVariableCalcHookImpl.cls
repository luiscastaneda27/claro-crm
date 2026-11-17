/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Cpq App Handler Hook for custom pricing calculations in the cart - handling custom pricing variables
Code Coverage:  90%
History
<Date>            <Author>             <Description>             <Version>
20-Sep-24         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
global with sharing class CustomPricingVariableCalcHookImpl implements vlocity_cmt.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)  
    {
        try
        {
            if (methodName.equalsIgnoreCase('calculate.PreInvoke'))
            {
                // dump the input
                System.debug('--- calculate.PreInvoke output: ' + JSON.serialize(output));
                System.debug('--- calculate.PreInvoke input: ' + input);
            }
            else if (methodName.equalsIgnoreCase('calculate.PostInvoke')) {
                System.debug('--- calculate.PostInvoke input: ' + input);
                //System.debug(output);
                System.debug('--- calculate.PostInvoke output: ' + JSON.serialize(output));
                Id itemId = (Id)input.get('itemId');
                Boolean isRoot = (Boolean)input.get('isRoot');
                SObject parent = (SObject) vlocity_cmt.PricingPlanService.getFromPricingContext('Parent');
                //Reading isIVAExempt variable from pricing context input
                Boolean isOrderIVAExempt = (Boolean)vlocity_cmt.PricingPlanService.getFromPricingContext('IVAExempt');

                Id parentId = (Id)parent.get('Id');

                //Inicializar variables:
                Map<String, Object> lineItemMap = new Map<String, Object>();
                String prod2Family = '';
                String prod2Type = '';
                String prod2SubType = '';
                String serviceAccountServiceState = '';
                String cityCAV = '';
                Decimal IMPUESTO_DECIMAL = 0;
                Decimal UVT_VIGENTE = 0;
                Boolean aplicaIVA;
                String prod2Attributes = '';
                Map<String, Object> prod2AttributesMap = new Map<String, Object>();
                Integer prod2UVTVal = 0;
                String prod2SupCatProd = '';
                Decimal DEVICE_PRICE_LIMIT = 0;
                //Define si un product2 es terminal y tecnologia
                Boolean prod2TerminalTech = false;

                Map<String, Object> customFieldValuesMap = (Map<String, Object>)vlocity_cmt.PricingPlanService.getFromPricingContext('CUSTOM_FIELDS_VALUES_MAP');
                System.debug('--- customFieldValuesMap: ' + customFieldValuesMap);
                if (customFieldValuesMap != null && customFieldValuesMap.containsKey(itemId)){
                    lineItemMap = (Map<String, Object>)customFieldValuesMap.get(itemId);
                    prod2Family = (String)lineItemMap.get('Family');
                    prod2Type = (String)lineItemMap.get('vlocity_cmt__Type__c');
                    prod2SubType = (String)lineItemMap.get('vlocity_cmt__SubType__c');
                    serviceAccountServiceState = (String)lineItemMap.get('serviceAccDptoCode');
                    cityCAV = (String)lineItemMap.get('daneDptoCAVCode');
                    IMPUESTO_DECIMAL = (Decimal)lineItemMap.get('IMPUESTO_DECIMAL');
                    UVT_VIGENTE = (Decimal)lineItemMap.get('UVT_VIGENTE');
                    aplicaIVA = (Boolean)lineItemMap.get('aplicaIVA');
                    prod2Attributes = (String)lineItemMap.get('vlocity_cmt__AttributeSelectedValues__c');
                    prod2AttributesMap = (Map<String, Object>)JSON.deserializeUntyped(prod2Attributes);
                    prod2UVTVal = 0;
                    prod2SupCatProd = '';
                    prod2TerminalTech = true;
                    if (prod2Family == 'Device' && prod2Type == 'Tech' ){
                        prod2SupCatProd = String.valueOf(prod2AttributesMap.get('B2C-ATTR-TEC-SUP-CAT-PROD'));
                        prod2UVTVal = Integer.valueOf(prod2AttributesMap.get('B2C-ATTR-TEC-LIMITE-UVT'));
                    }
                    else {
                        prod2UVTVal = Integer.valueOf(prod2AttributesMap.get('B2C-ATTR-EXC-IMP-TERM'));
                    }
                }

                Map<String, Object> variableValuesMap = (Map<String, Object>)output.get('pricingVariableMap');

                //Leer las variables de precio
                Decimal OT_STD_PRC_TOTAL = (Decimal)variableValuesMap.get('OT_STD_PRC_TOTAL');
                Decimal REC_MNTH_STD_PRC_TOTAL = (Decimal)variableValuesMap.get('REC_MNTH_STD_PRC_TOTAL');
                Decimal OT_STD_PRC = (Decimal)variableValuesMap.get('OT_STD_PRC');
                Decimal BASE_OT_STD_PRC = (Decimal)variableValuesMap.get('BASE_OT_STD_PRC');
                Decimal BASE_REC_MNTH_STD_PRC = (Decimal)variableValuesMap.get('BASE_REC_MNTH_STD_PRC');
                Decimal REC_MNTH_STD_PRC = (Decimal)variableValuesMap.get('REC_MNTH_STD_PRC');
                Decimal REC_MNTH_STD_PRC_INC_TAXES = (Decimal)variableValuesMap.get('REC_MNTH_STD_PRC_INC_TAXES'); //Precio por unidad "Mensual con impuestos"
                Decimal OT_STD_PRC_INC_TAXES = (Decimal)variableValuesMap.get('OT_STD_PRC_INC_TAXES'); //Precio por unidad One Time con impuestos
                Decimal ROLLUP_OT_STD_PRC_INC_TAXES_TOTAL = (Decimal)variableValuesMap.get('ROLLUP_OT_STD_PRC_INC_TAXES_TOTAL');
                Decimal OT_STD_PRC_VENTA = (Decimal)variableValuesMap.get('OT_STD_PRC_VENTA');
                Decimal EFF_OT_STD_PRC_TOTAL = (Decimal)variableValuesMap.get('EFF_OT_STD_PRC_TOTAL');
                Decimal EFF_REC_MNTH_STD_PRC_TOTAL = (Decimal)variableValuesMap.get('EFF_REC_MNTH_STD_PRC_TOTAL');

                //UVT_VIGENTE es diferente de cero en caso que no sea un equipo Terminal o Tecnología
                if(UVT_VIGENTE != 0){
                    DEVICE_PRICE_LIMIT = UVT_VIGENTE * prod2UVTVal;
                }

                Decimal OT_STD_PRC_INC_TAXES_TOTAL = (Decimal)variableValuesMap.get('OT_STD_PRC_INC_TAXES_TOTAL');
                Decimal REC_MNTH_STD_PRC_INC_TAXES_TOTAL = (Decimal)variableValuesMap.get('REC_MNTH_STD_PRC_INC_TAXES_TOTAL');

                //Lee la cantidad que se agregaron del item en el carrito, se lee para el análisis de cantidades más adelante
                Decimal LINE_QUANTITY = (Decimal)variableValuesMap.get('LINE_QUANTITY');

                // Check if the Line Item is exempt from taxes.
                // Calculate One Time Total including Taxes for the line item
                if (OT_STD_PRC_TOTAL != 0.00)
                {
                    if(OT_STD_PRC_INC_TAXES != 0.00 || ROLLUP_OT_STD_PRC_INC_TAXES_TOTAL != 0.00){
                        //Se ingresa acá si se trata de un producto que tiene definido precio one time incluyendo impuestos, esto quiere decir que no es de Terminales y Tecnología.
                        //O si es un producto que es padre de un producto que tiene definido precio one time incluyendo impuestos.
                        //Análisis de cantidades ya se tiene en OT_STD_PRC_TOTAL por defecto.
                        //Se copia el precio por unidad con impuestos a la variable de precio total con impuestos. Se asume una sola unidad del producto en el carrito.
                        //Manejo del roll up del precio one time incluyendo impuestos. Incluye análisis de cantidades.
                        OT_STD_PRC_INC_TAXES_TOTAL = (OT_STD_PRC_INC_TAXES + ROLLUP_OT_STD_PRC_INC_TAXES_TOTAL) * LINE_QUANTITY;
                        //Precio de lista: (sin impuestos, sin descuentos) se define como 0 porque al precio de lista no se le aplicaron descuentos. (A la SIM Card no le aplican promociones)
                        BASE_OT_STD_PRC = 0;
                    } else {
                        if(aplicaIVA == true){
                            // Si la compra no está exenta de impuestos, el valor a pagar es el precio sin impuestos luego de descuentos + los  impuestos
                            // El precio de venta es el precio de lista + impuestos (calculado en el paso del plan de precios con implementación    ClaroCustomAddFieldsPricingPlanStepImpl)
                            //  - El precio de venta calculado (OT_STD_PRC_VENTA) no se modifica en este escenario

                            OT_STD_PRC_INC_TAXES_TOTAL = OT_STD_PRC_TOTAL * IMPUESTO_DECIMAL;

                            //Escenario: A la venta aplica impuestos, pero el precio luego de descuentos o el precio sin impuestos si no hay    descuentos,
                            //es menor al límite de UVTs del producto (Terminal o Tecnología únicamente)
                            //esto termina en exención de impuestos.
                            if (prod2Family == 'Device' && (prod2Type == 'Handset' || prod2Type == 'Tech') && DEVICE_PRICE_LIMIT > OT_STD_PRC)
                            {
                                System.debug('--- AplicaIVA: True. Terminal/Tecnología: Precio luego de descuentos es menor al límite de UVTs');
                                System.debug('--- AplicaIVA: True. Se usa el mismo comportamiento que sin impuestos, pero el precio de venta si     lleva impuestos');
                                //Si la compra es de un Terminal o equipo de Tecnología y el precio sin impuestos luego de descuentos es menor al   límite de UVTs,
                                //el valor a pagar es el mismo que el precio sin impuestos luego de descuentos.
                                OT_STD_PRC_INC_TAXES_TOTAL = OT_STD_PRC_TOTAL;
                            }
                        } else {
                            // Si la compra está exenta de impuestos:
                            //  - El precio de venta debe ser igual al precio de lista (precio sin impuestos antes de descuentos)
                            OT_STD_PRC_VENTA = BASE_OT_STD_PRC;
                            //  - El total a pagar (OT_STD_PRC_INC_TAXES_TOTAL) debe ser igual al precio luego de aplicados los descuentos  OT_STD_PRC_TOTAL
                            OT_STD_PRC_INC_TAXES_TOTAL = OT_STD_PRC_TOTAL;
                        }

                        // Save the new Pricing Variables in the Variable Values Map
                        //If the One Time Std Price including Taxes is the same as the Base One Time Std Price (original Price List Entry Value)
                        //  it means there were no discounts/promotions and no taxes applied to the original price list entry value.
                        //If the One Time Std Price is the same as the Base One Time Std Price (original Price List Entry Value)
                        //  it means no discounts/promotions were applied to the original price list entry value.
                        //  setting BASE_OT_STD_PRC = 0 makes that no Base price is shown in the LWC Cart. (customization applied to the    cpqCartItemPrices FlexCard)
                        if(OT_STD_PRC_INC_TAXES_TOTAL == BASE_OT_STD_PRC || OT_STD_PRC == BASE_OT_STD_PRC)
                        {
                            BASE_OT_STD_PRC = 0;
                        }
                    }

                    // Evalua si el producto es de terminales y tecnologia.
                    if(prod2TerminalTech){
                        //Precio sin impuestos luego de descuentos
                        variableValuesMap.put('OT_STD_PRC', OT_STD_PRC.setScale(0, RoundingMode.HALF_UP));
                        //Precio de lista: (sin impuestos, sin descuentos) o 0 si es que al precio de lista no se le aplicaron descuentos y la  compra está exenta de impuestos.
                        variableValuesMap.put('BASE_OT_STD_PRC', BASE_OT_STD_PRC.setScale(0, RoundingMode.HALF_UP));
                        //Precio de venta: Precio de lista + impuestos, o precio de lista si está exento de impuestos o el precio de lista es menor     al límite de UVTs.
                        variableValuesMap.put('OT_STD_PRC_VENTA', OT_STD_PRC_VENTA.setScale(0, RoundingMode.HALF_UP));
                        //Precio sin impuestos luego de descuentos total (acumula precios si hay más de un item en el carrito)
                        variableValuesMap.put('OT_STD_PRC_TOTAL', OT_STD_PRC_TOTAL.setScale(0, RoundingMode.HALF_UP));
                        //Valor a pagar: Valor final luego de descuentos y análisis de exención de impuestos
                        variableValuesMap.put('OT_STD_PRC_INC_TAXES_TOTAL', OT_STD_PRC_INC_TAXES_TOTAL.setScale(0, RoundingMode.HALF_UP));

                        // Only for root items, we copy the OT_STD_PRC_INC_TAXES_TOTAL
                        // to EFF_OT_STD_PRC_INC_TAX_TOTAL
                        // since the latter will be rolled up to a field in the parent as the SUM of
                        // all root child item effective values in the Cart
                        if(isRoot){
                            variableValuesMap.put('EFF_OT_STD_PRC_INC_TAXES_TOTAL', OT_STD_PRC_INC_TAXES_TOTAL.setScale(0, RoundingMode.HALF_UP));
                            variableValuesMap.put('EFF_OT_STD_PRC_TOTAL', EFF_OT_STD_PRC_TOTAL.setScale(0, RoundingMode.HALF_UP));
                        }
                    }else{
                        variableValuesMap.put('OT_STD_PRC', OT_STD_PRC.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('BASE_OT_STD_PRC', BASE_OT_STD_PRC.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('OT_STD_PRC_VENTA', OT_STD_PRC_VENTA.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('OT_STD_PRC_TOTAL', OT_STD_PRC_TOTAL.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('OT_STD_PRC_INC_TAXES_TOTAL', OT_STD_PRC_INC_TAXES_TOTAL.setScale(2, RoundingMode.HALF_UP));

                        if(isRoot){
                            variableValuesMap.put('EFF_OT_STD_PRC_INC_TAXES_TOTAL', OT_STD_PRC_INC_TAXES_TOTAL.setScale(2, RoundingMode.HALF_UP));
                            variableValuesMap.put('EFF_OT_STD_PRC_TOTAL', EFF_OT_STD_PRC_TOTAL.setScale(2, RoundingMode.HALF_UP));
                        }
                    }
                }

                // Análisis de si el precio es recurrente.
                if (REC_MNTH_STD_PRC != 0.00 && REC_MNTH_STD_PRC_INC_TAXES != 0.00)
                {
                    //System.debug('--- calculate.PostInvoke input: ' + JSON.serialize(input));
                    System.debug('--- calculate.PostInvoke output: ' + JSON.serialize(output));
                    System.debug('--- calculate.PostInvoke options: ' + JSON.serialize(options));

                    if (isOrderIVAExempt == true){
                        System.debug('isIVAExempt -> true');
                        REC_MNTH_STD_PRC_INC_TAXES_TOTAL = REC_MNTH_STD_PRC_TOTAL;
                    } else {
                        //Análisis de cantidades ya se tiene en REC_MNTH_STD_PRC_TOTAL por defecto.
                        REC_MNTH_STD_PRC_INC_TAXES_TOTAL = REC_MNTH_STD_PRC_INC_TAXES;
                    }
                    //Si el precio base (recurrente sin impuestos) es igual al precio recurrente sin impuestos luego de descuentos el precio base se deja en 0 para que no se muestre el precio tachado en el carrito.
                    System.debug('--- calculate.PostInvoke BASE_REC_MNTH_STD_PRC: ' + BASE_REC_MNTH_STD_PRC);
                    System.debug('--- calculate.PostInvoke REC_MNTH_STD_PRC: ' + REC_MNTH_STD_PRC);
                    if(BASE_REC_MNTH_STD_PRC == REC_MNTH_STD_PRC || BASE_REC_MNTH_STD_PRC == REC_MNTH_STD_PRC_INC_TAXES){
                        BASE_REC_MNTH_STD_PRC = 0;
                    }
                    //Si es terminal o tecnología se redondean los precios sin decimales
                    if(prod2TerminalTech){
                        variableValuesMap.put('REC_MNTH_STD_PRC', REC_MNTH_STD_PRC.setScale(0, RoundingMode.HALF_UP));
                        variableValuesMap.put('REC_MNTH_STD_PRC_TOTAL', REC_MNTH_STD_PRC_TOTAL.setScale(0, RoundingMode.HALF_UP));
                        //Se debe copiar REC_MNTH_STD_PRC_TOTAL a REC_MNTH_STD_PRC_INC_TAXES_TOTAL. No es técnicamente necesario pero se hace
                        //para mantener la compatibilidad con el manejo de los precios One Time.
                        variableValuesMap.put('REC_MNTH_STD_PRC_INC_TAXES_TOTAL', REC_MNTH_STD_PRC_INC_TAXES_TOTAL.setScale(0, RoundingMode.HALF_UP));
                        variableValuesMap.put('BASE_REC_MNTH_STD_PRC', BASE_REC_MNTH_STD_PRC.setScale(0, RoundingMode.HALF_UP));
                        // Only for root items, we copy the REC_MNTH_STD_PRC_INC_TAXES_TOTAL
                        // to EFF_REC_MNTH_STD_PRC_INC_TAXES_TOTAL
                        // since the latter will be rolled up to a field in the parent as the SUM of
                        // all root child item effective values in the Cart
                        if (isRoot){
                            variableValuesMap.put('EFF_REC_MNTH_STD_PRC_INC_TAXES_TOTAL', REC_MNTH_STD_PRC_INC_TAXES_TOTAL.setScale(0, RoundingMode.HALF_UP));
                            variableValuesMap.put('EFF_REC_MNTH_STD_PRC_TOTAL', EFF_REC_MNTH_STD_PRC_TOTAL.setScale(0, RoundingMode.HALF_UP));
                        }
                    }else {
                        // Para Servicios Moviles se redondea a 2 decimales
                        variableValuesMap.put('REC_MNTH_STD_PRC', REC_MNTH_STD_PRC.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('REC_MNTH_STD_PRC_TOTAL', REC_MNTH_STD_PRC_TOTAL.setScale(2, RoundingMode.HALF_UP));
                        //Se debe copiar REC_MNTH_STD_PRC_TOTAL a REC_MNTH_STD_PRC_INC_TAXES_TOTAL. No es técnicamente necesario pero se hace
                        //para mantener la compatibilidad con el manejo de los precios One Time.
                        variableValuesMap.put('REC_MNTH_STD_PRC_INC_TAXES_TOTAL', REC_MNTH_STD_PRC_INC_TAXES_TOTAL.setScale(2, RoundingMode.HALF_UP));
                        variableValuesMap.put('BASE_REC_MNTH_STD_PRC', BASE_REC_MNTH_STD_PRC.setScale(2, RoundingMode.HALF_UP));
                        // Only for root items, we copy the REC_MNTH_STD_PRC_INC_TAXES_TOTAL
                        // to EFF_REC_MNTH_STD_PRC_INC_TAXES_TOTAL
                        // since the latter will be rolled up to a field in the parent as the SUM of
                        // all root child item effective values in the Cart
                        if (isRoot){
                            variableValuesMap.put('EFF_REC_MNTH_STD_PRC_INC_TAXES_TOTAL', REC_MNTH_STD_PRC_INC_TAXES_TOTAL.setScale(2, RoundingMode.HALF_UP));
                            variableValuesMap.put('EFF_REC_MNTH_STD_PRC_TOTAL', EFF_REC_MNTH_STD_PRC_TOTAL.setScale(2, RoundingMode.HALF_UP));
                        }
                    }
                }

                System.debug('updated variableValuesMap: '+ JSON.serialize(variableValuesMap));
                //Get Principal Governor Limits
                //Remover el comentario cuando se quieran realizar pruebas de desempeño
                /*
                System.debug('<<<<<< Class: CustomPricingVariableCalcHookImpl -  Method: ' + methodName);
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
            return true;
        }
        catch (Exception ex)
        {
            System.debug('--- Exception: ' + ex.getMessage());
            System.debug('--- Stack Trace: ' + ex.getStackTraceString());
            throw ex;
        }
    }
}