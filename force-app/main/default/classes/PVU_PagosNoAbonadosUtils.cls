/*******************************************************************************
* Autor: Federico Mandri
* Fecha: 2023-09-11
* Equipo: Pos-Ventas
* HU: 644584
* Descripcion: Clase utils para funcionalidad Pagos no abonados.
				Surge de la necesidad de mostrar en pantalla el valor visible de picklist
				y no el api name, esto se resuelve en apex con función toLabel(fieldName)
***********************************************************************************/
global with sharing class PVU_PagosNoAbonadosUtils implements vlocity_cmt.VlocityOpenInterface{
    public  Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        Boolean result = true;
        try{
            if (methodName.equals('getOrdersByAccountId')){
            	getOrdersByAccountId(input, outMap, options);
        	}
            else if (methodName.equals('getOrdersAvailable')){
                getOrdersAvailable(input, outMap, options);
            }
        }
        catch(Exception ex){
            outMap.put('error', ex.getStackTraceString()); 
            outMap.put('MensajeExcepcion', ex.getMessage());
            outMap.put('Linea', ex.getLineNumber());
            outMap.put('Causa', ex.getCause());
            system.debug('MensajeExcepcion: ' + ex.getMessage());
            system.debug('Linea: ' + ex.getLineNumber());
            system.debug('Causa: ' + ex.getCause());
            System.debug('Stack: ' + ex.getStackTraceString());
            result = false;
        }
        return result;
    }
    
    /*****************************************************************************************
	* Autor: Federico Mandri
	* Fecha: 2023-09-11
    * Equipo: Pos-Ventas
    * HU: 644584
    * Descripcion: Busca todas las ordenes para la cuenta cliente (AccountId -> Consumer)
	***********************************************************************************************/
    public void getOrdersByAccountId(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        String AccountId = (String)input.get('AccountId');
        List<Order> ordenes = [SELECT Id, AccountId, toLabel(Status), toLabel(FVU_PaymentStatus__c), toLabel(FVU_ClosingReason__c) FROM Order WHERE AccountId = :AccountId WITH USER_MODE];
        outMap.put('Ordenes', ordenes);
    }
    
    /*****************************************************************************************
	* Autor: Federico Mandri
	* Fecha: 2023-09-11
    * Equipo: Pos-Ventas
    * HU: 644584
    * Descripcion: Busca las ordenes de la cuenta que cumplen los criterios de entrada de pagos no abonados
	***********************************************************************************************/
    public void getOrdersAvailable(Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options){
        String AccountId = (String)input.get('AccountId');
        List<Order> ordenes = [SELECT Id, AccountId, OrderNumber, toLabel(Status), toLabel(FVU_PaymentStatus__c), toLabel(FVU_ClosingReason__c)
                               FROM Order 
                               WHERE AccountId = :AccountId
                               AND ( (toLabel(Status) = 'Cerrada Perdida' AND toLabel(FVU_ClosingReason__c) = 'Cancelado por no finalización de orden') 
                                   OR (toLabel(Status) = 'En Proceso de Pago' AND toLabel(FVU_PaymentStatus__c) = 'Pendiente de pago')
                                   OR (toLabel(Status) = 'Cerrada Ganada' ))
                               WITH USER_MODE];
        outMap.put('Ordenes', ordenes);
    }

}