package com.proyecto.PlayApp.service;

import com.proyecto.PlayApp.service.SalesChartsCalculator.ProductInfo;
import com.proyecto.PlayApp.service.SalesChartsCalculator.Range;
import com.proyecto.PlayApp.service.SalesChartsCalculator.SaleLine;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SuppressWarnings("unchecked")
class SalesChartsCalculatorTest {
    private static final LocalDate HOY = LocalDate.of(2026, 11, 19); // jueves

    private static SaleLine line(String pedido, String fechaHora, String productoId, String nombre, int cat, double cant, double subtotal) {
        return new SaleLine(pedido, LocalDateTime.parse(fechaHora), productoId, nombre, cat, cant, subtotal);
    }

    private static final List<ProductInfo> CATALOGO = List.of(
            new ProductInfo("p1", "Pescado frito", 1, 32000.0, 24.0),
            new ProductInfo("p2", "Limonada de coco", 2, 10000.0, 50.0),
            new ProductInfo("p3", "Gusanito", 3, 45000.0, 5.0),
            new ProductInfo("p4", "Coca-Cola", 2, 3500.0, 62.0)); // nunca vendido

    // Periodo actual (7d): 13-19 nov. Periodo anterior: 6-12 nov.
    private static final List<SaleLine> LINEAS = List.of(
            line("A", "2026-11-18T12:30:00", "p1", "Pescado frito", 1, 2, 64000),
            line("A", "2026-11-18T12:30:00", "p2", "Limonada de coco", 2, 2, 20000),
            line("B", "2026-11-19T15:10:00", "p2", "Limonada de coco", 2, 1, 10000),
            line("C", "2026-11-14T10:05:00", "p3", "Gusanito", 3, 1, 45000),
            line("D", "2026-11-15T12:45:00", "x9", "Mojarra (retirada)", 1, 1, 35000),
            line("E", "2026-11-16T12:00:00", null, "pescado frito ", 1, 1, 32000),   // sin id: se asocia por nombre
            line("F", "2026-11-10T13:00:00", "p1", "Pescado frito", 1, 1, 32000),   // periodo anterior
            line("G", "2026-11-11T18:00:00", "p2", "Limonada de coco", 2, 3, 30000), // periodo anterior
            line("H", "2026-10-01T09:00:00", "p1", "Pescado frito", 1, 5, 160000)); // fuera de ambos

    private static Map<String, Object> run(String rango, Integer categoria) {
        Range r = SalesChartsCalculator.resolveRange(rango, null, null, "auto", HOY, LocalDate.of(2026, 10, 1));
        return SalesChartsCalculator.compute(r, categoria, LINEAS, CATALOGO);
    }

    private static Map<String, Object> kpi(Map<String, Object> out, String name) {
        return (Map<String, Object>) ((Map<String, Object>) out.get("kpis")).get(name);
    }

    // ------------------------------------------------------------ rangos

    @Test
    void presetsDefineElPeriodoYElPeriodoAnteriorDeIgualDuracion() {
        Range r7 = SalesChartsCalculator.resolveRange("7d", null, null, "auto", HOY, null);
        assertThat(r7.desde()).isEqualTo(LocalDate.of(2026, 11, 13));
        assertThat(r7.hasta()).isEqualTo(HOY);
        assertThat(r7.anteriorDesde()).isEqualTo(LocalDate.of(2026, 11, 6));
        assertThat(r7.anteriorHasta()).isEqualTo(LocalDate.of(2026, 11, 12));
        assertThat(r7.granularidad()).isEqualTo("day");
        assertThat(SalesChartsCalculator.resolveRange("30d", null, null, null, HOY, null).desde()).isEqualTo(LocalDate.of(2026, 10, 21));
        assertThat(SalesChartsCalculator.resolveRange("90d", null, null, "auto", HOY, null).granularidad()).isEqualTo("week");
        assertThat(SalesChartsCalculator.resolveRange("365d", null, null, "auto", HOY, null).granularidad()).isEqualTo("month");
        assertThat(SalesChartsCalculator.resolveRange(null, null, null, null, HOY, null).rango()).isEqualTo("30d");
    }

    @Test
    void todoEmpiezaEnElPrimerPedidoYNoTienePeriodoAnterior() {
        Range r = SalesChartsCalculator.resolveRange("todo", null, null, "auto", HOY, LocalDate.of(2020, 2, 3));
        assertThat(r.desde()).isEqualTo(LocalDate.of(2020, 2, 3));
        assertThat(r.hasPrevious()).isFalse();
        assertThat(r.granularidad()).isEqualTo("month");
        assertThat(SalesChartsCalculator.resolveRange("todo", null, null, "auto", HOY, null).desde()).isEqualTo(HOY);
    }

