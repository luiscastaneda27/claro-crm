/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class Controller for the LWC Cat Product Browser - General View (Tile List View) -Tech
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
26-Feb-25         Josue Pineda                                inicial version
30-Ene-26		  Hugo Revuelta								  Fix vulnerabilidades (uso variables bind)
----------------------------------------------------------------------------*/
public with sharing class CATTechProductBrowserController {
    // Static variable to hold the current time, accessible to all methods
    private static DateTime currentTime;

    // Static block to initialize the currentTime
    static {
        currentTime = DateTime.now();
    }
    //Method for getting all available Categories from Tech Products
    @AuraEnabled(cacheable=true)
    public static List<String> getCategories(String productType) {
        
        // Fetch products that meet the conditions
        List<Product2> products = [
            SELECT Id FROM Product2
            WHERE vlocity_cmt__SpecificationType__c = 'Offer'
            AND vlocity_cmt__Type__c = :productType
            AND vlocity_cmt__IsOrderable__c = true
            AND IsActive = true
            AND (vlocity_cmt__SellingStartDate__c <= :currentTime OR vlocity_cmt__SellingStartDate__c = null)
            AND (vlocity_cmt__SellingEndDate__c >= :currentTime OR vlocity_cmt__SellingEndDate__c = null)
            WITH USER_MODE
            ORDER BY CreatedDate DESC, Name ASC
        ];

        // Collect all product IDs
        Set<Id> productIds = new Set<Id>();
        for (Product2 prod : products) {
            productIds.add(prod.Id);
        }
        
        
        Set<String> uniqueCategories = new Set<String>();

        List<vlocity_cmt__AttributeAssignment__c> categoryRecords = [
            SELECT vlocity_cmt__Value__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-CAT-PROD'
            AND vlocity_cmt__ObjectId__c IN :productIds
            WITH USER_MODE 
        ];

        for (vlocity_cmt__AttributeAssignment__c cat : categoryRecords) {
            if (cat.vlocity_cmt__Value__c != null && cat.vlocity_cmt__Value__c.trim() != '') {
                uniqueCategories.add(cat.vlocity_cmt__Value__c.trim());
            }
        }

        List<String> sortedCategories = new List<String>(uniqueCategories);
        sortedCategories.sort();
        return sortedCategories;
    }

    //Method for getting all available SubCategories from Tech Products in function of the Selected Category
    @AuraEnabled(cacheable=true)
    public static List<String> getSubCategories(String selectedCategory, String productType) {
        // Step 1: Fetch vlocity_cmt__ObjectId__c values
        Set<String> objectIds = new Set<String>();
        for (vlocity_cmt__AttributeAssignment__c assignment : [
            SELECT vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-CAT-PROD'
            AND vlocity_cmt__Value__c = :selectedCategory
            WITH USER_MODE
        ]) {
            objectIds.add(assignment.vlocity_cmt__ObjectId__c);
        }

        // Step 2: Use these IDs to filter Product2 records
        List<Product2> products = [
            SELECT Id FROM Product2
            WHERE vlocity_cmt__SpecificationType__c = 'Offer'
            AND vlocity_cmt__Type__c = :productType
            AND vlocity_cmt__IsOrderable__c = true
            AND IsActive = true
            AND (vlocity_cmt__SellingStartDate__c <= :currentTime OR vlocity_cmt__SellingStartDate__c = null)
            AND (vlocity_cmt__SellingEndDate__c >= :currentTime OR vlocity_cmt__SellingEndDate__c = null)
            AND Id IN :objectIds
            WITH USER_MODE
            ORDER BY CreatedDate DESC, Name ASC
        ];

        // Collect all product IDs
        Set<Id> productIds = new Set<Id>();
        for (Product2 prod : products) {
            productIds.add(prod.Id);
        }

        List<vlocity_cmt__AttributeAssignment__c> subCategoryRecords = [
            SELECT vlocity_cmt__Value__c 
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-SUP-CAT-PROD'
            AND vlocity_cmt__ObjectId__c IN :productIds
            WITH USER_MODE
        ];

        Set<String> subCategories = new Set<String>();

        for (vlocity_cmt__AttributeAssignment__c sub : subCategoryRecords) {
            if (sub.vlocity_cmt__Value__c != null && sub.vlocity_cmt__Value__c.trim() != '') {
                subCategories.add(sub.vlocity_cmt__Value__c.trim());
            }
        }

        List<String> sortedSubCategories = new List<String>(subCategories);
        sortedSubCategories.sort();
        return sortedSubCategories;
    }

    //Method for fetching all TechProducts Depending on different scenarios
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getTechProducts(String productType, String productBrand, Integer latestReleasesDays, Integer bestSellersDays, String selectedPriceRange, Integer numProducts, String selectedCategory, String selectedSubCategory) {
        List<Product2> productsList = new List<Product2>();
        
        // Variables auxiliares para Bind en SOQL Dinámico
        Boolean isActiveTrue = true;

        system.debug('Product Type: ' + productType);
        system.debug('selectedCategory: ' + selectedCategory);
        system.debug('selectedSubCategory: ' + selectedSubCategory);
        system.debug('Product Brand: ' + productBrand);
        system.debug('latestReleasesDays: ' + latestReleasesDays);
        system.debug('bestSellersDays: ' + bestSellersDays);
        system.debug('selectedPriceRange: ' + selectedPriceRange);
        system.debug('numProducts: ' + numProducts);

        //Cuando se da Click a botón "Tecnología" Se Busca por productType -> Tech y se selecciona alguna categoría 
        if (productType == 'Tech' && selectedCategory != '' && productBrand == '' && latestReleasesDays == 0 &&  bestSellersDays == 0 && numProducts == 0 ) {
            system.debug('Executing Case 1');
            List<Id> productIds = new List<Id>();
            // Obtener los IDs de productos haciendo una consulta desde vlocity_cmt__AttributeAssignment__c
            //Parametros: attrName: 'Marca', 'Categoria', 'Subcategoria' attrValue
            productIds = getAttrAssgProductIds('Categoria', selectedCategory );
            if (selectedSubCategory != ''){
                productIds = getMergedProductIds(selectedCategory, selectedSubCategory,'' );
            }

            if (selectedPriceRange != '' && selectedPriceRange != null) {
                productsList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                return wrapProductData(productsList);
            }
            productsList = [
                SELECT Id,Name, Short_Description__c
                FROM Product2
                WHERE vlocity_cmt__SpecificationType__c = 'Offer' 
                AND vlocity_cmt__Type__c = :productType
                AND vlocity_cmt__IsOrderable__c = true 
                AND IsActive  = true
                AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                AND Id IN :productIds
                WITH USER_MODE
                ORDER BY CreatedDate DESC, Name ASC
            ];
            system.debug('productsList: ' + productsList);
        }

        //Click en Boton Tecnología, categoria Seleccionada y Botón Marca, 
        else if (productType == 'Tech' && selectedCategory != '' && productBrand != '' && latestReleasesDays == 0 &&  bestSellersDays == 0 && numProducts == 0) {
            System.debug('Executing Case 2');
            
            List<Id> productIds = new List<Id>();
            // Obtener los IDs de productos haciendo una consulta desde vlocity_cmt__AttributeAssignment__c
            //Parametros: attrName: 'Marca', 'Categoria', 'Subcategoria' attrValue
            if (selectedSubCategory != ''){
                System.debug('Ejecutando merge con SubCat');
                productIds = getMergedProductIds(selectedCategory, selectedSubCategory, productBrand );
            } else {
                System.debug('Ejecutando merge sin SubCat');
                productIds = getMergedProductIds(selectedCategory, '', productBrand );
            }

            List<Product2> productsPriceRangeList = new List<Product2>();
            // Verificar que la lista de IDs no esté vacía
            if (!productIds.isEmpty()) {
                if (selectedPriceRange != '' && selectedPriceRange != null) {
                    productsList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                    return wrapProductData(productsList);
                }
                // Consulta de productos filtrando por los IDs obtenidos
                productsList = [
                    SELECT Id, Name, Short_Description__c
                    FROM Product2
                    WHERE vlocity_cmt__SpecificationType__c = 'Offer'
                    AND vlocity_cmt__Type__c = :productType
                    AND Id IN :productIds
                    AND vlocity_cmt__IsOrderable__c = true 
                    AND IsActive  = true
                    AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                    AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC, Name ASC
                    ];
            }
        }
        //Cuando Se da Click a Botón Terminales y se busca por "Últimos Lanzamientos" y se selecciona alguna de las opciones de fecha
        else if (latestReleasesDays != 0 && selectedCategory != '') {
            System.debug('Executing Case 3');
            List<Product2> productsPriceRangeList = new List<Product2>();
            List<Id> productPriceRangeIds = new List<Id>();
            //Variable for storing all Products
            List<Id> productIds = new List<Id>();
            if (productBrand != '' && productType != '') {
                // Obtener los IDs de productos haciendo una consulta desde vlocity_cmt__AttributeAssignment__c
                //Parametros: attrName: 'Marca', 'Categoria', 'Subcategoria' attrValue
                if (selectedSubCategory != ''){
                    System.debug('Ejecutando merge con SubCat');
                    productIds = getMergedProductIds(selectedCategory, selectedSubCategory, productBrand );
                } else {
                    System.debug('Ejecutando merge sin SubCat');
                    productIds = getMergedProductIds(selectedCategory, '', productBrand );
                }
                // Verificar que la lista de IDs no esté vacía
                if (!productIds.isEmpty()) {
                    if (selectedPriceRange != '' && selectedPriceRange != null) {
                        productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                        // Extract the Product2Id values from the results
                        if (!productsPriceRangeList.isEmpty()) {
                            for (Product2 p : productsPriceRangeList) {
                                productPriceRangeIds.add(p.Id);
                            }
                        }
                        // Debug to verify the extracted IDs
                        System.debug(' Filtered Product IDs: ' + productPriceRangeIds);
                    }

                    // CORRECCIÓN LÍNEA 257 (Hallazgo Veracode): Uso de Bind Variables
                    String baseQuery = 'SELECT Id, Name, Short_Description__c ' +
                                       'FROM Product2 ' +
                                       'WHERE vlocity_cmt__SpecificationType__c = \'Offer\' ' +
                                       'AND vlocity_cmt__Type__c = :productType ';
                    
                    if (!productPriceRangeIds.isEmpty()) {
                        baseQuery += ' AND Id IN :productPriceRangeIds ';
                    } else{
                        baseQuery += ' AND Id IN :productIds ';
                    }
                    // Add the dynamic LAST_N_DAYS filter if latestReleasesDays > 0
                    if (latestReleasesDays > 0) {
                        baseQuery += ' AND CreatedDate = LAST_N_DAYS:' + latestReleasesDays + ' ';
                    }
                    baseQuery +=' AND vlocity_cmt__IsOrderable__c = :isActiveTrue ' +
                                ' AND IsActive  = :isActiveTrue ' + 
                                ' AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)' +
                                ' AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)' +
                                'WITH USER_MODE ORDER BY CreatedDate DESC, Name ASC';
                    
                    System.debug('SOQL Query: ' + baseQuery);
                    // Execute the dynamic SOQL query
                    productsList = Database.query(baseQuery);
                }
                return wrapProductData(productsList);
            }
            productIds = getAttrAssgProductIds('Categoria', selectedCategory );
            if (selectedSubCategory != ''){
                productIds = getMergedProductIds(selectedCategory, selectedSubCategory,'' );
            }
            // Build dynamic SOQL query
            String baseQuery = 'SELECT Id, Name, Short_Description__c ' +
                               'FROM Product2 ' +
                               'WHERE  vlocity_cmt__SpecificationType__c = \'Offer\' ' +
                               'AND vlocity_cmt__Type__c = :productType ';
            
            if (selectedPriceRange != '' && selectedPriceRange != null) {
                productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                // Extract the Product2Id values from the results
                if (!productsPriceRangeList.isEmpty()) {
                    for (Product2 p : productsPriceRangeList) {
                        productPriceRangeIds.add(p.Id);
                    }
                }
                // Debug to verify the extracted IDs
                System.debug(' Filtered Product IDs: ' + productPriceRangeIds);
                baseQuery += ' AND Id IN :productPriceRangeIds ';
            } else {
                // Debug to verify the extracted IDs
                System.debug(' Filtered Product IDs: ' + productIds);
                baseQuery += ' AND Id IN :productIds ';
            }
            // Add the dynamic LAST_N_DAYS filter if latestReleasesDays > 0
            if (latestReleasesDays > 0) {
                baseQuery += ' AND CreatedDate = LAST_N_DAYS:' + latestReleasesDays + ' ';
            }
        
            baseQuery +=' AND vlocity_cmt__IsOrderable__c = :isActiveTrue ' +
                        ' AND IsActive  = :isActiveTrue ' +
                        ' AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)' +
                        ' AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)' +
                        ' WITH USER_MODE ORDER BY CreatedDate DESC, Name ASC';
            System.debug('SOQL Query: ' + baseQuery);        
            // Execute the dynamic SOQL query
            productsList = Database.query(baseQuery);
            System.debug('productsList: ' + productsList);
        }
        //Cuando Se da Click a Botón Terminales y se busca por "Más Vendidos" y se selecciona alguna de las opciones de fecha
        else if (latestReleasesDays == 0 && selectedCategory != '' && (bestSellersDays != 0 || numProducts != 0)) {
            System.debug('Executing Case 4');
            List<Id> productPriceRangeIds = new List<Id>();
            List<Product2> productsPriceRangeList = new List<Product2>();
            //Variable for storing all products
            List<Id> productIds = new List<Id>();
            if (productBrand != '' && productType != '') {
                // Obtener los IDs de productos haciendo una consulta desde vlocity_cmt__AttributeAssignment__c
                //Parametros: attrName: 'Marca', 'Categoria', 'Subcategoria' attrValue
                if (selectedSubCategory != ''){
                    System.debug('Ejecutando merge con SubCat');
                    productIds = getMergedProductIds(selectedCategory, selectedSubCategory, productBrand );
                } else {
                    System.debug('Ejecutando merge sin SubCat');
                    productIds = getMergedProductIds(selectedCategory, '', productBrand );
                }
                // Verificar que la lista de IDs no esté vacía
                if (!productIds.isEmpty()) {
                    if (selectedPriceRange != '' && selectedPriceRange != null) {
                        productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                        // Extract the Product2Id values from the results
                        if (!productsPriceRangeList.isEmpty()) {
                            for (Product2 p : productsPriceRangeList) {
                                productPriceRangeIds.add(p.Id);
                            }
                        }
                        // Debug to verify the extracted IDs
                        System.debug(' Filtered Product IDs: ' + productPriceRangeIds);
                    }
                }
                // CORRECCIÓN LÍNEA 301 (Hallazgo Veracode): Uso de Bind Variables en Asset query
                String baseQuery = 'SELECT COUNT(Id), Product2Id, Product2.Name ' +
                                    'FROM Asset ' +
                                    'WHERE Product2.vlocity_cmt__SpecificationType__c = \'Offer\' ' +
                                    'AND Product2.vlocity_cmt__Type__c = :productType ';
                
                if (selectedPriceRange != '' && selectedPriceRange != null) {
                    baseQuery += ' AND Product2Id IN :productPriceRangeIds ';
                } else{
                    baseQuery += ' AND Product2Id IN :productIds ';
                }
            
                // Add LAST_N_DAYS filter
                baseQuery += (bestSellersDays > 0) ? ' AND CreatedDate = LAST_N_DAYS:' + bestSellersDays + ' ' : ' AND CreatedDate = LAST_N_DAYS:7';
                
                // Group by and order clause - CORRECCIÓN LÍNEA 361 (Hallazgo Veracode): Bind para LIMIT
                Integer limitRows = (numProducts != 0 ? numProducts : 10);
                baseQuery += ' WITH USER_MODE GROUP BY Product2.Name, Product2Id ' +
                             'ORDER BY COUNT(Id) DESC LIMIT :limitRows';
            
                System.debug('SOQL Query: ' + baseQuery);
            
                // Execute the query
                List<AggregateResult> assetsList = Database.query(baseQuery);
            
                // Extract Product2Id and maintain order based on asset count
                List<Id> assetProductIds = new List<Id>();
                for (AggregateResult ar : assetsList) {
                    Id productId = (Id) ar.get('Product2Id');
                    assetProductIds.add(productId);
                }
            
                // Fetch matching products
                List<Product2> sortedProductsList = new List<Product2>();
                if (!assetProductIds.isEmpty()) {
                    sortedProductsList = [
                        SELECT Id, Name, Short_Description__c
                        FROM Product2
                        WHERE vlocity_cmt__SpecificationType__c = 'Offer'
                            AND vlocity_cmt__Type__c = :productType
                            AND Id IN :assetProductIds
                            AND vlocity_cmt__IsOrderable__c = true 
                            AND IsActive  = true
                            AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                            AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                            WITH USER_MODE
                            ORDER BY CreatedDate DESC, Name ASC                    
                        ];
                }
            
                // Sort products based on asset order
                for (Id productId : assetProductIds) {
                    for (Product2 p : sortedProductsList) {
                        if (p.Id == productId) {
                            productsList.add(p);
                            break;
                        }
                    }
                }
            
                System.debug('Final Ordered Products List: ' + productsList);
                return wrapProductData(productsList);
            }
            productIds = getAttrAssgProductIds('Categoria', selectedCategory );
            if (selectedSubCategory != ''){
                productIds = getMergedProductIds(selectedCategory, selectedSubCategory,'' );
            }
            //Analisis por precio
            String baseQuery = 'SELECT COUNT(Id), Product2Id, Product2.Name ' +
                                'FROM Asset ' +
                                'WHERE Product2.vlocity_cmt__SpecificationType__c = \'Offer\' ' +
                                'AND Product2.vlocity_cmt__Type__c = :productType ';

            if (selectedPriceRange != '' && selectedPriceRange != null) {
                productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productIds);
                // Extract the Product2Id values from the results
                if (!productsPriceRangeList.isEmpty()) {
                    for (Product2 p : productsPriceRangeList) {
                        productPriceRangeIds.add(p.Id);
                    }
                }
                // Debug to verify the extracted IDs
                System.debug(' Filtered Product IDs: ' + productPriceRangeIds);
                baseQuery += ' AND Product2Id IN :productPriceRangeIds ';
            } else {
                // Debug to verify the extracted IDs
                System.debug(' Filtered Product IDs: ' + productIds);
                baseQuery += ' AND Product2Id IN :productIds ';
            }
            // Add LAST_N_DAYS filter
            baseQuery += (bestSellersDays > 0) ? ' AND CreatedDate = LAST_N_DAYS:' + bestSellersDays + ' ' : ' AND CreatedDate = LAST_N_DAYS:7';
            // Group by and order clause
            Integer limitRows = (numProducts != 0 ? numProducts : 10);
            baseQuery += ' WITH USER_MODE GROUP BY Product2.Name, Product2Id ' +
                         'ORDER BY COUNT(Id) DESC LIMIT :limitRows';
            System.debug('SOQL Query: ' + baseQuery);
            // Execute the query
            List<AggregateResult> assetsList = Database.query(baseQuery);
            // Extract Product2Id and maintain order based on asset count
            List<Id> assetProductIds = new List<Id>();
            for (AggregateResult ar : assetsList) {
                Id productId = (Id) ar.get('Product2Id');
                assetProductIds.add(productId);
            }
        
            // Fetch matching products
            List<Product2> sortedProductsList = new List<Product2>();
            if (!assetProductIds.isEmpty()) {
                sortedProductsList = [
                    SELECT Id, Name, Short_Description__c
                    FROM Product2
                    WHERE vlocity_cmt__SpecificationType__c = 'Offer'
                        AND vlocity_cmt__Type__c = :productType
                        AND Id IN :assetProductIds
                        AND vlocity_cmt__IsOrderable__c = true 
                        AND IsActive  = true
                        AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                        AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                        WITH USER_MODE
                        ORDER BY CreatedDate DESC, Name ASC
                ];
            }
        
            // Sort products based on asset order
            for (Id productId : assetProductIds) {
                for (Product2 p : sortedProductsList) {
                    if (p.Id == productId) {
                        productsList.add(p);
                        break;
                    }
                }
            }
            System.debug('Final Ordered Products List: ' + productsList);
        }
        return wrapProductData(productsList);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getBrandsURl( String selectedCategory, String selectedSubCategory, String productType) {

        // Fetch products that meet the conditions
        List<Product2> products = [
            SELECT Id FROM Product2
            WHERE vlocity_cmt__SpecificationType__c = 'Offer'
            AND vlocity_cmt__Type__c = :productType
            AND vlocity_cmt__IsOrderable__c = true
            AND IsActive = true
            AND (vlocity_cmt__SellingStartDate__c <= :currentTime OR vlocity_cmt__SellingStartDate__c = null)
            AND (vlocity_cmt__SellingEndDate__c >= :currentTime OR vlocity_cmt__SellingEndDate__c = null)
            WITH USER_MODE
            ORDER BY CreatedDate DESC, Name ASC
        ];

        // Collect all product IDs
        Set<Id> productIds = new Set<Id>();
        for (Product2 prod : products) {
            productIds.add(prod.Id);
        }

        // Filter by category
        List<vlocity_cmt__AttributeAssignment__c> categoryRecords = [
            SELECT vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-CAT-PROD'
            AND vlocity_cmt__Value__c  = :selectedCategory
            AND vlocity_cmt__ObjectId__c IN :productIds
            WITH USER_MODE 
        ];

        // Collect all Category product IDs
        Set<Id> categoryProductIds = new Set<Id>();
        for (vlocity_cmt__AttributeAssignment__c catRec : categoryRecords) {
            categoryProductIds.add(catRec.vlocity_cmt__ObjectId__c);
        }

        // Collect the Final ProductIds
        Set<Id> selectedProductIds = new Set<Id>();

        // Optionally filter by subcategory if it is not empty
        if (selectedSubCategory != '') {
            List<vlocity_cmt__AttributeAssignment__c> subCategoryRecords = [
                SELECT vlocity_cmt__ObjectId__c
                FROM vlocity_cmt__AttributeAssignment__c
                WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-SUP-CAT-PROD'
                AND vlocity_cmt__Value__c  = :selectedSubCategory
                AND vlocity_cmt__ObjectId__c IN :categoryProductIds
                WITH USER_MODE 
            ];
            
            Set<Id> finalProductIds = new Set<Id>();
            for (vlocity_cmt__AttributeAssignment__c subCatRec : subCategoryRecords) {
                finalProductIds.add(subCatRec.vlocity_cmt__ObjectId__c);
            }
            selectedProductIds = finalProductIds; // Update the productIds with those filtered by subcategory
        } else {
            selectedProductIds = categoryProductIds; // Use category filtered IDs if no subcategory is provided
        }

        Map<String, String> brandMap = new Map<String, String>(); 
        Map<String, String> urlMap = new Map<String, String>();
        
        // Query to get brands
        for (AggregateResult ar : [
            SELECT vlocity_cmt__Value__c Brand, vlocity_cmt__ObjectId__c ProductId
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-TEC-MARCA'
            AND  vlocity_cmt__ObjectId__c IN :selectedProductIds
            WITH USER_MODE
            GROUP BY vlocity_cmt__Value__c, vlocity_cmt__ObjectId__c
        ]) {
            String brand = (String) ar.get('Brand');
            String productId = (String) ar.get('ProductId');
            if (brand != null && productId != null) {
                brandMap.put(productId, brand);
            }
        }
    
        // Query to get URLs
        for (AggregateResult ar : [
            SELECT vlocity_cmt__Value__c URL, vlocity_cmt__ObjectId__c ProductId
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-MARCA-URL'
            AND  vlocity_cmt__ObjectId__c IN :selectedProductIds
            WITH USER_MODE
            GROUP BY vlocity_cmt__Value__c, vlocity_cmt__ObjectId__c
        ]) {
            String url = (String) ar.get('URL');
            String productId = (String) ar.get('ProductId');
            if (url != null && productId != null) {
                urlMap.put(productId, url);
            }
        }
    
        // Create a map of brands and URLs to avoid duplicates
        Map<String, String> brandsURLMap = new Map<String, String>();
    
        for (String productId : brandMap.keySet()) {
            String brandName = brandMap.get(productId);
            String brandURL = urlMap.get(productId);
    
            if (!brandsURLMap.containsKey(brandName) || (brandURL != null)) {
                brandsURLMap.put(brandName, brandURL);
            }
        }
    
        // **Sort brands alphabetically**
        List<String> sortedBrandNames = new List<String>(brandsURLMap.keySet());
        sortedBrandNames.sort(); // Sorting alphabetically
    
        // Convert sorted brands back into List<Map<String, String>>
        List<Map<String, String>> brandList = new List<Map<String, String>>();
        for (String brandName : sortedBrandNames) {
            brandList.add(new Map<String, String>{'brand' => brandName, 'url' => brandsURLMap.get(brandName)});
        }
    
        System.debug('Sorted brandList: ' + JSON.serialize(brandList));
        return brandList;
    }
    

    // Get Products by Selected Price Range
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsByPriceRange(String selectedPriceRange, String productType, List<Id> productIds) {

        // Split the string by '-'
        List<String> priceRangeParts = selectedPriceRange.split('-');
        
        Decimal minPrice;
        Decimal maxPrice;
        //Busqueda de precios sin impuestos

        Decimal minPriceOriginal = Decimal.valueOf(priceRangeParts[0].trim());
        Decimal maxPriceOriginal = Decimal.valueOf(priceRangeParts[1].trim());

        //Getting UVT records from Org
        List<FVU_UVT_info__c> uVT = [
            SELECT Id, Name, FVU_Valor_UVT__c, FVU_UVT_Fecha_Inicial_Vigencia__c, FVU_UVT_Fecha_Final_Vigencia__c 
            FROM FVU_UVT_info__c 
            WHERE FVU_UVT_Fecha_Inicial_Vigencia__c < :currentTime 
            AND FVU_UVT_Fecha_Final_Vigencia__c > :currentTime 
            WITH USER_MODE 
            LIMIT 1];
        
        Decimal uvtLimit = 22;
        Decimal uvtPrice = (Decimal) uVT[0].FVU_Valor_UVT__c;
        //Analisis de Rango por limite de UVT
        if (minPriceOriginal <= (uvtPrice * uvtLimit)){
            minPrice = minPriceOriginal;
        } else{
            // Convert the first price of the string into a decimal
            minPrice = (Decimal.valueOf(priceRangeParts[0].trim())) - (Decimal.valueOf(priceRangeParts[0].trim()) * 0.19);
        }
        if (maxPriceOriginal <= (uvtPrice * uvtLimit)){
            maxPrice = maxPriceOriginal;
        } else{
            // Convert the second price of the string into a decimal
            maxPrice = (Decimal.valueOf(priceRangeParts[1].trim())) - (Decimal.valueOf(priceRangeParts[1].trim()) * 0.19);
        }
        
        // Debug the values
        System.debug('Min Price: ' + minPrice);
        System.debug('Max Price: ' + maxPrice);

        System.debug('Filtering products for price range: ' + selectedPriceRange + ' (' + minPrice + ' - ' + maxPrice + ')');

        // Variable Bind para booleanos
        Boolean isActiveTrue = true;

        // CORRECCIÓN LÍNEA 437 (Hallazgo Veracode): Uso de Bind Variables en toda la consulta
        String baseQuery = 'SELECT Id, Name, Short_Description__c FROM Product2 WHERE Id IN (SELECT vlocity_cmt__ProductId__c FROM vlocity_cmt__PriceListEntry__c ' +
        ' WHERE vlocity_cmt__PricingElementAmount__c >= :minPrice ' +
        ' AND vlocity_cmt__PricingElementAmount__c <= :maxPrice ' +
        ' AND vlocity_cmt__IsActive__c = :isActiveTrue ' +
        ' AND vlocity_cmt__EffectiveUntilDate__c = null ' +
        ' AND vlocity_cmt__PromotionId__c = null '+
        ' AND vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c = \'PL-B2C\' ' +
        ' AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null )' +
        ' AND vlocity_cmt__SpecificationType__c = \'Offer\' ' +
        ' AND vlocity_cmt__Type__c = :productType ' +
        ' AND vlocity_cmt__IsOrderable__c = :isActiveTrue ' +
        ' AND IsActive  = :isActiveTrue ' + 
        ' AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)' +
        ' AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)';
        
        // Handle case where productIds is provided
        if (productIds != null && !productIds.isEmpty()) {
            baseQuery += ' AND Id IN :productIds ';
        }
        baseQuery += ' WITH USER_MODE ORDER BY CreatedDate DESC, Name ASC';
        System.debug('Final SOQL Query: ' + baseQuery);
        List<Product2> filteredProducts = Database.query(baseQuery);
        return filteredProducts;
    }

    // Fetch Attribute Assignment IDs
    private static List<Id> getAttrAssgProductIds(String attrName, String attrValue) {
        List<Id> attrProductIdsList = new List<Id>();
        String attrCode;
        if (attrName == 'Marca') {
            attrCode = 'B2C-ATTR-TEC-MARCA';
        } else if (attrName == 'Categoria') {
            attrCode = 'B2C-ATTR-TEC-CAT-PROD';
        } else if (attrName == 'Subcategoria') {
            attrCode = 'B2C-ATTR-TEC-SUP-CAT-PROD';
        }
        
        List<vlocity_cmt__AttributeAssignment__c> attrProductsList = [
            SELECT vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = :attrCode
            AND vlocity_cmt__Value__c = :attrValue
            WITH USER_MODE
            ORDER BY Name
        ];

        // Extract IDs from the query result
        for (vlocity_cmt__AttributeAssignment__c assignment : attrProductsList) {
            attrProductIdsList.add(assignment.vlocity_cmt__ObjectId__c);
        }

        System.debug('Fetched Attr Product IDs: ' + attrProductIdsList);
        return attrProductIdsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getMergedProductIds(String selectedCategory, String selectedSubCategory, String productBrand) {
        System.debug('Ejecutando metodo merge');
        Set<Id> mergedProductIds = new Set<Id>();

        // Retrieve Product IDs for Category if provided
        // Is a Best Practice to use isEmpty for a String comparison as it checks for null and '' both as well
        if (!String.isEmpty(selectedCategory)) {
            List<Id> categoryProductIds = getAttrAssgProductIds('Categoria', selectedCategory);
            System.debug('categoryProductIds' + categoryProductIds);
            mergedProductIds.addAll(categoryProductIds);
            System.debug('mergedProductIds for Category' + mergedProductIds);
        }

        // Retrieve Product IDs for Subcategory if provided
        if (!String.isEmpty(selectedSubCategory)) {
            List<Id> subCategoryProductIds = getAttrAssgProductIds('Subcategoria',selectedSubCategory);
            mergedProductIds.retainAll(subCategoryProductIds);
            System.debug('mergedProductIds for SubCategory' + mergedProductIds);
        }

        // Retrieve Product IDs for Product Brand if provided
        if (!String.isEmpty(productBrand)) {
            List<Id> brandProductIds = getAttrAssgProductIds('Marca',productBrand);
            mergedProductIds.retainAll(brandProductIds);
            System.debug('mergedProductIds for Marca' + mergedProductIds);
        }
        System.debug('Final Merged Product IDs: ' + mergedProductIds);
        
        return new List<Id>(mergedProductIds);
    }

    // Method to get product images
    @AuraEnabled(cacheable=true)
    public static Map<Id, String> getProductImages(List<Id> products) {
        List<vlocity_cmt__VlocityAttachment__c> attachments = [
            SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__UrlLong__c
            FROM vlocity_cmt__VlocityAttachment__c
            WHERE vlocity_cmt__ObjectId__c IN :products 
            AND vlocity_cmt__IsDefaultImage__c = true
            WITH USER_MODE
        ];

        // Convert List to Map
        Map<Id, String> productImageMap = new Map<Id, String>();
        for (vlocity_cmt__VlocityAttachment__c productImage : attachments) {
            if (!productImageMap.containsKey(productImage.vlocity_cmt__ObjectId__c)) {
                productImageMap.put(productImage.vlocity_cmt__ObjectId__c, productImage.vlocity_cmt__UrlLong__c);
            }
        }
        return productImageMap;
    }
    
    // Method to get product prices
    @AuraEnabled(cacheable=true)
    public static Map<Id, String> getProductPrices(List<Id> products) {
        List<vlocity_cmt__PriceListEntry__c> pricedProducts = [
            SELECT vlocity_cmt__ProductId__c, vlocity_cmt__DisplayText__c FROM vlocity_cmt__PriceListEntry__c 
            WHERE vlocity_cmt__ProductId__c IN: products 
            AND vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__EffectiveUntilDate__c = null 
            AND vlocity_cmt__PromotionId__c = null
            AND vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c  = 'PL-B2C'
            AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            WITH USER_MODE
        ];
        // Convert List to Map
        Map<Id, String> productPriceMap = new Map<Id, String>();
        for (vlocity_cmt__PriceListEntry__c priceEntry : pricedProducts) {
            productPriceMap.put(priceEntry.vlocity_cmt__ProductId__c, priceEntry.vlocity_cmt__DisplayText__c);
        }
        return productPriceMap;
    }
    
    // Method to wrap everything needed from Product2
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> wrapProductData(List<Product2> productsList) {
        List<ProductWrapper> productWrappers = new List<ProductWrapper>();
        //Convert List from Products to List of IDs
        List<Id> productIds = new List <Id> ();
        for (Product2 p : productsList) {
            productIds.add(p.Id);
        }
        
        // Fetch image URLs and prices
        Map<Id, String> productImageMap = getProductImages(productIds);
        Map<Id, String> productPriceMap = getProductPrices(productIds);
        
        System.debug('productImageMap: ' + JSON.serialize(productImageMap)); // Debugging to verify the output
        System.debug('productPriceMap: ' + JSON.serialize(productPriceMap)); // Debugging to verify the output
        for (Product2 product : productsList) {
            ProductWrapper wrapper = new ProductWrapper();
            wrapper.Id = product.Id;
            wrapper.Name = product.Name;
            wrapper.Description = product.Short_Description__c;
            wrapper.ImageUrl = productImageMap.get(product.Id);
            wrapper.Price = productPriceMap.get(product.Id);
            productWrappers.add(wrapper);
        }
        System.debug('productWrappers: ' + JSON.serialize(productWrappers)); // Debugging to verify the output
        return productWrappers;
    }

    // Wrapper class to return enriched product data
    public class ProductWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Description;
        @AuraEnabled public String ImageUrl;
        @AuraEnabled public String Price;
    }
}