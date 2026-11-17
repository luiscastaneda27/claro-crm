/*--------------------------------------------------------------------------
Author:         Hever Salas
Company:        Salesforce.com
Description:    
Code Coverage:  100%
History
<Date>            <Author>             <Description>                                    		<Version>
2024-06-10      Hever Salas  Utility class to update attributes AdminCharge in JSON        		 1.0.0
----------------------------------------------------------------------------*/
public class OM_UpdateValuesAdminCharge {
    public Map<String, Object> updateValuesAdminCharge(String ipInput){

        Map<String, Object> jsonAdminCharge = (Map<String, Object>)JSON.deserializeuntyped(ipInput);
        List<Object> orderItemsNew = new List<Object>();
        List<Object> orderItems = (List<Object>)jsonAdminCharge.get('orderItems');

        for(Object item : orderItems){
            List<Object> attrsNew = new List<Object>();
            List<Object> attrs = new List<Object>();
            Map<String,Object> itemMap = new Map<String,Object>();
            Map<String,Object> itemMapInterno = new Map<String,Object>();
            itemMap = (Map<String,Object>)item;
            itemMapInterno = (Map<String,Object>)itemMap.get('item');
            
            if(itemMapInterno.get('action') == OrderIntegrationSystemInterfaceConstants.ACTION_ADMIN_CHARGE){
                attrs = (List<Object>)itemMapInterno.get('attrs');
                for(Object itemAttrs :attrs){
                    Map<String,Object> attrsMap = new Map<String,Object>();
                    attrsMap = (Map<String,Object>)itemAttrs;
                    List<Object> valueNew = (List<object>)attrsMap.get('value');
                    attrsMap.put('value', (String)valueNew[0]);
                    attrsNew.add(attrsMap);
                }
                itemMapInterno.put('attrs', attrsNew);
                itemMap.put('item', itemMapInterno);
            }
            orderItemsNew.add((Object)itemMap);
        }

        jsonAdminCharge.put('orderItems', orderItemsNew);

        return jsonAdminCharge;
    }
}