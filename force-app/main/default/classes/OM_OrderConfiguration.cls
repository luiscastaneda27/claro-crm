/*--------------------------------------------------------------------------
Author:         Ashish Paymode - apaymode@salesforce.com
Company:        Salesforce.com
Description:    Allows the Orchestration Item Auto Task called Configuration to execute the required information setup to ease the  
                query and view of data in proceses, reports and dashboards.
Test Class:     OM_OrderConfiguration_Test
Code Coverage:  86%
History
<Date>            <Version>  <Author>                          <Description>             					
17-May-24         1.0.0      Ashish Paymode                    Initial                   					
22-May-24         1.0.1      Gabriel Alvis                     HDU 562582                					
03-Jul-24         1.0.2      Karen Sanchez (karsanchez)        HDU 335666                					
09-Jul-24		  1.0.3      Hever Salas					   HDU-335797				  					
22-Jul-24		  1.0.4      Hever Salas			           Se agrega nuevo valor del ProductCode para SIM Card		
31-Jul-24		  1.0.5      Hever Salas			           Se coloca condicion para actualizar fecha de portout	
20-Ago-24		  1.0.6      Karen Sanchez			           HDU-345283: Se coloca condicion para actualizar fecha de negación de portout	
17-Sep-24		  1.0.7      Karen Sanchez			           HDU-413297: Se crea nuevo método ""processFulfilmentRequest"", nueva instancia para crear un fulfillment y actualizar los datos de la orden para vusaulizarlos en el reporte de las ordenes
27-Sep-24		  1.0.8		 Hever Salas					   HDU-407460: No se realiza flujo simplificado para Action Change con Subaction ChangeService-Product
13-Mar-25		  1.0.9      Karen Sanchez			           BUG-564960: Se cambian las restructuran las condiciones  para cuando el OrderItem es un SIM e SIM
14-Abr-25         1.1        Hever Salas      	               BUG-588377: BUG - QA - No se genera correctamente el JSON para el flujo de cesion de contrato
21-Abr-25         1.2        Hever Salas      	               HDU-577070: [CESION]Validacion end to end cesion de contrato
12-May-25		  1.2.1      Karen Sanchez			           HDU-580978: Se crea nuevo método "asignarFechaDesact", para agregar 90 días a la fecha actual si fechaFinCanc cumple con las condiciones en el campo CASEINFO de la order
16-Sep-25         2.0        Hever Salas      	               HDU-652170: [CONCILIACION INNOVACION ]-Optimización conciliación SVA -Ofertas incluidas con serv movil
27-Oct-25         2.1        Hever Salas      	               HDU-660988: [EvolutivoOM] Configuracion SLA por Orden según su Tipo y Subtipo
06-Nov-25         2.2        Hever Salas      	               HDU-660988: Optimización vista de ordenes-tableros y reportes
10-Dic-25         2.3        Hever Salas      	               HDU-623007: [EVOLUTIVO OM] Validacion consistencia carrito
21-Ene-26		  2.4        Hever Salas      	               BUG-715760: Retención - Cuando agrego un producto de CFM en proceso de retención entonces el plan de orquestación falla con error "No existe cambio relevante"
----------------------------------------------------------------------------*/

