/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class test PVU_GetProductCharacteristicTEST
History
<Date>          <Author>        <Change Description>
14/03/2024      Luis Mendoza    Initial Version
------------------------------------------------------------*/
@isTest
public class PVU_GetProductCharacteristicTEST {
    

    @TestSetup
    static void makeData(){
        vlocity_cmt__AttributeCategory__c attrbDes = new vlocity_cmt__AttributeCategory__c();
        attrbDes.Name = 'TEST description';
        attrbDes.vlocity_cmt__Description__c = 'Atributos del número de Teléfono Móvil';
        attrbDes.vlocity_cmt__DisplaySequence__c = 920;

        insert attrbDes;
        
        vlocity_cmt__attribute__c attrb = new vlocity_cmt__attribute__c();
        attrb.Name = 'Test';
        attrb.vlocity_cmt__Code__c = 'B2C_ATTR_TEST';
        attrb.vlocity_cmt__ValueType__c = 'Text';
        attrb.vlocity_cmt__AttributeCategoryId__c  = attrbDes.Id;
        
        insert attrb;

    }

    @isTest
    static void getProductCharacteristic(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 

        String assets = '[{"productCodeRoot":"B2C-MOV-BUND-POST-NAV-VIP-22","OmConcatData":"PS_MovPosPlanVSTDDWTFIL, PS_MovPosPlanVSTDDWTFIL","OOMEricson":[{"CFSS":"PS_MovPosPlanVSTDDWTFIL"},{"CFSS":"PS_MovPosPlanVSTDDWTFIL"}],"orderId":"Q00001074","warrantyValid":false,"isbundle":true,"type":"Mobile","productSubType":"Postpaid","productName":"Navégala VIP 22","tariffSegment":"Postpaid","recurringWithTax":0,"assetId":"02i75000008KDPfAAO","recurringTotalWithoutTax":0,"href":"/services/data/v57.0/sobjects/Asset/02i75000008KDPfAAO","id":"8ba8c298-5789-48d8-40b8-b33a2db8267d","productfamily":"Mobile","oneTimeTaxAmount":2000,"oneTimeWithTax":0,"productType":"Plan","oneTimeAmountWithoutTax":2000,"product2Id":"01t750000077wzQAAQ","recurringTotalAmount":0,"rootItemId":"8ba8c298-5789-48d8-40b8-b33a2db8267d","shortDescription":"Incluye: Llamadas ilimitadas Nal y a USA, Canada, Mexico y Pto Rico. SMS Ilimitados a Todo Destino Nal. Navegacion: Libre para uso exclusivo de la linea y 70GB para compartir con otros dispositivos al alcance del movil. Vlr Min adic LDI: Otros Destinos Hispanoamerica: $1.144, Resto del Mundo: $1.331. Las llamadas LDI se deben realizar por el 00444, generan cobro llamadas realizadas por otros operadores y no aplica marcaciones satelitales ni destinos especiales. No Incluye: Roaming Intnal, LDI a Otros Destinos, MMS, ni descarga de contenidos con costo. Info www.claro.com.co","accountId":"/services/data/v57.0/sobjects/Account/0017900000Mz9UTAAZ","productCode":"B2C-MOV-BUND-POST-NAV-VIP-22","name":"Navégala VIP 22","paymentMethod":"Contado","assetStatus":"Active","recurringCharge":0}]';
        input.put('assetsList', JSON.deserializeUntyped(assets));
        Test.startTest();     
            PVU_GetProductCharacteristic getProductCharacteristic = new PVU_GetProductCharacteristic();
            Boolean result = getProductCharacteristic.invokeMethod('getProductCharacteristic', input, output, options);        
        Test.stopTest();

        Assert.areEqual(true, result);
    }
    
    
    @isTest
    static void getProductCharacteristicJSOn(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 
        Map<String, Object> mapjson = new Map<String, Object>(); 

        String jsnAttrr = '{"B2C_ATTR_TEST":"nuevo test"}';

        List<Object> assts = new List<Object>();
        mapjson.put('jsonattr', jsnAttrr);
        assts.add(mapjson);
        input.put('assetsList', assts );
        Test.startTest();     
            PVU_GetProductCharacteristic getProductCharacteristic = new PVU_GetProductCharacteristic();
            Boolean result = getProductCharacteristic.invokeMethod('getProductCharacteristic', input, output, options);        
        Test.stopTest();

        Assert.areEqual(true, result);
    }
    @isTest
    static void getProductCharacteristicErrorControllerTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>(); 

        String assets = '[{"productCodeRoot":"B2C-MOV-BUND-POST-NAV-VIP-22","OmConcatData":"PS_MovPosPlanVSTDDWTFIL, PS_MovPosPlanVSTDDWTFIL","OOMEricson":[{"CFSS":"PS_MovPosPlanVSTDDWTFIL"},{"CFSS":"PS_MovPosPlanVSTDDWTFIL"}],"productType":"Plan","productfamily":"Mobile","assetStatus":"Active","id":"8ba8c298-5789-48d8-40b8-b33a2db8267d","href":"/services/data/v57.0/sobjects/Asset/02i75000008KDPfAAO","amountTotal":0,"paymentMethod":"Contado","name":"Navégala VIP 22","assetId":"02i75000008KDPfAAO","tariffSegment":"Postpaid","accountId":"/services/data/v57.0/sobjects/Account/0017900000Mz9UTAAZ","productName":"Navégala VIP 22","productSubType":"Postpaid","type":"Mobile","shortDescription":"Incluye: Llamadas ilimitadas Nal y a USA, Canada, Mexico y Pto Rico. SMS Ilimitados a Todo Destino Nal. Navegacion: Libre para uso exclusivo de la linea y 70GB para compartir con otros dispositivos al alcance del movil. Vlr Min adic LDI: Otros Destinos Hispanoamerica: $1.144, Resto del Mundo: $1.331. Las llamadas LDI se deben realizar por el 00444, generan cobro llamadas realizadas por otros operadores y no aplica marcaciones satelitales ni destinos especiales. No Incluye: Roaming Intnal, LDI a Otros Destinos, MMS, ni descarga de contenidos con costo. Info www.claro.com.co","isbundle":true,"tax":2000,"warrantyValid":false,"orderId":"Q00001074","product2Id":"01t750000077wzQAAQ","amountWithoutTax":2000}]';
        input.put('assetsList', assets);
        Test.startTest();     
            PVU_GetProductCharacteristic getProductCharacteristic = new PVU_GetProductCharacteristic();
            Boolean result = getProductCharacteristic.invokeMethod('getProductCharacteristic', input, output, options);        
        Test.stopTest();

        Assert.areEqual(false, result);
    }

}