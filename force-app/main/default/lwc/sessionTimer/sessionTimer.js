import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchTimeoutConfig from '@salesforce/apex/SessionTimeoutConfigController.fetchTimeoutConfig';
import logoUrl from '@salesforce/resourceUrl/LogoUrl';
import isGuestUser from "@salesforce/user/isGuest";


export default class SessionTimer extends NavigationMixin(LightningElement) {
    _config = {
        inactivityTimeout: null,
        logoutCountdown: null,
        modalTitle: '',
        modalMessage: '',
        continueButtonLabel: '',
        logoutButtonLabel: '',
        modalHeaderColor: '',
        modalBodyColor: '',
        modalFooterColor: '',
        continueButtonColor: '',
        logoutButtonColor: '',
        countdownColor: '',
        modalWidth: '',
        modalBorderRadius: '',
        showCountdown: false,
        logoUrl: null,
        logoImage: null,
        actionSettings: {
            postTimeoutAction: 'logout',
            redirectUrl: ''
        }
    };

    @api get inactivityTimeout() { return this._config.inactivityTimeout; }
    @api get logoutCountdown() { return this._config.logoutCountdown; }
    @api get modalTitle() { return this._config.modalTitle; }
    @api get modalMessage() { return this._config.modalMessage; }
    @api get continueButtonLabel() { return this._config.continueButtonLabel; }
    @api get logoutButtonLabel() { return this._config.logoutButtonLabel; }
    @api get modalHeaderColor() { return this._config.modalHeaderColor; }
    @api get modalBodyColor() { return this._config.modalBodyColor; }
    @api get modalFooterColor() { return this._config.modalFooterColor; }
    @api get continueButtonColor() { return this._config.continueButtonColor; }
    @api get logoutButtonColor() { return this._config.logoutButtonColor; }
    @api get countdownColor() { return this._config.countdownColor; }
    @api get modalWidth() { return this._config.modalWidth; }
    @api get modalBorderRadius() { return this._config.modalBorderRadius; }
    @api get showCountdown() { return this._config.showCountdown; }
    @api get logoUrl() { return this._config.logoUrl; }
    @api get logoImage() { return this._config.logoImage; }

    @track showTimeoutModal = false;
    @track countdown = 10;
    @track hasRendered = false;

    isGuest = false;
    sessionTimer;
    countdownTimer;
    observer;
    activityEvents = ['mousemove', 'mousedown', 'keypress', 'scroll', 'touchstart', 'wheel', 'click', 'dragstart', 'mouseenter'];
    windowHasFocus = true;


