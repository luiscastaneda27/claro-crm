/*--------------------------------------------------------------------------
Author:         Nahir Arrejoria - narrejoria@salesforce.com
Company:        Salesforce.com
Description:    Filtrado de clases de promoción
Code Coverage:  91%
History
<Date>            <Author>             <Description>             <Version>
20-Sep-24         Nahir Arrejoria                            initial version
----------------------------------------------------------------------------*/

global with sharing class CATObligatoriedadClasesBeneficios implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) { 
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('filterPromotions')) {
                System.debug('Calling filterPromotions method');
                filterPromotions(input, output, options);
            } 
        } catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }

    public void filterPromotions (Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)  {

        List<Object> listClasesNoOblig = (List<Object>)input.get('listaClasesNoOblig'); 
        List<Object> listClasesOblig = (List<Object>)input.get('listaClasesOblig'); 
        List<Object> promocionesDisponibles = (List<Object>)input.get('promocionesDisponibles'); 

        System.debug('listaClasesNoOblig: ' + input.get('listaClasesNoOblig'));
        System.debug('listaClasesOblig: ' + input.get('listaClasesOblig'));
        System.debug('promocionesDisponibles: ' + input.get('promocionesDisponibles'));

        List<Object> nuevaLista = new List<Object>();
        List<Object> listaPromoFinal = new List<Object>();

        for(Object str : listClasesNoOblig) {
            system.debug('str: ' + str );
            //se arma nueva lista quitando las clases obligatorias
            if(!listClasesOblig.contains(str)) {
                nuevaLista.add(str);
            }
        }
        System.debug('nuevaLista: ' + nuevaLista );
        for (Object promo : promocionesDisponibles ) {
            Map<String,Object> data = (Map<String,Object>)promo;
            String promoClass = (String)data.get('CAT_PromotionClass__c');
            system.debug('promoClass: ' + promoClass);
            if(!nuevaLista.contains(promoClass)){
                listaPromoFinal.add(promo);
            }

        }


        System.debug('nuevaLista: ' + nuevaLista );
        //output.put('nuevaLista', nuevaLista);
        output.put('listaPromoFinal', listaPromoFinal);
        
        
    }
}