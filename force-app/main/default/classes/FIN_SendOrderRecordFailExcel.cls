/**
 * @description      Clase que envia registros fallidos de fianza
 * @author           ezequiel.olivera@nespon.com
 * @date             2025-12-11
 * @notes            La clase usa 'global' porque Vlocity Open Interface lo requiere.
 */
global with sharing class FIN_SendOrderRecordFailExcel implements vlocity_cmt.VlocityOpenInterface { // NOPMD: AvoidGlobalModifier

    /**
     * @description Método obligatorio de Vlocity para invocar acciones
     * @param methodName nombre del método solicitado desde Vlocity
     * @param inputMap parámetros
     * @param outputMap resultados
     * @param options opciones extra
     * @return true si se ejecutó correctamente, false si no
     */
    global Boolean invokeMethod( // NOPMD: ExcessiveParameterList - requerido por Vlocity
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outputMap,
        Map<String, Object> options
    ) {
        if (methodName == 'enviarExcel') {
            List<Map<String, Object>> orderData =
                (List<Map<String, Object>>) inputMap.get('orderData');

            enviarExcelPorEmail(orderData);
            outputMap.put('status', 'OK');
            outputMap.put('message', 'Email enviado correctamente.');
            return true;
        }

        outputMap.put('status', 'ERROR');
        outputMap.put('message', 'Método no reconocido: ' + methodName);
        return false;
    }

    /**
     * @description Construye y envía por correo el archivo CSV con registros fallidos
     * @param orderData lista de mapas con info
     */
    global static void enviarExcelPorEmail(List<Map<String, Object>> orderData) {
        String csvContent = buildCsv(orderData);
        Blob archivoBlob  = Blob.valueOf(csvContent);

        List<String> correos = obtenerCorreosConfigurados();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(correos);
        email.setSubject('Error Inserción de fianzas en Plataformas');
        email.setPlainTextBody('Adjunto reporte de registros fallidos.\n\nSaludos.');

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('ReporteRegistroFallido.csv');
        attachment.setBody(archivoBlob);
        attachment.setContentType('text/csv');

        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    /**
     * @description Construye el CSV completo en formato TABLA (una fila header + data)
     * @param orderData lista con los registros fallidos
     * @return contenido completo del archivo CSV
     */
    private static String buildCsv(List<Map<String, Object>> orderData) {

        // ÚNICA fila de encabezados
        List<String> headerCols = new List<String>{
            'Tipo de Documento Cliente',
            'Numero Documento Cliente',
            'Cod Dane Municipio Cliente',
            'Numero Credito',
            'ID Simulacion Credito',
            'Valor inicial de Credito',
            'Fecha de Desembolso',
            'Plazo',
            'Score del Cliente',
            'Sigla Afianzador',
            'Tarifa de Fianza Aplicada',
            'Valor Total Fianza',
            'Cuota Mensual Fianza',
            '% IVA Fianza',
            'ID Orden',
            'Numero Contrato',
            'Customer ID',
            'Cuenta Facturacion Principal',
            'Cuenta Facturacion Credito',
            'ID Ciclo',
            'Fecha Corte Ciclo'
        };

        String csvContent = String.join(headerCols, ',') + '\n';

        if (orderData == null || orderData.isEmpty()) {
            return csvContent;
        }

        for (Map<String, Object> item : orderData) {

            List<String> row = new List<String>{
                cell(safeText(item.get('documentType'))),
                cell(safeText(item.get('documentNumber'))),
                cell(safeText(item.get('cityDaneCode'))),

                cell(safeText(item.get('codigoCredito'))),
                cell(safeText(item.get('idSimulacion'))),
                cell(formatMoney(item.get('saldoDiferir'))),
                cell(safeText(item.get('fechaInicioCredito'))),
                cell(safeText(item.get('plazoCredito'))),
                cell(safeText(item.get('calificacionCredito'))),

                cell(safeText(item.get('sigla'))),
                cell(formatTarifaPorMil(item.get('tarifaFianza'))),
                cell(formatMoney(item.get('totalFianza'))),
                cell(formatMoney(item.get('cuotaMensualFianza'))),
                cell(formatPercent(item.get('ivaFianza'))),

                cell(safeText(item.get('idOrder'))),
                cell(safeText(item.get('idContract'))),

                cell(safeText(item.get('customerId'))),
                cell(safeText(item.get('cuentaFacturacionPrincipal'))),
                cell(safeText(item.get('cuentaFacturacionCredito'))),
                cell(safeText(item.get('idCiclo'))),
                cell(safeText(item.get('fechaCorteCiclo')))
            };

            csvContent += String.join(row, ',') + '\n';
        }

        return csvContent;
    }

    /**
     * @description Obtiene la lista de correos configurada en MDT
     * @return lista de direcciones de correo electrónico
     */
    private static List<String> obtenerCorreosConfigurados() {

        if (!Schema.sObjectType.Correos_logs__mdt.isAccessible()) {
            return new List<String>();
        }

        Correos_logs__mdt config = [
            SELECT PVU_Correos_electronicos__c
            FROM Correos_logs__mdt
            WHERE PVU_Nombre_de_la_Integracion__c = 'APIMCMICCusInstallmenAssetMng'
            LIMIT 1
        ];

        List<String> correos = new List<String>();

        if (config != null && String.isNotBlank(config.PVU_Correos_electronicos__c)) {
            for (String c : config.PVU_Correos_electronicos__c.split('\n')) {
                if (c != null && c.trim() != '') {
                    correos.add(c.trim());
                }
            }
        }

        return correos;
    }

    // =========================
    // Helpers de formateo CSV
    // =========================

    /**
     * @description Arma una celda CSV segura:
     *              - Si viene como fórmula tipo ="123", la deja tal cual.
     *              - Si no, la encierra en comillas y escapa comillas internas.
     */
    private static String cell(String value) {
        if (value == null) return '';
        if (value.startsWith('="')) return value; // truco Excel para IDs largos
        return '"' + value.replace('"', '""') + '"';
    }

    /**
     * @description Texto seguro, preserva IDs largos (>=11 dígitos) como ="..."
     */
    private static String safeText(Object val) {
        if (val == null) return '';

        String s = String.valueOf(val).trim();
        if (String.isBlank(s)) return '';

        Integer digitCount = s.replaceAll('\\D', '').length();
        if (digitCount >= 11) {
            return '="' + s + '"';
        }
        return s;
    }

    /**
     * @description Parse flexible LATAM:
     *              "590.900" -> 590900
     *              "0,050"   -> 0.050
     *              "1.234,56"-> 1234.56
     *              "19%"     -> 19
     */
    private static Decimal parseDecimalFlexible(Object val) {
        if (val == null) return null;

        String s = String.valueOf(val).trim();
        if (String.isBlank(s)) return null;

        s = s.replace('%', '').replace(' ', '');

        Boolean hasComma = s.contains(',');
        Boolean hasDot   = s.contains('.');

        if (hasComma && hasDot) {
            s = s.replace('.', '');
            s = s.replace(',', '.');
            return Decimal.valueOf(s);
        }

        if (hasDot && !hasComma) {
            if (Pattern.matches('^-?\\d{1,3}(\\.\\d{3})+$', s)) {
                s = s.replace('.', '');
                return Decimal.valueOf(s);
            }
            return Decimal.valueOf(s);
        }

        if (hasComma && !hasDot) {
            s = s.replace(',', '.');
            return Decimal.valueOf(s);
        }

        return Decimal.valueOf(s);
    }

    /**
     * @description Formato monetario: '$' + miles, sin decimales
     */
    private static String formatMoney(Object val) {
        Decimal d = parseDecimalFlexible(val);
        if (d == null) return '';
        d = d.setScale(0);
        return '$' + d.format();
    }

    /**
     * @description Tarifa de fianza aplicada (como en tu ejemplo):
     *              si llega 0,050 => 0.050 * 1000 = 50
     *
     * Si la querés como % (5%), cambiá *1000 por *100.
     */
    private static String formatTarifaPorMil(Object val) {
        Decimal d = parseDecimalFlexible(val);
        if (d == null) return '';

        if (d < 1) {
            d = d * 1000;
        }
        return d.setScale(0).format();
    }

    /**
     * @description IVA: respeta "19%" si ya viene así; si no, agrega '%'
     */
    private static String formatPercent(Object val) {
        if (val == null) return '';
        String s = String.valueOf(val).trim();
        if (String.isBlank(s)) return '';
        if (s.contains('%')) return s;

        Decimal d = parseDecimalFlexible(val);
        if (d == null) return '';
        return d.setScale(0).format() + '%';
    }

    /**
     * @description Customer ID: usa customerId si viene; si no, cae a cuentaFacturacionPrincipal
     */
    private static Object getCustomerId(Map<String, Object> item) {
        if (item == null) return null;
        if (item.containsKey('customerId') && item.get('customerId') != null) {
            return item.get('customerId');
        }
        return item.get('cuentaFacturacionPrincipal');
    }
}