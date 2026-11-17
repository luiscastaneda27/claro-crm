import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfPVUPromociones extends FlexCardMixin(LightningElement){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};
        @api set cfAssetReference(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["AssetReference"] = val;
          }
        } get cfAssetReference() {
          return this._sessionApiVars["AssetReference"] || "";
        }
      
        @api set cfAssetStatus(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["AssetStatus"] = val;
          }
        } get cfAssetStatus() {
          return this._sessionApiVars["AssetStatus"] || "";
        }
      
        @api set cfAccountId(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["AccountId"] = val;
          }
        } get cfAccountId() {
          return this._sessionApiVars["AccountId"] || "";
        }
      
        @api set cfAssetId(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["AssetId"] = val;
          }
        } get cfAssetId() {
          return this._sessionApiVars["AssetId"] || "";
        }
      
        @api set cfIsAdditionServicesActive(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["IsAdditionServicesActive"] = val;
          }
        } get cfIsAdditionServicesActive() {
          return this._sessionApiVars["IsAdditionServicesActive"] || "false";
        }
      
        @api set cfIsAssigneUser(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["IsAssigneUser"] = val;
          }
        } get cfIsAssigneUser() {
          return this._sessionApiVars["IsAssigneUser"] || "false";
        }
      
        @api set cfIsAccessProcess(val) {
          if(typeof val !== "undefined") {
            this._sessionApiVars["IsAccessProcess"] = val;
          }
        } get cfIsAccessProcess() {
          return this._sessionApiVars["IsAccessProcess"] || "false";
        }
      
              
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
              }

              unregisterEvents(){
                
              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }