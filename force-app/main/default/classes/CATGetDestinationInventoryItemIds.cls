public with sharing class CATGetDestinationInventoryItemIds {
    // Wrapper class for Input
    public class Request {
        @InvocableVariable(label='Asset Ids' description='Records containing mapping data' required=true)
        public List<String> assetIds;

        @InvocableVariable(label='Technical Product Id' description='The attribute code to search for in the JSON' required=true)
        public String techProdId;
    }

    // Invocable method for Flow
    @InvocableMethod(label='Get Inventory Item Ids' description='Searches the InventoryItemsIds which attribute value should be updated')
    public static List<List<String>> inventoryItemIds(List<Request> requests) {
        System.debug('--- requests: ' + JSON.serialize(requests));
        List<List<String>> inventoryItemIds = new List<List<String>>();

        for (Request req : requests) {
            List<String> destinationItemIds = new List<String>();
            List<vlocity_cmt__InventoryItemDecompositionRelationship__c> inventoryItemDecompositionRelationShips = [
                SELECT vlocity_cmt__DestinationInventoryItemId__c 
                FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
                WHERE vlocity_cmt__SourceAssetId__c IN :req.assetIds  
                AND vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__ProductId__c = :req.techProdId
                WITH USER_MODE
            ];
            System.debug('--- inventoryItemDecompositionRelationShips: ' + inventoryItemDecompositionRelationShips);
            System.debug('--- req.assetIds: ' + req.assetIds);

            //esta clase debe devolver la lista de assetIds
            for (vlocity_cmt__InventoryItemDecompositionRelationship__c relation : inventoryItemDecompositionRelationShips) {
                destinationItemIds.add(relation.vlocity_cmt__DestinationInventoryItemId__c);
            }

            if (destinationItemIds.isEmpty()) {
                destinationItemIds.add('No matching records found');
            }

            inventoryItemIds.add(destinationItemIds);
        }

        return inventoryItemIds;
    }
}