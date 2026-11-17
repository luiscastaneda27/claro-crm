@isTest
private class CATPromotionsQualificationTest {
    
    @isTest
    static void testPromotionsQualificationMethod() {
        // Prepare the input
        Map<String, Object> input = new Map<String, Object>();
        List<Map<String, Object>> promotionsList = new List<Map<String, Object>>();
        
        Map<String, Object> promo1 = new Map<String, Object>();
        promo1.put('Id', 'PROMO1');
        promotionsList.add(promo1);
        
        Map<String, Object> promo2 = new Map<String, Object>();
        promo2.put('Id', 'PROMO2');
        promotionsList.add(promo2);
        
        input.put('PromotionsList', promotionsList);
        
        // Prepare the output
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Instantiate the class and invoke the method
        CATPromotionsQualification promotionsQual = new CATPromotionsQualification();
        Boolean result = promotionsQual.invokeMethod('promotionsQualification', input, output, options);
        
        // Assertions
        System.assertEquals(true, result, 'The invokeMethod should return true');
        System.assert(output.containsKey('qualifiedPromotions'), 'The output should contain the key qualifiedPromotions');
        System.assertEquals('PROMO1_PROMO2', output.get('qualifiedPromotions'), 'The qualifiedPromotions should be correctly concatenated');
    }
    
    @isTest
    static void testPromotionsQualificationMethodWithSinglePromo() {
        // Prepare the input
        Map<String, Object> input = new Map<String, Object>();
        List<Map<String, Object>> promotionsList = new List<Map<String, Object>>();
        
        Map<String, Object> promo1 = new Map<String, Object>();
        promo1.put('Id', 'PROMO1');
        promotionsList.add(promo1);
        
        input.put('PromotionsList', promotionsList);
        
        // Prepare the output
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Instantiate the class and invoke the method
        CATPromotionsQualification promotionsQual = new CATPromotionsQualification();
        Boolean result = promotionsQual.invokeMethod('promotionsQualification', input, output, options);
        
        // Assertions
        System.assertEquals(true, result, 'The invokeMethod should return true');
        System.assert(output.containsKey('qualifiedPromotions'), 'The output should contain the key qualifiedPromotions');
        System.assertEquals('PROMO1', output.get('qualifiedPromotions'), 'The qualifiedPromotions should be correctly concatenated for single promo');
    }
    
    @isTest
    static void testExceptionHandlingInInvokeMethod() {
        // Prepare the input that will cause an exception
        Map<String, Object> input = new Map<String, Object>();
        // Intentionally not putting the required 'PromotionsList' key to cause an exception
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Instantiate the class and invoke the method
        CATPromotionsQualification promotionsQual = new CATPromotionsQualification();
        Boolean result = promotionsQual.invokeMethod('promotionsQualification', input, output, options);
        
        // Assertions
        System.assertEquals(false, result, 'The invokeMethod should return false due to exception');
        System.assert(!output.containsKey('qualifiedPromotions'), 'The output should not contain the key qualifiedPromotions due to exception');
    }
}