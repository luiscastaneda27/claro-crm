// Invokes Einstein Prompt Template via Connect API, gets response/citations, transforms citations. Part of AI Agentforce Viki.
public class KnowledgeBaseApex {

    // Test method for debugging execute().
    public static void test() {
        AI_Agentforce_Configs__mdt config = AI_Agentforce_Configs__mdt.getInstance('AI_Viki_Config');
        String value = config?.AI_Call_Center_Retriever_API_Name__c;
        execute('Can you explain what is an LLM?', value);
    }

    @TestVisible
    private static ConnectApi.EinsteinPromptTemplateGenerationsRepresentation testMockResponse;

    // Calls 'Knowledge_Search' Prompt Template via Connect API, gets raw response/citations.
    public static ConnectApi.EinsteinPromptTemplateGenerationsRepresentation execute(String query, String retrieverIdOrName) {        
        ConnectApi.WrappedValue inputText = new ConnectApi.WrappedValue();
        ConnectApi.WrappedValue inputRetriever = new ConnectApi.WrappedValue();
        inputText.value = query;
        inputRetriever.value = retrieverIdOrName;
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        // NOTE: 'Input:Question' must match the Prompt Template input variable API name.
        inputParams.put('Input:Query', inputText);
        inputParams.put('Input:RetrieverIdOrName', inputRetriever);

        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.citationMode = 'post_generation';
        executeTemplateInput.inputParams = inputParams;

        if (Test.isRunningTest() && testMockResponse != null) {
            return testMockResponse;
        }

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
            'einstein_gpt__answerWithKnowledge', // Developer Name of the Prompt Template
            executeTemplateInput
        );

        return generationsOutput;
    }

    // Helper methods to transform Connect API citations to AI Copilot format.

    // Transforms a single Connect API source reference to AiCopilot format.
    public static AiCopilot.GenAiSourceReference transform(ConnectApi.EinsteinLlmGenAiSourceReference sourceRef) {
        List<AiCopilot.GenAiSourceContentInfo> contents = new List<AiCopilot.GenAiSourceContentInfo>();
        for (ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo contentInfo : sourceRef.contents) {
            contents.add(new AiCopilot.GenAiSourceContentInfo(contentInfo.fieldName, contentInfo.objectName, contentInfo.content));
        }

        List<AiCopilot.GenAiSourceReferenceInfo> metadata = new List<AiCopilot.GenAiSourceReferenceInfo>();
        for (ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo referenceInfo : sourceRef.metadata) {
            metadata.add(new AiCopilot.GenAiSourceReferenceInfo(referenceInfo.link, referenceInfo.sourceObjectRecordId, referenceInfo.sourceObjectApiName));
        }

        return new AiCopilot.GenAiSourceReference(null, contents, metadata);
    }

    // Transforms the overall Connect API citation block to AiCopilot format.
    public static AiCopilot.GenAiCitationInput transform(ConnectApi.EinsteinLlmGenerationCitationOutput citations) {
        List<AiCopilot.GenAiSourceReference> sourceRefs = new List<AiCopilot.GenAiSourceReference>();
        if (citations != null && citations.sourceReferences != null) {
            for (ConnectApi.EinsteinLlmGenAiSourceReference source : citations.sourceReferences) {
                sourceRefs.add(transform(source));
            }
        }
        return new AiCopilot.GenAiCitationInput(null, sourceRefs);
    }

    // Defines input (Request) and output (Response) structures for the Invocable Method.
    public class Request {
        @InvocableVariable(required=true description='Complete user question')
        public String Question;

        @InvocableVariable(required=true description='Complete retriever Id or Name')
        public String Retriever;
    }

    public class Response {
        @InvocableVariable(required=true description='Generated text response from the LLM')
        public String Data;

        @InvocableVariable(required=true description='Structured citation sources')
        public AiCopilot.GenAiCitationInput sources;
    }

    // @InvocableMethod for Flows: gets question, calls execute, transforms citations, returns results.
    @InvocableMethod(label='Call Knowledge Prompt Apex' description='Invokes the Knowledge Search prompt template and returns the response with citations.')
    public static List<Response> executePrompt(List<Request> requests) {
        String question = requests[0].Question;
        String retriver = requests[0].Retriever;
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = execute(question, retriver);

        List<Response> responses = new List<Response>();
        Response response = new Response();
        ConnectApi.EinsteinLlmGenerationItemOutput generationItemOutput = output.generations[0];
        response.Data = generationItemOutput.text;
        response.sources = transform(output.citations);
        responses.add(response);

        return responses;
    }
}