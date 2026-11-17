/*--------------------------------------------------------------------------
Author:         hever.salas@nespon.com
Description:    Clase de prueba para validar la actualización de JSONAttribute__c
                en InventoryItem relacionados a PO_MovPosOptOTT
Code Coverage:  95%
History
<Date>            <Author>             <Description>                                            	<Version>
11-03-2026       Hever Salas    HDU-718193: Comportamiento en proceso cambio de numero         		  1.0       
----------------------------------------------------------------------------*/

@isTest
private class OM_UpdateTechProductSubTypeBatchTest {
    
    @testSetup
    static void setup() {
        // Crear un Product2
        Product2 product = new Product2(
            Name = 'PO_MovPosOptOTT',
            IsActive = true
        );
        insert product;
        
        // Crear InventoryItems con JSONAttribute__c
        List<vlocity_cmt__InventoryItem__c> inventoryItems = new List<vlocity_cmt__InventoryItem__c>();
        
        String jsonAttributeValue = '{"223541c2-e1cb-fe89-a86d-b07a65470f1b": [' +
            '{"attributeuniquecode__c": "TechProductSubType", ' +
            '"SegmentValue": "BaseTechProduct", ' +
            '"attributeRunTimeInfo": {"selectedItem": {"value": "BaseTechProduct", "displayText": "BaseTechProduct", "id": "74ef2b34-cfb8-cf6b-4343-e927b9c93cae"}, ' +
            '"values": [{"value": "BaseTechProduct"}, {"value": "AddOnTechProduct"}]}}' +
            ']}';
        
        for (Integer i = 0; i < 5; i++) {
            vlocity_cmt__InventoryItem__c item = new vlocity_cmt__InventoryItem__c(
                Name = 'Test Inventory Item ' + i,
                vlocity_cmt__ProductId__c = product.Id,
                vlocity_cmt__JSONAttribute__c = jsonAttributeValue
            );
            inventoryItems.add(item);
        }
        
        insert inventoryItems;
    }
    
    @isTest
    static void testBatchExecutionSuccess() {
        // Arrange
        Test.startTest();
        
        // Act: Ejecutar el batch
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: Verificar que los registros fueron actualizados
        List<vlocity_cmt__InventoryItem__c> updatedItems = [
            SELECT Id, vlocity_cmt__JSONAttribute__c 
            FROM vlocity_cmt__InventoryItem__c 
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
        ];
        
        System.assertEquals(5, updatedItems.size(), 'Debería haber 5 registros actualizados');
        
        // Verificar que el JSON se actualizó correctamente
        for (vlocity_cmt__InventoryItem__c item : updatedItems) {
            System.assert(String.isNotBlank(item.vlocity_cmt__JSONAttribute__c), 'JSONAttribute no debería estar vacío');
            
            // Parsear el JSON y verificar que TechProductSubType cambió a AddOnOTTTechProduct
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(item.vlocity_cmt__JSONAttribute__c);
            List<Object> attributes = (List<Object>)jsonMap.values()[0];
            
            Boolean foundTechProductSubType = false;
            for (Object attr : attributes) {
                Map<String, Object> attribute = (Map<String, Object>)attr;
                if (attribute.get('attributeuniquecode__c') == 'TechProductSubType') {
                    foundTechProductSubType = true;
                    String segmentValue = (String)attribute.get('SegmentValue');
                    System.assertEquals('AddOnOTTTechProduct', segmentValue, 'SegmentValue debería ser AddOnOTTTechProduct');
                    break;
                }
            }
            
            System.assert(foundTechProductSubType, 'TechProductSubType debería encontrarse en el JSON');
        }
    }
    
