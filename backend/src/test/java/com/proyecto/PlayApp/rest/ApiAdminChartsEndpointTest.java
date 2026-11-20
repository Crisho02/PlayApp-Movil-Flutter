package com.proyecto.PlayApp.rest;

import com.proyecto.PlayApp.entity.Usuario;
import com.proyecto.PlayApp.repository.PedidoRepository;
import com.proyecto.PlayApp.repository.ProductoRepository;
import com.proyecto.PlayApp.repository.ResenaRepository;
import com.proyecto.PlayApp.repository.UsuarioRepository;
import com.proyecto.PlayApp.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDate;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Permisos, parámetros y errores de GET /api/admin/charts (sin base de datos ni red). */
class ApiAdminChartsEndpointTest {
    private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
    private final SalesChartsService charts = mock(SalesChartsService.class);
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        var controller = new ApiAdminController(mock(PedidoService.class), mock(PedidoRepository.class),
                mock(ProductoService.class), mock(ProductoRepository.class), usuarios, mock(ReporteService.class),
                mock(CurrentWeatherService.class), mock(WekaPredictionService.class), mock(ResenaRepository.class),
                mock(UsuarioService.class), charts);
        ReflectionTestUtils.setField(controller, "adminGlobalCorreo", "admin@playapp.test");
        mvc = MockMvcBuilders.standaloneSetup(controller).build();
        when(usuarios.findUsuarioByCorreo("admin@playapp.test"))
                .thenReturn(Usuario.builder().correo("admin@playapp.test").rol("ROLE_ADMIN").build());
    }

    @Test
    void noAdminRecibe403YNoSeConsultaLaBaseDeDatos() throws Exception {
        when(usuarios.findUsuarioByCorreo("cliente@x.com")).thenReturn(Usuario.builder().correo("cliente@x.com").rol("ROLE_USER").build());
        mvc.perform(get("/api/admin/charts").param("correo", "cliente@x.com")).andExpect(status().isForbidden());
        verifyNoInteractions(charts);
    }

    @Test
    void adminRecibeLosDatosYLosParametrosLleganAlServicio() throws Exception {
        when(charts.build(any(), any(), any(), any(), any(), any())).thenReturn(Map.of("resumen", Map.of("pedidos", 7)));
        mvc.perform(get("/api/admin/charts").param("correo", "admin@playapp.test").param("rango", "personalizado")
                        .param("desde", "2026-05-01").param("hasta", "2026-05-31").param("categoria", "2").param("granularidad", "week"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resumen.pedidos").value(7));
        verify(charts).build("admin@playapp.test", "personalizado", LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), 2, "week");
    }

    @Test
    void valoresPorDefectoSonUltimos30DiasYGranularidadAutomatica() throws Exception {
        when(charts.build(any(), any(), any(), any(), any(), any())).thenReturn(Map.of());
        mvc.perform(get("/api/admin/charts").param("correo", "admin@playapp.test")).andExpect(status().isOk());
        verify(charts).build("admin@playapp.test", "30d", null, null, null, "auto");
    }

    @Test
    void fechaMalFormadaOParametrosInvalidosDevuelven400ConMensaje() throws Exception {
        mvc.perform(get("/api/admin/charts").param("correo", "admin@playapp.test").param("rango", "personalizado")
                        .param("desde", "01/05/2026").param("hasta", "2026-05-31"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").exists());
        when(charts.build(any(), eq("ayer"), any(), any(), any(), any())).thenThrow(new IllegalArgumentException("Rango no válido: ayer"));
        mvc.perform(get("/api/admin/charts").param("correo", "admin@playapp.test").param("rango", "ayer"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Rango no válido: ayer"));
        mvc.perform(get("/api/admin/charts").param("correo", "admin@playapp.test").param("categoria", "abc"))
                .andExpect(status().isBadRequest());
    }
}
