/**
 * @description Clase de pruebas para FIN_CallIP_NoInput. Valida escenarios de éxito, error y mock.
 */
@IsTest
private class FIN_CallIP_NoInputTest {

    /**
     * @description Mock de éxito para simular una ejecución correcta del Integration Procedure.
     */
    private class MockSuccess implements FIN_CallIP_NoInput.IntegrationProcedureMock {

        /**
         * @description Implementación mock del método run que retorna una respuesta exitosa.
         * @param procedureName Nombre del Integration Procedure.
         * @param inputMap Mapa de entrada recibido por el procedimiento.
         * @param options Opciones adicionales enviadas en la llamada.
         * @return Mapa simulando la respuesta exitosa del Integration Procedure.
         */
        public Map<String, Object> run(
            String procedureName,
            Map<String, Object> inputMap,
            Map<String, Object> options
        ) {
            return new Map<String, Object>{
                'status' => 'OK',
                'procedure' => procedureName
            };
        }
    }

    /**
     * @description Mock que lanza una excepción para validar el bloque catch del método principal.
     */
    private class MockThrows implements FIN_CallIP_NoInput.IntegrationProcedureMock {

        /**
         * @description Implementación mock del método run que lanza una excepción simulada.
         * @param p Nombre del Integration Procedure.
         * @param i Mapa de entrada simulado.
         * @param o Opciones adicionales.
         * @return Mapa (no retorna porque lanza excepción).
         * @throws CalloutException Excepción simulada para probar el catch.
         */
        public Map<String, Object> run(
            String p,
            Map<String, Object> i,
            Map<String, Object> o
        ) {
            throw new CalloutException('IP exploded');
        }
    }

    /**
     * @description Test: ejecución exitosa del mock.
     */
    @IsTest
    static void testSuccessFlow() {
        FIN_CallIP_NoInput.ipMock = new MockSuccess();

        FIN_CallIP_NoInput.IPWrapper wrap = new FIN_CallIP_NoInput.IPWrapper();
        wrap.procedureName = 'IP_Test';

        Test.startTest();
        List<FIN_CallIP_NoInput.IPResult> res =
            FIN_CallIP_NoInput.callIP(
                new List<FIN_CallIP_NoInput.IPWrapper>{ wrap }
            );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Debe retornar una respuesta');
        System.assert(res[0].result.contains('OK'), 'Debe contener OK');
        System.assert(res[0].result.contains('IP_Test'), 'Debe contener el nombre del IP');

        FIN_CallIP_NoInput.clearMockForTest();
    }

    /**
     * @description Test: procedureName faltante debe retornar un error.
     */
    @IsTest
    static void testMissingProcedureName() {
        FIN_CallIP_NoInput.IPWrapper wrap = new FIN_CallIP_NoInput.IPWrapper();
        wrap.procedureName = null;

        Test.startTest();
        List<FIN_CallIP_NoInput.IPResult> res =
            FIN_CallIP_NoInput.callIP(
                new List<FIN_CallIP_NoInput.IPWrapper>{ wrap }
            );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Debe devolver un resultado');
        System.assert(
            res[0].result.contains('procedureName is required'),
            'Debe marcar error por nombre faltante'
        );
    }

    /**
     * @description Test: mock que lanza excepción para cubrir el catch.
     */
    @IsTest
    static void testExceptionInIp() {
        FIN_CallIP_NoInput.ipMock = new MockThrows();

        FIN_CallIP_NoInput.IPWrapper wrap = new FIN_CallIP_NoInput.IPWrapper();
        wrap.procedureName = 'IP_Broken';

        Test.startTest();
        List<FIN_CallIP_NoInput.IPResult> res =
            FIN_CallIP_NoInput.callIP(
                new List<FIN_CallIP_NoInput.IPWrapper>{ wrap }
            );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Debe retornar un resultado');
        System.assert(
            res[0].result.contains('IP exploded'),
            'Debe capturar la excepción lanzada por el mock'
        );

        FIN_CallIP_NoInput.clearMockForTest();
    }

    /**
     * @description Test: clearMock debe poner ipMock en null.
     */
    @IsTest
    static void testClearMock() {
        FIN_CallIP_NoInput.ipMock = new MockSuccess();
        FIN_CallIP_NoInput.clearMockForTest();
        System.assertEquals(null, FIN_CallIP_NoInput.ipMock, 'El mock debe limpiarse');
    }
}