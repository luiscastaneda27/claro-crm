/*******************************************************************************
* Autor: Daniel Alvarez
* Fecha: 2024-12-03
* Equipo: Posventas
* Descripcion: API que permite gestionar las comunidades.

<Date>            <Author>             <Description>                                      <Version>
2025-15-01         C.Daniel Alvarez       Creacion                                               01
2025-23-01         Luis Mendoza           Change to get parameter                                01
***********************************************************************************/
@RestResource(urlMapping='/PVU_GetCommunityInfo/*')
global with sharing class PVU_GestorComunidades{


     @HttpGet
     global static void getResquestCommunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        //   Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String line = req.params.get('line');

        if(String.isEmpty(line)){
           Map<String,Object> error = new Map<String,Object>();
           res.statusCode = 400;
           error.put('error', 'error required line');
           res.responseBody = Blob.valueOf(JSON.serialize(error));  
           return;
        }

        Map<String,Object> input = new Map<String,Object>();
        input.put('line', line);

        Map<String,Object> respuestaInfo  = PVU_CommunityUtilsService.manageCommunity(input) ;
         
        res.statusCode = (Integer) respuestaInfo.get('statusCode');
        respuestaInfo.remove('statusCode');
        res.responseBody = Blob.valueOf(JSON.serialize(respuestaInfo));  
         
     }
    
    


   
}