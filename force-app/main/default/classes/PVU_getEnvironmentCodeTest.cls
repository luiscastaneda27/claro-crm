/*--------------------------------------------------------------------------
Autor:                  Johana - johana.dutan@intellectsystem.net
Empresa:                Salesforce.com
Descripción:            Clase Test de la Apex para obtener el nombre de la ORG
Cobertura de Código:    

Historial
<Date>            <Author>             <Description>             <Version>
2-Enero-25        Johana               Creación clase test       inicial version
----------------------------------------------------------------------------*/
@IsTest
public class PVU_getEnvironmentCodeTest {

    @IsTest
    static void testGetEnvironmentCode() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();


        Test.startTest();

        Boolean result = PVU_getEnvironmentCode.invokeMethod('getEnvironmentCode', inputMap, outputMap, options);

        Test.stopTest();

        System.debug('environmentCode: ' + outputMap.get('environmentCode'));
        System.assertNotEquals(null, outputMap.get('environmentCode'),'Contiene enviroment code');
    }
    
      @IsTest
    static void testGetTargetCode() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();


        Test.startTest();

        Boolean result = PVU_getEnvironmentCode.invokeMethod('getTargetCode', inputMap, outputMap, options);

        Test.stopTest();

        System.debug('targetCode: ' + outputMap.get('targetCode'));
        System.assertNotEquals(null, outputMap.get('targetCode'),'Contiene target code');
    }
}