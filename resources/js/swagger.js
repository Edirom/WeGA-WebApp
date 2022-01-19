$(function () {
    var url = $('.swagger-section').attr('data-openapi');
    
    // Begin Swagger UI call region
    const ui = SwaggerUIBundle({
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
    // End Swagger UI call region
    window.ui = ui
});