  connectedCallback() {

    this.isGuest = isGuestUser;
    if (this.isGuest) {
        this.template.host.style.display = 'block';
        this.template.host.style.visibility = 'visible';
        this.template.host.style.opacity = '1';

    }

    if (sessionStorage.getItem('sessionTimeoutLogout')) {
        sessionStorage.removeItem('sessionTimeoutLogout');
        return;
    }

    fetchTimeoutConfig()
        .then(result => {
            if (result) {
                this._config = {
                    ...this._config,
                    inactivityTimeout: result.timeoutSettings?.inactivityTimeout || this._config.inactivityTimeout,
                    logoutCountdown: result.timeoutSettings?.logoutCountdown || this._config.logoutCountdown,
                    showCountdown: result.timeoutSettings?.showCountdown || this._config.showCountdown,
                    modalTitle: result.modalContent?.modalTitle || this._config.modalTitle,
                    modalMessage: result.modalContent?.modalMessage || this._config.modalMessage,
                    continueButtonLabel: result.modalContent?.continueButtonLabel || this._config.continueButtonLabel,
                    logoutButtonLabel: result.modalContent?.logoutButtonLabel || this._config.logoutButtonLabel,
                    modalHeaderColor: result.modalStyle?.modalHeaderColor || this._config.modalHeaderColor,
                    modalBodyColor: result.modalStyle?.modalBodyColor || this._config.modalBodyColor,
                    modalFooterColor: result.modalStyle?.modalFooterColor || this._config.modalFooterColor,
                    continueButtonColor: result.modalStyle?.continueButtonColor || this._config.continueButtonColor,
                    logoutButtonColor: result.modalStyle?.logoutButtonColor || this._config.logoutButtonColor,
                    countdownColor: result.modalStyle?.countdownColor || this._config.countdownColor,
                    modalWidth: result.modalStyle?.modalWidth || this._config.modalWidth,
                    modalBorderRadius: result.modalStyle?.modalBorderRadius || this._config.modalBorderRadius,
                    logoUrl: result.logoUrl || logoUrl,
                    logoImage: result.logoImage || `${logoUrl}/logoImage.png`,
                    actionSettings: {
                        postTimeoutAction: result.actionSettings?.postTimeoutAction || this._config.actionSettings.postTimeoutAction,
                        redirectUrl: result.actionSettings?.redirectUrl || this._config.actionSettings.redirectUrl
                    }
                };
            }

            // Apply fallback if no logo URL is configured
            if (!this._config.logoUrl) {
                this._config.logoUrl = logoUrl;
                this._config.logoImage = `${logoUrl}/logoImage.png`;
            }


            this.countdown = Math.floor(this._config.logoutCountdown / 1000);
            this.setupInactivityMonitoring();
            this.setupVisibilityListeners();
            this.setupMutationObserver();
        })
        .catch(() => {
            // this._config.inactivityTimeout = this._config.inactivityTimeout || 300000;
            // this._config.logoutCountdown = this._config.logoutCountdown || 10000;
            this.countdown = Math.floor(this._config.logoutCountdown / 1000);
            this.setupInactivityMonitoring();
            this.setupVisibilityListeners();
            this.setupMutationObserver();
        });
    }

    isExperienceSite() {
        return (window.location.pathname.includes('/s/') ||
        window.location.pathname.includes('/sfsites/') ||
        (window.location.pathname.match(/\/s\/[a-zA-Z0-9_-]+/)));
    }

    getCommunityBaseUrl() {
        if (this.isExperienceSite()) {
            const pathParts = window.location.pathname.split('/');
            const communityPrefixIndex = pathParts.findIndex(part =>
                part === 's' || part === 'sfsites');

            if (communityPrefixIndex >= 0) {
                const communityPath = pathParts.slice(0, communityPrefixIndex + 2).join('/');
                return `${window.location.origin}${communityPath}`;
            }
        }
        return window.location.origin;
    }

    lastActivityTime = Date.now();
    @track monitoringInactivity = false;

    setupInactivityMonitoring() {
        this.lastActivityTime = Date.now();
        this.activityEvents.forEach(event =>
            window.addEventListener(event, this.handleUserActivity.bind(this))
        );
        if (!this.monitoringInactivity) {
            this.monitoringInactivity = true;
            this.startInactivityLoop();
        }
    }
    handleUserActivity() {
        this.lastActivityTime = Date.now();
    }
    startInactivityLoop() {
        const check = () => {
             if (!this.monitoringInactivity) {
                return;
            }
            const now = Date.now();
            const diff = now - this.lastActivityTime;

            if (diff >= this._config.inactivityTimeout && !this.showTimeoutModal) {
                this.showTimeoutWarning();
            }

            if ('requestIdleCallback' in window) {
                requestIdleCallback(check);
            } else {
                const mc = new MessageChannel();
                mc.port1.onmessage = check;
                mc.port2.postMessage(null);
            }
        };

        check();
    }

    showTimeoutWarning() {
        this.showTimeoutModal = true;
        this.countdown = Math.floor(this._config.logoutCountdown / 1000);

       this.countdownTimer= this.startManualCountdown();
    }
    stopCountdown = false;
    @track isCountingDown = false;

