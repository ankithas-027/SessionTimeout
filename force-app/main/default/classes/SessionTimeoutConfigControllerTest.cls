@IsTest
private class SessionTimeoutConfigControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test custom setting
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Name = 'Test Setting',
            SetupOwnerId = UserInfo.getProfileId(),
            Inactivity_Timeout__c = 20,
            Logout_Countdown__c = 3,
            Show_Countdown__c = false,
            Modal_Title__c = 'Custom Setting Timeout',
            Modal_Message__c = 'Custom setting message',
            Continue_Button_Label__c = 'Stay',
            Logout_Button_Label__c = 'Exit',
            Modal_Header_Color__c = '#000000',
            Modal_Body_Color__c = '#CCCCCC',
            Modal_Footer_Color__c = '#000000',
            Continue_Button_Color__c = '#00FF00',
            Logout_Button_Color__c = '#0000FF',
            Countdown_Color__c = '#FFFF00',
            Modal_Width__c = '600px',
            Modal_Border_Radius__c = '8px',
            Post_Timeout_Action__c = 'redirect',
            Redirect_URL__c = 'https://example.com',
            Logo_URL__c = 'https://example.com/logo.png'
        );
        insert testSetting;
    }

    // Helper method to create metadata config
    private static Session_Timeout_Config__mdt createMetadataConfig(Integer priority, Boolean isActive, String postTimeoutAction, String redirectUrl) {
        return new Session_Timeout_Config__mdt(
            Label = 'Test Metadata',
            DeveloperName = 'Test_Metadata_' + priority,
            Is_Active__c = isActive,
            Priority__c = priority,
            Inactivity_Timeout__c = 15,
            Logout_Countdown__c = 2,
            Show_Countdown__c = true,
            Modal_Title__c = 'Metadata Timeout',
            Modal_Message__c = 'Metadata message',
            Continue_Button_Label__c = 'Keep Going',
            Logout_Button_Label__c = 'Sign Out',
            Modal_Header_Color__c = '#111111',
            Modal_Body_Color__c = '#222222',
            Modal_Footer_Color__c = '#111111',
            Continue_Button_Color__c = '#00AA00',
            Logout_Button_Color__c = '#AA0000',
            Countdown_Color__c = '#FFAA00',
            Modal_Width__c = '400px',
            Modal_Border_Radius__c = '2px',
            Post_Timeout_Action__c = postTimeoutAction,
            Redirect_URL__c = redirectUrl,
            Logo_URL__c = 'https://example.com/meta_logo.png'
        );
    }

    @IsTest
    static void testFetchTimeoutConfigWithCustomSetting() {
        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(20000, result.timeoutSettings.inactivityTimeout, 'Inactivity timeout should match custom setting');
        System.assertEquals('Custom Setting Timeout', result.modalContent.modalTitle, 'Modal title should match custom setting');
        System.assertEquals('redirect', result.actionSettings.postTimeoutAction, 'Post timeout action should match custom setting');
        System.assertEquals('https://example.com/logo.png', result.logoUrl, 'Logo URL should match');
    }

    @IsTest
    static void testFetchTimeoutConfigWithMetadata() {
        // Delete custom setting to force fallback to metadata
        delete [SELECT Id FROM SessionTimeoutSettings__c WHERE SetupOwnerId = :UserInfo.getProfileId()];

        Session_Timeout_Config__mdt testMetadata = createMetadataConfig(1, true, 'logout', null);

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = testMetadata;

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(15000, result.timeoutSettings.inactivityTimeout, 'Inactivity timeout should match test metadata');
        System.assertEquals('Metadata Timeout', result.modalContent.modalTitle, 'Modal title should match test metadata');
        System.assertEquals('logout', result.actionSettings.postTimeoutAction, 'Post timeout action should match test metadata');
        System.assertEquals(1, result.timeoutSettings.priority, 'Priority should match metadata');
        System.assertEquals(true, result.timeoutSettings.isActive, 'IsActive should match metadata');
    }

    @IsTest
    static void testFetchTimeoutConfigWithNoActiveConfig() {
        // Delete custom setting
        delete [SELECT Id FROM SessionTimeoutSettings__c WHERE SetupOwnerId = :UserInfo.getProfileId()];

        // Set test config to simulate no active metadata config
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.error = 'No active configuration found';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Configuration error: No active configuration found', e.getMessage(), 'Expected error message not found');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFetchTimeoutConfigWithInvalidRedirect() {
        // Update existing setting to make it invalid
        SessionTimeoutSettings__c existingSetting = [
            SELECT Id, Post_Timeout_Action__c, Redirect_URL__c
            FROM SessionTimeoutSettings__c
            WHERE SetupOwnerId = :UserInfo.getProfileId()
            LIMIT 1
        ];

        existingSetting.Post_Timeout_Action__c = 'redirect';
        existingSetting.Redirect_URL__c = null;
        update existingSetting;

        Test.startTest();
        try {
            SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Redirect URL required for redirect action'), 'Expected redirect validation error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFetchTimeoutConfigWithDuplicatePriorities() {
        // Set test config to simulate duplicate priorities
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.error = 'Duplicate priority 1 in Config1 and Config2';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Configuration error: Duplicate priority 1 in Config1 and Config2', e.getMessage(), 'Expected priority error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetActiveMetadataConfigSuccess() {
        Session_Timeout_Config__mdt testMetadata = createMetadataConfig(1, true, 'logout', null);

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = testMetadata;

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(15000, result.timeoutSettings.inactivityTimeout, 'Should return configured timeout value');
        System.assertEquals('logout', result.actionSettings.postTimeoutAction, 'Should return configured action');
    }

    @IsTest
    static void testSessionTimeoutConfigDTOConstructorWithMetadata() {
        Session_Timeout_Config__mdt testMetadata = createMetadataConfig(1, true, 'logout', null);

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testMetadata);
        Test.stopTest();

        System.assertEquals(15000, dto.timeoutSettings.inactivityTimeout, 'Inactivity timeout should match');
        System.assertEquals('Metadata Timeout', dto.modalContent.modalTitle, 'Modal title should match');
        System.assertEquals('#111111', dto.modalStyle.modalHeaderColor, 'Modal header color should match');
        System.assertEquals('logout', dto.actionSettings.postTimeoutAction, 'Post timeout action should match');
        System.assertEquals('https://example.com/meta_logo.png', dto.logoUrl, 'Logo URL should match');
    }

    @IsTest
    static void testSessionTimeoutConfigDTOConstructorWithCustomSetting() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Inactivity_Timeout__c = 15,
            Logout_Countdown__c = 3,
            Show_Countdown__c = false,
            Modal_Title__c = 'Setting Title',
            Modal_Message__c = 'Setting Message',
            Continue_Button_Label__c = 'Stay',
            Logout_Button_Label__c = 'Leave',
            Modal_Header_Color__c = '#111111',
            Modal_Body_Color__c = '#222222',
            Modal_Footer_Color__c = '#111111',
            Continue_Button_Color__c = '#00FF00',
            Logout_Button_Color__c = '#FF0000',
            Countdown_Color__c = '#FFFF00',
            Modal_Width__c = '600px',
            Modal_Border_Radius__c = '8px',
            Post_Timeout_Action__c = 'redirect',
            Redirect_URL__c = 'https://example.com',
            Logo_URL__c = 'https://setting.com/logo.png'
        );

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testSetting);
        Test.stopTest();

        System.assertEquals(15000, dto.timeoutSettings.inactivityTimeout, 'Inactivity timeout should match');
        System.assertEquals('Setting Title', dto.modalContent.modalTitle, 'Modal title should match');
        System.assertEquals('#111111', dto.modalStyle.modalHeaderColor, 'Modal header color should match');
        System.assertEquals('redirect', dto.actionSettings.postTimeoutAction, 'Post timeout action should match');
        System.assertEquals('https://setting.com/logo.png', dto.logoUrl, 'Logo URL should match');
        System.assertEquals(null, dto.timeoutSettings.priority, 'Priority should be null for custom settings');
        System.assertEquals(true, dto.timeoutSettings.isActive, 'isActive should default to true');
    }

    @IsTest
    static void testActionSettingsWithInvalidAction() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Post_Timeout_Action__c = 'invalid',
            Redirect_URL__c = null
        );

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testSetting);
        Test.stopTest();

        System.assertEquals('logout', dto.actionSettings.postTimeoutAction, 'Invalid action should default to logout');
    }

