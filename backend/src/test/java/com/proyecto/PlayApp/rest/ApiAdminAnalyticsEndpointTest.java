package com.proyecto.PlayApp.rest;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.proyecto.PlayApp.entity.Usuario;
import com.proyecto.PlayApp.repository.PedidoRepository;
import com.proyecto.PlayApp.repository.ProductoRepository;
import com.proyecto.PlayApp.repository.UsuarioRepository;
import com.proyecto.PlayApp.service.CurrentWeatherService;
import com.proyecto.PlayApp.service.OccupancyAnalyticsService;
import com.proyecto.PlayApp.service.PedidoService;
import com.proyecto.PlayApp.service.ProductoService;
import com.proyecto.PlayApp.service.ReporteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Permisos y códigos de respuesta de GET /api/admin/prediction/analytics (sin tocar base de datos ni red). */
class ApiAdminAnalyticsEndpointTest {
    private final ObjectMapper mapper = new ObjectMapper();
    private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
    private final OccupancyAnalyticsService analytics = mock(OccupancyAnalyticsService.class);
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        var controller = new ApiAdminController(mock(PedidoService.class), mock(PedidoRepository.class),
                mock(ProductoService.class), mock(ProductoRepository.class), usuarios, mock(ReporteService.class),
                mock(CurrentWeatherService.class), analytics);
        ReflectionTestUtils.setField(controller, "adminGlobalCorreo", "admin@playapp.test");
        mvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void nonAdminGets403AndTheModelIsNeverCalled() throws Exception {
        when(usuarios.findUsuarioByCorreo("cliente@x.com")).thenReturn(Usuario.builder().correo("cliente@x.com").rol("ROLE_USER").build());
        mvc.perform(get("/api/admin/prediction/analytics").param("correo", "cliente@x.com"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
        mvc.perform(get("/api/admin/prediction/analytics").param("correo", "desconocido@x.com"))
                .andExpect(status().isForbidden());
        verifyNoInteractions(analytics);
    }

    @Test
    void adminGetsTheAnalyticsPayload() throws Exception {
        when(usuarios.findUsuarioByCorreo("admin@playapp.test")).thenReturn(Usuario.builder().correo("admin@playapp.test").rol("ROLE_ADMIN").build());
        when(analytics.get()).thenReturn(Optional.of(mapper.readTree("{\"available\":true,\"modelVersion\":\"sim-v1-test\"}")));
        mvc.perform(get("/api/admin/prediction/analytics").param("correo", "admin@playapp.test"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.available").value(true))
                .andExpect(jsonPath("$.modelVersion").value("sim-v1-test"));
    }

    @Test
    void adminGets503WithAReadableMessageWhenTheModelIsDown() throws Exception {
        when(usuarios.findUsuarioByCorreo("admin@playapp.test")).thenReturn(Usuario.builder().correo("admin@playapp.test").rol("ROLE_ADMIN").build());
        when(analytics.get()).thenReturn(Optional.empty());
        mvc.perform(get("/api/admin/prediction/analytics").param("correo", "admin@playapp.test"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("no está disponible")));
    }

    @Test
    void missingCorreoParameterIsRejected() throws Exception {
        mvc.perform(get("/api/admin/prediction/analytics")).andExpect(status().isBadRequest());
    }
}
