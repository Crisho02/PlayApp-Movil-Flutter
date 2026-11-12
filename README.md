# PlayApp-Movil-Flutter

PlayApp Móvil — Aplicación móvil en **Flutter** desarrollada a partir del proyecto universitario **PlayApp** (Spring Boot 3 + Java 21 + MongoDB Atlas + Mercado Pago + Weka).

Diseñada con enfoque **mobile-first**, conectada directamente a la **misma base de datos MongoDB Atlas** y con la **pasarela de datos y de pagos** completa para playas de Cartagena de Indias, Colombia.

---

## 🚀 Características Principales

### 1. Pasarela de Datos & Misma Base de Datos MongoDB Atlas (`playappdb`)
- **Conexión Directa:** Conectado al cluster oficial MongoDB Atlas del proyecto universitario:
  `mongodb+srv://playapp_user:PlayAppadmin123@playapp-prod.0ibspwi.mongodb.net/playappdb?retryWrites=true&w=majority`
- **Colecciones sincronizadas bidireccionalmente:**
  - `productos`: Catálogo con imágenes binarias, categorías (Comida, Bebida, Servicio) y stock en playa.
  - `entidades`: Usuarios y administradores/restaurantes con hash seguro **BCrypt** compatible con Spring Security.
  - `pedidos`: Órdenes completas con carritos, estado operativo (`Recibido`, `En preparación`, `Terminado`) y datos de entrega.
  - `reseñas`: Calificaciones 1–5 estrellas y opiniones en playa.
  - `mensajes_contacto`: Mensajes de reservación, sugerencia o consulta para Kiosco El Bony.
  - `chat_messages` y `chat_sessions`: Historial de consultas del asistente de playa.
- **Tolerancia y Modo Offline:** Si no hay conectividad o en entornos restringidos, conmuta automáticamente a caché local reactiva sin interrupciones ni bloqueos.
- **Hoja de Estado de la Pasarela:** Botón interactivo en la barra superior para inspeccionar el estado de la conexión, ver conteo de documentos en tiempo real y forzar sincronización.

### 2. Pasarela de Pagos (Payment Gateway)
- Fiel al flujo de `fake-payment-gateway.html` y `PaymentController.java`:
  - **Mercado Pago:** Flujo de pago preferencial con modal móvil y verificación de orden.
  - **Efectuar Pago (Aprobación inmediata):** Descuenta inventario en MongoDB, actualiza el estado de pago a `Terminado` y genera el comprobante digital.
  - **Cancelar Pago:** Marca el pago como `Cancelado`, permitiendo reintentar desde el historial de pedidos (`user-orders.html`).

### 3. Asistente Inteligente Costero Dual (Gemini AI + Motor de Intenciones)
- Conexión directa a **Google Gemini REST API** (`gemini-1.5-flash`) con el prompt del sistema especializado en turismo de Cartagena, prevención de sobrecostos y recomendaciones locales.
- **Motor determinista local (`ChatBotService`):** Respuestas instantáneas a preguntas sobre precios oficiales, limonada de coco, cerveza nacional, pescado frito y estado de compras.

### 4. Predicción de Ventas (Machine Learning Weka)
- Fiel a `manager-prediccion.html`, `WekaPredictionService.java` y `dataset_ventas.arff`:
  - Variables de entrada: Día de la semana, Producto (los 10 productos del dataset), Categoría, Precio, Clima (Soleado, Nublado, Lluvioso) y Temporada (Alta, Baja, Normal).
  - Cálculo de demanda proyectada en unidades.

### 5. Interfaz Móvil y Experiencia de Usuario
- **Inicio:** Carrusel de platos típicos, bienvenida con verificación de precios y mapa interactivo de zonas de playa.
- **Tienda:** Búsqueda en vivo, filtrado por categorías, ordenamiento, detalle en Bottom Sheet y validación de existencias.
- **Carrito & Entrega:** Selector de zona de playa (Bocagrande, Castillogrande, Marbella, Laguito), coordenadas GPS, Carpa/Mesa y método de pago.
- **Historial de Pedidos:** Filtros por estado, badges de colores idénticos a los estilos CSS del proyecto Spring Boot y reintento de pago.
- **Panel Administrativo:** Dashboard con métricas globales, gráficos móviles de ingresos, métodos de pago, productos más vendidos y control de catálogo (CRUD).

---

## 🔑 Credenciales Demo

| Rol | Correo | Contraseña |
|---|---|---|
| **Usuario / Cliente** | `cliente@playapp.co` | `1234` |
| **Administrador / Restaurante** | `adminplayapp01@gmail.com` | `admin123` |
| **Administrador Secundario** | `dondearri@gmail.com` | `1234` |

*También es posible registrarse en tiempo real como nuevo Usuario o Administrador tanto en local como en MongoDB Atlas.*

---

## 🛠️ Cómo Ejecutar

```bash
# 1. Clonar el repositorio
git clone https://github.com/Crisho02/PlayApp-Movil-Flutter.git
cd PlayApp-Movil-Flutter

# 2. Descargar dependencias
flutter pub get

# 3. Ejecutar en dispositivo / emulador / web / escritorio
flutter run
```

### Comandos de Verificación
```bash
flutter analyze
flutter test
```
