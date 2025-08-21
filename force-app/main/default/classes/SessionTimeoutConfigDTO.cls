/**
 * @description Data Transfer Object for session timeout configuration
 * Contains all settings needed for session timeout functionality
 */
public with sharing class SessionTimeoutConfigDTO {
    @AuraEnabled public TimeoutSettings timeoutSettings;
    @AuraEnabled public ModalContent modalContent;
    @AuraEnabled public ModalStyle modalStyle;
    @AuraEnabled public ActionSettings actionSettings;
    @AuraEnabled public String logoUrl;
    @AuraEnabled public String logoImage;

    /**
     * @description Constructor for custom metadata configuration
     * @param config Session_Timeout_Config__mdt record
     */
    public SessionTimeoutConfigDTO(Session_Timeout_Config__mdt config) {
        this.timeoutSettings = new TimeoutSettings(config);
        this.modalContent = new ModalContent(config);
        this.modalStyle = new ModalStyle(config);
        this.actionSettings = new ActionSettings(config);
        this.logoUrl = config.Logo_URL__c;
        this.logoImage = config.Logo_URL__c;
    }

    /**
     * @description Constructor for custom setting configuration
     * @param config SessionTimeoutSettings__c record
     */
    public SessionTimeoutConfigDTO(SessionTimeoutSettings__c config) {
        this.timeoutSettings = new TimeoutSettings(config);
        this.modalContent = new ModalContent(config);
        this.modalStyle = new ModalStyle(config);
        this.actionSettings = new ActionSettings(config);
        this.logoUrl = config.Logo_URL__c;
        this.logoImage = config.Logo_URL__c;
    }

    /**
     * @description Contains timeout-related settings
     */
    public class TimeoutSettings {
        @AuraEnabled public Integer inactivityTimeout;
        @AuraEnabled public Integer logoutCountdown;
        @AuraEnabled public Boolean showCountdown;
        @AuraEnabled public Integer priority;
        @AuraEnabled public Boolean isActive;

        public TimeoutSettings(Session_Timeout_Config__mdt config) {
            this.inactivityTimeout = (Integer) config.Inactivity_Timeout__c;
            this.logoutCountdown = (Integer) config.Logout_Countdown__c;
            this.showCountdown = config.Show_Countdown__c;
            this.priority = (Integer) config.Priority__c;
            this.isActive = config.Is_Active__c;
        }

        public TimeoutSettings(SessionTimeoutSettings__c config) {
            this.inactivityTimeout = (Integer) config.Inactivity_Timeout__c;
            this.logoutCountdown = (Integer) config.Logout_Countdown__c;
            this.showCountdown = config.Show_Countdown__c;
            this.priority = null;
            this.isActive = true;
        }
    }

    /**
     * @description Contains modal content text
     */
    public class ModalContent {
        @AuraEnabled public String modalTitle;
        @AuraEnabled public String modalMessage;
        @AuraEnabled public String continueButtonLabel;
        @AuraEnabled public String logoutButtonLabel;

        public ModalContent(Session_Timeout_Config__mdt config) {
            this.modalTitle = config.Modal_Title__c;
            this.modalMessage = config.Modal_Message__c;
            this.continueButtonLabel = config.Continue_Button_Label__c;
            this.logoutButtonLabel = config.Logout_Button_Label__c;
        }

        public ModalContent(SessionTimeoutSettings__c config) {
            this.modalTitle = config.Modal_Title__c;
            this.modalMessage = config.Modal_Message__c;
            this.continueButtonLabel = config.Continue_Button_Label__c;
            this.logoutButtonLabel = config.Logout_Button_Label__c;
        }
    }

    /**
     * @description Contains modal styling properties
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

        public ModalStyle(Session_Timeout_Config__mdt config) {
            this.modalHeaderColor = config.Modal_Header_Color__c;
            this.modalBodyColor = config.Modal_Body_Color__c;
            this.modalFooterColor = config.Modal_Footer_Color__c;
            this.continueButtonColor = config.Continue_Button_Color__c;
            this.logoutButtonColor = config.Logout_Button_Color__c;
            this.countdownColor = config.Countdown_Color__c;
            this.modalWidth = config.Modal_Width__c;
            this.modalBorderRadius = config.Modal_Border_Radius__c;
        }

        public ModalStyle(SessionTimeoutSettings__c config) {
            this.modalHeaderColor = config.Modal_Header_Color__c;
            this.modalBodyColor = config.Modal_Body_Color__c;
            this.modalFooterColor = config.Modal_Footer_Color__c;
            this.continueButtonColor = config.Continue_Button_Color__c;
            this.logoutButtonColor = config.Logout_Button_Color__c;
            this.countdownColor = config.Countdown_Color__c;
            this.modalWidth = config.Modal_Width__c;
            this.modalBorderRadius = config.Modal_Border_Radius__c;
        }
    }

    /**
     * @description Contains action-related settings
     */
    public class ActionSettings {
        @AuraEnabled public String postTimeoutAction;
        @AuraEnabled public String redirectUrl;

        public ActionSettings(Session_Timeout_Config__mdt config) {
            this.postTimeoutAction = config.Post_Timeout_Action__c;
            this.redirectUrl = config.Redirect_URL__c;
        }

        public ActionSettings(SessionTimeoutSettings__c config) {
            String action = config.Post_Timeout_Action__c != null
                ? config.Post_Timeout_Action__c.trim().toLowerCase()
                : 'logout';

            Set<String> validActions = new Set<String>{ 'logout', 'redirect' };
            this.postTimeoutAction = validActions.contains(action) ? action : 'logout';
            // this.redirectUrl = config.Redirect_URL__c;
            this.redirectUrl = String.isEmpty(config.Redirect_URL__c) ? null : config.Redirect_URL__c;
        }
    }
}