/*-----------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Creates TSV file with ProductRelationshipInfo
Code Coverage:  100%
History
<Date>            <Author>             <Description>                        <Version>
10-Feb-25         Fernanda Maldonado    Creates TSV file with ProductInfo   1
------------------------------------------------------------------------------------------*/

public class CATProductRelationshipTSVExporter {

    @InvocableMethod
    public static List<Id> generateProductRelationshipTSV(List<List<Id>> productChildItemList) {
        List<Id> results = new List<Id>();

        // Para cada lista de productChildItemIds proporcionada
        for (List<Id> productChildItemIds : productChildItemList) {
            if (productChildItemIds.isEmpty()) {
                System.debug('No hay IDs de producto provenientes del flujo.');
            }

            // 1. Obtener información de productos
            Map<Id, List<String>> productDataMap = new Map<Id, List<String>>();
            for (vlocity_cmt__ProductChildItem__c p : [
                SELECT Id, vlocity_cmt__ParentProductName__c, 
                       vlocity_cmt__ParentProductId__r.ProductCode, 
                       vlocity_cmt__ChildProductName__c, 
                       vlocity_cmt__ChildProductId__r.ProductCode, 
                       vlocity_cmt__ChildLineNumber__c,
                       vlocity_cmt__ChildProductId__r.vlocity_cmt__ProductSpecName__c, 
                       vlocity_cmt__ChildProductId__r.vlocity_cmt__ProductSpecId__r.ProductCode 
                FROM vlocity_cmt__ProductChildItem__c
                WHERE Id IN :productChildItemIds WITH USER_MODE
            ]) {
                productDataMap.put(p.Id, new List<String>{
                    p.vlocity_cmt__ParentProductName__c, p.vlocity_cmt__ParentProductId__r.ProductCode, p.vlocity_cmt__ChildProductName__c, p.vlocity_cmt__ChildProductId__r.ProductCode, p.vlocity_cmt__ChildLineNumber__c, p.vlocity_cmt__ChildProductId__r.vlocity_cmt__ProductSpecName__c, p.vlocity_cmt__ChildProductId__r.vlocity_cmt__ProductSpecId__r.ProductCode
                });
            }
            System.debug('--- productDataMap: ' + productDataMap);

            // 5. Construcción del tsv
            String tsvContent = 'Nombre Producto Padre\tCódigo Producto Padre\tNombre Producto Hijo\tCódigo Producto Hijo\tCardinalidad Hijo\tPS del Producto Hijo\tCódigo PS\n';
            System.debug('--- tsvContent: ' + tsvContent);

            for (Id productChildItemId : productChildItemIds) {
                // Verificar si los datos existen en los mapas, si no, se asignan valores predeterminados
                List<String> productRow = new List<String>{'','','','',''};
                if(productDataMap.containsKey(productChildItemId)){
                    productRow = productDataMap.get(productChildItemId);
                }
                // Concatenación de cadenas
                tsvContent += String.join(productRow, '\t') + '\n';
            }
            System.debug('--- tsvContent: ' + tsvContent);

            // 6. Creación de ContentVersion
            ContentVersion tsv = new ContentVersion();
            tsv.Title = 'ProductRelationshipInfo.tsv';
            tsv.PathOnClient = 'ProductRelationshipInfo.tsv';
            tsv.VersionData = Blob.valueOf(tsvContent);
            tsv.IsMajorVersion = true;
            insert as user tsv;

            results.add(tsv.Id);
        }

        return results;
    }
}