@isTest
private class CATOfertasRetencionTest {

    // --- Helper Method to Build Product JSON ---
    private static Map<String, Object> buildProductJson(String productCode, String name, Boolean isRetention) {
        Map<String, Object> productJson = new Map<String, Object>();
        
        // 1. Core Fields (for simple access)
        productJson.put('ProductCode', new Map<String, Object>{'value' => productCode});
        productJson.put('name', name); // Used for debug
        
        // 2. Nested Product2 Node (for isRetentionOffer check)
        productJson.put('Product2', new Map<String, Object>{
            'CAT_Oferta_Retencion__c' => isRetention // The critical field
        });
        
        // Add other required structure to prevent TypeException errors
        productJson.put('Id', '01uXX00000xxxxxx'); 
        
        return productJson;
    }

    /*
    * @description 669698 - Construye un JSON simulado de promoción
    */
    private static Map<String, Object> buildPromoJson(String promoCode, String name, Boolean isRetention) {
        Map<String, Object> promoJson = new Map<String, Object>();
        
        // Estructura según el JSON real de CompatibleOffersList
        promoJson.put('code', promoCode);
        promoJson.put('name', name);
        promoJson.put('CAT_Oferta_Retencion__c', isRetention);
        promoJson.put('Id', 'a4TXX00000' + promoCode.left(5));

        return promoJson;
    }

    // --- Test Scenarios ---

