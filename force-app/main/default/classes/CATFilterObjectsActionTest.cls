/*--------------------------------------------------------------------------
Author: Alan Semino - alan.semino@intellectsystem.net
Company: Salesforce.com
Description: Clase apex test para clase apex CATFilterObjectsAction.
Code Coverage: -
History
<Date> 			<Author>	 	<Description>		 <Version>
11-Sep-25	   Alan Semino  						inicial version
----------------------------------------------------------------------------*/
@IsTest(SeeAllData=false)
public class CATFilterObjectsActionTest {

    /*
    * @description 622605 - Creación de datos de prueba: productos y promociones (con y sin canal).
    */
    @TestSetup
    static void setupData() {
        String channel = 'ECOMMERCE';

        // Product con canal
        insert new Product2(
            Name = 'Prod OK',
            ProductCode = 'PRODCODE-OK',
            vlocity_cmt__GlobalKey__c = 'GK_PROD_OK',
            CAT_Canales__c = channel,
            IsActive = true
        );

        // Product SIN canal
        insert new Product2(
            Name = 'Prod NOCH',
            ProductCode = 'PRODCODE-NOCH',
            vlocity_cmt__GlobalKey__c = 'GK_PROD_NOCH',
            IsActive = true
        );

        // Promotion NO-Bundle con canal (va a promoCodes)
        insert new vlocity_cmt__Promotion__c(
            Name = 'Promo NoBundle OK',
            CAT_Type__c = 'Estandar',
            CAT_PromotionClass__c = 'Terceros', // != 'Bundle'
            vlocity_cmt__GlobalKey__c = 'GK_PROMO_NB_OK',
            vlocity_cmt__Code__c = 'PROMO-NB-01',
            CAT_Canales__c = channel
        );

        // Promotion Bundle con canal (Code va a productCodes)
        insert new vlocity_cmt__Promotion__c(
            Name = 'Promo Bundle OK',
            CAT_Type__c = 'Estandar',
            CAT_PromotionClass__c = 'Bundle',
            vlocity_cmt__GlobalKey__c = 'GK_PROMO_BUNDLE_OK',
            vlocity_cmt__Code__c = 'PROMO-BUNDLE-01',
            CAT_Canales__c = channel
        );

        // Promotion SIN canal (va a noChannelKeys)
        insert new vlocity_cmt__Promotion__c(
            Name = 'Promo NOCH',
            CAT_Type__c = 'Estandar',
            CAT_PromotionClass__c = 'Terceros',
            vlocity_cmt__GlobalKey__c = 'GK_PROMO_NOCH',
            vlocity_cmt__Code__c = 'PROMO-NB-NOCH'
        );
    }
    
    /*
    * @description 622605 - Test con canal seleccionado: Valida Product2 y Promotion devolviendo ProductCode o Code (promotion).
    */
    @IsTest
    static void testConCanalSeleccionado() {
        String channel = 'ECOMMERCE';

        String gkProdOk   = [SELECT vlocity_cmt__GlobalKey__c FROM Product2 WHERE Name='Prod OK' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkProdNoCh = [SELECT vlocity_cmt__GlobalKey__c FROM Product2 WHERE Name='Prod NOCH' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkPromoNB  = [SELECT vlocity_cmt__GlobalKey__c FROM vlocity_cmt__Promotion__c WHERE Name='Promo NoBundle OK' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkPromoB   = [SELECT vlocity_cmt__GlobalKey__c FROM vlocity_cmt__Promotion__c WHERE Name='Promo Bundle OK' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkPromoNoCh= [SELECT vlocity_cmt__GlobalKey__c FROM vlocity_cmt__Promotion__c WHERE Name='Promo NOCH' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkInvalid  = 'GK_INVALID';

        CATFilterObjectsAction.InputParameters in1 = new CATFilterObjectsAction.InputParameters();
        in1.globalKeys = new List<String>{
            gkProdOk, gkProdNoCh,
            gkPromoNB, gkPromoB, gkPromoNoCh,
            gkInvalid
        };
        in1.canales = channel;

        Test.startTest();
        List<CATFilterObjectsAction.OutputParameters> outList =
            CATFilterObjectsAction.validateGlobalKeys(new List<CATFilterObjectsAction.InputParameters>{ in1 });
        Test.stopTest();

        System.assertEquals(1, outList.size());
        CATFilterObjectsAction.OutputParameters out = outList[0];

        // Válidos
        System.assert(out.validKeys.contains(gkProdOk),  'Product con canal debe ser válido');
        System.assert(out.validKeys.contains(gkPromoNB), 'Promotion NO-Bundle con canal debe ser válida');
        System.assert(out.validKeys.contains(gkPromoB),  'Promotion Bundle con canal debe ser válida');

        // - Product2
        System.assert(out.productCodes.contains('PRODCODE-OK'), 'Debe incluir ProductCode del Product2');
        // - Promotion no Bundle
        System.assert(out.promoCodes.contains('PROMO-NB-01'), 'NO-Bundle debe ir a promoCodes');
        // - Promotion Bundle
        System.assert(out.productCodes.contains('PROMO-BUNDLE-01'), 'Bundle debe aportar su Code a productCodes');

        // Sin canal
        System.assert(out.noChannelKeys.contains(gkProdNoCh), 'Product sin canal');
        System.assert(out.noChannelKeys.contains(gkPromoNoCh), 'Promotion sin canal');

        // Inexistente
        System.assert(out.invalidKeys.contains(gkInvalid), 'Key inexistente → invalidKeys');
    }

    /*
    * @description 622605 - Test sin canal seleccionado: Ninguno debe ser válido (invalidKeys) y los que carecen de canal (noChannelKeys).
    */
    @IsTest
    static void testSinCanalesSeleccionado() {
        String gkProdOk   = [SELECT vlocity_cmt__GlobalKey__c FROM Product2 WHERE Name='Prod OK' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkPromoNB  = [SELECT vlocity_cmt__GlobalKey__c FROM vlocity_cmt__Promotion__c WHERE Name='Promo NoBundle OK' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkProdNoCh = [SELECT vlocity_cmt__GlobalKey__c FROM Product2 WHERE Name='Prod NOCH' LIMIT 1].vlocity_cmt__GlobalKey__c;
        String gkPromoNoCh= [SELECT vlocity_cmt__GlobalKey__c FROM vlocity_cmt__Promotion__c WHERE Name='Promo NOCH' LIMIT 1].vlocity_cmt__GlobalKey__c;

        CATFilterObjectsAction.InputParameters inNoCh = new CATFilterObjectsAction.InputParameters();
        inNoCh.globalKeys = new List<String>{ gkProdOk, gkPromoNB, gkProdNoCh, gkPromoNoCh };
        inNoCh.canales = null;

        Test.startTest();
        List<CATFilterObjectsAction.OutputParameters> outList =
            CATFilterObjectsAction.validateGlobalKeys(new List<CATFilterObjectsAction.InputParameters>{ inNoCh });
        Test.stopTest();

        CATFilterObjectsAction.OutputParameters out = outList[0];

        // Sin canal
        System.assertEquals(0, out.validKeys.size(), 'Sin canal elegido no debería haber válidos');

        // NO tienen canal en el registro
        System.assert(out.noChannelKeys.contains(gkProdNoCh),  'Product sin canal.');
        System.assert(out.noChannelKeys.contains(gkPromoNoCh), 'Promotion sin canal.');

        // Sí tienen canal pero no gb validas
        System.assert(out.invalidKeys.contains(gkProdOk),  'Product con gk invalido.');
        System.assert(out.invalidKeys.contains(gkPromoNB), 'Promotion con gk invalido.');
    }
}