@isTest
public with sharing class FVU_IdClaroMetadataSelectorTest {
    @isTest
    static void getIdClaroMetadataTest() {
        FVU_IdClaroMetadata__mdt result = new FVU_IdClaroMetadataSelector().getIdClaroMetadata('UNIT_TEST_APP', 'UNIT_TEST_CHANNEL');
        System.assertEquals(result, null);
    }
}