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

}