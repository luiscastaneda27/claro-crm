@isTest
public with sharing class CaseCatalogsServiceTest {
    
	@isTest
    static void getMetadataFieldsTest(){
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
        ccf.PVU_Required__c = false;
        ccf.PVU_CaseCatagorySpecification__c     = ccs.Id;
        ccf.PVU_CaseFieldSpecification__c  =  cfs.Id;

        insert ccf;


        system.debug('salida>'+ Caso.Id);
        String salida=CaseCatalogsService.getMetadataFields(Caso.Id);
        system.debug('salida>'+ salida);
        System.assert(salida != null,'Error al obtener los campos...');
        
        
    }
}