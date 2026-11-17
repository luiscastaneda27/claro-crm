public class FVU_CallNotificationCusChannel {
    
    private final static String IP_NOTIFICATION_CUS_CHANNEL = 'FVU_SendPinLinkNotification';
    private final static String MESSAGE_OK = 'Sending notification successful';
    private final static String MESSAGE_FAIL = 'Sending notification failed';

    @InvocableMethod(label='sendNotificationCusChannel' description='Send request an Integration Procedure.' category='General')
    public static List<String> sendNotificationCusChannel( List<InputNotificationCusChannel> variableNodes ){

        String messageType = variableNodes.get(0).messageType;
        String phone = variableNodes.get(0).phone; 
        String email = variableNodes.get(0).email; 
        String codigoPago = variableNodes.get(0).codigoPago;
        String totalPayment = variableNodes.get(0).totalPayment;
        String fechaVigencia = variableNodes.get(0).fechaVigencia;
        String accountId = variableNodes.get(0).accountId; 
        String orderId = variableNodes.get(0).orderId;
        String resend = variableNodes.get(0).resend;

        Map<String, Object> options =  new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> inputMap =  new Map<String, Object>(); 
        Map<String, Object> receiverMap =  new Map<String, Object>(); 
        List<Map<String, Object>> listObject = new List<Map<String, Object>>();

        inputMap.put('MessageType', messageType);
        inputMap.put('Phone', phone);
        inputMap.put('Email',  email);
        inputMap.put('CodigoPago', codigoPago);
        inputMap.put('TotalPayment', totalPayment);
        inputMap.put('FechaVigencia', fechaVigencia);
        inputMap.put('AccountId', AccountId);
        inputMap.put('OrderId', orderId); 
        inputMap.put('Resend', resend); 

        outputMap = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(IP_NOTIFICATION_CUS_CHANNEL, inputMap, options);

        if(outputMap.containsKey('SendLink')) {

            Map<String, Object> sendLink = (Map<String, Object>) outputMap.get('SendLink');
            Map<String, Object> notification = (Map<String, Object>) SendLink.get('Notification');
            Boolean sendSMS = (Boolean) Notification.get('SendSMS');
            Boolean sendSMTP = (Boolean) Notification.get('SendSMTP');

            if( sendSMS || sendSMTP ) {
                return new List<String>{MESSAGE_OK};
            }
        }

        return new List<String>{MESSAGE_FAIL};

    }

    @TestVisible
    public class InputNotificationCusChannel {
        
        @InvocableVariable
        public String messageType;
    
        @InvocableVariable
        public String phone;

        @InvocableVariable
        public String email;

        @InvocableVariable
        public String codigoPago;
    
        @InvocableVariable
        public String totalPayment;

        @InvocableVariable
        public String fechaVigencia;

        @InvocableVariable
        public String accountId;
    
        @InvocableVariable
        public String orderId;

        @InvocableVariable
        public String resend;

    }

}