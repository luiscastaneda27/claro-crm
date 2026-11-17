@isTest
public class PVU_MessageMgmtTest {
    
    @isTest
    private static void callIPTest(){

        Case casetest = new Case();
        insert casetest;

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'callIP';
        String procedureName = 'PVU_IPsvcCaseInfo';
        String methodName = 'callIP';
        String ContextId = String.valueOf(casetest.Id);
        input.put('methodName', methodName);
        input.put('procedureName',procedureName);
        input.put('ContextId',ContextId);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_MessageMgmt messageInterface = new PVU_MessageMgmt();
        testWasCalled = (Boolean) messageInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        System.assertEquals('Successful test', (String) response.get('messageCallIP'), 'El mensaje no coincide');
    }
    
     @isTest
    private static void updateMessageTest(){

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'UpdateMessage';
        String methodName = 'UpdateMessage';
        String Message = 'Hola %accountName%, orden %ordenNumero%, tercero %nombreTercero%, direccion %direccion%';
        String AccountName = 'AccountName Test';
		String OrdenNumero = '123';
		String NombreTercero = 'Tercero Test';
		String Direccion = 'Direccion Test';
        input.put('methodName', methodName);
        input.put('Message',Message);
        input.put('AccountName',AccountName);
        input.put('OrdenNumero',OrdenNumero);
        input.put('NombreTercero',NombreTercero);
        input.put('Direccion',Direccion);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_MessageMgmt messageInterface = new PVU_MessageMgmt();
        testWasCalled = (Boolean) messageInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
        // System.assertEquals('Successful test', (String) response.get('UpdateMessageOutput'), 'El mensaje no coincide');
    }

    @isTest
    private static void updateMessageTestDate(){

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        String action = 'UpdateMessage';
        String methodName = 'UpdateMessage';
        String Message = 'Hola %accountName%, orden %ordenNumero%, tercero %nombreTercero%, direccion %direccion%';
        String AccountName = 'AccountName Test';
		String OrdenNumero = '123';
		String NombreTercero = 'Tercero Test';
		String Direccion = 'Direccion Test';
        input.put('methodName', methodName);
        input.put('Message',Message);
        input.put('AccountName',AccountName);
        input.put('OrdenNumero',OrdenNumero);
        input.put('NombreTercero',NombreTercero);
        input.put('Direccion',Direccion);
        input.put('dateNow', Date.today());
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        Boolean testWasCalled = false;
        Test.startTest();
        PVU_MessageMgmt messageInterface = new PVU_MessageMgmt();
        testWasCalled = (Boolean) messageInterface.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
        Map<String, Object> response = (Map<String, Object>) output.get('response');
    }
}