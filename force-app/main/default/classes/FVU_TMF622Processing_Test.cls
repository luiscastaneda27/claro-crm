/**
 * @description Comprehensive test class for FVU_TMF622Processing
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
@isTest
private class FVU_TMF622Processing_Test {
    
    @testSetup
    static void setupTestData() {
        Account consumerAccount = new Account(Name = 'Test Consumer');
        insert consumerAccount;
        
        Account billingAccount = new Account(Name = 'Test Billing', ParentId = consumerAccount.Id);
        insert billingAccount;
        
        Account serviceAccount = new Account(Name = 'Test Service', ParentId = consumerAccount.Id);
        insert serviceAccount;
        
        Order testOrder = new Order(
            AccountId = consumerAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;
    }
    
    // ========================================
    // CREATE PRODUCT ORDER TESTS (COVERS IP CALL PATH)
    // ========================================
    
    @isTest
    static void testCreateProductOrder_Success() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> payload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>{new Map<String, Object>{'id' => 'ORD-001'}}
        };
        
        Test.startTest();
        Object result = processor.createProductOrder(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testCreateProductOrder_TransformFails() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        Object result = processor.createProductOrder(null);
        Test.stopTest();
        
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals('error', resultMap.get('status'));
    }
    
    // ========================================
    // TRANSFORM TO IP FORMAT - COMPREHENSIVE
    // ========================================
    
	@isTest
    static void testProcessRequest_POST_ValidationFails() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account consumer = [SELECT Id FROM Account LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            '@type' => 'ProductOrder',
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>{new Map<String, Object>{'id' => 'ORD-001', '@type' => 'ExternalIdentifier'}},
            'channel' => new List<Object>{new Map<String, Object>{'role' => 'OriginatingChannel', '@type' => 'RelatedChannel', 'channel' => new Map<String, Object>{'name' => 'ECOMMERCE', '@type' => 'Channel', 'id' => '1'}}},
            'relatedParty' => new List<Object>{new Map<String, Object>{'role' => 'ConsumerAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => consumer.Id}}},
            'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'salesType', 'value' => 'Test'}},
            'payment' => new List<Object>{new Map<String, Object>{'id' => '001', 'paymentDate' => '2025-04-10T19:30:00Z', 'amount' => new Map<String, Object>{'value' => 1000}, 'paymentMethod' => new Map<String, Object>{'id' => '1'}}},
            'productOrderItem' => new List<Object>{new Map<String, Object>{'id' => '1', 'productOffering' => new Map<String, Object>{'id' => 'TEST'}}},
            'quote' => new List<Object>{new Map<String, Object>{'id' => '3650', 'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'FIN_CreditQuota__c', 'value' => 1000000}}}}
        };
        
        Test.startTest();
        Object result = processor.processRequest('POST',tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals('error', resultMap.get('status'), 'Status should be error');
        System.assert(resultMap.containsKey('errors'), 'Should contain errors');
    }
    
    @isTest
    static void testValidateProductOrderItemPositions_SameProductDifferentPosition() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account consumer = [SELECT Id FROM Account LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>{new Map<String, Object>{'id' => 'ORD-001'}},
            'channel' => new List<Object>{new Map<String, Object>{'channel' => new Map<String, Object>{'name' => 'ECOMMERCE'}}},
            'relatedParty' => new List<Object>{new Map<String, Object>{'role' => 'ConsumerAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => consumer.Id}}},
            'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'salesType', 'value' => 'Test'}},
            'payment' => new List<Object>{new Map<String, Object>{'id' => '001', 'paymentDate' => '2025-04-10T19:30:00Z', 'amount' => new Map<String, Object>{'value' => 1000}, 'paymentMethod' => new Map<String, Object>{'id' => '1'}}},
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{'id' => '1', 'action' => 'add', 'quantity' => 1, 'productOffering' => new Map<String, Object>{'id' => 'B2C-TERM-X7A-PLATA-128GB', '@type' => 'ProductOfferingRef'}, 'product' => new Map<String, Object>{'productCharacteristic' => new List<Object>{new Map<String, Object>{'name' => 'position', 'value' => '000010', 'valueType' => 'string', '@type' => 'Characteristic'}, new Map<String, Object>{'name' => 'sequence', 'value' => 1, 'valueType' => 'number', '@type' => 'Characteristic'}}, '@type' => 'ProductRefOrValue'}, '@type' => 'ProductOrderItem'},
                new Map<String, Object>{'id' => '2', 'action' => 'add', 'quantity' => 1, 'productOffering' => new Map<String, Object>{'id' => 'B2C-TERM-X7A-PLATA-128GB', '@type' => 'ProductOfferingRef'}, 'product' => new Map<String, Object>{'productCharacteristic' => new List<Object>{new Map<String, Object>{'name' => 'position', 'value' => '000020', 'valueType' => 'string', '@type' => 'Characteristic'}, new Map<String, Object>{'name' => 'sequence', 'value' => 2, 'valueType' => 'number', '@type' => 'Characteristic'}}, '@type' => 'ProductRefOrValue'}, '@type' => 'ProductOrderItem'}
            },
            'quote' => new List<Object>{new Map<String, Object>{'id' => '3650', 'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'FIN_CreditQuota__c', 'value' => 1000000}}}}
        };
        
        Test.startTest();
        FVU_TMFBase.ValidationResult result = processor.validateProductOrderItemPositions(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isValid, 'Validation should fail');
        System.assert(!result.errors.isEmpty(), 'Should contain errors');
    }
    
    @isTest
    static void testValidateProductOrderItemPositions_DifferentProductSamePosition() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account consumer = [SELECT Id FROM Account LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>{new Map<String, Object>{'id' => 'ORD-001'}},
            'channel' => new List<Object>{new Map<String, Object>{'channel' => new Map<String, Object>{'name' => 'ECOMMERCE'}}},
            'relatedParty' => new List<Object>{new Map<String, Object>{'role' => 'ConsumerAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => consumer.Id}}},
            'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'salesType', 'value' => 'Test'}},
            'payment' => new List<Object>{new Map<String, Object>{'id' => '001', 'paymentDate' => '2025-04-10T19:30:00Z', 'amount' => new Map<String, Object>{'value' => 1000}, 'paymentMethod' => new Map<String, Object>{'id' => '1'}}},
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{'id' => '1', 'action' => 'add', 'quantity' => 1, 'productOffering' => new Map<String, Object>{'id' => 'B2C-TERM-X7A-PLATA-128GB', '@type' => 'ProductOfferingRef'}, 'product' => new Map<String, Object>{'productCharacteristic' => new List<Object>{new Map<String, Object>{'name' => 'position', 'value' => '000010', 'valueType' => 'string', '@type' => 'Characteristic'}, new Map<String, Object>{'name' => 'sequence', 'value' => 1, 'valueType' => 'number', '@type' => 'Characteristic'}}, '@type' => 'ProductRefOrValue'}, '@type' => 'ProductOrderItem'},
                new Map<String, Object>{'id' => '2', 'action' => 'add', 'quantity' => 1, 'productOffering' => new Map<String, Object>{'id' => 'B2C-TERM-X7A-PLATA-256GB', '@type' => 'ProductOfferingRef'}, 'product' => new Map<String, Object>{'productCharacteristic' => new List<Object>{new Map<String, Object>{'name' => 'position', 'value' => '000010', 'valueType' => 'string', '@type' => 'Characteristic'}, new Map<String, Object>{'name' => 'sequence', 'value' => 2, 'valueType' => 'number', '@type' => 'Characteristic'}}, '@type' => 'ProductRefOrValue'}, '@type' => 'ProductOrderItem'}
            },
            'quote' => new List<Object>{new Map<String, Object>{'id' => '3650', 'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'FIN_CreditQuota__c', 'value' => 1000000}}}}
        };
        
        Test.startTest();
        FVU_TMFBase.ValidationResult result = processor.validateProductOrderItemPositions(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.isValid, 'Validation should fail');
        System.assert(!result.errors.isEmpty(), 'Should contain errors');
    }
    
    @isTest
    static void testTransformToIPFormat_AllFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account consumer = [SELECT Id FROM Account LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>{new Map<String, Object>{'id' => 'ORD-001'}},
            'channel' => new List<Object>{new Map<String, Object>{'channel' => new Map<String, Object>{'name' => 'ECOMMERCE'}}},
            'relatedParty' => new List<Object>{new Map<String, Object>{'role' => 'ConsumerAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => consumer.Id}}},
            'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'salesType', 'value' => 'Test'}},
            'payment' => new List<Object>{new Map<String, Object>{'id' => '001', 'paymentDate' => '2025-04-10T19:30:00Z', 'amount' => new Map<String, Object>{'value' => 1000}, 'paymentMethod' => new Map<String, Object>{'id' => '1'}}},
            'productOrderItem' => new List<Object>{new Map<String, Object>{'id' => '1', 'productOffering' => new Map<String, Object>{'id' => 'TEST'}}},
            'quote' => new List<Object>{new Map<String, Object>{'id' => '3650', 'characteristic' => new List<Object>{new Map<String, Object>{'name' => 'FIN_CreditQuota__c', 'value' => 1000000}}}}
        };
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('EnterpriseOrder', result.get('@type'));
        System.assertEquals('ORD-001', result.get('storeOrderId'));
        System.assertEquals('ECOMMERCE', result.get('channel'));
        System.assert(result.containsKey('orderPayments'));
        System.assert(result.containsKey('products'));
        System.assert(result.containsKey('financingDetails'));
    }
    
    @isTest
    static void testTransformToIPFormat_EmptyArrays() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'externalId' => new List<Object>(),
            'channel' => new List<Object>(),
            'relatedParty' => new List<Object>(),
            'characteristic' => new List<Object>(),
            'payment' => new List<Object>(),
            'productOrderItem' => new List<Object>(),
            'quote' => new List<Object>()
        };
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testTransformToIPFormat_ExceptionHandling() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(null);
        Test.stopTest();
        
        System.assertEquals(null, result);
    }
    
    @isTest
    static void testTransformToIPFormat_CategoryOnly() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{'category' => 'EnterpriseOrder'};
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertEquals('EnterpriseOrder', result.get('@type'));
    }
    
    @isTest
    static void testTransformToIPFormat_ExternalIdMultiple() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'externalId' => new List<Object>{
                new Map<String, Object>{'id' => 'ORD-001'},
                new Map<String, Object>{'id' => 'ORD-002'}
            }
        };
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertEquals('ORD-001', result.get('storeOrderId'));
    }
    
    @isTest
    static void testTransformToIPFormat_ChannelWithoutName() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'channel' => new List<Object>{
                new Map<String, Object>{'channel' => new Map<String, Object>{'id' => '1'}}
            }
        };
        
        Test.startTest();
        Map<String, Object> result = processor.transformToIPFormat(tmfPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    // ========================================
    // PROCESS RELATED PARTIES - EDGE CASES
    // ========================================
    
    @isTest
    static void testProcessRelatedParties_AllSixRoles() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account consumer = [SELECT Id FROM Account WHERE Name = 'Test Consumer' LIMIT 1];
        Account billing = [SELECT Id FROM Account WHERE Name = 'Test Billing' LIMIT 1];
        Account service = [SELECT Id FROM Account WHERE Name = 'Test Service' LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'ConsumerAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => consumer.Id}},
                new Map<String, Object>{'role' => 'BillingAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => billing.Id}},
                new Map<String, Object>{'role' => 'ServiceAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => service.Id}},
                new Map<String, Object>{'role' => 'ExternalAccount93', 'partyOrPartyRole' => new Map<String, Object>{'id' => '93000000055932'}},
                new Map<String, Object>{'role' => 'ExternalAccount91', 'partyOrPartyRole' => new Map<String, Object>{'id' => '91000000070914'}},
                new Map<String, Object>{'role' => 'ExternalAccount92', 'partyOrPartyRole' => new Map<String, Object>{'id' => '92000000099844'}}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processRelatedParties(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assertEquals(consumer.Id, ipPayload.get('customerIdSF'));
        System.assertEquals('93000000055932', ipPayload.get('externalAccount93'));
        System.assertEquals('91000000070914', ipPayload.get('externalAccount91'));
        System.assertEquals('92000000099844', ipPayload.get('externalAccount92'));
        System.assert(ipPayload.containsKey('orderCharacteristic'));
    }
    
    @isTest
    static void testProcessRelatedParties_WithExistingOrderCharacteristic() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Account billing = [SELECT Id FROM Account WHERE Name = 'Test Billing' LIMIT 1];
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'BillingAccount', 'partyOrPartyRole' => new Map<String, Object>{'id' => billing.Id}}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>{
            'orderCharacteristic' => new List<Map<String, Object>>{
                new Map<String, Object>{'name' => 'existing', 'value' => 'test'}
            }
        };
        
        Test.startTest();
        processor.processRelatedParties(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> chars = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
        System.assertEquals(2, chars.size());
    }
    
    @isTest
    static void testProcessRelatedParties_WithoutPartyOrPartyRole() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{'role' => 'ConsumerAccount'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processRelatedParties(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assertEquals(false, ipPayload.containsKey('customerIdSF'));
    }
    
    @isTest
    static void testProcessRelatedParties_UnknownRole() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'relatedParty' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'UnknownRole',
                    'partyOrPartyRole' => new Map<String, Object>{'id' => '123'}
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processRelatedParties(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assertEquals(false, ipPayload.containsKey('UnknownRole'));
    }
    
    // ========================================
    // PROCESS CHARACTERISTICS - EDGE CASES
    // ========================================
    
    @isTest
    static void testProcessCharacteristics_AllRootLevelFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'characteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'salesType', 'value' => 'HandsetAndTech'},
                new Map<String, Object>{'name' => 'salesSubtype', 'value' => 'Act_migracion_Pre_Pos'},
                new Map<String, Object>{'name' => 'billingCycle', 'value' => '05'},
                new Map<String, Object>{'name' => 'cutoffDetailsDate', 'value' => '27'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processCharacteristics(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assertEquals('HandsetAndTech', ipPayload.get('salesType'));
        System.assertEquals('Act_migracion_Pre_Pos', ipPayload.get('salesSubtype'));
        System.assertEquals('05', ipPayload.get('billingCycle'));
        System.assertEquals('27', ipPayload.get('cutoffDetailsDate'));
    }
    
    @isTest
    static void testProcessCharacteristics_AllObjectTypes() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'characteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'deliveryDetails', 'valueType' => 'object', 'value' => new Map<String, Object>{'test' => 'value'}},
                new Map<String, Object>{'name' => 'authorizedPersonData', 'valueType' => 'object', 'value' => new Map<String, Object>{'test' => 'value'}},
                new Map<String, Object>{'name' => 'portInData', 'valueType' => 'object', 'value' => new Map<String, Object>{'test' => 'value'}},
                new Map<String, Object>{'name' => 'migraData', 'valueType' => 'object', 'value' => new Map<String, Object>{'test' => 'value'}},
                new Map<String, Object>{'name' => 'additionalServices', 'valueType' => 'array', 'value' => new List<Object>{new Map<String, Object>{'code' => 'ADD-1'}}}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processCharacteristics(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assert(ipPayload.containsKey('deliveryDetails'));
        System.assert(ipPayload.containsKey('authorizedPersonData'));
        System.assert(ipPayload.containsKey('portInData'));
        System.assert(ipPayload.containsKey('migraData'));
        System.assert(ipPayload.containsKey('additionalServices'));
    }
    
    @isTest
    static void testProcessCharacteristics_WithExistingOrderCharacteristic() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'characteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'FVU_Custom1__c', 'value' => 'Test1'},
                new Map<String, Object>{'name' => 'FVU_Custom2__c', 'value' => 'Test2'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>{
            'orderCharacteristic' => new List<Map<String, Object>>{
                new Map<String, Object>{'name' => 'existing', 'value' => 'test'}
            }
        };
        
        Test.startTest();
        processor.processCharacteristics(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> chars = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
        System.assertEquals(3, chars.size());
    }
    
    @isTest
    static void testProcessCharacteristics_NonCustomField() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'characteristic' => new List<Object>{
                new Map<String, Object>{'name' => 'unknownField', 'value' => 'test'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processCharacteristics(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assertEquals(false, ipPayload.containsKey('orderCharacteristic'));
    }
    
    // ========================================
    // PROCESS PAYMENTS - EDGE CASES
    // ========================================
    
    @isTest
    static void testProcessPayments_AllFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'payment' => new List<Object>{
                new Map<String, Object>{
                    'id' => '00005343',
                    'paymentDate' => '2025-04-10T19:30:00Z',
                    'amount' => new Map<String, Object>{'value' => 10500},
                    'paymentMethod' => new Map<String, Object>{'id' => '3'}
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processPayments(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> payments = (List<Map<String, Object>>)ipPayload.get('orderPayments');
        System.assertEquals('00005343', payments[0].get('orderPaymentNumber'));
        System.assertEquals('3', payments[0].get('orderPaymentMethod'));
        System.assertEquals(10500, payments[0].get('orderPaymentAmount'));
        System.assert(payments[0].containsKey('orderPaymentDate'));
    }
    
    @isTest
    static void testProcessPayments_MissingFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'payment' => new List<Object>{
                new Map<String, Object>{}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processPayments(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> payments = (List<Map<String, Object>>)ipPayload.get('orderPayments');
        System.assertEquals(1, payments.size());
    }
    
    @isTest
    static void testProcessPayments_ThreePayments() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'payment' => new List<Object>{
                new Map<String, Object>{'id' => '001', 'paymentDate' => '2025-04-10T19:30:00Z', 'amount' => new Map<String, Object>{'value' => 1000}, 'paymentMethod' => new Map<String, Object>{'id' => '1'}},
                new Map<String, Object>{'id' => '002', 'paymentDate' => '2025-04-11T10:00:00Z', 'amount' => new Map<String, Object>{'value' => 2000}, 'paymentMethod' => new Map<String, Object>{'id' => '2'}},
                new Map<String, Object>{'id' => '003', 'paymentDate' => '2025-04-12T15:00:00Z', 'amount' => new Map<String, Object>{'value' => 3000}, 'paymentMethod' => new Map<String, Object>{'id' => '3'}}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processPayments(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> payments = (List<Map<String, Object>>)ipPayload.get('orderPayments');
        System.assertEquals(3, payments.size());
    }
    
    // ========================================
    // PROCESS PRODUCT ORDER ITEMS - EDGE CASES
    // ========================================
    
    @isTest
    static void testProcessProductOrderItems_AllFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{
                    'id' => '1',
                    'productOffering' => new Map<String, Object>{'id' => 'B2C-TERM-TEST'},
                    'product' => new Map<String, Object>{
                        'productCharacteristic' => new List<Object>{
                            new Map<String, Object>{'name' => 'position', 'value' => '00010'},
                            new Map<String, Object>{'name' => 'sequence', 'value' => 1},
                            new Map<String, Object>{'name' => 'other', 'value' => 'test'}
                        }
                    }
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processProductOrderItems(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> products = (List<Map<String, Object>>)ipPayload.get('products');
        System.assertEquals('B2C-TERM-TEST', products[0].get('productCode'));
        System.assertEquals(1, products[0].get('sequence'));
        System.assertEquals('00010', products[0].get('position'));
    }
    
    @isTest
    static void testProcessProductOrderItems_MissingProductOffering() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{'id' => '1'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processProductOrderItems(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> products = (List<Map<String, Object>>)ipPayload.get('products');
        System.assertEquals(1, products.size());
    }
    
    @isTest
    static void testProcessProductOrderItems_InvalidSequence() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{
                    'id' => 'invalid',
                    'productOffering' => new Map<String, Object>{'id' => 'TEST'}
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processProductOrderItems(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> products = (List<Map<String, Object>>)ipPayload.get('products');
        System.assertEquals(1, products.size());
    }
    
    @isTest
    static void testProcessProductOrderItems_MultipleWithoutPosition() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'productOrderItem' => new List<Object>{
                new Map<String, Object>{'id' => '1', 'productOffering' => new Map<String, Object>{'id' => 'PROD1'}},
                new Map<String, Object>{'id' => '2', 'productOffering' => new Map<String, Object>{'id' => 'PROD2'}},
                new Map<String, Object>{'id' => '3', 'productOffering' => new Map<String, Object>{'id' => 'PROD3'}}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processProductOrderItems(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> products = (List<Map<String, Object>>)ipPayload.get('products');
        System.assertEquals(3, products.size());
    }
    
    // ========================================
    // PROCESS QUOTE - EDGE CASES
    // ========================================
    
    @isTest
    static void testProcessQuote_AllFinancingFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'quote' => new List<Object>{
                new Map<String, Object>{
                    'id' => '3650',
                    'characteristic' => new List<Object>{
                        new Map<String, Object>{'name' => 'FIN_CreditQuota__c', 'value' => 4700000},
                        new Map<String, Object>{'name' => 'FIN_TipoDeCuota__c', 'value' => 'Cuota Fija'},
                        new Map<String, Object>{'name' => 'FIN_PlazoMeses__c', 'value' => 18},
                        new Map<String, Object>{'name' => 'FIN_ValorTotal', 'value' => 2962008}
                    }
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processQuote(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> financing = (List<Map<String, Object>>)ipPayload.get('financingDetails');
        System.assertEquals(4, financing.size());
    }
    
    @isTest
    static void testProcessQuote_WithExistingOrderCharacteristic() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'quote' => new List<Object>{
                new Map<String, Object>{'id' => 'Q-123'}
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>{
            'orderCharacteristic' => new List<Map<String, Object>>{
                new Map<String, Object>{'name' => 'existing', 'value' => 'test'}
            }
        };
        
        Test.startTest();
        processor.processQuote(tmfPayload, ipPayload);
        Test.stopTest();
        
        List<Map<String, Object>> chars = (List<Map<String, Object>>)ipPayload.get('orderCharacteristic');
        System.assertEquals(2, chars.size());
    }
    
    @isTest
    static void testProcessQuote_EmptyCharacteristics() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> tmfPayload = new Map<String, Object>{
            'quote' => new List<Object>{
                new Map<String, Object>{
                    'id' => '3650',
                    'characteristic' => new List<Object>()
                }
            }
        };
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        Test.startTest();
        processor.processQuote(tmfPayload, ipPayload);
        Test.stopTest();
        
        System.assert(ipPayload.containsKey('orderCharacteristic'));
        System.assertEquals(false, ipPayload.containsKey('financingDetails'));
    }
    
    // ========================================
    // UTILITY METHODS - EDGE CASES
    // ========================================
    
    @isTest
    static void testConvertISOToIPDateFormat_Valid() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        String result = processor.convertISOToIPDateFormat('2025-04-10T19:30:00Z');
        Test.stopTest();
        
        System.assertEquals('2025-04-10 19:30:00', result);
    }
    
    @isTest
    static void testConvertISOToIPDateFormat_Exception() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        String result = processor.convertISOToIPDateFormat(null);
        Test.stopTest();
        
        System.assertEquals(null, result);
    }
    
    @isTest
    static void testParseIPResponse_SuccessWithAllFields() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success',
            'message' => 'Order created successfully',
            'attributes' => new Map<String, Object>{
                'Id' => '00003110',
                'href' => '/services/data/v57.0/sobjects/Order/801XXXXXXXXXXXXXXX'
            }
        };
        
        Test.startTest();
        Object result = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testParseIPResponse_ErrorInOutput() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'error' => 'Test error message'
        };
        
        Test.startTest();
        Object result = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testParseIPResponse_InvalidCode() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '400',
            'status' => 'Failed',
            'message' => 'Bad request'
        };
        
        Test.startTest();
        Object result = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testParseIPResponse_MissingAttributes() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> ipOutput = new Map<String, Object>{
            'code' => '200',
            'status' => 'Success'
        };
        
        Test.startTest();
        Object result = processor.parseIPResponse(ipOutput);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testParseIPResponse_Exception() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        Object result = processor.parseIPResponse(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testMapIPErrorToTMF_AllCodes() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        Object result400 = processor.mapIPErrorToTMF('400', 'Bad request');
        Object result404 = processor.mapIPErrorToTMF('404', 'Not found');
        Object result409 = processor.mapIPErrorToTMF('409', 'Conflict');
        Object result422 = processor.mapIPErrorToTMF('422', 'Unprocessable');
        Object result500 = processor.mapIPErrorToTMF('500', 'Server error');
        Object resultUnknown = processor.mapIPErrorToTMF('999', 'Unknown');
        Test.stopTest();
        
        System.assertNotEquals(null, result400);
        System.assertNotEquals(null, result404);
        System.assertNotEquals(null, result409);
        System.assertNotEquals(null, result422);
        System.assertNotEquals(null, result500);
        System.assertNotEquals(null, resultUnknown);
    }
    
    @isTest
    static void testMapIPErrorToTMF_MessagePatterns() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Test.startTest();
        Object resultRequired = processor.mapIPErrorToTMF('400', 'Field is required');
        Object resultNotFound = processor.mapIPErrorToTMF('404', 'Record not found');
        Object resultDuplicate = processor.mapIPErrorToTMF('409', 'Duplicate entry');
        Test.stopTest();
        
        System.assertNotEquals(null, resultRequired);
        System.assertNotEquals(null, resultNotFound);
        System.assertNotEquals(null, resultDuplicate);
    }
    
    @isTest
    static void testBuildTMFResponseFromIP_WithValidOrder() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        Order order = [SELECT Id FROM Order LIMIT 1];
        
        Map<String, Object> originalPayload = new Map<String, Object>{
            'category' => 'EnterpriseOrder',
            'description' => 'Test order'
        };
        
        Test.startTest();
        Map<String, Object> result = processor.buildTMFResponseFromIP(order.Id, '00001234', '/services/data/v57.0/sobjects/Order/XXXXXXXXXXX', originalPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('id'));
        System.assert(result.containsKey('href'));
        System.assert(result.containsKey('creationDate'));
        System.assert(result.containsKey('lastUpdate'));
        System.assertEquals('EnterpriseOrder', result.get('category'));
    }
    
    @isTest
    static void testBuildTMFResponseFromIP_InvalidOrderId() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        Map<String, Object> originalPayload = new Map<String, Object>{'category' => 'EnterpriseOrder'};
        
        Test.startTest();
        Map<String, Object> result = processor.buildTMFResponseFromIP('INVALID_ID', '00001234', '/services/data/v57.0/sobjects/Order/XXXXXXXXXXX', originalPayload);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('00001234', result.get('id'));
    }
    
    @isTest
    static void testBuildErrorResponse_SingleError() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        List<FVU_TMFBase.TMFError> errors = new List<FVU_TMFBase.TMFError>();
        FVU_TMFBase.TMFError error = processor.buildError('TMF-400-001', 'Test error', 400);
        errors.add(error);
        
        Test.startTest();
        Map<String, Object> result = processor.buildErrorResponse(errors);
        Test.stopTest();
        
        System.assertEquals('error', result.get('status'));
        List<Object> errorList = (List<Object>)result.get('errors');
        System.assertEquals(1, errorList.size());
    }
    
    @isTest
    static void testBuildErrorResponse_MultipleErrors() {
        FVU_TMF622Processing processor = new FVU_TMF622Processing();
        
        List<FVU_TMFBase.TMFError> errors = new List<FVU_TMFBase.TMFError>();
        errors.add(processor.buildError('TMF-400-001', 'Error 1', 400));
        errors.add(processor.buildError('TMF-400-002', 'Error 2', 400));
        errors.add(processor.buildError('TMF-500-001', 'Error 3', 500));
        
        Test.startTest();
        Map<String, Object> result = processor.buildErrorResponse(errors);
        Test.stopTest();
        
        List<Object> errorList = (List<Object>)result.get('errors');
        System.assertEquals(3, errorList.size());
    }
}