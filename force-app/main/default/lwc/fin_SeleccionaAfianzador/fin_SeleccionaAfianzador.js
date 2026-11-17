/**
 * @description       : JS que muestra los afianzadores de disponibles en OS simulacion detallada por Fianza.
 * @author            : rodrigo.olivera@nespon.com
 * @group             :
 * @last modified on  : 17-11-2025
 * @last modified by  : rodrigo.olivera@nespon.com
 **/
import { LightningElement, track, api } from 'lwc';
import { getDataHandler } from 'vlocity_cmt/utility';
import { OmniscriptBaseMixin } from "vlocity_cmt/omniscriptBaseMixin";

export default class Fin_SeleccionaAfianzador extends OmniscriptBaseMixin(LightningElement) {
   
    _inicialvoluntaria;
    _monthlyterm;
 
    @api channel = '';
    @api financingamount = '';
    @api clienttype = '';
    @api producttype = '';
    @api citydanecode = '';
    @api messageinfo = this.messageinfo;
    @track sureties = [];
    @track response;
    @track error;
    @track isLoading = false;
    @track showLWC = false; 
    @track showContainer = true;
    @track selectedSurety = '';
    @track optionType = 'claro';
    @track urlFIN038 = '';
    @track messageFIN039 = '';
    @track messageFIN040 = '';
    @track messageFIN042 = '';
    @track suretiesAvailable = null;

    _phone;
    @api
    get phone() {
        return this._phone;
    }
    set phone(value) {
        this._phone = value !== null && value !== undefined ? String(value).trim() : '';
        
    }

    @api
    get inicialvoluntaria() {
        return this._inicialvoluntaria;
    }
    set inicialvoluntaria(value) {
        const changed = value !== this._inicialvoluntaria;
        this._inicialvoluntaria = value;

        if (changed) {
            this.resetSureties();
        }
    }
    @api
    get monthlyterm() {
        return this._monthlyterm;
    }
    set monthlyterm(value) {
        const changed = value !== this._monthlyterm;
        this._monthlyterm = value;

        if (!changed) return;

        this.resetSureties();
    }

    get parsedMessage() {
        if (!this.messageinfo) return [];

        return this.messageinfo
            .split('\n')       
            .map(line => line.trim())
            .filter(line => line.length > 0);
    }

    get showClientSection() {
         return this.optionType === 'cliente';
    }

    connectedCallback() {
        this._monthlyterm = null;
        this.resetSureties();
        this.loadMessages(); 
        this.response = null;
    }

    resetSureties() {
        this.sureties = [];
        this.showLWC = false;
        this.selectedSurety = '';
        this.error = null;
        this.showContainer = true;
        this.sureties = '' ;
        this.optionType = 'claro';

        this.omniApplyCallResp({
            selectedSurety: null,
            selectedSuretyBoolean: false,
            responseSuccess: '',
            selectedSuretyData: null,
            optionType: 'claro'
        });
    }

    async loadMessageByCode(code) {
    try {
        const params = {
            input: JSON.stringify({ codeMessage: code }),
            sClassName: 'IntegrationProcedureService',
            sMethodName: 'FIN_IPGetMessages',
            options: '{}'
        };

        const response = await this.omniRemoteCall(params, false);
        return response?.result?.IPResult?.message?.MainMessage || '';
        } catch (error) {
            console.error(`Error consultando FIN_IPGetMessages (${code}):`, error);
            return '';
        }
    }

    async loadMessages() {
    this.urlFIN038 = await this.loadMessageByCode('FIN038');
    this.messageFIN039 = await this.loadMessageByCode('FIN039');
    this.messageFIN040 = await this.loadMessageByCode('FIN040');
    this.messageFIN042 = await this.loadMessageByCode('FIN042');

        this.omniApplyCallResp({
            messageFIN038: this.urlFIN038,
            messageFIN039: this.messageFIN039,
            messageFIN040: this.messageFIN040,
            messageFIN042: this.messageFIN042
        });
    }

    async sendSMSLink(messageFIN042, phone) {
        try {

            const params = {
                input: JSON.stringify({ smsMessage: messageFIN042, smsPhone: phone }),
                sClassName: 'IntegrationProcedureService',
                sMethodName: 'PVU_NotificationSMS',
                options: '{}'
            };

            const response = await this.omniRemoteCall(params, false);

            this.omniApplyCallResp({
                lastSMSResponse: response
            });

            return response?.value?.data?.message || '';
        } catch (error) {
            console.error('Error consultando PUV_NotificationSMS:', error);
            return '';
        }
    }


    async handleSendSMS() {
        this.isLoading = true;
        try {
            await this.loadMessages();
            await this.sendSMSLink(this.messageFIN042, this.phone);
        } catch (error) {
            console.error('Error enviando SMS:', error);
        } finally {
            this.isLoading = false;
        }
    }


