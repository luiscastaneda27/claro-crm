/*-----------------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Creates TSV file with AttributeInfo
Code Coverage:  100%
History
<Date>            <Author>             <Description>                          <Version>
10-Feb-25         Fernanda Maldonado    Creates TSV file with AttributeInfo   1
------------------------------------------------------------------------------------------*/

public class CATAttributeTSVExporter {

    @InvocableMethod
    public static List<Id> generateAttrTSV(List<List<Id>> productIdsList) {
        List<Id> results = new List<Id>();

        // Definir el orden esperado de los atributos en la tabla
        List<String> attributeOrder = new List<String>{
            'Barring Roaming Internacional Postpago', 'Bloqueo Roaming Internacional Postpago GPT', 'Cabify',
            'Claro Drive', 'Claro música gratis', 'Claro música premium', 'Claro video', 'Código Split', 'Datos',
            'Datos para compartir', 'Facebook', 'Familia y Amigos', 'Fecha Activación', 'Fecha Desactivación',
            'Indefinido', 'Instagram', 'LDI Otros Destinos Hispanoamérica', 'LDI Otros Destinos Resto del Mundo',
            'Límite Nacional Paquetes', 'Límite Nacional Servicios', 'Límite Roaming', 'Minutos LDI', 'Move Time',
            'Paquetes Compatibles', 'Process Details', 'Red Social X', 'Relevo', 'Roaming CAN', 'Service_Id',
            'Servicio Roaming Internacional Postpago', 'SMS a Claro', 'SMS LD Nacional', 'Taxis Libres',
            'Technical Details', 'Tipo de Plan', 'Valor del KB Adicional', 'Voz LD Nacional', 'Waze', 'WhatsApp'
        };
        
        // Para cada lista de productIds proporcionada
        for (List<Id> productIds : productIdsList) {
            if (productIds.isEmpty()) {
                System.debug('No hay IDs de producto provenientes del flujo.');
            }

            // 1. Obtener información de productos
            Map<Id, String> productDataMap = new Map<Id, String>();
            Set<Id> internetMovilPlanIds = new Set<Id>();
            for (Product2 p : [
                SELECT Name, vlocity_cmt__ProductSpecId__r.ProductCode
                FROM Product2
                WHERE Id IN :productIds WITH USER_MODE
            ]) {
                productDataMap.put(p.Id, p.Name);

                // Identificar si el producto es un "Plan Internet Móvil PS"
                if (p.vlocity_cmt__ProductSpecId__r.ProductCode == 'B2C-MOV-PLAN-INTERNET-PS') {
                    internetMovilPlanIds.add(p.Id);
                }
            }

            // 2. Obtener información de los atributos
            Map<Id, Map<String, String>> attrDataMap = new Map<Id, Map<String, String>>();
            for (vlocity_cmt__AttributeAssignment__c attr : [
                SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__AttributeId__r.Name, vlocity_cmt__Value__c
                FROM vlocity_cmt__AttributeAssignment__c
                WHERE vlocity_cmt__ObjectId__c IN :productIds WITH USER_MODE
                ORDER BY vlocity_cmt__AttributeId__r.Name
            ]) {
                if (!attrDataMap.containsKey(attr.vlocity_cmt__ObjectId__c)) {
                    attrDataMap.put(attr.vlocity_cmt__ObjectId__c, new Map<String, String>());
                }
                attrDataMap.get(attr.vlocity_cmt__ObjectId__c).put(attr.vlocity_cmt__AttributeId__r.Name, attr.vlocity_cmt__Value__c);
            }

            // 3. Construcción del TSV
            String tsvContent = 'Plan Móvil Nombre\t' + String.join(attributeOrder, '\t') + '\n';

            for (Id productId : productIds) {
                String productName = '';
                if(productDataMap.containsKey(productId)) {
                    productName = productDataMap.get(productId);
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

                // Si el producto es un "Plan Internet Móvil PS", la columna "Familia y Amigos" (índice 12) debe quedar vacía
                Integer colFamAm = 12;
                if (internetMovilPlanIds.contains(productId)) {
                    attrRow[colFamAm] = ' ';
                }

                // Construcción de la fila en el archivo TSV
                tsvContent += productName + '\t' + String.join(attrRow, '\t') + '\n';
            }

            // 4. Creación de ContentVersion
            ContentVersion tsv = new ContentVersion();
            tsv.Title = 'ProductAttributeInfo.tsv';
            tsv.PathOnClient = 'ProductAttributeInfo.tsv';
            tsv.VersionData = Blob.valueOf(tsvContent);
            tsv.IsMajorVersion = true;
            insert as user tsv;

            results.add(tsv.Id);
        }

        return results;
    }
}