@IsTest
static void testActionSettingsWithRedirectAction_UsingCMDT() {
    // Delete custom setting to force fallback to metadata
    delete [SELECT Id FROM SessionTimeoutSettings__c WHERE SetupOwnerId = :UserInfo.getProfileId()];

    // Use a relative path URL that will pass validation
    String testRedirectUrl = '/lightning/page/home';

    // Create metadata config with uppercase REDIRECT and valid relative URL
    Session_Timeout_Config__mdt testMetadata = createMetadataConfig(
        1,                     // priority
        true,                  // isActive
        'REDIRECT',            // postTimeoutAction (case insensitive)
        testRedirectUrl        // redirect URL that will pass validation
    );

    // Inject test metadata into controller
    SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
    wrapper.config = testMetadata;
    SessionTimeoutConfigController.testConfig = wrapper;

    Test.startTest();
    SessionTimeoutConfigDTO dto = SessionTimeoutConfigController.fetchTimeoutConfig();
    Test.stopTest();

    System.assertNotEquals(null, dto, 'DTO should not be null');
    System.assertNotEquals(null, dto.actionSettings, 'Action settings should not be null');
    System.assertEquals('redirect', dto.actionSettings.postTimeoutAction, 'Action should be normalized to lowercase');
    System.assertEquals(testRedirectUrl, dto.actionSettings.redirectUrl, 'Redirect URL should match CMDT');
}

    @IsTest
    static void testFetchTimeoutConfigWithNoConfigAvailable() {
        // Ensure no custom settings
        delete [SELECT Id FROM SessionTimeoutSettings__c WHERE SetupOwnerId = :UserInfo.getProfileId()];

        // Simulate no metadata available
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = null;
        wrapper.error = 'No metadata config available';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No metadata config available'), 'Expected missing config error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testPriorityHandlingInMetadata() {
        // Create two metadata records with different priorities
        Session_Timeout_Config__mdt highPriority = createMetadataConfig(10, true, 'logout', null);
        Session_Timeout_Config__mdt lowPriority = createMetadataConfig(5, true, 'redirect', 'https://example.com');

        // Simulate controller returning highest priority
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = highPriority;

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertEquals(10, result.timeoutSettings.priority, 'Should select highest priority config');
        System.assertEquals(15000, result.timeoutSettings.inactivityTimeout, 'Should use high priority config');
    }

    @IsTest
    static void testInactiveMetadataConfig() {
        Session_Timeout_Config__mdt testMetadata = createMetadataConfig(1, false, 'logout', null);

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = testMetadata;
        wrapper.error = 'No active configuration found';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No active configuration found'), 'Should skip inactive config');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFallbackToOrgDefaultSetting() {
        // Delete profile-specific setting
        delete [SELECT Id FROM SessionTimeoutSettings__c WHERE SetupOwnerId = :UserInfo.getProfileId()];

        // Create org default setting
        SessionTimeoutSettings__c orgSetting = new SessionTimeoutSettings__c(
            Name = 'Org Default',
            Inactivity_Timeout__c = 25,
            Logout_Countdown__c = 5,
            Show_Countdown__c = true,
            Post_Timeout_Action__c = 'redirect',
            Redirect_URL__c = 'https://org-default.com'
        );
        insert orgSetting;

        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertEquals(25000, result.timeoutSettings.inactivityTimeout, 'Should use org default setting');
        System.assertEquals('redirect', result.actionSettings.postTimeoutAction, 'Should use org default action');
    }

    @IsTest
    static void testAllInnerClassesInitialized() {
        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result.timeoutSettings, 'TimeoutSettings should be initialized');
        System.assertNotEquals(null, result.modalContent, 'ModalContent should be initialized');
        System.assertNotEquals(null, result.modalStyle, 'ModalStyle should be initialized');
        System.assertNotEquals(null, result.actionSettings, 'ActionSettings should be initialized');
    }

    @IsTest
    static void testMultipleActiveMetadataConfigs() {
        // Simulate multiple active configs with different priorities
        Session_Timeout_Config__mdt config1 = createMetadataConfig(5, true, 'logout', null);
        Session_Timeout_Config__mdt config2 = createMetadataConfig(10, true, 'redirect', 'https://example.com');

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = config2; // Higher priority should be selected

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertEquals(10, result.timeoutSettings.priority, 'Should select highest priority config');
        System.assertEquals('redirect', result.actionSettings.postTimeoutAction, 'Should use high priority action');
    }

    @IsTest
    static void testGetLiveConfigurationError() {
        // Force an error by making the query return no results
        delete [SELECT Id FROM SessionTimeoutSettings__c];

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.error = 'Simulated error';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Simulated error'), 'Expected error message not found');
        }
        Test.stopTest();
    }

    @IsTest
    static void testActionSettingsCaseSensitivity() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Post_Timeout_Action__c = 'REDIRECT',
            Redirect_URL__c = 'https://test.com'
        );

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testSetting);
        Test.stopTest();

        System.assertEquals('redirect', dto.actionSettings.postTimeoutAction, 'Should normalize to lowercase');
    }

    @IsTest
    static void testActionSettingsDefaults() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Post_Timeout_Action__c = null,
            Redirect_URL__c = null
        );

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testSetting);
        Test.stopTest();

        System.assertEquals('logout', dto.actionSettings.postTimeoutAction, 'Should default to logout');
        System.assertEquals(null, dto.actionSettings.redirectUrl, 'Redirect URL should be null');
    }

    @IsTest
    static void testFetchTimeoutConfigWithOrgDefaultSetting() {
        // Delete existing settings
        delete [SELECT Id FROM SessionTimeoutSettings__c];

        // Create org default setting
        SessionTimeoutSettings__c orgSetting = new SessionTimeoutSettings__c(
            Name = 'Org Default',
            Inactivity_Timeout__c = 40,
            Post_Timeout_Action__c = 'redirect',
            Redirect_URL__c = 'https://org-default.com'
        );
        insert orgSetting;

        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertEquals(40000, result.timeoutSettings.inactivityTimeout, 'Should use org default setting');
        System.assertEquals('redirect', result.actionSettings.postTimeoutAction, 'Should use org default action');
    }

    @IsTest
    static void testActionSettingsEmptyString() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Post_Timeout_Action__c = '',
            Redirect_URL__c = '',
            Show_Countdown__c = true,
            Inactivity_Timeout__c = 30
        );

        Test.startTest();
        SessionTimeoutConfigDTO dto = new SessionTimeoutConfigDTO(testSetting);
        Test.stopTest();

        System.assertEquals('logout', dto.actionSettings.postTimeoutAction);
        System.assertEquals(null, dto.actionSettings.redirectUrl);
    }

    @IsTest
    static void testFetchTimeoutConfigWithNullValues() {
        // Get and update the existing profile setting instead of creating new
        SessionTimeoutSettings__c existingSetting = [
            SELECT Id FROM SessionTimeoutSettings__c
            WHERE SetupOwnerId = :UserInfo.getProfileId()
            LIMIT 1
        ];
        existingSetting.Inactivity_Timeout__c = null;
        existingSetting.Logout_Countdown__c = null;
        update existingSetting;

        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result.timeoutSettings.inactivityTimeout);
        System.assertNotEquals(null, result.timeoutSettings.logoutCountdown);
    }

    @IsTest
    static void testFetchTimeoutConfigWithNoSettings() {
        // Delete all settings to test the no-configuration scenario
        delete [SELECT Id FROM SessionTimeoutSettings__c];

        // Simulate no metadata available
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.error = 'No configuration found';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No configuration found'), 'Expected error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFetchTimeoutConfigWithDuplicatePrioritiesThroughPublicInterface() {
        // Simulate duplicate priority error
        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.error = 'Duplicate priority found';

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        try {
            SessionTimeoutConfigController.fetchTimeoutConfig();
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Duplicate priority'), 'Expected priority error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFetchTimeoutConfigWithDefaultValues() {
        // Delete all settings to test default values in DTO
        delete [SELECT Id FROM SessionTimeoutSettings__c];

        // Create minimal valid metadata config
        Session_Timeout_Config__mdt testMetadata = new Session_Timeout_Config__mdt(
            Label = 'Minimal Config',
            DeveloperName = 'Minimal_Config',
            Is_Active__c = true,
            Priority__c = 1,
            Inactivity_Timeout__c = 15,
            Show_Countdown__c = true
        );

        SessionTimeoutConfigController.TestConfigWrapper wrapper = new SessionTimeoutConfigController.TestConfigWrapper();
        wrapper.config = testMetadata;

        Test.startTest();
        SessionTimeoutConfigController.testConfig = wrapper;
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertEquals(15000, result.timeoutSettings.inactivityTimeout, 'Should use default timeout');
        System.assertEquals(true, result.timeoutSettings.isActive, 'Should be active');
        System.assertNotEquals(null, result.modalContent, 'Modal content should be initialized');
        System.assertNotEquals(null, result.modalStyle, 'Modal style should be initialized');
    }

    @IsTest
    static void testFetchTimeoutConfigWithAllNullValuesInSetting() {
        SessionTimeoutSettings__c testSetting = new SessionTimeoutSettings__c(
            Show_Countdown__c = true
        );

        Test.startTest();
        SessionTimeoutConfigDTO result = SessionTimeoutConfigController.fetchTimeoutConfig();
        Test.stopTest();

        System.assertNotEquals(null, result.timeoutSettings.inactivityTimeout);
        System.assertNotEquals(null, result.timeoutSettings.logoutCountdown);
    }
}