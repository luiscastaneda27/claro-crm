/**
 * @description       : 
 * @author            : SALESFORCE
 * @group             : 
 * @last modified on  : 03-08-2024
 * @last modified by  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   03-08-2024   SALESFORCE   Initial Version
**/



global with sharing class PVU_habilitaLiberacion implements vlocity_cmt.VlocityOpenInterface {

    static global Boolean invokeMethod(String methodName, Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){        
        if (methodName == 'liberacionImeiAccount') {
            liberacionImeiAccount(input, outMap, options);    
        }
        /*else if (methodName == 'DevolucionDineroOrder') {
            DevolucionDineroOrder(input, outMap, options);    
        }*/ 
        return true;
    }


    /* Dev: SALESFORCE
     * Descripcion: metodo para validaciones de casos en el proceso de Liberacion de Imei
     * Fecha: 08/03/2024
     * Input: reportList
     * Input: AccountId
     * Input: Imei
     * Input: MIN
     * Output: Lista de variables Booleanas para validar botones y menesajes.
    */
    static public void liberacionImeiAccount( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        Map<String,Boolean> respuestas = new Map<String,Boolean>();
        String accountId=(String)input.get('accountId');
        String imei=(String)input.get('imei');
        String min=(String)input.get('minInput');       
        List<Object> listaReportes = (List<Object>)input.get('reportsList'); 
        Boolean habilitaLiberacion = false; 
    
        if(min.left(2).equals('57')){
            min = min.substring(2);
        }
        try {
            habilitaBotonRoboPerdida(min, listaReportes,respuestas);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'Error en habilitaBotonRoboPerdida: ' + e.getMessage()+' - '+e.getStackTraceString());
        }
        try {
            habilitaBotonReinicidente(accountId, imei, listaReportes,respuestas);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'Error en habilitaBotonReinicidente: ' + e.getMessage()+' - '+e.getStackTraceString());
        }

        Boolean mostrarBotonLiberacion = respuestas.get('habilitarLiberacionRobo') || respuestas.get('habilitarLiberacionReincidente');
        outMap.put('mostrarBotonLiberacion', mostrarBotonLiberacion);

        if(!mostrarBotonLiberacion){
            if (respuestas.get('mostrarMensajeErrorRobo')) {
                outMap.put('roboPerdidaMinNoCoincide', respuestas.get('mostrarMensajeErrorRobo'));
            } else if (respuestas.get('reincidenteNoEsQuienComproEquipo')) {
                outMap.put('mensajeFalloValidacionReincidente', 'La persona que solicita la liberación no es la misma a la que compro el equipo');
            } else if(respuestas.get('reincidenteNoVendioClaro')){
                outMap.put('mensajeFalloValidacionReincidente', 'IMEI no fue vendido por claro');
            } else if (respuestas.get('reincidenteNoReportoClaro')){
                outMap.put('mensajeFalloValidacionReincidente', 'IMEI no está reportado por claro');
            }        
        }
    }
    
    static public Map<String,Boolean> habilitaBotonRoboPerdida(String minCuenta, List<Object> listaReportes, Map<String,Boolean> respuestas){
        
        Boolean habilitarLiberacion = false; 
        Boolean mostrarMensajeError = false;
        for (Object reporte : listaReportes) {
            ReportsList objectReport = (ReportsList)Json.deserialize(JSON.serialize(reporte),ReportsList.class);
            if(objectReport.tipoReporte != null){
                if ((objectReport.tipoReporte.equals('1') || objectReport.tipoReporte.equals('2')) 
                     && objectReport.operador.equals('Comcel S.A')) {
                    if (objectReport.msisdn.equals(minCuenta)) {
                        habilitarLiberacion = true;
                        break;
                    } else {
                        mostrarMensajeError = true;
                        break;
                    }
                }         
            }
        }        
        respuestas.put('habilitarLiberacionRobo', habilitarLiberacion);
        respuestas.put('mostrarMensajeErrorRobo', mostrarMensajeError);
        return respuestas;        
    }

    static public Map<String,Object> habilitaBotonReinicidente(String accountIdInput, String imeiConsulta,List<Object> listaReportes, Map<String,Boolean> respuestas){
        //AssetsByAccount
        Boolean habilitarLiberacion = false; 
        Boolean reincidenteNoReportoClaro = false; 
        Boolean reincidenteNoVendioClaro = false; 
        Boolean reincidenteNoEsQuienComproEquipo = false; 

        List<Asset> asset = [SELECT accountid, pvu_imei__c, fvu_imei2__c, id FROM Asset 
                            WHERE (FVU_IMEI2__c =: imeiConsulta OR PVU_IMEI__c =:imeiConsulta)  WITH USER_MODE LIMIT 1 ];

        List<orderItem> orderItem = [SELECT order.status, fvu_imei2__c, order.accountid, product2.family, id, fvu_imei__c FROM OrderItem 
                                    WHERE (Order.AccountId =:accountIdInput AND Order.Status = 'Activated' AND Product2.Family = 'Device') 
                                        AND (FVU_IMEI__c =: imeiConsulta OR FVU_IMEI2__c =:imeiConsulta) WITH USER_MODE LIMIT 1];

        for (Object reporte : listaReportes) {
            ReportsList objectReport = (ReportsList)Json.deserialize(JSON.serialize(reporte),ReportsList.class);
            if(objectReport.tipoReporte != null){
                if (objectReport.tipoReporte.equals('7')) {
                    if(objectReport.operador.equals('Comcel S.A')){
                        if(asset.size() <> 0){
                            if (orderItem.size() <> 0) {
                                habilitarLiberacion =true;
                            } else {
                                reincidenteNoEsQuienComproEquipo = true;
                            }                        
                        }else{
                            reincidenteNoVendioClaro = true;
                        }
                    }else{
                        reincidenteNoReportoClaro = true;
                    }               
                }else{
                    break;
                }         
            }
        }
        //ass variables 
        respuestas.put('habilitarLiberacionReincidente', habilitarLiberacion);
        respuestas.put('reincidenteNoReportoClaro', reincidenteNoReportoClaro);
        respuestas.put('reincidenteNoVendioClaro', reincidenteNoVendioClaro);
        respuestas.put('reincidenteNoEsQuienComproEquipo', reincidenteNoEsQuienComproEquipo);
        return respuestas;
    }
    
    public class ReportsList {
        public String fechaReporte;
        public String msisdn;
        public String operador;
        public String tipoReporte;
    } 

}