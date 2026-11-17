/*------------------------------------------------------------
Author:         Gabriel Oros
    Description:    Class to create and update custom portability cases
    Test Class:     FVU_TMFCreateOrderTest
    History
    <Date>          <Author>        <Change Description>
    22/12/23        Gabriel Oros 	Initial Version
    ------------------------------------------------------------*/
global without sharing class FVU_TMFCreateOrder implements vlocity_cmt.VlocityOpenInterface{
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('insertNewOrder')) {
                insertNewOrder(inputMap, outMap, options);
            }
        }
        catch(Exception e) {
            System.debug('invokeMethod -> exception: ' + e);
            System.debug('invokeMethod -> exception: ' + e.getLineNumber());
            result = false;
        }
        
        return result;
        
    }
    
    //Variable globales
    global static String idAccountBilling = null;
    global static String idOrder = null;
    global static String idOrderPayment = null;
    global static String idQuote = null;
    global static String idOpp = null;
    global static String message = null;
    global static String status = null;
    global static String code = null;
    global static Boolean isMigration = false;
    global static Boolean isHandsetAndTech = false;
    global static Boolean isActivation = false;
    global static Boolean isPortIn = false;
    global static Boolean isFin = false;
    
    
    
    
    public static void insertNewOrder(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        
        try {
            
            
            
            String action = String.valueOf(inputMap.get('action'));
            isMigration = action == 'ActivationAct_migracion_Pre_Pos';
            isHandsetAndTech = action == 'HandsetAndTech';
            isActivation = action == 'ActivationActivation';
            isPortIn = action == 'PortInPortIn';
            isFin = action == 'HandsetAndTechFIN';
            
            Boolean isFieldsDateCutAndCycle = isActivation || isHandsetAndTech || isMigration;
            
            // Campos de entrada al llamar a la clase
            String salesType = String.valueOf(inputMap.get('salesType'));
            String salesSubtype = String.valueOf(inputMap.get('salesSubtype'));
            String customerIdSF = String.valueOf(inputMap.get('customerIdSF'));
            String storeOrderId = String.valueOf(inputMap.get('storeOrderId'));
            String channel = String.valueOf(inputMap.get('channel'));
            Object orderCharacteristicObj = inputMap.get('orderCharacteristic');
            String recordTypeOrder = String.valueOf(inputMap.get('recordTypeOrder'));
            String externalAccount93 = (String) inputMap.get('externalAccount93');
            String externalAccount91 = (String) inputMap.get('externalAccount91');
            String externalAccount92 = String.valueOf(inputMap.get('externalAccount92'));
            String fieldsRequired = String.valueOf(inputMap.get('fieldsRequired'));
            String billingCycle = String.valueOf(inputMap.get('billingCycle'));
            String cutoffDetailsDate = String.valueOf(inputMap.get('cutoffDetailsDate'));
            
            String migraDataValue = null;
            String portInValue = null;
            String authorizedPersonDataValue = null;
            String portInFieldsOrderItemsValue = null;
            Map<String, Object> financingDetailsMap = new Map<String, Object>();
            
            
            if (inputMap.containsKey('migraData') && inputMap.get('migraData') != null && isMigration == true) {
                Map<String, Object> migraData = (Map<String, Object>) inputMap.get('migraData');
                List<Object> migraList = new List<Object>();
                migraList.add(migraData);
                migraDataValue = JSON.serialize(migraList);
                System.debug(migraDataValue);
            }
            if(inputMap.containsKey('financingDetails') && inputMap.get('financingDetails') != null && isFin == true){
                Object financingDetailsObj = inputMap.get('financingDetails');
                // Verificar que no sea nulo y convertirlo a una lista de objetos
                if (financingDetailsObj != null) {
                    List<Object> financingDetailsList = (List<Object>) financingDetailsObj;
                    // Iterar sobre la lista y convertir cada objeto en un Map
                    for (Object item : financingDetailsList) {
                        Map<String, Object> objectfinancingDetails = (Map<String, Object>) item;
                        String name = (String) objectfinancingDetails.get('name');
                        Object value = (Object) objectfinancingDetails.get('value');
                        System.debug('Campos finalcials value: ' + value);
                        System.debug('Campos finalcials name: ' + name);
                        if (name != null && value != null) {
                            financingDetailsMap.put(name, value);
                        }
                    }
                    System.debug('Campos financingDetailsMap: ' + financingDetailsMap);
                }
            }
            
            Map<String, Object> fieldsJson = new  Map<String, Object>();
            fieldsJson.put('customerIdSF',customerIdSF);
            fieldsJson.put('salesType',salesType);
            fieldsJson.put('salesSubtype',salesSubtype);
            fieldsJson.put('storeOrderId',storeOrderId);
            fieldsJson.put('channel',channel);
            fieldsJson.put('billingCycle',billingCycle);
            fieldsJson.put('cutoffDetailsDate',cutoffDetailsDate);
            fieldsJson.put('externalAccount93',externalAccount93);
            fieldsJson.put('externalAccount91',externalAccount91);
            fieldsJson.put('externalAccount92',externalAccount92);
            
            System.debug ('fieldsJson' + fieldsJson);
            
            
            Map<String, Object> orderCharacteristicMap = new Map<String, Object>();
            // Verificar que no sea nulo y convertirlo a una lista de objetos
            if (orderCharacteristicObj != null) {
                List<Object> orderCharacteristicList = (List<Object>) orderCharacteristicObj;
                // Iterar sobre la lista y convertir cada objeto en un Map
                for (Object item : orderCharacteristicList) {
                    Map<String, Object> characteristic = (Map<String, Object>) item;
                    String name = (String) characteristic.get('name');
                    Object value = (Object) characteristic.get('value');
                    System.debug('Campos value: ' + value);
                    System.debug('Campos name: ' + name);
                    if (name != null && value != null) {
                        orderCharacteristicMap.put(name, value);
                    }
                }
                System.debug('Campos orderCharacteristic: ' + orderCharacteristicMap);
            }
            System.debug('fieldsRequiredList ' + fieldsRequired);
            
            // BUG-756698 Para una orden Activacion con Cargo a la Factura no debe pedir el nodo de OrderPayment.
            System.debug('OrderChar ' + orderCharacteristicMap.get('FVU_PaymentType__c'));
            boolean isCargoAFactura = orderCharacteristicMap.get('FVU_PaymentType__c') == 'Cargo a la Factura';
            System.debug('isCargoAFactura ' + isCargoAFactura);
            System.debug('isActivation ' + isActivation);
            Boolean isValidOrderPayment = (isActivation && !isCargoAFactura)|| isHandsetAndTech;
            System.debug('isValidOrderPayment ' + isValidOrderPayment);

            Boolean checkFieldsRequired = checkRequiredFields(fieldsJson,orderCharacteristicMap,fieldsRequired,financingDetailsMap);
            
            List<Object> orderPaymentList = null;
            List<Object> productsList = (List<Object>) inputMap.get('products');
            List<Object> additionalServicesList  = new List<Object>();
            if (inputMap.containsKey('orderPayments') && inputMap.get('orderPayments') != '') {
                orderPaymentList = (List<Object>) inputMap.get('orderPayments');
            }
            
            if (inputMap.containsKey('additionalServices') && inputMap.get('additionalServices') != null) {
                // additionalServicesList = (List<Object>) inputMap.get('additionalServices');
                Object additionalServiceObj = inputMap.get('additionalServices');
                System.debug('additionalServiceObj' + additionalServiceObj);
                if (additionalServiceObj != null) {
                    if (additionalServiceObj instanceof List<Object>) {
                        additionalServicesList = (List<Object>)additionalServiceObj;
                    } else if (additionalServiceObj instanceof Map<String, Object>) {
                        additionalServicesList.add((Map<String, Object>)additionalServiceObj);
                    }
                }
                System.debug('additionalServicesList' + additionalServicesList);
                
            }
            
            Object deliveryDetailsList = (Object) inputMap.get('deliveryDetails');
            
            if ((orderPaymentList == null || orderPaymentList.isEmpty()) && isValidOrderPayment == true) {
                checkFieldsRequired = false;
                message = 'No hay objeto para la lista de orderPayment';
                status = 'Error';
                code = '400';
            }
            if (productsList == null || productsList.isEmpty()) {
                checkFieldsRequired = false;
                message = 'No hay objeto para la lista de productos';
                status = 'Error';
                code = '400';
            }
            if (inputMap.containsKey('authorizedPersonData')  && isPortIn == true && orderCharacteristicMap.get('vlocity_cmt__DeliveryMethod__c') == 'PickUp') {
                if(inputMap.get('authorizedPersonData') == null){
                    checkFieldsRequired = false;
                    message = 'Error en el Nodo AuthorizedPersonData';
                    status = 'Error';
                    code = '400';
                }
                Object authorizedPersonDataObject = (Object) inputMap.get('authorizedPersonData');
                authorizedPersonDataValue = JSON.serialize(authorizedPersonDataObject);
                System.debug('authorizedPersonDataValue'+authorizedPersonDataValue);
            }
            if (inputMap.containsKey('portIn')  && inputMap.containsKey('portInFieldsOrderItems') && isPortIn == true) {
                if(inputMap.get('portIn') == null || inputMap.get('portInFieldsOrderItems') == null){
                    checkFieldsRequired = false;
                    message = 'Error en el Nodo PortIn';
                    status = 'Error';
                    code = '400';
                }
                Object portInObject =  (Object) inputMap.get('portIn');
                Object portInFieldsOrderItemsObject =  (Object) inputMap.get('portInFieldsOrderItems');
                portInValue = JSON.serialize(portInObject);
                portInFieldsOrderItemsValue= JSON.serialize(portInFieldsOrderItemsObject);
                System.debug('portInValue'+portInValue);
                System.debug('portInFieldsOrderItemsValue212 '+ (String.isBlank(portInFieldsOrderItemsValue)));
            }
            
            if(checkFieldsRequired == true ) {
                Boolean existAccount = validateExistAccount(customerIdSF);
                if(existAccount == true){
                    //String action = salesType + salesSubtype;
                    List<FVU_TMFFieldsInsertCustomer__mdt> mdt = [SELECT FVU_Object__c,FVU_OrderExecution__c, FVU_FieldsCustom__c, FVU_FieldsService__c FROM FVU_TMFFieldsInsertCustomer__mdt WHERE FVU_Action__c = :action WITH USER_MODE order by FVU_OrderExecution__c  asc];
                    
                    
                    for (FVU_TMFFieldsInsertCustomer__mdt recordMdt : mdt) {
                        
                        if(Test.isRunningTest()){
                            if(inputMap.containsKey('testMdt')){
                                if(inputMap.get('testMdt') == null){
                                    recordMdt.FVU_FieldsService__c = null;
                                    recordMdt.FVU_FieldsCustom__c = null;
                                }
                                if(inputMap.get('testMdt') == 'diff'){
                                    recordMdt.FVU_FieldsService__c = (String)inputMap.get('fieldsServiceTest');
                                }
                            }
                        }
                        
                        if(recordMdt.FVU_Object__c == 'Order'){
                            
                            String fieldsServiceOrder = recordMdt.FVU_FieldsService__c;
                            String fieldsCustomOrder = recordMdt.FVU_FieldsCustom__c;
                            if(!String.isBlank(fieldsCustomOrder) && !String.isBlank (fieldsServiceOrder)){
                                Map <String, String> matchedFieldsRecord = matchFieldsCustom(fieldsCustomOrder, fieldsServiceOrder);
                                if (!matchedFieldsRecord.isEmpty() ) {
                                    
                                    createOrder(matchedFieldsRecord,recordTypeOrder,fieldsJson,outMap,orderCharacteristicMap,productsList,additionalServicesList,deliveryDetailsList,migraDataValue,authorizedPersonDataValue,portInValue,portInFieldsOrderItemsValue);
                                    if(isValidOrderPayment == true && idOrder != null){
                                        createOrderPayment(idOrder,orderPaymentList,outMap);
                                    }
                                    if((isMigration|| isActivation || isPortIn)  && idOrder != null){
                                        updateAccountBilling(idAccountBilling,externalAccount93,externalAccount91,billingCycle,cutoffDetailsDate);
                                        
                                    }else{
                                        
                                        if(idOrder != null && idOrderPayment != null){
                                            message = 'Order Created';
                                            code ='200';
                                        }
                                    }
                                }else{
                                    message = 'No se pudo hacer match de los campos';
                                    status = 'Error';
                                    code = '400';
                                }
                            }else{
                                message = 'Configure el metadata los campos fieldsService y fieldsCustom';
                                status = 'Error';
                                code = '400';
                                
                            }
                        }
                        if(recordMdt.FVU_Object__c == 'Quote' && isFin == true){
                            String fieldsServiceQuote = recordMdt.FVU_FieldsService__c;
                            String fieldsCustomQuote = recordMdt.FVU_FieldsCustom__c;
                            if(!String.isBlank(fieldsCustomQuote) && !String.isBlank (fieldsServiceQuote)){
                                Map <String, String> matchedFieldsRecordQuote = matchFieldsCustom(fieldsCustomQuote, fieldsServiceQuote);
                                if (!matchedFieldsRecordQuote.isEmpty()) {
                                    createOpportunity();
                                    if(idOpp != null){
                                        createQuote(matchedFieldsRecordQuote,financingDetailsMap, externalAccount93);
                                        if(idQuote == null){
                                            message = 'No se pudo crear la Quote';
                                            status = 'Error';
                                            code = '400';
                                        }
                                    }else{
                                        message = 'No se pudo crear la Opportunity';
                                        status = 'Error';
                                        code = '400';
                                    }
                                    
                                }else{
                                    message = 'No se pudo hacer match de los campos';
                                    status = 'Error';
                                    code = '400';
                                }
                            }else{
                                message = 'Configure el metadata los campos fieldsService y fieldsCustom';
                                status = 'Error';
                                code = '400';
                                
                            }
                        }
                    }
                    
                }else{
                    message = 'Cuenta no existe';
                    status = 'Error';
                    code = '400';
                    
                }
            }
            
            outMap.put('message', message);
            outMap.put('status', status);
            outMap.put('orderId', idOrder);
            outMap.put('orderPaymentId', idOrderPayment);
            outMap.put('quoteId', idQuote);
            outMap.put('code', code);
        }
        catch (Exception e) {
            status = 'Error';
            outMap.put('message', e.getMessage() + ' - Line -> ' + e.getLineNumber() + ' - Cause -> ' + e.getCause());
            outMap.put('status', status);
            outMap.put('code', '400');
            System.debug('Error::'+e.getMessage()+ ' - Line -> ' + e.getLineNumber());
        }
    }
    // Metodo para match de campos con el input con los valores de respuesta del metadata
    public static Map<String, String>  matchFieldsCustom (String fieldsCustom, String fieldsService){
        List<String> listFieldsCustom = fieldsCustom.split(',');
        List<String> listFieldsService = fieldsService.split(',');
        Map<String, String> matchedFields = new Map<String, String>();
        if (listFieldsService.size() != listFieldsCustom.size()) {
            message = 'Los campos tienen diferente cantidad de valores';
            status = 'Error';
            code = '400';
        } else {
            for (Integer i = 0; i < listFieldsService.size(); i++) {
                matchedFields.put(listFieldsService[i], listFieldsCustom[i]);
            }
            System.debug('Campos mapeados: ' + matchedFields);
        }
        return matchedFields;
    }
    // Metodo para validar si la account ya existe
    public static Boolean validateExistAccount(String customerIdSF){
        Integer countRecord = [SELECT COUNT() FROM Account WHERE Id =:customerIdSF   WITH USER_MODE];
        if(countRecord > 0){
            return true;
        }
        return false;
    }
    // Metodo para validar los campos requeridos
    public static Boolean checkRequiredFields(Map<String, Object> fieldsJson,Map<String, Object> orderCharacteristicMap,String fieldsRequired,Map<String,Object> financingDetailsMap){
        
        List<String> fieldsRequiredList = new List<String>();
        if(fieldsRequired == null ||  String.isBlank(fieldsRequired)){
            message = 'Configure los campos requeridos en el metadata';
            status = 'Error';
            code = '500';
            return false;
            
        }else {
            fieldsRequiredList = fieldsRequired.split(',');
            System.debug('fieldsRequiredString: ' + fieldsRequiredList);
        }
        List<String> missingFields = new List<String>();
        for (String field : fieldsRequiredList) {
            String valueField = (String)fieldsJson.get(field);
            if (fieldsJson.get(field) == null || String.isBlank(valueField)) {
                Object valueCharacteristicMap = (Object)orderCharacteristicMap.get(field);
                if (orderCharacteristicMap.get(field) == null || valueCharacteristicMap == null) {
                    Object valueFinancingDetailsMap = (Object)financingDetailsMap.get(field);
                    if(financingDetailsMap.get(field) == null || valueFinancingDetailsMap == null){
                        missingFields.add(field);
                    }
                }
            }
        }
        if (!missingFields.isEmpty()) {
            message = 'Error: Los siguientes campos son requeridos: ' + String.join(missingFields, ', ');
            code = '400';
            status = 'Error';
            System.debug('Los siguientes campos son requeridos y están vacíos: ' + String.join(missingFields, ', '));
            return false;
        }
        return true;
        
    }
    
    
    // Metodo para insertar una Order
    private static void createOrder ( Map <String, String>  matchedFieldsRecord,String recordTypeOrder,Map<String, Object> fieldsJson, Map<String, Object> outMap,Map<String, Object> orderCharacteristicMap,List<Object> productsList,List<Object> additionalServicesList,Object deliveryDetailsList,String migraDataValue,String authorizedPersonDataValue, String portInValue,String portInFieldsOrderItemsValue){
        Order order = new Order();
        
        if(Test.isRunningTest()){
            matchedFieldsRecord.put('startDate','EffectiveDate');
            matchedFieldsRecord.put('endDate','vlocity_cmt__RequestedStartDate__c');
            matchedFieldsRecord.put('totalAmount','vlocity_cmt__EffectiveBaseRecurringCharge__c');
            matchedFieldsRecord.put('createdByApi','vlocity_cmt__CreatedByAPI__c');
            
            orderCharacteristicMap.put('startDate','2024-04-27');
            orderCharacteristicMap.put('endDate','2024-04-27 15:30:00');
            orderCharacteristicMap.put('totalAmount','10.5');
            orderCharacteristicMap.put('createdByApi','false');
            
        }
        
        System.debug('matchedFieldsRecord: ' + matchedFieldsRecord);
        for (String key : matchedFieldsRecord.keySet()) {
            String valueFieldName = matchedFieldsRecord.get(key);
            
            Schema.DescribeFieldResult fieldDescribe = order.getSObjectType().getDescribe().fields.getMap().get(valueFieldName).getDescribe();
            if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                Datetime dtValue = null;
                //dtValue = parseDateTimeISO((String) orderCharacteristicMap.get(key));
                dtValue = Datetime.valueOf((String) orderCharacteristicMap.get(key));
                if(dtValue == null){
                    dtValue = Datetime.valueOf((String) fieldsJson.get(key));
                }
                order.put(valueFieldName, dtValue);
            }else if( fieldDescribe.getType() == Schema.DisplayType.Date){
                Date dtValue = null;
                dtValue = Date.valueOf((String) orderCharacteristicMap.get(key));
                if(dtValue == null){
                    dtValue = Date.valueOf((String) fieldsJson.get(key));
                }
                order.put(valueFieldName, dtValue);
            }else if( fieldDescribe.getType() == Schema.DisplayType.BOOLEAN){
                Object rawValueObj = orderCharacteristicMap.get(key);
                if (rawValueObj == null && fieldsJson.containsKey(key)) {
                    rawValueObj = fieldsJson.get(key);
                }
                
                Boolean boolValue;
                if (rawValueObj instanceof Boolean) {
                    boolValue = (Boolean) rawValueObj;
                } else if (rawValueObj instanceof String) {
                    boolValue = Boolean.valueOf((String) rawValueObj);
                } else {
                    boolValue = false; // Valor por defecto si no se puede determinar
                }
                
                order.put(valueFieldName, boolValue);
            }else if (fieldDescribe.getType() == Schema.DisplayType.Currency) {
                Decimal currencyValue = null;
                Object rawValue = orderCharacteristicMap.get(key);
                if (rawValue == null && fieldsJson.containsKey(key)) {
                    rawValue = fieldsJson.get(key);
                }
                if (rawValue != null) {
                    currencyValue = Decimal.valueOf(String.valueOf(rawValue));
                }
                order.put(valueFieldName, currencyValue);
                
            }else{
                String valueField = null;
                valueField = (String) orderCharacteristicMap.get(key);
                if(valueField == null){
                    valueField = (String) fieldsJson.get(key);
                }
                order.put(valueFieldName,valueField);
            }
            System.debug('Clave: ' + key + ' | Valor: ' + valueFieldName);
            System.debug('order fields: ' + order);
        }
        
        idAccountBilling = (String) order.get('vlocity_cmt__DefaultBillingAccountId__c');
        
        
        Pricebook2 pricebook = [SELECT Id, Name FROM Pricebook2 WHERE Name='Standard Price Book' WITH USER_MODE];
        vlocity_cmt__PriceList__c pricelist = [SELECT Id, Name, vlocity_cmt__Code__c FROM vlocity_cmt__PriceList__c WHERE vlocity_cmt__Code__c='PL-B2C' WITH USER_MODE];
        User currentUser = [SELECT Id, FVU_BusinessChannel__c, FVU_Canal__c, FVU_DANE_Punto_de_Venta__c, FVU_CiudadCAV__c, FVU_CAV__c, FVU_CodigoD__c,Name FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        
        String serializeProductsList = JSON.serialize(productsList);
        String serializeDeliveryDetailsList = JSON.serialize(deliveryDetailsList);
        order.put('FVU_DeliveryDetailsData__c',serializeDeliveryDetailsList);
        
        if(migraDataValue != null && isMigration == true){
            order.put('FVU_MigraData__c', migraDataValue);
            order.put('vlocity_cmt__DeliveryMethod__c','Immediatepickup');
        }
        order.put('RecordTypeId', recordTypeOrder);
        order.put('Status', 'Draft');
        order.put('EffectiveDate', Date.today());
        order.put('FVU_CustomerDataAuthorizationDate__c', Date.today());
        order.put('FVU_PaymentStatus__c', 'PP');
        if(pricebook!=null && pricebook.Id!=null){
            order.put('Pricebook2Id', pricebook.Id);
        }
        if(pricelist!=null && pricelist.Id!=null){
            order.put('vlocity_cmt__PriceListId__c', pricelist.Id);
        }
        if(idQuote != null){
            order.put('vlocity_cmt__QuoteId__c', idQuote);
        }
        order.put('FVU_OrderDeliveryStatus__c', 'Closed');
        //order.put('vlocity_cmt__OriginatingChannel__c', currentUser.FVU_BusinessChannel__c);
        order.put('FVU_BusinessChannel__c', currentUser.FVU_BusinessChannel__c);
        order.put('FVU_Channel__c', currentUser.FVU_Canal__c);
        order.put('FVU_DaneCiudadCAVOrden__c', currentUser.FVU_DANE_Punto_de_Venta__c);
        order.put('FVU_CiudadCAVOrden__c', currentUser.FVU_CiudadCAV__c);
        order.put('FVU_CodigoCAV__c', currentUser.FVU_CAV__c);
        order.put('FVU_CodigoD__c', currentUser.FVU_CodigoD__c);
        order.put('FVU_Short_Name__c', currentUser.Name);
        order.put('FVU_OriginalChannel__c',order.get('vlocity_cmt__OriginatingChannel__c'));
        
        order.put('FVU_ProductsData__c',serializeProductsList);
        
        if (additionalServicesList != null || !additionalServicesList.isEmpty()) {
            String serializeAdditionalServiceList = JSON.serialize(additionalServicesList);
            order.put('FVU_AdditionalServiceData__c',serializeAdditionalServiceList);
        }
        if(isPortIn==true){
            order.put('FVU_PortInData__c',portInValue);
            order.put('FVU_PortInFieldsOrderItems__c',portInFieldsOrderItemsValue);
            if(!String.isBlank(authorizedPersonDataValue)){
                order.put('FVU_DeliveryData__c', authorizedPersonDataValue);
            }
        }
        
        Database.SaveResult saveResults = Database.insert(order, false);
        if (!saveResults.isSuccess()) {
            for (Database.Error error : saveResults.getErrors()) {
                message = error.getMessage();
                status = 'Error';
                code = '400';
            }
        }
        else{
            idOrder = saveResults.getId();
            status = 'Success';
            code = '200';
        }
        
        
    }
    
    
    // metodo para crear orderPayment
    private static void createOrderPayment (String idOrder, List<Object> orderPaymentList, Map<String, Object> outMap){
        vlocity_cmt__OrderPayment__c orderPayment = new vlocity_cmt__OrderPayment__c();
        
        List<vlocity_cmt__OrderPayment__c> paymentsToInsert = new List<vlocity_cmt__OrderPayment__c>();
        
        if (orderPaymentList != null && !orderPaymentList.isEmpty()) {
            
            for (Object orderPay : orderPaymentList) {
                Map<String, Object> paymentMap = (Map<String, Object>) orderPay;
                String dateService  = (String) paymentMap.get('orderPaymentDate');
                Datetime fechaDatetime = parseDateTimeISO(dateService);
                orderPayment.Name = (String) paymentMap.get('orderPaymentNumber');
                orderPayment.vlocity_cmt__PaymentAmount__c =(Decimal) paymentMap.get('orderPaymentAmount');
                orderPayment.FVU_PaymentMethod__c = (String) paymentMap.get('orderPaymentMethod');
                orderPayment.FVU_PaymentTxDate__c = fechaDatetime;
                orderPayment.vlocity_cmt__OrderId__c = idOrder;
                
                paymentsToInsert.add(orderPayment);
            }
            
        } else {
            System.debug('La lista orderPayment está vacía o es null');
        }
        List<Database.SaveResult> saveResults = Database.insert(paymentsToInsert, false);
        for (Database.SaveResult result : saveResults) {
            
            if (!result.isSuccess()) {
                
                for (Database.Error error : result.getErrors()) {
                    message = error.getMessage();
                    status = 'Error';
                    code = '400';
                }
            }
            else{
                idOrderPayment = result.getId();
                status = 'Success';
                
            }
        }
    }
    // metodo para crear orderPayment
    private static void updateAccountBilling (String idAccountBilling, String externalAccount93, String externalAccount91, String billingCycle, String cutoffDetailsDate){
        Account acc = new Account();
        
        if (!String.isBlank(externalAccount93) && !String.isBlank(externalAccount91)) {
            acc.FVU_AccountExternalID__c = externalAccount93;
            acc.OM_BSCSID__c = externalAccount91;
        }
        if ( !String.isBlank(billingCycle)){
            acc.vlocity_cmt__BillCycle__c = billingCycle;
        }
        if (!String.isBlank(cutoffDetailsDate)) {
            acc.FVU_CutoffDetailsDate__c = cutoffDetailsDate;
        }
        acc.Id = idAccountBilling;
        Database.UpsertResult saveResults = Database.upsert(acc, false);
        
        if (!saveResults.isSuccess()) {
            for (Database.Error error : saveResults.getErrors()) {
                message = 'Fail Update AccounBilling' + error.getMessage();
                status = 'Error';
                code = '400';
            }
        }
        else{
            message = 'Order Created';
            status = 'Success';
            code ='200';
        }
    }
    // metodo para crear opportunity
    private static void createOpportunity (){
        Opportunity opp = new Opportunity();
        
        opp.Name= 'Opportunity FIN Ecommerce';
        opp.CloseDate = Date.today();
        opp.StageName = 'Diseño de la Oferta';
        
        Database.SaveResult saveResults = Database.insert(opp, false);
        
        if (!saveResults.isSuccess()) {
            for (Database.Error error : saveResults.getErrors()) {
                message = 'Fail Create Opportunity ' + error.getMessage();
                status = 'Error';
                code = '400';
            }
        }else{
            idOpp = saveResults.getId();
        }
    }
    // metodo para crear Quote
    private static void createQuote (Map<String,String> matchedFieldsRecordQuote,Map<String,Object> financingDetailsMap, String externalAccount93 ){
        Quote quote = new Quote();
        
        for (String key : matchedFieldsRecordQuote.keySet()) {
            String valueFieldName = matchedFieldsRecordQuote.get(key);
            
            Schema.DescribeFieldResult fieldDescribe = quote.getSObjectType().getDescribe().fields.getMap().get(valueFieldName).getDescribe();
            if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                Datetime dtValue = null;
                dtValue = Datetime.valueOf((String) financingDetailsMap.get(key));
                quote.put(valueFieldName, dtValue);
            }else if( fieldDescribe.getType() == Schema.DisplayType.Date){
                Date dtValue = null;
                dtValue = Date.valueOf((String) financingDetailsMap.get(key));
                quote.put(valueFieldName, dtValue);
            }else if( fieldDescribe.getType() == Schema.DisplayType.BOOLEAN){
                Object rawValueObj = financingDetailsMap.get(key);
                Boolean boolValue;
                if (rawValueObj instanceof Boolean) {
                    boolValue = (Boolean) rawValueObj;
                } else if (rawValueObj instanceof String) {
                    boolValue = Boolean.valueOf((String) rawValueObj);
                } else {
                    boolValue = false; // Valor por defecto si no se puede determinar
                }
                
                quote.put(valueFieldName, boolValue);
            }else if (fieldDescribe.getType() == Schema.DisplayType.Currency) {
                Decimal currencyValue = null;
                Object rawValue = financingDetailsMap.get(key);
                if (rawValue != null) {
                    currencyValue = Decimal.valueOf(String.valueOf(rawValue));
                }
                quote.put(valueFieldName, currencyValue);
                
            }else if (fieldDescribe.getType() == Schema.DisplayType.DOUBLE) {
                Object rawValue = financingDetailsMap.get(key);
                
                if (rawValue != null ) {
                    Double integerValue = Double.valueOf(String.valueOf(rawValue));
                    quote.put(valueFieldName, integerValue);
                }
            }else if (fieldDescribe.getType() == Schema.DisplayType.PERCENT) {
                Object rawValue = financingDetailsMap.get(key);
                if (rawValue != null) {
                    Double value = Double.valueOf(String.valueOf(rawValue));
                    quote.put(valueFieldName, value);
                }
                
            }else{
                String valueField = null;
                valueField = (String) financingDetailsMap.get(key);
                quote.put(valueFieldName,valueField);
            }
            System.debug('ClaveQuote: ' + key + ' | ValorQuote: ' + valueFieldName);
            System.debug('quote fields: ' + quote);
        }
        
        quote.Name= 'Quote FIN Ecommerce';
        quote.Status = 'Approved';
        quote.OpportunityId = idOpp;
        quote.FIN_AccountExternalID__c=externalAccount93;
        
        Database.SaveResult saveResults = Database.insert(quote, false);
        
        if (!saveResults.isSuccess()) {
            for (Database.Error error : saveResults.getErrors()) {
                message = 'Fail Create Quote ' + error.getMessage();
                status = 'Error';
                code = '400';
            }
        }else{
            idQuote = saveResults.getId();
        }
    }
    
    
    public static DateTime parseDateTimeISO(String dateTimeStr) {
        if (String.isBlank(dateTimeStr)) {
            return null;
        }
        
        try {
            if (dateTimeStr.endsWith('Z')) {
                dateTimeStr = dateTimeStr.replace('Z', '');
            }
            return DateTime.valueOf(dateTimeStr);
        } catch (Exception e) {
            System.debug('Error al convertir fecha: ' + dateTimeStr + ' -> ' + e.getMessage());
            return null;
        }
    }
}