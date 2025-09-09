/**
 * @description Data Transfer Object for session timeout configuration.
 * Supports values from both Custom Metadata (Session_Timeout_Config__mdt)
 * and Hierarchy Custom Setting (SessionTimeoutSettings__c).
 */
public with sharing class SessionTimeoutConfigDTO {
    @AuraEnabled public TimeoutSettings timeoutSettings;
    @AuraEnabled public ModalContent modalContent;
    @AuraEnabled public ModalStyle modalStyle;
    @AuraEnabled public ActionSettings actionSettings;
    @AuraEnabled public String logoUrl;
    @AuraEnabled public String logoImage;

    /**
     * @description Constructor for Custom Metadata Type configuration
     * @param config Session_Timeout_Config__mdt record containing configuration data
     */
    public SessionTimeoutConfigDTO(Session_Timeout_Config__mdt config) {
        this.timeoutSettings = new TimeoutSettings(config);
        this.modalContent   = new ModalContent(config);
        this.modalStyle     = new ModalStyle(config);
        this.actionSettings = new ActionSettings(config);
        this.logoUrl   = validateLogoUrl(config.Logo_URL__c);
        this.logoImage = validateLogoUrl(config.Logo_URL__c);
    }

    /**
     * @description Constructor for Hierarchy Custom Setting configuration
     * @param config SessionTimeoutSettings__c record containing configuration data
     */
    public SessionTimeoutConfigDTO(SessionTimeoutSettings__c config) {
        this.timeoutSettings = new TimeoutSettings(config);
        this.modalContent   = new ModalContent(config);
        this.modalStyle     = new ModalStyle(config);
        this.actionSettings = new ActionSettings(config);
        this.logoUrl   = validateLogoUrl(config.Logo_URL__c);
        this.logoImage = validateLogoUrl(config.Logo_URL__c);
    }

     /**
     * @description Inner class representing timeout-related settings
     */
    public class TimeoutSettings {
        @AuraEnabled public Integer inactivityTimeout; // ms
        @AuraEnabled public Integer logoutCountdown;   // ms
        @AuraEnabled public Boolean showCountdown;
        @AuraEnabled public Integer priority;
        @AuraEnabled public Boolean isActive;

        /**
         * @description Constructor using CMDT configuration
         * @param config Session_Timeout_Config__mdt record
         */
        public TimeoutSettings(Session_Timeout_Config__mdt config) {
            this.inactivityTimeout = (config.Inactivity_Timeout__c == null) ? null : (Integer)(config.Inactivity_Timeout__c * 1000);
            this.logoutCountdown   = (config.Logout_Countdown__c == null) ? null : (Integer)(config.Logout_Countdown__c * 1000);
            this.showCountdown     = config.Show_Countdown__c;
            this.priority          = (Integer) config.Priority__c;
            this.isActive          = config.Is_Active__c;
        }

        /**
         * @description Constructor using Hierarchy Custom Setting configuration
         * @param config SessionTimeoutSettings__c record
         */
        public TimeoutSettings(SessionTimeoutSettings__c config) {
            this.inactivityTimeout = (config.Inactivity_Timeout__c == null) ? null : (Integer)(config.Inactivity_Timeout__c * 1000);
            this.logoutCountdown   = (config.Logout_Countdown__c == null) ? null : (Integer)(config.Logout_Countdown__c * 1000);
            this.showCountdown     = config.Show_Countdown__c;
            this.priority          = null;
            this.isActive          = true;
        }
    }

    /**
     * @description Inner class representing modal content configuration
     */
    public class ModalContent {
        @AuraEnabled public String modalTitle;
        @AuraEnabled public String modalMessage;
        @AuraEnabled public String continueButtonLabel;
        @AuraEnabled public String logoutButtonLabel;

        /**
         * @description Constructor using CMDT configuration
         * @param config Session_Timeout_Config__mdt record
         */
        public ModalContent(Session_Timeout_Config__mdt config) {
            this.modalTitle           = config.Modal_Title__c;
            this.modalMessage         = config.Modal_Message__c;
            this.continueButtonLabel  = config.Continue_Button_Label__c;
            this.logoutButtonLabel    = config.Logout_Button_Label__c;
        }

        /**
         * @description Constructor using Hierarchy Custom Setting configuration
         * @param config SessionTimeoutSettings__c record
         */
        public ModalContent(SessionTimeoutSettings__c config) {
            this.modalTitle           = config.Modal_Title__c;
            this.modalMessage         = config.Modal_Message__c;
            this.continueButtonLabel  = config.Continue_Button_Label__c;
            this.logoutButtonLabel    = config.Logout_Button_Label__c;
        }
    }

    /**
     * @description Inner class representing modal styling configuration
     */
    public class ModalStyle {
        @AuraEnabled public String modalHeaderColor;
        @AuraEnabled public String modalBodyColor;
        @AuraEnabled public String modalFooterColor;
        @AuraEnabled public String continueButtonColor;
        @AuraEnabled public String logoutButtonColor;
        @AuraEnabled public String countdownColor;
        @AuraEnabled public String modalWidth;
        @AuraEnabled public String modalBorderRadius;

        /**
         * @description Constructor using CMDT configuration
         * @param config Session_Timeout_Config__mdt record
         */
        public ModalStyle(Session_Timeout_Config__mdt config) {
            this.modalHeaderColor    = config.Modal_Header_Color__c;
            this.modalBodyColor      = config.Modal_Body_Color__c;
            this.modalFooterColor    = config.Modal_Footer_Color__c;
            this.continueButtonColor = config.Continue_Button_Color__c;
            this.logoutButtonColor   = config.Logout_Button_Color__c;
            this.countdownColor      = config.Countdown_Color__c;
            this.modalWidth          = config.Modal_Width__c;
            this.modalBorderRadius   = config.Modal_Border_Radius__c;
        }

        /**
         * @description Constructor using Hierarchy Custom Setting configuration
         * @param config SessionTimeoutSettings__c record
         */
        public ModalStyle(SessionTimeoutSettings__c config) {
            this.modalHeaderColor    = config.Modal_Header_Color__c;
            this.modalBodyColor      = config.Modal_Body_Color__c;
            this.modalFooterColor    = config.Modal_Footer_Color__c;
            this.continueButtonColor = config.Continue_Button_Color__c;
            this.logoutButtonColor   = config.Logout_Button_Color__c;
            this.countdownColor      = config.Countdown_Color__c;
            this.modalWidth          = config.Modal_Width__c;
            this.modalBorderRadius   = config.Modal_Border_Radius__c;
        }
    }

    /**
     * @description Inner class representing action settings configuration
     */
    public class ActionSettings {
        @AuraEnabled public String postTimeoutAction;
        @AuraEnabled public String redirectUrl;

        /**
         * @description Constructor using CMDT configuration
         * @param config Session_Timeout_Config__mdt record
         */
        public ActionSettings(Session_Timeout_Config__mdt config) {
            this.postTimeoutAction = validateAction(config.Post_Timeout_Action__c);
            this.redirectUrl       = validateRedirectUrl(config.Redirect_URL__c, this.postTimeoutAction);
        }

        /**
         * @description Constructor using Hierarchy Custom Setting configuration
         * @param config SessionTimeoutSettings__c record
         */
        public ActionSettings(SessionTimeoutSettings__c config) {
            String action = (config.Post_Timeout_Action__c == null)
                ? 'logout'
                : config.Post_Timeout_Action__c.trim().toLowerCase();
            Set<String> validActions = new Set<String>{ 'logout', 'redirect' };
            this.postTimeoutAction = validActions.contains(action) ? action : 'logout';
            this.redirectUrl       = validateRedirectUrl(config.Redirect_URL__c, this.postTimeoutAction);
        }
    }

    
/**
 * Validates and normalizes the logo URL.
 * Blocks "javascript:" and "data:" schemes for XSS safety.
 * Allows relative paths and HTTPS external URLs for branding.
 * Returns a safe URL string or null if invalid.
 */

   private static String validateLogoUrl(String url) {
    if (String.isBlank(url)) {
        return null;
    }

    String lower = url.trim().toLowerCase();

    // Block obvious dangerous schemes
    if (lower.startsWith('javascript:') || lower.startsWith('data:')) {
        return null;
    }

    // Allow relative paths (safe within Salesforce)
    if (lower.startsWith('/')) {
        return url;
    }

    // Allow any HTTPS absolute URL (for logos/images)
    if (lower.startsWith('https://')) {
        return url;
    }

    // Block everything else
    return null;
}


    /**
     * @description Validates and normalizes the post-timeout action value
     * @param action The configured action value (e.g., "logout", "redirect")
     * @return The normalized action ("logout" or "redirect")
     */
    private static String validateAction(String action) {
        if (String.isBlank(action)) {
                return 'logout';
            }
        String normalized = action.trim().toLowerCase();
        return (new Set<String>{ 'logout', 'redirect' }).contains(normalized) ? normalized : 'logout';
    }

    /**
     * @description Validates the redirect URL against Salesforce domains,
     * CSP Trusted Sites, CMDT allowlist, and Custom Settings
     * @param url The redirect URL to validate
     * @param action The post-timeout action (only checked if "redirect")
     * @return The valid redirect URL, or null if invalid
     */
    public static String validateRedirectUrl(String url, String action) {
        if (action != 'redirect' || String.isBlank(url)) {
            return null;
        }

        // 1. Relative path check
        if (url.startsWith('/')) {
            return url;
        }

        try {
            Url parsedUrl = new Url(url);
            String host = parsedUrl.getHost().toLowerCase();

            if (isSalesforceDomain(host)) {
                return url;
            }
            if (isInTrustedSites(url)) {
                return url;
            }
            if (isInCmdtAllowlist(url)) {
                return url;
            }
            if (isInCustomSettings(url)) {
                return url;
            }
        } catch (Exception e) {

            return null;
        }

        return null;
    }

    /**
     * @description Checks if the given host is a Salesforce-owned domain
     * @param host The hostname to check
     * @return Boolean indicating if the host is a Salesforce domain
     */
private static Boolean isSalesforceDomain(String host) {
    return host.endsWith('.salesforce.com') ||
           host.endsWith('.force.com') ||
           host.endsWith('.site.com') ||
           host.endsWith('.lightning.force.com') ||
           host.endsWith('.salesforce-sites.com');
}

    /**
     * @description Checks if the URL is in CSP Trusted Sites
     * @param url The URL to check
     * @return Boolean indicating if the URL is in trusted sites
     */
private static Boolean isInTrustedSites(String url) {
    if (!Schema.sObjectType.CspTrustedSite.isQueryable()) {
            return false;
        }
    for (CspTrustedSite site :
         [SELECT EndpointUrl FROM CspTrustedSite WHERE EndpointUrl != null LIMIT 200 ]) {
        if (url.startsWith(site.EndpointUrl)) {
            return true;
        }
    }
    return false;
}

    /**
     * @description Checks if the URL is in CMDT allowlist
     * @param url The URL to check
     * @return Boolean indicating if the URL is in CMDT allowlist
     */
private static Boolean isInCmdtAllowlist(String url) {
    if (!Schema.sObjectType.Session_Timeout_Config__mdt.isAccessible()) {
        return false;
    }
    for (Session_Timeout_Config__mdt mdt :
         [SELECT Redirect_URL__c FROM Session_Timeout_Config__mdt
          WHERE Redirect_URL__c != null LIMIT 200]) {
        if (url.startsWith(mdt.Redirect_URL__c)) {
            return true;
        }
    }
    return false;
}

    /**
     * @description Checks if the URL is in Custom Settings
     * @param url The URL to check
     * @return Boolean indicating if the URL is in custom settings
     */
private static Boolean isInCustomSettings(String url) {
    if (!Schema.sObjectType.SessionTimeoutSettings__c.isAccessible()) {
    return false;
    }
    SessionTimeoutSettings__c cs = SessionTimeoutSettings__c.getInstance();
    return (cs != null && !String.isBlank(cs.Redirect_URL__c) && url.startsWith(cs.Redirect_URL__c));
}

}