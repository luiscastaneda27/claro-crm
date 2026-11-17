@isTest(seeAllData=true)
public class FVU_CallNotificationCusChannelTest {
    
    @IsTest
    static void sendNotificationCusChannelSMSTest() {

        Account acc = new Account();
        acc.Name = 'Account CusChannel Test';
        acc.FVU_Email__c = 'test010201@test.com';
        acc.Phone = '01';
        insert acc;

        Order ord = new Order();
        ord.AccountId = acc.Id;
   		ord.Status = 'Draft';
        ord.EffectiveDate = System.today();
        insert ord;

        FVU_CallNotificationCusChannel.InputNotificationCusChannel inputNotification = new FVU_CallNotificationCusChannel.InputNotificationCusChannel();
        inputNotification.messageType = 'SMS'; 
        inputNotification.phone = ord.Account.Phone;
        inputNotification.email = ord.Account.FVU_Email__c;
        inputNotification.codigoPago = '003';
        inputNotification.totalPayment = '123456978';
        inputNotification.fechaVigencia = '';
        inputNotification.accountId = ord.Id;
        inputNotification.orderId = ord.AccountId;
        inputNotification.resend = 'false';

        List<FVU_CallNotificationCusChannel.InputNotificationCusChannel> notificationsList = new List<FVU_CallNotificationCusChannel.InputNotificationCusChannel>();
        notificationsList.add(inputNotification);

        Test.startTest();

            String url = 'http://example.com/example';
            String path = 'PVU_IPNotificationCusChannel';
            String mockResponse = '{"SendLink":{"Notification":{"SendSMS":false,"SendSMTP":true,"Type":"SMTP","NotificationCount":null},"UpdateAccount":true,"ValidationEmail":true}}';

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(mockResponse);
            response.setStatusCode(200);
            vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponseByUrlOrActionName('FVU_CallNotificationCusChannel', response);
            
            List<String> result = FVU_CallNotificationCusChannel.sendNotificationCusChannel(notificationsList);

            Assert.areEqual('Sending notification failed', result.get(0), 'Success message failed'); 
        Test.stopTest();
    }

    @IsTest
    static void sendNotificationCusChannelEMAILTest() {

        Account acc = new Account();
        acc.Name = 'Account CusChannel Test';
        acc.FVU_Email__c = 'test010201@test.com';
        acc.Phone = '01';
        insert acc;

        Order ord = new Order();
        ord.AccountId = acc.Id;
   		ord.Status = 'Draft';
        ord.EffectiveDate = System.today();
        insert ord;

        FVU_CallNotificationCusChannel.InputNotificationCusChannel inputNotification = new FVU_CallNotificationCusChannel.InputNotificationCusChannel();
        inputNotification.messageType = 'Correo Electrónico'; 
        inputNotification.phone = ord.Account.Phone;
        inputNotification.email = ord.Account.FVU_Email__c;
        inputNotification.codigoPago = '003';
        inputNotification.totalPayment = '123456978';
        inputNotification.fechaVigencia = '';
        inputNotification.accountId = ord.Id;
        inputNotification.orderId = ord.AccountId;
        inputNotification.resend = 'false';

        List<FVU_CallNotificationCusChannel.InputNotificationCusChannel> notificationsList = new List<FVU_CallNotificationCusChannel.InputNotificationCusChannel>();
        notificationsList.add(inputNotification);

        Test.startTest();

            String url = 'http://example.com/example';
            String path = 'PVU_IPNotificationCusChannel';
            String mockResponse = '{"SendLink":{"Notification":{"SendSMS":false,"SendSMTP":false,"Type":"SMTP","NotificationCount":null},"UpdateAccount":true,"ValidationEmail":true}}';

            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(mockResponse);
            response.setStatusCode(200);
            vlocity_cmt.IntegrationProcedureServiceTest.setMockHttpResponseByUrlOrActionName('FVU_CallNotificationCusChannel', response);

            List<String> result = FVU_CallNotificationCusChannel.sendNotificationCusChannel(notificationsList);

            Assert.areEqual('Sending notification failed', result.get(0), 'Success message failed'); 
        Test.stopTest();
    }
}