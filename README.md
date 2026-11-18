# PlayApp Móvil (Flutter) - Cartagena de Indias 🏖️

Aplicación móvil oficial de **PlayApp**, desarrollada en **Flutter (Android & iOS)** con arquitectura limpia y moderna, conservando el 100% de la lógica de negocio, catálogo playero, flujos de pedido y sistema de diseño costero de la versión web.

---

## 📱 Características Principales

1. **Inicio con Carrusel Interactivo & Propuesta de Valor:**
   - Carrusel hero automático con platos destacados (*Hamburguesa de la casa*, *Pescado frito cartagenero*, *Bebidas heladas*).
   - Propuesta de valor de PlayApp: precios justos oficiales, entregas sin sobrecostos en carpas de Cartagena y pagos seguros.
   - Accesos directos a categorías: **Comidas**, **Bebidas** y **Servicios**.

2. **Tienda Playera & Búsqueda Avanzada:**
   - Búsqueda en tiempo real por texto (comidas, bebidas, servicios).
   - Filtros por categoría y ordenamiento (relevancia, menor precio, mayor precio, A-Z).
   - Tarjetas de producto con fotos locales o remotas, estado de disponibilidad en tiempo real, contador de unidades y botón de agregado al carrito.

3. **Carrito de Compras & Desglose Transparente:**
   - Modificación instantánea de cantidades o eliminación de ítems.
   - Desglose detallado: Subtotal de productos, Tarifa de entrega a la playa (**$5.000 COP**) y Total general en pesos colombianos.

4. **Entrega en Playa con Mapa Interactivo (Paso 1 Checkout):**
   - Selector visual de playas en Cartagena: *Playas de Bocagrande*, *Castillogrande (Bahía)*, *El Laguito (Hotel Hilton)*, *Marbella / Cabrero*.
   - Mapa con radar costero y coordenadas reales.
   - Campos dedicados para **N° de Carpa / Mesa** y notas de referencia (ej: *"sombrilla azul"*).
   - Teléfono / WhatsApp de contacto del cliente.

5. **Métodos de Pago Modernizados (Paso 2 Checkout):**
   - **Wompi (Bancolombia) [Recomendado]:** Tarjetas débito/crédito, Nequi, PSE y Botón Bancolombia en pasarela segura.
   - **Efectivo contraentrega:** *"Paga en efectivo cuando recibas tu pedido en la playa."*
   - **Transferencia contraentrega:** *"Realiza la transferencia al recibir tu pedido."*
   - *(Eliminado por completo cualquier modo simulado o demo local).*

6. **Pasarela de Pago Wompi:**
   - Formulario de tarjeta seguro con chips de prueba rápida:
     - **Aprobada:** `4242 4242 4242 4242`
     - **Rechazada:** `4111 1111 1111 1111`
   - Firma y verificación criptográfica coordinada con el backend Spring Boot.

7. **Ventana Modal de Detalle de Pedidos:**
   - Lista moderna de pedidos con etiquetas de estado dinámicas.
   - Ventana modal interactiva para clientes y administradores con desglose completo de productos con imágenes reales, carpa, playa, método de pago y fecha.

8. **Reseñas de la Comunidad & Contacto:**
   - Calificación interactiva de 1 a 5 estrellas y publicación de opiniones de playa (muestra las 5 más recientes desde MongoDB Atlas).
   - Formulario de contacto directo y datos del punto de atención en Playas de Bocagrande, Cartagena.

9. **Panel de Administración Completo (`ROLE_ADMIN`):**
   - Validación estricta de permisos.
   - Métricas en vivo: Total de ventas, pedidos totales, pendientes y entregados.
   - Estimación de ocupación de playas (Bocagrande y Castillogrande) y clima en Cartagena.
   - Gestión de pedidos: actualización de estado (*Recibido* ➔ *En preparación* ➔ *Terminado* ➔ *Cancelado*) y marcado como pagado.
   - Gestión de productos (crear, editar precio/stock y eliminar platos).

---

## 🏛️ Arquitectura & Seguridad

- **Clean Architecture:**
  - `lib/core/`: configuración de entorno, temas Material 3, constantes, cliente HTTP y almacenamiento seguro de sesiones.
  - `lib/data/models/`: modelos inmutables de datos (`UserModel`, `ProductModel`, `CartItemModel`, `OrderModel`, `ReviewModel`, `WompiInitData`).
  - `lib/providers/`: gestión de estado reactiva con `Provider` (`AuthProvider`, `ProductProvider`, `CartProvider`, `OrderProvider`, `ReviewProvider`, `AdminProvider`).
  - `lib/presentation/`: pantallas responsive organizadas por dominio y widgets reutilizables.
