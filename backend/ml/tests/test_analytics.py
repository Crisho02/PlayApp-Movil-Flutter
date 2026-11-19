from datetime import datetime
import pytest
from fastapi.testclient import TestClient
from ml.api import app
from ml.analytics import DAY_TYPES, SEASONS, SENSITIVITY_BASES, WEEKDAYS, _moment
from ml.common import calendar_features


def flags(date, hour=14):
    return calendar_features(_moment(date, hour))[1]


def test_reference_dates_have_the_calendar_flags_the_labels_claim():
    by_id = {d["id"]: d["date"] for d in DAY_TYPES}
    assert _moment(by_id["weekday"], 12).weekday() == 2
    assert _moment(by_id["weekend"], 12).weekday() == 5
    assert flags(by_id["weekday"])["holiday"] is False and flags(by_id["weekend"])["holiday"] is False
    assert flags(by_id["holiday"])["holiday"] is True
    for s in SEASONS:
        start = datetime.fromisoformat(s["week_start"])
        assert start.weekday() == 0, "cada semana del mapa de calor debe iniciar en lunes"
        week = [flags(f"{start.year}-{start.month:02d}-{start.day + i:02d}") for i in range(7)]
        assert all(w["holiday"] is False for w in week), s["id"]
        if s["id"] == "normal":
            assert not any(w["vacation"] or w["high_season"] for w in week)
        if s["id"] == "vacation":
            assert all(w["vacation"] and not w["high_season"] for w in week)
        if s["id"] == "high":
            assert all(w["vacation"] and w["high_season"] for w in week)
    for b in SENSITIVITY_BASES:
        assert flags(b["holiday"])["holiday"] or flags(b["holiday"])["bridge"]
        assert flags(b["vacation"])["vacation"] and not flags(b["vacation"])["high_season"]
        assert flags(b["high"])["high_season"]
        assert _moment(b["date"], 12).weekday() == _moment(b["high"], 12).weekday() == _moment(b["vacation"], 12).weekday()


@pytest.fixture(scope="module")
def body():
    with TestClient(app) as client:
        response = client.get("/analytics")
        assert response.status_code == 200, response.text
        return response.json()


def test_analytics_shape_and_provenance(body):
    assert body["available"] is True and body["trainingData"] == "SIMULATED_ONLY"
    assert body["modelVersion"].startswith("sim-v1-")
    assert body["evaluation"]["mae"] < body["evaluation"]["baselineMae"]
    assert "simulados" in body["notice"]


def test_hourly_curves_are_valid_percentages_with_night_policy(body):
    h = body["hourly"]
    assert [d["id"] for d in h["dayTypes"]] == ["weekday", "weekend", "holiday"]
    assert [c["id"] for c in h["conditions"]] == ["clear", "cloudy", "rain"]
    for day in h["dayTypes"]:
        for cond in h["conditions"]:
            curve = h["series"][day["id"]][cond["id"]]
            assert len(curve) == 24 and all(0 <= v <= 100 for v in curve)
            assert all(v <= 1 for i, v in enumerate(curve) if not 6 <= i < 18), "noche limitada a 0-1 %"
            assert max(curve) > 5, "el modelo debe responder de dia"
    clear, rain = h["series"]["weekday"]["clear"], h["series"]["weekday"]["rain"]
    assert max(clear) > max(rain), "lluvia debe reducir la ocupacion maxima"


def test_heatmap_dimensions_and_seasonal_ordering(body):
    hm = body["heatmap"]
    assert hm["days"] == WEEKDAYS
    for s in hm["seasons"]:
        grid = hm["values"][s["id"]]
        assert len(grid) == 7 and all(len(r) == 24 for r in grid)
        assert all(0 <= v <= 100 for r in grid for v in r)
    peak = lambda sid: max(max(r) for r in hm["values"][sid])
    assert peak("high") > peak("normal")
    assert max(hm["values"]["normal"][5]) > max(hm["values"]["normal"][2]), "sabado > miercoles"


def test_sensitivity_deltas_are_consistent(body):
    bases = body["sensitivity"]["bases"]
    assert [b["id"] for b in bases] == ["weekday", "weekend"]
    for b in bases:
        assert 0 <= b["baseline"] <= 100
        assert [f["id"] for f in b["factors"]] == ["sky", "rain", "temperature", "wind", "hour", "calendar"]
        for f in b["factors"]:
            assert f["options"], f["id"]
            for o in f["options"]:
                assert o["delta"] == pytest.approx(o["value"] - b["baseline"], abs=0.11)
            assert f["impact"] == max(abs(o["delta"]) for o in f["options"])
        night = next(o for f in b["factors"] if f["id"] == "hour" for o in f["options"] if "noche" in o["label"])
        assert night["value"] <= 1 and night["delta"] < -5
