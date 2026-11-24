/*--------------------------------------------------------------------------
 * Author: Nahir Arrejoria - narrejoria@salesforce.com
 * Company: Salesforce.com
 * Description: Clase responsable de extraer datos de Salesforce y cargarlos 
 * en objetos custom para su posterior exportación.
 * Code Coverage: 96%
 * History
 * <Date>       <Author>        	<Description>       														<Version>
 * 07-Oct-25	Nahir Arrejoria		Implementación de logica de extracción y llenado de objetos					0.1
 * 02-Dic-25	Nahir Arrejoria		Se agrega lógica temporal para manejar la estructura de múltiples atributo 	0.2
 * 16-Dic-25 	Nahir Arrejoria		Nueva lógica para obtener AttributeAssignment y CAT_AsignacionAt 			0.3
 * 17-Dic-25 	Nahir Arrejoria		Nueva lógica para campos como atributos							 			0.4
 *----------------------------------------------------------------------------*/
 public with sharing class CATAttributeExportBatch implements Database.Batchable<SObject> {

    // Member variables to hold data queried in the constructor
   private Map<Id, Product2> allProductsById;
   private Map<String, vlocity_cmt__ProductChildItem__c> parentProductByChildProductCode;

   // HOTFIX HDU 825558: Parámetros para encadenar la cadena de precios desde finish().
   // Los atributos (CAT_AtributosProductosExportados__c) dejan de lanzarse sueltos: este
   // batch pasa a ser el primer eslabón de la cadena síncrona
   //   atributos -> precios -> promociones -> calculateAndUpdateData (notifica).
   // Antes CATAttributeExportBatch corría en paralelo vía Flex Queue y la notificación
   // (enqueue en calculateAndUpdateData) podía dispararse ANTES de que terminara de
   // insertar los atributos, de modo que el consumo externo vía Bulk API obtenía un
   // conteo incompleto de CAT_AtributosProductosExportados__c.
   private Boolean chainPrices = false;
   private List<String> priceCodeList;
   private String objetoControlId;
   private Id idLogRecord;
   private List<String> productCodeList;
   private List<String> promotionCodeList;
   private String tipoCarga;

   // Cache Map: Field Name => Data Type String
   private Map<String, String> fieldTypeCache = new Map<String, String>();
   private Map<String, String> fieldLabelCache = new Map<String, String>();

   // The constructor remains the same, accepting the product and hierarchy data.
   public CATAttributeExportBatch( Map<Id, Product2> allProducts, Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode) {
       this.allProductsById = allProducts;
       this.parentProductByChildProductCode = parentsByChildCode;

       // --- CACHE INITIALIZATION ---
       // Perform describes once in the constructor
       Map<String, Schema.SObjectField> fieldMap = Product2.SObjectType.getDescribe().fields.getMap();
       for (String fieldName : VIRTUAL_ATTR_FIELDS) {
           if (fieldMap.containsKey(fieldName)) {
               // Get the describe result once for efficiency
               Schema.DescribeFieldResult dResult = fieldMap.get(fieldName).getDescribe();
               
               // Cache the Data Type
               fieldTypeCache.put(fieldName, String.valueOf(dResult.getType()));
               
               // Cache the Label
               fieldLabelCache.put(fieldName, dResult.getLabel());
           }
       }
   }

   // HOTFIX HDU 825558: Constructor que, además de los datos de atributos, recibe los
   // parámetros para encadenar CATProductPricesExportBatch en finish(). Con esto la
   // notificación de "finalizado" solo se emite cuando atributos, precios y promociones
   // ya terminaron, evitando el conteo incompleto de CAT_AtributosProductosExportados__c.
   public CATAttributeExportBatch(
       Map<Id, Product2> allProducts,
       Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode,
       List<String> priceCodeList,
       String objetoControlId,
       Id idLogRecord,
       List<String> productCodeList,
       List<String> promotionCodeList,
       String tipoCarga
   ) {
       this(allProducts, parentsByChildCode);
       this.chainPrices = true;
       this.priceCodeList = (priceCodeList != null) ? priceCodeList : new List<String>();
       this.objetoControlId = objetoControlId;
       this.idLogRecord = idLogRecord;
       this.productCodeList = (productCodeList != null) ? productCodeList : new List<String>();
       this.promotionCodeList = (promotionCodeList != null) ? promotionCodeList : new List<String>();
       this.tipoCarga = tipoCarga;
   }

   // List of Product2 fields to be treated as individual attributes if they have values
   private final List<String> VIRTUAL_ATTR_FIELDS = new List<String>{
       'CAT_ApplicableCountries__c',
       'CAT_ApplicableCountriesAdd__c'
   };
       
   

   // Start method: Queries all the records to be processed. 
   // NOW RETURNS PRODUCT2 RECORDS, NOT ATTRIBUTE ASSIGNMENTS.
   public Database.QueryLocator start(Database.BatchableContext bc) {
       Set<Id> allRelevantProductIds = allProductsById.keySet();
       
       // Query the Product2 records that will define the execution scope chunks.
       return Database.getQueryLocator([
           SELECT Id, ProductCode, Name, vlocity_cmt__SpecificationSubType__c, vlocity_cmt__Type__c,
           CAT_ApplicableCountries__c, CAT_ApplicableCountriesAdd__c //fields that are considered attributes
           FROM Product2
           WHERE Id IN :allRelevantProductIds
           WITH USER_MODE
       ]);
   }

   // Execute method: Contains the core processing logic for each chunk of Product2 records.
   public void execute(Database.BatchableContext bc, List<Product2> scope) {
       System.debug('Processing a batch of ' + scope.size() + ' Product2 records.');

       List<CAT_AtributosProductosExportados__c> atributosProdExportados = new List<CAT_AtributosProductosExportados__c>();
       Set<Id> scopeProductIds = new Set<Id>();
       for (Product2 prod : scope) {
           scopeProductIds.add(prod.Id);
       }

       // 1. Get ALL Vlocity Assignments for the current product batch
       List<vlocity_cmt__AttributeAssignment__c> vlocityAssignments = [
           SELECT 
               Id, vlocity_cmt__ObjectId__c, vlocity_cmt__Value__c,
               vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c, vlocity_cmt__AttributeId__r.Name,
               vlocity_cmt__AttributeCategoryId__r.Name, vlocity_cmt__AttributeId__r.vlocity_cmt__ValueType__c,
               vlocity_cmt__IsRequired__c, vlocity_cmt__IsReadOnly__c, vlocity_cmt__IsHidden__c
           FROM vlocity_cmt__AttributeAssignment__c
           WHERE vlocity_cmt__ObjectId__c IN :scopeProductIds
          // AND vlocity_cmt__IsActiveAssignment__c = TRUE
           WITH USER_MODE
       ];
       
       // 2. Get ALL Custom Assignments for the current product batch
       List<CAT_AsignacionAt__c> customAssignments = [
           SELECT 
               Id, CAT_Producto__c, CAT_Valor__c, 
               CAT_Atributo_Informativo__r.CAT_Codigo__c, CAT_Atributo_Informativo__r.Name,
               CAT_Atributo_Informativo__r.CAT_Categoria__c, CAT_Atributo_Informativo__r.CAT_Tipo_dato__c,
               CAT_Oculto__c, CAT_Solo_lectura__c, CAT_Asignacion_activa__c
           FROM CAT_AsignacionAt__c
           WHERE CAT_Producto__c IN :scopeProductIds
           //AND CAT_Asignacion_activa__c = TRUE
           WITH USER_MODE
       ];
       
       // Combine all assignments into one list for processing (Map for easy product lookup)
       Map<Id, Product2> productsInScopeMap = new Map<Id, Product2>(scope);
       
       // --- PROCESS DATA ---
       for (Product2 prod : scope) {
           // Process Virtual Attributes (Product Fields)
           for (String fieldName : VIRTUAL_ATTR_FIELDS) {
               Object value = prod.get(fieldName);
               if (value != null && String.isNotBlank(String.valueOf(value))) {
                   processVirtualAttribute(fieldName, String.valueOf(value), prod, this.parentProductByChildProductCode, atributosProdExportados);
               }
           }
       }
       
       // Process Vlocity Assignments
       for (vlocity_cmt__AttributeAssignment__c att : vlocityAssignments) {
           Product2 currentProduct = productsInScopeMap.get(att.vlocity_cmt__ObjectId__c);
           if (currentProduct != null) {
               // Call helper function to create export records for Vlocity Assignment
               processVlocityAssignment(att, currentProduct, this.parentProductByChildProductCode, atributosProdExportados);
           }
       }
       
       // Process Custom Assignments
       for (CAT_AsignacionAt__c customAtt : customAssignments) {
           Product2 currentProduct = productsInScopeMap.get(customAtt.CAT_Producto__c);
           if (currentProduct != null) {
               // Call helper function to create export records for Custom Assignment
               processCustomAssignment(customAtt, currentProduct, this.parentProductByChildProductCode, atributosProdExportados);
           }
       }

       if (!atributosProdExportados.isEmpty()) {
           insert as user atributosProdExportados;
       }
   }

   // --- NEW HELPER FUNCTION: Process Virtual Attribute (Product Field) ---
   private void processVirtualAttribute(String fieldName, String value, Product2 prod,
                                       Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode,
                                       List<CAT_AtributosProductosExportados__c> exportList) {
       
       CAT_AtributosProductosExportados__c info = new CAT_AtributosProductosExportados__c();
                                           
       info.CAT_CodigoAtributos__c = fieldName; // The field API name acts as the code
       info.CAT_NombreAtributos__c = fieldLabelCache.get(fieldName);
       info.CAT_NombreCategoriaAtributos__c = 'Generales';  
       info.CAT_ValorAtributos__c = value;
       info.CAT_TipoDatoAtributos__c = fieldTypeCache.get(fieldName);
       info.CAT_RequeridoAtributos__c = false; //valores default
       info.CAT_OcultoAtributos__c = false; //valores default
       info.CAT_SoloLecturaAtributos__c = true; //valores default
       info.CAT_CodigoProductoAtributos__c = getParentProductCode(prod, parentsByChildCode);
       exportList.add(info);
   }
   // --- HELPER FUNCTION: Process Simple/Standard Vlocity Assignment (original logic) ---
   private void processVlocityAssignment(vlocity_cmt__AttributeAssignment__c att, Product2 currentProduct, 
                                       Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode, 
                                       List<CAT_AtributosProductosExportados__c> exportList) {
       
       final String PRIMARY_DELIMITER = '##'; 
       final String SECONDARY_DELIMITER = ':'; 
       String compositeValue = att.vlocity_cmt__Value__c;
       String productCodeToUse = getParentProductCode(currentProduct, parentsByChildCode);
       
       // --- COMPLEX STRUCTURE CHECK (Original V0.2 Logic) ---
       if (String.isNotBlank(compositeValue) && compositeValue.contains(PRIMARY_DELIMITER)) {
           // SCENARIO 1: COMPLEX/MULTI-ATTRIBUTE STRUCTURE
           List<String> attributeChunks = compositeValue.split(PRIMARY_DELIMITER);
           for (String chunk : attributeChunks) {
               List<String> codeAndValue = chunk.trim().split(SECONDARY_DELIMITER, 2);
               if (codeAndValue.size() == 2) {
                   CAT_AtributosProductosExportados__c infoAtributos = new CAT_AtributosProductosExportados__c();
                   infoAtributos.CAT_NombreAtributos__c = att.vlocity_cmt__AttributeId__r.Name;
                   infoAtributos.CAT_NombreCategoriaAtributos__c = att.vlocity_cmt__AttributeCategoryId__r.Name;
                   infoAtributos.CAT_TipoDatoAtributos__c = att.vlocity_cmt__AttributeId__r.vlocity_cmt__ValueType__c;
                   infoAtributos.CAT_RequeridoAtributos__c = att.vlocity_cmt__IsRequired__c;
                   infoAtributos.CAT_OcultoAtributos__c = att.vlocity_cmt__IsHidden__c;
                   infoAtributos.CAT_SoloLecturaAtributos__c = att.vlocity_cmt__IsReadOnly__c;
                   infoAtributos.CAT_CodigoProductoAtributos__c = productCodeToUse;
                   infoAtributos.CAT_CodigoAtributos__c = codeAndValue[0].trim(); // Parsed Code
                   infoAtributos.CAT_ValorAtributos__c = codeAndValue[1].trim(); // Parsed Value
                   exportList.add(infoAtributos);
               } else {
                   System.debug('VLOCITY ERROR: Skipping attribute chunk due to incorrect secondary delimiter format: ' + chunk);
               }
           }
       } else {
           // SCENARIO 2: SIMPLE/SINGLE-ATTRIBUTE STRUCTURE
           CAT_AtributosProductosExportados__c infoAtributos = new CAT_AtributosProductosExportados__c();
           infoAtributos.CAT_CodigoAtributos__c = att.vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c;
           infoAtributos.CAT_NombreAtributos__c = att.vlocity_cmt__AttributeId__r.Name;
           infoAtributos.CAT_NombreCategoriaAtributos__c = att.vlocity_cmt__AttributeCategoryId__r.Name;
           infoAtributos.CAT_ValorAtributos__c = compositeValue;
           infoAtributos.CAT_TipoDatoAtributos__c = att.vlocity_cmt__AttributeId__r.vlocity_cmt__ValueType__c;
           infoAtributos.CAT_RequeridoAtributos__c = att.vlocity_cmt__IsRequired__c;
           infoAtributos.CAT_OcultoAtributos__c = att.vlocity_cmt__IsHidden__c;
           infoAtributos.CAT_SoloLecturaAtributos__c = att.vlocity_cmt__IsReadOnly__c;
           infoAtributos.CAT_CodigoProductoAtributos__c = productCodeToUse;
           exportList.add(infoAtributos);
       }
   }

   // --- NEW HELPER FUNCTION: Process Custom Attribute Assignment ---
   private void processCustomAssignment(CAT_AsignacionAt__c customAtt, Product2 currentProduct, 
                                       Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode, 
                                       List<CAT_AtributosProductosExportados__c> exportList) {
       
       String productCodeToUse = getParentProductCode(currentProduct, parentsByChildCode);
       
       CAT_AtributosProductosExportados__c infoAtributos = new CAT_AtributosProductosExportados__c();
       
       infoAtributos.CAT_CodigoAtributos__c = customAtt.CAT_Atributo_Informativo__r.CAT_Codigo__c;
       infoAtributos.CAT_NombreAtributos__c = customAtt.CAT_Atributo_Informativo__r.Name;
       infoAtributos.CAT_NombreCategoriaAtributos__c = customAtt.CAT_Atributo_Informativo__r.CAT_Categoria__c; 
       infoAtributos.CAT_TipoDatoAtributos__c = customAtt.CAT_Atributo_Informativo__r.CAT_Tipo_dato__c;
       infoAtributos.CAT_ValorAtributos__c = customAtt.CAT_Valor__c;
       infoAtributos.CAT_OcultoAtributos__c = customAtt.CAT_Oculto__c;
       infoAtributos.CAT_SoloLecturaAtributos__c = customAtt.CAT_Solo_lectura__c;
       
       infoAtributos.CAT_CodigoProductoAtributos__c = productCodeToUse;
       
       exportList.add(infoAtributos);
   }
   
   // --- HELPER FUNCTION: Determine the Product Code to Use ---
   private String getParentProductCode(Product2 currentProduct, Map<String, vlocity_cmt__ProductChildItem__c> parentsByChildCode) {
       String productCodeToUse = currentProduct.ProductCode;
       
       if (currentProduct.vlocity_cmt__SpecificationSubType__c == 'Simple' && currentProduct.vlocity_cmt__Type__c == 'Plan') {
           String productCod = currentProduct.ProductCode;
           if(parentsByChildCode.containsKey(productCod)) {
               // Ensure the ParentProductId__r.ProductCode relationship is available in the map's ProductChildItem record
               productCodeToUse = parentsByChildCode.get(productCod).vlocity_cmt__ParentProductId__r.ProductCode;
           }
       }
       return productCodeToUse;
   }


   // Finish method: Optional for post-processing logic
   public void finish(Database.BatchableContext bc) {
       System.debug('Batch process for attributes completed.');

       // HOTFIX HDU 825558: Primer eslabón de la cadena síncrona. Solo cuando este batch
       // de atributos terminó de insertar, se dispara la cadena de precios -> promociones
       // -> calculateAndUpdateData (que notifica). Así la notificación nunca se adelanta
       // a la carga de CAT_AtributosProductosExportados__c.
       if (chainPrices) {
           CATProductPricesExportBatch pricesBatch = new CATProductPricesExportBatch(
               priceCodeList,
               objetoControlId,
               idLogRecord,
               productCodeList,
               promotionCodeList,
               tipoCarga
           );
           Database.executeBatch(pricesBatch, 50);
       }
   }
}