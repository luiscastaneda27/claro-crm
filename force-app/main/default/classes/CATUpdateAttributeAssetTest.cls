@IsTest
public class CATUpdateAttributeAssetTest {
    @IsTest
    public static void testActualizarAttributeAsset(){

        // Crear datos de prueba

        Account testAccount = new Account(
            Name = 'Test Account',
            vlocity_cmt__Status__c = 'Active',
            BillingStreet = 'Calle 123 # 45 - 67',
            BillingCity = 'Bogotá D.C',
            BillingState = 'Bogotá D.C',
            BillingCountry = 'Colombia',
            FVU_ServiceDaneCode__c = '88001'
        );
        insert testAccount;

        Product2 prod1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'TEST-PROD1',
            Family = 'Mobile',
            vlocity_cmt__Type__c = 'Plan',
            vlocity_cmt__SubType__c = 'Postpaid'
        );
        insert prod1;


        Asset asset1 = new Asset(
            Name = 'Test Asset 1',
            AccountId = testAccount.Id,
            Product2Id = prod1.Id
        );
        insert asset1;

        Asset asset2 = new Asset(
            Name = 'Test Asset 2',
            AccountId = testAccount.Id,
            Product2Id = prod1.Id
        );
        insert asset2;

        Asset asset3 = new Asset(
            Name = 'Test Asset 3',
            AccountId = testAccount.Id,
            Product2Id = prod1.Id
        );
        insert asset3;

        // Caso exitoso: Actualizar un atributo existente en AttributeSelectedValues
        CATUpdateAttributeAsset.AssetData updateAsset1Data = new CATUpdateAttributeAsset.AssetData();
        updateAsset1Data.assetId = asset1.Id;
        updateAsset1Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        updateAsset1Data.attrCode = 'attr1';
        updateAsset1Data.attrValue = 'newValue1';
        updateAsset1Data.action = 'Actualizar';

        // Caso exitoso: Añadir un nuevo atributo en AttributeSelectedValues
        CATUpdateAttributeAsset.AssetData addAsset1Data = new CATUpdateAttributeAsset.AssetData();
        addAsset1Data.assetId = asset1.Id;
        addAsset1Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        addAsset1Data.attrCode = 'attr3';
        addAsset1Data.attrValue = 'newValue3';
        addAsset1Data.action = 'Añadir';

        // Caso exitoso: Borrar un atributo existente en AttributeSelectedValues
        CATUpdateAttributeAsset.AssetData deleteAsset1Data = new CATUpdateAttributeAsset.AssetData();
        deleteAsset1Data.assetId = asset1.Id;
        deleteAsset1Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        deleteAsset1Data.attrCode = 'attr2';
        deleteAsset1Data.action = 'Borrar';

        // Caso exitoso: Actualizar un atributo existente en attributeMetadataChangesJson
        CATUpdateAttributeAsset.AssetData updateAsset2Data = new CATUpdateAttributeAsset.AssetData();
        updateAsset2Data.assetId = asset2.Id;
        updateAsset2Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2","attr3":"value3","attr4":"value4"}';
        updateAsset2Data.attrCode = 'attr3';
        updateAsset2Data.attrValue = 'newValue3';
        updateAsset2Data.action = 'Actualizar';

        // Caso exitoso: Añadir un nuevo atributo en attributeMetadataChangesJson
        CATUpdateAttributeAsset.AssetData addAsset2Data = new CATUpdateAttributeAsset.AssetData();
        addAsset2Data.assetId = asset2.Id;
        addAsset2Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2","attr3":"value3","attr4":"value4"}';
        addAsset2Data.attrCode = 'attr5';
        addAsset2Data.attrValue = 'newValue5';
        addAsset2Data.action = 'Añadir';

        // Caso exitoso: Borrar un atributo existente en attributeMetadataChangesJson
        CATUpdateAttributeAsset.AssetData deleteAsset2Data = new CATUpdateAttributeAsset.AssetData();
        deleteAsset2Data.assetId = asset2.Id;
        deleteAsset2Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2","attr3":"value3","attr4":"value4"}';
        deleteAsset2Data.attrCode = 'attr1';
        deleteAsset2Data.action = 'Borrar';

        // Caso fallido: Actualizar un atributo inexistente
        CATUpdateAttributeAsset.AssetData failedUpdateAsset3Data = new CATUpdateAttributeAsset.AssetData();
        failedUpdateAsset3Data.assetId = asset3.Id;
        failedUpdateAsset3Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        failedUpdateAsset3Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2"}';
        failedUpdateAsset3Data.attrCode = 'attr3';
        failedUpdateAsset3Data.attrValue = 'newValue3';
        failedUpdateAsset3Data.action = 'Actualizar';

        // Caso fallido: Añadir un atributo existente
        CATUpdateAttributeAsset.AssetData failedAddAsset3Data = new CATUpdateAttributeAsset.AssetData();
        failedAddAsset3Data.assetId = asset3.Id;
        failedAddAsset3Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        failedAddAsset3Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2"}';
        failedAddAsset3Data.attrCode = 'attr1';
        failedAddAsset3Data.attrValue = 'value1';
        failedAddAsset3Data.action = 'Añadir';

        // Caso fallido: Borrar un atributo inexistente
        CATUpdateAttributeAsset.AssetData failedDeleteAsset3Data = new CATUpdateAttributeAsset.AssetData();
        failedDeleteAsset3Data.assetId = asset2.Id;
        failedDeleteAsset3Data.attributeSelectedValuesJson = '{"attr1":"value1","attr2":"value2"}';
        failedDeleteAsset3Data.attributeMetadataChangesJson = '{"attr1":"value1","attr2":"value2"}';
        failedDeleteAsset3Data.attrCode = 'attr4';
        failedDeleteAsset3Data.attrValue = 'value4';
        failedDeleteAsset3Data.action = 'Borrar';

        // Ejecutar método
        Test.startTest();
        List<CATUpdateAttributeAsset.AssetData> assetDataList = new List<CATUpdateAttributeAsset.AssetData>{updateAsset1Data, addAsset1Data, deleteAsset1Data, updateAsset2Data, addAsset2Data, deleteAsset2Data, failedUpdateAsset3Data, failedAddAsset3Data, failedDeleteAsset3Data};
        List<CATUpdateAttributeAsset.resultadoAssetsProcesados> results = CATUpdateAttributeAsset.CATUpdateAttributeAsset(assetDataList);

        // Verificar que los AssetIds se hayan agregado a la lista de éxitos
        List<String> successfullAssetIds = results[0].successfullAssetIds;

        // Verificar que las actualizaciones se hayan realizado correctamente
        Asset updatedAsset1 = [SELECT vlocity_cmt__AttributeSelectedValues__c FROM Asset WHERE Id = :asset1.Id];
        Asset updatedAsset2 = [SELECT vlocity_cmt__AttributeSelectedValues__c FROM Asset WHERE Id = :asset2.Id];
        Asset updatedAsset3 = [SELECT vlocity_cmt__AttributeSelectedValues__c FROM Asset WHERE Id = :asset3.Id];
    }
}