/*--------------------------------------------------------------------------
Author:           Josue Pineda - josue.pineda@salesforce.com
Company:          Salesforce.com
Description:      Class Controller for the LWC Cat Product Browser - General View (Tile List View)
Code Coverage:    100%
History
<Date>            <Author>              <Description>              <Version>
21-Feb-25         Josue Pineda          initial version
11-Sep-25		Hugo Revuelta			Fix SQL Injection
----------------------------------------------------------------------------*/
public with sharing class CATProductListController {
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProducts(String productType, String searchCriteria, String productBrand, Integer latestReleasesDays, Integer bestSellersDays, String selectedPriceRange, Integer numProducts) {
        List<Product2> productsList = new List<Product2>();
        system.debug('Product Type: ' + productType);
        system.debug('Search Criteria: ' + searchCriteria);
        system.debug('Product Brand: ' + productBrand);
        String searchValue = '%' + searchCriteria.trim() + '%';
        system.debug('searchValue: ' + searchValue);
        system.debug('latestReleasesDays: ' + latestReleasesDays);
        system.debug('bestSellersDays: ' + bestSellersDays);
        system.debug('selectedPriceRange: ' + selectedPriceRange);
        system.debug('numProducts: ' + numProducts);
        //Declare System Time to be used for dates in fields
        Datetime currentTime = System.now();
        system.debug('currentTime: ' + currentTime);

        //Cuando es por busqueda global PRODUCT TYPE vacio, Search value lleno, todo lo demás vacio solo lleno Search value
        if(productType == '' && searchCriteria != ''){
            productsList = [
                SELECT Id,Name, Short_Description__c
                FROM Product2
                WHERE (Name LIKE :searchValue OR Description LIKE :searchValue) 
                AND vlocity_cmt__SpecificationType__c = 'Offer'
                AND vlocity_cmt__IsOrderable__c = true 
                AND IsActive  = true 
                AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                WITH USER_MODE
                ORDER BY CreatedDate DESC, Name ASC
            ];
        } 
        //Cuando se da Click a botón "Terminales" Se Busca por productType -> Handset, 
        else if (productType != '' && (searchCriteria == null || searchCriteria == '') && (productBrand == '' || productBrand == null) && latestReleasesDays == 0 &&  bestSellersDays == 0 && numProducts == 0) {
            if (selectedPriceRange != '' && selectedPriceRange != null) {
                productsList = getProductsByPriceRange(selectedPriceRange, productType, null);
                return wrapProductData(productsList);
            }
            productsList = [
                SELECT Id,Name, Short_Description__c
                FROM Product2
                WHERE (Name LIKE :searchValue OR Description LIKE :searchValue) 
                AND vlocity_cmt__SpecificationType__c = 'Offer' 
                AND vlocity_cmt__Type__c = :productType
                AND vlocity_cmt__IsOrderable__c = true 
                AND IsActive  = true
                AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                WITH USER_MODE
                ORDER BY CreatedDate DESC, Name ASC
            ];
            system.debug('productsList: ' + productsList);
        }
        //Click en Boton Terminales y Botón Marca, 
        else if ((productType != null && productType != '') && (productBrand != null && productBrand != '') && latestReleasesDays == 0 &&  bestSellersDays == 0 && numProducts == 0) {
            // Obtener los IDs desde vlocity_cmt__AttributeAssignment__c
            List<Id> productMarcaIds = getProductMarcaIds(productBrand);
            List<Product2> productsPriceRangeList = new List<Product2>();
            // Verificar que la lista de IDs no esté vacía
            if (!productMarcaIds.isEmpty()) {
                if (selectedPriceRange != '' && selectedPriceRange != null) {
                    productsList = getProductsByPriceRange(selectedPriceRange, productType, productMarcaIds);
                    return wrapProductData(productsList);
                }
                // Consulta de productos filtrando por los IDs obtenidos
                productsList = [
                    SELECT Id, Name, Short_Description__c
                    FROM Product2
                    WHERE (Name LIKE :searchValue OR Description LIKE :searchValue)
                        AND vlocity_cmt__SpecificationType__c = 'Offer'
                        AND vlocity_cmt__Type__c = :productType
                        AND Id IN :productMarcaIds
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
        else if (latestReleasesDays != 0) {
            List<Product2> productsPriceRangeList = new List<Product2>();
            List<Id> productPriceRangeIds = new List<Id>();

            if (productBrand != '' && productType != '') {
                List<Id> productMarcaIds = getProductMarcaIds(productBrand);
                if (!productMarcaIds.isEmpty()) {
                    if (selectedPriceRange != '' && selectedPriceRange != null) {
                        productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productMarcaIds);
                        if (!productsPriceRangeList.isEmpty()) {
                            productPriceRangeIds = new List<Id>(); // Reiniciar
                            for (Product2 p : productsPriceRangeList) {
                                productPriceRangeIds.add(p.Id);
                            }
                        }
                    }
                    
                    String query = 'SELECT Id, Name, Short_Description__c FROM Product2 WHERE vlocity_cmt__SpecificationType__c = \'Offer\' AND vlocity_cmt__Type__c = :productType AND CreatedDate = LAST_N_DAYS:' + latestReleasesDays;
                    if (!productPriceRangeIds.isEmpty()) {
                         query += ' AND Id IN :productPriceRangeIds';
                    } else if (!productMarcaIds.isEmpty()){
                         query += ' AND Id IN :productMarcaIds';
                    }
                    query += ' AND vlocity_cmt__IsOrderable__c = true AND IsActive = true AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null) AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null) WITH USER_MODE ORDER BY CreatedDate DESC, Name ASC';
                    
                    productsList = Database.query(query);
                }
            } else {
                if (selectedPriceRange != '' && selectedPriceRange != null) {
                    productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, null);
                    if (!productsPriceRangeList.isEmpty()) {
                        productPriceRangeIds = new List<Id>(); // Reiniciar
                        for (Product2 p : productsPriceRangeList) {
                            productPriceRangeIds.add(p.Id);
                        }
                    }
                }
                
                String query = 'SELECT Id, Name, Short_Description__c FROM Product2 WHERE vlocity_cmt__SpecificationType__c = \'Offer\' AND vlocity_cmt__Type__c = :productType AND CreatedDate = LAST_N_DAYS:' + latestReleasesDays;
                if (!productPriceRangeIds.isEmpty()) {
                    query += ' AND Id IN :productPriceRangeIds';
                }
                query += ' AND vlocity_cmt__IsOrderable__c = true AND IsActive = true AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null) AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null) WITH USER_MODE ORDER BY CreatedDate DESC, Name ASC';
                
                productsList = Database.query(query);
            }
            return wrapProductData(productsList);
        }
        //Cuando Se da Click a Botón Terminales y se busca por "Más Vendidos" y se selecciona alguna de las opciones de fecha
        else if ((searchCriteria == null || searchCriteria == '') && latestReleasesDays == 0 && (bestSellersDays != 0 || numProducts != 0)) {
            List<Id> productPriceRangeIds = new List<Id>();
            List<Product2> productsPriceRangeList = new List<Product2>();
            if (productBrand != '' && productType != '') {
                List<Id> productMarcaIds = getProductMarcaIds(productBrand);
                if (!productMarcaIds.isEmpty()) {
                    if (selectedPriceRange != '' && selectedPriceRange != null) {
                        productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, productMarcaIds);
                        if (!productsPriceRangeList.isEmpty()) {
                            productPriceRangeIds = new List<Id>(); // Reiniciar
                            for (Product2 p : productsPriceRangeList) {
                                productPriceRangeIds.add(p.Id);
                            }
                        }
                    }
                }
                
                String query = 'SELECT COUNT(Id), Product2Id, Product2.Name FROM Asset WHERE Product2.vlocity_cmt__SpecificationType__c = \'Offer\' AND Product2.vlocity_cmt__Type__c = :productType';
                
                if (!productPriceRangeIds.isEmpty()) {
                     query += ' AND Product2Id IN :productPriceRangeIds';
                } else if (!productMarcaIds.isEmpty()) {
                     query += ' AND Product2Id IN :productMarcaIds';
                }
                
                query += (bestSellersDays > 0) ? ' AND CreatedDate = LAST_N_DAYS:' + bestSellersDays : ' AND CreatedDate = LAST_N_DAYS:7';
                query += ' WITH USER_MODE GROUP BY Product2.Name, Product2Id ORDER BY COUNT(Id) DESC LIMIT ' + (numProducts != 0 ? numProducts : 10);
                
                List<AggregateResult> assetsList = Database.query(query);

                List<Id> productIds = new List<Id>();
                for (AggregateResult ar : assetsList) {
                    Id productId = (Id) ar.get('Product2Id');
                    productIds.add(productId);
                }

                List<Product2> sortedProductsList = new List<Product2>();
                if (!productIds.isEmpty()) {
                    sortedProductsList = [
                        SELECT Id, Name, Short_Description__c
                        FROM Product2
                        WHERE vlocity_cmt__SpecificationType__c = 'Offer'
                            AND vlocity_cmt__Type__c = :productType
                            AND Id IN :productIds
                            AND vlocity_cmt__IsOrderable__c = true 
                            AND IsActive = true
                            AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
                            AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
                            WITH USER_MODE
                            ORDER BY CreatedDate DESC, Name ASC          
                        ];
                }

                for (Id productId : productIds) {
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
            
            //Analisis por precio
            if (selectedPriceRange != '' && selectedPriceRange != null) {
                productsPriceRangeList = getProductsByPriceRange(selectedPriceRange, productType, null);
                if (!productsPriceRangeList.isEmpty()) {
                    productPriceRangeIds = new List<Id>(); // Reiniciar
                    for (Product2 p : productsPriceRangeList) {
                        productPriceRangeIds.add(p.Id);
                    }
                }
            }
            
            String query = 'SELECT COUNT(Id), Product2Id, Product2.Name FROM Asset WHERE Product2.vlocity_cmt__SpecificationType__c = \'Offer\' AND Product2.vlocity_cmt__Type__c = :productType';
            if (!productPriceRangeIds.isEmpty()) {
                 query += ' AND Product2Id IN :productPriceRangeIds';
            }

            query += (bestSellersDays > 0) ? ' AND CreatedDate = LAST_N_DAYS:' + bestSellersDays : ' AND CreatedDate = LAST_N_DAYS:7';
            query += ' WITH USER_MODE GROUP BY Product2.Name, Product2Id ORDER BY COUNT(Id) DESC LIMIT ' + (numProducts != 0 ? numProducts : 10);

            List<AggregateResult> assetsList = Database.query(query);

            List<Id> productIds = new List<Id>();
            for (AggregateResult ar : assetsList) {
                Id productId = (Id) ar.get('Product2Id');
                productIds.add(productId);
            }

            List<Product2> sortedProductsList = new List<Product2>();
            if (!productIds.isEmpty()) {
                sortedProductsList = [
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

            for (Id productId : productIds) {
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

    // Get Brands with URLs
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getBrandsURl() {
        Map<String, String> brandMap = new Map<String, String>(); 
        Map<String, String> urlMap = new Map<String, String>();
    
        // Query to get brands
        for (AggregateResult ar : [
            SELECT vlocity_cmt__Value__c Brand, vlocity_cmt__ObjectId__c ProductId
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-MARCA-TERM'
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

        Decimal minPriceOriginal = Decimal.valueOf(priceRangeParts[0].trim());
        Decimal maxPriceOriginal = Decimal.valueOf(priceRangeParts[1].trim());
        System.debug('minPriceOriginal: ' + minPriceOriginal);
        System.debug('maxPriceOriginal: ' + maxPriceOriginal);

        //Getting UVT records from Org
        Datetime currentTime = Datetime.now();
        List<FVU_UVT_info__c> uvt = [
            SELECT Id, Name, FVU_Valor_UVT__c, FVU_UVT_Fecha_Inicial_Vigencia__c, FVU_UVT_Fecha_Final_Vigencia__c 
            FROM FVU_UVT_info__c 
            WHERE FVU_UVT_Fecha_Inicial_Vigencia__c < :currentTime 
            AND FVU_UVT_Fecha_Final_Vigencia__c > :currentTime 
            WITH USER_MODE 
            LIMIT 1
        ];

        Decimal uvtPrice = (Decimal) uvt[0].FVU_Valor_UVT__c;
        System.debug('uvtPrice: ' + uvtPrice);

        // Bring all the candidate products by type and status
        List<Product2> candidateProducts = [
            SELECT Id, Name, Short_Description__c FROM Product2 WHERE Id IN (
                SELECT vlocity_cmt__ProductId__c
                FROM vlocity_cmt__PriceListEntry__c
                WHERE vlocity_cmt__IsActive__c = true
                AND vlocity_cmt__EffectiveUntilDate__c = null
                AND vlocity_cmt__PromotionId__c = null
                AND vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c = 'PL-B2C'
                AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            )
            AND vlocity_cmt__SpecificationType__c = 'Offer'
            AND vlocity_cmt__Type__c = :productType
            AND vlocity_cmt__IsOrderable__c = true
            AND IsActive = true
            AND (vlocity_cmt__SellingStartDate__c <=: currentTime OR vlocity_cmt__SellingStartDate__c = null)
            AND (vlocity_cmt__SellingEndDate__c >=: currentTime OR vlocity_cmt__SellingEndDate__c = null)
            WITH USER_MODE
        ];

        if(productIds != null && !productIds.isEmpty()){
            List<Product2> productsToFilter = new List<Product2>();
            for(Product2 p : candidateProducts){
                if(productIds.contains(p.Id)){
                    productsToFilter.add(p);
                }
            }
            candidateProducts = productsToFilter;
        }

        System.debug('List of candidate products: ' + JSON.serialize(candidateProducts));

        if(candidateProducts.isEmpty()){
            return new List<Product2>();
        }

        // Obtain the UVT from each product
        Map<Id, Decimal> productUVTLimits = new Map<Id, Decimal>();

        List<Id> candidateIds = new List<Id>();
        for (Product2 product : candidateProducts) {
            candidateIds.add(product.Id);
        }
        System.debug('candidateIds: ' + candidateIds);

        List<vlocity_cmt__AttributeAssignment__c> attrAssignments = [
            SELECT vlocity_cmt__ObjectId__c, vlocity_cmt__Value__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-EXC-IMP-TERM'
            AND vlocity_cmt__ObjectId__c IN :candidateIds
            WITH USER_MODE
        ];
        System.debug('attrAssignments: ' + attrAssignments);

        for(vlocity_cmt__AttributeAssignment__c attr: attrAssignments){
            // If the attribute value is null, then we consider it as value 0
            Decimal limitProdUVT;
            if(attr.vlocity_cmt__Value__c == null){
                limitProdUVT = 0;
            } else{
                limitProdUVT = Decimal.valueOf(attr.vlocity_cmt__Value__c);
            }
            productUVTLimits.put(attr.vlocity_cmt__ObjectId__c, limitProdUVT);
        }
        System.debug('productUVTLimits: ' + productUVTLimits);

        // Bring every price in just one query to avoid loops
        Map<Id, Decimal> productPrices = new Map<Id, Decimal>();
        List<vlocity_cmt__PriceListEntry__c> priceEntries = [
            SELECT vlocity_cmt__ProductId__c, vlocity_cmt__PricingElementAmount__c
            FROM vlocity_cmt__PriceListEntry__c
            WHERE vlocity_cmt__ProductId__c IN :candidateIds
            AND vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__EffectiveUntilDate__c = null 
            AND vlocity_cmt__PromotionId__c = null
            AND vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c  = 'PL-B2C'
            AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            WITH USER_MODE
        ];
        System.debug('productPrices: ' + productPrices);

        for(vlocity_cmt__PriceListEntry__c ple: priceEntries){
            productPrices.put(ple.vlocity_cmt__ProductId__c, ple.vlocity_cmt__PricingElementAmount__c);
            System.debug('productPrices loop: ' + productPrices);
        }

        // Filter products according to their UVT limit and price
        List<Product2> filteredProducts = new List<Product2>();
        for (Product2 product : candidateProducts) {
            Decimal productPrice = productPrices.containsKey(product.Id) ? productPrices.get(product.Id) : 0;
            Decimal productLimit = productUVTLimits.containsKey(product.Id) ? productUVTLimits.get(product.Id) : 0;
            if(productLimit == null) productLimit = 0;
            System.debug('productPrice: ' + productPrice);
            System.debug('productLimit: ' + productLimit);
            System.debug('product.Id: ' + product.Id);

            // Aplicar iVA si el precio supera el límite UVT
            Decimal adjustedPrice;
            if(productPrice > (uvtPrice * productLimit)){
                adjustedPrice = productPrice + (productPrice * 0.19);
            } else{
                adjustedPrice = productPrice;
            }
            System.debug('adjustedPrice: ' + adjustedPrice);

            if(adjustedPrice >= minPriceOriginal && adjustedPrice <= maxPriceOriginal){
                filteredProducts.add(product);
            }
        }

        return filteredProducts;
    }

    // Fetch Attribute Assignment IDs
    private static List<Id> getProductMarcaIds(String productBrand) {
        List<Id> productMarcaIds = new List<Id>();
        List<vlocity_cmt__AttributeAssignment__c> productsMarcaList = [
            SELECT vlocity_cmt__ObjectId__c
            FROM vlocity_cmt__AttributeAssignment__c 
            WHERE vlocity_cmt__AttributeId__r.vlocity_cmt__Code__c = 'B2C-ATTR-MARCA-TERM'
            AND vlocity_cmt__Value__c = :productBrand
            WITH USER_MODE
            ORDER BY Name
        ];

        // Extract IDs from the query result
        for (vlocity_cmt__AttributeAssignment__c assignment : productsMarcaList) {
            productMarcaIds.add(assignment.vlocity_cmt__ObjectId__c);
        }

        System.debug('Fetched Product Marca IDs: ' + productMarcaIds);
        return productMarcaIds;
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

    //Method for getting the price options based on the ProductType
    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getPriceOptions (String priceOptionProductType){
        List <CAT_Opciones_Precio_Buscador_Productos__c> priceOptionsList = [
                SELECT CAT_Descripcion_Rango__c, CAT_Precio_Minimo__c, CAT_Precio_Maximo__c
                FROM CAT_Opciones_Precio_Buscador_Productos__c
                WHERE CAT_Tipo_de_Producto__c = :priceOptionProductType
                WITH USER_MODE
                ORDER BY CAT_Precio_Minimo__c ASC
        ];
        Map <String, String> priceOptionsMap = new Map <String, String> ();
        List <Map<String,String>> priceOptions = new List <Map<String,String>> ();
            for (CAT_Opciones_Precio_Buscador_Productos__c priceOption : priceOptionsList) {
                //priceOptionsMap.put('label', priceOption.CAT_Descripcion_Rango__c);
                //priceOptionsMap.put('value', priceOption.CAT_Precio_Minimo__c +'-'+ priceOption.CAT_Precio_Maximo__c);
                System.debug('priceOptionsMap'+ JSON.serialize(priceOptionsMap));
                priceOptions.add( new Map <String,String> {'label'=> priceOption.CAT_Descripcion_Rango__c,'value'=> priceOption.CAT_Precio_Minimo__c +'-'+ priceOption.CAT_Precio_Maximo__c});
                System.debug('priceOptionsList'+ JSON.serialize(priceOptions));
            }
        return priceOptions;
    }
}