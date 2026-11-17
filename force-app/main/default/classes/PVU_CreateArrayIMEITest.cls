@isTest
private class PVU_CreateArrayIMEITest {

    @isTest
    static void testArrayIMEIOK() {

        Map<String,Object> input = new Map<String,Object>();
        
        List<Object> listaReportes = new List<Object>();
        listaReportes.add(new Map<String,Object>{
            'tipoReporte' => 'Hurto',
            'operador' => '00003',
            'fechaReporte' => 'May 7, 2020, 8:59:56 PM',
            'msisdn' => '3122575523'
        });

        input.put('listaReportesBean', listaReportes);

        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        PVU_CreateArrayIMEI clase = new PVU_CreateArrayIMEI();

        Test.startTest();
        Boolean result = clase.invokeMethod('arrayIMEI', input, output, options);
        Test.stopTest();

        System.assertEquals(true, result);
        System.assert(output.containsKey('response'));
    }


    @isTest
    static void testArrayIMEIException() {
    
        Map<String,Object> input = new Map<String,Object>();
    
        Map<String,Object> output = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
    
        PVU_CreateArrayIMEI clase = new PVU_CreateArrayIMEI();
    
        Test.startTest();
        Boolean result = clase.invokeMethod('arrayIMEI', input, output, options);
        Test.stopTest();
    
        System.assertEquals(false, result);
        System.assert(output.containsKey('EXCEPTION'));
    
        Map<String,Object> exceptionMap = (Map<String,Object>) output.get('EXCEPTION');
        System.assert(exceptionMap.containsKey('Message'));
    }
}