@isTest
private class CATListsMergePromotionsTest {
    @isTest
    static void testInvokeMethod() {
        // Create input data
        Map<String, Object> input = new Map<String, Object>{
            'ListMapDR' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Name' => 'Test Promotion 1',
                    'Code' => 'Promo1',
                    'Id' => '001'
                }
            },
            'ListMapIP' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Name' => 'Test Promotion 2',
                    'Code' => 'Promo2',
                    'Id' => '002'
                }
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Call the method to be tested
        CATListsMergePromotions instance = new CATListsMergePromotions();
        Boolean result = instance.invokeMethod('getpromotionsList', input, output, options);

        // Assert the result
        System.assertEquals(true, result);
        System.assertNotEquals(null, output.get('duplicates'));
    }

    @isTest
    static void testGetPromotionsList() {
        // Create input data
        List<Map<String, Object>> ListMapDR = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test Promotion 1',
                'Code' => 'Promo1',
                'Id' => '001'
            }
        };
        List<Map<String, Object>> ListMapIP = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Name' => 'Test Promotion 2',
                'Code' => 'Promo2',
                'Id' => '001'
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Call the method to be tested
        CATListsMergePromotions instance = new CATListsMergePromotions();
        instance.getpromotionsList(ListMapDR, ListMapIP, output, options);

        // Assert the result
        System.assertNotEquals(null, output.get('duplicates'));
        List<Map<String, Object>> duplicates = (List<Map<String, Object>>) output.get('duplicates');
        System.assertEquals(1, duplicates.size());
    }
}