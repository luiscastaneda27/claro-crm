/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class to filter fields from a list
Test Class:     ListComparerTest
History
<Date>          <Author>          <Change Description>
                Matheus Forgane     Initial Version
22/11/23        Luis Mendoza        Add Method 'filterListComplete'
08/03/24		    Luis Mendoza        fixed issue in method 'filterListComplete'
------------------------------------------------------------*/
global class ListComparer implements vlocity_cmt.VlocityOpenInterface2 {
  global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
      Boolean result = true;
      try {
          switch on methodName {
              when 'filterList' {
                  filterList(input, output);
              }
              when 'filterListComplete' {
                filterListComplete(input, output);
              }
          }
      } catch(Exception ex) {
          result = false;
          output = null;
          // output.put('Error', ex.getMessage());
          System.debug('Exception: ' + ex);
          System.debug('Error message: ' + ex.getMessage()); 
          System.debug('Stack trace: ' + ex.getStackTraceString());
      }

      return result;
  }

  //Metodo para filtragem dos fields
  public void filterList(Map<String, Object> inputMap,Map<String, Object> output) {
    Map<String,Object> lista1 = (Map<String,Object>)inputMap.get('lista1');
/*     output.put('debug', lista1);
 */
    String Fields = (String)inputMap.get('fields');

    List<String> ListaDosInputs = fields.split(',');

/*     Map<String,Object> InputFinal = new Map<String,Object>();
 */    
    For(String IdentacaoObject : ListadosInputs){
      String valueToCompare = IdentacaoObject;
      output.put(valueToCompare, lista1.get(valueToCompare));
      output.remove('errorCode');
      output.remove('error');
    }
  }


/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Method filter field from list 
Test Class:     ListComparerTest
History
<Date>          <Author>          <Change Description>
                Luis Mendoza        Initial Version
08/03/24		    Luis Mendoza        fixed issue in this method
------------------------------------------------------------*/
  public void filterListComplete(Map<String, Object> inputMap,Map<String, Object> output) {

    System.debug('here filterListComplete');
    
    List<Map<String, Object>> listMap = new List<Map<String, Object>>();
    List<Map<String, Object>> listOut = new List<Map<String, Object>>();
    
    List<Object> listAny = (List<Object>) inputMap.get('listInput');
    String fieldsCompare = (String)inputMap.get('fields');
    
    for (Object instance : listAny ){
      listMap.add((Map<String, Object>) instance);
    }
    
    System.debug('here listMap'+ listMap);
    
    
    List<String> list2Inputs = fieldsCompare.split(',');
    
    for (Map<String,Object> itm : listMap) {
      Map<String, Object> mapOut = new Map<String, Object>();
      for (String compare : list2Inputs) {
        mapOut.put(compare, itm.get(compare));
      }
      listOut.add(mapOut);
    }

    output.put('result',listOut);
    output.remove('errorCode');
    output.remove('error');

  }
}