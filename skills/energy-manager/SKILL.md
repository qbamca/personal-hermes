---
name: energy-manager
description: Home energy management for a solar + battery + EV household. Use when the user asks about charging the car, whether to grid-charge the battery, how much energy they'll produce, or what to do given today's or tomorrow's forecast.
---

# energy-manager

Orchestrates pv-forecast, growatt-bridge, and solar-monitor to make concrete dispatch and charging decisions.

## Installation

- **PV:** 10.1 kWp, east/west roof, ~30° tilt, Mińsk Mazowiecki PL (52.1812°N, 21.5587°E)
- **Battery:** 20 kWh nominal — 16 kWh usable (bottom 20% reserved); operational range ~10–90% SOC
- **EV:** 76 kWh battery — normal ceiling 80% = ~60.8 kWh (life-prolonging default); charging to 100% is acceptable when preparing for a longer trip or when several days of low solar production are forecast
- **Home consumption:** ~20 kWh/day; overnight share (22:00–06:00) ~5–7 kWh
- **Grid tariff G12** — off-peak (cheaper) windows:
  - Weekdays: 22:00–06:00 and 13:00–15:00
  - Weekends and public holidays: all day
  - Note: exact hours may shift with DST or contract revision — verify against energy bill

## Daily planning workflow

1. Fetch current battery SOC from growatt-bridge (`/api/v1/devices/{sn}/telemetry` → `battery_soc`)
2. Ask user for current EV charge % if not available via app
3. Fetch today's remaining forecast + tomorrow's full forecast (pv-forecast skill, both strings combined)
4. Determine scenario and give a concrete recommendation (see below)

Always state the key numbers: expected production, current battery, EV state, recommended action in kWh.

## Scenario A — Sunny day, leaving with the car

Goal: prevent battery from hitting 100% and exporting while the user is away; maintain enough reserve for the night.

```
available_solar_excess = forecast_remaining - estimated_home_load_until_return
overnight_reserve      = 6 kWh  (covers ~22:00–06:00 at half typical overnight draw)
battery_headroom       = battery_current_kwh - overnight_reserve
ev_can_absorb          = 60.8 - ev_current_kwh

recommend_ev_charge    = min(available_solar_excess + battery_headroom, ev_can_absorb)
```

Report: how much to add to EV (kWh and approx % of 76 kWh), whether to reduce battery SOC setpoint before leaving, expected battery level on return.

## Scenario B — Sunny day, staying home

- Let battery charge from solar naturally
- If forecast suggests battery will reach 100% before sunset: alert and offer to charge EV proactively to absorb the excess
- Target: battery finishes day at ~85–90% SOC, ready for evening/overnight use

## Scenario C — Cloudy or rainy day

```
expected_tomorrow  = pv_forecast_tomorrow_kwh
needed_for_day     = 20 kWh  (typical daily consumption)
shortfall          = max(0, needed_for_day - expected_tomorrow - battery_current_kwh)
```

If shortfall > 0: recommend overnight G12 grid charge. State:
- How many kWh to add (shortfall + small buffer)
- Which off-peak window to use (next 22:00–06:00 or 13:00–15:00 window)
- Target SOC after charge

If no shortfall: confirm battery is sufficient, no grid charge needed.

## Scenario D — Forecast query only

Return:
- Today remaining (combined east + west, kWh)
- Tomorrow total (combined, kWh)
- Per-string breakdown if useful
- Cache freshness note if data is >1 hour old
