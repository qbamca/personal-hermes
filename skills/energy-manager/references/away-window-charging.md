# Away-window charging pattern

Use this pattern when the EV leaves before the solar peak and returns while production is still significant (typically 09:00–14:00 on a sunny day).

## Situation

- EV departs early morning, before the solar ramp peaks
- EV returns mid-morning or at midday
- Battery may reach 85–90 % SOC before return if no load absorbs the surplus
- Goal: reserve battery headroom so the EV can soak up the midday peak on return

## Pre-departure step

If battery SOC is already high (≥ 70 %) and a large solar day is forecast, lower the battery charge setpoint to ~70 % before departure so it has room to absorb the ramp.

## On-return charging

Charge at **5.6 kW** (the lower power level) so the charger draws steadily without over-saturating the inverter when solar and battery are both available.

Avoid 10.6 kW unless the EV needs a fast top-up and solar surplus is large enough to justify it (forecast remaining > 10 kWh from the current hour).

## Quick kWh math

```
solar_window_hours    = hours from return until forecast drops below ~1 kW
solar_in_window       = sum of watt_hours_period buckets in that window (kWh)
home_load_in_window   = solar_window_hours × 0.8  # ~800 W avg non-EV draw
battery_headroom      = battery_current_kwh - overnight_reserve  # overnight_reserve = 6 kWh
ev_can_absorb         = ev_target_kwh - ev_current_kwh

available_for_ev      = solar_in_window - home_load_in_window + battery_headroom
recommend_ev_charge   = min(available_for_ev, ev_can_absorb)
charge_duration_hours = recommend_ev_charge / 5.6
```

## Example

Return at 11:00, forecast shows 12 kWh remaining until 16:00, battery at 14 kWh (headroom = 14 − 6 = 8 kWh), EV at 40 kWh (target 60 kWh):

```
home_load_in_window   = 5 h × 0.8 = 4 kWh
available_for_ev      = 12 − 4 + 8 = 16 kWh
ev_can_absorb         = 60 − 40   = 20 kWh
recommend_ev_charge   = min(16, 20) = 16 kWh  → ~2.9 h at 5.6 kW
```

Report: "Charge the EV for about 3 hours at 5.6 kW after returning. Expected battery end-of-day: ~6–8 kWh."
