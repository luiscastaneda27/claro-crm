@isTest
public class PVU_ODSSystemInterfaceTest {
	@isTest
    private static void callGetODS(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String contextId = '123456789012345';
        String action = 'callIP';
        String methodName = 'PVU_IPsvcGetODSWrapper';
        input.put('procedureName', methodName);
        input.put('contextId', contextId);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_ODSSystemInterface odsInterface = new PVU_ODSSystemInterface();
        	testWasCalled = (Boolean) odsInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        //Map<String, Object> response = (Map<String, Object>) output.get('response');
        //System.assertEquals('Juan Perez Test', (String) response.get('nombreComplero'), 'El nombre no coincide');
    }
    
    @isTest
    private static void callGetODSException(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Decimal contextId = 3; // se pasa un tipo de dato que hace saltar excepcion
        String action = 'callIP';
        String numDoc = '49778167';
        String methodName = 'PVU_IPsvcGetODSWrapper';
        input.put('procedureName', methodName); 
        input.put('contextId', contextId);
        //input.put('numeroDocumento', numDoc);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_ODSSystemInterface odsInterface = new PVU_ODSSystemInterface();
        	testWasCalled = (Boolean) odsInterface.call(action, args);
        Test.stopTest();
        System.assert(!testWasCalled, 'El método de test sí fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('EXCEPTION');
        String exceptionMessage = (String) response.get('Message');
        System.assert(!String.isBlank(exceptionMessage), 'El mensaje de exception es vacio');
    }
}