    @Test
    void personalizadoValidaLasFechas() {
        Range r = SalesChartsCalculator.resolveRange("personalizado", LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), "week", HOY, null);
        assertThat(r.granularidad()).isEqualTo("week");
        assertThat(r.anteriorHasta()).isEqualTo(LocalDate.of(2026, 4, 30));
        assertThatThrownBy(() -> SalesChartsCalculator.resolveRange("personalizado", null, HOY, "auto", HOY, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> SalesChartsCalculator.resolveRange("personalizado", HOY, HOY.minusDays(1), "auto", HOY, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> SalesChartsCalculator.resolveRange("personalizado", HOY.minusYears(11), HOY, "auto", HOY, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> SalesChartsCalculator.resolveRange("ayer", null, null, "auto", HOY, null))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> SalesChartsCalculator.resolveRange("7d", null, null, "hora", HOY, null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void granularidadDemasiadoFinaSeAjustaParaNoSuperarElMaximoDePuntos() {
        Range r = SalesChartsCalculator.resolveRange("personalizado", HOY.minusYears(5), HOY, "day", HOY, null);
        assertThat(r.granularidad()).isEqualTo("week");
        Range r2 = SalesChartsCalculator.resolveRange("personalizado", HOY.minusYears(9), HOY, "week", HOY, null);
        assertThat(r2.granularidad()).isEqualTo("month");
    }

    @Test
    void agrupaPorSemanaDesdeElLunesYPorMesConEtiquetaAAAAMM() {
        assertThat(SalesChartsCalculator.buckets(LocalDate.of(2026, 11, 19), LocalDate.of(2026, 11, 30), "week"))
                .containsExactly(LocalDate.of(2026, 11, 16), LocalDate.of(2026, 11, 23), LocalDate.of(2026, 11, 30));
        assertThat(SalesChartsCalculator.label(LocalDate.of(2026, 11, 1), "month")).isEqualTo("2026-11");
    }

    // ------------------------------------------------------------ indicadores y tendencia

    @Test
    void indicadoresCuentanPedidosDistintosYComparanConElPeriodoAnterior() {
        Map<String, Object> out = run("7d", null);
        // Actual: A(84000) B(10000) C(45000) D(35000) E(32000) = 206000; 5 pedidos; 8 unidades
        assertThat(kpi(out, "ingresos").get("actual")).isEqualTo(206000.0);
        assertThat(kpi(out, "pedidos").get("actual")).isEqualTo(5.0);
        assertThat(kpi(out, "unidades").get("actual")).isEqualTo(8.0);
        assertThat(kpi(out, "ticketPromedio").get("actual")).isEqualTo(41200.0);
        // Anterior: F(32000) G(30000) = 62000 -> +232,3 %
        assertThat(kpi(out, "ingresos").get("anterior")).isEqualTo(62000.0);
        assertThat(kpi(out, "ingresos").get("cambioPct")).isEqualTo(232.3);
        assertThat(kpi(out, "pedidos").get("cambioPct")).isEqualTo(150.0);
    }

    @Test
    void enTodoNoHayComparacion() {
        Map<String, Object> out = run("todo", null);
        assertThat(kpi(out, "ingresos").get("anterior")).isNull();
        assertThat(kpi(out, "ingresos").get("cambioPct")).isNull();
        assertThat(((Map<String, Object>) out.get("trend")).get("ingresosAnterior")).isNull();
        assertThat(kpi(out, "ingresos").get("actual")).isEqualTo(206000.0 + 62000 + 160000);
    }

    @Test
    void laTendenciaSumaLoMismoQueLosIndicadoresYAlineaElPeriodoAnterior() {
        Map<String, Object> out = run("7d", null);
        Map<String, Object> trend = (Map<String, Object>) out.get("trend");
        List<String> labels = (List<String>) trend.get("labels");
        List<Double> ingresos = (List<Double>) trend.get("ingresos");
        List<Double> pedidos = (List<Double>) trend.get("pedidos");
        assertThat(labels).hasSize(7).startsWith("2026-11-13").endsWith("2026-11-19");
        assertThat(ingresos.stream().mapToDouble(Double::doubleValue).sum()).isEqualTo(206000.0);
        assertThat(pedidos.stream().mapToDouble(Double::doubleValue).sum()).isEqualTo(5.0);
        assertThat(ingresos.get(labels.indexOf("2026-11-18"))).isEqualTo(84000.0);
        List<Double> anterior = (List<Double>) trend.get("ingresosAnterior");
        assertThat(anterior).hasSize(7);
        assertThat(anterior.get(4)).isEqualTo(32000.0); // 10 nov = posición 4 del periodo 6-12
        assertThat(anterior.get(5)).isEqualTo(30000.0);
    }

    // ------------------------------------------------------------ productos

    @Test
    void rankingIncluyeProductosSinVentasRetiradosYAsociaPorNombre() {
        List<Map<String, Object>> products = (List<Map<String, Object>>) run("7d", null).get("products");
        assertThat(products).extracting(p -> p.get("nombre"))
                .containsExactly("Pescado frito", "Gusanito", "Mojarra (retirada)", "Limonada de coco", "Coca-Cola");
        Map<String, Object> pescado = products.get(0);
        assertThat(pescado.get("ingresos")).isEqualTo(96000.0); // A + E (asociado por nombre)
        assertThat(pescado.get("unidades")).isEqualTo(3.0);
        assertThat(pescado.get("pedidos")).isEqualTo(2);
        assertThat(pescado.get("ticketPromedio")).isEqualTo(48000.0);
        assertThat(pescado.get("frecuenciaPct")).isEqualTo(40.0);
        assertThat(pescado.get("stock")).isEqualTo(24.0);
        assertThat((List<Double>) pescado.get("serieIngresos")).hasSize(7);
        Map<String, Object> retirado = products.get(2);
        assertThat(retirado.get("activo")).isEqualTo(false);
        assertThat(retirado.get("stock")).isNull();
        Map<String, Object> coca = products.get(4);
        assertThat(coca.get("unidades")).isEqualTo(0.0);
        assertThat(coca.get("frecuenciaPct")).isEqualTo(0.0);
    }

    @Test
    void elFiltroDeCategoriaAfectaIndicadoresYProductosPeroNoLaMezclaDeCategorias() {
        Map<String, Object> out = run("7d", 2);
        assertThat(kpi(out, "ingresos").get("actual")).isEqualTo(30000.0);
        assertThat(kpi(out, "pedidos").get("actual")).isEqualTo(2.0);
        List<Map<String, Object>> products = (List<Map<String, Object>>) out.get("products");
        assertThat(products).extracting(p -> p.get("nombre")).containsExactly("Limonada de coco", "Coca-Cola");
        List<Map<String, Object>> mix = (List<Map<String, Object>>) out.get("categoryMix");
        assertThat(mix).extracting(m -> m.get("nombre")).containsExactly("Comida", "Bebida", "Servicio");
        assertThat(mix.get(0).get("ingresos")).isEqualTo(131000.0);
        assertThat(mix.get(1).get("ingresos")).isEqualTo(30000.0);
        assertThat(mix.get(2).get("pedidos")).isEqualTo(1);
        assertThatThrownBy(() -> run("7d", 9)).isInstanceOf(IllegalArgumentException.class);
    }

    // ------------------------------------------------------------ mapa de calor

    @Test
    void mapaDeCalorCuentaCadaPedidoUnaSolaVezEnSuDiaYHora() {
        Map<String, Object> heat = (Map<String, Object>) run("7d", null).get("heatmap");
        List<List<Double>> pedidos = (List<List<Double>>) heat.get("pedidos");
        List<List<Double>> ingresos = (List<List<Double>>) heat.get("ingresos");
        assertThat(pedidos).hasSize(7).allSatisfy(row -> assertThat(row).hasSize(24));
        assertThat(pedidos.get(2).get(12)).isEqualTo(1.0);     // miércoles 18 nov, 12 h: pedido A (2 líneas)
        assertThat(ingresos.get(2).get(12)).isEqualTo(84000.0);
        assertThat(pedidos.get(3).get(15)).isEqualTo(1.0);     // jueves 19 nov, 15 h
        double total = pedidos.stream().flatMap(List::stream).mapToDouble(Double::doubleValue).sum();
        assertThat(total).isEqualTo(5.0);
    }

    @Test
    void sinVentasDevuelveCerosSinErrores() {
        Range r = SalesChartsCalculator.resolveRange("30d", null, null, "auto", HOY, null);
        Map<String, Object> out = SalesChartsCalculator.compute(r, null, List.of(), CATALOGO);
        assertThat(kpi(out, "ingresos").get("actual")).isEqualTo(0.0);
        assertThat(kpi(out, "ticketPromedio").get("actual")).isEqualTo(0.0);
        assertThat(kpi(out, "ingresos").get("cambioPct")).isNull();
        assertThat((List<?>) out.get("products")).hasSize(4);
    }
}
