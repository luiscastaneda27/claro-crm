/*-------------------------------------------------------------------------------------------------------------------
Autor: Juan Mojica 
Fecha: 2025-04-24 
Code Coverage: 100%
Equipo: Catálogo
Descripcion: Servicio para consultar IDs de Material de equipos TyT configurados en Salesforce (activos e inactivos)
History
<Date>            <Author>             <Description>                                <Version>
2025-04-24         Juan Mojica         Version Inicial                               1
2025-05-07         Nahir Arrejoria     Nuevo nombre + with user mode en query        1.1
--------------------------------------------------------------------------------------------------------------------*/
@RestResource(urlMapping='/consultaIdsMaterialTyT/*')
global with sharing class CATConsultaIDsMaterialTyT {

    @HttpGet
    global static List<String> consultaIdsMaterialTyT() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        System.debug('consultaIdsMaterialTyT GET Request: ' + JSON.serialize(req));
        System.debug('consultaIdsMaterialTyT GET Response: ' + JSON.serialize(res));
        List<String> idsProductoActivos = new List<String>();

        for (Product2 idProducto : [SELECT Id FROM Product2 WHERE Family = 'Device' AND vlocity_cmt__Type__c IN ('Handset','Tech') AND vlocity_cmt__SpecificationType__c = 'Offer' WITH USER_MODE]){
            idsProductoActivos.add(idProducto.Id);
        }
        List<String> listaIdsMaterial = new List<String>();
        for (vlocity_cmt__AttributeAssignment__c idMaterial : [SELECT vlocity_cmt__Value__c FROM vlocity_cmt__AttributeAssignment__c WHERE (vlocity_cmt__AttributeUniqueCode__c = 'B2C-ATTR-TEC-MATERIAL' OR vlocity_cmt__AttributeUniqueCode__c = 'B2C-ATTR-MATERIAL-TERM') AND vlocity_cmt__Value__c != null AND vlocity_cmt__ObjectId__c IN :idsProductoActivos WITH USER_MODE]){
            listaIdsMaterial.add(idMaterial.vlocity_cmt__Value__c);
        }
        System.debug('IDs Material: ' + JSON.serialize(listaIdsMaterial));
        return listaIdsMaterial;
    }
}