    async startManualCountdown() {
    if (this.isCountingDown) {
        return;
    }

    this.countdown =  Math.floor(this._config.logoutCountdown / 1000);
    this.stopCountdown = false;
    this.isCountingDown = true;

    while (this.countdown > 0 && !this.stopCountdown) {
        await this.delayOneSecond();
        this.countdown--;
    }

    this.isCountingDown = false;

    if (this.countdown <= 0 && !this.stopCountdown) {
        this.handleLogoutClick();
    }
}

    delayOneSecond() {
        return new Promise((resolve) => {
            const start = Date.now();
            const wait = () => {
                if (Date.now() - start >= 1000) {
                    resolve();
                } else {
                    if ('requestIdleCallback' in window) {
                        requestIdleCallback(wait);
                    } else {
                        const mc = new MessageChannel();
                        mc.port1.onmessage = wait;
                        mc.port2.postMessage(null);
                    }
                }
            };
            wait();
        });
    }

    handleManualDecrement() {
        if (this.countdown > 1) {
            this.countdown--;
        } else {
            this.handleLogoutClick();
        }
    }

    handleContinueClick() {
        this.stopCountdown = true;
        this.showTimeoutModal = false;
        this.isCountingDown = false
         this.lastActivityTime = Date.now();


        if (!this.monitoringInactivity) {
            this.monitoringInactivity = true;
            this.startInactivityLoop();
        }

    }

    handleLogoutClick() {
    this.stopCountdown = true;
    this.monitoringInactivity = false;
    this.lastActivityTime = Infinity;
    this.showTimeoutModal = false;
    this.isCountingDown = false;

    sessionStorage.setItem('sessionTimeoutLogout', 'true');

    const action = this._config.actionSettings?.postTimeoutAction || 'logout';

    switch(action) {
        case 'redirect':
            this.handleRedirect();
            break;

        case 'logout':
        default:
            this.handleSystemLogout();
    }


     this.activityEvents.forEach(event =>
        window.removeEventListener(event, this.handleUserActivity.bind(this))
    );
}



handleRedirect() {
    let url = this._config.actionSettings?.redirectUrl || '/';

    // Normalize the URL first
    url = this.normalizeRedirectUrl(url);

    if (this.isExperienceSite()) {
        this.handleCommunityRedirect(url);
    } else {
        this.handleStandardRedirect(url);
    }
}

normalizeRedirectUrl(url) {
    // Ensure URL is properly formatted
    if (!url.startsWith('http') && !url.startsWith('/')) {
        url = '/' + url;
    }

    // Remove any duplicate slashes
    url = url.replace(/([^:]\/)\/+/g, '$1');

    return url;
}

handleCommunityRedirect(url) {
    const communityUrl = this.getCommunityBaseUrl();

    if (url.startsWith('http')) {
        window.location.href = url;
        return;
    }


    if (url.startsWith('/s/') || url.startsWith('/sfsites/')) {
        window.location.href = `${window.location.origin}${url}`;
        return;
    }

    if (url.startsWith('/')) {
        if (url.startsWith(communityUrl)) {
            window.location.href = url;
        } else {
            window.location.href = `${communityUrl}${url}`;
        }
        return;
    }


    window.location.href = communityUrl;
}

handleStandardRedirect(url) {
    if (url.startsWith('http')) {
        window.location.href = url;
    } else {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        }, true);
    }
}


