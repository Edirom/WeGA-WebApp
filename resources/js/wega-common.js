/**
 * Converts obfuscated email text inside DOM elements into clickable mailto links.
 *
 * Expected source format per element: `localpart [ignored] domain.tld`
 * Example: `max.mustermann [at] example.org` -> `max.mustermann@example.org`
 *
 * @param {string | NodeListOf<HTMLElement> | HTMLElement[]} [target='.obfuscate-email']
 * CSS selector or list of elements to process.
 * @returns {void}
 */
export function obfuscateEmail(target = '.obfuscate-email') {
    const elements = typeof target === 'string' ? document.querySelectorAll(target) : target;

    elements.forEach((element) => {
        const text = element.textContent || '';
        const openBracket = text.indexOf('[');
        const closeBracket = text.indexOf(']');

        // Skip elements that do not match the expected obfuscation pattern.
        if (openBracket === -1 || closeBracket === -1 || closeBracket < openBracket) {
            return;
        }

        // Build email from text before `[` and after `]`.
        const localPart = text.slice(0, openBracket).trim();
        const domainPart = text.slice(closeBracket + 1).trim();
        const email = `${localPart}@${domainPart}`;

        // Replace content and href with the de-obfuscated email address.
        element.setAttribute('href', `mailto:${email}`);
        element.textContent = email;
    });
}

/**
 * Initializes image hover swap behavior using `data-hovered-src`.
 * On hover-in, swaps `src` to `data-hovered-src`; on hover-out, restores the original source.
 *
 * @param {string | NodeListOf<HTMLImageElement> | HTMLImageElement[]} [target='[data-hovered-src]']
 * @returns {void}
 */
export function initHoveredSrcSwap(target = '[data-hovered-src]') {
    const elements = typeof target === 'string' ? document.querySelectorAll(target) : target;

    elements.forEach((element) => {
        element.addEventListener('mouseenter', () => {
            const currentSrc = element.getAttribute('src');
            if (currentSrc !== null) {
                element.dataset.originalSrc = currentSrc;
            }
            if (element.dataset.hoveredSrc) {
                element.setAttribute('src', element.dataset.hoveredSrc);
            }
        });

        element.addEventListener('mouseleave', () => {
            const currentSrc = element.getAttribute('src');
            if (currentSrc !== null) {
                element.dataset.hoveredSrc = currentSrc;
            }
            if (element.dataset.originalSrc) {
                element.setAttribute('src', element.dataset.originalSrc);
            }
        });
    });
}
