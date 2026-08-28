import SwaggerUIBundle from "swagger-ui-dist/swagger-ui-es-bundle.js"
import "swagger-ui-dist/swagger-ui.css"

window.addEventListener("DOMContentLoaded", () => {
  SwaggerUIBundle({
    url: "/api/docs/openapi.yaml", // Api::DocsController#openapi (routed as api_openapi_path)
    dom_id: "#swagger-ui",
    deepLinking: true,
    presets: [SwaggerUIBundle.presets.base, SwaggerUIBundle.presets.apis],
    layout: "BaseLayout"
  })
})
