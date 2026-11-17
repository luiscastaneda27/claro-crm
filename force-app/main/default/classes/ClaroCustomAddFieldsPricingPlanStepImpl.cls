/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class for putting variables into the pricing context
Code Coverage:  99%
History
<Date>            <Author>             <Description>             <Version>
20-Mar-24         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
global with sharing class ClaroCustomAddFieldsPricingPlanStepImpl implements vlocity_cmt.VlocityOpenInterface
{
    global Boolean invokeMethod (String methodName,
                                Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options)
    {
        if (methodName == 'GetSalesContextInfo')
        {
            System.debug('GetSalesContextInfoInput: ' + input);
            GetSalesContextInfo(input, output, options);
            return true;
        }
        return false;
    }
    private void GetSalesContextInfo(Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options)
    {
        //Copy OneTimeCharge value before discounts/promotions to BaseOneTimeCharge so the original (rounded) price list entry value can be shown in the Cart and is available in the sales flow
        //Get the full pricing variables map for the Order
        Map<Id, Map<String, Object>> priceVarMap;
        if (!Test.isRunningTest()) 
        {
            priceVarMap = vlocity_cmt.PricingPlanService.getLineItemPricingVariableValues();
        }
        else
        {
            priceVarMap = (Map<Id, Map<String, Object>>)vlocity_cmt.PricingPlanService.getFromPricingContext('TestLineItemPricingVariableValues');
        }
        //if (priceVarMap == null || priceVarMap.isEmpty() || input.isEmpty()) { return; }
        if (priceVarMap == null || priceVarMap.isEmpty()) { return; }
        System.debug('LineItemPricingVariableValues: ' + JSON.serialize(priceVarMap));
        // Get Order Id from the pricing context, to be used when querying extra info from the Order.
        SObject parentObject = (SObject) vlocity_cmt.PricingPlanService.getFromPricingContext('Parent');
        Id cartId = (Id)parentObject.get('Id');
        //Identificar si se trata de una Orden o de una Cotización
        String objectType = cartId.getSObjectType().getDescribe().getName();
        System.debug('CartId Object Type: ' + objectType);
        //Consultar información adicional del carrito.
        //La siguiente información es requerida que esté en el carrito (Orden o Cotización).
        //  - Canal Venta: FVU_Channel__c
        //  - Dane Ciudad CAV: FVU_DaneCiudadCAVOrden__c
        //  - Service Account. Dane Code: vlocity_cmt__DefaultServiceAccountId__r.FVU_ServiceDaneCode__c
        //  - Dept. Tienda Retiro: FVU_TiendaRetiroDaneCode__c
        //  - Dept. Bodega Envío: FVU_BodegaEnvioDaneCode__c
        //  - Método de entrega: vlocity_cmt__DeliveryMethod__c //Immediatepickup, Retiro en tienda, Entrega en domicilio
        List<SObject> orderExtraInfo;
        List<SObject> quoteExtraInfo;
        List<SObject> cartExtraInfo;
        //List<OrderItem> orderItemExternalPrices;
        List<SObject> orderItemExternalPrices;
        //Map<Id, OrderItem> orderItemExternalPricesMap;
        Map<Id, SObject> orderItemExternalPricesMap;
        String deliveryMethod;
        Boolean isIVAExemptOrder; //Variable que guarda si la orden está excenta de impuestos o no
        if(objectType == 'Quote'){
            cartExtraInfo = [SELECT Id, FVU_Channel__c,FVU_DaneCiudadCAVOrden__c,vlocity_cmt__DefaultServiceAccountId__r.FVU_ServiceDaneCode__c,FVU_TiendaRetiroDaneCode__c,FVU_BodegaEnvioDaneCode__c,CAT_DeliveryMethod__c,vlocity_cmt__ParentQuoteId__c ,RecordType.DeveloperName FROM Quote WHERE Id = :cartId WITH USER_MODE];
            System.debug('Quote - cartExtraInfo: ' + JSON.serialize(cartExtraInfo));
            //Se identifica si se está trabajando con un carrito tipo "WorkingCart" (carrito temporal).
            Id parentQuoteId = (Id)cartExtraInfo[0].get('vlocity_cmt__ParentQuoteId__c');
            System.debug('Quote - parentQuoteId: ' + parentQuoteId);
            String recordTypeName = (String)cartExtraInfo[0].getSObject('RecordType').get('DeveloperName');
            System.debug('Quote - recordTypeName: ' + recordTypeName);
            //Si el record type es "WorkingCart", se debe traer la información extra de la cotización padre (carrito original)
            if(recordTypeName == 'WorkingCart'){
                cartExtraInfo = [SELECT Id, FVU_Channel__c,FVU_DaneCiudadCAVOrden__c,vlocity_cmt__DefaultServiceAccountId__r.FVU_ServiceDaneCode__c,FVU_TiendaRetiroDaneCode__c,FVU_BodegaEnvioDaneCode__c,CAT_DeliveryMethod__c,vlocity_cmt__ParentQuoteId__c ,RecordType.DeveloperName FROM Quote WHERE Id = :parentQuoteId WITH USER_MODE];
            }
            deliveryMethod = (String)cartExtraInfo[0].get('CAT_DeliveryMethod__c');
            System.debug('Quote - deliveryMethod: ' + deliveryMethod);
        } else {
            cartExtraInfo = [SELECT Id, FVU_Channel__c,FVU_DaneCiudadCAVOrden__c,vlocity_cmt__DefaultServiceAccountId__r.FVU_ServiceDaneCode__c,FVU_TiendaRetiroDaneCode__c,FVU_BodegaEnvioDaneCode__c,vlocity_cmt__DeliveryMethod__c,vlocity_cmt__ParentOrderId__c ,RecordType.DeveloperName, FVU_IsIVAExempt__c FROM Order WHERE Id = :cartId WITH USER_MODE];
            orderItemExternalPrices = [SELECT Id, CAT_ExternalPrice__c FROM OrderItem WHERE OrderId = :cartId WITH USER_MODE];
            //orderItemExternalPricesMap = new Map<Id, OrderItem>(orderItemExternalPrices);
            orderItemExternalPricesMap = new Map<Id, SObject>(orderItemExternalPrices);
            System.debug('orderItemExternalPrices (lista): ' + orderItemExternalPrices);
            System.debug('orderItemExternalPricesMap (map): ' + orderItemExternalPricesMap);

            //Obtener información si la orden está exenta o no de impuestos (aplica para servicios móviles no para Terminales/Tecnología)
            //Y se guarda en el Pricing Context
            isIVAExemptOrder = (Boolean)cartExtraInfo[0].get('FVU_IsIVAExempt__c');
            System.debug('isIVAExemptOrder: ' + isIVAExemptOrder);
            if(isIVAExemptOrder == true){
                vlocity_cmt.PricingPlanService.putInPricingContext('IVAExempt', true);
            } else{
                vlocity_cmt.PricingPlanService.putInPricingContext('IVAExempt', false);
            }
            Id parentOrderId = (Id)cartExtraInfo[0].get('vlocity_cmt__ParentOrderId__c');
            String recordTypeName = (String)cartExtraInfo[0].getSObject('RecordType').get('DeveloperName');
            //Si el record type es "WorkingCart", se debe traer la información extra de la orden del parent order (carrito original)
            if(recordTypeName == 'WorkingCart'){
                cartExtraInfo = [SELECT Id, FVU_Channel__c,FVU_DaneCiudadCAVOrden__c,vlocity_cmt__DefaultServiceAccountId__r.FVU_ServiceDaneCode__c,FVU_TiendaRetiroDaneCode__c,FVU_BodegaEnvioDaneCode__c,vlocity_cmt__DeliveryMethod__c,vlocity_cmt__ParentOrderId__c ,RecordType.DeveloperName FROM Order WHERE Id = :parentOrderId WITH USER_MODE];
            }
            deliveryMethod = (String)cartExtraInfo[0].get('vlocity_cmt__DeliveryMethod__c');
        }
        // Get the cart line items from the pricing context
        List<SObject> itemList = (List<SObject>)vlocity_cmt.PricingPlanService.getFromPricingContext('LineItemList');
        //Lista que va a almacenar los order items que corresponden a Terminales o Tecnología.
        List<SObject> devicesItemList =  new List<SObject>();
        //Initialize new Map for storing the additional information required for every Line Item (OrderItem)
        Map<string, object> additionalInfoItemsMap = new Map<string, object>(); //Key is the LineItem ID, value is a Map with all the required info
        //Si no hay items en el carrito no se realiza ningún análisis adicional
        if (itemList == null || itemList.isEmpty()) { return; }
        //Analizar si la venta debe llevar IVA o no, por defecto si lleva IVA.
        Boolean aplicaIVAOrden = true;
        String salesChannel = (String)cartExtraInfo[0].get('FVU_Channel__c');
        String serviceAccDaneCode = (String)cartExtraInfo[0].getSObject('vlocity_cmt__DefaultServiceAccountId__r').get('FVU_ServiceDaneCode__c');
        System.debug('serviceAccDaneCode: ' + serviceAccDaneCode);
        String serviceAccDptoCode = '';
        //Obtener los primeros dos dígitos del código DANE (Departamento)
        if(serviceAccDaneCode != null){
            serviceAccDptoCode = serviceAccDaneCode.substring(0,2);
        }
        String daneCiudadCAV = (String)cartExtraInfo[0].get('FVU_DaneCiudadCAVOrden__c');
        System.debug('daneCiudadCAV: ' + daneCiudadCAV);
        String daneDptoCAVCode = '';
        //Obtener los primeros dos dígitos del código DANE (Departamento)
        if(daneCiudadCAV != null){
            if(salesChannel == 'SF_CAV' && daneCiudadCAV.length() == 8){
                daneDptoCAVCode = daneCiudadCAV.substring(0,2);
            }
        }
        String tiendaRetDaneCode = (String)cartExtraInfo[0].get('FVU_TiendaRetiroDaneCode__c');
        String tiendaRetDptoCode = '';
        if(tiendaRetDaneCode != null){
            tiendaRetDptoCode = tiendaRetDaneCode.substring(0,2);
        }
        String bodegaEnvioDaneCode = (String)cartExtraInfo[0].get('FVU_BodegaEnvioDaneCode__c');
        String bodegaEnvioDptoCode = '';
        if(bodegaEnvioDaneCode != null){
            bodegaEnvioDptoCode = bodegaEnvioDaneCode.substring(0,2);
        }
        //Obtener todos los Product2Ids de los OrderItems en un string para ser usados en un query
        Id prod2Id;
        list<Id> product2IdsStrList = new list<Id>();
        List<SObject> productsExtraInfo;
        Map<Id, SObject> productsExtraInfoMap = new Map<Id, SObject>();
        System.debug('itemList: '+ JSON.serialize(itemList));
        for (SObject cartItem : itemList){
            prod2Id = (Id)cartItem.get('vlocity_cmt__Product2Id__c');
            System.debug('prod2Id: ' + prod2Id);
            product2IdsStrList.add(prod2Id);
            //product2IdsStrList.add((Id)cartItem.get('vlocity_cmt__Product2Id__c')); 
        }
        System.debug('product2IdsStrList: ' + JSON.serialize(product2IdsStrList));
        productsExtraInfo = [SELECT Id, ProductCode,Family, vlocity_cmt__Type__c, vlocity_cmt__SubType__c FROM Product2 WHERE Id IN :product2IdsStrList WITH USER_MODE];
        productsExtraInfoMap = new Map<Id, SObject>(productsExtraInfo);

        //Identificar si es un plan móvil.
        //Plan móvil no necesita análisis de UVTs o exención de IVA, la orden ya viene marcada
        //con identificador de si lleva impuestos o no.

        //Loop through the itemList (order items)
        //Se repite este loop para evitar hacer queries SOQL dentro de loops
        for (SObject cartItem : itemList){
            //Get Line Item Id from the itemList
            Id lineItemId = (Id)cartItem.get('Id');
            // Get the Product2Id from the itemList
            Id productId = (Id)cartItem.get('vlocity_cmt__Product2Id__c');

            SObject productInfo = (SObject)productsExtraInfoMap.get(productId);
            String prodFamily = (String)productInfo.get('Family');
            String prodType = (String)productInfo.get('vlocity_cmt__Type__c');
            String prodSubType = (String)productInfo.get('vlocity_cmt__SubType__c');
            String prodCode = (String)productInfo.get('ProductCode');

            Map<String, Object> valuesMap = priceVarMap.get(lineItemId);
            Map<String, Object> lineItemPricingVariableMap;

            //OrderItem orderItemPrice = (OrderItem)orderItemExternalPricesMap.get(lineItemId);
            SObject orderItemPrice;
            if(orderItemExternalPricesMap != null){
                orderItemPrice = (SObject)orderItemExternalPricesMap.get(lineItemId);
                System.debug('cartItemPrice: '+ JSON.serialize(orderItemPrice));
            }
            if (valuesMap != null){
                lineItemPricingVariableMap = (Map<String, Object>)valuesMap.get('PricingVariableValues');
                if(orderItemPrice != null){
                    Decimal orderItemExternalPrice = (Decimal)orderItemPrice.get('CAT_ExternalPrice__c');
                    System.debug('orderItemExternalPrice: '+ JSON.serialize(orderItemExternalPrice));
                    if(orderItemExternalPrice > 0 && lineItemPricingVariableMap != null){
                        Decimal OT_STD_PRC = (Decimal)lineItemPricingVariableMap.get('OT_STD_PRC');
                        Decimal OT_EXT_PRC = (Decimal)lineItemPricingVariableMap.get('OT_EXT_PRC');
                        // Guardar el precio externo en la variable one time asociada al precio del order item
                        OT_STD_PRC = orderItemExternalPrice;
                        OT_EXT_PRC = orderItemExternalPrice;
                        lineItemPricingVariableMap.put('OT_STD_PRC', OT_STD_PRC.setScale(0, RoundingMode.HALF_UP));
                        lineItemPricingVariableMap.put('OT_EXT_PRC', OT_EXT_PRC.setScale(0, RoundingMode.HALF_UP));
                    }
                }
            }
            //Si es Terminal, Tecnología, Cargo de Envío o SIM Card se agrega a una nueva lista a la que si se le aplica análisis.
            if((prodFamily == 'Device' && (prodType == 'Handset' || prodType == 'Tech')) || prodSubType == 'Cargo de Envío' || prodType == 'SIM Card'){
                devicesItemList.add(cartItem);
            } else {
                if (lineItemPricingVariableMap != null){
                    Decimal REC_MNTH_STD_PRC = (Decimal)lineItemPricingVariableMap.get('REC_MNTH_STD_PRC'); //Precio por unidad "Mensual sin impuestos"
                    Decimal REC_MNTH_STD_PRC_INC_TAXES = (Decimal)lineItemPricingVariableMap.get('REC_MNTH_STD_PRC_INC_TAXES'); //Precio por unidad "Mensual con impuestos"
                    //Guardar Recurring Monthly como precio BASE, BASE controla si se muestra o no se muestra la diferencia entre precio de venta y valor a pagar (precio tachado)
                    // Si la orden de venta lleva impuestos se guarda como base el precio con impuestos, si no se guarda el precio sin impuestos.
                    if(isIVAExemptOrder == true){
                        lineItemPricingVariableMap.put('BASE_REC_MNTH_STD_PRC', REC_MNTH_STD_PRC);
                    }else{
                        lineItemPricingVariableMap.put('BASE_REC_MNTH_STD_PRC', REC_MNTH_STD_PRC_INC_TAXES); 
                    }
                }
            }
        }
        //Si la lista de order items de Terminales y Tecnología está vacía no se debe hacer nada más.
        if(devicesItemList.size() == 0) { return; }
        //Análisis de impuestos para Terminales y Tecnología
        //Escenario 1: Entrega Inmediata (Immediatepickup)
        if(deliveryMethod == 'Immediatepickup'){
            List<FVU_Exencion_IVA_EI__c> aplicaIVAList = [SELECT FVU_EEI_Aplica_IVA__c FROM FVU_Exencion_IVA_EI__c WHERE FVU_EEI_DaneDpto_CAV__c = :daneDptoCAVCode WITH USER_MODE LIMIT 1];
            System.debug('Immediatepickup - daneDptoCAVCode: ' + daneDptoCAVCode);
            System.debug('Immediatepickup - aplicaIVAList: ' + JSON.serialize(product2IdsStrList));
            if (!aplicaIVAList.isEmpty() && aplicaIVAList[0].FVU_EEI_Aplica_IVA__c == 'No' ){
                aplicaIVAOrden = false;
            }
            System.debug('Immediatepickup - aplicaIVAOrden: ' + aplicaIVAOrden);
        } else if (deliveryMethod == 'Delivery'){
            //Escenario 2: Entrega en domicilio (Delivery)
            // 1. Se consulta FVU_Exencion_IVA_Dom__c para traer resultados usando:
            //  -- El Canal de Venta, la ciudad del CAV (o TMK) y el código DANE (Depto) de la dirección de servicio.
            //  OR
            //  -- El Canal de Venta y el código DANE (Depto) de la dirección de servicio.
            // 
            // 2. Si no hay resultados, la venta lleva IVA a menos que salga de una bodega con exención.
            List<FVU_Exencion_IVA_Dom__c> aplicaIVAList = [SELECT FVU_EDOM_Aplica_IVA__c FROM FVU_Exencion_IVA_Dom__c WHERE (FVU_EDOM_Canal_Venta__c = :salesChannel AND FVU_EDOM_DaneDpto_CAV__c = :daneDptoCAVCode AND FVU_EDOM_Cod_Depto_Destino__c = :serviceAccDptoCode) OR (FVU_EDOM_Canal_Venta__c = :salesChannel AND FVU_EDOM_DaneDpto_CAV__c = '' AND FVU_EDOM_Cod_Depto_Destino__c = :serviceAccDptoCode) WITH USER_MODE LIMIT 1];
            if (!aplicaIVAList.isEmpty() && aplicaIVAList[0].FVU_EDOM_Aplica_IVA__c == 'No' ){
                aplicaIVAOrden = false;
            } else {
                //Si a la venta le aplica IVA, revisar si el equipo sale de una Bodega que tenga exención de IVA
                List<FVU_Exencion_IVA_Bodega_Envio__c> bodegaEnvioList = [SELECT FVU_EBODG_Aplica_IVA__c FROM FVU_Exencion_IVA_Bodega_Envio__c WHERE FVU_EBODG_Cod_Dept_Bodega__c = :bodegaEnvioDptoCode WITH USER_MODE LIMIT 1];
                if (!bodegaEnvioList.isEmpty() && bodegaEnvioList[0].FVU_EBODG_Aplica_IVA__c == 'No' ){
                    aplicaIVAOrden = false;
                }
            }
        } else if (deliveryMethod == 'PickUp'){
            //Escenario 3: Entrega en domicilio (PickUp)
            // 1. Se consulta FVU_Exencion_IVA_Ret_Tienda__c para traer resultados usando:
            //  -- El Canal de Venta, la ciudad del CAV (o TMK) y el código DANE (Depto) de la tienda de retiro.
            //  OR
            //  -- El Canal de Venta y el código DANE (Depto) de la tienda de retiro.
            // 
            // 2. Si no hay resultados, la venta lleva IVA a menos que salga de una bodega con exención.
            List<FVU_Exencion_IVA_Ret_Tienda__c> aplicaIVAList = [SELECT FVU_ERT_Aplica_IVA__c FROM FVU_Exencion_IVA_Ret_Tienda__c WHERE (FVU_ERT_Canal_Venta__c = :salesChannel AND FVU_ERT_DaneDpto_CAV__c = :daneDptoCAVCode AND FVU_ERT_Cod_Depto_Tienda__c = :tiendaRetDptoCode) OR (FVU_ERT_Canal_Venta__c = :salesChannel AND FVU_ERT_DaneDpto_CAV__c = '' AND FVU_ERT_Cod_Depto_Tienda__c = :tiendaRetDptoCode) WITH USER_MODE LIMIT 1];
            if (!aplicaIVAList.isEmpty() && aplicaIVAList[0].FVU_ERT_Aplica_IVA__c == 'No' ){
                aplicaIVAOrden = false;
            } else {
                //Si a la venta le aplica IVA, revisar si el equipo sale de una Bodega que tenga exención de IVA
                List<FVU_Exencion_IVA_Bodega_Envio__c> bodegaEnvioList = [SELECT FVU_EBODG_Aplica_IVA__c FROM FVU_Exencion_IVA_Bodega_Envio__c WHERE FVU_EBODG_Cod_Dept_Bodega__c = :bodegaEnvioDptoCode WITH USER_MODE LIMIT 1];
                if (!bodegaEnvioList.isEmpty() && bodegaEnvioList[0].FVU_EBODG_Aplica_IVA__c == 'No' ){
                    aplicaIVAOrden = false;
                }
            }
        }
        Decimal lineItemNumber = 1;
        Decimal puntosTVNumber = 1;
        //Leer el valor en $ vigente de una UVT
        Decimal UVT_VIGENTE = 0;
        //Trae el valor en UTC, pero funciona bien porque los valores en el objeto FVU_UVT_info__c están guardados también en UTC.
        //"FVU_UVT_Fecha_Final_Vigencia__c":"2024-01-01T05:00:00.000Z"
        Datetime currentTime = Datetime.now();
        List<FVU_UVT_info__c> UVT = [SELECT Id, Name, FVU_Valor_UVT__c, FVU_UVT_Fecha_Inicial_Vigencia__c, FVU_UVT_Fecha_Final_Vigencia__c FROM FVU_UVT_info__c WHERE FVU_UVT_Fecha_Inicial_Vigencia__c < :currentTime AND FVU_UVT_Fecha_Final_Vigencia__c > :currentTime WITH USER_MODE LIMIT 1];
        if (!UVT.isEmpty() ){
            UVT_VIGENTE = (Decimal)UVT[0].get('FVU_Valor_UVT__c');
        }
        //Leer el valor del IVA a ser aplicado del objeto FVU_IVA_info__c
        Decimal TAX_IVA_PCNT = 0;
        List<FVU_IVA_info__c> ivaInfoList = [SELECT Id, Name, FVU_IVA_Tipo_de_equipo__c, FVU_IVA_Subtipo_de_equipo__c,FVU_Valor_IVA__c,FVU_IVA_Fecha_Inicial_Vigencia__c, FVU_IVA_Fecha_Final_Vigencia__c FROM FVU_IVA_info__c WHERE FVU_IVA_Fecha_Inicial_Vigencia__c < :currentTime AND FVU_IVA_Fecha_Final_Vigencia__c > :currentTime WITH USER_MODE];
        //Crear un Map con el subtipo de equipo como Key.
        Map<String,Decimal> ivaInfoMap = new Map<String,Decimal>();
        if (!ivaInfoList.isEmpty() ){
            for(FVU_IVA_info__c ivaInfo : ivaInfoList){
                ivaInfoMap.put(ivaInfo.FVU_IVA_Subtipo_de_equipo__c,ivaInfo.FVU_Valor_IVA__c);
            }
            System.debug('ivaInfoMap: ' + JSON.serialize(ivaInfoMap));
        }
        //Recorrer la lista de items en el carrito
        for (SObject cartItem : devicesItemList)
        {
            Boolean aplicaIVAItem = aplicaIVAOrden;
            //Get Line Item Id from the devicesItemList
            Id lineItemId = (Id)cartItem.get('Id');
            // Get the Product2Id from the itemList
            Id productId = (Id)cartItem.get('vlocity_cmt__Product2Id__c');
            //Obtener el atributo B2C-ATTR-TEC-SUP-CAT-PROD para los equipos de Tecnología y poder ver si es una patineta eléctrica
            //Obtener el límite de UVTs del producto, Tecnología: B2C-ATTR-TEC-LIMITE-UVT, Terminales: B2C-ATTR-EXC-IMP-TERM
            String prod2AttributesSelected = (String)cartItem.get('vlocity_cmt__AttributeSelectedValues__c');
            Map<String, Object> prod2AttributesSelectedMap = (Map<String, Object>)JSON.deserializeUntyped(prod2AttributesSelected);
            String prod2SubCatProd = '';
            Integer prodUVT = 0;

            SObject productInfo = (SObject)productsExtraInfoMap.get(productId);
            String prodFamily = (String)productInfo.get('Family');
            String prodType = (String)productInfo.get('vlocity_cmt__Type__c');
            String prodSubType = (String)productInfo.get('vlocity_cmt__SubType__c');
            String prodCode = (String)productInfo.get('ProductCode');
            if (prodFamily == 'Device' && prodType == 'Tech'){
                prod2SubCatProd = String.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TEC-SUP-CAT-PROD'));
                prodUVT = Integer.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TEC-LIMITE-UVT'));
            } else if(prodFamily == 'Device' && prodType == 'Handset'){
                prod2SubCatProd = String.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TIPO-TERM'));
                prodUVT = Integer.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-EXC-IMP-TERM'));
            } else if(prodType == 'Fee' && prodSubType == 'Cargo de Envío'){
                prodUVT = Integer.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-EXC-IMP-TERM'));
            } else if(prodType == 'SIM Card'){
                prodUVT = 0;
            }
            System.debug('--- prod2SubCatProd: ' + prod2SubCatProd);
            System.debug('--- prodUVT: ' + prodUVT);
            //Buscar el IVA que se debe aplicar al producto
            TAX_IVA_PCNT = ivaInfoMap.get(prod2SubCatProd);
            Decimal TOTAL_TAX = 0;
            if(TAX_IVA_PCNT == null){
                TAX_IVA_PCNT = ivaInfoMap.get('Defecto');
            }
            TOTAL_TAX = 1 + (TAX_IVA_PCNT/100);
            System.debug('--- TOTAL_TAX: ' + TOTAL_TAX);
            //Obtener el OT_STD_PRC para el OrderItem
            Map<String, Object> valuesMap = priceVarMap.get(lineItemId);
            System.debug('valuesMap: ' + JSON.serialize(valuesMap));
            if (valuesMap != null)
            {
                Map<String, Object> lineItemPricingVariableMap = (Map<String, Object>)valuesMap.get('PricingVariableValues');
                System.debug('lineItemPricingVariableMap: ' + JSON.serialize(lineItemPricingVariableMap));
                if (lineItemPricingVariableMap != null)
                {
                    Decimal OT_STD_PRC = (Decimal)lineItemPricingVariableMap.get('OT_STD_PRC');
                    System.debug('OT_STD_PRC: ' + OT_STD_PRC);
                    //Agregar IVA al OT_STD_PRC y almacenarlo como precio de venta
                    Decimal OT_STD_PRC_VENTA = OT_STD_PRC * TOTAL_TAX;
                    lineItemPricingVariableMap.put('OT_STD_PRC_VENTA', OT_STD_PRC_VENTA);
                    //Guardar OTC como precio BASE, BASE controla si se muestra o no se muestra la diferencia entre precio de venta y valor a pagar (precio tachado)
                    lineItemPricingVariableMap.put('BASE_OT_STD_PRC', OT_STD_PRC);
                    System.debug('lineItemPricingVariableMap: ' + JSON.serialize(lineItemPricingVariableMap));
                    //Escenario: Precio antes de descuentos es menor a límite de UVTs, no se calculan impuestos
                    if (OT_STD_PRC < (UVT_VIGENTE * prodUVT)){
                        System.debug('--- aplicaIVAItem: false, precio antes de descuentos es menor a límite de UVTs (' + UVT_VIGENTE * prodUVT + ')');
                        aplicaIVAItem = false;
                    }
                }
            }
            System.debug('additionalInfoItemsMap before: ' + JSON.serialize(additionalInfoItemsMap));
            additionalInfoItemsMap.put(lineItemId,new map<String, object>{'daneDptoCAVCode'=>daneDptoCAVCode,'serviceAccDptoCode'=>serviceAccDptoCode,'Product2Id'=>productId,'vlocity_cmt__AttributeSelectedValues__c'=>cartItem.get('vlocity_cmt__AttributeSelectedValues__c'),'ProductCode'=>prodCode,'Family'=>prodFamily,'vlocity_cmt__Type__c'=>prodType,'vlocity_cmt__SubType__c'=>prodSubType,'LineItemNumber'=>lineItemNumber,'IMPUESTO_DECIMAL'=>TOTAL_TAX,'UVT_VIGENTE'=>UVT_VIGENTE,'aplicaIVA'=>aplicaIVAItem});
            lineItemNumber += 1;
        }
        System.debug('additionalInfoItemsMap: ' + JSON.serialize(additionalInfoItemsMap));
        //Add the line item extra info map to the pricing context so it can be read in the pricing hook
        vlocity_cmt.PricingPlanService.putInPricingContext('CUSTOM_FIELDS_VALUES_MAP', additionalInfoItemsMap);
        //Get Main Governor Limits
        //Remover el comentario cuando se quieran realizar pruebas de desempeño
        /*
        System.debug('<<<<<< Class: ClaroCustomAddFieldsPricingPlanStepImpl');
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
}