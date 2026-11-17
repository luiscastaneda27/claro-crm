global class FIN_ScheduleDeleteQuotes implements Schedulable {
    
    public static String CRON_JOB = '0 59 23 * * ?';
    
    global void execute(SchedulableContext sc) {
        
        FIN_BatchDeleteQuotes batch = new FIN_BatchDeleteQuotes(); 
        Database.executeBatch(batch, 1000);
        
    }
    
}