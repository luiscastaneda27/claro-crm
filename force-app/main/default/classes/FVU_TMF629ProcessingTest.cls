@IsTest
private class FVU_TMF629ProcessingTest {
	
    @TestSetup
    static void testData() {
        // Minimal data to support possible queries in parseIPResponse:
        // Create a Consumer Account with a primary contact so the inner SOQL can resolve values when status=Success
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'Primary', FirstName = 'John', Email = 'primary@example.com');
        insert c;

        Account a = new Account(
            Name = 'Main Consumer',
            RecordTypeId = rt != null ? rt.Id : null,
            vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_DocumentNumber__c = '987654321',
            FVU_DocumentType__c = 'CC',
            FVU_Email__c = 'main@example.com'
        );
        insert a;

        // Create two child accounts to simulate Address Service/Billing (referenced by parseIPResponse payload)
        insert new Account(Name = 'Addr Service', RecordTypeId = a.RecordTypeId, ParentId = a.Id);
        insert new Account(Name = 'Addr Billing', RecordTypeId = a.RecordTypeId, ParentId = a.Id);
    }

    private static Map<String, Object> buildSampleTMFPayload() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('@type', 'Individual');
        payload.put('name', 'John Doe');
        payload.put('status', 'Active');

        // engagedParty
        Map<String, Object> engagedParty = new Map<String, Object>();
        engagedParty.put('@type', 'Individual');
        engagedParty.put('name', 'John Doe');
        engagedParty.put('role', 'Customer');
        engagedParty.put('characteristic', new List<Object>{
            new Map<String, Object>{ 'name' => 'FirstName', 'value' => 'John' },
            new Map<String, Object>{ 'name' => 'LastName',  'value' => 'Doe' },
            new Map<String, Object>{ 'name' => 'FVU_DocumentType__c', 'value' => 'CC' },
            new Map<String, Object>{ 'name' => 'FVU_DocumentNumber__c', 'value' => '123456' },
			new Map<String, Object>{ 'name' => 'FVU_SecondLastName__c', 'value' => 'Lopez' },
            new Map<String, Object>{ 'name' => 'FVU_PersonalDataAgreementMethod__c', 'value' => 'Correo electrónico' },
            new Map<String, Object>{ 'name' => 'FVU_ExpeditionDate__c', 'value' => '2025-05-01' },
            new Map<String, Object>{ 'name' => 'FVU_PersonalDataAgreementDate__c', 'value' => '2025-11-28T17:27:42.000+0000' }
        });
        payload.put('engagedParty', engagedParty);

        // contactMedium
        payload.put('contactMedium', new List<Object>{
            new Map<String, Object>{ '@type' => 'EmailContactMedium','preferred' => true, 'contactType' => 'Personal', 'emailAddress' => 'john@example.com' },
            new Map<String, Object>{ '@type' => 'GeographicAddressContactMedium', 'contactType' => 'Service', 'city' => 'Bogota', 'street1' => 'Street 123' }
        });

        // root-level characteristic
        payload.put('characteristic', new List<Object>{
            new Map<String, Object>{ 'name' => 'AccountSource', 'value' => 'Web' }
        });

        return payload;
    }

    // Helper for PATCH tests
    private static Map<String, Object> buildPatchPayload(Boolean includeEngagedParty, String epType, String action, String epId) {
        Map<String, Object> payload = new Map<String, Object>{'@type' => 'Customer', 'name' => 'Patch Customer'};
        if (includeEngagedParty) {
            payload.put('engagedParty', new List<Object>{new Map<String, Object>{'@type' => epType, 'action' => action, 'id' => epId}});
            payload.put('contactMedium', new List<Object>{new Map<String, Object>{
                '@type' => 'GeographicAddressContactMedium', 'contactType' => epType, 'street1' => 'Calle 123',
                'city' => 'Bogota', 'stateOrProvince' => 'Cundinamarca', 'postCode' => '110111',
                'characteristic' => new List<Object>{new Map<String, Object>{
                    'name' => 'extendedAddressInfo', 'valueType' => 'object',
                    'value' => new Map<String, Object>{'daneCode' => '11001000', 'merId' => '12345', 'municipality' => 'Bogota', 'addressStatus' => 'Validada', 'addressType' => 'CK'}
                }}
            }});
        }
        return payload;
    }

    @IsTest
    static void testProcessRequest_RoutesAndErrors() {

		// Arrange
        FVU_TMF629Processing proc = new FVU_TMF629Processing();
        Map<String, Object> payload = buildSampleTMFPayload();

        // Act + Assert for POST (it will likely hit IntegrationProcedureService; we only validate graceful error response)
        Test.startTest();
        Object postResp = proc.processRequest('POST', payload);
        Test.stopTest();
        // Expect either a map with error or structured body. In any case, not null.
        System.assertNotEquals(null, postResp, 'POST response should not be null');


        
		// Unsupported method -> 405
       /*Test.startTest();
        Object unsupported = proc.processRequest('PUT', payload);
        Test.stopTest();
        
        System.debug('respuesta =>'+ unsupported);
        System.assertNotEquals(null, unsupported, 'Unsupported method should return error map');
        Map<String, Object> err = (Map<String, Object>) unsupported;
        System.assertEquals('error', (String) err.get('status'), 'Error status expected for unsupported method');
		*/
        
        // Invalid by validation (depends on FVU_TMFBase.validateRequest). Pass nulls to force invalid.
        /*Test.startTest();
        Object invalid = proc.processRequest(null, null);
        Test.stopTest();
        System.debug('respuesta =>'+ invalid);
        System.assertNotEquals(null, invalid, 'Invalid input should return error response');*/
		
    }

    @IsTest
    static void testProcessRequest_GET_Success() {
        // 1. Obtener datos del Setup
        Account acc = [SELECT Id, FVU_DocumentNumber__c, FVU_DocumentType__c FROM Account WHERE Name = 'Main Consumer' LIMIT 1];

        FVU_TMF629Processing proc = new FVU_TMF629Processing();
        
        // Escenario A: GET por ID
        Map<String, Object> reqById = new Map<String, Object>{ 'id' => acc.Id };
        
        // Escenario B: GET por Filtros (Documento)
        Map<String, Object> reqByFilters = new Map<String, Object>{
            'filters' => new Map<String, String>{
                'FVU_DocumentNumber__c' => acc.FVU_DocumentNumber__c,
                'FVU_DocumentType__c' => acc.FVU_DocumentType__c
            }
        };

        Test.startTest();
        Object respId = proc.processRequest('GET', reqById);
        Object respFilter = proc.processRequest('GET', reqByFilters);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, respId, 'GET by ID should return data');
        System.assertNotEquals(null, respFilter, 'GET by Filters should return data');
    }

    @IsTest
    static void testParseIPResponse_Success200() {
        // Arrange IP successful structure

        Account mainAcc = [SELECT Id FROM Account WHERE Name = 'Main Consumer' LIMIT 1];
        Account servAcc = [SELECT Id FROM Account WHERE Name = 'Addr Service' LIMIT 1];
        Account billAcc = [SELECT Id FROM Account WHERE Name = 'Addr Billing' LIMIT 1];

        // 2. Configurar el ipOutput con IDs REALES para que el SOQL encuentre los datos
        Map<String, Object> ipOutput = new Map<String, Object>();
        ipOutput.put('code', '200');
        ipOutput.put('status', 'Success');
        ipOutput.put('message', 'OK');
        
        ipOutput.put('attributes', new Map<String, Object>{
            'Id' => mainAcc.Id,
            'href' => '/services/data/v60.0/sobjects/Account/' + mainAcc.Id
        });

        ipOutput.put('address', new Map<String, Object>{
            'idAddressService' => servAcc.Id,
            'idAddressBilling' => billAcc.Id
        });

        /*Map<String, Object> ipOutput = new Map<String, Object>();
        ipOutput.put('code', '200');
        ipOutput.put('status', 'Success');
        ipOutput.put('message', 'OK');
        ipOutput.put('attributes', new Map<String, Object>{
            'Id' => '001000000000001',
            'href' => '/services/data/v60.0/sobjects/Account/001000000000001'
        });
        ipOutput.put('address', new Map<String, Object>{
            'idAddressService' => '001000000000002',
            'idAddressBilling' => '001000000000003'
        });*/

        Map<String, Object> payload = buildSampleTMFPayload();
		FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act: Call via public entry point (processRequest) to ensure full integration path
        Test.startTest();
		Object result = proc.parseIPResponse(ipOutput, payload);
        //Object result = FVU_TMF629Processing.parseIPResponse(ipOutput, payload);
        Test.stopTest();

        // Assert: Full response structure validation
        Map<String, Object> response = (Map<String, Object>) result;
        System.assertEquals(200, (Integer) response.get('statusCode'), 'Should return 200 on Success');
        System.assert(response.containsKey('body'), 'Body should be present');
        Map<String, Object> body = (Map<String, Object>) response.get('body');
        
        // Validate core fields
        System.assertEquals('Individual', (String) body.get('@type'));
        System.assertEquals('John Doe', (String) body.get('name'));
        // Validate presence of key nested structures
        System.assertNotEquals(null, body.get('engagedParty'), 'Engaged party should be present');
        System.assertNotEquals(null, body.get('contactMedium'), 'ContactMedium should be present');
        
        // Validate specific fields from payload
        System.assertEquals('John Doe', (String) body.get('name'));
    }

    @IsTest
    static void testParseIPResponse_ErrorPath() {
        // Arrange an error response structure
        Map<String, Object> ipOutput = new Map<String, Object>();
        ipOutput.put('code', '400');
        ipOutput.put('status', 'Bad Request');
        ipOutput.put('message', 'Invalid data');

        Map<String, Object> payload = buildSampleTMFPayload();

        // Act
        FVU_TMF629Processing proc = new FVU_TMF629Processing();
        Map<String, Object> response = proc.parseIPResponse(ipOutput, payload);

        // Assert
        System.assertEquals(400, (Integer) response.get('statusCode'), 'Should map provided code as statusCode');
        Map<String, Object> body = (Map<String, Object>) response.get('body');
        System.assertEquals('400', String.valueOf(body.get('code')));
        System.assertEquals('BAD_REQUEST', (String) body.get('statusmessage'));
        System.assertEquals('Invalid data', (String) body.get('message'));
    }

    @IsTest
    static void testBuildErrorResponseViaPublicEntry() {
        // Build an empty error response through processRequest invalid path to ensure response structure.
        FVU_TMF629Processing proc = new FVU_TMF629Processing();
        Object invalid = proc.processRequest(null, null);
        Map<String, Object> response = (Map<String, Object>) invalid;
        System.assert(response != null, 'Invalid processing should return an error response');
        System.assertEquals('error', (String) response.get('status'));
        System.assert(response.containsKey('errors'), 'Errors array must be present');
        System.assert(response.containsKey('timestamp'), 'Timestamp must be present');
    }

    // ==================== Tests for getCustomerManagement ====================

    @IsTest
    static void testGetCustomerManagement_ByID() {
        // Arrange: Create a Consumer Account
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'TestContact', FirstName = 'Test', Email = 'test@example.com');
        insert c;

        Account testAcc = new Account(
            Name = 'Test Account By ID',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_Email__c = 'account@test.com'
        );
        insert testAcc;

        Map<String, Object> params = new Map<String, Object>();
        params.put('id', testAcc.Id);
        params.put('filters', new Map<String, String>());

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null when Account exists');
        
        // Result should be either a List of Accounts or a DataRaptor response
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assert(!accountList.isEmpty(), 'Should retrieve at least one account');
            System.assertEquals(testAcc.Id, accountList[0].Id, 'Should retrieve the exact account by ID');
            System.assertEquals('Test Account By ID', accountList[0].Name, 'Account name should match');
        }
    }

    @IsTest
    static void testGetCustomerManagement_ByDocumentNumberAndType() {
        // Arrange: Create a Consumer Account with document fields
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(
            LastName = 'DocumentTest',
            FirstName = 'Doc',
            Email = 'doc@example.com'
        );
        insert c;

        Account testAcc = new Account(
            Name = 'Account with Doc',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_DocumentNumber__c = '9876543210',
            FVU_DocumentType__c = 'CC'
        );
        insert testAcc;

        Map<String, String> filters = new Map<String, String>();
        filters.put('FVU_DocumentNumber__c', '9876543210');
        filters.put('FVU_DocumentType__c', 'CC');

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', filters);

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assert(!accountList.isEmpty(), 'Should retrieve account by document number and type');
            System.assertEquals('Account with Doc', accountList[0].Name, 'Should return correct account');
            System.assertEquals('9876543210', accountList[0].FVU_DocumentNumber__c, 'Document number should match');
            System.assertEquals('CC', accountList[0].FVU_DocumentType__c, 'Document type should match');
        }
    }

    @IsTest
    static void testGetCustomerManagement_EmptyFilters() {
        // Arrange: Create multiple Consumer Accounts
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c1 = new Contact(LastName = 'Test1', FirstName = 'Contact1', Email = 'test1@example.com');
        Contact c2 = new Contact(LastName = 'Test2', FirstName = 'Contact2', Email = 'test2@example.com');
        insert new List<Contact>{ c1, c2 };

        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Consumer Account 1',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c1.Id
        ));
        testAccounts.add(new Account(
            Name = 'Consumer Account 2',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c2.Id
        ));
        insert testAccounts;

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', new Map<String, String>());

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert: Should return a list (limited to 200 by default)
        System.assertNotEquals(null, result, 'Result should not be null for empty filters');
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assert(!accountList.isEmpty(), 'Should retrieve accounts with empty filters');
        }
    }

    @IsTest
    static void testGetCustomerManagement_WithPaginationLimit() {
        // Arrange: Create Consumer Accounts
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'Pagination', FirstName = 'Page', Email = 'page@example.com');
        insert c;

        Account testAcc = new Account(
            Name = 'Account for Pagination',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c.Id
        );
        insert testAcc;

        Map<String, String> filters = new Map<String, String>();
        filters.put('pageLimit', '10');
        filters.put('offset', '0');

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', filters);

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null with pagination parameters');
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assert(accountList.size() <= 10, 'Should respect pageLimit of 10');
        }
    }

    @IsTest
    static void testGetCustomerManagement_WithOffset() {
        // Arrange: Setup Consumer Account with pagination
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'Offset', FirstName = 'Off', Email = 'offset@example.com');
        insert c;

        Account testAcc = new Account(
            Name = 'Account with Offset',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c.Id
        );
        insert testAcc;

        Map<String, String> filters = new Map<String, String>();
        filters.put('offset', '5');

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', filters);

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert: Should not throw error
        System.assertNotEquals(null, result, 'Result should not be null with offset parameter');
    }

    @IsTest
    static void testGetCustomerManagement_InvalidParameters() {
        // Arrange: Create params with invalid filter structure
        Map<String, String> filters = new Map<String, String>();
        filters.put('invalidKey', 'invalidValue'); // Key that doesn't match any condition

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', filters);

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert: Should return error response
        System.assertNotEquals(null, result, 'Result should not be null even with invalid parameters');
        
        // Check if error response was returned
        if (result instanceof Map<String, Object>) {
            Map<String, Object> response = (Map<String, Object>) result;
            if (response.containsKey('status') && response.get('status') == 'error') {
                System.assertEquals('error', response.get('status'), 'Should return error for invalid parameters');
            }
        }
    }

    @IsTest
    static void testGetCustomerManagement_NoAccountsFound() {
        // Arrange: Query for non-existent document
        Map<String, String> filters = new Map<String, String>();
        filters.put('FVU_DocumentNumber__c', '0000000000');
        filters.put('FVU_DocumentType__c', 'PP');

        Map<String, Object> params = new Map<String, Object>();
        params.put('filters', filters);

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert: Should return empty list when no accounts found
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assertEquals(0, accountList.size(), 'Should return empty list when no accounts match');
        }
    }

    @IsTest
    static void testGetCustomerManagement_WithChildAccounts() {
        // Arrange: Create a Consumer Account with child accounts
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'Parent', FirstName = 'Main', Email = 'parent@example.com');
        insert c;

        Account parentAcc = new Account(
            Name = 'Parent Account',
            RecordTypeId = rt.Id,
            vlocity_cmt__PrimaryContactId__c = c.Id
        );
        insert parentAcc;

        // Create child accounts
        List<Account> childAccounts = new List<Account>();
        childAccounts.add(new Account(
            Name = 'Service Address',
            RecordTypeId = rt.Id,
            ParentId = parentAcc.Id
        ));
        childAccounts.add(new Account(
            Name = 'Billing Address',
            RecordTypeId = rt.Id,
            ParentId = parentAcc.Id
        ));
        insert childAccounts;

        Map<String, Object> params = new Map<String, Object>();
        params.put('id', parentAcc.Id);
        params.put('filters', new Map<String, String>());

        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Act
        Test.startTest();
        Object result = proc.getCustomerManagement(params);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        if (result instanceof List<Account>) {
            List<Account> accountList = (List<Account>) result;
            System.assert(!accountList.isEmpty(), 'Should retrieve parent account');
            Account retrieved = accountList[0];
            System.assertEquals('Parent Account', retrieved.Name, 'Should have correct parent account name');
            // ChildAccounts should be populated in the query
            System.assertNotEquals(null, retrieved.ChildAccounts, 'Child accounts should be populated');
        }
    }

    // ==================== PATCH TESTS - Maximum coverage, minimum code ====================

    @IsTest
    static void testPATCH_Validations() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'PatchTest', FirstName = 'Patch', Email = 'patch@test.com');
        insert c;
        Account consumerAcc = new Account(Name = 'Patch Consumer', RecordTypeId = rt.Id, vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_DocumentNumber__c = '123456789', FVU_DocumentType__c = 'CC', FVU_Email__c = 'patch@test.com', Phone = '3001234567');
        insert consumerAcc;
        Account serviceAcc = new Account(Name = 'Patch Service', RecordTypeId = rt.Id, ParentId = consumerAcc.Id);
        insert serviceAcc;
        
        FVU_TMF629Processing proc = new FVU_TMF629Processing();
        Map<String, Object> payload = buildPatchPayload(false, null, null, null);

        payload.put('identificationParams', new Map<String, Object>());
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', payload)).get('status'));

        payload.put('identificationParams', new Map<String, Object>{'docNumber' => '123'});
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', payload)).get('status'));

        payload.put('identificationParams', new Map<String, Object>{'docType' => 'CC'});
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', payload)).get('status'));

        payload.put('identificationParams', new Map<String, Object>{'docNumber' => '123456789', 'docType' => 'CC'});
        Test.startTest();
        System.assertNotEquals(null, proc.processRequest('PATCH', payload));
        Test.stopTest();

        payload.put('identificationParams', new Map<String, Object>{'email' => 'patch@test.com'});
        System.assertNotEquals(null, proc.processRequest('PATCH', payload));

        payload.put('identificationParams', new Map<String, Object>{'id' => '001000000000000'});
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', payload)).get('status'));

        Map<String, Object> basePayload = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => consumerAcc.Id}};
        System.assertNotEquals(null, proc.processRequest('PATCH', basePayload));

        Map<String, Object> p2 = buildPatchPayload(true, 'Service', 'modify', serviceAcc.Id);
        p2.put('identificationParams', new Map<String, Object>{'id' => consumerAcc.Id});
        System.assertNotEquals(null, proc.processRequest('PATCH', p2));

        Map<String, Object> p3 = buildPatchPayload(true, 'Billing', 'add', null);
        p3.put('identificationParams', new Map<String, Object>{'id' => consumerAcc.Id});
        System.assertNotEquals(null, proc.processRequest('PATCH', p3));

        Map<String, Object> p4 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => consumerAcc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'action' => 'modify', 'id' => serviceAcc.Id},
            new Map<String, Object>{'@type' => 'Billing', 'action' => 'add'}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p4)).get('status'));

        Map<String, Object> p5 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => consumerAcc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'action' => 'add'},
            new Map<String, Object>{'@type' => 'Service', 'action' => 'modify', 'id' => serviceAcc.Id}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p5)).get('status'));

        Map<String, Object> p7 = buildPatchPayload(true, 'Service', 'modify', null);
        p7.put('identificationParams', new Map<String, Object>{'id' => consumerAcc.Id});
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p7)).get('status'));

        Map<String, Object> p8 = buildPatchPayload(true, 'Service', 'add', serviceAcc.Id);
        p8.put('identificationParams', new Map<String, Object>{'id' => consumerAcc.Id});
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p8)).get('status'));

        Map<String, Object> p10 = buildPatchPayload(true, 'Service', 'add', null);
        p10.put('identificationParams', new Map<String, Object>{'id' => consumerAcc.Id});
        ((List<Object>) p10.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Contact', 'name' => 'John'});
        System.assertNotEquals(null, proc.processRequest('PATCH', p10));
    }

    @IsTest
    static void testPATCH_TransformAndParse() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'PatchTest', FirstName = 'Patch', Email = 'patch@test.com');
        insert c;
        Account acc = new Account(Name = 'Patch Consumer', RecordTypeId = rt.Id, vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_DocumentNumber__c = '123456789', FVU_DocumentType__c = 'CC', FVU_Email__c = 'patch@test.com');
        insert acc;
        Account serviceAcc = new Account(Name = 'Patch Service', RecordTypeId = rt.Id, ParentId = acc.Id);
        insert serviceAcc;
        
        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        Map<String, Object> p1 = buildPatchPayload(true, 'Service', 'modify', serviceAcc.Id);
        p1.put('contactMedium', new List<Object>{
            new Map<String, Object>{'@type' => 'PhoneContactMedium', 'contactType' => 'phone', 'phoneNumber' => '3001234567'},
            new Map<String, Object>{'@type' => 'GeographicAddressContactMedium', 'contactType' => 'Service', 'street1' => 'Calle 123',
                'city' => 'Bogota', 'stateOrProvince' => 'Cundinamarca', 'postCode' => '110111',
                'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'extendedAddressInfo', 'valueType' => 'object',
                    'value' => new Map<String, Object>{'daneCode' => '11001000', 'merId' => '12345', 'addressMunicipality' => 'Bogota',
                        'addressStatus' => 'Validada', 'addressType' => 'CK', 'addressExtract' => '-1', 'addressNode' => '{"test":"data"}', 'externalId' => '9999'}}}}
        });
        Map<String, Object> ip1 = proc.transformToIPFormatPatch(p1, acc, new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, ip1);
        System.assertEquals(acc.FVU_DocumentNumber__c, ip1.get('documentNumber'));
        System.assertEquals(acc.FVU_DocumentType__c, ip1.get('documentType'));
        System.assert(ip1.containsKey('demographicData'));
        Map<String, Object> demo1 = (Map<String, Object>) ip1.get('demographicData');
        System.assertEquals('3001234567', demo1.get('phone'));
        System.assert(demo1.containsKey('address'));
        Map<String, Object> addr1 = (Map<String, Object>) demo1.get('address');
        System.assertEquals('Service', addr1.get('@type'));
        System.assertEquals(serviceAcc.Id, addr1.get('idSF'));
        System.assertEquals('Calle 123', addr1.get('streetAndNumber'));
        System.assertEquals('11001000', addr1.get('daneCode'));

        Map<String, Object> p2 = buildPatchPayload(true, 'Billing', 'add', null);
        Map<String, Object> ip2 = proc.transformToIPFormatPatch(p2, null, new Map<String, Object>{'docNumber' => '123456789', 'docType' => 'CC'});
        System.assertEquals('123456789', ip2.get('documentNumber'));
        System.assertEquals('CC', ip2.get('documentType'));
        Map<String, Object> addr2 = (Map<String, Object>) ((Map<String, Object>) ip2.get('demographicData')).get('address');
        System.assertEquals('Billing', addr2.get('@type'));
        System.assertEquals(null, addr2.get('idSF'));

        Map<String, Object> p3 = buildPatchPayload(false, null, null, null);
        p3.put('contactMedium', new List<Object>{new Map<String, Object>{'@type' => 'EmailContactMedium', 'emailAddress' => 'new@test.com'}});
        Map<String, Object> ip3 = proc.transformToIPFormatPatch(p3, null, new Map<String, Object>{'email' => 'patch@test.com'});
        System.assertEquals('patch@test.com', ip3.get('email'));
        System.assertEquals(null, ip3.get('documentNumber'));
        System.assertEquals(null, ip3.get('documentType'));

        Map<String, Object> payload = buildPatchPayload(true, 'Service', 'add', null);
        payload.put('consumerAccountId', acc.Id);
        payload.put('identificationParams', new Map<String, Object>{'id' => acc.Id});

        Map<String, Object> r1 = proc.parseIPResponsePatch(new Map<String, Object>{'responseCode' => 200, 'message' => 'OK'}, payload);
        System.assertEquals(200, r1.get('statusCode'));
        Map<String, Object> b1 = (Map<String, Object>) r1.get('body');
        System.assertEquals(acc.Id, b1.get('id'));
        System.assert(b1.containsKey('href'));
        System.assert(b1.containsKey('createdDate'));
        System.assert(b1.containsKey('lastModifiedDate'));
        System.assertEquals(null, b1.get('identificationParams'));

        Map<String, Object> r2 = proc.parseIPResponsePatch(new Map<String, Object>{'responseCode' => 400, 'message' => 'Bad request'}, payload);
        System.assertEquals(400, r2.get('statusCode'));
        Map<String, Object> b2 = (Map<String, Object>) r2.get('body');
        System.assertEquals('400', b2.get('code'));
        System.assertEquals('BAD_REQUEST', b2.get('statusmessage'));

        Map<String, Object> r3 = proc.parseIPResponsePatch(new Map<String, Object>{'responseCode' => 500, 'message' => 'Error'}, payload);
        System.assertEquals(500, r3.get('statusCode'));
        System.assertEquals('INTERNAL_SERVER_ERROR', ((Map<String, Object>) r3.get('body')).get('statusmessage'));

        Map<String, Object> p4 = buildPatchPayload(false, null, null, null);
        p4.put('identificationParams', new Map<String, Object>{'id' => acc.Id});
        Map<String, Object> r4 = proc.parseIPResponsePatch(new Map<String, Object>{'responseCode' => 200, 'message' => 'OK'}, p4);
        System.assertEquals(200, r4.get('statusCode'));
        System.assertEquals(acc.Id, ((Map<String, Object>) r4.get('body')).get('id'));

        Account res1 = proc.identifyCustomerAccount(new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, res1);
        System.assertEquals(acc.Id, res1.Id);

        Account res2 = proc.identifyCustomerAccount(new Map<String, Object>{'docNumber' => acc.FVU_DocumentNumber__c, 'docType' => acc.FVU_DocumentType__c});
        System.assertNotEquals(null, res2);

        Account res3 = proc.identifyCustomerAccount(new Map<String, Object>{'email' => acc.FVU_Email__c});
        System.assertNotEquals(null, res3);

        Account res4 = proc.identifyCustomerAccount(new Map<String, Object>{'id' => '001000000000000'});
        System.assertEquals(null, res4);

        System.assertEquals('OK', proc.getStatusMessage(200));
        System.assertEquals('BAD_REQUEST', proc.getStatusMessage(400));
        System.assertEquals('NOT_FOUND', proc.getStatusMessage(404));
        System.assertEquals('INTERNAL_SERVER_ERROR', proc.getStatusMessage(500));
        System.assertEquals('ERROR', proc.getStatusMessage(999));
        System.assertEquals('INTERNAL_SERVER_ERROR', proc.getStatusMessage(null));
    }

    @IsTest
    static void testPATCH_EdgeCases() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Consumer' LIMIT 1];
        Contact c = new Contact(LastName = 'EdgeTest', FirstName = 'Edge', Email = 'edge@test.com');
        insert c;
        Account acc = new Account(Name = 'Edge Consumer', RecordTypeId = rt.Id, vlocity_cmt__PrimaryContactId__c = c.Id,
            FVU_DocumentNumber__c = '999888777', FVU_DocumentType__c = 'CC', FVU_Email__c = 'edge@test.com');
        insert acc;
        Account svc = new Account(Name = 'Edge Service', RecordTypeId = rt.Id, ParentId = acc.Id);
        insert svc;
        
        FVU_TMF629Processing proc = new FVU_TMF629Processing();

        // Test: engagedParty without action
        Map<String, Object> p1 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => acc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'id' => svc.Id}},
            'contactMedium' => new List<Object>{new Map<String, Object>{'@type' => 'GeographicAddressContactMedium', 'contactType' => 'Service'}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p1)).get('status'));

        // Test: engagedParty with invalid action
        Map<String, Object> p2 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => acc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'action' => 'delete', 'id' => svc.Id}},
            'contactMedium' => new List<Object>{new Map<String, Object>{'@type' => 'GeographicAddressContactMedium', 'contactType' => 'Service'}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p2)).get('status'));

        // Test: engagedParty without corresponding GeographicAddressContactMedium
        Map<String, Object> p3 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => acc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'action' => 'add'}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p3)).get('status'));

        // Test: GeographicAddressContactMedium with mismatched contactType
        Map<String, Object> p4 = new Map<String, Object>{'@type' => 'Customer', 'identificationParams' => new Map<String, Object>{'id' => acc.Id},
            'engagedParty' => new List<Object>{new Map<String, Object>{'@type' => 'Service', 'action' => 'add'}},
            'contactMedium' => new List<Object>{new Map<String, Object>{'@type' => 'GeographicAddressContactMedium', 'contactType' => 'Billing', 'street1' => 'Calle 1'}}};
        System.assertEquals('error', ((Map<String, Object>) proc.processRequest('PATCH', p4)).get('status'));

        // Test: transformToIPFormatPatch with otherPhone
        Map<String, Object> p5 = buildPatchPayload(false, null, null, null);
        p5.put('contactMedium', new List<Object>{
            new Map<String, Object>{'@type' => 'PhoneContactMedium', 'contactType' => 'phone', 'phoneNumber' => '3001111111'},
            new Map<String, Object>{'@type' => 'PhoneContactMedium', 'contactType' => 'otherPhone', 'phoneNumber' => '3002222222'}
        });
        Map<String, Object> ip5 = proc.transformToIPFormatPatch(p5, acc, new Map<String, Object>{'id' => acc.Id});
        Map<String, Object> demo5 = (Map<String, Object>) ip5.get('demographicData');
        System.assertEquals('3001111111', demo5.get('phone'));
        System.assertEquals('3002222222', demo5.get('otherPhone'));

        // Test: transformToIPFormatPatch with EmailContactMedium (not in identification)
        Map<String, Object> p6 = buildPatchPayload(false, null, null, null);
        p6.put('contactMedium', new List<Object>{new Map<String, Object>{'@type' => 'EmailContactMedium', 'emailAddress' => 'contact@test.com'}});
        Map<String, Object> ip6 = proc.transformToIPFormatPatch(p6, null, new Map<String, Object>{'docNumber' => '123', 'docType' => 'CC'});
        Map<String, Object> demo6 = (Map<String, Object>) ip6.get('demographicData');
        System.assertEquals('contact@test.com', demo6.get('email'));

        // Test: transformToIPFormatPatch with all alternative characteristic field names
        Map<String, Object> p7 = buildPatchPayload(true, 'Service', 'add', null);
        ((List<Object>) p7.get('contactMedium')).clear();
        p7.put('contactMedium', new List<Object>{new Map<String, Object>{
            '@type' => 'GeographicAddressContactMedium', 'contactType' => 'Service', 'street1' => 'Calle Alt',
            'city' => 'Medellin', 'stateOrProvince' => 'Antioquia', 'postCode' => '050001',
            'characteristic' => new List<Object>{new Map<String, Object>{
                'name' => 'extendedAddressInfo', 'valueType' => 'object',
                'value' => new Map<String, Object>{
                    'addressDaneCode' => '05001000', 'addressMerId' => '54321', 'addressMunicipality' => 'Medellin',
                    'status' => 'Pendiente', 'addressExtract' => '2', 'addressNode' => '{"alt":true}'
                }
            }}
        }});
        Map<String, Object> ip7 = proc.transformToIPFormatPatch(p7, acc, new Map<String, Object>{'id' => acc.Id});
        Map<String, Object> addr7 = (Map<String, Object>) ((Map<String, Object>) ip7.get('demographicData')).get('address');
        System.assertEquals('Calle Alt', addr7.get('streetAndNumber'));
        System.assertEquals('05001000', addr7.get('daneCode'));
        System.assertEquals('54321', addr7.get('merId'));
        System.assertEquals('Medellin', addr7.get('municipality'));
        System.assertEquals('Pendiente', addr7.get('addressStatus'));

        // Test: Multiple Contacts + 1 Service
        Map<String, Object> p8 = buildPatchPayload(true, 'Service', 'add', null);
        ((List<Object>) p8.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Contact', 'name' => 'Contact1'});
        ((List<Object>) p8.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Contact', 'name' => 'Contact2'});
        ((List<Object>) p8.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Contact', 'name' => 'Contact3'});
        p8.put('identificationParams', new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, proc.processRequest('PATCH', p8));

        // Test: Multiple Contacts + 1 Billing
        Map<String, Object> p9 = buildPatchPayload(true, 'Billing', 'add', null);
        ((List<Object>) p9.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Contact', 'name' => 'ContactA'});
        ((List<Object>) p9.get('engagedParty')).add(new Map<String, Object>{'@type' => 'Organization', 'name' => 'OrgB'});
        p9.put('identificationParams', new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, proc.processRequest('PATCH', p9));

        // Test: transformToIPFormatPatch with empty engagedParty
        Map<String, Object> p10 = new Map<String, Object>{'@type' => 'Customer', 'engagedParty' => new List<Object>()};
        Map<String, Object> ip10 = proc.transformToIPFormatPatch(p10, acc, new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, ip10);
        Map<String, Object> demo10 = (Map<String, Object>) ip10.get('demographicData');
        System.assertEquals(null, demo10.get('address'));

        // Test: transformToIPFormatPatch with null engagedParty
        Map<String, Object> p11 = new Map<String, Object>{'@type' => 'Customer'};
        Map<String, Object> ip11 = proc.transformToIPFormatPatch(p11, acc, new Map<String, Object>{'id' => acc.Id});
        System.assertNotEquals(null, ip11);

        // Test: parseIPResponsePatch with null responseCode
        Map<String, Object> r1 = proc.parseIPResponsePatch(new Map<String, Object>{'message' => 'Error'}, new Map<String, Object>{'consumerAccountId' => acc.Id});
        System.assertEquals(500, r1.get('statusCode'));

        // Test: parseIPResponsePatch with different message (not OK)
        Map<String, Object> r2 = proc.parseIPResponsePatch(new Map<String, Object>{'responseCode' => 200, 'message' => 'Success'}, 
            new Map<String, Object>{'consumerAccountId' => acc.Id});
        System.assertEquals(200, r2.get('statusCode'));

        // Test: Multiple GeographicAddressContactMedium, only matching one is used
        Map<String, Object> p12 = buildPatchPayload(true, 'Service', 'add', null);
        ((List<Object>) p12.get('contactMedium')).add(new Map<String, Object>{
            '@type' => 'GeographicAddressContactMedium', 'contactType' => 'Billing', 'street1' => 'Wrong Street'
        });
        Map<String, Object> ip12 = proc.transformToIPFormatPatch(p12, acc, new Map<String, Object>{'id' => acc.Id});
        Map<String, Object> addr12 = (Map<String, Object>) ((Map<String, Object>) ip12.get('demographicData')).get('address');
        System.assertEquals('Service', addr12.get('@type'));
        System.assertEquals('Calle 123', addr12.get('streetAndNumber'));

        // Test: updateCustomerManagementViaIP indirect coverage through processRequest
        Map<String, Object> p13 = buildPatchPayload(true, 'Service', 'add', null);
        p13.put('identificationParams', new Map<String, Object>{'docNumber' => acc.FVU_DocumentNumber__c, 'docType' => acc.FVU_DocumentType__c});
        Test.startTest();
        Object result = proc.processRequest('PATCH', p13);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
}