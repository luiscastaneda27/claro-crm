@IsTest
public class FVU_PositionSerialMapperTest {
    
    @IsTest
    static void testPositionSerialMapper() {
        // Crear una instancia de la clase FVU_PositionSerialMapper
        FVU_PositionSerialMapper mapper = new FVU_PositionSerialMapper();

        // Crear el inputMap con datos simulados
        Map<String, Object> inputMap = new Map<String, Object>();
        
        List<Object> serials = new List<Object>();
        Map<String, Object> serialEntry = new Map<String, Object>();
        serialEntry.put('position', '1');
        serialEntry.put('serials', new List<Object>{'123', '456'});
        serials.add(serialEntry);
        inputMap.put('serials', serials);

        List<Object> itemsWithPosition = new List<Object>();
        Map<String, Object> itemEntry = new Map<String, Object>();
        itemEntry.put('position', '1');
        itemEntry.put('orderItemId', 'OID001');
        itemEntry.put('vlocityOrderStatus', 'READY_FOR_PICKUP');
        itemEntry.put('orderStatus', 'COMPLETED');
        itemEntry.put('orderProductItemStatus', 'DELIVERED_ADVISOR');
        itemEntry.put('deliveryStatus', 'Delivered');
        itemEntry.put('closingReason', 'Reason1');
        itemEntry.put('OrderEndDate', '2025-01-01');
        itemEntry.put('productType', 'SIM Card');
        itemEntry.put('subStatus', 'Active');
        itemEntry.put('status', 'READY_FOR_PICKUP');
        itemEntry.put('deliveryOrderId', '124154548');
        itemEntry.put('sapDeliveryId', '124154548');
        itemEntry.put('sapBillingNbr', '124154548');
        itemEntry.put('sapFreightBillingNbr', '124154548');

        itemsWithPosition.add(itemEntry);
        inputMap.put('itemsWithPosition', itemsWithPosition);

        // Crear el outputMap y options vacíos
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Invocar el método PositionSerialMapper
        Boolean result = mapper.PositionSerialMapper(inputMap, outputMap, options);

        // Validar el resultado
        System.assert(result, 'El método debe retornar true');
        System.assert(outputMap.containsKey('listIdPositionSerial'), 'El outputMap debe contener la clave listIdPositionSerial');
        List<Map<String, String>> finalList = (List<Map<String, String>>) outputMap.get('listIdPositionSerial');
        System.assertEquals(1, finalList.size(), 'La lista final debe tener un elemento');
        System.assertEquals('89123', finalList[0].get('serialNumber'), 'El serialNumber debe ser correcto para SIM Card');
    }
    
    @IsTest
    static void testInvokeMethod() {
        // Crear una instancia de la clase FVU_PositionSerialMapper
        FVU_PositionSerialMapper mapper = new FVU_PositionSerialMapper();

        // Crear inputMap, outputMap y options
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('serials', new List<Object>());
        inputMap.put('itemsWithPosition', new List<Object>());
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Invocar el método invokeMethod con un método válido
        Boolean result = mapper.invokeMethod('PositionSerialMapper', inputMap, outputMap, options);

        // Validar el resultado
        System.assert(result, 'El método debe retornar true');
    }
    
    @IsTest
    static void testMergeLists() {
        // Crear datos de prueba para listIdPosition y listPositionSerial
        List<Map<String, String>> listIdPosition = new List<Map<String, String>>();
        Map<String, String> idEntry = new Map<String, String>();
        idEntry.put('position', '1');
        idEntry.put('Id', 'OID001');
        idEntry.put('productType', 'Handset');
        idEntry.put('status', 'READY_FOR_PICKUP');
        listIdPosition.add(idEntry);

        List<Map<String, String>> listPositionSerial = new List<Map<String, String>>();
        Map<String, String> serialEntry = new Map<String, String>();
        serialEntry.put('position', '1');
        serialEntry.put('serial', '987654');
        listPositionSerial.add(serialEntry);

        // Crear una instancia de la clase FVU_PositionSerialMapper
        FVU_PositionSerialMapper mapper = new FVU_PositionSerialMapper();

        // Invocar el método mergeLists
        List<Map<String, String>> result = mapper.mergeLists(listIdPosition, listPositionSerial);

        // Validar el resultado
        System.assertEquals(1, result.size(), 'La lista resultante debe tener un elemento');
        System.assertEquals('987654', result[0].get('imei'), 'El IMEI debe ser correcto para Handset');
    }
}