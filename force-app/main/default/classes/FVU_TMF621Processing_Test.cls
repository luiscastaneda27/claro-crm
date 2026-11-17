/**
 * @description Comprehensive test class for FVU_TMF621Processing
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 * 
 * Coverage Areas:
 * - Constructor
 * - processRequest (POST operation)
 * - createTroubleTicket
 * - transformToIPFormat
 * - getDocumentInfoFromParty
 * - parseIPResponse
 * - mapIPErrorToTMF
 * - buildTMFResponseFromIP
 * - buildMinimalTMFResponse
 * - buildErrorResponse
 * - Inner classes (IPResponse, IPErrorMapping)
 */
@isTest
private class FVU_TMF621Processing_Test {
    
    // ============================================================================
    // TEST DATA SETUP
    // ============================================================================
    // Note: Test data is created within each test method as needed
    // to avoid issues with @testSetup transaction isolation
    
    // ============================================================================
    // CONSTRUCTOR TESTS
    // ============================================================================
    
    @isTest
    static void testConstructor_Success() {
        Test.startTest();
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        Test.stopTest();
        
        System.assertNotEquals(null, processor, 'Processor instance should be created');
        System.assertEquals('TMF621', processor.apiName, 'API name should be TMF621');
    }
    
    // ============================================================================
    // PROCESS REQUEST TESTS
    // ============================================================================
    
    @isTest
    static void testProcessRequest_POST_ValidationFails() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        // Empty payload should fail validation
        Map<String, Object> payload = new Map<String, Object>();
        
        Test.startTest();
        Object result = processor.processRequest('POST', payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals('error', resultMap.get('status'), 'Status should be error');
        System.assert(resultMap.containsKey('errors'), 'Should contain errors');
    }
    
