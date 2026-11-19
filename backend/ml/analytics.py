"""Escenarios sinteticos para graficar el comportamiento de la red neuronal.

Todas las cifras salen de ejecutar el modelo guardado sobre escenarios controlados
(clima y calendario definidos aqui). No son mediciones reales de la playa: el modelo
se entreno solo con datos simulados.
"""
import json
import math
from datetime import datetime

import numpy as np

from .common import ROOT, ZONE, WeatherInput, features

WEEKDAYS = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

# Tipos de dia (temporada normal, marzo/mayo 2026). Fechas fijas y verificadas en tests.
DAY_TYPES = [
    {"id": "weekday", "label": "Entre semana", "date": "2026-03-04"},   # miércoles
    {"id": "weekend", "label": "Fin de semana", "date": "2026-03-07"},  # sábado
    {"id": "holiday", "label": "Festivo", "date": "2026-05-01"},        # Día del Trabajo
]

# Condiciones de clima: codigo OpenWeather, desplazamiento de temperatura, humedad, viento,
# nubosidad y lluvia tipicos dentro del dominio de entrenamiento.
CONDITIONS = {
    "clear": {"label": "Despejado", "codes": [800], "dt": 0.0, "hum": 70.0, "wind": 12.0, "clouds": 8.0, "rain": None},
    "cloudy": {"label": "Nublado", "codes": [804], "dt": -1.0, "hum": 80.0, "wind": 14.0, "clouds": 90.0, "rain": None},
    "rain": {"label": "Lluvia", "codes": [501], "dt": -2.0, "hum": 92.0, "wind": 18.0, "clouds": 95.0, "rain": 3.5},
}

# Semana (lunes a domingo) representativa de cada temporada.
SEASONS = [
    {"id": "normal", "label": "Normal", "week_start": "2026-03-02"},
    {"id": "vacation", "label": "Vacaciones", "week_start": "2026-07-06"},
    {"id": "high", "label": "Temporada alta", "week_start": "2026-01-19"},
]

# Escenario base para el analisis de sensibilidad: 14:00, parcialmente nublado, 30 C.
SENSITIVITY_BASES = [
    {"id": "weekday", "label": "Entre semana · 14:00", "date": "2026-03-04",
     "holiday": "2026-05-01", "high": "2026-01-21", "vacation": "2026-07-08"},
    {"id": "weekend", "label": "Sábado · 14:00", "date": "2026-03-07",
     "holiday": "2026-03-21", "high": "2026-01-24", "vacation": "2026-07-11"},
]


def _is_daylight(hour):
    # Mismo supuesto que el simulador de entrenamiento: sol de 06:00 a 18:00.
    return 6 <= hour < 18


def _feels_like(temp, humidity):
    return min(max(temp + max(0.0, temp - 25.0) * humidity / 100.0 * 1.5, 21.0), 52.0)


def _moment(date_iso, hour):
    return datetime.fromisoformat(f"{date_iso}T{hour:02d}:00:00").replace(tzinfo=ZONE)


def _row(date_iso, hour, *, codes=(802,), temp=None, humidity=72.0, wind=12.0, clouds=40.0, rain=None):
    """Construye una entrada valida. La temperatura sigue el ciclo diario del simulador."""
    if temp is None:
        temp = 28.0 + 3.0 * math.sin((hour - 8) * math.pi / 12)
    return WeatherInput(
        observed_at=_moment(date_iso, hour),
        temperature_c=round(temp, 2),
        feels_like_c=round(_feels_like(temp, humidity), 2),
        humidity_pct=humidity,
        wind_kmh=wind,
        gust_kmh=round(min(wind * 1.4, 100.0), 2),
        clouds_pct=clouds,
        visibility_m=10000.0,
        rain_1h_mm=rain,
        pressure_hpa=1010.0,
        weather_codes=list(codes),
        daylight=_is_daylight(hour),
    )


def _condition_row(date_iso, hour, key):
    c = CONDITIONS[key]
    temp = 28.0 + 3.0 * math.sin((hour - 8) * math.pi / 12) + c["dt"]
    return _row(date_iso, hour, codes=c["codes"], temp=temp, humidity=c["hum"], wind=c["wind"],
                clouds=c["clouds"], rain=c["rain"])


def predict_rows(model, rows):
    """Ocupacion (%) para cada fila, con la misma politica nocturna que /predict."""
    x = np.asarray([features(r) for r in rows], dtype=np.float32)
    raw = np.asarray(model(x, training=False)).reshape(-1) * 100.0
    if not np.isfinite(raw).all():
        raise ValueError("Invalid model output")
    limits = np.asarray([100.0 if r.daylight else 1.0 for r in rows])
    return [round(float(v), 1) for v in np.clip(raw, 0.0, limits)]


