global class PVU_DeleteFileDataProvidenceBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(
            new PVU_DeleteFileDataProvidence(),
            200
        );
    }
}