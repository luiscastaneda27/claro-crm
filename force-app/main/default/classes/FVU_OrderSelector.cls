/**
 * The FVU_OrderSelector class provides methods to retrieve order data from Salesforce.
 */
public with sharing class FVU_OrderSelector {

    public FVU_OrderSelector() {}

   // Retrieves order information for the Id Claro application based on the provided Order Id.
   public Order getOrderIdClaroData(String orderId) {
    List<Order> orderList = [
        SELECT Id, FVU_DeliveryData__c
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
    ];

    return (orderList.isEmpty()) ? null : orderList[0];
}
}