def _sensitivity_options(base):
    """Cada opcion cambia UNA sola variable respecto al escenario base."""
    date = base["date"]
    h = 14
    return [
        ("sky", "Cielo", [
            ("Despejado", _row(date, h, codes=(800,), clouds=5.0)),
            ("Nublado", _row(date, h, codes=(804,), clouds=90.0)),
        ]),
        ("rain", "Lluvia", [
            ("Llovizna", _row(date, h, codes=(500,), clouds=85.0, humidity=88.0, rain=1.0)),
            ("Lluvia moderada", _row(date, h, codes=(501,), clouds=95.0, humidity=92.0, rain=4.0)),
            ("Tormenta", _row(date, h, codes=(211,), clouds=100.0, humidity=95.0, rain=10.0)),
        ]),
        ("temperature", "Temperatura", [
            ("26 °C", _row(date, h, temp=26.0)),
            ("35 °C", _row(date, h, temp=35.0)),
        ]),
        ("wind", "Viento", [
            ("Calma · 4 km/h", _row(date, h, wind=4.0)),
            ("Fuerte · 38 km/h", _row(date, h, wind=38.0)),
        ]),
        ("hour", "Hora del día", [
            ("08:00", _row(date, 8)),
            ("17:00", _row(date, 17)),
            ("20:00 (noche)", _row(date, 20)),
        ]),
        ("calendar", "Calendario", [
            ("Festivo / puente", _row(base["holiday"], h)),
            ("Vacaciones", _row(base["vacation"], h)),
            ("Temporada alta", _row(base["high"], h)),
        ]),
    ]


def build_analytics(model, meta):
    """Ejecuta el modelo sobre todos los escenarios y devuelve JSON listo para Flutter."""
    rows = []
    # 1) Curva horaria: tipo de dia x condicion x 24 horas
    hourly_index = {}
    for d in DAY_TYPES:
        for key in CONDITIONS:
            hourly_index[(d["id"], key)] = len(rows)
            rows.extend(_condition_row(d["date"], hour, key) for hour in range(24))
    # 2) Mapa de calor: temporada x 7 dias x 24 horas (parcialmente nublado)
    heat_index = {}
    for s in SEASONS:
        start = datetime.fromisoformat(s["week_start"]).date()
        for day in range(7):
            date = start.fromordinal(start.toordinal() + day).isoformat()
            heat_index[(s["id"], day)] = len(rows)
            rows.extend(_row(date, hour) for hour in range(24))
    # 3) Sensibilidad: base + opciones
    sens_plan = []
    for base in SENSITIVITY_BASES:
        base_at = len(rows)
        rows.append(_row(base["date"], 14))
        factors = []
        for fid, flabel, options in _sensitivity_options(base):
            opts = []
            for label, row in options:
                opts.append((label, len(rows)))
                rows.append(row)
            factors.append((fid, flabel, opts))
        sens_plan.append((base, base_at, factors))

    values = predict_rows(model, rows)

    hourly = {"dayTypes": [{"id": d["id"], "label": d["label"], "date": d["date"]} for d in DAY_TYPES],
              "conditions": [{"id": k, "label": c["label"]} for k, c in CONDITIONS.items()],
              "series": {d["id"]: {k: values[hourly_index[(d["id"], k)]:hourly_index[(d["id"], k)] + 24]
                                   for k in CONDITIONS} for d in DAY_TYPES}}
    heatmap = {"days": WEEKDAYS,
               "seasons": [{"id": s["id"], "label": s["label"], "weekStart": s["week_start"]} for s in SEASONS],
               "values": {s["id"]: [values[heat_index[(s["id"], d)]:heat_index[(s["id"], d)] + 24] for d in range(7)]
                          for s in SEASONS}}
    bases = []
    for base, base_at, factors in sens_plan:
        baseline = values[base_at]
        out = []
        for fid, flabel, opts in factors:
            options = [{"label": label, "value": values[i], "delta": round(values[i] - baseline, 1)} for label, i in opts]
            out.append({"id": fid, "label": flabel, "options": options,
                        "impact": round(max(abs(o["delta"]) for o in options), 1)})
        bases.append({"id": base["id"], "label": base["label"], "baseline": baseline, "factors": out})

    evaluation = {}
    path = ROOT / "artifacts/evaluation.json"
    if path.exists():
        e = json.loads(path.read_text(encoding="utf-8"))
        evaluation = {"mae": round(e["mae_percentage_points"], 2), "rmse": round(e["rmse_percentage_points"], 2),
                      "baselineMae": round(e["mean_baseline_mae"], 2),
                      "dayMae": round(e["day_mae_percentage_points"], 2),
                      "nightMae": round(e["night_mae_percentage_points"], 2)}

    return {
        "available": True,
        "modelVersion": meta["version"],
        "trainingData": "SIMULATED_ONLY",
        "notice": "Escenarios sintéticos evaluados con la red neuronal. Entrenada solo con datos simulados: "
                  "describe el comportamiento del modelo, no mediciones reales de la playa.",
        "evaluation": evaluation,
        "hourly": hourly,
        "heatmap": heatmap,
        "sensitivity": {"bases": bases},
    }
