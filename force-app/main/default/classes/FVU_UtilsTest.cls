@isTest
private class FVU_UtilsTest {
    
    @isTest
    private static void invokeValidFraudeSuccess() {
        
        String response ='{"addresses":{"listHhpps":[{"rushtype":"AEREA","constructionType":"CASA","listAddresMarks":[{"descriptionMark":"HHPP SIN VERIFICACION","markId":"HSV"},{"descriptionMark":"FRAUDE FR","markId":"FR"}],"node":{"technology":"BI","nodeName":"TRINIDAD GALAN BOGOTA        ","qualificationDate":"2018/12/04","state":"A","codeNode":"DGA"},"viability":{"mensajeRespuesta":"Na hay proyecto para procesar","codRespuesta":"I","ResultadoValidacion":"false"},"technology":"BI","state":"PO","hhppId":"10767078"},{"rushtype":"CAJA RELIANCE","constructionType":"CASA","listAddresMarks":[{"descriptionMark":"HHPP SIN VERIFICACION","markId":"HSV"},{"descriptionMark":"FRAUDE FR","markId":"FR"}],"node":{"technology":"DTH","nodeName":"SIT-BOGOTA","qualificationDate":"2020/04/02","state":"ACT","codeNode":"DTHBOG"},"viability":{"mensajeRespuesta":"Na hay proyecto para procesar","codRespuesta":"I","ResultadoValidacion":"false"},"technology":"DTH","state":"PO","hhppId":"10767079"}],"stratum":"3","listCarrierCover":["(LOGYTECH)(1)","(LOGYTECH)(3)"],"listCover":[{"state":"ACT","qualificationDate":"2020/04/02","node":"DTHBOG","technology":"DTH"}],"splitAddres":{"estadoDirGeo":"E","idDirCatastro":"d7896038","cpTipoNivel5":"CASA","placaDireccion":"34","numViaGeneradora":"8","numViaPrincipal":"17","tipoViaPrincipal":"TRANSVERSAL","idTipoDireccion":"CK"},"lengthCoordinate":"0","latitudeCoordinate":"0","adressReliability":"99","igacAddress":"TV 17 8 34","city":{"geographycLevelType":"CENTRO POBLADO","claroCode":"BOG","region":{"technicalCode":"RTW1","name":"REGIONAL TECNICA CENTRAL COLOMBIA","regionId":"3161"},"uperGeographycLevel":{"uperGeographycLevel":{"geographycLevelType":"DEPARTAMENTO","daneCode":"11","name":"BOGOTA","geographyStateId":"7"},"geographycLevelType":"CIUDAD","daneCode":"11001","name":"BOGOTÁ, D.C.","geographyStateId":122},"daneCode":"11001000","name":"BOGOTA","cityId":"24926"},"addressId":"15218538"},"messageType":"I","message":"Operacion Exitosa","headerResponse":{"traceabilityId":"8d910ec5-a187-4ffe-9dc6-d540af959be5","responseDate":"2023-05-31T11:10:19.155-05:00"}}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(response); 
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', inputMap);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            FVU_Utils fraudeValid = new FVU_Utils();
            fraudeValid.call('ValidFraude', args);
        Test.stopTest();
        
    }
    
    @isTest
    private static void invokeValidFraudeException() {
        
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', null);
        args.put('output', outputMap);
        args.put('options', options);

        Test.startTest();
            FVU_Utils fraudeValid = new FVU_Utils();
            fraudeValid.call('ValidFraude', args);
        Test.stopTest();
    }
    
}