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
