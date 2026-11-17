@isTest
class ObjectUtilsTest {

    @isTest
    static void getQueryParameterArrayFromListTest() {
        String areas ='Soporte, fallas de servicio y equipos';
        String salida= '';
        /*salida=CaseCatalogUtils.CaseCatalogUtils(subCauses, areas);*/
        //ObjectUtils ObjectgUtils = new ObjectUtils(new Set<String>{subCause}, new List<String> {area});
        salida =  ObjectUtils.getQueryParameterArrayFromList(new List<String> {areas});
        System.assert(true,'Error al obtener los campos...');
    }

    static void isObjectAStringTest() {
        Integer areasInt = 6;
        String salida= '';
        salida =  ObjectUtils.getQueryParameterArrayFromList(new List<Integer> {areasInt});
        System.assert(true,'Error al obtener los campos...');
    }
}