global with sharing class OM_OrderConfiguration implements Database.AllowsCallouts, vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    public static final String KEY_FECHAFINCANC = 'fechaFinCanc';                        // v 1.5

    class notificationException extends Exception{}

    @testVisible
    private static List<OM_SLAsOrdenes__mdt> lstSlasOrdenes {
        get {
            if (lstSlasOrdenes == null) {
                lstSlasOrdenes = [
                    SELECT OM_SubtipoOrden__c, OM_TiempoMaximo__c, OM_TipoOrden__c, OM_UnidadTiempoSLAs__c 
                    FROM OM_SLAsOrdenes__mdt WITH SECURITY_ENFORCED
                ];
            }
            return lstSlasOrdenes;
        }
        set;
    }

    global void executeBatch(List <vlocity_cmt__OrchestrationItem__c> item) {
        OrderIntegrationSystemInterfaceUtility.getOMEricsonActionDerivation();
        
        //Update FRL for EOC
        updateEOCinFRL(item[0].vlocity_cmt__OrchestrationPlanId__c);
        
        // Get the Fulfilment Request Lines related to the Orchestration Plan - V. 1.0.1
        Map<Id, vlocity_cmt__FulfilmentRequestLine__c> fulfilmentReqLinesXOrchPlan = new Map<Id, vlocity_cmt__FulfilmentRequestLine__c>([
            SELECT Id
            FROM vlocity_cmt__FulfilmentRequestLine__c
            WHERE Id IN (SELECT vlocity_cmt__FulfilmentRequestLineId__c 
                         FROM vlocity_cmt__OrchestrationItem__c 
                         WHERE vlocity_cmt__OrchestrationPlanId__c = :item[0].vlocity_cmt__OrchestrationPlanId__c ) WITH SECURITY_ENFORCED
        ]);
                
        /* Set completion date, Due Date on Order which will be used to calculate Jeopardy status */
        Order orderDetails = searchOrder(item[0]);

        if(orderDetails.Type == OrderIntegrationSystemInterfaceConstants.ORDER_TYPE_CESION){
            updateICCIDCesion(orderDetails);
        }
        
        if(orderDetails.FVU_OrderSubType__c == OrderIntegrationSystemInterfaceConstants.getValue('ORDER_SUBTYPE_CONC_RED')){
            updateFRLProductsIncluded(orderDetails.Id);
        }
       
        // Extracts the Decomposition Relationship between Order Items and Fulfilment Request Lines - V. 1.0.1
        List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> fulfilmentReqLinDecompositionRel = [
            SELECT 
                vlocity_cmt__SourceOrderItemId__c, vlocity_cmt__SourceOrderItemId__r.Product2.ProductCode, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ParentItemId__c,
                vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c, vlocity_cmt__SourceOrderItemId__r.Product2.Family, 
                vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SerialNumber__c, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__AttributeSelectedValues__c,
                vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SubscriptionId__r.OM_Contract__c, vlocity_cmt__DestinationFulfilmentRequestLineId__c,
                vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__Action__c, vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__SubAction__c,
                vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.Name, vlocity_cmt__SourceOrderItemId__r.OM_newICCID__c,
                vlocity_cmt__SourceOrderItemId__r.FVU_ReasonCode__c
            FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c
            WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c = :item[0].vlocity_cmt__OrchestrationPlanId__c WITH SECURITY_ENFORCED
            ORDER BY vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Action__c DESC
        ];

        Map<Id, List<OrderItem>> fulfilmentReqLineId_OrderItems = new Map<Id, List<OrderItem>>();
        for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c fRLDR: fulfilmentReqLinDecompositionRel){
            // The relationships in scope are: the ones with Fulfilment Request Lines referenced in the Orchestration Plan - V. 1.0.1
            if(fulfilmentReqLinesXOrchPlan.containsKey(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c)){
                // Mapping of Fulfilment Request Line and their related Order Items
                if(!fulfilmentReqLineId_OrderItems.containsKey(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c)){
                    fulfilmentReqLineId_OrderItems.put(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c, new List<OrderItem>{fRLDR.vlocity_cmt__SourceOrderItemId__r});
                }
                else{
                    fulfilmentReqLineId_OrderItems.get(fRLDR.vlocity_cmt__DestinationFulfilmentRequestLineId__c).add(fRLDR.vlocity_cmt__SourceOrderItemId__r);
                }
            }
        }
		Set<String> simCardProductCodes = new Set<String>{OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD, OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD, 'B2C-ATTR-SIM-MATERIAL'};
        for(Id fRLId: fulfilmentReqLineId_OrderItems.keySet()){
            Set<String> mSISDNs = new Set<String>();
            Set<String> iCCIDs = new Set<String>();
            Set<String> iCCIDOlds = new Set<String>();
            Set<String> families = new Set<String>();
            Set<String> contractIds = new Set<String>();
            Set<String> reasonCodes = new Set<String>();
            for(OrderItem orderItemRel: fulfilmentReqLineId_OrderItems.get(fRLId)){
                if(orderItemRel.vlocity_cmt__ParentItemId__c == null && orderItemRel.vlocity_cmt__ReliesOnItemId__c == null){
                    families.add(orderItemRel.Product2.Family);
                    contractIds.add(orderItemRel.vlocity_cmt__SubscriptionId__r.OM_Contract__c);
                    reasonCodes.add(orderItemRel.FVU_ReasonCode__c);
                }
                if(orderItemRel.Product2.ProductCode == OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER) {
                    Map<String, Object> oIAttributes = (Map<String, Object>) JSON.deserializeUntyped(orderItemRel.vlocity_cmt__AttributeSelectedValues__c);
                    mSISDNs.add(String.valueOf(oIAttributes.get(OrderIntegrationSystemInterfaceConstants.ATTR_MSISDN)));
                } else if (simCardProductCodes.contains(orderItemRel.Product2.ProductCode)) {// Verificar si el producto es una tarjeta SIM 
                    Boolean isChangeAction = orderItemRel.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_CHANGE;
                    Boolean isDisconnectAction = orderItemRel.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_DISCONNECT;
                    Boolean isChangeSimSubAction = orderItemRel.vlocity_cmt__SubAction__c.contains(OrderIntegrationSystemInterfaceConstants.ORD_SUBTYPE_CHANGESIM);
                    Boolean hasSerialNumber = String.isNotBlank(orderItemRel.vlocity_cmt__SerialNumber__c);
                    Boolean hasNewICCID = String.isNotBlank(orderItemRel.OM_newICCID__c);

                    if (isChangeAction && isChangeSimSubAction && hasNewICCID) { // Procesar el nuevo ICCID para operaciones de cambio
                        iCCIDs.add(orderItemRel.OM_newICCID__c);
                    } else if ((isChangeAction || isDisconnectAction) && isChangeSimSubAction && hasSerialNumber) {// Procesar el ICCID antiguo en casos específicos
                        iCCIDOlds.add(orderItemRel.vlocity_cmt__SerialNumber__c);
                    } else if (hasSerialNumber) {// Para cualquier otro caso con número de serie, añadir a ICCIDs
                        iCCIDs.add(orderItemRel.vlocity_cmt__SerialNumber__c);
                    }
                }
            }
            processFulfilmentRequest(fRLId, mSISDNs, iCCIDs, iCCIDOlds, families, contractIds, orderDetails, reasonCodes);
        }
        System.debug('orderDetails:' +orderDetails);
        if(orderDetails != null && String.isNotBlank(orderDetails.Type) && String.isNotBlank(orderDetails.FVU_OrderSubType__c)) {
            updateSLAsDueDateOrder(orderDetails);
        }
        //Se revisa que al menos un producto tecnico tenga valor de action
        validarProductosTecnicos(item[0].vlocity_cmt__OrchestrationPlanId__c, item[0].Id, orderDetails.Id);
    }

    /**
    * @description: Este método crea una nueva instancia de vlocity_cmt__FulfilmentRequestLine__c con los valores proporcionados. Específicamente, asigna los valores de MSISDNs, ICCIDs, familias de productos y contratos a los campos correspondientes en el registro de la solicitud de cumplimiento.
    * @author karsanchez| 09-17-2024 
    * @param fRLId 
    * @param mSISDNs 
    * @param iCCIDs 
    * @param iCCIDOlds 
    * @param families 
    * @param contractIds
    * @param reasonCodes
    * @param orderDetails 
    **/
    public void processFulfilmentRequest(Id fRLId, Set<String> mSISDNs, Set<String> iCCIDs, Set<String> iCCIDOlds, Set<String> families, Set<String> contractIds, Order orderDetails, Set<String> reasonCodes) {
        // Prepare Fulfilment Request Lines for update based on Order Item information - V. 1.0.1
        List<vlocity_cmt__FulfilmentRequestLine__c> fulfilmentReqLineUpd = new List<vlocity_cmt__FulfilmentRequestLine__c>();
        vlocity_cmt__FulfilmentRequestLine__c fulfilmentRequestLine = createFulfilmentRequestLine(fRLId, mSISDNs, iCCIDs, families, contractIds);
        fulfilmentReqLineUpd.add(fulfilmentRequestLine);
        updateOrderDetails(orderDetails, mSISDNs, iCCIDOlds, iCCIDs, families, contractIds, reasonCodes);
        update fulfilmentReqLineUpd;
    }

    /**
    * @description: Crea un nuevo objeto vlocity_cmt__FulfilmentRequestLine__c con los datos de la orden y los valores de los atributos de los productos relacionados con la orden.
    * @author karsanchez| 09-17-2024 
    * @param fRLId 
    * @param mSISDNs 
    * @param iCCIDs 
    * @param families 
    * @param contractIds 
    * @return vlocity_cmt__FulfilmentRequestLine__c 
    **/
    private vlocity_cmt__FulfilmentRequestLine__c createFulfilmentRequestLine(Id fRLId, Set<String> mSISDNs, Set<String> iCCIDs, Set<String> families, Set<String> contractIds) {
        return new vlocity_cmt__FulfilmentRequestLine__c(
            Id = fRLId, 
            OM_MSISDN__c = String.join(mSISDNs, ';'), 
            OM_ICCID__c = String.join(iCCIDs, ';'), 
            OM_ProductFamily__c = String.join(families, ';'), 
            OM_Contract__c = String.join(contractIds, ';')
        );
    }
    
    /**
    * @description: Actualiza los campos de OrderDetails con los datos de Order Item relacionados con la orden.
    * @author karsanchez| 09-17-2024 
    * @param orderDetails 
    * @param mSISDNs 
    * @param iCCIDOlds 
    * @param iCCIDs 
    * @param families 
    * @param contractIds
    * @param reasonCodes 
    **/
    private void updateOrderDetails(Order orderDetails, Set<String> mSISDNs, Set<String> iCCIDOlds, Set<String> iCCIDs, Set<String> families, Set<String> contractIds, Set<String> reasonCodes) {
        if (orderDetails != null) {
            orderDetails.OM_MSISDN__c = String.join(mSISDNs, ';');
            orderDetails.OM_ICCIDOld__c = String.join(iCCIDOlds, ';');
            orderDetails.OM_ICCIDNew__c = String.join(iCCIDs, ';');
            orderDetails.OM_ProductFamily__c = String.join(families, ';');
            orderDetails.OM_ContractId__c = String.join(contractIds, ';');
            orderDetails.OM_ReasonCode__c = String.join(reasonCodes, ';');
        }
    }
    
    /**
    * @description: Busca la orden asociada al Orchestation plan relacionado con el Orchestation Item 
    * @author karsanchez | 07-03-2024 
    * @param OrchItem 
    * @return Order 
    **/
    public Order searchOrder(vlocity_cmt__OrchestrationItem__c orchItem) {
        List<vlocity_cmt__OrchestrationPlan__c> planList = [SELECT Id, vlocity_cmt__OrderId__c,vlocity_cmt__OrderId__r.PVU_CaseInfo__c,vlocity_cmt__OrderId__r.Type,vlocity_cmt__OrderId__r.FVU_OrderSubType__c, vlocity_cmt__OrderId__r.vlocity_cmt__SubmittedToOmDate__c, vlocity_cmt__OrderId__r.vlocity_cmt__RequestedCompletionDate__c
                                                       FROM vlocity_cmt__OrchestrationPlan__c 
                                                       WHERE Id = :orchItem.vlocity_cmt__OrchestrationPlanId__c WITH SECURITY_ENFORCED];
        vlocity_cmt__OrchestrationPlan__c planId = planList.isEmpty() ? null : planList[0];
        if (planId != null) {
            Order orderDetails = new Order();
            orderDetails.Id = planId.vlocity_cmt__OrderId__c;
            orderDetails.Type = planId.vlocity_cmt__OrderId__r.Type;
            orderDetails.FVU_OrderSubType__c = planId.vlocity_cmt__OrderId__r.FVU_OrderSubType__c;
            orderDetails.vlocity_cmt__SubmittedToOmDate__c = planId.vlocity_cmt__OrderId__r.vlocity_cmt__SubmittedToOmDate__c;
            orderDetails.vlocity_cmt__RequestedCompletionDate__c = planId.vlocity_cmt__OrderId__r.vlocity_cmt__RequestedCompletionDate__c;
            orderDetails.PVU_CaseInfo__c = planId.vlocity_cmt__OrderId__r.PVU_CaseInfo__c;
            orderDetails.vlocity_cmt__OrchestrationPlanId__c = planId.Id;
            return orderDetails;
        } else {
            return null;
        }
    }

    /**
    * @description:Actualiza el campo DueDate del objeto Order basado en configuraciones de SLAs obtenidas desde un Custom Metadata Type (OM_SLAsOrdenes__mdt).
    * Convierte el tiempo a minutos según la unidad de tiempo que se tenga en el CM. Convertir días a minutos (1 día = 1440 minutos)
    * @author karsanchez | 07-03-2024 
    * @param objOrder 
    **/
    public void updateSLAsDueDateOrder(Order objOrder) {
        try {
            asignarFechaDesact(objOrder);

            if(!lstSlasOrdenes.isEmpty()) {
                Map<String, Object> mapSlasOrdenes = new Map<String, Object>();
                Integer tiempo = 0;
                String unidadDeTiempo = '';
                Integer tiempoDefault;
                String unidadDeTiempoDefault;
                Boolean isNotValueDefault = false;
                for (OM_SLAsOrdenes__mdt item : lstSlasOrdenes) {
                    if(item.OM_TipoOrden__c == objOrder.Type && item.OM_SubtipoOrden__c == objOrder.FVU_OrderSubType__c){
                        tiempo = Integer.valueOf(item.OM_TiempoMaximo__c);
                        unidadDeTiempo = (String)item.OM_UnidadTiempoSLAs__c;
                        isNotValueDefault = true;
                        break;
                    }
                    if(item.OM_TipoOrden__c == OrderIntegrationSystemInterfaceConstants.getValue('DEFAULT_STR') && item.OM_SubtipoOrden__c == OrderIntegrationSystemInterfaceConstants.getValue('DEFAULT_STR')){
                        tiempoDefault = Integer.valueOf(item.OM_TiempoMaximo__c);
                        unidadDeTiempoDefault = (String)item.OM_UnidadTiempoSLAs__c;
                    }
                }
                if(!isNotValueDefault){
                    tiempo = tiempoDefault;
                    unidadDeTiempo = unidadDeTiempoDefault;
                }
            	
                if (unidadDeTiempo.equalsIgnoreCase('segundos')) {
                    tiempo /= 60;
                } else if (unidadDeTiempo.equalsIgnoreCase('minutos')) {
                    tiempo *= 1;
                } else if (unidadDeTiempo.equalsIgnoreCase('horas')) {
                    tiempo *= 60; 
                } else if (unidadDeTiempo.equalsIgnoreCase('días')) {
                    tiempo *= 1440; 
                }
                
                if(objOrder.Type == OrderIntegrationSystemInterfaceConstants.PORTABILITY_TYPE  && (objOrder.FVU_OrderSubType__c == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBTYPE || objOrder.FVU_OrderSubType__c == OrderIntegrationSystemInterfaceConstants.PORTABILITY_SUBTYPEREINST) ){ //HDU-345283
                    objOrder.vlocity_cmt__RequestedCompletionDate__c = String.isNotBlank(String.valueOf(objOrder.OM_PortOutDateStart__c)) ? objOrder.OM_PortOutDateStart__c.addMinutes(tiempo) : null;
                } else{
                    objOrder.vlocity_cmt__RequestedCompletionDate__c = String.isNotBlank(String.valueOf(objOrder.vlocity_cmt__SubmittedToOmDate__c.addMinutes(tiempo))) ? objOrder.vlocity_cmt__SubmittedToOmDate__c.addMinutes(tiempo) : null;
                }           
            }
            update objOrder;
        } catch (Exception err) {

        }
    }

    /**
    * @description: Asigna la fecha de finalización de cancelación en el campo PVU_CaseInfo__c del objeto Order,
    * si el subtipo del pedido está configurado para requerir esta vigencia. La fecha se calcula sumando una cantidad
    * de días configurable (desde Custom Metadata Type) a la fecha actual. Si el campo ya contiene un JSON válido,
    * se valida la existencia de la clave correspondiente; en caso contrario, se genera un nuevo JSON.
    * @author karsanchez | 12-05-2025
    * @param objOrder Objeto Order al que se le asignará la fecha de finalización de cancelación.
    */
    public void asignarFechaDesact(Order objOrder) {
        // Validar si la orden cumple con los criterios de tipo y subtipo
        if (!esTipoOrdenValido(objOrder.Type) || !esSubtipoOrdenValido(objOrder.FVU_OrderSubType__c)) {
            return;
        }
        actualizarCaseInfoConFechaFinCanc(objOrder);
    }

    /**
    * Verifica si el tipo de orden está en la lista de tipos permitidos para vigencia de cancelación.
    * @param tipoOrden El tipo de orden a validar
    * @return true si el tipo de orden es válido, false en caso contrario
    */
    private Boolean esTipoOrdenValido(String tipoOrden) {
        return esValorPermitido(tipoOrden, 'TiposVigenciaCancelacion');
    }

    /**
    * Verifica si el subtipo de orden está en la lista de subtipos permitidos para vigencia de cancelación.
    * @param subtipoOrden El subtipo de orden a validar
    * @return true si el subtipo de orden es válido, false en caso contrario
    */
    private Boolean esSubtipoOrdenValido(String subtipoOrden) {
        return esValorPermitido(subtipoOrden, 'SubtiposVigenciaCancelacion');
    }

    /**
    * Verifica si un valor está en la lista de valores permitidos según una clave de configuración.
    * @param valor El valor a verificar
    * @param claveConfiguracion La clave de configuración que contiene los valores permitidos
    * @return true si el valor está en la lista, false en caso contrario
    */
    @testVisible
    private Boolean esValorPermitido(String valor, String claveConfiguracion) {
        String valoresPermitidos = OrderIntegrationSystemInterfaceConstants.getValue(claveConfiguracion);
        if (String.isBlank(valoresPermitidos)) {
            return false;
        }
        
        List<String> listaValores = new List<String>();
        for (String itemValor : valoresPermitidos.split(',')) {
            listaValores.add(itemValor.trim());
        }
        return listaValores.contains(valor);
    }

    /**
    * Actualiza el campo PVU_CaseInfo__c de la orden con la fecha de fin de cancelación.
    * @param objOrder La orden a actualizar
    */
    private void actualizarCaseInfoConFechaFinCanc(Order objOrder) {
        String caseInfo = objOrder.PVU_CaseInfo__c;
        
        // Si no existe case info, crear uno nuevo
        if (String.isBlank(caseInfo)) {
            objOrder.PVU_CaseInfo__c = generarNuevoJsonConFechaFinCanc(null);
            System.debug(LoggingLevel.DEBUG, 'objOrder actualizado: ' + objOrder);
            return;
        }
        
        try {
            Map<String, Object> caseInfoMap = (Map<String, Object>) JSON.deserializeUntyped(caseInfo);
            
            // Si no existe la clave o está vacía, generar uno nuevo
            if (!caseInfoMap.containsKey(KEY_FECHAFINCANC) || 
                String.isBlank(String.valueOf(caseInfoMap.get(KEY_FECHAFINCANC)))) {
                objOrder.PVU_CaseInfo__c = generarNuevoJsonConFechaFinCanc(caseInfoMap);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error al parsear JSON: ' + ex.getMessage());
            objOrder.PVU_CaseInfo__c = generarNuevoJsonConFechaFinCanc(null);
        }
    }

    /**
    * @description: Genera un JSON que incluye la fecha de finalización de cancelación (KEY_FECHAFINCANC),
    * calculada sumando una cantidad de días configurable (obtenida desde un Custom Metadata Type) a la fecha actual.
    * Si se proporciona un mapa existente, se agrega o actualiza la clave correspondiente; de lo contrario, se crea uno nuevo.
    * @author karsanchez | 12-05-2025
    * @param existingData Mapa existente con datos previos del campo PVU_CaseInfo__c, puede ser null.
    * @return String JSON serializado con la clave KEY_FECHAFINCANC y su valor correspondiente.
    */
    private String generarNuevoJsonConFechaFinCanc(Map<String, Object> existingData) {
        String diasStr = OrderIntegrationSystemInterfaceConstants.getValue('DiasVigenciaCancelacion');
        Integer dias = String.isNotBlank(diasStr) ? Integer.valueOf(diasStr) : 0;
        DateTime fechaFinCanc = DateTime.now().addDays(dias);

        if (existingData == null) {
            existingData = new Map<String, Object>();
        }
        existingData.put(KEY_FECHAFINCANC, fechaFinCanc.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
        return JSON.serialize(existingData);
    }
    
    /**
    * @description: Verifica si existe algun producto que no necesite EOC 
    * @author Hever Salas | 09-07-2024 
    * @param OrchesPlanId 
    **/
    public void updateEOCinFRL(String OrchesPlanId) {
		Boolean isNotEOC = false;
        Boolean ignoreEOC = false;
		Set<Id> lstFRLIds = new Set<Id>();
        try {
            
            List<OrderItem> lstOi = [SELECT Id, vlocity_cmt__Action__c, vlocity_cmt__SubAction__c
                                    FROM OrderItem 
                                    WHERE Order.vlocity_cmt__OrchestrationPlanId__c = :OrchesPlanId WITH SECURITY_ENFORCED];
            
            for(OrderItem oi :lstOi){
                if(oi.vlocity_cmt__Action__c == OrderIntegrationSystemInterfaceConstants.S_CHANGE && oi.vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_PRODUCT){
                    ignoreEOC = true;
                }
            }
            if(!ignoreEOC){
                List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> lstFRLDR = [
                    SELECT Id, vlocity_cmt__DestinationFulfilmentRequestLineId__c
                    FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c 
                    WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c = :OrchesPlanId 
                    AND vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c <> null
                    AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c <> :OrderIntegrationSystemInterfaceConstants.EOC_WITHOUTEOC
                    AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Action__c IN (:OrderIntegrationSystemInterfaceConstants.S_ADD, :OrderIntegrationSystemInterfaceConstants.S_DISCONNECT)
                    AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__SubAction__c = :OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_PRODUCT WITH SECURITY_ENFORCED];
                
                List<vlocity_cmt__FulfilmentRequestLine__c> lstFRLMovPosBasic = [SELECT Id, OM_isNotEOC__c, vlocity_cmt__SubAction__c 
                                                                                 FROM vlocity_cmt__FulfilmentRequestLine__c 
                                                                                 WHERE vlocity_cmt__Product2Id__r.Name = :OrderIntegrationSystemInterfaceConstants.TECHNICAL_PARENT_PRODUCT
                                                                                 AND vlocity_cmt__FulfilmentRequestID__c IN (SELECT Id
                                                                                                                             FROM vlocity_cmt__FulfilmentRequest__c 
                                                                                                                             WHERE vlocity_cmt__orchestrationPlanId__c = :OrchesPlanId) WITH SECURITY_ENFORCED];
                
                if(lstFRLDR.isEmpty() && lstFRLMovPosBasic[0].vlocity_cmt__SubAction__c == OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_PRODUCT) {
                    
                    for(vlocity_cmt__FulfilmentRequestLine__c itemFRLMovPosBasic :lstFRLMovPosBasic){
                        itemFRLMovPosBasic.OM_isNotEOC__c = true;
                    }
                    UPDATE lstFRLMovPosBasic;
                    
                    List<vlocity_cmt__FulfilmentRequestLineDecompRelationship__c> lstFRLDRnewFlow = [
                        SELECT Id, vlocity_cmt__DestinationFulfilmentRequestLineId__c
                        FROM vlocity_cmt__FulfilmentRequestLineDecompRelationship__c 
                        WHERE vlocity_cmt__SourceOrderItemId__r.Order.vlocity_cmt__OrchestrationPlanId__c = :OrchesPlanId 
                        AND vlocity_cmt__SourceOrderItemId__r.vlocity_cmt__ReliesOnItemId__c <> null
                        AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Product2Id__r.vlocity_cmt__SubType__c = :OrderIntegrationSystemInterfaceConstants.EOC_WITHOUTEOC
                        AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__Action__c IN (:OrderIntegrationSystemInterfaceConstants.S_ADD, :OrderIntegrationSystemInterfaceConstants.S_DISCONNECT)
                        AND vlocity_cmt__DestinationFulfilmentRequestLineId__r.vlocity_cmt__SubAction__c = :OrderIntegrationSystemInterfaceConstants.CHANGESERVICE_PRODUCT WITH SECURITY_ENFORCED];
                    
                    
                    for(vlocity_cmt__FulfilmentRequestLineDecompRelationship__c item :lstFRLDRnewFlow){
                        lstFRLIds.add(item.vlocity_cmt__DestinationFulfilmentRequestLineId__c);
                    }
                    
                    List<vlocity_cmt__FulfilmentRequestLine__c> lstFRLOthers = [SELECT Id, OM_isNotEOC__c 
                                                                                FROM vlocity_cmt__FulfilmentRequestLine__c 
                                                                                WHERE (Id IN :lstFRLIds) WITH SECURITY_ENFORCED];
                    
                    for(vlocity_cmt__FulfilmentRequestLine__c itemFRLOthers :lstFRLOthers){
                        itemFRLOthers.OM_isNotEOC__c = true;
                    }
                    UPDATE lstFRLOthers;
                }
            }
      
        } catch (Exception err) {
            
        } 
    }

    /**
    * @description: gestiona la actualizacion de la data del asset cedente hacia el nuevo
    * @author Hever Salas | 14-04-2025 
    * @param OrchesPlanId 
    **/
    public void updateICCIDCesion(Order orderDetails) {
        String caseInfo = orderDetails.PVU_CaseInfo__c;
            
        if(String.IsNotBlank(caseInfo) && caseInfo.contains('cedenteAssetId')){
                
            Map<String,Object> mapCaseInfo = (Map<String,Object>)JSON.deserializeUntyped(caseInfo);

            String strAssetReferenceId = [SELECT vlocity_cmt__AssetReferenceId__c
                                            FROM Asset
                                            WHERE Id = :(String)mapCaseInfo.get('cedenteAssetId') WITH SECURITY_ENFORCED].vlocity_cmt__AssetReferenceId__c;
            
            updateOrderItemCesion(orderDetails, strAssetReferenceId);
            updateFRLCesion(orderDetails, strAssetReferenceId);
        }
    }

    /**
    * @description: Copia los valores desde el asset cedente hacia el OrderItem nuevo
    * @author Hever Salas | 14-04-2025 
    * @param OrchesPlanId 
    **/
    public void updateOrderItemCesion(Order orderDetails, String strAssetReferenceId) {
        List<Asset> lstAsset = [SELECT Id, vlocity_cmt__AssetReferenceId__c, vlocity_cmt__SubscriptionId__r.OM_MSISDN__c, 
                                    product2.productcode, SerialNumber, vlocity_cmt__AttributeSelectedValues__c
                            FROM Asset
                            WHERE (vlocity_cmt__RootItemId__c = :strAssetReferenceId
                            OR vlocity_cmt__ReliesOnItemId__c =: strAssetReferenceId)
                            AND (Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER
                                OR Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD
                                OR Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD) WITH SECURITY_ENFORCED];

       

        if(lstAsset.size() > 0){
            List<OrderItem> lstOrderItem = [SELECT Id, product2.productcode, vlocity_cmt__SerialNumber__c, 
                                                    vlocity_cmt__AttributeSelectedValues__c
                                            FROM OrderItem
                                            WHERE OrderId = :orderDetails.Id
                                            AND (Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_MOBILE_NUMBER
                                                OR Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_SIM_CARD
                                                OR Product2.ProductCode = :OrderIntegrationSystemInterfaceConstants.PR_ESIM_CARD) WITH SECURITY_ENFORCED];
            Map<String,Object> mapAsset = new Map<String,Object>();
            for(Asset item: lstAsset){
                mapAsset.put(item.vlocity_cmt__AssetReferenceId__c, item);
            }
            for(OrderItem oiItem: lstOrderItem){
                if(mapAsset.containsKey(oiItem.product2.productcode) && mapAsset.get(oiItem.product2.productcode) != null){
                    Asset asset = (Asset)mapAsset.get(oiItem.product2.productcode);
                    oiItem.vlocity_cmt__SerialNumber__c = asset.SerialNumber;
                    oiItem.vlocity_cmt__AttributeSelectedValues__c = asset.vlocity_cmt__AttributeSelectedValues__c;
                }
            }
            UPDATE lstOrderItem;
        }
    }

    /**
    * @description: Copia los valores del inventoryitem cedente hacia los nuevos FRL
    * @author Hever Salas | 14-04-2025 
    * @param OrchesPlanId 
    **/
    public void updateFRLCesion(Order orderDetails, String strAssetReferenceId) {
        List<String> lstAttributeCodeToValue = new List<String>{'TechRCSubMarket','TechRCelectricalProfile','TechRChlrcode','TechRCiccid','TechRCimei','TechRCimsi',
                                                                'TechRCki','TechRCnumberingPlan','TechRCpin','TechRCportation_status','TechRCpuk','TechRCresourceNumber',
                                                                'TechRCserialNumber','TechRCsimCardClass','TechRCsm_id','TechRCAttrMarket','TechRCCodigoMaterial',
                                                                'TechRCCodigoMaterialHijo','TechRCMarket','TechRCNRN','TechRCNetwork','TechRCSDP_ID','TechPCcontractId'};
        List<vlocity_cmt__InventoryItem__c> lstInventoryItemInfo = [SELECT vlocity_cmt__ProductId__r.Name, vlocity_cmt__JSONAttribute__c
                                                                    FROM vlocity_cmt__InventoryItem__c 
                                                                    WHERE Id IN (SELECT vlocity_cmt__DestinationInventoryItemId__c 
                                                                                FROM vlocity_cmt__InventoryItemDecompositionRelationship__c 
                                                                                WHERE vlocity_cmt__SourceAssetId__r.vlocity_cmt__RootItemId__c = :strAssetReferenceId
                                                                                OR vlocity_cmt__SourceAssetId__r.vlocity_cmt__ReliesOnItemId__c = :strAssetReferenceId) WITH SECURITY_ENFORCED];
        
        if(lstInventoryItemInfo.size() > 0 ){
            List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = [SELECT Id, vlocity_cmt__Product2id__r.Name, vlocity_cmt__JSONAttribute__c
                                                                    FROM vlocity_cmt__FulfilmentRequestLine__c
                                                                    WHERE vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__orchestrationPlanId__c = :orderDetails.vlocity_cmt__OrchestrationPlanId__c WITH SECURITY_ENFORCED];
        
            Map<String,Object> mapInvenItem = new Map<String,Object>();
            for(vlocity_cmt__InventoryItem__c item: lstInventoryItemInfo){
                mapInvenItem.put(item.vlocity_cmt__ProductId__r.Name, item);
            }
            for(vlocity_cmt__FulfilmentRequestLine__c frlItem: lstFRL){
                if(mapInvenItem.containsKey(frlItem.vlocity_cmt__Product2id__r.Name) && mapInvenItem.get(frlItem.vlocity_cmt__Product2id__r.Name) != null){
                    OM_UpdateJsonAttribute updateJsonAttribute = new OM_UpdateJsonAttribute();
                    vlocity_cmt__InventoryItem__c frlTemporal = (vlocity_cmt__InventoryItem__c)mapInvenItem.get(frlItem.vlocity_cmt__Product2id__r.Name);
                    Map<String,Object> mapInput = new Map<String,Object>();
                    mapInput.put('lstAttributeCodeToValue',lstAttributeCodeToValue);
                    mapInput.put('jsonAttribute',(Map<String,Object>)JSON.DeserializeUntyped((String)frlTemporal.vlocity_cmt__JSONAttribute__c));
                    Map<String,Object> mapOutput = updateJsonAttribute.extractListAttributeJSON(mapInput);
                    if(!mapOutput.isEmpty()){
                        Map<String,Object> mapInputModifyJSON = new Map<String,Object>();
                        Map<String,Object> mapOutputModifyJSON = new Map<String,Object>();
                        Map<String,Object> mapOptionModifyJSON = new Map<String,Object>();
                        mapInputModifyJSON.put('mapAttributeCodeToValue',mapOutput.get('mapAttributeCodeToValue'));
                        mapInputModifyJSON.put('jsonAttribute',(Map<String,Object>)JSON.DeserializeUntyped((String)frlItem.vlocity_cmt__JSONAttribute__c));
                        updateJsonAttribute.modifyJSON(mapInputModifyJSON, mapOutputModifyJSON, mapOptionModifyJSON);
                        frlItem.vlocity_cmt__JSONAttribute__c = (String)JSON.serialize(mapOutputModifyJSON.get('JSONAttribute'));
                    }
                }
            }
            UPDATE lstFRL;
         }      
    }
    
     /**
    * @description: gestiona la actualizacion del subAction de los FRL para conciliacion de red (Productos incluidos en el plan)
    * @author Hever Salas | 16-09-2025 
    * @param OrderId 
    **/
    public void updateFRLProductsIncluded(Id OrderId) {
        List<OrderItem> lstOI = [SELECT Id, OM_ProductosIncluidosPlan__c 
                                 FROM OrderItem
                                 WHERE OrderId = :OrderId
                                 AND Product2.vlocity_cmt__Type__c = :OrderIntegrationSystemInterfaceConstants.getValue('PLAN')
                                 AND Product2.vlocity_cmt__SpecificationSubType__c = :OrderIntegrationSystemInterfaceConstants.getValue('SIMPLE')
                                 AND Product2.vlocity_cmt__ParentClassCode__c = :OrderIntegrationSystemInterfaceConstants.getValue('CODIGOCLASEPLAN') WITH SECURITY_ENFORCED
                                 LIMIT 1];
        
        if(lstOI.size() > 0){
            if(String.IsNotBlank(lstOI[0].OM_ProductosIncluidosPlan__c)){
                List<Object> lstObject = (List<Object>)JSON.deserializeUntyped(lstOI[0].OM_ProductosIncluidosPlan__c);
                List<String> lstNamePO = new List<String>();
                for(Object item :lstObject){
                    Map<String,Object> mapObject = (Map<String,Object>)item;
                    lstNamePO.add((String)mapObject.get(OrderIntegrationSystemInterfaceConstants.getValue('NOMBREPRODUCTO')));
                }
                List<vlocity_cmt__FulfilmentRequestLine__c> lstFRL = [SELECT Id, vlocity_cmt__SubAction__c
                                                                      FROM vlocity_cmt__FulfilmentRequestLine__c
                                                                      WHERE vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__OrderId__c = :OrderId
                                                                      AND vlocity_cmt__Product2Id__r.Name IN :lstNamePO WITH SECURITY_ENFORCED];
                if(lstFRL.size() > 0){
                    for(vlocity_cmt__FulfilmentRequestLine__c itemFRL :lstFRL){
                        itemFRL.vlocity_cmt__SubAction__c = OrderIntegrationSystemInterfaceConstants.getValue('CONCILE_LINE_MODIFY');
                    }
                    UPDATE lstFRL;
                }
            }
        }
    }
    
    /**
    * @description: valida que al menos 1 producto comercial tenga una action valida de operacion
    * @author Hever Salas | 09-12-2025 
    * @param planId 
    **/
    global virtual void validarProductosTecnicos(Id planId, Id orchesItemId, Id orderId){
        Boolean isValidAction = false;
        List<vlocity_cmt__FulfilmentRequestLine__c> lstFrldr = [SELECT id, vlocity_cmt__Action__c, vlocity_cmt__SubAction__c, vlocity_cmt__JSONAttribute__c, vlocity_cmt__Product2Id__r.Name
                                                       FROM vlocity_cmt__FulfilmentRequestLine__c 
                                                       WHERE vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__orchestrationPlanId__c = :planId WITH SECURITY_ENFORCED];
        
        for(vlocity_cmt__FulfilmentRequestLine__c item: lstFrldr){
            String techProductSubType = '';
            List<Object> lstAttributes = new List<Object>();
            Map<String,Object> jsonAttribute = (Map<String,Object>)JSON.deserializeUntyped(item.vlocity_cmt__JSONAttribute__c);
            lstAttributes = (List<Object>)jsonAttribute.get(OrderIntegrationSystemInterfaceConstants.getValue('CATEGORYCODE'));
            for(Object ItemAttribute: lstAttributes){
                Map<String,Object> attribute = new Map<String,Object>();
                attribute = (Map<String,Object>)ItemAttribute;
                if(attribute.get('attributeuniquecode__c') == OrderIntegrationSystemInterfaceConstants.getValue('TECHPRODUCTSUBTYPE')){
                    techProductSubType = (String)attribute.get('SegmentValue');
                    break;
                }
            }
            String ActionCalculated = OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.containskey(item.vlocity_cmt__Action__c+item.vlocity_cmt__SubAction__c+techProductSubType)?
                OrderIntegrationSystemInterfaceUtility.ericsonActionByActionSubActionSubType.get(item.vlocity_cmt__Action__c+item.vlocity_cmt__SubAction__c+techProductSubType) : '' ;
            if(ActionCalculated != OrderIntegrationSystemInterfaceConstants.getValue('ACTION_NO_CHANGE')){
                isValidAction = true;
                break;
            }
        }
        
        //Validacion de promociones de retencion en ADD
        if (isValidAction == false){
            Map<String, Object> inputParamsDR = (Map<String, Object>)JSON.deserializeUntyped('{"OrderId":"'+orderId+'"}'); 
            List<Map <String, Object>> getDRAppliedPromotion = OrderIntegrationSystemInterfaceHelper.callDrExtract(inputParamsDR, OrderIntegrationSystemInterfaceConstants.GET_DR_APPLIED_PROMOTION);
            List<Map <String, Object>> mapAppliedPromotionObsequio;
            if (getDRAppliedPromotion != null && !getDRAppliedPromotion.isEmpty()) {
                Object applPromoObseq = getDRAppliedPromotion[0].get(OrderIntegrationSystemInterfaceConstants.GIFT) ;
                if (applPromoObseq != null &&  applPromoObseq instanceof List<Map <String, Object>> ){
                    mapAppliedPromotionObsequio = (List<Map <String, Object>>)applPromoObseq; 
                }else if(applPromoObseq != null &&  applPromoObseq instanceof Map <String, Object>){ 
                    mapAppliedPromotionObsequio = new List<Map <String, Object>>();
                    mapAppliedPromotionObsequio.add((Map <String, Object>)applPromoObseq); 
                }
                if(mapAppliedPromotionObsequio != null && mapAppliedPromotionObsequio.size() > 0){
                    isValidAction = true;
                }
            }
        }
        
        if(!isValidAction){
            Order objOrder = [SELECT Type, FVU_OrderSubType__c 
                              FROM Order 
                              WHERE vlocity_cmt__OrchestrationPlanId__c = :planId WITH SECURITY_ENFORCED LIMIT 1];
            Map<String,Object> mapResult = new Map<String,Object>();
            Map<String,Object> maporderInfo = new Map<String,Object>();
            Map<String,Object> mapOrder = new Map<String,Object>();
            Map<String,Object> mapQueueInfo = new Map<String,Object>();
            mapOrder.put('Type', (String)objOrder.Type);
            mapOrder.put('SubType', (String)objOrder.FVU_OrderSubType__c);
            mapResult.put('orderInfo', maporderInfo);
            maporderInfo.put('Order', mapOrder);
            mapQueueInfo.put('Cancelacion', true);
            mapQueueInfo.put('DescripcionCancelacion', 'No existe cambio relevante en ningún producto técnico');
            mapQueueInfo.put('RazonCancelacion', 'CATRES02');           
            mapResult.put('queueInfo', mapQueueInfo);
            updateItemAsync(orchesItemId, (String)JSON.serialize(mapResult), true);
            HandledException ex = new HandledException();
            ex.setMessage('Error: No existe cambio relevante en ningún producto técnico');
            throw ex;  
        }        

    }
    
    /**
     * @author Hever Salas | 09-12-2025 
     * Asynchronous method to update an Orchestration Item.
     * This method is annotated with @future to run asynchronously and is static because it cannot reference instance variables or methods.
     * @future
     * @param item The Orchestration Item to update
     */
    @future
    global static void updateItemAsync(Id itemId, String dataCancelacion, Boolean cancelacion) {
        vlocity_cmt__OrchestrationItem__c item = new vlocity_cmt__OrchestrationItem__c();
        item.OM_Cancelacion__c = dataCancelacion == 'null' ? '' : dataCancelacion;
        item.OM_CancelarPlan__c = cancelacion;
        item.Id = itemId;
        update item;                   
    }
}