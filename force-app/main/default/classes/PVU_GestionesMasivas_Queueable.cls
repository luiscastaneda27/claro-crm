/*******************************************************************************
* Autor: Hllanos
* Fecha: 2024-10-25
* Equipo: Pos-Ventas
* Descripcion: Handler para el proceso de gestiones masivas.
* History
<Date>            <Author>             <Description>             <Version>
2024-10-25         hllanos                 creacion                   01
2025-03-24         hllanos               Add new method  callAsyncIP  02
***********************************************************************************/
public class PVU_GestionesMasivas_Queueable implements Queueable{
    private String cartId;
    private String gestionId;
    private String operation;
    public PVU_Gestiones_Masivas_Handler.WGestionMasiva WGestionMasiva;
    public Map<String,Object> inputIP;
    public Map<String,Object> outputIP;
    public Map<String,Object> optionIP;
    public string ipname;
    
    public PVU_GestionesMasivas_Queueable(String cartId, String gestionId){
        this.cartId = cartId;
        this.gestionId = gestionId;
        this.operation = 'checkout';
    }
    
    public PVU_GestionesMasivas_Queueable(String cartId, String gestionId, String operation){
        this.cartId = cartId;
        this.gestionId = gestionId;
        this.operation = operation;
    }
    public PVU_GestionesMasivas_Queueable(String operation, PVU_Gestiones_Masivas_Handler.WGestionMasiva gm){
        this.cartId = cartId;
        this.gestionId = gestionId;
        this.operation = operation;
        this.WGestionMasiva = gm;
    }
    
    public PVU_GestionesMasivas_Queueable(String ipname, Map<String,Object> input, Map<String,Object> options){
        this.operation = 'callAsyncIP';
        this.ipname = ipname;
        this.inputIP = input;
        this.optionIP = options;
    }
    
    public void execute(QueueableContext context) {
        switch on this.operation {
            when 'checkout' {	
                Map<String, Object> inputMap = new Map<String, Object>();
                Map<String, Object> outputMap = new Map<String, Object>();
                Map<String, Object> optionsMap = new Map<String, Object>();
                PVU_GestionesMasivas_Interface assetToOrderClass = new PVU_GestionesMasivas_Interface();
                
                String status = 'Orden checkout';
                String msj = '';
                try{
                    inputMap.put('cartId', this.cartId);
                    assetToOrderClass.invokeMethod('checkout', inputMap, outputMap,optionsMap);
                    system.debug('PVU_GestionesMasivas_Queueable: checkout:'+outputMap);
                    //status = outputMap.get('status') == 'success' ? 'Orden checkout' : 'Error';
                    //msj = 'Error order checkout';
                }catch(Exception ex){
                    system.debug('Error checkout: ' + ex.getMessage());
                    status = 'Error';
                    msj = 'Error order checkout:' + ex.getMessage();
                }
                
                PVU_Gestiones_Masivas__c gestionM = new PVU_Gestiones_Masivas__c(
                    Id = gestionId,
                    PVU_Status__c = status,
                    PVU_Message__c = msj
                );
                
                update gestionM;
            }	
            when 'procesarOrdenYCaso' {
                system.debug('procesarOrdenYCaso:::' + this.WGestionMasiva);
                PVU_Gestiones_Masivas_Handler handler = new PVU_Gestiones_Masivas_Handler();
                //Crear Orden
                handler.createOrder(this.WGestionMasiva);
                system.debug('procesarOrdenYCaso2:::' + this.WGestionMasiva);
                if(this.WGestionMasiva.StatusOrden){
                    //crear caso
                    handler.createCase(this.WGestionMasiva);
                    
                    //Update and checkout(Queuable) Orden
                    handler.updateOrder(this.WGestionMasiva);
                }
                
                handler.updateRecordGestionMasiva(this.WGestionMasiva);
            }
            when 'callAsyncIP' {
                system.debug('callAsyncIP:' + this.ipname + '----' + this.inputIP + '----' + this.optionIP);
                vlocity_cmt.IntegrationProcedureService.runIntegrationService(this.ipname, this.inputIP, this.optionIP);
                system.debug('callAsyncIP output:'  );
            }
            when else {		
                
            }
        }
        
    }
}