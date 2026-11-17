global with sharing class PVU_CommunityInfoExtract implements vlocity_cmt.VlocityOpenInterface {
    
     public Boolean invokeMethod(String methodName, Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
         Boolean result = true;
         
            if (methodName == 'getCommunitInformation') {
                
            getCommunitInformation(input, outMap, options);    
         
            }else{
               result = false;
            }
         return result;
         
      
     }
    
    public static  void getCommunitInformation (Map<String,Object> inputMap,Map<String,Object> outMap, Map<String,Object> options) 
    {
        try{
                     Map<String, String> stringMap = new Map<String, String>();
         String parentLine = (String)inputMap.get('parentLine');
         stringMap.put('parentLine',parentLine);

        
          Map<String, Object> communityInfo = PVU_CommunityValidations.getCommunitInformation(stringMap);
           if (communityInfo != null) {
              outMap.putAll(communityInfo);  // Add all the key-value pairs from communityInfo into outMap
             }
            
         }catch(Exception e) {
          System.debug('Error:: ' + e.getMessage() + ' ' + e.getCause() );
           outMap.put('code', '406');
           outMap.put('reason', e.getCause());
           outMap.put('message', e.getMessage());
           outMap.put('status', 'Failed');
       


       
    }
    
    }
}