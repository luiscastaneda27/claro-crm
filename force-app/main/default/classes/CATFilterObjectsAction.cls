/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: 
Code Coverage: 95%
History
<Date> 			<Author>	 	<Description>		 <Version>
10-Sep-25	   Alan Semino  						inicial version
----------------------------------------------------------------------------*/
public without sharing class CATFilterObjectsAction {
    
    /*
    * @description 622605 - Parámetros de input para obtener datos de procesamiento (Global Keys y Canales).
    * @param  globalKeys : Lista de Global Keys recibidas desde el Screen Flow (por ejemplo, procesadas desde un CSV).
    * @param  canales    : Cadenas de canal(es) seleccionados en el Screen Flow.
    */
    public class InputParameters {
        @InvocableVariable(required=true  label='Global Keys')
        public List<String> globalKeys;
        @InvocableVariable(required=false label='Canales Seleccionados')
        public String canales;
    }
    
    /*
    * @description 622605 - Parámetros de output para devolver resultados de búsquedas de keys validas/invalidas y códigos de productos.
    * @param  validKeys: Variable de salida para registro de Global Keys validas en objetos.
    * @param  invalidKeys: Variable de salida para registro de Global Keys invalidas en objetos.
    * @param  productCodes: Variable de salida para codigos de productos validados por cada Globalkey y Canal de los objetos.
    * @param  noChannelKeys: Variable de salida para registro de Global Keys validas sin Canal relacionados en objetos.
    */
    public class OutputParameters {
        @InvocableVariable(label='Valid Keys')     public List<String> validKeys;
        @InvocableVariable(label='Invalid Keys')   public List<String> invalidKeys;
        @InvocableVariable(label='Product Codes')  public List<String> productCodes;
        @InvocableVariable(label='Promotion Codes') public List<String> promoCodes; 
        @InvocableVariable(label='Keys sin Canal') public List<String> noChannelKeys;
    }

    /*
    * @description 622605 - Metodo inicial invocable desde el Flow. 
    * @param  requests: Parametro de request de petición de inputs.
    * @return List<OutputParameters>  : Lista de resultados (validKeys, invalidKeys, productCodes, noChannelKeys).
    */
    @InvocableMethod(label='Filtrar Global Keys en objetos' description='Valida Global Keys en Product2, Promotion y PromotionItem usando canal(es).')
    public static List<OutputParameters> validateGlobalKeys(List<InputParameters> requests) {
        Aggregated aggregatedData = aggregateInputs(requests);
        Indexed indexData = indexAll(aggregatedData.allKeys);
        return resolvePerRequest(requests, aggregatedData.channelsPerRequest, indexData);
    }

    /*
    * @description 622605 - Contenedor agregado de entrada, toma los Global Keys y canales por cada request.
    * @param  allKeys : Conjunto de Global Keys obtenidos por requests.
    * @param  channelsPerRequest : Lista paralela a los requests con los canales normalizados.
    */
    private class Aggregated {
        Set<String> allKeys;
        List<Set<String>> channelsPerRequest;
        Aggregated(Set<String> keys, List<Set<String>> channels){ allKeys=keys; channelsPerRequest=channels; }
    }
    
    /*
    * @description 622605 - Agrega y normaliza la entrada: deduplica Global Keys, parsea canales por request y arma el contenedor agregado.
    * @param  requests : Lista de InputParameters recibida del Flow.
    * @return Aggregated : Objeto con allKeys (Set<String>) y channelsPerRequest (List<Set<String>>).
    */
    private static Aggregated aggregateInputs(List<InputParameters> requests) {
        Set<String> allKeys = new Set<String>();
        List<Set<String>> channelsPerRequest = new List<Set<String>>();
        for (InputParameters request : requests) {
            Set<String> parsedChannels = parseChannels(request == null ? null : request.canales);
            channelsPerRequest.add(parsedChannels);
            
            if (request != null && request.globalKeys != null)
                for (String key : request.globalKeys)
                if (!String.isBlank(key)) allKeys.add(key.trim());
        }
        return new Aggregated(allKeys, channelsPerRequest);
    }
    
    /*
    * @description 622605 - Parsea la cadena de canales (multi-select) y descarta vacíos/nulos.
    * @param  rawChannels : Cadena de canales.
    * @return Set<String> : Conjunto de canales normalizados (únicos, sin espacios).
    */
    private static Set<String> parseChannels(String rawChannels) {
        Set<String> parsed  = new Set<String>();
        if (String.isBlank(rawChannels)) return parsed;
        for (String channelToken : rawChannels.split(';'))
            if (!String.isBlank(channelToken)) parsed.add(channelToken.trim());
        return parsed;
    }
    
    /*
    * @description 622605 - Construye la clave compuesta en los mapas: "globalKey:canal". Retorna null si algún valor es blank.
    * @param  globalKey   : Global Key normalizado.
    * @param  channelName : Canal normalizado.
    * @return String : Clave compuesta "globalKey:canal" o null si no aplica.
    */
    private static String compositeKey(String globalKey, String channelName) {
        return (String.isBlank(globalKey) || String.isBlank(channelName)) ? null : globalKey.trim() + ':' + channelName.trim();
    }
    /*
    * @description 622605 - Índices construidos a partir de las consultas. Permiten resolver (GlobalKey:Canal) en memoria.
    * @param  productByKeyChannel           : Map para coincidencias de productos.
    * @param  promotionByKeyChannel         : Map para coincidencias de promociones.
    * @param  promotionItemByKeyChannel     : Map de promotionItem usando datos de Objeto "Promotion" para coincidencias de promociones.
    * @param  productKeysNoChannel          : Set de Global Keys de Product2 sin canal asignado.
    * @param  promotionKeysNoChannel        : Set de Global Keys de Promotion sin canal asignado.
    * @param  promotionItemKeysNoChannel    : Set de Global Keys de Promotion desde PromotionItem sin canal asignado.
    */
     private class Indexed {
        Map<String, Product2> productByKeyChannel = new Map<String, Product2>();
        Map<String, vlocity_cmt__Promotion__c> promotionByKeyChannel = new Map<String, vlocity_cmt__Promotion__c>();
        Map<String, vlocity_cmt__PromotionItem__c> promotionItemByKeyChannel = new Map<String, vlocity_cmt__PromotionItem__c>();
        Set<String> productKeysNoChannel = new Set<String>();
        Set<String> promotionKeysNoChannel = new Set<String>();
        Set<String> promotionItemKeysNoChannel = new Set<String>();
        Map<String, List<String>> productCodesByPromoKeyChannel = new Map<String, List<String>>();


    }
    
    /*
    * @description 622605 - Ejecuta el indexado completo: consulta los objetos y llena los maps y sets de "sin canal".
    * @param  keys : Conjunto de Global Keys de los requests.
    * @return Indexed : Estructura con los mapas por (GlobalKey:Canal) y los sets de keys sin canal por objeto.
    */
    private static Indexed indexAll(Set<String> keys) {
        Indexed indexData  = new Indexed();
        if (keys.isEmpty()) return indexData;
        indexProducts(keys, indexData);
        indexPromotions(keys, indexData);
        return indexData;
    }
    
    /*
    * @description 622605 - Recorre "Product2" por cada registro, agrega por canal en productByKeyChannel o en productKeysNoChannel.
    * @param  keys : Conjunto de Global Keys a consultar en Product2.
    * @param  indexData : Estructura de índices a poblar.
    */
    private static void indexProducts(Set<String> keys, Indexed indexData) {
        List<Product2> productRows = [
            SELECT vlocity_cmt__GlobalKey__c, ProductCode, CAT_Canales__c
            FROM Product2 WHERE vlocity_cmt__GlobalKey__c IN :keys 
            WITH USER_MODE
        ];
        for (Product2 product  : productRows) {
            if (String.isBlank(product.CAT_Canales__c)) { indexData.productKeysNoChannel.add(product.vlocity_cmt__GlobalKey__c); continue; }
            for (String channelName : product.CAT_Canales__c.split(';')) {
                String compositeKeyStr = compositeKey(product.vlocity_cmt__GlobalKey__c, channelName);
                if (compositeKeyStr != null) indexData.productByKeyChannel.put(compositeKeyStr, product);
            }
        }
    }
    
    /*
    * @description 622605 - Recorre "Promotion" por cada registro,agrega por canal en promotionByKeyChannel o en promotionKeysNoChannel.
    * @param  keys : Conjunto de Global Keys a consultar en vlocity_cmt__Promotion__c.
    * @param  indexData : Estructura de índices a poblar.
    */
    private static void indexPromotions(Set<String> keys, Indexed indexData) {
        List<vlocity_cmt__Promotion__c> promotionRows = [
            SELECT vlocity_cmt__GlobalKey__c,CAT_PromotionClass__c,
            vlocity_cmt__Code__c, CAT_Canales__c
            FROM vlocity_cmt__Promotion__c WHERE vlocity_cmt__GlobalKey__c IN :keys
            WITH USER_MODE
        ];
        for (vlocity_cmt__Promotion__c promotion : promotionRows) {
            if (String.isBlank(promotion.CAT_Canales__c)) { indexData.promotionKeysNoChannel.add(promotion.vlocity_cmt__GlobalKey__c); continue; }
            for (String channelName : promotion.CAT_Canales__c.split(';')) {
                String compositeKeyStr = compositeKey(promotion.vlocity_cmt__GlobalKey__c, channelName);
                if (compositeKeyStr != null) indexData.promotionByKeyChannel.put(compositeKeyStr, promotion);
            }
        }
    }

    /*
    * @description 622605 - Resuelve cada request de "GlobalKey" y "Canal", recolecta códigos y clasifica en válidos, inválidos y sin canal.
    * @param  requests : Lista original de InputParameters.
    * @param  channelsPerRequest : Canales normalizados por cada request.
    * @param  indexData : Índices anteriores construidos.
    * @return results : Salida de: validKeys, invalidKeys, productCodes y noChannelKeys.
    */
    private static List<OutputParameters> resolvePerRequest(List<InputParameters> requests,List<Set<String>> channelsPerRequest,Indexed indexData) {

        List<OutputParameters> results = new List<OutputParameters>();
        for (Integer i = 0; i < requests.size(); i++) {
            InputParameters request = requests[i];
            Set<String> requestChannels = channelsPerRequest[i];

            OutputParameters output = new OutputParameters();
            output.validKeys = new List<String>();
            output.invalidKeys = new List<String>();
            output.noChannelKeys = new List<String>();
		 
            List<String> codes = new List<String>();
            List<String> promoCodes = new List<String>();

            if (request  == null || request.globalKeys == null) {
                output.productCodes = new List<String>();
                results.add(output);
                continue;
            }
            
            for (String rawGlobalKey : request.globalKeys) {
                String globalKey  = String.isBlank(rawGlobalKey) ? null : rawGlobalKey.trim();
                if (String.isBlank(globalKey))
                    continue;

                Boolean found = false;

                if (!requestChannels.isEmpty()){ 
                    for (String channelName : requestChannels) {
                        Product2 product = indexData.productByKeyChannel.get(compositeKey(globalKey, channelName));
                        if (product  != null) {
                            codes.add(product.ProductCode);
                            found = true;
                            break; }
                    }
                }
                
                if (!found && !requestChannels.isEmpty()) {
                    for (String channelName : requestChannels) {
                        String key = compositeKey(globalKey, channelName);
                        vlocity_cmt__Promotion__c promo = indexData.promotionByKeyChannel.get(key);
                        if (promo != null) {
                            if (promo.CAT_PromotionClass__c == 'Bundle') {
                                codes.add(promo.vlocity_cmt__Code__c);
                            } else {
                                promoCodes.add(promo.vlocity_cmt__Code__c);
                            }
                            found = true;
                            break;
                        }
                    }
                }

                if (!found) {
                    if (indexData.productKeysNoChannel.contains(globalKey) || indexData.promotionKeysNoChannel.contains(globalKey)) {
                        output.noChannelKeys.add(globalKey);
                    } else {
                        output.invalidKeys.add(globalKey);
                    }
                } else {
                    output.validKeys.add(globalKey);
                }
            }
            output.productCodes = new List<String>(codes);
            output.promoCodes   = new List<String>(promoCodes);
            results.add(output);
        }
        return results;
    }
}