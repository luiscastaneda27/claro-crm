/*--------------------------------------------------------------------------
Author:         Hever Salas - hever.salas@nespon.com
Company:        Salesforce.com
Code Coverage:  91%

History
<Date>         <Version>  	<Author>           <Description>             					
20-02-2026       1.0.0      Hever Salas           Initial                   			
----------------------------------------------------------------------------*/
@IsTest
private class EU_CallSystemInterfaceTest {
    
    @IsTest
    static void testCallProcedureOmniStudioSuccess() {
        
        String response ='{"Id":"1234"}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(response); 
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', inputMap);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            EU_CallSystemInterface callInterface = new EU_CallSystemInterface();
            callInterface.call('procedureName', args);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCallProcedureOmniStudioException() {
         
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', null);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            EU_CallSystemInterface callInterface = new EU_CallSystemInterface();
            callInterface.call('procedureName', args);
        	System.assert(outputMap.isEmpty());
        Test.stopTest();
        
    }

    @IsTest
    static void testCallProcedureFlowSuccess() {
        
        EU_CallSystemInterface.ProcedureWrapper procWrapper = new EU_CallSystemInterface.ProcedureWrapper();
        List<EU_CallSystemInterface.ProcedureWrapper> lstProcedureWrapper = new List<EU_CallSystemInterface.ProcedureWrapper>();
        procWrapper.mapping = new List<ProcedureMapping>();
        ProcedureMapping procMapping = new ProcedureMapping();
        
        procWrapper.procedureName = 'procedureName';
        procMapping.key = 'Id';
        procMapping.value = '1234';
        
        procWrapper.mapping.add(procMapping);
        lstProcedureWrapper.add(procWrapper);

        Test.startTest();
            List<EU_CallSystemInterface.ProcedureResult> lstProcedureResult = EU_CallSystemInterface.callProcedure(lstProcedureWrapper);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCallProcedureFlowSuccessFuture() {
        
        EU_CallSystemInterface.ProcedureWrapper procWrapper = new EU_CallSystemInterface.ProcedureWrapper();
        List<EU_CallSystemInterface.ProcedureWrapper> lstProcedureWrapper = new List<EU_CallSystemInterface.ProcedureWrapper>();
        procWrapper.mapping = new List<ProcedureMapping>();
        ProcedureMapping procMapping = new ProcedureMapping();
        
        procWrapper.procedureName = 'procedureName';
        procMapping.key = 'OrderId';
        procMapping.value = '1234';
        
        ProcedureMapping procMappingFuture = new ProcedureMapping();
        procMappingFuture.key = 'CallFuture';
        procMappingFuture.value = 'true';
        
        procWrapper.mapping.add(procMapping);
        procWrapper.mapping.add(procMappingFuture);
        lstProcedureWrapper.add(procWrapper);

        Test.startTest();
            List<EU_CallSystemInterface.ProcedureResult> lstProcedureResult = EU_CallSystemInterface.callProcedure(lstProcedureWrapper);
        Test.stopTest();
        
    }    

}