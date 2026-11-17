@isTest
public class FVU_ProductListMapperTest {

    @isTest
    static void testInvokeMethodWithValidProductList() {
        // Arrange: Set up input data with a valid product list and valid purchaseType
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> productList = new Map<String, Object>();
        List<Object> productCodes = new List<Object>{'prod1', 'prod2'};
        List<Object> productNums = new List<Object>{2, 3};
        productList.put('productCode', productCodes);
        productList.put('productNum', productNums);
        inputMap.put('productList', productList);
        inputMap.put('purchaseType', 'ATT');  // Purchase type 'ATT' will require groupId
        inputMap.put('terminalId', 1001);

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Instantiate the class to test
        FVU_ProductListMapper productListMapper = new FVU_ProductListMapper();

        // Act: Call invokeMethod with the correct method name
        Boolean result = productListMapper.invokeMethod('ProductListMapper', inputMap, outputMap, options);

        // Assert: Check that the method returned true and outputMap contains the expected result
        System.assert(result, 'Invoke method should return true');
        System.assert(outputMap.containsKey('productListMapped'), 'Output map should contain the productListMapped key');

        List<Map<String, String>> mappedProductList = (List<Map<String, String>>) outputMap.get('productListMapped');
        System.assertEquals(2, mappedProductList.size(), 'The list should contain two products');

        // Assert that the mapped data matches expected results
        System.assertEquals('prod1', mappedProductList.get(0).get('productCode'), 'Product code should be prod1');
        System.assertEquals('2', mappedProductList.get(0).get('productNum'), 'Product number should be 2');
        System.assertEquals('1001', mappedProductList.get(0).get('groupId'), 'Group ID should be 1001');
        
        System.assertEquals('prod2', mappedProductList.get(1).get('productCode'), 'Product code should be prod2');
        System.assertEquals('3', mappedProductList.get(1).get('productNum'), 'Product number should be 3');
        System.assertEquals('1001', mappedProductList.get(1).get('groupId'), 'Group ID should be 1001');
    }

    @isTest
    static void testInvokeMethodWithSingleProduct() {
        // Arrange: Set up input data with a single product
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> productList = new Map<String, Object>();
        productList.put('productCode', 'prod1');
        productList.put('productNum', 5);
        inputMap.put('productList', productList);
        inputMap.put('purchaseType', 'ATT');
        inputMap.put('terminalId', 1001);

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Instantiate the class to test
        FVU_ProductListMapper productListMapper = new FVU_ProductListMapper();

        // Act: Call invokeMethod with the correct method name
        Boolean result = productListMapper.invokeMethod('ProductListMapper', inputMap, outputMap, options);

        // Assert: Check that the method returned true and outputMap contains the expected result
        System.assert(result, 'Invoke method should return true');
        System.assert(outputMap.containsKey('productListMapped'), 'Output map should contain the productListMapped key');

        List<Map<String, String>> mappedProductList = (List<Map<String, String>>) outputMap.get('productListMapped');
        System.assertEquals(1, mappedProductList.size(), 'The list should contain one product');

        // Assert that the mapped data matches expected results
        System.assertEquals('prod1', mappedProductList.get(0).get('productCode'), 'Product code should be prod1');
        System.assertEquals('5', mappedProductList.get(0).get('productNum'), 'Product number should be 5');
        System.assertEquals('1001', mappedProductList.get(0).get('groupId'), 'Group ID should be 1001');
    }

    @isTest
    static void testInvokeMethodWithoutGroupId() {
        // Arrange: Set up input data with a different purchase type that doesn't include groupId
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> productList = new Map<String, Object>();
        List<Object> productCodes = new List<Object>{'prod1', 'prod2'};
        List<Object> productNums = new List<Object>{2, 3};
        productList.put('productCode', productCodes);
        productList.put('productNum', productNums);
        inputMap.put('productList', productList);
        inputMap.put('purchaseType', 'OTHER');  // Different purchase type
        inputMap.put('terminalId', 1001);

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Instantiate the class to test
        FVU_ProductListMapper productListMapper = new FVU_ProductListMapper();

        // Act: Call invokeMethod with the correct method name
        Boolean result = productListMapper.invokeMethod('ProductListMapper', inputMap, outputMap, options);

        // Assert: Check that the method returned true and outputMap contains the expected result
        System.assert(result, 'Invoke method should return true');
        System.assert(outputMap.containsKey('productListMapped'), 'Output map should contain the productListMapped key');

        List<Map<String, String>> mappedProductList = (List<Map<String, String>>) outputMap.get('productListMapped');
        System.assertEquals(2, mappedProductList.size(), 'The list should contain two products');

        // Assert that the mapped data matches expected results
        System.assertEquals('prod1', mappedProductList.get(0).get('productCode'), 'Product code should be prod1');
        System.assertEquals('2', mappedProductList.get(0).get('productNum'), 'Product number should be 2');
        System.assertEquals(null, mappedProductList.get(0).get('groupId'), 'Group ID should be null');

        System.assertEquals('prod2', mappedProductList.get(1).get('productCode'), 'Product code should be prod2');
        System.assertEquals('3', mappedProductList.get(1).get('productNum'), 'Product number should be 3');
        System.assertEquals(null, mappedProductList.get(1).get('groupId'), 'Group ID should be null');
    }

    @isTest
    static void testInvokeMethodWithInvalidData() {
        // Arrange: Set up input data with invalid or empty product list
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> productList = new Map<String, Object>();
        productList.put('productCode', 5555);
        productList.put('productNum', null);  // Invalid product number (null)
        inputMap.put('productList', productList);
        inputMap.put('purchaseType', 'ATT');
        inputMap.put('terminalId', 1001);

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Instantiate the class to test
        FVU_ProductListMapper productListMapper = new FVU_ProductListMapper();

        // Act: Call invokeMethod with the correct method name
        try {
            Boolean result = productListMapper.invokeMethod('ProductListMapper', inputMap, outputMap, options);
            System.assert(false, 'Exception should have been thrown due to invalid data');
        } catch (Exception e) {
            System.assert(true, 'Exception was correctly thrown');
        }
    }

}