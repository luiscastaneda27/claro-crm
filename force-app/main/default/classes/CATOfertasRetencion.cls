/*--------------------------------------------------------------------------
Author:         Nahir Arrejoria - narrejoria@salesforce.com
Company:        Salesforce.com
Description:    Class for giving format to the input of the API call for getting promotions in the cart
Code Coverage:  98%
History
<Date>            <Author>             <Description>             <Version>
12-Nov-25         Nahir Arrejoria                            inicial version
----------------------------------------------------------------------------*/
global with sharing class CATOfertasRetencion implements vlocity_cmt.VlocityOpenInterface {
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        Boolean result = true;
        try {
            System.debug('methodName: ' + methodName);
            if (methodName.equalsIgnoreCase('filterPlanesDestino')) {
                System.debug('Calling filterPlanesDestino method');
                filterPlanesDestino(input, output, options);
            }
            // HDU 669698 - Filtro de promociones por tipo de retención y rango de precios
            else if (methodName.equalsIgnoreCase('filterPromosDestino')) {
                System.debug('Calling filterPromosDestino method');
                filterPromosDestino(input, output, options);
            }
        }
        catch (Exception e) {
            result = false;
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return result;
    }
    public void filterPlanesDestino (Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        List<Object> planesDestinoApi = (List<Object>)input.get('planesDisponibles'); 
        Decimal precioPlan = (Decimal)input.get('precioPlan'); 
        String userRole = (String)input.get('userRole'); 
        List <CAT_Oferta_Retencion__mdt> actoresmdt = [select CAT_Actor__c from CAT_Oferta_Retencion__mdt where CAT_Role__c = :userRole WITH SECURITY_ENFORCED];
		List<String> actoresList = new List<String>();
        for (CAT_Oferta_Retencion__mdt  actor : actoresmdt) {
            actoresList.add(actor.CAT_Actor__c);
        }
        List<String> allowedRetentionCodes = new List<String>();
        List <CAT_Oferta_Retencion__mdt> ofertasmdt = new List<CAT_Oferta_Retencion__mdt>();
        System.debug('actoresList: '+ actoresList);
        System.debug('precioPlan: '+ precioPlan);
        ofertasmdt = [select id,CAT_Codigo_oferta__c,CAT_Precio_minimo__c,CAT_Precio_maximo__c from CAT_Oferta_Retencion__mdt where CAT_Actor__c IN :actoresList and CAT_Tipo_Oferta__c ='Producto' and CAT_Precio_minimo__c <= :precioPlan and CAT_Precio_maximo__c >= :precioPlan WITH SECURITY_ENFORCED];
        System.debug('ofertasmdt.size(): '+ ofertasmdt.size());
        if( ofertasmdt.size() == 0){
            System.debug('el precio del asset es mayor que el último rango con precio máximo definido, se debe modificar la query');
            ofertasmdt = [select id,CAT_Codigo_oferta__c,CAT_Precio_minimo__c,CAT_Precio_maximo__c from CAT_Oferta_Retencion__mdt where CAT_Actor__c IN :actoresList and CAT_Tipo_Oferta__c ='Producto' and CAT_Precio_minimo__c <= :precioPlan and CAT_Precio_maximo__c = null WITH SECURITY_ENFORCED ];
        }
        
        for (CAT_Oferta_Retencion__mdt oferta : ofertasmdt ) {
            allowedRetentionCodes.add(oferta.CAT_Codigo_oferta__c);
        }
        System.debug('allowedRetentionCodes: '+ allowedRetentionCodes );
        List<Map<String, Object>> listaPlanesFinal = new List<Map<String, Object>>();
        for (Object plan : planesDestinoApi){
            Map<String, Object> productMap = (Map<String, Object>)plan;
            Object product2Object = productMap.get('Product2');
            String currentProductCode;
            Object productCodeObject = productMap.get('ProductCode');
            if (productCodeObject instanceof Map<String, Object>) {
                Map<String, Object> productCodeMap = (Map<String, Object>)productCodeObject;
    
                currentProductCode = (String)productCodeMap.get('value');
            }
            
            if (product2Object instanceof Map<String, Object>){
                Map<String, Object> product2Map = (Map<String, Object>) product2Object;
                System.debug('campo rente '+ (Boolean)product2Map.get('CAT_Oferta_Retencion__c'));
 
                Boolean isRetentionOffer = (Boolean)product2Map.get('CAT_Oferta_Retencion__c');
                
                if (isRetentionOffer == false) {
                    System.debug('No es un producto de retención');
                    // al no ser un producto de retencion se conserva en la lista a devolver
                    listaPlanesFinal.add(productMap);
                    
                } else if (allowedRetentionCodes.contains(currentProductCode)){
                    System.debug('Es un producto de retención que se encuentra dentro de los permidos en la operación');
                    listaPlanesFinal.add(productMap);
                }
            }
            
        }
        

        output.put('listaPlanesFinal', listaPlanesFinal);

    }

    /*
    * @description 669698 - Filtra promociones según tipo de retención, rango de precios y códigos permitidos
    * @param  input : Contiene la lista de promociones y datos de contexto.
    * @param  output : Mapa donde se carga la lista filtrada.
    * @param  options : Opciones adicionales.
    */
     public void filterPromosDestino (Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        List<Object> promosDestinoApi = (List<Object>)input.get('promosDisponibles'); 
        Decimal precioPlan = (Decimal)input.get('precioPromo'); 
        String userRole = (String)input.get('userRole'); 

        List <CAT_Oferta_Retencion__mdt> actoresmdt = [select CAT_Actor__c from CAT_Oferta_Retencion__mdt where CAT_Role__c = :userRole WITH SECURITY_ENFORCED ];
		List<String> actoresList = new List<String>();

        for (CAT_Oferta_Retencion__mdt  actor : actoresmdt) {
            actoresList.add(actor.CAT_Actor__c);
        }

        List<String> allowedRetentionCodes = new List<String>();

        List <CAT_Oferta_Retencion__mdt> ofertasmdt = new List<CAT_Oferta_Retencion__mdt>();
        System.debug('actoresList: '+ actoresList);
        System.debug('precioPlan: '+ precioPlan);

        ofertasmdt = [select id, CAT_Codigo_oferta__c, CAT_Precio_minimo__c, CAT_Precio_maximo__c from CAT_Oferta_Retencion__mdt where CAT_Actor__c IN :actoresList and CAT_Tipo_Oferta__c ='Promoción' and CAT_Precio_minimo__c <= :precioPlan and CAT_Precio_maximo__c >= :precioPlan WITH SECURITY_ENFORCED];
        System.debug('ofertasmdt.size(): '+ ofertasmdt.size());

        if( ofertasmdt.size() == 0){
            System.debug('el precio del asset es mayor que el último rango con precio máximo definido, se debe modificar la query');
            ofertasmdt = [select id,CAT_Codigo_oferta__c,CAT_Precio_minimo__c,CAT_Precio_maximo__c from CAT_Oferta_Retencion__mdt where CAT_Actor__c IN :actoresList and CAT_Tipo_Oferta__c ='Promoción' and CAT_Precio_minimo__c <= :precioPlan and CAT_Precio_maximo__c = null WITH SECURITY_ENFORCED];
        }
        
        for (CAT_Oferta_Retencion__mdt oferta : ofertasmdt ) {
            allowedRetentionCodes.add(oferta.CAT_Codigo_oferta__c);
        }

        System.debug('allowedRetentionCodes: '+ allowedRetentionCodes );

        List<Map<String, Object>> listaPromosFinal = new List<Map<String, Object>>();
        
        for (Object promo : promosDestinoApi) {
            Map<String, Object> promoMap = (Map<String, Object>) promo;

            String currentPromoCode = (String) promoMap.get('code');
            Boolean isRetentionOffer = (Boolean) promoMap.get('CAT_Oferta_Retencion__c');

            System.debug('code => ' + currentPromoCode);
            System.debug('CAT_Oferta_Retencion__c => ' + isRetentionOffer);

            if (isRetentionOffer == false) {
                System.debug('No es una promoción de retención');
                listaPromosFinal.add(promoMap);

            } else if (allowedRetentionCodes.contains(currentPromoCode)){

                System.debug('Es una promo de retención que se encuentra dentro de los permidos en la operación');
                listaPromosFinal.add(promoMap);
            }
        }

        System.debug('listaPromosFinal >>>> ' + JSON.serialize(listaPromosFinal));
        output.put('listaPromosFinal', listaPromosFinal);

    }
}