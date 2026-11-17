/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase responsable de calcular y complementar información 
 * almacenada en los objetos custom (precio iva UVT, total por producto).
 * Code Coverage: 95%
 * History  
 * <Date> 		<Author> 		<Description>	 	<Version>
 * 07-Sep-25	Hugo Revuelta	Version inicial 	1.0
 * 25-Sep-25	Nahir Arrejoria Version sprint 61

 ----------------------------------------------------------------------------*/
public with sharing class CATDataUpdateService {

    /**
     * @description Orquesta el proceso de actualización de datos.
     * Invoca los métodos para calcular y actualizar los campos requeridos.
     * @return void
     */
    public static void calculateAndUpdateData(String objetoControlId,Id idLogRecord, List<String> prodCodeList, Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode,List<vlocity_cmt__PromotionItem__c> promoItemList) {
    //public static void calculateAndUpdateData(String objetoControlId,Id idLogRecord, List<String> prodCodeList, Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode,List<vlocity_cmt__PromotionItem__c> promoItemList, String tipoExtraccion, String canales) {
        System.debug('[INFO] Iniciando el proceso de actualización de datos.');
        
        List<Product2> tytsByCode = getTyTsByProductCode(prodCodeList);
        // getPreciosPorProductosNew
        List<CAT_PreciosProductosExportados__c> preciosProductosExportadosList = getPreciosProductosExporados(prodCodeList);
 		Map<String, CAT_PreciosProductosExportados__c> precioPorProductoPL = getPreciosPorProductosPL(preciosProductosExportadosList);
        Map<String, List<CAT_PreciosProductosExportados__c>> precioPorProductoTyT = getPreciosPorProductosNew(preciosProductosExportadosList,tytsByCode);
        Map<String,List<CAT_PromocionesExportadas__c>> promocionesExportadasList = getPromocionesExportadas(prodCodeList);
        Map<String,List<CAT_PromocionesExportadas__c>> promocionesExportadasListAddons = getPromocionesExportadasAddOns(prodCodeList);
        Map<String,CAT_ProductosExportados__c> productosExportadosMap = getProductosExportados(); 
     	Map<String,CAT_PreciosProductosExportados__c> precioPorProductoPromoList = getPreciosPorPromo(preciosProductosExportadosList,tytsByCode);
        Map<String, List<CAT_PromocionesExportadas__c>> codigoPromoAddOnsMap = updatePricesAddOn(prodCodeList);
        System.debug('precioPorProductoPromo size '+ precioPorProductoPromoList.size());
        try {
            // Invoca los métodos de cálculo y actualización para cada proceso.
            
            updatePriceUVT(tytsByCode,pricesByProductCode,precioPorProductoTyT,precioPorProductoPL);
            updateTotalPrice(precioPorProductoPromoList,promoItemList,promocionesExportadasList,productosExportadosMap,codigoPromoAddOnsMap,promocionesExportadasListAddons);

            updateSuccessLogRecord('Extracción y carga de datos completada con éxito.', objetoControlId,idLogRecord);
          
            //Notificacion
            CATNotificationService.enqueue(objetoControlId);
            
            System.debug('[SUCCESS] El proceso de actualización de datos ha finalizado correctamente.');

        } catch (Exception processException) {
            System.debug('[ERROR] El proceso de actualización de datos ha fallado: ' + processException.getMessage());
            throw new CAT_TransformationException('Error en el proceso de actualización.', processException);
        }
    }
    
       // --- Helper Methods for Data Retrieval ---
    private static List<Product2> getTyTsByProductCode(List<String> prodCodeList) {
        System.debug('prodCodeList: '+ prodCodeList);
        List<Product2> productList = [
            SELECT Id, Name, ProductCode,vlocity_cmt__AttributeDefaultValues__c, vlocity_cmt__Type__c,vlocity_cmt__SpecificationSubType__c, vlocity_cmt__SubType__c, Description, Short_Description__c, Family,
                   vlocity_cmt__SellingEndDate__c, CAT_Canales__c, CAT_Proceso_Negocio__c, vlocity_cmt__SellingStartDate__c,
                   vlocity_cmt__IsOrderable__c, IsActive
            FROM Product2
            WHERE (vlocity_cmt__Type__c  = 'Handset' OR vlocity_cmt__Type__c = 'Tech')
            AND ProductCode IN :prodCodeList
            WITH SECURITY_ENFORCED
        ];
 
        return productList;
        
    }
    private static List<CAT_PreciosProductosExportados__c> getPreciosProductosExporados(List<String> prodCodeList) {
        
        List<CAT_PreciosProductosExportados__c> preciosPorProductotList = [ SELECT Id,CAT_NombrePrecioSinImpuestosPrecios__c , CAT_CodigoProductoPrecios__c,CAT_ListaPrecioPrecios__c ,CAT_InicioVigenciaPrecioConImpPrecios__c ,CAT_InicioVigenciaPrecioSinImpPrecios__c ,CAT_FinVigenciaPrecioConImpuestos__c ,CAT_FinVigenciaPrecioSinImpuestos__c , CAT_CodigoListaPrecioPrecios__c, CAT_PrecioSinImpuestosPrecios__c, CAT_PrecioConImpuestosPrecios__c, CAT_NombrePrecioConImpuestosPrecios__c FROM CAT_PreciosProductosExportados__c  WITH SECURITY_ENFORCED
        ];
        return preciosPorProductotList;
        
    }
    
    private static Map<String,List<CAT_PromocionesExportadas__c>>  updatePricesAddOn(List<String> prodCodeList){
        List<CAT_PromocionesExportadas__c> promocionesExportadasListAjustes = [ SELECT Id,CAT_CardinalidadDefault__c ,CAT_CardinalidadMaxima__c ,CAT_CardinalidadMinima__c , CAT_DescripcionPromocion__c ,CAT_Frecuencia__c,CAT_FinVigenciaPromocion__c,CAT_InicioVigenciaPromocion__c ,CAT_ValorOverridePrecioPromocion__c,CAT_CodigoPromocion__c,CAT_CodigoProductoPromocion__c,CAT_TipoProductoPromocion__c,CAT_TipoAjuste__c, CAT_ValorAjustePrecioPromocion__c,CAT_TipoBeneficioPromocion__c, CAT_TipoPromocion__c, CAT_PromocionOrderable__c, CAT_PromocionActivo__c , CAT_ProcesosNegocioPromocion__c , CAT_NombrePromocion__c , CAT_NombreProductoPromocion__c,CAT_CodigoListaPrecioPrecios__c    FROM CAT_PromocionesExportadas__c where CAT_TipoProductoPromocion__c  = 'Add On' and CAT_Frecuencia__c = 'Monthly' and CAT_ValorAjustePrecioPromocion__c != null AND CAT_CodigoPromocion__c IN :prodCodeList  WITH SECURITY_ENFORCED
        ]; 
		List<CAT_PromocionesExportadas__c> promocionesExportadasList = [ SELECT Id,CAT_CardinalidadDefault__c ,CAT_CardinalidadMaxima__c ,CAT_CardinalidadMinima__c , CAT_DescripcionPromocion__c ,CAT_Frecuencia__c,CAT_FinVigenciaPromocion__c,CAT_InicioVigenciaPromocion__c ,CAT_ValorOverridePrecioPromocion__c,CAT_CodigoPromocion__c,CAT_CodigoProductoPromocion__c,CAT_TipoProductoPromocion__c,CAT_TipoAjuste__c, CAT_ValorAjustePrecioPromocion__c,CAT_TipoBeneficioPromocion__c, CAT_TipoPromocion__c, CAT_PromocionOrderable__c, CAT_PromocionActivo__c , CAT_ProcesosNegocioPromocion__c , CAT_NombrePromocion__c , CAT_NombreProductoPromocion__c,CAT_CodigoListaPrecioPrecios__c    FROM CAT_PromocionesExportadas__c where CAT_TipoProductoPromocion__c  = 'Add On' and CAT_ValorAjustePrecioPromocion__c = null AND CAT_CodigoPromocion__c IN :prodCodeList WITH SECURITY_ENFORCED];
        Map<String, List<CAT_PromocionesExportadas__c>> codigoPromoMap = new Map<String, List<CAT_PromocionesExportadas__c>> ();
        List<String> codigosProductos = new List<String>();
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasList ){
            String codigoPromo = promoExportada.CAT_CodigoPromocion__c ;
            codigosProductos.add(promoExportada.CAT_CodigoProductoPromocion__c);
            
        }
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasListAjustes ){
            String codigoPromo = promoExportada.CAT_CodigoPromocion__c ;
            codigosProductos.add(promoExportada.CAT_CodigoProductoPromocion__c);
            
        }
       
        System.debug('++codigosProductos:' + codigosProductos);
        List<vlocity_cmt__PriceListEntry__c> priceListEntries = [
            SELECT Id, vlocity_cmt__PromotionId__c,vlocity_cmt__PromotionItemId__c,vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__IsOverride__c, vlocity_cmt__ProductId__r.Name,
                   vlocity_cmt__ProductId__r.ProductCode, vlocity_cmt__ProductId__r.vlocity_cmt__Type__c, vlocity_cmt__DisplayText__c,vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c,
                   vlocity_cmt__PricingElementAmount__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c,vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c,
                   vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.Name, vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__AdjustmentMethod__c,
                   vlocity_cmt__EffectiveFromDate__c
            FROM vlocity_cmt__PriceListEntry__c
            WHERE vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__PricingElementId__c != null
            AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            AND vlocity_cmt__ProductId__r.ProductCode IN :codigosProductos  
            AND ((vlocity_cmt__EffectiveFromDate__c <= TODAY AND (vlocity_cmt__EffectiveUntilDate__c >= TODAY OR vlocity_cmt__EffectiveUntilDate__c = null))
            OR (vlocity_cmt__EffectiveFromDate__c > TODAY) OR (vlocity_cmt__EffectiveFromDate__c = null and vlocity_cmt__EffectiveUntilDate__c = null ))
            WITH SECURITY_ENFORCED ];
        
    	Map<String, vlocity_cmt__PriceListEntry__c> plePorCodigoMap = new Map<String,vlocity_cmt__PriceListEntry__c>();
    	//Map<String, List<vlocity_cmt__PriceListEntry__c>> plePorCodigoMap1 = new Map<String,List<vlocity_cmt__PriceListEntry__c>>();
        for (vlocity_cmt__PriceListEntry__c ple : priceListEntries){
            String productCodeFrecuencia = ple.vlocity_cmt__ProductId__r.ProductCode+ple.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c;
            plePorCodigoMap.put(productCodeFrecuencia,ple);
            
        }
        List<CAT_PromocionesExportadas__c> newRecordsToUpsert = new List<CAT_PromocionesExportadas__c>();
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasList ){
            if (promoExportada.CAT_ValorAjustePrecioPromocion__c == null){
                System.debug('add on sin descuento');
                CAT_PromocionesExportadas__c originalRecord = promoExportada;
                CAT_PromocionesExportadas__c registroNuevo = originalRecord.clone(false, true, false, false);
                String searchKeyImpuestos = promoExportada.CAT_CodigoProductoPromocion__c+'Mensual con impuestos';
                String searchKeySinImpuestos = promoExportada.CAT_CodigoProductoPromocion__c+'Monthly';
                vlocity_cmt__PriceListEntry__c pleImpuestos = plePorCodigoMap.get(searchKeyImpuestos);
                vlocity_cmt__PriceListEntry__c pleSinImpuestos = plePorCodigoMap.get(searchKeySinImpuestos);
                originalRecord.CAT_DisplayNameAjustePromocion__c = pleImpuestos.vlocity_cmt__DisplayText__c;
                originalRecord.CAT_ValorAjustePrecioPromocion__c = pleImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c;	
                originalRecord.CAT_Frecuencia__c = pleImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c;
                originalRecord.CAT_CodigoListaPrecioPrecios__c = pleImpuestos.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
                registroNuevo.CAT_ValorAjustePrecioPromocion__c =  pleSinImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c;
                registroNuevo.CAT_Frecuencia__c = pleSinImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c; 
                registroNuevo.CAT_DisplayNameAjustePromocion__c = pleSinImpuestos.vlocity_cmt__DisplayText__c ;
                registroNuevo.CAT_CodigoListaPrecioPrecios__c = pleSinImpuestos.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
                newRecordsToUpsert.add(originalRecord);
                newRecordsToUpsert.add(registroNuevo);
            }
        }
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasListAjustes ) {
            System.debug('add on con descuento');
            CAT_PromocionesExportadas__c originalRecord = promoExportada;
            CAT_PromocionesExportadas__c registroNuevo = originalRecord.clone(false, true, false, false);
            CAT_PromocionesExportadas__c registroNuevo2 = originalRecord.clone(false, true, false, false);
            String searchKeyImpuestos = promoExportada.CAT_CodigoProductoPromocion__c+'Mensual con impuestos';
            String searchKeySinImpuestos = promoExportada.CAT_CodigoProductoPromocion__c+'Monthly';
            vlocity_cmt__PriceListEntry__c pleImpuestos = plePorCodigoMap.get(searchKeyImpuestos);
            vlocity_cmt__PriceListEntry__c pleSinImpuestos = plePorCodigoMap.get(searchKeySinImpuestos);
            registroNuevo2.CAT_DisplayNameAjustePromocion__c = pleImpuestos.vlocity_cmt__DisplayText__c;
            registroNuevo2.CAT_TipoAjuste__c = '';
            registroNuevo2.CAT_CodigoListaPrecioPrecios__c = pleImpuestos.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
            registroNuevo2.CAT_ValorAjustePrecioPromocion__c = pleImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c;    
            registroNuevo2.CAT_Frecuencia__c = pleImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c;
            registroNuevo.CAT_ValorAjustePrecioPromocion__c =  pleSinImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__Amount__c;
            registroNuevo.CAT_TipoAjuste__c = '';    
            registroNuevo.CAT_CodigoListaPrecioPrecios__c = pleImpuestos.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c;
            registroNuevo.CAT_Frecuencia__c = pleSinImpuestos.vlocity_cmt__PricingElementId__r.vlocity_cmt__PricingVariableId__r.vlocity_cmt__RecurringFrequency__c; 
            registroNuevo.CAT_DisplayNameAjustePromocion__c = pleSinImpuestos.vlocity_cmt__DisplayText__c ;
            newRecordsToUpsert.add(registroNuevo2);
            newRecordsToUpsert.add(registroNuevo);
            
        }
        for (CAT_PromocionesExportadas__c promoExportada : newRecordsToUpsert ){
            String codigoPromo = promoExportada.CAT_CodigoPromocion__c ;
            if(!codigoPromoMap.containsKey(codigoPromo)){
                codigoPromoMap.put(codigoPromo, new List<CAT_PromocionesExportadas__c>());
            }
            codigoPromoMap.get(codigoPromo).add(promoExportada);
        }

        upsert as user newRecordsToUpsert;   
        return codigoPromoMap;
    }       
    private static Map<String,List<CAT_PromocionesExportadas__c>> getPromocionesExportadas(List<String> prodCodeList) { 
        
        List<CAT_PromocionesExportadas__c> promocionesExportadasList = [ SELECT Id, CAT_Frecuencia__c,CAT_CodigoListaPrecioPrecios__c ,CAT_FinVigenciaPromocion__c,CAT_InicioVigenciaPromocion__c ,CAT_ValorOverridePrecioPromocion__c,CAT_CodigoPromocion__c,CAT_CodigoProductoPromocion__c,CAT_TipoProductoPromocion__c,CAT_TipoAjuste__c, CAT_ValorAjustePrecioPromocion__c,CAT_TipoBeneficioPromocion__c FROM CAT_PromocionesExportadas__c where CAT_TipoBeneficioPromocion__c = 'Bundle' AND CAT_CodigoPromocion__c IN :prodCodeList  WITH SECURITY_ENFORCED
        ];
        Map<String, List<CAT_PromocionesExportadas__c>> promocionesExportadasMap = new Map<String, List<CAT_PromocionesExportadas__c>>();
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasList) {
            String promoCode = promoExportada.CAT_CodigoProductoPromocion__c+promoExportada.CAT_CodigoListaPrecioPrecios__c;
            if(!promocionesExportadasMap.containsKey(promoCode)){
                promocionesExportadasMap.put(promoCode, new List<CAT_PromocionesExportadas__c>());
            }
            promocionesExportadasMap.get(promoCode).add(promoExportada);
            
        }
        return promocionesExportadasMap;
        
    }
    private static Map<String,List<CAT_PromocionesExportadas__c>> getPromocionesExportadasAddOns(List<String> prodCodeList) { 
        
        List<CAT_PromocionesExportadas__c> promocionesExportadasList = [ SELECT Id, CAT_Frecuencia__c,CAT_FinVigenciaPromocion__c,CAT_InicioVigenciaPromocion__c ,CAT_ValorOverridePrecioPromocion__c,CAT_CodigoPromocion__c,CAT_CodigoProductoPromocion__c,CAT_TipoProductoPromocion__c,CAT_TipoAjuste__c, CAT_ValorAjustePrecioPromocion__c,CAT_TipoBeneficioPromocion__c,CAT_CodigoListaPrecioPrecios__c FROM CAT_PromocionesExportadas__c where CAT_TipoBeneficioPromocion__c = 'Bundle' and CAT_TipoProductoPromocion__c = 'Add On' and CAT_TipoAjuste__c != null AND CAT_CodigoPromocion__c IN :prodCodeList WITH SECURITY_ENFORCED
        ];
        Map<String, List<CAT_PromocionesExportadas__c>> promocionesExportadasMap = new Map<String, List<CAT_PromocionesExportadas__c>>();
        for (CAT_PromocionesExportadas__c promoExportada : promocionesExportadasList) {
            String promoCode = promoExportada.CAT_CodigoPromocion__c+promoExportada.CAT_CodigoListaPrecioPrecios__c;
            if(!promocionesExportadasMap.containsKey(promoCode)){
                promocionesExportadasMap.put(promoCode, new List<CAT_PromocionesExportadas__c>());
            }
            promocionesExportadasMap.get(promoCode).add(promoExportada);
            
        }
        return promocionesExportadasMap;
        
    }
    private static Map<String, CAT_ProductosExportados__c> getProductosExportados() {
        List<CAT_ProductosExportados__c> productosExportadasList = [ SELECT Id,CAT_CodigoProducto__c FROM CAT_ProductosExportados__c  WITH SECURITY_ENFORCED
        ];
        Map<String, CAT_ProductosExportados__c> productosMap = new Map<String, CAT_ProductosExportados__c>();
        
        for (CAT_ProductosExportados__c prod : productosExportadasList) {
            productosMap.put(prod.CAT_CodigoProducto__c, prod);
        }
        return productosMap;
    } 
    
    private static Map<String, List<CAT_PreciosProductosExportados__c>> getPreciosPorProductosNew(List<CAT_PreciosProductosExportados__c> preciosPorProductotList, List<Product2> getTyTsByProductCode) {
        // Create a Set for efficient lookup of product codes.
        Set<String> productCodesTyT = new Set<String>();
        for (Product2 prod : getTyTsByProductCode) {
            productCodesTyT.add(prod.ProductCode);
        }
        Map<String, List<CAT_PreciosProductosExportados__c>> preciosProductoTyTMap = new Map<String, List<CAT_PreciosProductosExportados__c>>();
        
        for (CAT_PreciosProductosExportados__c precioProd : preciosPorProductotList) {
            String productCode = precioProd.CAT_CodigoProductoPrecios__c;
            if (productCodesTyT.contains(productCode)) {
                if(!preciosProductoTyTMap.containsKey(productCode)) {
                preciosProductoTyTMap.put(productCode, new List<CAT_PreciosProductosExportados__c>());
            	}
            	preciosProductoTyTMap.get(productCode).add(precioProd);
            }
            
        }
        System.debug('preciosProductoTyTMap: '+ preciosProductoTyTMap);
        return preciosProductoTyTMap;
    }  
    
    private static Map<String,CAT_PreciosProductosExportados__c> getPreciosPorPromo(List<CAT_PreciosProductosExportados__c> preciosPorProductotList,List<Product2> getTyTsByProductCode) {
        // Create a Set for efficient lookup of product codes.
        Set<String> productCodesTyT = new Set<String>();
        for (Product2 prod : getTyTsByProductCode) {
            productCodesTyT.add(prod.ProductCode);
        }
        Map<String, CAT_PreciosProductosExportados__c> preciosPromoMap = new Map<String, CAT_PreciosProductosExportados__c>();
        
        for (CAT_PreciosProductosExportados__c precioProd : preciosPorProductotList) {
            String productCodePL = precioProd.CAT_CodigoProductoPrecios__c+'+'+precioProd.CAT_CodigoListaPrecioPrecios__c+'+'+precioProd.CAT_NombrePrecioConImpuestosPrecios__c;
            String productCode = precioProd.CAT_CodigoProductoPrecios__c;
            if (!productCodesTyT.contains(productCode)) {  
				preciosPromoMap.put(productCodePL, precioProd);			
            }
            
        }
        System.debug('++preciosPromoMap: '+ preciosPromoMap.size());
        return preciosPromoMap;
    }
    
    private static Map<String,CAT_PreciosProductosExportados__c> getPreciosPorProductosPL(List<CAT_PreciosProductosExportados__c> preciosPorProductotList) {
        
        Map<String, CAT_PreciosProductosExportados__c> preciosProductoPLMap = new Map<String, CAT_PreciosProductosExportados__c>();
        
        for (CAT_PreciosProductosExportados__c precioProd : preciosPorProductotList) {
            //String precioProdkey = precioProd.CAT_CodigoProductoPrecios__c+precioProd.CAT_CodigoListaPrecioPrecios__c+precioProd.CAT_PrecioSinImpuestosPrecios__c;
            String precioProdkey = precioProd.CAT_CodigoProductoPrecios__c+precioProd.CAT_CodigoListaPrecioPrecios__c+precioProd.CAT_NombrePrecioSinImpuestosPrecios__c+precioProd.CAT_InicioVigenciaPrecioSinImpPrecios__c;
            System.debug('precioProdkey: '+ precioProdkey);
            preciosProductoPLMap.put(precioProdkey, precioProd);
        }
        return preciosProductoPLMap;
    }
    
    /**
     * @description Actualiza el precio total en los productos.
     * @return void
     */
    private static void updateTotalPrice(Map<String,CAT_PreciosProductosExportados__c> precioPorProductoPromoList,List<vlocity_cmt__PromotionItem__c> promoItemList,Map<String,List<CAT_PromocionesExportadas__c>> promocionesExportadasList,Map<String,CAT_ProductosExportados__c> productosExportadosMap,Map<String, List<CAT_PromocionesExportadas__c>> codigoPromoAddOnsMap,Map<String,List<CAT_PromocionesExportadas__c>> promocionesExportadasListAddOns) {
        System.debug('[INFO] Actualizando el precio total en los registros de precios de productos.');
        Datetime fechaActual = datetime.NOW();
        List<CAT_PreciosProductosExportados__c> recordsToUpdate = new List<CAT_PreciosProductosExportados__c>();
        Map<String, vlocity_cmt__PromotionItem__c> promoItemByCodeMap = new Map<String, vlocity_cmt__PromotionItem__c>();

        for (vlocity_cmt__PromotionItem__c promoItem : promoItemList) {
            promoItemByCodeMap.put(promoItem.vlocity_cmt__ProductId__r.ProductCode, promoItem);
        }
        List<CAT_PreciosProductosExportados__c> newRecordsToInsert = new List<CAT_PreciosProductosExportados__c>();
        List<CAT_PreciosProductosExportados__c> recordsToDelete = new List<CAT_PreciosProductosExportados__c>();

        for (String productCodePL : precioPorProductoPromoList.keySet()) {
            
            System.debug('++productCode en for: '+ productCodePL);
            List<String> parts = productCodePL.split('\\+');

            // Access the first element (the first part)
            String productCode = parts[0].trim();
            String pricelistCode = parts[1].trim();
            String productCodePLCode = productCode+pricelistCode;
            System.debug('productCodePLCode: '+ productCodePLCode );
            System.debug('productCode: '+ productCode );
            CAT_ProductosExportados__c prodExportado = productosExportadosMap.get(productCode);
            
            vlocity_cmt__PromotionItem__c promoItem = promoItemByCodeMap.get(productCode);
            if(promoItem!= null){
                System.debug(promoItem);
                CAT_PreciosProductosExportados__c originalRecord = precioPorProductoPromoList.get(productCodePL);
                if(prodExportado == null) {
                    recordsToDelete.add(originalRecord);
                    System.debug('se agrega a la lista para borrado');
                }
                if (originalRecord != null) {
                    List<CAT_PromocionesExportadas__c> promociones = promocionesExportadasList.get(productCodePLCode);
                    if(promociones != null){
                        System.debug('promociones: '+ promociones.size());     
                        //Lógica para ajustes de precio con impuestos y sin impuestos
                        Map<String,CAT_PromocionesExportadas__c> tipoPrecioPorPromo = new Map<String,CAT_PromocionesExportadas__c>();
                        Map<String,Decimal> ajustesAddonPorPromo = new Map<String,Decimal>();
                        Decimal sumaDeAjustesSinImpuestos = 0 ;
                        Decimal sumaDeAjustesImpuestos = 0 ;
                        String codigoPromocion;
                        for(CAT_PromocionesExportadas__c promoExportada : promociones) {
                            if(promoExportada.CAT_TipoProductoPromocion__c == 'Plan'){
                                codigoPromocion = promoExportada.CAT_CodigoPromocion__c;
                                String codigoFrecuencia = promoExportada.CAT_CodigoPromocion__c + promoExportada.CAT_Frecuencia__c;
                             	tipoPrecioPorPromo.put(codigoFrecuencia, promoExportada); 
                            } 
                        }
                       List<CAT_PromocionesExportadas__c> ajustesAddons = promocionesExportadasListAddOns.get(codigoPromocion);
                        
                        if (ajustesAddons!= null){
                            System.debug('ajustesAddons: ' + ajustesAddons.size());
                            System.debug('hay ajustes en addons');
                            for(CAT_PromocionesExportadas__c promoExportada : ajustesAddons) {
                                if (promoExportada.CAT_TipoProductoPromocion__c == 'Add On') {
                                    if (promoExportada.CAT_Frecuencia__c == 'Monthly'){
                                        System.debug('ajuste addon sin impuesots');
                                        sumaDeAjustesSinImpuestos = sumaDeAjustesSinImpuestos - promoExportada.CAT_ValorAjustePrecioPromocion__c ;
                                	} else {
                                    	System.debug('ajuste addon con impuesots');
                                    	sumaDeAjustesImpuestos = sumaDeAjustesImpuestos - promoExportada.CAT_ValorAjustePrecioPromocion__c ;
                                	}
                              
                            	}
                        	}
                        } 
                        
                        System.debug('++sumaDeAjustesImpuestos: '+ sumaDeAjustesImpuestos);
                        System.debug('++sumaDeAjustesSinImpuestos: '+ sumaDeAjustesSinImpuestos);
                        
                        Map<String,CAT_PromocionesExportadas__c> promoPorProducto = new Map<String,CAT_PromocionesExportadas__c>();
                        for(CAT_PromocionesExportadas__c promoExportada : promociones) {
                             promoPorProducto.put(promoExportada.CAT_CodigoPromocion__c, promoExportada);                 
                        }
                        System.debug('promoPorProducto: '+ promoPorProducto.size());
                        for(String promoCode : promoPorProducto.keySet()) {
                            Decimal addOnImpuesto = 0;
                            Decimal addOnSinImpuesto = 0;
                            List<CAT_PromocionesExportadas__c> addOns = codigoPromoAddOnsMap.get(promoCode);
                            if (addOns != null) {
                                System.debug('addOns size: '+ addOns.size());
                                for (CAT_PromocionesExportadas__c addOn : addOns) {
                                    System.debug('addon frequeny: '+ addOn.CAT_Frecuencia__c);
                                    if(addOn.CAT_Frecuencia__c == 'Monthly'){
                                        addOnSinImpuesto = addOnSinImpuesto + addOn.CAT_ValorAjustePrecioPromocion__c;
                                    } else {
                                        addOnImpuesto = addOnImpuesto + addOn.CAT_ValorAjustePrecioPromocion__c; 
                                    }
                                }
                            }
                            
                            CAT_PreciosProductosExportados__c registroActualizado = originalRecord.clone(false, true, false, false);
                            registroActualizado.CAT_Codigo_Promocion__c = promoCode;
                            System.debug('se define promo code');
                            String promoVigente = ((promoPorProducto.get(promoCode).CAT_FinVigenciaPromocion__c != null && promoPorProducto.get(promoCode).CAT_FinVigenciaPromocion__c >= fechaActual) || promoPorProducto.get(promoCode).CAT_FinVigenciaPromocion__c == null ) ? 'vigente' : 'no vigente';
                            System.debug('promoVigente: '+ promoVigente);
                            if(promoVigente == 'vigente'){
                                String tipoAjuste = promoPorProducto.get(promoCode).CAT_TipoAjuste__c;
                            	Boolean isOverride = promoPorProducto.get(promoCode).CAT_ValorOverridePrecioPromocion__c; 
                                if (isOverride){
                                    System.debug('es override');
                                    String keySearchMonthly = promoCode+'Monthly';
                                    String keySearchImpuestos = promoCode+'Mensual con impuestos';
                                    Decimal ajustePrecioSinImpuestos = tipoPrecioPorPromo.get(keySearchMonthly).CAT_ValorAjustePrecioPromocion__c + addOnSinImpuesto;
                                    Decimal ajustePrecioImpuestos = tipoPrecioPorPromo.get(keySearchImpuestos).CAT_ValorAjustePrecioPromocion__c + addOnImpuesto;
                                    registroActualizado.CAT_PrecioConImpuestosPrecios__c = ajustePrecioImpuestos;
                                    registroActualizado.CAT_PrecioSinImpuestosPrecios__c = ajustePrecioSinImpuestos;
                                    String adjustedPriceFormat = ajustePrecioImpuestos.setScale(0).format();
                                    registroActualizado.CAT_NombrePrecioConImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                    registroActualizado.CAT_NombrePrecioSinImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                                           
                                } else {
                                    System.debug('no es override');
                                    Decimal adjustedPrice;
                                    if (tipoAjuste == 'Absolute') {
                                        System.debug('es Absolute');
                                        String keySearchMonthly = promoCode+'Monthly';
                                        String keySearchImpuestos = promoCode+'Mensual con impuestos';
                                        System.debug('tipoPrecioPorPromo.get(keySearchMonthly).CAT_ValorAjustePrecioPromocion__c: '+ tipoPrecioPorPromo.get(keySearchMonthly).CAT_ValorAjustePrecioPromocion__c);
                                        System.debug('addOnSinImpuesto: '+ addOnSinImpuesto);
                                        System.debug('sumaDeAjustesSinImpuestos: '+ sumaDeAjustesSinImpuestos);
                                        Decimal ajustePrecioSinImpuestos = tipoPrecioPorPromo.get(keySearchMonthly).CAT_ValorAjustePrecioPromocion__c + addOnSinImpuesto - sumaDeAjustesSinImpuestos;
                                        Decimal ajustePrecioImpuestos = tipoPrecioPorPromo.get(keySearchImpuestos).CAT_ValorAjustePrecioPromocion__c + addOnImpuesto - sumaDeAjustesImpuestos;
                                        adjustedPrice = registroActualizado.CAT_PrecioConImpuestosPrecios__c + ajustePrecioImpuestos;
                                        registroActualizado.CAT_PrecioConImpuestosPrecios__c = registroActualizado.CAT_PrecioConImpuestosPrecios__c + ajustePrecioImpuestos;
                                        registroActualizado.CAT_PrecioSinImpuestosPrecios__c = registroActualizado.CAT_PrecioSinImpuestosPrecios__c + ajustePrecioSinImpuestos;
                                        String adjustedPriceFormat = adjustedPrice.setScale(0).format();
                                        registroActualizado.CAT_NombrePrecioConImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                        registroActualizado.CAT_NombrePrecioSinImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                        
                                    } else if (tipoAjuste == 'Percent') {
                                        System.debug('es Percent');
                                        Decimal ajustePrecioSinImpuestos = promoPorProducto.get(promoCode).CAT_ValorAjustePrecioPromocion__c;
                                        adjustedPrice = registroActualizado.CAT_PrecioConImpuestosPrecios__c - (registroActualizado.CAT_PrecioConImpuestosPrecios__c * ajustePrecioSinImpuestos / 100) + addOnImpuesto;
                                        registroActualizado.CAT_PrecioConImpuestosPrecios__c = registroActualizado.CAT_PrecioConImpuestosPrecios__c - (registroActualizado.CAT_PrecioConImpuestosPrecios__c * ajustePrecioSinImpuestos / 100);
                                        registroActualizado.CAT_PrecioSinImpuestosPrecios__c = registroActualizado.CAT_PrecioSinImpuestosPrecios__c - (registroActualizado.CAT_PrecioSinImpuestosPrecios__c * ajustePrecioSinImpuestos / 100);
                                        String adjustedPriceFormat = adjustedPrice.setScale(0).format();
                                        registroActualizado.CAT_NombrePrecioConImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                        registroActualizado.CAT_NombrePrecioSinImpuestosPrecios__c = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                                        
                                    }
                                }
                            }
                            newRecordsToInsert.add(registroActualizado);         
                        }
                    }
                           
                }
            }       
        }
   
        if (!newRecordsToInsert.isEmpty()) {
            try {
               // update recordsToUpdate;
                insert as user newRecordsToInsert;
                System.debug('[INFO] ' + recordsToUpdate.size() + ' records updated successfully.');
            } catch (DmlException e) {
                System.debug('ERROR: DML Exception occurred: ' + e.getMessage());
            }
        }
       
        if(!recordsToDelete.isEmpty()){
            try{
                delete as user recordsToDelete;
            } catch (DmlException e) {
                System.debug('ERROR: DML Exception occurred: ' + e.getMessage());
            }
        }  
        System.debug('[INFO] El proceso de actualización del precio total ha finalizado.');
    }
    

    /**
     * @description Actualiza el precio considerando o no el IVA en los registros de productos dependiendo del valor de la UVT.
     * @return void
     */
    private static void updatePriceUVT(List<Product2> tytsByCode,Map<String, List<vlocity_cmt__PriceListEntry__c>> pricesByProductCode,Map<String, List<CAT_PreciosProductosExportados__c>> precioPorProducto,Map<String,CAT_PreciosProductosExportados__c> preciosPorProductosPL) {
        System.debug('[INFO] Actualizando el IVA en los registros de productos usando el valor de la UVT.');
           
        Datetime currentTime = Datetime.now();
        List<FVU_UVT_info__c> uvt = [
            SELECT Id, Name, FVU_Valor_UVT__c, FVU_UVT_Fecha_Inicial_Vigencia__c, FVU_UVT_Fecha_Final_Vigencia__c 
            FROM FVU_UVT_info__c 
            WHERE FVU_UVT_Fecha_Inicial_Vigencia__c < :currentTime 
            AND FVU_UVT_Fecha_Final_Vigencia__c > :currentTime 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
        Decimal uvtPrice;
        if(!uvt.isEmpty()) {
            uvtPrice = (Decimal) uvt[0].FVU_Valor_UVT__c;
            System.debug('uvtPrice: ' + uvtPrice);
        }
  
        List<FVU_IVA_info__c> ivaInfoList = [SELECT Id, Name, FVU_IVA_Tipo_de_equipo__c, FVU_IVA_Subtipo_de_equipo__c,FVU_Valor_IVA__c,FVU_IVA_Fecha_Inicial_Vigencia__c, FVU_IVA_Fecha_Final_Vigencia__c FROM FVU_IVA_info__c WHERE FVU_IVA_Fecha_Inicial_Vigencia__c < :currentTime AND FVU_IVA_Fecha_Final_Vigencia__c > :currentTime WITH SECURITY_ENFORCED];
        //Crear un Map con el subtipo de equipo como Key.
        Map<String,Decimal> ivaInfoMap = new Map<String,Decimal>();
        if (!ivaInfoList.isEmpty() ){
            for(FVU_IVA_info__c ivaInfo : ivaInfoList){
                ivaInfoMap.put(ivaInfo.FVU_IVA_Subtipo_de_equipo__c,ivaInfo.FVU_Valor_IVA__c);
            }
            System.debug('ivaInfoMap: ' + JSON.serialize(ivaInfoMap));
        }
        Decimal TAX_IVA_PCNT = 0;
        // Obtain the UVT from each product
        Map<Id, Decimal> productUVTLimits = new Map<Id, Decimal>();

        Map<String, Product2> productsByCodeMap = new Map<String, Product2>();
        List<Id> candidateIds = new List<Id>();
        for (Product2 product : tytsByCode) {
            candidateIds.add(product.Id);
            productsByCodeMap.put(product.ProductCode, product);
        }
        System.debug('candidateIds: ' + candidateIds);

        List<vlocity_cmt__AttributeAssignment__c> attrAssignments = [
            SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__Value__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-EXC-IMP-TERM'
            AND vlocity_cmt__ObjectId__c IN :candidateIds
            WITH SECURITY_ENFORCED
        ]; 
        System.debug('attrAssignments: ' + attrAssignments);
        
        List<CAT_PreciosProductosExportados__c> recordsToUpdate = new List<CAT_PreciosProductosExportados__c>();
        for (String productCode : precioPorProducto.keySet()) {
            Product2 producto = productsByCodeMap.get(productCode);
            if(producto!= null){
                List<vlocity_cmt__PriceListEntry__c> priceListEntriesPorProducto = pricesByProductCode.get(productCode);
                for (vlocity_cmt__PriceListEntry__c ple : priceListEntriesPorProducto){
                    //productPrices.put(ple.vlocity_cmt__ProductId__c, ple.vlocity_cmt__PricingElementAmount__c);
                    String searchKey = productCode+ple.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c+ple.vlocity_cmt__DisplayText__c+ple.vlocity_cmt__EffectiveFromDate__c;
                    System.debug('searchKey: '+ searchKey);
                    CAT_PreciosProductosExportados__c precioActualizado = preciosPorProductosPL.get(searchKey);
                    System.debug('precioActualizado antes de lógica: ' + precioActualizado.Id);
                    
                    Decimal productPrice = ple.vlocity_cmt__PricingElementAmount__c;
                    
                    System.debug('product.Id: ' + producto.Id);
                    System.debug('productPrice: ' + productPrice);
                    String prod2AttributesSelected = (String)producto.get('vlocity_cmt__AttributeDefaultValues__c');
                    Map<String, Object> prod2AttributesSelectedMap = (Map<String, Object>)JSON.deserializeUntyped(prod2AttributesSelected);
                    String prod2SubCatProd;
                    Integer prodUVT = 0;
                    if (producto.vlocity_cmt__Type__c == 'Tech') {
                        prod2SubCatProd = String.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TEC-SUP-CAT-PROD'));
                        prodUVT = Integer.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TEC-LIMITE-UVT'));
                    } else if (producto.vlocity_cmt__Type__c == 'Handset') {
                        prod2SubCatProd = String.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-TIPO-TERM'));
                        prodUVT = Integer.valueOf(prod2AttributesSelectedMap.get('B2C-ATTR-EXC-IMP-TERM'));
                    }
                    
    
                    
                    if(prodUVT == null) prodUVT = 0;
                    TAX_IVA_PCNT = ivaInfoMap.get(prod2SubCatProd);
                    Decimal TOTAL_TAX = 0;
                    if(TAX_IVA_PCNT == null){
                        TAX_IVA_PCNT = ivaInfoMap.get('Defecto');
                    }
                    TOTAL_TAX = 1 + (TAX_IVA_PCNT/100);
                    // Aplicar iVA si el precio supera el límite UVT
                    Decimal adjustedPrice;
                    //Decimal newprice = uvtPrice * prodUVT;
                    if(productPrice > (uvtPrice *  prodUVT )){ 
                        adjustedPrice = productPrice * TOTAL_TAX;
                        Decimal adjustedPriceRounded = adjustedPrice.setScale(0, RoundingMode.HALF_UP);
                        adjustedPrice = adjustedPriceRounded;
                        System.debug('adjustedPriceRounded: '+ adjustedPriceRounded);
                    } else{
                        adjustedPrice = productPrice;
                    }
                    System.debug('adjustedPrice: ' + adjustedPrice);
                    precioActualizado.CAT_PrecioConImpuestosPrecios__c  = adjustedPrice;
                    String adjustedPriceFormat = adjustedPrice.setScale(0).format();
                    precioActualizado.CAT_NombrePrecioConImpuestosPrecios__c  ='$ ' + adjustedPriceFormat + ' impuestos incluidos';
                    precioActualizado.CAT_NombrePrecioSinImpuestosPrecios__c  = '$ ' + adjustedPriceFormat + ' impuestos incluidos';
                    System.debug('++precioActualizado: '+ precioActualizado);
                    recordsToUpdate.add(precioActualizado);
                    
                }
                
            }
            
            
        }
         if (!recordsToUpdate.isEmpty()) {
            try {
                update as user recordsToUpdate;
                System.debug('[INFO] ' + recordsToUpdate.size() + ' records updated successfully.');
            } catch (DmlException e) {
                System.debug('ERROR: DML Exception occurred: ' + e.getMessage());
            }
        }
        
        System.debug('[INFO] El proceso de actualización del precio ha finalizado.');
    }
    
    
    /**
     * @description Actualiza el seguimiento de éxito en CAT_SeguimientoProductosExportados__c.
     * @param message El mensaje del log.
     * @return void
     */
    public static void updateSuccessLogRecord(String message, String objetoControlId, Id idLogRecord) {
        //  COMENTARIO: Lógica para insertar el registro de trazabilidad en custom object CAT_SeguimientoProductosExportados__c
        System.debug('[LOGGING] Creando registro de control: ' + message);
        CAT_Control_Interno_Digital__c logInterno = [SELECT Id FROM CAT_Control_Interno_Digital__c WHERE Id = :objetoControlId WITH SECURITY_ENFORCED LIMIT 1];
        CAT_SeguimientoProductosExportados__c logRecord = [SELECT Id FROM CAT_SeguimientoProductosExportados__c WHERE Id = :idLogRecord WITH SECURITY_ENFORCED LIMIT 1];
        logRecord.CAT_DetalleResultadoGlobalSeguimiento__c = 'Salesforce completado';
        logRecord.CAT_FechaFinSfSeguimiento__c = datetime.NOW();
        logRecord.CAT_ResultadoGlobalSeguimiento__c = 'Éxito';
        logInterno.CAT_Estado_Final__c = 'Procesado';
        update as user logInterno;
        update as user logRecord;    

    }
    
    
    // Clase de excepción personalizada para el manejo de errores en esta clase.
    public class CAT_TransformationException extends Exception {}
}