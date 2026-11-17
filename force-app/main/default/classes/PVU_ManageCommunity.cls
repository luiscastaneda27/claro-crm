/*******************************************************************************
* Autor: Daniel Alvarez
* Fecha: 2024-12-03
* Equipo: Posventas
* Descripcion: API que permite gestionar las comunidades.

<Date>            <Author>             <Description>                                      <Version>
2024-12-03         C.Daniel Alvarez       Creacion                                               01
***********************************************************************************/
@RestResource(urlMapping='/PVU_ManageCommunity/*')
global with sharing class PVU_ManageCommunity {
        // Clase de respuesta del servicio
            global class Response {
                public String status;
                public String message;
                public String statusCode;
        
                public Response(String status, String message,String statusCode) {
                    this.status = status;
                    this.message = message;
                    this.statusCode = statusCode;

                }

            }
    // Método principal para manejar el POST
    @HttpPost
    global static Response handlePost() {
        try {
            // Obtener la solicitud
            RestRequest req = RestContext.request;
            Map<String, Object> messageResponse;
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            // Validar parámetros requeridos
            String action = (String) input.get('action');
            if (String.isEmpty(action) || action == null) {
                //define error
                messageResponse = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_ACTION_REQUIRED');
                return new response('error',(String) messageResponse.get('message'), (String)messageResponse.get('code'));
            }
            
            // Determinar acción
            Map<String, Object> result = new Map<String, Object>();
            if (action.equalsIgnoreCase('activate')) {
                
                result  = PVU_CommunityUtilsService.activateCommunity(input);

            } else if (action.equalsIgnoreCase('deactivate')) {

                
                result = PVU_CommunityUtilsService.deactivateCommunity(input);

            } else if (action.equalsIgnoreCase('suspend')) {

                result = PVU_CommunityUtilsService.suspendCommunity(input);

            } else {


                //define error
                messageResponse = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_INVALID_ACTION');
                return new response('error',(String) messageResponse.get('message'), (String)messageResponse.get('code'));
                
            }

           //Response 
            if(result.get('parentLine') == null) {
                return new response('error',(String) result.get('message'), (String) result.get('code'));
            }else{
                return new response('success',(String)result.get('message'),(String) result.get('code'));

            }

        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            return new response('Error: ' + e.getMessage(),'error','500');
        }
    }
}