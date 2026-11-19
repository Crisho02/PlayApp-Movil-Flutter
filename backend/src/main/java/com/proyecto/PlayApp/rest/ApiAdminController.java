package com.proyecto.PlayApp.rest;

import com.proyecto.PlayApp.dto.BusquedaDTO;
import com.proyecto.PlayApp.dto.PedidoDetalleDTO;
import com.proyecto.PlayApp.entity.Pedido;
import com.proyecto.PlayApp.entity.Producto;
import com.proyecto.PlayApp.entity.Usuario;
import com.proyecto.PlayApp.repository.PedidoRepository;
import com.proyecto.PlayApp.repository.ProductoRepository;
import com.proyecto.PlayApp.repository.UsuarioRepository;
import com.proyecto.PlayApp.service.CurrentWeatherService;
import com.proyecto.PlayApp.service.OccupancyAnalyticsService;
import com.proyecto.PlayApp.service.PedidoService;
import com.proyecto.PlayApp.service.ProductoService;
import com.proyecto.PlayApp.service.ReporteService;
import lombok.RequiredArgsConstructor;
import org.bson.BsonBinarySubType;
import org.bson.types.Binary;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ApiAdminController {

    private final PedidoService pedidoService;
    private final PedidoRepository pedidoRepository;
    private final ProductoService productoService;
    private final ProductoRepository productoRepository;
    private final UsuarioRepository usuarioRepository;
    private final ReporteService reporteService;
    private final CurrentWeatherService currentWeatherService;
    private final OccupancyAnalyticsService occupancyAnalyticsService;

    @Value("${playapp.admin.email:adminplayapp01@gmail.com}")
    private String adminGlobalCorreo;

    private boolean validarAdmin(String correo) {
        if (correo == null || correo.isBlank()) return false;
        Usuario u = usuarioRepository.findUsuarioByCorreo(correo.trim());
        return u != null && ("ROLE_ADMIN".equalsIgnoreCase(u.getRol()) || adminGlobalCorreo.equalsIgnoreCase(u.getCorreo()));
    }

    @GetMapping("/orders")
    public ResponseEntity<?> listarPedidosAdmin(
            @RequestParam(name = "correo") String correo,
            @RequestParam(name = "estado", required = false) Integer estado,
            @RequestParam(name = "page", defaultValue = "0") Integer page,
            @RequestParam(name = "size", defaultValue = "20") Integer size
    ) {
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        Page<Pedido> pedidosPage = pedidoService.buscarPedidoPorRestaurate(
                BusquedaDTO.builder()
                        .id(correo.trim())
                        .categoria(estado)
                        .page(page)
                        .size(size)
                        .sort("[{\"campo\":\"timestamp\",\"direccion\":\"desc\"}]")
                        .build()
        );

        List<Map<String, Object>> list = new ArrayList<>();
        for (Pedido p : pedidosPage.getContent()) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId());
            map.put("total", p.getTotal());
            map.put("fecha", p.getTimestamp() != null ? p.getTimestamp().toString() : "");
            map.put("estado", p.getEstado());
            map.put("estadoNombre", p.obtenerNombreEstado());
            map.put("estadoCss", p.obtenerClaseCSSEstado());
            if (p.getPago() != null) {
                map.put("metodoPago", p.getPago().obtenerNombreMetodo());
                map.put("estadoPago", p.getPago().obtenerNombreEstado());
                map.put("estadoPagoCss", p.getPago().obtenerClaseCSSEstado());
            } else {
                map.put("metodoPago", "No registrado");
                map.put("estadoPago", "Sin estado");
                map.put("estadoPagoCss", "text-bg-secondary");
            }
            map.put("clienteNombre", p.getCliente() != null ? p.getCliente().getNombreCompleto() : "Cliente");
            map.put("clienteCorreo", p.getCliente() != null ? p.getCliente().getCorreo() : "");
            map.put("direccion", p.getEnvio() != null ? p.getEnvio().getDirreccion() : "");
            map.put("itemsCount", p.getCarrito() != null ? p.getCarrito().size() : 0);
            list.add(map);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("pedidos", list);
        res.put("totalElements", pedidosPage.getTotalElements());
        res.put("totalPages", pedidosPage.getTotalPages());
        res.put("currentPage", pedidosPage.getNumber());

        return ResponseEntity.ok(res);
    }

    @PostMapping("/orders/{id}/status")
    public ResponseEntity<?> cambiarEstadoPedido(
            @PathVariable String id,
            @RequestBody Map<String, Object> body
    ) {
        String correo = (String) body.get("correo");
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        Integer estado = ((Number) body.get("estado")).intValue();
        Pedido actualizado = pedidoService.actualizarEstadoPedido(estado, id);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "id", actualizado.getId(),
                "estado", actualizado.getEstado(),
                "estadoNombre", actualizado.obtenerNombreEstado()
        ));
    }

    @PostMapping("/orders/{id}/mark-paid")
    public ResponseEntity<?> marcarPedidoPagado(
            @PathVariable String id,
            @RequestBody Map<String, String> body
    ) {
        String correo = body.get("correo");
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        Pedido actualizado = pedidoService.marcarPedidoComoPagado(id);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "id", actualizado.getId(),
                "estadoPago", actualizado.getPago().getEstadoPago(),
                "mensaje", "Pedido marcado como pagado exitosamente"
        ));
    }

    @PostMapping("/products")
    public ResponseEntity<?> crearProducto(
            @RequestBody Map<String, Object> body
    ) {
        String correo = (String) body.get("correo");
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        String nombre = (String) body.get("nombre");
        String descripcion = (String) body.get("descripcion");
        Double precio = ((Number) body.get("precio")).doubleValue();
        Double stock = body.get("stock") != null ? ((Number) body.get("stock")).doubleValue() : 10.0;
        Integer categoria = body.get("categoria") != null ? ((Number) body.get("categoria")).intValue() : 1;
        Integer tipo = body.get("tipo") != null ? ((Number) body.get("tipo")).intValue() : 1;
        String base64Image = (String) body.get("base64Image");

        Producto nuevo = new Producto();
        nuevo.setNombre(nombre);
        nuevo.setDescripcion(descripcion);
        nuevo.setPrecio(precio);
        nuevo.setStock(stock);
        nuevo.setCategoria(categoria);
        nuevo.setTipo(tipo);

        if (base64Image != null && !base64Image.isBlank()) {
            try {
                String cleanBase64 = base64Image;
                String contentType = "image/jpeg";
                if (cleanBase64.contains(",")) {
                    String[] parts = cleanBase64.split(",");
                    if (parts[0].contains("image/png")) contentType = "image/png";
                    cleanBase64 = parts[1];
                }
                byte[] decoded = Base64.getDecoder().decode(cleanBase64);
                nuevo.setImagen(new Binary(BsonBinarySubType.BINARY, decoded));
                nuevo.setImagenContentType(contentType);
            } catch (Exception ignored) {}
        }

        Producto guardado = productoService.crearProducto(nuevo, correo.trim());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "success", true,
                "id", guardado.getId(),
                "nombre", guardado.getNombre(),
                "mensaje", "Producto creado exitosamente"
        ));
    }

    @PutMapping("/products/{id}")
    public ResponseEntity<?> actualizarProducto(
            @PathVariable String id,
            @RequestBody Map<String, Object> body
    ) {
        String correo = (String) body.get("correo");
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        Optional<Producto> opt = productoService.buscarProductoPorId(id);
        if (opt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Producto no encontrado"));
        }

        Producto existente = opt.get();
        if (body.containsKey("nombre")) existente.setNombre((String) body.get("nombre"));
        if (body.containsKey("descripcion")) existente.setDescripcion((String) body.get("descripcion"));
        if (body.containsKey("precio")) existente.setPrecio(((Number) body.get("precio")).doubleValue());
        if (body.containsKey("stock")) existente.setStock(((Number) body.get("stock")).doubleValue());
        if (body.containsKey("categoria")) existente.setCategoria(((Number) body.get("categoria")).intValue());

        if (body.containsKey("base64Image") && body.get("base64Image") != null) {
            try {
                String cleanBase64 = (String) body.get("base64Image");
                String contentType = "image/jpeg";
                if (cleanBase64.contains(",")) {
                    String[] parts = cleanBase64.split(",");
                    if (parts[0].contains("image/png")) contentType = "image/png";
                    cleanBase64 = parts[1];
                }
                byte[] decoded = Base64.getDecoder().decode(cleanBase64);
                existente.setImagen(new Binary(BsonBinarySubType.BINARY, decoded));
                existente.setImagenContentType(contentType);
            } catch (Exception ignored) {}
        }

        Producto guardado = productoRepository.save(existente);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "id", guardado.getId(),
                "nombre", guardado.getNombre(),
                "mensaje", "Producto actualizado exitosamente"
        ));
    }

    @DeleteMapping("/products/{id}")
    public ResponseEntity<?> eliminarProducto(
            @PathVariable String id,
            @RequestParam(name = "correo") String correo
    ) {
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        productoService.deleteProducto(id);
        return ResponseEntity.ok(Map.of("success", true, "mensaje", "Producto eliminado exitosamente"));
    }

    @GetMapping("/metrics")
    public ResponseEntity<?> obtenerMetricas(@RequestParam(name = "correo") String correo) {
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }

        long totalPedidos = pedidoRepository.count();
        long totalProductos = productoRepository.count();
        long totalUsuarios = usuarioRepository.count();

        Map<String, Object> metricas = new HashMap<>();
        metricas.put("totalPedidos", totalPedidos);
        metricas.put("totalProductos", totalProductos);
        metricas.put("totalUsuarios", totalUsuarios);
        metricas.put("ubicacion", currentWeatherService.location());
        try {
            metricas.put("clima", currentWeatherService.current());
        } catch (Exception e) {
            metricas.put("clima", Map.of("temperatura", "31°C", "condicion", "Soleado en Bocagrande"));
        }

        return ResponseEntity.ok(metricas);
    }

    @GetMapping("/prediction/analytics")
    public ResponseEntity<?> analiticaPrediccion(@RequestParam(name = "correo") String correo) {
        if (!validarAdmin(correo)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "No tienes permisos de administrador"));
        }
        return occupancyAnalyticsService.get()
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                        .body(Map.of("error", "El modelo de red neuronal no está disponible en este momento.")));
    }
}