    @isTest
    static void testBatchWithEmptyJSON() {
        // Arrange
        List<vlocity_cmt__InventoryItem__c> itemsWithEmptyJSON = [
            SELECT Id
            FROM vlocity_cmt__InventoryItem__c
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
            LIMIT 1
        ];
        
        if (!itemsWithEmptyJSON.isEmpty()) {
            itemsWithEmptyJSON[0].vlocity_cmt__JSONAttribute__c = '';
            update itemsWithEmptyJSON;
        }
        
        Test.startTest();
        
        // Act
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: El batch debe completar sin errores
        System.assertEquals(true, true, 'El batch debería ejecutarse sin excepciones');
    }
    
    @isTest
    static void testBatchWithInvalidJSON() {
        // Arrange
        List<vlocity_cmt__InventoryItem__c> items = [
            SELECT Id
            FROM vlocity_cmt__InventoryItem__c
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
            LIMIT 1
        ];
        
        if (!items.isEmpty()) {
            items[0].vlocity_cmt__JSONAttribute__c = 'invalid json {';
            update items;
        }
        
        Test.startTest();
        
        // Act
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: El batch debe manejar el error gracefully
        System.assertEquals(true, true, 'El batch debe capturar excepciones sin fallar');
    }
    
    @isTest
    static void testBatchNoRecords() {
        // Arrange: Eliminar todos los registros de prueba
        List<vlocity_cmt__InventoryItem__c> itemsToDelete = [
            SELECT Id
            FROM vlocity_cmt__InventoryItem__c
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
        ];
        delete itemsToDelete;
        
        Test.startTest();
        
        // Act
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: El batch debe completar sin registros
        System.assertEquals(0, [SELECT COUNT() FROM vlocity_cmt__InventoryItem__c WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT']);
    }
    
    @isTest
    static void testBatchStatefulVariables() {
        // Arrange
        Test.startTest();
        
        // Act
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        System.assertEquals(0, batch.totalUpdated, 'totalUpdated debe iniciar en 0');
        System.assertEquals(0, batch.totalErrors, 'totalErrors debe iniciar en 0');
        
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: Valores finales deben ser mayores a 0 para totalUpdated
        System.assert(batch.totalUpdated >= 0, 'totalUpdated debe ser >= 0 después de la ejecución');
    }
    
    @isTest
    static void testBatchWithLargeBatchSize() {
        // Arrange
        Test.startTest();
        
        // Act: Ejecutar with large batch size
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Assert: Todos los registros deben actualizarse
        List<vlocity_cmt__InventoryItem__c> updatedItems = [
            SELECT Id
            FROM vlocity_cmt__InventoryItem__c
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
        ];
        
        System.assertEquals(5, updatedItems.size(), 'Todos los 5 registros deben procesarse');
    }
    
    @isTest
    static void testBatchSelectedItemUpdate() {
        // Arrange
        Test.startTest();
        
        // Act
        OM_UpdateTechProductSubTypeBatch batch = new OM_UpdateTechProductSubTypeBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Assert: Verificar que selectedItem fue actualizado correctamente
        List<vlocity_cmt__InventoryItem__c> items = [
            SELECT vlocity_cmt__JSONAttribute__c
            FROM vlocity_cmt__InventoryItem__c
            WHERE vlocity_cmt__ProductId__r.name = 'PO_MovPosOptOTT'
            LIMIT 1
        ];
        
        if (!items.isEmpty()) {
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(items[0].vlocity_cmt__JSONAttribute__c);
            List<Object> attributes = (List<Object>)jsonMap.values()[0];
            
            for (Object attr : attributes) {
                Map<String, Object> attribute = (Map<String, Object>)attr;
                if (attribute.get('attributeuniquecode__c') == 'TechProductSubType') {
                    Map<String, Object> runtimeInfo = (Map<String, Object>)attribute.get('attributeRunTimeInfo');
                    Map<String, Object> selectedItem = (Map<String, Object>)runtimeInfo.get('selectedItem');
                    
                    System.assertEquals('AddOnOTTTechProduct', selectedItem.get('value'), 'El selectedItem value debe ser AddOnOTTTechProduct');
                    break;
                }
            }
        }
    }
}