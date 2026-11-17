/**
 * @description Processing class for the TMF629 account management API 
 * @author Ventas Flo
 * @version 3.0
 */

public class FVU_TMF629Processing extends FVU_TMFBase {
    
    private static final String API_NAME = 'TMF629';
    private static final Map<String, Object> PAYLOAD =  new Map<String, Object>();
    
    /**
     * @description Constructor
     */
    public FVU_TMF629Processing() {
        super(API_NAME);
    }
    
    /**
     * @description Main request processor - orchestrates all operations
     * @param operation HTTP operation (POST, GET, PATCH, DELETE)
     * @param requestData Request payload
     * @return Response object
     */
    public override Object processRequest(String operation, Map<String, Object> requestData) {
        
        // 1. Validate request class base
        ValidationResult validationResult = validateRequest(operation, requestData);
        
        if (!validationResult.isValid) {
            return buildErrorResponse(validationResult.errors);
        }
        
        // 2. Route to appropriate handler
        try {
            switch on operation {
                when 'POST' {
                    return createCustomerManagement(requestData);
                }
                when 'GET' {
                    return getCustomerManagement(requestData);
                }
                when 'PATCH' {
                    return updateCustomerManagement(requestData);
                }
                when else {
                    return buildErrorResponse(new List<TMFError>{
                        buildError('TMF-405-001', 'Method not allowed', 405)
                    });
                }
            }
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-001', 'Internal Server Error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Retrieves customer information (Accounts) based on provided criteria.
     * @param params 'id' or 'filters' (documentNumber, documentType, pageLimit, offset).
     * @return Object DataRaptor transformed results.
     */
    @TestVisible
    private Object getCustomerManagement(Map<String, Object> params) { 

        try {

            String drName = 'FVU_TMF629CustomerDataResponse';
            String recordId = (String)params.get('id');
            Map<String, String> filters = (Map<String, String>)params.get('filters');

            Map<String, Object> responseMap = new Map<String, Object>();
            List<Account> accountList = new List<Account>();
            Boolean isList = false;
            
            // Query dinamica
            String query = '';

            // Query dinamica: Campos a consultar segun la respuesta final (response).
            String fieldsUnique = 'Id, RecordType.DeveloperName, Name, FVU_UrlAccount__c, vlocity_cmt__Status__c, FVU_ServiceType__c, ' +
                        'FVU_Segment__c, FVU_NotificationChoice__c, CreatedDate, FVU_Email__c, vlocity_cmt__PrimaryContactId__r.Id, ' +
                        'vlocity_cmt__PrimaryContactId__r.FVU_FullName__c, vlocity_cmt__PrimaryContactId__r.FVU_DocumentType__c, ' +
                        'vlocity_cmt__PrimaryContactId__r.FVU_DocumentNumber__c, vlocity_cmt__PrimaryContactId__r.FirstName, ' +
                        'vlocity_cmt__PrimaryContactId__r.LastName, vlocity_cmt__PrimaryContactId__r.FVU_SecondLastName__c, ' +
                        'vlocity_cmt__PrimaryContactId__r.FVU_ExpeditionDate__c, vlocity_cmt__PrimaryContactId__r.Birthdate, vlocity_cmt__PrimaryContactId__r.CreatedDate, ' +
                        '(SELECT id, name, CreatedDate, OM_BSCSID__c, FVU_ServiceAccountRelated__c,  FVU_BillingDaneCode__c, FVU_BillingMerId__c, FVU_FullServiceAddress__c, ' + 
                            'FVU_ServiceDaneCode__c, FVU_SerciveMerId__c, FVU_FullBillingAddress__c, FVU_AccountExternalID__c, RecordType.DeveloperName ' + 
                            'FROM ChildAccounts)';                    

            String fieldsList = 'Id, RecordType.DeveloperName, Name, vlocity_cmt__Status__c, ' +
                        'vlocity_cmt__PrimaryContactId__r.Id, vlocity_cmt__PrimaryContactId__r.FVU_FullName__c, ' +
                        '(SELECT Id, Name, RecordType.DeveloperName FROM ChildAccounts)';
            
                
            // Query dinamica: Condiciones {ID}
            if (String.isNotBlank(recordId)) {
                
                query = 'SELECT ' + fieldsUnique + ' FROM Account WHERE Id = :recordId'; 
    
            // Query dinamica: Condiciones {documentType} / {documentNumber}
            } else if (filters.containsKey('FVU_DocumentNumber__c') && filters.containsKey('FVU_DocumentType__c')) {
                
                String documentNumber = filters.get('FVU_DocumentNumber__c');
                String docType = filters.get('FVU_DocumentType__c');

                query = 'SELECT ' + fieldsUnique + ' FROM Account WHERE RecordType.DeveloperName = \'Consumer\' AND '+ 
                                                    'FVU_DocumentNumber__c = :documentNumber AND FVU_DocumentType__c = :docType';
            
            // Query dinamica: Condiciones {NULL}, Sin parametros de entrada
            } else if(filters.isEmpty()){
                
                isList = TRUE;
                query = 'SELECT ' + fieldsList + ' FROM Account WHERE RecordType.DeveloperName = \'Consumer\' LIMIT 200';

            // Query dinamica: Condiciones {pageLimit} o {offset} 
            } else if (filters.containsKey('pageLimit') || filters.containsKey('offset') ) {
                
                isList = TRUE;
                Integer queryLimit = filters.containsKey('pageLimit') ? Integer.valueOf(filters.get('pageLimit')): 200;
                Integer queryOffset = filters.containsKey('offset') ? Integer.valueOf(filters.get('offset')) : 0;
            
                query = 'SELECT ' + fieldsList + ' FROM Account WHERE RecordType.DeveloperName = \'Consumer\' '+ 
                                                    'ORDER BY CreatedDate DESC LIMIT :queryLimit OFFSET :queryOffset';
                
            }else{
                return buildErrorResponse(new List<TMFError>{
                    buildError('TMF-400-001', 'Invalid parameter value', 400)
                });  
            }

            accountList = Database.query(query, AccessLevel.USER_MODE);
            
            if (!accountList.isEmpty()) {
                
                responseMap.put('listAccount', accountList); 
                vlocity_cmt.DRProcessResult resultDR = vlocity_cmt.DRGlobal.processObjectsJSON(JSON.serialize(responseMap), drName);
                Map<String, Object> drOutput = resultDR.convertToMap();
                Object result = drOutput.get('returnResultsData');
                
                // Convierto a lista             
                if( isList && result instanceof Map<String, Object> ){
                    
                    List<Object> newList = new List<Object>();
                    newList.add(result);
                    result = newList;
                }
                
                return result;
            }

            return new Map<String, Object>(); 

        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-001', 'Execution error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Creates a new account through an existing integration procedure.
     * @param payload data in TMF format.
     * @return Object Account creation.
     */
    @TestVisible
    private Object createCustomerManagement(Map<String, Object> payload) { 

        // Transform TMF payload to IP format
        Map<String, Object> ipPayload = transformToIPFormat(payload); 
    
        if (ipPayload.isEmpty()) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-001', 'Failed to transform payload', 500)
            });
        }
        
        // Call existing Integration Procedure
        Map<String, Object> ipInput = ipPayload;
        Map<String, Object> ipOutput = new Map<String, Object>();
        Map<String, Object> ipOptions = new Map<String, Object>();
        
        try {
            // Call IP using vlocity_cmt namespace
            ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                'FVU_CreateCustomer',
                ipInput,
                ipOptions
            );
            
            // Parse IP response
            Map<String, Object> ipResponse = parseIPResponse(ipOutput, payload);
            return ipResponse; 

        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-001', 'IP execution error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Updates customer information via Integration Procedure
     * @param payload TMF format payload with identificationParams
     * @return Response object
     */
    @TestVisible
    private Object updateCustomerManagement(Map<String, Object> payload) {
        
        // 1. Extract and validate identification parameters
        Map<String, Object> identificationParams = (Map<String, Object>) payload.get('identificationParams');
        
        if (identificationParams == null || identificationParams.isEmpty()) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-400-001', 'Identification parameters required: provide Salesforce ID in path, or docNumber+docType, or email as query parameters', 400)
            });
        }
        
