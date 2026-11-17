@isTest
public class PVU_ReconocerSystemInterfaceTest {
	
    @isTest
    private static void callReconocer(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String tipoDoc = '1';
        String action = 'callIP';
        String numDoc = '49778167';
        String apellido = 'Perez';
        String methodName = 'PVU_IPsvcReconocer';
        input.put('procedureName', methodName);
        input.put('tipoDocumento', tipoDoc);
        input.put('numeroDocumento', numDoc);
        input.put('apellido', apellido);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_ReconocerSystemInterface reconocerInterface = new PVU_ReconocerSystemInterface();
        	testWasCalled = (Boolean) reconocerInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('Juan Perez Test', (String) response.get('nombreComplero'), 'El nombre no coincide');
    }
    
    @isTest
    private static void callReconocerException(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Decimal tipoDoc = 3; // se pasa un tipo de dato que hace saltar excepcion
        String action = 'callIP';
        String numDoc = '49778167';
        String methodName = 'PVU_IPsvcReconocer';
        input.put('procedureName', methodName); 
        input.put('tipoDocumento', tipoDoc);
        input.put('numeroDocumento', numDoc);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        	PVU_ReconocerSystemInterface reconocerInterface = new PVU_ReconocerSystemInterface();
        	testWasCalled = (Boolean) reconocerInterface.call(action, args);
        Test.stopTest();
        System.assert(!testWasCalled, 'El método de test sí fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('EXCEPTION');
        String exceptionMessage = (String) response.get('Message');
        System.assert(!String.isBlank(exceptionMessage), 'El mensaje de exception es vacio');
    }
    
}