    @isTest
    static void test_Method_Success_No_Match_Filter() {
        // GIVEN: Input data simulating products, price (100), and a user role.
        
        // Product Codes: PROD_A_RET (Retention, Allowed), PROD_C_RET (Retention, Not Allowed), PROD_X (Standard)
        Map<String, Object> productA = buildProductJson('PO_MovPosPlanCon25E46', 'Plan A', true);
        Map<String, Object> productC = buildProductJson('PROD_C_RET', 'Plan C', true);
        Map<String, Object> productX = buildProductJson('PROD_X', 'Plan X', false);
        
        List<Object> planesDisponibles = new List<Object>{productA, productC, productX};

        Map<String, Object> input = new Map<String, Object>{
            'planesDisponibles' => planesDisponibles,
            'precioPlan' => 44000, // This price falls within 50-150 range for PROD_A_RET
            'userRole' => 'Asesor CAV Aliado'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // WHEN: The method is invoked
        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPlanesDestino', input, output, options);
        List<Map<String, Object>> listaPlanesFinal = (List<Map<String, Object>>)output.get('listaPlanesFinal');
        Test.stopTest();

        // THEN: Verify the expected products were filtered.
        // Expected allowed code: PROD_A_RET (because price 100 is in range 50-150)
        // Expected products in final list: PROD_A_RET (Retention & Allowed), PROD_X (Standard)
        
        System.assert(success, 'InvokeMethod should return true on successful execution.');
        System.assertEquals(2, listaPlanesFinal.size(), 'Two products (Allowed Retention & Standard) should be returned.');

        // Verify that the filtered product (PROD_C_RET) is NOT present
        Boolean productCPresent = false;
        for (Map<String, Object> finalPlan : listaPlanesFinal) {
            Map<String, Object> codeMap = (Map<String, Object>)finalPlan.get('ProductCode');
            String finalProductCode = (String)codeMap.get('value');
            
            if (finalProductCode == 'PROD_C_RET') {
                productCPresent = true;
            }
        }
        System.assert(!productCPresent, 'Retention product PROD_C_RET should have been filtered out.');
    }

    @isTest
    static void test_Method_Success_Fallback_Query() {
        // GIVEN: Input data where the price is high (600), triggering the fallback query (CAT_Precio_maximo__c = null)
        
        Map<String, Object> productB = buildProductJson('PO_MovPosPlanCon25E81', 'Plan B', true);
        Map<String, Object> productY = buildProductJson('PROD_Y', 'Plan Y', false);
        
        List<Object> planesDisponibles = new List<Object>{productB, productY};

        Map<String, Object> input = new Map<String, Object>{
            'planesDisponibles' => planesDisponibles,
            'precioPlan' => 89000, // Price is > 300 and > 150, forcing fallback query (Price_min=500, Price_max=null)
            'userRole' => 'Asesor CAV Aliado'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // WHEN: The method is invoked
        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPlanesDestino', input, output, options);
        List<Map<String, Object>> listaPlanesFinal = (List<Map<String, Object>>)output.get('listaPlanesFinal');
        Test.stopTest();

        // THEN: Verify the fallback query executed and allowed PROD_B_RET.
        System.assert(success, 'InvokeMethod should return true.');
        System.assertEquals(2, listaPlanesFinal.size(), 'Two products (Fallback Retention & Standard) should be returned.');

        Boolean productBPresent = false;
        for (Map<String, Object> finalPlan : listaPlanesFinal) {
            Map<String, Object> codeMap = (Map<String, Object>)finalPlan.get('ProductCode');
            String finalProductCode = (String)codeMap.get('value');

            if (finalProductCode == 'PO_MovPosPlanCon25E81') {
                productBPresent = true;
            }
        }
        System.assert(productBPresent, 'Retention product PO_MovPosPlanCon25E81 should be present due to fallback query.');
    }
    
    @isTest
    static void test_Method_Exception_Handling() {
        // GIVEN: Input data designed to cause a TypeException (passing a String where a List<Object> is expected)
        
        Map<String, Object> input = new Map<String, Object>{
            'planesDisponibles' => 'This is not a list', // Causes the exception at casting
            'precioPlan' => 100.00,
            'userRole' => 'Asesor CAV Aliado'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // WHEN: The method is invoked
        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPlanesDestino', input, output, options);
        Test.stopTest();

        // THEN: Verify the invokeMethod returns FALSE.
        System.assert(!success, 'InvokeMethod should return false when an exception occurs.');
    }

    /*
    * @description 669698 - Valida que las promociones de retención permitidas por el MDT.
    */
    @isTest
    static void test_Success_FilterPromotion() {

        Map<String, Object> promoA = buildPromoJson('POSTASTSALUD25V53_49900', 'Promo MDT', true); // Promoción configurada en el mdt.
        Map<String, Object> promoC = buildPromoJson('B2C-PROMO-NO-CONFIG', 'Promo C', true);
        Map<String, Object> promoX = buildPromoJson('B2C-PROMO-STANDARD', 'Promo X', false);

        List<Object> promosDisponibles = new List<Object>{ promoA, promoC, promoX };
        Decimal precioPromo = 50000;
        String userRole   = 'Asesor CAV Aliado';

        List<CAT_Oferta_Retencion__mdt> ofertasPromoMdt = [SELECT Id, CAT_Codigo_oferta__c, CAT_Precio_minimo__c, CAT_Precio_maximo__c
                                                           FROM CAT_Oferta_Retencion__mdt WHERE CAT_Role__c = :userRole AND CAT_Tipo_Oferta__c = 'Promoción' AND CAT_Codigo_oferta__c = 'POSTASTSALUD25V53_49900'
                                                           AND CAT_Precio_minimo__c < :precioPromo AND CAT_Precio_maximo__c > :precioPromo  WITH SECURITY_ENFORCED];

        Boolean promoEstaPermitidaPorMdt = !ofertasPromoMdt.isEmpty();

        Map<String, Object> input = new Map<String, Object>{
            'promosDisponibles' => promosDisponibles,
            'precioPromo'       => precioPromo,
            'userRole'          => userRole
        };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPromosDestino', input, output, options);
        List<Map<String, Object>> listaPromosFinal = (List<Map<String, Object>>) output.get('listaPromosFinal');
        Test.stopTest();

        System.assert(success, 'InvokeMethod should return true on successful execution.');
        System.assertNotEquals(null, listaPromosFinal, 'listaPromosFinal should not be null.');

        Boolean promoStdPresent = false;
        Boolean promoAPresent   = false;
        Boolean promoCPresent   = false;

        for (Map<String, Object> finalPromo : listaPromosFinal) {
            String finalCode = (String) finalPromo.get('code');

            if (finalCode == 'B2C-PROMO-STANDARD') {
                promoStdPresent = true;
            }
            if (finalCode == 'POSTASTSALUD25V53_49900') {
                promoAPresent = true;
            }
            if (finalCode == 'B2C-PROMO-NO-CONFIG') {
                promoCPresent = true;
            }
        }

        System.assert(promoStdPresent,'La promo estándar (no retención) siempre debe permanecer.');

        System.assertEquals(promoEstaPermitidaPorMdt, promoAPresent,'La presencia de la promo de retención debe coincidir con lo configurado en el MDT.');

        System.assert(!promoCPresent, 'La promo de retención NO configurada en MDT debe filtrarse.');

        Integer expectedSize = promoEstaPermitidaPorMdt ? 2 : 1;
        System.assertEquals( expectedSize, listaPromosFinal.size(), 'El tamaño de la lista debe coincidir con las promociones permitidas por MDT.');
    }

    /*
    * @description 669698 - Verifica que solo se mantengan las promociones que no son de retención.
    */
    @isTest
    static void test_Method_Success_NoMatch_FilterPromotion(){

        Map<String, Object> promoRet1 = buildPromoJson('B2C-PROMO-RET-1', 'Promo Ret 1', true);
        Map<String, Object> promoRet2 = buildPromoJson('B2C-PROMO-RET-2', 'Promo Ret 2', true);
        Map<String, Object> promoStd  = buildPromoJson('B2C-PROMO-STD',   'Promo Std',  false);

        List<Object> promosDisponibles = new List<Object>{ promoRet1, promoRet2, promoStd };

        Map<String, Object> input = new Map<String, Object>{
            'promosDisponibles' => promosDisponibles,
            'precioPromo'       => 50000,
            'userRole'          => 'ROL_SIN_CONFIG_MDT' // Rol sin configuración para forzar allowedRetentionCodes vacío
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPromosDestino', input, output, options);
        List<Map<String, Object>> listaPromosFinal = (List<Map<String, Object>>)output.get('listaPromosFinal');
        Test.stopTest();

        System.assert(success, 'InvokeMethod should return true.');
        System.assertNotEquals(null, listaPromosFinal, 'listaPromosFinal should not be null.');

        System.assertEquals(1, listaPromosFinal.size(), 'No hay configuración MDT para rol, solo deben mantenerse las promos NO de retención.');

        String remainingCode = (String) listaPromosFinal[0].get('code');
        System.assertEquals('B2C-PROMO-STD', remainingCode, 'La única promo restante debe ser la estándar.');
    }

    /*
    * @description 669698 - Comprueba el manejo de excepciones cuando la entrada no corresponde a una lista válida de promociones.
    */
    @isTest
    static void test_Method_Exception_FilterPromotion() {
        Map<String, Object> input = new Map<String, Object>{
            'promosDisponibles' => 'This is not a list', 
            'precioPromo'       => 44000,
            'userRole'          => 'Asesor CAV Aliado'
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        CATOfertasRetencion instance = new CATOfertasRetencion();
        Boolean success = instance.invokeMethod('filterPromosDestino', input, output, options);
        Test.stopTest();

        System.assert(!success,'InvokeMethod debe devolver false cuando se produce una excepción en filterPromosDestino.');
    }
}