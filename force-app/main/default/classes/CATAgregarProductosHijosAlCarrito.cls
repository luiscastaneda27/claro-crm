/*--------------------------------------------------------------------------
Author:         Juan Mojica - juan.mojica@salesforce.com
Company:        Salesforce.com
Description:    Llamado de IP CPQ_DeleteItemFromCart que permite borrar productos del carrito
Code Coverage:  100%
History
<Date>            <Author>             <Description>             <Version>
06-Abr-25         Juan Mojica                                    version inicial
----------------------------------------------------------------------------*/
public class CATAgregarProductosHijosAlCarrito {
    @InvocableMethod
    public static void agregarProductosHijos(List<List<String>> infoProducto) {
        List<String> informacionProducto = infoProducto[0];
        System.debug('--- informacionProducto: ' + JSON.serialize(informacionProducto)); 

        /* postCartsItems input map:
        {
            "methodName": "postCartsItems",
            "items": [
                {
                    "parentId": "802dl000004grgnAAA", //OrderItem ID del padre -> Escoja SIM Card
                    "parentHierarchyPath": "01tdl000000UtOuAAK<01t8X00000O3McpQAF", //vlocity_cmt__ProductHierarchyPath__c del order item padre -> Escoja SIM Card
                    "itemId": "01u8X00000M1P6CQAV", //Pricebook Entry producto siendo agregado -> eSIM
                    "parentRecord": {
                        "records": [
                            {
        
                                "Pricebook2Id": "01s8X000001xF0nQAE", //Pricebook Entry producto padre -> Escoja SIM Card
                                "productHierarchyPath": "01tdl000000UtOuAAK<01t8X00000O3McpQAF" //vlocity_cmt__ProductHierarchyPath__c del order item padre -> Escoja SIM Card
                            }
                        ]
                    }
                }
            ],
            "cartId": "801dl00000JBd7xAAD", //Id de la orden
            "price": true,
            "validate": true,
            "includeAttachment": false
        }*/

        String idOrden = informacionProducto[0];
        System.debug('--- idOrden: ' + idOrden);
        String idOrderItemPadre = informacionProducto[2];
        System.debug('--- idOrderItemPadre: ' + idOrderItemPadre);
        String hierarchyPathOrderItemPadre = informacionProducto[3];
        System.debug('--- hierarchyPathOrderItemPadre: ' + hierarchyPathOrderItemPadre);
        String priceBookEntryProductoPadre = informacionProducto[4];
        System.debug('--- priceBookEntryProductoPadre: ' + priceBookEntryProductoPadre);
        String priceBookEntryProductoHijo = informacionProducto[5];
        System.debug('--- priceBookEntryProductoHijo: ' + priceBookEntryProductoHijo);

        String nombreIP = 'CPQ_AddChildItems';
        Map<String, Object> ipInput = new Map<String, Object> ();
        Map<String, Object> ipOutput = new Map<String, Object> ();
        Map<String, Object> ipOptions = new Map<String, Object> ();

        List<Map<String, Object>> records = new List<Map<String, Object>>();
        Map<String, Object> record = new Map<String, Object>();
        record.put('Pricebook2Id', priceBookEntryProductoPadre);
        record.put('productHierarchyPath', hierarchyPathOrderItemPadre);
        records.add(record);

        Map<String, Object> parentRecords = new Map<String, Object>();
        parentRecords.put('records', records);

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> item = new Map<String, Object>();
        item.put('parentId', idOrderItemPadre);
        item.put('parentHierarchyPath', hierarchyPathOrderItemPadre);
        item.put('itemId', priceBookEntryProductoHijo);
        item.put('parentRecord', parentRecords);
        items.add(item);

        ipInput.put('methodName', nombreIP);
        ipInput.put('items', items);
        ipInput.put('cartId', idOrden);
        ipInput.put('price', false);
        ipInput.put('validate', false);
        ipInput.put('includeAttachment', false);

        System.debug('--- ipInput: ' + JSON.serialize(ipInput));
        ipOutput = (Map<String, Object>)vlocity_cmt.IntegrationProcedureService.runIntegrationService(nombreIP, ipInput, ipOptions);
        System.debug('--- ipOutput: ' + ipOutput);
    }
}