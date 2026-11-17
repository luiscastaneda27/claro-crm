@IsTest
private class FVU_CallSystemInterfaceTest {
    
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
            FVU_CallSystemInterface callInterface = new FVU_CallSystemInterface();
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
            FVU_CallSystemInterface callInterface = new FVU_CallSystemInterface();
            callInterface.call('procedureName', args);
        	System.assert(outputMap.isEmpty());
        Test.stopTest();
        
    }

    @IsTest
    static void testCallProcedureFlowSuccess() {
        
        FVU_CallSystemInterface.ProcedureWrapper procWrapper = new FVU_CallSystemInterface.ProcedureWrapper();
        List<FVU_CallSystemInterface.ProcedureWrapper> lstProcedureWrapper = new List<FVU_CallSystemInterface.ProcedureWrapper>();
        procWrapper.mapping = new List<ProcedureMapping>();
        ProcedureMapping procMapping = new ProcedureMapping();
        
        procWrapper.procedureName = 'procedureName';
        procMapping.key = 'Id';
        procMapping.value = '1234';
        
        procWrapper.mapping.add(procMapping);
        lstProcedureWrapper.add(procWrapper);

        Test.startTest();
            List<FVU_CallSystemInterface.ProcedureResult> lstProcedureResult = FVU_CallSystemInterface.callProcedure(lstProcedureWrapper);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCallProcedureFlowSuccessFuture() {
        
        FVU_CallSystemInterface.ProcedureWrapper procWrapper = new FVU_CallSystemInterface.ProcedureWrapper();
        List<FVU_CallSystemInterface.ProcedureWrapper> lstProcedureWrapper = new List<FVU_CallSystemInterface.ProcedureWrapper>();
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
            List<FVU_CallSystemInterface.ProcedureResult> lstProcedureResult = FVU_CallSystemInterface.callProcedure(lstProcedureWrapper);
        Test.stopTest();
        
    }    

}