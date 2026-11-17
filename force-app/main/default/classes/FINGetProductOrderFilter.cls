global class FINGetProductOrderFilter implements vlocity_cmt.VlocityOpenInterface2 {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        if (methodName == 'obtenerFiltroGetProduct') {
            Map<String, Object> result = obtenerFiltroGetProduct(input);
            outMap.put('result', result);
        }
        return true;
    }

    public static Map<String, Object> obtenerFiltroGetProduct(Map<String, Object> input) {
        // Clonar el input para no modificarlo directamente
        Map<String, Object> clonedInput = new Map<String, Object>(input);
        List<Object> productOrders = (List<Object>) clonedInput.get('ProductOrder');

        for (Integer i = 0; i < productOrders.size(); i++) {
            Map<String, Object> order = (Map<String, Object>) productOrders[i];
            String purchaseType = (String) order.get('PurchaseType');

            if (purchaseType == 'FIN') {
                List<Object> items = (List<Object>) order.get('ProductOrderItems');
                List<Object> filteredItems = new List<Object>();

                for (Object itemObj : items) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    Map<String, Object> offering = (Map<String, Object>) item.get('ProductOffering');
                    
                    // Conversión segura del ProductCode a String
                    String productCode = String.valueOf(offering.get('ProductCode'));

                    if (productCode != 'PO_EquipoPosCostoEnvioEquiFlete') {
                        filteredItems.add(item);
                    }
                }

                // Reemplazamos la lista filtrada
                order.put('ProductOrderItems', filteredItems);
                productOrders[i] = order;
            }
        }

        clonedInput.put('ProductOrder', productOrders);
        return clonedInput;
    }
}