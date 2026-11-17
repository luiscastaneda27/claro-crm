global class FVU_CloseAbandonedOrdersSchedule implements Schedulable {
    
    public static String CRON_JOB = '0 59 23 * * ?';
    
    global void execute(SchedulableContext sc) {
        
        FVU_CloseAbandonedOrdersBatch batch = new FVU_CloseAbandonedOrdersBatch(); 
        Database.executeBatch(batch, 50);
        
    }
    
}