# Backend de la pestaña "Gráficos" (PlayApp-main)

La pestaña **Gráficos** del panel admin consulta `GET /api/admin/charts`, que vive en el
backend **PlayApp-main** (el que se ejecuta con `start-playapp.bat` en el puerto 8080).
Ese proyecto no está en este repositorio, así que el cambio se entrega como parche.

## Qué añade el parche (solo código nuevo; no modifica nada existente)

- `service/SalesChartsCalculator.java`: cálculos (rangos, periodo anterior, tendencia,
  ranking, mapa de calor, mezcla por categoría).
- `service/SalesChartsService.java`: consulta a MongoDB (solo los campos necesarios, sin
  imágenes). Admin global ve todo; admin de restaurante solo sus productos.
- `rest/ApiAdminController.java`: 1 campo y el endpoint `GET /api/admin/charts`.
- Pruebas: `SalesChartsCalculatorTest` y `ApiAdminChartsEndpointTest`.

Criterios iguales al reporte de "productos más vendidos": se cuentan los productos de pedidos
no cancelados (estado distinto de 3 y -1); ingreso = subtotal (o precio x cantidad).

## Cómo aplicarlo

Desde la carpeta raíz de PlayApp-main (donde está `pom.xml`):

```powershell
git -c core.autocrlf=false apply --check ruta\a\graficos-backend.patch
git -c core.autocrlf=false apply ruta\a\graficos-backend.patch
```

`core.autocrlf=false` conserva los saltos de línea LF del proyecto. Luego reiniciar el
backend con `start-playapp.bat`.

## Parámetros del endpoint

`GET /api/admin/charts?correo=...&rango=30d&categoria=2&granularidad=auto`

- `rango`: `7d`, `30d`, `90d`, `365d`, `todo` o `personalizado` (con `desde` y `hasta`, AAAA-MM-DD).
- `categoria` (opcional): 1 Comida, 2 Bebida, 3 Servicio.
- `granularidad`: `auto`, `day`, `week` o `month`.

Responde 403 si el correo no es administrador y 400 con un mensaje si los parámetros no son válidos.
