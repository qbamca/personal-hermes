---
name: pv-forecast
description: Retrieve and summarize photovoltaic production forecasts from forecast.solar. Use when the user wants expected solar generation for today or the next few days, especially for east and west roof strings that should be fetched separately on the free tier and merged into one household forecast with conservative rate limiting.
---

# pv-forecast

Use this skill to fetch PV generation forecasts from `forecast.solar`, keep per-string output, and compute a combined household forecast.

## Quick workflow

1. Read local installation notes in `TOOLS.md` if available; also check `references/user-installation-notes.md` for any saved site geometry.
2. Use the free-tier single-plane route for each roof string.
3. Combine east and west locally by day or timestamp.
4. For hourly schedules, use the `estimate` response and aggregate `watt_hours_period` into local hourly buckets; do not assume a separate `/watthours/hour` route exists.
5. Reuse cached data unless the user explicitly needs a fresh pull.
6. Report rate-limit or freshness details when available.

See `references/hourly-forecast-notes.md` for a compact example of the hourly aggregation workflow.

## What to collect before calling the API

For each string, gather:

- label
- latitude
- longitude
- tilt / declination
- orientation or forecast.solar azimuth
- capacity in kWp

If the roof is east/west and the exact bearing is uncertain, a near-even split plus slightly south-biased azimuths is often a useful first approximation; refine when the user gives better geometry.

If exact site inputs are missing, ask for a city/address or location pin first and clearly mark the result as an estimate. Do not invent orientation, tilt, or kWp values from thin air.

## forecast.solar conventions

- free public route:
  - `https://api.forecast.solar/estimate/:lat/:lon/:dec/:az/:kwp`
- for day totals, prefer:
  - `https://api.forecast.solar/estimate/watthours/day/:lat/:lon/:dec/:az/:kwp`
- azimuth is not the common `0..360` house-roof convention:
  - `-180` = north
  - `-90` = east
  - `0` = south
  - `90` = west
  - `180` = north

If local notes use `0..360`, convert with `az = orientation - 180`, normalized into `[-180, 180]`.

## Free-tier behavior

Use the free tier conservatively.

- assume a small hourly request budget
- do not spam refreshes
- default to daily energy totals using `watthours/day`
- cache successful responses for 1 hour unless the user wants a forced fresh check

## Output expectations

When replying to the user, keep it practical:

- east roof total for tomorrow
- west roof total for tomorrow
- combined total for tomorrow
- today total if useful for comparison
- rate-limit or stale-cache note if relevant
