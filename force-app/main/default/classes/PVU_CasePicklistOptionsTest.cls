/**
 * Grupo              : PVU
 * @author            : María Ángeles Pérez - maria.perez@nespon.com
 * @last modified on  : 09-09-2025
 * @last modified by  : María Ángeles Pérez - maria.perez@nespon.com
 * @description       : Tests para PVU_CasePicklistOptions
 */
@IsTest
private class PVU_CasePicklistOptionsTest {

    @testSetup
    static void setupData() {
        insert new Case(Origin = 'Phone', Status = 'New', Subject = 'Caso de prueba');
    }

    private static List<Schema.PicklistEntry> getOriginEntries() {
        Schema.DescribeFieldResult dfr = Case.Origin.getDescribe();
        List<Schema.PicklistEntry> all = dfr.getPicklistValues();
        List<Schema.PicklistEntry> act = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry pe : all) if (pe.isActive()) act.add(pe);
        return act;
    }

    private static List<Schema.PicklistEntry> getDependentEntries() {
        Schema.DescribeFieldResult dfr = Case.FIN_MotivoAjuste__c.getDescribe();
        return dfr.getPicklistValues();
    }

    private class ValidPair {
        Integer ctrlIndex;
        String ctrlValue;
        Schema.PicklistEntry depEntry;
    }
    
    private static ValidPair findAnyValidPair() {
        List<Schema.PicklistEntry> origins = getOriginEntries();
        List<Schema.PicklistEntry> deps    = getDependentEntries();
        for (Integer i = 0; i < origins.size(); i++) {
            for (Schema.PicklistEntry dep : deps) {
                if (PVU_CasePicklistOptions.isValidFor(dep, i)) {
                    ValidPair vp = new ValidPair();
                    vp.ctrlIndex = i;
                    vp.ctrlValue = origins[i].getValue();
                    vp.depEntry  = dep;
                    return vp;
                }
            }
        }
        return null;
    }

    private static void assertOptionsShape(Object maybeList) {
        System.assertNotEquals(null, maybeList, 'outMap debe contener la clave "options".');
        System.assertEquals(true, maybeList instanceof List<Object>, 'options debe ser una lista.');
        List<Object> opts = (List<Object>) maybeList;
        for (Object rowObj : opts) {
            System.assertEquals(true, rowObj instanceof Map<String, Object>, 'Cada opción debe ser un mapa name/value.');
            Map<String, Object> row = (Map<String, Object>) rowObj;
            System.assertEquals(true, row.containsKey('name'), 'Cada opción debe tener "name".');
            System.assertEquals(true, row.containsKey('value'), 'Cada opción debe tener "value".');
            if (row.get('name') != null)  System.assertEquals(true, row.get('name')  instanceof String);
            if (row.get('value') != null) System.assertEquals(true, row.get('value') instanceof String);
        }
    }

    // ==============================
    // Casos de validación de negocio
    // ==============================
    @IsTest
    static void testPopulate_withDefaultOrigin() {
        Map<String, Object> input   = null;
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = null;

        Test.startTest();
        PVU_CasePicklistOptions.populatePicklist(input, outMap, options);
        Test.stopTest();

        System.assertEquals(true, outMap.containsKey('options'), 'Debe devolver "options" en outMap.');
        assertOptionsShape(outMap.get('options'));
    }

    @IsTest
    static void testPopulate_withExplicitOrigin_andDependencyIfPresent() {
        List<Schema.PicklistEntry> origins = getOriginEntries();
        System.assertNotEquals(0, origins.size(),
            'Case.Origin debe tener al menos un valor activo para esta prueba.');

        PVU_CasePicklistOptionsTest.ValidPair vp = findAnyValidPair();
        String originValue = (vp != null) ? vp.ctrlValue : origins[0].getValue();

        Map<String, Object> input   = new Map<String, Object>{ 'origin' => originValue };
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        PVU_CasePicklistOptions.populatePicklist(input, outMap, options);
        Test.stopTest();

        System.assertEquals(true, outMap.containsKey('options'));
        List<Object> opts = (List<Object>) outMap.get('options');
        assertOptionsShape(opts);

        if (vp != null) {
            Boolean found = false;
            for (Object rowObj : opts) {
                Map<String, Object> row = (Map<String, Object>) rowObj;
                if ((String)row.get('name') == vp.depEntry.getValue()
                 && (String)row.get('value') == vp.depEntry.getLabel()) {
                    found = true; break;
                }
            }
            System.assertEquals(true, found,
                'Con dependencia configurada, debe incluirse al menos una opción mapeada al Origin elegido.');
        }
    }

    @IsTest
    static void testPopulate_withInvalidOrigin_returnsEmpty() {
        Map<String, Object> input   = new Map<String, Object>{ 'Origin' => '__INVALID__ORIGIN__' };
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        PVU_CasePicklistOptions.populatePicklist(input, outMap, options);
        Test.stopTest();

        System.assertEquals(true, outMap.containsKey('options'));
        List<Object> opts = (List<Object>) outMap.get('options');
        System.assertEquals(0, opts.size(), 'Para Origin inválido no deben generarse opciones.');
    }

    @IsTest
    static void testInvokeMethod_populatePicklist_ok() {
        Map<String, Object> input   = new Map<String, Object>(); // usará DEFAULT_ORIGIN
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = new PVU_CasePicklistOptions()
            .invokeMethod('populatePicklist', input, outMap, options);
        Test.stopTest();

        System.assertEquals(true, result, 'Debe retornar true.');
        System.assertEquals(true, outMap.containsKey('options'),
            'Con populatePicklist, outMap debe tener "options".');
        assertOptionsShape(outMap.get('options'));
    }

    @IsTest
    static void testInvokeMethod_unknownAction_returnsTrue_noOptions() {
        Map<String, Object> input   = new Map<String, Object>();
        Map<String, Object> outMap  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Boolean result = new PVU_CasePicklistOptions()
            .invokeMethod('unknownAction', input, outMap, options);

        System.assertEquals(true, result,
            'Según implementación actual, acciones desconocidas retornan true sin modificar outMap.');
        System.assertEquals(false, outMap.containsKey('options'),
            'Para acción desconocida, no debería poblar "options".');
    }

    @IsTest
    static void testIsValidFor_edgeCases() {
        List<Schema.PicklistEntry> deps = getDependentEntries();

        System.assertEquals(false, PVU_CasePicklistOptions.isValidFor(null, 0));

        if (!deps.isEmpty()) {
            System.assertEquals(false, PVU_CasePicklistOptions.isValidFor(deps[0], null));
            System.assertEquals(false, PVU_CasePicklistOptions.isValidFor(deps[0], -1));
        } else {
            System.assertEquals(false, PVU_CasePicklistOptions.isValidFor(null, null));
        }
    }
}