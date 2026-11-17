@isTest
public class PVUBusnessHoursUtilTest {
@isTest
    static void getDateAfterDaysTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVUBusnessHoursUtil testclass = new PVUBusnessHoursUtil();       
        
        input.put('Warranty','false');
        input.put('NoConformingDays','3');     
        input.put('RetractoCompraDays','3'); 
        input.put('DateAfterCreateDays','3');
        Date hoy = Date.today();
        Time myTime = Time.newInstance(9, 0, 0, 0);
        Datetime myDate = Datetime.newInstance(hoy, myTime);
		input.put('dateInitial',myDate);         
        
        List<Map<String,Object>> optionsList = new List<Map<String,Object>>();
       
        Test.startTest();
        testclass.invokeMethod('getDateAfterDays',input,output,options);
        Test.stopTest();
        system.debug('NoConformingFinal>>>'+output.get('NoConformingFinal'));
        system.debug('RetractoCompraFinal>>>>'+output.get('RetractoCompraFinal'));
        System.assert(output.get('NoConformingFinal') != null,'Fallo Lista NoConformingFinal');
         System.assert(output.get('RetractoCompraFinal') != null,'Fallo Lista RetractoCompraFinal');
    }
    
    @isTest
    static void calculateBusinessDaysForCancellationTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVUBusnessHoursUtil testclass = new PVUBusnessHoursUtil();       
        
        Date hoy = Date.today();
        Time myTime = Time.newInstance(9, 0, 0, 0);
        Datetime myDate = Datetime.newInstance(hoy, myTime);
		input.put('dateInitial',myDate);
       
        Test.startTest();
        testclass.invokeMethod('calculateBusinessDaysForCancellation',input,output,options);
        Test.stopTest();
        System.assert(output.get('dateCalculated') != null,'calculateBusinessDaysForCancellationTest');
    }
    
    @isTest
    static void catchErrorTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVUBusnessHoursUtil testclass = new PVUBusnessHoursUtil();
       
        Test.startTest();
        testclass.invokeMethod(null,input,output,options);
        Test.stopTest();
        System.assert(output.get('error -> ') != null,'catchErrorTest');
    }
}