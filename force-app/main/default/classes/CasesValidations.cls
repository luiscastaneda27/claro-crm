/**
* @description       : 
* @author            : SALESFORCE
* @group             : 
* @last modified on  : 04-24-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author       Modification
* 1.0   03-07-2024   SALESFORCE   Initial Version
* 1.1   05-09-2025   hector.machuca@intellectSystem.net      Ajustes Devolución Dinero.
* 1.1   11-27-2025   molay@salesforce.com      Ajustes Devolución Dinero Casos Soporte y Fallas.
* 1.2   01-26-2026   molay@salesforce.com      Ajustes Devolución Dinero se añade cuenta 93 para todos los origenes - Service ChargeNotification.
* 1.3   04-01-2026.  molay@salesforce.com      Se ajusta metodo DevolucionDineroOrder para devoluciones con venta no exitosa.
* 1.4   04-28-2026.  molay@salesforce.com      Se ajusta metodo devolucionObtenerAssetPQR donde es valida devolucion para asset desactivados.
**/
global with sharing class CasesValidations implements vlocity_cmt.VlocityOpenInterface  {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        System.debug('Method Name: '+methodName);
        System.debug('Input '+input);
        System.debug('outmap '+ outMap);
        System.debug('options '+ options);
        
        if (methodName == 'DevolucionDinero') {
            DevolucionDinero(input, outMap, options);    
        }
        else if (methodName == 'DevolucionDineroOrder') {
            DevolucionDineroOrder(input, outMap, options);    
        } 
        else if (methodName == 'DevolucionDineroPQR') {
            DevolucionDineroPQR(input, outMap, options);    
        }
        else if (methodName == 'devolucionDineroCloseCaseVentaNoExitosa') {
            devolucionDineroCloseCaseVentaNoExitosa(input, outMap, options);    
        }
        else if (methodName == 'devolucionDineroCloseCasePQR') {
            devolucionDineroCloseCasePQR(input, outMap, options);    
        }
        else if (methodName == 'devolucionDineroCloseCaseSoporteFalla') {
            devolucionDineroCloseCaseSoporteFalla(input, outMap, options);    
        }
        else if(methodName.equals('pagosNoAbonados')){
            pagosNoAbonados(input, outMap, options); 
        }
        else if(methodName.equals('reporteImei')){
            reporteImei(input, outMap, options); 
        }
        else if(methodName.equals('liberacionImei')){
            liberacionImei(input, outMap, options); 
        }
        else if(methodName.equals('registroImei')){
            registroImei(input, outMap, options); 
        }
        else if(methodName.equals('duplicadoImei')){
            duplicadoImei(input, outMap, options); 
        }else if(methodName.equals('cancelacion')){
            cancelacion(input, outMap, options); 
        }else if(methodName.equals('cancelacionByCausal')){
            cancelacionByCausal(input, outMap, options); 
        }else if(methodName.equals('reconexion')){
            reconexion(input, outMap, options); 
        }else if(methodName.equals('cambioCiclo')){
            cambioCiclo(input, outMap, options); 
        }else if(methodName.equals('cambioTitularidad')){
            cambioTitularidad(input, outMap, options); 
        }else if(methodName.equals('cambioPlan')){
            cambioPlan(input, outMap, options); 
        }else if(methodName.equals('cambioSimCard')){
            cambioSimCard(input, outMap, options); 
        }else if(methodName.equals('roaming')){
            roaming(input, outMap, options); 
        }else if(methodName.equals('cobroErrado')){
            cobroErrado(input, outMap, options);
        } 
        else if(methodName.equals('cambioNumero')){
            cambioNumero(input, outMap, options);
        }else if(methodName.equals('cesionImei')){
            cesionImei(input, outMap, options); 
        } else if(methodName.equals('reinstalacion')) {
            reinstalacion(input, outMap, options); 
        } else if(methodName.equals('desglosePago')) {
            desglosePago(input, outMap, options); 
        } else if(methodName.equals('cesioncontrato')) {
            cesioncontrato(input, outMap, options); 
        } else if(methodName.equals('cambioPlanAccInmediatas')) {
            cambioPlanAccInmediatas(input, outMap, options); 
        }else if(methodName.equals('devolucionObtenerAssetPQR')) {
            devolucionObtenerAssetPQR(input, outMap, options); 
        } else if(methodName.equals('devolucionObtenerAssetSF')) {
            devolucionObtenerAssetSF(input, outMap, options); 
        }else if(methodName.equals('devolucionObtenerAssetSaldoFin')) {
            devolucionObtenerAssetSaldoFin(input, outMap, options); 
        } else if(methodName.equals('devolucionDineroOpenCaseSoporteFallaServiciosEquipos')) {
            devolucionDineroOpenCaseSoporteFallaServiciosEquipos(input, outMap, options); 
        }else if(methodName.equals('devolucionObtenerAssetSaldo')) {
            devolucionObtenerAssetSaldo(input, outMap, options); 
        }else if(methodName.equals('devolucionDineroObtenerAssetSaldoFin')) {
            devolucionDineroObtenerAssetSaldoFin(input, outMap, options); 
        }else if(methodName.equals('devolucionDineroObtenerAssetSaldo')) {
            devolucionDineroObtenerAssetSaldo(input, outMap, options); 
        }
        
               
        return true;
    }
    
    public void DevolucionDinero( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        List<Case> CasesNuevos=new List<Case>();  
        Set<String> ids=new Set<String>();  
        List<Case> blockedCases =  [SELECT assetid
                                    FROM Case 
                                    WHERE  PVU_Level1__c = 'Facturación y pagos' AND 
                                    (status = 'Abierto' OR status = 'En curso' OR (status = 'Cerrado' AND PVU_Codigo_de_Cierre__c IN('Se realiza reverso de pago','Se realiza devolución'))) and AccountId = :accountId WITH USER_MODE];
        
        for(Case openC : blockedCases){
            ids.add(openC.assetId);            
        }        
        
        List<Case> openCases = [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                casenumber,assetid,account.name,asset.name,PVU_NoNotaCredito__c, PVU_Valor__c, PVU_IdODS__c, PVU_Level3__c, PVU_Codigo_de_Cierre__c  
                                FROM Case 
                                WHERE (AccountId =: accountId AND 
                                       PVU_Level2__c = 'Falla del equipo' AND 
                                       PVU_Sub_Estado__c = 'Aplica Devolucion de dinero' AND 
                                       Status = 'Cerrado') and assetId not in :ids  WITH USER_MODE];
        
        outMap.put('openCases',openCases);
        
    }
    public void DevolucionDineroOrder( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        
        Set<String> ids=new Set<String>();          
        List<Case> blockedCases =  [SELECT PVU_Order__c
                                    FROM case 
                                    WHERE  PVU_Level1__c = 'Facturación y pagos' AND 
                                    (status = 'Abierto' OR status = 'En curso' OR (status = 'Cerrado' AND PVU_Codigo_de_Cierre__c IN('Se realiza reverso de pago','Se realiza devolución'))) and AccountId = :accountId WITH USER_MODE];
                          
        for(Case openC : blockedCases){
            ids.add(openC.PVU_Order__c);            
        }     
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
           // 1. metadata Traer los motivos de reversion por venta no finalizada 
        List<PVU_VentaNoFinalizadaMotivo__mdt> configs = [
            SELECT PVU_Motivo__c 
            FROM PVU_VentaNoFinalizadaMotivo__mdt
            WHERE PVU_Activo__c = true
            WITH USER_MODE
        ];
        
        Set<String> validReasons = new Set<String>();
        for (PVU_VentaNoFinalizadaMotivo__mdt cfg : configs) {
            validReasons.add(cfg.PVU_Motivo__c);
        }

        if (!validReasons.isEmpty()) {
          // si hay motivos configurados
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        List<Order> openOrders = [SELECT id, status, OrderNumber, FVU_ClosingReason__c, Type, FVU_BusinessChannel__c, FVU_PaymentMethod__c, FVU_CodigoPago__c, FVU_EffectiveOneTimeIncTaxesTotal__c
                                  FROM Order
                                  WHERE AccountId =: accountId AND 
                                         Status = 'Cerrada Perdida'  AND FVU_ClosingReason__c IN :validReasons AND id not in :ids  
                                         WITH USER_MODE];
        
        outMap.put('openOrders',openOrders);
        outMap.put('openOrdersSize',openOrders.size());
            }
        
    }
    
    public void devolucionDineroCloseCaseVentaNoExitosa( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String orderId=(String)input.get('OrderId');
        
        Set<String> ids=new Set<String>();  
        
        List<Case> blokedCasesReturnMoney =  [SELECT Id, AccountId, AssetId,  PVU_Level3__c, PVU_Codigo_de_cierre__c
                                FROM case  
                                WHERE PVU_Level1__c = 'Facturación y pagos'
                                AND (PVU_Level3__c ='Devolución dinero en efectivo' or PVU_Level3__c ='Devolución dinero por transferencia'  or PVU_Level3__c ='Devolución dinero por Claro Pay' or PVU_Level3__c ='Reverso de pago')                                    
                                AND status = 'Cerrado' 
                                AND (PVU_Codigo_de_Cierre__c ='Se rechaza reversión de pago' or PVU_Codigo_de_Cierre__c ='Devolución no realizada')                                
                                AND AccountId = :accountId
                                AND PVU_Order__c = :orderId
                                WITH USER_MODE];
        
        List<Case> blockedCases =  [SELECT Id, AccountId, AssetId,  PVU_Level3__c, PVU_Codigo_de_cierre__c
                                FROM case  
                                WHERE PVU_Level1__c = 'Facturación y pagos'
                                AND (PVU_Level3__c ='Devolución dinero en efectivo' or PVU_Level3__c ='Devolución dinero por transferencia'  or PVU_Level3__c ='Devolución dinero por Claro Pay' or PVU_Level3__c ='Reverso de pago')                                    
                                AND status = 'Cerrado' 
                                AND (PVU_Codigo_de_Cierre__c ='Se realiza devolución' or PVU_Codigo_de_Cierre__c ='Se realiza reverso de pago')                                
                                AND AccountId = :accountId
                                AND PVU_Order__c = :orderId
                                WITH USER_MODE];
        outMap.put('CasesClosedReturnMoney',blokedCasesReturnMoney);
        outMap.put('CasesClosedSizeReturnMoney',blokedCasesReturnMoney.size());
        outMap.put('CasesClosed',blockedCases);
        outMap.put('CasesClosedSize',blockedCases.size());
        
    }
    public void devolucionDineroCloseCasePQR( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String cun=String.valueOf(input.get('Cun'));
        String nr=String.valueOf(input.get('Nr'));
        
        Set<String> ids=new Set<String>();  
        List<Case> blockedCases =  [SELECT Id, AccountId, AssetId,  PVU_Level3__c, PVU_Codigo_de_cierre__c
                                FROM case  
                                WHERE PVU_Level1__c = 'Facturación y pagos'
                                AND (PVU_Level3__c ='Devolución dinero en efectivo' or PVU_Level3__c ='Devolución dinero por transferencia'  or PVU_Level3__c ='Devolución dinero por Claro Pay' or PVU_Level3__c ='Reverso de pago')                                    
                                AND status = 'Cerrado' 
                                AND (PVU_Codigo_de_Cierre__c ='Se realiza devolución' or PVU_Codigo_de_Cierre__c ='Se realiza reverso de pago')                                
                                AND AccountId = :accountId
                                AND PVU_CUN__c = :cun
                                AND PVU_NR__c = :nr   
                                WITH USER_MODE];
                                    
        outMap.put('CasesClosed',blockedCases);
        outMap.put('CasesClosedSize',blockedCases.size());
        
    }
    public void devolucionDineroCloseCaseSoporteFalla( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String assetId=(String)input.get('AssetId');
        
        Set<String> ids=new Set<String>(); 
        
        List<Case> blokedCasesReturnMoney =  [SELECT Id, AccountId, AssetId,  PVU_Level3__c, PVU_Codigo_de_cierre__c
                                FROM case  
                                WHERE PVU_Level1__c = 'Facturación y pagos'
                                AND (PVU_Level3__c ='Devolución dinero en efectivo' or PVU_Level3__c ='Devolución dinero por transferencia'  or PVU_Level3__c ='Devolución dinero por Claro Pay' or PVU_Level3__c ='Reverso de pago')                                    
                                AND status = 'Cerrado' 
                                AND PVU_Origen_DevDinero__c='Asset'
                                AND (PVU_Codigo_de_Cierre__c ='Se rechaza reversión de pago' or PVU_Codigo_de_Cierre__c ='Devolución no realizada')                                
                                AND AccountId = :accountId
                                AND AssetId = :assetId
                                WITH USER_MODE];
        
        List<Case> blockedCases =  [SELECT Id, AccountId, AssetId,  PVU_Level3__c, PVU_Codigo_de_cierre__c
                                FROM case  
                                WHERE PVU_Level1__c = 'Facturación y pagos'
                                AND (PVU_Level3__c ='Devolución dinero en efectivo' or PVU_Level3__c ='Devolución dinero por transferencia'  or PVU_Level3__c ='Devolución dinero por Claro Pay' or PVU_Level3__c ='Reverso de pago')                                    
                                AND status = 'Cerrado' 
                                AND PVU_Origen_DevDinero__c='Asset'
                                AND (PVU_Codigo_de_Cierre__c ='Se realiza devolución' or PVU_Codigo_de_Cierre__c ='Se realiza reverso de pago')                                
                                AND AccountId = :accountId
                                AND AssetId = :assetId
                                WITH USER_MODE];
           
        outMap.put('CasesClosedReturnMoney',blokedCasesReturnMoney);
        outMap.put('CasesClosedReturnMoney',blokedCasesReturnMoney.size());
        outMap.put('CasesClosed',blockedCases);
        outMap.put('CasesClosedSize',blockedCases.size());
        
    }
    
      public void devolucionDineroOpenCaseSoporteFallaServiciosEquipos( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String assetId=(String)input.get('AssetId'); 
        String Tipo=(String)input.get('Tipo');
        List<Object> listAssets = (List<Object>) input.get('listAssets');
        Boolean siAssets=(Boolean)input.get('siAssets')==null?false:(Boolean)input.get('siAssets'); 
        Set<Id> assetIds=new Set<Id>();
        if(siAssets){
            for (Object  assetObj : listAssets) {
                Map<String, Object> asset = (Map<String, Object>) assetObj;
                String idStr = (String) asset.get('Id');  
                System.debug('Asset ID: ' + idStr);
                if (idStr != null) {
                    assetIds.add((Id) idStr);
                }
            }                 
            
        }
        
        System.debug('Assetids: ' + assetIds);
        switch on Tipo {
            when 'Asset' {
                System.debug('Asset');
                List<Case> openCases =  [SELECT Id, AccountId, AssetId
                                         FROM case  
                                         WHERE PVU_Level1__c = 'Soporte, fallas de servicio y equipos'                                   
                                         AND (status = 'Abierto'  OR status = 'En curso')                             
                                         AND AccountId = :accountId
                                         AND AssetId = :assetId
                                         WITH USER_MODE
                                        ];
                outMap.put('CasesOpen',openCases);
                outMap.put('CasesOpenSize',openCases.size());
                
            }
            when 'PQR','SaldoFin','Saldo' {
                System.debug('Tipo:'+Tipo);
                System.debug('assetIds PQR '+assetIds);
                if(siAssets){
                    List<Case> openCases =  [SELECT Id, AccountId, AssetId
                                             FROM case  
                                             WHERE PVU_Level1__c = 'Soporte, fallas de servicio y equipos'                                   
                                             AND (status = 'Abierto'  OR status = 'En curso')                             
                                             AND AccountId = :accountId
                                             AND AssetId IN :assetIds
                                             WITH USER_MODE];
                    outMap.put('CasesOpen',openCases);
                    outMap.put('CasesOpenSize',openCases.size());
                    
                }   
            }
           

        }
        
        
        
    }
    
    //20230929 - FM: BUG 669488 INICIO - Se modifica la condicion de subestado para PQR a Dinero entregado
    //esto porque la radicacion de PQR en SF siempre va con subestado vacío
    public void DevolucionDineroPQR( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        List<Case> CasesNuevos=new List<Case>();  
        Set<String> ids=new Set<String>();  
        List<Case> blockedCases =  [SELECT PVU_NR__c
                                    FROM Case 
                                    WHERE  PVU_Level1__c = 'Facturación y pagos' AND 
                                    (status = 'Abierto' OR status = 'En curso' OR (status = 'Cerrado' AND pvu_sub_estado__c = 'Dinero entregado') ) and AccountId = :accountId
                                    WITH USER_MODE];
        //20230929 - FM: BUG 669488 FIN - Se modifica la condicion de subestado para PQR a Dinero entregado
        
        
        system.debug('devolucion>>>>>>>>>>>>>>>>>>>>>>>>>'+blockedCases);
        //20230926 - FM BUG 668577 INICIO: esta asignacion rompe cuando hay un solo caso o ninguno
        //Primero evaluar que no sea nulo el nodo Casos
        List<Object> cases = new List<Object>();
        if(input.get('Casos') != null){
            cases=(List<Object>)input.get('Casos');
        }
        //20230926 - FM BUG 668577 FIN
        Map<String,Object> casesAux=new Map<String,Object>();
        for(Object caso:cases){
            Map<String,Object> casosInput=(Map<String,Object>)caso;
            casesAux.put((String)casosInput.get('casoNumRadicado'),casosInput);
        }
        
        for(case caseBlock : blockedCases){
            if(casesAux.containsKey(caseBlock.PVU_NR__c)){
                casesAux.remove(caseBlock.PVU_NR__c);
            }            
        } 
        
        
        /**************************************************************
List<Object> casesAux=new List<Object>(cases);
system.debug('Casos>>>>>>>>>>>>>>>>>>>>>>>>>'+cases);

integer index=cases.size();
integer j=0;
try{
system.debug('size>>>>>>>>>>>>>>>>>>>>>>>>>'+index);
for(case caseBlock : blockedCases){
system.debug('JJJJJ>>>>>>>>>>>>>>>>>>>>>>>>>'+j);
for(integer i=0;i< index ;i++){
system.debug('indice>>>>>>>>>>>>>>>>>>>>>>>>>'+i);
Map<String,Object> caso=(Map<String,Object>)cases.get(i);                
if(cases.size() >0 && caso.get('casoNumRadicado') ==caseBlock.PVU_NR__c){
system.debug('ANTES REMOVIO'+i);
casesAux.remove(i);
system.debug('REMOVIO'+i);
}
}
j++;
}  

}catch (Exception e){
System.debug('DevolucionDineroPQR Exception ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
}
******************************************************************************************/
        
        outMap.put('openCases',casesAux.values());
        outMap.put('openCasesSize',casesAux.size());
        
    }
    
    public void pagosNoAbonados( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String orderId = (String)input.get('OrderId');
        String vozCliente = (String)input.get('VozCliente');
        String accountId = (String)input.get('AccountId');
        List<Case> cases = [SELECT Id, Status, PVU_Level3__c, PVU_Order__c 
                            FROM Case 
                            WHERE PVU_Level3__c = :vozCliente AND PVU_Order__c = :orderId
                            AND Status IN ('Abierto', 'En curso') AND AccountId = :accountId
                            WITH USER_MODE];
        Boolean tieneCasosBloqueantes = cases.size() > 0;
        outMap.put('tieneCasosBloqueantes', tieneCasosBloqueantes);
    }
    
    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Reporte de Imei
     * Fecha: 21/02/2024
     * Input: AccountId
     * Output: Lista de casos Abiertos o en curso para el mismo tipo y numero de documento relacionado a la cuenta.
    */
    public void reporteImei( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String imei=(String)input.get('Imei');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c = 'Reporte de IMEI' AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei)
                                WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    
    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Liberacion de Imei
     * Fecha: 27/02/2024
     * Input: AccountId
     * Input: Imei
     * Input: MIN
     * Output: Lista de casos Abiertos o en curso para el mismo imei, y numero de documento relacionado a la cuenta.
	 * Output: Lista de casos Cerrados reportados por Robo o Perdida dentro de los ultimnmos 25min.
    */
    public void liberacionImei( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String imei=(String)input.get('Imei');
        String min=(String)input.get('MIN');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId WITH USER_MODE limit 1];
        
        // Validacion para casos Abiertos o En curso de Liberacion
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c = 'Liberación IMEI' AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                 AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei)
                                 WITH USER_MODE];
        
        // Validacion para casos reportados Cerrados dentro de los pasados 25min
        List<Case> closedCasesList = [
            SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, casenumber,assetid,account.name, 
            account.FVU_DocumentNumber__c, account.FVU_DocumentType__c,asset.name, ClosedDate, PVU_Tipo_de_documento_de_quien_reporta__c,
            PVU_Numero_de_documento_de_quien_reporta__c 
            FROM Case 
            WHERE  PVU_Level3__c = 'Reporte de IMEI' AND ((status = 'Cerrado' AND (PVU_Sub_Estado__c = 'Reporte realizado' 
                OR PVU_Sub_Estado__c ='Suspensión y Reporte realizado') AND PVU_Codigo_de_Cierre__c ='Se realiza reporte'))
                AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei) AND PVU_MINReporteImei__c =:min
                AND (PVU_Motivo_del_reporte__c = 'Robo' OR PVU_Motivo_del_reporte__c = 'Pérdida') 
                WITH USER_MODE
                order By ClosedDate desc];
        
        Datetime dateTime25 = DateTime.now().addMinutes(-25);
        List<Case> recentlyCases = new List<Case>();
        
        //caso reportado mas reciente
        Case lastCase = new Case();
        
        If(closedCasesList.size() >0){
            lastcase=closedCasesList[0];
            for(Case cases:closedCasesList){
                If(cases.ClosedDate > dateTime25){
                    recentlyCases.add(cases);
                }
            }
        }
          
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('recentlyCasesRoboPerdida',recentlyCases);        
        outMap.put('recentlyCasesRoboPerdidaSize',recentlyCases.size()); 
        outMap.put('lastCase',lastcase);
    }

    /* Dev: Sara Garrido sara.garrido@intellectsystem.net
     * Descripcion: metodo para validaciones de casos en el proceso de Registro de Imei
     * Fecha: 14/03/2024
     * Input: AccountId
     * Output: Lista de casos Abiertos o en curso para el mismo tipo y numero de documento relacionado a la cuenta.
    */
    public void registroImei( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String imei=(String)input.get('Imei');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c = 'Registro de IMEI' AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei)
                                WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    
    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Imei Duplicado
     * Fecha: 25/03/2024
     * Input: AccountId, Imei
     * Output: Lista de casos Abiertos o en curso para el mismo tipo y numero de documento relacionado a la cuenta.
    */
    public void duplicadoImei( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String imei=(String)input.get('Imei');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c = 'Gestión de IMEI duplicado' AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei)
                                WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }

    /* Dev: Sara Garrido sara.garrido@intellectsystem.net
     * Descripcion: metodo para validaciones de casos en el proceso de Cancelación
     * Fecha: 20/04/2024
     * Input: AccountId, VozCliente
     * Output: Lista de casos Abiertos o en curso para la misma voz de cliente y numero de documento relacionado a la cuenta.
    */
    public void cancelacion( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String vozCliente=(String)input.get('VozCliente');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                 WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    
     public void cancelacionByCausal( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId=(String)input.get('AssetId');
        List<Object> causales = (List<Object>)input.get('Causales');
        List<String> listCausales = new List<String>();
         try{
        for(Object causal:causales){
            listCausales.add((String)causal);
        }
          
        
        //List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c IN: listCausales AND 
                                 (status = 'Abierto' OR status = 'En curso')
                    //             AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                      //           AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                AND assetid =: assetId 
                                WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
         }catch(Exception e){
             System.debug('validation >>>>>>>>>>>>>>>>>> ' + e.getMessage() + ', Line#: ' + e.getLineNumber() + ', ' + e.getCause());
         }
        
    }

     /* Dev: Sara Garrido sara.garrido@intellectsystem.net
     * Descripcion: metodo para validaciones de casos en el proceso de Reconexión
     * Fecha: 16/05/2024
     * Input: AccountId, VozCliente
     * Output: Lista de casos Abiertos o en curso para la misma voz de cliente y numero de documento relacionado a la cuenta.
     * Modified:Jean Nieto Leonardo carranza  jnietom@deloitte.com .lcarranza@intellect.net
     * Descripcion:ajuste del metodo para filtar por nùmero de linea
     * Fecha: 23/08/2024
     * Input: AccountId, VozCliente, NumeroLineaAsset
     * Output: Lista de casos Abiertos o en curso para la misma voz de cliente y numero de documento relacionado a la linea.
    */
    public void reconexion( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String vozCliente=(String)input.get('VozCliente');
        String NumeroLineaAsset = (String)input.get('NumeroLineaAsset');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                 AND PVU_MINReporteImei__c =: NumeroLineaAsset
                                 WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    
    /* Dev: Silvia Tovar silvia.tovar@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Cambio de Ciclo 
     * Fecha: 15/05/2024
     * Input: AccountId, Subcategoria
     * Output: Lista de casos Abiertos o en curso 
    */
    public void cambioCiclo( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String assetId=(String)input.get('AssetId');
        Date dateTD = System.TODAY();       
        Datetime startDate = Datetime.newInstance(dateTD.year(), 1, 1, 0, 0, 0);
		Datetime endDate = Datetime.newInstance(dateTD.year(),12,31, 0, 0, 0);                    
        
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c, FVU_Email__c, Phone FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  (pvu_level2__c = 'Cancelación Servicio Móvil'
                                 OR pvu_level2__c = 'Portabilidad' OR pvu_level2__c = 'Cambio de ciclo') 
                                 AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                 WITH USER_MODE];
        List<Case> casesClosed =  [Select id, PVU_Level1__c, PVU_Level2__c, PVU_Level3__c, PVU_Codigo_de_Cierre__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c ='Cambio de ciclo' AND PVU_Codigo_de_Cierre__c = 'Cambio de ciclo exitoso' 
                                 AND CreatedDate >=: startDate AND CreatedDate <=: endDate AND assetid =: assetId
                                 WITH USER_MODE];        
        outMap.put('openCases',casesList);
        outMap.put('closedCases',casesClosed);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('closedCasesSize',casesClosed.size());        
    }

     /* Dev: Sara Garrido sara.garrido@intellectsystem.net
     * Descripcion: metodo para validaciones de casos en el proceso de Cambio de Titularidad
     * Fecha: 12/06/2024
     * Input: AccountId, VozCliente
     * Output: Lista de casos Abiertos o en curso para la misma voz de cliente y numero de documento relacionado a la cuenta.
    */
    public void cambioTitularidad( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String vozCliente=(String)input.get('VozCliente');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId limit 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND accountid =: accountId AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                 WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());      
    }

    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Cambio de Plan
     * Fecha: 7/07/2024
     * Input: AssetId
     * Output: Lista de casos Abiertos o en curso para la linea con la misma subcategoria de Cambio de Plan,
     *          Lista de casos Abiertos o en curso para la linea con la subcategoria de Cambio de Ciclo,
     *          Lista de casos Abiertos o en curso para la linea con la subcategoria de Cancelación Servicio Móvil,
     *          Lista de casos Abiertos o en curso para la linea con la subcategoria de Portabilidad y voz de cliente Portabilidad Out 
    */
    public void cambioPlan( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId=(String)input.get('AssetId');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  pvu_level2__c = 'Cambio de plan'AND pvu_level3__c = 'Cambio de plan móvil'
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];
 
        List<Case> casesCambioCicloList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  pvu_level2__c = 'Cambio de ciclo'
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];
        
        List<Case> casesCancelacionList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  pvu_level2__c = 'Cancelación Servicio Móvil'
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];
        
        List<Case> casesPortabilidadList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  pvu_level2__c = 'Portabilidad' AND PVU_Level3__c = 'Portabilidad Out'
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];
        List<Case> casesDownGradeList = [SELECT  Id, Status, PVU_Codigo_de_Cierre__c 
                                         FROM Case 
                                         WHERE PVU_Level3__c ='Cambio de plan móvil' AND PVU_Codigo_de_Cierre__c ='DownGrade Exitoso'
                                        AND assetid =: assetId AND CreatedDate >= LAST_N_MONTHS:6
                                        WITH USER_MODE];	
       
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('openCasesCambioCiclo',casesCambioCicloList);
        outMap.put('openCasesCambioCicloSize',casesCambioCicloList.size()); 
        outMap.put('openCasesCancelacionServMovil',casesCancelacionList);
        outMap.put('openCasesCancelacionServMovilSize',casesCancelacionList.size());
        outMap.put('openCasesPortabilidad',casesPortabilidadList);
        outMap.put('openCasesPortabilidadSize',casesPortabilidadList.size());
        outMap.put('openCasesDownGrade',casesDownGradeList);
        outMap.put('openCasesDownGradeSize',casesDownGradeList.size());
    }

    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Cambio de Sim Card y Reconexion por Robo/Perdida
     * Fecha: 24/07/2024
     * Input: AssetId, AccountId, VozCliente
     * Output: Lista de casos Abiertos o en curso para la linea y cuenta con la misma subcategoria de Cambio de Sim Card
