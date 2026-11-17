global with sharing class FVU_PositionSerialMapper implements vlocity_cmt.VlocityOpenInterface2 {    
    
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        try {
            if (methodName == 'PositionSerialMapper') {
                return PositionSerialMapper(inputMap, outputMap, options);
            }
        } catch (Exception e) {
            System.debug('Error in invoke method: ' + e.getMessage());
            throw e;
        }
        return false;
    }

    public Boolean PositionSerialMapper(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        

        List<Map<String, String>> listPositionSerial = new List<Map<String, String>>();
        List<Map<String, String>> listIdPosition = new List<Map<String, String>>();
        List<Map<String, String>> finalList = new List<Map<String, String>>();
        List<Object> serials = (List<Object>) inputMap.get('serials');
        List<Object> itemsWithPosition = (List<Object>) inputMap.get('itemsWithPosition');

        for (Object serial : serials) {
            Map<String, Object> serialMap = (Map<String, Object>) serial;
            String positionValue = (String) serialMap.get('position');

            List<Object> serialsValues = (List<Object>) serialMap.get('serials');
            for (Object serialValue : serialsValues) {

                Map<String, String> newEntry = new Map<String, String>();
                newEntry.put('position', positionValue);
                newEntry.put('serial', (String) serialValue);
                listPositionSerial.add(newEntry);
            }
            
        }

        for (Object itemWithPosition : itemsWithPosition) {
            Map<String, Object> itemWithPositionMap = (Map<String, Object>) itemWithPosition;
            String positionValue = (String) itemWithPositionMap.get('position');
            String idValue = (String) itemWithPositionMap.get('orderItemId');
            String vlocityOrderStatus = (String) itemWithPositionMap.get('vlocityOrderStatus');
            String orderStatus = (String) itemWithPositionMap.get('orderStatus');
            String orderProductItemStatus = (String) itemWithPositionMap.get('orderProductItemStatus');
            String orderProductItemSubstatus = (String) itemWithPositionMap.get('orderProductItemSubstatus');
            String deliveryStatus = (String) itemWithPositionMap.get('deliveryStatus');
            String closingReason = (String) itemWithPositionMap.get('closingReason');
            String orderEndDate = (String) itemWithPositionMap.get('OrderEndDate');
            String productType = (String) itemWithPositionMap.get('productType');
            String subStatus = (String) itemWithPositionMap.get('subStatus');
            String status = (String) itemWithPositionMap.get('status');
            String deliveryOrderId = (String) itemWithPositionMap.get('deliveryOrderId');
            String sapDeliveryId = (String) itemWithPositionMap.get('sapDeliveryId');
            String sapBillingNbr = (String) itemWithPositionMap.get('sapBillingNbr');
            String sapFreightBillingNbr = (String) itemWithPositionMap.get('sapFreightBillingNbr');

            Map<String, String> newEntry = new Map<String, String>();
            newEntry.put('position', positionValue);
            newEntry.put('Id', (String) idValue);
            newEntry.put('vlocityOrderStatus', (String) vlocityOrderStatus);
            newEntry.put('orderStatus', (String) orderStatus);
            newEntry.put('orderProductItemStatus', (String) orderProductItemStatus);
            newEntry.put('orderProductItemSubstatus', (String) orderProductItemSubstatus);
            newEntry.put('deliveryStatus', (String) deliveryStatus);
            newEntry.put('closingReason', (String) closingReason);
            newEntry.put('orderEndDate', (String) orderEndDate);
            newEntry.put('productType', (String) productType);
            newEntry.put('subStatus', (String) subStatus);
            newEntry.put('status', (String) status);
            newEntry.put('deliveryOrderId', (String) deliveryOrderId);
            newEntry.put('sapDeliveryId', (String) sapDeliveryId);
            newEntry.put('sapBillingNbr', (String) sapBillingNbr);
            newEntry.put('sapFreightBillingNbr', (String) sapFreightBillingNbr);
            listIdPosition.add(newEntry);
        }
        
        finalList = mergeLists(listIdPosition, listPositionSerial);
        outputMap.put('listIdPositionSerial', finalList);
        
        return true;
    }

    public List<Map<String, String>> mergeLists(List<Map<String, String>> listIdPosition, List<Map<String, String>> listPositionSerial) {
        List<Map<String, String>> finalList = new List<Map<String, String>>();

        // Crear un mapa para almacenar los seriales agrupados por 'position' en listPositionSerial
        Map<String, List<String>> positionToSerialsMap = new Map<String, List<String>>();

        // Llenamos el mapa con los seriales agrupados por 'position'
        for (Map<String, String> entry : listPositionSerial) {
            String position = entry.get('position');
            String serial = entry.get('serial');

            // Si no existe una lista para esa posición, la creamos
            if (!positionToSerialsMap.containsKey(position)) {
                positionToSerialsMap.put(position, new List<String>());
            }

            // Añadimos el serial a la lista correspondiente
            positionToSerialsMap.get(position).add(serial);
        }

        // Iteramos sobre listIdPosition para agregar los 'Id' y asignar los seriales correspondientes
        for (Map<String, String> entry : listIdPosition) {
            String position = entry.get('position');
            String id = entry.get('Id');
            String vlocityOrderStatus = entry.get('vlocityOrderStatus');
            String orderStatus = entry.get('orderStatus');
            String orderProductItemStatus = entry.get('orderProductItemStatus');
            String orderProductItemSubstatus = entry.get('orderProductItemSubstatus');
            String deliveryStatus = entry.get('deliveryStatus');
            String closingReason = entry.get('closingReason');
            String orderEndDate = entry.get('orderEndDate');
            String productType = entry.get('productType');
            String subStatus = entry.get('subStatus');
            String status = entry.get('status');
            String deliveryOrderId = entry.get('deliveryOrderId');
            String sapDeliveryId = entry.get('sapDeliveryId');
            String sapBillingNbr = entry.get('sapBillingNbr');
            String sapFreightBillingNbr = entry.get('sapFreightBillingNbr');
            String serialNumberAttribute = '';
            String serialNumber = '';
            String imei = '';
            
            
            // Comprobamos si existe la lista de seriales para esa posición
            if (positionToSerialsMap.containsKey(position) && !positionToSerialsMap.get(position).isEmpty()) {
                // Sacamos el primer serial de la lista
                String serial = positionToSerialsMap.get(position).remove(0);
                switch on productType {
                    when 'Tech' {
                        if (status == 'READY_FOR_PICKUP' || status == 'COMPLETED' || status == 'DeliveredAgent' || status == 'DELIVERED_ADVISOR') {
                            serialNumberAttribute = '';
                            serialNumber = serial;
                            imei = '';
                        } else {
                            serialNumber = '';
                        }
                    }
                    when 'Handset' {
                        if (status == 'READY_FOR_PICKUP' || status == 'COMPLETED' || status == 'DeliveredAgent' || status == 'DELIVERED_ADVISOR') {
                            serialNumberAttribute = '';
                            serialNumber = '';
                            imei = serial;
                        } else {
                            serialNumber = '';
                        }
                    }
                    when 'SIM Card' {
                        if (status == 'READY_FOR_PICKUP' || status == 'COMPLETED' || status == 'DeliveredAgent' || status == 'DELIVERED_ADVISOR') {
                            serialNumberAttribute = '89'+serial;
                            serialNumber = '89'+serial;
                            imei = '';
                        } else {
                            serialNumber = '';
                        }
                    }
                    when else {
                        System.debug('El tipo de producto no es válido.');
                    }
                }

                // Creamos un nuevo Map con position, Id y serial
                Map<String, String> resultEntry = new Map<String, String>();

                
                resultEntry.put('ordertItemTypeSerial', serial);
                resultEntry.put('position', position);
                resultEntry.put('orderItemId', id);
                resultEntry.put('vlocityOrderStatus', vlocityOrderStatus);
                resultEntry.put('orderStatus', orderStatus);
                resultEntry.put('orderProductItemStatus', orderProductItemStatus);
                resultEntry.put('orderProductItemSubstatus', orderProductItemSubstatus);
                resultEntry.put('deliveryStatus', deliveryStatus);
                resultEntry.put('closingReason', closingReason);
                resultEntry.put('orderEndDate', orderEndDate);
                resultEntry.put('productType', productType);
                resultEntry.put('subStatus', subStatus);
                resultEntry.put('status', status);
                resultEntry.put('deliveryOrderId', deliveryOrderId);
                resultEntry.put('sapDeliveryId', sapDeliveryId);
                resultEntry.put('sapBillingNbr', sapBillingNbr);
                resultEntry.put('sapFreightBillingNbr', sapFreightBillingNbr);
                resultEntry.put('serialNumberAttribute', serialNumberAttribute);
                resultEntry.put('serialNumber', serialNumber);
                resultEntry.put('imei', imei);

                // Añadimos a la lista final
                finalList.add(resultEntry);
            }
        }
        // Retornamos la lista final con la información combinada
        return finalList;
    }
}