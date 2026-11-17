global with sharing class PVUBusnessHoursUtil implements vlocity_cmt.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;        
        try {
            
            if (methodName.Equals('getDateAfterDays')){                
                 getDateAfterDays(inputMap,outMap);
            } else if (methodName.Equals('calculateBusinessDaysForCancellation')){                
                calculateBusinessDaysForCancellation(inputMap,outMap);
            }
        } catch(Exception ex) {
            System.debug('error>>'+ ex.getStackTraceString()); 
            System.debug('MensajeExcepcion>>'+ ex.getMessage());
            System.debug('Linea>>'+ ex.getLineNumber());
            System.debug('Causa><'+ ex.getCause());
            
            
            outMap.put('error -> ', ex.getStackTraceString() +' MensajeExcepcion ->'+ ex.getMessage()+ ' Linea-> '+ ex.getLineNumber()+' Causa-> '+ ex.getCause());             
            result = false; 
        }
        return result;
    }
    
    public Boolean isWithinThreeBusinessDays(Integer days, DateTime deliveryDate) {  
        Datetime caseCreationDate = Datetime.now(); // Fecha actual de creación del caso
        
        BusinessHours bh = [SELECT ID FROM BusinessHours WHERE Name = 'DiasHabiles' WITH SYSTEM_MODE LIMIT 1];
        
        // Calcular días hábiles entre la fecha de entrega y la fecha de creación del caso
        Long businessMilliseconds = BusinessHours.diff(bh.Id, deliveryDate, caseCreationDate);
        Long millisecondsPerBusinessDay = BusinessHours.diff(bh.Id, deliveryDate, deliveryDate.addDays(1));
        
        // Calcular días hábiles (redondeado hacia arriba para manejar días parciales)
        Decimal businessDays = Decimal.valueOf(businessMilliseconds) / Decimal.valueOf(millisecondsPerBusinessDay);
        Long totalBusinessDays = businessDays.round(System.RoundingMode.UP);
        
        System.debug('Fecha de Entrega: ' + deliveryDate);
        System.debug('Fecha de Creación del Caso: ' + caseCreationDate);
        System.debug('Diferencia en Días Hábiles: ' + totalBusinessDays);
        
        Boolean isWithinThreeDays = totalBusinessDays <= days;
        
        return isWithinThreeDays;
    }
    
    
    public void getDateAfterDays( Map<String,Object> inputMap, Map<String,Object> outMap){
        
        String NoConformingDays = (String) inputMap.get('NoConformingDays');
        Datetime dateInitial =(Datetime) inputMap.get('dateInitial');    
        String RetractoCompraDays = (String) inputMap.get('RetractoCompraDays');
        Integer DateAfterCreateDays = Integer.valueOf(String.valueOf(inputMap.get('DateAfterCreateDays')));
        Datetime NoConformingFinal= getNewDate(NoConformingDays,dateInitial);
        Datetime RetractoCompraFinal= getNewDate(RetractoCompraDays,dateInitial);
        Boolean isWithinThreeDays= isWithinThreeBusinessDays(DateAfterCreateDays,dateInitial);
        outMap.put('NoConformingFinal',NoConformingFinal);
        outMap.put('RetractoCompraFinal',RetractoCompraFinal);
        outMap.put('isWithinThreeBusinessDays', isWithinThreeDays);
    }

    public void calculateBusinessDaysForCancellation( Map<String,Object> inputMap, Map<String,Object> outMap){
        
        Datetime dateInitial =(Datetime) inputMap.get('dateInitial');    
        BusinessHours bHours = [SELECT ID  FROM BusinessHours WHERE Name = 'DiasHabilesOficina' WITH SYSTEM_MODE LIMIT 1];
        Long millisecondsDay = BusinessHours.diff(bHours.Id, dateInitial, dateInitial+1);
        Boolean isBusinessDay = BusinessHours.isWithin(bHours.Id, dateInitial);
        Long daysAdd = isBusinessDay ? 2 : 3;
        Datetime dateCalculated = BusinessHours.addGmt(bHours.Id, dateInitial, millisecondsDay*daysAdd);

        outMap.put('dateCalculated',dateCalculated.format('yyyy-MM-dd'));
    }
    
    public Datetime getNewDate(String days, DateTime dateInitial ){
       // String userId = UserInfo.getUserId();
       // User user= [SELECT ID, FVU_CodigoD__c FROM user WHERE id = :userId limit 1];   
        BusinessHours  businessHoursId=null;
       // if(!Test.isRunningTest()){
       // 	businessHoursId = [SELECT ID  FROM BusinessHours WHERE Name = :user.FVU_CodigoD__c limit 1];
        //}else{
            businessHoursId = [SELECT ID  FROM BusinessHours WHERE Name = 'DiasHabiles' WITH SYSTEM_MODE limit 1];
       // }    
       
       
      //  System.debug('user.FVU_CodigoD__c ' + user.FVU_CodigoD__c);
        System.debug('days ' + days);
        System.debug('Start date ' + dateInitial);       
        System.debug('businessHoursId ' + businessHoursId.ID);
        System.debug('businessHours diff ' + BusinessHours.diff(businessHoursId.ID, dateInitial, dateInitial+1));
        
       // Datetime dateFinal= BusinessHours.addGmt(businessHoursId.ID, dateInitial, fiveDays);
        Datetime dateFinal= BusinessHours.addGmt( businessHoursId.ID, dateInitial, BusinessHours.diff(businessHoursId.ID, dateInitial, dateInitial+1)*(long.valueOf(days)+1) );
        return dateFinal;
    }        

}