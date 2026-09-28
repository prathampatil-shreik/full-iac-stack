package com.fulliac.app.model;

public class HealthResponse {

    private String status;
    private String application;
    private String environment;
    private String version;
    private String message;

    public HealthResponse() {}

    public HealthResponse(String status, String application, String environment, String version, String message) {
        this.status = status;
        this.application = application;
        this.environment = environment;
        this.version = version;
        this.message = message;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getApplication() { return application; }
    public void setApplication(String application) { this.application = application; }

    public String getEnvironment() { return environment; }
    public void setEnvironment(String environment) { this.environment = environment; }

    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
