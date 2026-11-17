@isTest
public class FVU_TMFCreateOrderTest {
    
    @isTest
    static void testInsertNewOrder_Success() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'HandsetAndTech',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('200', outMap.get('code'));
        Assert.isTrue(outMap.containsKey('orderId'), 'Debe retornar un ID de orden');
        
    }
    @isTest
    static void testInsertNewOrder_ErrorMDTFieldsNull() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'HandsetAndTech',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            },
            'testMdt' => null
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('400', outMap.get('code'));
        
    }
    @isTest
    static void testInsertNewOrder_ErrorDiffFieldsMD() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'HandsetAndTech',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            },
            'testMdt' => 'diff',
            'fieldsServiceTest' => 'customerIdSF,salesType,salesSubtype'
                
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('400', outMap.get('code'));
        
    }
    @isTest
    static void testInsertNewOrder_SuccessPortIn() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'PortIn',
            'salesSubtype' => 'PortIn',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'PortInPortIn',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'PickUp'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'POR'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 150000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PromiseEndDate__c',
                    'value' => '2025-04-10'
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            },
            'portInData' => new Map<String, Object>{
                'min' => '5744333333',
                'nrn' => '123213',
                'donorOperatorName' => 'Donor Test'
            },
            'authorizedPersonData' => new Map<String, Object>{
                'subStaauthorizedPersonNametus' => 'Gustavo',
                'authorizedPersonLastname' => 'Mucino',
                'authorizedPersonSecondLastName' => 'Dominguez'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('200', outMap.get('code'));
        Assert.isTrue(outMap.containsKey('orderId'), 'Debe retornar un ID de orden');
        
    }
    @isTest
    static void testInsertNewOrder_ErrorNodePortIn_ErrorPortIn() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'PortIn',
            'salesSubtype' => 'PortIn',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'PortInPortIn',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'PickUp'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'POR'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 150000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PromiseEndDate__c',
                    'value' => '2025-04-10'
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            },
            'portInFieldsOrderItems' => null,
            'portIn' => null,
            'authorizedPersonData' => new Map<String, Object>{
                'subStaauthorizedPersonNametus' => 'Gustavo',
                'authorizedPersonLastname' => 'Mucino',
                'authorizedPersonSecondLastName' => 'Dominguez'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('400', outMap.get('code'));
        Assert.areEqual('Error en el Nodo PortIn', outMap.get('message'));
    }
    @isTest
    static void testInsertNewOrder_ErrorNodeAuthorized_PortIn() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'PortIn',
            'salesSubtype' => 'PortIn',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'PortInPortIn',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'PickUp'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'POR'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 150000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PromiseEndDate__c',
                    'value' => '2025-04-10'
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            },
            'portInData' => new Map<String, Object>{
                'min' => '5744333333',
                'nrn' => '123213',
                'donorOperatorName' => 'Donor Test'
            },
            'authorizedPersonData' => null
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('400', outMap.get('code'));
        Assert.areEqual('Error en el Nodo AuthorizedPersonData', outMap.get('message'));
    }
    
    @isTest
    static void testInsertNewOrder_SuccessMigra() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'Activation',
            'salesSubtype' => 'Act_migracion_Pre_Pos',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'ActivationAct_migracion_Pre_Pos',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'MIG'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 120000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PrepaidCreditQuota__c',
                    'value' => 3000
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'migraData' => new Map<String, Object>{
                'numberToMigrate' => '3001234567',
                'serial' => '8986001234567890123',
                'NRN' => '57'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('200', outMap.get('code'));
        Assert.isTrue(outMap.containsKey('orderId'), 'Debe retornar un ID de orden');
        
    }
    @isTest
    static void testInsertNewOrder_NodoAdditionaljson_SuccessMigra() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'Activation',
            'salesSubtype' => 'Act_migracion_Pre_Pos',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'ActivationAct_migracion_Pre_Pos',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'MIG'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 120000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PrepaidCreditQuota__c',
                    'value' => 3000
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            'additionalServices' => new Map<String, Object>{
                'additionalServiceCode' => 'ADD-ADDITIONAL'
                    
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'migraData' => new Map<String, Object>{
                'numberToMigrate' => '3001234567',
                'serial' => '8986001234567890123',
                'NRN' => '57'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.areEqual('200', outMap.get('code'));
        Assert.isTrue(outMap.containsKey('orderId'), 'Debe retornar un ID de orden');
        
    }
    @isTest
    static void testInsertNewOrder_SuccessFIN() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<RecordType>  recordTypeAccount = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'billing' AND SobjectType = 'Account'
            LIMIT 1
            ];
        Account accbilling = new Account (Name = 'Test Billing Account',RecordTypeId = recordTypeAccount[0].Id );
        insert accbilling;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'HandsetAndTechFIN',
            'externalAccount93'=>'93000000055932',
            'externalAccount92'=> '91000000099844',
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => accbilling.id
                },
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Financiado 100%'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Credito Claro'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'FIN'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_PromiseEndDate__c',
                    'value' => '2025-04-10'
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                },
                new Map<String, Object>{
                    'name' => 'FIN_NumeroCredito__c',
                    'value' => '01312431'
                }
            },
            'financingDetails' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'FIN_TipoDeCuota__c',
                    'value' => 'Cuota Fija'
                },
                new Map<String, Object>{
                    'name' => 'FIN_CreditQuota__c',
                    'value' => 4700000
                },
                new Map<String, Object>{
                    'name' => 'FIN_PlazoMeses__c',
                    'value' => 18
                },
                new Map<String, Object>{
                    'name' => 'FIN_SaldoADiferir__c',
                    'value' => 2885959
                },
                new Map<String, Object>{
                    'name' => 'FIN_TasaDeInteresEA__c',
                    'value' => 25.64
                },
                new Map<String, Object>{
                    'name' => 'FIN_TasaDeInteresMensual__c',
                    'value' => 1.9203
                },
                new Map<String, Object>{
                    'name' => 'FIN_TasaMaximaLegalVigente__c',
                    'value' => 25.64
                },
                new Map<String, Object>{
                    'name' => 'FIN_ValorDeCuotaMensual__c',
                    'value' => 1492628
                },
                new Map<String, Object>{
                    'name' => 'FIN_TotalDeIntereses__c',
                    'value' => 63907
                },
                new Map<String, Object>{
                    'name' => 'FIN_TotalIVAIntereses__c',
                    'value' => 12142
                },
                new Map<String, Object>{
                    'name' => 'FIN_ValorTotal__c',
                    'value' => 2962008
                },
                new Map<String, Object>{
                    'name' => 'FIN_IDDeSimulacion__c',
                    'value' => '2122112'
                }
            },
            
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual(true, result, 'Debe retornar true en ejecución exitosa');
        Assert.isTrue(outMap.containsKey('orderId'), 'Debe retornar un ID de orden');
        
    }
    
    
    
    
    @isTest
    static void testInsertNewOrder_MissingFields() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => '001000000000001',
            'salesType' => '',
            'salesSubtype' => '',
            'storeOrderId' => '',
            'channel' => '',
            'recordTypeOrder' => '012000000000001',
            'fieldsRequired' => 'customerIdSF,salesType,salesSubtype,storeOrderId,channel',
            'orderPayments' => new List<Object>(),
            'products' => new List<Object>(),
            'additionalServices' => new List<Object>(),
            'deliveryDetails' => new Map<String, Object>()
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        //System.assertEquals(false, result, 'Debe retornar false si hay error');
        Assert.areEqual('Error', outMap.get('status'));
        // System.assert(((String) outMap.get('message')).contains('campos son requeridos'), 'Debe retornar mensaje de campos faltantes');
    }
    
    @isTest
    static void testInsertNewOrder_FailAccount() {
        
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => '0023199jhjs',
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            
            'orderCharacteristic' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27T14:20:00Z'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual('400', outMap.get('code'));
        Assert.areEqual('Cuenta no existe', outMap.get('message'));
        Assert.areEqual('Error', outMap.get('status'));
        
        
    }
    @isTest
    static void testInsertNewOrder_FailUpdateAccountBilling() {
        
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price Book');
        insert pricebook;
        vlocity_cmt__PriceList__c  pricelist = new vlocity_cmt__PriceList__c(Name= 'Cliente Masivo',vlocity_cmt__Code__c='PL-B2C');
        insert pricelist;
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'Activation',
            'salesSubtype' => 'Act_migracion_Pre_Pos',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ECOMMERCE',
            'recordTypeOrder' => recordType[0].Id,
            'externalAccount93'=>'93000000055932',
            'externalAccount91'=> '91000000099844',
            'billingCycle' => '05',
            'cutoffDetailsDate' => '2025-05-12',
            'fieldsRequired' => 'customerIdSF,salesType,storeOrderId,channel',
            'action'=>'ActivationAct_migracion_Pre_Pos',
            
            
            'orderCharacteristic' => new List<Object>{
                
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DefaultBillingAccountId__c',
                    'value' => '212212'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Cargo a la factura'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'MIG'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'Requerido'
                },
                new Map<String, Object>{
                    'name' => 'FVU_CreditQuota__c',
                    'value' => 120000
                },
                new Map<String, Object>{
                    'name' => 'FVU_CarouselSalePolicy__c',
                    'value' => false
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPNotificationMethod__c',
                    'value' => 'email'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationStatus__c',
                    'value' => 'Validado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentifyValidationId__c',
                    'value' => '123456'
                },
                new Map<String, Object>{
                    'name' => 'FVU_DunningStatus__c',
                    'value' => 'Al Dia'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PrepaidCreditQuota__c',
                    'value' => 3000
                },
                new Map<String, Object>{
                    'name' => 'FVU_ATDPDatetime__c',
                    'value' => '2025-04-10 19:30:00'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27 14:20:00'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 }
            },
            
            'migraData' => new Map<String, Object>{
                'numberToMigrate' => '3001234567',
                'serial' => '8986001234567890123',
                'NRN' => '57'
            }
        };
        
        
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual('400', outMap.get('code'));
        Assert.areEqual('Error', outMap.get('status'));
        
        
    }
    @isTest
    static void testInsertNewOrder_FailMetadata() {
        Account acc = new Account(Name = 'Test Account2');
        insert acc;
        
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'fieldsRequired' => '',
            
            'orderCharacteristic' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayments' => new List<Object>{
                new Map<String, Object>{
                    'orderPaymentNumber' => '00005343',
                    'orderPaymentAmount' => 10500,
                    'orderPaymentMethod' => '3',
                    'orderPaymentDate' => '2025-03-27T14:20:00Z'
                }
            },
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual('Configure los campos requeridos en el metadata', outMap.get('message'));
        Assert.areEqual('500', outMap.get('code'));
        Assert.areEqual('Error', outMap.get('status'));
        
        
    }
    @isTest
    static void testInsertNewOrder_FailOrderPaymentNode() {
        Account acc = new Account(Name = 'Test Account2');
        insert acc;
        
        List<RecordType>  recordType = [
            SELECT Id
            FROM RecordType
            WHERE DeveloperName = 'EnterpriseOrder' AND SobjectType = 'Order'
            LIMIT 1
            ];
        
        // Datos de prueba
        Map<String, Object> inputMap = new Map<String, Object>{
            'customerIdSF' => acc.Id,
            'salesType' => 'HandsetAndTech',
            'salesSubtype' => '',
            'storeOrderId' => 'ORD-20250405-001',
            'channel' => 'ecommerce',
            'recordTypeOrder' => recordType[0].Id,
            'fieldsRequired' => 'customerIdSF',
            'action'=>'HandsetAndTech',
            
            'orderCharacteristic' => new List<Object>{
                new Map<String, Object>{
                    'name' => 'vlocity_cmt__DeliveryMethod__c',
                    'value' => 'Delivery'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderOMSId__c',
                    'value' => 'OMS-456789'
                },
                new Map<String, Object>{
                    'name' => 'FVU_OrderSAPId__c',
                    'value' => 'SAP-112233'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentType__c',
                    'value' => 'Contado'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PaymentMethod__c',
                    'value' => 'Pago en línea'
                },
                new Map<String, Object>{
                    'name' => 'FVU_PurchaseType__c',
                    'value' => 'NAP'
                },
                new Map<String, Object>{
                    'name' => 'FVU_IdentityValidationRequired__c',
                    'value' => 'No Requerido'
                }
            },
            
            'orderPayment' => '',
            
            'products' => new List<Object>{
                new Map<String, Object>{ 'productCode' => 'PO_MovPosPlanConV41Mx',
                'sequence' => 1 },
                new Map<String, Object>{ 'promotionCode' => 'B2C-PROMO-CONGAMING25V62',
                'sequence' => 2 }
            },
            
            'deliveryDetails' => new Map<String, Object>{
                'subStatus' => 'BILLED',
                'sapDeliveryId' => '1483175286',
                'deliveryOrderId' => 'F231114100101'
            }
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = (new FVU_TMFCreateOrder()).invokeMethod('insertNewOrder', inputMap, outMap, options);
        Test.stopTest();
        
        Assert.areEqual('No hay objeto para la lista de orderPayment', outMap.get('message'));
        Assert.areEqual('400', outMap.get('code'));
        Assert.areEqual('Error', outMap.get('status'));
        
        
    }
}