global with sharing class PVU_AzureADRegistrationHandler implements Auth.RegistrationHandler {

    global Boolean canCreateUser(Auth.UserData data) {
        System.debug('PVU_AzureADRegistrationHandler.canCreateUser: ' + data);
        return true;
    }

    global User createUser(Id portalId, Auth.UserData data) {
        User u = findActiveUserByEmail(data.email);
        if (u != null) {
            System.debug('PVU_AzureADRegistrationHandler.createUser - usuario encontrado: ' + u.Id);
        }
        return u;
    }

    global Id getUserId(Auth.UserData data) {
        System.debug('PVU_AzureADRegistrationHandler.getUserId - email: ' + data.email);
        User u = findActiveUserByEmail(data.email);
        if (u == null) {
            System.debug(LoggingLevel.WARN, 'PVU_AzureADRegistrationHandler.getUserId - no se encontró usuario activo para: ' + data.email);
            return null;
        }
        System.debug('PVU_AzureADRegistrationHandler.getUserId - usuario encontrado: ' + u.Id);
        return u.Id;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
    }

    private User findActiveUserByEmail(String email) {
        List<User> users = [
            SELECT Id FROM User
            WHERE Email = :email AND IsActive = true
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        return users.isEmpty() ? null : users[0];
    }
}