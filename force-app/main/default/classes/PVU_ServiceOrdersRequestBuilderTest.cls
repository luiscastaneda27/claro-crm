@isTest
public class PVU_ServiceOrdersRequestBuilderTest {
    @isTest
    static void callRequestBuilder(){
        String action = 'buildRequest';
        String documentNumber = '245332';
        String documentType = '1';
        DateTime requestDate = System.Now();
        Boolean testWasCalled = false;
        Map<String, Object> headerRequest = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();

        headerRequest.put('requestDate', requestDate);
        input.putAll(headerRequest);
        input.put('documentType', documentType);
        input.put('documentNumber', documentNumber);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        Test.startTest();
            PVU_ServiceOrdersRequestBuilder builder = new PVU_ServiceOrdersRequestBuilder();
            testWasCalled = (Boolean) builder.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
    }
    
    @isTest
    static void callRequestByODSIdBuilder(){
        String action = 'buildRequestByOds';
        String idOds = '245332';
        DateTime requestDate = System.Now();
        Boolean testWasCalled = false;
        Map<String, Object> headerRequest = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();

        headerRequest.put('requestDate', requestDate);
        input.putAll(headerRequest);
        input.put('idOds', idOds);
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);

        Test.startTest();
            PVU_ServiceOrdersRequestBuilder builder = new PVU_ServiceOrdersRequestBuilder();
            testWasCalled = (Boolean) builder.call(action, args);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
    }
    
     @isTest
    static void callgetInterfazSettringMTDByName(){
        String action = 'getInterfazSettringMTDByName';
        String metadataKey = 'PVU_DiasCancelacionParcialNumeroNoClaro';
        Map<String, Object> input = new Map<String, Object>();
        Boolean testWasCalled = false;
        input.put('arguments', new List<String>{metadataKey});
        
        
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        args.put('options', options);
        
        Test.startTest();
            PVU_ServiceOrdersRequestBuilder builder = new PVU_ServiceOrdersRequestBuilder();
            testWasCalled = (Boolean) builder.call(action, args);
        	system.debug(builder);
        Test.stopTest();
        System.assert(testWasCalled, 'El método de test no fue llamado');
    }
}