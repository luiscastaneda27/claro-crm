@isTest
private class ListComparerTest {

    @isTest
    static void testFilterList() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 

        // Sample input data
        Map<String, Object> lista1 = new Map<String, Object>{
            'Field1' => 'Value1',
            'Field2' => 'Value2',
            'Field3' => 'Value3'
        };
        String fields = 'Field1,Field3';

        inputMap.put('lista1', lista1);
        inputMap.put('fields', fields);

        // Call the method to be tested
        test.startTest();
            ListComparer postOrderMethod = new ListComparer();
            Boolean result = postOrderMethod.invokeMethod('filterList', inputMap, outputMap, options);
        test.stopTest();

        // Assert the output
        System.assertEquals('Value1', outputMap.get('Field1'));
        System.assertEquals('Value3', outputMap.get('Field3'));
    }

     @isTest
    static void testFilterListComplete() {
  
          String fiels = 'Status';

          List<Object> listLast = new List<Object>();
          Map<String, Object> listData = new Map<String, Object>(); 

          listData.put('CaseNumber', '00001016');
          listData.put('Status', 'Test');
          listData.put('FirstName', 'test21');

          listLast.add(listData);

          Map<String, Object> inputMap = new Map<String, Object>(); 
          Map<String, Object> outputMap = new Map<String, Object>();
          Map<String, Object> options = new Map<String, Object>();  
          inputMap.put('listInput',  listLast);
          inputMap.put('fields', fiels );

          test.startTest();
            ListComparer postOrderMethod = new ListComparer();
            Boolean result = postOrderMethod.invokeMethod('filterListComplete', inputMap, outputMap, options);
          test.stopTest();

          System.debug('resutl' + outputMap);

          List<Object> resultout = (List<Object>) outputMap.get('result');

          Assert.areEqual(resultout.size(), 1);
          
    }
}