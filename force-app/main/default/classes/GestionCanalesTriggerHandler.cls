public with sharing class GestionCanalesTriggerHandler {
    
    public static void actualizaUsuario(List<GestionCanalesUsuario__c> lInfoUsuario) {       
        Set<String> setIdFederacion = new Set<String>();        
        for(GestionCanalesUsuario__c ec : lInfoUsuario) {
            if(String.isNotBlank(ec.FederationIdentifier__c)) { 
                setIdFederacion.add(ec.FederationIdentifier__c); 
            }
        }
        
        Map<String,String> mapUsers = new Map<String,String>();
        for(User us : [SELECT Id,Email,FederationIdentifier FROM User WHERE FederationIdentifier IN :setIdFederacion OR Email IN :setIdFederacion WITH SECURITY_ENFORCED]) {
            if(String.isNotBlank(us.FederationIdentifier)) {
                mapUsers.put(us.FederationIdentifier.toLowerCase(), us.Id);
            } else mapUsers.put(us.Email.toLowerCase(), us.Id);
        }
        
        Map<String,String> mapUserGCU = new Map<String,String>();
        for(GestionCanalesUsuario__c ec : lInfoUsuario) {
            if(String.isNotBlank(ec.FederationIdentifier__c)) {
                if(!mapUsers.containsKey(ec.FederationIdentifier__c.toLowerCase())) {
                    ec.addError('No se encontró usuario con ID: ' + ec.FederationIdentifier__c);
                } else if(String.isBlank(ec.FVU_DANE_Punto_de_Venta__c)) {
                    ec.addError('El campo FVU_DANE_Punto_de_Venta__c no puede estar vacío');
                } else {
                    ec.User__c = mapUsers.get(ec.FederationIdentifier__c.toLowerCase());             
                    mapUserGCU.put(ec.FederationIdentifier__c.toLowerCase(), mapUsers.get(ec.FederationIdentifier__c.toLowerCase()));
                }
            }           
        }
        updateUsers(mapUserGCU);
        
    }
    
    @future
    public static void updateUsers(Map<String,String> mapUserGCU) {
        
        List<User> lUsersToUpd = new List<User>();
        for(GestionCanalesUsuario__c ec : [SELECT Id,User__c,FederationIdentifier__c, FVU_BusinessChannel__c, FVU_Cargo__c, FVU_Categoria__c,
                                           FVU_CentroLogistico__c, FVU_CiudadCAV__c, FVU_Comite__c, FVU_CodigoG__c, FVU_CodigoD__c, 
                                           FVU_DANE_Punto_de_Venta__c, FVU_Departamento__c, FVU_Empleador__c, FVU_Estado__c, FVU_FechaDeAdmision__c,
                                           FVU_GerenciaDireccion__c, FVU_GVAREA__c, FVU_GVDISTRICT__c, FVU_GVDIVISION__c, FVU_GVRED__c, FVU_GVZONE__c,
                                           FVU_IDDistrito__c, FVU_IDDivision__c, FVU_IDZona__c, FVU_IDArea__c, FVU_JefeDirecto__c, FVU_NITDelEmpleador__c,
                                           FVU_NumeroDeIdentificacion__c, FVU_OrganizacionDeVentas__c, FVU_PerfilamientoCatalogo__c, FVU_PuntoVenta__c,
                                           FVU_RazonDeTerminacionDelContrato__c, FVU_Subcanal__c, FVU_TipoDeDocumento__c, PVU_UserType__c, PVU_Usuario_Red__c
                                           FROM GestionCanalesUsuario__c 
                                           WHERE FederationIdentifier__c IN : mapUserGCU.keySet() WITH SYSTEM_MODE]) 
        {
            User us = new User();
            us.Id = mapUserGCU.get(ec.FederationIdentifier__c.toLowerCase());
            if(String.isNotBlank(ec.FVU_BusinessChannel__c)) { us.FVU_BusinessChannel__c = ec.FVU_BusinessChannel__c; }
            if(String.isNotBlank(ec.FVU_Cargo__c)) { us.FVU_Cargo__c = ec.FVU_Cargo__c; }
            if(String.isNotBlank(ec.FVU_Categoria__c)) { us.FVU_Categoria__c = ec.FVU_Categoria__c; }
            if(String.isNotBlank(ec.FVU_CentroLogistico__c)) { us.FVU_CentroLogistico__c = ec.FVU_CentroLogistico__c; }
            if(String.isNotBlank(ec.FVU_CiudadCAV__c)) { us.FVU_CiudadCAV__c = ec.FVU_CiudadCAV__c; }
            if(String.isNotBlank(ec.FVU_Comite__c)) { us.FVU_Comite__c = ec.FVU_Comite__c; }
            if(String.isNotBlank(ec.FVU_CodigoG__c)) { us.FVU_CodigoG__c = ec.FVU_CodigoG__c; }
            if(String.isNotBlank(ec.FVU_CodigoD__c)) { us.FVU_CodigoD__c = ec.FVU_CodigoD__c; }
            if(String.isNotBlank(ec.FVU_DANE_Punto_de_Venta__c)) { us.FVU_DANE_Punto_de_Venta__c = ec.FVU_DANE_Punto_de_Venta__c; }
            if(String.isNotBlank(ec.FVU_Departamento__c)) { us.FVU_Departamento__c = ec.FVU_Departamento__c; }
            if(String.isNotBlank(ec.FVU_Empleador__c)) { us.FVU_Empleador__c = ec.FVU_Empleador__c; }
            if(String.isNotBlank(ec.FVU_Estado__c)) { us.FVU_Estado__c = ec.FVU_Estado__c; }
            if(String.isNotBlank(String.valueOf(ec.FVU_FechaDeAdmision__c))) { us.FVU_FechaDeAdmision__c = ec.FVU_FechaDeAdmision__c; }
            if(String.isNotBlank(ec.FVU_GerenciaDireccion__c)) { us.FVU_GerenciaDireccion__c = ec.FVU_GerenciaDireccion__c; }
            if(String.isNotBlank(ec.FVU_GVAREA__c)) { us.FVU_GVAREA__c = ec.FVU_GVAREA__c; }
            if(String.isNotBlank(ec.FVU_GVDISTRICT__c)) { us.FVU_GVDISTRICT__c = ec.FVU_GVDISTRICT__c; }
            if(String.isNotBlank(ec.FVU_GVDIVISION__c)) { us.FVU_GVDIVISION__c = ec.FVU_GVDIVISION__c; }
            if(String.isNotBlank(ec.FVU_GVRED__c)) { us.FVU_GVRED__c = ec.FVU_GVRED__c; }
            if(String.isNotBlank(ec.FVU_GVZONE__c)) { us.FVU_GVZONE__c = ec.FVU_GVZONE__c; }
            if(String.isNotBlank(ec.FVU_IDDistrito__c)) { us.FVU_IDDistrito__c = ec.FVU_IDDistrito__c; }
            if(String.isNotBlank(ec.FVU_IDDivision__c)) { us.FVU_IDDivision__c = ec.FVU_IDDivision__c; }
            if(String.isNotBlank(ec.FVU_IDZona__c)) { us.FVU_IDZona__c = ec.FVU_IDZona__c; }
            if(String.isNotBlank(ec.FVU_IDArea__c)) { us.FVU_IDArea__c = ec.FVU_IDArea__c; }
            if(String.isNotBlank(ec.FVU_JefeDirecto__c)) { us.FVU_JefeDirecto__c = ec.FVU_JefeDirecto__c; }
            if(String.isNotBlank(ec.FVU_NITDelEmpleador__c)) { us.FVU_NITDelEmpleador__c = ec.FVU_NITDelEmpleador__c; }
            if(String.isNotBlank(ec.FVU_NumeroDeIdentificacion__c)) { us.FVU_NumeroDeIdentificacion__c = ec.FVU_NumeroDeIdentificacion__c; }
            if(String.isNotBlank(ec.FVU_OrganizacionDeVentas__c)) { us.FVU_OrganizacionDeVentas__c = ec.FVU_OrganizacionDeVentas__c; }
            if(String.isNotBlank(ec.FVU_PerfilamientoCatalogo__c)) { us.FVU_PerfilamientoCatalogo__c = ec.FVU_PerfilamientoCatalogo__c; }
            if(String.isNotBlank(ec.FVU_PuntoVenta__c)) { us.FVU_PuntoVenta__c = ec.FVU_PuntoVenta__c; }
            if(String.isNotBlank(ec.FVU_RazonDeTerminacionDelContrato__c)) { us.FVU_RazonDeTerminacionDelContrato__c = ec.FVU_RazonDeTerminacionDelContrato__c; }
            if(String.isNotBlank(ec.FVU_Subcanal__c)) { us.FVU_Subcanal__c = ec.FVU_Subcanal__c; }
            if(String.isNotBlank(ec.FVU_TipoDeDocumento__c)) { us.FVU_TipoDeDocumento__c = ec.FVU_TipoDeDocumento__c; }
            if(String.isNotBlank(ec.PVU_UserType__c)) { us.PVU_UserType__c = ec.PVU_UserType__c; }
            if(String.isNotBlank(ec.PVU_Usuario_Red__c)) { us.PVU_Usuario_Red__c = ec.PVU_Usuario_Red__c; }
            lUsersToUpd.add(us);
        }
        if(!lUsersToUpd.isEmpty()) {
            update lUsersToUpd;
        } 
    }

}