/*---------------------------------------------------------------------------------------------------------------
Autor: Fernanda Maldonado
Fecha: 2025-05-13
Equipo: Catálogo
Descripcion: Batch para el proceso de actualizaciones de precios recibidos a través de la integración con SAP
Code Coverage:92%
History
<Date>            <Author>             <Description>             <Version>
2025-05-13                            Versión Inicial             01
2025-10-02		Pablo Calderon		  nuevos pl y mod             02
2025-10-21		Nahir Arrejoria		  Versión sp 62 aceptar null  02.1
----------------------------------------------------------------------------------------------------------------*/
public with sharing class CATActualizacionPreciosSAPBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts { //Database.Batchable<String>

    private String batchJobId15;
    private String bulkJobId;
    String pl_ClienteMasivoId;
    String pl_Antig6_23MesesId;
    String pl_Antig24MesesId;
    String pl_EcomAnti5MesesId;
    String pl_EcomAnti23MesesId;
    String pl_EcomAnti24MesesId;
    String discountOTId;
    String chargeOTId;
    String pv_OneTimeStdId;
    String pv_OneTimeAbsId;
    String sf_pl_code;
    String priceListId;
    Boolean isPromoTodoClaro;
    String adjCtxRule;

    private Map<String,vlocity_cmt__PriceList__c> mapPL_SAP_SF;
    private List<vlocity_cmt__PricingVariable__c> lPricingVariables;

    //Establecer configuraciones iniciales del batch en caso que se requiera.
    public CATActualizacionPreciosSAPBatch(String bulkJobId) { //String contentDocumentId
        System.debug(':: INI CATActualizacionPreciosSAPBatch() ');
        this.bulkJobId = bulkJobId;
        System.debug('bulkJobId: '+ bulkJobId); 
        //Hacer queries a los objetos comunes necesarios para la creación de las entradas de precio de lista
        //Obtención de todas los id pricelists activas
        Set<String> priceListCodes = new Set<String>{'PL-B2C','B2C-PL-ANT-6-23M','B2C-PL-ANT-MAYOR-24M','PL-ECOM-B2C','B2C-PL-ECOM-ANT-6-23M','B2C-PL-ECOM-ANT-MAYOR-24M'};
        List<vlocity_cmt__PriceList__c> listaprices = [ SELECT Id, vlocity_cmt__Code__c FROM vlocity_cmt__PriceList__c WHERE vlocity_cmt__Code__c IN :priceListCodes WITH SECURITY_ENFORCED];
        Map<String, String> priceListMap = new Map<String, String>();
        for (vlocity_cmt__PriceList__c pl : listaprices) {
            priceListMap.put(pl.vlocity_cmt__Code__c, pl.Id);
        }

        System.debug('-- priceListMap: '+ priceListMap); 
        this.pl_ClienteMasivoId = priceListMap.get('PL-B2C');
        this.pl_Antig6_23MesesId = priceListMap.get('B2C-PL-ANT-6-23M');
        this.pl_Antig24MesesId = priceListMap.get('B2C-PL-ANT-MAYOR-24M');
        this.pl_EcomAnti5MesesId = priceListMap.get('PL-ECOM-B2C');
        this.pl_EcomAnti23MesesId = priceListMap.get('B2C-PL-ECOM-ANT-6-23M');
        this.pl_EcomAnti24MesesId = priceListMap.get('B2C-PL-ECOM-ANT-MAYOR-24M');

        //IDs de OTs
        //Consultar Id del Object Type "Discount"
        List<vlocity_cmt__ObjectClass__c> discountOTIdList = [SELECT Id FROM vlocity_cmt__ObjectClass__c WHERE Name = 'Discount' WITH SECURITY_ENFORCED];
        if(discountOTIdList.isEmpty() || discountOTIdList.size() > 1){
            System.debug('--- CrearAjuste: Hay más de un OT "Discount" (vlocity_cmt__ObjectClass__c) o no hay ninguno: ');
        }
        this.discountOTId = discountOTIdList[0].Id;

        //Consultar Id del Object Type "Charge"
        List<vlocity_cmt__ObjectClass__c> chargeOTIdList = [SELECT Id FROM vlocity_cmt__ObjectClass__c WHERE Name = 'Charge' WITH SECURITY_ENFORCED];
        if(chargeOTIdList.isEmpty() || chargeOTIdList.size() > 1){
            System.debug('--- CrearAjuste: Hay más de un OT "Charge" (vlocity_cmt__ObjectClass__c) o no hay ninguno: ');
        }
        this.chargeOTId = chargeOTIdList[0].Id;

        //IDs de variables de precio
        //Pricing Variable One Time Standard Price
        List<vlocity_cmt__PricingVariable__c> pv_OneTimeStdList = [SELECT Id FROM vlocity_cmt__PricingVariable__c WHERE vlocity_cmt__Code__c = 'OT_STD_PRC' WITH SECURITY_ENFORCED LIMIT 1];
        this.pv_OneTimeStdId = pv_OneTimeStdList[0].Id;
        System.debug('--- pv_OneTimeStdId: ' + this.pv_OneTimeStdId);

        //Pricing Variable Adjustment One Time Absolute
        List<vlocity_cmt__PricingVariable__c> pv_OneTimeAbsList = [SELECT Id FROM vlocity_cmt__PricingVariable__c WHERE vlocity_cmt__Code__c = 'OT_STD_PRC_ADJ_ABS' WITH SECURITY_ENFORCED LIMIT 1];
        this.pv_OneTimeAbsId = pv_OneTimeAbsList[0].Id;
        System.debug('--- pv_OneTimeAbsId: ' + this.pv_OneTimeAbsId);
        
        //**Esto es muy importante ya que esto va a ayudar mucho a no exceder los Governor Limits en el método execute.
        //**mapeo de valores del campo CAT_Lista_Precio__c al código de la lista de precio correspondiente 
        //??y a la regla de contexto del ajuste (para promociones de descuento por pago de contado con antiguedad)
        
        System.debug(':: FIN CATActualizacionPreciosSAPBatch() ');  
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(':: INI CATActualizacionPreciosSAPBatch.start ');
        
        //Acceder al JobId de 15 caracteres
        this.batchJobId15 = bc.getJobId().to15();
        
        //**Consultar todos los registros del objeto personalizado (HDU 595595) que tengan la fecha actual en el campo CreatedDate y el campo CAT_Id_Job_Procesamiento__c vacío (null).
        
        //Actualizar estos registros con el Job Id de 15 caracteres. Esto es porque el de 15 caracteres es el que se devuelve al cliente que disparó la ejecución del apex batch.
        //Devolver los registros que se consultaron (estos registros se pasan por el método execute en batches de 200 por defecto o en el tamaño de batch especificado cuando se disparó la ejecución del batch apex, en este caso el batch se deberá ejecutar de a 1 registro debido a la cantidad de queries, operaciones DML y creación de promociones necesarias de lo contrario es muy posible que se excedan los Governor Limits)

        //Si se ve necesario ejecutar acá consultas adicionales para enriquecer la información del producto a partir del ID de Material (por ejemplo Nombre, código, etc) que se puedan necesitar para la creación de las promociones y reducir las consultas del método execute.
        // Esto va a determinar si es necesario retornar un Iterable como en este ejemplo o si es posible devolver un Database.QueryLocator como en la clase de posventa PVU_Gestiones_Masivas_Batch (El Database.QueryLocator permite retornar más registros)
        
        System.debug('>> TODAY -> ' + System.today());
        
        //Incluir CAT_Canales__c en la query de la TMP - Actualización HU 650455
        return Database.getQueryLocator([
            SELECT Id, CAT_Equipo__c,CAT_Canales__c, CAT_Desc_Comercial__c, CAT_Lista_Precio__c, CAT_Precio_sin_IVA_ZP06__c, 
                CAT_Precio_IVA_Final_Red_ZP05__c, CAT_ValorDescuento__c, CAT_FechaInicioVigencia__c, 
                CAT_Id_Job_Procesamiento__c, CAT_Resultado_Procesamiento__c, CAT_Descripcion_Procesamiento__c, CreatedDate 
            FROM CAT_Informacion_Precios_SAP_tmp__c
            WHERE CAT_Id_Job_Procesamiento__c = NULL AND CAT_Id_Job_Externo__c = :bulkJobId WITH SECURITY_ENFORCED ORDER BY CAT_FechaInicioVigencia__c ASC
        ]);      
    }
    
    public void execute(Database.BatchableContext bc, List<CAT_Informacion_Precios_SAP_tmp__c> scope) {  //List<SObject>
        System.debug(':: INI CATActualizacionPreciosSAPBatch.execute ');

        // Establecer variables a utilizar
        Long startDateEpoch;
        Boolean isProductPrice = false;
        Boolean isAdjustment = false;
        String promoId;
        String promoName;
        String promoCode;
        String promoClass;
        String promoType;
        Integer promoItemMaxQuantity;
        Integer promoItemMinQuantity;
        Integer promoItemQuantity;
        Boolean promoIsActive;
        String existingPromoId;
        String promotionItemId;
        String createPromoItemReqStr;
        String productId;
        String productName;
        String productCode;
        String priceDisplayNumber;
        String priceDisplayName;
        String adjustmentOneTimeDisplayName;
        String pricingVariableId;
        String pricingVariableName;
        String priceListEntryId;
        String pricingElementId;
        String canalAsignado;
        List<String> crearPromoResList = new List<String>();
        List<String> crearPromoItemResList = new List<String>();
        String errorMessage;
        String response;
        String responseDescription;

        // Formatear fecha de inicio
        String startDate = scope[0].CAT_FechaInicioVigencia__c;
        System.debug('--- startDate: ' + startDate);

        if (String.isNotBlank(startDate)) {
            // Validar formato de fecha yyyy-mm-dd usando expresión regular
            Pattern datePattern = Pattern.compile('^\\d{4}-\\d{2}-\\d{2}$');
            Matcher matcher = datePattern.matcher(startDate);

            if (matcher.matches()) {
                try {
                    List<String> startDateList = startDate.split('-');
                    System.debug('--- startDateList: ' + startDateList);
                    Datetime startDateDt = DateTime.newInstance(
                        Integer.valueOf(startDateList[0]), 
                        Integer.valueOf(startDateList[1]), 
                        Integer.valueOf(startDateList[2]), 
                        0, 0, 0
                    );
                    System.debug('--- startDateDt: ' + startDateDt);
                    startDateEpoch = startDateDt.getTime();
                    System.debug('--- startDateEpoch: ' + startDateEpoch);
                    /*Date fechaHoy = Date.today();
                    System.debug('fechaHoy: '+ fechaHoy);
                    if (fechaHoy > startDateDt) {
                        System.debug('--- Fecha de vigencia en el pasado');
                        response = 'Éxito';
                        responseDescription = 'Exito: No se procesa por tener una vigencia anterior al precio activo actual.';
                        scope[0].CAT_Resultado_Procesamiento__c = response;
                        scope[0].CAT_Descripcion_Procesamiento__c = responseDescription;
                        scope[0].CAT_Id_Job_Procesamiento__c = batchJobId15;
                        update scope[0];
                        return;
                    }*/
                } catch (Exception e) {
                    System.debug('--- Error al convertir la fecha: ' + e.getMessage());
                }
            } else {
                System.debug('--- Formato de fecha incorrecto');
                registrarResultado(scope[0], 'Error', 'Error: La fecha debe estar en formato yyyy-mm-dd');
                return;
            }
        } else {
            System.debug('--- La fecha de inicio viene vacía');            
            registrarResultado(scope[0], 'Error', 'Error: La fecha de inicio viene vacía');
            return;
        }

        //this.numeroBatch += 1;        
        System.debug('CATActualizacionPreciosSAPBatch -- batchJobId: ' + batchJobId15);

        //Primero se debe conocer e identificar el tipo de dato correspondiente al scope, los ?? es porque en este punto del diseño aún es desconocido.
        System.debug('>> scope : ' + scope);

        //**Hacer mapeo del valor del campo CAT_Lista_Precio__c al código de la lista de precio correspondiente.
        String sap_pl_code = scope[0].CAT_Lista_Precio__c;
        
        if (sap_pl_code == '04_SF TEC' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TEC') {
            asignarListaPrecio('PL-B2C', this.pl_ClienteMasivoId, false, null);

        } else if (sap_pl_code == '04_SF TER CL00' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER CL00') {
            asignarListaPrecio('PL-B2C', this.pl_ClienteMasivoId, false, 'Cliente Antiguedad Menor 5 Meses');

        } else if (sap_pl_code == '04_SF TER CL06' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER CL06') {
            asignarListaPrecio('B2C-PL-ANT-6-23M', this.pl_Antig6_23MesesId, false, 'Cliente Antiguedad Entre 6 y 23 Meses');

        } else if (sap_pl_code == '04_SF TER CL24' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER CL24') {
            asignarListaPrecio('B2C-PL-ANT-MAYOR-24M', this.pl_Antig24MesesId, false, 'Cliente Antiguedad Mayor 24 Meses');
        
        } else if (sap_pl_code == '04_SF_TEC_ECO' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TEC ECO') {
            asignarListaPrecio('PL-ECOM-B2C', this.pl_EcomAnti5MesesId, false, null);

        } else if (sap_pl_code == '04_SF_TER_EC00' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER EC00') {
            asignarListaPrecio('PL-ECOM-B2C', this.pl_EcomAnti5MesesId, false, 'Canales - Cliente Antiguedad Menor 5 Meses');

        } else if (sap_pl_code == '04_SF_TER_EC06' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER EC06') {
            asignarListaPrecio('B2C-PL-ANT-6-23M', this.pl_EcomAnti23MesesId, false, 'Canales - Cliente Antiguedad Entre 6 y 23 Meses');
        
        } else if (sap_pl_code == '04_SF_TER_EC24' || sap_pl_code == 'Dto_Comercial_ZD79_04_SF TER EC24') {
            asignarListaPrecio('B2C-PL-ANT-MAYOR-24M', this.pl_EcomAnti24MesesId, false, 'Canales - Cliente Antiguedad Mayor 24 Meses');
        
        } else if (sap_pl_code == '04_SF TEC TDCL') {
            asignarListaPrecio('PL-B2C', this.pl_ClienteMasivoId, true, 'Cliente Todo Claro o Cliente Potencial con Antig Menor a 24 Meses');

        } else if (sap_pl_code == '04_SF TER TDCL') {
            asignarListaPrecio('PL-B2C', this.pl_ClienteMasivoId, true, 'Cliente Todo Claro con Antig Menor a 24 Meses o Cliente Potencial');

        } else {
            System.debug('--- La lista de precio no está correctamente escrita');
            registrarResultado(scope[0], 'Error', 'Error: La lista de precio asignada no existe');
            return;
        }

        String amountWithoutTaxStr = scope[0].CAT_Precio_sin_IVA_ZP06__c;
        if(amountWithoutTaxStr == null) {
            System.debug('--- El campo CAT_Precio_sin_IVA_ZP06__c viene vacío');            
            registrarResultado(scope[0], 'Error', 'Error: El precio sin IVA debe tener un valor');
            return;
        }
        String amountWithoutTaxClean = amountWithoutTaxStr.replace('\r','');
        System.debug('--- amountWithoutTaxClean is Numeric: ' + amountWithoutTaxClean.isNumeric());
        Decimal amountWithoutTaxInt;
        try{
            amountWithoutTaxInt = Decimal.valueOf(amountWithoutTaxClean);
        } catch (Exception e){            
            registrarResultado(scope[0], 'Error', 'Error: El precio sin IVA debe ser un valor numérico');
            return;
        }
        System.debug('--- amountWithoutTaxInt: ' + amountWithoutTaxInt);

        String amountWithTaxStr = scope[0].CAT_Precio_IVA_Final_Red_ZP05__c;
        if(amountWithTaxStr == null) {
            System.debug('--- El campo CAT_Precio_IVA_Final_Red_ZP05__c viene vacío');                  
            registrarResultado(scope[0], 'Error', 'Error: El precio con IVA debe tener un valor');
            return;
        }
        String amountWithTaxClean = amountWithTaxStr.replace('\r','');
        System.debug('--- amountWithTaxClean is Numeric: ' + amountWithTaxClean.isNumeric());
        Decimal amountWithTaxInt;
        try{
            amountWithTaxInt = Decimal.valueOf(amountWithTaxClean);
        } catch (Exception e){
            registrarResultado(scope[0], 'Error', 'Error: El precio con IVA debe ser un valor numérico');
            return;
        }
        System.debug('--- amountWithTaxInt: ' + amountWithTaxInt);

        String discountAmountStr = scope[0].CAT_ValorDescuento__c;
        Boolean descuentoNulo = false;
        if(discountAmountStr == null) {
            System.debug('--- El campo CAT_ValorDescuento__c viene vacío');
            discountAmountStr = '0';
            descuentoNulo = true;
            /*response = 'Error';
            responseDescription = 'Error: El descuento debe tener un valor';
            scope[0].CAT_Resultado_Procesamiento__c = response;
            scope[0].CAT_Descripcion_Procesamiento__c = responseDescription;
            scope[0].CAT_Id_Job_Procesamiento__c = batchJobId15;
            update scope[0];
            return;*/
        }

        String discountAmountClean = discountAmountStr.replace('\r','');
        System.debug('--- discountAmountClean is Numeric: ' + discountAmountClean.isNumeric());
        Decimal discountAmountInt;
        try{
            discountAmountInt = Decimal.valueOf(discountAmountClean);
        } catch (Exception e){
            registrarResultado(scope[0], 'Error', 'Error: El valor de descuento debe ser numérico');
            return;  
        }
        System.debug('--- discountAmountInt: ' + discountAmountInt);

        // Validar si los tres campos tienen valor al mismo tiempo
        if(amountWithoutTaxInt > 0 && amountWithTaxInt > 0 && discountAmountInt < 0) {
            System.debug('--- Error: los tres campos tienen valor al mismo tiempo');
            registrarResultado(scope[0], 'Error', 'Error: No se puede crear un precio y un descuento al mismo tiempo.');
            return;
        }

        //Checar si se requiere de un precio sobre el producto o de un ajuste de precio
        if(amountWithoutTaxInt > 0 && amountWithTaxInt > 0 && discountAmountInt == 0){
            isProductPrice = true;
        } 
        else if(amountWithoutTaxInt == 0 && amountWithTaxInt == 0 && discountAmountInt <= 0){
            isAdjustment = true;
        }

        if(isAdjustment == false && (amountWithoutTaxInt <= 0 || amountWithTaxInt <= 0)){
            System.debug('--- Cuando el valor de la lista de precios del producto llega en 0 o negativo no se debe actualizar.');
            response = 'Error';
            responseDescription = 'Error: El valor de la lista de precios del producto es 0 o negativo, por ende no se debe actualizar';
        }
        System.debug('--- ¿El precio a configurar es sobre el producto? ' + isProductPrice);
        System.debug('--- ¿El precio a configurar es un ajuste? ' + isAdjustment);

        //Muy importante intentar descartar si es necesario procesar el registro o no validando inicialmente si ya existe una entrada de precio con el mismo valor, si ya existe o no una promoción de descuento y si esta tiene un ajuste con el mismo valor, 
        //además una promoción Todo Claro y si existe si tiene un ajuste con el mismo valor. El objetivo es ahorrar procesamiento, es posible que se deban procesar alrededor de 4000 registros, esto significa ejecutar 4000 veces el método execute.

        //Guardar productId
        String idMaterial = scope[0].CAT_Equipo__c;
        if(idMaterial == null) {
            System.debug('--- El campo CAT_Equipo__c viene vacío');
            registrarResultado(scope[0], 'Error', 'Error: El ID del material debe estar configurado');
            return;
        }

        List<vlocity_cmt__AttributeAssignment__c> attrAssignmentList = [SELECT vlocity_cmt__ObjectId__c FROM vlocity_cmt__AttributeAssignment__c WHERE (vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-MATERIAL-TERM' OR vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-MATERIAL') AND vlocity_cmt__Value__c = :idMaterial WITH SECURITY_ENFORCED];

        // Extraer los object ids
        Set<Id> objectIdSet = new Set<Id>();
        for(vlocity_cmt__AttributeAssignment__c attr : attrAssignmentList){
            if(attr.vlocity_cmt__ObjectId__c != null){
                objectIdSet.add(attr.vlocity_cmt__ObjectId__c);
            }
        }

        // Guardar el id del producto
        //Leer canal desde Product2 para usar en la Promoción - Actualización HU 650455
        List<Product2> productIdList = [SELECT Id, Name, ProductCode, CAT_Canales__c FROM Product2 WHERE Id IN :objectIdSet AND vlocity_cmt__ProductSpecId__c != null WITH SECURITY_ENFORCED LIMIT 1];
        
        if(productIdList.size() == 0) {
            System.debug('--- El producto no existe');
            registrarResultado(scope[0], 'Error', 'Error: No se encontró el producto con ID de Material ' + idMaterial);
            return;            
        }    
        
        String productChannelString = productIdList[0].CAT_Canales__c;
        if(productChannelString == null){
            canalAsignado = '';
        }else {
            canalAsignado = productChannelString;
        }
        System.debug('--- canalAsignado' + canalAsignado);

        //Replicar lógica del flujo Crear Entrada de Precio (V4) para la creación de la entrada de precio en la lista de precio correspondiente
            //Tener en cuenta que los IDs requeridos ya se consultaron cuando se instanció la clase.
            // Amount = CAT_Precio_sin_IVA_ZP06__c
            // Para Display Name usar = CAT_Precio_IVA_Final_Red_ZP05__c (el valor que allí viene se debe dar el formato al string para que sea igual a los Display Names existentes)
            // Para vlocity_cmt__EffectiveFromDate__c de la entrada nueva y vlocity_cmt__EffectiveUntilDate__c de la entrada de precios activa actual usar CAT_FechaInicioVigencia__c

        if(isProductPrice == true){
            System.debug('--- Se requiere entrada de precio en el producto.');
            //5. Manejo de ajustes de precio
            //Guardar productId
            if(productIdList.size() > 0){
                productId = productIdList[0].Id;
                System.debug('--- productId: ' + productId);
                priceDisplayNumber = amountWithTaxInt.format().replace(',', '.');
                priceDisplayName   = '$ ' + priceDisplayNumber + ' impuestos incluidos';
                System.debug('--- priceDisplayName: ' + priceDisplayName);

                //Analisis para asignar variables de precio OneTime
                pricingVariableId = this.pv_OneTimeStdId;
                pricingVariableName = 'One Time Std Price';
                System.debug('--- pricingVariableSelected = One time standard with Name: ' + pricingVariableName + 'And Id:' + pricingVariableId);
            }

            //Encontrar pricing element 
            List<vlocity_cmt__PricingElement__c> pricingElementList = [SELECT Id FROM vlocity_cmt__PricingElement__c WHERE vlocity_cmt__Amount__c = :amountWithoutTaxInt AND vlocity_cmt__PricingVariableId__c = :pricingVariableId AND vlocity_cmt__PricingVariableType__c = 'Price' AND vlocity_cmt__CurrencyCode__c = 'COP' AND vlocity_cmt__PriceListId__c = :priceListId WITH SECURITY_ENFORCED];
            if(pricingElementList.isEmpty()){
                System.debug('--- CrearAjuste: El pricing element no existe, se debe crear uno');
                //Crear el pricing element
                vlocity_cmt__PricingElement__c newPricingElement = new vlocity_cmt__PricingElement__c();
                newPricingElement.Name = pricingVariableName + amountWithoutTaxInt;
                newPricingElement.vlocity_cmt__Amount__c = amountWithoutTaxInt;
                newPricingElement.vlocity_cmt__CalculationType__c = 'Simple';
                newPricingElement.vlocity_cmt__Code__c = pricingVariableName + '_' + amountWithoutTaxInt + '_COP_' + this.chargeOTId;
                newPricingElement.vlocity_cmt__CurrencyCode__c = 'COP';
                newPricingElement.vlocity_cmt__DisplayText__c = pricingVariableName + amountWithoutTaxInt;
                newPricingElement.vlocity_cmt__IsActive__c = true;
                newPricingElement.vlocity_cmt__PriceListId__c = priceListId;
                newPricingElement.vlocity_cmt__PricingVariableId__c = pricingVariableId;
                newPricingElement.vlocity_cmt__IsReusable__c = true;
                newPricingElement.vlocity_cmt__ObjectTypeId__c = this.chargeOTId;
                insert newPricingElement;
                pricingElementId = newPricingElement.Id;
            } /*else if(pricingElementList.size() > 1){ //BUG 657498 
                System.debug('--- Hay más de un pricing element. Product Id: ' + productId);
            }*/ else{
                pricingElementId = pricingElementList[0].Id;
            }
            //Verificar precio actual si es el mismo no se hace nada. Si el precio es diferente se crea la nueva entrada de precio y se actualizan las entradas viejas con la fecha de inicio de la nueva entrada en la fecha de termino para las viejas, el analisis se realizara con la conulta del pricing element, si ocupan el mismo pricing element Id entonces es un duplicado y se trata del mismo precio, si ocupan otro, se trata de un nuevo precio
            List<vlocity_cmt__PriceListEntry__c> lastPriceListEntryAdjustment;
            if (pricingVariableName == 'One Time Std Price'){
                lastPriceListEntryAdjustment = [SELECT Id, vlocity_cmt__PricingElementId__c, vlocity_cmt__PricingElementAmount__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__EffectiveFromDate__c FROM vlocity_cmt__PriceListEntry__c  WHERE vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveUntilDate__c = null AND vlocity_cmt__PromotionId__c = null AND vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PriceListId__c = :priceListId WITH SECURITY_ENFORCED];
                System.debug('--- lastPriceListEntryAdjustment: ' + lastPriceListEntryAdjustment);
            }
            if (lastPriceListEntryAdjustment.isEmpty()) {
                //Crear el price list entry para el ajuste de precio
                System.debug('--- CrearPriceListEntry: No existen Ajustes de Precio activos para este producto: ' + productId);
                System.debug('--- CrearPriceListEntry: Creando Price List Entry Nuevo');
                String priceListEntryReq = '{"epcRequest":{"entity":{"vlocity_cmt__PriceListId__c":"' + priceListId + '","vlocity_cmt__DisplayText__c":"' +priceDisplayName + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch +',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__IsOverride__c":false,"vlocity_cmt__OfferId__c":"","vlocity_cmt__PricingElementId__c":"' + pricingElementId +'","vlocity_cmt__PricingMatrixBindingData__c":"","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__PromotionId__c":"","vlocity_cmt__PromotionItemId__c":"","vlocity_cmt__RuleDescription__c":"","vlocity_cmt__TimePlanId__c":"","vlocity_cmt__TimePolicyId__c":""}}}';
                System.debug('--- priceListEntryReq: ' + priceListEntryReq);
                Object createPriceListEntryResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPriceListEntry',priceListEntryReq);
                System.debug('--- createPriceListEntryResponse: ' + createPriceListEntryResponse);
                String createPriceListEntryResponseStr = JSON.serialize(createPriceListEntryResponse);
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('\\"', '"');
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('"{', '{');
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('}"', '}');
                System.debug('--- createPriceListEntryResponseStr: ' + createPriceListEntryResponseStr);
                //Obtener respuesta de la llamada al API
                Map<String, Object> createPriceListEntryResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPriceListEntryResponseStr);
                Map<String, Object> epcPriceListEntryResponseMap = (Map<String, Object>) createPriceListEntryResponseMap.get('epcResponse');
                if (epcPriceListEntryResponseMap.containsKey('overallResult') && String.valueOf(epcPriceListEntryResponseMap.get('overallResult')) == 'failure') {
                    errorMessage = (String) epcPriceListEntryResponseMap.get('failureReason');
                    System.debug('Error en la actualización de precio: ' + errorMessage);
                    response = 'Error';
                    responseDescription = 'Error: La actualización del ajuste de precio no se procesó correctamente ';
                } else {
                    List<Object> priceListEntryEntitiesList = (List<Object>)epcPriceListEntryResponseMap.get('entities');
                    Map<String, Object> priceListEntryEntitiesMap = (Map<String, Object>)priceListEntryEntitiesList[0];
                    Map<String, Object> priceListEntryEntityMap = (Map<String, Object>)priceListEntryEntitiesMap.get('entity');
                    priceListEntryId = (String)priceListEntryEntityMap.get('Id');
                    response = 'Éxito';
                    responseDescription = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + idMaterial; //##Test.insertaEntradaPreciosNueva
                }
            }
            // Si el precio se le hace a un TyT, entonces debemos actualizar por medio de pricelist
            else if (lastPriceListEntryAdjustment.size() > 0) {
                if (amountWithoutTaxInt != lastPriceListEntryAdjustment[0].vlocity_cmt__PricingElementAmount__c){
                    //Actualizar útlima entrada de ajuste de precio
                    System.debug('--- ActualizandoPriceListEntry: Existe un Ajuste de Precio activo para este producto: ' + productId);
                    System.debug('--- ActualizandoPriceListEntry: Actualizando fecha fin de la ultima entrada activa para este producto: ' + productId);
                    System.debug('--- priceStartDate: ' + startDateEpoch);
                    DateTime priceListEntryEffectiveUntilDateTime = DateTime.newInstance(startDateEpoch);
                    System.debug('--- priceListEntryEffectiveUntilDateTime: ' + priceListEntryEffectiveUntilDateTime);
                    if(lastPriceListEntryAdjustment[0].vlocity_cmt__EffectiveFromDate__c >= priceListEntryEffectiveUntilDateTime){
                        System.debug('--- No se procesa por tener una vigencia anterior al precio activo actual');
                        registrarResultado(scope[0], 'Éxito', 'Exito: No se procesa por tener una vigencia anterior al precio activo actual');
                        return;                            
                    }
                    lastPriceListEntryAdjustment[0].vlocity_cmt__EffectiveUntilDate__c = priceListEntryEffectiveUntilDateTime;
                    System.debug('--- lastPriceListEntryEffectiveUntilDateTime: ' + lastPriceListEntryAdjustment[0].vlocity_cmt__EffectiveUntilDate__c);
                    update lastPriceListEntryAdjustment;
                    //Actualizar entradas viejas que sean anteriores a la última entrada de ajuste de precio
                    System.debug('--- ActualizandoPriceListEntry: Actualizando is active -> false para cada entrada pasada a la última activa para este producto: ' + productId);
                    System.debug('--- ActualizandoPriceListEntry TyT: Fecha de Inicio de la última entrada de precio: ' + lastPriceListEntryAdjustment[0].vlocity_cmt__EffectiveFromDate__c);
                    List<vlocity_cmt__PriceListEntry__c> oldPriceListEntryAdjustments = [SELECT Id, vlocity_cmt__PricingElementId__c, vlocity_cmt__EffectiveFromDate__c, vlocity_cmt__EffectiveUntilDate__c FROM vlocity_cmt__PriceListEntry__c  WHERE vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveFromDate__c < :lastPriceListEntryAdjustment[0].vlocity_cmt__EffectiveFromDate__c AND vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PriceListId__c = :priceListId AND vlocity_cmt__PromotionId__c = null AND vlocity_cmt__EffectiveFromDate__c < TODAY AND vlocity_cmt__EffectiveUntilDate__c < TODAY WITH SECURITY_ENFORCED];
                    if (oldPriceListEntryAdjustments.size() > 0) { 
                        //Actualizar las entradas de precio viejas a is active -> false
                        for (Integer j= 0; j<oldPriceListEntryAdjustments.size(); j++) {
                            System.debug('--- ActualizandoPriceListEntry TyT: Actualizando is active ->false para entradas viejas ');
                            oldPriceListEntryAdjustments[j].vlocity_cmt__IsActive__c = false;
                        }
                        update oldPriceListEntryAdjustments;
                    }
                    //Crear el price list entry para el ajuste de precio
                    String priceListEntryReq = '{"epcRequest":{"entity":{"vlocity_cmt__PriceListId__c":"' + priceListId + '","vlocity_cmt__DisplayText__c":"' +priceDisplayName + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch +',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__IsOverride__c":false,"vlocity_cmt__OfferId__c":"","vlocity_cmt__PricingElementId__c":"' + pricingElementId +'","vlocity_cmt__PricingMatrixBindingData__c":"","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__PromotionId__c":"","vlocity_cmt__PromotionItemId__c":"","vlocity_cmt__RuleDescription__c":"","vlocity_cmt__TimePlanId__c":"","vlocity_cmt__TimePolicyId__c":""}}}';
                    System.debug('--- priceListEntryReq: ' + priceListEntryReq);
                    Object createPriceListEntryResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPriceListEntry',priceListEntryReq);
                    System.debug('--- createPriceListEntryResponse: ' + createPriceListEntryResponse);
                    String createPriceListEntryResponseStr = JSON.serialize(createPriceListEntryResponse);
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('\\"', '"');
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('"{', '{');
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('}"', '}');
                    System.debug('--- createPriceListEntryResponseStr: ' + createPriceListEntryResponseStr);
                    //Obtener respuesta de la llamada al API
                    Map<String, Object> createPriceListEntryResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPriceListEntryResponseStr);
                    Map<String, Object> epcPriceListEntryResponseMap = (Map<String, Object>) createPriceListEntryResponseMap.get('epcResponse');
                    //Analiza la respuesta para ver si hay error y mostrarlo en el Flow
                    if (epcPriceListEntryResponseMap.containsKey('overallResult') && String.valueOf(epcPriceListEntryResponseMap.get('overallResult')) == 'failure') {
                        errorMessage = (String) epcPriceListEntryResponseMap.get('failureReason');
                        System.debug('--- Error en la actualización del ajuste de precio: ' + errorMessage);
                        response = 'Error';
                        responseDescription = 'Error: La actualización del ajuste de precio no se procesó correctamente ';
                    } else {
                        List<Object> priceListEntryEntitiesList = (List<Object>)epcPriceListEntryResponseMap.get('entities');
                        Map<String, Object> priceListEntryEntitiesMap = (Map<String, Object>)priceListEntryEntitiesList[0];
                        Map<String, Object> priceListEntryEntityMap = (Map<String, Object>)priceListEntryEntitiesMap.get('entity');
                        priceListEntryId = (String)priceListEntryEntityMap.get('Id');
                        response = 'Éxito';
                        responseDescription = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + idMaterial;  //##Test.insertaEntradaPreciosExistente
                    }
                } else{
                    response = 'Éxito';
                    responseDescription = 'Éxito: No se actualiza la entrada porque es el mismo precio de la entrada actual en el producto';
                }
            }
        }

        //Si en el campo CAT_Dto_Comercial_Prom_ZD79__c hay información se debe consultar si ya existe una promoción de descuento de pago de contado activa para ese equipo, si ya existe se debe dar el mismo tratamiento a las entradas de precio de los ajustes que a los precios normales del equipo. (Crear nueva entrada si es necesario y asignarle a regla de contexto mapeada a la lista de precio, actualizar la anterior y desactivar las demás, esto se debe hacer sobre la entrada de precio que tiene asignada la regla de contexto mapeada a la lista de precio)
            //Si ya existe la promoción y el valor en CAT_Dto_Comercial_Prom_ZD79__c se debe desactivar la promoción. (Concepto base de diseño: Los descuentos se manejan en grupo para las antiguedades, si el descuento para una antiguedad se pasa a $0 se asume que no se van a tener más descuentos para las demás antiguedades y se desactiva la promoción completa)
        // Si no existe la promoción se debe crear una siguiendo la lógica utilizada en el flujo "Carga Promociones/Descuentos" para un descuento por pago de contado:
            //Nombre: Dar formato a un nombre siguiendo los nombres actuales.
            //Código: Dar formato a un código siguiendo los códigos actuales.

        else if(isAdjustment == true){ //Si es ajuste de precio, entonces significa que el precio va sobre una promoción (configurar la promoción)
            System.debug('--- Se requiere ajuste de precio, es decir, estamos hablando de configuración promoción.');
            productId = productIdList[0].Id;
            productName = productIdList[0].Name;
            productCode = productIdList[0].ProductCode;
            priceListId = this.priceListId;

            //2. Checar si la promoción existe
            if(isPromoTodoClaro == false){
                System.debug('--- Verificar si hay promoción pago de contado relacionada al producto');
                List<vlocity_cmt__PromotionItem__c> promoContadoList = [SELECT Id, vlocity_cmt__PromotionId__c FROM vlocity_cmt__PromotionItem__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PromotionId__r.CAT_Type__c = 'Estandar' AND vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = 'Descuento' WITH SECURITY_ENFORCED LIMIT 1];
                if(promoContadoList.size() == 0){
                    if(discountAmountInt == 0 && descuentoNulo == true){  
                        System.debug('--- El producto no tiene promoción pago contado activa.');
                        registrarResultado(scope[0], 'Éxito', 'Valor descuento vacío, no tiene promoción activa');
                        return;
                    } else {
                        System.debug('--- No hay promoción de contado relacionada al producto ' + productName + '.');
                        //Establecer campos de la promoción a crear
                        promoName = productName + ' Pago de contado';
                        promoCode = 'B2C-PROMO-' + idMaterial + '-CONTADO';
                        System.debug('--- promoCode: ' + promoCode);
                        promoType = 'Estandar';
                        promoClass = 'Descuento';
                    }
                } else{
                    System.debug('--- Sí existe promoción de contado relacionada al producto ' + productName + '.');
                    existingPromoId = promoContadoList[0].vlocity_cmt__PromotionId__c;
                    promoId = promoContadoList[0].vlocity_cmt__PromotionId__c;
                    System.debug('--- existingPromoId: ' + existingPromoId);
                }
            } else{
                System.debug('--- Verificar si hay promoción todo claro relacionada al producto');
                List<vlocity_cmt__PromotionItem__c> promoTodoClaroList = [SELECT Id, vlocity_cmt__PromotionId__c, vlocity_cmt__IsActive__c FROM vlocity_cmt__PromotionItem__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PromotionId__r.CAT_Type__c = 'TodoClaro' AND vlocity_cmt__PromotionId__r.CAT_PromotionClass__c = 'Descuento Todo Claro' WITH SECURITY_ENFORCED LIMIT 1];
                if(promoTodoClaroList.size() == 0){
                    System.debug('--- No hay promoción todo claro relacionada al producto ' + productName + '.');
                    //Establecer campos de la promoción a crear
                    promoName = productName + ' Todo Claro';
                    promoCode = 'B2C-PROMO-' + idMaterial + '-TODOCLARO';
                    System.debug('--- promoCode: ' + promoCode);
                    promoType = 'TodoClaro';
                    promoClass = 'Descuento Todo Claro';
                } else{
                    System.debug('--- Sí existe promoción todo claro relacionada al producto ' + productName + '.');
                    existingPromoId = promoTodoClaroList[0].vlocity_cmt__PromotionId__c; //promoTodoClaroList[0].Id;
                    promoId = promoTodoClaroList[0].vlocity_cmt__PromotionId__c; //promoTodoClaroList[0].Id;
                    System.debug('--- existingPromoId: ' + existingPromoId);
                }
            }

            //Obtener RecordType de la org
            String promoRecordType = Schema.SObjectType.vlocity_cmt__Promotion__c.getRecordTypeInfosByName().get('Promotion').getRecordTypeId();

            //3. Crear la promoción
            if(existingPromoId == null){
                System.debug('--- La promoción no existe, se debe crear una');
                String createPromoReqStr = '';
                //Enviar CAT_Canales__c al crear la Promoción - Actualización HU 650455
                createPromoReqStr = '{"epcRequest":{"entity":{"Name":"' + promoName +'","vlocity_cmt__PriceListId__c":"' + this.pl_ClienteMasivoId + '","vlocity_cmt__Code__c":"' + promoCode + '","vlocity_cmt__IsOrderable__c":true,"vlocity_cmt__EnableAutoAddProducts__c":true,"vlocity_cmt__EffectiveStartDate__c":' + startDateEpoch + ',"vlocity_cmt__IsActive__c":true, "vlocity_cmt__Description__c":"","RecordTypeId":"'+promoRecordType+'","CAT_Type__c":"'+promoType+'","CAT_PromotionClass__c":"'+promoClass+'","CAT_Canales__c":"'+ canalAsignado +'","vlocity_cmt__EffectiveEndDate__c":null}}}';
              
                //Se llama al remote method addPromotion
                Object createPromoResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPromotion',createPromoReqStr);
                System.debug('--- createPromoResponse: ' + createPromoResponse);
                String createPromoResponseStr = JSON.serialize(createPromoResponse);
                createPromoResponseStr = createPromoResponseStr.replace('\\"', '"');
                createPromoResponseStr = createPromoResponseStr.replace('"{', '{');
                createPromoResponseStr = createPromoResponseStr.replace('}"', '}');
                System.debug('--- createPromoResponseStr: ' + createPromoResponseStr);
                Map<String, Object> createPromoResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPromoResponseStr);
                Map<String, Object> epcResponseMap = (Map<String, Object>) createPromoResponseMap.get('epcResponse');
                //Analiza la respuesta para ver si hay error
                if (epcResponseMap.containsKey('overallResult') && String.valueOf(epcResponseMap.get('overallResult')) == 'failure') {
                    System.debug('--- Error en la creación de la promoción: ' + errorMessage);
                } else{
                    List<Object> entitiesList = (List<Object>)epcResponseMap.get('entities');
                    Map<String, Object> entitiesMap = (Map<String, Object>)entitiesList[0];
                    Map<String, Object> entityMap = (Map<String, Object>)entitiesMap.get('entity');
                    promoId = (String)entityMap.get('Id');  
                    crearPromoResList.add(promoId); 
                    System.debug('--- crearPromoResList: ' + crearPromoResList);
                }

                //4. Agregar promotionItem
                System.debug('--- El promotion item no existe, se debe crear uno');
                List<vlocity_cmt__Promotion__c> promoIdList = [SELECT Id,vlocity_cmt__IsOrderable__c FROM vlocity_cmt__Promotion__c WHERE vlocity_cmt__Code__c = :promoCode WITH SECURITY_ENFORCED];
                if (promoIdList.size() == 0) {
                    System.debug('--- La Promoción ' + promoCode + ' no existe');
                }
                promoId = promoIdList[0].Id;
                System.debug('--- promoId: ' + promoId);
                promoItemMaxQuantity = 1;
                promoItemMinQuantity = 0;
                promoItemQuantity = 0;

                createPromoItemReqStr = '{"epcRequest":{"entity":{"vlocity_cmt__PromotionId__c":"' + promoId +'","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch + ',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__ActionType__c":"Add/Update","vlocity_cmt__MaxQuantity__c":"'+promoItemMaxQuantity+'","vlocity_cmt__MinQuantity__c":"'+promoItemMinQuantity+'","vlocity_cmt__Quantity__c":"'+promoItemQuantity+'","vlocity_cmt__UpdateScope__c":"Update Item Only","vlocity_cmt__ContextProductId__c":"","vlocity_cmt__CardinalityCheckScope__c":"Cart Scope"},"include":["productHierarchy"]}}';
                System.debug(createPromoItemReqStr);

                Object createPromoItemResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPromotionItem',createPromoItemReqStr);
                System.debug('--- createPromoItemResponse: ' + createPromoItemResponse);
                String createPromoItemResponseStr = JSON.serialize(createPromoItemResponse);
                createPromoItemResponseStr = createPromoItemResponseStr.replace('\\"', '"');
                createPromoItemResponseStr = createPromoItemResponseStr.replace('"{', '{');
                createPromoItemResponseStr = createPromoItemResponseStr.replace('}"', '}');
                System.debug('--- createPromoItemResponseStr: ' + createPromoItemResponseStr);
                Map<String, Object> createPromoItemResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPromoItemResponseStr);
                Map<String, Object> epcPromoItemResponseMap = (Map<String, Object>) createPromoItemResponseMap.get('epcResponse');
                //Analiza la respuesta para ver is hay error y mostrarlo en el Flow
                if (epcPromoItemResponseMap.containsKey('overallResult') && String.valueOf(epcPromoItemResponseMap.get('overallResult')) == 'failure') {
                    errorMessage = (String) epcPromoItemResponseMap.get('failureReason');
                    System.debug('Error en la actualización del Promotion Item: ' + errorMessage);
                } else {
                    List<Object> promoItemEntitiesList = (List<Object>)epcPromoItemResponseMap.get('entities');
                    Map<String, Object> promoItemEntitiesMap = (Map<String, Object>)promoItemEntitiesList[0];
                    Map<String, Object> promoItemEntityMap = (Map<String, Object>)promoItemEntitiesMap.get('entity');
                    promotionItemId = (String)promoItemEntityMap.get('Id');
                    crearPromoItemResList.add(promotionItemId);
                    System.debug('--- crearPromoItemResList: ' + crearPromoItemResList);
                }
            }

             //actualizar canal en Promoción existente - Actualización HU 650455
            if (promoId != null) {
                if (String.isNotBlank(canalAsignado)) {
                vlocity_cmt__Promotion__c promoUpd = [SELECT Id, CAT_Canales__c FROM vlocity_cmt__Promotion__c WHERE Id = :promoId WITH SECURITY_ENFORCED LIMIT 1];
                promoUpd.CAT_Canales__c = canalAsignado;
                update promoUpd;
                }
            }

            //5. Manejo de ajustes de precio
            //Verificar si la promo está acitva
            System.debug('--- promoId: ' + promoId); 
            List<vlocity_cmt__Promotion__c> promoActiveList = [SELECT vlocity_cmt__IsActive__c FROM vlocity_cmt__Promotion__c WHERE Id = :promoId WITH SECURITY_ENFORCED LIMIT 1];
            System.debug('--- promoActiveList: ' + promoActiveList);
            promoIsActive = promoActiveList[0].vlocity_cmt__IsActive__c;

            //Guardar promotionItemId
            //Verificar si el promotion item ya existe
            List<vlocity_cmt__PromotionItem__c> existingPromoItemList = [SELECT Id FROM vlocity_cmt__PromotionItem__c
            WHERE vlocity_cmt__PromotionId__c = :promoId WITH SECURITY_ENFORCED LIMIT 1];
            if(existingPromoItemList.size() > 0){
                promotionItemId = existingPromoItemList[0].Id;
                System.debug('--- promotionItemId: ' + promotionItemId);

                //Cantidad absoluta
                Decimal discountAmountIntAbs = Math.abs(discountAmountInt);
                System.debug('--- discountAmountIntAbs: ' + discountAmountIntAbs);


                //Analisis para asignar variables de precio OneTime
                pricingVariableId = this.pv_OneTimeAbsId;
                System.debug('--- pricingVariableId: ' + pricingVariableId);
                pricingVariableName = 'One Time Std Price Adjustment Abs';
                System.debug('--- pricingVariableSelected = One time Absoluto with Name: ' + pricingVariableName + 'And Id:' + pricingVariableId);
                //Consultar los precios al producto
                List<vlocity_cmt__PriceListEntry__c> pleProduct = [SELECT Id FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PromotionId__c = null AND vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveUntilDate__c = null AND vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c != 'PL-B2C' WITH SECURITY_ENFORCED];
                if(isPromoTodoClaro == false && sf_pl_code == 'PL-B2C' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (<= 5 meses)';
                } else if(isPromoTodoClaro == false && sf_pl_code == 'B2C-PL-ANT-6-23M' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (6 a 23 meses)';
                } else if(isPromoTodoClaro == false && sf_pl_code == 'B2C-PL-ANT-MAYOR-24M' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (>= 24 meses)';
                } else if(isPromoTodoClaro == false && sf_pl_code == 'PL-ECOM-B2C' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (<= 5 meses)';
                } else if(isPromoTodoClaro == false && sf_pl_code == 'B2C-PL-ECOM-ANT-6-23M' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (6 a 23 meses)';
                } else if(isPromoTodoClaro == false && sf_pl_code == 'B2C-PL-ECOM-ANT-MAYOR-24M' && pleProduct.size() > 0){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado (>= 24 meses)';
                } else if(isPromoTodoClaro){
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' todo claro';
                } else{
                    adjustmentOneTimeDisplayName = 'Descuento $' + discountAmountIntAbs + ' por pago de contado';
                }
                System.debug('--- adjustmentOneTimeDisplayName: ' + adjustmentOneTimeDisplayName);
            }

            //Encontrar pricing element 
            System.debug('--- discountAmountInt: ' + discountAmountInt);
            System.debug('--- pricingVariableId: ' + pricingVariableId);
            List<vlocity_cmt__PricingElement__c> pricingElementList = [SELECT Id FROM vlocity_cmt__PricingElement__c WHERE vlocity_cmt__AdjustmentValue__c = :discountAmountInt AND vlocity_cmt__PricingVariableId__c = :pricingVariableId AND vlocity_cmt__PricingVariableType__c = 'Price' AND vlocity_cmt__CurrencyCode__c = 'COP' AND vlocity_cmt__PriceListId__c = :priceListId WITH SECURITY_ENFORCED];
            if(pricingElementList.isEmpty()){
                System.debug('--- CrearAjuste: El pricing element no existe, se debe crear uno');
                //Crear Pricing Element

                //Crear el pricing element
                vlocity_cmt__PricingElement__c newPricingElement = new vlocity_cmt__PricingElement__c();
                newPricingElement.Name = pricingVariableName + discountAmountInt;
                newPricingElement.vlocity_cmt__AdjustmentValue__c = discountAmountInt;
                newPricingElement.vlocity_cmt__CalculationType__c = 'Simple';
                newPricingElement.vlocity_cmt__Code__c = pricingVariableName + '_' + discountAmountInt + '_COP_' + this.discountOTId;
                newPricingElement.vlocity_cmt__CurrencyCode__c = 'COP';
                newPricingElement.vlocity_cmt__DisplayText__c = pricingVariableName + discountAmountInt;
                newPricingElement.vlocity_cmt__IsActive__c = true;
                newPricingElement.vlocity_cmt__PriceListId__c = priceListId;
                newPricingElement.vlocity_cmt__PricingVariableId__c = pricingVariableId;
                newPricingElement.vlocity_cmt__IsReusable__c = true;
                newPricingElement.vlocity_cmt__ObjectTypeId__c = this.discountOTId;
                insert newPricingElement;
                pricingElementId = newPricingElement.Id;
            }  /*else if(pricingElementList.size() > 1){
                System.debug('--- CrearPromo: Hay más de un pricing element . Product Id: ' + productId);
            } */ else{
                pricingElementId = pricingElementList[0].Id;
            }
            //Verificar Ajuste de precio actual si es el mismo no se hace nada. Si el ajuste es diferente se crea la nueva entrada de precio y se actualizan las entradas viejas con la fecha de inicio de la nueva entrada en la fecha de termino para las viejas, el analisis se realizara con la conulta del pricing element, si ocupan el mismo pricing element Id entonces es un duplicado y se trata del mismo precio, si ocupan otro, se trata de un nuevo precio
            List<vlocity_cmt__PriceListEntry__c> lastPriceListEntryAdjustment;
            if (pricingVariableName == 'One Time Std Price Adjustment Abs'){
                lastPriceListEntryAdjustment = [SELECT Id,vlocity_cmt__PricingElementId__c FROM vlocity_cmt__PriceListEntry__c  WHERE vlocity_cmt__PromotionId__c = :promoId AND vlocity_cmt__ProductId__c = :productId WITH SECURITY_ENFORCED]; // vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveUntilDate__c = null AND 
            }
            if (lastPriceListEntryAdjustment.isEmpty()) {
                //Si el valor del ajuste es $0 no se crea ajuste nuevo, se marca el registro como procesado exitosamente y en la descripción se indica que se intentó crear un ajuste nuevo de $0 sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)
                if(discountAmountInt == 0){
                    System.debug('--- CrearPriceListEntry: no se crea ajuste nuevo, se está pidiendo crear un ajuste de $0 - lo que significa que se debe actualizar un registro existente - sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)');
                    registrarResultado(scope[0], 'Éxito', 'Éxito: No se crea ajuste nuevo, se está pidiendo crear un ajuste de $0 - lo que significa que se debe actualizar un registro existente - sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)');
                    return;                        
                }
                //Crear el price list entry para el ajuste de precio
                System.debug('--- CrearPriceListEntry: No existen Ajustes de Precio activos para este promotion Item: ' + promotionItemId);
                System.debug('--- CrearPriceListEntry: Creando Price List Entry Nuevo');
                String priceListEntryReq = '{"epcRequest":{"entity":{"vlocity_cmt__PriceListId__c":"' + priceListId + '","vlocity_cmt__DisplayText__c":"' +adjustmentOneTimeDisplayName + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch +',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__IsOverride__c":false,"vlocity_cmt__OfferId__c":"","vlocity_cmt__PricingElementId__c":"' + pricingElementId +'","vlocity_cmt__PricingMatrixBindingData__c":"","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__PromotionId__c":"' + promoId + '","vlocity_cmt__PromotionItemId__c":"' + promotionItemId + '","vlocity_cmt__RuleDescription__c":"","vlocity_cmt__TimePlanId__c":"","vlocity_cmt__TimePolicyId__c":""}}}';
                System.debug('--- priceListEntryReq: ' + priceListEntryReq);
                Object createPriceListEntryResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPriceListEntry',priceListEntryReq);
                System.debug('--- createPriceListEntryResponse: ' + createPriceListEntryResponse);
                String createPriceListEntryResponseStr = JSON.serialize(createPriceListEntryResponse);
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('\\"', '"');
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('"{', '{');
                createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('}"', '}');
                System.debug('--- createPriceListEntryResponseStr: ' + createPriceListEntryResponseStr);
                //Obtener respuesta de la llamada al API
                Map<String, Object> createPriceListEntryResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPriceListEntryResponseStr);
                Map<String, Object> epcPriceListEntryResponseMap = (Map<String, Object>) createPriceListEntryResponseMap.get('epcResponse');
                if (epcPriceListEntryResponseMap.containsKey('overallResult') && String.valueOf(epcPriceListEntryResponseMap.get('overallResult')) == 'failure') {
                    errorMessage = (String) epcPriceListEntryResponseMap.get('failureReason');
                    response = 'Error';
                    responseDescription = 'Error: La actualización del ajuste de precio no se procesó correctamente: ' ;
                } else {
                    List<Object> priceListEntryEntitiesList = (List<Object>)epcPriceListEntryResponseMap.get('entities');
                    Map<String, Object> priceListEntryEntitiesMap = (Map<String, Object>)priceListEntryEntitiesList[0];
                    Map<String, Object> priceListEntryEntityMap = (Map<String, Object>)priceListEntryEntitiesMap.get('entity');
                    priceListEntryId = (String)priceListEntryEntityMap.get('Id');
                    response = 'Éxito';
                    responseDescription = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + idMaterial;  //##Test.insertaEntradaPreciosPromo
                }
            }
            // Si existe un ajuste de precio previo entonces debemos actualizar por medio de la regla
            else if (lastPriceListEntryAdjustment.size() > 0) {

                System.debug('--- productId: ' + productId);
                System.debug('--- promoId: ' + promoId);
                System.debug('--- priceListId: ' + priceListId);

                List<vlocity_cmt__PriceListEntry__c> priceListEntries = [SELECT Id, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c, vlocity_cmt__EffectiveUntilDate__c, vlocity_cmt__EffectiveFromDate__c FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__PromotionId__c = :promoId AND vlocity_cmt__PriceListId__c = :priceListId AND vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveUntilDate__c = null WITH SECURITY_ENFORCED ORDER BY vlocity_cmt__EffectiveUntilDate__c DESC];//
                System.debug('--- priceListEntries: ' + JSON.serialize(priceListEntries));

                Set<Id> pleIds = new Set<Id>();
                for(vlocity_cmt__PriceListEntry__c ple : priceListEntries){
                    pleIds.add(ple.Id);
                }
                System.debug('--- pleIds: ' + pleIds);

                System.debug('--- adjCtxRule: ' + adjCtxRule);
                // Obtener la PriceListEntry asociada a la regla (adjCtxRule)
                List<vlocity_cmt__RuleAssignment__c> ruleAssignment = [SELECT vlocity_cmt__ObjectId__c FROM vlocity_cmt__RuleAssignment__c WHERE vlocity_cmt__RuleId__r.Name = :adjCtxRule AND vlocity_cmt__ObjectId__c IN :pleIds WITH SECURITY_ENFORCED order by LastModifiedDate DESC  LIMIT 1];
                System.debug('--- ruleAssignment: ' + JSON.serialize(ruleAssignment));

                List<vlocity_cmt__RuleAssignment__c> ruleAssignment2 = [SELECT vlocity_cmt__ObjectId__c FROM vlocity_cmt__RuleAssignment__c WHERE vlocity_cmt__RuleId__c != null AND vlocity_cmt__ObjectId__c IN :pleIds WITH SECURITY_ENFORCED LIMIT 1];
                System.debug('--- ruleAssignment2: ' + JSON.serialize(ruleAssignment2));

                if(ruleAssignment2.size() == 0 && priceListEntries.size() == 1){
                    //Significa que es un precio sin antigüedad y se debe actualizar el pricelistentry
                    if (discountAmountInt != priceListEntries[0].vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c){
                        //Actualizar útlima entrada de ajuste de precio
                        System.debug('--- ActualizandoPriceListEntry TyT: Existe un Ajuste de Precio activo para este promotion Item: ' + promotionItemId);
                        System.debug('--- ActualizandoPriceListEntry TyT: Actualizando fecha fin de la ultima entrada activa para este promotion Item: ' + promotionItemId);
                        System.debug('--- adjustmentStartDate TyT: ' + startDateEpoch);
                        DateTime priceListEntryEffectiveUntilDateTime = DateTime.newInstance(startDateEpoch);
                        if(priceListEntries[0].vlocity_cmt__EffectiveFromDate__c >= priceListEntryEffectiveUntilDateTime){
                            System.debug('--- No se procesa por tener una vigencia anterior al precio activo actual');
                            registrarResultado(scope[0], 'Éxito', 'Exito: No se procesa por tener una vigencia anterior al precio activo actual');
                            return;
                        }
                        System.debug('--- priceListEntryEffectiveUntilDateTime: ' + priceListEntryEffectiveUntilDateTime);
                        priceListEntries[0].vlocity_cmt__EffectiveUntilDate__c = priceListEntryEffectiveUntilDateTime;
                        System.debug('--- lastPriceListEntryEffectiveUntilDateTime: ' + priceListEntries[0].vlocity_cmt__EffectiveUntilDate__c);
                        update priceListEntries;
                        //Actualizar entradas viejas que sean anteriores a la última enrada de ajuste de precio
                        System.debug('--- ActualizandoPriceListEntry TyT: Actualizando is active -> false para cada entrada pasada a la última activa para este promotion Item: ' + promotionItemId);
                        System.debug('--- ActualizandoPriceListEntry TyT: Fecha de Inicio de la última entrada de precio: ' + priceListEntries[0].vlocity_cmt__EffectiveFromDate__c);
                        List<vlocity_cmt__PriceListEntry__c> oldPriceListEntryAdjustments = [SELECT Id, vlocity_cmt__PricingElementId__c, vlocity_cmt__IsActive__c FROM vlocity_cmt__PriceListEntry__c  WHERE vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveFromDate__c < :priceListEntries[0].vlocity_cmt__EffectiveFromDate__c AND vlocity_cmt__PromotionId__c = :promoId AND vlocity_cmt__PriceListId__c = :priceListId AND vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__EffectiveFromDate__c < TODAY AND vlocity_cmt__EffectiveUntilDate__c < TODAY WITH SECURITY_ENFORCED];

                        Set<Id> oldPLEIds = new Set<Id>();
                        for(vlocity_cmt__PriceListEntry__c oldPLE : oldPriceListEntryAdjustments){
                            oldPLEIds.add(oldPLE.Id);
                        }
                        System.debug('--- oldPLEIds: ' + oldPLEIds);
                        System.debug('--- adjCtxRule: ' + adjCtxRule);
                        // Obtener la PriceListEntry asociada a la regla (adjCtxRule)
                        List<vlocity_cmt__RuleAssignment__c> ruleAssignmentOldPLE = [SELECT vlocity_cmt__ObjectId__c FROM vlocity_cmt__RuleAssignment__c WHERE vlocity_cmt__RuleId__r.Name  = :adjCtxRule AND vlocity_cmt__ObjectId__c IN :oldPLEIds WITH SECURITY_ENFORCED];
                        System.debug('--- ruleAssignmentOldPLE: ' + JSON.serialize(ruleAssignmentOldPLE));

                        if (ruleAssignmentOldPLE.size() == 0) {
                            //Si las entradas de precio viejas no tienen regla de contexto y las debemos desactivar
                            //Actualizar las entradas de precio viejas a is active -> false
                            for (Integer j= 0; j<oldPriceListEntryAdjustments.size(); j++) {
                                System.debug('--- ActualizandoPriceListEntry TyT: Actualizando is active ->false para entradas viejas ');
                                oldPriceListEntryAdjustments[j].vlocity_cmt__IsActive__c = false;                                
                            }
                            update oldPriceListEntryAdjustments;
                        }
                    }
                }
                if(ruleAssignment.size() == 0){
                    //Esto significa que no hay ajuste activo con esa regla de contexto, entonces debemos crearlo
                    //Crear el price list entry para el ajuste de precio
                    //Si el valor del ajuste es $0 no se crea ajuste nuevo, se marca el registro como procesado exitosamente y en la descripción se indica que se intentó crear un ajuste nuevo de $0 sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)
                    if(discountAmountInt == 0 && descuentoNulo == false){
                        System.debug('--- CrearPriceListEntry: no se crea ajuste nuevo, se está pidiendo crear un ajuste de $0 - lo que significa que se debe actualizar un registro existente - sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)');
                        registrarResultado(scope[0], 'Éxito', 'Éxito: No se crea ajuste nuevo, se está pidiendo crear un ajuste de $0 - lo que significa que se debe actualizar un registro existente - sobre un ajuste inexistente o que corresponde a otra lista de precio (regla de contexto)');
                        return;
                    } else if(discountAmountInt == 0 && descuentoNulo == true){
                        System.debug('--- Valor descuento vacío, no tiene promoción activa');
                        registrarResultado(scope[0], 'Éxito', 'Valor descuento vacío, no tiene promoción activa');
                        return;
                    }
                    System.debug('--- CrearPriceListEntry: No existen Ajustes de Precio activos para este promotion Item: ' + promotionItemId);
                    System.debug('--- CrearPriceListEntry: Creando Price List Entry Nuevo');
                    String priceListEntryReq = '{"epcRequest":{"entity":{"vlocity_cmt__PriceListId__c":"' + priceListId + '","vlocity_cmt__DisplayText__c":"' + adjustmentOneTimeDisplayName + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch +',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__IsOverride__c":false,"vlocity_cmt__OfferId__c":"","vlocity_cmt__PricingElementId__c":"' + pricingElementId +'","vlocity_cmt__PricingMatrixBindingData__c":"","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__PromotionId__c":"' + promoId + '","vlocity_cmt__PromotionItemId__c":"' + promotionItemId + '","vlocity_cmt__RuleDescription__c":"","vlocity_cmt__TimePlanId__c":"","vlocity_cmt__TimePolicyId__c":""}}}';
                    System.debug('--- priceListEntryReq: ' + priceListEntryReq);
                    Object createPriceListEntryResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPriceListEntry',priceListEntryReq);
                    System.debug('--- createPriceListEntryResponse: ' + createPriceListEntryResponse);
                    String createPriceListEntryResponseStr = JSON.serialize(createPriceListEntryResponse);
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('\\"', '"');
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('"{', '{');
                    createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('}"', '}');
                    System.debug('--- createPriceListEntryResponseStr: ' + createPriceListEntryResponseStr);
                    //Obtener respuesta de la llamada al API
                    Map<String, Object> createPriceListEntryResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPriceListEntryResponseStr);
                    Map<String, Object> epcPriceListEntryResponseMap = (Map<String, Object>) createPriceListEntryResponseMap.get('epcResponse');
                    if (epcPriceListEntryResponseMap.containsKey('overallResult') && String.valueOf(epcPriceListEntryResponseMap.get('overallResult')) == 'failure') {
                        errorMessage = (String) epcPriceListEntryResponseMap.get('failureReason');
                        response = 'Error';
                        responseDescription = 'Error: La actualización del ajuste de precio no se procesó correctamente: ' + errorMessage;
                    } else {
                        List<Object> priceListEntryEntitiesList = (List<Object>)epcPriceListEntryResponseMap.get('entities');
                        Map<String, Object> priceListEntryEntitiesMap = (Map<String, Object>)priceListEntryEntitiesList[0];
                        Map<String, Object> priceListEntryEntityMap = (Map<String, Object>)priceListEntryEntitiesMap.get('entity');
                        priceListEntryId = (String)priceListEntryEntityMap.get('Id');
                        response = 'Éxito';
                        responseDescription = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + idMaterial;  //##Test.insertaEntradaPreciosPromo
                    }
                } else{
                    Id pricelistentryTyT = ruleAssignment[0].vlocity_cmt__ObjectId__c;
                    System.debug('--- pricelistentryTyT ' + pricelistentryTyT);

                    // Obtener información del pricelistentry (pricelistentryTyT)
                    List<vlocity_cmt__PriceListEntry__c> lastPriceListEntryAdjustmentTyT =  [SELECT vlocity_cmt__PricingElementId__c, vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c, vlocity_cmt__EffectiveFromDate__c, vlocity_cmt__EffectiveUntilDate__c FROM vlocity_cmt__PriceListEntry__c  WHERE Id = :pricelistentryTyT WITH SECURITY_ENFORCED];
                    System.debug('--- Nos estamos trayendo el campo vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c:');
                    System.debug('--- lastPriceListEntryAdjustmentTyT: ' + JSON.serialize(lastPriceListEntryAdjustmentTyT));
                    System.debug('--- lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c: ' + lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c);
                    System.debug('--- discountAmountInt: ' + discountAmountInt);
                    Decimal adjustmentValue = (Decimal) lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c;
                    System.debug('--- adjustmentValue: ' + adjustmentValue);

                    if (discountAmountInt != adjustmentValue){
                        //Actualizar útlima entrada de ajuste de precio
                        System.debug('--- ActualizandoPriceListEntry TyT: Existe un Ajuste de Precio activo para este promotion Item: ' + promotionItemId);
                        System.debug('--- ActualizandoPriceListEntry TyT: Actualizando fecha fin de la ultima entrada activa para este promotion Item: ' + promotionItemId);
                        System.debug('--- adjustmentStartDate TyT: ' + startDateEpoch);
                        DateTime priceListEntryEffectiveUntilDateTime = DateTime.newInstance(startDateEpoch);
                        System.debug('--- priceListEntryEffectiveUntilDateTime: ' + priceListEntryEffectiveUntilDateTime);
                        if(lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__EffectiveFromDate__c >= priceListEntryEffectiveUntilDateTime){
                            System.debug('--- No se procesa por tener una vigencia anterior al precio activo actual');
                            registrarResultado(scope[0], 'Éxito', 'Exito: No se procesa por tener una vigencia anterior al precio activo actual');
                            return;
                        }
                        lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__EffectiveUntilDate__c = priceListEntryEffectiveUntilDateTime;
                        System.debug('--- lastPriceListEntryEffectiveUntilDateTime: ' + lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__EffectiveUntilDate__c);
                        update lastPriceListEntryAdjustmentTyT;
                        //Actualizar entradas viejas que sean anteriores a la última enrada de ajuste de precio
                        System.debug('--- ActualizandoPriceListEntry TyT: Actualizando fecha fin de la ultima entrada activa para este promotion Item: ' + promotionItemId);
                        System.debug('--- ActualizandoPriceListEntry TyT: Fecha de Inicio de la última entrada de precio: ' + lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__EffectiveFromDate__c);
                        List<vlocity_cmt__PriceListEntry__c> oldPriceListEntryAdjustments = [SELECT Id, vlocity_cmt__PricingElementId__c FROM vlocity_cmt__PriceListEntry__c  WHERE vlocity_cmt__IsActive__c = true AND vlocity_cmt__EffectiveFromDate__c < :lastPriceListEntryAdjustmentTyT[0].vlocity_cmt__EffectiveFromDate__c AND vlocity_cmt__PromotionId__c = :promoId AND vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__EffectiveFromDate__c < TODAY AND vlocity_cmt__EffectiveUntilDate__c < TODAY WITH SECURITY_ENFORCED];

                        Set<Id> oldPLEIds = new Set<Id>();
                        for(vlocity_cmt__PriceListEntry__c oldPLE : oldPriceListEntryAdjustments){
                            oldPLEIds.add(oldPLE.Id);
                        }
                        System.debug('--- oldPLEIds: ' + oldPLEIds);
                        System.debug('--- adjCtxRule: ' + adjCtxRule);
                        // Obtener la PriceListEntry asociada a la regla (adjCtxRule)
                        List<vlocity_cmt__RuleAssignment__c> ruleAssignmentOldPLE = [SELECT vlocity_cmt__ObjectId__c FROM vlocity_cmt__RuleAssignment__c WHERE vlocity_cmt__RuleId__r.Name = :adjCtxRule AND vlocity_cmt__ObjectId__c IN :oldPLEIds WITH SECURITY_ENFORCED];
                        System.debug('--- ruleAssignmentOldPLE: ' + JSON.serialize(ruleAssignmentOldPLE));
                        Set<Id> ruleObjectIds = new Set<Id>();
                        for(vlocity_cmt__RuleAssignment__c ruleObject : ruleAssignmentOldPLE){
                            ruleObjectIds.add(ruleObject.vlocity_cmt__ObjectId__c);
                        }
                        List<vlocity_cmt__PriceListEntry__c> oldPriceListEntryFiltered = [SELECT Id, vlocity_cmt__PricingElementId__c FROM vlocity_cmt__PriceListEntry__c  WHERE Id IN :ruleObjectIds WITH SECURITY_ENFORCED];
                        if (oldPriceListEntryFiltered.size() > 0) {
                            //Actualizar las entradas de precio viejas a is active -> false
                            for (Integer j= 0; j<oldPriceListEntryFiltered.size(); j++) {
                                System.debug('--- ActualizandoPriceListEntry TyT: Actualizando is active ->false para entradas viejas ');
                                oldPriceListEntryFiltered[j].vlocity_cmt__IsActive__c = false;
                            }
                            update oldPriceListEntryFiltered;
                        }
                        //Crear el price list entry para el ajuste de precio
                        String priceListEntryReq = '{"epcRequest":{"entity":{"vlocity_cmt__PriceListId__c":"' + priceListId + '","vlocity_cmt__DisplayText__c":"' +adjustmentOneTimeDisplayName + '","vlocity_cmt__EffectiveFromDate__c":' + startDateEpoch +',"vlocity_cmt__IsActive__c":true,"vlocity_cmt__IsOverride__c":false,"vlocity_cmt__OfferId__c":"","vlocity_cmt__PricingElementId__c":"' + pricingElementId +'","vlocity_cmt__PricingMatrixBindingData__c":"","vlocity_cmt__ProductId__c":"' + productId + '","vlocity_cmt__PromotionId__c":"' + promoId + '","vlocity_cmt__PromotionItemId__c":"' + promotionItemId + '","vlocity_cmt__RuleDescription__c":"","vlocity_cmt__TimePlanId__c":"","vlocity_cmt__TimePolicyId__c":""}}}';
                        System.debug('--- priceListEntryReq (ajuste de precio): ' + priceListEntryReq);
                        Object createPriceListEntryResponse = vlocity_cmt.ProductConsoleControllerV2.invokeMethod('addPriceListEntry',priceListEntryReq);
                        System.debug('--- createPriceListEntryResponse: ' + createPriceListEntryResponse);
                        String createPriceListEntryResponseStr = JSON.serialize(createPriceListEntryResponse);
                        createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('\\"', '"');
                        createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('"{', '{');
                        createPriceListEntryResponseStr = createPriceListEntryResponseStr.replace('}"', '}');
                        System.debug('--- createPriceListEntryResponseStr: ' + createPriceListEntryResponseStr);
                        //Obtener respuesta de la llamada al API
                        Map<String, Object> createPriceListEntryResponseMap = (Map<String, Object>)JSON.deserializeUntyped(createPriceListEntryResponseStr);
                        Map<String, Object> epcPriceListEntryResponseMap = (Map<String, Object>) createPriceListEntryResponseMap.get('epcResponse');
                        //Analiza la respuesta para ver si hay error y mostrarlo en el Flow
                        if (epcPriceListEntryResponseMap.containsKey('overallResult') && String.valueOf(epcPriceListEntryResponseMap.get('overallResult')) == 'failure') {
                            errorMessage = (String) epcPriceListEntryResponseMap.get('failureReason');
                            response = 'Error';
                            responseDescription = 'Error: La actualización del ajuste de precio no se procesó correctamente: ' + errorMessage;
                        } else {
                            List<Object> priceListEntryEntitiesList = (List<Object>)epcPriceListEntryResponseMap.get('entities');
                            Map<String, Object> priceListEntryEntitiesMap = (Map<String, Object>)priceListEntryEntitiesList[0];
                            Map<String, Object> priceListEntryEntityMap = (Map<String, Object>)priceListEntryEntitiesMap.get('entity');
                            priceListEntryId = (String)priceListEntryEntityMap.get('Id');
                            if (discountAmountInt == 0 && descuentoNulo == true){
                            	response = 'Éxito';
                        		responseDescription = 'Valor descuento vacío, actualiza promoción a cero';  //##Test.insertaEntradaPreciosPromo
                        	} else {
                                response = 'Éxito';
                                responseDescription = 'Éxito: Se ha creado la entrada de precio exitosamente para el producto ' + idMaterial;  //##Test.insertaEntradaPreciosPromo
                        	}
                        }
                    }
                    else if (discountAmountInt == 0 && descuentoNulo == true){
                        System.debug('--- : Éxito: Tiene promoción ya tiene cero.');
                        registrarResultado(scope[0], 'Éxito', 'Valor descuento vacío, tiene promoción ya tiene cero');
                        return;            
                    }
                    else{
                        System.debug('--- : Éxito: No se actualiza la entrada porque es el mismo precio del actual descuento activo');
                        registrarResultado(scope[0], 'Éxito', 'Éxito: No se actualiza la entrada porque es el mismo precio del actual descuento activo');
                        return;
                    }
                }
            }
