global class FVU_CloseOrderDeliveryTypeRegBDOBDA {
    
    @InvocableMethod(label='Call IP BDOBDADel' description='Calls an Integration Procedure BDOBDADel.' category='General')
    public static void callProBDOBDADel(List<ProcedureWrapper> lstProcedureWrapper) {
        system.debug( 'OrderId --> '+lstProcedureWrapper[0].orderId);
        Map<String, Object> inputmap = new Map<String, Object>();
        Map<String, Object> outputmap = new Map<String, Object>();
        Map<String, Object> optionsmap = new Map<String, Object>();        
        inputmap.put('OrderId', lstProcedureWrapper[0].orderId);
        String ipName='FVU_RegisterBDOBDADelivery';
        Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(ipName, inputmap, optionsmap);
        system.debug( 'result --> '+result);
        
    }
    
    public class ProcedureWrapper {
        
        @InvocableVariable(required=true)
        public String orderId;
        
    }
}