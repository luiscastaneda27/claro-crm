/*--------------------------------------------------------------------------------
Author:         Fernanda Maldonado - mmaldonado@salesforce.com
Company:        Salesforce.com
Description:    Class for updating/adding/deleting attributes from an Asset JSON
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
15-Jan-25         Fernanda Maldonado                             inicial version
----------------------------------------------------------------------------------*/

public class CATUpdateAttributeAsset {

    // Clase para guardar la info del flujo
    public class AssetData{
        @InvocableVariable
        public String assetId;

        @InvocableVariable
        public String attributeSelectedValuesJson;

        @InvocableVariable
        public String attributeMetadataChangesJson;

        @InvocableVariable
        public String attrCode;

        @InvocableVariable
        public String attrValue;

        @InvocableVariable
        public String action;
    }


    // Clase para guardar los assetIds exitosos y fallidos
    public class resultadoAssetsProcesados{
        @InvocableVariable
        public List<String> successfullAssetIds = new List<String>();
        @InvocableVariable
        public List<String> failedAssetIds = new List<String>();
    }

    // Procesar los assets y regresar su estado
    @InvocableMethod
    public static List<resultadoAssetsProcesados> CATUpdateAttributeAsset(List<AssetData> asset) {
        System.debug('--- asset: ' + asset);

        resultadoAssetsProcesados result = new resultadoAssetsProcesados();

        Set<String> successfullAssetIdsSet = new Set<String>();
        Set<String> failedAssetIdsSet = new Set<String>();

        for(AssetData assetData : asset) {
            // Extraer información del asset
            String assetId = assetData.assetId;
            System.debug('--- assetId: ' + assetId);
            String attributeSelectedValuesJson = assetData.attributeSelectedValuesJson;
            String attributeMetadataChangesJson = assetData.attributeMetadataChangesJson;
            String attrCode = assetData.attrCode;
            String attrValue = assetData.attrValue;
            String action = assetData.action;

            Asset assetToUpdate = new Asset(id = assetId);

            // Lógica para attributeSelectedValuesJson
            if(String.isNotBlank(attributeSelectedValuesJson)){
                Map<String, Object> attributeSelectedValues = (Map<String, Object>) JSON.deserializeUntyped(attributeSelectedValuesJson);
                if(action == 'Actualizar'){
                    if(attributeSelectedValues.containsKey(attrCode)){
                        // Actualizar el valor del atributo
                        attributeSelectedValues.put(attrCode, attrValue);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' no existe en el asset ' + assetId + '.');
                        failedAssetIdsSet.add(assetId);
                    }
                } else if(action == 'Añadir'){
                    if(!attributeSelectedValues.containsKey(attrCode)){
                        // Añadir el código y valor del atributo
                        attributeSelectedValues.put(attrCode, attrValue);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' ya existe en el asset ' + assetId + '.');
                        failedAssetIdsSet.add(assetId);
                    }
                } else if(action == 'Borrar'){
                    if(attributeSelectedValues.containsKey(attrCode)){
                        // Eliminar el atributo
                        attributeSelectedValues.remove(attrCode);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' no existe en el asset ' + assetId + '. Verifique que el código sea el correcto.');
                        failedAssetIdsSet.add(assetId);
                    }
                }
                assetToUpdate.vlocity_cmt__AttributeSelectedValues__c = JSON.serialize(attributeSelectedValues);
            }

            // Lógica para attributeMetadataChangesJson
            if(String.isNotBlank(attributeMetadataChangesJson)){
                Map<String, Object> attributeMetadataChanges = (Map<String, Object>) JSON.deserializeUntyped(attributeMetadataChangesJson);
                if(action == 'Actualizar'){
                    if(attributeMetadataChanges.containsKey(attrCode)){
                        // Actualizar el valor del atributo
                        attributeMetadataChanges.put(attrCode, attrValue);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' no existe en el asset ' + assetId + '.');
                        failedAssetIdsSet.add(assetId);
                    }
                } else if(action == 'Añadir'){
                    if(!attributeMetadataChanges.containsKey(attrCode)){
                        // Añadir el código y valor del atributo
                        attributeMetadataChanges.put(attrCode, attrValue);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' ya existe en el asset ' + assetId + '.');
                        failedAssetIdsSet.add(assetId);
                    }
                } else if(action == 'Borrar'){
                    if(attributeMetadataChanges.containsKey(attrCode)){
                        // Eliminar el atributo
                        attributeMetadataChanges.remove(attrCode);
                        successfullAssetIdsSet.add(assetId);
                    }
                    else{
                        System.debug('--- ERROR: El atributo ' + attrCode + ' no existe en el asset ' + assetId + '. Verifique que el código sea el correcto.');
                        failedAssetIdsSet.add(assetId);
                    }
                }
                assetToUpdate.vlocity_cmt__AttributeMetadataChanges__c = JSON.serialize(attributeMetadataChanges);
            }

            // Actualizar el asset
            update as user assetToUpdate;
        }
        // Convertir los conjuntos a listas
        result.successfullAssetIds = new List<String>(successfullAssetIdsSet);
        result.failedAssetIds = new List<String>(failedAssetIdsSet);

        System.debug('--- result.successfullAssetIds: ' + result.successfullAssetIds);
        System.debug('--- result.failedAssetIds: ' + result.failedAssetIds);

        return new List<resultadoAssetsProcesados> {result};
    }
}