- **Seguridad Garantizada:**
  - La aplicación Flutter **no se conecta directamente a MongoDB Atlas**.
  - Todas las operaciones pasan por la API REST del backend Spring Boot.
  - No se exponen llaves privadas ni credenciales de base de datos en el cliente móvil.
- **Copia Reproducible del Backend:**
  - Incluido en la carpeta `backend/` con Maven Wrapper (`./mvnw`) y endpoints REST `/api/**` listos para ser levantados de manera autónoma.

---

## 🚀 Guía de Instalación y Ejecución

### 1. Iniciar el Backend Spring Boot

Asegúrate de contar con Java 21 y ejecuta:

```bash
cd backend
./mvnw spring-boot:run
```

*(En Windows puedes usar `mvnw.cmd spring-boot:run`)*. El servidor se iniciará en `http://localhost:8080`.

### 2. Ejecutar la Aplicación Móvil en Flutter

Desde la raíz del proyecto `PlayApp-Movil-Flutter`:

```bash
# Descargar dependencias
flutter pub get

# Ejecutar análisis estático (0 errores garantizados)
flutter analyze

# Ejecutar pruebas unitarias y de widgets
flutter test

# Iniciar la app en tu emulador o dispositivo
flutter run
```

### 3. Modos de Conexión y Depuración por Ambiente

La aplicación utiliza `EnvConfig` para resolver la conexión de forma automática y transparente sin exponer controles técnicos a los usuarios finales:

1. **Celular Android Físico por USB (Modo Recomendado):**
   Conecta tu teléfono Android por cable USB con depuración habilitada y ejecuta en tu computador:
   ```bash
   adb reverse tcp:8080 tcp:8080
   flutter run
   ```
   *(Esto permite que las solicitudes a `127.0.0.1:8080` viajen por el cable USB directamente a tu backend Spring Boot).*

2. **Celular Android Físico por Wi-Fi:**
   Asegúrate de que tu celular y el computador estén en la misma red Wi-Fi y ejecuta:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://<IP_DE_TU_PC>:8080
   # Ejemplo: flutter run --dart-define=API_BASE_URL=http://192.168.1.34:8080
   ```
   *(La aplicación autodetecta la IP activa mediante sondeo en cascada si no se especifica el parámetro).*

3. **Emulador de Android:**
   Se conecta automáticamente a `http://10.0.2.2:8080`.

4. **Flutter Web (Chrome Escritorio y Móvil):**
   - En **Chrome de escritorio**, utiliza `http://localhost:8080`.
   - En **Chrome móvil** conectado por red local (ej: `http://192.168.1.34:54004`), autodetecta el host del navegador y consume `http://192.168.1.34:8080` sin bloqueos de origen cruzado (CORS habilitado en Spring Boot con `@CrossOrigin(origins = "*")`).

5. **Compilación para Producción (Nube / Release):**
   Para compilar el APK o versión web final conectada a tu servidor en la nube (HTTPS seguro):
   ```bash
   # Generar APK de producción:
   flutter build apk --release --dart-define=API_BASE_URL=https://tu-backend.up.railway.app

   # Generar versión web de producción:
   flutter build web --release --dart-define=API_BASE_URL=https://tu-backend.up.railway.app
   ```

---

## 🔑 Credenciales de Prueba

- **Administrador:**
  - Correo: `adminplayapp01@gmail.com`
  - Contraseña: `admin123`
  - Rol: `ROLE_ADMIN` *(Habilita pestaña y accesos al panel de administración)*
- **Tarjetas Wompi Sandbox:**
  - Aprobada: `4242 4242 4242 4242` | Vence: `12/28` | CVC: `123`
  - Rechazada: `4111 1111 1111 1111` | Vence: `06/27` | CVC: `999`

---

## 🧪 Pruebas Automatizadas

El proyecto incluye 34 pruebas completas en `test/widget_test.dart`:
- Formateo de moneda colombiana (COP).
- Lógica de carrito: cálculo de subtotales, adición de tarifa fija de playa ($5.000 COP) y vaciado.
- Modelos de datos: mapeo de roles de usuario, etiquetas de pedidos y deserialización de productos MongoDB.
- Componentes de interfaz: insignias de estado dinámicas, tarjeta de producto adaptable sin desbordamiento a 320px, 375px, 390px, 414px, 768px y 1200px.
- Paridad administrativa: métricas, reportes ejecutivos e ingresos reales de productos más vendidos.

Ejecutar pruebas:
```bash
flutter test
```
*Resultado: `All tests passed! (34/34)`*

---

## 🌴 Identidad Visual

- **Ocean Dark:** `#075985`
- **Primary Sky:** `#0284C7`
- **Turquesa Caribe:** `#14B8A6`
- **Arena de Playa:** `#F8F5EF`
- **Coral PlayApp:** `#F97360`
- **Deep Navy:** `#0C4A6E`
