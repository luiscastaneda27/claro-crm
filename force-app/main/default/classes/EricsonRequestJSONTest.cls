@isTest
public class EricsonRequestJSONTest {

    @isTest
    static void testParse() {
        // Cenário 1: JSON válido
        String validJson = '{"orderType":"ProductOfferingOrder","createdDate":"2023-03-07T14:40:48.894Z","description":"ORDMD282406","requestedStartDate":"2023-03-07T14:40:48.894Z","orderSpecification":{},"relatedParties":[],"correlationID":"1678200050","run":true,"relatedEntities":[],"version":0,"orderItems":[],"requestedCompletionDate":"2023-03-11T14:40:48.894Z","orderSpec":{},"attrs":[]}';

        EricsonRequestJSON ericsonRequest = EricsonRequestJSON.parse(validJson);
        System.assertNotEquals(null, ericsonRequest, 'O objeto não deve ser nulo');
        System.assertEquals('ProductOfferingOrder', ericsonRequest.orderType);
        System.assertEquals('2023-03-07T14:40:48.894Z', ericsonRequest.createdDate);
        System.assertEquals('ORDMD282406', ericsonRequest.description);

        // Cenário 2: JSON inválido
        String invalidJson = '{ "invalidField": "invalidValue" }';
        try {
            ericsonRequest = EricsonRequestJSON.parse(invalidJson);
        } catch (Exception e) {
            // Exceção esperada para JSON inválido
            System.assertEquals('System.JSONException', e.getTypeName());
        }

        // Cenário 3: Cobertura para cls_relatedParties
        String jsonWithRelatedParties = '{"orderType":"ProductOfferingOrder","relatedParties":[{"reference":"93000000000181","role":"Customer","party":{"CustomerInformation":{"attributes":[{"name":"MARKET","value":"GSM"}]}}}], "correlationID":"1678200050","run":true}';
        ericsonRequest = EricsonRequestJSON.parse(jsonWithRelatedParties);
        System.assertNotEquals(null, ericsonRequest, 'O objeto não deve ser nulo');
        System.assertEquals('Customer', ericsonRequest.relatedParties[0].role);

        // Cenário 4: Cobertura para cls_relatedEntities
        String jsonWithRelatedEntities = '{"orderType":"ProductOfferingOrder","relatedEntities":[{"type":"Contract","id":"ContractId","reference":"CONTR0000","entity":{"name":"EntityName"}}]}';
        ericsonRequest = EricsonRequestJSON.parse(jsonWithRelatedEntities);
        System.assertNotEquals(null, ericsonRequest, 'O objeto não deve ser nulo');
        System.assertEquals('Contract', ericsonRequest.relatedEntities[0].type);

        // Adicione mais cenários e mocks conforme necessário

    }

    // Outros métodos de teste...
}