*/
    public void cambioSimCard( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId=(String)input.get('AssetId');
        String accountId=(String)input.get('AccountId');
        String vozCliente=(String)input.get('VozCliente');
        String motivo=(String)input.get('AsuntoMotivo');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  PVU_Level3__c =: vozCliente
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId 
                                    AND accountId =: accountId AND Asunto_Motivo__c =: motivo
                                    WITH USER_MODE];
 
               
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
    }

    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
     * Descripcion: metodo para validaciones de casos en el proceso de Roaming
     * Fecha: 15/08/2024
     * Input: AssetId, SubCategoria, AccountId
     * Output: Lista de casos Abiertos o en curso para la linea  con la misma subcategoria de Roaming
*/
    public void roaming( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId=(String)input.get('AssetId');
        String accountId=(String)input.get('AccountId');
        String subcategoria=(String)input.get('SubCategoria');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, PVU_Order__c,
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE  pvu_level2__c =: subcategoria
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];

        List<Case> casesPortabilidadList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                    FROM Case 
                                    WHERE PVU_Level3__c = 'Portabilidad Out'
                                    AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                    WITH USER_MODE];
            
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('openCasesPortabilidad',casesPortabilidadList);
        outMap.put('openCasesPortabilidadSize',casesPortabilidadList.size());

    }

