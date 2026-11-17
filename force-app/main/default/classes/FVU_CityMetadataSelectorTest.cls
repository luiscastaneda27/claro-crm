@isTest
private class FVU_CityMetadataSelectorTest {

    @isTest
    static void getCityMetadataTest() {
        FVU_CityMetadata__mdt result = new FVU_CityMetadataSelector().getCityMetadata('Claro_UnitTest');
        System.assertEquals(result, null);
    }
}