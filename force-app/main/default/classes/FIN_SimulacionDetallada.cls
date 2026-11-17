global with sharing class FIN_SimulacionDetallada implements vlocity_cmt.VlocityOpenInterface2 {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        if (methodName.equals('getPlazosDisponibles')) {
            getPlazosDisponibles(input, outMap, options);
        }
        
        // Return true to indicate successful execution.
        return true;
    }
    
	public void getPlazosDisponibles(Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options){
        List<Object> plazosDisponibles = new List<Object>();
        
        try{
        	List<Object> lstMapInputPlazos = (List<Object>) input.get('lstMapInputPlazos');
            String idProduct = (String) input.get('idProduct');
            String idOpportunity = (String) input.get('idOpportunity');
            List<Quote> exclusionList = [SELECT FIN_PlazoMeses__c FROM Quote WHERE OpportunityId=:idOpportunity AND FIN_MasterQuote__c = false AND FIN_PlazoMeses__c !=null AND Id IN (SELECT QuoteId FROM QuoteLineItem WHERE Product2Id=: idProduct)WITH SECURITY_ENFORCED];
            Set<Decimal> exclusionSet = new Set<Decimal>();
            for (Quote q : exclusionList) {
                exclusionSet.add(q.FIN_PlazoMeses__c);
            }
            for (Object plazoObj : lstMapInputPlazos) {
                Map<String, Object> itemPlazo = (Map<String, Object>)plazoObj;
                if (!exclusionSet.contains(Decimal.valueOf((String)itemPlazo.get('value')))) {
                    plazosDisponibles.add(itemPlazo);
                }
            }  
            outMap.put('result', plazosDisponibles);
        }
        catch(Exception ex){
        	outMap.put('result', plazosDisponibles);
        }
    }
}