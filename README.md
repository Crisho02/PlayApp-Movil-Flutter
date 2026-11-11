# PlayApp-Movil-Flutter

PlayApp Movil — Aplicación móvil en **Flutter** desarrollada a partir de la plataforma web **PlayApp** (Cartagena, Colombia).

## Funcionalidades incluidas

- **Inicio:** Carrusel hero (*Hamburguesa de la casa*, *Mojarra*, *Bebidas*), bienvenida y enfoque anti-sobrecostos en playas de Cartagena, categorías populares (*Comida*, *Bebidas*, *Servicios*) y zonas de entrega en Bocagrande.
- **Tienda:** Catálogo de productos y servicios costeros con búsqueda por texto, filtro por categoría, ordenamiento por nombre/precio, detalle de producto, selector de cantidad y validación de stock.
- **Carrito, Envío y Pasarela de Pago:** Verificación de carrito, mapa interactivo de zonas de playa en Bocagrande / Cartagena (`Carpa / Mesa` y coordenadas), selección de método de pago (`Mercado Pago`, `DEBITO`, `CREDITO`, `EFECTIVO`), pasarela de pago y confirmación de pedido.
- **Pedidos:** Historial con filtro por estado (`Recibido`, `En preparación`, `Terminado`), estado de pago y opción para completar pagos pendientes.
- **Contacto y Reseñas:** Publicación de reseñas con estrellas (1–5) y formulario de contacto para Kiosco El Bony (`Cra. 1, Cartagena de Indias`).
- **Asistente PlayApp (Chat flotante):** Botón flotante con consulta inteligente de precios oficiales, bebidas frías, recomendaciones y estado de pedidos.
- **Autenticación y Panel Administrador:** Inicio de sesión y registro por rol (`Usuario` / `Administrador`), botones demo de acceso rápido y panel administrativo con métricas, gestión de órdenes, CRUD de catálogo y simulador de predicción de ventas.

## Credenciales demo incluidas

- **Usuario:** `cliente@playapp.co` / `1234`
- **Administrador:** `dondearri@gmail.com` / `1234`

## Requisitos para ejecutar

- Flutter SDK `3.47.2` o compatible
- Dart SDK `3.13.2` o compatible

## Cómo correr el proyecto

```bash
git clone https://github.com/Crisho02/PlayApp-Movil-Flutter.git
cd PlayApp-Movil-Flutter
flutter pub get
flutter run
```

Para elegir dispositivo específico:

```bash
flutter devices
flutter run -d chrome      # En navegador Chrome
flutter run -d windows     # App de escritorio Windows
flutter run -d <android>   # Emulador o teléfono Android
```

## Pruebas y análisis estático

```bash
dart analyze
flutter test
```
