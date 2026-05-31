---
name: service-control
description: Start, stop, restart Docker containers and tail their logs via the Docker socket proxy. Use when the user wants to restart a service (e.g. growatt-bridge), check if a container is running, or fetch recent container logs.
---

# service-control

Manage Docker containers via the socket proxy at `http://localhost:2375`. The proxy allows only: container list/inspect/logs, start, stop, restart. All other Docker API operations are blocked.

No Docker CLI needed — use HTTP calls directly.

## Base URL

```
http://localhost:2375
```

Available from the gateway container (host networking). Not accessible outside the host.

## List containers

```
GET http://localhost:2375/containers/json?all=1
```

Returns array of container objects. Key fields: `Names`, `State` (running/exited), `Status`, `Id`.

Add `?filters={"name":["growatt-bridge"]}` to filter by name.

## Inspect a container

```
GET http://localhost:2375/containers/{name_or_id}/json
```

Returns full container config and state. Check `.State.Status` and `.State.Health.Status`.

## Start a container

```
POST http://localhost:2375/containers/{name_or_id}/start
```

Returns 204 on success, 304 if already running, 404 if not found.

## Stop a container

```
POST http://localhost:2375/containers/{name_or_id}/stop
```

Add `?t=10` for a 10-second graceful shutdown timeout before SIGKILL.

## Restart a container

```
POST http://localhost:2375/containers/{name_or_id}/restart
```

Add `?t=10` for graceful timeout. Returns 204 on success.

## Tail logs

```
GET http://localhost:2375/containers/{name_or_id}/logs?stdout=1&stderr=1&tail=100&timestamps=1
```

Returns raw log bytes (may be multiplexed stream format — each line prefixed with 8-byte header). Strip headers or read as plain text.

## Common container names in this stack

| Container | Name |
|---|---|
| Growatt bridge | `growatt-bridge` |
| Hermes gateway | `hermes-gateway` |
| Hermes web UI | `hermes-webui` |
| Socket proxy | `hermes-socket-proxy` |

## Example: restart growatt-bridge

```
POST http://localhost:2375/containers/growatt-bridge/restart?t=10
```

Then verify:

```
GET http://localhost:2375/containers/growatt-bridge/json
```

Check `.State.Status == "running"` and `.State.Health.Status == "healthy"`.

## Example: check growatt-bridge health after restart

After restarting, also verify via the bridge's own health endpoint:

```
GET http://localhost:8081/health
```

The bridge healthcheck polls every 30s with a 15s start period — allow up to 45s before declaring unhealthy.

## Blocked operations

The proxy does not allow: image pull/build, network/volume management, exec into containers, create/delete containers, swarm operations. Attempts return 403.
