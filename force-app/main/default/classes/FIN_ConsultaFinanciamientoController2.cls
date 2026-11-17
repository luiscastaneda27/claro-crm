/***************************************************************************************************
 * @Class Name          : FIN_ConsultaFinanciamientoController2
 * @Description         : Contiene los metodos para el componente Consulta de Financiamiento
 * @Author              : Gerardo A. Mendoza
 * @Created date        : 18-october-2024
 * @Modification Log    :
 * Version  Date          Developer             Modification
 * 1.0      18/10/2024    Gerardo A. Mendoza    Initial version
 */
public without sharing class FIN_ConsultaFinanciamientoController2 {
    
   	public static final String NODO_FINANCIAMIENTOS = 'financing';
    
    public static final String NODO_CREATION_DATE = 'creationDate';
    
    public static final String TEST_STRING = '{ \"financing\": [ { \"username\": {}, \"billCycle\": \"16\", \"equipmentRef\": \"669258435030924\", \"salesTaxAmount\": \"0\", \"remainingTerm\": \"10\", \"financingType\": \"Terminal Movil a Credito\", \"currentMaxLegalInterestRate\": \"31.53\", \"process\": \"VENTA\", \"currentOpenAmount\": \"1599254.24\", \"interestRate\": \"38.16\", \"administrativeFeePeriod\": \"O\", \"downPaymentStatus\": \"P\", \"remainingBalance\": \"1735474.01\", \"term\": \"24\", \"AEInterestRate\": \"38.16\", \"lastModUsername\": {}, \"resellerCode\": \"DUMMY.00001\", \"equipmentInsuranceFee\": \"0\", \"profitCenter\": \"Telefono,Smartphone\", \"previousCutOffDate\": \"2024-09-16\", \"interestType\": \"AE\", \"city\": \"Cartagena\", \"financingId\": \"1590\", \"previousOpenAmount\": \"2099254.24\", \"status\": \"N - NORMAL\", \"region\": \"Andina\", \"lastModDate\": {}, \"salesNetAmount\": \"4615960\", \"financingTypeId\": { \"#text\": \"1\" }, \"downPaymentCreditAnalysis\": \"0\", \"financingCode\": \"CRED00000001590\", \"baseAmount\": \"4615960\", \"equipmentReference\": \"AppleIph14\", \"downPaymentAffinityEngine\": \"0\", \"creationDate\": \"2024-10-26 11:32:07\", \"resellerName\": \"CAV-CLARO-CARTAGENA\", \"debtInsuranceFee\": \"0\", \"affinityGroupCode\": {}, \"lastTerm\": \"14\", \"monthlyFee\": \"259271\", \"brand\": \"Apple\", \"state\": \"Bolivar\", \"model\": \"Apple Iph 14 128Gb\", \"administrativeFee\": \"0\", \"segment\": \"POSPAGO\", \"downPayment\": \"0\", \"debitState\": \"EN MORA\", \"equipmentId\": {}, \"salesChannel\": \"CAC\", \"equipmentRef2\": \"664901806089001\", \"amortizationSystem\": \"Cuotas Fijas\" }, { \"username\": {}, \"billCycle\": \"16\", \"equipmentRef\": \"669258435030924\", \"salesTaxAmount\": \"0\", \"remainingTerm\": \"10\", \"financingType\": \"Terminal Movil a Credito\", \"currentMaxLegalInterestRate\": \"31.53\", \"process\": \"VENTA\", \"currentOpenAmount\": \"1599254.24\", \"interestRate\": \"38.16\", \"administrativeFeePeriod\": \"O\", \"downPaymentStatus\": \"P\", \"remainingBalance\": \"1735474.01\", \"term\": \"24\", \"AEInterestRate\": \"38.16\", \"lastModUsername\": {}, \"resellerCode\": \"DUMMY.00001\", \"equipmentInsuranceFee\": \"0\", \"profitCenter\": \"Telefono,Smartphone\", \"previousCutOffDate\": \"2024-09-16\", \"interestType\": \"AE\", \"city\": \"Cartagena\", \"financingId\": \"1590\", \"previousOpenAmount\": \"2099254.24\", \"status\": \"N - NORMAL\", \"region\": \"Andina\", \"lastModDate\": {}, \"salesNetAmount\": \"4615960\", \"financingTypeId\": { \"#text\": \"1\" }, \"downPaymentCreditAnalysis\": \"0\", \"financingCode\": \"CRED00000001590\", \"baseAmount\": \"4615960\", \"equipmentReference\": \"AppleIph14\", \"downPaymentAffinityEngine\": \"0\", \"creationDate\": \"2023-10-26 11:32:07\", \"resellerName\": \"CAV-CLARO-CARTAGENA\", \"debtInsuranceFee\": \"0\", \"affinityGroupCode\": {}, \"lastTerm\": \"14\", \"monthlyFee\": \"259271\", \"brand\": \"Apple\", \"state\": \"Bolivar\", \"model\": \"Apple Iph 14 128Gb\", \"administrativeFee\": \"0\", \"segment\": \"POSPAGO\", \"downPayment\": \"0\", \"debitState\": \"EN MORA\", \"equipmentId\": {}, \"salesChannel\": \"CAC\", \"equipmentRef2\": \"664901806089001\", \"amortizationSystem\": \"Cuotas Fijas\" } ]}';

    /***************************************************************************************************
     * @Method name	: generateJSONFinanciamientos
     * @Author      : Gerardo A. Mendoza
     * @Date        : 18-oct-2024
     * @Description	: Recieve the JSON of the Financiamientos and analize it to only get the valid ones
     *                based on the year parameter
     * @Parameter   : Financiamientos JSON
     * @Return      : JSON refined
     */
    public static String filtrado(String jsonFinanciamientos) {
        String jsonResult;
        Map<String, Object> jsonMapaFinanciamientos = (Map<String, Object>)JSON.deserializeUntyped(jsonFinanciamientos);
        List<Object> listaFinanciamientos = (List<Object>) jsonMapaFinanciamientos.get(NODO_FINANCIAMIENTOS);
        for(Object financiamiento : listaFinanciamientos){
            if(financiamiento instanceof Map<String, Object>){
                Map<String, Object> financiamientoMap = (Map<String, Object>) financiamiento;
                Object creationDateObj = financiamientoMap.get(NODO_CREATION_DATE);
                if(creationDateObj instanceof String){
                    String creationDateString = (String) creationDateObj;
                    Datetime financingCreationDateTime = DateTime.valueOfGMT(creationDateString);
                    financingCreationDateTime.addYears(5);
                }
            }
        }
        return jsonResult; 
    }  
}