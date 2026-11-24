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
            } else if (methodName.equalsIgnoreCase('obtenerObligatorias')) {
                System.debug('Calling obtenerObligatorias method');
                obtenerObligatorias(input, output);
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

    public void obtenerObligatorias(Map<String, Object> input, Map<String, Object> output) {
        List<Object> listaPromosObligatorias = new List<Object>();
        String orderSubType = String.valueOf(input.get('orderSubType')).trim();
        if (orderSubType.equalsIgnoreCase('Adicion_de_Adicionales')) {
            output.put('listaPromosObligatorias', listaPromosObligatorias);
            return;
        }
        List<Object> listaPromoFinal = (List<Object>) input.get('listaPromoFinal');
        if (listaPromoFinal == null) {
            listaPromoFinal = new List<Object>();
        }
        for (Object promo : listaPromoFinal) {
            Map<String, Object> data = (Map<String, Object>) promo;
            if (toBoolean(data.get('CAT_Obligatorio__c'))) {
                listaPromosObligatorias.add(promo);
            }
        }
        output.put('listaPromosObligatorias', listaPromosObligatorias);
    }

    private static Boolean toBoolean(Object rawValue) {
        if (rawValue == null) {
            return false;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean)rawValue;
        }
        return String.valueOf(rawValue).trim().equalsIgnoreCase('true');
    }
}