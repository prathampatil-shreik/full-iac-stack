package com.fulliac.app.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class ApplicationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void rootEndpointReturns200WithExpectedFields() throws Exception {
        mockMvc.perform(get("/").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application").value("full-iac-stack-app"))
                .andExpect(jsonPath("$.status").value("running"))
                .andExpect(jsonPath("$.environment").exists())
                .andExpect(jsonPath("$.version").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void healthEndpointReturns200WithHealthyStatus() throws Exception {
        mockMvc.perform(get("/health").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("healthy"))
                .andExpect(jsonPath("$.application").value("full-iac-stack-app"))
                .andExpect(jsonPath("$.environment").exists())
                .andExpect(jsonPath("$.version").exists())
                .andExpect(jsonPath("$.message").value("Application is running successfully"));
    }

    @Test
    void infoEndpointReturns200WithExpectedFields() throws Exception {
        mockMvc.perform(get("/api/info").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application").value("full-iac-stack-app"))
                .andExpect(jsonPath("$.environment").exists())
                .andExpect(jsonPath("$.version").exists())
                .andExpect(jsonPath("$.java").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    @Test
    void actuatorHealthReturns200WithStatusUp() throws Exception {
        mockMvc.perform(get("/actuator/health").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
