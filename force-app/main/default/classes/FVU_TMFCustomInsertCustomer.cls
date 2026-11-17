/*------------------------------------------------------------
Author:         Gabriel Oros
Description:    Class to create and update custom portability cases
Test Class:     FVU_TMFCustomInsertCustomerTest
History
<Date>          <Author>        <Change Description>
22/12/23        Gabriel Oros 	Initial Version
------------------------------------------------------------*/
global without sharing class FVU_TMFCustomInsertCustomer implements vlocity_cmt.VlocityOpenInterface{
 
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        Boolean result = true;
        
        try {
            if(methodName.equals('insertAccountAndContactTMF')) {
                insertAccountAndContactTMF(inputMap, outMap, options);
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
    global static String idAccount = null;
    global static String idContact = null;
    global static String message = null;
    global static String status = null;



    public static void insertAccountAndContactTMF(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        
        try {
    
          Map<String, Object> fieldsJson = (Map<String, Object>) inputMap.get('jsonAll');
          String fieldsRequired = String.valueOf(inputMap.get('fieldsRequired'));
          List<String> fieldsRequiredList = fieldsRequired.split(',');
          System.debug('fieldsRequiredList: ' + fieldsRequiredList);
          
          Map<String, Object> addressInformation;

		  if (inputMap.containsKey('addressInformation') && inputMap.get('addressInformation') instanceof Map<String, Object>) {
              addressInformation = (Map<String, Object>) inputMap.get('addressInformation');
          } else {
			  addressInformation = new Map<String, Object>();
          }

            
          //Map<String, Object> addressInformation =  (Map<String, Object>) inputMap.get('addressInformation');
          Boolean checkFieldsRequired = checkRequiredFields(fieldsJson,addressInformation,fieldsRequiredList); 
          Map<String, Object> customerCharacteristicsMap = new Map<String, String>();
          if(checkFieldsRequired == false ) {
              status = 'Fail';
            
          }else{
    
           
            String documentType = (String) fieldsJson.get('documentType');
            String documentNumber = (String) fieldsJson.get('documentNumber');
            String action = (String) inputMap.get('action');
            //se valida si tiene una cuenta existente con el mismo numero de documento y tipo
            Boolean existAccount = validateExistAccount(documentType,documentNumber);
            if(existAccount == false){
          
            Object customerCharacteristicsObj = fieldsJson.get('customerCharacteristics');
            // Verificar que no sea nulo y convertirlo a una lista de objetos
            if (customerCharacteristicsObj != null) {
                List<Object> customerCharacteristicsList = (List<Object>) customerCharacteristicsObj;
                // Iterar sobre la lista y convertir cada objeto en un Map
                for (Object item : customerCharacteristicsList) {
                    Map<String, Object> characteristic = (Map<String, Object>) item;
                    String name = (String) characteristic.get('name');
                    Object value = (Object) characteristic.get('value');
            
                    if (name != null && value != null) {
                        customerCharacteristicsMap.put(name, value);
                    }
                }
                System.debug('Campos characteris: ' + customerCharacteristicsMap);
            }
            //query Metadata con la configuracion de los campos matchados para cada objeto.   
           List<FVU_TMFFieldsInsertCustomer__mdt> mdt = [SELECT FVU_Object__c, FVU_FieldsCustom__c, FVU_FieldsService__c FROM FVU_TMFFieldsInsertCustomer__mdt WHERE FVU_Action__c = :action WITH USER_MODE order by FVU_OrderExecution__c  asc];  
             
            for (FVU_TMFFieldsInsertCustomer__mdt recordMdt : mdt) {
                if(recordMdt.FVU_Object__c == 'Account'){
                    String fieldsServiceAcc = recordMdt.FVU_FieldsService__c;
                    String fieldsCustomAcc = recordMdt.FVU_FieldsCustom__c;
                    Map <String, String> matchedFieldsRecord = matchFieldsCustom(fieldsCustomAcc, fieldsServiceAcc); 
                    createAccount(matchedFieldsRecord,inputMap,fieldsJSON,outMap,customerCharacteristicsMap);
                }
                if(recordMdt.FVU_Object__c == 'Contact'){
                    String fieldsServiceContact = recordMdt.FVU_FieldsService__c;
                    String fieldsCustomContact = recordMdt.FVU_FieldsCustom__c;
                    Map <String, String> matchedFieldsRecord = matchFieldsCustom(fieldsCustomContact,fieldsServiceContact); 
                    createContact(idAccount,matchedFieldsRecord,inputMap,fieldsJSON,outMap,customerCharacteristicsMap);
                }
                message = 'Customer created';
             } 
            }else{
                message = 'Cuenta ya existente con ese numero de documento y tipo de documento';
                status = 'Fail';
            }

            }
            
            outMap.put('message', message);
            outMap.put('status', status);
            outMap.put('accountId', idAccount);
            outMap.put('contactId', idContact);
        } 
        catch (Exception e) {
            status = 'Failed';
            outMap.put('message', e.getMessage() + ' - Line -> ' + e.getLineNumber() + ' - Cause -> ' + e.getCause());
            outMap.put('status', status);
        }
    }
// Metodo para match de campos con el input con los valores de respuesta del metadata 
    public static Map<String, String>  matchFieldsCustom (String fieldsCustom, String fieldsService){
        List<String> listFieldsCustom = fieldsCustom.split(',');
        List<String> listFieldsService = fieldsService.split(',');
        Map<String, String> matchedFields = new Map<String, String>();
        if (listFieldsService.size() != listFieldsCustom.size()) {
            message = 'Error: Los campos tienen diferente cantidad de valores';
            status = 'Failed';
            System.debug('Error: Los campos tienen diferente cantidad de valores');
        } else {
            for (Integer i = 0; i < listFieldsService.size(); i++) {
                matchedFields.put(listFieldsService[i], listFieldsCustom[i]);
            }
            System.debug('Campos mapeados: ' + matchedFields);
    }
    return matchedFields;
}
// Metodo para validar si la account ya existe
    public static Boolean validateExistAccount(String documentType, String documentNumber){
        Integer countRecord = [SELECT COUNT() FROM Account WHERE FVU_DocumentType__c =:documentType and FVU_DocumentNumber__c=: documentNumber  WITH USER_MODE];
        if(countRecord > 0){
            return true;
        }
        return false;
    }
// Metodo para validar los campos requeridos
    public static Boolean checkRequiredFields(Map<String, Object> fieldsJson,Map<String, Object> addressInformation,List<String> fieldsRequired){
        List<String> requiredFields = fieldsRequired;
        List<String> missingFields = new List<String>();
        String origin = (String) fieldsJson.get('origin');
        String firstName = (String) fieldsJson.get('firstName');
        String lastName = (String) fieldsJson.get('lastName');
        String documentType = (String) fieldsJson.get('documentType');
        String documentNumber = (String) fieldsJson.get('documentNumber');
        
        for (String field : requiredFields) {
            String valueField = (String)fieldsJson.get(field);
            if (fieldsJson.get(field) == null || String.isBlank(valueField)) {
                String valueAddress = (String)addressInformation.get(field);
                if ((addressInformation.get(field) == null || String.isBlank(valueAddress)) && origin != 'whatsapp') {
                missingFields.add(field);
                }else if (origin == 'whatsapp' && (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(documentType) || String.isBlank(documentNumber))) {
                missingFields.add(field);
                }
            }
        }

        if (!missingFields.isEmpty()) {
            message = 'Error: Los siguientes campos son requeridos: ' + String.join(missingFields, ', ');
          System.debug('Los siguientes campos son requeridos y están vacíos: ' + String.join(missingFields, ', '));
            return false;
        }
        return true;
    
    }


// Metodo para insertar una cuenta
    private static void createAccount ( Map <String, String>  matchedFieldsRecord,Map<String, Object> inputMap,Map<String, Object> fieldsJSON, Map<String, Object> outMap,Map<String, Object> customerCharacteristicsMap){
        Account acc = new Account();
        String recordType = (String) inputMap.get('recordTypeAccount');
        String firstName = (String)fieldsJson.get('firstName');
        String lastName = (String) fieldsJson.get('lastName');
        String email = (String) fieldsJson.get('email');
        String documentType = (String) fieldsJSON.get('documentType');
        String documentNumber = (String) fieldsJSON.get('documentNumber');
        String origin = (String) fieldsJSON.get('origin');
        String fullName = firstName + ' ' + lastName; 
        if(customerCharacteristicsMap.get('FVU_SecondLastName__c') != null){
            fullName = fullName+' '+ String.valueOf(customerCharacteristicsMap.get('FVU_SecondLastName__c'));
        }
        for (String key : matchedFieldsRecord.keySet()) {
            String valueFieldName = matchedFieldsRecord.get(key);
            Schema.DescribeFieldResult fieldDescribe = acc.getSObjectType().getDescribe().fields.getMap().get(valueFieldName).getDescribe();
                if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	String dtValueWithLetterT = String.valueOf(customerCharacteristicsMap.get(key)); 
                    	String dtValueWithOutLetterT = dtValueWithLetterT.replace('T', ' '); //Remplazamos la "T" por un espacio en blanco en el DateTime para hacer posible la inserción.
                    	Datetime dtValue = DateTime.valueOf(dtValueWithOutLetterT);
                    	acc.put(valueFieldName, dtValue);
                    }
                }else if( fieldDescribe.getType() == Schema.DisplayType.Date){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	acc.put(valueFieldName, Date.valueOf((String)customerCharacteristicsMap.get(key)));
                    }
                }else if( fieldDescribe.getType() == Schema.DisplayType.BOOLEAN){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	acc.put(valueFieldName, (Boolean) customerCharacteristicsMap.get(key));
                    }
                }else{
                    //Agregamos por defecto el valor Correo Electrónico cuando el campo FVU_NotificationChoice__c es nulo HDU 702395
                    if(valueFieldName == 'FVU_NotificationChoice__c' && customerCharacteristicsMap.get(key) == null){ 
                        acc.put(valueFieldName, 'Correo electrónico');
                    }else{
                    acc.put(valueFieldName,(String)  customerCharacteristicsMap.get(key));
                    
                    }
                    
                }
            System.debug('Clave: ' + key + ' | Valor: ' + valueFieldName);
            System.debug('Account fields: ' + acc);
        }
            
           acc.put('Name', fullName);
           acc.put('FVU_DocumentType__c', documentType);
           acc.put('FVU_DocumentNumber__c', documentNumber);
           acc.put('AccountSource', origin);
           acc.put('FVU_Email__c', email);
           acc.put('RecordTypeId', recordType);
           Database.SaveResult saveResults = Database.insert(acc, false);
        if (!saveResults.isSuccess()) {
        	for (Database.Error error : saveResults.getErrors()) {
                message = error.getMessage();
                status = 'Failed';
            }
        }
        else{
            idAccount = saveResults.getId();
            status = 'Success';
        }


    }


    // metodo para crear el contact
    private static void createContact (String idAccount, Map <String, String>  matchedFieldsRecord,Map<String, Object> inputMap,Map<String, Object> fieldsJSON, Map<String, Object> outMap,Map<String, Object> customerCharacteristicsMap){
        Contact cont = new Contact();
        String recordType = (String) inputMap.get('recordTypeContact');
        String firstName = (String)fieldsJson.get('firstName');
        String lastName = (String) fieldsJson.get('lastName');
        String email = (String) fieldsJson.get('email');
        String documentType = (String) fieldsJSON.get('documentType');
        String expeditionDate = (String) fieldsJSON.get('documentExpeditionDate');
        String documentNumber = (String) fieldsJSON.get('documentNumber');
        System.debug('Account id: ' + idAccount);

        for (String key : matchedFieldsRecord.keySet()) {
            String valueFieldName = matchedFieldsRecord.get(key);
            System.debug('key: ' + key);
            System.debug('valueFieldName: ' + valueFieldName);

            Schema.DescribeFieldResult fieldDescribe = cont.getSObjectType().getDescribe().fields.getMap().get(valueFieldName).getDescribe();
                if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	Datetime dtValue = DateTime.valueOf((String) customerCharacteristicsMap.get(key));
                    	cont.put(valueFieldName, dtValue);
                    }
                }else if( fieldDescribe.getType() == Schema.DisplayType.Date){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	cont.put(valueFieldName, Date.valueOf((String)customerCharacteristicsMap.get(key)));
                        }
                }else if( fieldDescribe.getType() == Schema.DisplayType.BOOLEAN){
                    if(customerCharacteristicsMap.get(key)!= null){ //Validamos si no es null para evitar Exceptions de conversion
                    	cont.put(valueFieldName, (Boolean) customerCharacteristicsMap.get(key));
                    }
                }else{
                    cont.put(valueFieldName,(String)  customerCharacteristicsMap.get(key));
                }
            System.debug('Clave: ' + key + ' | Valor: ' + valueFieldName);
            System.debug('Contact fields: ' + cont);
        }
        cont.put('Email',email);
        cont.put('firstName', firstName);
        cont.put('lastName', lastName);
        cont.put('AccountId', idAccount);
        cont.put('FVU_DocumentType__c', documentType);
        cont.put('FVU_DocumentNumber__c', documentNumber);
        if(!String.isBlank(expeditionDate)){
            cont.put('FVU_ExpeditionDate__c', Date.valueOf(expeditionDate));
        }
        cont.put('RecordTypeId', recordType);
           Database.SaveResult saveResults = Database.insert(cont, false);
        if (!saveResults.isSuccess()) {

        	for (Database.Error error : saveResults.getErrors()) {
            	message = error.getMessage();
                status = 'Failed';
            }
        }
        else{
            Account acc = new Account();
            acc.id = idAccount;
            acc.vlocity_cmt__PrimaryContactId__c = saveResults.getId();
            Database.SaveResult updateResult = Database.update(acc, false);
            if (!updateResult.isSuccess()) {
                for (Database.Error error : updateResult.getErrors()) {
                message = error.getMessage();
                status = 'Failed';
                } 
          }else{
            idContact = saveResults.getId();
            status = 'Success';
          }
        }
    }
}