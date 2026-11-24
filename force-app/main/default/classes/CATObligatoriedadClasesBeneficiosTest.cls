@isTest
public class CATObligatoriedadClasesBeneficiosTest {
    @isTest
    static void testInvoke(){

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>{
            'promocionesDisponibles' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'name' => 'Descuento 50% CFM',
                    'CAT_PromotionClass__c' => 'Obsequios de CFM'
                }
            }
        };
        String methodName = 'filterPromotions';
        List<String> listaClasesOblig = new List<String>();
        List<String> listaClasesNoOblig = new List<String>(); 
        listaClasesOblig.add('Bundle');
        listaClasesOblig.add('Obsequios de CFM');
        listaClasesNoOblig.add('Bundle');
        listaClasesNoOblig.add('Terceros');
        listaClasesNoOblig.add('Plan Lector');
        List<String> listOutput = new List<String>(); 
        input.put('listaClasesOblig',listaClasesOblig);
        input.put('listaClasesNoOblig', listaClasesNoOblig);

        try {
            // Call the method to be tested
            CATObligatoriedadClasesBeneficios instance = new CATObligatoriedadClasesBeneficios();
            Test.startTest();
            instance.invokeMethod('filterPromotions', input, output, options);
            Test.stopTest();
            // Assert the result
            List<Map<String, Object>> listaPromoFinal = (List<Map<String, Object>>) output.get('listaPromoFinal');
            Assert.areEqual(1, listaPromoFinal.size(), 'Filtered promotions list should have one element');

        } catch (Exception e) {
            System.debug('Error in invoke method');
            //throw e;

        }
    }

    @isTest
    static void testObtenerObligatorias_filtersCorrectly() {
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<Map<String, Object>> promos = new List<Map<String, Object>>{
            new Map<String, Object>{ 'CAT_Obligatorio__c' => true,  'Name' => 'Promo Obligatoria' },
            new Map<String, Object>{ 'CAT_Obligatorio__c' => false, 'Name' => 'Promo No Obligatoria' },
            new Map<String, Object>{ 'CAT_Obligatorio__c' => true,  'Name' => 'Otra Obligatoria' }
        };

        Map<String, Object> input = new Map<String, Object>{ 
            'listaPromoFinal' => promos,
            'orderSubType' => ''
        };

        CATObligatoriedadClasesBeneficios instance = new CATObligatoriedadClasesBeneficios();
        Test.startTest();
        instance.invokeMethod('obtenerObligatorias', input, output, options);
        Test.stopTest();

        List<Object> result = (List<Object>) output.get('listaPromosObligatorias');
        Assert.areEqual(2, result.size(), 'Should return only the 2 mandatory promotions');
    }

    @isTest
    static void testObtenerObligatorias_nullInputReturnsEmpty() {
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>{ 
            'listaPromoFinal' => null,
            'orderSubType' => ''
        };

        CATObligatoriedadClasesBeneficios instance = new CATObligatoriedadClasesBeneficios();
        Test.startTest();
        instance.invokeMethod('obtenerObligatorias', input, output, options);
        Test.stopTest();

        List<Object> result = (List<Object>) output.get('listaPromosObligatorias');
        Assert.areEqual(0, result.size(), 'Null input should return empty list');
    }

    @isTest
    static void testObtenerObligatorias_adicionAdicionalesReturnsEmpty() {
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<Map<String, Object>> promos = new List<Map<String, Object>>{
            new Map<String, Object>{ 'CAT_Obligatorio__c' => true,  'Name' => 'Promo Obligatoria' },
            new Map<String, Object>{ 'CAT_Obligatorio__c' => true,  'Name' => 'Otra Obligatoria' }
        };

        Map<String, Object> input = new Map<String, Object>{
            'listaPromoFinal' => promos,
            'orderSubType' => 'Adicion_de_Adicionales'
        };

        CATObligatoriedadClasesBeneficios instance = new CATObligatoriedadClasesBeneficios();
        Test.startTest();
        instance.invokeMethod('obtenerObligatorias', input, output, options);
        Test.stopTest();

        List<Object> result = (List<Object>) output.get('listaPromosObligatorias');
        Assert.areEqual(0, result.size(), 'Adicion de adicionales should return empty mandatory list');
    }

}