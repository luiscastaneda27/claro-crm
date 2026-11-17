/**
 * @author Rodrigo Olivera
 * @email rodrigo.olivera@nespon.com
 * @date 2026-01-30
 * @description
 * Clase test del Controlador Apex invocable que ejecuta Integration Procedures de OmniStudio
 * y retorna información procesada para Flows.
 */

@IsTest
public class FIN_IPGetFinancingInfoInvocableTest {

    private static final String MOCK_FINANCING_CODE = 'TEST_FIN_CODE';
    private static final String MOCK_CASE_ID = 'TEST_CASE_ID';

    @IsTest
    static void testGetFinancingInfo() {

        FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput input =
            new FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput();

        input.procedureAPIName = 'FIN_IPGetFinancingInfo';
        input.input = MOCK_FINANCING_CODE;

        Test.startTest();
        List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureOutput> result =
            FIN_IPGetFinancingInfoInvocable.runIntegrationServiceInvocable(
                new List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe retornar un solo elemento');
        System.assertEquals(
            'NORMAL',
            result[0].resolvedState,
            'El resolvedState debe ser NORMAL'
        );
    }

    @IsTest
    static void testRefund() {

        FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput input =
            new FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput();

        input.procedureAPIName = 'PVU_ValidateNormalCreditStatus';
        input.input = MOCK_CASE_ID;

        Test.startTest();
        List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureOutput> result =
            FIN_IPGetFinancingInfoInvocable.runIntegrationServiceInvocable(
                new List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe retornar un solo resultado');
        System.assertNotEquals(
            null,
            result[0].dataJson,
            'El JSON de salida no debe ser null'
        );
        System.assert(
            result[0].dataJson.contains('Refund OK'),
            'El JSON debe contener el mensaje de confirmación'
        );
    }

    @IsTest
    static void testInputVacio() {

        Test.startTest();
        List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureOutput> result =
            FIN_IPGetFinancingInfoInvocable.runIntegrationServiceInvocable(
                new List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput>()
            );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe retornar un resultado vacío');
        System.assertEquals(
            null,
            result[0].resolvedState,
            'resolvedState debe ser null cuando no hay input'
        );
        System.assertEquals(
            null,
            result[0].dataJson,
            'dataJson debe ser null cuando no hay input'
        );
    }

    @IsTest
    static void testProcedureNoSoportado() {

        FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput input =
            new FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput();

        input.procedureAPIName = 'IP_QUE_NO_EXISTE';
        input.input = 'TEST';

        Test.startTest();
        List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureOutput> result =
            FIN_IPGetFinancingInfoInvocable.runIntegrationServiceInvocable(
                new List<FIN_IPGetFinancingInfoInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe retornar un resultado');
        System.assertEquals(
            null,
            result[0].resolvedState,
            'resolvedState debe ser null para IP no soportado'
        );
        System.assertEquals(
            null,
            result[0].dataJson,
            'dataJson debe ser null para IP no soportado'
        );
    }
}