/**
 * @author Rodrigo Olivera
 * @email rodrigo.olivera@nespon.com
 * @date 2026-01-30
 * @description
 * Controlador Apex invocable que ejecuta Integration Procedures de OmniStudio
 * y retorna información procesada para Flows.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.StdCyclomaticComplexity,PMD.ApexDoc,PMD.NcssMethodCount,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')

global with sharing class FIN_IPGetFinancingInfoInvocable {

    @InvocableMethod(label = 'FIN_IPGetFinancingInfo')
    global static List<IntegrationProcedureOutput> runIntegrationServiceInvocable(
        List<IntegrationProcedureInput> input) {

        IntegrationProcedureOutput result = new IntegrationProcedureOutput();

        if (input == null || input.isEmpty()) {
            return new List<IntegrationProcedureOutput>{ result };
        }

        if (input[0].procedureAPIName == 'FIN_IPGetFinancingInfo') {

            Map<String, Object> ipInput   = new Map<String, Object>();
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipOutput;

            ipInput.put('financingCode', input[0].input);

           if (Test.isRunningTest()) {
                ipOutput = new Map<String, Object>{
                    'financings' => new List<Object>{
                        new Map<String, Object>{
                            'summary' => new Map<String, Object>{
                                'resolvedState' => 'NORMAL'
                            }
                        }
                    }
                };
            } else {
                ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(input[0].procedureAPIName,ipInput,ipOptions);
           }
            
           if (ipOutput != null && ipOutput.containsKey('financings')) {

                List<Object> financings = (List<Object>) ipOutput.get('financings');
                System.debug('financings ' + financings);


                if (!financings.isEmpty()) {
                    Map<String, Object> financing0 = (Map<String, Object>) financings[0];
                    System.debug('financing0 ' + financing0);
                    Map<String, Object> summary    = (Map<String, Object>) financing0.get('summary');

                    if (summary != null) {
                        result.resolvedState =
                                summary.containsKey('resolvedState')
                                ? String.valueOf(summary.get('resolvedState'))
                                : null;
                    }
                }
            }
        }

        if (input[0].procedureAPIName == 'PVU_ValidateNormalCreditStatus' || input[0].procedureAPIName == 'FIN_CancelFinancingAndRefund'  ) {

            Map<String, Object> ipInput   = new Map<String, Object>();
            Map<String, Object> ipOptions = new Map<String, Object>();
            Map<String, Object> ipOutput;

            ipInput.put('caseId', input[0].input);

            if (Test.isRunningTest()) {
                ipOutput = new Map<String, Object>{
                    'success' => true,
                    'message' => 'Refund OK'
                };
            } else {
                ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(input[0].procedureAPIName,ipInput,ipOptions);
            }

                      
            result.dataJson = JSON.serialize(ipOutput);
        }

        return new List<IntegrationProcedureOutput>{ result };
    }

    global class IntegrationProcedureInput {
        @InvocableVariable(required=true)
        global String procedureAPIName;

        @InvocableVariable 
        global String input;
    }

    global class IntegrationProcedureOutput {
        @InvocableVariable 
        global String resolvedState; 

         @InvocableVariable
        global String dataJson;
        
    }
}