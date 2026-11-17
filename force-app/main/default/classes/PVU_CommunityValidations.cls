/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class that exposes service inbound Object Community and Community Manager 
Test Class:     
History
<Date>          <Author>        <Change Description>
29/11/2024      Luis Mendoza    Initial Version
16/12/2024      Luis Mendoza    new method to get data from other apex class
------------------------------------------------------------*/
@RestResource(urlMapping='/PVU_CommunityValidations')
global with sharing class PVU_CommunityValidations {

    private static  Map<String, Object> ERROR_CHILDLINE_REQUIRED;
    private static  Map<String, Object> ERROR_PARENTLINE_REQUIRED;
    private static  Map<String, Object> ERROR_COMMUNITY_NOT_FOUND;
    private static  Map<String, Object> ERROR_COMMUNITY_MEMBER_NOT_FOUND;
    private static  Map<String, Object> ERROR_COMM_INACTIVE;

     @HttpGet
     global static void getResquestCommunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
         
        String parentLine = req.params.get('parentLine');
        String childLine = req.params.get('childLine');
         
        Map<String,String> input = new Map<String,String> ();
        input.put('parentLine',parentLine);
        input.put('childLine', childLine);
             
        Map<String,Object> respuestaInfo  = getCommunitInformation(input) ;
         
        res.statusCode = (Integer) respuestaInfo.get('statusCode');
        respuestaInfo.remove('statusCode');
        res.responseBody = Blob.valueOf(JSON.serialize(respuestaInfo));  
         
     }
    
    


   public static Map<String,Object> getCommunitInformation( Map<String,String> input) {


        // Retrieve query parameters
        String parentLine = input.get('parentLine');
        String childLine = input.get('childLine');
        Map<String,Object> respMap = new Map<String,Object>();

        getMessageMDT();
        
        if( String.isEmpty(parentLine) && String.isNotEmpty(childLine)){   
            respMap.put('status', 'error');
            respMap.put('message', ERROR_CHILDLINE_REQUIRED.get('message'));           
            respMap.put('codeStatus', ERROR_CHILDLINE_REQUIRED.get('code'));
            respMap.put('statusCode', 400);
            return respMap ;
        }
        
        if( String.isEmpty(parentLine)){    
            respMap.put('status', 'error');
            respMap.put('message', ERROR_PARENTLINE_REQUIRED.get('message'));
            respMap.put('codeStatus', ERROR_PARENTLINE_REQUIRED.get('code'));
            respMap.put('statusCode', 400);
            return respMap;
        }
        
        try {
            List<PVU_CommunityParameters__mdt> parameterCustom = [SELECT Id, PVU_cost__c,PVU_MaxAllowedCommunities__c,PVU_MaxAllowedEvents__c,
                                                                        PVU_MaxAllowedLines__c FROM PVU_CommunityParameters__mdt 
                                                                        WHERE PVU_Message__c = null AND PVU_code__c = null  WITH USER_MODE LIMIT 1 ];

            if(String.isNotEmpty(parentLine) && String.isEmpty(childLine) ){
                Map<String,Object> respMapData = getCommunityLine(parentLine, parameterCustom);

                respMap.put('statusCode', respMapData.get('message') != null ? 404 : 200);
                respMap.put( 'status', respMapData.get('communityStatus') == null ? 'error' : 'success');
                respMap.put( 'additionalParentInfo', respMapData);
                
            }else if(String.isNotEmpty(parentLine) && String.isNotEmpty(childLine) ){
                Map<String,Object> respInChild= getCommunityLine(parentLine, parameterCustom);

                respMap.put('statusCode', respInChild.get('message') != null ? 404 : 200);
                respMap.put( 'status', respInChild.get('communityStatus') == null ? 'error' : 'success');
                respMap.put( 'additionalParentInfo',respInChild );
                respMap.put( 'additionalChildInfo', getCommunityLineAndChild(parentLine, childLine, parameterCustom));                
            }
            
        } catch (Exception e) {
            respMap.put('status', 'error');
            respMap.put('message', e.getMessage());
            respMap.put('statusCode', 400);
        }
        

        return respMap;
    }
    
    private static Map<String,Object> getCommunityLine(String parentLine, List<PVU_CommunityParameters__mdt> parameterCustom){

        Map<String,Object> rspCommunity = new Map<String,Object>();
        Boolean isHasFixedLine = false;

        List<PVU_Community__c>  lisParentLine=  [SELECT Id,PVU_Linea_Padre__c,PVU_Estatus__c,PVU_Fecha_de_activacion__c,
                                                            PVU_Total_de_lineas_hijas__c,PVU_Segmento_linea__c, PVU_Linea_Padre__r.OM_MSISDN__c 
                                                            FROM PVU_Community__c WHERE  PVU_Linea_Padre__r.OM_MSISDN__c =:parentLine WITH USER_MODE];

        List<PVU_Community_Member__c> listChildCommunityList = [SELECT Id, PVU_Comunidad__c, PVU_Tipo_Linea__c FROM PVU_Community_Member__c WHERE 
                                                        PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c =:parentLine WITH USER_MODE];  
        
        for (PVU_Community_Member__c itm : listChildCommunityList) {
            if(itm.PVU_Tipo_Linea__c == 'Fija'){
                isHasFixedLine = true;
                break;
            }
        }
                                                        
        if(lisParentLine.size() > 0){
            
            if(lisParentLine[0].PVU_Estatus__c == 'Inactiva'){
                rspCommunity.put('status', 'error');
                rspCommunity.put('statusCode', ERROR_COMM_INACTIVE.get('code'));
                rspCommunity.put('message', ERROR_COMM_INACTIVE.get('message'));
            }else{

                List<Asset> ass =  [SELECT ID, Status FROM Asset where vlocity_cmt__SubscriptionId__c = :lisParentLine[0].PVU_Linea_Padre__c 
                AND Product2.vlocity_cmt__Type__c = 'Plan' AND vlocity_cmt__ParentItemId__c = null WITH USER_MODE];
    
                List<AggregateResult> cass  = [SELECT COUNT(PVU_Comunidad__c) FROM Case where PVU_Comunidad__c = :lisParentLine[0].Id WITH USER_MODE];
                 
                Integer currentEvents = (Integer) cass[0].get('expr0');
                
                rspCommunity.put('parentLine', lisParentLine[0].PVU_Linea_Padre__r.OM_MSISDN__c);
                rspCommunity.put('communityStatus', lisParentLine[0].PVU_Estatus__c);
                rspCommunity.put('lineStatus', ass.size() > 0 ? ass[0].Status : ' - ');
                rspCommunity.put('lineSegment', lisParentLine[0].PVU_Segmento_linea__c);
                rspCommunity.put('currentEvents', currentEvents );
                rspCommunity.put('maxAllowedEvents', parameterCustom.size() > 0 && parameterCustom[0].PVU_MaxAllowedEvents__c != null ?  parameterCustom[0].PVU_MaxAllowedEvents__c : 0 );
                rspCommunity.put('cost', parameterCustom.size() > 0 && parameterCustom[0].PVU_cost__c != null ?  parameterCustom[0].PVU_cost__c : 0);
                rspCommunity.put('registeredLines', lisParentLine[0].PVU_Total_de_lineas_hijas__c);
                rspCommunity.put('maxAllowedLines', parameterCustom.size() > 0 && parameterCustom[0].PVU_MaxAllowedLines__c != null ?  parameterCustom[0].PVU_MaxAllowedLines__c : 0);
                rspCommunity.put('hasFixedLine', isHasFixedLine);
                rspCommunity.put('activatedDate', lisParentLine[0].PVU_Fecha_de_activacion__c);
                rspCommunity.put('Id', lisParentLine[0].Id);
            }
            
            
        }else {
            rspCommunity.put('parentLine', parentLine);
            rspCommunity.put('message', ERROR_COMMUNITY_NOT_FOUND.get('message'));
            rspCommunity.put('statusCode', ERROR_COMMUNITY_NOT_FOUND.get('code'));
            
        }
        return rspCommunity;
    }
    
    private static Map<String,Object> getCommunityLineAndChild(String parentLine, String childLine, List<PVU_CommunityParameters__mdt> parameterCustom){
        
        Map<String,Object> rspCommunityChild = new Map<String,Object>();
        
        List<PVU_Community_Member__c>  listChildLine =  [SELECT Id, PVU_Linea_Hija__c,Name,PVU_Segmento_Linea__c, PVU_Tipo_Linea__c  FROM 
        PVU_Community_Member__c WHERE PVU_Linea_Hija__c =:childLine 
        AND PVU_Comunidad__r.PVU_Linea_Padre__r.OM_MSISDN__c  =:parentLine WITH USER_MODE];
        
        List<PVU_Community_Member__c>  currentCommunities =  [SELECT Id, PVU_Linea_Hija__c,Name,PVU_Segmento_Linea__c, PVU_Tipo_Linea__c  FROM 
        PVU_Community_Member__c WHERE PVU_Linea_Hija__c =:childLine WITH USER_MODE];
        
        if(listChildLine.size() > 0){
            
            rspCommunityChild.put('childLine', listChildLine[0].PVU_Linea_Hija__c);
            rspCommunityChild.put('lineType', listChildLine[0].PVU_Tipo_Linea__c);
            rspCommunityChild.put('currentCommunities', currentCommunities.size());
            rspCommunityChild.put('maxAllowedCommunities', parameterCustom.size() > 0 && parameterCustom[0].PVU_MaxAllowedCommunities__c != null ?  parameterCustom[0].PVU_MaxAllowedCommunities__c : 0);
            rspCommunityChild.put('lineSegment', listChildLine[0].PVU_Segmento_Linea__c );
            rspCommunityChild.put('existsInCurrentCommunitie', true);  
            
        }else {
            
            rspCommunityChild.put('childLine',childLine);
            rspCommunityChild.put('currentCommunities', currentCommunities.size());
            rspCommunityChild.put('maxAllowedCommunities', parameterCustom.size() > 0 && parameterCustom[0].PVU_MaxAllowedCommunities__c != null ?  parameterCustom[0].PVU_MaxAllowedCommunities__c : 0);
            rspCommunityChild.put('existsInCurrentCommunitie', false);            
            rspCommunityChild.put('message', ERROR_COMMUNITY_MEMBER_NOT_FOUND.get('message'));
            rspCommunityChild.put('statusCode', ERROR_COMMUNITY_MEMBER_NOT_FOUND.get('code'));
            
            
        }
        return rspCommunityChild;
    }

    private static void getMessageMDT(){
        ERROR_CHILDLINE_REQUIRED =  PVU_CommunityUtilsService.getMessageFormCode('ERROR_CHILDLINE_REQUIRED');
        ERROR_PARENTLINE_REQUIRED = PVU_CommunityUtilsService.getMessageFormCode('ERROR_PARENTLINE_REQUIRED');
        ERROR_COMMUNITY_MEMBER_NOT_FOUND = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_MEMBER_NOT_FOUND');
        ERROR_COMMUNITY_NOT_FOUND = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_NOT_FOUND');
        ERROR_COMM_INACTIVE = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMM_INACTIVE');
    }

}