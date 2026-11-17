@isTest
public class FVU_UserSelectorTest {

    @isTest
    static void testGetUserIdClaroData() {

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'apextestuser@clarosfi.com.co',
            Email = 'apextestuser@example.com',
            Alias = 'test',
            CommunityNickname = 'testuser',
            ProfileId = UserInfo.getProfileId(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert testUser;

        FVU_UserSelector userSelector = new FVU_UserSelector();

        User resultUser = userSelector.getUserIdClaroData(testUser.Id);
        System.assertEquals(testUser.Id, resultUser.Id);
    }
    
}