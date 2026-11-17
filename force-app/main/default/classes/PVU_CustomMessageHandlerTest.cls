@isTest
public with sharing class PVU_CustomMessageHandlerTest {
    
    @isTest
    static void getConfirmationMsgTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        PVU_CustomMessageHandler testMsg = new PVU_CustomMessageHandler();
        
        MensajesPersonalizados__mdt prueba = MensajesPersonalizados__mdt.getInstance('MSG001');

        Map<String, Object> datos = new Map<String, Object>();
        datos.put('Titulo', prueba.Titulo__c);
        datos.put('Mensaje', prueba.Mensaje__c);
        datos.put('Codigo', prueba.Codigo__c);
        datos.put('Accion', prueba.Accion__c);
        
        List<Object> paramstest = new List<Object> {'343432423432'};
        options.put('confirmationParams', paramstest);
        options.put('Message', datos);
        options.put('codeMSG', prueba.Codigo__c);
        Test.startTest();
        testMsg.invokeMethod('getConfirmationMsg',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Get Message');
    }
    
    @isTest
    static void getConfirmationMsgFailTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        PVU_CustomMessageHandler testMsg = new PVU_CustomMessageHandler();
        Test.startTest();
        testMsg.invokeMethod('',input,output,options);
        Test.stopTest();
        System.assert(output.get('Message') == null,'Get Message');
    }
    
    /*
	* Created Date: 20240216
	* Created By: Federico Mandri
	*/
    @isTest
    static void getMensajesPorVozDeClienteTest(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
        String vozCliente = 'Suspensión Temporal Voluntaria';
        String methodName = 'getMensajesPorVozDeCliente';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        input.put('VozCliente',vozCliente);
        
        Test.startTest();
        	messageHandler.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Map<String, String> mensajes = (Map<String, String>)output.get('mensajes');
        System.Assert(mensajes.size() > 0, 'No Hay mensajes para voz de cliente ' + vozCliente);
    }
    
    /*
	* Created Date: 20240216
	* Created By: Federico Mandri
	*/
    @isTest static void setParametrosEnMensajeTest(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
                
        String methodName = 'setParametrosEnMensaje';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String mensaje = 'Sr.(a) {2}, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día {0} hasta el {1}';
        List<String> parametros = new List<String>();
        parametros.add('01/02/2024');
        parametros.add('29/02/2024');
        parametros.add('Jhon Doe');
        input.put('mensaje', mensaje);
        input.put('parametros', parametros);
        
        Test.startTest();
        	messageHandler.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        String mensajeFinal = (String)output.get('mensajeParametrizado');
        String mensajeEsperado = 'Sr.(a) Jhon Doe, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día 01/02/2024 hasta el 29/02/2024';
        
        System.AssertEquals(mensajeFinal, mensajeEsperado, 'Los mensajes no coinciden');
    }
    
    /*
	* Created Date: 20240216
	* Created By: Federico Mandri
	*/
    @isTest static void setParametrosEnMensajeTestNoOk(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
                
        String methodName = 'setParametrosEnMensaje';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String mensaje = 'Sr.(a) {2}, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día {0} hasta el {1}';
        List<String> parametros = new List<String>();
        //parametros.add('01/02/2024');
        //parametros.add('29/02/2024');
        //parametros.add('Jhon Doe');
        input.put('mensaje', mensaje);
        input.put('parametros', parametros);
        
        Test.startTest();
        	messageHandler.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        String errorCode = (String)output.get('errorCode');
        String errorMessage = (String)output.get('errorMessage');
        
        System.AssertEquals(errorCode, '400', 'Todos los argumentos tienen valores validos');
        System.AssertEquals(errorMessage, 'No hay parametros para reemplazar en el mensaje o el mensaje está vacío', 'Todos los argumentos tienen valores validos');
    }
    
    /*
	* Created Date: 20240408
	* Created By: Hever Salas
	*/
    @isTest static void setParametrosEnMensajeIndexTest(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
                
        String methodName = 'setParametrosEnMensajeIndex';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String mensaje = 'Sr.(a) {2}, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día {0} hasta el {1}';
        List<String> parametros = new List<String>();
        parametros.add('01/02/2024');
        parametros.add('29/02/2024');
        parametros.add('Jhon Doe');
        input.put('mensaje', mensaje);
        input.put('parametros', parametros);
        input.put('index', 0);
        
        Test.startTest();
        	messageHandler.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        String mensajeFinal = (String)output.get('mensajeParametrizado');
        String mensajeEsperado = 'Sr.(a) Jhon Doe, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día 01/02/2024 hasta el 29/02/2024';
        
        System.AssertEquals(mensajeFinal, mensajeEsperado, 'Los mensajes no coinciden');
    }
    
    /*
	* Created Date: 20240408
	* Created By: Hever Salas
	*/
    @isTest static void setParametrosEnMensajeIndexTestNoOk(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
                
        String methodName = 'setParametrosEnMensajeIndex';
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String mensaje = 'Sr.(a) {2}, se ha recibido la solicitud de suspensión temporal del servicio la cuál quedará activa desde el día {0} hasta el {1}';
        List<String> parametros = new List<String>();
        //parametros.add('01/02/2024');
        //parametros.add('29/02/2024');
        //parametros.add('Jhon Doe');
        input.put('mensaje', mensaje);
        input.put('parametros', parametros);
        input.put('index', 0);
        
        Test.startTest();
        	messageHandler.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        
        String errorCode = (String)output.get('errorCode');
        String errorMessage = (String)output.get('errorMessage');
        
        System.AssertEquals(errorCode, '400', 'Todos los argumentos tienen valores validos');
        System.AssertEquals(errorMessage, 'No hay parametros para reemplazar en el mensaje o el mensaje está vacío', 'Todos los argumentos tienen valores validos');
    }
    
    /*
	* Created Date: 20240227
	* Created By: hllanos
	*/
    @isTest static void getNotificationMessageTest(){
        PVU_CustomMessageHandler messageHandler = new PVU_CustomMessageHandler();
        PVU_CustomMessageHandler.getNotificationMessageInput input = new PVU_CustomMessageHandler.getNotificationMessageInput();
        List<PVU_CustomMessageHandler.getNotificationMessageInput> listInput = new List<PVU_CustomMessageHandler.getNotificationMessageInput>();
        List<PVU_CustomMessageHandler.getNotificationMessageOutput> output = new List<PVU_CustomMessageHandler.getNotificationMessageOutput>();
        
        input.msgId = 'MSG003';
        List<String> listFieldValues = new List<String>();
        listFieldValues.add('666');
        input.fieldValuesToReplace = listFieldValues;
        listInput.add(input);
        
        Test.startTest();
        	output = PVU_CustomMessageHandler.getNotificationMessage(listInput);
        	system.debug('output:' + output);
        Test.stopTest();
        
        System.Assert(output.size() >0);
    }
    
}