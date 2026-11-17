@IsTest
public class PVU_IntegrationProcedureInvocableTest {
   
    @IsTest
    static void testCallProcedureOmniStudioSuccess() {
        List < PVU_IntegrationProcedureInvocable.IntegrationProcedureInput > input= new List < PVU_IntegrationProcedureInvocable.IntegrationProcedureInput >();
        List < PVU_IntegrationProcedureInvocable.IntegrationProcedureOutput > output=new List < PVU_IntegrationProcedureInvocable.IntegrationProcedureOutput >();
        PVU_IntegrationProcedureInvocable.IntegrationProcedureInput ipi=new PVU_IntegrationProcedureInvocable.IntegrationProcedureInput();
        List<ProcedureMapping> pmList=new List<ProcedureMapping>();
        ProcedureMapping pm=new ProcedureMapping();
        pm.key='';
        pm.value='';
        pmList.add(pm);
        
        ipi.input=pmList;
        ipi.procedureAPIName='';
        input.add(ipi);               

        Test.startTest();
           output= PVU_IntegrationProcedureInvocable.runIntegrationServiceInvocable(input);
        System.debug(LoggingLevel.debug,'salida>>>'+ JSON.serialize(output));
        System.assert(!output.isEmpty());
        Test.stopTest();
    }
    
   /* @IsTest
    static void testCallProcedureOmniStudioException() {
         
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', null);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            PVU_IntegrationProcedureInvocable callInterface = new PVU_IntegrationProcedureInvocable();
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
        
    }    */

}