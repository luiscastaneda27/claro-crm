/*-----------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Creates TSV file with ProductInfo
Code Coverage:  100%
History
<Date>            <Author>             <Description>                        <Version>
10-Feb-25         Fernanda Maldonado    Creates TSV file with ProductInfo   1
------------------------------------------------------------------------------------------*/

public class CATDeviceProductTSVExporter {

    @InvocableMethod
    public static List<Id> generateDeviceHandsetProductTSV(List<List<Id>> productIdsList) {
        List<Id> results = new List<Id>();

        List<String> attributeOrder = new List<String>{
            'Cantidad Max Permitida por cliente', 'Garantía', 'ID Material', 'Límite UVT Impuesto', 'Marca', 'Modelo', 'Muerto en Caja', 'Producto Aplica Financiación'
        };

        // Para cada lista de productIds proporcionada
        for (List<Id> productIds : productIdsList) {
            if (productIds.isEmpty()) {
                System.debug('No hay IDs de producto provenientes del flujo.');
            }

            // 1. Obtener información de productos
            Map<Id, List<String>> productDataMap = new Map<Id, List<String>>();
            String prodDescription = '';
            String prodShortDescription = '';
            for (Product2 p : [
                SELECT Id, Name, ProductCode, Description, Family, 
                       Short_Description__c, vlocity_cmt__Type__c, vlocity_cmt__SubType__c,vlocity_cmt__ProductSpecName__c, vlocity_cmt__SpecificationType__c, vlocity_cmt__SpecificationSubType__c, vlocity_cmt__IsOrderable__c
                FROM Product2
                WHERE Id IN :productIds WITH USER_MODE
            ]) {
                System.debug('--- p.Description: ' + p.Description);
                System.debug('--- p.Short_Description__c: ' + p.Short_Description__c);
                if(p.Description != null){
                    prodDescription = p.Description.escapeCsv();
                } else{
                    prodDescription = p.Description;
                }
                if(p.Short_Description__c != null){
                    prodShortDescription = p.Short_Description__c.escapeCsv();
                } else{
                    prodShortDescription = p.Short_Description__c;
                }
                System.debug('--- prodDescription: ' + prodDescription);
                System.debug('--- prodShortDescription: ' + prodShortDescription);
                productDataMap.put(p.Id, new List<String>{
                    p.Id, p.Name, p.ProductCode, prodDescription, prodShortDescription, 
                    p.Family, p.vlocity_cmt__Type__c, p.vlocity_cmt__SubType__c, p.vlocity_cmt__ProductSpecName__c, p.vlocity_cmt__SpecificationType__c, p.vlocity_cmt__SpecificationSubType__c, String.valueOf(p.vlocity_cmt__IsOrderable__c)
                });
            }
            System.debug('--- productDataMap: ' + productDataMap);

            // 2. Obtener información de los atributos
            Map<Id, Map<String, String>> attrDataMap = new Map<Id, Map<String, String>>();
            for (vlocity_cmt__AttributeAssignment__c attr : [
                SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__AttributeId__r.Name, vlocity_cmt__Value__c FROM vlocity_cmt__AttributeAssignment__c WHERE vlocity_cmt__ObjectId__c IN :productIds AND vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c IN ('B2C-ATTR-MATERIAL-TERM', 'B2C-ATTR-GARANTIA-TERM', 'B2C-ATTR-EXC-IMP-TERM', 'B2C-ATTR-CANT-COMPRA-PERMITIDA', 'B2C-ATTR-TEC-DOA', 'B2C-ATTR-FINANC-TERM', 'B2C-ATTR-MARCA-TERM', 'B2C-ATTR-MODELO-TERM') WITH USER_MODE ORDER BY vlocity_cmt__AttributeId__r.Name
            ]) {
                if (!attrDataMap.containsKey(attr.vlocity_cmt__ObjectId__c)) {
                    attrDataMap.put(attr.vlocity_cmt__ObjectId__c, new Map<String, String>());
                }
                attrDataMap.get(attr.vlocity_cmt__ObjectId__c).put(attr.vlocity_cmt__AttributeId__r.Name, attr.vlocity_cmt__Value__c);
            }

            // 3. Obtener información de reglas (RuleInfo)
            Map<Id, List<String>> ruleDataMap = new Map<Id, List<String>>();
            for (vlocity_cmt__RuleAssignment__c rule : [
                SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__RuleId__r.Name, vlocity_cmt__RuleId__r.vlocity_cmt__Description__c
                FROM vlocity_cmt__RuleAssignment__c
                WHERE vlocity_cmt__ObjectId__c IN :productIds WITH USER_MODE
            ]) {
                ruleDataMap.put(rule.vlocity_cmt__ObjectId__c, new List<String>{rule.vlocity_cmt__RuleId__r.Name, rule.vlocity_cmt__RuleId__r.vlocity_cmt__Description__c});
            }
            System.debug('--- ruleDataMap: ' + ruleDataMap);

            // 4. Obtener precios SIN impuestos
            Map<Id, List<String>> priceWithoutTaxMap = new Map<Id, List<String>>();
            for (vlocity_cmt__PriceListEntry__c entry : [
                SELECT vlocity_cmt__ProductId__c, vlocity_cmt__DisplayText__c, vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c,
                       vlocity_cmt__PricingElementAmount__c, vlocity_cmt__EffectiveFromDate__c
                FROM vlocity_cmt__PriceListEntry__c
                WHERE vlocity_cmt__IsActive__c = true 
                  AND vlocity_cmt__IsBasePrice__c = true 
                  AND vlocity_cmt__EffectiveUntilDate__c = null 
                  AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null 
                  AND vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__Code__c = 'OT_STD_PRC'
                  AND vlocity_cmt__ProductId__c IN :productIds WITH USER_MODE
            ]) {
                if (!priceWithoutTaxMap.containsKey(entry.vlocity_cmt__ProductId__c)) {
                    priceWithoutTaxMap.put(entry.vlocity_cmt__ProductId__c, new List<String>());
                }
                
                List<String> priceList = priceWithoutTaxMap.get(entry.vlocity_cmt__ProductId__c);
                priceList.add(entry.vlocity_cmt__DisplayText__c);
                priceList.add(entry.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c);
                priceList.add(String.valueOf(entry.vlocity_cmt__PricingElementAmount__c));
                priceList.add(String.valueOf(entry.vlocity_cmt__EffectiveFromDate__c));
            }
            System.debug('--- priceWithoutTaxMap: ' + priceWithoutTaxMap);

            // 5. Construcción del tsv
            String tsvContent = 'Id\tNombre\tCódigo Producto\tDescripción\tDescripción Corta\tFamilia\tTipo\tSubtipo\tNombre Especificación del Producto (PS)\tTipo de Especificación\tSubtipo de Especificación\tEs Ordenable\t' + String.join(attributeOrder, '\t') + '\tNombre Regla\tDescripción Regla\tNombre Precio Sin Impuestos\tCódigo PriceList\tPrecio Sin Impuestos\tFecha de Inicio Precio Sin Impuestos\tNombre Precio Sin Impuestos\tCódigo PriceList\tPrecio Sin Impuestos\tFecha de Inicio Precio Sin Impuestos\tNombre Precio Sin Impuestos\tCódigo PriceList\tPrecio Sin Impuestos\tFecha de Inicio Precio Sin Impuestos\n';
            System.debug('--- tsvContent: ' + tsvContent);

            for (Id productId : productIds) {
                // Verificar si los datos existen en los mapas, si no, se asignan valores predeterminados
                List<String> productRow = new List<String>{'','','','','','','','','','','','','',''};
                if(productDataMap.containsKey(productId)){
                    productRow = productDataMap.get(productId);
                }
                // Crear una lista vacía con la cantidad correcta de columnas
                List<String> attrRow = new List<String>(new String[attributeOrder.size()]);
                for (Integer i = 0; i < attrRow.size(); i++) {
                    attrRow[i] = ''; // Llenar con valores vacíos por defecto
                }
                // Rellenar la fila con los valores correctos de atributos
                if (attrDataMap.containsKey(productId)) {
                    Map<String, String> productAttributes = attrDataMap.get(productId);
                    for (Integer i = 0; i < attributeOrder.size(); i++) {
                        String attributeName = attributeOrder[i];
                        if (productAttributes.containsKey(attributeName)) {
                            attrRow[i] = productAttributes.get(attributeName);
                        }
                    }
                }
                List<String> ruleRow = new List<String>{'',''};
                if(ruleDataMap.containsKey(productId)){
                    ruleRow = ruleDataMap.get(productId);
                }
                List<String> priceWithoutTaxRow = new List<String>{'','',''};
                if(priceWithoutTaxMap.containsKey(productId)){
                    priceWithoutTaxRow = priceWithoutTaxMap.get(productId);
                }

                // Concatenación de cadenas
                tsvContent += String.join(productRow, '\t') + '\t' + String.join(attrRow, '\t') + '\t' + String.join(ruleRow, '\t') + '\t' + String.join(priceWithoutTaxRow, '\t') + '\n';
            }
            System.debug('--- tsvContent: ' + tsvContent);

            // 6. Creación de ContentVersion
            ContentVersion tsv = new ContentVersion();
            tsv.Title = 'ProductInfo-Terminales.tsv';
            tsv.PathOnClient = 'ProductInfo-Terminales.tsv';
            tsv.VersionData = Blob.valueOf(tsvContent);
            tsv.IsMajorVersion = true;
            insert as user tsv;

            results.add(tsv.Id);
        }

        return results;
    }
}