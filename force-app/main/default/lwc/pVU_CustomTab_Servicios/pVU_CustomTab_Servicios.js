/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @Descripción              : 
 * @Cobertura de Código      : 
 * @Ultima modificación en   : 01-27-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   01-21-2025   SALESFORCE   Initial Version
**/
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, track } from 'lwc';



export default class PVU_CustomTab_Servicios extends OmniscriptBaseMixin(LightningElement) {

@api statusAsset;
@api recordId;
@track showSpinner = false;

assetList = [];

    connectedCallback() {
        this.callServices();
    }
    
    callServices(){ 
        this.showSpinner = true; 
        const options = {
            chainable: true, //Use chainable when an Integration Procedure exceeds the Salesforce CPU Governor limit.
            //useFuture: true, 
        };      
        const input = {
            ContextId: this.recordId,
            status: this.statusAsset,           
            componentName: 'PVU_CustomTab_Servicios'          
        };       
        const params = {
            input: JSON.stringify(input),
            sClassName: 'vlocity_cmt.IntegrationProcedureService',
            sMethodName: 'PVU_GetAssetByAccountId', 
            options: JSON.stringify(options),
        };
        this.omniRemoteCall(params, true).then(response => {
            this.showSpinner = false;            
            let data = response.result.IPResult;
            this.assetList = data.AssetsList;
            this.isAssignUser = data.isAssigneUser;

        }).catch(error => {
            window.console.log(error, 'error');
        });
    }
    
}