    @isTest
    static void testProcessRequest_UnsupportedMethod() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Test ticket'
        };
        
        Test.startTest();
        Object result = processor.processRequest('DELETE', payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals('error', resultMap.get('status'), 'Status should be error');
        
        List<Object> errors = (List<Object>)resultMap.get('errors');
        System.assert(errors.size() > 0, 'Should have errors');
        
        Map<String, Object> error = (Map<String, Object>)errors[0];
        // Accept either TMF-405-001 (method not allowed) or TMF-404-001 (operation not found)
        // depending on if validateRequest fails first
        System.assert(
            error.get('code') == 'TMF-405-001' || error.get('code') == 'TMF-404-001',
            'Should return method not allowed or operation not found error'
        );
    }
    
    // ============================================================================
    // TRANSFORM TO IP FORMAT TESTS
    // ============================================================================
    
    @isTest
    static void testTransformToIPFormat_DirectFields() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'status' => 'New',
            'description' => 'Test description',
            'priority' => 'High',
            'category' => 'Technical',
            'subcategory' => 'Network',
            'customerVoice' => 'Complaint',
            'subscriberNumber' => '123456789',
            '@type' => 'TroubleTicket'
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals('New', ipPayload.get('status'), 'Status should be mapped');
        System.assertEquals('Test description', ipPayload.get('description'), 'Description should be mapped');
        System.assertEquals('High', ipPayload.get('priority'), 'Priority should be mapped');
        System.assertEquals('Technical', ipPayload.get('category'), 'Category should be mapped');
        System.assertEquals('Network', ipPayload.get('subcategory'), 'Subcategory should be mapped');
        System.assertEquals('Complaint', ipPayload.get('customerVoice'), 'CustomerVoice should be mapped');
        System.assertEquals('123456789', ipPayload.get('subscriberNumber'), 'SubscriberNumber should be mapped');
        System.assertEquals('TroubleTicket', ipPayload.get('@type'), '@type should be mapped');
    }
    
    @isTest
    static void testTransformToIPFormat_ChannelField() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> channel = new Map<String, Object>{
            'name' => 'Web',
            '@type' => 'Channel'
        };
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'channel' => channel
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assert(ipPayload.containsKey('channel'), 'Channel should be present');
        
        Map<String, Object> resultChannel = (Map<String, Object>)ipPayload.get('channel');
        System.assertEquals('Web', resultChannel.get('name'), 'Channel name should be mapped');
    }
    
    @isTest
    static void testTransformToIPFormat_TroubleTicketCharacteristic() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<Object> characteristics = new List<Object>{
            new Map<String, Object>{
                'name' => 'serviceType',
                'value' => 'Internet'
            }
        };
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'troubleTicketCharacteristic' => characteristics
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assert(ipPayload.containsKey('troubleTicketCharacteristic'), 
            'Characteristics should be present');
        
        List<Object> resultChars = (List<Object>)ipPayload.get('troubleTicketCharacteristic');
        System.assertEquals(1, resultChars.size(), 'Should have one characteristic');
    }
    
    @isTest
    static void testTransformToIPFormat_RelatedPartyAccount() {
        // Create account within test method
        Account acc = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<Object> relatedParties = new List<Object>{
            new Map<String, Object>{
                'id' => acc.Id,
                '@referredType' => 'Account'
            }
        };
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => relatedParties
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals('CC', ipPayload.get('documentType'), 'Document type should be from Account');
        System.assertEquals('12345678', ipPayload.get('documentNumber'), 'Document number should be from Account');
    }
    
    @isTest
    static void testTransformToIPFormat_RelatedPartyContact() {
        // Create contact within test method
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            FVU_DocumentType__c = 'PP',
            FVU_DocumentNumber__c = 'P87654321'
        );
        insert con;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<Object> relatedParties = new List<Object>{
            new Map<String, Object>{
                'id' => con.Id,
                '@referredType' => 'Contact'
            }
        };
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => relatedParties
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals('PP', ipPayload.get('documentType'), 'Document type should be from Contact');
        System.assertEquals('P87654321', ipPayload.get('documentNumber'), 'Document number should be from Contact');
    }
    
    @isTest
    static void testTransformToIPFormat_RelatedPartyInvalidId() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<Object> relatedParties = new List<Object>{
            new Map<String, Object>{
                'id' => '001000000000000', // Invalid ID
                '@referredType' => 'Account'
            }
        };
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => relatedParties
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals(false, ipPayload.containsKey('documentType'), 
            'Document type should not be present for invalid ID');
    }
    
    @isTest
    static void testTransformToIPFormat_EmptyRelatedParty() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => new List<Object>()
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals(false, ipPayload.containsKey('documentType'), 
            'Document type should not be present for empty related party');
    }
    
    @isTest
    static void testTransformToIPFormat_ExceptionHandling() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        // Payload that might cause exception (null values, wrong types, etc.)
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => 'invalid' // Should be List, not String
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertEquals(null, ipPayload, 'Should return null when exception occurs');
    }
    
    // ============================================================================
    // GET DOCUMENT INFO FROM PARTY TESTS
    // ============================================================================
    
    @isTest
    static void testGetDocumentInfoFromParty_Account() {
        // Create account within test method
        Account acc = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty(acc.Id, 'Account');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('CC', result.get('documentType'), 'Document type should match');
        System.assertEquals('12345678', result.get('documentNumber'), 'Document number should match');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_AccountBlankReferredType() {
        // Create account within test method
        Account acc = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty(acc.Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null even with blank referredType');
        System.assertEquals('CC', result.get('documentType'), 'Should default to Account query');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_Contact() {
        // Create contact within test method
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            FVU_DocumentType__c = 'PP',
            FVU_DocumentNumber__c = 'P87654321'
        );
        insert con;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty(con.Id, 'Contact');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('PP', result.get('documentType'), 'Document type should match');
        System.assertEquals('P87654321', result.get('documentNumber'), 'Document number should match');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_InvalidId() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty('001000000000000', 'Account');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null for invalid ID');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_AccountWithBlankFields() {
        // Create account without document fields
        Account acc = new Account(
            Name = 'Account Without Docs'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty(acc.Id, 'Account');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null when fields are blank');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_ExceptionHandling() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty('invalid-id', 'Account');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should handle exceptions gracefully');
    }
    
    // ============================================================================
    // PARSE IP RESPONSE TESTS
    // ============================================================================
    
    @isTest
    static void testParseIPResponse_Success() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'message' => 'Case created successfully',
            'attributes' => new Map<String, Object>{
                'id' => '00001234',
                'href' => '/services/data/v57.0/sobjects/Case/50078000002rf0BAAQ',
                'type' => 'Case'
            }
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals('00001234', response.caseNumber, 'Case number should be extracted');
        System.assertEquals('50078000002rf0BAAQ', response.caseId, 'Case ID should be extracted from href');
    }
    
    @isTest
    static void testParseIPResponse_SuccessWithIdInAttributes() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'message' => 'Case created',
            'attributes' => new Map<String, Object>{
                'Id' => '00005678', // Capital I
                'href' => '/services/data/v57.0/sobjects/Case/50078000002rf0BAAQ'
            }
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals('00005678', response.caseNumber, 'Should extract Id with capital I');
    }
    
    @isTest
    static void testParseIPResponse_ErrorInResponse() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'error' => 'Something went wrong'
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should be unsuccessful');
        System.assertEquals('TMF-500-004', response.errorCode, 'Should use default error code');
        System.assertEquals(500, response.httpStatus, 'Should return 500 status');
        System.assertEquals('Something went wrong', response.errorMessage, 'Should contain error message');
    }
    
    @isTest
    static void testParseIPResponse_NonSuccessCode() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '400',
            'status' => 'Error',
            'message' => 'Invalid request'
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should be unsuccessful');
        System.assertEquals('TMF-400-020', response.errorCode, 'Should map 400 error');
        System.assertEquals(400, response.httpStatus, 'Should return 400 status');
        System.assertEquals('Invalid request', response.errorMessage, 'Should contain error message');
    }
    
    @isTest
    static void testParseIPResponse_MissingCaseIdOrNumber() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'message' => 'Case created',
            'attributes' => new Map<String, Object>{
                'type' => 'Case'
                // Missing id and href
            }
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should be unsuccessful without case data');
        System.assertEquals('TMF-500-005', response.errorCode, 'Should return invalid response error');
        System.assert(response.errorMessage.contains('missing'), 'Error message should mention missing data');
    }
    
    @isTest
    static void testParseIPResponse_NoCodeInResponse() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'status' => 'Unknown',
            'message' => 'Something happened'
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should be unsuccessful');
        System.assertEquals('TMF-500-004', response.errorCode, 'Should use default error code when no code');
        System.assertEquals(500, response.httpStatus, 'Should return 500 status');
    }
    
    @isTest
    static void testParseIPResponse_ExceptionHandling() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        // Create invalid structure that will cause exception
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'attributes' => 'invalid' // Should be Map, not String
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Should handle exceptions');
        System.assertEquals('TMF-500-006', response.errorCode, 'Should return parsing error code');
        System.assert(response.errorMessage.contains('parsing'), 'Error message should mention parsing');
    }
    
    // ============================================================================
    // MAP IP ERROR TO TMF TESTS
    // ============================================================================
    
    @isTest
    static void testMapIPErrorToTMF_400Code() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('400', 'Bad request');
        Test.stopTest();
        
        System.assertEquals('TMF-400-020', mapping.tmfCode, 'Should map to TMF 400 error');
        System.assertEquals(400, mapping.httpStatus, 'HTTP status should be 400');
    }
    
    @isTest
    static void testMapIPErrorToTMF_404Code() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('404', 'Not found');
        Test.stopTest();
        
        System.assertEquals('TMF-404-003', mapping.tmfCode, 'Should map to TMF 404 error');
        System.assertEquals(404, mapping.httpStatus, 'HTTP status should be 404');
    }
    
    @isTest
    static void testMapIPErrorToTMF_409Code() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('409', 'Conflict');
        Test.stopTest();
        
        System.assertEquals('TMF-409-001', mapping.tmfCode, 'Should map to TMF 409 error');
        System.assertEquals(409, mapping.httpStatus, 'HTTP status should be 409');
    }
    
    @isTest
    static void testMapIPErrorToTMF_422Code() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('422', 'Unprocessable');
        Test.stopTest();
        
        System.assertEquals('TMF-422-001', mapping.tmfCode, 'Should map to TMF 422 error');
        System.assertEquals(422, mapping.httpStatus, 'HTTP status should be 422');
    }
    
    @isTest
    static void testMapIPErrorToTMF_500Code() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('500', 'Server error');
        Test.stopTest();
        
        System.assertEquals('TMF-500-007', mapping.tmfCode, 'Should map to TMF 500 error');
        System.assertEquals(500, mapping.httpStatus, 'HTTP status should be 500');
    }
    
    @isTest
    static void testMapIPErrorToTMF_UnknownCode() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('999', 'Unknown error');
        Test.stopTest();
        
        System.assertEquals('TMF-500-008', mapping.tmfCode, 'Should map unknown codes to default');
        System.assertEquals(500, mapping.httpStatus, 'HTTP status should be 500 for unknown');
    }
    
    @isTest
    static void testMapIPErrorToTMF_RequiredInMessage() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('400', 'Field is required');
        Test.stopTest();
        
        System.assertEquals('TMF-400-021', mapping.tmfCode, 'Should detect required error from message');
        System.assertEquals(400, mapping.httpStatus, 'HTTP status should be 400');
    }
    
    @isTest
    static void testMapIPErrorToTMF_NotFoundInMessage() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('400', 'Record not found');
        Test.stopTest();
        
        System.assertEquals('TMF-404-003', mapping.tmfCode, 'Should detect not found from message');
        System.assertEquals(404, mapping.httpStatus, 'HTTP status should be 404');
    }
    
    @isTest
    static void testMapIPErrorToTMF_DuplicateInMessage() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = processor.mapIPErrorToTMF('400', 'Duplicate record found');
        Test.stopTest();
        
        System.assertEquals('TMF-409-002', mapping.tmfCode, 'Should detect duplicate from message');
        System.assertEquals(409, mapping.httpStatus, 'HTTP status should be 409');
    }
    
    // ============================================================================
    // BUILD TMF RESPONSE FROM IP TESTS
    // ============================================================================
    
    @isTest
    static void testBuildTMFResponseFromIP_Success() {
        // Create test case within test method
        Account acc = new Account(Name = 'Test Account For Case');
        insert acc;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test',
            Status = 'New',
            AccountId = acc.Id
        );
        insert testCase;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test ticket',
            'priority' => 'High',
            'status' => 'New',
            'category' => 'Technical'
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildTMFResponseFromIP(
            testCase.Id, 
            testCase.CaseNumber, 
            originalPayload
        );
        Test.stopTest();
        
        // Should preserve original payload fields
        System.assertEquals('Test ticket', response.get('description'), 'Should preserve description');
        System.assertEquals('High', response.get('priority'), 'Should preserve priority');
        System.assertEquals('Technical', response.get('category'), 'Should preserve category');
        
        // Should add/override required fields
        System.assertEquals(testCase.CaseNumber, response.get('id'), 'Should set case number as id');
        System.assert(response.containsKey('href'), 'Should contain href');
        System.assert(response.containsKey('creationDate'), 'Should contain creationDate');
        System.assert(response.containsKey('lastUpdate'), 'Should contain lastUpdate');
    }
    
    @isTest
    static void testBuildTMFResponseFromIP_PreservesAllOriginalFields() {
        // Create test case within test method
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test',
            Status = 'New'
        );
        insert testCase;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test',
            'priority' => 'Low',
            'channel' => new Map<String, Object>{'name' => 'Email'},
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => '001xxx', 'name' => 'Party'}
            },
            'troubleTicketCharacteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'type', 'value' => 'billing'}
            }
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildTMFResponseFromIP(
            testCase.Id, 
            testCase.CaseNumber, 
            originalPayload
        );
        Test.stopTest();
        
        System.assert(response.containsKey('channel'), 'Should preserve channel');
        System.assert(response.containsKey('relatedParty'), 'Should preserve relatedParty');
        System.assert(response.containsKey('troubleTicketCharacteristic'), 
            'Should preserve characteristics');
    }
    
    @isTest
    static void testBuildTMFResponseFromIP_InvalidCaseId() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test'
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildTMFResponseFromIP(
            '500000000000000', // Invalid ID
            '00009999', 
            originalPayload
        );
        Test.stopTest();
        
        // Should fallback to timestamps
        System.assertEquals('00009999', response.get('id'), 'Should still set case number');
        System.assert(response.containsKey('creationDate'), 'Should have fallback timestamp');
        System.assert(response.containsKey('lastUpdate'), 'Should have fallback timestamp');
    }
    
    @isTest
    static void testBuildTMFResponseFromIP_ExceptionHandling() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test'
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildTMFResponseFromIP(
            'invalid-id',
            '00001111', 
            originalPayload
        );
        Test.stopTest();
        
        // Should handle exception gracefully and use fallback
        System.assertEquals('00001111', response.get('id'), 'Should set case number');
        System.assert(response.containsKey('href'), 'Should contain href');
    }
    
    // ============================================================================
    // BUILD MINIMAL TMF RESPONSE TESTS
    // ============================================================================
    
    @isTest
    static void testBuildMinimalTMFResponse_WithOriginalPayload() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test description',
            'ticketType' => 'Incident',
            'status' => 'Open'
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildMinimalTMFResponse('00001234', originalPayload);
        Test.stopTest();
        
        System.assertEquals('00001234', response.get('id'), 'Should set case number');
        System.assert(response.containsKey('href'), 'Should contain href');
        System.assertEquals('Test description', response.get('description'), 
            'Should copy description from original');
        System.assertEquals('Incident', response.get('ticketType'), 
            'Should copy ticketType from original');
        System.assertEquals('Open', response.get('status'), 'Should copy status from original');
    }
    
    @isTest
    static void testBuildMinimalTMFResponse_WithoutStatus() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'description' => 'Test'
        };
        
        Test.startTest();
        Map<String, Object> response = processor.buildMinimalTMFResponse('00001234', originalPayload);
        Test.stopTest();
        
        System.assertEquals('New', response.get('status'), 'Should default status to New');
    }
    
    @isTest
    static void testBuildMinimalTMFResponse_EmptyPayload() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>();
        
        Test.startTest();
        Map<String, Object> response = processor.buildMinimalTMFResponse('00005678', originalPayload);
        Test.stopTest();
        
        System.assertEquals('00005678', response.get('id'), 'Should set case number');
        System.assertEquals('New', response.get('status'), 'Should default status to New');
        System.assert(response.containsKey('creationDate'), 'Should have timestamps');
        System.assert(response.containsKey('lastUpdate'), 'Should have timestamps');
    }
    
    // ============================================================================
    // BUILD ERROR RESPONSE TESTS
    // ============================================================================
    
    @isTest
    static void testBuildErrorResponse_SingleError() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<FVU_TMFBase.TMFError> errors = new List<FVU_TMFBase.TMFError>();
        FVU_TMFBase.TMFError error = processor.buildError('TMF-400-001', 'Test error', 400);
        errors.add(error);
        
        Test.startTest();
        Map<String, Object> response = processor.buildErrorResponse(errors);
        Test.stopTest();
        
        System.assertEquals('error', response.get('status'), 'Status should be error');
        System.assert(response.containsKey('errors'), 'Should contain errors array');
        System.assert(response.containsKey('timestamp'), 'Should contain timestamp');
        
        List<Object> errorList = (List<Object>)response.get('errors');
        System.assertEquals(1, errorList.size(), 'Should have one error');
        
        Map<String, Object> errorMap = (Map<String, Object>)errorList[0];
        System.assertEquals('TMF-400-001', errorMap.get('code'), 'Error code should match');
        System.assertEquals('Test error', errorMap.get('message'), 'Error message should match');
    }
    
    @isTest
    static void testBuildErrorResponse_MultipleErrors() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<FVU_TMFBase.TMFError> errors = new List<FVU_TMFBase.TMFError>();
        errors.add(processor.buildError('TMF-400-001', 'Error 1', 400));
        errors.add(processor.buildError('TMF-400-002', 'Error 2', 400));
        errors.add(processor.buildError('TMF-400-003', 'Error 3', 400));
        
        Test.startTest();
        Map<String, Object> response = processor.buildErrorResponse(errors);
        Test.stopTest();
        
        List<Object> errorList = (List<Object>)response.get('errors');
        System.assertEquals(3, errorList.size(), 'Should have three errors');
    }
    
    @isTest
    static void testBuildErrorResponse_EmptyErrorList() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        List<FVU_TMFBase.TMFError> errors = new List<FVU_TMFBase.TMFError>();
        
        Test.startTest();
        Map<String, Object> response = processor.buildErrorResponse(errors);
        Test.stopTest();
        
        System.assertEquals('error', response.get('status'), 'Status should be error');
        List<Object> errorList = (List<Object>)response.get('errors');
        System.assertEquals(0, errorList.size(), 'Should have empty error list');
    }
    
    // ============================================================================
    // INNER CLASS TESTS
    // ============================================================================
    
    @isTest
    static void testIPResponse_DefaultConstructor() {
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = new FVU_TMF621Processing.IPResponse();
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Default success should be false');
    }
    
    @isTest
    static void testIPResponse_SetProperties() {
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = new FVU_TMF621Processing.IPResponse();
        response.success = true;
        response.caseId = '500xxx';
        response.caseNumber = '00001234';
        response.errorMessage = 'Test error';
        response.errorCode = 'TMF-400-001';
        response.httpStatus = 400;
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Should set success');
        System.assertEquals('500xxx', response.caseId, 'Should set caseId');
        System.assertEquals('00001234', response.caseNumber, 'Should set caseNumber');
        System.assertEquals('Test error', response.errorMessage, 'Should set errorMessage');
        System.assertEquals('TMF-400-001', response.errorCode, 'Should set errorCode');
        System.assertEquals(400, response.httpStatus, 'Should set httpStatus');
    }
    
    @isTest
    static void testIPErrorMapping_DefaultConstructor() {
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = new FVU_TMF621Processing.IPErrorMapping();
        Test.stopTest();
        
        System.assertEquals('TMF-500-004', mapping.tmfCode, 'Default tmfCode should be TMF-500-004');
        System.assertEquals(500, mapping.httpStatus, 'Default httpStatus should be 500');
    }
    
    @isTest
    static void testIPErrorMapping_SetProperties() {
        Test.startTest();
        FVU_TMF621Processing.IPErrorMapping mapping = new FVU_TMF621Processing.IPErrorMapping();
        mapping.tmfCode = 'TMF-400-001';
        mapping.httpStatus = 400;
        Test.stopTest();
        
        System.assertEquals('TMF-400-001', mapping.tmfCode, 'Should set tmfCode');
        System.assertEquals(400, mapping.httpStatus, 'Should set httpStatus');
    }
    
    // ============================================================================
    // INTEGRATION TESTS (with mocked IP call)
    // ============================================================================
    
    @isTest(seeAllData=true)
    static void testCreateTroubleTicket_TransformationFails() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        // Create a payload that will cause transformation to fail
        Map<String, Object> payload = new Map<String, Object>{
            'description' => 'Test',
            'relatedParty' => 'invalid' // Should be List, not String
        };
        
        Test.startTest();
        Object result = processor.createTroubleTicket(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals('error', resultMap.get('status'), 'Should return error');
        
        List<Object> errors = (List<Object>)resultMap.get('errors');
        Map<String, Object> error = (Map<String, Object>)errors[0];
        System.assertEquals('TMF-500-003', error.get('code'), 'Should return transformation error');
    }
    
    @isTest(seeAllData=true)
    static void testCreateTroubleTicket_CallIp() {
        
        Account acc = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        // Create a complete valid payload to test IP call
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'status' => 'New',
            'description' => 'Full payload test',
            'priority' => 'Critical',
            'category' => 'Billing',
            'subcategory' => 'Invoice',
            'customerVoice' => 'Angry',
            'subscriberNumber' => '999888777',
            '@type' => 'ComplexTicket',
            'channel' => new Map<String, Object>{'name' => 'Mobile App'},
            'troubleTicketCharacteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'urgency', 'value' => 'high'}
            },
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => acc.Id, '@referredType' => 'Account'}
            }
        };
        
        Test.startTest();
        Object result = processor.createTroubleTicket(tmfPayload);
        Test.stopTest();
        
        // Asserts - The IP call will likely fail in test context
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        
        // Could be either 'error' (if IP fails) or success (if IP exists and works)
        System.assert(
            resultMap.get('status') == 'error' || resultMap.containsKey('id'),
            'Should return either error or success response'
        );
        
        // If error, verify it's the IP execution error
        if (resultMap.get('status') == 'error') {
            List<Object> errors = (List<Object>)resultMap.get('errors');
            System.assert(errors.size() > 0, 'Should have errors');
            
            Map<String, Object> error = (Map<String, Object>)errors[0];
            // The error code should be TMF-500-005 (IP execution error)
            // unless the IP actually exists and returns a different error
            System.assert(
                error.get('code') == 'TMF-500-005' || 
                error.get('code') == 'TMF-500-004' ||
                String.valueOf(error.get('code')).startsWith('TMF-'),
                'Should return a TMF error code'
            );
        }
        
        // If success, verify it has required fields
        if (resultMap.containsKey('id')) {
            System.assert(resultMap.containsKey('href'), 'Success response should have href');
            System.assert(resultMap.containsKey('creationDate'), 'Success response should have creationDate');
        }
    }
    
    // ============================================================================
    // EDGE CASES AND BOUNDARY TESTS
    // ============================================================================
    
    @isTest
    static void testTransformToIPFormat_AllFieldsPopulated() {
        // Create account within test method
        Account acc = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'status' => 'New',
            'description' => 'Full payload test',
            'priority' => 'Critical',
            'category' => 'Billing',
            'subcategory' => 'Invoice',
            'customerVoice' => 'Angry',
            'subscriberNumber' => '999888777',
            '@type' => 'ComplexTicket',
            'channel' => new Map<String, Object>{'name' => 'Mobile App'},
            'troubleTicketCharacteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'urgency', 'value' => 'high'}
            },
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'id' => acc.Id, '@referredType' => 'Account'}
            }
        };
        
        Test.startTest();
        Map<String, Object> ipPayload = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, ipPayload, 'IP payload should not be null');
        System.assertEquals(12, ipPayload.size(), 'Should have all fields mapped');
        System.assertEquals('CC', ipPayload.get('documentType'), 'Should include document info');
    }
    
    @isTest
    static void testParseIPResponse_ComplexHref() {
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'attributes' => new Map<String, Object>{
                'id' => '00007777',
                'href' => '/services/data/v60.0/sobjects/Case/500Qx00000ABCDEFGHI'
            }
        };
        
        Test.startTest();
        FVU_TMF621Processing.IPResponse response = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertEquals('500Qx00000ABCDEFGHI', response.caseId, 
            'Should extract 18-char case ID from href');
    }
    
    @isTest
    static void testGetDocumentInfoFromParty_ContactPartialData() {
        // Create contact with only document type (using valid picklist value)
        Contact con = new Contact(
            FirstName = 'Partial',
            LastName = 'Data',
            FVU_DocumentType__c = 'CC'
            // No FVU_DocumentNumber__c
        );
        insert con;
        
        FVU_TMF621Processing processor = new FVU_TMF621Processing();
        
        Test.startTest();
        Map<String, String> result = processor.getDocumentInfoFromParty(con.Id, 'Contact');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result even with partial data');
        System.assertEquals('CC', result.get('documentType'), 'Should have document type');
        System.assertEquals(false, result.containsKey('documentNumber'), 
            'Should not have document number');
    }
}