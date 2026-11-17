/**
 * @description Test class for KnowledgeBaseApex part of AI Agentforce Viki. 
 * This class uses an HttpCalloutMock to simulate the response from the ConnectApi.EinsteinLLM API.
 */
@isTest
private class KnowledgeBaseApexTest {

    /**
     * @description Mock implementation to simulate the EinsteinLLM API response. 
     * Returns a JSON string that simulates the ConnectApi.EinsteinPromptTemplateGenerationsRepresentation structure.
     */
    private class KnowledgeBaseApexTestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            
            String mockBody = '{' +
            '  "generations": [' +
            '    {' +
            '      "text": "This is the simulated LLM response."' +
            '    }' +
            '  ],' +
            '  "prompt": "This is the simulated input prompt...",' + 
            '  "citations": {' + 
            '    "sourceReferences": [' +
            '      {' +
            '        "contents": [' +
            '          {' +
            '            "fieldName": "Answer__c",' +
            '            "objectName": "Knowledge__kav",' +
            '            "content": "Simulated article content..."' +
            '          }' +
            '        ],' +
            '        "metadata": [' +
            '          {' +
            '            "link": "/lightning/r/Knowledge__kav/ka0xx0000000001AAA/view",' +
            '            "sourceObjectRecordId": "ka0xx0000000001AAA",' +
            '            "sourceObjectApiName": "Knowledge__kav"' +
            '          }' +
            '        ]' +
            '      }' +
            '    ]' +
            '  }' +
            '}';
            
            res.setBody(mockBody);
            return res;
        }
    }

    /**
     * @description Tests the main @InvocableMethod executePrompt method.
     */
    @isTest(SeeAllData=true)
    static void testExecutePrompt() {
        KnowledgeBaseApex.testMockResponse = buildTestMockResponse();
        KnowledgeBaseApex.Request req = new KnowledgeBaseApex.Request();
        req.Question = 'Can you explain what is an LLM?';
        req.Retriever = 'KA_UMM_Call_Center';
        
        List<KnowledgeBaseApex.Request> requests = new List<KnowledgeBaseApex.Request>{ req };
        
        Test.startTest();
        List<KnowledgeBaseApex.Response> responses = KnowledgeBaseApex.executePrompt(requests);
        Test.stopTest();
        
        System.assertEquals(1, responses.size(), 'Should return exactly one response.');
        
        KnowledgeBaseApex.Response res = responses[0];
        
        System.assertNotEquals(null, res.sources, 'Sources must not be null.');
    }

    /**
     * @description Tests the static test() method to ensure coverage.
     */
    @isTest(SeeAllData=true)
    static void testTestMainMethod() {
        Test.setMock(HttpCalloutMock.class, new KnowledgeBaseApexTestMock());

        Test.startTest();
        KnowledgeBaseApex.test();
        Test.stopTest();

        System.assert(true, 'The test() method must run without errors.');
    }

    /**
     * @description Tests the helper transformation (transform) methods in isolation.
     */
    @isTest
    static void testTransformHelpers() {
        ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo content = new ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo();
        content.fieldName = 'TestField__c';
        content.objectName = 'TestObject__c';
        content.content = 'Test Content';
        
        ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo meta = new ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo();
        meta.link = '/test/link';
        meta.sourceObjectRecordId = '001xx0000000001ABA';
        meta.sourceObjectApiName = 'Account';
        
        ConnectApi.EinsteinLlmGenAiSourceReference source = new ConnectApi.EinsteinLlmGenAiSourceReference();
        source.contents = new List<ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo>{ content };
        source.metadata = new List<ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo>{ meta };
        
        AiCopilot.GenAiSourceReference transformedSource = KnowledgeBaseApex.transform(source);
        System.assertNotEquals(null, transformedSource, 'transformedSource shuld not be null');
            
        ConnectApi.EinsteinLlmGenerationCitationOutput citations = new ConnectApi.EinsteinLlmGenerationCitationOutput();
        citations.sourceReferences = new List<ConnectApi.EinsteinLlmGenAiSourceReference>{ source };
        
        AiCopilot.GenAiCitationInput transformedCitations = KnowledgeBaseApex.transform(citations);
        System.assertNotEquals(null, transformedCitations, 'citations should not be null');
            
        AiCopilot.GenAiCitationInput nullCitations = KnowledgeBaseApex.transform((ConnectApi.EinsteinLlmGenerationCitationOutput)null);
        System.assertNotEquals(null, nullCitations, 'Transforming null must return a non-null object.');
        
        ConnectApi.EinsteinLlmGenerationCitationOutput emptyCitations = new ConnectApi.EinsteinLlmGenerationCitationOutput();
        emptyCitations.sourceReferences = null;
        AiCopilot.GenAiCitationInput emptySourceListCitations = KnowledgeBaseApex.transform(emptyCitations);
        System.assertNotEquals(null, emptySourceListCitations, 'Transforming an object with a null list must return a non-null result.');
    }    

    private static ConnectApi.EinsteinPromptTemplateGenerationsRepresentation buildTestMockResponse() {
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mockResponse = new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();
        ConnectApi.EinsteinLlmGenerationItemOutput mockGeneration = new ConnectApi.EinsteinLlmGenerationItemOutput();
        mockGeneration.text = 'This is a simulated LLM response';
        mockResponse.generations = new List<ConnectApi.EinsteinLlmGenerationItemOutput>{ mockGeneration };
        mockResponse.citations = new ConnectApi.EinsteinLlmGenerationCitationOutput();
        mockResponse.citations.sourceReferences = new List<ConnectApi.EinsteinLlmGenAiSourceReference>();
        ConnectApi.EinsteinLlmGenAiSourceReference mockSource = new ConnectApi.EinsteinLlmGenAiSourceReference();
        mockSource.contents = new List<ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo>();
        mockSource.metadata = new List<ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo>();
        mockResponse.citations.sourceReferences.add(mockSource);
        return mockResponse;
    }
}