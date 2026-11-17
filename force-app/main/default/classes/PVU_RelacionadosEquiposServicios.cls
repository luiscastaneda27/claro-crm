/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class PVU_RelacionadosEquiposServicios implements vlocity_cmt.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        System.debug('Method Name: '+methodName);
        System.debug('Input '+input);
        System.debug('outmap '+ outMap);
        System.debug('options '+ options);
        
        if (methodName == 'obtenerDetalle') {
            obtenerDetalle(input, outMap, options);    
        }
        
        return true;
    }
    
    public void obtenerDetalle( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String recId =(String)input.get('RelServEquipoId');
        
        PVU_Relacion_de_servicios_y_equipos__c rec = [Select Id, PVU_Serial_o_Imei__c, PVU_Order__c, PVU_caso_relacionado__c, PVU_Fecha_Factura__c , 
                                                      PVU_Order__r.FIN_NumeroDeFacturaDeVenta__c, PVU_Order__r.OrderNumber, PVU_Order__r.FIN_NumeroCredito__c,
                                                      PVU_caso_relacionado__r.Account.FVU_Email__c, PVU_caso_relacionado__r.Account.Name, 
                                                      PVU_caso_relacionado__r.Account.FVU_DocumentNumber__c, PVU_caso_relacionado__r.PVU_MotivoDevolucion__c,
                                                      PVU_caso_relacionado__r.PVU_CUN__c, PVU_caso_relacionado__r.PVU_IdODS__c, PVU_EsFinanciado__c,PVU_CuentaFinanciamiento92__c
                                                      FROM PVU_Relacion_de_servicios_y_equipos__c 
                                                      WHERE Id =: recId WITH SYSTEM_MODE];
        
        List<OrderItem> lstOrderItem = [SELECT id, FVU_sapBillingNbr__c FROM OrderItem WHERE OrderId =: rec.PVU_Order__c AND FVU_sapBillingNbr__c != null WITH SYSTEM_MODE LIMIT 1];
        
        User userInfo = [SELECT FVU_CentroLogistico__c, FVU_CAV__c FROM User WHERE Id=:UserInfo.getUserId() WITH SYSTEM_MODE];
        String numFactura = !lstOrderItem.isEmpty() ? lstOrderItem[0].FVU_sapBillingNbr__c: '';  

        
        String note = 
            'Número de Factura: ' + numFactura + '\n' +
            'Documento de identidad Cliente: ' + rec.PVU_caso_relacionado__r.Account.FVU_DocumentNumber__c + '\n' +
            'Nombre del Cliente: ' + rec.PVU_caso_relacionado__r.Account.Name + '\n' +
            'Correo Electrónico: ' + rec.PVU_caso_relacionado__r.Account.FVU_Email__c + '\n' +
            'Motivo Nota de Crédito: ' + rec.PVU_caso_relacionado__r.PVU_MotivoDevolucion__c + '\n' +
            'Motivo de Pedido: ' + 'Devolución en ventas' + '\n' +
            'CUN/ODS: ' + rec.PVU_caso_relacionado__r.PVU_CUN__c+'/'+rec.PVU_caso_relacionado__r.PVU_IdODS__c + '\n' +
            
            'Fecha de Factura: ' + rec.PVU_Fecha_Factura__c + '\n' +
            'Número del Centro del CAV donde se está realizando el trámite: ' + userInfo.FVU_CentroLogistico__c + '\n' +
            'Número del Almacén del CAV donde se está realizando el trámite: ' + userInfo.FVU_CAV__c + '\n' +
            'No. Crédito (Si Aplica):  ' + rec.PVU_Order__r.FIN_NumeroCredito__c + '\n';
        
        outMap.put('userInfo',userInfo);
        outMap.put('relacionadoServicio',rec);
        outMap.put('nota',note);
        outMap.put('orderItem',lstOrderItem);
        
    }

}