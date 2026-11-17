@isTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
public class FIN_PlazosPreciosTest {
    // Datos comunes para todos los tests
    @testSetup
    static void setupTestData() {

        // Usa una fecha que siempre estará en el futuro en el momento de la inserción.
        // Aumentar los segundos a 5 garantiza que no habrá un error de validación.
        DateTime desde = System.now().addSeconds(5);
        DateTime hasta = desde.addHours(2);

        // Registro válido: Tecnología, PVP_Min = 100
        FIN_PlazosPrecios__c valido = new FIN_PlazosPrecios__c(
            FIN_PVP_Min__c    = '100',
            FIN_PVP_Max__c    = '500',
            FIN_Producto__c   = 'Tecnología',
            FIN_Plazo_1_6__c  = 'SI',
            FIN_Plazo_7_12__c = 'NO',
            FIN_Plazo_13_18__c= 'SI',
            FIN_Plazo_19_24__c= 'NO',
            FIN_Plazo_25_36__c= 'SI',
            FIN_Desde__c      = desde,
            FIN_Hasta__c      = hasta
        );
        
        // Registro con PVP_Min mayor que el input (300)
        FIN_PlazosPrecios__c altoPvp = valido.clone(false, true, true);
        altoPvp.FIN_PVP_Min__c = '300';
        
        // Registro de producto distinto
        FIN_PlazosPrecios__c otroProd = valido.clone(false, true, true);
        otroProd.FIN_Producto__c = 'Terminales';
        
        insert new List<FIN_PlazosPrecios__c>{ valido, altoPvp, otroProd };
    }

    // Helper para construir el inputMap
    private static Map<String,Object> buildInput(Decimal pvpMin, DateTime fecha) {
        return new Map<String,Object>{
            'Producto'    => 'Tecnología',
            'PVPMin'      => pvpMin,
            'FechaActual' => fecha.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')
        };
    }

    @isTest static void testEscenarioValido() {
        
        // Usar una fecha que coincida con la data de setup, ajustando los segundos.
        DateTime fechaInput = System.now().addSeconds(5);
        Map<String,Object> input  = buildInput(150, fechaInput);
        
        Map<String,Object> outMap = new Map<String,Object>();

        Test.startTest();
            Boolean ok = new FIN_PlazosPrecios().invokeMethod('obtenerPlazos', input, outMap, new Map<String,Object>());
        Test.stopTest();

        Assert.isTrue(ok, 'invokeMethod debe devolver true');
        List<Object> resultados = (List<Object>) outMap.get('result');
        Assert.areEqual(1, resultados.size(), 'Debe retornar 1 registro válido');
        Map<String,Object> mapa = (Map<String,Object>) resultados[0];
        Assert.isTrue((Boolean)mapa.get('1-6'), 'Plazo 1-6 debe ser true');
        Assert.areEqual('500', mapa.get('PVPMax'));
    }    
}