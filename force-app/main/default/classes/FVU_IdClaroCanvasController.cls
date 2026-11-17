public with sharing class FVU_IdClaroCanvasController {
    // Properties to store data
    public static String jsonString {get;set;}
    public static String userId {get;set;} 
    public static String accountId {get;set;} 
    public static String recordId {get;set;} 
    public static String application {get;set;} 
    public static String channel {get;set;} 
    public static String isAuthorizedPerson {get;set;} 
    //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
    public static String thirdPersonData {get;set;} 
    public static String isAuthorizedPersonPV {get;set;} 
    public static String urlPath {get;set;}

    public FVU_IdClaroCanvasController() {
        // Get endpoint ID Claro
        urlPath = System.label.FVU_IdClaro_CANVAS_URL_PATH;
        // Get the current user's Salesforce ID
        userId = UserInfo.getUserId();

        // INICIO CORRECCIÓN DE SEGURIDAD: Se aplicar llamado a la clase 'FVU_SecurityInputUtils' para validacion de tipos de datos.

        String rawAccount = ApexPages.currentPage().getParameters().get('account');
        accountId = (rawAccount != null) ? FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId(rawAccount, true) : null;

        String rawRecord = ApexPages.currentPage().getParameters().get('record');
        recordId = (rawRecord != null) ? FVU_SecurityInputUtils.sanitizeAndValidateSalesforceId(rawRecord, true) : null;

        String rawApp = ApexPages.currentPage().getParameters().get('app');
        application = (rawApp != null) ? FVU_SecurityInputUtils.validateAppName(rawApp) : null;

        String rawChannel = ApexPages.currentPage().getParameters().get('channel');
        channel = (rawChannel != null) ? FVU_SecurityInputUtils.validateNumeric(rawChannel) : null;

        String rawIsAuthorizedPerson = ApexPages.currentPage().getParameters().get('isThirdPerson');
        isAuthorizedPerson = (rawIsAuthorizedPerson != null) ? FVU_SecurityInputUtils.validateBoolean(rawIsAuthorizedPerson) : null;

        //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
        String rawThirdPersonData = ApexPages.currentPage().getParameters().get('thirdPersonData');
        thirdPersonData = (rawThirdPersonData != null) ? FVU_SecurityInputUtils.sanitizeAndValidateJson(rawThirdPersonData, 1000, true) : null;

        String rawIsAuthorizedPersonPV = ApexPages.currentPage().getParameters().get('isThirdPersonPV');
        isAuthorizedPersonPV = (rawIsAuthorizedPersonPV != null) ? FVU_SecurityInputUtils.validateString(rawIsAuthorizedPersonPV) : null;
        
        // FIN CORRECCIÓN DE SEGURIDAD
        
        // Create a map to store the data
        Map<String, String> mapToSerialize = new Map<String, String>();
        mapToSerialize.put('userId', userId);
        mapToSerialize.put('accountId', accountId);
        mapToSerialize.put('recordId', recordId);
        mapToSerialize.put('application', application);
        mapToSerialize.put('channel', channel);
        mapToSerialize.put('isAuthorizedPerson', isAuthorizedPerson);
        //20241003 - FM - HU 422921 - Se agrega datos de tercero para gestiones posventa donde aun no hay un caso creado.
        mapToSerialize.put('thirdPersonData', thirdPersonData);
        mapToSerialize.put('isAuthorizedPersonPV', isAuthorizedPersonPV);
        
        // Serialize the map to JSON and store it in 'jsonString'
        //jsonString = JSON.serialize(mapToSerialize); [2025/09/30 COE: Se inactiva esta línea, por el cambio de GET a POST en la recepción de parámetros de ID Claro]
		
		// Generate the JSON String by calling the FVU_IdClaroCanvasLifecycleHandler class
		jsonString = this.callLifecycleHandler(mapToSerialize);
    }
    /**
     * This method calls the encryptToken method from the FVU_IdClaroCanvasLifecycleHandler class.     
     * @param parameters The map of parameters to be encrypted.
     * @return The encrypted token string.
     */
    private String callLifecycleHandler(Map<String, String> parameters) {
        // Create a new instance of the LifecycleHandler class
        FVU_IdClaroCanvasLifecycleHandler handler = new FVU_IdClaroCanvasLifecycleHandler();

        // Call the public encryptToken method with the map of parameters
        return handler.encryptToken(parameters);
    }
}