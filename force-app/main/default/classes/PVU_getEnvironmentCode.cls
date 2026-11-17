/*--------------------------------------------------------------------------
Autor:                  Johana - johana.dutan@intellectsystem.net
Empresa:                Salesforce.com
Descripción:            Apex para obtener el código de la ORG
Cobertura de Código:    100%

Historial
<Date>            <Author>             <Description>             <Version>
2-Enero-25        Johana               Creación clase apex       inicial version
----------------------------------------------------------------------------*/
global with sharing class PVU_getEnvironmentCode implements vlocity_cmt.VlocityOpenInterface {   

    global static Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        if (methodName == 'getEnvironmentCode') {
            getEnvironmentCode(inputMap, outMap, options);
        }else if (methodName == 'getTargetCode') {
            getTargetCode(inputMap, outMap, options);
        }
        
        return true;
    }

    
    public static void getEnvironmentCode(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
        System.debug(d.getSandboxName());
        
        String sandboxName = String.isNotBlank(d.getSandboxName())?d.getSandboxName() :'prod';
        

        // Consulta a la metadata creada PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt
        PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt mdtEnvironmentCode = [
            SELECT PVU_Codigo_Ambiente_Claro__c, PVU_CusInstallRefund_EnvSF__c
            FROM PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt
            WHERE PVU_Nombre_de_ORG__c = :sandboxName
            WITH USER_MODE
            LIMIT 1
        ];

        String environmentCode = mdtEnvironmentCode != null ? mdtEnvironmentCode.PVU_Codigo_Ambiente_Claro__c : null;
        String cusInstallRefundEnvSF = mdtEnvironmentCode != null ? mdtEnvironmentCode.PVU_CusInstallRefund_EnvSF__c : null;
        outMap.put('environmentCode', environmentCode); 
        outMap.put('cusInstallRefundEnvSF', cusInstallRefundEnvSF); 
    }
        
   public static void getTargetCode(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        System.Domain dt = System.DomainParser.parse(URL.getOrgDomainUrl());
        System.debug(dt.getSandboxName());
        
        String sandboxName = String.isNotBlank(dt.getSandboxName())?dt.getSandboxName():'prod';

        // Consulta a la metadata creada PVU_Target_Load_Contract_Ambiente__mdt
        PVU_Target_Load_Contract_Ambiente__mdt mdtTargetCode = [
            SELECT PVU_Target_Ambiente_Claro__c
            FROM  PVU_Target_Load_Contract_Ambiente__mdt
            WHERE PVU_Nombre_de_ORG__c = :sandboxName
            WITH USER_MODE
            LIMIT 1
        ];

        String targetCode = mdtTargetCode != null ? mdtTargetCode.PVU_Target_Ambiente_Claro__c : null ;
        outMap.put('targetCode', targetCode); 
    }
}