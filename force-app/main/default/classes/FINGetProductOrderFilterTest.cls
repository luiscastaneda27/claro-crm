@isTest
private class FINGetProductOrderFilterTest {

    @isTest
    static void testFiltroConPurchaseTypeFIN() {
        // Arrange
        Map<String, Object> productOffering1 = new Map<String, Object>{
            'ProductCode' => 'PO_EquipoPosCostoEnvioEquiFlete'
        };

        Map<String, Object> productOffering2 = new Map<String, Object>{
            'ProductCode' => 'PO_ProductoValido'
        };

        Map<String, Object> item1 = new Map<String, Object>{
            'ProductOffering' => productOffering1
        };

        Map<String, Object> item2 = new Map<String, Object>{
            'ProductOffering' => productOffering2
        };

        Map<String, Object> orderFIN = new Map<String, Object>{
            'PurchaseType' => 'FIN',
            'ProductOrderItems' => new List<Object>{ item1, item2 }
        };

        Map<String, Object> input = new Map<String, Object>{
            'ProductOrder' => new List<Object>{ orderFIN }
        };

        // Start Test
        Test.startTest();
        
        Map<String, Object> result = fINGetProductOrderFilter.obtenerFiltroGetProduct(input);

        // Stop Test
        Test.stopTest();

        List<Object> filteredOrders = (List<Object>) result.get('ProductOrder');
        Map<String, Object> filteredOrder = (Map<String, Object>) filteredOrders[0];
        List<Object> filteredItems = (List<Object>) filteredOrder.get('ProductOrderItems');

        // Assert using Assert.areEqual
        Assert.areEqual(1, filteredItems.size(), 'Solo debe quedar un producto');
        Map<String, Object> remainingItem = (Map<String, Object>) filteredItems[0];
        Map<String, Object> remainingOffering = (Map<String, Object>) remainingItem.get('ProductOffering');
        Assert.areEqual('PO_ProductoValido', String.valueOf(remainingOffering.get('ProductCode')));
    }

    @isTest
    static void testSinFiltroConOtroPurchaseType() {
        // Arrange
        Map<String, Object> productOffering = new Map<String, Object>{
            'ProductCode' => 'PO_EquipoPosCostoEnvioEquiFlete'
        };

        Map<String, Object> item = new Map<String, Object>{
            'ProductOffering' => productOffering
        };

        Map<String, Object> order = new Map<String, Object>{
            'PurchaseType' => 'NEW',
            'ProductOrderItems' => new List<Object>{ item }
        };

        Map<String, Object> input = new Map<String, Object>{
            'ProductOrder' => new List<Object>{ order }
        };

        // Start Test
        Test.startTest();

        Map<String, Object> result = fINGetProductOrderFilter.obtenerFiltroGetProduct(input);

        // Stop Test
        Test.stopTest();

        List<Object> orders = (List<Object>) result.get('ProductOrder');
        Map<String, Object> unchangedOrder = (Map<String, Object>) orders[0];
        List<Object> items = (List<Object>) unchangedOrder.get('ProductOrderItems');

        // Assert using Assert.areEqual
        Assert.areEqual(1, items.size(), 'No debe filtrar cuando PurchaseType no es FIN');
    }

    @isTest
    static void testInvokeMethod() {
        // Arrange
        Map<String, Object> productOffering = new Map<String, Object>{
            'ProductCode' => 'OtroCodigo'
        };

        Map<String, Object> item = new Map<String, Object>{
            'ProductOffering' => productOffering
        };

        Map<String, Object> order = new Map<String, Object>{
            'PurchaseType' => 'FIN',
            'ProductOrderItems' => new List<Object>{ item }
        };

        Map<String, Object> input = new Map<String, Object>{
            'ProductOrder' => new List<Object>{ order }
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Start Test
        Test.startTest();
        
        // Act
        Boolean success = (new fINGetProductOrderFilter()).invokeMethod('obtenerFiltroGetProduct', input, output, options);

        // Stop Test
        Test.stopTest();

        // Assert using Assert.areEqual
        Assert.areEqual(true, success, 'invokeMethod debe retornar true');
        Assert.areEqual(true, output.containsKey('result'), 'El resultado debe estar en outMap bajo la clave "result"');
    }
}