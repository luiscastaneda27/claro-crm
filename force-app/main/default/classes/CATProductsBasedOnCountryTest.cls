@IsTest
public class CATProductsBasedOnCountryTest{
    @IsTest
    public static void testGetCompatibleProducts() {

        // Crear los productos con países asociados
        Product2 prod1 = new Product2 (
            Name='Product 1',
            ProductCode = 'Product1',
            vlocity_cmt__IsOrderable__c = true,
            IsActive = true,
            CAT_ApplicableCountries__c = 'Canadá;Estados Unidos;México;Puerto Rico'
        );
        insert prod1;

        Product2 prod2 = new Product2 (
            Name='Product 2',
            ProductCode = 'Product2',
            vlocity_cmt__IsOrderable__c = true,
            IsActive = true,
            CAT_ApplicableCountries__c = 'Alemania;Australia;Brasil;Chile'
        );
        insert prod2;

        Product2 prod3 = new Product2 (
            Name='Product 3',
            ProductCode = 'Product3',
            vlocity_cmt__IsOrderable__c = true,
            IsActive = true,
            CAT_ApplicableCountries__c = 'Venezuela;México'
        );
        insert prod3;

        // Crear mapa con el país seleccionado
        Map<String, Object> input = new Map<String, Object>();
        input.put('selectedCountry', 'México;Alemania');
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        System.debug('input Fernanda: ' + input);

        // Llamar al método de la clase
        CATProductsBasedOnCountry productsByCountry = new CATProductsBasedOnCountry();
        Boolean result = productsByCountry.invokeMethod('getCompatibleProduct', input, output, options);
        System.debug('productsByCountry: ' + productsByCountry);
        System.debug('result: ' + result);
        
        System.assert(result);
        System.assertEquals(true, result);
        
    }
}