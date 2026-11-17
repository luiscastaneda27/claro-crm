/*******************************************************************************
* Autor: Eliana Piña
* Fecha: 2025-12-23
* Equipo: Catálogo
* Code Coverage:
* Descripcion: Procesa un archivo CSV cargado en Salesforce para actualizar los valores de atributos de productos B2C en Salesforce Industries (Vlocity), de forma asíncrona usando un Queueable.
También maneja atributos 
*              informativos personalizados almacenados en CAT_AsignacionAt__c.
* History
<Date>            <Author>             <Description>       <Version>
2025-12-23        Eliana Piña                              Versión Inicial 
2025-01-06        Eliana Piña           Agregar soporte para atributos informativos 1.1
***********************************************************************************/
public with sharing class CAT_ProductAttributeCsvQueueable implements Queueable {

    private Id contentVersionId;

    public CAT_ProductAttributeCsvQueueable(Id contentVersionId) {
        this.contentVersionId = contentVersionId;
    }

    public void execute(QueueableContext context) {
        // Leer CSV
        ContentVersion cv = [
            SELECT VersionData,Title
            FROM ContentVersion
            WHERE Id = :contentVersionId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        String csv;
        try {
            csv = cv.VersionData.toString();
        } catch (Exception e) {
            String errorMsg = 'ERROR: El archivo "' + cv.Title + '" no está en formato UTF-8 válido.\n\n' +
                            'INSTRUCCIONES PARA EL USUARIO:\n' +
                            '1. Abra el archivo en Excel\n' +
                            '2. Archivo > Guardar como\n' +
                            '3. En "Tipo", seleccione: "CSV UTF-8 (delimitado por comas) (*.csv)"\n' +
                            '4. Guarde y vuelva a subir';
            throw new AuraHandledException(errorMsg);
        }
        
        List<String> lines = csv.split('\n');

        if (lines.size() < 3) {
            return;
        }

        // Headers de atributos (línea 1 - índice 1)
        List<String> headerCodes = parseCsvLine(lines[1]);
        for (Integer i = 0; i < headerCodes.size(); i++) {
            // Mostrar códigos de caracteres para espacios
            if (headerCodes[i].contains(' ')) {
                String codes = '';
                for (Integer j = 0; j < headerCodes[i].length(); j++) {
                    Integer charCode = headerCodes[i].charAt(j);
                    codes += charCode + ' ';
                }
            }
        }

        // Mapear columnas a códigos de atributo
        Map<Integer, String> colIndexToAttrCode = new Map<Integer, String>();
        for (Integer i = 1; i < headerCodes.size(); i++) {
            if (String.isNotBlank(headerCodes[i])) {
                String attrCode = headerCodes[i].trim();
                
                attrCode = normalizeSpaces(attrCode);
                colIndexToAttrCode.put(i, attrCode);
            }
        }

        // Recopilar todos los materiales
        Set<String> materiales = new Set<String>();
        Map<String, List<String>> filasPorMaterial = new Map<String, List<String>>();
        
        for (Integer rowIdx = 2; rowIdx < lines.size(); rowIdx++) {
            List<String> cols = parseCsvLine(lines[rowIdx]);
            
            if (cols.size() < 2) {
                continue;
            }

            String material = cols[1].trim();
            if (String.isBlank(material)) {
                continue;
            }

            materiales.add(material);
            filasPorMaterial.put(material, cols);
        }

     

        // Buscar todos los productos en una sola query
        Map<String, Id> productIdPorMaterial = new Map<String, Id>();
        
        if (!materiales.isEmpty()) {
            // Crear lista de códigos de producto a buscar
            Set<String> codigosProducto = new Set<String>();
            for (String material : materiales) {
                String codigo = 'B2C-TEC-OFER-' + material;
                codigosProducto.add(codigo);
            }
            
            // Query única para todos los productos
            for (Product2 prod : [
                SELECT Id, ProductCode
                FROM Product2
                WHERE ProductCode IN :codigosProducto
                WITH SECURITY_ENFORCED
            ]) {
                // Extraer el material del ProductCode
                if (prod.ProductCode.startsWith('B2C-TEC-OFER-')) {
                    String material = prod.ProductCode.substringAfter('B2C-TEC-OFER-');
                    productIdPorMaterial.put(material, prod.Id);
                }
            }
        }
        
    

        // Buscar todos los atributos en una sola query
        Map<Id, Map<String, vlocity_cmt__AttributeAssignment__c>> atributosPorProducto = 
            new Map<Id, Map<String, vlocity_cmt__AttributeAssignment__c>>();
        
        if (!productIdPorMaterial.isEmpty()) {
            Set<Id> productIds = new Set<Id>(productIdPorMaterial.values());
            for (vlocity_cmt__AttributeAssignment__c aa : [
                SELECT Id, Name, vlocity_cmt__Value__c, vlocity_cmt__ObjectId__c
                FROM vlocity_cmt__AttributeAssignment__c
                WHERE vlocity_cmt__ObjectId__c IN :productIds
                WITH SECURITY_ENFORCED
                ORDER BY vlocity_cmt__ObjectId__c, Name
            ]) {
                Id productId = aa.vlocity_cmt__ObjectId__c;
                
                if (!atributosPorProducto.containsKey(productId)) {
                    atributosPorProducto.put(productId, new Map<String, vlocity_cmt__AttributeAssignment__c>());
                }
                
                // EXTRAER Y NORMALIZAR EL CÓDIGO DEL ATRIBUTO
                String attrCode = extractAttrCodeFromName(aa.Name);
                if (String.isNotBlank(attrCode)) {
                    // Normalizar espacios para comparación
                    String normalizedAttrCode = normalizeSpaces(attrCode);
                    atributosPorProducto.get(productId).put(normalizedAttrCode, aa);
                }
            }
        }
        
        System.debug('Productos con atributos encontrados: ' + atributosPorProducto.size());

        // Procesar actualizaciones
        List<vlocity_cmt__AttributeAssignment__c> updates = new List<vlocity_cmt__AttributeAssignment__c>();
        
        // Buscar todos los informativos
        Map<String, Id> infoAttrIdByCode = new Map<String, Id>();

        for (CAT_AtInformativos__c info : [
            SELECT Id, CAT_Codigo__c
            FROM CAT_AtInformativos__c WITH SECURITY_ENFORCED
        ]) {
            if (String.isNotBlank(info.CAT_Codigo__c)) {
                infoAttrIdByCode.put(
                    normalizeSpaces(info.CAT_Codigo__c),
                    info.Id
                );
            }
        }

        // ANTES del bucle principal: Buscar todas las asignaciones existentes de atributos informativos
        Map<String, CAT_AsignacionAt__c> asignacionesExistentesMap = new Map<String, CAT_AsignacionAt__c>();
        if (!productIdPorMaterial.isEmpty()) {
            Set<Id> productIds = new Set<Id>(productIdPorMaterial.values());
            
            // Una sola consulta para todas las asignaciones existentes
            for (CAT_AsignacionAt__c asignacion : [
                SELECT Id, CAT_Valor__c, CAT_Atributo_Informativo__c, CAT_Producto__c
                FROM CAT_AsignacionAt__c
                WHERE CAT_Producto__c IN :productIds
                WITH SECURITY_ENFORCED
            ]) {
                // Crear clave única: ProductoId + AtributoInfoId
                String clave = asignacion.CAT_Producto__c + '_' + asignacion.CAT_Atributo_Informativo__c;
                asignacionesExistentesMap.put(clave, asignacion);
            }
        }

        List<CAT_AsignacionAt__c> asignacionesToUpsert = new List<CAT_AsignacionAt__c>();
        
        for (String material : materiales) {
            
            if (!productIdPorMaterial.containsKey(material)) {
                continue;
            }
            
            if (!filasPorMaterial.containsKey(material)) {
                continue;
            }

            Id productId = productIdPorMaterial.get(material);
            List<String> cols = filasPorMaterial.get(material);

            // Verificar si el producto tiene atributos
            if (!atributosPorProducto.containsKey(productId)) {
                System.debug('  Producto no tiene atributos');
                continue;
            }

            Map<String, vlocity_cmt__AttributeAssignment__c> attrByCode = atributosPorProducto.get(productId);

            // Procesar cada columna del CSV para este material
            for (Integer colIdx : colIndexToAttrCode.keySet()) {
                if (colIdx >= cols.size()) {
                    continue;
                }

                String value = cols[colIdx] != null ? cols[colIdx].trim() : '';
                String attrCodeFromCsv = colIndexToAttrCode.get(colIdx);
                
                // NORMALIZAR el código del CSV
                String normalizedCsvAttrCode = normalizeSpaces(attrCodeFromCsv);

                // BUSCAR ATRIBUTO CON COINCIDENCIA EXACTA (después de normalizar)
                if (attrByCode.containsKey(normalizedCsvAttrCode)) {
                    vlocity_cmt__AttributeAssignment__c aa = attrByCode.get(normalizedCsvAttrCode);
                    String currentValue = aa.vlocity_cmt__Value__c;
                    String normalizedCurrent = currentValue != null ? currentValue.trim() : null;

                    // Comparar si hay cambio
                    Boolean hasChanged = false;

                    if (normalizedCurrent == null && String.isNotBlank(value)) {
                        hasChanged = true;
                    } else if (normalizedCurrent != null && normalizedCurrent != value) {
                        hasChanged = true;
                    }
                    
                    if (hasChanged) {
                        aa.vlocity_cmt__Value__c = value;
                        updates.add(aa);
                    } 
                } 
                else {
                    
                    // Buscar atributos similares para debug (coincidencia sin espacios)
                    for (String sfAttrCode : attrByCode.keySet()) {
                        if (sfAttrCode.replace(' ', '').equalsIgnoreCase(normalizedCsvAttrCode.replace(' ', ''))) {
                            vlocity_cmt__AttributeAssignment__c aa = attrByCode.get(sfAttrCode);
                            aa.vlocity_cmt__Value__c = value;
                            updates.add(aa); 
                            break; // Salir del for interno
                        }
                    }
                    
                    // ¿Existe como atributo informativo?
                    if (infoAttrIdByCode.containsKey(normalizedCsvAttrCode)) {
                        Id attrInfoId = infoAttrIdByCode.get(normalizedCsvAttrCode);
                        
                        // Crear clave para buscar en el mapa
                        String claveAsignacion = productId + '_' + attrInfoId;
                        
                        CAT_AsignacionAt__c asignacion;
                          
                        if (asignacionesExistentesMap.containsKey(claveAsignacion)) {
                            // UPDATE - asignación existente
                            asignacion = asignacionesExistentesMap.get(claveAsignacion);
                        } else {
                            // INSERT - nueva asignación
                            asignacion = new CAT_AsignacionAt__c();
                            asignacion.CAT_Atributo_Informativo__c = attrInfoId;
                            asignacion.CAT_Producto__c = productId;
                        }
                        
                        // Solo actualizar si el valor cambió
                        if (asignacion.CAT_Valor__c != value) {
                            asignacion.CAT_Valor__c = value;
                            asignacion.CAT_Solo_lectura__c = false;
                            asignacionesToUpsert.add(asignacion);
                        }
                    }
                }
            }
        }
        
        if (!asignacionesToUpsert.isEmpty()) {
            upsert asignacionesToUpsert;
        }

        
        System.debug('Registros de atributos Vlocity a actualizar: ' + updates.size() + 'Registros de asignaciones informativas a upsert: ' + asignacionesToUpsert.size());

        // Ejecutar actualizaciones de atributos Vlocity
        if (!updates.isEmpty()) { 
            try {
                System.debug('Actualizando ' + updates.size() + ' registros de atributos Vlocity...');
                update updates;
            } catch (Exception e) {
                System.debug('Error en actualización de atributos Vlocity: ' + e.getMessage());
            }
        } else {
            System.debug('No se encontraron atributos Vlocity para actualizar');
        }
    }
    
    // Método auxiliar para parsear líneas CSV correctamente
    private List<String> parseCsvLine(String line) {
        List<String> result = new List<String>();
        String currentField = '';
        Boolean inQuotes = false;
        
        for (Integer i = 0; i < line.length(); i++) {
            String currentChar = line.substring(i, i + 1);
            
            if (currentChar == '"') {
                inQuotes = !inQuotes;
            } else if (currentChar == ',' && !inQuotes) {
                result.add(currentField);
                currentField = '';
            } else {
                currentField += currentChar;
            }
        }
        
        // Añadir el último campo
        result.add(currentField);
        
        return result;
    }

    // Método para extraer código de atributo del nombre    
    private String extractAttrCodeFromName(String name) {
        if (String.isBlank(name)) return '';
        
        // Buscar 'B2C-ATTR' en el nombre
        Integer b2cIndex = name.indexOf('B2C-ATTR');
        if (b2cIndex == -1) {
            return '';
        }
        
        // Extraer desde B2C-ATTR hasta antes del último _ (si existe)
        String fromB2c = name.substring(b2cIndex);
        
        // Si hay otro _ después de B2C-ATTR, cortar 
        Integer underscoreAfterB2c = fromB2c.indexOf('_', 'B2C-ATTR'.length());
        if (underscoreAfterB2c != -1) {
            // Cortar antes del _ que tiene el número
            String result = fromB2c.substring(0, underscoreAfterB2c);
            return result;
        }
        
        return fromB2c;
    }

    // Método para normalizar todos los tipos de espacios
    private String normalizeSpaces(String input) {
        if (String.isBlank(input)) return input;
        
        // Reemplazar todos los tipos de espacios por espacio normal
        String normalized = input;
        
        // Espacio no-breaking (char 160)
        normalized = normalized.replace('\u00A0', ' ');
        
        // Espacio de ancho cero (char 8203)
        normalized = normalized.replace('\u200B', ' ');
        
        // Espacio delgado (char 8201)
        normalized = normalized.replace('\u2009', ' ');
        
        // Espacio de no-joiner (char 8204)
        normalized = normalized.replace('\u200C', ' ');
        
        // Espacio de joiner (char 8205)
        normalized = normalized.replace('\u200D', ' ');
        
        // Espacio de figura (char 8199)
        normalized = normalized.replace('\u2007', ' ');
        
        // Espacio de puntuación (char 8198)
        normalized = normalized.replace('\u2006', ' ');
        
        // Espacio de 1/4 de em (char 8195)
        normalized = normalized.replace('\u2003', ' ');
        
        // Espacio de 1/3 de em (char 8194)
        normalized = normalized.replace('\u2002', ' ');
        
        // Espacio en (char 8193)
        normalized = normalized.replace('\u2001', ' ');
        
        // Espacio em (char 8192)
        normalized = normalized.replace('\u2000', ' ');
        
        // Espacio de 6 por em (char 8196)
        normalized = normalized.replace('\u2004', ' ');
        
        // Espacio de pelo (char 8197)
        normalized = normalized.replace('\u2005', ' ');
        
        // Eliminar múltiples espacios y trim
        normalized = normalized.replace('  ', ' ').replace('  ', ' ').trim();
        
        return normalized;
    }
}