handleSystemLogout() {
    if (this.isExperienceSite()) {
        const communityUrl = this.getCommunityBaseUrl();
        window.location.href = `${communityUrl}/secur/logout.jsp?retUrl=${encodeURIComponent(communityUrl)}`;
    } else {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/secur/logout.jsp?retUrl=' +
                     encodeURIComponent(window.location.origin)
            }
        }, true);
    }
}

    get modalStyle() {
        return `width: ${this._config.modalWidth}; border-radius: ${this._config.modalBorderRadius};`;
    }

    get headerStyle() {
        return `background-color: ${this._config.modalHeaderColor};`;
    }

    get bodyStyle() {
        return `background-color: ${this._config.modalBodyColor};`;
    }

    get footerStyle() {
        return `background-color: ${this._config.modalFooterColor};`;
    }

    get countdownStyle() {
        return `color: ${this._config.countdownColor}; font-weight: bold;`;
    }

    get continueButtonStyle() {
        return this._config.continueButtonColor ? `background-color: ${this._config.continueButtonColor};` : '';
    }

    get logoutButtonStyle() {
        return this._config.logoutButtonColor ? `background-color: ${this._config.logoutButtonColor};` : '';
    }

    get displayMessage() {
    return this.modalMessage || 'Your session is about to expire due to inactivity.';
}

    renderedCallback() {
        if (this.showTimeoutModal && !this.hasRendered) {
            this.hasRendered = true;
            this.applyAllStyles();
        } else if (!this.showTimeoutModal) {
            this.hasRendered = false;
        }
    }

    applyAllStyles() {
        this.applyModalStyles();
        this.applySectionColors();
        this.setButtonColorVariables();
    }

    applyModalStyles() {
        const modal = this.template.querySelector('.session-timer-modal');
        if (modal) {
            modal.style.width = this._config.modalWidth;
            modal.style.borderRadius = this._config.modalBorderRadius;
        }
    }

    applySectionColors() {
        const header = this.template.querySelector('.modal-header');
        const body = this.template.querySelector('.modal-body');
        const footer = this.template.querySelector('.modal-footer');
        const countdown = this.template.querySelector('.countdown');

        if (header) header.style.backgroundColor = this._config.modalHeaderColor;
        if (body) body.style.backgroundColor = this._config.modalBodyColor;
        if (footer) footer.style.backgroundColor = this._config.modalFooterColor;
        if (countdown) {
            countdown.style.color = this._config.countdownColor;
            countdown.style.fontWeight = 'bold';
        }
    }

    setButtonColorVariables() {
        if (this._config.continueButtonColor) {
            this.template.host.style.setProperty('--continue-button-bg-color', this._config.continueButtonColor);
        }
        if (this._config.logoutButtonColor) {
            this.template.host.style.setProperty('--logout-button-bg-color', this._config.logoutButtonColor);
        }
    }

    setupMutationObserver() {
        this.observer = new MutationObserver(() => {
            if (this.showTimeoutModal) {
                this.applyAllStyles();
            }
        });
        this.observer.observe(this.template, { childList: true, subtree: true });
    }

    disconnectedCallback() {
        if (this.observer) this.observer.disconnect();
        window.removeEventListener('focus', this.handleWindowFocus);
        window.removeEventListener('blur', this.handleWindowBlur);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);
        this.activityEvents.forEach(event =>
            window.removeEventListener(event, this.handleUserActivity.bind(this))
        );
        this.monitoringInactivity = false;

         // Clear any active timers
         clearTimeout(this.sessionTimer);
         clearTimeout(this.countdownTimer);

         // Reset all state variables
         this.showTimeoutModal = false;
         this.stopCountdown = true;
         this.isCountingDown = false;
         this.lastActivityTime = 0;
    }

    setupVisibilityListeners() {
        window.addEventListener('focus', this.handleWindowFocus.bind(this));
        window.addEventListener('blur', this.handleWindowBlur.bind(this));
        document.addEventListener('visibilitychange', this.handleVisibilityChange.bind(this));
    }

    handleWindowFocus() {
        this.windowHasFocus = true;
        this.lastActivityTime = Date.now();
    }

    handleWindowBlur() {
        this.windowHasFocus = false;
    }

    handleVisibilityChange() {
        this.windowHasFocus = document.visibilityState === 'visible';
        if (this.windowHasFocus) {
             this.lastActivityTime = Date.now();
        }
    }

    handleModalClick(event) {
    if (event.target === this.template.querySelector('.session-timer-modal')) {
        event.stopPropagation();
    }
}

    handleKeydown(event) {
        if (event.key === 'Escape') {
            this.handleContinueClick();
        }
    }

    handleImageError(event) {
        event.target.style.display = 'none';
    }
}