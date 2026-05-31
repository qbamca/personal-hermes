---
name: solar-monitor
description: Check the health and recent activity of the solar stack — growatt-bridge health, live telemetry snapshot, recent write audit, and service status. Use when user asks "how is the solar?" or "what's the inverter doing?" or wants a quick status overview.
---

# solar-monitor

Quick solar stack health check. Combines bridge health, live telemetry, and audit log inspection into a single status overview.

## Checklist

Run these steps in order and summarize results concisely.

### 1. Bridge health

```
GET http://localhost:8081/health          # from gateway
GET http://growatt-bridge:8081/health    # from dev shell
```

Report `cloud_reachable` and `status`. If degraded, stop and surface the error.

### 2. Bridge info

```
GET <base_url>/info
```

Report `readonly` flag and `allowed_write_operations`. Remind the user if writes are disabled.

### 3. Live telemetry

```
GET <base_url>/api/v1/devices/{device_sn}/telemetry
```

If `GROWATT_DEVICE_SN` is set in env, use it. Otherwise first call `GET /api/v1/plants` → devices.

Report compactly:
- PV: `ppv` W
- Battery: `soc`% — charging `p_charge` W / discharging `p_discharge` W
- Grid: importing `p_to_user` W / exporting `p_to_grid` W
- AC output: `pac` W
- Generation today: `e_today` kWh
- Status: `status_text`, `lost` flag

### 4. Recent write audit

Read the last 10 lines of the audit log:
- **Gateway**: `/opt/data/workspace/growatt-audit/audit.jsonl`
- **Dev shell**: `/workspace/growatt-audit/audit.jsonl`

Report: last operation, timestamp, result_code. If file is empty or missing, note "no writes recorded".

### 5. Service container status (host-side)

The agent cannot run `docker` inside the container. Instruct the user to run on the host if needed:

```bash
docker compose ps
docker compose logs --tail=50 growatt-bridge
docker compose logs --tail=50 hermes-gateway
```

Or check health via HTTP endpoints available to the agent (steps 1–2 above).

## Output format

Keep the summary short. Example:

```
Solar stack — 2026-05-31 10:30 UTC
Bridge: ok (cloud reachable)
PV: 3420 W  |  Battery: 78% discharging 1200 W  |  Export: 800 W
Today: 18.4 kWh generated
Last write: set_ac_charge_stop_soc @ 09:15 UTC → result_code 1
```
