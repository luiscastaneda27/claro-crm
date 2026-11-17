/*******************************************************************************
* Autor: Gabriel Oros
* Fecha: 2024-12-03
* Equipo: Pos-Ventas
* Descripcion: Clase Util para APIs
* History
<Date>            <Author>             <Description>                                      <Version>
2024-12-03         Gabriel Oros        Creacion                                               01
***********************************************************************************/
public with sharing class PVU_CommunityUtilsService {

    //Clase para variables globales
    public class Input {
        public String parentLine;
        public String childLine;
        public String origin;
        public Boolean hasCost;
        public String lineType;
        public String lineSegment;
        public String newChildLine;
        public String action;
        public String line;


        // Constructor para validar y mapear inputs
        public
         Input(Map<String, Object> input) {
            this.parentLine = (String) input.get('parentLine');
            this.childLine = (String) input.get('childLine');
            this.origin = (String) input.get('origin');
            this.hasCost = (Boolean) input.get('hasCost');
            this.lineType = (String) input.get('lineType');
            this.lineSegment = (String) input.get('lineSegment');
            this.newChildLine = (String) input.get('newChildLine');
            this.action = (String) input.get('action');
            this.line = (String) input.get('line');

        }
    }

    // Agregar registro Community Member
    public static Map<String, Object> addRecord(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();
  

        if (String.isEmpty(data.parentLine) || String.isEmpty(data.childLine) || String.isEmpty(data.lineType) || String.isEmpty(data.lineSegment) || String.isEmpty(data.origin)) {
            messageResponse = getMessageFormCode('ERROR_PARAMS_ADD');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }
        try {
        PVU_Community__c  idCommunity = [SELECT Id FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1 ];
        
        if (checkIfIsExistCommunityMember(data.parentLine,data.childLine) == true) {
            messageResponse = getMessageFormCode('ERROR_MEMBER_EXIST');
            response.put('message',(String) messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }
        //Armado del insert
         PVU_Community_Member__c newMember = new PVU_Community_Member__c();
         newMember.PVU_Comunidad__c = idCommunity.id;
         newMember.PVU_Linea_Hija__c = data.childLine;
         newMember.PVU_Segmento_Linea__c = data.lineSegment;
         newMember.PVU_Tipo_Linea__c = data.lineType;
         insert as system newMember;

         if (data.origin == 'SuperApp' && data.hasCost != null) {
           Map<String, Object> result = createCaseCommunity(input,false); 
         } else {
            messageResponse = getMessageFormCode('ERROR_FIELD_HASCOST');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
         }
        //Armado de respuesta
         Id memberId = newMember.Id;
         messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_ADD');
         response.put('message',messageResponse.get('message'));
         response.put('statusCode',messageResponse.get('code'));
         response.put('parentLine',data.parentLine);
         response.put('childLine',data.childLine);
         response.put('memberId',memberId);
                 
         return response;

        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }
    }

    // Editar registro Community member
    public static  Map<String, Object>  editRecord(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();
        

        if (String.isEmpty(data.parentLine) || String.isEmpty(data.childLine)|| String.isEmpty(data.lineSegment)  || String.isEmpty(data.lineType)  || String.isEmpty(data.origin) || String.isEmpty(data.newChildLine)) {
            messageResponse = getMessageFormCode('ERROR_PARAMS_EDIT');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }

        try {
            PVU_Community_Member__c  registerCommunityMember = [SELECT Id FROM PVU_Community_Member__c WHERE PVU_Linea_Hija__c =:data.childLine  AND PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c =: data.parentLine WITH SYSTEM_MODE LIMIT 1];

            registerCommunityMember.PVU_Linea_Hija__c = data.newChildLine;
            registerCommunityMember.PVU_Tipo_Linea__c = data.lineType;
            registerCommunityMember.PVU_Segmento_Linea__c = data.lineSegment;
            update as system registerCommunityMember;

            if (data.origin == 'SuperApp' && data.hasCost != null) {
                Map<String, Object> result = createCaseCommunity(input,false); 
             } else {
                messageResponse = getMessageFormCode('ERROR_FIELD_HASCOST');
                response.put('message',messageResponse.get('message'));
                response.put('code',messageResponse.get('code'));
                return response;
             }

            Id memberId = registerCommunityMember.Id;
            //armado de respuesta
            messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_EDIT');
            response.put('message',messageResponse.get('message'));
            response.put('statusCode',messageResponse.get('code'));
            response.put('parentLine',data.parentLine);
            response.put('childLine',data.newChildLine);
            response.put('memberId',memberId);
            return response;
  
        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY_MEMBER');
            response.put('message',messageResponse.get('message')+data.childLine);
            response.put('code',messageResponse.get('code'));
            return response;
            
        }

    }

    // Eliminar registro Community member
    public static  Map<String, Object>  deleteRecord(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();


        if (String.isEmpty(data.parentLine) || String.isEmpty(data.childLine)  || String.isEmpty(data.origin)) {
            messageResponse = getMessageFormCode('ERROR_PARAMS_REMOVE');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }

        try {
            PVU_Community_Member__c  registerCommunityMemberToDelete = [SELECT Id FROM PVU_Community_Member__c WHERE PVU_Linea_Hija__c =:data.childLine  AND PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c =: data.parentLine WITH SYSTEM_MODE LIMIT 1];
            
            if (data.origin == 'SuperApp' && data.hasCost != null) {
                Map<String, Object> result = createCaseCommunity(input,false); 
             } else {
                messageResponse = getMessageFormCode('ERROR_FIELD_HASCOST');
                response.put('message',messageResponse.get('message'));
                response.put('code',messageResponse.get('code'));
                return response;
             }

            delete as system registerCommunityMemberToDelete;

            Id memberId = registerCommunityMemberToDelete.Id;
             //Armado de respuesta
            messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_REMOVE');
            response.put('message',messageResponse.get('message'));
            response.put('statusCode',messageResponse.get('code'));
            response.put('parentLine',data.parentLine);
            response.put('childLine',data.childLine);
            response.put('memberId',memberId);
            return response;
  
        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY_MEMBER');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
            
        }
    }
    //Metodos para comunidad y su manejamiento

    public static  Map<String, Object>  activateCommunity(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();
        PVU_Community__c  activatedCommunity = new PVU_Community__c();

        System.debug('::activateCommunity ');

        if (String.isEmpty(data.parentLine)  || String.isEmpty(data.origin)|| String.isEmpty(data.lineSegment)) {
            //agregar tipo de error para comunidad
            messageResponse = getMessageFormCode('ERROR_COMMUNITY_PARAMS');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }
    
    try {
        vlocity_cmt__Subscription__c  registerSucription = [SELECT Id FROM vlocity_cmt__Subscription__c WHERE OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1];
    
        if (checkIfIsExistCommunity(data.parentLine) == true) {

            activatedCommunity = [SELECT Id FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1];
            activatedCommunity.PVU_Estatus__c = 'Activa';
            activatedCommunity.PVU_Fecha_de_activacion__c = DateTime.now();
           activatedCommunity.PVU_wasSuspended__c = true;
            input.put('wasSuspended',true);

            
            update as system activatedCommunity;
            


 
        }else{
         //Armado del insert
         //PVU_Community__c newCommunity = new PVU_Community__c();
         activatedCommunity.PVU_Linea_Padre__c = registerSucription.Id;
         activatedCommunity.PVU_Estatus__c = 'Activa';
         activatedCommunity.PVU_Segmento_linea__c = data.lineSegment;
         activatedCommunity.PVU_Fecha_de_activacion__c = DateTime.now();
         insert as system activatedCommunity;
            

            
        }
        
         Map<String, Object> result = createCaseCommunity(input,true); 
        //Armado de respuesta
        Id  communityId = activatedCommunity.Id;
        //marcar error de respues
        messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_ACTIVATED');
        response.put('message',messageResponse.get('message'));
        response.put('code',messageResponse.get('code'));
        response.put('parentLine',data.parentLine);
         response.put('communityId',communityId);
             
       return response;

       } catch (QueryException e) {

        messageResponse = getMessageFormCode('ERROR_COMMUNITY_LINEPARTNER_NOT_FOUND');
        response.put('message',messageResponse.get('message'));
        response.put('code',messageResponse.get('code'));
        return response;
      }
        

        
    }
    public static  Map<String, Object>  deactivateCommunity(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();

        System.debug('::deactivateCommunity ');

        if (String.isEmpty(data.parentLine)  || String.isEmpty(data.origin)|| String.isEmpty(data.lineSegment)) {
            //agregar tipo de error para comunidad
            messageResponse = getMessageFormCode('ERROR_COMMUNITY_PARAMS');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }

        try {
            PVU_Community__c  registeredCommunity = [SELECT Id, PVU_MSISDN__c FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1];
            registeredCommunity.PVU_Estatus__c = 'Inactiva';
            registeredCommunity.PVU_wasSuspended__c = false;
            input.put('communityId',registeredCommunity.Id);
            update as system registeredCommunity;

            Map<String, Object> result = createCaseCommunity(input,true); 

            Id communityId = registeredCommunity.Id;
            //armado de respuesta
            messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_DEACTIVATED');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            response.put('parentLine',data.parentLine);
            response.put('communityId',communityId);
            return response;
  
        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_NO_COMMUNITY_AVAILABLE');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
            
        }
 
        
    }
    public static  Map<String, Object>  suspendCommunity(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();

        if (String.isEmpty(data.parentLine)  || String.isEmpty(data.origin)|| String.isEmpty(data.lineSegment)) {
            
            messageResponse = getMessageFormCode('ERROR_COMMUNITY_PARAMS');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }

        try {
            PVU_Community__c  registeredCommunity = [SELECT Id FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1];
            registeredCommunity.PVU_Estatus__c = 'Suspendida';
            registeredCommunity.PVU_wasSuspended__c = false;
            update as system registeredCommunity;

            Map<String, Object> result = createCaseCommunity(input,true); 

            Id communityId = registeredCommunity.Id;
            
            messageResponse = getMessageFormCode('SUCCESS_COMMUNITY_SUSPENDED');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            response.put('parentLine',data.parentLine);
            response.put('communityId',communityId);
            return response;
  
        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_NO_COMMUNITY_AVAILABLE');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
            
        }
        
    }


  //Metodo para checkear que si esta creado o no el Community member
    public static Boolean checkIfIsExistCommunityMember (String parentLine,String childLine){

        try {
            PVU_Community_Member__c  registerCommunityMemberToDelete = [SELECT Id FROM PVU_Community_Member__c WHERE PVU_Linea_Hija__c =:childLine  AND PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c =: parentLine WITH SYSTEM_MODE LIMIT 1];

        }
        catch(QueryException e){
            return false;
        }
        return true;

    }


  //Metodo para checkear que si esta creado o no el Community 
  public static Boolean checkIfIsExistCommunity (String parentLine){

    try {
        PVU_Community__c  registerCommunity = [SELECT Id FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :parentLine WITH SYSTEM_MODE LIMIT 1];

    }
    catch(QueryException e){
        return false;
    }
    return true;



  }

    // Metodo para crear un Caso para Comunidades y Miembros de Comunidades
    public static  Map<String, Object>  createCaseCommunity(Map<String, Object> input, Boolean isCallForCommunity) {
        
        System.debug('createCaseCommunity:: ');
        Map<String, Object> response = new Map<String, Object>();
        Input data = new Input(input);
        String childLineValue = data.childLine;
        Map<String, Object> messageResponse = new Map<String, Object>();
       Boolean wasSuspended = (Boolean) input.get('wasSuspended') ;

        if (String.isEmpty(data.parentLine) ||( isCallForCommunity==false && String.isEmpty(data.childLine) ) || String.isEmpty(data.origin) || String.isEmpty(data.action)){
            messageResponse = getMessageFormCode('ERROR_CASE_PARAMS');
            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            return response;
        }

        try {
            PVU_Community__c  idCommunity = [SELECT Id FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.parentLine WITH SYSTEM_MODE LIMIT 1];
            Id recordTypeId  = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('GestionCasosPosventa').getRecordTypeId();

            //checkear si tiene un community con if
            Case newCase = new Case();
            // obtener tipo de accion dependiento si es sobre la linea hija o community
            
            if (isCallForCommunity == false ) {
              newCase.PVU_Tiene_Costo__c = data.hasCost;
              newCase.PVU_Accion_sobre_Linea_Hija__c = data.action;  
              newCase.PVU_Accion_del_Servicio_Comunidad__c = 'No Aplica';
            }else{
                newCase.PVU_Accion_del_Servicio_Comunidad__c = data.action;
                newCase.PVU_Accion_sobre_Linea_Hija__c = 'No Aplica';    
            }

            if (data.newChildLine != null) {
                childLineValue = data.newChildLine;
            }
            if( wasSuspended == true){
                newCase.Descripcion__c = 'Reactivado';
            }

             
            
            
            newCase.PVU_Numero_de_linea_hija__c = childLineValue;
            newCase.PVU_Comunidad__c = idCommunity.Id;
            newCase.PVU_Origen_Comunidad__c =  data.origin;
            newCase.RecordTypeId = recordTypeId;
            newCase.Status = 'Cerrado';
            newCase.PVU_Codigo_de_Cierre__c = 'Gestión realizada';
            newCase.PVU_Level1__c = 'Solicitud de información y modificaciones';
            newCase.PVU_Level2__c  ='Comunidades';
            newCase.PVU_Level3__c = 'Familia y Amigos';
            
                        
            insert as system newCase;
            
            Id caseId = newCase.Id;
            System.debug('el nuevo caso '+newCase.Id );


            messageResponse = getMessageFormCode('SUCCESS_CASE_CREATION');            

            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
            response.put('parentLine',data.parentLine);
            response.put('childLine',data.childLine);
            response.put('caseId',caseId);

          //  System.enqueueJob(new PVU_GestionComunidades_Queueable(newCase.Id));

            return response;
  
        } catch (QueryException e) {
            messageResponse = getMessageFormCode('ERROR_NO_SUCCESS_CREATION_CASE');
            response.put('message',messageResponse.get('message') + data.parentLine);
            response.put('code',messageResponse.get('code'));
             
            return response;
            
        }

    }


    // Method to manage communities
        
    public static  Map<String, Object> manageCommunity(Map<String, Object> input) {
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> responseMain= new Map<String, Object>();
        List<Map<String,Object>> relatedCommunities = new List<Map<String, Object>>();

       
        Input data = new Input(input);
        Map<String, Object> messageResponse = new Map<String, Object>();
        PVU_Community__c  registeredCommunity = new PVU_Community__c();


        String line = (String) input.get('line');
        if (String.isEmpty(line) || line == null) {
            messageResponse = getMessageFormCode('ERROR_NO_LINE_GIVEN');

            response.put('message',messageResponse.get('message'));
            response.put('code',messageResponse.get('code'));
    
            response.put('status','error');

            return response;
            
        }

        try {
            // Get Data for main Community when the line is community
              registeredCommunity = [SELECT Id,	PVU_Estatus__c,PVU_Segmento_linea__c,	PVU_MSISDN__c, PVU_Fecha_de_activacion__c,PVU_Total_de_lineas_hijas__c,PVU_Linea_Padre__r.vlocity_cmt__Status__c FROM PVU_Community__c WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = :data.line WITH SYSTEM_MODE LIMIT 1];
         }catch (QueryException e) {
             registeredCommunity = null;       
        }
        if( registeredCommunity != null ){

            if (registeredCommunity.PVU_Estatus__c == 'Inactiva') {
                messageResponse = getMessageFormCode('ERROR_COMM_INACTIVE');
            
                response.put('message',messageResponse.get('message'));
                response.put('code',messageResponse.get('code'));
                response.put('status','error');

                return response;
            }

            List<PVU_Community_Member__c>  registeredCommunityMembers = [SELECT Id,	PVU_Linea_Hija__c,PVU_Tipo_Linea__c,PVU_Segmento_Linea__c FROM PVU_Community_Member__c  WHERE PVU_Comunidad__c =: registeredCommunity.Id WITH SYSTEM_MODE ];

            responseMain = getCommunityResponse(registeredCommunity,registeredCommunityMembers);

        }

            List<PVU_Community_Member__c>   registeredInMembers = [SELECT Id,	PVU_Comunidad__c FROM PVU_Community_Member__c  WHERE PVU_Linea_Hija__c  = :data.line WITH SYSTEM_MODE];

            if(registeredInMembers.size() > 0){
                for(PVU_Community_Member__c member : registeredInMembers) {

                    PVU_Community__c  registeredCommunityinMember = [SELECT Id,	PVU_Estatus__c,PVU_Segmento_linea__c, PVU_Fecha_de_activacion__c,PVU_Total_de_lineas_hijas__c,	PVU_MSISDN__c,PVU_Linea_Padre__r.vlocity_cmt__Status__c FROM PVU_Community__c WHERE Id= : member.PVU_Comunidad__c WITH SYSTEM_MODE LIMIT 1];
                    List<PVU_Community_Member__c>  registeredMembers = [SELECT Id,	PVU_Linea_Hija__c,PVU_Tipo_Linea__c,PVU_Segmento_Linea__c FROM PVU_Community_Member__c  WHERE PVU_Comunidad__c =: registeredCommunityinMember.Id WITH SYSTEM_MODE ];
                    relatedCommunities.add(getCommunityResponse(registeredCommunityinMember,registeredMembers));
                }

            }else if(registeredCommunity == null){
                messageResponse = getMessageFormCode('ERROR_NO_COMMUNITY_ASSOCIATE');
            
                response.put('message',messageResponse.get('message'));
                response.put('code',messageResponse.get('code'));
                response.put('status','error');
                
                return response;

            }



            response.put('mainCommunity',responseMain);
            response.put('relatedCommunities',relatedCommunities);
            response.put('status','success');
 
            
            
            


            System.debug('response '+response);
            return response;
  
        } 
        
    


    public static  Map<String, Object>  getCommunityResponse(PVU_Community__c  registeredCommunity, List<PVU_Community_Member__c>  registeredCommunityMembers) {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, Object>> responseMembers = new List<Map<String, Object>>();

        Datetime dt = Datetime.valueOf(registeredCommunity.PVU_Fecha_de_activacion__c); // Convert string to Datetime
        Date datePart = dt.date();


        for(PVU_Community_Member__c member : registeredCommunityMembers) {

            Map<String, Object> memberData = new Map<String, Object>();
            memberData.put('memberId', member.Id);
            memberData.put('childLine', member.PVU_Linea_Hija__c);
            memberData.put('lineType', member.PVU_Tipo_Linea__c); 
            memberData.put('lineSegment', member.PVU_Segmento_Linea__c );// Add other fields as needed

            responseMembers.add(memberData);
        }

           response.put('Id',registeredCommunity.Id);
           response.put('parentLine',registeredCommunity.PVU_MSISDN__c);
           response.put('communityStatus',registeredCommunity.PVU_Estatus__c);
           response.put('lineStatus',registeredCommunity.PVU_Linea_Padre__r.vlocity_cmt__Status__c);    
           response.put('lineSegment',registeredCommunity.PVU_Segmento_linea__c);
           response.put('activationDate', datePart);	
           response.put('totalChildLines',registeredCommunity.PVU_Total_de_lineas_hijas__c);
           response.put('members',responseMembers);
          

           return response;


    }

    

    //Metodo para respuesta de mensajes cargados en el metadata PVU_CommunityParameters__mdt
    public static Map<String, Object>  getMessageFormCode ( String code ) {
        Map<String, Object> resultMedataMessage = new Map<String, Object>();
        resultMedataMessage.put('message','Contact the administrator for more details');
        resultMedataMessage.put('code','ERROR');
        try {
            PVU_CommunityParameters__mdt metadataRecords = [SELECT PVU_Message__c,PVU_code__c  FROM PVU_CommunityParameters__mdt  WHERE DeveloperName =: code WITH SYSTEM_MODE LIMIT 1];

            if (!String.isEmpty(metadataRecords.PVU_Message__c)) {
                resultMedataMessage.put('message',metadataRecords.PVU_Message__c);
                resultMedataMessage.put('code',String.valueOf(metadataRecords.PVU_code__c.format()));

            }
            return resultMedataMessage;
            
        } catch (QueryException e){

          return resultMedataMessage;
        }
        
    }
}