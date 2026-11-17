public class FVU_ValidateStatusOrder_SCH implements Schedulable {
    public void execute (SchedulableContext sc) {
        FVU_ValidateStatusOrder_BCH borrarRegistros2 = new FVU_ValidateStatusOrder_BCH();
        Database.executeBatch(borrarRegistros2,100);       
    }
}