/*------------------------------------------------------------
Author:         Luis Mendoza
Company:        Salesforce.com
Description:    Class that exposes service inbound to details object asset 
Test Class:     PVU_Inbound_GetAssetsDetail_TEST
History
<Date>          <Author>        <Change Description>
25/06/2024      Luis Mendoza    Initial Version
17/07/2024      Luis Mendoza    change add node subscription
23/08/2024      Luis Mendoza    version with response in format JSON
04/09/2024      Luis Mendoza    new field adds
19/11/2024      Luis Mendoza    new logic in method 'getResponseData'
05/12/2024      Luis Mendoza    add new nodo reliesOnItemId and method GetAddOns
------------------------------------------------------------*/
@RestResource(urlMapping='/GetAssetDetails')
global with sharing class PVU_Inbound_GetAssetDetail {


    @HttpGet
    global static void getAssetDetail() {
        Map<String, Object> errorObj = new Map<String, Object>();
        Map<String, Object> resps = new Map<String, Object>();
        Map<String, String> variableAttrs = new Map<String, String>();
        Boolean flagintomethod = false;
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        // Retrieve query parameters
        String documentNumber = req.params.get('documentNumber');
        String documentType = req.params.get('documentType');
        String externalCustomerId = req.params.get('externalCustomerId');
        String serial = req.params.get('serial');
        String mobileNumber = req.params.get('mobileNumber');
        String imei = req.params.get('imei');
        String fields = req.params.get('fields');

        variableAttrs.put('isSeeAll', req.params.get('isSeeAll'));
        variableAttrs.put('attrFlag', req.params.get('attrFlag'));

        String whereInfo = '';
        String querydata = 'SELECT Id, vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c, vlocity_cmt__BillingAccountId__r.OM_BSCSID__c,'+
            ' vlocity_cmt__ServiceAccountId__r.FVU_SerciveMerId__c,vlocity_cmt__ServiceAccountId__r.FVU_ServiceDaneCode__c, '+
            ' vlocity_cmt__ServiceAccountId__r.FVU_ServiceMiniCity__c,vlocity_cmt__ServiceAccountId__r.FVU_ServiceMunicipality__c, '+
            ' vlocity_cmt__ServiceAccountId__r.FVU_ServiceShortAddress__c, vlocity_cmt__ServiceAccountId__r.FVU_ServiceState__c,'+
            ' ProductFamily, ProductCode, Product2.vlocity_cmt__SubType__c, Product2.vlocity_cmt__Type__c, Name,PVU_IMEI__c, PurchaseDate, '+
            ' Status, vlocity_cmt__AssetReferenceId__c, PVU_Serial__c,vlocity_cmt__ConnectDate__c, vlocity_cmt__DisconnectDate__c, '+
            ' vlocity_cmt__ActivationDate__c, PVU_FechaEntrega__c,vlocity_cmt__AttributeSelectedValues__c, AccountId, Product2.vlocity_cmt__ProductSpecId__c,'+
            ' Product2.vlocity_cmt__ProductSpecName__c, Product2.Name, Product2Id, Account.FVU_CustomerGroup__c, Account.Name,'+
            ' Product2.vlocity_cmt__SpecificationSubType__c, PVU_FechaVencimientoGarantia__c, Product2.Short_Description__c, PVU_GarantiaVigente__c ,'+
            ' Account.FVU_DocumentNumber__c, Account.FVU_DocumentType__c,vlocity_cmt__CurrencyPaymentMode__c, FVU_EffectiveOneTimeTotalIncTaxes__c, '+
            ' vlocity_cmt__OneTimeTotal__c, FVU_RecurringTotalIncTaxes__c, vlocity_cmt__RecurringTotal__c,'+
            ' vlocity_cmt__SubscriptionId__c, vlocity_cmt__SubscriptionId__r.vlocity_cmt__StartDate__c, vlocity_cmt__SubscriptionId__r.vlocity_cmt__Status__c,'+
            ' vlocity_cmt__SubscriptionId__r.OM_SubStatus__c, vlocity_cmt__SubscriptionId__r.vlocity_cmt__SuspendDate__c, vlocity_cmt__ContractId__c,'+          
            ' vlocity_cmt__ParentItemId__c, vlocity_cmt__RootItemId__c, vlocity_cmt__ReliesOnItemId__c,vlocity_cmt__SubscriptionId__r.OM_RoamingCANBlocking__c'+          
            ' FROM Asset WHERE ';
        
        if( String.isNotBlank(externalCustomerId)) {
    
            whereInfo = 'vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c = '+ ' \''+ String.escapeSingleQuotes( externalCustomerId ) + '\''+ 
            'AND (Product2.vlocity_cmt__Type__c <>  \'Tech \' AND Product2.vlocity_cmt__Type__c <> \'Handset \') AND '+
            '(vlocity_cmt__DisconnectDate__c = null OR vlocity_cmt__DisconnectDate__c > TODAY)';

        }else if(String.isNotBlank(serial)){

            whereInfo = ' PVU_Serial__c = ' + ' \''+ String.escapeSingleQuotes( serial ) + '\''+ 
            ' AND (vlocity_cmt__DisconnectDate__c = null OR vlocity_cmt__DisconnectDate__c > TODAY)';
            
        }else if(String.isNotBlank(mobileNumber)){
            
            whereInfo = 'vlocity_cmt__SubscriptionId__r.OM_MSISDN__c = ' + ' \''+ String.escapeSingleQuotes( mobileNumber ) + '\''+ 
            ' AND (Status = \'Suspended\' OR Status = \'Active\' OR Status = \'Deactivated\')'+
            ' AND (vlocity_cmt__DisconnectDate__c = null OR vlocity_cmt__DisconnectDate__c > TODAY)';
            
        }else if(String.isNotBlank(imei)){

            if (String.isBlank(documentNumber) && String.isBlank(documentType)) {

                res.statusCode = 400;
                errorObj.put('message', 'número y tipo de documento requeridos');
                errorObj.put('responseCode', '400');
                res.responseBody = Blob.valueOf(JSON.serialize(errorObj));
                return;

            }else{
                whereInfo = 'PVU_IMEI__c=' + ' \''+ String.escapeSingleQuotes( imei ) + '\''+ 
                ' AND Account.FVU_DocumentNumber__c= '+ ' \''+ String.escapeSingleQuotes( documentNumber ) + '\''+ 
                ' AND  Account.FVU_DocumentType__c= ' + ' \''+ String.escapeSingleQuotes( documentType ) + '\''+
                ' AND (vlocity_cmt__DisconnectDate__c = null OR vlocity_cmt__DisconnectDate__c > TODAY)';
            }

        }else{

            res.statusCode = 404;
            errorObj.put('message', 'Parameter not found');
            errorObj.put('responseCode', '404' );
            res.responseBody = Blob.valueOf(JSON.serialize(errorObj));
            return;

        }

        resps =  (Map<String, Object>) JSON.deserializeUntyped(getQueryInformation(querydata + whereInfo, variableAttrs));
        

        if(String.isNotBlank(fields)){
            List<Object> listObj = (List<Object>) resps.get('Assets');
            if(resps.get('message') != 'Asset Not found' ){
                List<Map<String,Object>> asstsreps = getFilterList( listObj, fields);
                resps.put('Assets',asstsreps);
            }
        }
        
        res.responseBody = Blob.valueOf(JSON.serialize(resps));
    }

     private static String getSimCardKI(Id assetId){

        String querydataSimCardKI = 'SELECT Id, vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__JSONAttribute__c'+
             ' FROM vlocity_cmt__InventoryItemDecompositionRelationship__c'+
             ' WHERE vlocity_cmt__DestinationInventoryItemId__r.vlocity_cmt__ProductId__r.Name = \'PO_MovPosBasico\' AND vlocity_cmt__SourceAssetId__c =:assetId';
        
        //List<SObject> records = Database.query(querydataSimCardKI);
        Map<String, Object> variablesBind = new Map<String, Object>{'assetId' => assetId};
        List<SObject> records = Database.queryWithBinds(querydataSimCardKI, variablesBind, AccessLevel.SYSTEM_MODE);

        Map<String, Object> recordMap = new Map<String, Object>();

        if (!records.isEmpty()) {
          SObject record = records[0];
          recordMap.put('Id', record.get('Id'));

             SObject relatedItem = (SObject) record.getSObject('vlocity_cmt__DestinationInventoryItemId__r');
             if (relatedItem != null) {
        
                String jsonString = (String) relatedItem.get('vlocity_cmt__JSONAttribute__c');
        
                recordMap.put('vlocity_cmt__JSONAttribute__c', jsonString);

        
                if (String.isNotBlank(jsonString)) {
        
                    try {
        
                        Map<String, Object> topLevel = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        
                        for (Object key : topLevel.keySet()) {
        
                            List<Object> attributes = (List<Object>) topLevel.get((String) key);

        
                            for (Object attrObj : attributes) {
        
                                Map<String, Object> attr = (Map<String, Object>) attrObj;

        
                                if (attr.containsKey('attributeuniquecode__c') &&
        
                                (String) attr.get('attributeuniquecode__c') == 'TechRCki') {
        
                                recordMap.put('TechRCki_SegmentValue', attr.get('SegmentValue'));
    
                                break;
                        }
                    }
                }

            } catch (Exception e) {
                recordMap.put('TechRCki_SegmentValue', 'JSON parse error: ' + e.getMessage());
            }
        } else {
            recordMap.put('TechRCki_SegmentValue', null);
        }
    } else {
        recordMap.put('vlocity_cmt__JSONAttribute__c', null);
        recordMap.put('TechRCki_SegmentValue', null);
     }
    }

         String kiValue=recordMap.containsKey('TechRCki_SegmentValue')?String.valueOf(recordMap.get('TechRCki_SegmentValue')): null;
         
         
    return  kiValue;
  }


    private static String getQueryInformation(String queries, Map<String, String> variableAttrs){

        List<Asset> assets = new List<Asset>();
        Map<String, Object> errorObj = new Map<String, Object>();
        Map<String, Object> respExternalId = new Map<String, Object>();
        
        try {
            assets = Database.query(queries);
            assets = getAddOns(assets, queries);
            
            if (assets.size() == 0) {
                errorObj.put('message', 'Asset Not found');
                errorObj.put('responseCode', '404' );
                return JSON.serialize(errorObj);
            }
            

            respExternalId = getResponseData(assets, variableAttrs);
            respExternalId.put('documentNumber', assets[0].Account.FVU_DocumentNumber__c);
            respExternalId.put('documentType', assets[0].Account.FVU_DocumentType__c);

        } catch(Exception e) {
            errorObj.put('message', e.getCause() + ' - ' + e.getMessage() + ' - ' + e.getLineNumber());
            errorObj.put('responseCode', '400' );
            return JSON.serialize(errorObj);
        } 

        return JSON.serialize(respExternalId);
        
    }    

    private static Map<String, Object> getResponseData(List<Asset> obj, Map<String, String> variableAttrs){

        Map<String,Object> respMap = new Map<String,Object>();
        respMap.put('Assets', new List<Map<String, Object>>());

        List<vlocity_cmt__attribute__c> attrListObject = [SELECT Name , vlocity_cmt__Code__c, vlocity_cmt__ValueType__c, vlocity_cmt__AttributeCategoryName__c  
                                                            FROM vlocity_cmt__attribute__c WITH SYSTEM_MODE LIMIT 500]; 


        for (Asset ass : obj) {
               Map<String,Object> assetsMaps = new Map<String,Object>();
                assetsMaps.put('productCharacteristic', new List<Map<String, Object>>());
                assetsMaps.put('id', ass.Id);
                assetsMaps.put('Imei', ass.PVU_IMEI__c);
                assetsMaps.put('simCardKI', getSimCardKI(ass.Id));
                assetsMaps.put('serial', ass.PVU_Serial__c);
                assetsMaps.put('description', ass.Name);
                assetsMaps.put('name', ass.Name);
                assetsMaps.put('purchaseDate', ass.PurchaseDate);
                assetsMaps.put('assetReferenceId', ass.vlocity_cmt__AssetReferenceId__c);
                assetsMaps.put('assetStatus', ass.Status);
                assetsMaps.put('connectDate', ass.vlocity_cmt__ConnectDate__c);
                assetsMaps.put('disconnectDate', ass.vlocity_cmt__DisconnectDate__c);
                assetsMaps.put('activationDate', ass.vlocity_cmt__SubscriptionId__r.vlocity_cmt__StartDate__c );
                assetsMaps.put('deliveryDate', ass.PVU_FechaEntrega__c);
                assetsMaps.put('convention', ass.Account.FVU_CustomerGroup__c);
                assetsMaps.put('ericcsonBillingAccountId', ass.vlocity_cmt__BillingAccountId__r.OM_BSCSID__c);
                assetsMaps.put('ericcsoncustomerid', ass.vlocity_cmt__BillingAccountId__r.FVU_AccountExternalID__c);
                assetsMaps.put('isBundle', ass.Product2.vlocity_cmt__SpecificationSubType__c == 'Bundle' ? true : false);
                assetsMaps.put('manufacturerWarranty', ass.PVU_FechaVencimientoGarantia__c);
                assetsMaps.put('shortDescription', ass.Product2.Short_Description__c);
                assetsMaps.put('tariffSegment', ass.Product2.vlocity_cmt__SubType__c);
                assetsMaps.put('warrantyValid', ass.PVU_GarantiaVigente__c);
                assetsMaps.put('contractId', ass.vlocity_cmt__ContractId__c);
                assetsMaps.put('parentId', ass.vlocity_cmt__ParentItemId__c);
                assetsMaps.put('rootAssetId', ass.vlocity_cmt__RootItemId__c); 
                assetsMaps.put('reliesOnItemId', ass.vlocity_cmt__ReliesOnItemId__c); 
                assetsMaps.put('attributes', JSON.deserializeUntyped('{'+
                '"@type": "Asset",'+
                '"href": "/services/data/v57.0/sobjects/Asset/'+ ass.Id +'",'+
                '"id": "'+ ass.Id +'"'+
                '}'));
                if(ass.vlocity_cmt__SubscriptionId__c != null){

                    assetsMaps.put('relatedEntity', JSON.deserializeUntyped('['+
                    '{'+
                    '"@referredType": "Subscription",'+
                    '"href": "/services/data/v57.0/sobjects/vlocity_cmt__Subscription__c/'+ ass.vlocity_cmt__SubscriptionId__c +'",'+
                    '"role":"'+ ass.vlocity_cmt__SubscriptionId__r.vlocity_cmt__Status__c +'",'+
                    '"name":"'+ ass.vlocity_cmt__SubscriptionId__r.OM_SubStatus__c +'",'+
                    '"roamingCANBlocking":"'+ ass.vlocity_cmt__SubscriptionId__r.OM_RoamingCANBlocking__c +'"'+
                    '}'+
                    ']'));
                }

                assetsMaps.put('relatedParty', JSON.deserializeUntyped('[{'+
                '"@referredType": "Account",'+
                '"Id": "'+ ass.AccountId +'",'+
                '"href": "/services/data/v57.0/sobjects/Account/'+ ass.AccountId +'",'+
                '"name": "'+ ass.Account.Name +'"'+
                '}'+
                ']'));
                
                assetsMaps.put('productSpecification', JSON.deserializeUntyped('{'+
                '"id": "'+ ass.Product2.vlocity_cmt__ProductSpecId__c +'",'+
                '"name": "'+ ass.Product2.vlocity_cmt__ProductSpecName__c +'"'+
                '}'));
                assetsMaps.put('productOffering', JSON.deserializeUntyped('{'+
                '"id": "'+ ass.Product2Id +'",'+
                '"name": "'+ ass.Product2.Name +'",'+
                '"productSubType": "'+ ass.Product2.vlocity_cmt__SubType__c +'",'+
                '"productType": "'+ ass.Product2.vlocity_cmt__Type__c +'",'+
                '"productFamily": "'+ ass.ProductFamily +'",'+
                '"productCode": "'+ ass.ProductCode +'"'+
                '}'));
                assetsMaps.put('place', JSON.deserializeUntyped('{'+
                '"placeDetails":{'+
                '"city": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_ServiceMiniCity__c +'",'+
                '"daneCode": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_ServiceDaneCode__c +'",'+
                '"shortAddress": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_ServiceShortAddress__c +'",'+
                '"municipality": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_ServiceMunicipality__c +'",'+
                '"merId": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_SerciveMerId__c +'",'+
                '"state": "'+ ass.vlocity_cmt__ServiceAccountId__r.FVU_ServiceState__c +'"'+
                '}'+
                '}'));

                String isSeeAllData = String.isNotEmpty(variableAttrs.get('isSeeAll')) ? variableAttrs.get('isSeeAll') : 'false';

                if (ass.vlocity_cmt__AttributeSelectedValues__c != null) {
                    Map<String, Object> mapListJSOn = (Map<String, Object>) JSON.deserializeUntyped( (String) ass.vlocity_cmt__AttributeSelectedValues__c );
                   
                    if(!isSeeAllData.contains('true')){

                        String isAttrFlag = String.isNotEmpty(variableAttrs.get('attrFlag')) ? variableAttrs.get('attrFlag') : 'true'; 
                        
                        for (String key : mapListJSOn.keySet()) {
                            for (vlocity_cmt__attribute__c attrObj : attrListObject) {
                                Map<String, Object> mapJsonAtt = new Map<String, Object>();
                                if (attrObj.vlocity_cmt__Code__c == key) {
                                    String valueData = String.valueOf(mapListJSOn.get(key));
                                    if(isAttrFlag.contains('true')){

                                        if(valueData != 'false'){
                                            mapJsonAtt.put('value', valueData);
                                            mapJsonAtt.put('name', attrObj.Name);
                                            mapJsonAtt.put('attr', key);
                                            mapJsonAtt.put('category', attrObj.vlocity_cmt__AttributeCategoryName__c);
                                            ((List<Map<String, Object>>)assetsMaps.get('productCharacteristic')).add(mapJsonAtt);     
                                        }  
                                    }else if(valueData == isAttrFlag){
                                            mapJsonAtt.put('value', valueData);
                                            mapJsonAtt.put('name', attrObj.Name);
                                            mapJsonAtt.put('attr', key);
                                            mapJsonAtt.put('category', attrObj.vlocity_cmt__AttributeCategoryName__c);
                                            ((List<Map<String, Object>>)assetsMaps.get('productCharacteristic')).add(mapJsonAtt);     
                                    }   
                                    
                                }
                            }
                        }
                    }else{
                        for (String key : mapListJSOn.keySet()) {
                            for (vlocity_cmt__attribute__c attrObj : attrListObject) {
                                Map<String, Object> mapJsonAtt = new Map<String, Object>();
                                if (attrObj.vlocity_cmt__Code__c == key) {
                                    String valueData = String.valueOf(mapListJSOn.get(key));
                                        mapJsonAtt.put('value', valueData);
                                        mapJsonAtt.put('name', attrObj.Name);
                                        mapJsonAtt.put('attr', key);
                                        mapJsonAtt.put('category', attrObj.vlocity_cmt__AttributeCategoryName__c);
                                        ((List<Map<String, Object>>)assetsMaps.get('productCharacteristic')).add(mapJsonAtt);     
                                }
                            }
                        }
                    }
                }

                ((List<Map<String, Object>>)respMap.get('Assets')).add(assetsMaps); 
                
                assetsMaps.put('productPrice', getProductPrice(ass));
        }


        return respMap;
    }

    private static List<Map<String,Object>> getProductPrice(Asset ass){

        List<Map<String,Object>> productPriceList =  new List<Map<String,Object>>();
            String paymenMethod = ass.vlocity_cmt__CurrencyPaymentMode__c != null && ass.vlocity_cmt__CurrencyPaymentMode__c == 'Currency' ? 'Contado' : ass.vlocity_cmt__CurrencyPaymentMode__c;

            Decimal oneTimeTotalIncTaxes = ass.FVU_EffectiveOneTimeTotalIncTaxes__c != null ? ass.FVU_EffectiveOneTimeTotalIncTaxes__c : 0;
            Decimal oneTimeTotal = ass.vlocity_cmt__OneTimeTotal__c != null ? ass.vlocity_cmt__OneTimeTotal__c : 0;
            Decimal recurringTotalIncTaxes = ass.FVU_RecurringTotalIncTaxes__c != null ? ass.FVU_RecurringTotalIncTaxes__c : 0;
            Decimal recurringTotal = ass.vlocity_cmt__RecurringTotal__c != null ? ass.vlocity_cmt__RecurringTotal__c : 0;


            Decimal oneTimeTax =  oneTimeTotalIncTaxes - oneTimeTotal;
            Decimal oneTimeTaxValue = oneTimeTax < 0 ? 0 : oneTimeTax;
            
            Decimal totalRecurringTax =  recurringTotalIncTaxes - recurringTotal;
            Decimal totalRecurringTaxValue = totalRecurringTax < 0 ? 0 : totalRecurringTax;

            //One time
            Map<String, Object> productPriceMap0 = new Map<String, Object>();
            Map<String, Object> priceMap1 = new Map<String, Object>();
            Map<String, Object> priceMap2 = new Map<String, Object>();

            productPriceMap0.put('unitOfMeasure', 'COP');
            productPriceMap0.put('priceType', 'One-time');
            productPriceMap0.put('paymentMethod', paymenMethod) ;
            productPriceMap0.put('name', 'AmountTotal');
            productPriceMap0.put('description', 'Total amount with Tax');

            priceMap2.put('value', oneTimeTotalIncTaxes);
            priceMap2.put('unit', 'COP');
            priceMap1.put('price', priceMap2);
            productPriceMap0.put('price', priceMap1);

            productPriceList.add(productPriceMap0);
            
            Map<String, Object> productPriceMap1 = new Map<String, Object>();
            Map<String, Object> priceMap11 = new Map<String, Object>();
            Map<String, Object> priceMap12 = new Map<String, Object>();
            
            productPriceMap1.put('unitOfMeasure', 'COP');
            productPriceMap1.put('priceType', 'One-time');
            productPriceMap1.put('paymentMethod', paymenMethod);
            productPriceMap1.put('name', 'AmountWithoutTax');
            productPriceMap1.put('description', 'Total amount without Tax');
            
            priceMap12.put('value', oneTimeTotal);
            priceMap12.put('unit', 'COP');
            priceMap11.put('price', priceMap12);
            productPriceMap1.put('price', priceMap11);
            productPriceList.add(productPriceMap1);
            
            Map<String, Object> productPriceMap2 = new Map<String, Object>();
            Map<String, Object> priceMap111 = new Map<String, Object>();
            Map<String, Object> priceMap112 = new Map<String, Object>();
            
            productPriceMap2.put('unitOfMeasure', 'COP');
            productPriceMap2.put('priceType', 'One-time');
            productPriceMap2.put('paymentMethod', paymenMethod);
            productPriceMap2.put('name', 'Tax');
            productPriceMap2.put('description', 'Tax amount');
            
            priceMap112.put('value', oneTimeTaxValue);
            priceMap112.put('unit', 'COP');
            priceMap111.put('price', priceMap112);
            productPriceMap2.put('price', priceMap111);
            productPriceList.add(productPriceMap2);
            
            // Recurring
            Map<String, Object> productPriceMap3 = new Map<String, Object>();
            Map<String, Object> priceMapChild1 = new Map<String, Object>();
            Map<String, Object> priceMapN1 = new Map<String, Object>();

            productPriceMap3.put('unitOfMeasure', 'COP');
            productPriceMap3.put('priceType', 'Recurring');
            productPriceMap3.put('paymentMethod', paymenMethod);
            productPriceMap3.put('name', 'AmountTotal');
            productPriceMap3.put('description', 'Total amount with Tax');

            priceMapN1.put('value', recurringTotalIncTaxes);
            priceMapN1.put('unit', 'COP');
            priceMapChild1.put('price', priceMapN1);
            productPriceMap3.put('price', priceMapChild1);

            productPriceList.add(productPriceMap3);
            
            Map<String, Object> productPriceMap4 = new Map<String, Object>();
            Map<String, Object> priceMapChild2 = new Map<String, Object>();
            Map<String, Object> priceMapN2 = new Map<String, Object>();
            
            productPriceMap4.put('unitOfMeasure', 'COP');
            productPriceMap4.put('priceType', 'Recurring');
            productPriceMap4.put('paymentMethod', paymenMethod);
            productPriceMap4.put('name', 'AmountWithoutTax');
            productPriceMap4.put('description', 'Total amount without Tax');
            
            priceMapN2.put('value', recurringTotal);
            priceMapN2.put('unit', 'COP');
            priceMapChild2.put('price', priceMapN2);
            productPriceMap4.put('price', priceMapChild2);
            productPriceList.add(productPriceMap4);
            
            Map<String, Object> productPriceMap5 = new Map<String, Object>();
            Map<String, Object> priceMapChild3 = new Map<String, Object>();
            Map<String, Object> priceMapN3 = new Map<String, Object>();
            
            productPriceMap5.put('unitOfMeasure', 'COP');
            productPriceMap5.put('priceType', 'Recurring');
            productPriceMap5.put('paymentMethod', paymenMethod);
            productPriceMap5.put('name', 'Tax');
            productPriceMap5.put('description', 'Tax amount');
            
            priceMapN3.put('value', totalRecurringTaxValue);
            priceMapN3.put('unit', 'COP');
            priceMapChild3.put('price', priceMapN3);
            productPriceMap5.put('price', priceMapChild3);
            productPriceList.add(productPriceMap5);

        return productPriceList;
    }

  public static List<Map<String,Object>> getFilterList( List<Object> obj, String fieldsCompare) {
    
    List<Map<String, Object>> listMap = new List<Map<String, Object>>();
    List<Map<String, Object>> listOut = new List<Map<String, Object>>();
    List<String> list2Inputs = fieldsCompare.split(',');
    System.debug(obj + ' obj');
    for (Object instance : obj ){
      listMap.add((Map<String, Object>) instance);
    }

    for (Map<String,Object> itm : listMap) {
        Map<String, Object> mapOut = new Map<String, Object>();
        for (String compare : list2Inputs) {
            mapOut.put(compare, itm.get(compare));
        }
        listOut.add(mapOut);
    }

    return listOut;

  }

  private static List<Asset> getAddOns(List<Asset> assts, String queryFields){
    
        List<Asset> assetsReliesOn = new List<Asset>();
        List<Asset> assetsFinalList = new List<Asset>();
        String idUnique = '';

        String[] fields = queryFields.split('WHERE');
        String queryNew = fields[0];

        Set<String> reliesOnId = new Set<String>();
        
        try {
            for (Asset ass : assts) {
                if(ass.vlocity_cmt__AssetReferenceId__c != null && ass.vlocity_cmt__RootItemId__c != null){
                    if(ass.vlocity_cmt__AssetReferenceId__c == ass.vlocity_cmt__RootItemId__c && ass.vlocity_cmt__ParentItemId__c == null && ass.vlocity_cmt__ReliesOnItemId__c == null){
                        reliesOnId.add(ass.vlocity_cmt__RootItemId__c);
                    }
                }
            }

            if(reliesOnId.size() > 0){
                queryNew += 'WHERE vlocity_cmt__ReliesOnItemId__c IN (' + '\''+ String.escapeSingleQuotes( String.join(reliesOnId, ',') ) + '\')';
                assetsReliesOn = Database.query(queryNew);
            }
            
            if(assetsReliesOn.size() > 0 ){
                assts.addAll(assetsReliesOn);

                for (Asset ass : assts) {
                    System.debug(ass.Id);
                    
                    if( !idUnique.contains(ass.Id) ){
                        assetsFinalList.add(ass);
                        idUnique = ass.Id;
                    }
                }
            }else{
               assetsFinalList = assts; 
            }


        } catch (Exception e ) {
            System.debug('ERROR ' + e.getMessage() + ' -- ' +e.getCause() + ' -- ' +e.getLineNumber());
            return new List<Asset>();
        }

        return assetsFinalList;

  }



}