    async handleCallIP() {
        this.isLoading = true;
        this.error = null;
        this.response = null;
        this.selectedSurety = '';
        this.showLWC = false;

        const inputMap = {
            productType: this.producttype,
            clientType: this.clienttype,
            financingAmount: this.financingamount,
            monthlyTerm: this.monthlyterm,
            channel: this.channel,
            cityDaneCode: this.citydanecode
        };
        
        await this.loadMessages();

        try {
            const vipRes = {
                type: 'IntegrationProcedure',
                value: {
                    ipMethod: 'FIN_MSBusInteAskSurCrlogs',
                    inputMap: inputMap,
                    optionsMap: '{}'
                }
            };

            const response = await getDataHandler(vipRes);
            const parsedResponse = typeof response === 'string' ? JSON.parse(response) : response;

            this.response = parsedResponse;
            this.sureties = (parsedResponse?.IPResult?.sureties || []).map(s => {
                return {
                    ...s,
                    suretyQuoteValueFormatted: this.formatCurrency(s.suretyQuoteValue),
                    suretyTotalAmountFormatted: this.formatCurrency(s.suretyTotalAmount)
                };
            });

            this.showLWC = this.sureties.length > 0;

            if (this.sureties.length > 0) {
                this.selectFirstSurety();
            }
            
            this.suretiesAvailable = this.sureties.length > 0 ? true : false;


            this.omniApplyCallResp({
                response: this.response,
                suretiesAvailable: this.suretiesAvailable,
                responseSuccess: this.response?.IPResult?.success
            });
             

        } catch (err) {
            this.error = err?.message || JSON.stringify(err);
        } finally {
            this.isLoading = false;
        }
    }

    

    handleChange(event) {
        this.selectedSurety = event.target.value;

        const data = this.sureties.find(s => s.suretyInitials === this.selectedSurety);

        this.omniApplyCallResp({
            selectedSurety: null,
            selectedSuretyData: null
        });

        this.omniApplyCallResp({
            optionType: this.optionType,
            selectedSurety: this.selectedSurety,
            selectedSuretyData: data,
            response: this.response,
            suretiesAvailable: this.sureties.length > 0
        });
    }

    handleMainOptionChange(event) {
        this.optionType = event.detail.value;

        if (this.optionType === 'claro') {

        this.omniApplyCallResp({
            selectedSurety: null,
            selectedSuretyData: null
        });

        this.selectedSurety = '';

        if (this.sureties.length > 0) {
            this.selectFirstSurety();
        }

        } else if (this.optionType === 'cliente') {

            this.omniApplyCallResp({
                selectedSurety: null,
                selectedSuretyData: null,
                selectedSuretyBoolean: false
            });

            this.selectedSurety = '';
            this.template.querySelectorAll('input[name="afianzador"]').forEach(r => (r.checked = false));
        }

        this.omniApplyCallResp({
            optionType: this.optionType,
            selectedSurety: this.selectedSurety
        });
    }

    handlePhoneChange(event) {
        this.phone = event.target.value;
    }

    selectFirstSurety() {
    if (this.sureties.length === 0) return;

    // Setea el valor por defecto
    this.selectedSurety = this.sureties[0].suretyInitials;

    const data = this.sureties.find(s => s.suretyInitials === this.selectedSurety);

    requestAnimationFrame(() => {
        const firstRadio = this.template.querySelector(
            `input[value="${this.selectedSurety}"]`
        );
        if (firstRadio) firstRadio.checked = true;
    });

    this.omniApplyCallResp({
        optionType: this.optionType,
        selectedSurety: this.selectedSurety,
        selectedSuretyData: data,
        selectedSuretyBoolean: true
    });
}


   get mainOptions() {
        const opcionClaro = { label: 'Ofrecido por Claro (recomendado)', value: 'claro' };
        const opcionCliente = { label: 'Traído por el cliente', value: 'cliente' };
        return [opcionClaro, opcionCliente];
    }

    get showSuretiesList() {
        return this.optionType === 'claro' && this.sureties.length > 0;
    }

    get showConsultButton() {
        const plazoValido = Number(this._monthlyterm) > 0;
        const cuotaValida = Number(this._inicialvoluntaria) > 0;
        const sinAfianzadores = this.sureties.length === 0;

        return sinAfianzadores && (plazoValido || cuotaValida);
    }

    get showMessageNoSurety() {
        return this.showWarningMessage ? false : this.suretiesAvailable == false;
    }

    get showWarningMessage() {
         
        if(this.response?.IPResult?.success === false){
            this.responseSuccess = false;
         }
        return this.responseSuccess === false;
    }

    get isPhoneValid() {
        return this.phone && this.phone.length === 10 && /^\d{10}$/.test(this.phone);
    }

    get disabledSendButton() {
        return this.isLoading || !this.isPhoneValid;
    }

    formatCurrency(value) {
         if (value === null || value === undefined || value === '') return '0';

            const normalized = String(value).replace(',', '.');

            const number = Math.round(Number(normalized));

            if (isNaN(number)) return '0';

            return number.toLocaleString('es-CO');
         }


}