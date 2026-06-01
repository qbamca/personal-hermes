# User installation notes

- Location: Mińsk Mazowiecki, Poland.
- Approximate coordinates: 52.1812, 21.5587.
- PV size: 10.1 kWp total.
- Roof exposure: east / west.
- Roof tilt: about 15°.
- The east side is slightly more south-facing than a pure east roof.

## Forecasting guidance

- Prefer daily energy totals (`watthours/day`) for summary forecasts.
- Model the array as two strings and combine locally when the roof has east/west exposure.
- A near-even split between east and west is a reasonable first assumption unless string sizes are known.
- When the exact roof bearing is uncertain, start with one azimuth slightly south of east and the other slightly south of west, then refine if the user provides better geometry.
