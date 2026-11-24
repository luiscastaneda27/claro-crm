/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class to create and update custom portability cases
Test Class:     PVU_TMFCustomCaseTest
History
<Date>          <Author>        <Change Description>
                Luis Mendoza    Initial Version
22/12/23        Silvia Tovar    Validation update and response
29/12/24        Federico Mandri Adding AssetId reference and account owner id reference to the case
07/03/24        Luis Mendoza    Adding method to get Case
11/06/24        Luis Mendoza    Update controll fields picklist in method "updateRecordDynamic"
28/02/25        Luis Mendoza    HU 519039: change for add method validete required field custom.
19/06/25        Mariana Olay    BUG-613839: El sistema crea caso de ajuste de crédito proveniente de ADA cuando el serial del equipo financiado no es coincidente.
22/07/25        Hugo Revuelta BUG-637933: Asigna el caso a la queue 'FIN_BackAjustesFinanciacion' en lugar de owner. Method: manageCaseByFinancingCode
13/09/2025      Héctor Machuca  HU-640623: Se agrega el campo Cuota inicial para la información de la orden.
------------------------------------------------------------*/
global with sharing class PVU_TMFCustomCase implements vlocity_cmt.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {

        Boolean result = true;

        try {
            if(methodName.equals('insertCaseTMF')) {
                insertCaseTMF(inputMap, outMap, options);
            }
            if(methodName.equals('updateRecordDynamic')) {
                updateRecordDynamic(inputMap, outMap, options);
            }
            if(methodName.equals('getCaseDynamic')) {
                getCaseDynamic(inputMap, outMap, options);
            }
        }
        catch(Exception e) {System.debug('invokeMethod -> exception: ' + e);System.debug('invokeMethod -> exception: ' + e.getLineNumber());result = false;}

        return result;

    }

    /*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class to create and update custom portability cases
Test Class:     PVU_TMFCustomCaseTest
History
<Date>          <Author>        <Change Description>
                Luis Mendoza    Initial Version
29/12/24        Federico Mandri HU 656412: Changing the object on which query is executed from Contact to Account 
                                to fetch account assets and match the correct mobile plan based on subscriberNumber
28/02/25        Luis Mendoza    HU 519039: change for add method validete required field custom. 
03/09/25        Ezequiel Olivera    HU 633743: change for add method validete required field custom. 

------------------------------------------------------------*/
    public static void insertCaseTMF(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        try {

            String typeMatchCM = (String) inputMap.get('customerVoice');
            String status = (String) inputMap.get('status');
            String description = (String) inputMap.get('description');
            String category = (String) inputMap.get('category');
            String subcategory = (String) inputMap.get('subcategory');
            String priority = (String) inputMap.get('priority');
            String documentType = (String) inputMap.get('documentType');
            String documentNumber = (String) inputMap.get('documentNumber');
            String recordType = (String) inputMap.get('type');
            String financingCode = (String) inputMap.get('financingCode');
            //20240301 - FM - HU 656412: se corrije error de tipeo en parametro subscriberNumber que viene desde el IP
            String subscriberNumber = (String) inputMap.get('subscriberNumber');
            Map<String,Object> channel = (Map<String,Object>) inputMap.get('channel');

            List<Object> fieldsObject =  (List<Object>) inputMap.get('troubleTicketCharacteristic');
            List<Map<String,Object>> fieldsJSON = new List<Map<String,Object>>();

            for (Object instance : fieldsObject) {
                fieldsJSON.add((Map<String,Object>) instance);
            }

            //Query to get fields to insert
            PVU_TMFFieldsInsertCase__mdt cst = [SELECT type__c, field_custom__c, squad__c, PVU_Required__c FROM
                                                PVU_TMFFieldsInsertCase__mdt WHERE type__c = :typeMatchCM WITH USER_MODE];

            String fieldsCustom = cst.field_custom__c;
            List<String> fieldsCustoms = fieldsCustom.split(',');

            String channelValue=channel!=null?(String) channel.get('name'):null;
            String requiredFieldString;

            //Valida campos requeridos para los origenes de canales digitales, se diferencia para no afectar procesos existentes que se reutilizaron
            if(channelValue!=null  && (channelValue.equalsIgnoreCase('SuperApp')||channelValue.equalsIgnoreCase('WhatsApp'))||channelValue.equalsIgnoreCase('IVR')){
                requiredFieldString = getRequiredData( cst.PVU_Required__c,  fieldsJSON);
            }


            if(!String.isBlank(requiredFieldString)){
                requiredFieldString = requiredFieldString.removeEnd(', ');
                outMap.put('message', 'Fields -- ' + requiredFieldString + ' requireds');
                outMap.put('status', 'Failed');
                outMap.put('code', '409');
                outMap.remove('errorCode');
                outMap.remove('error');
                return;
            }

            Case cas = new Case();
            //Dinamyc fields
            for ( String fieldName : fieldsCustoms) {
                for (Map<String,Object> fieldJSON : fieldsJSON) {
                    if(fieldName.contains( (String) fieldJSON.get('name'))){
                        Schema.DescribeFieldResult fieldDescribe = cas.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
                        if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                            Datetime dtValue = DateTime.valueOf((String) fieldJSON.get('value'));
                            cas.put(fieldName, dtValue);
                        }else if( fieldDescribe.getType() == Schema.DisplayType.Date){
                            // cas.put(fieldName, (Date) fieldJSON.get('value'));
                            cas.put(fieldName, Date.valueOf((String) fieldJSON.get('value'))); 
                        }else if( fieldDescribe.getType() == Schema.DisplayType.Boolean){
                            cas.put(fieldName, (Boolean) fieldJSON.get('value'));
                        }else{
                            cas.put(fieldName, (String) fieldJSON.get('value'));
                        }
                    }
                }
            }

            // HU 633743 - Validate and set FIN_MotivoAjuste__c
            Boolean motivoAjusteNodeFound = false;

            for (Map<String,Object> fieldJSON : fieldsJSON) {
                if('FIN_MotivoAjuste__c'.equals((String) fieldJSON.get('name'))) {
                    motivoAjusteNodeFound = true;
                    String motivoApiValue = (String) fieldJSON.get('value');

                    // Describe picklist to map API values with Labels
                    Schema.DescribeFieldResult fieldDescribe = Case.FIN_MotivoAjuste__c.getDescribe();
                    List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                    Boolean isValidValue = false;

                    for(Schema.PicklistEntry entry : picklistValues){
                        if(entry.getValue().equals(motivoApiValue)){
                            cas.FIN_MotivoAjuste__c = entry.getValue(); // Save label into Case field
                            isValidValue = true;
                            break;
                        }
                    }

                    // If the value is not valid, return error
                    if(!isValidValue){
                        outMap.put('message', 'El valor del campo “Motivo de Ajuste” no coincide con los valores permitidos por el sistema.Favor de verificar e intenta nuevamente.');
                        outMap.put('status', 'Failed');
                        outMap.put('code', '409');
                        outMap.remove('errorCode');
                        outMap.remove('error');
                        return;
                    }
                }
             }

            // New validation: mandatory when typeMatchCM = 'Ajuste de Credito'
            if('Ajuste de Credito'.equalsIgnoreCase(typeMatchCM) && !motivoAjusteNodeFound){
                outMap.put('message', 'El campo “Motivo de Ajuste” es obligatorio. Favor de verificar e intenta nuevamente.');
                outMap.put('status', 'Failed');
                outMap.put('code', '409');
                outMap.remove('errorCode');
                outMap.remove('error');
                return;
            }
            
            //20240305 - FM - Se consideran dos escenarios diferentes: PortOut viene solamente subscriberNumber,
            //otras gestiones tipo y numero de documento
            //Nuevo escenario: Financiacion, filtramos los assets por numero de credito.
            if(String.isNotBlank(documentType) && String.isNotBlank(documentNumber)){
                if(String.isNotBlank(financingCode)){
                    manageCaseByFinancingCode(cas, inputMap, outMap);
                } else{
                    manageCaseByClient(cas, inputMap, outMap);
                }
            }

            //20240305 - FM: Subscriber number for portability
            else if(String.isNotBlank(subscriberNumber)){
                manageCaseBySubscriberNumber(cas, inputMap, outMap);
            }
            else{
                outMap.put('message', 'SubscriberNumber is required for Portability');
                outMap.put('status', 'Failed');
                outMap.put('code', '409');
            }

            outMap.remove('errorCode');
            outMap.remove('error');
        }
        catch (Exception e) {
            outMap.put('message', e.getMessage() + ' - Line -> ' + e.getLineNumber() + ' - Cause -> ' + e.getCause());
            outMap.put('status', 'Failed');
            outMap.put('code', '409');

            outMap.remove('errorCode');
            outMap.remove('error');

            System.debug('Line: ' + e.getLineNumber());
            System.debug('Error: ' + e.getMessage());
        }
    }

    /*------------------------------------------------------------
    Author:         Luis Mendoza
    Company:        Salesforce.com
    Description:    Method to Update Case
    History
    <Date>          <Author>        <Change Description>
                    Luis Mendoza    Initial Version
    22/12/23        Silvia Tovar    Validation update and response
    11/03/24        Luis Mendoza    Update query fields required
    11/06/24        Luis Mendoza    Update controll fields
    ------------------------------------------------------------*/
    public static void updateRecordDynamic(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Map<String,Object> jsondata = (Map<String,Object>) inputMap.get('datosjson');
        String objectName = (String) jsondata.get('sObjectName');
        String recordId = (String) jsondata.get('recordId');
        String status = (String) jsondata.get('status');
        String substate = (String) jsondata.get('substate');
        String closingCode = (String) jsondata.get('closingCode');
        String fieldsrequired = (String) jsondata.get('fieldsrequired');
        List<Object> fieldsObject = new List<Object>();
        if (jsondata.get('troubleTicketCharacteristic') != '') {
           fieldsObject = (List<Object>) jsondata.get('troubleTicketCharacteristic');
        }
        List<Object> whereObject =  (List<Object>) jsondata.get('wheredata');
        List<Map<String,Object>> fields = new List<Map<String,Object>>();
        List<Map<String,Object>> whereFields = new List<Map<String,Object>>();

        try {


            //Dinamyc fields
            for (Object instance : fieldsObject) {
                fields.add((Map<String,Object>) instance);
            }

            //Dynamic field where
            for (Object instance : whereObject) {
                whereFields.add((Map<String,Object>) instance);
            }

            String query = 'SELECT ';

            // fields required
            query += fieldsrequired + ', ';

            // fields troubleTicketCharacteristic
            if (!fields.isEmpty()) {

                for (Map<String,Object> fieldData : fields) {
                    query += fieldData.get('name') + ', ';
                }
            }

            query = query.removeEnd(', ');

            //Where dynamic
            String wheres = '';
            for (Map<String,Object> whereField : whereFields) {
                if (whereField.get('field') != null && whereField.get('value') != null) {
                    wheres += whereField.get('field') +  '= \'' +  String.escapeSingleQuotes( (String) whereField.get('value')) + '\' ' + whereField.get('operater') + ' ';  
                }
            }

            if(wheres.endsWith('AND ')){
                wheres = wheres.removeEnd('AND ');
            }else if(wheres.endsWith('OR ')){
                wheres = wheres.removeEnd('OR ');
            }

            query += ' FROM ' + objectName + ' WHERE ' + wheres;

            SObject[] recordsObject = Database.query(query);

            if (recordsObject.isEmpty()) {

                outMap.put('message', 'Case not found');
                outMap.put('status',  'Failed');
                outMap.put('code',  '500');

            }else{

                Case cas = new Case();
                cas.Id = recordsObject[0].Id;
                cas.PVU_Level3__c = (String) recordsObject[0].get('PVU_Level3__c' );

                //Add controll field code
                List<PVU_Controller_Field_Dependencis__mdt> dependenListValueStatus = [SELECT Id,PVU_Controlling_Field_Value__c,PVU_Dependent_Field_Value__c
                                                                                        FROM PVU_Controller_Field_Dependencis__mdt
                                                                                        WHERE PVU_Controlling_Field_Value__c =:status WITH USER_MODE];

                Boolean isDependendStatus = true;
                for (PVU_Controller_Field_Dependencis__mdt dependendStatus : dependenListValueStatus) {
                    if(dependendStatus.PVU_Dependent_Field_Value__c == substate){
                        isDependendStatus = false;
                    }
                }

                if(isDependendStatus){

                    outMap.put('message', 'Combinación de matriz de tipificación invalida. Revise la combinación e intente nuevamente');
                    outMap.put('status',  'Failed');
                    outMap.put('code',  '500');

                }else{

                    List<PVU_Controller_Field_Dependencis__mdt> dependenListValueSubStatus = [SELECT Id,PVU_Controlling_Field_Value__c,PVU_Dependent_Field_Value__c
                    FROM PVU_Controller_Field_Dependencis__mdt
                    WHERE PVU_Controlling_Field_Value__c =:substate WITH USER_MODE];

                    Boolean isDependendSubStatus = true;
                    for (PVU_Controller_Field_Dependencis__mdt dependendSubStatus : dependenListValueSubStatus) {
                        if((dependendSubStatus.PVU_Dependent_Field_Value__c == null && closingCode.equals('') )||(dependendSubStatus.PVU_Dependent_Field_Value__c == closingCode)){
                        //if(dependendSubStatus.PVU_Dependent_Field_Value__c == closingCode){
                            isDependendSubStatus = false;
                        }
                    }

                    if(isDependendSubStatus){
                        outMap.put('message', 'Combinación de matriz de tipificación invalida. Revise la combinación e intente nuevamente');
                        outMap.put('status',  'Failed');
                        outMap.put('code',  '500');        
                    }else{

                        for (Map<String,Object> fieldUpdate : fields) {

                            Schema.DescribeFieldResult fieldDescribe = cas.getSObjectType().getDescribe().fields.getMap().get((String)fieldUpdate.get('name')).getDescribe();

                            if( fieldDescribe.getType() == Schema.DisplayType.DATETIME){
                                Datetime dtValue = DateTime.valueOf((String) fieldUpdate.get('value'));
                                cas.put((String)fieldUpdate.get('name'), dtValue);
                            }else{
                                cas.put((String)fieldUpdate.get('name'), (String) fieldUpdate.get('value'));
                            }
                        }
                        cas.Status = status;
                        cas.PVU_Sub_Estado__c= substate;
                        cas.PVU_Codigo_de_Cierre__c = closingCode;
                        cas.PVU_Fecha_Reversion__c = System.Today();
                        
                        if (cas.PVU_Level3__c == 'Reverso de pago' && String.isNotEmpty(cas.Respuesta__c)) {
                            if (cas.Respuesta__c == 'Rechazado') {
                                cas.Status = 'En curso';
                                cas.PVU_Sub_Estado__c = 'Caja cerrada';
                            } else if (cas.Respuesta__c == 'Aprobado') {
                                cas.Status = 'Cerrado';
                                cas.PVU_Codigo_de_Cierre__c = 'Se realiza reverso de pago';
                                cas.PVU_Sub_Estado__c = '-';
                            }
                        }
                        Database.SaveResult saveResults = Database.update(cas, false);

                        // Process the results
                        if (!saveResults.isSuccess()) {
                            for (Database.Error error : saveResults.getErrors()) {
                                outMap.put('message', error.getMessage());
                                outMap.put('status',  'Failed');
                                outMap.put('code',  error.getStatusCode());

                                // Handle errors as needed
                                System.debug('Error message: ' + error.getMessage());
                                System.debug('Status code: ' + error.getStatusCode());
                            }
                        }else {
                            Case casquery = [SELECT Id, CaseNumber, ContactId, AccountId, AssetId, ProductId, RecordTypeId,  Type, Status, 
                                            Reason , Origin, Subject, Priority, Description, IsClosed, ClosedDate, OwnerId, 
                                            CreatedDate, CreatedById, LastModifiedDate, LastModifiedById  FROM Case 
                                            WHERE Id = :saveResults.id WITH USER_MODE LIMIT 1];

                            Map<String,Object> attributes = new Map<String,Object>();
                            attributes.put('type', 'Case');
                            attributes.put('href', '/services/data/v57.0/sobjects/Case/'+saveResults.id);
                            outMap.put('LastModifiedById', casquery.LastModifiedById);
                            outMap.put('LastModifiedDate', casquery.LastModifiedDate);
                            outMap.put('CreatedById', casquery.CreatedById);
                            outMap.put('CreatedDate', casquery.CreatedDate);
                            outMap.put('OwnerId', casquery.OwnerId);
                            outMap.put('ClosedDate', casquery.ClosedDate);
                            outMap.put('IsClosed', casquery.IsClosed);
                            outMap.put('Description', casquery.Description);
                            outMap.put('Priority', casquery.Priority);
                            outMap.put('Subject', casquery.Subject);
                            outMap.put('Origin', casquery.Origin);
                            outMap.put('Reason', casquery.Reason);
                            outMap.put('Status', casquery.Status);
                            outMap.put('RecordTypeId', casquery.RecordTypeId);
                            outMap.put('Type', casquery.Type);
                            outMap.put('ProductId', casquery.ProductId);
                            outMap.put('AssetId', casquery.AssetId);
                            outMap.put('AccountId', casquery.AccountId);
                            outMap.put('AccountId', casquery.AccountId);
                            outMap.put('ContactId', casquery.ContactId);
                            outMap.put('CaseNumber', casquery.CaseNumber);
                            outMap.put('Id', saveResults.id);
                            outMap.put('attributes', attributes);
                            outMap.put('message', 'Case updated');
                            outMap.put('status', 'Success');
                            outMap.put('code', '200');
                        }

                    }

                }

            }
            outMap.remove('errorCode');
            outMap.remove('error');

            // outMap.put('result DML', cas);

        } catch (Exception e) {
            System.debug('Error updating record: ' + e.getMessage());
            System.debug('Line: ' + e.getLineNumber());
            outMap.put('message', e.getMessage() + ' Line: ' + e.getLineNumber());
            outMap.put('status',  'Failed');
            outMap.put('code',  '500');
        }
    }

    private static void insertCase(Case caso, Map<String, Object> outMap){
        Database.SaveResult saveResults = Database.insert(caso, false);
        // Process the results
        if (!saveResults.isSuccess()) {
            for (Database.Error error : saveResults.getErrors()) {
                outMap.put('message', error.getMessage());
                outMap.put('status',  'Failed');
                outMap.put('code',  error.getStatusCode());
                // Handle errors as needed
                System.debug('Error message: ' + error.getMessage());
                System.debug('Status code: ' + error.getStatusCode());
            }
        }
        else{
            Case casquery = [SELECT Id, CaseNumber, ContactId, AccountId  FROM Case WHERE Id = :saveResults.id 
                            WITH USER_MODE LIMIT 1];  

            Map<String,Object> attributes = new Map<String,Object>();
            attributes.put('type', 'Case');
            attributes.put('href', '/services/data/v57.0/sobjects/Case/'+saveResults.id);
            attributes.put('Id', casquery.CaseNumber);
            outMap.put('attributes', attributes);
            outMap.put('message', 'Case created');
            outMap.put('status', 'Success');
            outMap.put('code', '200');
        }
    }

    @TestVisible
    // HU 811299 - Canales digitales: el owner del caso debe ser el usuario de integración (contexto de ejecución).
    // La lista se parametriza en el CMT ApplicationSetting__mdt.PVU_CanalesDigitales__c (registro GeneralConfiguration),
    // separada por ';'. El CMT es la única fuente de verdad; si viene vacío, ningún canal se trata como digital.
    // Cache de los canales digitales (en minúsculas) resueltos desde el CMT.
    private static Set<String> digitalChannelsCache;

    // HU 811299 - Devuelve el set de canales digitales (minúsculas) desde el CMT.
    @TestVisible
    private static Set<String> getDigitalChannels(){
        if(digitalChannelsCache != null){
            return digitalChannelsCache;
        }
        Set<String> result = new Set<String>();
        ApplicationSetting__mdt setting = ApplicationSetting__mdt.getInstance('GeneralConfiguration');
        if(setting != null && String.isNotBlank(setting.PVU_CanalesDigitales__c)){
            for(String canal : setting.PVU_CanalesDigitales__c.split(';')){
                if(String.isNotBlank(canal)){
                    result.add(canal.trim().toLowerCase());
                }
            }
        }
        digitalChannelsCache = result;
        return digitalChannelsCache;
    }

    // HU 811299 - Devuelve true si el canal recibido corresponde a un canal digital.
    @TestVisible
    private static Boolean isDigitalChannel(Map<String,Object> channel){
        if(channel == null){ return false; }
        String channelName = (String) channel.get('name');
        if(String.isBlank(channelName)){ return false; }
        return getDigitalChannels().contains(channelName.trim().toLowerCase());
    }

    // HU 811299 - Resuelve de forma centralizada el OwnerId del Caso para los tres escenarios de creación
    // (manageCaseByClient, manageCaseBySubscriberNumber, manageCaseByFinancingCode), garantizando el mismo
    // comportamiento sin importar por qué método enrute insertCaseTMF. Orden de prioridad:
    //   1) Canal digital              => usuario de integración (contexto de ejecución).
    //   2) Escenario financiación     => cola FIN_BackAjustesFinanciacion.
    //   3) Owner de la cuenta ACTIVO  => owner de la cuenta.
    //   4) Owner de la cuenta INACTIVO:
    //        - voz 'Portabilidad Out' => cola PVU_MesaPortout (o usuario creador si la cola no existe).
    //        - otra voz               => usuario que crea el caso.
    @TestVisible
    private static Id resolveOwnerId(Map<String,Object> channel, String customerVoice, Id accountOwnerId, Boolean esFinanciacion){
        if(isDigitalChannel(channel)){
            return UserInfo.getUserId();
        }
        if(esFinanciacion == true){
            return getQueueIdByName('FIN_BackAjustesFinanciacion');
        }
        Boolean ownerActivo = false;
        if(accountOwnerId != null){
            List<User> owners = [SELECT Id, IsActive FROM User WHERE Id = :accountOwnerId WITH SYSTEM_MODE LIMIT 1];
            ownerActivo = !owners.isEmpty() && owners[0].IsActive;
        }
        if(ownerActivo){
            return accountOwnerId;
        }
        // Owner inactivo: Portabilidad Out => cola PVU_MesaPortout; cualquier otra voz => usuario que crea el caso.
        if('Portabilidad Out'.equalsIgnoreCase(customerVoice)){
            Id mesaPortoutId = getQueueIdByName('PVU_MesaPortout');
            return mesaPortoutId != null ? mesaPortoutId : UserInfo.getUserId();
        }
        return UserInfo.getUserId();
    }

    @TestVisible
    private static void manageCaseBySubscriberNumber(Case cas, Map<String, Object> inputMap, Map<String, Object> outMap){
        String typeMatchCM = (String) inputMap.get('customerVoice');
        String status = (String) inputMap.get('status');
        String description = (String) inputMap.get('description');
        String category = (String) inputMap.get('category');
        String subcategory = (String) inputMap.get('subcategory');
        String priority = (String) inputMap.get('priority');
        String recordType = (String) inputMap.get('type');
        String subscriberNumber = (String) inputMap.get('subscriberNumber');
        Map<String,Object> channel = (Map<String,Object>) inputMap.get('channel');

        List<Asset> ast = [SELECT Id, Name,
                            AccountId, Account.Name, Account.FVU_DocumentNumber__c, Account.FVU_DocumentType__c,
                            Account.OwnerId, Account.vlocity_cmt__PrimaryContactId__c,
                            vlocity_cmt__SubscriptionId__r.OM_MSISDN__c
                            FROM Asset WHERE vlocity_cmt__SubscriptionId__r.OM_MSISDN__c = :subscriberNumber
                           AND Product2.vlocity_cmt__SpecificationSubType__c = 'Simple' AND Product2.vlocity_cmt__Type__c = 'Plan' AND Product2.Family = 'Mobile' AND Status  IN ('Active','Suspended','Deactivated')
                            WITH USER_MODE LIMIT 1];

        if(ast.size() > 0){

            cas.put('AssetId', ast[0].Id);
            cas.put('PVU_MINReporteImei__c', subscriberNumber);
            cas.put('AccountId', ast[0].AccountId);
            cas.put('ContactId', ast[0].Account.vlocity_cmt__PrimaryContactId__c);
            // HU 811299 - Asignación de owner centralizada (ver resolveOwnerId).
            cas.put('OwnerId', resolveOwnerId(channel, typeMatchCM, ast[0].Account.OwnerId, false));
            cas.put('Status', status);
            cas.put('Description', description);
            cas.put('PVU_Level1__c', category);
            cas.put('PVU_Level2__c', subcategory);
            cas.put('PVU_Level3__c', typeMatchCM);
            cas.put('priority', priority);
            cas.put('RecordTypeId', recordType);
            cas.put('Origin', (String) channel.get('name'));
            insertCase(cas, outMap);

        }
        else{
            outMap.put('message', 'No subscriberNumber found');
            outMap.put('status', 'Failed');
            outMap.put('code', '409');
        }
    }

    private static void manageCaseByClient(Case cas, Map<String, Object> inputMap, Map<String, Object> outMap){
        String typeMatchCM = (String) inputMap.get('customerVoice');
        String status = (String) inputMap.get('status');
        String description = (String) inputMap.get('description');
        String category = (String) inputMap.get('category');
        String subcategory = (String) inputMap.get('subcategory');
        String priority = (String) inputMap.get('priority');
        String documentType = (String) inputMap.get('documentType');
        String documentNumber = (String) inputMap.get('documentNumber');
        String recordType = (String) inputMap.get('type');
        String subscriberNumber = (String) inputMap.get('subscriberNumber');
        Map<String,Object> channel = (Map<String,Object>) inputMap.get('channel');

        //20240229 - FM - HU 656412 - INICIO
        List<Account> cuenta = [SELECT Id, Name, FVU_DocumentType__c, FVU_DocumentNumber__c, RecordType.Name, OwnerId, vlocity_cmt__PrimaryContactId__c,
                                vlocity_cmt__PrimaryContactId__r.Name, vlocity_cmt__PrimaryContactId__r.FVU_DocumentType__c, vlocity_cmt__PrimaryContactId__r.FVU_DocumentNumber__c,
                                (SELECT Id, Name, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__ParentItemId__c, vlocity_cmt__RootItemId__c, vlocity_cmt__AttributeSelectedValues__c,
                                Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SubType__c, Product2.Family,
                                Product2.vlocity_cmt__SpecificationType__c, Product2.vlocity_cmt__SpecificationSubType__c
                                FROM Assets WHERE Product2.Family = 'Mobile')
                                FROM Account
                                WHERE RecordType.Name = 'Consumer'
                                AND FVU_DocumentType__c =:documentType
                                AND FVU_DocumentNumber__c =:documentNumber
                                WITH USER_MODE LIMIT 1];
            //20240229 - FM - HU 656412 - FIN
            if(cuenta.size() > 0){
                //20240229 - FM - HU 656412 - INICIO
                //Mapa que contiene Key=AssetReferenceId, value=Asset
                Map<String, Asset> assetsMap = new Map<String, Asset>();
                //Mapa que contiene Key=numerodeLinea, value=AssetReferenceId
                Map<String, String> numerosLineaMap = new Map<String, String>();
                //20240229 - FM - HU 656412 - FIN
                //20240229 - FM - HU 656412 - INICIO
                for(Asset activo : cuenta[0].assets){
                    assetsMap.put(activo.vlocity_cmt__AssetReferenceId__c, activo);
                }

                for(Asset activo : cuenta[0].assets){
                    if(activo.Product2.vlocity_cmt__Type__c == 'MSISDN'){
                        Map<String,Object> attrDeserialized = (Map<String, Object>)JSON.deserializeUntyped(activo.vlocity_cmt__AttributeSelectedValues__c);

                        String numeroLineaMovil = (String) attrDeserialized.get('B2C-ATTR-MSISDN');

                        //guardo en mapa como llave el numero de linea movil para matchear luego con subscriberNumber que viene en request
                        //y guardo en el value el assetreferenceid del padre en la estructura
                        numerosLineaMap.put(numeroLineaMovil, activo.vlocity_cmt__ParentItemId__c);

                    }
                }
                Boolean existeNumeroLineaEnCliente = numerosLineaMap.get(subscriberNumber) != null;

                if(existeNumeroLineaEnCliente){
                    Asset plan = assetsMap.get(numerosLineaMap.get(subscriberNumber));
                    cas.put('AssetId', plan.Id);
                    cas.put('PVU_MINReporteImei__c', subscriberNumber);
                }
                //20240229 - FM - HU 656412 - FIN
                // This part is all data that does not change
                //20240229 - FM - HU 656412 - INICIO
                cas.put('AccountId', cuenta[0].Id);
                cas.put('ContactId', cuenta[0].vlocity_cmt__PrimaryContactId__c);
                // HU 811299 - Asignación de owner centralizada (ver resolveOwnerId).
                cas.put('OwnerId', resolveOwnerId(channel, typeMatchCM, cuenta[0].OwnerId, false));
                //20240229 - FM - HU 656412 - FIN
                cas.put('Status', status);
                cas.put('Description', description);
                cas.put('PVU_Level1__c', category);
                cas.put('PVU_Level2__c', subcategory);
                cas.put('PVU_Level3__c', typeMatchCM);
                cas.put('priority', priority);
                cas.put('RecordTypeId', recordType);
                cas.put('Origin', (String) channel.get('name'));
                cas.put('PVU_TipoDocumento__c',documentType);
                cas.put('PVU_NumeroDocCliente__c',documentNumber);
                insertCase(cas, outMap);
            }
            else{
                // 20241210 - FIN - HU - 421964 - INICIO
                String message = typeMatchCM != 'Ajuste de Credito' ?'Document number and document type not found' : System.Label.FIN_CaseAccNotFoundAjusteDeCredito;
                outMap.put('message', message);
                // 20241210 - FIN - HU - 421964 - FIN
                outMap.put('status', 'Failed');
                outMap.put('code', '409');
            }
    }
    @TestVisible
    private static void manageCaseByFinancingCode(Case cas, Map<String, Object> inputMap, Map<String, Object> outMap){
        String typeMatchCM = (String) inputMap.get('customerVoice');
        String status = (String) inputMap.get('status');
        String description = (String) inputMap.get('description');
        String category = (String) inputMap.get('category');
        String subcategory = (String) inputMap.get('subcategory');
        String priority = (String) inputMap.get('priority');
        String documentType = (String) inputMap.get('documentType');
        String documentNumber = (String) inputMap.get('documentNumber');
        String recordType = (String) inputMap.get('type');
        String subscriberNumber = (String) inputMap.get('subscriberNumber');
        String financingCode = (String) inputMap.get('financingCode');
        String billingAccountCode = (String) inputMap.get('billingAccountCode');
        String serialNumber = (String) inputMap.get('serialNumber');
        Map<String,Object> channel = (Map<String,Object>) inputMap.get('channel');

        List<Account> cuenta = [SELECT Id, Name, FVU_DocumentType__c, FVU_DocumentNumber__c, RecordType.Name, OwnerId, vlocity_cmt__PrimaryContactId__c,
                                vlocity_cmt__PrimaryContactId__r.Name, vlocity_cmt__PrimaryContactId__r.FVU_DocumentType__c, vlocity_cmt__PrimaryContactId__r.FVU_DocumentNumber__c,
                                (SELECT Id, Name, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__ParentItemId__c, vlocity_cmt__RootItemId__c, vlocity_cmt__AttributeSelectedValues__c,
                                Product2.vlocity_cmt__Type__c, Product2.vlocity_cmt__SubType__c, Product2.Family,
                                Product2.vlocity_cmt__SpecificationType__c, Product2.vlocity_cmt__SpecificationSubType__c,
                                FIN_IdReferenciaDelCredito92__c, PVU_IMEI__c, FIN_NumeroDeCredito__c, PVU_Serial__c
                                FROM Assets)
                                FROM Account
                                WHERE RecordType.Name = 'Consumer'
                                AND FVU_DocumentType__c =:documentType
                                AND FVU_DocumentNumber__c =:documentNumber
                                WITH USER_MODE LIMIT 1];
        if(cuenta.size() > 0) {
            Boolean isError = false;
            String errorMessage = '';
            Asset assetWithFinancingCode = null;
            for(Asset activo : cuenta[0].assets) {
                if(activo.FIN_NumeroDeCredito__c == financingCode) {
                    assetWithFinancingCode = activo;
                    break;
                }
            }
            if(assetWithFinancingCode != null) {
                if (assetWithFinancingCode.PVU_IMEI__c != serialNumber && assetWithFinancingCode.PVU_Serial__c != serialNumber) {
                    //ERROR 2 serial no coincide
                    isError = true;
                    errorMessage = System.Label.FIN_TroubleTicket_serialNumberNotMatch;
                } else {
                    //DEJA PASAR
                    cas.put('AssetId', assetWithFinancingCode.Id);
                    cas.put('FIN_SerialEquipo__c', serialNumber);
                    cas.put('FIN_cuenta92__c', billingAccountCode);
                    cas.put('FIN_NumeroCredito__c', financingCode);
                }
            } else {
                //ERROR 0 No hay asset con ese credito
                isError = true;
                errorMessage = System.Label.FIN_TroubleTicket_financingCodeNotMatch;
            }

            if (!isError) {
                // HU 811299 - Asignación de owner centralizada (ver resolveOwnerId). Escenario financiación => esFinanciacion=true.
                Id ownerToAssign = resolveOwnerId(channel, typeMatchCM, cuenta[0].OwnerId, true);
                if (ownerToAssign == null) {
                    // Solo ocurre si la cola FIN_BackAjustesFinanciacion no existe (caso no digital ni Portabilidad Out).
                    outMap.put('message', 'Queue \'FIN_BackAjustesFinanciacion\' not found. Cases cannot be assigned.');
                    outMap.put('status', 'Failed');
                    outMap.put('code', '409');
                    return;
                }
                cas.put('AccountId', cuenta[0].Id);
                cas.put('ContactId', cuenta[0].vlocity_cmt__PrimaryContactId__c);
                cas.put('OwnerId', ownerToAssign);
                //20240229 - FM - HU 656412 - FIN
                cas.put('Status', status);
                cas.put('Description', description);
                cas.put('PVU_Level1__c', category);
                cas.put('PVU_Level2__c', subcategory);
                cas.put('PVU_Level3__c', typeMatchCM);
                cas.put('priority', priority);
                cas.put('RecordTypeId', recordType);
                cas.put('Origin', (String) channel.get('name'));
                cas.put('PVU_TipoDocumento__c',documentType);
                cas.put('PVU_NumeroDocCliente__c',documentNumber);
                insertCase(cas, outMap);
            } else {
                outMap.put('message', errorMessage);
                outMap.put('status', 'Failed');
                outMap.put('code', '409');
            }
        } else {
            // 20241210 - FIN - HU - 421964 - INICIO
            String message = typeMatchCM != 'Ajuste de Credito' ?'Document number and document type not found' : System.Label.FIN_CaseAccNotFoundAjusteDeCredito;
            outMap.put('message', message);
            // 20241210 - FIN - HU - 421964 - FIN
            outMap.put('status', 'Failed');
            outMap.put('code', '409');
        }
    }


    /*------------------------------------------------------------
    Author:         Luis Mendoza
    Company:        Salesforce.com
    Description:    method to get data to object
    History
    <Date>          <Author>        <Change Description>
    06/03/24        Luis Mendoza    Initial Version
    27/08/24        Luis Mendoza    version change caseNumber search
    13/09/25        Hector Machuca  Add field Cuota Inicial from quote order.
    ------------------------------------------------------------*/
    public static void getCaseDynamic(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {

        String objectName = (String) inputMap.get('sObjectName');
        String fieldStandard = (String) inputMap.get('fieldStandard');
        String typeMatchCM = (String) inputMap.get('customerVoice');
        List<Object> whereObject =  (List<Object>) inputMap.get('wheredata');

        List<Map<String,Object>> allresponse =  new List<Map<String,Object>>();
        List<Map<String,Object>> whereFields = new List<Map<String,Object>>();

        try {
            //Dynamic field where
            for (Object instance : whereObject) {
                whereFields.add((Map<String,Object>) instance);
            }

            // search by CaseNumber
            if( whereFields[0].get('field') == 'CaseNumber' &&  whereFields[0].get('value') != null ){

                String caseNumberSearch = (String) whereFields[0].get('value');
                List<Case> caseMatchData = [SELECT PVU_Level3__c FROM Case WHERE CaseNumber = :caseNumberSearch WITH USER_MODE];
                typeMatchCM = caseMatchData.size() > 0 ? caseMatchData[0].PVU_Level3__c : '';

            }


            if (!String.isEmpty(typeMatchCM)) {

                //Query to get custom fields to show in query
                PVU_TMFFieldsInsertCase__mdt[] cmt = [SELECT type__c, field_custom__c, squad__c
                                                        FROM PVU_TMFFieldsInsertCase__mdt WHERE type__c = :typeMatchCM WITH USER_MODE LIMIT 1];
                String fieldsCustom = '';
                List<String> fieldsCustomsList = new  List<String>();
                if (cmt.size()> 0) {
                    fieldsCustom = cmt[0].field_custom__c;
                    fieldsCustomsList = fieldsCustom.split(',');
                }
                List<String> fieldStandards = fieldStandard.split(',');


                //init query
                String query = 'SELECT ';
                if( fieldStandard != null){
                    query += fieldStandard + ', ';
                }
                if ( !String.isEmpty(fieldsCustom)) {
                    query += fieldsCustom;
                }

                query = query.removeEnd(', ');


                //Where dynamic
                String wheres = '';

                for (Map<String,Object> whereField : whereFields) {
                    if (whereField.get('field') != null && whereField.get('value') != null) {
                        wheres += whereField.get('field') +  '= \'' +  String.escapeSingleQuotes( (String) whereField.get('value')) + '\' ' + whereField.get('operater') + ' ';  
                    }
                }

                if(wheres.endsWith('AND ')){
                    wheres = wheres.removeEnd('AND ');
                }else if(wheres.endsWith('OR ')){
                    wheres = wheres.removeEnd('OR ');
                }
                //end query
                query += ' FROM ' + objectName + ' WHERE ' + wheres;


                SObject[] recordsObject = Database.query(query);

                for (SObject resp : recordsObject) {

                    Map<String,Object> standardFields =  new Map<String,Object>();
                    for (String fieldObject : fieldStandards) {
                        if ( resp.get(fieldObject.trim()) != null) {

                            standardFields.put(fieldObject, resp.get(fieldObject.trim()));
                        }
                    }


                    List<Map<String,Object>> troubleTicketCharacteristics =  new List<Map<String,Object>>();
                    for (String fieldsCustomResp : fieldsCustomsList) {

                        Map<String,Object> troubleTicketCharacteristic =  new Map<String,Object>();
                        if(fieldsCustomResp.contains('.')){

                                String[] relathionObjectList = fieldsCustomResp.split('\\.');
                                String relathionObjectName = relathionObjectList[0];
                                String relathionObjectValue = relathionObjectList[1];

                                if (resp.getSObject(relathionObjectName.trim()) != null) {

                                    SObject  respChild = resp.getSObject(relathionObjectName.trim());

                                    Schema.DescribeFieldResult fieldLabelDescribe = respChild.getSObjectType().getDescribe().fields.getMap().get(relathionObjectValue.trim()).getDescribe();
                                    if (relathionObjectValue == 'OrderNumber') {
                                        troubleTicketCharacteristic.put('name','Order Number');
                                    } else if (relathionObjectValue == 'FVU_EffectiveOneTimeIncTaxesTotal__c') {
                                        troubleTicketCharacteristic.put('name','Order Total');
                                    } else if (relathionObjectValue == 'PVU_OfertaCuotaInicial__c') {
                                        troubleTicketCharacteristic.put('name','Cuota Inicial');
                                    } else {
                                        troubleTicketCharacteristic.put('name',fieldLabelDescribe.getLabel());
                                    }

                                    troubleTicketCharacteristic.put('value', respChild.get(relathionObjectValue.trim()));
                                    troubleTicketCharacteristics.add(troubleTicketCharacteristic);

                                }

                            }else{

                                if (resp.get(fieldsCustomResp.trim()) != null) {
									
                                    Schema.DescribeFieldResult fieldLabelDescribe = resp.getSObjectType().getDescribe().fields.getMap().get(fieldsCustomResp).getDescribe();
                                    troubleTicketCharacteristic.put('name',fieldLabelDescribe.getLabel());
                                    troubleTicketCharacteristic.put('value', resp.get(fieldsCustomResp.trim()));
                                    troubleTicketCharacteristics.add(troubleTicketCharacteristic);

                                }
                            }
                    }

                    standardFields.put('troubleTicketCharacteristic', troubleTicketCharacteristics);
                    allresponse.add(standardFields);
                }

                    // Process the results
                if (recordsObject.isEmpty()) {
                    outMap.put('message', 'Case not found');
                    outMap.put('status',  'Failed');
                    outMap.put('code',  '400'); 
                }else {
                    outMap.put('responsesData', allresponse);
                    outMap.put('status', 'Success');
                    outMap.put('code', '200');
                }
            }else{
                outMap.put('message', 'Field customerVoice required');
            outMap.put('status',  'Failed');
            outMap.put('code',  '400');
            }

            outMap.remove('errorCode');
            outMap.remove('error');


        } catch (Exception e) {
            System.debug('Error get record: ' + e.getMessage());
            System.debug('Line: ' + e.getLineNumber());
            outMap.put('message', e.getMessage() + ' Line: ' + e.getLineNumber());
            outMap.put('status',  'Failed');
            outMap.put('code',  '500');
        }
    }

    @TestVisible
    private static String getRequiredData( String requiredFields, List<Map<String,Object>> fieldsJSON ){


        if(String.isNotBlank(requiredFields)){

            List<String> filedRequireds = requiredFields.split(',');
            String requiredField = '';

            for (String reqField : filedRequireds) {

                Boolean isVerified = false;

                for (Map<String,Object> fieldView : fieldsJSON) {

                    String fieldTrouble = (String) fieldView.get('name');

                    if((reqField == fieldTrouble) && !isVerified){
                        isVerified = true;
                    }
                }

                if(!isVerified){
                   requiredField += reqField  + ', ';
                }
            }

            return requiredField;

        }else{
            return '';
        }

    }

    /**
     * @regresa Id de la Queue si existe
     */
    @TestVisible
    private static Id getQueueIdByName(String queueName) {
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueName WITH USER_MODE LIMIT 1];
        return queue != null ? queue.Id : null;
    }
}