/* Dev: Héctor Machuca / Silvia Tovar silvia.tovar@nespon.com / hector.machuca@intellectSystem.net. 
     * Descripcion: metodo para validaciones de casos en el proceso de Cobro Errado
     * Fecha: 19/09/2024
     * Input: CaseId, SelectedValues.
     * Output: Lista de casos Abiertos o en curso para cobro errado con los mismos items. 
*/
public void cobroErrado( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
    //Parametros de entrada.
    String accountId=(String)input.get('accountId');
    List<Object> selectedRows = (List<Object>)input.get('selectedRows');

    
    List<String> selectedIds = new List<String>();
    

    for (Object rowObj : selectedRows) {
        Map<String, Object> row = (Map<String, Object>) rowObj;        
            String uniqueId = (String)row.get('billNumber') +(String)row.get('descripcion') +(String)row.get('valorOriginal');
        selectedIds.add(uniqueId);
    }

    List<PVU_Ajustes_Factura__c> casesList =  [SELECT PVU_IdExclusivo__c 
                                FROM PVU_Ajustes_Factura__c 
                                WHERE Caso__r.AccountId=:accountId AND Caso__r.Status = 'En curso' AND 
                                PVU_IdExclusivo__c IN:selectedIds
                                WITH USER_MODE];    
        outMap.put('openCasesSize',casesList.size());
        outMap.put('SelectedIds', selectedIds);
    }
    
    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
    * Descripcion: metodo para validaciones de casos en el proceso de Cambio de Numero
    * Fecha: 27/09/2024
    * Input: AssetId, VozCliente
    * Output: Lista de casos Abiertos o en curso para la linea con la misma voz de cliente de Cambio de numero
    */
    public void cambioNumero( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId=(String)input.get('AssetId');
        String vozCliente=(String)input.get('VozCliente');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, PVU_Order__c,
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  pvu_level3__c =: vozCliente
                                 AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                 WITH USER_MODE];
        
        List<Case> casesPortabilidadList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                             casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                             FROM Case 
                                             WHERE PVU_Level3__c = 'Portabilidad Out'
                                             AND (status = 'Abierto' OR status = 'En curso') AND assetid =: assetId
                                             WITH USER_MODE];
        
        List<Case> cases30daysList =  [SELECT id, LastModifiedDate, accountid, pvu_sub_estado__c, pvu_level2__c, status, PVU_Order__c,
                                       casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                       FROM Case 
                                       WHERE  pvu_level3__c =: vozCliente
                                       AND status = 'Cerrado' AND PVU_Codigo_de_Cierre__c = 'Cambio de Número Exitoso' AND assetid =: assetId
                                       AND LastModifiedDate = LAST_N_DAYS:30
                                       WITH USER_MODE];
        
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('openCasesPortabilidad',casesPortabilidadList);
        outMap.put('openCasesPortabilidadSize',casesPortabilidadList.size());
        outMap.put('closedCases30daysList',cases30daysList);
        outMap.put('closedCases30daysListSize',cases30daysList.size());
        
    }

    /* Dev: Sara Garrido
    * Descripcion: Metodo para validaciones de casos en el proceso de Cesión de Imei
    * Fecha: 07/10/2024
    * Input: AccountId, Imei
    * Output: Lista de casos Abiertos o en curso para el mismo imei, tipo y numero de documento relacionado a la cuenta.
    */
    public void cesionImei( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId=(String)input.get('AccountId');
        String imei=(String)input.get('Imei');
        List<Account> acc = [SELECT Id, FVU_DocumentType__c, FVU_DocumentNumber__c FROM Account WHERE Id =: accountId LIMIT 1];
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, casenumber,
                                 assetid, Account.name, asset.name, Account.FVU_DocumentType__c, Account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c = 'Cesión de IMEI' AND 
                                 (status = 'Abierto' OR status = 'En curso')
                                 AND Account.FVU_DocumentType__c =: acc[0].FVU_DocumentType__c 
                                 AND Account.FVU_DocumentNumber__c =: acc[0].FVU_DocumentNumber__c
                                 AND (PVU_ImeiReporte1__c = :imei OR PVU_ImeiReporte2__c = :imei)
                                 WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    
    /* Dev: Mariana Olay
    * Descripcion: Metodo para validaciones de casos en el proceso de Reinstalación
    * Fecha: 05/12/2024
    * Input: AssetId
    * Output: Lista de casos Abiertos o en curso para reinstalación.
    */
    public void reinstalacion( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options) {
        String accountId = (String)input.get('accountId');
        String vozCliente = (String)input.get('vozCliente');
        String assetId = (String)input.get('assetId');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND accountid =: accountId AND assetid =: assetId 
                                 AND (status = 'Abierto' OR status = 'En curso') WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        
    }
    /* Dev: Silvia Tovar
    * Descripcion: Metodo para validaciones de casos en el proceso de Desglose de Pagos
    * Fecha: 06/01/2025
    * Input: AccountId
    * Output: Lista de casos Abiertos o en curso para DesglosePagos.
    */
    public void desglosePago( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options) {
        String accountId = (String)input.get('AccountId');
        String vozCliente = (String)input.get('vozCliente');
        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND accountid =: accountId 
                                 AND (status = 'Abierto' OR status = 'En curso') WITH USER_MODE];
        outMap.put('openCases',casesList);
        outMap.put('openCasesSize',casesList.size());
        outMap.put('caseNumber',casesList[0].CaseNumber);
        outMap.put('caseId',casesList[0].Id);
    }
    /* Dev: Hector Machuca
    * Descripcion: Metodo para validaciones de casos en el proceso de cesión de contrato.
    * Fecha: 26/03/2025
    * Input: BillingAccountumber, Lista de respuesta del servicio paymentReferences.
    * Output: Lista de casos Abiertos o en curso para CesionCotrato.
    */
    public void cesioncontrato( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options) {
        DateTime currentDateTime = System.now();
        String accountId = (String)input.get('AccountId');
        String vozCliente = (String)input.get('vozCliente');
        String accountValue = (String)input.get('Accountvalue');
        String productId = (String)input.get('Product2Id'); 

        List<Case> casesList =  [SELECT id, accountid, pvu_sub_estado__c, pvu_level2__c, status, 
                                 casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c
                                 FROM Case 
                                 WHERE  PVU_Level3__c =: vozCliente AND accountid =: accountId 
                                 AND (status = 'Abierto' OR status = 'En curso') WITH USER_MODE];

        if(casesList.size() != 0){
            outMap.put('caseId',casesList[0].Id);            
            outMap.put('caseNumber',casesList[0].CaseNumber);
        }
        outMap.put('openCases',casesList); 
        outMap.put('openCasesSize',casesList.size());
        
        List<vlocity_cmt__PriceListEntry__c> priceList =  [SELECT id FROM vlocity_cmt__PriceListEntry__c
                                 WHERE  vlocity_cmt__IsActive__c = true AND 
                                 vlocity_cmt__EffectiveUntilDate__c = null AND 
                                 vlocity_cmt__ProductId__c =: productId 
                                 AND (vlocity_cmt__ProductId__r.vlocity_cmt__SellingEndDate__c = null OR vlocity_cmt__ProductId__r.vlocity_cmt__SellingEndDate__c >=:System.now()) 
                                 AND (vlocity_cmt__ProductId__r.vlocity_cmt__SellingStartDate__c = null OR vlocity_cmt__ProductId__r.vlocity_cmt__SellingStartDate__c <=:System.now()) 
                                 AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null AND vlocity_cmt__PromotionId__c = null 
                                 WITH USER_MODE LIMIT 1];
        
        outMap.put('priceList',priceList); 
        outMap.put('priceListSize',priceList.size());
      
    }

    /* Dev: Sara Garrido
     * Descripcion: Metodo para validación especial de Cambio de Plan desde Acciones Inmediatas
     * Fecha: 21/03/2025
     * Input: AssetId
     * Output: Lista del caso Cerrado para la linea con la misma subcategoria de Cambio de Plan, 
     *          con una de los siguientes códigos de cierre "Cliente desiste de la solicitud" o "Falla de ejecución"
    */
    public void cambioPlanAccInmediatas( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String assetId = (String)input.get('AssetId');
        String stringStartDate = (String)input.get('startDate');
        String stringEndDate = (String)input.get('endDate');
        Date dateStart = Date.valueOf(stringStartDate);
        Date dateEnd = Date.valueOf(stringEndDate);
        Datetime startDT = Datetime.newInstanceGMT(dateStart.year(), dateStart.month(), dateStart.day(), 0, 0, 0);
        Datetime endDT = Datetime.newInstanceGMT(dateEnd.year(), dateEnd.month(), dateEnd.day(), 23, 59, 59);
        List<Case> casesList =  [SELECT id, PVU_Order__c, PVU_Order__r.Id, PVU_Order__r.OM_OrderError__c, accountid,PVU_Codigo_de_Cierre__c, pvu_sub_estado__c, pvu_level2__c, status, 
                                    casenumber,assetid,account.name,asset.name, account.FVU_DocumentType__c, account.FVU_DocumentNumber__c,
                                    PVU_NumeroLinea__c, Descripcion__c, PVU_Nuevo_plan_comprado__c
                                    FROM Case 
                                    WHERE  pvu_level2__c = 'Cambio de plan'
                                    AND (PVU_Codigo_de_Cierre__c = 'Cliente desiste de la solicitud' OR 
                                    PVU_Codigo_de_Cierre__c = 'Falla de ejecución') AND assetid =: assetId
                                    AND CreatedDate >=: startDT AND CreatedDate <=: endDT
                                    WITH USER_MODE
                                    ORDER BY CreatedDate DESC 
                                    LIMIT 1];
        
        List<OrderItem> oiList = new List<OrderItem>();
        List<Object> orderDataList = new List<Object>();

        if(casesList.size() > 0){
            oiList = [SELECT Id, Product2.name
                    FROM OrderItem 
                    WHERE OrderId =: casesList.get(0).PVU_Order__c AND 
                    (vlocity_cmt__ParentItemId__c = null OR  vlocity_cmt__ReliesOnItemId__c != null) AND vlocity_cmt__Action__c = 'Add'
                    WITH USER_MODE];
            for(OrderItem oInfo : oiList){
                Map<String, Object> obj = new Map<String, Object>();
                obj.put('productName', oInfo.Product2.Name);
                orderDataList.add(obj);                
            }
        }
                                    
        outMap.put('closedCases',casesList);
        outMap.put('closedCasesSize',casesList.size());
        outMap.put('lastOrder', orderDataList);
        outMap.put('lastOrderId', casesList[0].PVU_Order__r.Id);
        outMap.put('lastOrderError', casesList[0].PVU_Order__r.OM_OrderError__c);
    }
    
    public void devolucionObtenerAssetPQR( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String nr = String.valueOf(input.get('NR'));

        List<PVU_CasesAssets__c> caseAssetRelations = [SELECT PVU_RelatedAsset__r.Id, PVU_RelatedAsset__r.Name, PVU_RelatedAsset__r.Status, PVU_RelatedAsset__r.Product2.vlocity_cmt__Type__c, 
                                                        PVU_RelatedAsset__r.PVU_IMEI__c, PVU_RelatedAsset__r.PVU_Serial__c, PVU_RelatedAsset__r.FIN_IdReferenciaDelCredito92__c, 
                                                        PVU_RelatedCase__r.AccountId, PVU_RelatedCase__r.PVU_CUN__c, PVU_RelatedCase__r.PVU_NR__c, PVU_RelatedAsset__r.AccountId,
                                                        PVU_RelatedAsset__r.vlocity_cmt__AssetReferenceId__c, PVU_RelatedAsset__r.FIN_NumeroDeCredito__c, PVU_RelatedAsset__r.vlocity_cmt__BillingAccountId__r.OM_BSCSID__c,
                                                        PVU_RelatedAsset__r.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, PVU_RelatedAsset__r.FIN_NumeroDeCuenta__c
                                                       FROM PVU_CasesAssets__c
                                                       WHERE PVU_RelatedCase__r.AccountId = :accountId 
                                                       AND PVU_RelatedCase__r.PVU_NR__c = :nr
                                                       AND PVU_RelatedCase__r.RecordType.DeveloperName = 'GestionCasosPQR'
                                                       AND ( (PVU_RelatedAsset__r.Product2.vlocity_cmt__Type__c ='Plan' 
                                                              AND PVU_RelatedAsset__r.Product2.vlocity_cmt__ProductSpecId__c !=null )
                                                            OR (PVU_RelatedAsset__r.Product2.vlocity_cmt__Type__c ='Handset' 
                                                                OR PVU_RelatedAsset__r.Product2.vlocity_cmt__Type__c ='Tech'))
                                                        WITH USER_MODE];
        
        Map<Id, Case> uniqueCases = new Map<Id, Case>();

        for (PVU_CasesAssets__c relation : caseAssetRelations) {
            Case cas = relation.PVU_RelatedCase__r;
            if (cas != null) {
                uniqueCases.put(cas.Id, cas);
            }
        }
        
        List<case> finalCase = uniqueCases.values();
                
        List<Asset> finalAssets = new List<Asset>();
        
        for (PVU_CasesAssets__c relation : caseAssetRelations) {
            if (relation.PVU_RelatedAsset__r != null ) {
                finalAssets.add(relation.PVU_RelatedAsset__r);
            }
        }
                
        outMap.put('Cases',finalCase);
        outMap.put('CasesAssets',finalAssets);
        outMap.put('CasesAssetsSize', finalAssets.size());
    }

    public void devolucionObtenerAssetSF( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String caseNum = String.valueOf(input.get('CaseNumber'));
        
        List<Case> casoAsset = [SELECT id, PVU_Level3__c, FIN_Numero_de_tratamiento_Nota_credito__c, PVU_NoNotaCredito__c, 
                                AssetId, Asset.Name, Asset.Status, Asset.Product2.vlocity_cmt__Type__c, 
                                Asset.PVU_IMEI__c, Asset.PVU_Serial__c, Asset.FIN_IdReferenciaDelCredito92__c, 
                                Asset.AccountId,Asset.vlocity_cmt__AssetReferenceId__c, Asset.FIN_NumeroDeCredito__c, Asset.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, Asset.FIN_NumeroDeCuenta__c
                                FROM Case 
                                WHERE CaseNumber =: caseNum 
                               AND AccountId =:accountId 
                               WITH USER_MODE];
        
        outMap.put('Cases',casoAsset);
        outMap.put('CasesAssets',casoAsset.isEmpty()? new List<Asset>() : new List<Asset> {casoAsset[0].Asset});
        outMap.put('CasesAssetsSize', casoAsset.isEmpty()? 0 : casoAsset.size());
    }
    
    public void devolucionObtenerAssetSaldoFin( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String nroCredito = String.valueOf(input.get('NroCredito'));
        
        List<Case> casoAsset = [SELECT id, PVU_Level3__c, FIN_Numero_de_tratamiento_Nota_credito__c, PVU_NoNotaCredito__c , 
                                AssetId, Asset.Name, Asset.Status, Asset.Product2.vlocity_cmt__Type__c, 
                                Asset.PVU_IMEI__c, Asset.PVU_Serial__c, Asset.FIN_IdReferenciaDelCredito92__c, Asset.FIN_NumeroDeCredito__c, 
                                Asset.AccountId,Asset.vlocity_cmt__AssetReferenceId__c
                                FROM Case 
                                WHERE FIN_NumeroCredito__c  =:nroCredito 
                                AND PVU_Level3__c = 'Eliminación de financiamiento' 
                               AND AccountId =:accountId 
                               WITH USER_MODE];
        
        outMap.put('Cases',casoAsset);
        outMap.put('CasesAssets',casoAsset.isEmpty()? new List<Asset>() : new List<Asset> {casoAsset[0].Asset});
        outMap.put('CasesAssetsSize', casoAsset.size());
    }
    
    public void devolucionObtenerAssetSaldo( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String defaultBillingAccount = String.valueOf(input.get('DefaultBillingAccount'));
        
        System.debug('devolucionObtenerAssetSaldo::');
        System.debug('accountId::'+accountId);
        System.debug('defaultBillingAccount::'+defaultBillingAccount);
        
        List<Asset> assetRecords = [SELECT Id, vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, Product2.vlocity_cmt__Type__c 
                                FROM Asset WHERE  Product2.vlocity_cmt__Type__c IN ('Handset', 'Tech') 
                                AND vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c =:defaultBillingAccount
                                AND AccountId=:accountId 
                                WITH USER_MODE
                                LIMIT 1];
        
        outMap.put('CasesAssets',assetRecords.isEmpty()? new List<Asset>() : new List<Asset> {assetRecords[0]});
        outMap.put('CasesAssetsSize', assetRecords.size());
    }
    
    public void devolucionDineroObtenerAssetSaldoFin( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String defaultBillingAccount = String.valueOf(input.get('DefaultBillingAccount'));
        
        List<Asset> assetRecords = [SELECT Id, vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, Product2.vlocity_cmt__Type__c,
                                        Name, Status, PVU_IMEI__c, PVU_Serial__c, 
                                        FIN_IdReferenciaDelCredito92__c, FIN_NumeroDeCredito__c, FIN_NumeroDeCuenta__c, 
                                        AccountId
                                FROM Asset WHERE  Product2.vlocity_cmt__Type__c IN ('Handset', 'Tech') 
                                AND FIN_IdReferenciaDelCredito92__c =:defaultBillingAccount 
                                AND AccountId=:accountId 
                                WITH USER_MODE
                                LIMIT 1];
        
        outMap.put('CasesAssets',assetRecords.isEmpty()? new List<Asset>() : new List<Asset> {assetRecords[0]});
        outMap.put('CasesAssetsSize', assetRecords.size());
    }

    public void devolucionDineroObtenerAssetSaldo( Map<String,Object> input, Map <String,Object> outMap, Map<String,Object> options){
        String accountId = (String)input.get('AccountId');
        String defaultBillingAccount = String.valueOf(input.get('DefaultBillingAccount'));
               
        List<Asset> assetRecords = [SELECT Id,  
										vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, 
    									Product2.vlocity_cmt__Type__c, vlocity_cmt__AssetReferenceId__c,
                                        Name, 
                                        Status,   
                                        AccountId 
                                        
                                FROM Asset WHERE  Product2.vlocity_cmt__Type__c ='Plan' 
                                AND vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c =:defaultBillingAccount
                                AND AccountId=:accountId 
                                WITH USER_MODE
                                LIMIT 1];
        
        outMap.put('CasesAssets',assetRecords.isEmpty()? new List<Asset>() : new List<Asset> {assetRecords[0]});
        outMap.put('CasesAssetsSize', assetRecords.size());
    }
}