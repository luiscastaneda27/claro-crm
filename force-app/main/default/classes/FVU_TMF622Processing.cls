/**
 * @description Processing class for TMF622 Product Order Management API
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
public with sharing class FVU_TMF622Processing extends FVU_TMFBase {
    
    private static final String API_NAME = 'TMF622';
    
    /**
     * @description Constructor
     */
    public FVU_TMF622Processing() {
        super(API_NAME);
    }
    
    /**
     * @description Main request processor - orchestrates all operations
     * @param operation HTTP operation (POST, GET, PATCH, DELETE)
     * @param payload Request payload
     * @return Response object
     */
    public override Object processRequest(String operation, Map<String, Object> payload) {
        
        // 1. Validate request
        ValidationResult validationResult = validateRequest(operation, payload);
        
        if (!validationResult.isValid) {
            return buildErrorResponse(validationResult.errors);
        }
        
        // 2. Custom validation for productOrderItem position consistency (POST only)
        if (operation == 'POST') {
            ValidationResult positionValidation = validateProductOrderItemPositions(payload);
            if (!positionValidation.isValid) {
                return buildErrorResponse(positionValidation.errors);
            }
        }
        
        // 3. Route to appropriate handler
        try {
            switch on operation {
                when 'POST' {
                    return createProductOrder(payload);
                }
                /*when 'GET' {
                    return retrieveProductOrders(payload);
                }
                when 'PATCH' {
                    return updateProductOrder(payload);
                }*/
                when else {
                    return buildErrorResponse(new List<TMFError>{
                        buildError('TMF-405-001', 'Method not allowed', 405)
                    });
                }
            }
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-002', 'Processing error: ' + e.getMessage(), 500)
            });
        }
    }
    
    /**
     * @description Validates position consistency across productOrderItems
     * 
     * Rules:
     * - Products with different productCode CANNOT have the same position
     * - Products with the same productCode MUST have the same position
     * - Validations do NOT apply to promotions (items with @type containing "promotion")
     * 
     * @param payload Request payload
     * @return ValidationResult with errors if validation fails
     */
    @TestVisible
    private ValidationResult validateProductOrderItemPositions(Map<String, Object> payload) {
        ValidationResult result = new ValidationResult();
        
        if (!payload.containsKey('productOrderItem')) {
            return result; // No items to validate
        }
        
        List<Object> productOrderItems = (List<Object>)payload.get('productOrderItem');
        if (productOrderItems == null || productOrderItems.isEmpty()) {
            return result;
        }
        
        // Map: productCode -> Set of positions found
        Map<String, Set<String>> productCodeToPositions = new Map<String, Set<String>>();
        
        // Map: position -> Set of productCodes found
        Map<String, Set<String>> positionToProductCodes = new Map<String, Set<String>>();
        
        // First pass: collect all productCode-position pairs (skip promotions)
        for (Integer i = 0; i < productOrderItems.size(); i++) {
            Map<String, Object> item = (Map<String, Object>)productOrderItems[i];
            
            // Check if this is a promotion (skip validation)
            Boolean isPromotion = false;
            String productCode = null;
            String position = null;
            
            // Extract productCode and check if promotion
            if (item.containsKey('productOffering')) {
                Map<String, Object> productOffering = (Map<String, Object>)item.get('productOffering');
                
                if (productOffering.containsKey('id')) {
                    productCode = String.valueOf(productOffering.get('id'));
                }
                
                if (productOffering.containsKey('@type')) {
                    String offeringType = String.valueOf(productOffering.get('@type'));
                    isPromotion = offeringType.toLowerCase().contains('promotion');
                }
            }
            
            // Skip promotions
            if (isPromotion) {
                continue;
            }
            
            // Extract position from product.productCharacteristic
            if (item.containsKey('product')) {
                Map<String, Object> product = (Map<String, Object>)item.get('product');
                if (product.containsKey('productCharacteristic')) {
                    List<Object> characteristics = (List<Object>)product.get('productCharacteristic');
                    
                    for (Object charObj : characteristics) {
                        Map<String, Object> characteristic = (Map<String, Object>)charObj;
                        if (characteristic.get('name') == 'position') {
                            position = String.valueOf(characteristic.get('value'));
                            break;
                        }
                    }
                }
            }
            
            // Only validate if we have both productCode and position
            if (String.isNotBlank(productCode) && String.isNotBlank(position)) {
                
                // Track productCode -> positions
                if (!productCodeToPositions.containsKey(productCode)) {
                    productCodeToPositions.put(productCode, new Set<String>());
                }
                productCodeToPositions.get(productCode).add(position);
                
                // Track position -> productCodes
                if (!positionToProductCodes.containsKey(position)) {
                    positionToProductCodes.put(position, new Set<String>());
                }
                positionToProductCodes.get(position).add(productCode);
            }
        }
        
        // Second pass: validate rules and report errors with indices
        for (Integer i = 0; i < productOrderItems.size(); i++) {
            Map<String, Object> item = (Map<String, Object>)productOrderItems[i];
            
            // Skip promotions
            Boolean isPromotion = false;
            String productCode = null;
            String position = null;
            
            if (item.containsKey('productOffering')) {
                Map<String, Object> productOffering = (Map<String, Object>)item.get('productOffering');
                
                if (productOffering.containsKey('id')) {
                    productCode = String.valueOf(productOffering.get('id'));
                }
                
                if (productOffering.containsKey('@type')) {
                    String offeringType = String.valueOf(productOffering.get('@type'));
                    isPromotion = offeringType.toLowerCase().contains('promotion');
                }
            }
            
            if (isPromotion) {
                continue;
            }
            
            // Extract position
            if (item.containsKey('product')) {
                Map<String, Object> product = (Map<String, Object>)item.get('product');
                if (product.containsKey('productCharacteristic')) {
                    List<Object> characteristics = (List<Object>)product.get('productCharacteristic');
                    
                    for (Object charObj : characteristics) {
                        Map<String, Object> characteristic = (Map<String, Object>)charObj;
                        if (characteristic.get('name') == 'position') {
                            position = String.valueOf(characteristic.get('value'));
                            break;
                        }
                    }
                }
            }
            
            if (String.isBlank(productCode) || String.isBlank(position)) {
                continue;
            }
            
            // RULE 1: Products with same productCode MUST have same position
            Set<String> positions = productCodeToPositions.get(productCode);
            if (positions.size() > 1) {
                result.addError(buildError(
                    'TMF-400-030',
                    'productOrderItem[' + i + ']: Products with same productCode "' + productCode + 
                    '" must have the same position. Found positions: ' + String.join(new List<String>(positions), ', '),
                    400
                ));
            }
            
            // RULE 2: Products with different productCode CANNOT have same position
            Set<String> productCodes = positionToProductCodes.get(position);
            if (productCodes.size() > 1) {
                result.addError(buildError(
                    'TMF-400-031',
                    'productOrderItem[' + i + ']: Products with different productCodes cannot share position "' + position + 
                    '". Found productCodes: ' + String.join(new List<String>(productCodes), ', '),
                    400
                ));
            }
        }
        
        return result;
    }
    
    /**
     * @description Creates a new Product Order (Order) via existing Integration Procedure
     * @param payload Product Order data in TMF format
     * @return Created order with ID and href
     */
    @TestVisible
    private Object createProductOrder(Map<String, Object> payload) {
        
        // Transform TMF payload to IP format
        Map<String, Object> ipPayload = transformToIPFormat(payload);
        System.debug('Payload IP: '+JSON.serialize(ipPayload));
        
        if (ipPayload == null) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-003', 'Failed to transform payload', 500)
            });
        }
        
        // Call existing Integration Procedure
        Map<String, Object> ipInput = ipPayload;
        Map<String, Object> ipOutput = new Map<String, Object>();
        Map<String, Object> ipOptions = new Map<String, Object>();
        
        try {
            // Call IP using vlocity_cmt namespace
            ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                'FVU_CreateOrder',
                ipInput,
                ipOptions
            );
            
            System.debug('Response IP: '+JSON.serialize(ipOutput));
            // Parse IP response
            IPResponse ipResponse = parseIPResponse(ipOutput);
            
            if (!ipResponse.success) {
                return buildErrorResponse(new List<TMFError>{
                    buildError(ipResponse.errorCode, ipResponse.errorMessage, ipResponse.httpStatus)
                });
            }
            
            // Build TMF response from Order ID
            return buildTMFResponseFromIP(ipResponse.orderId, ipResponse.orderNumber, ipResponse.href, payload);
            
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-005', 'IP execution error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Transforms TMF622 payload to FVU_CreateOrder IP format
     * Handles conversion from TMF Product Order standard to legacy IP format
     * @param tmfPayload Request in TMF622 format
     * @return Payload in FVU_CreateOrder IP format
     */
    @TestVisible
    private Map<String, Object> transformToIPFormat(Map<String, Object> tmfPayload) {
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        try {
            // 1. Map category → @type
            if (tmfPayload.containsKey('category')) {
                ipPayload.put('@type', tmfPayload.get('category'));
            }
            
            // 2. Map externalId[0].id → storeOrderId
            if (tmfPayload.containsKey('externalId')) {
                List<Object> externalIds = (List<Object>)tmfPayload.get('externalId');
                if (!externalIds.isEmpty()) {
                    Map<String, Object> firstExternalId = (Map<String, Object>)externalIds[0];
                    if (firstExternalId.containsKey('id')) {
                        ipPayload.put('storeOrderId', firstExternalId.get('id'));
                    }
                }
            }
            
            // 3. Map channel[0].channel.name → channel
            if (tmfPayload.containsKey('channel')) {
                List<Object> channels = (List<Object>)tmfPayload.get('channel');
                if (!channels.isEmpty()) {
                    Map<String, Object> firstChannel = (Map<String, Object>)channels[0];
                    if (firstChannel.containsKey('channel')) {
                        Map<String, Object> channelObj = (Map<String, Object>)firstChannel.get('channel');
                        if (channelObj.containsKey('name')) {
                            ipPayload.put('channel', channelObj.get('name'));
                        }
                    }
                }
            }
            
            // 4. Process relatedParty array
            if (tmfPayload.containsKey('relatedParty')) {
                processRelatedParties(tmfPayload, ipPayload);
            }
            
            // 5. Process characteristic array
            if (tmfPayload.containsKey('characteristic')) {
                processCharacteristics(tmfPayload, ipPayload);
            }
            
            // 6. Process payment array → orderPayments
            if (tmfPayload.containsKey('payment')) {
                processPayments(tmfPayload, ipPayload);
            }
            
            // 7. Process productOrderItem array → products
            if (tmfPayload.containsKey('productOrderItem')) {
                processProductOrderItems(tmfPayload, ipPayload);
            }
            
            // 8. Process quote array → financingDetails
            if (tmfPayload.containsKey('quote')) {
                processQuote(tmfPayload, ipPayload);
            }
            
            return ipPayload;
            
        } catch (Exception e) {
            System.debug('Error transforming payload: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return null;
        }
    }

    /**
     * @description Processes relatedParty array and maps to IP fields
     * Handles: ConsumerAccount, BillingAccount, ServiceAccount, ExternalAccount91/92/93
     */
    @TestVisible
    private void processRelatedParties(Map<String, Object> tmfPayload, Map<String, Object> ipPayload) {
        List<Object> relatedParties = (List<Object>)tmfPayload.get('relatedParty');
        List<Map<String, Object>> orderCharacteristics = new List<Map<String, Object>>();
        
        for (Object partyObj : relatedParties) {
            Map<String, Object> party = (Map<String, Object>)partyObj;
            String role = (String)party.get('role');
            
            if (party.containsKey('partyOrPartyRole')) {
                Map<String, Object> partyOrPartyRole = (Map<String, Object>)party.get('partyOrPartyRole');
                String partyId = (String)partyOrPartyRole.get('id');
                
                // Map based on role
                if (role == 'ConsumerAccount') {
                    ipPayload.put('customerIdSF', partyId);
                    
                } else if (role == 'BillingAccount') {
                    orderCharacteristics.add(new Map<String, Object>{
                        'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                        'value' => partyId
                    });
                    
                } else if (role == 'ServiceAccount') {
                    orderCharacteristics.add(new Map<String, Object>{
                        'name' => 'vlocity_cmt__DefaultServiceAccountId__c',
                        'value' => partyId
                    });
                    
                } else if (role == 'ExternalAccount93') {
                    ipPayload.put('externalAccount93', partyId);
                    
                } else if (role == 'ExternalAccount91') {
                    ipPayload.put('externalAccount91', partyId);
                    
                } else if (role == 'ExternalAccount92') {
                    ipPayload.put('externalAccount92', partyId);
                }
            }
        }
        
        // Add orderCharacteristic array if not empty
        if (!orderCharacteristics.isEmpty()) {
            if (ipPayload.containsKey('orderCharacteristic')) {
                List<Map<String, Object>> existing = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
                existing.addAll(orderCharacteristics);
            } else {
                ipPayload.put('orderCharacteristic', orderCharacteristics);
            }
        }
    }

    /**
     * @description Processes characteristic array and maps to IP fields
     * Handles: salesType, salesSubtype, deliveryDetails, authorizedPersonData, 
     *          portInData, migraData, additionalServices, fiscal fields, etc.
     */
    @TestVisible
    private void processCharacteristics(Map<String, Object> tmfPayload, Map<String, Object> ipPayload) {
        List<Object> characteristics = (List<Object>)tmfPayload.get('characteristic');
        List<Map<String, Object>> orderCharacteristics = new List<Map<String, Object>>();
        
        for (Object charObj : characteristics) {
            Map<String, Object> characteristic = (Map<String, Object>)charObj;
            String name = (String)characteristic.get('name');
            Object value = characteristic.get('value');
            String valueType = (String)characteristic.get('valueType');
            
            // Direct mappings to root level
            if (name == 'salesType') {
                ipPayload.put('salesType', value);
                
            } else if (name == 'salesSubtype') {
                ipPayload.put('salesSubtype', value);

            } else if (name == 'billingCycle') {
            ipPayload.put('billingCycle', value);

            } else if (name == 'cutoffDetailsDate') {
            ipPayload.put('cutoffDetailsDate', value);
                
            } else if (name == 'deliveryDetails' && valueType == 'object') {
                ipPayload.put('deliveryDetails', value);
                
            } else if (name == 'authorizedPersonData' && valueType == 'object') {
                ipPayload.put('authorizedPersonData', value);
                
            } else if (name == 'portInData' && valueType == 'object') {
                ipPayload.put('portInData', value);
                
            } else if (name == 'migraData' && valueType == 'object') {
                ipPayload.put('migraData', value);
                
            } else if (name == 'additionalServices' && valueType == 'array') {
                ipPayload.put('additionalServices', value);
                
            // Characteristics that go into orderCharacteristic array
            } else if (name.contains('__c')) {
                orderCharacteristics.add(new Map<String, Object>{
                    'name' => name,
                    'value' => value
                });
            }
        }
                
        // Merge with existing orderCharacteristic
        if (!orderCharacteristics.isEmpty()) {
            if (ipPayload.containsKey('orderCharacteristic')) {
                List<Map<String, Object>> existing = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
                existing.addAll(orderCharacteristics);
            } else {
                ipPayload.put('orderCharacteristic', orderCharacteristics);
            }
        }
    }

    /**
     * @description Processes payment array and maps to orderPayments
     * TMF: payment[].{id, paymentDate, amount, paymentMethod}
     * IP:  orderPayments[].{orderPaymentNumber, orderPaymentMethod, orderPaymentAmount, orderPaymentDate}
     */
    @TestVisible
    private void processPayments(Map<String, Object> tmfPayload, Map<String, Object> ipPayload) {
        List<Object> payments = (List<Object>)tmfPayload.get('payment');
        List<Map<String, Object>> orderPayments = new List<Map<String, Object>>();
        
        for (Object paymentObj : payments) {
            Map<String, Object> payment = (Map<String, Object>)paymentObj;
            
            Map<String, Object> orderPayment = new Map<String, Object>();
            
            // Map id → orderPaymentNumber
            if (payment.containsKey('id')) {
                orderPayment.put('orderPaymentNumber', payment.get('id'));
            }
            
            // Map paymentMethod.id → orderPaymentMethod
            if (payment.containsKey('paymentMethod')) {
                Map<String, Object> paymentMethod = (Map<String, Object>)payment.get('paymentMethod');
                if (paymentMethod.containsKey('id')) {
                    orderPayment.put('orderPaymentMethod', paymentMethod.get('id'));
                }
            }
            
            // Map amount.value → orderPaymentAmount
            if (payment.containsKey('amount')) {
                Map<String, Object> amount = (Map<String, Object>)payment.get('amount');
                if (amount.containsKey('value')) {
                    orderPayment.put('orderPaymentAmount', amount.get('value'));
                }
            }
            
            // Map paymentDate → orderPaymentDate (convert ISO to IP format)
            if (payment.containsKey('paymentDate')) {
                String isoDate = (String)payment.get('paymentDate');
                String formattedDate = convertISOToIPDateFormat(isoDate);
                orderPayment.put('orderPaymentDate', formattedDate);
            }
            
            orderPayments.add(orderPayment);
        }
        
        if (!orderPayments.isEmpty()) {
            ipPayload.put('orderPayments', orderPayments);
        }
    }

    /**
     * @description Processes productOrderItem array and maps to products
     * TMF: productOrderItem[].{id, productOffering.id, product.productCharacteristic}
     * IP:  products[].{productCode, sequence, position} OR {promotionCode, sequence, position}
     * 
     * IMPORTANT: 
     * - Regular products get: productCode, sequence, position
     * - Promotions (identified by @type containing "promotion") get: promotionCode, sequence, position
     * - Sequence and position come from product.productCharacteristic
     */
    @TestVisible
    private void processProductOrderItems(Map<String, Object> tmfPayload, Map<String, Object> ipPayload) {
        List<Object> productOrderItems = (List<Object>)tmfPayload.get('productOrderItem');
        List<Map<String, Object>> products = new List<Map<String, Object>>();
        
        for (Object itemObj : productOrderItems) {
            Map<String, Object> item = (Map<String, Object>)itemObj;
            
            Map<String, Object> product = new Map<String, Object>();
            
            // Determine if this is a promotion or regular product
            Boolean isPromotion = false;
            String offeringId = null;
            
            if (item.containsKey('productOffering')) {
                Map<String, Object> productOffering = (Map<String, Object>)item.get('productOffering');
                
                // Get offering ID
                if (productOffering.containsKey('id')) {
                    offeringId = String.valueOf(productOffering.get('id'));
                }
                
                // Check if it's a promotion based on @type containing "promotion" (case insensitive)
                if (productOffering.containsKey('@type')) {
                    String offeringType = String.valueOf(productOffering.get('@type'));
                    isPromotion = offeringType.toLowerCase().contains('promotion');
                }
            }
            
            // Map to promotionCode or productCode based on type
            if (String.isNotBlank(offeringId)) {
                if (isPromotion) {
                    product.put('promotionCode', offeringId);
                } else {
                    product.put('productCode', offeringId);
                }
            }
            
            // Extract sequence and position from product.productCharacteristic
            if (item.containsKey('product')) {
                Map<String, Object> productData = (Map<String, Object>)item.get('product');
                if (productData.containsKey('productCharacteristic')) {
                    List<Object> characteristics = (List<Object>)productData.get('productCharacteristic');
                    
                    for (Object charObj : characteristics) {
                        Map<String, Object> characteristic = (Map<String, Object>)charObj;
                        String charName = (String)characteristic.get('name');
                        Object charValue = characteristic.get('value');
                        
                        if (charName == 'sequence') {
                            try {
                                Integer sequenceValue = Integer.valueOf(String.valueOf(charValue));
                                product.put('sequence', sequenceValue);
                            } catch (Exception e) {
                                System.debug('Error parsing sequence: ' + e.getMessage());
                            }
                        } else if (charName == 'position') {
                            product.put('position', String.valueOf(charValue));
                        }
                    }
                }
            }
            
            products.add(product);
        }

        if (!products.isEmpty()) {
            ipPayload.put('products', products);
        }
    }
            
    /**
     * @description Processes quote array and maps to financingDetails
     * TMF: quote[].characteristic[].{name, value}
     * IP:  financingDetails[].{name, value}
     * 
     * Maps financing data from TMF Quote object to IP financingDetails array.
     */
    @TestVisible
    private void processQuote(Map<String, Object> tmfPayload, Map<String, Object> ipPayload) {
        List<Object> quotes = (List<Object>)tmfPayload.get('quote');
        List<Map<String, Object>> financingDetails = new List<Map<String, Object>>();
        
        // Process first quote (typically only one quote for financing)
        if (!quotes.isEmpty()) {
            Map<String, Object> quote = (Map<String, Object>)quotes[0];
            
            // Map quote.id to orderCharacteristic if needed
            if (quote.containsKey('id')) {
                String quoteId = String.valueOf(quote.get('id'));
                
                // Add quote ID to orderCharacteristic
                List<Map<String, Object>> orderChars;
                if (ipPayload.containsKey('orderCharacteristic')) {
                    orderChars = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
                } else {
                    orderChars = new List<Map<String, Object>>();
                    ipPayload.put('orderCharacteristic', orderChars);
                }
                
                orderChars.add(new Map<String, Object>{
                    'name' => 'FIN_IDDeSimulacion__c',
                    'value' => quoteId
                });
            }
            
            // Process quote characteristics → financingDetails
            if (quote.containsKey('characteristic')) {
                List<Object> characteristics = (List<Object>)quote.get('characteristic');
                
                for (Object charObj : characteristics) {
                    Map<String, Object> characteristic = (Map<String, Object>)charObj;
                    String name = (String)characteristic.get('name');
                    Object value = characteristic.get('value');
                    
                    // All quote characteristics go to financingDetails
                    // The name should already be the Salesforce field name (e.g., FIN_CreditQuota__c)
                    financingDetails.add(new Map<String, Object>{
                        'name' => name,
                        'value' => value
                    });
                }
            }
        }
        
        if (!financingDetails.isEmpty()) {
            ipPayload.put('financingDetails', financingDetails);
        }
    }

    /**
     * @description Converts ISO 8601 date to IP format
     * From: "2025-04-10T19:30:00Z"
     * To:   "2025-04-10 19:30:00"
     */
    @TestVisible
    private String convertISOToIPDateFormat(String isoDate) {
        try {
            // Remove 'Z' and replace 'T' with space
            String formatted = isoDate.replace('T', ' ').replace('Z', '');
            return formatted;
        } catch (Exception e) {
            System.debug('Error converting date: ' + e.getMessage());
            return isoDate; // Return original if conversion fails
        }
    }
    
    /**
     * @description Parses Integration Procedure response
     * IP Response format:
     * {
     *   "code": "200",
     *   "status": "Success",
     *   "message": "Order created",
     *   "attributes": {
     *     "id": "00003110",
     *     "href": "/services/data/v57.0/sobjects/Order/801xxxxxxxxxxxxxxx",
     *     "type": "Order"
     *   }
     * }
     * @param ipOutput Output from Integration Procedure
     * @return IPResponse wrapper object
     */
    @TestVisible
    private IPResponse parseIPResponse(Map<String, Object> ipOutput) {
        IPResponse response = new IPResponse();
        
        try {
            // Check if IP returned error
            if (ipOutput.containsKey('error')) {
                response.success = false;
                response.errorMessage = String.valueOf(ipOutput.get('error'));
                response.errorCode = 'TMF-500-004';
                response.httpStatus = 500;
                return response;
            }
            
            // Parse response
            String code = ipOutput.containsKey('code') ? String.valueOf(ipOutput.get('code')) : null;
            String status = ipOutput.containsKey('status') ? String.valueOf(ipOutput.get('status')) : null;
            String message = ipOutput.containsKey('message') ? String.valueOf(ipOutput.get('message')) : 'No message provided';
            
            if (code == '200' && status == 'Success') {
                // Extract attributes
                if (ipOutput.containsKey('attributes')) {
                    Map<String, Object> attributes = (Map<String, Object>)ipOutput.get('attributes');
                    // Get Order Id (id in attributes is orderNumber, not Salesforce ID)
                    if (attributes.containsKey('Id')) {
                        response.orderNumber = String.valueOf(attributes.get('Id'));
                    } else if (attributes.containsKey('id')) {
                        response.orderNumber = String.valueOf(attributes.get('id'));
                    }
                    // Extract Salesforce Order ID from href
                    // Format: "/services/data/v57.0/sobjects/Order/50078000002rf0BAAQ"
                    if (attributes.containsKey('href')) {
                        String href = String.valueOf(attributes.get('href'));
                        response.href = href; // Store full href from IP
                        List<String> hrefParts = href.split('/');
                        if (!hrefParts.isEmpty()) {
                            response.orderId = hrefParts[hrefParts.size() - 1];
                        }
                    }
                }
                // Validate we got required data
                if (String.isBlank(response.orderId) || String.isBlank(response.orderNumber)) {
                    response.success = false;
                    response.errorMessage = 'Invalid IP response: missing order ID or number';
                    response.errorCode = 'TMF-500-005';
                    response.httpStatus = 500;
                    return response;
                }
                response.success = true;
                return response;
            }
            
            response.success = false;
            response.errorMessage = message;

            if (code != null) {
                IPErrorMapping errorMapping = mapIPErrorToTMF(code, message);
                response.errorCode = errorMapping.tmfCode;
                response.httpStatus = errorMapping.httpStatus;
            } else {
                response.errorCode = 'TMF-500-004';
                response.httpStatus = 500;
            }
            
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = 'Error parsing IP response: ' + e.getMessage();
            response.errorCode = 'TMF-500-006';
            response.httpStatus = 500;
        }
        
        return response;
    }

    @TestVisible
    private IPErrorMapping mapIPErrorToTMF(String ipCode, String ipMessage) {
        IPErrorMapping mapping = new IPErrorMapping();
        if (ipCode == '400') { mapping.tmfCode = 'TMF-400-020'; mapping.httpStatus = 400; }
        else if (ipCode == '404') { mapping.tmfCode = 'TMF-404-003'; mapping.httpStatus = 404; }
        else if (ipCode == '409') { mapping.tmfCode = 'TMF-409-001'; mapping.httpStatus = 409; }
        else if (ipCode == '422') { mapping.tmfCode = 'TMF-422-001'; mapping.httpStatus = 422; }
        else if (ipCode == '500') { mapping.tmfCode = 'TMF-500-007'; mapping.httpStatus = 500; }
        else { mapping.tmfCode = 'TMF-500-008'; mapping.httpStatus = 500; }
        
        if (ipMessage.containsIgnoreCase('required')) { mapping.tmfCode = 'TMF-400-021'; mapping.httpStatus = 400; }
        else if (ipMessage.containsIgnoreCase('not found')) { mapping.tmfCode = 'TMF-404-003'; mapping.httpStatus = 404; }
        else if (ipMessage.containsIgnoreCase('duplicate')) { mapping.tmfCode = 'TMF-409-002'; mapping.httpStatus = 409; }
        
        return mapping;
    }

    /**
     * @description Builds TMF response maintaining original payload structure
     * This method preserves the entire request payload and adds:
     * - Order metadata: id, href (from IP), creationDate, lastUpdate
     * - Account names in relatedParty for ConsumerAccount, BillingAccount, ServiceAccount
     * 
     * @param orderId Salesforce Order ID (15 or 18 chars)
     * @param orderNumber Order Number from IP response (e.g., "00001094")
     * @param ipHref Full href from IP response (e.g., "/services/data/v57.0/sobjects/Order/801XX...")
     * @param originalPayload Original TMF request payload
     * @return TMF response with original payload + Order metadata + Account names
     */
    @TestVisible
    private Map<String, Object> buildTMFResponseFromIP(String orderId, 
                                                       String orderNumber, 
                                                       String ipHref,
                                                       Map<String, Object> originalPayload) {
        
        // Start with original payload - this preserves all request fields
        Map<String, Object> response = new Map<String, Object>(originalPayload);
        
        try {
            // Query Order for creation and modification dates
            List<Order> orders = [
                SELECT CreatedDate, LastModifiedDate, OrderNumber
                FROM Order
                WHERE Id = :orderId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!orders.isEmpty()) {
                Order o = orders[0];
                
                // Add/Override required fields from Order
                /*response.put('id', orderNumber);
                response.put('href', '/services/apexrest/tmforum/v5/productOrder/' + orderNumber);*/
                response.put('id', o.OrderNumber);
                
                // Use href from IP response (preserve original IP href)
                if (String.isNotBlank(ipHref)) {
                    response.put('href', ipHref);
                } else {
                    // Fallback: generate href from OrderNumber (commented for reference)
                    // response.put('href', '/services/apexrest/tmforum/v5/productOrder/' + o.OrderNumber);
                    response.put('href', '/services/data/v57.0/sobjects/Order/' + orderId);
                }
                
                response.put('creationDate', o.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                response.put('lastUpdate', o.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                
            } else {
                // Fallback if Order query fails - use current timestamp
                response.put('id', orderNumber);
                response.put('href', String.isNotBlank(ipHref) ? ipHref : '/services/data/v57.0/sobjects/Order/' + orderId);
                
                String currentTimestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
                response.put('creationDate', currentTimestamp);
                response.put('lastUpdate', currentTimestamp);
            }
            
            // Enrich relatedParty with Account names
            enrichRelatedPartyWithAccountNames(response);
            
        } catch (Exception e) {
            System.debug('Error building TMF response: ' + e.getMessage());
            
            // Fallback with minimal data
            response.put('id', orderNumber);
            response.put('href', String.isNotBlank(ipHref) ? ipHref : '/services/data/v57.0/sobjects/Order/' + orderId);
            
            String currentTimestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            response.put('creationDate', currentTimestamp);
            response.put('lastUpdate', currentTimestamp);
        }
        
        return response;
    }
    
    /**
     * @description Enriches relatedParty array by adding Account names
     * Queries Account.Name for ConsumerAccount, BillingAccount, and ServiceAccount roles
     * @param response TMF response payload
     */
    @TestVisible
    private void enrichRelatedPartyWithAccountNames(Map<String, Object> response) {
        if (!response.containsKey('relatedParty')) {
            return;
        }
        
        List<Object> relatedParties = (List<Object>)response.get('relatedParty');
        if (relatedParties == null || relatedParties.isEmpty()) {
            return;
        }
        
        // Collect Account IDs to query
        Set<Id> accountIds = new Set<Id>();
        
        for (Object partyObj : relatedParties) {
            Map<String, Object> party = (Map<String, Object>)partyObj;
            String role = (String)party.get('role');
            
            // Only process ConsumerAccount, BillingAccount, ServiceAccount
            if (role == 'ConsumerAccount' || role == 'BillingAccount' || role == 'ServiceAccount') {
                if (party.containsKey('partyOrPartyRole')) {
                    Map<String, Object> partyOrPartyRole = (Map<String, Object>)party.get('partyOrPartyRole');
                    if (partyOrPartyRole.containsKey('id')) {
                        String accountIdStr = (String)partyOrPartyRole.get('id');
                        try {
                            accountIds.add((Id)accountIdStr);
                        } catch (Exception e) {
                            System.debug('Invalid Account ID: ' + accountIdStr);
                        }
                    }
                }
            }
        }
        
        // Query Account names
        Map<Id, String> accountNamesMap = new Map<Id, String>();
        if (!accountIds.isEmpty()) {
            for (Account acc : [SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH SECURITY_ENFORCED]) {
                accountNamesMap.put(acc.Id, acc.Name);
            }
        }
        
        // Add names to relatedParty
        for (Object partyObj : relatedParties) {
            Map<String, Object> party = (Map<String, Object>)partyObj;
            String role = (String)party.get('role');
            
            if (role == 'ConsumerAccount' || role == 'BillingAccount' || role == 'ServiceAccount') {
                if (party.containsKey('partyOrPartyRole')) {
                    Map<String, Object> partyOrPartyRole = (Map<String, Object>)party.get('partyOrPartyRole');
                    if (partyOrPartyRole.containsKey('id')) {
                        String accountIdStr = (String)partyOrPartyRole.get('id');
                        try {
                            Id accountId = (Id)accountIdStr;
                            if (accountNamesMap.containsKey(accountId)) {
                                partyOrPartyRole.put('name', accountNamesMap.get(accountId));
                            }
                        } catch (Exception e) {
                            System.debug('Error adding account name: ' + e.getMessage());
                        }
                    }
                }
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
    @TestVisible
    private class IPResponse {
        public Boolean success { get; set; }
        public String orderId { get; set; }
        public String orderNumber { get; set; }
        public String href { get; set; }
        public String errorMessage { get; set; }
        public String errorCode { get; set; }
        public Integer httpStatus { get; set; }
        
        public IPResponse() {
            this.success = false;
        }
    }

    /**
     * @description Inner class to wrap IP error mapping
     */
    @TestVisible
    private class IPErrorMapping {
        public String tmfCode { get; set; }
        public Integer httpStatus { get; set; }
        public IPErrorMapping() { this.tmfCode = 'TMF-500-004'; this.httpStatus = 500; }
    }
}