/*
            // Si el valor del ajuste es 0, entonces el ajuste debe actualizarse la fecha de salida
            if(discountAmountInt != null){
                if(discountAmountInt == 0 && promoIsActive == true){
                    List<vlocity_cmt__PriceListEntry__c> pleAdjIsZeroList = [SELECT Id, vlocity_cmt__IsActive__c, vlocity_cmt__EffectiveUntilDate__c FROM vlocity_cmt__PriceListEntry__c WHERE Id = :priceListEntryId WITH SECURITY_ENFORCED LIMIT 1];
                    System.debug('--- pleAdjIsZeroList: ' + JSON.serialize(pleAdjIsZeroList));
                    vlocity_cmt__PriceListEntry__c pleAdjIsZero = pleAdjIsZeroList[0];
                    // Inactivar pricelistentry cuyo ajuste es 0
                    System.debug('--- pleAdjIsZero: ' + pleAdjIsZero);
                    System.debug('--- priceListEntryId: ' + priceListEntryId);
                    System.debug('--- ActualizandoPriceListEntry TyT: Actualizando  fecha fin entrada para entradas viejas ');
                    Datetime priceListEntryEffectiveUntilDateTime = DateTime.now();
                    pleAdjIsZero.vlocity_cmt__EffectiveUntilDate__c = priceListEntryEffectiveUntilDateTime;
                    update pleAdjIsZero;
                    System.debug('--- El ajuste de precio ha sido actualizado porque su valor es 0'); 

                    // Obtener las últimas entradas de precio (vlocity_cmt__EffectiveUntilDate__c = null)
                    List<vlocity_cmt__PriceListEntry__c> latestPriceListEntryAdjustments = [SELECT Id FROM vlocity_cmt__PriceListEntry__c WHERE vlocity_cmt__EffectiveUntilDate__c = null AND vlocity_cmt__PromotionId__c = :promoId AND vlocity_cmt__ProductId__c = :productId AND vlocity_cmt__IsActive__c = true WITH SECURITY_ENFORCED];
                    System.debug('--- latestPriceListEntryAdjustments: ' + JSON.serialize(latestPriceListEntryAdjustments));

                    // Verificar que los últimos ajustes de precio estén inactivos
                    Integer totalCount = latestPriceListEntryAdjustments.size();
                    // Si todas las entradas están inactivas, entonces se desactive la promoción
                    if(totalCount == 0){
                        vlocity_cmt__Promotion__c promoToUpdate = promoActiveList[0];
                        System.debug('--- promoToUpdate: ' + promoToUpdate);                        
                        promoToUpdate.vlocity_cmt__EffectiveEndDate__c = priceListEntryEffectiveUntilDateTime;
                        promoToUpdate.vlocity_cmt__IsOrderable__c = false;
                        update promoToUpdate;
                        System.debug('--- La fecha de fin de la promoción ha sido actualizada porque todos sus últimos ajustes de precio están inactivos'); 
                    }
                /* } else if(discountAmountInt != 0 && promoIsActive == false){
                    // Activar la promoción
                    vlocity_cmt__Promotion__c promoToActivate = promoActiveList[0];
                    System.debug('--- promoToActivate: ' + promoToActivate);
                    promoToActivate.vlocity_cmt__IsActive__c = true;
                    promoToActivate.vlocity_cmt__IsOrderable__c = true;
                    update promoToActivate;
                    System.debug('--- La promoción ha sido activada porque el monto del ajuste es diferente a 0'); 
                }
            }*/

            //Regla de contexto del ajuste: Leer la regla de contexto del mapeo que se crea cuando se instancia la clase batch y asignar la regla al ajuste.
            String ctxRuleSetId;
            if( adjCtxRule != '' &&  adjCtxRule != null){
                List<vlocity_cmt__Rule__c> ctxRuleList = [SELECT Id FROM vlocity_cmt__Rule__c WHERE Name = : adjCtxRule WITH SECURITY_ENFORCED LIMIT 1];
                if(ctxRuleList.size() != 0){
                    ctxRuleSetId = (String)ctxRuleList[0].get('Id');
                    System.debug('---  adjCtxRule: ' +  adjCtxRule);
                    System.debug('--- ctxRuleSetId: ' + ctxRuleSetId);
                    vlocity_cmt.PCAppHandler pcAppHandlerCall = new vlocity_cmt.PCAppHandler();

                    Map<String, Object> outputMap = new Map<String, Object>();
                    Map<String, Object> optionsMap = new Map<String, Object>();

                    pcAppHandlerCall.invokeMethod('addContextRule', new map<String, object>{'epcRequest'=>new map<String, object>{'entity'=>new map<String, String>{'vlocity_cmt__ObjectId__c'=>priceListEntryId,'vlocity_cmt__RuleId__c'=>ctxRuleSetId}}}, outputMap, optionsMap);
                   /* if(isPromoTodoClaro == true){
                        pcAppHandlerCall.invokeMethod('addContextRule', new map<String, object>{'epcRequest'=>new map<String, object>{'entity'=>new map<String, String>{'vlocity_cmt__ObjectId__c'=>promoId,'vlocity_cmt__RuleId__c'=>ctxRuleSetId}}}, outputMap, optionsMap);
                    } else{
                        pcAppHandlerCall.invokeMethod('addContextRule', new map<String, object>{'epcRequest'=>new map<String, object>{'entity'=>new map<String, String>{'vlocity_cmt__ObjectId__c'=>priceListEntryId,'vlocity_cmt__RuleId__c'=>ctxRuleSetId}}}, outputMap, optionsMap);
                    } */
                }
                else{
                    //No se encontró la regla de contexto
                    System.debug('--- No se encontró el Id de la regla de contexto ' +  adjCtxRule);
                }
            }
        }

        //Actualizar el registro en el objeto personalizado en el campo CAT_Resultado_Procesamiento__c con OK o con el error correspondiente si es que se tuvo un error.
        registrarResultado(scope[0], response, responseDescription);
        System.debug(':: FIN CATActualizacionPreciosSAPBatch.execute ');
    }

    private void asignarListaPrecio(String sfCode, String priceListId, Boolean esTodoClaro, String reglaCtx) {
        this.sf_pl_code      = sfCode;
        this.priceListId     = priceListId;
        this.isPromoTodoClaro = esTodoClaro;
        this.adjCtxRule      = reglaCtx;
    }

    private void registrarResultado(CAT_Informacion_Precios_SAP_tmp__c registro, String resultado, String descripcion) {
        registro.CAT_Resultado_Procesamiento__c = resultado;
        registro.CAT_Descripcion_Procesamiento__c = descripcion;
        registro.CAT_Id_Job_Procesamiento__c = this.batchJobId15;
        update registro;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch CATActualizacionPreciosSAPBatch finalizado.');
    }
}