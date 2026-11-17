/*--------------------------------------------------------------------------
Author:         Juan Mojica - juan.mojica@salesforce.com
Company:        Salesforce.com
Description:    Llamado de IP CPQ_DeleteItemFromCart que permite borrar productos del carrito
Code Coverage:  96%
History
<Date>            <Author>             <Description>             <Version>
06-Abr-25         Juan Mojica                                    version inicial
----------------------------------------------------------------------------*/
public class CATBorrarProductosDelCarrito {
    @InvocableMethod
    public static List<String> borrarProductosDelCarrito(List<List<String>> infoProducto) {
        List<String> informacionProducto = infoProducto[0];
        System.debug('--- informacionProducto: ' + JSON.serialize(informacionProducto)); 
        String idOrden = informacionProducto[0];
        System.debug('--- idOrden: ' + idOrden);
        String idOrderItem = informacionProducto[1];
        System.debug('--- idOrderItem: ' + idOrderItem);

        String borrarIP = 'CPQ_DeleteItemFromCart';
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();

        ipInput.put('cartId', idOrden);
        ipInput.put('id', idOrderItem);
        ipInput.put('price', false);
        ipInput.put('validate', false);
        System.debug('--- ipInput: ' + JSON.serialize(ipInput));
        if(!Test.IsRunningTest()){
            ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(borrarIP, ipInput, ipOptions);
        }else {
            ipOutput = (Map<String, Object>) JSON.deserializeUntyped('{"actions": {"itempricesupdated": {"client": {"params": {}},"remote": {"params": {"methodName": "getCartLineItemPrices","cartId": "801dl00000JBd7xAAD","price": false}},"rest": {"link": "/services/apexrest/vlocity_cmt/v2/cpq/carts/801dl00000JBd7xAAD/price?price=false","method": "GET","params": {}}}},"messages": [{"message": "Successfully deleted.","severity": "INFO","code": "152"}],"totalSize": 0}');
        }
        System.debug('--- ipOutput: ' + ipOutput);

        List<Object> messages = (List<Object>) ipOutput.get('messages');
        System.debug('--- messages: ' + JSON.serialize(messages));
        List<String> messagesList = new List<String>();
        if(messages != null && messages.size() > 0){
            // Loop through the messages list and extract the `message` value from each message object
            for (Object messageObj : messages) {
                Map<String, Object> messageMap = (Map<String, Object>) messageObj;
                String message = (String) messageMap.get('message');
                messagesList.add(message);
            }
        }
        System.debug('messagesList: ' + messagesList);
        return messagesList;
    }
}