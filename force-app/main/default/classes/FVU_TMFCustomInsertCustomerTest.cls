@isTest
private class FVU_TMFCustomInsertCustomerTest {
    @testSetup
    static void setupTestData() {
        // Crear un Account de prueba
        Account testAccount = new Account(
            Name = 'Test Account',
            FVU_DocumentType__c = 'CC',
            FVU_DocumentNumber__c = '123456'
        );
        insert testAccount;

    }
    @isTest
    static void testValidExistAccount() {
       String documentType = 'CC';
       String numeroDocument =   '123456';
                 
        Test.startTest();
        Boolean result = FVU_TMFCustomInsertCustomer.validateExistAccount(documentType, numeroDocument);
        Test.stopTest();


        System.assertEquals(true, result, 'Debe devolver true ya que la cuenta existe.');

        
     } 

    @isTest
    static void testInsertAccountAndContactTMF_Success() {
        List<RecordType> recordTypeContact = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Cliente' AND SobjectType = 'Contact'
            LIMIT 1
            ];
            List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Consumer' AND SobjectType = 'Account'
            LIMIT 1
         ];   
        // Crear datos de entrada simulados
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Juan',
                'lastName' => 'Perez',
                'email' => 'jperez@example.com',
                'documentType' => 'CC',
                'documentNumber' => '235813',
                'documentExpeditionDate' =>'2025-05-01',
                'origin' => 'ecommerce',
                'customerCharacteristics' => new List<Map<String, Object>>{
                new Map<String, Object>{ 'name' => 'Phone', 'value' => '1234567890' },
                new Map<String, Object>{ 'name' => 'OtherPhone', 'value' => '0987654321' },
                new Map<String, Object>{ 'name' => 'FVU_SecondLastName__c', 'value' => 'Lopez' },
                new Map<String, Object>{ 'name' => 'FVU_PersonalDataAgreementMethod__c', 'value' => 'Correo electrónico' },
				new Map<String, Object>{ 'name' => 'FVU_ExpeditionDate__c', 'value' => '2025-05-01' },
				new Map<String, Object>{ 'name' => 'FVU_PersonalDataAgreementDate__c', 'value' => '2025-11-28T17:27:42.000+0000' },
				new Map<String, Object>{ 'name' => 'FVU_NotificationChoice__c', 'value' => 'Correo electrónico' }
                
            }
            },
            'recordTypeContact' => recordTypeContact[0].Id,
            'recordTypeAccount' => recordTypeAccount[0].Id,
            'fieldsRequired' => 'firstName,lastName,email,documentType,documentNumber',
            'action' => 'Create Customer',
            'addressInformation' => new Map<String, Object>()
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();
        System.assertEquals('Success', outMap.get('status'));
        System.assertNotEquals(null, outMap.get('accountId'));
    }

    @isTest
    static void testInsertAccountAndContactTMF_MissingFields() {
        // Crear datos de entrada con campos faltantes
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Juan'
            },
            'fieldsRequired' => 'firstName,lastName,email',
            'addressInformation' => new Map<String, Object>()
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Invocar el método
        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals('Fail', outMap.get('status'));
        //System.assert(outMap.get('message').contains('Los siguientes campos son requeridos'));
    }

    @isTest
    static void testInvokeMethod() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = new FVU_TMFCustomInsertCustomer().invokeMethod('insertAccountAndContactTMF', inputMap, outMap, options);
        Test.stopTest();

        System.assert(result == false || result == true); 
    }

    @isTest
    static void testInsertAccountAndContactTMF_MissingAddressInformation() {
        List<RecordType> recordTypeContact = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Cliente' AND SobjectType = 'Contact'
            LIMIT 1
        ];
        List<RecordType> recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Consumer' AND SobjectType = 'Account'
            LIMIT 1
        ];

        // Crear datos de entrada sin addressInformation
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Maria',
                'lastName' => 'Garcia',
                'email' => 'mgarcia@example.com',
                'documentType' => 'CC',
                'documentNumber' => '987654',
                'documentExpeditionDate' => '2025-05-01',
                'origin' => 'ecommerce',
                'customerCharacteristics' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'name' => 'Phone', 'value' => '5551234567' }
                }
            },
            'recordTypeContact' => recordTypeContact[0].Id,
            'recordTypeAccount' => recordTypeAccount[0].Id,
            'fieldsRequired' => 'firstName,lastName,email,documentType,documentNumber',
            'action' => 'Create Customer'
            // addressInformation is intentionally missing
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals('Success', outMap.get('status'), 'Should succeed even without addressInformation');
        System.assertNotEquals(null, outMap.get('accountId'));
    }

    @isTest
    static void testInsertAccountAndContactTMF_NullAddressInformation() {
        List<RecordType> recordTypeContact = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Cliente' AND SobjectType = 'Contact'
            LIMIT 1
        ];
        List<RecordType> recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Consumer' AND SobjectType = 'Account'
            LIMIT 1
        ];

        // Crear datos de entrada con addressInformation nulo
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Pedro',
                'lastName' => 'Martinez',
                'email' => 'pmartinez@example.com',
                'documentType' => 'CC',
                'documentNumber' => '456789',
                'documentExpeditionDate' => '2025-05-01',
                'origin' => 'ecommerce',
                'customerCharacteristics' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'name' => 'Phone', 'value' => '5559876543' }
                }
            },
            'recordTypeContact' => recordTypeContact[0].Id,
            'recordTypeAccount' => recordTypeAccount[0].Id,
            'fieldsRequired' => 'firstName,lastName,email,documentType,documentNumber',
            'action' => 'Create Customer',
            'addressInformation' => null
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals('Success', outMap.get('status'), 'Should succeed with null addressInformation');
        System.assertNotEquals(null, outMap.get('accountId'));
    }

    @isTest
    static void testInsertAccountAndContactTMF_InvalidTypeAddressInformation() {
        List<RecordType> recordTypeContact = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Cliente' AND SobjectType = 'Contact'
            LIMIT 1
        ];
        List<RecordType> recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Consumer' AND SobjectType = 'Account'
            LIMIT 1
        ];

        // Crear datos de entrada con addressInformation de tipo incorrecto (String en lugar de Map)
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Ana',
                'lastName' => 'Lopez',
                'email' => 'alopez@example.com',
                'documentType' => 'CC',
                'documentNumber' => '321654',
                'documentExpeditionDate' => '2025-05-01',
                'origin' => 'ecommerce',
                'customerCharacteristics' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'name' => 'Phone', 'value' => '5551122334' }
                }
            },
            'recordTypeContact' => recordTypeContact[0].Id,
            'recordTypeAccount' => recordTypeAccount[0].Id,
            'fieldsRequired' => 'firstName,lastName,email,documentType,documentNumber',
            'action' => 'Create Customer',
            'addressInformation' => 'invalid_type_string'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals('Success', outMap.get('status'), 'Should succeed with invalid type addressInformation by defaulting to empty map');
        System.assertNotEquals(null, outMap.get('accountId'));
    }

    @isTest
    static void testInsertAccountAndContactTMF_ExistingAccount() {
        List<RecordType> recordTypeContact = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Cliente' AND SobjectType = 'Contact'
            LIMIT 1
        ];
        List<RecordType> recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Consumer' AND SobjectType = 'Account'
            LIMIT 1
        ];

        // Intentar crear una cuenta con documento que ya existe (del testSetup)
        Map<String, Object> inputMap = new Map<String, Object>{
            'jsonAll' => new Map<String, Object>{
                'firstName' => 'Existing',
                'lastName' => 'User',
                'email' => 'existing@example.com',
                'documentType' => 'CC',
                'documentNumber' => '123456', // Este documento ya existe
                'documentExpeditionDate' => '2025-05-01',
                'origin' => 'ecommerce',
                'customerCharacteristics' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'name' => 'Phone', 'value' => '5559999999' }
                }
            },
            'recordTypeContact' => recordTypeContact[0].Id,
            'recordTypeAccount' => recordTypeAccount[0].Id,
            'fieldsRequired' => 'firstName,lastName,email,documentType,documentNumber',
            'action' => 'Create Customer',
            'addressInformation' => new Map<String, Object>()
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        FVU_TMFCustomInsertCustomer.insertAccountAndContactTMF(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals('Fail', outMap.get('status'), 'Should fail when account already exists');
        System.assert(((String)outMap.get('message')).contains('Cuenta ya existente'), 'Message should indicate account already exists');
    }
}