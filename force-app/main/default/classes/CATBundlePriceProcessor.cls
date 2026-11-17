/*---------------------------------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Process prices from product items in promotion type 'bundle'
Code Coverage:  %
History
<Date>            <Author>             <Description>                                                  <Version>
20-Mar-24         Fernanda Maldonado    Process prices from product items in promotion type 'bundle'   1
----------------------------------------------------------------------------------------------------------------*/
public with sharing class CATBundlePriceProcessor {
    @InvocableMethod(label='CATBundlePriceProcessor' description='Procesa los precios de los productos que son parte de las promociones de tipo "bundle"' category='CAT')

    public static List<List<Decimal>> processBundlePLE(List<List<String>> priceListEntryIdsList) {
        System.debug('priceListEntryIdsList:' + priceListEntryIdsList);

        List<String> priceListEntryIds = priceListEntryIdsList[0];
        System.debug('priceListEntryIds:' + priceListEntryIds);

        // Mapa que guarda elproductIDs y su tipo de precio (override, adjustment o ple)
        Map<Id, String> bundlePrices = new Map<Id, String>();

        // Inicializar variables que se usaran para acumular los precios con y sin impuestos
        Decimal addOnPriceWithTax = 0;
        Decimal addOnPriceWithoutTax = 0;

        // Inicializar variables de tipo mapa que guardan los precios dependiendo el producto
        Map<Id, Decimal> priceWithTaxMap = new Map<Id, Decimal>();
        Map<Id, Decimal> priceWithoutTaxMap = new Map<Id, Decimal>();

        // Variables para acumular el precio del plan móvil con y sin impuestos
        Decimal mobilePlanPriceWithTax = 0;
        Decimal mobilePlanPriceWithoutTax = 0;

        // Consulta los campos con relaciones del objeto PriceListEntry basados en los IDs recuperados del flujo
        List<vlocity_cmt__PriceListEntry__c> priceListEntries = [SELECT vlocity_cmt__IsOverride__c, vlocity_cmt__PricingElementAmount__c, vlocity_cmt__ProductId__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__AdjustmentMethod__c, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, vlocity_cmt__ProductId__r.vlocity_cmt__SubType__c FROM vlocity_cmt__PriceListEntry__c WHERE Id IN :priceListEntryIds WITH SECURITY_ENFORCED];
        System.debug('priceListEntries:' + priceListEntries);

        // Iterar los registros del objeto PriceListEntry y procesar su información basada en el tipo de precio (override, adjustment, ple)
        for (vlocity_cmt__PriceListEntry__c entry : priceListEntries) {
            String productType = entry.vlocity_cmt__ProductId__r.vlocity_cmt__Type__c;
            String productSubtype = entry.vlocity_cmt__ProductId__r.vlocity_cmt__SubType__c;
            Id productId = entry.vlocity_cmt__ProductId__c;
            String frequency = entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c;
            System.debug('productId:' + productId);
            System.debug('productType:' + productType);
            System.debug('productSubtype:' + productSubtype);
            System.debug('frequency:' + frequency);

            // Checar si la entrada de precio es de tipo override
            if(entry.vlocity_cmt__IsOverride__c) {
                bundlePrices.put(productId, 'override');
                System.debug('bundlePrices:' + bundlePrices);
                System.debug('entry.vlocity_cmt__PricingElementAmount__c: '+entry.vlocity_cmt__PricingElementAmount__c);
                //processedProductIds.add(productId);

                // Acumular precios en sus respectivas categorías (con/sin impuestos)
                // Añadir el descuento correspondiente al plan
                if(productType == 'Plan' && productSubtype == 'Postpaid') {
                    if(frequency == 'Mensual con impuestos') {
                        accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                        // Acumularlo en la variable de precio total con impuestos
                        mobilePlanPriceWithTax += entry.vlocity_cmt__PricingElementAmount__c;
                    } else if(frequency == 'Monthly'){
                        accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                        // Acumularlo en la variable de precio total sin impuestos
                        mobilePlanPriceWithoutTax += entry.vlocity_cmt__PricingElementAmount__c;
                    }
                    // Añadir el descuento correspondiente al paquete adicional
                } else {
                    if(frequency == 'Mensual con impuestos') {
                        accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                        // Acumularlo en la variable de precio total con impuestos
                        addOnPriceWithTax += entry.vlocity_cmt__PricingElementAmount__c;
                    } else if(frequency == 'Monthly'){
                        accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                        // Acumularlo en la variable de precio total sin impuestos
                        addOnPriceWithoutTax += entry.vlocity_cmt__PricingElementAmount__c;
                    }
                }
            } else if(entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c != null){
                bundlePrices.put(productId, 'adjustment');
                System.debug('bundlePrices: ' + bundlePrices);
                Decimal adjustmentValue = entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c;
                String adjustmentMethod = entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__AdjustmentMethod__c;
                System.debug('adjustmentValue: ' + adjustmentValue);
                System.debug('adjustmentMethod: ' + adjustmentMethod);

                if(adjustmentMethod == 'Absolute'){
                    // Traer el Pricing Element Amount del PLE que no tiene Adjustment Value del mismo producto
                    List<vlocity_cmt__PriceListEntry__c> matchingEntries = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c = :frequency WITH SECURITY_ENFORCED LIMIT 1 ];
                    if(matchingEntries.size() > 0){
                        // Añadir el descuento correspondiente al plan
                        if(productType == 'Plan' && productSubtype == 'Postpaid') {
                            if(frequency == 'Mensual con impuestos'){
                                accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                mobilePlanPriceWithTax += adjustmentValue; // adjustmentValue es un valor negativo, por lo que se restaría el precio
                            } else if(frequency == 'Monthly'){
                                accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                mobilePlanPriceWithoutTax += adjustmentValue;
                            }
                            // Añadir el descuento correspondiente al paquete adicional
                        } else {
                            if(frequency == 'Mensual con impuestos'){
                                accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                addOnPriceWithTax += adjustmentValue; // adjustmentValue es un valor negativo, por lo que se restaría el precio
                            } else if(frequency == 'Monthly'){
                                accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                addOnPriceWithoutTax += adjustmentValue;
                            }
                        }
                    }
                } else if(adjustmentMethod == 'Percent'){
                    List<vlocity_cmt__PriceListEntry__c> matchingEntries = [SELECT vlocity_cmt__PricingElementAmount__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c = :frequency WITH SECURITY_ENFORCED LIMIT 1];
                    if(matchingEntries.size() > 0){
                        Decimal basePrice = matchingEntries[0].vlocity_cmt__PricingElementAmount__c;
                        Decimal discountPercentage = adjustmentValue/100; // Pasar a decimal
                        Decimal discountPrice = basePrice * (discountPercentage); // Aplicar descuento de porcentaje
                        System.debug('basePrice: ' + basePrice);
                        System.debug('discountPercentage: ' + discountPercentage);
                        System.debug('discountPrice: ' + discountPrice);

                        // Añadir el descuento al valor existente en el mapa
                        // Añadir el descuento correspondiente al plan
                        if(productType == 'Plan' && productSubtype == 'Postpaid') {
                            if(frequency == 'Mensual con impuestos'){
                                accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                mobilePlanPriceWithTax += (-discountPrice);
                            } else if(frequency == 'Monthly'){
                                accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                mobilePlanPriceWithoutTax += (-discountPrice);
                            }
                            // Añadir el descuento correspondiente al paquete adicional
                        } else {
                            if(frequency == 'Mensual con impuestos'){
                                accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                addOnPriceWithTax += (-discountPrice);
                            } else if(frequency == 'Monthly'){
                                accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                                addOnPriceWithoutTax += (-discountPrice);
                            }
                        }
                    }
                }
            } else{
                // Si la entrada de precio no es ni tipo override, ni tipo adjustment, entonces solamente procesar la cantidad del price list entry (ple)
                // Si el tipo de producto es Plan y su subtipo Postpaid, se guarda su variable en sus campos correspondientes
                if(productType == 'Plan' && productSubtype == 'Postpaid') {
                    if(frequency == 'Mensual con impuestos') {
                        mobilePlanPriceWithTax += entry.vlocity_cmt__PricingElementAmount__c;
                    } else if(frequency == 'Monthly'){
                        mobilePlanPriceWithoutTax += entry.vlocity_cmt__PricingElementAmount__c;
                    }
                } else {
                    bundlePrices.put(productId, 'ple');
                    System.debug('bundlePrices: '+bundlePrices);
                    System.debug('entry.vlocity_cmt__PricingElementAmount__c: '+entry.vlocity_cmt__PricingElementAmount__c);

                    // Acumular precios en sus respectivas categorías (con/sin impuestos)
                    if(frequency == 'Mensual con impuestos') {
                        accumulatePrices(priceWithTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                        addOnPriceWithTax += entry.vlocity_cmt__PricingElementAmount__c;
                    } else if(frequency == 'Monthly'){
                        addOnPriceWithoutTax += entry.vlocity_cmt__PricingElementAmount__c;
                        accumulatePrices(priceWithoutTaxMap, productId, entry.vlocity_cmt__PricingElementAmount__c);
                    }
                }
            }
            System.debug('entry.vlocity_cmt__IsOverride__c:' + entry.vlocity_cmt__IsOverride__c);
            System.debug('entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c:' + entry.vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c);
            System.debug('bundlePrices:' + bundlePrices);
            //System.debug('processedProductIds:' + processedProductIds);
        }

        System.debug('priceWithTaxMap:' + priceWithTaxMap);
        System.debug('priceWithoutTaxMap:' + priceWithoutTaxMap);
        System.debug('addOnPriceWithTax:' + addOnPriceWithTax);
        System.debug('addOnPriceWithoutTax:' + addOnPriceWithoutTax);
        
        // Crear la lista que se va a regresar al flujo
        List<List<Decimal>> totalPrices = new List<List<Decimal>>();
        totalPrices.add(new List<Decimal>{addOnPriceWithTax, addOnPriceWithoutTax, mobilePlanPriceWithTax, mobilePlanPriceWithoutTax});
        System.debug('totalPrices:' + totalPrices);

        return totalPrices;
    }

    // Método de ayuda para acumular los precios en el mapa
    public static void accumulatePrices(Map<Id, Decimal> priceMap, Id productId, Decimal price) {
        if (priceMap.containsKey(productId)) {
            // Si el producto ya está en el mapa, añadir los precios existentes
            priceMap.put(productId, priceMap.get(productId) + price);
        } else {
            // Inicializar el precio para el producto
            priceMap.put(productId, price);
        }
    }
}