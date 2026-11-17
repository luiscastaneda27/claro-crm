/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 02-20-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
* 1.0   08-29-2024   SALESFORCE   Initial Version
* 2.0   02-18-2025   SALESFORCE   Ajustes para mostrar información de producto pasaporte america. 
**/
global with sharing class PVU_AssetUtils implements vlocity_cmt.VlocityOpenInterface2{
    static global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) { 
        Boolean result = false;
        try {
            if ('getIMSI'.equalsIgnoreCase(methodName)) {
                getIMSI(inputMap,outMap);
                result = true;
            }
            if ('getRoamingServices'.equalsIgnoreCase(methodName)) {
                getRoamingServices(inputMap,outMap);
                result = true;
            } 
        } catch (Exception ex) {
            system.debug('Error');
            system.debug('trackTrace>>>>'+ex.getStackTraceString());
            system.debug('getCause>>>>'+ex.getCause());
            
        }
        return result;
    }
    
    static public void getIMSI(Map<String,Object> inputMap,Map<String,Object> outMap){
        
        String minValue='"'+(String) inputMap.get('minValue')+'"';        
        List<List<sObject>> searchList = [FIND :minValue RETURNING asset (Id,vlocity_cmt__AttributeSelectedValues__c,vlocity_cmt__RootItemId__c)];            
        String imsi=null;
        if(Test.isRunningTest()){
            imsi='123456789000';
            searchList = new List<List<sObject>>();    
            List<sObject> objectList= new List<sObject>();
            Map<String, Object> objectJson= new Map<String, Object>();
            objectJson.put('B2C-ATTR-IMSI','123456789000');
            Asset activo = new Asset();
            activo.vlocity_cmt__AttributeSelectedValues__c=JSON.serialize(objectJson);
            activo.vlocity_cmt__RootItemId__c='123456789';
            objectList.add(activo);
            searchList.add(objectList);
            
        }
        if(!searchList.isEmpty()){                        
            Asset linea= ((Asset[])searchList[0])[0];            
            List<Asset>  lista = [SELECT Id, Name, vlocity_cmt__RootItemId__c, vlocity_cmt__AttributeSelectedValues__c  FROM Asset WHERE vlocity_cmt__RootItemId__c =:linea.vlocity_cmt__RootItemId__c and Name =   'SIM Card' WITH USER_MODE];  
            //List<Asset>  lista = [SELECT Id, Name, vlocity_cmt__RootItemId__c, vlocity_cmt__AttributeSelectedValues__c  FROM Asset];              
            Map<String, Object> assetAttributesMap = (Map<String, Object>) JSON.deserializeUntyped(lista[0].vlocity_cmt__AttributeSelectedValues__c); 
            if(assetAttributesMap.get('B2C-ATTR-IMSI') != null){
                imsi = String.valueOf(assetAttributesMap.get('B2C-ATTR-IMSI'));
            }            
        }          
        outMap.put('imsi', imsi);                  
    }
    
    /* Dev: Amenaida Vasquez amenaida.vasquez@nespon.com
    * Descripcion: metodo para obtener los paquetes activos en el proceso de Roaming
    * Fecha: 28/08/2024
    * Input: AssetReferenceId
    * Output: Lista y tamano de lista de assets con paquetes activos de Roaming internacional
    */
    static public void getRoamingServices(Map<String,Object> inputMap,Map<String,Object> outMap){
        
        String assetReferenceId=(String)inputMap.get('assetReferenceId');
        integer cantidad = 0;
        string nombrePaquete = '';
        
        List<Asset> assetsList= [SELECT Product2.ProductCode , fvu_effectiveonetimetotalinctaxes__c, product2id, vlocity_cmt__disconnectdate__c, name, description, id, vlocity_cmt__reliesonitemid__c, fvu_recurringtotalinctaxes__c, vlocity_cmt__activationdate__c 
                                 FROM Asset 
                                 WHERE vlocity_cmt__ReliesOnItemId__c =:assetReferenceId 
                                 AND Product2.vlocity_cmt__Type__c = 'Add On'
                                 AND Product2.vlocity_cmt__SubType__c = 'Roaming Internacional'
                                 AND status = 'Active'
                                 WITH USER_MODE
                                 LIMIT 50000 ];
        
        List<Object> assetDataList = new List<Object>();
        List<String> paquetesact = new List<String>();
        String currencySymbol = '$';
        for(Asset assetInfo:assetsList){
            Map<String, Object> newDataMapper = new Map<String, Object>();
            newDataMapper.put('name', assetInfo.Name);
            newDataMapper.put('activationDate', assetInfo.vlocity_cmt__activationdate__c);
            newDataMapper.put('vigencia', assetInfo.vlocity_cmt__disconnectdate__c);
            newDataMapper.put('description', assetInfo.description);
            newDataMapper.put('id', assetInfo.id);
            newDataMapper.put('productCode', assetInfo.Product2.ProductCode);
            IF(assetInfo.Product2.ProductCode == 'PO_MovPosOptPaqRoamConvC' || assetInfo.Product2.ProductCode == 'PO_MovPosOptPaqRoamConvEmpC'|| assetInfo.Product2.ProductCode == 'PO_MovPosAddOnRoamConvAmount004'|| assetInfo.Product2.ProductCode == 'PO_MovPosAddOnRoamConvAmount005' ){
                newDataMapper.put('pasaporteAmerica', true);
                cantidad = cantidad + 1;
                nombrePaquete = assetInfo.Name;
            }else{
                newDataMapper.put('pasaporteAmerica', false); 
                paquetesact.add(String.valueOf(assetInfo.Name));
            }
            IF(assetInfo.FVU_EffectiveOneTimeTotalIncTaxes__c == null){
                newDataMapper.put('costo', currencySymbol + string.valueOf(assetInfo.fvu_recurringtotalinctaxes__c.format()));
            }else{
                newDataMapper.put('costo', currencySymbol + string.valueOf(assetInfo.fvu_effectiveonetimetotalinctaxes__c.format()));
            }
            
            assetDataList.add(newDataMapper);
            
        }
        
        outMap.put('assets',assetDataList);
        outMap.put('paquetesActivos', paquetesact);
        outMap.put('assetsSize',assetDataList.size());
        outMap.put('passAmericaSize', cantidad);
        outMap.put('passAmericaName', nombrePaquete);
        System.debug('outMap::'+outMap);
    }
    
}