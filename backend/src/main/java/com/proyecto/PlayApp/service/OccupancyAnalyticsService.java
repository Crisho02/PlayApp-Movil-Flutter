package com.proyecto.PlayApp.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/**
 * Analítica de la red neuronal de ocupación. Los escenarios son fijos (no dependen del clima actual),
 * por eso el resultado se conserva en memoria; los fallos nunca se guardan.
 */
@Service
public class OccupancyAnalyticsService {
    static final Duration TTL = Duration.ofMinutes(30);
    private final NeuralOccupancyClient client;
    private JsonNode cached;
    private Instant expiresAt = Instant.MIN;

    public OccupancyAnalyticsService(NeuralOccupancyClient client) {
        this.client = client;
    }

    public synchronized Optional<JsonNode> get() {
        Instant now = Instant.now();
        if (cached != null && now.isBefore(expiresAt)) return Optional.of(cached);
        Optional<JsonNode> fresh = client.analytics();
        fresh.ifPresent(value -> { cached = value; expiresAt = now.plus(TTL); });
        // Si el servicio cae, se sirve la última versión válida en lugar de dejar las gráficas vacías.
        return fresh.isPresent() ? fresh : Optional.ofNullable(cached);
    }
}
