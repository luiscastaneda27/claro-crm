public class FVU_CloseAbandonedOrdersBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    private static final String IP_ORDER_PAYMENT_REJECT = 'Service_OrderPaymentConfirmationReject';
    private static final String IP_SOLICITUD_PORTABILIDAD_ENTRANTE = 'FVU_SolicitudPortabilidadEntranteBatch';
    private static final String IP_BILLING_ACCOUNT_DEACTIVATE = 'FVU_BillingAccountDeactivateBatch';
    private static final String PURCHASE_TYPE_POR = 'POR';
    private static final String PRODUCT_TYPE_PLAN = 'Plan';
    private String orderPaymentStatus1 = 'PP';
    private String orderPaymentStatus2 = 'PL';
    private String orderPaymentMethod1 = 'Contado';
    private String orderPaymentMethod2 = 'Pin Link de Pagos';
    private String orderStatus = 'InPayment';
    
    public Database.QueryLocator start(Database.BatchableContext BC) { 

        String query = 'SELECT Id, Status, OrderNumber,FVU_PurchaseType__c, FVU_PortInData__c, vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c, OwnerId, '
                +'FVU_ClosingReason__c, FVU_OrderOMSId__c, FVU_OrderDeliveryStatus__c, vlocity_cmt__OrderStatus__c, FVU_PaymentStatus__c, EndDate, FVU_FechaVigencia__c, '
                +'CreatedDate, FVU_PaymentMethod__c, CreatedBy.FVU_PuntoVenta__c, Account.FVU_DocumentNumber__c, Account.vlocity_cmt__PrimaryContactId__r.LastName, '
                +'Account.vlocity_cmt__PrimaryContactId__r.FirstName, Account.FVU_DocumentType__c, vlocity_cmt__DefaultServiceAccountId__r.FVU_FullServiceAddress__c, '
                +'(SELECT FVU_InitialRegReqId__c FROM OrderItems WHERE Product2.vlocity_cmt__Type__c = :PRODUCT_TYPE_PLAN AND vlocity_cmt__ParentItemId__c = null LIMIT 1) ' + 
            'FROM Order ' + 
            'WHERE ((FVU_PaymentStatus__c = :orderPaymentStatus1 AND CreatedDate = LAST_N_DAYS:2 AND FVU_PaymentMethod__c = :orderPaymentMethod1) ' + 
            'OR ((FVU_PaymentStatus__c = :orderPaymentStatus1 OR FVU_PaymentStatus__c = :orderPaymentStatus2) AND FVU_PaymentMethod__c = :orderPaymentMethod2 '+
            'AND FVU_FechaVigencia__c = LAST_N_DAYS:2 )) ' + 
            'AND Status = :orderStatus';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {

        List<Order> lstExpiredOrders = (List<Order>)scope;
        if(lstExpiredOrders.isEmpty()) return;

        List<Map<String, Object>> listExpiredOrderMap = new List<Map<String, Object>>();
        List<Order> listExpiredOrderPor = new List<Order>();
        List<Map<String, Object>> listAccDeactivateMap = new List<Map<String, Object>>();
  
        for(Order ord : lstExpiredOrders) {

            if(ord.FVU_PurchaseType__c == PURCHASE_TYPE_POR ){
                listExpiredOrderPor.add(ord);
            }else {
                Map<String, Object> expiredOrderMap = new Map<String, Object>();
                expiredOrderMap.put('orderNumber', ord.OrderNumber);
                listExpiredOrderMap.add(expiredOrderMap);
            }

            if(ord.FVU_PurchaseType__c != 'NAP' && ord.FVU_PurchaseType__c != 'FIN'){

                Map<String, Object> accDeactivateMap = new Map<String, Object>();
                accDeactivateMap.put('BillingAccountExternalID', ord.vlocity_cmt__DefaultBillingAccountId__r.FVU_AccountExternalID__c);
                accDeactivateMap.put('orderId', ord.Id);
                accDeactivateMap.put('userId', ord.OwnerId);
                listAccDeactivateMap.add(accDeactivateMap);
            }
        }

        if(!listExpiredOrderPor.isEmpty()){
            cancelPortability(listExpiredOrderPor, listExpiredOrderMap);
        } 

        if(!listAccDeactivateMap.isEmpty()){
            deactivateAcc(listAccDeactivateMap);
        } 

        if(listExpiredOrderMap.isEmpty()){
            return;
        } 

        //Integration Procedure maps
        Map<String, Object>  outputMap = new  Map<String, Object>();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        inputMap.put('orders', listExpiredOrderMap);
        
        //call IP - external service
        outputMap = ( Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(IP_ORDER_PAYMENT_REJECT, inputMap, options);
    }

    public static void cancelPortability(List<Order> orders, List<Map<String, Object>> listExpiredOrderMap){

        List<Map<String, Object>> listRequest = new List<Map<String, Object>>();

        for (Order order : orders) {
            Map<String, Object> request = new Map<String, Object>();
            Map<String, Object> usuario = new Map<String, Object>();
            Map<String, Object> mapPortin = new  Map<String, Object>();
            List<Object> listaPortin = new List<Object>();

            Integer tipoIdentificacion = null;
            switch on order.Account.FVU_DocumentType__c {
                when 'CC' {		
                    tipoIdentificacion = 1;
                }	
                when 'CD' {		
                    tipoIdentificacion = 6;
                }
                when 'CE' {		
                    tipoIdentificacion = 4;
                }
                when 'PP' {		
                    tipoIdentificacion = 5;
                }
                when else {		 
                    tipoIdentificacion = null;
                }
            }

            // Mapear Usuario
            usuario.put('tipoAutorizacion', '0'); 
            usuario.put('tipoUsuario', '1'); 
            usuario.put('numeroIdentidad', order.Account.FVU_DocumentNumber__c ); 
            usuario.put('apellidoAbonado', order.Account.vlocity_cmt__PrimaryContactId__r.LastName );
            usuario.put('nombreAbonado', order.Account.vlocity_cmt__PrimaryContactId__r.FirstName); 
            usuario.put('tipoIdentificacion', tipoIdentificacion); 
            usuario.put('direccionAbonado', order.vlocity_cmt__DefaultServiceAccountId__r.FVU_FullServiceAddress__c );
            request.put('usuario', usuario);

            List<Object> portInDataList = new List<Object>();
            String portInData = null;
            if(String.isNotBlank(order.FVU_PortInData__c)){
                portInDataList = (List<Object>) JSON.deserializeUntyped(order.FVU_PortInData__c);
                Map<String, Object> mapPort = new Map<String, Object>();
                mapPort =  (Map<String, Object>) portInDataList.get(0);
                portInData = (String) mapPort.get('minAPortar'); 
            }

            String initialRegReqId = null;
            if(!order.OrderItems.isEmpty()){
                initialRegReqId = order.OrderItems.get(0).FVU_InitialRegReqId__c;
            }

            // Mapear listaPortin
            mapPortin.put('regulatoryRequestStatus' , 'CANCELED');
            mapPortin.put('regulatoryRequestId', initialRegReqId ); 
            mapPortin.put('puntoDeVenta', order.CreatedBy.FVU_PuntoVenta__c);
            mapPortin.put('minAPortar', portInData);
            mapPortin.put('orderNumber', order.OrderNumber);
            listaPortin.add(mapPortin); 

            request.put('listaPortin', listaPortin);
            request.put('solicitudesSeparadas', true);
            listRequest.add(request);
        }

        Map<String, Object> requestPortin = new Map<String, Object>();
        requestPortin.put('requestPortin', listRequest);

        // call IP - Cancel PORTABILIDAD
        Map<String, Object> outputMap = new  Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        outputMap = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(IP_SOLICITUD_PORTABILIDAD_ENTRANTE, requestPortin, options);

        List<Object> respuestaIp = (List<Object>) outputMap.get('response');
        
        if(respuestaIp == null){
            return;
        }

        for( Object responsePort : respuestaIp) {

            Map<String, Object> response = (Map<String, Object>) responsePort;

            if(response.get('success') == true && response.get('error') == 'OK') {
                Map<String, Object> expiredOrderMap = new Map<String, Object>();
                expiredOrderMap.put('orderNumber', response.get('orderNumber'));
                listExpiredOrderMap.add(expiredOrderMap);
            }
        }
    }

    public static void deactivateAcc( List<Map<String, Object>> listAccDeactivateMap ){

        // call IP - Deactivate Account E//
        Map<String, Object> outputMap = new  Map<String, Object>();
        Map<String, Object> inputMap = new  Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        inputMap.put('ListAccDeactivate', listAccDeactivateMap);
        outputMap = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(IP_BILLING_ACCOUNT_DEACTIVATE, inputMap, options);
    }
    
    public void finish(Database.BatchableContext BC) {
        //finsish processing
    }
    
}