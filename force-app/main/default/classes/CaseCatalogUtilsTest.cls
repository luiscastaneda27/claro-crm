@isTest
public with sharing class CaseCatalogUtilsTest {
    @TestSetup
    static void makeData(){
        Case caso=new Case();
        caso.PVU_Level1__c='Soporte, fallas de servicio y equipos';
        caso.PVU_Level2__c='Falla del equipo'; 
        caso.PVU_Level3__c='Falla de Equipo Garantia'; 
        insert caso;
         
        PVU_CaseFieldSpecification__c cfs=new PVU_CaseFieldSpecification__c();
        cfs.PVU_APIName__c  ='Condiciones_de_servicio__c';
        cfs.Name ='Condiciones de Servicio';        

        insert cfs;

        PVU_CaseCatagorySpecification__c ccs=new PVU_CaseCatagorySpecification__c();
        ccs.Name ='4';
        ccs.PVU_Level1__c   ='Soporte, fallas de servicio y equipos';
        ccs.PVU_Level2__c  = 'Falla del equipo';
        ccs.PVU_Level3__c  = 'Falla de Equipo Garantia';

        insert ccs;


        PVU_CaseCatagoryFields__c ccf=new PVU_CaseCatagoryFields__c();        
        ccf.PVU_Required__c = true;
        ccf.PVU_CaseCatagorySpecification__c     = ccs.Id;
        ccf.PVU_CaseFieldSpecification__c  =  cfs.Id;

        insert ccf;
    }


    @isTest
    static void getDisplayFieldsTest() {
        String subCause='Falla del equipo';
        String cause = 'Falla de Equipo Garantia';
        String salida='';
        String area ='Soporte, fallas de servicio y equipos';
        /*salida=CaseCatalogUtils.CaseCatalogUtils(subCauses, areas);*/
        CaseCatalogUtils catalogUtils = new CaseCatalogUtils(new Set<String>{cause},new Set<String>{subCause}, new List<String> {area});
        salida =  catalogUtils.getDisplayFields(true,cause, subCause, area);
        System.assert(salida != null,'Error al obtener los campos...');
      
    }
}