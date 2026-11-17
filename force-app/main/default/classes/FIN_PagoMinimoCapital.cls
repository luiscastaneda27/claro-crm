global class FIN_PagoMinimoCapital implements vlocity_cmt.VlocityOpenInterface2 {

    
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName == 'getCapital') {
            getCapital(input, outMap);
        }
        return true;
    }
    
    public void getCapital(Map<String, Object> input, Map<String, Object> outMap) {
        List<Object> transactionList = (List<Object>) input.get('transaction');
        List<Object> resultList = new List<Object>();
        Decimal capital = 0;

        try {
            for (Object transObj : transactionList) {
                Map<String, Object> item = (Map<String, Object>) transObj;
                String typeValue = (String) item.get('type');

                if (typeValue == 'ACH') {
                    break; // Terminamos al encontrar el primer ACH
                }

                if (typeValue == 'MCH') {
                    resultList.add(item);

                    if (item.containsKey('details')) {
                        Map<String, Object> detailsMap = (Map<String, Object>) item.get('details');
                        if (detailsMap != null && detailsMap.containsKey('detail')) {
                            List<Object> detailList = (List<Object>) detailsMap.get('detail');
                            for (Object detailObj : detailList) {
                                Map<String, Object> detailItem = (Map<String, Object>) detailObj;
                                if ((String) detailItem.get('chargeType') == 'AMZ') {
                                    String amountStr = (String) detailItem.get('openAmount');
                                    if (amountStr != null) {
                                        capital += Decimal.valueOf(amountStr);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Error en getCapital: ' + ex.getMessage());
        }

        outMap.put('result', resultList);
        outMap.put('capital', capital);
 }
}