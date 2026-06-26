import { obfuscateEmail, initHoveredSrcSwap } from "./wega-common.js";

const url = document.querySelector('.swagger-section').getAttribute('data-openapi')

const swaggerUI = SwaggerUIBundle({
    url: url,
    dom_id: '#swagger-ui-container',
    deepLinking: true,
    presets:[
        SwaggerUIBundle.presets.apis,
        SwaggerUIStandalonePreset],
    plugins:[
        SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "BaseLayout"
})

/* actually, de-obfuscate the email address bugs@weber… for feedback */
obfuscateEmail();

/* Farbige Support Badges im footer (page.html) */
initHoveredSrcSwap();
