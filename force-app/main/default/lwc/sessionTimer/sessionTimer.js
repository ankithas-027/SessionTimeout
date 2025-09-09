import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchTimeoutConfig from '@salesforce/apex/SessionTimeoutConfigController.fetchTimeoutConfig';
import logoUrl from '@salesforce/resourceUrl/LogoUrl';
import isGuestUser from '@salesforce/user/isGuest';

export default class SessionTimer extends NavigationMixin(LightningElement) {
    // canonical internal config (timeouts are milliseconds)
    _config = {
        inactivityTimeout: null, // ms
        logoutCountdown: null,   // ms
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
            redirectUrl: null
        }
    };

    // exposed getters for template binding (read-only)
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
    @track countdown = 10; // seconds shown in UI
    @track hasRendered = false;

    isGuest = false;
    observer = null;
    activityEvents = ['mousemove', 'mousedown', 'keypress', 'scroll', 'touchstart', 'wheel', 'click', 'dragstart', 'mouseenter'];
    windowHasFocus = true;

    allowedSalesforceDomains = [
        'salesforce.com',
        'force.com',
        'visual.force.com',
        'lightning.force.com',
        'salesforce-sites.com'
    ];

    // event handlers
    handleUserActivity = () => { this.lastActivityTime = Date.now(); };
    handleWindowFocus = () => { this.windowHasFocus = true; this.lastActivityTime = Date.now(); };
    handleWindowBlur = () => { this.windowHasFocus = false; };
    handleVisibilityChange = () => {
        this.windowHasFocus = document.visibilityState === 'visible';
        if (this.windowHasFocus) this.lastActivityTime = Date.now();
    };
    handleModalClick = (event) => { event.stopPropagation(); };
    handleKeydown = (event) => { if (event.key === 'Escape') this.handleContinueClick(); };
    handleImageError = (event) => { event.target.style.display = 'none'; };

    connectedCallback() {
        this.isGuest = isGuestUser;

        if (sessionStorage.getItem('sessionTimeoutLogout')) {
            sessionStorage.removeItem('sessionTimeoutLogout');
            return;
        }

        fetchTimeoutConfig()
            .then(result => {
                try {
                    if (result?.timeoutSettings) {
                        const normalizeToMs = (val) => {
                            if (val == null) return null;
                            if (val > 0 && val < 10000) return val * 1000;
                            return val;
                        };

                        this._config = {
                            ...this._config,
                            inactivityTimeout: normalizeToMs(result.timeoutSettings.inactivityTimeout) ?? this._config.inactivityTimeout,
                            logoutCountdown: normalizeToMs(result.timeoutSettings.logoutCountdown) ?? this._config.logoutCountdown,
                            showCountdown: result.timeoutSettings.showCountdown ?? this._config.showCountdown,
                            modalTitle: result.modalContent?.modalTitle ?? this._config.modalTitle,
                            modalMessage: result.modalContent?.modalMessage ?? this._config.modalMessage,
                            continueButtonLabel: result.modalContent?.continueButtonLabel ?? this._config.continueButtonLabel,
                            logoutButtonLabel: result.modalContent?.logoutButtonLabel ?? this._config.logoutButtonLabel,
                            modalHeaderColor: result.modalStyle?.modalHeaderColor ?? this._config.modalHeaderColor,
                            modalBodyColor: result.modalStyle?.modalBodyColor ?? this._config.modalBodyColor,
                            modalFooterColor: result.modalStyle?.modalFooterColor ?? this._config.modalFooterColor,
                            continueButtonColor: result.modalStyle?.continueButtonColor ?? this._config.continueButtonColor,
                            logoutButtonColor: result.modalStyle?.logoutButtonColor ?? this._config.logoutButtonColor,
                            countdownColor: result.modalStyle?.countdownColor ?? this._config.countdownColor,
                            modalWidth: result.modalStyle?.modalWidth ?? this._config.modalWidth,
                            modalBorderRadius: result.modalStyle?.modalBorderRadius ?? this._config.modalBorderRadius,
                            logoUrl: result.logoUrl || logoUrl,
                            logoImage: result.logoImage || `${(result.logoUrl || logoUrl)}/logoImage.png`,
                            actionSettings: {
                                postTimeoutAction: result.actionSettings?.postTimeoutAction ?? this._config.actionSettings.postTimeoutAction,
                                redirectUrl: result.actionSettings?.redirectUrl ?? this._config.actionSettings.redirectUrl
                            }
                        };
                    }
                } catch (err) {
                    console.error('SessionTimer: error applying config', err);
                }

                if (!this._config.logoUrl) {
                    this._config.logoUrl = logoUrl;
                    this._config.logoImage = `${logoUrl}/logoImage.png`;
                }

                this.countdown = this._calculateCountdownSeconds(this._config.logoutCountdown);
                this.setupInactivityMonitoring();
                this.setupVisibilityListeners();
                this.setupMutationObserver();
            })
            .catch((err) => {
                console.error('SessionTimer: fetchTimeoutConfig failed', err);
                this.countdown = this._calculateCountdownSeconds(this._config.logoutCountdown);
                this.setupInactivityMonitoring();
                this.setupVisibilityListeners();
                this.setupMutationObserver();
            });
    }

    _calculateCountdownSeconds(ms) {
        if (!ms || isNaN(ms)) return 10;
        return Math.max(1, Math.floor(ms / 1000));
    }

    isExperienceSite() {
        return (
            window.location.pathname.includes('/s/') ||
            window.location.pathname.includes('/sfsites/') ||
            (window.location.pathname.match(/\/s\/[a-zA-Z0-9_-]+/))
        );
    }

    getCommunityBaseUrl() {
        return window.location.origin;
    }

    // ---------- inactivity monitoring ----------
    lastActivityTime = Date.now();
    @track monitoringInactivity = false;

    setupInactivityMonitoring() {
        this.lastActivityTime = Date.now();
        this.activityEvents.forEach(evt =>
            window.addEventListener(evt, this.handleUserActivity, { passive: true })
        );
        if (!this.monitoringInactivity) {
            this.monitoringInactivity = true;
            this.startInactivityLoop();
        }
    }

    startInactivityLoop() {
        const check = () => {
            if (!this.monitoringInactivity) return;

            try {
                const diff = Date.now() - this.lastActivityTime;
                if (this._config.inactivityTimeout && diff >= this._config.inactivityTimeout && !this.showTimeoutModal) {
                    this.showTimeoutWarning();
                }
            } catch (err) {
                console.error('SessionTimer: inactivity loop error', err);
            }

            if ('requestIdleCallback' in window) {
                requestIdleCallback(check, { timeout: 1000 });
            } else {
                const mc = new MessageChannel();
                mc.port1.onmessage = check;
                // safe microtask scheduling
                mc.port2.postMessage(null);
            }
        };
        check();
    }

    showTimeoutWarning() {
        this.showTimeoutModal = true;
        this.countdown = this._calculateCountdownSeconds(this._config.logoutCountdown);
        if (!this.isCountingDown) {
            this.startManualCountdown();
        }
    }

    stopCountdown = false;
    @track isCountingDown = false;

    delayOneSecond() {
        return new Promise((resolve) => {
            const start = Date.now();
            const wait = () => {
                if (Date.now() - start >= 1000) {
                    resolve();
                } else {
                    if ('requestIdleCallback' in window) {
                        requestIdleCallback(wait, { timeout: 1000 });
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

    async startManualCountdown() {
        if (this.isCountingDown) return;
        this.stopCountdown = false;
        this.isCountingDown = true;
        this.countdown = this._calculateCountdownSeconds(this._config.logoutCountdown);

        while (this.countdown > 0 && !this.stopCountdown) {
            await this.delayOneSecond();
            if (!this.stopCountdown) this.countdown--;
        }

        this.isCountingDown = false;

        if (this.countdown <= 0 && !this.stopCountdown) {
            this.handleLogoutClick();
        }
    }

    handleContinueClick() {
        this.stopCountdown = true;
        this.showTimeoutModal = false;
        this.isCountingDown = false;
        this.lastActivityTime = Date.now();

        if (!this.monitoringInactivity) {
            this.monitoringInactivity = true;
            this.startInactivityLoop();
        }
    }

    // ---------- Actions ----------
    handleLogoutClick() {
        this.stopCountdown = true;
        this.monitoringInactivity = false;
        this.lastActivityTime = Infinity;
        this.showTimeoutModal = false;
        this.isCountingDown = false;

        sessionStorage.setItem('sessionTimeoutLogout', 'true');

        const action = this._config.actionSettings?.postTimeoutAction || 'logout';
        switch (action) {
            case 'redirect':
                this.handleRedirect();
                break;
            case 'logout':
            default:
                this.handleSystemLogout();
        }

        this.activityEvents.forEach(evt => window.removeEventListener(evt, this.handleUserActivity));
    }

    handleRedirect() {
        let url = this._config.actionSettings?.redirectUrl || '/';
        url = this.normalizeRedirectUrl(url);

        if (this.isExperienceSite()) {
            this.handleCommunityRedirect(url);
        } else {
            this.handleStandardRedirect(url);
        }
    }

    normalizeRedirectUrl(url) {
        if (!url) return '/';
        if (!url.startsWith('http') && !url.startsWith('/')) {
            url = '/' + url;
        }
        return url.replace(/([^:]\/)\/+/g, '$1');
    }

    buildCommunityAbsoluteUrl(relativeOrAbsolute) {
        try {
            if (relativeOrAbsolute.startsWith('http')) return relativeOrAbsolute;
            const base = this.getCommunityBaseUrl();
            return new URL(relativeOrAbsolute, base).toString();
        } catch {
            return this.getCommunityBaseUrl();
        }
    }

    handleCommunityRedirect(url) {
        const finalUrl = url.startsWith('http') ? url : this.buildCommunityAbsoluteUrl(url);
        try {
            const targetHost = new URL(finalUrl).host.toLowerCase();
            const currentHost = window.location.host.toLowerCase();
            if (targetHost === currentHost) {
                this[NavigationMixin.Navigate]({ type: 'standard__webPage', attributes: { url: finalUrl } }, true);
            } else {
                window.location.assign(finalUrl);
            }
        } catch {
            window.location.assign(finalUrl);
        }
    }

    handleStandardRedirect(url) {
        let finalUrl = url;
        if (!url.startsWith('http')) {
            finalUrl = new URL(url, window.location.origin).toString();
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: finalUrl }
        }, true);
    }

    handleSystemLogout() {
        const origin = window.location.origin;
        const retUrl = this.isExperienceSite() ? `${origin}/s/` : origin;
        const logoutUrl = `${origin}/secur/logout.jsp?retUrl=${encodeURIComponent(retUrl)}`;
        window.location.assign(logoutUrl);
    }

    // ---------- Styles & DOM helpers ----------
    get modalStyle() {
        const width = this._config.modalWidth || '360px';
        const br = this._config.modalBorderRadius || '8px';
        return `width: ${width}; border-radius: ${br};`;
    }
    get headerStyle() { return `background-color: ${this._config.modalHeaderColor || 'transparent'};`; }
    get bodyStyle() { return `background-color: ${this._config.modalBodyColor || 'transparent'};`; }
    get footerStyle() { return `background-color: ${this._config.modalFooterColor || 'transparent'};`; }
    get countdownStyle() { return `color: ${this._config.countdownColor || '#000'}; font-weight: bold;`; }

    get continueButtonStyle() {
        return this._config.continueButtonColor ? `background-color: ${this._config.continueButtonColor};` : '';
    }
    get logoutButtonStyle() {
        return this._config.logoutButtonColor ? `background-color: ${this._config.logoutButtonColor};` : '';
    }

    get displayMessage() {
        return this._config.modalMessage || 'Your session is about to expire due to inactivity.';
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
        try {
            const modal = this.template.querySelector('.session-timer-modal');
            if (modal) {
                modal.style.width = this._config.modalWidth || modal.style.width;
                modal.style.borderRadius = this._config.modalBorderRadius || modal.style.borderRadius;
            }
        } catch { /* ignore */ }
    }

    applySectionColors() {
        try {
            const header = this.template.querySelector('.modal-header');
            const body = this.template.querySelector('.modal-body');
            const footer = this.template.querySelector('.modal-footer');
            const countdown = this.template.querySelector('.countdown');

            if (header) header.style.backgroundColor = this._config.modalHeaderColor || header.style.backgroundColor;
            if (body) body.style.backgroundColor = this._config.modalBodyColor || body.style.backgroundColor;
            if (footer) footer.style.backgroundColor = this._config.modalFooterColor || footer.style.backgroundColor;
            if (countdown) {
                countdown.style.color = this._config.countdownColor || countdown.style.color;
                countdown.style.fontWeight = 'bold';
            }
        } catch { /* ignore */ }
    }

    setButtonColorVariables() {
        try {
            if (this._config.continueButtonColor) {
                this.template.host.style.setProperty('--continue-button-bg-color', this._config.continueButtonColor);
            }
            if (this._config.logoutButtonColor) {
                this.template.host.style.setProperty('--logout-button-bg-color', this._config.logoutButtonColor);
            }
        } catch { /* ignore */ }
    }

    setupMutationObserver() {
        try {
            this.observer = new MutationObserver(() => {
                if (this.showTimeoutModal) this.applyAllStyles();
            });
            this.observer.observe(this.template, { childList: true, subtree: true });
        } catch { /* ignore */ }
    }

    disconnectedCallback() {
        if (this.observer) this.observer.disconnect();

        window.removeEventListener('focus', this.handleWindowFocus);
        window.removeEventListener('blur', this.handleWindowBlur);
        document.removeEventListener('visibilitychange', this.handleVisibilityChange);

        this.activityEvents.forEach(evt =>
            window.removeEventListener(evt, this.handleUserActivity)
        );
        this.monitoringInactivity = false;

        this.showTimeoutModal = false;
        this.stopCountdown = true;
        this.isCountingDown = false;
        this.lastActivityTime = 0;
    }

    setupVisibilityListeners() {
        window.addEventListener('focus', this.handleWindowFocus);
        window.addEventListener('blur', this.handleWindowBlur);
        document.addEventListener('visibilitychange', this.handleVisibilityChange);
    }
}