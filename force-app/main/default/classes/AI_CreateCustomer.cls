@RestResource(urlMapping='/AI_CreateCustomer')
global with sharing class AI_CreateCustomer {
    
    private static final String ACTION_CREATE_CUSTOMER = 'Create Customer';

    private static final String OBJECT_ACCOUNT = 'Account'; 
    private static final String OBJECT_CONTACT = 'Contact';

    private static final String RECORD_TYPE_ACCOUNT_CONSUMER = 'Consumer';
    private static final String RECORD_TYPE_CONTACT_CLIENTE = 'FVU_Consumer';

    private static final String METADATA_DEVELOPER_NAME_CREATE_CUSTOMER_ACCOUNT = 'Service_Create_Customer_Account';
    private static final String HREF_BASE_ACCOUNT = '/services/data/v57.0/sobjects/Account/';

    private static final String EMPTY_BODY_MESSAGE = 'Request body cannot be empty';
    private static final String PHONE_REQUIRED_MESSAGE = 'Phone number is required in customerCharacteristics';
    private static final String CUSTOMER_INFORMATION_REQUIRED_MESSAGE = 'customerInformation is required';
    private static final String INVALID_JSON_FORMAT_MESSAGE = 'Invalid JSON format: ';
    private static final String UNEXPECTED_ERROR_MESSAGE = 'An unexpected error occurred: ';
    private static final String RECORD_TYPE_NOT_FOUND_MESSAGE = 'RecordType not found: ';

    private static final String HTTP_STATUS_400 = '400';
    private static final String HTTP_STATUS_500 = '500';
    private static final String HTTP_STATUS_200 = '200';
    
    private static final String STATUS_SUCCESS = 'Success';
    private static final String STATUS_ERROR = 'Error';
    private static final String STATUS_FAIL = 'Fail';
    
    @TestVisible
    private static Map<String, Object> mockOutMap = null;
        
    @HttpPost
    global static void createCustomer() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        try {
            if (String.isBlank(req.requestBody?.toString())) {
                sendErrorResponse(res, HTTP_STATUS_400, EMPTY_BODY_MESSAGE);
                return;
            }

            Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
                req.requestBody.toString()
            );
            
            Map<String, Object> customerInformation = extractCustomerInformation(requestBody);
            
            if (customerInformation.isEmpty()) {
                sendErrorResponse(res, HTTP_STATUS_400, CUSTOMER_INFORMATION_REQUIRED_MESSAGE);
                return;
            }

            if (!hasPhoneInCustomerCharacteristics(customerInformation)) {
                sendErrorResponse(res, HTTP_STATUS_400, PHONE_REQUIRED_MESSAGE);
                return;
            }
            
            Map<String, String> recordTypeIds = validateAndGetRecordTypes();
            Map<String, Object> inputMap = buildInputMap(customerInformation, recordTypeIds);

            Map<String, Object> outMap = new Map<String, Object>();
            Map<String, Object> options = new Map<String, Object>();

            if (Test.isRunningTest() && mockOutMap != null) {
                outMap = mockOutMap;
            } else {
                FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
            }

            res.responseBody = Blob.valueOf(buildResponseFromOutMap(outMap));
            res.statusCode = Integer.valueOf(determineStatusCode(outMap));
            
        } catch (JSONException e) {
            sendErrorResponse(res, HTTP_STATUS_400, INVALID_JSON_FORMAT_MESSAGE + e.getMessage());
        } catch (Exception e) {
            sendErrorResponse(res, HTTP_STATUS_500, UNEXPECTED_ERROR_MESSAGE + e.getMessage() + ' - Line: ' + e.getLineNumber());
        }
    }

    private static void sendErrorResponse(RestResponse res, String code, String message) {
        res.statusCode = Integer.valueOf(code);
        res.responseBody = Blob.valueOf(JSON.serialize(buildErrorResponse(code, message)));
    }

    private static Map<String, Object> buildErrorResponse(String code, String message) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('code', code);
        response.put('address', processAddress());
        response.put('attributes', processAttributes(false, ''));
        response.put('message', message);
        response.put('status', STATUS_ERROR);
        return response;
    }

    /**
     * @description Creates an empty address map structure
     * Returns empty strings for address IDs as they are not populated during AI customer creation
     * Address creation happens separately via DataRaptors if needed
     * @return Map<String, Object> Address map with empty idAddressService and idAddressBilling
     */
    private static Map<String, Object> processAddress() {
        Map<String, Object> address = new Map<String, Object>();
        address.put('idAddressService', '');
        address.put('idAddressBilling', '');
        return address;
    }

    private static Map<String, Object> processAttributes(Boolean isSuccess, String accountId) {
        Map<String, Object> attributes = new Map<String, Object>();
        if (isSuccess && String.isNotBlank(accountId)) {
            attributes.put('Id', accountId);
            attributes.put('href', HREF_BASE_ACCOUNT + accountId);
            attributes.put('type', OBJECT_ACCOUNT);
        } else {
            attributes.put('Id', '');
            attributes.put('href', '');
            attributes.put('type', '');
        }
        return attributes;
    }

    private static Map<String, Object> extractCustomerInformation(Map<String, Object> requestBody) {
        if (requestBody.containsKey('customerInformation')) {
            return (Map<String, Object>) requestBody.get('customerInformation');
        }
        return new Map<String, Object>();
    }

    private static Boolean hasPhoneInCustomerCharacteristics(Map<String, Object> customerInformation) {
        if (!customerInformation.containsKey('customerCharacteristics')) {
            return false;
        }
        
        Object characteristicsObj = customerInformation.get('customerCharacteristics');
        if (!(characteristicsObj instanceof List<Object>)) {
            return false;
        }
        
        List<Object> characteristics = (List<Object>) characteristicsObj;
        for (Object characteristicObj : characteristics) {
            if (characteristicObj instanceof Map<String, Object>) {
                Map<String, Object> characteristic = (Map<String, Object>) characteristicObj;
                Object nameObj = characteristic.get('name');
                if (nameObj != null && String.valueOf(nameObj).equalsIgnoreCase('Phone')) {
                    Object valueObj = characteristic.get('value');
                    if (valueObj != null && String.isNotBlank(String.valueOf(valueObj))) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    }

    private static Map<String, String> validateAndGetRecordTypes() {        
        return new Map<String, String>{
            'account' => getRecordTypeId(OBJECT_ACCOUNT, RECORD_TYPE_ACCOUNT_CONSUMER),
            'contact' => getRecordTypeId(OBJECT_CONTACT, RECORD_TYPE_CONTACT_CLIENTE)
        };
    }
        
    private static String getRecordTypeId(String sObjectType, String recordTypeName) {
        Schema.SObjectType sObjectTypeObj = Schema.getGlobalDescribe().get(sObjectType);

        Schema.DescribeSObjectResult describeResult = sObjectTypeObj?.getDescribe();
        Schema.RecordTypeInfo recordTypeInfo = describeResult?.getRecordTypeInfosByDeveloperName()?.get(recordTypeName);
        return recordTypeInfo?.getRecordTypeId();
    }
    
    private static Map<String, Object> buildInputMap(Map<String, Object> customerInformation, Map<String, String> recordTypeIds) {
        return new Map<String, Object>{
            'jsonAll' => customerInformation,
            'recordTypeAccount' => recordTypeIds.get('account'),
            'recordTypeContact' => recordTypeIds.get('contact'),
            'fieldsRequired' => getRequiredFields(),
            'action' => ACTION_CREATE_CUSTOMER
        };
    }
    
    private static String getRequiredFields() {
        FVU_TMFFieldsInsertCustomer__mdt metadataRecord = FVU_TMFFieldsInsertCustomer__mdt.getInstance(METADATA_DEVELOPER_NAME_CREATE_CUSTOMER_ACCOUNT);
        if (metadataRecord != null && String.isNotBlank(metadataRecord.FVU_FieldsRequiredService__c)) {
            return metadataRecord.FVU_FieldsRequiredService__c;
        }
        return '';
    }
    
    private static String buildResponseFromOutMap(Map<String, Object> outMap) {
        Map<String, Object> result = new Map<String, Object>();
        String status = (String) outMap.get('status');
        Boolean isSuccess = status?.equalsIgnoreCase(STATUS_SUCCESS);
        String accountId = (String) outMap.get('accountId');
        
        result.put('code', determineStatusCode(outMap));
        result.put('attributes', processAttributes(isSuccess, accountId));
        result.put('address', processAddress());
        result.put('message', outMap.get('message'));
        result.put('status', isSuccess ? STATUS_SUCCESS : STATUS_ERROR);
     
        return JSON.serialize(result);
    }

    private static String determineStatusCode(Map<String, Object> outMap) {
        String status = (String) outMap.get('status');
        if (status == STATUS_SUCCESS) {
            return HTTP_STATUS_200;
        } else if (status.contains(STATUS_FAIL)) {
            return HTTP_STATUS_400;
        }
        return HTTP_STATUS_500;
    }
}