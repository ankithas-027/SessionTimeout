/**
 * @description Controller for retrieving session timeout configuration from either
 * custom settings or custom metadata with proper fallback logic and validation.
 */
public with sharing class SessionTimeoutConfigController {

    @TestVisible
    private static TestConfigWrapper testConfig;

    /**
     * @description TestConfigWrapper class
     */
    public class TestConfigWrapper {
        public Session_Timeout_Config__mdt config;
        public String error;
    }

    /**
     * @description Retrieves session timeout configuration
     * @return SessionTimeoutConfigDTO containing configuration
     * @throws AuraHandledException if configuration is invalid or inaccessible
     */
    @AuraEnabled(cacheable=true)
    public static SessionTimeoutConfigDTO fetchTimeoutConfig() {
        try {
            return getConfiguration();
        } catch (Exception e) {
            throw createHandledException('Configuration error: ' + e.getMessage());
        }
    }

    private static SessionTimeoutConfigDTO getConfiguration() {
        if (Test.isRunningTest() && testConfig != null) {
            return handleTestConfiguration();
        }
        return getLiveConfiguration();
    }

    private static SessionTimeoutConfigDTO handleTestConfiguration() {
        if (testConfig.error != null) {
            throw createHandledException(testConfig.error);
        }
        if (testConfig.config == null) {
            throw createHandledException('No test config provided');
        }
        return new SessionTimeoutConfigDTO(testConfig.config);
    }

    private static SessionTimeoutConfigDTO getLiveConfiguration() {
        try {
            // 1) Try Hierarchy Custom Setting (user -> profile -> org)
            SessionTimeoutConfigDTO cs = getCustomSettingConfig();
            if (cs != null && cs.timeoutSettings != null
                && cs.timeoutSettings.inactivityTimeout != null) {
                return cs;
            }

            // 2) Fallback to Custom Metadata
            return getMetadataConfig();

        } catch (Exception e) {
            throw createHandledException('Failed to retrieve configuration: ' + e.getMessage());
        }
    }

    private static SessionTimeoutConfigDTO getCustomSettingConfig() {
        SessionTimeoutSettings__c config = SessionTimeoutSettings__c.getInstance(UserInfo.getUserId());
        config = (config != null) ? config : SessionTimeoutSettings__c.getInstance(UserInfo.getProfileId());
        config = (config != null) ? config : SessionTimeoutSettings__c.getOrgDefaults();
        return (config != null) ? createValidatedConfig(config) : null;
    }

    private static SessionTimeoutConfigDTO createValidatedConfig(SessionTimeoutSettings__c config) {
        validateRedirect(config.Post_Timeout_Action__c, config.Redirect_URL__c);
        return new SessionTimeoutConfigDTO(config);
    }

    private static SessionTimeoutConfigDTO getMetadataConfig() {
        Session_Timeout_Config__mdt config = getActiveMetadataConfig();
        validateRedirect(config.Post_Timeout_Action__c, config.Redirect_URL__c);
        return new SessionTimeoutConfigDTO(config);
    }

    private static Session_Timeout_Config__mdt getActiveMetadataConfig() {
        validatePriorities();
        List<Session_Timeout_Config__mdt> configs = [
            SELECT Inactivity_Timeout__c, Logout_Countdown__c, Show_Countdown__c,
                   Modal_Title__c, Modal_Message__c, Continue_Button_Label__c,
                   Logout_Button_Label__c, Modal_Header_Color__c, Modal_Body_Color__c,
                   Modal_Footer_Color__c, Priority__c, Continue_Button_Color__c,
                   Logout_Button_Color__c, Is_Active__c, Countdown_Color__c, Modal_Width__c,
                   Modal_Border_Radius__c, Post_Timeout_Action__c, Redirect_URL__c, Logo_URL__c, Label
            FROM Session_Timeout_Config__mdt
            WHERE Is_Active__c = true
            WITH USER_MODE
            ORDER BY Priority__c DESC
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw createHandledException('No active configuration found');
        }
        return configs[0];
    }

    private static void validatePriorities() {
        Map<Decimal, String> priorityMap = new Map<Decimal, String>();
        for (Session_Timeout_Config__mdt config : [
            SELECT Priority__c, Label
            FROM Session_Timeout_Config__mdt
            WHERE Is_Active__c = true AND Priority__c != null
            WITH USER_MODE
        ]) {
            if (priorityMap.containsKey(config.Priority__c)) {
                throw createHandledException(
                    'Duplicate priority ' + config.Priority__c +
                    ' in ' + priorityMap.get(config.Priority__c) + ' and ' + config.Label
                );
            }
            priorityMap.put(config.Priority__c, config.Label);
        }
    }

   
        private static void validateRedirect(String action, String url) {
        String normalizedAction = (action == null) ? 'logout' : action.trim().toLowerCase();
        if (normalizedAction == 'redirect') {
            if (String.isBlank(url)) {
                throw createHandledException('Redirect URL required for redirect action');
            }
            if (SessionTimeoutConfigDTO.validateRedirectUrl(url, 'redirect') == null) {
                throw createHandledException('Invalid redirect URL: ' + url);
            }
        }
    }
    
    private static AuraHandledException createHandledException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}