import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';

export default class Fin_BotonSimular extends OmniscriptBaseMixin (LightningElement) {

    @api label;

    connectedCallBack(){
        console.log('loaded omniscript custom lwc');
        console.log(`current OS Data => ${JSON.stringify(this.omniJsonData)}`);
    }

    handleClick(){
        let myData = {"StepInfoSimulacion" : {"LWCPreSim" : { "selectedPlazo":{"EnableSimulation":""}}}}
            
        this.omniApplyCallResp(myData);
        this.omniNextStep();
    }
}