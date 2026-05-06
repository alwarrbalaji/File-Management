// src/main/java/com/filemanager/config/CorsConfig.java
package com.filemanager.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Global CORS configuration.
 *
 * Allows the Flutter Android app (running on your phone) to call
 * this Spring Boot API over the local WiFi network.
 *
 * ⚠️  "*" is used here for development convenience.
 *     In production, replace "*" with specific origins.
 */
@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry
                    .addMapping("/api/**")            // apply to all /api/ routes
                    .allowedOriginPatterns("*")        // allow any origin (dev mode)
                    .allowedMethods(                   // allow these HTTP methods
                        "GET", "POST", "DELETE",
                        "PUT", "PATCH", "OPTIONS"
                    )
                    .allowedHeaders("*")               // allow any request headers
                    .exposedHeaders(                   // expose these to the client
                        "Content-Disposition",
                        "Content-Length",
                        "Content-Type"
                    )
                    .allowCredentials(false)           // no cookies needed
                    .maxAge(3600);                     // cache preflight for 1 hour
            }
        };
    }
}