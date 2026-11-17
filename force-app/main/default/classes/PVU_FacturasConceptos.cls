/**
* @description       : Clase para filtrar los conceptos por factura
* @author            : Eduardo Wentancur
* @last modified on  : 11-19-2024
* @last modified by  : Eduardo Wentancur
**/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global virtual with sharing class PVU_FacturasConceptos implements vlocity_cmt.VlocityOpenInterface {
    
    @TestVisible
    global virtual Map<String,Object> runIP(String ipName, Map<String,Object> input) {
        return (Map<String,Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
            ipName, input, new Map<String,Object>()
        );
    }
        /*******************************************************************************************************
    * @description 
    * @param methodName nombre del metodo
    * @param inputMap obtiene los parametros declarados
    * @param outMap Mapa que devuelve el resultado
    * @param options parámetros adicionales
    * @return Metodo
    */
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName == 'getFacturasConConceptos') {
            getFacturasConConceptos(input, outMap, options);
        }
        return true;
    }
	
    /*******************************************************************************************************
        * @description Método para invocar PVU_APIMCMICMSCuInInqConsOCC
        * @param inputMap obtiene los parametros declarados
        * @param outMap  Mapa que devuelve el resultado
        * @return resultado del llamado
        * @example
        * -
    */
    private void getFacturasConConceptos(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            List<Object> datos = (List<Object>) input.get('Datos');
            if (datos == null) {
                System.debug('No se encontró la key Datos en el input');
                outMap.put('FacturasConConceptos', new List<Object>());
                return;
            }

            // Recolectamos facturas
            List<Map<String, Object>> facturasEncontradas = new List<Map<String, Object>>();
            List<Map<String, Object>> invoiceNumbers = new List<Map<String, Object>>();

            for (Object obj : datos) {
                Map<String, Object> item = (Map<String, Object>) obj;
                String tipo = item.containsKey('Tipo') ? String.valueOf(item.get('Tipo')) : String.valueOf(item.get('tipo'));

                if (tipo != null && tipo.trim().toUpperCase() == 'FACTURA') {
                    String billNumber = String.valueOf(item.get('billNumber'));
                    if (String.isNotBlank(billNumber)) {
                        facturasEncontradas.add(item);
                        invoiceNumbers.add(new Map<String, Object>{ 'InvoiceNumber' => billNumber });
                    }
                }
            }

            if (invoiceNumbers.isEmpty()) {
                outMap.put('FacturasConConceptos', new List<Object>());
                return;
            }

            // Ejecutamos la IP una sola vez
            Map<String, Object> ipInput = new Map<String, Object>{
                'InvoiceNumbers' => invoiceNumbers
            };

            Map<String, Object> response = new Map<String, Object>();
            try {
                response = runIP('PVU_ConsultaFacturasDeCliente', ipInput);
                
                System.debug('Respuesta cruda de la IP (multi-factura): ' + JSON.serializePretty(response));
            } catch (Exception ipEx) {
                System.debug('Error ejecutando IP multi-factura: ' + ipEx.getMessage());
            }

            //Construimos mapa: billNumber -> nodo de respuesta
            Map<String, Object> conceptosPorFactura = new Map<String, Object>();
            if (response.containsKey('getInvoiceDetailsResponse')) {
                List<Object> detalles = (List<Object>) response.get('getInvoiceDetailsResponse');
                for (Object o : detalles) {
                    Map<String, Object> nodo = (Map<String, Object>) o;
                    String invoiceRef = String.valueOf(nodo.get('invoiceReferenceNumber'));
                    if (String.isNotBlank(invoiceRef)) {
                        conceptosPorFactura.put(invoiceRef, nodo);
                    }
                }
            }

            // Armamos la salida final
            List<Map<String, Object>> facturasResponse = new List<Map<String, Object>>();
            for (Map<String, Object> factura : facturasEncontradas) {
                String billNumber = String.valueOf(factura.get('billNumber'));
                Map<String, Object> nodoFactura = (Map<String, Object>) conceptosPorFactura.get(billNumber);

                Map<String, Object> facturaConRespuesta = new Map<String, Object>();
                facturaConRespuesta.putAll(factura);
                //facturaConRespuesta.put('Conceptos', extraerConceptos(nodoFactura));
                List<Map<String, Object>> conceptosFactura = extraerConceptos(nodoFactura);
				facturaConRespuesta.put('Conceptos', agruparInteresPorMora(conceptosFactura));

                facturasResponse.add(facturaConRespuesta);
            }

            outMap.put('FacturasConConceptos', facturasResponse);
            System.debug('Resultado final (Facturas con Conceptos mapeados): ' + JSON.serializePretty(facturasResponse));

        } catch (Exception e) {
            System.debug('Error en getFacturasConConceptos: ' + e.getMessage());
            outMap.put('error', e.getMessage());
        }
    }

    // Extrae y transforma conceptos de un nodo de factura
    private List<Map<String, Object>> extraerConceptos(Map<String, Object> facturaNodo) {
        List<Map<String, Object>> conceptos = new List<Map<String, Object>>();

        if (facturaNodo == null) return conceptos;
        if (!facturaNodo.containsKey('servicesDetails')) return conceptos;

        Map<String, Object> servicesDetails = (Map<String, Object>) facturaNodo.get('servicesDetails');
        if (servicesDetails == null || !servicesDetails.containsKey('detail')) return conceptos;

        Map<String, Object> detail = (Map<String, Object>) servicesDetails.get('detail');
        if (detail == null || !detail.containsKey('section')) return conceptos;

        Map<String, Object> section = (Map<String, Object>) detail.get('section');
        if (section == null || !section.containsKey('item')) return conceptos;

        List<Object> items = (List<Object>) section.get('item');
        for (Object itemObj : items) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            if (!item.containsKey('subSection')) continue;

            Map<String, Object> subSection = (Map<String, Object>) item.get('subSection');
            if (subSection == null || !subSection.containsKey('item')) continue;

            List<Object> subItems = (List<Object>) subSection.get('item');
            for (Object subItemObj : subItems) {
                Map<String, Object> subItem = (Map<String, Object>) subItemObj;
                if (!subItem.containsKey('invoiceItem')) continue;
            
                Map<String, Object> invoiceItem = (Map<String, Object>) subItem.get('invoiceItem');
                if (invoiceItem == null || !invoiceItem.containsKey('item')) continue;
            
                List<Object> conceptosRaw = (List<Object>) invoiceItem.get('item');
            
                
                String servicioFromPrintBox = '';
                if (item.containsKey('printBoxDes')) {
                    // Nivel general (ej: "Móvil", "Otros Servicios")
                    servicioFromPrintBox = String.valueOf(item.get('printBoxDes'));
                } else if (subItem.containsKey('printBoxDes')) {
                    // Nivel más específico (ej: "Cargos Fijos Móviles")
                    servicioFromPrintBox = String.valueOf(subItem.get('printBoxDes'));
                }

            
                for (Object conceptoObj : conceptosRaw) {
                    Map<String, Object> conceptoRaw = (Map<String, Object>) conceptoObj;
            
                    Map<String, Object> concepto = new Map<String, Object>();
                    concepto.put('IMPOConsumo', conceptoRaw.get('ipc'));
                    concepto.put('impRegional', '');
                    concepto.put('valorOriginal', conceptoRaw.get('orginalAmount'));
                    concepto.put('concepto', conceptoRaw.get('chargeType'));
                    concepto.put('valorTotal', conceptoRaw.get('totalAmount'));
                    concepto.put('otrosImpuestos', conceptoRaw.get('otherTax'));
                    concepto.put('descuento', conceptoRaw.get('discount'));
                    concepto.put('IVA', conceptoRaw.get('iva'));
                    concepto.put('servicio', servicioFromPrintBox);
                    concepto.put('descripcion', conceptoRaw.get('spDescription'));
                    concepto.put('fechaInicio', conceptoRaw.get('startDate'));
                    concepto.put('fechaFin', conceptoRaw.get('endDate'));
                    concepto.put('productOffering', conceptoRaw.get('productOffering'));
            
                    conceptos.add(concepto);
                }
            }

        }
        return conceptos;
    }
    
    // Convertir Object a Decimal
    private Decimal toDecimal(Object value) {
        if (value == null) return 0;
        
        if (value instanceof Decimal) {
            return (Decimal) value;
        }
        
        String s = String.valueOf(value);
        
        if (String.isBlank(s)) return 0;
        
        try {
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return 0;
        }
    }
    
    private List<Map<String, Object>> agruparInteresPorMora(List<Map<String, Object>> conceptos) {
        
        List<Map<String, Object>> resultado = new List<Map<String, Object>>();
        
        if (conceptos == null || conceptos.isEmpty()) {
            return resultado;
        }
    
        // Acumulador para "Interés por Mora"
        Decimal moraValorOriginal   = 0;
        Decimal moraValorTotal      = 0;
        Decimal moraIva             = 0;
        Decimal moraImpoConsumo     = 0;
        Decimal moraOtrosImpuestos  = 0;
        Decimal moraDescuento       = 0;
    
        Map<String, Object> moraBase;
    
        for (Map<String, Object> c : conceptos) {
            String description = (String) c.get('descripcion');

            if (description != null && description.equalsIgnoreCase('Interés por Mora')) {

                if (moraBase == null) {
                    moraBase = new Map<String, Object>();
                    moraBase.putAll(c);
                }
    
                moraValorOriginal   += toDecimal(c.get('valorOriginal'));
                moraValorTotal      += toDecimal(c.get('valorTotal'));
                moraIva             += toDecimal(c.get('IVA'));
                moraImpoConsumo     += toDecimal(c.get('IMPOConsumo'));
                moraOtrosImpuestos  += toDecimal(c.get('otrosImpuestos'));
                moraDescuento       += toDecimal(c.get('descuento'));
    
            } else {
                resultado.add(c);
            }
        }
    
        if (moraBase != null) {
            moraBase.put('valorOriginal',  moraValorOriginal);
            moraBase.put('valorTotal',     moraValorTotal);
            moraBase.put('IVA',            moraIva);
            moraBase.put('IMPOConsumo',    moraImpoConsumo);
            moraBase.put('otrosImpuestos', moraOtrosImpuestos);
            moraBase.put('descuento',      moraDescuento);
    
            resultado.add(moraBase);
        }
    
        return resultado;
    }

}