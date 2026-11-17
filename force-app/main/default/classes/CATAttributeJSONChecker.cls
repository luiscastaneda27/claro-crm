/*--------------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class for Checking Attr JSON Field in Decomposition Relationship records
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
11-Mar-25         Josue Pineda                                  inicial version
----------------------------------------------------------------------------------*/
public class CATAttributeJSONChecker {
    // Wrapper class for Input
    public class Request {
        @InvocableVariable(label='Decomposition Relationship Records' description='Records containing mapping data' required=true)
        public List<SObject> records;

        @InvocableVariable(label='Search Attribute Code' description='The attribute code to search for in the JSON' required=true)
        public String searchAttr;
    }

    // Output wrapper class for Flow
    public class Response {
        @InvocableVariable(label='Destination Attribute Code' description='The destination attribute code found in the JSON')
        public String destinationAttrCode;

        @InvocableVariable(label='Record ID' description='The Record ID associated with the found attribute code')
        public String recordId;

        @InvocableVariable(label='Is Attribute Found' description='True if the search attribute was found in any record')
        public Boolean isAttributeFound;
    }

    // Invocable method for Flow
    @InvocableMethod(label='Check Attributes in JSON' description='Searches for a specific attribute in JSON and returns the destination attribute code and record ID')
    public static List<Response> checkJSONAttributes(List<Request> requests) {
        List<Response> responses = new List<Response>(); // Store matched results

        for (Request req : requests) {
            // Loop through all records inside the request
            for (SObject sobj : req.records) {
                // Typecast the generic SObject to vlocity_cmt__DecompositionRelationship__c
                vlocity_cmt__DecompositionRelationship__c record = (vlocity_cmt__DecompositionRelationship__c) sobj;

                String mappingsData = record.vlocity_cmt__MappingsData__c;
                System.debug(mappingsData);
                String recordId = record.vlocity_cmt__DestinationProductId__c;  // Adjust if needed
                System.debug(recordId);
                String searchAttr = req.searchAttr; 
                System.debug(searchAttr);

                // Parse JSON
                List<Object> rawList;
                rawList = (List<Object>) JSON.deserializeUntyped(mappingsData); 


                // Convert List<Object> to List<Map<String, Object>> 
                List<Map<String, Object>> attributes = new List<Map<String, Object>>();
                for (Object obj : rawList) {
                    if (obj instanceof Map<String, Object>) {
                        attributes.add((Map<String, Object>) obj);
                    }
                }

                for (Map<String, Object> attribute : attributes) {
                    if (attribute.containsKey('source_attr_code') && attribute.get('source_attr_code') == searchAttr) {
                        String destinationAttrCode = (String) attribute.get('destination_attr_code');
                        System.debug('Found attribute code ' + destinationAttrCode + ' in JSON' + mappingsData);
                        Response res = new Response();
                        res.destinationAttrCode = destinationAttrCode;
                        res.recordId = recordId;
                        res.isAttributeFound = true;
                        responses.add(res);
                        System.debug('Added to responses: ' + res);
                        break; // Stop searching after first match in this JSON
                    }
                }
            }
        }
        // If the attribute was never found, return at least one response with isAttributeFound = false
        if (responses.isEmpty()) {
            Response res = new Response();
            res.isAttributeFound = false;
            responses.add(res);
        }
        return responses; // Return the list of responses to Flow
    }
}