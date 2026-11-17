/*-----------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Creates TSV file with PromotionInfo
Code Coverage:  100%
History
<Date>            <Author>             <Description>                          <Version>
10-Feb-25         Fernanda Maldonado    Creates TSV file with PromotionInfo   1
------------------------------------------------------------------------------------------*/

 public class CATPromotionTSVExporter {

    @InvocableMethod
    public static List<Id> generatePromotionTSV(List<List<Id>> promotionIdsList) {
        List<Id> results = new List<Id>();

        // Para cada lista de promoIds proporcionada
        for (List<Id> promoIds : promotionIdsList) {
            if (promoIds.isEmpty()) {
                System.debug('No hay IDs de promoción provenientes del flujo.');
            }

            // 1. Obtener información de productos y promociones
            Map<Id, List<String>> promoDataMap = new Map<Id, List<String>>();
            for (vlocity_cmt__Promotion__c promo : [
                SELECT Id, Name, vlocity_cmt__Code__c, vlocity_cmt__IsOrderable__c, CAT_Type__c, CAT_PromotionClass__c, CAT_FirstMonthDiscount__c, CAT_FirstMonthDiscountPercent__c
                FROM vlocity_cmt__Promotion__c 
                WHERE Id IN :promoIds WITH USER_MODE
            ]) {
                promoDataMap.put(promo.Id, new List<String>{
                    promo.Id, 
                    promo.Name, 
                    promo.vlocity_cmt__Code__c, 
                    String.valueOf(promo.vlocity_cmt__IsOrderable__c), 
                    promo.CAT_Type__c, 
                    promo.CAT_PromotionClass__c, 
                    String.valueOf(promo.CAT_FirstMonthDiscount__c), 
                    String.valueOf(promo.CAT_FirstMonthDiscountPercent__c)
                });
            }
            System.debug('--- promoDataMap: ' + promoDataMap);

            // 2. Obtener información de reglas (RuleInfo)
            Map<Id, List<String>> ruleDataMap = new Map<Id, List<String>>();
            for (vlocity_cmt__RuleAssignment__c rule : [
                SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__RuleId__r.Name, vlocity_cmt__RuleId__r.vlocity_cmt__Description__c
                FROM vlocity_cmt__RuleAssignment__c
                WHERE vlocity_cmt__ObjectId__c IN :promoIds WITH USER_MODE
            ]) {
                ruleDataMap.put(rule.vlocity_cmt__ObjectId__c, new List<String>{rule.vlocity_cmt__RuleId__r.Name, rule.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c});
            }
            System.debug('--- ruleDataMap: ' + ruleDataMap);

            // 3. Obtener info productos
            Map<Id, Map<Id,List<String>>> prodDataMap = new Map<Id, Map<Id,List<String>>>();
            for (vlocity_cmt__PromotionItem__c prod : [
                SELECT vlocity_cmt__PromotionId__c, vlocity_cmt__ProductId__c, vlocity_cmt__ProductId__r.Name, vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c 
                FROM vlocity_cmt__PromotionItem__c WHERE vlocity_cmt__PromotionId__c IN :promoIds WITH USER_MODE
            ]) {
                if(!prodDataMap.containsKey(prod.vlocity_cmt__PromotionId__c)){
                    prodDataMap.put(prod.vlocity_cmt__PromotionId__c,new Map<Id, List<String>>());
                }

                prodDataMap.get(prod.vlocity_cmt__PromotionId__c).put(prod.vlocity_cmt__ProductId__c, new List<String>{prod.vlocity_cmt__ProductId__r.Name, prod.vlocity_cmt__ProductId__r.ProductCode, prod.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c});
            }
            System.debug('--- prodDataMap: ' + prodDataMap);

            // 4. Obtener precios SIN impuestos de productos - PL: Cliente Masivo
            for (vlocity_cmt__PriceListEntry__c entry : [
                SELECT Id, vlocity_cmt__PromotionId__c, vlocity_cmt__ProductId__c, vlocity_cmt__ProductId__r.Name, vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, vlocity_cmt__DisplayText__c, vlocity_cmt__PricingElementAmount__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name, vlocity_cmt__EffectiveFromDate__c
                FROM vlocity_cmt__PriceListEntry__c 
                WHERE vlocity_cmt__PromotionId__c IN :promoIds AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c  IN ('OT_STD_PRC_ADJ_ABS', 'OT_STD_PRC_ADJ_PCT', 'OT_STD_PRC', 'REC_MNTH_STD_PRC', 'REC_MNTH_STD_PRC_ADJ_ABS') AND vlocity_cmt__EffectiveUntilDate__c = null AND vlocity_cmt__IsActive__c = true WITH USER_MODE
            ]) {
                if(prodDataMap.containsKey(entry.vlocity_cmt__PromotionId__c)){
                    Map<Id, List<String>> productMap = prodDataMap.get(entry.vlocity_cmt__PromotionId__c);
                    if(productMap.containsKey(entry.vlocity_cmt__ProductId__c)){
                        List<String> promotionItemInfo = productMap.get(entry.vlocity_cmt__ProductId__c);
                        // Agregar info de precios
                        promotionItemInfo.add(entry.vlocity_cmt__DisplayText__c);
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__PricingElementAmount__c));
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c));
                        promotionItemInfo.add(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name);
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__EffectiveFromDate__c));

                        System.debug('--- promotionItemInfo: ' + JSON.serialize(promotionItemInfo));
                    }
                    else{
                        prodDataMap.get(entry.vlocity_cmt__PromotionId__c).put(entry.Id, new List<String>{entry.vlocity_cmt__ProductId__r.Name, entry.vlocity_cmt__ProductId__r.ProductCode, entry.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, entry.vlocity_cmt__DisplayText__c, String.valueOf(entry.vlocity_cmt__PricingElementAmount__c), String.valueOf(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c), entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name, String.valueOf(entry.vlocity_cmt__EffectiveFromDate__c)});
                        List<String> promotionItemInfo = productMap.get(entry.vlocity_cmt__ProductId__c);
                        System.debug('--- prodDataMap: ' + JSON.serialize(prodDataMap));
                    }
                }
            }

            // 4. Obtener precios CON impuestos de productos
            for (vlocity_cmt__PriceListEntry__c entry : [
                SELECT vlocity_cmt__PromotionId__c, vlocity_cmt__ProductId__c, vlocity_cmt__DisplayText__c, vlocity_cmt__PricingElementAmount__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name, vlocity_cmt__EffectiveFromDate__c
                FROM vlocity_cmt__PriceListEntry__c 
                WHERE vlocity_cmt__PromotionId__c IN :promoIds AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c = 'Mensual con impuestos' AND vlocity_cmt__EffectiveUntilDate__c = null AND vlocity_cmt__IsActive__c = true WITH USER_MODE
            ]) {

                if(prodDataMap.containsKey(entry.vlocity_cmt__PromotionId__c)){
                    Map<Id, List<String>> productMap = prodDataMap.get(entry.vlocity_cmt__PromotionId__c);
                    if(productMap.containsKey(entry.vlocity_cmt__ProductId__c)){
                        List<String> promotionItemInfo = productMap.get(entry.vlocity_cmt__ProductId__c);
                        // Agregar info de precios
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add('');
                        promotionItemInfo.add(entry.vlocity_cmt__DisplayText__c);
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__PricingElementAmount__c));
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c));
                        promotionItemInfo.add(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name);
                        promotionItemInfo.add(String.valueOf(entry.vlocity_cmt__EffectiveFromDate__c));

                        System.debug('--- promotionItemInfo: ' + JSON.serialize(promotionItemInfo));
                    }
                }
            }

            // 5. Construcción del tsv
            String tsvContent = 'Id\tNombre\tCódigo Promoción\tEs Ordenable\tTipo de Promo\tTipo de Beneficio\tDescuento Primer Mes\tPcnt Descuento Primer Mes\tNombre Regla Asociada\tDescripción Regla\tNombre Producto Asociado\tCódigo Producto\tTipo Producto\tDisplay Name PLE sin Impuestos\tOverride a Precio sin impuestos\tAjuste a Precio sin impuestos\tVariable de Precio sin Impuestos\tEfectivo desde la fecha\tDisplay Name PLE sin Impuestos\tOverride a Precio sin impuestos\tAjuste a Precio sin impuestos\tVariable de Precio sin Impuestos\tEfectivo desde la fecha\tDisplay Name PLE sin Impuestos\tOverride a Precio sin impuestos\tAjuste a Precio sin impuestos\tVariable de Precio sin Impuestos\tEfectivo desde la fecha\tDisplay Name PLE con Impuestos\tOverride a Precio con impuestos\tAjuste a Precio con impuestos\tVariable de Precio con Impuestos\tEfectivo desde la fecha\n';
            System.debug('--- tsvContent: ' + tsvContent);

            for (Id promotionId : promoIds) {

                // Definir mapa de información de productos
                Map<Id, List<String>> productMap = new Map<Id, List<String>>();

                //Verificar si los datos existen en los mapas, si no, se asignan valores predeterminados
                List<String> promoRow = new List<String>{'','','','','','','','','','',''};
                if(promoDataMap.containsKey(promotionId)){
                    promoRow = promoDataMap.get(promotionId);
                }
                System.debug('--- promoRow: ' + promoRow);
                List<String> ruleRow = new List<String>{'',''};
                if(ruleDataMap.containsKey(promotionId)){
                    ruleRow = ruleDataMap.get(promotionId);
                }
                System.debug('--- ruleRow: ' + ruleRow);
                List<String> prodRow = new List<String>();
                if(prodDataMap.containsKey(promotionId)){
                    productMap = prodDataMap.get(promotionId);
                    for (String key : productMap.keySet()) {
                        prodRow.add(String.join(productMap.get(key), '\t'));
                    }
                }
                System.debug('--- prodRow: ' + JSON.serialize(prodRow));

                // Concatenación de cadenas
                for(String prodInfo : prodRow){
                    tsvContent += String.join(promoRow, '\t') + '\t' + String.join(ruleRow, '\t') + '\t' + prodInfo + '\n';
                    System.debug('--- tsvContentProdInfo: ' + tsvContent);
                }
            }
            System.debug('--- tsvContent: ' + tsvContent);

            // 6. Creación de ContentVersion
            ContentVersion tsv = new ContentVersion();
            tsv.Title = 'PromotionInfo.tsv';
            tsv.PathOnClient = 'PromotionInfo.tsv';
            tsv.VersionData = Blob.valueOf(tsvContent);
            tsv.IsMajorVersion = true;
            insert as user tsv;

            results.add(tsv.Id);
        }

        return results;
    }
}