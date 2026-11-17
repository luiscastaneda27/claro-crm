/**
 * The FVU_IdClaroCanvasLifecycleHandler class provides methods to customize the Aa Identidad Claro Connected App lifecycle.
 * It provides a dynamic URL for the Canvas, based on account, user, and application information.
 */
public with sharing class FVU_IdClaroCanvasLifecycleHandler implements Canvas.CanvasLifecycleHandler{
    
    private final static String CANVAS_URL_PATH = System.label.FVU_IdClaro_CANVAS_URL_PATH;
    private final static String APP_EXT_VECTOR_INITIALIZATION = System.label.FVU_IdClaro_APP_EXT_VECTOR_INITIALIZATION;
    private final static String APP_EXT_SECRET_KEY = System.label.FVU_IdClaro_APP_EXT_SECRET_KEY;

    // Mandatory method to specify which context types to exclude
    public Set<Canvas.ContextTypeEnum> excludeContextTypes(){
        Set<Canvas.ContextTypeEnum> excluded = new Set<Canvas.ContextTypeEnum>();
        
        return excluded;
    }

    // Code executed when the app is rendered
    public void onRender(Canvas.RenderContext renderContext) {
        // Get the Application and Environment context from the RenderContext
        Canvas.ApplicationContext app = renderContext.getApplicationContext();
        Canvas.EnvironmentContext env = renderContext.getEnvironmentContext();

        // Deserialize parameters passed from the VisualForce page as JSON
        Map<String, Object> parameters =  (Map<String, Object>) JSON.deserializeUntyped(env.getParametersAsJSON());

        // Set the Canvas URL path with an encrypted token
        app.setCanvasUrlPath(CANVAS_URL_PATH + encryptToken(parameters));
    }

    // Encrypt a token using AES128 encryption
    public String encryptToken(Map<String, Object> parameters) {
        
        // Encryption secret key
        String secretKey = APP_EXT_SECRET_KEY + System.now().format('yyyyMMdd');
      
        // Call the getData method to retrieve the data to be encrypted
        String data = getData(parameters);

        Blob IV = Blob.valueOf(generateIV());
        Blob key = Blob.valueOf(secretKey);
        Blob dataBlob = Blob.valueOf(data);
        Blob encryptedBlob = Crypto.encrypt('AES128', key, IV, dataBlob);

        String encryptedToken = EncodingUtil.base64Encode(encryptedBlob);
        return encryptedToken;
    }

    // Retrieve data that needs to be encrypted based on the parameters received (application, channel, accountId and userId)
    private String getData(Map<String, Object> parameters) {
        // Create an instance of FVU_IdClaroRepresentation to store all retrieved data
        FVU_IdClaroRepresentation params = new FVU_IdClaroRepresentation();

        Map<String,String> dataMap = new Map<String,String>();

        // Retrieve IdClaro metadata based on application and channel
        FVU_IdClaroMetadata__mdt idClaroMetadata = new FVU_IdClaroMetadataSelector().getIdClaroMetadata(String.valueOf(parameters.get('application')).unescapeHtml4(), String.valueOf(parameters.get('channel')));
        populateParametersFromIdClaroMetadata(params, idClaroMetadata, dataMap);
        
        // Check if the person to be authenticated is a client (has a Salesforce account record) or an authorized third person
        Boolean isThirdPerson = parameters.get('isAuthorizedPerson')!=null? Boolean.valueOf(parameters.get('isAuthorizedPerson')): false;
        String recordId = String.valueOf(parameters.get(isThirdPerson ? 'recordId' : 'accountId'));
        //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
        Boolean isThirdPersonPV = parameters.get('isAuthorizedPersonPV')!=null? Boolean.valueOf(parameters.get('isAuthorizedPersonPV')): false;
        String thirdPersonData = (String) parameters.get('thirdPersonData');
        
        if (!isThirdPerson && FVU_IdClaroUtils.isValidAccountId(recordId)) {
            Account account = new FVU_AccountSelector().getAccountIdClaroData(String.valueOf(parameters.get('accountId')));
            populateParametersFromAccount(params, account, dataMap);
        } else if (isThirdPerson && FVU_IdClaroUtils.isValidOrderId(recordId)) {
            Order order = new FVU_OrderSelector().getOrderIdClaroData(String.valueOf(parameters.get('recordId')));
            populateParametersFromOrder(params, order, dataMap);
        } else if (isThirdPerson && FVU_IdClaroUtils.isValidCaseId(recordId)) {
            Case record = new FVU_CaseSelector().getCaseIdClaroData(String.valueOf(parameters.get('recordId')));
            populateParametersFromCase(params, record, dataMap);
        } else { //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
            populateParametersFromData(thirdPersonData, dataMap);
        }

        // Check if userId is valid and retrieve related data
        if(FVU_IdClaroUtils.isValidUserId(String.valueOf(parameters.get('userId')))){
            User user = new FVU_UserSelector().getUserIdClaroData(String.valueOf(parameters.get('userId')));
            dataMap.put('user', user.PVU_Usuario_Red__c);
        }
        
        // Generate a data string from params
        String data = '';
        
        for(String key : dataMap.keySet()){
            if(dataMap.get(key) != null){
                data += key + '=' + dataMap.get(key) + '|';
            }
        }
        data = data.removeEnd('|');
        system.debug(data);
        
        return data;
    }

    // Generate the initialization vector (IV) for encryption following the rule specified in the Id Claro documentation
    private String generateIV() {
        List<String> splitKey = APP_EXT_VECTOR_INITIALIZATION.split('');
        List<String> splitDate = System.now().format('MMddyyyy').split('');
        List<String> splitIV = new List<String>();

        for(Integer i=0; i<splitKey.size(); i++){
            splitIV.add(splitKey[i]);
            splitIV.add(splitDate[i]);
        }

        String resultIV = String.join(splitIV,'');
        
        return resultIV;
    }

    private void populateParametersFromIdClaroMetadata(FVU_IdClaroRepresentation params, FVU_IdClaroMetadata__mdt idClaroMetadata, Map<String,String> dataMap) {
        if(idClaroMetadata != null) {
            dataMap.put('urlOK', idClaroMetadata.FVU_UrlOK__c == null ? '' : idClaroMetadata.FVU_UrlOK__c);
            dataMap.put('methodSendOK', idClaroMetadata.FVU_MethodSendOK__c == null ? '' : idClaroMetadata.FVU_MethodSendOK__c);
            dataMap.put('urlReturn', idClaroMetadata.FVU_UrlReturn__c == null ? '' : idClaroMetadata.FVU_UrlReturn__c);
            dataMap.put('methodSendReturn', idClaroMetadata.FVU_MethodSendReturn__c == null ? '' : idClaroMetadata.FVU_MethodSendReturn__c);
            dataMap.put('accountType', idClaroMetadata.FVU_AccountType__c);
            dataMap.put('company', idClaroMetadata.FVU_Company__c);
            dataMap.put('application', idClaroMetadata.FVU_Application__c);
            dataMap.put('accessKey', idClaroMetadata.FVU_AccessKey__c);
            dataMap.put('chanelTypeCode', idClaroMetadata.FVU_ChanelTypeCode__c);
        }
    }

    private void populateParametersFromAccount(FVU_IdClaroRepresentation params, Account account, Map<String,String> dataMap) {
        String documentClient = account.FVU_DocumentType__c == 'PP' ? 'PS' + '-' + account.FVU_DocumentNumber__c : account.FVU_DocumentType__c + '-' + account.FVU_DocumentNumber__c;
        dataMap.put('documentClient', documentClient);
        dataMap.put('name', account.vlocity_cmt__PrimaryContactId__r.FirstName);
        dataMap.put('secondName', '');
        dataMap.put('lastName', account.vlocity_cmt__PrimaryContactId__r.LastName);

        String lastName = account.vlocity_cmt__PrimaryContactId__r.LastName;
        String secondLastName = account.vlocity_cmt__PrimaryContactId__r.FVU_SecondLastName__c;
        if(secondLastName != null) {
        	secondLastName = lastName.endsWith(secondLastName) ? '': secondLastName;
        } 
        
        dataMap.put('secondLastName', secondLastName);
        dataMap.put('phoneNumber', account.Phone);
        dataMap.put('emailAddress', account.FVU_Email__c);

        if(account.vlocity_cmt__PrimaryContactId__r.FVU_ExpeditionSite__c != null){
            FVU_CityMetadata__mdt cityData = new FVU_CityMetadataSelector().getCityMetadata(account.vlocity_cmt__PrimaryContactId__r.FVU_ExpeditionSite__c);
            dataMap.put('codDepartment', cityData?.FVU_DaneDepartment__c);
            dataMap.put('codCity', cityData?.FVU_DaneMunicipality__c);
        }
    }

    private void populateParametersFromOrder(FVU_IdClaroRepresentation params, Order order, Map<String,String> dataMap) {  
        if(order.FVU_DeliveryData__c != null){
            // Deserialize the FVU_DeliveryData__c field
            Map<String, Object> deliveryData =  (Map<String, Object>) JSON.deserializeUntyped(order.FVU_DeliveryData__c);
            Map<String, Object> authorizedPersonData = (Map<String, Object>)deliveryData.get('AuthorizedPersonData');

            String documentClient = String.valueOf(authorizedPersonData.get('DocumentType')) == 'PP' ? 'PS' + '-' + String.valueOf(authorizedPersonData.get('Document')) : String.valueOf(authorizedPersonData.get('DocumentType')) + '-' + String.valueOf(authorizedPersonData.get('Document'));
            dataMap.put('documentClient', documentClient);
            dataMap.put('name', String.valueOf(authorizedPersonData.get('Name')));
            dataMap.put('secondName', '');
            dataMap.put('lastName', String.valueOf(authorizedPersonData.get('LastName')));
            dataMap.put('secondLastName', String.valueOf(authorizedPersonData.get('SecondLastName')));
            dataMap.put('phoneNumber', String.valueOf(authorizedPersonData.get('Phone')));
        }
    }

    private void populateParametersFromCase(FVU_IdClaroRepresentation params, Case record, Map<String,String> dataMap) {  
        if(record.PVU_AuthorizedPersonData__c != null){
            // Deserialize the PVU_AuthorizedPersonData__c field
            Map<String, Object> personData =  (Map<String, Object>) JSON.deserializeUntyped(record.PVU_AuthorizedPersonData__c);
            Map<String, Object> authorizedPersonData = (Map<String, Object>)personData.get('AuthorizedPersonData');

            String documentClient = String.valueOf(authorizedPersonData.get('DocumentType')) == 'PP' ? 'PS' + '-' + String.valueOf(authorizedPersonData.get('Document')) : String.valueOf(authorizedPersonData.get('DocumentType')) + '-' + String.valueOf(authorizedPersonData.get('Document'));
            dataMap.put('documentClient', documentClient);
            dataMap.put('name', String.valueOf(authorizedPersonData.get('Name')));
            dataMap.put('secondName', '');
            dataMap.put('lastName', String.valueOf(authorizedPersonData.get('LastName')));
            dataMap.put('secondLastName', String.valueOf(authorizedPersonData.get('SecondLastName')));
            dataMap.put('phoneNumber', String.valueOf(authorizedPersonData.get('Phone')));
            dataMap.put('emailAddress', String.valueOf(authorizedPersonData.get('Email')));
        }
    }

    //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
    private void populateParametersFromData(String personData, Map<String,String> dataMap) {  
        
        Map<String, Object> personDataMap =  (Map<String, Object>) JSON.deserializeUntyped(personData);
        String documentClient = String.valueOf(personDataMap.get('TipoDoc')) == 'PP' ? 'PS' + '-' + String.valueOf(personDataMap.get('NumDoc')) : String.valueOf(personDataMap.get('TipoDoc')) + '-' + String.valueOf(personDataMap.get('NumDoc'));
        dataMap.put('documentClient', documentClient);
        dataMap.put('name', String.valueOf(personDataMap.get('primerNombre')));
        dataMap.put('secondName', String.valueOf(personDataMap.get('segundoNombre')));
        dataMap.put('lastName', String.valueOf(personDataMap.get('primerApellido')));
        dataMap.put('secondLastName', String.valueOf(personDataMap.get('segundoApellido')));
        dataMap.put('phoneNumber', String.valueOf(personDataMap.get('telefono')));
        dataMap.put('emailAddress', String.valueOf(personDataMap.get('mail')));
        
    }

    public FVU_IdClaroCanvasLifecycleHandler() { }   

}