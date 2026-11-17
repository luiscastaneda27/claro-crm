@isTest
private class FIN_PagoMinimoCapitalTest {

    @isTest
    static void testGetCapital_withACHCutoffAndAMZSum() {
        // Simula la entrada como se enviaría desde el Integration Procedure
        Map<String, Object> input = new Map<String, Object>();
        List<Object> transactionList = new List<Object>();

        Map<String, Object> detail1 = new Map<String, Object>{
            'openAmount' => '1000.00',
            'chargeType' => 'AMZ'
        };

        Map<String, Object> detail2 = new Map<String, Object>{
            'openAmount' => '500.00',
            'chargeType' => 'IVA'
        };

        Map<String, Object> mchTransaction = new Map<String, Object>{
            'type' => 'MCH',
            'details' => new Map<String, Object>{
                'detail' => new List<Object>{ detail1, detail2 }
            }
        };

        Map<String, Object> achTransaction = new Map<String, Object>{
            'type' => 'ACH'
        };

        Map<String, Object> mchAfterAch = new Map<String, Object>{
            'type' => 'MCH',
            'details' => new Map<String, Object>{
                'detail' => new List<Object>{
                    new Map<String, Object>{
                        'openAmount' => '9999.00',
                        'chargeType' => 'AMZ'
                    }
                }
            }
        };

        transactionList.add(mchTransaction);
        transactionList.add(achTransaction);
        transactionList.add(mchAfterAch);

        input.put('transaction', transactionList);

        Map<String, Object> outMap = new Map<String, Object>();

        FIN_PagoMinimoCapital classUnderTest = new FIN_PagoMinimoCapital();
        Test.startTest();
        classUnderTest.invokeMethod('getCapital', input, outMap, new Map<String, Object>());
		Test.stopTest();
        Assert.isTrue(outMap.containsKey('result'), 'El mapa outMap debe contener la clave "result"');
        Assert.isTrue(outMap.containsKey('capital'), 'El mapa outMap debe contener la clave "capital"');

        List<Object> filteredResult = (List<Object>) outMap.get('result');
        Decimal capital = (Decimal) outMap.get('capital');

        Assert.areEqual(1, filteredResult.size(), 'Solo un elemento MCH debe incluirse antes de ACH');
        Assert.areEqual(1000.00, capital, 'Debe sumar solo el AMZ antes del primer ACH');
    }

    @isTest
    static void testGetCapital_noAMZPresent() {
        Map<String, Object> input = new Map<String, Object>();
        List<Object> transactionList = new List<Object>();

        // MCH sin AMZ
        Map<String, Object> mchNoAMZ = new Map<String, Object>{
            'type' => 'MCH',
            'details' => new Map<String, Object>{
                'detail' => new List<Object>{
                    new Map<String, Object>{ 'openAmount' => '999.99', 'chargeType' => 'IVA' }
                }
            }
        };

        transactionList.add(mchNoAMZ);

        input.put('transaction', transactionList);
        Map<String, Object> outMap = new Map<String, Object>();

        FIN_PagoMinimoCapital classUnderTest = new FIN_PagoMinimoCapital();
        Test.startTest();
        classUnderTest.invokeMethod('getCapital', input, outMap, new Map<String, Object>());
		Test.stopTest();
        Assert.areEqual(0, outMap.get('capital'), 'El capital debe ser cero si no hay AMZ');
        Assert.areEqual(1, ((List<Object>) outMap.get('result')).size(), 'Debe incluir el MCH aunque no tenga AMZ');
    }

    @isTest
    static void testGetCapital_withNullOrInvalidInput() {
        Map<String, Object> input = new Map<String, Object>{
            'transaction' => null // Simula entrada inválida
        };

        Map<String, Object> outMap = new Map<String, Object>();

        FIN_PagoMinimoCapital classUnderTest = new FIN_PagoMinimoCapital();
        
        Test.startTest();
        classUnderTest.invokeMethod('getCapital', input, outMap, new Map<String, Object>());
    	Test.stopTest();

        Assert.isTrue(outMap.containsKey('capital'), 'Debe tener clave "capital" incluso con entrada inválida');
        Assert.areEqual(0, outMap.get('capital'), 'El capital debe ser cero con entrada inválida');
    }
}