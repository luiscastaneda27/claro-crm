/*--------------------------------------------------------------------------------------------------------
Author:         Hever Salas  - hever.salas@nespon.com
Company:        Nespon
Description:    Clase Test de OM_DeactivateAssets
Code Coverage:  96%
History
<Date>         <Author>          	<Description>             												<Version>
20-03-2025   Hever Salas     	HDU-531956 - PV - [CESION] Plan de orquestación CESION      					1.0
24-09-2025   Hever Salas     	HDU-635832 - [MEJORAS OM] Actualizacion reason code cesion de contrato     		2.0
-----------------------------------------------------------------------------------------------------------*/
@isTest
global without sharing class OM_DeactivateAssetsTest {

    @isTest static void executeDeactivateAssets(){
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        Asset activo = new Asset(vlocity_cmt__AssetReferenceId__c = 'testHever', Name = 'AssetHever', AccountId = testAccount.Id);
        INSERT activo;
        
        testOrder.PVU_CaseInfo__c = '{"cedenteCustomerAccount":"'+testAccount.Id+'","cedenteAssetId":"'+activo.Id+'","fechaInicioSusp":"2025-03-24","fechaFinSusp":"2025-03-24","Id":"50079000004Xn4PAAS"}';
        UPDATE testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];

        OM_DeactivateAssets deactivateAssets = new OM_DeactivateAssets();  
        Try{
            Test.startTest();
            deactivateAssets.executeBatch(itemsLst);
            Test.stopTest();
        }catch(Exception ex){
            system.debug('ex'+ex);
            System.assertEquals('Error al desactivar los assets. descripcion:Error', ex.getMessage());
        }
    }
    
    @isTest static void executeDeactivateAssetsFailed(){
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        Asset activo = new Asset(vlocity_cmt__AssetReferenceId__c = 'testHever', Name = 'AssetHever', AccountId = testAccount.Id);
        INSERT activo;
        
        testOrder.PVU_CaseInfo__c = '{"causalDesactivacionCedente":"Des Proteccion Comercial","cedenteAssetId":"'+activo.Id+'","fechaInicioSusp":"2025-03-24","fechaFinSusp":"2025-03-24","Id":"50079000004Xn4PAAS"}';
        UPDATE testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];

        OM_DeactivateAssets deactivateAssets = new OM_DeactivateAssets();  
        Try{
            Test.startTest();
            deactivateAssets.executeBatch(itemsLst);
            Test.stopTest();
        }catch(Exception ex){
            system.debug('ex'+ex);
            System.assertEquals('Error al desactivar los assets. descripcion:Error', ex.getMessage());
        }
        
    }
    
    @isTest static void executeDeactivateAssetsFailed2(){
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Order testOrder = new Order(AccountId = testAccount.Id, status = 'Draft', EffectiveDate= Date.today() );
        insert testOrder;
        
        Asset activo = new Asset(vlocity_cmt__AssetReferenceId__c = 'testHever', Name = 'AssetHever', AccountId = testAccount.Id);
        INSERT activo;
        
        testOrder.PVU_CaseInfo__c = '{"causalDesactivacionCedente":"Des Proteccion Comercial","cedenteAssetId":"","fechaInicioSusp":"2025-03-24","fechaFinSusp":"2025-03-24","Id":"50079000004Xn4PAAS"}';
        UPDATE testOrder;
        
        vlocity_cmt__OrchestrationPlan__c testOrchestrationPlan = new vlocity_cmt__OrchestrationPlan__c(vlocity_cmt__OrderId__c = testOrder.Id);
        insert testOrchestrationPlan;
        
        vlocity_cmt__OrchestrationItem__c testOrchestrationItem = new vlocity_cmt__OrchestrationItem__c(vlocity_cmt__OrchestrationPlanId__c = testOrchestrationPlan.Id);
        insert testOrchestrationItem;
        
        List<vlocity_cmt__OrchestrationItem__c> itemsLst = [SELECT id,
                                                                vlocity_cmt__OrchestrationPlanId__r.vlocity_cmt__OrderId__c  
                                                                FROM vlocity_cmt__OrchestrationItem__c];

        OM_DeactivateAssets deactivateAssets = new OM_DeactivateAssets();  
        Try{
            Test.startTest();
            deactivateAssets.executeBatch(itemsLst);
            Test.stopTest();
        }catch(Exception ex){
            system.debug('ex'+ex);
            System.assertEquals('Error al desactivar los assets. descripcion:Falta el valor cedenteAssetId en el campo PVU_CaseInfo__c', ex.getMessage());
        }
        
    }
}