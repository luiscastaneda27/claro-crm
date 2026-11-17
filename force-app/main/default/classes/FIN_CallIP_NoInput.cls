/**
 * @description      Clase que llama un Integration Procedure sin parámetros de entrada.
 *                   Diseñada para usarse desde Flows/Vlocity sin inputs.
 * @author           ezequiel.olivera@nespon.com           
 * @date             2025-12-11
 */
global class FIN_CallIP_NoInput { // NOPMD: AvoidGlobalModifier - requerido por Vlocity


    /**
     * @description Hook interno para test: permite inyectar mocks de IP.
     */
    @TestVisible private static IntegrationProcedureMock ipMock;

    /**
     * @description Interfaz usada en tests para simular la ejecución de un Integration Procedure.
     */
    // NOPMD: ApexDoc - requerido por Vlocity, la interfaz debe ser global
    global interface IntegrationProcedureMock {
        /**
         * @description Ejecuta un IP mockeado.
         * @param procedureName  Nombre del Integration Procedure
         * @param inputMap       Mapa de entrada (vacío)
         * @param options        Opciones adicionales
         * @return Mapa con la respuesta simulada
         */
        Map<String, Object> run(String procedureName, Map<String, Object> inputMap, Map<String, Object> options);
    }

    /**
     * @description Método invocable para llamar un IP sin inputs.
     * @param requests Lista de requests con procedureName
     * @return Lista de resultados serializados
     */
    @InvocableMethod(
        label='Call Integration Procedure (No Input)' 
        description='Llama un Integration Procedure sin parámetros de entrada.'
        category='General'
    )
    public static List<IPResult> callIP(List<IPWrapper> requests) {

        List<IPResult> results = new List<IPResult>();

        for (IPWrapper req : requests) {
            if (String.isBlank(req.procedureName)) {
                IPResult errorRes = new IPResult();
                errorRes.result = '{"error": "procedureName is required"}';
                results.add(errorRes);
                continue;
            }

            Map<String, Object> inputMap = new Map<String, Object>();
            Map<String, Object> options = new Map<String, Object>();

            Map<String, Object> output = runIntegrationProcedure(req.procedureName, inputMap, options);

            IPResult r = new IPResult();
            r.result = JSON.serialize(output);

            results.add(r);
        }

        return results;
    }

    /**
     * @description Wrapper para ejecutar un Integration Procedure real o mockeado.
     *              En test usa el mock, en producción ejecuta el servicio real.
     * @param procedureName Nombre del IP
     * @param inputMap      Inputs (vacíos)
     * @param options       Opciones
     * @return Resultado del IP
     */
    private static Map<String, Object> runIntegrationProcedure(
        String procedureName,
        Map<String, Object> inputMap,
        Map<String, Object> options
    ) {
      

        try {
            
            if (Test.isRunningTest() && ipMock != null) {
                return ipMock.run(procedureName, inputMap, options);
            }
            return (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                procedureName, inputMap, options
            );
        } catch (Exception ex) {
            Map<String, Object> err = new Map<String, Object>();
            err.put('error', ex.getMessage());
            return err;
        }
    }

    /**
     * @description Wrapper de entrada requerido por InvocableMethod.
     */
    // NOPMD: ApexDoc - requerido por Vlocity
    global class IPWrapper {
        @InvocableVariable(required=true)
        public String procedureName;
    }

    /**
     * @description Resultado Devuelto al Flow/OmniScript.
     */
    // NOPMD: ApexDoc - requerido por Vlocity
    global class IPResult {
        @InvocableVariable
        public String result;
    }

    /**
     * @description Limpia el mock en test (opcional).
     */
    @TestVisible static void clearMockForTest() {
        ipMock = null;
    }
}