package com.proyecto.PlayApp.service;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class OccupancyAnalyticsServiceTest {
    private static final String VALID = "{\"available\":true,\"trainingData\":\"SIMULATED_ONLY\",\"modelVersion\":\"sim-v1-test\","
            + "\"hourly\":{},\"heatmap\":{},\"sensitivity\":{\"bases\":[]}}";

    private record Fixture(MockRestServiceServer server, NeuralOccupancyClient client) {}

    private Fixture fixture() {
        var builder = RestClient.builder().baseUrl("http://localhost:8001");
        var server = MockRestServiceServer.bindTo(builder).build();
        return new Fixture(server, new NeuralOccupancyClient(builder.build()));
    }

    @Test
    @org.junit.jupiter.api.condition.EnabledIfSystemProperty(named = "occupancy.live", matches = "true")
    void javaConsumesAnalyticsFromTheRunningTensorflowService() {
        var client = new NeuralOccupancyClient(RestClient.builder().baseUrl("http://127.0.0.1:8001").build());
        var result = new OccupancyAnalyticsService(client).get().orElseThrow();
        assertThat(result.path("modelVersion").asText()).startsWith("sim-v1-");
        assertThat(result.path("hourly").path("series").path("weekday").path("clear")).hasSize(24);
        assertThat(result.path("heatmap").path("values").path("high")).hasSize(7);
        assertThat(result.path("sensitivity").path("bases")).hasSize(2);
    }

    @Test void clientReturnsValidAnalyticsPayload() {
        var f = fixture();
        f.server().expect(requestTo("http://localhost:8001/analytics")).andExpect(method(org.springframework.http.HttpMethod.GET))
                .andRespond(withSuccess(VALID, MediaType.APPLICATION_JSON));
        var result = f.client().analytics();
        assertThat(result).isPresent();
        assertThat(result.get().path("modelVersion").asText()).isEqualTo("sim-v1-test");
        f.server().verify();
    }

    @Test void clientRejectsServerErrorsAndPayloadsWithoutSimulationProvenance() {
        var f = fixture();
        f.server().expect(requestTo("http://localhost:8001/analytics")).andRespond(withServerError());
        assertThat(f.client().analytics()).isEmpty();
        f.server().reset();
        f.server().expect(requestTo("http://localhost:8001/analytics"))
                .andRespond(withSuccess(VALID.replace("SIMULATED_ONLY", "REAL"), MediaType.APPLICATION_JSON));
        assertThat(f.client().analytics()).isEmpty();
        f.server().reset();
        f.server().expect(requestTo("http://localhost:8001/analytics"))
                .andRespond(withSuccess("{\"available\":true,\"trainingData\":\"SIMULATED_ONLY\"}", MediaType.APPLICATION_JSON));
        assertThat(f.client().analytics()).isEmpty();
    }

    @Test void serviceCachesSuccessAndDoesNotCacheFailures() {
        var f = fixture();
        var service = new OccupancyAnalyticsService(f.client());
        // Solo dos peticiones esperadas, en orden: error y luego éxito. Una tercera haría fallar el test.
        f.server().expect(requestTo("http://localhost:8001/analytics")).andRespond(withServerError());
        f.server().expect(requestTo("http://localhost:8001/analytics")).andRespond(withSuccess(VALID, MediaType.APPLICATION_JSON));
        assertThat(service.get()).isEmpty();            // fallo: no se guarda
        assertThat(service.get()).isPresent();          // reintenta y guarda
        assertThat(service.get()).isPresent();          // sirve desde caché: sin tercera petición
        f.server().verify();
    }
}
