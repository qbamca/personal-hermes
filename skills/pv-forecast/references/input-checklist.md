# PV forecast input checklist

Use this checklist before querying forecast.solar or presenting a PV forecast to the user.

## Preferred inputs

- site location: latitude + longitude
- roof/string orientation or azimuth
- tilt / declination
- system size in kWp per string
- whether the user wants a conservative combined house total or per-string totals

## Fallbacks

- If exact coordinates are missing, ask for a city, address, or location pin before estimating.
- If only a city is available, treat the forecast as approximate and say so explicitly.
- Do not invent orientation, tilt, or system size unless they are already known from prior context.

## Output guidance

- Provide today and tomorrow totals when requested.
- If multiple roof strings exist, keep per-string values available and combine them conservatively for the final answer.
- Mention freshness/caching only if the data may be stale or rate-limited.