        // Validate docNumber and docType come together
        Boolean hasDocNumber = identificationParams.containsKey('docNumber');
        Boolean hasDocType = identificationParams.containsKey('docType');
        Boolean hasEmail = identificationParams.containsKey('email');
        Boolean hasId = identificationParams.containsKey('id');
        
        if (hasDocNumber && !hasDocType) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-400-001', 'docType is required when docNumber is provided', 400)
            });
        }
        
        if (hasDocType && !hasDocNumber) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-400-001', 'docNumber is required when docType is provided', 400)
            });
        }
        
        // Must have at least one valid identification method
        if (!hasId && !hasEmail && !(hasDocNumber && hasDocType)) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-400-001', 'Identification parameters required: provide Salesforce ID in path, or docNumber+docType, or email as query parameters', 400)
            });
        }
        
        // 2. Validate engagedParty structure
        List<TMFError> validationErrors = validateEngagedPartyForPatch(payload);
        if (!validationErrors.isEmpty()) {
            return buildErrorResponse(validationErrors);
        }
        
        // 3. Identify the Consumer Account (only if using id param, otherwise we'll use query params directly)
        Account consumerAccount = null;
        if (identificationParams.containsKey('id')) {
            consumerAccount = identifyCustomerAccount(identificationParams);
            
            if (consumerAccount == null) {
                return buildErrorResponse(new List<TMFError>{
                    buildError('TMF-404-001', 'Customer not found with provided identification', 404)
                });
            }
            
            // Add consumer account info to payload for downstream processing
            payload.put('consumerAccountId', consumerAccount.Id);
            payload.put('consumerAccountDocNumber', consumerAccount.FVU_DocumentNumber__c);
            payload.put('consumerAccountDocType', consumerAccount.FVU_DocumentType__c);
        }
        
        // 4. Process via IP
        return updateCustomerManagementViaIP(payload, consumerAccount, identificationParams);
    }
    
    /**
     * @description Validates engagedParty structure for PATCH operation
     * @param payload TMF format payload
     * @return List of validation errors (empty if valid)
     */
    @TestVisible
    private List<TMFError> validateEngagedPartyForPatch(Map<String, Object> payload) {
        
        List<TMFError> errors = new List<TMFError>();
        
        if (!payload.containsKey('engagedParty')) {
            return errors; // engagedParty is optional
        }
        
        List<Object> engagedParties = (List<Object>) payload.get('engagedParty');
        
        if (engagedParties == null || engagedParties.isEmpty()) {
            return errors; // Empty list is OK
        }
        
        // Count Billing and Service types
        Integer billingCount = 0;
        Integer serviceCount = 0;
        Map<String, Object> addressEngagedParty = null; // To track the Billing/Service for validation
        
        for (Object obj : engagedParties) {
            Map<String, Object> engagedParty = (Map<String, Object>) obj;
            String epType = (String) engagedParty.get('@type');
            
            if (epType == 'Billing') {
                billingCount++;
                addressEngagedParty = engagedParty;
            } else if (epType == 'Service') {
                serviceCount++;
                addressEngagedParty = engagedParty;
            }
            // Other types (Contact, Organization, etc.) are ignored
        }
        
        // Only one of Billing or Service is allowed (mutually exclusive)
        if (billingCount > 0 && serviceCount > 0) {
            errors.add(buildError('TMF-400-001', 'Only one engagedParty of type Billing OR Service is allowed, not both', 400));
            return errors;
        }
        
        // Cannot have more than 1 Billing
        if (billingCount > 1) {
            errors.add(buildError('TMF-400-001', 'Only one engagedParty of type Billing is allowed', 400));
            return errors;
        }
        
        // Cannot have more than 1 Service
        if (serviceCount > 1) {
            errors.add(buildError('TMF-400-001', 'Only one engagedParty of type Service is allowed', 400));
            return errors;
        }
        
        // If we have a Billing or Service, validate its structure
        if (addressEngagedParty != null) {
            String epType = (String) addressEngagedParty.get('@type');
            
            // Validate action is present
            String action = (String) addressEngagedParty.get('action');
            if (String.isBlank(action)) {
                errors.add(buildError('TMF-400-001', 'engagedParty action is required for type ' + epType, 400));
                return errors;
            }
            
            if (action != 'add' && action != 'modify') {
                errors.add(buildError('TMF-400-001', 'engagedParty action must be either "add" or "modify"', 400));
            }
            
            // Validate id presence based on action
            String epId = (String) addressEngagedParty.get('id');
            
            if (action == 'modify' && String.isBlank(epId)) {
                errors.add(buildError('TMF-400-001', 'engagedParty id is required when action is "modify"', 400));
            }
            
            if (action == 'add' && String.isNotBlank(epId)) {
                errors.add(buildError('TMF-400-001', 'engagedParty id must not be provided when action is "add"', 400));
            }
            
            // Validate corresponding GeographicAddressContactMedium exists
            if (String.isNotBlank(epType)) {
                Boolean hasCorrespondingAddress = false;
                
                if (payload.containsKey('contactMedium')) {
                    List<Object> contactMediums = (List<Object>) payload.get('contactMedium');
                    
                    for (Object obj : contactMediums) {
                        Map<String, Object> cm = (Map<String, Object>) obj;
                        String cmType = (String) cm.get('@type');
                        String contactType = (String) cm.get('contactType');
                        
                        if (cmType == 'GeographicAddressContactMedium' && contactType == epType) {
                            hasCorrespondingAddress = true;
                            break;
                        }
                    }
                }
                
                if (!hasCorrespondingAddress) {
                    errors.add(buildError('TMF-400-001', 
                        'A GeographicAddressContactMedium with contactType "' + epType + '" is required when engagedParty type is "' + epType + '"', 400));
                }
            }
        }
        
        return errors;
    }

    /**
     * @description Updates customer via Integration Procedure
     * @param payload TMF format payload
     * @param consumerAccount The identified consumer account (null if using email/docNumber+docType)
     * @param identificationParams Identification parameters from query
     * @return Response object
     */
    @TestVisible
    private Object updateCustomerManagementViaIP(Map<String, Object> payload, Account consumerAccount, Map<String, Object> identificationParams) {
        
        // Transform TMF payload to IP format for PATCH
        Map<String, Object> ipPayload = transformToIPFormatPatch(payload, consumerAccount, identificationParams);
        System.debug('Payload IP: ' + JSON.serialize(ipPayload));
        
        if (ipPayload == null || ipPayload.isEmpty()) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-001', 'Failed to transform payload', 500)
            });
        }
        
        // Call Integration Procedure
        Map<String, Object> ipInput = ipPayload;
        Map<String, Object> ipOutput = new Map<String, Object>();
        Map<String, Object> ipOptions = new Map<String, Object>();
        
        try {
            // Call IP - FVU_IPCustomerDemographicInfo
            ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                'FVU_IPCustomerDemographicInfo',
                ipInput,
                ipOptions
            );
            
            // Parse IP response for PATCH
            Map<String, Object> ipResponse = parseIPResponsePatch(ipOutput, payload);
            return ipResponse;
            
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-629', 'IP execution error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Identifies the Consumer Account based on identification parameters
     * @param identificationParams Map with id, docNumber+docType, or email
     * @return Account record or null if not found
     */
    @TestVisible
    private Account identifyCustomerAccount(Map<String, Object> identificationParams) {
        
        List<Account> accounts = new List<Account>();
        
        try {
            // Option 1: Direct Salesforce ID
            if (identificationParams.containsKey('id')) {
                String accountId = (String) identificationParams.get('id');
                
                accounts = [
                    SELECT Id, Name, Phone, FVU_Email__c, FVU_OtherPhone__c, 
                           FVU_DocumentNumber__c, FVU_DocumentType__c,
                           vlocity_cmt__PrimaryContactId__c, RecordType.DeveloperName
                    FROM Account
                    WHERE Id = :accountId 
                      AND RecordType.DeveloperName = 'Consumer'
                    WITH USER_MODE
                    LIMIT 1
                ];
            }
            // Option 2: Document Number + Document Type
            else if (identificationParams.containsKey('docNumber') && identificationParams.containsKey('docType')) {
                String docNumber = (String) identificationParams.get('docNumber');
                String docType = (String) identificationParams.get('docType');
                
                accounts = [
                    SELECT Id, Name, Phone, FVU_Email__c, FVU_OtherPhone__c,
                           FVU_DocumentNumber__c, FVU_DocumentType__c,
                           vlocity_cmt__PrimaryContactId__c, RecordType.DeveloperName
                    FROM Account
                    WHERE FVU_DocumentNumber__c = :docNumber
                      AND FVU_DocumentType__c = :docType
                      AND RecordType.DeveloperName = 'Consumer'
                    WITH USER_MODE
                    LIMIT 1
                ];
            }
            // Option 3: Email
            else if (identificationParams.containsKey('email')) {
                String email = (String) identificationParams.get('email');
                
                accounts = [
                    SELECT Id, Name, Phone, FVU_Email__c, FVU_OtherPhone__c,
                           FVU_DocumentNumber__c, FVU_DocumentType__c,
                           vlocity_cmt__PrimaryContactId__c, RecordType.DeveloperName
                    FROM Account
                    WHERE FVU_Email__c = :email
                      AND RecordType.DeveloperName = 'Consumer'
                    WITH USER_MODE
                    LIMIT 1
                ];
            }
            
            return accounts.isEmpty() ? null : accounts[0];
            
        } catch (Exception e) {
            System.debug('Error identifying customer account: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Transforms TMF629 payload to existing IP format for POST
     * Handles the conversion from TMF standard to legacy format
     * @param tmfPayload Request in TMF format
     * @return Payload in IP format
     */
    @TestVisible
    private Map<String, Object> transformToIPFormat(Map<String, Object> tmfPayload) { 
        
        try {
            Map<String, Object> ipPayload = new Map<String, Object>();
            Map<String, Object> addressInformation = new Map<String, Object>();  
            Map<String, Object> customerInformation = new Map<String, Object>(); 
            List<Map<String, Object>> customerCharacteristics = new List<Map<String, Object>>();
            
            if (tmfPayload.containsKey('characteristic')) {
                List<Object> characteristics = (List<Object>) tmfPayload.get('characteristic');
                for (Object obj : characteristics) {
                    Map<String, Object> ch = (Map<String, Object>) obj;
                    if (ch.get('name') == 'AccountSource') {                  
                        customerInformation.put('origin', ch.get('value'));
                    }
                }
            }

            // tmfPayload: nodo Engaged Party
            if (tmfPayload.containsKey('engagedParty')) {
                Map<String, Object> engagedParty = (Map<String, Object>) tmfPayload.get('engagedParty');

                if (engagedParty.containsKey('characteristic')) {
                    List<Object> epChars = (List<Object>) engagedParty.get('characteristic');

                    for (Object obj : epChars) {
                        Map<String, Object> ch = (Map<String, Object>) obj;
                        String name = (String) ch.get('name');
                        Object value = ch.get('value');

                        if (name == 'FirstName') {
                            customerInformation.put('firstName', value);

                        } else if (name == 'LastName') {
                            customerInformation.put('lastName', value);

                        } else if (name == 'FVU_DocumentType__c') {
                            customerInformation.put('documentType', value);

                        } else if (name == 'FVU_DocumentNumber__c') {
                            customerInformation.put('documentNumber', value);

                        //HDU 702395: Se agregan FVU_SecondLastName__c,FVU_PersonalDataAgreementMethod__c,FVU_ExpeditionDate__c, FVU_PersonalDataAgreementDate__c 
                        //Como campos de customerCharacteristics.
                        } else if (name == 'FVU_SecondLastName__c'){ 
                            Map<String, Object> lastNameChar = new Map<String, Object>();
                            lastNameChar.put('name', 'FVU_SecondLastName__c');
                            lastNameChar.put('value', value);
                            customerCharacteristics.add(lastNameChar);
                            
                        } else if (name == 'FVU_PersonalDataAgreementMethod__c'){
                            Map<String, Object> AgreementMethodChar = new Map<String, Object>();
                            AgreementMethodChar.put('name', 'FVU_PersonalDataAgreementMethod__c');
                            AgreementMethodChar.put('value', value);
                            customerCharacteristics.add(AgreementMethodChar);
                            
                        } else if (name == 'FVU_ExpeditionDate__c'){
                            Map<String, Object> ExpeditionDateChar = new Map<String, Object>();
                            ExpeditionDateChar.put('name', 'FVU_ExpeditionDate__c');
                            ExpeditionDateChar.put('value', value);
                            customerCharacteristics.add(ExpeditionDateChar);
                            
                        } else if (name == 'FVU_PersonalDataAgreementDate__c'){ 
                            Map<String, Object> AgreementDateChar = new Map<String, Object>();
                            AgreementDateChar.put('name', 'FVU_PersonalDataAgreementDate__c');
                            AgreementDateChar.put('value', value);
                            customerCharacteristics.add(AgreementDateChar);
                        }
                    }
                }
            }

            // tmfPayload: nodo contactMedium
            if (tmfPayload.containsKey('contactMedium')) {
                List<Object> contactMediums = (List<Object>) tmfPayload.get('contactMedium');

                for (Object obj : contactMediums) {
                    Map<String, Object> cm = (Map<String, Object>) obj;
                    String type = (String) cm.get('@type');
                    String preferred = String.valueOf(cm.get('preferred'));

                    // Email
                    if (type == 'EmailContactMedium') {
                        customerInformation.put('email', cm.get('emailAddress'));
                        Map<String, Object> PreferredMethodMailChar = new Map<String, Object>();
                        if(preferred == 'true'){ //HDU 702395: Si correo es método preferido lo agregamos al nodo de customerCharacteristics
                            PreferredMethodMailChar.put('name', 'FVU_NotificationChoice__c');
                            PreferredMethodMailChar.put('value', 'Correo electrónico');
                            customerCharacteristics.add(PreferredMethodMailChar);
                        }
                    }
                    //HDU 702395:Si el preferido es Teléfono, lo agregamos al nodo de customerCharacteristics.
                    if(type == 'PhoneContactMedium' && preferred == 'true'){
                         Map<String, Object> PreferredMethodCallChar = new Map<String, Object>();
                         PreferredMethodCallChar.put('name', 'FVU_NotificationChoice__c');
                         PreferredMethodCallChar.put('value', 'SMS - Teléfono de contacto');
                         customerCharacteristics.add(PreferredMethodCallChar); 
                    }

                    // Phone
                    if (type == 'PhoneContactMedium' &&  cm.get('contactType') == 'Mobile') { 
                        Map<String, Object> phoneChar = new Map<String, Object>();
                        phoneChar.put('name', 'Phone');
                        phoneChar.put('value', cm.get('phoneNumber'));
                        customerCharacteristics.add(phoneChar);
                    }
                    // otherPhone
                    if (type == 'PhoneContactMedium' &&  cm.get('contactType') == 'otherPhone') { 
                        Map<String, Object> phoneChar = new Map<String, Object>();
                        phoneChar.put('name', 'otherPhone');
                        phoneChar.put('value', cm.get('phoneNumber'));
                        customerCharacteristics.add(phoneChar);
                    }
                    
                    // Address
                    if (type == 'GeographicAddressContactMedium') {
                        addressInformation.put('@type', cm.get('contactType'));
                        addressInformation.put('city', cm.get('city'));
                        addressInformation.put('state', cm.get('stateOrProvince'));
                        addressInformation.put('postalCode', cm.get('postCode'));
                        addressInformation.put('streetAndNumber', cm.get('street1'));

                        if (cm.containsKey('characteristic')) {
                            Map<String, Object> addrChar = (Map<String, Object>) cm.get('characteristic');
                            addressInformation.put('daneCode', addrChar.get('addressDaneCode'));
                            addressInformation.put('merId', addrChar.get('addressMerId'));
                            addressInformation.put('municipality', addrChar.get('addressMunicipality'));
                            addressInformation.put('addressType', addrChar.get('addressType'));
                            addressInformation.put('addressStatus', addrChar.get('addressStatus'));
                            addressInformation.put('addressExtract', addrChar.get('addressExtract'));
                            addressInformation.put('addressNode', addrChar.get('addressNode'));
                        }
                    }
                }
            }
            
            if (!customerCharacteristics.isEmpty()) {
                customerInformation.put('customerCharacteristics', customerCharacteristics);
            }

            ipPayload.put('customerInformation', customerInformation);
            ipPayload.put('addressInformation', addressInformation);
            return ipPayload;

        } catch (Exception e) {
            System.debug('Error transforming payload: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Transforms TMF629 PATCH payload to IP format for FVU_IPCustomerDemographicInfo
     * @param tmfPayload Request in TMF format
     * @param consumerAccount The identified consumer account (null if using email/docNumber+docType)
     * @param identificationParams Identification parameters from query
     * @return Payload in IP format
     */
    @TestVisible
    private Map<String, Object> transformToIPFormatPatch(Map<String, Object> tmfPayload, Account consumerAccount, Map<String, Object> identificationParams) {
        
        try {
            Map<String, Object> ipPayload = new Map<String, Object>();
            Map<String, Object> demographicData = new Map<String, Object>();
            
            // 1. Handle identification - docNumber+docType, email, or id (query account)
            if (identificationParams.containsKey('docNumber') && identificationParams.containsKey('docType')) {
                // Option A: Direct docNumber + docType from query params
                ipPayload.put('documentNumber', identificationParams.get('docNumber'));
                ipPayload.put('documentType', identificationParams.get('docType'));
                
            } else if (identificationParams.containsKey('email')) {
                // Option B: Only email (no documentNumber/documentType)
                ipPayload.put('email', identificationParams.get('email'));
                
            } else if (identificationParams.containsKey('id') && consumerAccount != null) {
                // Option C: Query account for docNumber + docType
                ipPayload.put('documentNumber', consumerAccount.FVU_DocumentNumber__c);
                ipPayload.put('documentType', consumerAccount.FVU_DocumentType__c);
            }
            
            // 2. Process contactMedium for phone and email
            if (tmfPayload.containsKey('contactMedium')) {
                List<Object> contactMediums = (List<Object>) tmfPayload.get('contactMedium');
                
                for (Object obj : contactMediums) {
                    Map<String, Object> cm = (Map<String, Object>) obj;
                    String type = (String) cm.get('@type');
                    
                    // Phone
                    if (type == 'PhoneContactMedium') {
                        String contactType = (String) cm.get('contactType');
                        if (contactType == 'phone') {
                            demographicData.put('phone', cm.get('phoneNumber'));
                        } else if (contactType == 'otherPhone') {
                            demographicData.put('otherPhone', cm.get('phoneNumber'));
                        }
                    }
                    
                    // Email (only add if not already in root level from identification)
                    if (type == 'EmailContactMedium' && !ipPayload.containsKey('email')) {
                        demographicData.put('email', cm.get('emailAddress'));
                    }
                }
            }
            
            // 3. Process engagedParty for address updates - only Billing or Service
            if (tmfPayload.containsKey('engagedParty')) {
                List<Object> engagedParties = (List<Object>) tmfPayload.get('engagedParty');
                
                // Filter to find only Billing or Service type
                Map<String, Object> addressEngagedParty = null;
                for (Object obj : engagedParties) {
                    Map<String, Object> ep = (Map<String, Object>) obj;
                    String epType = (String) ep.get('@type');
                    
                    if (epType == 'Billing' || epType == 'Service') {
                        addressEngagedParty = ep;
                        break; // Only process one (already validated there's only 1)
                    }
                    // Ignore Contact and other types
                }
                
                // If we found a Billing or Service engagedParty, process it
                if (addressEngagedParty != null) {
                    String epType = (String) addressEngagedParty.get('@type');
                    String action = (String) addressEngagedParty.get('action');
                    String epId = (String) addressEngagedParty.get('id');
                    
                    // Build address object
                    Map<String, Object> address = new Map<String, Object>();
                    address.put('@type', epType);
                    
                    // If modify, include the SF ID
                    if (action == 'modify' && String.isNotBlank(epId)) {
                        address.put('idSF', epId);
                    }
                    
                    // Find corresponding GeographicAddressContactMedium
                    if (tmfPayload.containsKey('contactMedium')) {
                        List<Object> contactMediums = (List<Object>) tmfPayload.get('contactMedium');
                        
                        for (Object cmObj : contactMediums) {
                            Map<String, Object> cm = (Map<String, Object>) cmObj;
                            String cmType = (String) cm.get('@type');
                            String contactType = (String) cm.get('contactType');
                            
                            if (cmType == 'GeographicAddressContactMedium' && contactType == epType) {
                                
                                // Map basic address fields
                                if (cm.containsKey('street1')) {
                                    address.put('streetAndNumber', cm.get('street1'));
                                }
                                if (cm.containsKey('city')) {
                                    address.put('city', cm.get('city'));
                                }
                                if (cm.containsKey('stateOrProvince')) {
                                    address.put('state', cm.get('stateOrProvince'));
                                }
                                if (cm.containsKey('postCode')) {
                                    address.put('postalCode', cm.get('postCode'));
                                }
                                
                                // Map characteristic fields (extendedAddressInfo)
                                if (cm.containsKey('characteristic')) {
                                    List<Object> characteristics = (List<Object>) cm.get('characteristic');
                                    
                                    for (Object chObj : characteristics) {
                                        Map<String, Object> ch = (Map<String, Object>) chObj;
                                        
                                        if (ch.get('name') == 'extendedAddressInfo' && ch.get('valueType') == 'object') {
                                            Map<String, Object> value = (Map<String, Object>) ch.get('value');
                                            
                                            if (value.containsKey('addressNode')) {
                                                address.put('addressNode', String.valueOf(value.get('addressNode')));
                                            }
                                            if (value.containsKey('daneCode')) {
                                                address.put('daneCode', String.valueOf(value.get('daneCode')));
                                            }
                                            if (value.containsKey('addressDaneCode')) {
                                                address.put('daneCode', String.valueOf(value.get('addressDaneCode')));
                                            }
                                            if (value.containsKey('merId')) {
                                                address.put('merId', String.valueOf(value.get('merId')));
                                            }
                                            if (value.containsKey('addressMerId')) {
                                                address.put('merId', String.valueOf(value.get('addressMerId')));
                                            }
                                            if (value.containsKey('municipality')) {
                                                address.put('municipality', String.valueOf(value.get('municipality')));
                                            }
                                            if (value.containsKey('addressMunicipality')) {
                                                address.put('municipality', String.valueOf(value.get('addressMunicipality')));
                                            }
                                            if (value.containsKey('status')) {
                                                address.put('addressStatus', String.valueOf(value.get('status')));
                                            }
                                            if (value.containsKey('addressStatus')) {
                                                address.put('addressStatus', String.valueOf(value.get('addressStatus')));
                                            }
                                            if (value.containsKey('addressType')) {
                                                address.put('addressType', String.valueOf(value.get('addressType')));
                                            }
                                            if (value.containsKey('addressExtract')) {
                                                address.put('addressExtract', String.valueOf(value.get('addressExtract')));
                                            }
                                            if (value.containsKey('externalId')) {
                                                address.put('externalId', String.valueOf(value.get('externalId')));
                                            }
                                        }
                                    }
                                }
                                
                                break;
                            }
                        }
                    }
                    
                    demographicData.put('address', address);
                }
            }
            
            ipPayload.put('demographicData', demographicData);
            return ipPayload;
            
        } catch (Exception e) {
            System.debug('Error transforming PATCH payload: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Parses Integration Procedure response for POST
     * @param ipOutput Output from Integration Procedure
     * @param payload Output from Integration Procedure
     * @return IPResponse wrapper object
     */
    @TestVisible
    private Map<String, Object> parseIPResponse(Map<String, Object> ipOutput, Map<String, Object> payload ) {
        
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> body = new Map<String, Object>();
        
        // Extraer códigos base
        String code = ipOutput.containsKey('code') ? String.valueOf(ipOutput.get('code')) : null;
        String status = ipOutput.containsKey('status') ? String.valueOf(ipOutput.get('status')) : null;
        String message = ipOutput.containsKey('message') ? String.valueOf(ipOutput.get('message')) : null;

        try {
      
            if (code == '200' && status == 'Success') {

                body.put('@type', payload.get('@type'));
                body.put('name', payload.get('name'));
                body.put('status', payload.get('status'));
                String accountId = null;
                String href = null;
                String keyString = 'sobjects/';

                if (ipOutput.containsKey('attributes')) {
                    Map<String, Object> attributes = (Map<String, Object>)ipOutput.get('attributes');
                    // id
                    if (attributes.containsKey('Id')) {
                        accountId = String.valueOf(attributes.get('Id'));
                        body.put('id', String.valueOf(attributes.get('Id')));
                    }
                    // href
                    if (attributes.containsKey('href')) {
                        href = String.valueOf(attributes.get('href'));
                      

                        body.put('href', String.valueOf(attributes.get('href')));
                    }            
                }

                // Limpiar la ruta 'href' /services/data/vn.n/sobjects/
                Integer endPos = href.indexOf(keyString) + keyString.length();
                String baseRoute = href.substring(0, endPos);

                // Account
                List<Map<String, Object>> accounts = new List<Map<String, Object>>();
                Map<String, Object> addressOutput = (Map<String, Object>) ipOutput.get('address');
                Map<String, Object> serviceAcc = new Map<String, Object>();
                Map<String, Object> billingAcc = new Map<String, Object>();

                // Account get data
                Account acc;
                List<Id> accId = new list<Id>();
                List<Account> childAccounts = new List<Account>();
                String billingAccountName;
                String billingAccountDescription;
                String serviceAccountName;
                String serviceAccountDescription;
                Id primaryContactId;
                 
                if (String.isNotBlank((String) addressOutput.get('idAddressService'))) { 
                    accId.add(String.valueOf(addressOutput.get('idAddressService')));
                }
                if (String.isNotBlank((String) addressOutput.get('idAddressBilling'))) {    
                    accId.add(String.valueOf(addressOutput.get('idAddressBilling')));
                }

                // Consultar cuentas
                List<Account> accList = [
                    SELECT Id,
                        vlocity_cmt__PrimaryContactId__r.Id,
                        (SELECT Id, Name, Description
                            FROM ChildAccounts
                            WHERE Id IN :accId)
                    FROM Account
                    WHERE RecordType.DeveloperName = 'Consumer'
                    AND Id = :accountId
                    WITH USER_MODE
                ];

                if (!accList.isEmpty()) {
                    acc = accList[0];
                    primaryContactId = acc.vlocity_cmt__PrimaryContactId__r != null ? acc.vlocity_cmt__PrimaryContactId__r.Id : null;

                    if (acc.ChildAccounts != null && !acc.ChildAccounts.isEmpty()) {
                        childAccounts.addAll(acc.ChildAccounts);

                        // Mapeo de nombres Billing / Service
                        for (Account child : acc.ChildAccounts) {
                            
                            if (child.Id == addressOutput.get('idAddressBilling')) {
                                billingAccountName = child.Name;
                                billingAccountDescription = child.Description != null ? child.Description: '';
                            }

                            if(child.Id == addressOutput.get('idAddressService')) {
                                serviceAccountName = child.Name;
                                serviceAccountDescription = child.Description != null ? child.Description : '';
                            }
                        }
                    }
                }

                // Acc Service
                if (String.isNotBlank((String) addressOutput.get('idAddressService'))) { 
                    serviceAcc.put('@type', 'AccountRef'); 
                    serviceAcc.put('id', addressOutput.get('idAddressService'));
                    serviceAcc.put('href', baseRoute +'account/'+ addressOutput.get('idAddressService')); 
                    serviceAcc.put('name', serviceAccountName );
                    serviceAcc.put('description', serviceAccountDescription); 
                    serviceAcc.put('@referredType', 'Service');
                    accounts.add(serviceAcc);
                    accId.add(String.valueOf(addressOutput.get('idAddressService')));
                }
                // Acc Billing
                if (String.isNotBlank((String) addressOutput.get('idAddressBilling'))) {    
                    billingAcc.put('@type', 'AccountRef'); 
                    billingAcc.put('id', addressOutput.get('idAddressBilling'));
                    billingAcc.put('href', baseRoute +'account/'+ addressOutput.get('idAddressBilling')); 
                    billingAcc.put('name', billingAccountName ); 
                    billingAcc.put('description', billingAccountDescription); 
                    billingAcc.put('@referredType', 'Billing');
                    accounts.add(billingAcc);
                    accId.add(String.valueOf(addressOutput.get('idAddressBilling')));
                }
                body.put('account', accounts);
              
                // engagedParty
                Map<String, Object> contactOutput = (Map<String, Object>) payload.get('engagedParty');
                Map<String, Object> engagedParty = new Map<String, Object>();
                engagedParty.put('@type', contactOutput.get('@type') ); 
                engagedParty.put('name', contactOutput.get('name'));
                engagedParty.put('role', contactOutput.get('role'));
                engagedParty.put('id', primaryContactId); 
                engagedParty.put('href', baseRoute +'contact/'+ primaryContactId); 
                body.put('engagedParty', engagedParty);
                
                // contactMedium
                List<Map<String, Object>> result = new List<Map<String, Object>>();
                List<Object> contactMediums = (List<Object>) payload.get('contactMedium');

                for (Object obj : contactMediums) {
                    Map<String, Object> cm = (Map<String, Object>) obj;
                    String type = (String) cm.get('@type');

                    if (type == 'EmailContactMedium') {
                        Map<String, Object> email = new Map<String, Object>();
                        email.put('@type', type);
                        email.put('contactType', cm.get('contactType'));
                        email.put('emailAddress', cm.get('emailAddress'));
                        result.add(email);
                    }

                    if (type == 'GeographicAddressContactMedium') {
                        Map<String, Object> addr = new Map<String, Object>();
                        addr.put('@type', type);
                        addr.put('contactType', cm.get('contactType'));
                        addr.put('city', cm.get('city'));
                        addr.put('street1', cm.get('street1'));
                        result.add(addr);
                    }
                }
                body.put('contactMedium', result);
                response.put('body', body);
                response.put('statusCode', 200);
        
            }else{
                body.put('code', code);
                body.put('statusmessage', (code == '400') ? 'BAD_REQUEST' : 'INTERNAL_SERVER_ERROR');
                body.put('message', message);
                response.put('body', body);
                response.put('statusCode', (code != null && code.isNumeric()) ? Integer.valueOf(code) : 500);
            }
        } catch (Exception e) {
            body.put('code', '500');
            body.put('statusmessage', 'INTERNAL_SERVER_ERROR'); 
            body.put('message', 'Error procesando respuesta: ' + e.getMessage());
            response.put('body', body); 
            response.put('statusCode', 500);
        }
        
        return response;
    }

    /**
     * @description Parses Integration Procedure response for PATCH
     * @param ipOutput Output from Integration Procedure
     * @param payload Original TMF payload
     * @return Response object
     */
    @TestVisible
    private Map<String, Object> parseIPResponsePatch(Map<String, Object> ipOutput, Map<String, Object> payload) {
        
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> body = new Map<String, Object>();
        
        // Extract IP response codes
        Integer responseCode = ipOutput.containsKey('responseCode') ? Integer.valueOf(ipOutput.get('responseCode')) : null;
        String message = ipOutput.containsKey('message') ? String.valueOf(ipOutput.get('message')) : null;
        
        try {
            if (responseCode == 200 && message == 'OK') {
                
                // Start with the original payload
                body.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(payload)));
                String engagedPartyType = '';
                List<Object> engagedPartyList = (List<Object>) body.get('engagedParty');
                if(engagedPartyList != null && !engagedPartyList.isEmpty()) {
                   Map<String, Object> engagedParty = (Map<String, Object>) engagedPartyList[0];
                   engagedPartyType = (String) engagedParty.get('@type');
                }

                
                // Remove internal fields that shouldn't be in response
                body.remove('identificationParams');
                body.remove('consumerAccountId');
                body.remove('consumerAccountDocNumber');
                body.remove('consumerAccountDocType');
                
                // Query the Consumer Account for additional fields
                String consumerAccountId = (String) payload.get('consumerAccountId');
                
                if (String.isNotBlank(consumerAccountId)) {
                    List<Account> accounts = [
                        SELECT Id, CreatedDate, LastModifiedDate, Name
                        FROM Account
                        WHERE Id = :consumerAccountId
                        WITH USER_MODE
                        LIMIT 1
                    ];
                    
                    if (!accounts.isEmpty()) {
                        Account consumerAccount = accounts[0];
                        
                        // Add/Update required fields
                        body.put('id', consumerAccount.Id);
                        body.put('href', '/services/apexrest/tmforum/v4/customer/' + consumerAccount.Id);
                        body.put('name', consumerAccount.Name);
                        
                        // Add dates in ISO format
                        if (consumerAccount.CreatedDate != null) {
                            body.put('createdDate', consumerAccount.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                        }
                        if (consumerAccount.LastModifiedDate != null) {
                            body.put('lastModifiedDate', consumerAccount.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                        }
                    }
                } else {
                    // If we don't have the account ID from previous step, try to get it from identification params
                    Map<String, Object> identificationParams = (Map<String, Object>) payload.get('identificationParams');
                    
                    if (identificationParams != null) {
                        Account consumerAccount = identifyCustomerAccount(identificationParams);
                        
                        if (consumerAccount != null) {
                            // Query for dates
                            List<Account> accounts = [
                                SELECT Id, CreatedDate, LastModifiedDate, Name
                                FROM Account
                                WHERE Id = :consumerAccount.Id
                                WITH USER_MODE
                                LIMIT 1
                            ];
                            
                            if (!accounts.isEmpty()) {
                                Account acc = accounts[0];
                                
                                body.put('id', acc.Id);
                                body.put('href', '/services/apexrest/tmforum/v4/customer/' + acc.Id);
                                body.put('name', acc.Name);
                                
                                if (acc.CreatedDate != null) {
                                    body.put('createdDate', acc.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                                }
                                if (acc.LastModifiedDate != null) {
                                    body.put('lastModifiedDate', acc.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                                }
                            }
                        }
                    }
                }
                //BUG 756695 08/05/2026
                if(ipOutput.containsKey('idAccount')){
                    String id = (String)ipOutput.get('idAccount');
                    List<Account> accounts = [SELECT Id, Name
                                              FROM Account
                                              WHERE Id = : id
                                              WITH USER_MODE
                                              LIMIT 1
                    ];
                    if(!accounts.isEmpty()){
                        List<Map<String, Object>> accountList = new List<Map<String, Object>>();
                        for(Account acc : accounts){
                            Map<String, Object> accountMap = new Map<String, Object>();
                            accountMap.put('@type', engagedPartyType);
                            accountMap.put('id', acc.Id);
                            accountMap.put('href','/services/apexrest/tmforum/v4/customer'+'/'+ acc.Id);
                            accountMap.put('name', acc.Name);
                            accountMap.put('@referredType', 'Account');
                            accountList.add(accountMap);
                        }
                        body.put('account', accountList);
                    }

                }
                response.put('body', body);
                response.put('statusCode', 200);
                
            } else {
                // Error from IP - return user-friendly error without mentioning IP
                body.put('code', String.valueOf(responseCode != null ? responseCode : 500));
                body.put('statusmessage', getStatusMessage(responseCode));
                body.put('message', message != null ? message : 'An error occurred while updating customer');
                
                response.put('body', body);
                response.put('statusCode', responseCode != null ? responseCode : 500);
            }
            
        } catch (Exception e) {
            body.put('code', '500');
            body.put('statusmessage', 'INTERNAL_SERVER_ERROR');
            body.put('message', 'Error processing update response: ' + e.getMessage());
            response.put('body', body);
            response.put('statusCode', 500);
        }
        
        return response;
    }
    
    /**
     * @description Returns standard HTTP status message based on code
     * @param statusCode HTTP status code
     * @return Status message
     */
    @TestVisible
    private String getStatusMessage(Integer statusCode) {
        if (statusCode == null) {
            return 'INTERNAL_SERVER_ERROR';
        }
        
        switch on statusCode {
            when 200 {
                return 'OK';
            }
            when 400 {
                return 'BAD_REQUEST';
            }
            when 404 {
                return 'NOT_FOUND';
            }
            when 500 {
                return 'INTERNAL_SERVER_ERROR';
            }
            when else {
                return 'ERROR';
            }
        }
    }
    
    /**
     * @description Builds error response
     */
    @TestVisible
    private Map<String, Object> buildErrorResponse(List<TMFError> errors) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'error');
        
        // Convert TMFError objects to Maps for serialization
        List<Map<String, Object>> errorMaps = new List<Map<String, Object>>();
        for (TMFError error : errors) {
            errorMaps.add(error.toMap());
        }
        
        response.put('errors', errorMaps);
        response.put('timestamp', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        return response;
    }  

    /**
     * @description Inner class to wrap IP response parsing
     */
    public class IPResponse {
        public Boolean success { get; set; }
        public String caseId { get; set; }
        public String caseNumber { get; set; }
        public String errorMessage { get; set; }
        public String errorCode { get; set; }
        public Integer httpStatus { get; set; }
        
        public IPResponse() {
            this.success = false;
        }
    }
}