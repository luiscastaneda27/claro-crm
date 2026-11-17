import { LightningElement , api} from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin'
import { getNamespaceDotNotation } from 'vlocity_cmt/omniscriptInternalUtils'
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';


const actions = [
    { label: 'Pago no abonado financiación', name: 'pago_no_abonado',cellAttributes: {
        style: { fieldName: 'buttonStyle' },
    } },
    { label: 'Ajuste de crédito', name: 'ajustes'}

];

const columns = [
    { label: 'Número de crédito', fieldName: 'financingCode',hideDefaultActions: 'true',initialWidth : 150, type:'button',typeAttributes:{ label :{fieldName : 'financingCode'}, name:'urlredirect', variant:'base'}},
    { label: 'Tasa', fieldName: 'interestRate',hideDefaultActions: 'true',initialWidth : 80,type:'button', typeAttributes:{ label :{fieldName : 'interestRate'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    },},
    { label: 'Serial', fieldName: 'equipmentRef1', hideDefaultActions: 'true',initialWidth : 150 ,type:'button', typeAttributes:{ label :{fieldName : 'equipmentRef1'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    },},
    { label: 'Referencia de Producto', fieldName: 'equipmentReference',hideDefaultActions: 'true',initialWidth : 200, type:'button', typeAttributes:{ label :{fieldName : 'equipmentReference'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    },},
    { label: 'Fecha de Creación', fieldName: 'initialDate',hideDefaultActions: 'true',initialWidth : 150, type:'button', typeAttributes:{ label :{fieldName : 'initialDate'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    },},
    { label: 'Estado Crédito', fieldName: 'summary',hideDefaultActions: 'true',initialWidth : 245, type:'button', typeAttributes:{ label :{fieldName : 'summary'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    }, },
    { label: 'Saldo a la fecha', fieldName: 'currentOpentAmount',hideDefaultActions: 'true',initialWidth : 150, type:'currency', typeAttributes:{ label :{fieldName : 'currentOpentAmount'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
   }, },
    { label: 'Saldo a favor', fieldName: 'currentBalance',hideDefaultActions: 'true',initialWidth : 150, type: 'currency',typeAttributes:{ label :{fieldName : 'currentBalance'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    }, },
    { label: 'Número de Línea', fieldName: 'numerolinea',hideDefaultActions: 'true',initialWidth : 200, type: 'button',typeAttributes:{ label :{fieldName : 'numerolinea'}, name:'urlredirect', variant:'base'},
    cellAttributes: {
        style: { fieldName: 'customStyle' },
    }, },    
    {
        type: 'action',
        initialWidth : 150,
        typeAttributes: { rowActions: actions, menuLabel: 'Gestionar', menuAignment:'left',name: 'gestionar',
            variant: 'neutral',},
        cellAttributes: {
            class: { fieldName: 'custom-neutral-button' },
            style: { fieldName: 'buttonStyle' },
        },
    }

];

export default class Fin_DatatableWithRowActions extends NavigationMixin(OmniscriptBaseMixin(
    LightningElement,
  ))  {
    _ns = getNamespaceDotNotation()
    data = [];
    columns = columns;
    record = {};
    title = '';
    message = 'No es posible realizar la gestión de pagos no abonados, ya que no existe una venta que cumpla con los criterios.';
    messageAjustes = 'No es posible realizar el ajuste de crédito, ya que no existe una venta que cumpla con los criterios.';
    variant = 'warning';
    showMessage = true;
    spinner = true
    @api recordId

    connectedCallback() {
        this.creditFinancing();
    }

    showErrorMessage(codeMessage){
        try {
            const input = {codeMessage};
            const params = {
                input: JSON.stringify(input),
                sClassName: 'IntegrationProcedureService', 
                sMethodName: "FIN_IPGetMessages",
                options: "{}",
            };   
            this.omniRemoteCall(params, false)
                .then((response) => {
                let message = response.result.IPResult.message.MainMessage;
                this.showToast(message);
                })
                .catch((error) => {
                    console.error("Error en omniRemoteCall:", error);
                });
        } catch (error) {
            console.error("Error en getData:", error);
        }
    }
        
    showToast(message, title = '', variant = 'warning'){
        const event = new ShowToastEvent({
            title: title, 
            message: message, 
            mode: 'sticky',
            variant: variant,
        });
        this.dispatchEvent(event);
    }
        
    handleRowAction(event) {
        const currentRowData = this.data.find (currentItem => {
            return currentItem.financingCode === event.detail. row.financingCode
        }) ;

        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'urlredirect':
                this.handleNavigateToOmniscript(row);
                break;
            case 'pago_no_abonado':
                if(currentRowData.NegacionContratoAprobada === true) {
                    this. showErrorMessage( 'PVU011');
                    return
                }
                if(currentRowData.userProfile === 'Read Only' || currentRowData.userProfile === '') {
                    this. showErrorMessage( 'PVU015');
                    break;
                }
                this.handleNavigateToOmniscriptPagoNoAbonado(row);
                break;
            case 'ajustes':
                if(currentRowData.NegacionContratoAprobada === true) {
                    this. showErrorMessage( 'PVU011');
                    return
                }
                if(currentRowData.userProfile === 'Read Only' || currentRowData.userProfile === '') {
                    this. showErrorMessage( 'PVU015');
                    break;
                }
                this.handleNavigateToOmniscriptAjustes(row);
                break;
            default:
        }
    }

    deleteRow(row) {
        const { id } = row;
        const index = this.findRowIndexById(id);
        if (index !== -1) {
            this.data = this.data
                .slice(0, index)
                .concat(this.data.slice(index + 1));
        }
    }

    findRowIndexById(id) {
        let ret = -1;
        this.data.some((row, index) => {
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }

    creditFinancing(){
          try{
            const input = {
                "accountId": this.recordId
            };
            const params = {
                input: JSON.stringify(input),
                sClassName: `IntegrationProcedureService`,
                sMethodName: "FIN_FIN_ConsultaFinanciacion",
                options: "{}",
            };
            console.log('input params',params);
            this.omniRemoteCall(params, false)

                .then((response) => {
                    //Si existe un error en cualquiera de las integraciones, muestra mensaje de error
                    console.log(response.result.IPResult.success);
                    if (response.result.IPResult.success == false) {
                      this.data = [];
                      this.spinner = false;
                      this.message = response.result.IPResult.paramMensaje || "Ha ocurrido un error, intente más tarde";
                      this.showBanner = true
                      this.showMessage = false;
                      return;
                                   }
                //Si hay un sólo registro en el objeto, evalúa la condición para poder mostrar un sólo registro en la tabla.
                if (response.result.IPResult.length == undefined || response.result.IPResult.mensaje !='No existen financiamientos relacionados al cliente') {
                   // let financingData = response.result.IPResult.financing;
                   let financingData = response.result.IPResult.financing.filter(item => item.financingCode);

                    //this.data = this.formatDataAsPercentage(financingData);
                    this.data = financingData.map(item => ({
                        ...item,
                        interestRate: item.interestRate !== undefined ? item.interestRate + '%' : item.interestRate,
                        currentBalance: parseFloat(item.currentBalance) >= 0 ? '0' : item.currentBalance,
                        currentOpentAmount: item.currentOpentAmount  ? Number( item.currentOpentAmount.toString().replace(/\./g, '').replace(',', '.')) : 0
                    }));

                    console.log("PLE: ",JSON.stringify(this.data))
                    let dataCopy = JSON.parse(JSON.stringify(this.data));
                    dataCopy.forEach(currentItem => {
                    currentItem.customStyle = "--sds-c-button-text-color: black; --slds-c-button-text-color-hover: black;"
                })
                    this.data = dataCopy
                    console.log("DATATABLE:", JSON.stringify(this.data))
                    this.showBanner = false
                    this.showMessage = false
                    this.spinner= false
                }else{
                    this.data=[]
                    this.spinner= false
                    this.message="No existen financiamientos relacionados al cliente"
                    this.showMessage = true;
                }


                })
                .catch((error) => {
                window.console.log(error, "error");
                this.spinner = false;
                });
          } catch (error) {
            console.log("Error en getData ", error);
            this.spinner = false;
            this.showMessage = true;
          }
        }

    handleClickRow(){
        const evt = new ShowToastEvent({
            title: this.title,
            message: this.message,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
    }

    handleNavigateToOmniscript(row) {
        const code = row.financingCode
        const omniBaseUrl = '/lightning/cmp/vlocity_cmt__vlocityLWCOmniWrapper';
        const params = {
            c__target: 'c:fINOSFinanciamientoDetailEnglish',
            c__layout: 'lightning',
            c__tabIcon: 'custom:custom18',
            c__tabLabel: 'Detalle Financiamiento',
            c__ContextId: code, // Usa recordId dinámico si es necesario
            c__AccountId: this.recordId,

        };
            // Construye la URL con parámetros dinámicos
            const urlParams = new URLSearchParams(params).toString();
            const fullUrl = `${omniBaseUrl}?${urlParams}`;

            // Redirige al Omniscript
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                        url: fullUrl,
                },
            });
    }

    // Método para formatear datos
    formatDataAsPercentage(data) {
        return data.map(item => {
        if (item.interestRate !== undefined) {
        // Convertir el interestRate a porcentaje formateado
        item.interestRate = item.interestRate + '%';
    }
        return item;
    });
    }


    handleNavigateToOmniscriptPagoNoAbonado(row){
        if (row.isActive) {
            const code = row.financingCode
            const equipReference = row.equipmentReference
            const equipRef = row.equipmentRef1
            const omniBaseUrl = '/lightning/cmp/vlocity_cmt__vlocityLWCOmniWrapper';
            const params = {
            c__target: 'c:fINPagosNoAbonadosFinanciacionEnglish',
            c__layout: 'lightning',
            c__tabIcon: 'utility:money',
            c__tabLabel: 'Pagos no abonados Financiación',
            c__ContextId: this.recordId, // Usa recordId dinámico si es necesario
            c__creditNumber: code,
            c__serial: equipRef,
            c__equipmentReference: equipReference
        };

        // Construye la URL con parámetros dinámicos
        const urlParams = new URLSearchParams(params).toString();
        const fullUrl = `${omniBaseUrl}?${urlParams}`;

        // Redirige al Omniscript
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: fullUrl,
            },
        });
        }else{
            const evt = new ShowToastEvent({
                title: this.title,
                message: this.message,
                variant: this.variant,
            });
            this.dispatchEvent(evt);
        }

    }

    handleNavigateToOmniscriptAjustes(row){
        if (row.isActive) {
            const code = row.financingCode
            const equipReference = row.equipmentReference
            const equipRef = row.equipmentRef1
            const tasa = parseFloat(row.interestRate)
            const omniBaseUrl = '/lightning/cmp/vlocity_cmt__vlocityLWCOmniWrapper';
            const params = {
            c__target: 'c:fINAjusteDeCreditoFinanciacionEnglish',
            c__layout: 'lightning',
            c__tabIcon: 'utility:money',
            c__tabLabel: 'Ajuste de crédito',
            c__ContextId: this.recordId, // Usa recordId dinámico si es necesario
            c__creditNumber: code,
            c__equipmentReference: equipReference,
            c__serial: equipRef,
            c__tasa: tasa
        };

        // Construye la URL con parámetros dinámicos
        const urlParams = new URLSearchParams(params).toString();
        const fullUrl = `${omniBaseUrl}?${urlParams}`;

        // Redirige al Omniscript
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: fullUrl,
            },
        });
        }else{
            const evt = new ShowToastEvent({
                title: this.title,
                message: this.messageAjustes,
                variant: this.variant,
            });
            this.dispatchEvent(evt);
        }

    }
}