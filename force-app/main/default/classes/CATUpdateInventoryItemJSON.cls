/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class for Updating Inventory Items JSON Attribute Field
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
11-Mar-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
public with sharing class CATUpdateInventoryItemJSON {

    // Wrapper class for Input
    public class Request {
        @InvocableVariable(label='Inventory Asset Id' description='Records containing mapping data' required=true)
        public String inventoryAssetId;

        @InvocableVariable(label='Techincal Attribute Code' description='The attribute code to search for in the JSON' required=true)
        public String techAttrCode;

        @InvocableVariable(label='Technical Attribute Value' description='The value to replace the attribute with' required=true)
        public String techAttrValue;
    }

    // Output wrapper class for Flow
    public class Response {
        @InvocableVariable(label='Updated JSON List' description='The modified JSON structure')
        public List<String> updatedJSONList;
    }

    // Invocable method for Flow
    @InvocableMethod(label='Update Inventory Item JSON Attribute' description='Searches for a specific attribute in JSON and updates its value')
    public static List<Response> updateJSONAttribute(List<Request> requests) {
        System.debug('--- requests: ' + JSON.serialize(requests));

        List<Response> responses = new List<Response>();
        List<vlocity_cmt__InventoryItem__c> itemsToUpdate = new List<vlocity_cmt__InventoryItem__c>();
        vlocity_cmt__InventoryItem__c inventoryItem = new vlocity_cmt__InventoryItem__c();

        for (Request req : requests) {
            Response res = new Response();
            res.updatedJSONList = new List<String>();

            /*vlocity_cmt__InventoryItem__c inventoryItem;
            if(String.isNotBlank(req.inventoryAssetId)){
                List<vlocity_cmt__InventoryItem__c> inventoryItems = [
                    SELECT Id, vlocity_cmt__JSONAttribute__c 
                    FROM vlocity_cmt__InventoryItem__c
                    WHERE Id = :req.inventoryAssetId
                    WITH USER_MODE
                ];

                if(!inventoryItems.isEmpty()) {
                    inventoryItem = inventoryItems[0];
                    System.debug('--- inventoryItem: ' + inventoryItem);
                }
            }*/

            List<vlocity_cmt__InventoryItem__c> inventoryItems = [
                SELECT Id, vlocity_cmt__JSONAttribute__c 
                FROM vlocity_cmt__InventoryItem__c
                WHERE Id = :req.inventoryAssetId
                WITH USER_MODE
            ];

            if (!inventoryItems.isEmpty()) {
                inventoryItem = inventoryItems[0];
                System.debug('--- inventoryItem: ' + inventoryItem);
            } else {
                res.updatedJSONList.add('No matching records found');
                responses.add(res);
                continue;
            }

            if (inventoryItem!= null && String.isNotBlank(inventoryItem.vlocity_cmt__JSONAttribute__c)) {
                String jsonString = inventoryItem.vlocity_cmt__JSONAttribute__c;

                Map<String, Object> parsedJSON = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

                Boolean updated = false;
                for (String key : parsedJSON.keySet()) {
                    List<Object> attributes = (List<Object>) parsedJSON.get(key);
                    for (Object obj : attributes) {
                        if (obj instanceof Map<String, Object>) {
                            Map<String, Object> attribute = (Map<String, Object>) obj;
                            if (attribute.containsKey('attributeuniquecode__c') && attribute.get('attributeuniquecode__c') == req.techAttrCode) {
                                // Update value in attributeRunTimeInfo->value and SegmentValue
                                if (attribute.containsKey('attributeRunTimeInfo')) {
                                    Map<String, Object> runtimeInfo = (Map<String, Object>) attribute.get('attributeRunTimeInfo');
                                    runtimeInfo.put('value', req.techAttrValue);
                                    attribute.put('attributeRunTimeInfo', runtimeInfo);
                                }

                                if (attribute.containsKey('SegmentValue')) {
                                    attribute.put('SegmentValue', req.techAttrValue);
                                }

                                updated = true;
                            }
                        }
                    }
                }

                if (updated) {
                    inventoryItem.vlocity_cmt__JSONAttribute__c = JSON.serialize(parsedJSON);
                    itemsToUpdate.add(inventoryItem);
                }

                res.updatedJSONList.add(JSON.serialize(parsedJSON));
            }
            responses.add(res);
        }

        if (!itemsToUpdate.isEmpty()) {
            update as user itemsToUpdate;
        }

        return responses;
    }
}