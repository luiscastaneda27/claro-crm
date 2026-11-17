/**
 * @class       PVU_TyDCanvasController
 * @description Controlador Visualforce para la página PVU_TyDCanvas.
 *              Construye la URL de redirección hacia la aplicación TyD
 *              a partir del número de línea del caso y del endpoint configurado en el
 *              Custom Metadata PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt, filtrando por el
 *              ambiente de Salesforce activo (sandbox o producción).
 *
 * @author      Claro Colombia - PV Cloudy
 * @date        2026-02-09
 * @bug         755401
 *
 * @see         PVU_TyDCanvas (Visualforce Page)
 * @see         PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt (Custom Metadata)
 */
public with sharing class PVU_TyDCanvasController {

    /** URL final construida para redirigir a la aplicación TyD. */
    public String finalUrl {get; set;}

    /** Mensaje de error mostrado en la página cuando el proceso falla. */
    public String errorMessage {get; set;}

    /**
     * @description Constructor del controlador. Obtiene el número de línea del caso,
     *              resuelve el endpoint TyD desde el Custom Metadata del ambiente actual
     *              y construye la URL de redirección.
     * @param       stdController Controlador estándar de Visualforce con el contexto del Case.
     */
    public PVU_TyDCanvasController(ApexPages.StandardController stdController) {
        try {
            if (stdController.getId() == null) {
                throw new TyDException('No se encontró el registro del caso.');
            }

            Case currentCase = [SELECT PVU_NumeroLinea__c FROM Case WHERE Id = :stdController.getId() WITH USER_MODE LIMIT 1];

            if (String.isBlank(currentCase.PVU_NumeroLinea__c)) {
                throw new TyDException('El caso no tiene número de línea configurado.');
            }

            // Resolver nombre del ambiente desde el dominio de la org
            System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            String sandboxName = d.getSandboxName();
            if (String.isBlank(sandboxName)) {
                sandboxName = 'prod';
            }
            if (Test.isRunningTest()) {
                // En tests no existe sandbox real; se usa un nombre que garantiza metadata ausente
                sandboxName = 'sandboxNoExist';
            }

            // Sanitizar parámetro dinámico para evitar XSS e inyección en la URL
            String escapedLine = EncodingUtil.urlEncode(currentCase.PVU_NumeroLinea__c, 'UTF-8');

            // Obtener configuración del endpoint TyD para el ambiente actual
            PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt config = PVU_Codigo_Ambiente_Claro_ADA_SGA__mdt.getInstance(sandboxName);

            if (config == null || String.isBlank(config.PVU_URL_TyD_Application__c)) {
                throw new TyDException('Error de Configuración: No se encontró el endpoint de TyD en los metadatos para este ambiente. Contactar al administrador');
            }

            this.finalUrl = config.PVU_URL_TyD_Application__c + '?lineNumber=' + escapedLine;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PVU_TyDCanvasController error: ' + e.getTypeName() + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString());
            this.errorMessage = e.getMessage();
            this.finalUrl = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.errorMessage));
        }
    }

    /**
     * @description Ejecuta la redirección hacia la URL de la aplicación TyD.
     *              Si ocurrió un error en el constructor, retorna null para que
     *              la página permanezca y muestre el mensaje de error.
     * @return      PageReference con la URL de TyD, o null si hubo un error previo.
     */
    public PageReference redirectToTyD() {
        if (String.isBlank(this.finalUrl)) {
            return null;
        }
        PageReference pr = new PageReference(this.finalUrl);
        pr.setRedirect(true);
        return pr;
    }

    /**
     * @description Excepción personalizada para errores de negocio internos del controlador
     *              (configuración ausente, datos faltantes en el caso, etc.).
     */
    public class TyDException extends Exception {}

}