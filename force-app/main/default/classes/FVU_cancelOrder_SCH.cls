public class FVU_cancelOrder_SCH implements Schedulable {
    public void execute (SchedulableContext sc) {
        FVU_cancelOrder_BCH validarEstado = new FVU_cancelOrder_BCH();
        Database.executeBatch(validarEstado, 30);
    }
}