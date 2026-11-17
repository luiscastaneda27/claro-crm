/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class that exposes service inbound Object Assets 
Test Class:     PVU_Inbound_GetAssets_TEST
History
<Date>          <Author>        <Change Description>
20/06/2024      Luis Mendoza    Initial Version
23/08/2024      Luis Mendoza    version with response in format JSON
------------------------------------------------------------*/
@RestResource(urlMapping='/GetAssets')
global with sharing class PVU_Inbound_GetAssets {

    @HttpGet
    global static void getAssetsByDocumentAndType() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        // Retrieve query parameters
        String documentNumber = req.params.get('documentNumber');
        String documentType = req.params.get('documentType');
        String fields = req.params.get('fields');

        System.debug('documentNumber' + documentNumber);
        System.debug('documentType' + documentType);

        List<Asset> assets = new List<Asset>();
        Set<Id> idAccounts = new Set<Id>();

        Map<String,Object> respMap = new Map<String,Object>();
        
        try {
            List<Account> accountIds = [SELECT fvu_documentnumber__c, fvu_documenttype__c, name, id, type, parentid 
            FROM Account WHERE FVU_DocumentNumber__c =:documentNumber AND FVU_DocumentType__c =:documentType WITH USER_MODE];
            
            for (Account acc : accountIds) {
                idAccounts.add(acc.Id);
            }   
            
            assets = [SELECT Id, vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c,
            ProductFamily, ProductCode, Product2.vlocity_cmt__SubType__c, Product2.vlocity_cmt__Type__c, Name,
            PVU_IMEI__c, PurchaseDate, Status, vlocity_cmt__AssetReferenceId__c, PVU_Serial__c,
            vlocity_cmt__ConnectDate__c, vlocity_cmt__DisconnectDate__c, vlocity_cmt__ActivationDate__c, PVU_FechaEntrega__c,  
            vlocity_cmt__SubscriptionId__r.OM_SubStatus__c, vlocity_cmt__SubscriptionId__r.OM_MSISDN__c
            FROM Asset WHERE AccountId IN :idAccounts AND 
            vlocity_cmt__ParentItemId__c = null  AND vlocity_cmt__ReliesOnItemId__c = null 
            AND (vlocity_cmt__DisconnectDate__c = null OR vlocity_cmt__DisconnectDate__c > TODAY ) 
            WITH USER_MODE 
            order by CreatedDate desc ];
            
            System.debug('assets ' +  assets);
            
            
        } catch(Exception e) {
            Map<String, Object> errorObj = new Map<String, Object>();
            errorObj.put('Error', e.getCause());
            errorObj.put('Status', '400' );
            errorObj.put('Message', e.getMessage() + ' ' + e.getLineNumber());
            // return JSON.serialize(errorObj);
            res.responseBody = Blob.valueOf(JSON.serialize(errorObj));
        }
        
        if(assets.size() == 0){
            res.statusCode = 404;

            Map<String, Object> errorObj = new Map<String, Object>();
            errorObj.put('responseCode', '400' );
            errorObj.put('message', 'Asset not found');
            // return JSON.serialize(errorObj);
            res.responseBody = Blob.valueOf(JSON.serialize(errorObj));
            
        }else{

            respMap.put('Assets', new List<Map<String, Object>>());

            for (Asset ass : assets) {
                Map<String,Object> assetsMaps = new Map<String,Object>();
                assetsMaps.put('externalcustomerid', ass.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c);
                assetsMaps.put('id', ass.Id);
                assetsMaps.put('Imei', ass.PVU_IMEI__c);
                assetsMaps.put('serial', ass.PVU_Serial__c);
                assetsMaps.put('productFamily', ass.ProductFamily);
                assetsMaps.put('productCode', ass.ProductCode);
                assetsMaps.put('productSubType', ass.Product2.vlocity_cmt__SubType__c);
                assetsMaps.put('productType', ass.Product2.vlocity_cmt__Type__c);
                assetsMaps.put('name', ass.Name);
                assetsMaps.put('purchaseDate', ass.PurchaseDate);
                assetsMaps.put('assetReferenceId', ass.vlocity_cmt__AssetReferenceId__c);
                assetsMaps.put('assetStatus', ass.Status);
                assetsMaps.put('subCausal', ass.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c);
                assetsMaps.put('connectDate', ass.vlocity_cmt__ConnectDate__c);
                assetsMaps.put('disconnectDate', ass.vlocity_cmt__DisconnectDate__c);
                assetsMaps.put('activationDate', ass.vlocity_cmt__ActivationDate__c );
                assetsMaps.put('deliveryDate', ass.PVU_FechaEntrega__c);
                assetsMaps.put('msisdn', ass.vlocity_cmt__SubscriptionId__r.OM_MSISDN__c);
                ((List<Map<String, Object>>)respMap.get('Assets')).add(assetsMaps);
            }
            
            respMap.put('documentNumber', documentNumber);
            respMap.put('documentType', documentType);
        }
 
        if(String.isNotBlank(fields)){
            List<Object> listObj = (List<Object>) respMap.get('Assets');
            if(respMap.get('message') != 'Asset Not found' ){
                List<Map<String,Object>> asstsreps = PVU_Inbound_GetAssetDetail.getFilterList( listObj, fields);
                respMap.put('Assets',asstsreps);
            }
        }

        res.responseBody = Blob.valueOf(JSON.serialize(respMap));
        // return JSON.serialize(respMap);
    }
}