/**
 * =============<< ********* >>=============
 * Author       : Harold Garcia
 * Email        : harold.garcia@intellectsystem.net
 * Organization : Intellect System
 * Created On   : 2026-02-25
 * Copyright (c) 2025 Intellect System.
 * =============<< ********* >>=============
 */

@IsTest
private class EU_TipificacionServiceTest {

    @TestSetup
    static void setupData() {
        // N1
        EU_TipificacionN1__c n1 = new EU_TipificacionN1__c(
            Name = 'CALLQUALIFY_TEST',
            EU_NumTipN1__c = 'TN1-0001' // max 10, cumple
        );
        insert n1;

        // Skill -> apunta a N1
        EU_Skill__c sk = new EU_Skill__c(
            Name = 'SKILL_TEST',
            EU_Tipificacion__c = n1.Id
        );
        insert sk;

        // N2 (obligatorio: Name, EU_TipificacionN1__c)
        EU_TipificacionN2__c n2 = new EU_TipificacionN2__c(
            Name = 'N2_TEST',
            EU_TipificacionN1__c = n1.Id
        );
        insert n2;

        // N3 (obligatorio: Name, EU_TipificacionN1__c, EU_TipificacionN2__c)
        EU_TipificacionN3__c n3 = new EU_TipificacionN3__c(
            Name = 'N3_TEST',
            EU_TipificacionN1__c = n1.Id,
            EU_TipificacionN2__c = n2.Id
        );
        insert n3;
    }

    @IsTest
    static void test_getInit_success() {
        Test.startTest();
        EU_TipificacionService.TipInitDTO dto = EU_TipificacionService.getInit('SKILL_TEST');
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO no debe ser null');
        System.assertNotEquals(null, dto.n1Id, 'Debe devolver n1Id');
        System.assertEquals('CALLQUALIFY_TEST', dto.n1Name, 'Debe devolver el nombre correcto de N1');
    }

    @IsTest
    static void test_getN2_success() {
        EU_TipificacionN1__c n1 = [
            SELECT Id
            FROM EU_TipificacionN1__c
            WHERE Name = 'CALLQUALIFY_TEST'
            LIMIT 1
        ];

        Test.startTest();
        List<EU_TipificacionService.TipOptionDTO> n2Opts = EU_TipificacionService.getN2(n1.Id);
        Test.stopTest();

        System.assertEquals(1, n2Opts.size(), 'Debe devolver 1 N2');
        System.assertEquals('N2_TEST', n2Opts[0].label);
        System.assertNotEquals(null, n2Opts[0].id);
    }

    @IsTest
    static void test_getN3_success() {
        EU_TipificacionN2__c n2 = [
            SELECT Id
            FROM EU_TipificacionN2__c
            WHERE Name = 'N2_TEST'
            LIMIT 1
        ];

        Test.startTest();
        List<EU_TipificacionService.TipOptionDTO> n3Opts = EU_TipificacionService.getN3(n2.Id);
        Test.stopTest();

        System.assertEquals(1, n3Opts.size(), 'Debe devolver 1 N3');
        System.assertEquals('N3_TEST', n3Opts[0].label);
        System.assertNotEquals(null, n3Opts[0].id);
    }

    @IsTest
    static void test_blank_inputs() {
        Test.startTest();

        EU_TipificacionService.TipInitDTO dtoBlank = EU_TipificacionService.getInit('');
        System.assertEquals(null, dtoBlank.n1Id);
        System.assertEquals(null, dtoBlank.n1Name);

        System.assertEquals(0, EU_TipificacionService.getN2('').size());
        System.assertEquals(0, EU_TipificacionService.getN3('').size());

        Test.stopTest();
    }
}