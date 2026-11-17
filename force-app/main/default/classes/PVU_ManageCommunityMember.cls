/*******************************************************************************
* Autor: Gabriel Oros
* Fecha: 2024-12-03
* Equipo: Pos-Ventas
* Descripcion: API que permite gestionar los miembros de una comunidad.
* History
<Date>            <Author>             <Description>                                      <Version>
2024-12-03         Gabriel Oros        Creacion                                               01
2024-12-26         Gabriel Oros        Update Endpoint                                        02
***********************************************************************************/
@RestResource(urlMapping='/PVU_ManageCommunityMember/*')
global with sharing class PVU_ManageCommunityMember {
        // Clase de respuesta del servicio
            global class Response {
                public String status;
                public String memberId;
                public String parentLine;
                public String childLine;
                public String message;
                public String statusCode;
        
                public Response(String status, String message, String memberId, String parentLine, String childLine, String statusCode) {
                    this.status = status;
                    this.message = message;
                    this.memberId = memberId;
                    this.parentLine = parentLine;
                    this.childLine = childLine;
                    this.statusCode = statusCode;
                }
                public Response(String message, String status,String statusCode){
                    this.message = message;
                    this.status = status;
                    this.statusCode = statusCode;
                }

            }
    // Método principal para manejar el POST
    @HttpPost
    global static Response handlePost() {
        try {
            // Obtener la solicitud
            RestRequest req = RestContext.request;
            Map<String, Object> messageResponse = new Map<String, Object>();
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            // Validar parámetros requeridos
            String action = (String) input.get('action');
            if (String.isEmpty(action) || action == null) {
                messageResponse = PVU_CommunityUtilsService.getMessageFormCode('ERROR_ACTION_REQUIRED');
                return new response( (String) messageResponse.get('message'),'error',(String) messageResponse.get('code'));
            }
            
            // Determinar acción
            Map<String, Object> result = new Map<String, Object>();
            if (action.equalsIgnoreCase('add')) {
                
                result  = PVU_CommunityUtilsService.addRecord(input);

            } else if (action.equalsIgnoreCase('edit')) {

                
                result = PVU_CommunityUtilsService.editRecord(input);

            } else if (action.equalsIgnoreCase('remove') || action.equalsIgnoreCase('removeByProcess') ){

                result = PVU_CommunityUtilsService.deleteRecord(input);

            } else {
              
                messageResponse = PVU_CommunityUtilsService.getMessageFormCode('ERROR_INVALID_ACTION');
                return new response( (String) messageResponse.get('message'),'error',(String) messageResponse.get('code'));
                
            }

            
           //Response 
            if(result.get('memberId') == null) {
                return new response( (String) result.get('message'),'error',(String) result.get('code'));
            }else{
                System.debug('result cuando se crea'+ result);
                return new response('success',(String)result.get('message'),(String)result.get('memberId'),(String) result.get('parentLine'),(String) result.get('childLine'),(String) result.get('statusCode'));

            }

        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            return new response('Error: ' + e.getMessage(),'error','500');
        }
    }
}