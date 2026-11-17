/*--------------------------------------------------------------------------
Author:         Josue Pineda - josue.pineda@salesforce.com
Company:        Salesforce.com
Description:    Class Controller for the LWC Cat Product Browser - Details View (Modal Window)
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
21-Feb-25         Josue Pineda                            inicial version
----------------------------------------------------------------------------*/
public with sharing class CATProductDetailsController {

    @AuraEnabled(cacheable=true)
    public static ProductWrapper getProductDetails(Id productId) {
        ProductWrapper productData = new ProductWrapper();
        
        // Fetch Product2 Details
        Product2 product = [
            SELECT Id, Name, Description 
            FROM Product2 
            WHERE Id = :productId
            WITH USER_MODE
            LIMIT 1
        ];
        
        productData.id = product.Id;
        productData.name = product.Name;
        productData.description = product.Description;

        // Fetch Product Images
        productData.imageList = getProductImages(productId);

        // Fetch Two Prices
        Map<String, String> priceMap = getProductPrices(productId);
        productData.basePrice = priceMap.get('Cliente Masivo');
        productData.lowestPrice = priceMap.get('Antiguedad Mayor a 24 meses');

        // Fetch Product Attributes
        productData.attributes = getProductAttributes(productId);

        return productData;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductImages(Id productId) {
        List<String> imageUrls = new List<String>();

        List<vlocity_cmt__VlocityAttachment__c> attachments = [
            SELECT vlocity_cmt__UrlLong__c 
            FROM vlocity_cmt__VlocityAttachment__c
            WHERE vlocity_cmt__ObjectId__c = :productId
            WITH USER_MODE
        ];

        for (vlocity_cmt__VlocityAttachment__c attachment : attachments) {
            imageUrls.add(attachment.vlocity_cmt__UrlLong__c);
        }

        return imageUrls;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getProductPrices(Id productId) {
        Map<String, String> priceMap = new Map<String, String>();

        List<vlocity_cmt__PriceListEntry__c> prices = [
            SELECT vlocity_cmt__DisplayText__c, vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c
            FROM vlocity_cmt__PriceListEntry__c
            WHERE vlocity_cmt__ProductId__c = :productId
            AND vlocity_cmt__IsActive__c = true
            AND vlocity_cmt__EffectiveUntilDate__c = null 
            AND vlocity_cmt__PromotionId__c = null
            AND vlocity_cmt__PricingElementId__r.vlocity_cmt__AdjustmentValue__c = null
            AND (vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c  = 'PL-B2C' OR vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c  = 'B2C-PL-ANT-MAYOR-24M')
            WITH USER_MODE
        ];

        for (vlocity_cmt__PriceListEntry__c price : prices) {
            if (price.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c == 'PL-B2C') {
                priceMap.put('Cliente Masivo', price.vlocity_cmt__DisplayText__c);
            } else if (price.vlocity_cmt__PriceListId__r.vlocity_cmt__Code__c == 'B2C-PL-ANT-MAYOR-24M') {
                priceMap.put('Antiguedad Mayor a 24 meses', price.vlocity_cmt__DisplayText__c);
            }
        }

        return priceMap;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductAttributeWrapper> getProductAttributes(Id productId) {
        List<ProductAttributeWrapper> attributesList = new List<ProductAttributeWrapper>();

        List<vlocity_cmt__AttributeAssignment__c> attributes = [
            SELECT Id, vlocity_cmt__AttributeDisplayName__c, vlocity_cmt__Value__c, vlocity_cmt__CategoryName__c
            FROM vlocity_cmt__AttributeAssignment__c
            WHERE vlocity_cmt__ObjectId__c = :productId
            AND vlocity_cmt__IsHidden__c = false
            WITH USER_MODE
            ORDER BY vlocity_cmt__CategoryName__c 
        ];

        for (vlocity_cmt__AttributeAssignment__c attr : attributes) {
            ProductAttributeWrapper wrapper = new ProductAttributeWrapper();
            wrapper.name = attr.vlocity_cmt__AttributeDisplayName__c;
            wrapper.value = attr.vlocity_cmt__Value__c;
            wrapper.categoryName = attr.vlocity_cmt__CategoryName__c;
            attributesList.add(wrapper);
        }

        return attributesList;
    }

    // Wrapper Classes
    public class ProductWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public List<String> imageList;
        @AuraEnabled public String basePrice;
        @AuraEnabled public String lowestPrice;
        @AuraEnabled public List<ProductAttributeWrapper> attributes;
    }

    public class ProductAttributeWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String value;
        @AuraEnabled public String categoryName;
    }
}