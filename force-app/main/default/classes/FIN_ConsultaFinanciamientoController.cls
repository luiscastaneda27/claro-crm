/***************************************************************************************************
 * @Class Name          : FIN_ConsultaFinanciamientoController
 * @description         : Contiene los metodos para el componente Consulta de Financiamiento
 * @Author              : Gerardo A. Mendoza
 * @Created date        : 18-october-2024
 * @Modification Log    :
 * Version  Date          Developer             Modification
 * 1.0      18/10/2024    Gerardo A. Mendoza    Initial version
 * 1.1      02/11/2024    Javier A. Esquivel    Se agrega el método integrateAllData para unir los json que se reciben de los servicios
 *                                              BillingManagement, FinancingPaymentTransactions, GetFinancingInfo, FinancingTransactionDetails
 *                                              y enviar la respuesta formateada al IP IPConsultaFinFlexCards. De igual forma se crea el método
 *                                              currency para dar formato de moneda colombiana a los importes recibidos por los servicios.
 * 1.2      8/11/2024     Javier A. Esquivel    Se modifica el método integrateAllData para llamar al método currency y dar formato a los importes
 *                                              de Saldo y Valor. Para el tipo de transaccion de "financiamiento" el campo valor se manda vacío.
 * 1.3      15/11/2024    Ricardo Rodriguez    Se agrega en el método integrateAllData validacion de chargetype del nodo para pagos.
 *
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.AvoidDeeplyNestedIfStmts,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.ClassNamingConventions,PMD.UnusedLocalVariable')
global with sharing class FIN_ConsultaFinanciamientoController implements vlocity_cmt.VlocityOpenInterface2 {

    public static final String NODO_FINANCIAMIENTO = 'financing';
    public static final String NODO_SUMMARY = 'summary';

    public static final String NODO_CREATION_DATE = 'initialDate';

    public static final String RESULT_STRING = 'result';

    public static final Datetime CURRENT_DATETIME = System.today();

    public static final String DATE_TO_VALIDATE_LABEL =
        [SELECT label FROM Fin_Parametros__mdt
         WHERE DeveloperName = 'DateToValidate'
         AND FIN_Flujo__c = 'ConsultaFinanciamientoIP'
         WITH SECURITY_ENFORCED].Label;

    public static final String NODO_TRANSACTION = 'transaction';

    public static final String NODO_REF_DATE = 'refDate';
    public static final String NODO_TRANSACTION_ID = 'id';

    public static final String NODO_OPEN_AMOUNT = 'openAmount';

    public static final String NODO_SUM_AMOUNT = 'sumAmount';

    public static final String NODO_TYPE_TRANSACTION = 'type';

    public static final String TRANSACTION_PAY = 'PAY';

    public static final String TRANSACTION_PAGO = 'Pago';

    public static final String TRANSACTION_ADJ = 'ADJ';

    public static final String TRANSACTION_AJUSTE = 'Ajuste';

    public static final String NODO_PAYMENTS = 'payments';

    public static final String NODO_AMOUNT_DETAILS = 'details';

    public static final String TRANSACTION_FACTURA = 'Factura';
    public static final String TRANSACTION_FINANCIAMIENTO = 'Financiamiento';

    public static final String FINANCIAL_DOC_DATE = 'financialDocDate';
    public static final String FINANCIAL_TOTAL_AMOUNT = 'totalAmount';
    public static final String FINANCIAL_PENDING_AMOUNT = 'pendingAmount';
    public static final String FINANCIAL_BASE_AMOUNT = 'baseAmount';

    public static final String NODO_DET_TRANSACTION_ID = 'id';
    public static final String NODO_DET_FECHA_TRANSACCION = 'fechaTransaccion';
    public static final String NODO_DET_VALOR = 'valor';
    public static final String NODO_DET_VALORSINSIGNO = 'valorSinSigno';
    public static final String NODO_DET_SALDO = 'saldo';
    public static final String NODO_DET_TIPO_TRANSACCION = 'tipoTransaccion';
    public static final String NODO_DET_ENTIDAD = 'entidad';
    public static final String NODO_DET_MEDIO_PAGO = 'medioPago';
    public static final String NODO_DET_NO_TRANSACCION = 'noTransaccion';
    public static final String NODO_DET_CAPITAL = 'capital';
    public static final String NODO_DET_INTERES_CORRIENTES = 'interesCorrientes';
    public static final String NODO_DET_INTERES_MORA = 'interesMora';
    public static final String NODO_DET_IVA_INTERES_MORA = 'ivaInteresMora';
    public static final String NODO_DET_IVA_INTERES_CORRIENTES = 'ivaInteresCorrientes';
    public static final String NODO_FIN_DOC_ID = 'financialDocID';

    public static final String NODO_DET_TIPO_AJUSTE = 'tipoAjuste';
    public static final String NODO_DET_DESCRIPCION_AJUSTE = 'descripcionAjuste';

    public static final String NODO_ID_TRANSACTION = 'id';
    public static final String NODO_CHARGE_TYPE = 'chargeType';
    public static final String NODO_CHARGE_DESC = 'chargeDesc';
    public static final String NODO_AMOUNT = 'amount';
    public static final String NODO_PAYMENT_ID_DETAIL = 'paymentId';

    public static final String NODO_DETAIL = 'detail';

    public static final String NODO_CHARGE_TYPE_RI_TER = 'RI_TER';
    public static final String NODO_CHARGE_TYPE_LPI_TER = 'LPI_TER';
    public static final String NODO_CHARGE_TYPE_LPI_TEC = 'LPI_TEC';
    public static final String NODO_CHARGE_TYPE_LPV = 'LPV';
    public static final String NODO_CHARGE_TYPE_AMZ = 'AMZ';
    public static final String NODO_CHARGE_TYPE_IVA = 'IVA';
    public static final String NODO_CHARGE_TYPE_MFOC_FI = 'MFOC_FI';
    public static final String NODO_CHARGE_TYPE_MFOC_FFI = 'MFOC_FFI';
    public static final String NODO_CHARGE_TYPE_MFOC_FFS = 'MFOC_FFS';
    public static final String NODO_CHARGE_TYPE_MFOC = 'MFOC';
    public static final String NODO_CHARGE_TYPE_IVA_MORA_DESC = 'Late Payment Interest';
    public static final String NODO_CHARGE_TYPE_IVA_CORRIENTES_DESC = 'Regular Interest Tax';

    public static final String NODO_PAYMENT_COLLECTING_ENTITY = 'collectingEntity';
    public static final String NODO_PAYMENT_METHOD = 'method';
    public static final String NODO_PAYMENT_ID = 'id';
    public static final String NODO_PAYMENT_AMOUNT = 'amount';
    public static final String NODO_FINANCIAMIENTOS = 'financings';
    public static final String NODO_FACTURAS = 'invoices';
    public static final String NODO_FINANCING_REFERENCE = 'financingReference';

    public static final Integer MAX_ID_ENTIDAD = 21;
    public static final Integer MAX_ID_MEDIO_PAGO = 35;
    public static final String EMPTY_STRING = '';
    public static final String ACCOUNTID = 'accountId';
    public static final String CUENTA_ORIGEN = 'cuentaOrigen';

    /**
     * @description Entry point para VlocityOpenInterface2. Enruta la ejecución según methodName.
     * @param methodName Nombre del método invocado.
     * @param input      Mapa de entrada.
     * @param outMap     Mapa de salida.
     * @param options    Opciones adicionales.
     * @return true si ejecutó el enrutamiento.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        if (methodName.equals('generateJSONFinanciamientos')) {
            generateJSONFinanciamientos(input, outMap, options);
        } else if (methodName.equals('integrateAllData')) {
            integrateAllData(input, outMap, options);
        }
        return true;
    }

    /***************************************************************************************************
     * @Method name : generateJSONFinanciamientos
     * @description Recieve the JSON of the Financiamientos and analize it to only get the valid ones based on the year parameter.
     * @param input   Financiamientos JSON.
     * @param outMap  JSON refined.
     * @param options Opciones adicionales.
     */
    public void generateJSONFinanciamientos(Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options) {
        List<Object> result = new List<Object>();

        Integer numberOfYearsToSearch = Integer.valueOf(DATE_TO_VALIDATE_LABEL);
        Datetime todaySomeYearsAgo = CURRENT_DATETIME.addYears(-numberOfYearsToSearch);

        List<Object> financingObjList = (List<Object>) input.get(NODO_FINANCIAMIENTO);
        List<Object> summaryList      = (List<Object>) input.get(NODO_SUMMARY);

        if (financingObjList == null || summaryList == null) {
            outMap.put(RESULT_STRING, result);
            return;
        }

        Integer size = Math.min(financingObjList.size(), summaryList.size());

        for (Integer i = 0; i < size; i++) {
            Map<String, Object> financingItem = (Map<String, Object>) financingObjList[i];
            Map<String, Object> summaryItem   = (Map<String, Object>) summaryList[i];

            String creationDate = (String) financingItem.get(NODO_CREATION_DATE);
            if (creationDate == null) {
                continue;
            }

            Datetime financingDateTime = Datetime.valueOf(creationDate);

            if (todaySomeYearsAgo < financingDateTime) {
                if (summaryItem != null && summaryItem.containsKey('resolvedState')) {
                    financingItem.put('resolvedState', summaryItem.get('resolvedState'));
                }
                result.add(financingItem);
            }
        }

        outMap.put(RESULT_STRING, result);
    }

    /***************************************************************************************************
     * @Method name : integrateAllData
     * @description Integra datos de transacciones, financiamientos, historial de crédito y cargos; devuelve movimientos ordenados.
     * @param input   Mapa de entrada.
     * @param outMap  Mapa de salida.
     * @param options Opciones adicionales.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList,PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
    public static void integrateAllData(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        String accountId = (String) input.get(ACCOUNTID);
        String cuentaOrigen = (String) input.get(CUENTA_ORIGEN);

        try {
            result.addAll(processTransactions(input, accountId, cuentaOrigen));
            // result.addAll(processInvoices(input, accountId, cuentaOrigen));
            result.addAll(processFinancings(input, accountId, cuentaOrigen));
            result.addAll(processCreditHistory(input, accountId, cuentaOrigen));
            result.addAll(processCustomerCharges(input, accountId, cuentaOrigen));

            result.sort(new TransactionComparator());
            outMap.put('result', result);
        } catch (Exception e) {
            outMap.put('error', 'Se produjo un error al procesar los datos: ' + e.getMessage());
        }
    }

    /**
     * @description Procesa transacciones/pagos y construye movimientos estandarizados.
     * @param input        Mapa de entrada.
     * @param accountId    AccountId.
     * @param cuentaOrigen Cuenta origen.
     * @return Lista de movimientos.
     */
    @SuppressWarnings('PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssMethodCount,PMD.AvoidDeeplyNestedIfStmts')
    private static List<Map<String, Object>> processTransactions(Map<String, Object> input, String accountId, String cuentaOrigen) {

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<Object> transactionsObjList = (List<Object>) input.get(NODO_TRANSACTION);
        List<Object> paymentObjList = (List<Object>) input.get(NODO_PAYMENTS);

        if (transactionsObjList == null || transactionsObjList.isEmpty()) {
            return result;
        }

        for (Object transObj : transactionsObjList) {
            Decimal saldo = 0;

            Map<String, Object> transacionMap = new Map<String, Object>();
            List<Map<String, Object>> detailsList = new List<Map<String, Object>>();

            Map<String, Object> transactionItem = (Map<String, Object>) transObj;
            String tipoTransaction = (String) transactionItem.get('type');

            if (tipoTransaction == 'PAY' || tipoTransaction == TRANSACTION_ADJ || tipoTransaction == 'MCH') {

                Map<String, Object> paymentDetailsObj = (Map<String, Object>) transactionItem.get('details');

                String entidad = '';
                String medioPago = '';
                String noTransaccion = '';
                String capital = '0';
                String interesCorrientes = '0';
                String interesMora = '0';
                String ivaInteresMora = '0';
                String ivaInteresCorrientes = '0';

                String chargeType = '';
                String chargeDesc = '';

                String transactionId = (String) transactionItem.get('id');

                if (paymentDetailsObj != null) {
                    for (String key : paymentDetailsObj.keySet()) {
                        try {
                            Object node = paymentDetailsObj.get(key);

                            List<Object> detailList = new List<Object>();
                            if (node instanceof List<Object>) {
                                detailList = (List<Object>) node;
                            } else if (node instanceof Map<String, Object>) {
                                detailList.add(node);
                            } else {
                                continue;
                            }

                            for (Object detail : detailList) {
                                Map<String, Object> detailItem = (Map<String, Object>) detail;

                                String openAmountStr = (String) detailItem.get('openAmount');
                                if (openAmountStr != null) {
                                    saldo += Decimal.valueOf(openAmountStr);
                                }

                                chargeType = (String) detailItem.get('chargeType');
                                chargeDesc = (String) detailItem.get('chargeDesc');

                                if (tipoTransaction == 'PAY' || tipoTransaction == 'MCH') {
                                    Map<String, String> dyn = new Map<String, String>();
                                    //dyn.put('tipo', chargeType);
                                    dyn.put('descripcion', chargeDesc);
                                    dyn.put('valor', currency((String) detailItem.get('amount')));
                                    //dyn.put('saldo', currency((String) detailItem.get('openAmount')));
                                    detailsList.add(dyn);
                                }

                                if (chargeType == 'RI_TER') {
                                    interesCorrientes = (String) detailItem.get('amount');
                                } else if (chargeType == 'AMZ') {
                                    capital = (String) detailItem.get('amount');
                                } else if (chargeType == 'LPI_TER' || chargeType == 'LPI_TEC') {
                                    interesMora = (String) detailItem.get('amount');
                                } else if (chargeType == 'LPV') {
                                    ivaInteresMora = (String) detailItem.get('amount');
                                } else if (chargeType == 'IVA' || chargeType == 'NRI' || chargeType == 'NLPI_TEC') {
                                    if (chargeDesc == NODO_CHARGE_TYPE_IVA_MORA_DESC || chargeType == 'NLPI_TEC') {
                                        ivaInteresMora = (String) detailItem.get('amount');
                                    } else if (chargeDesc == NODO_CHARGE_TYPE_IVA_CORRIENTES_DESC || chargeType == 'NRI') {
                                        ivaInteresCorrientes = (String) detailItem.get('amount');
                                    }
                                }
                            }
                        } catch (Exception e) {
                            // sin debug para evitar PMD.AvoidDebugStatements
                        }
                    }
                }

                if ((tipoTransaction == 'PAY' || tipoTransaction == 'MCH') && paymentObjList != null) {
                    for (Object paymentObject : paymentObjList) {
                        if (paymentObject == null) {
                            continue;
                        }

                        Map<String, Object> transactionPayment = (Map<String, Object>) paymentObject;
                        String paymentId = (String) transactionPayment.get('paymentId');

                        if (paymentId == transactionId) {
                            entidad = (String) transactionPayment.get('collectingEntity');
                            medioPago = (String) transactionPayment.get('method');
                            noTransaccion = (String) transactionPayment.get('paymentId');
                            break;
                        }
                    }
                }

                String transactionType = '';
                Decimal openAmount = Decimal.valueOf((String) transactionItem.get('openAmount'));

                if (tipoTransaction == 'PAY') {
                    transactionType = 'Pago';
                } else if (tipoTransaction == 'ADJ') {
                    transactionType = openAmount < 0 ? 'Ajuste Crédito' : 'Ajuste Débito';
                } else if (tipoTransaction == 'RPY') {
                    transactionType = 'Ajuste Débito';
                } else if (tipoTransaction == 'MCH') {
                    transactionType = 'Factura';
                }

                transacionMap.put('transactionId', (String) transactionItem.get('id'));
                transacionMap.put('fechaTransaccion', (String) transactionItem.get('refDate'));
                transacionMap.put('valor', formatCurrency((String) transactionItem.get('openAmount')));
                transacionMap.put('saldo', formatCurrency(String.valueOf(saldo)));
                transacionMap.put('tipoTransaccion', transactionType);

                transacionMap.put('entidad', getEntidadDescription(entidad));
                transacionMap.put('medioPago', getMedioPago(medioPago));
                transacionMap.put('noTransaccion', noTransaccion);
                transacionMap.put('capital', formatCurrency(capital));
                transacionMap.put('interesCorrientes', formatCurrency(interesCorrientes));
                transacionMap.put('interesMora', formatCurrency(interesMora));
                transacionMap.put('ivaInteresMora', formatCurrency(ivaInteresCorrientes));
                transacionMap.put('ivaInteresCorrientes', formatCurrency(ivaInteresMora));

                transacionMap.put('tipoAjuste', chargeType);
                transacionMap.put('descripcionAjuste', chargeDesc);
                transacionMap.put('accountId', accountId);
                transacionMap.put('cuentaOrigen', cuentaOrigen);

                if (transacionMap.get('tipoTransaccion') == TRANSACTION_FACTURA ||
                    transacionMap.get('tipoTransaccion') == TRANSACTION_PAGO) {
                    transacionMap.put('details', detailsList);
                }

                result.add(transacionMap);
            }
        }

        return result;
    }

    private static List<Map<String, String>> processFinancings(Map<String, Object> input, String accountId, String cuentaOrigen) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        List<Object> financiamientosObjList = (List<Object>) input.get(NODO_FINANCIAMIENTOS);

        if (financiamientosObjList == null || financiamientosObjList.isEmpty()) {
            return result;
        }

        for (Object financObj : financiamientosObjList) {
            Map<String, String> transacionMap = new Map<String, String>();
            Map<String, Object> financiamientoItem = (Map<String, Object>) financObj;

            transacionMap.put('fechaTransaccion', (String) financiamientoItem.get('creationDate'));
            transacionMap.put('valor', formatCurrency((String) financiamientoItem.get('baseAmount')));
            transacionMap.put('tipoTransaccion', 'Financiamiento');
            transacionMap.put('saldo', '');
            transacionMap.put('monthlyFee', formatCurrency((String) financiamientoItem.get('monthlyFee')));
            transacionMap.put('accountId', accountId);
            transacionMap.put('cuentaOrigen', cuentaOrigen);
            result.add(transacionMap);
        }

        return result;
    }

    @SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
    private static List<Map<String, String>> processCreditHistory(Map<String, Object> input, String accountId, String cuentaOrigen) {
        List<Map<String, String>> result = new List<Map<String, String>>();

        List<Object> validReasonIds = (List<Object>) input.get('reasonIds');
        List<Object> creditHistoryList = (List<Object>) input.get('creditHistory');

        if (creditHistoryList == null || creditHistoryList.isEmpty()) {
            return result;
        }

        for (Object historyObj : creditHistoryList) {
            if (historyObj == null || historyObj == '') {
                continue;
            }

            Map<String, Object> historyItem = (Map<String, Object>) historyObj;
            String idRazon = (String) historyItem.get('IdRazon');

            if (idRazon != null && validReasonIds.contains(idRazon)) {
                Map<String, String> transaccionMap = new Map<String, String>();

                String saldo = (String) historyItem.get('Saldo');
                String valor = (String) historyItem.get('Valor');
                String fechaTransaccion = (String) historyItem.get('FechaTransaccion');
                String estado = (String) historyItem.get('Estado');

                transaccionMap.put('saldo', saldo != null ? formatCurrency(saldo) : '');
                transaccionMap.put('valor', valor != null ? formatCurrency(valor) : '');
                transaccionMap.put('tipoTransaccion', 'Ajuste Crédito');
                transaccionMap.put('fechaTransaccion', fechaTransaccion != null ? fechaTransaccion : '');
                transaccionMap.put('cuentaOrigen', cuentaOrigen);
                transaccionMap.put('accountId', accountId);
                transaccionMap.put('estado', estado);
                transaccionMap.put('idRazon', idRazon);

                result.add(transaccionMap);
            }
        }

        return result;
    }

    @SuppressWarnings('PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
    private static List<Map<String, String>> processCustomerCharges(Map<String, Object> input, String accountId, String cuentaOrigen) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        List<Object> customerChargesList = (List<Object>) input.get('customerCharges');

        if (customerChargesList == null || customerChargesList.isEmpty()) {
            return result;
        }

        for (Object chargeObj : customerChargesList) {
            if (chargeObj == null || chargeObj == '') {
                continue;
            }

            Map<String, Object> chargeItem = (Map<String, Object>) chargeObj;
            Map<String, String> transaccionMap = new Map<String, String>();

            String currentBalance = (String) chargeItem.get('currentBalance');
            String amount = (String) chargeItem.get('amount');
            String transactionDate = (String) chargeItem.get('transactionDate');
            String description = (String) chargeItem.get('description');
            String chargeService = (String) chargeItem.get('chargeService');
            String idCharge = (String) chargeItem.get('idCharge');

            transaccionMap.put('saldo', currentBalance != null ? formatCurrency(currentBalance) : '');
            transaccionMap.put('valor', amount != null ? formatCurrency(amount) : '');
            transaccionMap.put('tipoTransaccion', 'Cargo Fijo');
            transaccionMap.put('fechaTransaccion', transactionDate != null ? transactionDate : '');
            transaccionMap.put('cuentaOrigen', cuentaOrigen);
            transaccionMap.put('accountId', accountId);

            transaccionMap.put('descripcion', description != null ? description : '');
            transaccionMap.put('servicioCargoId', chargeService != null ? chargeService : '');
            transaccionMap.put('idCargo', idCharge != null ? idCharge : '');

            result.add(transaccionMap);
        }

        return result;
    }

    private static String formatCurrency(String value) {
        return value != null ? '$' + Decimal.valueOf(value).setScale(2).format() : '$0.00';
    }

    /***************************************************************************************************
     * @Method name : currency
     * @description Conver a string to currency to format.
     * @param i Valor numérico como string.
     * @return String formated as currency.
     */
    public static String currency(String i) {
        Decimal valor = Decimal.valueOf(i == null || i.trim() == '' ? '0' : i).setScale(3);
        String s = (valor == 0 ? 0.001 : (valor > 0 ? valor + 0.001 : valor - 0.001)).format();
        return '$ ' + s.substring(0, s.length() - 1);
    }

    /***************************************************************************************************
     * @Method name : getEntidadDescription
     * @description Get the entidad description for an Id.
     * @param entidadId Id entidad.
     * @return Entidad description.
     */
    public static String getEntidadDescription(String entidadId) {
        String[] descriptions = new String[] {
            'AGRARIO', 'BANCOLOMBIA', 'BBVA', 'BOGOTA', 'CAJA', 'CITI', 'COLPATRIA', 'CORFICOLOMBIANA', 'DAVIVIENDA',
            'COOPECEMS', 'COOPENESA', 'RECAUDO SERVICER', 'REDSERVI', 'Superefectivos', 'FONYOU2', 'TUYA', 'NOMINA', 'EFECTY',
            'SERVIBANCA', 'PRETUPS', 'REDEBAN'
        };

        String descriptionEntidad = entidadId;

        if (entidadId != '' && entidadId != null) {
            Integer idEntidad = Integer.valueOf(entidadId);

            if (idEntidad <= MAX_ID_ENTIDAD) {
                descriptionEntidad = descriptions[idEntidad - 1];
            }
        }

        return descriptionEntidad;
    }

    /***************************************************************************************************
     * @Method name : getMedioPago
     * @description Get the medio de pago description for an Id.
     * @param medioPagoId Id medio de pago.
     * @return Medio de pago description.
     */
    public static String getMedioPago(String medioPagoId) {
        String[] descriptions = new String[] {
            'POR VENTANILLA EN EFECTIVO', 'POR VENTANILLA EN CHEQUE', 'POR VENTANILLA EN TARJETA', 'PAGO MIXTO','BONO CLARO CLUB',
            'CRÉDITO DEL BOTÓN DE PAGOS. (PAGO DIGITAL - PAGOS EN LÝNEA)', 'DÉBITO DEL BOTÓN DE PAGOS. (PAGO DIGITAL - PAGOS EN LÝNEA)',
            'BOTÓN BANCOLOMBIA', 'DÉBITO EN CUENTA POR SISTEMA DE AUDIORESPUESTA', 'DÉBITO EN CUENTA POR CAJERO ELECTRÓNICO', 'DÉBITO EN CUENTA POR DATÝFONO',
            'DÉBITO EN CUENTA POR DOMICILIACIÓN', 'DÉBITO EN CUENTA POR INTERNET', 'DÉBITO EN CUENTA POR BANCA MOVIL', 'DÉBITO EN CUENTA POR AGILIZADOR ELECTRONICO',
            'DÉBITO EN CUENTA POR PINPAD', 'DÉBITO EN CUENTA POR CNB', 'DÉBITO EN CUENTA POR OTRAS REDES', 'TARJETA CRÉDITO POR SISTEMA DE AUDIORESPUESTA',
            'TARJETA CRÉDITO POR CAJERO ELECTRÓNICO', 'TARJETA CRÉDITO POR DATÝFONO', 'TARJETA CRÉDITO POR DOMICILIACIÓN', 'TARJETA CRÉDITO POR INTERNET',
            'TARJETA DE CRÉDITO POR VENTANILLA', 'POR VENTANILLA MIXTO (EFECTIVO Y CHEQUE)', 'POR VENTANILLA CARGO A CUENTA', 'POR CNB', 'POR VENTANILLA CON REMESA',
            'POR TRANSPORTADORA DE EFECTIVO', 'BONO SODEXHO', 'PUNTOS CLARO', 'PUNTOS COLPATRIA', 'TARJETA REGALO'
        };

        String descriptionMedioPago = medioPagoId;

        if (medioPagoId != '' && medioPagoId != null) {
            Integer idMedioPago = Integer.valueOf(medioPagoId);

            if (idMedioPago <= MAX_ID_MEDIO_PAGO) {
                descriptionMedioPago = descriptions[idMedioPago - 1];
            }
        }

        return descriptionMedioPago;
    }

    /**
     * @description Comparator para ordenar movimientos por fechaTransaccion descendente.
     */
    private class TransactionComparator implements Comparator<Map<String, Object>> {
        /**
         * @description Compara dos movimientos por fechaTransaccion descendente.
         * @param a Movimiento A.
         * @param b Movimiento B.
         * @return -1 si A va antes, 1 si B va antes, 0 si iguales.
        */
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            String fechaA = (String) a.get('fechaTransaccion');
            String fechaB = (String) b.get('fechaTransaccion');

            if (fechaA == null && fechaB == null) {
                return 0;
            }
            if (fechaA == null) {
                return 1;
            }
            if (fechaB == null) {
                return -1;
            }

            Date dateA = Date.valueOf(fechaA.split(' ')[0]);
            Date dateB = Date.valueOf(fechaB.split(' ')[0]);

            if (dateA > dateB) {
                return -1;
            }
            if (dateA < dateB) {
                return 1;
            }
            return 0;
        }
    }
}