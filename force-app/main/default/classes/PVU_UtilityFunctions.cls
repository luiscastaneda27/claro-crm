/**
 * @description       : Utility Class
 * @author            : Salesforce.com
 * @group             : Posventa
 * @last modified on  : 09-24-2024
 * History
<Date>            <Author>             <Description>                                      <Version>
2025-03-10         hllanos     Ajuste para manejo de errores en caso que el caso se cierre manualmente                   02
**/
global with sharing class PVU_UtilityFunctions implements vlocity_cmt.VlocityOpenInterface {
            
	global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        if (methodName == 'ListToObjects')      
            outputMap.put('result', ListToObjects((List<Object>)inputMap.get('listObject'),(String) inputMap.get('label')));
        return true;
    }
         
     private List<Object> ListToObjects(List<Object> args, String label) {
    	
		List<Object> iterableObj = new List<Object>();
        List<Map<String,object>> out=new List<Map<String,object>>();
                        
        for (Object obj:args){
            String value=(String) obj;
            Map<String,object> objMap= new Map<String,object>();
            objMap.put(label,value);
            out.add(objMap);
        }
                
         return out;
    }
    
    /*
	* Created Date: 20240531
	* Created By: Federico Mandri
	* HU: 692695
	* Description: Implementation from flow call - given parameter order id related to change of SimCard Case, return Sim data from the new Sim Asset
	*/
    @InvocableMethod(label='getNewSimInformation' description='Get new Sim data for change of SimCard feature')
	public static List<SimInfo> getNewSimInformationByOrderId (List<SimInput> inputs){
        Asset newSimAsset = null;
        Map<String, Object> attrMap = new Map<String, Object>();
		SimInfo sim = new SimInfo();
        List<SimInfo> listOutput = new List<SimInfo>();

		Case caseOfOrder = [SELECT ID, PVU_ICCID_Temporal__c, PVU_tipoSIM__c
							FROM Case
							WHERE PVU_Order__c = :inputs.get(0).orderId 
							WITH SYSTEM_MODE LIMIT 1];

        String subTypeProd = caseOfOrder.PVU_tipoSIM__c == 'E-Sim' ? 'eSIM' : 'SIM Card';

		OrderItem ordItem = [SELECT  vlocity_cmt__AssetReferenceId__c
							FROM ORderItem 
							WHERE OrderId = :inputs.get(0).orderId 
							AND Product2.vlocity_cmt__Type__c = 'SIM Card' 
							AND Product2.vlocity_cmt__SubType__c = :subTypeProd
                             WITH SYSTEM_MODE LIMIT 1];
        try{
            newSimAsset = [SELECT Id, vlocity_cmt__AttributeSelectedValues__c
                                 FROM Asset 
                                 WHERE vlocity_cmt__AssetReferenceId__c =: ordItem.vlocity_cmt__AssetReferenceId__c
                                 WITH SYSTEM_MODE LIMIT 1];
            
            String newSimAttributes = newSimAsset.vlocity_cmt__AttributeSelectedValues__c;
            attrMap = (Map<String, Object>) JSON.deserializeUntyped(newSimAttributes);
        }catch(Exception ex){
            System.debug('Error al obtener sim information: ' + ex.getMessage());
            sim.puk =  newSimAsset != null ? (String)attrMap.get('B2C-ATTR-SIM-PUK') : '';
			sim.iccid = caseOfOrder!= null ? caseOfOrder.PVU_ICCID_Temporal__c : '';
        }
		
		sim.puk = (String)attrMap.get('B2C-ATTR-SIM-PUK');
		sim.iccid = caseOfOrder.PVU_ICCID_Temporal__c;
        
        listOutput.add(sim);
        
        //System.debug('List Output: ' + listOutput);
        
		return listOutput;
	}
	
	public Class SimInput{
		@InvocableVariable (label = 'Order Id') public String orderId;
	}
	
	global Class SimInfo{
		@InvocableVariable(label = 'ICCID') public String iccid;
		@InvocableVariable(label = 'PUK') public String puk;
	}
     
}