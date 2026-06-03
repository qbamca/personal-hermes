# Hourly forecast aggregation

forecast.solar's free tier does not expose a `/watthours/hour` endpoint. Use the `estimate` response instead, which includes a `watt_hours_period` map keyed by timestamp.

## Response structure

```json
{
  "result": {
    "watt_hours_period": {
      "2026-06-03 07:00:00": 120,
      "2026-06-03 07:30:00": 310,
      "2026-06-03 08:00:00": 580,
      ...
    }
  }
}
```

Each value is the energy produced **in that period** (Wh), not a cumulative total. Periods are typically 30 minutes but may vary.

## Aggregating into hourly buckets

```python
from collections import defaultdict
from datetime import datetime

hourly = defaultdict(float)
for ts_str, wh in watt_hours_period.items():
    hour = datetime.fromisoformat(ts_str).replace(minute=0, second=0)
    hourly[hour] += wh  # accumulate 30-min slices into the hour

# Convert to kWh
hourly_kwh = {h: wh / 1000 for h, wh in sorted(hourly.items())}
```

## Combining east + west strings

Run the same aggregation for each string separately, then add them:

```python
combined_kwh = {
    h: east_kwh.get(h, 0) + west_kwh.get(h, 0)
    for h in set(east_kwh) | set(west_kwh)
}
```

## Practical notes

- Always fetch both strings in separate API calls (free tier: one plane per call).
- For the energy-manager skill, extract the `watt_hours_period` slice from the current hour onwards to compute remaining-day production.
- Sum of all `watt_hours_period` values equals `watt_hours.day` — use this as a quick sanity check.
