package com.fulliac.app.controller;

import com.fulliac.app.model.HealthResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class ApplicationController {

    private static final String APP_NAME = "full-iac-stack-app";

    @Value("${app.environment}")
    private String environment;

    @Value("${app.version}")
    private String version;

    @GetMapping("/")
    public Map<String, String> root() {
        Map<String, String> response = new LinkedHashMap<>();
        response.put("application", APP_NAME);
        response.put("message", "Full Infrastructure-as-Code Stack Demo");
        response.put("status", "running");
        response.put("environment", environment);
        response.put("version", version);
        response.put("timestamp", Instant.now().toString());
        return response;
    }

    @GetMapping("/health")
    public HealthResponse health() {
        return new HealthResponse(
                "healthy",
                APP_NAME,
                environment,
                version,
                "Application is running successfully"
        );
    }

    @GetMapping("/api/info")
    public Map<String, String> info() {
        Map<String, String> response = new LinkedHashMap<>();
        response.put("application", APP_NAME);
        response.put("environment", environment);
        response.put("version", version);
        response.put("java", System.getProperty("java.version"));
        response.put("timestamp", Instant.now().toString());
        return response;
    }
}
