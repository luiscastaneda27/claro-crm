/**
 * @description       : Esta clase se encarga de obtener el mensaje de error de las posibles JSONs que el campo vlocity_cmt__Response__c de los OI (Orchestration Items) tienen.
 *                      Este mensaje es retornado al flow OM_Update_Order_Orchestration_Item_State que es el encargado de actualizar el campo "OM_OrchestrationItemState__c" en la orden
 * @author            : Karen Belem Sanchez Ruiz (karsanchez)
 * @group             : SFDC
 * @last modified on  : 08-05-2024
 * ------------------------------------------------------------------------------------------
 *                         Date           Author          Description         
 * -------------------------------------------------------------------------------------------
 * @version 1.0           09/07/2024     Karen Sanchez    HDU 335666 - Created
 * @version 1.1           26/07/2024     Karen Sanchez    HDU 335666 - Se agrega a la condicional "errorCode", ya que hubo cambios en la respuesta de la API.
 * @version 1.2           05/08/2024     Karen Sanchez    HDU 354355 - Se cambia logica en el metodo updateOrder para eliminar complejidad ciclomatica. Además,
 *                                                        se agrega la lógica para cuando dos ordenes tienen el mismo orchestrationplanId y se debe actualizar uno.
**/
public with sharing class OM_SplitStringFromFlow_cls {
    
    /**
    * @description: Recibe una lista de objetos vlocity_cmt__OrchestrationItem__c y procesa el campo vlocity_cmt__Response__c de cada objeto para extraer mensajes de error. 
    * @author karsanchez | 07-09-2024 
    * @param lstOrchItem 
    * @return List<String> 
    **/
    @InvocableMethod(label='Split String' description='Received a string from a flow and take the last error' category='OM')
    public static List<String> extractErrorMessage(List<vlocity_cmt__OrchestrationItem__c> lstOrchItem) {
        List<String> lstStateFinalString = new List<String>();
        
        for (vlocity_cmt__OrchestrationItem__c orchItem : lstOrchItem) {
            String strStateOrchItem = orchItem.vlocity_cmt__Response__c;
            try {
                if(orchItem.vlocity_cmt__State__c == 'completed') {
                    updateOrder(orchItem, null);
                } else {
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(strStateOrchItem);
                    if (jsonMap.containsKey('responseStatus')) {
                        handleResponseStatus((Map<String, Object>) jsonMap.get('responseStatus'), lstStateFinalString);
                    } else {
                        handleTopLevel(jsonMap, lstStateFinalString);
                    }
                    if(lstStateFinalString.size()>0) {
                        updateOrder(orchItem, lstStateFinalString);
                    }
                }
                
            } catch (JSONException e) {
                lstStateFinalString.add('Error parsing JSON: ' + e.getMessage());
            } catch (NullPointerException e) {
                lstStateFinalString.add('Null pointer exception: ' + e.getMessage());
            } catch (Exception e) {
                lstStateFinalString.add('Unexpected error: ' + e.getMessage());
            }
        }
        
        return lstStateFinalString;
    }

    /**
     * @description: Actualiza el estado de una orden basado en el ítem de orquestación y una lista de errores.
     *                Busca órdenes relacionadas con el ítem de orquestación y actualiza el estado de la primera
     *                orden válida encontrada.
     * @author karsanchez | 07-09-2024
     * @param orchItem El ítem de orquestación que contiene el ID del plan de orquestación.
     * @param lstStateFinalString Lista de mensajes de error que se deben agregar al estado de la orden.
     **/
    public static void updateOrder(vlocity_cmt__OrchestrationItem__c orchItem, List<String> lstStateFinalString) {
        try {
            List<Order> orders = fetchOrders(orchItem);
            Order orderToUpdate = getOrderToUpdate(orders);
            updateOrderState(orderToUpdate, orchItem, lstStateFinalString);
        } catch (Exception e) {
            System.debug('Error durante la actualización de la orden: ' + e.getMessage());
        }
    }

    /**
     * @description: Recupera una lista de órdenes asociadas con el ítem de orquestación.
     * @author karsanchez | 07-09-2024
     * @param orchItem El ítem de orquestación que contiene el ID del plan de orquestación.
     * @return Lista de órdenes que están asociadas con el ID del plan de orquestación proporcionado.
     **/
    private static List<Order> fetchOrders(vlocity_cmt__OrchestrationItem__c orchItem) {
        return [SELECT Id, OM_OrchestrationItemState__c, vlocity_cmt__SupersededOrderId__c 
                FROM Order 
                WHERE vlocity_cmt__OrchestrationPlanId__c = :orchItem.vlocity_cmt__OrchestrationPlanId__c 
                FOR UPDATE];
    }

    /**
     * @description: Determina cuál orden debe actualizarse entre una lista de órdenes.
     *                Selecciona la primera orden que tiene un campo vlocity_cmt__SupersededOrderId__c lleno.
     *                Si no se encuentra ninguna, devuelve la única orden disponible si solo hay una.
     * @author karsanchez | 07-09-2024
     * @param orders Lista de órdenes recuperadas para decidir cuál se debe actualizar.
     * @return La orden que debe actualizarse o null si no se encuentra ninguna válida.
     **/
    private static Order getOrderToUpdate(List<Order> orders) {
        for (Order ord : orders) {
            if (String.isNotBlank(ord.vlocity_cmt__SupersededOrderId__c)) {
                return ord;
            }
        }
        
        return orders.size() == 1 ? orders[0] : null;
    }

    /**
     * @description: Actualiza el estado de la orden con base en los mensajes de error proporcionados.
     *                Si la lista de errores no está vacía, establece el campo OM_OrchestrationItemState__c
     *                con los mensajes de error concatenados. Si está vacía, limpia el campo.
     * @author karsanchez | 07-09-2024
     * @param order La orden cuyo estado se debe actualizar.
     * @param orchItem 
     * @param lstStateFinalString Lista de mensajes de error que se deben concatenar en el estado de la orden.
     **/
    private static void updateOrderState(Order order, vlocity_cmt__OrchestrationItem__c orchItem, List<String> lstStateFinalString) {
        if (lstStateFinalString != null && !lstStateFinalString.isEmpty()) {
            order.OM_OrchestrationItemState__c = 'Ha fallado el Item: "' + orchItem.Name + '" con los siguientes errores: ' + String.join(lstStateFinalString, ', ');
        } else if (String.isNotBlank(order.OM_OrchestrationItemState__c)) {
            order.OM_OrchestrationItemState__c = '';
        }
        update order;
    }

    
    /**
    * @description: Manejar el objeto responseStatus dentro del JSON deserializado. 
                    Verifica si contiene un mensaje o un error y agrega el mensaje correspondiente a la lista lstStateFinalString. 
    * @author karsanchez | 07-09-2024 
    * @param responseStatus 
    * @param lstStateFinalString 
    **/
    private static void handleResponseStatus(Map<String, Object> responseStatus, List<String> lstStateFinalString) {
        if (responseStatus.containsKey('message')) {
            Object messageObj = responseStatus.get('message');
            
            if (messageObj instanceof String && ((String) messageObj).startsWith('<?xml')) {
                String xmlMessage = (String) messageObj;
                String extractedMessage = extractMessageFromXML(xmlMessage);
                lstStateFinalString.add(extractedMessage);
            } else {
                lstStateFinalString.add((String) messageObj);
            }
        } else if (responseStatus.containsKey('error')) {
            lstStateFinalString.add((String) responseStatus.get('error'));
        } else {
            lstStateFinalString.add('No message or error found in responseStatus');
        }
    }
    
    /**
    * @description: Método privado utilizado para manejar directamente el JSON deserializado si no contiene un objeto responseStatus. 
      Verifica si contiene un mensaje o un error y agrega el mensaje correspondiente a la lista lstStateFinalString. 
    * @author karsanchez | 07-09-2024 
    * @param jsonMap 
    * @param lstStateFinalString 
    **/
    private static void handleTopLevel(Map<String, Object> jsonMap, List<String> lstStateFinalString) {
        if (jsonMap.containsKey('message')) {
            lstStateFinalString.add((String) jsonMap.get('message'));
        } else if (jsonMap.containsKey('error')) {
            lstStateFinalString.add((String) jsonMap.get('error'));
        } else if (jsonMap.containsKey('errorCode')) {
            lstStateFinalString.add((String) jsonMap.get('errorCode'));
        } else {
            lstStateFinalString.add('No message or error found');
        }
    }
    
    /**
    * @description: Extrae el mensaje de error de un XML contenido dentro de un campo message en el JSON deserializado. 
    * @author karsanchez | 07-09-2024 
    * @param jsonResponse 
    * @return String 
    **/
    private static String extractMessageFromXML(String jsonResponse) {
        try {
            String startTag = '<message>';
            String endTag = '</message>';
            Integer startIndex = jsonResponse.indexOf(startTag);
            Integer endIndex = jsonResponse.indexOf(endTag);
            
            if (startIndex != -1 && endIndex != -1) {
                return jsonResponse.substring(startIndex + startTag.length(), endIndex);
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('Error extracting message from XML: ' + e.getMessage());
            return null;
        }
    }
}